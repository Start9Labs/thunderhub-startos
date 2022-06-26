import { ExpectedExports, Config, matches } from "../deps.ts";

const { shape, arrayOf, string, boolean } = matches;

const matchLndConfig = shape({

});

function times<T>(fn: (i: number) => T, amount: number): T[] {
  const answer = new Array(amount);
  for (let i = 0; i < amount; i++) {
    answer[i] = fn(i);
  }
  return answer;
}

function randomItemString(input: string) {
  return input[Math.floor(Math.random() * input.length)];
}

const serviceName = "thunderhub";
const fullChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
type Check = {
  currentError(config: Config): string | void;
  fix(config: Config): void;
};

export const dependencies: ExpectedExports.dependencies = {
    lnd: {
        async check(effects, configInput) {
            effects.info("check bitcoind");
            const config = matchLndConfig.unsafeCast(configInput);
            return { result: null };
        },
        async autoConfigure(effects, configInput) {
            effects.info("autoconfigure bitcoind");
            const config = matchLndConfig.unsafeCast(configInput);
            return { result: config };
        },
    },
};