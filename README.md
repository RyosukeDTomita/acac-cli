![acac-cli](https://github.com/RyosukeDTomita/acac-cli/blob/main/assets/header.png)

[![test](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/test.yml/badge.svg)](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/test.yml)
[![release](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/release.yml/badge.svg)](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/release.yml)
[![npm downloads](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/RyosukeDTomita/acac-cli/badges/downloads.json)](https://www.npmjs.com/package/acac-cli)
[![Socket score](https://socket.dev/api/badge/npm/package/acac-cli)](https://socket.dev/npm/package/acac-cli)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/RyosukeDTomita/acac-cli/badge)](https://scorecard.dev/viewer/?uri=github.com/RyosukeDTomita/acac-cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[(日本語READMEはこちら)](README.ja.md)

## ABOUT

A CLI tool written in [Haskell](https://www.haskell.org/) for checking your recent [AtCoder](https://atcoder.jp/) AC count and the problems you solved, from the command line.

Inspired by [ccusage](https://ccusage.com/).

It uses the [AtCoder Problems API](https://github.com/kenkoooo/AtCoderProblems/blob/main/doc/api.md) to fetch the AC history.

---

## Star History

<a href="https://www.star-history.com/?repos=RyosukeDTomita%2Facac-cli&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=RyosukeDTomita/acac-cli&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=RyosukeDTomita/acac-cli&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=RyosukeDTomita/acac-cli&type=date&legend=top-left" />
 </picture>
</a>

---

## HOW TO USE

```shell
npx acac-cli <atcoder-username>
┌──────────────────┬────┬───────────────────────────────────────────────────┐
│ Date             │ AC │ Problems                                          │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-05-26 (Tue) │ 2  │ abc081B abc290A                                   │
│ 2026-05-29 (Fri) │ 1  │ abc342C                                           │
│ 2026-05-30 (Sat) │ 6  │ abc460A abc460B abc460C abc460D awc0001A awc0001B │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 9  │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-05-31 (Sun) │ 1  │ abc460C                                           │
│ 2026-06-01 (Mon) │ 1  │ abc460D                                           │
│ 2026-06-06 (Sat) │ 3  │ abc461A abc461B abc461C                           │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 5  │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-06-07 (Sun) │ 1  │ abc461C                                           │
│ 2026-06-08 (Mon) │ 1  │ abc144B                                           │
│ 2026-06-09 (Tue) │ 5  │ abc106B abc120B abc122B abc136B abc150B           │
│ 2026-06-10 (Wed) │ 1  │ abc057C                                           │
│ 2026-06-11 (Thu) │ 1  │ abc095A                                           │
│ 2026-06-12 (Fri) │ 1  │ sumitrust2019D                                    │
│ 2026-06-13 (Sat) │ 3  │ abc462A abc462B abc462C                           │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 13 │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-06-15 (Mon) │ 5  │ APG4bA APG4bPythonA abc128C abc462B abc462D       │
│ 2026-06-17 (Wed) │ 3  │ abc145C abc147C abc150C                           │
│ 2026-06-18 (Thu) │ 2  │ abc054C abc448B                                   │
│ 2026-06-19 (Fri) │ 5  │ abc054C abc245B abc273A abc425B awc0001B          │
│ 2026-06-20 (Sat) │ 6  │ abc029C abc153D abc247C abc463A abc463B abc463C   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 21 │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-06-22 (Mon) │ 2  │ abc292B abc350B                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 2  │                                                   │
└──────────────────┴────┴───────────────────────────────────────────────────┘
```

It displays your recent AC history as a weekly table.

### supported

The following binaries are built.

| OS | binary type | Verified on real device |
| ------- | ------------ | ----------------------- |
| Linux | linux-x64 | ✅ |
| Linux | linux-arm64 | |
| macOS | darwin-arm64 | ✅ |
| macOS | darwin-x64 | |
| Windows | win32-x64 | ✅ |

If you have verified acac on a real device other than the ✅ ones, please let us know via an [Issue](https://github.com/RyosukeDTomita/acac/issues).

If you use another environment, we would appreciate a request/PR on an Issue, but you can also set it up by referring to [For Developer Memo](#for-developer-memo).

### Supply chain / build transparency

For supply chain transparency, the distributed artifacts are produced as follows.

- All binaries are built on GitHub Actions from the [acac-cli](https://github.com/RyosukeDTomita/acac-cli) source. Nothing is published from a local machine.
  - Linux (linux-x64 / linux-arm64) is a reproducible musl static build via Nix (`nix build .#static`).
  - macOS / Windows are built on each OS's native runner with GHC 9.12.2 + cabal.
- Publishing to npm is done by CI **with provenance** (`--provenance`, OIDC trusted publishing). Each release can be verified back to the workflow run and commit it came from.
- Releases are cut from `v*.*.*` tags using GitHub **Immutable Releases** (the release is created by the CI bot, not by hand).
- Each GitHub Release binary is **signed with cosign (keyless)** — every `acac-<os>-<arch>` ships an accompanying `.sig` (signature) and `.pem` (certificate), plus a `acac.intoto.jsonl` SLSA **provenance** attestation for the release. This is what OpenSSF Scorecard's `Signed-Releases` checks (Immutable Releases and npm provenance alone do not satisfy it).
- Platform binaries are distributed as `acac-<os>-<arch>` `optionalDependency` packages, so the main package has no runtime dependencies.

---

## For Developer Memo

### Initial Set Up

```shell
nix develop
```

### run locally

Run it from cabal inside the `nix develop` shell.

```shell
cabal run acac -- <atcoder-username>
```

```shell
# runghc may be handier for debugging
runghc -isrc -iapp app/Main.hs <atcoder-username>
```

You can also run it directly from the flake.

```shell
nix run . -- <atcoder-username>
```

### run test

```shell
runghc -isrc test/Spec.hs
```

### formatter

Format everything at once with treefmt (ormolu / nixfmt / mdformat).

```shell
nix fmt
```

### Release

Pushing a `v*.*.*` tag triggers artifact upload to a GitHub Release and npm publish.

#### 1. Configuring GitHub Secrets

- `CACHIX_AUTH_TOKEN`

#### 2. Seed the static build to Cachix

The CI fetches the distributable musl static binary from Cachix (`acac`) (because rebuilding from source takes around 60 minutes and times out).
Therefore, before cutting a tag, you must seed the current static build to Cachix.

```shell
# Set the token only the first time (not needed afterwards)
cachix authtoken <CACHIX_AUTH_TOKEN>

nix build .#static
cachix push acac ./result
```

Run the following; 200 means OK. If it returns 404, it is not seeded, so push it:

```shell
hash=$(basename "$(readlink -f result)" | cut -d- -f1)
curl -s -o /dev/null -w "%{http_code}\n" "https://acac.cachix.org/$hash.narinfo"
```

##### When you need to re-seed

Only when the `.#static` derivation changes. Specifically, when you change the following:

- `src/`, `app/`, `test/`, `acac.cabal` (= the cabal package source)
- `flake.lock` (dependency updates)
- the parts of `flake.nix` that **affect `.#static`** (dependencies, `fileset`, GHC version, `pkgsStatic` config, etc.)

Conversely, changes to only README, docs, npm, or the devShell/comments in `flake.nix` do not require re-seeding
(because the `callCabal2nix` source is narrowed to `src/app/test/acac.cabal` via `fileset`).
When in doubt, if the narinfo check above returns 404, push — that is reliable.

#### 3. Cut a tag and push

```shell
git tag v0.1.0
git push origin v0.1.0
```
