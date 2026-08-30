# ThunderHub

## Documentation

- [Start9 Bitcoin Guides](https://docs.start9.com/bitcoin-guides/) — connecting wallets and dashboards to a Lightning node on StartOS.
- [ThunderHub upstream README](https://github.com/apotdevin/thunderhub#readme) — the project README, covering features and general usage of ThunderHub.

## What you get on StartOS

- A **Web UI** for managing and monitoring your Lightning node — channels, payments, routing, balances, forwarding reports, and the rest of ThunderHub's dashboards.
- A **pre-configured connection to your local LND** node. ThunderHub picks up LND's admin macaroon and TLS certificate automatically; you do not configure a node, paste a macaroon, or upload a cert.
- A **single master password** that gates the web UI, generated and rotated through a StartOS action rather than edited into a config file by hand.

## Getting set up

ThunderHub depends on LND. Install LND first and let it finish syncing before you try to use ThunderHub.

1. After install, ThunderHub posts a critical task to create your master password. Run the **Create Master Password** action. A random password is generated and shown once — copy it to a password manager before dismissing the result.
2. Start the service and open the **Web UI** interface.
3. Log in with the master password from step 1.

## Using ThunderHub

### Web UI

The **Web UI** opens directly to ThunderHub's login screen. Enter the master password to reach the dashboard, where you manage channels, send and receive payments, view routing and forwarding reports, and use the rest of ThunderHub's LND-management features.

### Actions

- **Create Master Password** / **Reset Master Password** — generates a new random master password for the web UI and shows it once. The action is named "Create" on first run and "Reset" on every run after that; use Reset to rotate the password or recover access if you've lost it.
