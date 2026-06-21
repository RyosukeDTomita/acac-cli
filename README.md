# ACAC-CLI

[![test](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/test.yml/badge.svg)](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/test.yml)
[![release](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/release.yml/badge.svg)](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[(日本語READMEはこちら)](README.ja.md)

## ABOUT

A CLI tool written in [Haskell](https://www.haskell.org/) for checking your recent AtCoder AC count and the problems you solved, from the command line.

Inspired by [ccusage](https://ccusage.com/).

It uses the [AtCoder Problems API](https://github.com/kenkoooo/AtCoderProblems/blob/main/doc/api.md) to fetch the AC history.

---

## HOW TO USE

### linux-x64

```shell
npx acac-cli <atcoder-username>
┌──────────────────┬────┬───────────────────────────────────────────────────┐
│ Date             │ AC │ Problems                                          │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-05-26 (Tue) │ 2  │ abc081B abc290A                                   │
│ 2026-05-29 (Fri) │ 1  │ abc342C                                           │
│ 2026-05-30 (Sat) │ 6  │ abc460A abc460B abc460C abc460D awc0001A awc0001B │
│ 2026-05-31 (Sun) │ 1  │ abc460C                                           │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 10 │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-06-01 (Mon) │ 1  │ abc460D                                           │
│ 2026-06-06 (Sat) │ 3  │ abc461A abc461B abc461C                           │
│ 2026-06-07 (Sun) │ 1  │ abc461C                                           │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 5  │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-06-08 (Mon) │ 1  │ abc144B                                           │
│ 2026-06-09 (Tue) │ 5  │ abc106B abc120B abc122B abc136B abc150B           │
│ 2026-06-10 (Wed) │ 1  │ abc057C                                           │
│ 2026-06-11 (Thu) │ 1  │ abc095A                                           │
│ 2026-06-12 (Fri) │ 1  │ sumitrust2019D                                    │
│ 2026-06-13 (Sat) │ 3  │ abc462A abc462B abc462C                           │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 12 │                                                   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ 2026-06-15 (Mon) │ 5  │ APG4bA APG4bPythonA abc128C abc462B abc462D       │
│ 2026-06-17 (Wed) │ 3  │ abc145C abc147C abc150C                           │
│ 2026-06-18 (Thu) │ 2  │ abc054C abc448B                                   │
│ 2026-06-19 (Fri) │ 5  │ abc054C abc245B abc273A abc425B awc0001B          │
│ 2026-06-20 (Sat) │ 6  │ abc029C abc153D abc247C abc463A abc463B abc463C   │
├──────────────────┼────┼───────────────────────────────────────────────────┤
│ week total       │ 21 │                                                   │
└──────────────────┴────┴───────────────────────────────────────────────────┘
```

It displays your recent AC history as a weekly table.

### Others

WIP

See [For Developer Memo](#for-developer-memo) to set it up.

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
 runghc -isrc -iapp app/Main.hs HathawayNoa
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

Pushing a `v*.*.*` tag triggers artifact upload to a GitHub Release and npm publish (`.github/workflows/release.yml`).

The CI **fetches the distributable musl static binary from Cachix (`acac`)** (because building from source takes around 60 minutes and times out). Therefore, **before cutting a tag, you must seed the current static build to Cachix.**

#### 1. Seed the static build to Cachix

```shell
# Set the token only the first time (not needed afterwards)
cachix authtoken <CACHIX_AUTH_TOKEN>

nix build .#static
cachix push acac ./result
```

Check (200 means the CI will hit the cache; 404 means it is not seeded, so push it):

```shell
hash=$(basename "$(readlink -f result)" | cut -d- -f1)
curl -s -o /dev/null -w "%{http_code}\n" "https://acac.cachix.org/$hash.narinfo"
```

##### When you need to re-seed

Only when the `.#static` derivation changes. Specifically, when you change the following:

- `src/`, `app/`, `test/`, `acac.cabal` (= the cabal package source)
- `flake.lock` (dependency updates)
- the parts of `flake.nix` that **affect `.#static`** (dependencies, `fileset`, GHC version, `pkgsStatic` config, etc.)

Conversely, changes to only README, docs, npm, or the devShell/comments in `flake.nix` do not require re-seeding (the `callCabal2nix` source is narrowed to `src/app/test/acac.cabal` via `fileset`). When in doubt, if the narinfo check above returns 404, push — that is reliable.

#### 2. Cut a tag and push

```shell
git tag v0.1.0
git push origin v0.1.0
```
