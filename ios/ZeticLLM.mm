#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(ZeticLLM, RCTEventEmitter)

// Constants
RCT_EXTERN_METHOD(constantsToExport)

// Model Management
RCT_EXTERN_METHOD(initModel:(NSString *)personalAccessKey
                 modelKey:(NSString *)modelKey
                 target:(NSString *)target
                 quantType:(NSString *)quantType
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getModelStatus:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(dispose:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

// Generation
RCT_EXTERN_METHOD(generateResponse:(NSString *)prompt
                 options:(NSDictionary *)options
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(cancelGeneration:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)

// Event Support
RCT_EXTERN_METHOD(supportedEvents)

// Required for RCTEventEmitter
+ (BOOL)requiresMainQueueSetup {
    return NO;
}

@end
