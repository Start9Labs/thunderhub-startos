import { VersionGraph } from '@start9labs/start-sdk'
import { current, other } from './versions'
import { configYaml } from '../fileModels/config.yml'
import { store } from '../fileModels/store.json'
import { getSecretPhrase } from '../utils'

export const versionGraph = VersionGraph.of({
  current,
  other,
  preInstall: async (effects) => {
    const name = 'World'

    await Promise.all([
      configYaml.write(effects, { name }),
      store.write(effects, {
        secretPhrase: getSecretPhrase(name),
        nameLastUpdatedAt: null,
      }),
    ])
  },
})
