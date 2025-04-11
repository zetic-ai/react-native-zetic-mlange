#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(Zetic, NSObject)

RCT_EXTERN_METHOD(create:(NSString *)instanceId
                 personalKey:(NSString *)personalKey
                 modelKey:(NSString *)modelKey
                 withResolve:(RCTPromiseResolveBlock)resolve
                 withReject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(run:(NSString *)instanceId
                 inputs:(NSArray *)inputs
                 withResolve:(RCTPromiseResolveBlock)resolve
                 withReject:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(destroy:(NSString *)instanceId
                 withResolve:(RCTPromiseResolveBlock)resolve
                 withReject:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
