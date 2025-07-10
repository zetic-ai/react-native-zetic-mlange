import Foundation
import ZeticMLange


@objc(ZeticLLM)
class ZeticLLM: RCTEventEmitter {
    private var mlangeModel: ZeticMLangeLLMModel?
    private var tokenGenerationTask: Task<Void, Error>?
    private var isModelLoaded = false
    private var progress: Float = 0
    private var dispatchQueue = DispatchQueue(label: "com.zeticai.mlange", qos: .userInitiated)
    
    override init() {
        super.init()
        print("ZeticLLM initialized")
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    @objc
    override func supportedEvents() -> [String]! {
        return [
            "onEvent",
            "onError",
        ]
    }
    
    @objc
    override func constantsToExport() -> [AnyHashable : Any]! {
        return [
            "STATUS_NOT_INITIALIZED": "notInitialized",
            "STATUS_DOWNLOADING": "downloading",
            "STATUS_READY": "ready",
            "STATUS_ERROR": "error",
            // Quantization
            "ORG": "ORG",
            "F16": "F16",
            "BF16": "BF16",
            "Q8_0": "Q8_0",
            "Q6_K": "Q6_K",
            "Q4_K_M": "Q4_K_M",
            "Q3_K": "Q3_K",
            "Q2_K": "Q2_K",
            // Target
            "LLAMA_CPP": "LLAMA_CPP"
        ]
    }
    
    @objc
    func getModelStatus(_ resolve: @escaping RCTPromiseResolveBlock, 
                       reject: @escaping RCTPromiseRejectBlock) {
        let status: [String: Any] = [
            "isLoaded": isModelLoaded,
            "hasModel": mlangeModel != nil,
            "isGenerating": tokenGenerationTask != nil && !(tokenGenerationTask?.isCancelled ?? true)
        ]
        resolve(status)
    }
    
    @objc
    func initModel(_ personalAccessKey: String, 
                        modelKey: String,
                        target: String,
                        quantType: String,
                        resolve: @escaping RCTPromiseResolveBlock,
                        reject: @escaping RCTPromiseRejectBlock) {
        // If model is already loaded, return success
        if mlangeModel != nil && isModelLoaded {
            resolve([
                "success": true,
                "message": "Model already initialized",
                "isLoaded": true,
            ])
            return
        }
        
        let nativeTarget = self.convertTarget(target)
        let nativeQuantType = self.convertQuantType(quantType)
        
        // Return success immediately to indicate initialization started
        resolve([
            "success": true,
            "message": "Model initialization started",
            "isLoaded": false,
        ])
        
        dispatchQueue.async { [weak self] in
            do {
                let model = try ZeticMLangeLLMModel(
                    personalAccessKey,
                    modelKey,
                    nativeTarget,
                    nativeQuantType
                ) { progress in
                    // Send progress updates via event channel
                    DispatchQueue.main.async {
                        self?.progress = Float(progress)
                        self?.sendEventToJS(name: "onEvent", body: [
                            "type": "progress",
                            "progress": progress,
                            "message": "Loading model... \(Int(progress * 100))%"
                        ])
                    }
                }
                
                DispatchQueue.main.async {
                    self?.mlangeModel = model
                    self?.isModelLoaded = true
                    
                    // Send completion via event channel
                    self?.sendEventToJS(name: "onEvent", body: [
                        "type": "initialized",
                        "success": true,
                        "message": "Model initialized successfully",
                        "modelKey": modelKey,
                        "target": target,
                        "quantType": quantType,
                    ])
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.sendEventToJS(name: "onError", body: [
                        "type": "error",
                        "success": false,
                        "message": "Failed to initialize model: \(error.localizedDescription)",
                        "error": error.localizedDescription,
                    ])
                }
            }
        }
    }
    
    @objc
    func generateResponse(_ prompt: String, 
               options: [String: Any],
               resolve: @escaping RCTPromiseResolveBlock,
               reject: @escaping RCTPromiseRejectBlock) {
        guard let mlangeModel = mlangeModel, isModelLoaded else {
            reject("MODEL_NOT_INITIALIZED", "Model not initialized", nil)
            return
        }
        
        // Cancel any existing generation
        tokenGenerationTask?.cancel()
        
        // Send success response immediately
        resolve([
            "success": true,
            "message": "Generation started",
            "prompt": prompt,
        ])
        
        // Start token generation task
        tokenGenerationTask = Task { [weak self] in
            var response = ""
            var tokenCount = 0
            
            do {
                try mlangeModel.run(prompt)
                
                // Send generation started event
                await MainActor.run {
                    self?.sendEventToJS(name: "onEvent", body: [
                        "type": "started",
                        "message": "AI is thinking...",
                    ])
                }
                
                while !Task.isCancelled {
                    let token = mlangeModel.waitForNextToken()
                    
                    if token.isEmpty {
                        // Generation completed
                        await MainActor.run {
                            self?.sendEventToJS(name: "onEvent", body: [
                                "type": "complete",
                                "fullResponse": response,
                                "tokenCount": tokenCount,
                                "finished": true,
                            ])
                        }
                        break
                    }
                    
                    response.append(token)
                    tokenCount += 1
                    
                    // Send token update
                    await MainActor.run {
                        self?.sendEventToJS(name: "onEvent", body: [
                            "type": "token",
                            "token": token,
                            "fullResponse": response,
                            "tokenCount": tokenCount,
                        ])
                    }
                }
                
            } catch {
                await MainActor.run {
                    self?.sendEventToJS(name: "onError", body: [
                        "type": "error",
                        "message": "Generation error: \(error.localizedDescription)",
                        "error": error.localizedDescription,
                    ])
                }
            }
            
            // Clean up task reference
            await MainActor.run {
                if self?.tokenGenerationTask?.isCancelled == false {
                    self?.tokenGenerationTask = nil
                }
            }
        }
    }
    
    @objc
    func cancelGeneration(_ resolve: @escaping RCTPromiseResolveBlock, 
             reject: @escaping RCTPromiseRejectBlock) {
        tokenGenerationTask?.cancel()
        tokenGenerationTask = nil
        
        // Send cancellation event
        sendEventToJS(name: "onEvent", body: [
            "type": "cancelled",
            "message": "Generation cancelled",
        ])
        
        resolve([
            "success": true,
            "message": "Generation cancelled",
        ])
    }
    
    @objc
    func dispose(_ resolve: @escaping RCTPromiseResolveBlock, 
                reject: @escaping RCTPromiseRejectBlock) {
        // Cancel any running generation
        tokenGenerationTask?.cancel()
        tokenGenerationTask = nil
        
        // Clean up model
        mlangeModel = nil
        isModelLoaded = false
        
        resolve([
            "success": true,
            "message": "Model disposed successfully",
        ])
    }
    
    private func convertTarget(_ targetString: String) -> LLMTarget {
        let target: LLMTarget
        switch targetString.uppercased() {
        case "LLAMA_CPP":
        target = .LLAMA_CPP
        default:
        target = .LLAMA_CPP
        }
        return target
    }
    
    private func convertQuantType(_ quantTypeString: String) -> LLMQuantType {
        let quantType: LLMQuantType
        switch quantTypeString.uppercased() {
        case "ORG":
        quantType = .GGUF_QUANT_ORG
        case "F16":
        quantType = .GGUF_QUANT_F16
        case "BF16":
        quantType = .GGUF_QUANT_BF16
        case "Q8_0":
        quantType = .GGUF_QUANT_Q8_0
        case "Q6_K":
        quantType = .GGUF_QUANT_Q6_K
        case "Q4_K_M":
        quantType = .GGUF_QUANT_Q4_K_M
        case "Q3_K_M":
        quantType = .GGUF_QUANT_Q3_K_M
        case "Q2_K":
        quantType = .GGUF_QUANT_Q2_K
        default:
        quantType = .GGUF_QUANT_Q6_K
        }
        return quantType
    }
    
    private func sendEventToJS(name: String, body: [String: Any]) {
        if bridge != nil {
            sendEvent(withName: name, body: body)
        }
    }

    deinit {
        tokenGenerationTask?.cancel()
        tokenGenerationTask = nil
    }
}
