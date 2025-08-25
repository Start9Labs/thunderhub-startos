import { setupManifest } from '@start9labs/start-sdk'
import { SDKImageInputSpec } from '@start9labs/start-sdk/base/lib/types/ManifestTypes'

const BUILD = process.env.BUILD || ''

const architectures =
  BUILD === 'x86_64' || BUILD === 'aarch64' ? [BUILD] : ['x86_64', 'aarch64']

export const manifest = setupManifest({
  id: 'thunderhub',
  title: 'ThunderHub',
  license: 'MIT',
  wrapperRepo: 'https://github.com/Start9Labs/thunderhub-wrapper',
  upstreamRepo: 'https://github.com/apotdevin/thunderhub',
  supportSite: 'https://github.com/apotdevin/thunderhub/issues',
  marketingSite: 'https://www.thunderhub.io/',
  donationUrl: null,
  docsUrl:
    'https://github.com/Start9Labs/thunderhub-startos/blob/master/instructions.md',
  description: {
    short: 'LND Lightning Node Manager in your Browser',
    long: 'ThunderHub is an open-source LND node manager where you can manage and monitor your node on any device or browser. It allows you to take control of the lightning network with a simple and intuitive UX and the most up-to-date tech stack.',
  },
  volumes: ['main'],
  images: {
    thunderhub: {
      source: { dockerTag: 'apotdevin/thunderhub:v0.13.32' },
      arch: architectures,
    } as SDKImageInputSpec,
  },
  hardwareRequirements: {
    arch: architectures,
  },
  alerts: {
    install: 'Optional alert to display before installing the service',
    update: null,
    uninstall: null,
    restore: null,
    start: null,
    stop: null,
  },
  dependencies: {},
})
