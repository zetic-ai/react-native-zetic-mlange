import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-zetic' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';


let instanceId: string | null = null;

const ZeticLibrary = NativeModules.Zetic
  ? NativeModules.Zetic
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function create(instanceId: string,
  personalKey: string,
  modelKey: string): Promise<string> {
    return ZeticLibrary.create(instanceId, personalKey, modelKey);
}

export async function run(instanceId: string, inputs: any[]): Promise<unknown> {
  const data = await ZeticLibrary.run(instanceId, inputs);
  return data;
}

export function deinit(instanceId: string): Promise<null> {
  return ZeticLibrary.destroy(instanceId);
}

const ZeticModel = {
  async create(
    mlangePersonalToken: string,
    mlangeModelKey: string
  ) {
    if (!instanceId) {
      instanceId = String(Date.now());
    }
    return ZeticLibrary.create(instanceId, mlangePersonalToken, mlangeModelKey);
  },
  async run(inputs: any[]) {
    if (!instanceId) {
      throw Error(`Can not find instanceId ${instanceId}`);
    }
    return ZeticLibrary.run(instanceId, inputs);
  },
  async dispose() {
    if (!instanceId) {
      throw Error(`Can not find instanceId ${instanceId}`);
    }
    await ZeticLibrary.deinit(instanceId);
    instanceId = null;
    return null;
  },
}

export default ZeticModel;
