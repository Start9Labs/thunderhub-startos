<p align="center">
  <img src="icon.png" alt="ThunderHub Logo" width="21%">
</p>

# ThunderHub on StartOS

> Everything not listed in this document should behave the same as upstream
> ThunderHub. If a feature, setting, or behavior is not mentioned here, the
> upstream documentation is accurate and fully applicable — see the
> Documentation section of `instructions.md` for links.

[ThunderHub](https://github.com/apotdevin/thunderhub) is a web dashboard for an LND node: channels, payments, forwards, fees, and the tools to manage them. This package runs it against the LND on the same server, with the node account configured for you.

- **Upstream repo:** <https://github.com/apotdevin/thunderhub>
- **Wrapper repo:** <https://github.com/Start9Labs/thunderhub-startos>

---

## Table of Contents

- [Image and Container Runtime](#image-and-container-runtime)
- [Volume and Data Layout](#volume-and-data-layout)
- [File Models](#file-models)
- [Dependencies](#dependencies)
- [Network Access and Interfaces](#network-access-and-interfaces)
- [Installation and First-Run Flow](#installation-and-first-run-flow)
- [Actions](#actions)
- [Tasks](#tasks)
- [Health Checks](#health-checks)
- [Backups and Restore](#backups-and-restore)
- [Limitations and Differences](#limitations-and-differences)
- [Quick Reference for AI Consumers](#quick-reference-for-ai-consumers)

---

## Image and Container Runtime

One upstream image, consumed unmodified.

| Property      | Value                      |
| ------------- | -------------------------- |
| Image         | `apotdevin/thunderhub`     |
| Architectures | x86_64, aarch64            |
| Command       | The image's own entrypoint |

| Subcontainer     | Purpose                                  |
| ---------------- | ---------------------------------------- |
| `thunderhub-sub` | The only daemon — the one to `attach` to |

**The daemon is run as root, overriding the image's own user**, and there are two concrete reasons: it has to write its accounts file to persist the hashed password, and it has to read LND's admin macaroon, which LND writes as root on the dependency mount.

## Volume and Data Layout

One volume, plus a read-only view of LND's.

| Volume                    | Mount Point | Purpose                                             |
| ------------------------- | ----------- | --------------------------------------------------- |
| `main`                    | `/data`     | The accounts file                                   |
| LND's `public/admin` (ro) | `/mnt/lnd`  | LND's `tls.cert` and `admin.macaroon`, nothing else |

| Path            | Written by                         | Holds                                   |
| --------------- | ---------------------------------- | --------------------------------------- |
| `accounts.yaml` | `main`, the action, and ThunderHub | The login password and the node account |

**There is very little state here.** ThunderHub is a view onto LND: channels, balances and history all live in the node, so this volume holds the account definition and the login credential and nothing else.

**LND's credentials are read straight off the dependency mount**, not copied — so a rotated certificate is picked up without any copy step going stale.

## File Models

One model, and it is co-owned.

| File            | Format | Modelled                | Written by                                |
| --------------- | ------ | ----------------------- | ----------------------------------------- |
| `accounts.yaml` | YAML   | Yes — `FileHelper.yaml` | `main`, the action, and ThunderHub itself |

Two fields matter:

- **The master password**, which is the login. ThunderHub replaces the plaintext value with a hash of it once it has read it, which is why the application counts as a writer of this file.
- **The node account**, whose certificate and macaroon paths are `z.literal(...).catch(...)` — **repaired on read**, because they can only ever be the mount points of the LND dependency.

**LND's gRPC address is resolved at start and written in**, over the internal bridge, where LND's own TLS is terminated. **While it is unresolved the field is left absent** rather than filled with a placeholder, so ThunderHub does not dial a dead port.

That absence is the normal state on a fresh install, and it heals by itself: **LND publishes its gRPC binding only once its wallet has first been unlocked**, and the reactive read restarts ThunderHub with the real address as soon as it appears. Uninstalling LND propagates the same way — the field is dropped rather than left stale.

## Dependencies

One, and it is required.

| Dependency | Required | Health checks required | Mounted                                 | Why             |
| ---------- | -------- | ---------------------- | --------------------------------------- | --------------- |
| LND        | Yes      | `lnd`                  | `public/admin`, read-only at `/mnt/lnd` | The node itself |

**This package uses LND's admin macaroon.** ThunderHub opens and closes channels, pays invoices, and changes fee policy — so access to this service is operational control of your node and the ability to move funds.

## Network Access and Interfaces

One interface.

| Interface | Id   | Type | Port | Description              |
| --------- | ---- | ---- | ---- | ------------------------ |
| Web UI    | `ui` | ui   | 3000 | The ThunderHub dashboard |

Bound on the `ui-multi` MultiHost over HTTP and not masked. **ThunderHub's own master password gates it**, and StartOS adds no gate of its own.

Given what the macaroon allows, treat that password as a wallet credential rather than a dashboard login.

The StartOS 0.3.5 package's `main` host is retired on update, so its port is freed. None of its addresses are carried over to `ui-multi`.

## Installation and First-Run Flow

Install seeds the accounts file and raises a `critical` task: create the master password.

**The service cannot start until it exists**, so there is no window in which a dashboard with spending authority is reachable without a credential.

**LND must be running, and its wallet unlocked at least once**, before ThunderHub can connect. Installed before LND is fine — the address is filled in and the service restarts on its own when the binding appears.

Version checking against upstream is turned off by the package, so the interface does not nag about a version the package controls.

## Actions

One action.

### Create Master Password

Generates the login password and shows it once. The name changes to **Reset Master Password** once one exists.

- **What it changes:** the password in the accounts file.
- **When it takes effect:** immediately. ThunderHub reads the accounts file only at startup, so the action restarts it if it is running.
- **Repeat safety:** each run generates a **new** password and invalidates the old one. It is never user-chosen.
- **Confirmation:** when a password already exists, StartOS shows a warning and asks before replacing it. The first run, from the install task, does not prompt.
- **Runnable at any status**, including stopped — which is how the install-time task is completed.

**The stored value is replaced by a hash** the first time ThunderHub reads it, so it cannot be recovered from the file afterwards. Save it when it is shown.

## Tasks

One, and it is reactive.

| Task                   | Severity   | Raised when                     | Cleared when    |
| ---------------------- | ---------- | ------------------------------- | --------------- |
| Create Master Password | `critical` | Any init that finds no password | The action runs |

`critical` blocks the service from starting and suspends the ordinary controls, so a fresh install shows the task and nothing else.

## Health Checks

One check, on the only daemon.

| Check     | Displayed as    | Method                 |
| --------- | --------------- | ---------------------- |
| `primary` | "Web Interface" | Port 3000 is listening |

It reports that the dashboard is serving. **It says nothing about LND**: an unresolved address, a locked wallet, or a node that stopped answering all show a green check and an error inside the interface.

## Backups and Restore

The `main` volume is copied wholesale — `sdk.Backups.ofVolumes('main')`. In practice that is one file: the accounts definition and the hashed login password.

**Nothing here is a wallet.** The macaroon and the certificate belong to LND and are read from its mount, not copied — so this backup grants no access on its own.

A restored instance comes back with the same login and re-resolves LND's address on the new server. It needs LND present and unlocked before it shows anything.

## Limitations and Differences

1. **The admin macaroon is required**, so access to this dashboard is spending control of your node.
2. **One node, one account.** The package configures a single LND account and pins its credential paths.
3. **The password can be reset but not chosen**, and it is stored hashed after first use.
4. **A locked LND means an empty dashboard.** The gRPC binding does not exist until the wallet has been unlocked once.
5. **The daemon runs as root**, overriding the image's user, to write its accounts file and read the macaroon.
6. **Mainnet only.** The macaroon is the one LND publishes in its `admin` tier, which is its Bitcoin mainnet macaroon.
7. **Upstream version checking is disabled.**

---

## Quick Reference for AI Consumers

```yaml
package_id: thunderhub
image: apotdevin/thunderhub
architectures:
  - x86_64
  - aarch64
subcontainers:
  - thunderhub-sub # runs as root, overriding the image's node user
volumes:
  main: /data # accounts.yaml only; LND's public/admin is read-only at /mnt/lnd
file_models:
  - accounts.yaml # masterPassword + the LND account; co-owned with the app
startos_managed_env_vars:
  - ACCOUNT_CONFIG_PATH
  - PORT
  - NO_VERSION_CHECK
dependencies:
  - lnd # required, kind: running, healthChecks: [lnd], admin macaroon via a read-only mount
interfaces:
  ui: { type: ui, port: 3000 } # ThunderHub's own master password; no gate added by StartOS
actions:
  - master-password # name flips between Create and Reset
tasks:
  - { action: master-password, severity: critical } # reactive
health_checks:
  - primary # displayed "Web Interface"; says nothing about LND
```
