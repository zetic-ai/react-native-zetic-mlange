import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-sample-rn-library' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';


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

export async function run(instanceId: string, inputs: any[][], callback?: (data: unknown) => void): Promise<unknown> {
  const data = await ZeticLibrary.run(instanceId, inputs);
  return data;
}

export function deinit(instanceId: string): Promise<null> {
  return ZeticLibrary.destroy(instanceId);
}
