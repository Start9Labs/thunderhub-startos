import { types as T, ok, error, guardDurationAboveMinimum } from '../deps.ts';

const url = 'http://thunderhub.embassy:3000';

export const health: T.ExpectedExports.health = {
  async 'web-ui'(effects, duration) {
    const value = guardDurationAboveMinimum({ duration, minimumTime: 25_000 });
    if (value) {
      return value;
    }
    try {
      await effects.fetch(url);
      return ok;
    } catch(e) {
      console.warn(e);
      return error('Can not reach service');
    }
  },
};
