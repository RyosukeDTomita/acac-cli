# ACAC

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ABOUT

AtCoderの直近のAC数とACした問題をCLIから確認するため[Haskell](https://www.haskell.org/)製CLIツール。

[ccusage](https://ccusage.com/)にインスピレーションを受けて開発しました。

---

## HOW TO USE

npm(`npx`)で実行できる。引数に AtCoder のユーザ名を1つ渡す。

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

直近の AC 履歴を週ごとのテーブルで表示する。現状の配布対象は linux-x64 のみ。

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

```shell
git tag v0.1.0
git push origin v0.1.0
```

