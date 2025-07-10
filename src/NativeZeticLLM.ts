import {
  EmitterSubscription,
  NativeEventEmitter,
  NativeModules,
  Platform,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-zetic' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const ZeticLibrary = NativeModules.ZeticLLM
  ? NativeModules.ZeticLLM
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

const subscriptions: EmitterSubscription[] = [];
let emitter: NativeEventEmitter | null = null;

type EventBody =
  | { type: 'progress'; progress: number; message: string }
  | {
      type: 'initialized';
      success: boolean;
      message: string;
      modelKey: string;
      target: string;
      quantType: string;
    }
  | { type: 'error'; message: string; error: string }
  | { type: 'started'; message: string }
  | {
      type: 'complete';
      fullResponse: string;
      tokenCount: string;
      finished: boolean;
    }
  | { type: 'token'; token: string; fullResponse: string; tokenCount: number }
  | { type: 'cancelled'; message: string };
const ZeticLLM = {
  async init(
    mlangePersonalToken: string,
    mlangeModelKey: string,
    target: keyof typeof ZeticLLMTarget,
    quantType: keyof typeof ZeticQuantType
  ) {
    return ZeticLibrary.initModel(
      mlangePersonalToken,
      mlangeModelKey,
      target,
      quantType
    );
  },
  async run(input: string, options = {}) {
    return ZeticLibrary.generateResponse(input, options);
  },
  async stop() {
    return ZeticLibrary.cancelGeneration(); // Fixed: was cancelResponse
  },
  async getModelStatus(): Promise<{
    isLoaded: boolean;
    hasModel: boolean;
    isGenerating: boolean;
  }> {
    return ZeticLibrary.getModelStatus();
  },
  async dispose() {
    await ZeticLibrary.dispose();
    return null;
  },
  addListener(
    callback: (
      type: 'event' | 'error',
      e: EventBody,
    ) => void
  ) {
    emitter = new NativeEventEmitter(ZeticLibrary);
    const newSubscriptions = [
      emitter.addListener('onEvent', (e) => callback('event', e)),
      emitter.addListener('onError', (e) => callback('error', e)),
    ];
    subscriptions.push(...newSubscriptions);
  },
  removeListener() {
    if (subscriptions.length > 0) {
      while (true) {
        const listener = subscriptions.pop();
        if (!listener) break;
        listener.remove();
      }
    }
    const eventTypes = [
      'onEvent',
      'onError',
    ];
    eventTypes.forEach((evetType) => {
      emitter?.removeAllListeners(evetType);
    });
  },
};

export const ZeticQuantType = Object.freeze({
  ORG: 'ORG',
  F16: 'F16',
  BF16: 'BF16',
  Q8_0: 'Q8_0',
  Q6_K: 'Q6_K',
  Q4_K_M: 'Q4_K_M',
  Q3_K: 'Q3_K',
  Q2_K: 'Q2_K',
});

export const ZeticLLMTarget = Object.freeze({
  LLAMA_CPP: 'LLAMA_CPP',
});

export default ZeticLLM;
