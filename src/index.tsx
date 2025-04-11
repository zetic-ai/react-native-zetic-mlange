import * as NativeZetic from './NativeZetic';

let instanceId: string | null = null;

function create(
  mlangePersonalToken: string,
  mlangeModelKey: string
) {
  if (!instanceId) {
    instanceId = String(Date.now());
  }
  return NativeZetic.create(instanceId, mlangePersonalToken, mlangeModelKey);
}

function run(inputs: any[][], callback?: (data: unknown) => void) {
  if (!instanceId) {
    throw Error(`Can not find instanceId ${instanceId}`);
  }
  return NativeZetic.run(instanceId, inputs, callback);
}

async function deinit() {
  if (!instanceId) {
    throw Error(`Can not find instanceId ${instanceId}`);
  }
  await NativeZetic.deinit(instanceId);
  instanceId = null;
  return null;
}

export const Zetic = {
  create,
  run,
  deinit,
};

export default Zetic;
