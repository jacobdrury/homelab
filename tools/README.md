# Homelab tools (Rust)

Cargo workspace for in-cluster / operator helpers built with [moon](https://moonrepo.dev) + [proto](https://moonrepo.dev/docs/proto).

Toolchain pin: root [`.prototools`](../.prototools) (`rust`) and [`.moon/toolchains.yml`](../.moon/toolchains.yml). Shared tasks: [`.moon/tasks/rust.yml`](../.moon/tasks/rust.yml) (tag `rust`).

## Add a crate

```bash
cd tools
cargo new --bin pihole-sync
```

Then:

1. Add `"pihole-sync"` to `members` in this `Cargo.toml`.
2. Add `tools/pihole-sync/moon.yml` (copy pattern below).
3. `moon run pihole-sync:check`

```yaml
# tools/<crate>/moon.yml
id: 'pihole-sync'
language: 'rust'
layer: 'application'
stack: 'backend'
tags:
  - rust

project:
  name: 'pihole-sync'
  description: 'Pi-hole policy sync sidecar'
```

## Common tasks

```bash
proto install          # rustc / cargo via rustup (pinned)
moon run <crate>:check
moon run <crate>:test
moon run <crate>:clippy
moon run <crate>:fmt
moon run <crate>:build
```
