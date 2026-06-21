# ACAC-CLI

[![test](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/test.yml/badge.svg)](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/test.yml)
[![release](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/release.yml/badge.svg)](https://github.com/RyosukeDTomita/acac-cli/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ABOUT

AtCoderの直近のAC数とACした問題をCLIから確認するため[Haskell](https://www.haskell.org/)製CLIツール。

[ccusage](https://ccusage.com/)にインスピレーションを受けて開発しました。

AC履歴の取得には [AtCoder Problems API](https://github.com/kenkoooo/AtCoderProblems/blob/main/doc/api.md) を利用しています。

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

直近の AC 履歴を週ごとのテーブルで表示する。

### Others

WIP

[For Developer Memo](#for-developer-memo)を見てセットアップされたし。

---

## For Developer Memo

### Initial Set Up

```shell
nix develop
```

### run locally

`nix develop` のシェル内で cabal から実行する。

```shell
cabal run acac -- <atcoder-username>
```

```shell
# デバックならrunghcの方が気楽かも
 runghc -isrc -iapp app/Main.hs HathawayNoa
```

flake から直接実行することもできる。

```shell
nix run . -- <atcoder-username>
```

### run test

```shell
runghc -isrc test/Spec.hs
```

### formatter

treefmt(ormolu / nixfmt / mdformat)でまとめて整形する。

```shell
nix fmt
```

### Release

`v*.*.*` タグを push すると、GitHub Release への成果物アップロードと npm publish が走る(`.github/workflows/release.yml`)。

CI は配布用の musl 静的バイナリを **Cachix(`acac`)から取得**する(ソースからの再ビルドは
60分級でタイムアウトするため)。なので **タグを切る前に、現在の静的ビルドを Cachix へ
seed しておく**必要がある。

#### 1. Cachix に静的ビルドを seed する

```shell
# 初回のみ token を設定(以降は不要)
cachix authtoken <CACHIX_AUTH_TOKEN>

nix build .#static
cachix push acac ./result
```

確認(200 なら CI がヒットする。404 なら未 seed なので push する):

```shell
hash=$(basename "$(readlink -f result)" | cut -d- -f1)
curl -s -o /dev/null -w "%{http_code}\n" "https://acac.cachix.org/$hash.narinfo"
```

##### いつ seed し直す必要があるか

`.#static` の derivation が変わった時だけ。具体的には次を変更した場合:

- `src/`・`app/`・`test/`・`acac.cabal`(= cabal パッケージのソース)
- `flake.lock`(依存の更新)
- `flake.nix` のうち **`.#static` に影響する部分**(依存・`fileset`・ghc バージョン・`pkgsStatic` 設定など)

逆に **README・docs・npm・`flake.nix` の devShell やコメントだけ**の変更では seed し直し不要
(`callCabal2nix` のソースを `fileset` で `src/app/test/acac.cabal` に絞っているため)。
判断に迷ったら、上の narinfo 確認で 404 なら push、で確実。

#### 2. タグを切って push する

```shell
git tag v0.1.0
git push origin v0.1.0
```
