import { setupManifest } from '@start9labs/start-sdk'
import { long, short } from './i18n'

export const manifest = setupManifest({
  id: 'thunderhub',
  title: 'ThunderHub',
  license: 'MIT',
  packageRepo: 'https://github.com/Start9Labs/thunderhub-startos',
  upstreamRepo: 'https://github.com/apotdevin/thunderhub',
  marketingUrl: 'https://www.thunderhub.io/',
  donationUrl: null,
  description: { short, long },
  volumes: ['main'],
  images: {
    thunderhub: {
      source: { dockerTag: 'apotdevin/thunderhub:0.19.1' },
      arch: ['x86_64', 'aarch64'],
      emulateMissing: false,
    },
  },
})
