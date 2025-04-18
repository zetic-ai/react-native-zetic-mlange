import Foundation
import ZeticMLange

class MultipleInstances<T> {
    private var instances = [String: T]()

    func createInstance(instanceId: String, instance: T) {
        instances[instanceId] = instance
    }

    func removeInstance(instanceId: String) -> T? {
        return instances.removeValue(forKey: instanceId)
    }

    func getInstance(instanceId: String, reject: @escaping RCTPromiseRejectBlock) -> T {
        guard let instance = instances[instanceId] else {
            reject("Not found error", "Instance not created yet", nil)
            fatalError("Instance not created yet")
        }
        return instance
    }
}

class ZeticSwift {

    let instances = MultipleInstances<ZeticMLangeModel>()

    static let shared: ZeticSwift = ZeticSwift()

    private init() {
    }
    // MARK: - Interface Methods

    public func create(
        instanceId: String, personalKey: String, modelKey: String,
        resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.global(qos: .background).async {
            do {
                let model = try ZeticMLangeModel(personalKey, modelKey)
                self.instances.createInstance(instanceId: instanceId, instance: model)

                DispatchQueue.main.async {
                    resolve(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    reject(
                        "CREATE_FAILED",
                        "Failed to create Zetic instance: \(error.localizedDescription)", error)
                }
            }
        }
    }
    
    private func processOutputForReactNative(data: [Data]) -> [String] {
        // Convert each Data object to a base64 string
        return data.map { $0.base64EncodedString() }
    }
    
    public func run(
        instanceId: String, inputs: [[Any]], resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        let model = self.instances.getInstance(instanceId: instanceId, reject: reject)
        
        do {
            let dataInputs = try ZeticMlangeRNCodec.encode(input: inputs)
            try model.run(dataInputs)
            let output: [Data] = model.getOutputDataArray()
            resolve(output)
        } catch let e as ZeticMLangeError {
            reject(
                "RUN_ERROR",
                e.localizedDescription,
                nil
            )
        } catch {
            reject(
                "RUN_ERROR",
                error.localizedDescription,
                nil
            )
        }
    }

    public func destroy(
        instanceId: String, resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        instances.removeInstance(instanceId: instanceId)
        resolve(nil)
    }
}

@objc(Zetic)
class Zetic: NSObject {

    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc(create:personalKey:modelKey:withResolve:withReject:)
    func create(
        _ instanceId: String, personalKey: String, modelKey: String,
        resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock
    ) {
        let instance: ZeticSwift = ZeticSwift.shared
        instance.create(
            instanceId: instanceId, personalKey: personalKey, modelKey: modelKey, resolve: resolve,
            reject: reject)
    }

    @objc(run:inputs:withResolve:withReject:)
    func run(
        _ instanceId: String, inputs: [[Any]], resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {

        let instance: ZeticSwift = ZeticSwift.shared
        instance.run(instanceId: instanceId, inputs: inputs, resolve: resolve, reject: reject)
    }

    @objc(destroy:withResolve:withReject:)
    func destroy(
        _ instanceId: String, resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        let instance: ZeticSwift = ZeticSwift.shared
        instance.destroy(instanceId: instanceId, resolve: resolve, reject: reject)
    }

    @objc
    func constantsToExport() -> [AnyHashable: Any]! {
        return [:]
    }
}
