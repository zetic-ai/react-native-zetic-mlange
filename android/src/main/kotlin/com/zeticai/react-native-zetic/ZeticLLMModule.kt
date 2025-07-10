package com.zetic

import android.os.Handler
import android.os.Looper
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.zeticai.mlange.core.model.llm.LLMTarget
import com.zeticai.mlange.core.model.llm.LLMQuantType
import com.zeticai.mlange.core.model.llm.ZeticMLangeLLMModel

class ZeticLLMModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    private var mlangeModel: ZeticMLangeLLMModel? = null
    private var tokenGenerationThread: Thread? = null
    private var isModelLoaded = false
    private var progress: Float = 0f
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun getName() = NAME

    override fun getConstants(): MutableMap<String, Any> {
        return hashMapOf(
            "STATUS_NOT_INITIALIZED" to "notInitialized",
            "STATUS_DOWNLOADING" to "downloading",
            "STATUS_READY" to "ready",
            "STATUS_ERROR" to "error",
            // Quantization
            "ORG" to "ORG",
            "F16" to "F16",
            "BF16" to "BF16",
            "Q8_0" to "Q8_0",
            "Q6_K" to "Q6_K",
            "Q4_K_M" to "Q4_K_M",
            "Q3_K" to "Q3_K",
            "Q2_K" to "Q2_K",
            // Target
            "LLAMA_CPP" to "LLAMA_CPP"
        )
    }

    @ReactMethod
    fun getModelStatus(promise: Promise) {
        try {
            val status = Arguments.createMap().apply {
                putBoolean("isLoaded", isModelLoaded)
                putBoolean("hasModel", mlangeModel != null)
                putBoolean("isGenerating", tokenGenerationThread != null && tokenGenerationThread?.isAlive == true)
            }
            promise.resolve(status)
        } catch (e: Exception) {
            promise.reject("GET_STATUS_ERROR", "Failed to get model status: ${e.message}", e)
        }
    }

    @ReactMethod
    fun initModel(personalAccessKey: String, modelKey: String, target: String, quantType: String, promise: Promise) {
        // If model is already loaded, return success
        if (mlangeModel != null && isModelLoaded) {
            val result = Arguments.createMap().apply {
                putBoolean("success", true)
                putString("message", "Model already initialized")
                putBoolean("isLoaded", true)
            }
            promise.resolve(result)
            return
        }

        if (personalAccessKey.isEmpty() || modelKey.isEmpty()) {
            promise.reject("INVALID_PARAMETERS", "personalAccessKey and modelKey are required", null)
            return
        }

        val nativeTarget = convertTarget(target)
        val nativeQuantType = convertQuantType(quantType)

        // Return success immediately to indicate initialization started
        val result = Arguments.createMap().apply {
            putBoolean("success", true)
            putString("message", "Model initialization started")
            putBoolean("isLoaded", false)
        }
        promise.resolve(result)

        // Start initialization in background thread
        Thread {
            runCatching {
                val model = ZeticMLangeLLMModel(
                    reactContext,
                    personalAccessKey,
                    modelKey,
                    nativeTarget,
                    nativeQuantType
                ) { progressValue ->
                    // Send progress updates via event channel
                    mainHandler.post {
                        progress = progressValue
                        sendUnifiedEvent(Arguments.createMap().apply {
                            putString("type", "progress")
                            putDouble("progress", progressValue.toDouble())
                            putString("message", "Loading model... ${(progressValue * 100).toInt()}%")
                        })
                    }
                }

                mainHandler.post {
                    mlangeModel = model
                    isModelLoaded = true

                    // Send completion via event channel
                    sendUnifiedEvent(Arguments.createMap().apply {
                        putString("type", "initialized")
                        putBoolean("success", true)
                        putString("message", "Model initialized successfully")
                        putString("modelKey", modelKey)
                        putString("target", target)
                        putString("quantType", quantType)
                    })
                }

            }.onFailure { e ->
                mainHandler.post {
                    sendErrorEvent(Arguments.createMap().apply {
                        putString("type", "error")
                        putBoolean("success", false)
                        putString("message", "Failed to initialize model: ${e.message}")
                        putString("error", e.message ?: "Unknown error")
                    })
                }
            }
        }.start()
    }

    @ReactMethod
    fun generateResponse(prompt: String, options: ReadableMap, promise: Promise) {
        val model = mlangeModel
        if (model == null || !isModelLoaded) {
            promise.reject("MODEL_NOT_INITIALIZED", "Model not initialized", null)
            return
        }

        if (prompt.isEmpty()) {
            promise.reject("INVALID_PROMPT", "Prompt cannot be empty", null)
            return
        }

        // Stop any existing generation
        tokenGenerationThread?.interrupt()
        tokenGenerationThread = null

        // Send success response immediately
        val result = Arguments.createMap().apply {
            putBoolean("success", true)
            putString("message", "Generation started")
            putString("prompt", prompt)
        }
        promise.resolve(result)

        // Start token generation thread
        tokenGenerationThread = Thread {
            try {
                model.run(prompt)

                // Send generation started event
                mainHandler.post {
                    sendUnifiedEvent(Arguments.createMap().apply {
                        putString("type", "started")
                        putString("message", "AI is thinking...")
                    })
                }

                var fullResponse = ""
                var tokenCount = 0

                while (!Thread.currentThread().isInterrupted) {
                    val token = model.waitForNextToken() ?: ""

                    if (token.isEmpty()) {
                        // Generation completed
                        mainHandler.post {
                            if (!Thread.currentThread().isInterrupted) {
                                sendUnifiedEvent(Arguments.createMap().apply {
                                    putString("type", "complete")
                                    putString("fullResponse", fullResponse)
                                    putInt("tokenCount", tokenCount)
                                    putBoolean("finished", true)
                                })
                            }
                        }
                        break
                    }

                    fullResponse += token
                    tokenCount++

                    // Send token update
                    mainHandler.post {
                        if (!Thread.currentThread().isInterrupted) {
                            sendUnifiedEvent(Arguments.createMap().apply {
                                putString("type", "token")
                                putString("token", token)
                                putString("fullResponse", fullResponse)
                                putInt("tokenCount", tokenCount)
                            })
                        }
                    }
                }

            } catch (e: Exception) {
                if (!Thread.currentThread().isInterrupted) {
                    mainHandler.post {
                        sendErrorEvent(Arguments.createMap().apply {
                            putString("type", "error")
                            putString("message", "Generation error: ${e.message}")
                            putString("error", e.message ?: "Unknown error")
                        })
                    }
                }
            }
        }
        tokenGenerationThread?.start()
    }

    @ReactMethod
    fun cancelGeneration(promise: Promise) {
        tokenGenerationThread?.interrupt()
        tokenGenerationThread = null

        // Send cancellation event
        mainHandler.post {
            sendUnifiedEvent(Arguments.createMap().apply {
                putString("type", "cancelled")
                putString("message", "Generation cancelled")
            })
        }

        val result = Arguments.createMap().apply {
            putBoolean("success", true)
            putString("message", "Generation cancelled")
        }
        promise.resolve(result)
    }

    @ReactMethod
    fun dispose(promise: Promise) {
        // Stop any running generation
        tokenGenerationThread?.interrupt()
        tokenGenerationThread = null

        // Clean up model
        mlangeModel = null
        isModelLoaded = false

        val result = Arguments.createMap().apply {
            putBoolean("success", true)
            putString("message", "Model disposed successfully")
        }
        promise.resolve(result)
    }

    private fun convertTarget(targetString: String): LLMTarget {
        return when (targetString.uppercase()) {
            "LLAMA_CPP" -> LLMTarget.LLAMA_CPP
            else -> LLMTarget.LLAMA_CPP
        }
    }

    private fun convertQuantType(quantTypeString: String): LLMQuantType {
        return when (quantTypeString.uppercase()) {
            "ORG" -> LLMQuantType.GGUF_QUANT_ORG
            "F16" -> LLMQuantType.GGUF_QUANT_F16
            "BF16" -> LLMQuantType.GGUF_QUANT_BF16
            "Q8_0" -> LLMQuantType.GGUF_QUANT_Q8_0
            "Q6_K" -> LLMQuantType.GGUF_QUANT_Q6_K
            "Q4_K_M" -> LLMQuantType.GGUF_QUANT_Q4_K_M
            "Q3_K_M" -> LLMQuantType.GGUF_QUANT_Q3_K_M
            "Q2_K" -> LLMQuantType.GGUF_QUANT_Q2_K
            else -> LLMQuantType.GGUF_QUANT_Q6_K
        }
    }

    // Unified event sender for all regular events
    private fun sendUnifiedEvent(body: WritableMap) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("onEvent", body)
    }

    // Dedicated error event sender
    private fun sendErrorEvent(body: WritableMap) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit("onError", body)
    }

    override fun onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy()
        // Stop generation thread when module is destroyed
        tokenGenerationThread?.interrupt()
        tokenGenerationThread = null
    }

    companion object {
        const val NAME = "ZeticLLM"
    }
}