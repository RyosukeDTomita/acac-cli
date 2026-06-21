# ACAC

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ABOUT

AtCoderの直近のAC数とACした問題をCLIから確認するため[Haskell](https://www.haskell.org/)製CLIツール。

[ccusage](https://ccusage.com/)にインスピレーションを受けて開発しました。

---

## HOW TO USE

npm(`npx`)で実行できる。引数に AtCoder のユーザ名を1つ渡す。

```shell
npx @sigma1881/acac <atcoder-username>
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

flake から直接実行することもできる。

```shell
nix run . -- <atcoder-username>
```

### run test

```shell
nix develop --command runghc -isrc test/Spec.hs
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

