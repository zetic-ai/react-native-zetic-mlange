package com.zetic

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.Arguments
import java.util.concurrent.ConcurrentHashMap
import com.zeticai.mlange.core.error.ZeticMLangeException
import com.zeticai.mlange.core.model.ZeticMLangeModel
import java.nio.ByteBuffer


class ZeticRNModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName() = NAME

  private val modelMap = ConcurrentHashMap<String, ZeticMLangeModel>()

  @ReactMethod
  fun create(instanceId: String, mlangePersonalKey: String, mlnageModelKey: String, promise: Promise) { 
    Thread {
        try {
            if (!modelMap.containsKey(instanceId)) {
                val model = ZeticMLangeModel(reactApplicationContext, mlangePersonalKey, mlnageModelKey)
                modelMap[instanceId] = model
            }
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("CREATE_FAILED", e.message, e)
        }
    }.start()
  }

  @ReactMethod
  fun run(instanceId: String, inputs: ReadableArray, promise: Promise) {
    Thread {
        val model = modelMap[instanceId] ?: throw Exception("Model not found for instanceId: $instanceId")
        try {
            val inputBuffers = Array(inputs.size()) { i ->
                val byteArrayInput = inputs.getArray(i)
                    ?: throw IllegalArgumentException("Input at index $i is not a valid array")

                val byteArray = ByteArray(byteArrayInput.size())
                for (j in 0 until byteArrayInput.size()) {
                    val intValue = byteArrayInput.getInt(j)
                    byteArray[j] = intValue.toByte()
                }

                ByteBuffer.wrap(byteArray)
            }
            model.run(inputBuffers)
            val outputBuffers: Array<ByteBuffer> = model.outputBuffers

            val outputArray: WritableArray = Arguments.createArray()
            for (buffer in outputBuffers) {
                buffer.rewind()
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)

                val innerArray = Arguments.createArray()
                bytes.forEach { byte ->
                    innerArray.pushInt(byte.toInt() and 0xFF) // Convert to unsigned
                }

                outputArray.pushArray(innerArray)
            }

            promise.resolve(outputArray)
        } catch (e: ZeticMLangeException) {
            promise.reject(
                "RUN_ERROR",
                e.message,
                null
            )
        }
    }.start()
  }

  @ReactMethod
  fun destroy(instanceId: String, promise: Promise) {
    Thread {
        try {
            modelMap.remove(instanceId)
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("DEINIT_FAILED", e.message, e)
        }
    }.start()
  }

  companion object {
    const val NAME = "Zetic"
  }
}
