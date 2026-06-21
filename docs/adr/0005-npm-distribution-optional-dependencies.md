---
status: accepted
date: 2026-06-21
decision-makers: "@RyosukeDTomita"
---

# ADR-0005: npm 配布はプラットフォーム別パッケージ(optionalDependencies)方式にする

## Context and Problem Statement

acac は Haskell 製のネイティブバイナリであり、`npx acac <user>` で使えるようにしたい。
ネイティブバイナリを npm 経由で配るには、利用者の OS/arch に合うバイナリを届ける
仕組みが要る。当初は「GitHub Releases にバイナリを置き、`postinstall` で現在の
プラットフォーム向けを download する」方式で実装した。しかし主要ツール
(esbuild / biome / swc / Rust 版 ccusage)は別方式を採っており、どちらに寄せるかを
決める必要がある。

参考: Rust 版 `ccusage` の npm パッケージ(v20 系)は次の構成だった。

```
bin: { "ccusage": "./src/cli.js" }
optionalDependencies:
  @ccusage/ccusage-linux-x64, -darwin-arm64, -linux-arm64, -darwin-x64, -win32-x64, -win32-arm64
postinstall: なし
```

## Decision Drivers

* install 時にネットワーク download を避けたい(プロキシ/オフラインミラー/企業FWで失敗しない)
* npm の整合性チェック・provenance に乗せたい
* 主要ツールと同じ枯れた仕組みにしたい(将来のマルチプラットフォーム化も楽)
* publish の手間は許容範囲に収めたい

## Considered Options

1. optionalDependencies でプラットフォーム別パッケージを配る(ccusage / esbuild 方式)
2. postinstall で GitHub Releases からバイナリを download する(当初実装)
3. バイナリを npm 本体パッケージに同梱する

## Decision Outcome

Chosen option: "1(optionalDependencies 方式)"。

メインパッケージ `acac` は薄い JS シム(`bin/cli.js`)だけを持ち、`optionalDependencies`
にプラットフォーム別パッケージ(まずは `acac-linux-x64`)を同バージョンで宣言する。
プラットフォーム別パッケージは `os`/`cpu` を宣言し、npm が現在の環境に合うものだけを
自動でインストールする(合わないものはスキップ)。`bin/cli.js` は
`require.resolve("acac-<platform>-<arch>/bin/acac")` でバイナリを解決して exec する。
`postinstall` は持たない。

パッケージ名は、当初スコープなし(`acac`)を狙ったが、npm の名前類似ガード
("Package name too similar to existing packages")で `acac` の publish が 403 で拒否された。
スコープ付き(`@user/acac`)なら回避できるが、利用者がスコープを覚えるのが面倒なため、
**素のまま少し長くした `acac-cli`** を採用する(`npx <name>` を素直にしたい意図)。実行される
コマンド名(`bin`)は `acac` のまま。プラットフォーム別パッケージ `acac-linux-x64` は
スコープなしのまま publish できたので据え置く(本体の optionalDependencies からは
`acac-linux-x64` をそのまま参照)。利用は `npx acac-cli <user>` となる。

CI(`release.yml`)は、タグ push 時に musl 静的バイナリをビルドし、(a)プラットフォーム別
パッケージの `bin/acac` に配置 → (b)バージョンをタグに合わせる → (c)プラットフォーム別
パッケージ → メインパッケージの順に publish する。あわせて GitHub Release にも同じ
バイナリを添付する(直接 download 用 / Immutable Releases によるアセット保護)。

### Consequences

* Good: install 時に追加の download が無く、npm の仕組み(checksum / provenance)に乗る
* Good: 企業 FW・オフラインミラー環境でも素直に動く
* Good: マルチプラットフォーム対応は optionalDependencies と publish 対象を増やすだけ
* Good: 主要ツールと同じ構成で、利用者にとっても馴染みがある
* Bad: 1リリースで publish する npm パッケージが増える(linux-x64 のみでも メイン+1個)
* Bad: メインとプラットフォーム別パッケージのバージョン整合を CI で担保する必要がある

### Confirmation

メイン `acac` の `optionalDependencies` に `acac-linux-x64` が同バージョンで入っており、
`bin/cli.js` が当該パッケージの `bin/acac` を `require.resolve` して exec すること、
`release.yml` が両パッケージを publish することで確認する。ローカルでは静的バイナリを
プラットフォーム別パッケージに置き、`node npm/bin/cli.js <user>` で動作確認できる。

## Pros and Cons of the Options

### 1. optionalDependencies(ccusage / esbuild 方式)

* Good: install 時 download 不要・npm の整合性/provenance に乗る・業界標準
* Bad: publish するパッケージ数が増える

### 2. postinstall で Releases から download

* Good: publish は npm 1個 + Release アセットで済む
* Bad: install 時のネットワーク依存(プロキシ/オフライン/FW で失敗しうる)
* Bad: 整合性は自前担保になりがち

### 3. バイナリを本体パッケージに同梱

* Good: 仕組みが単純で download も不要
* Bad: 全プラットフォーム分を1パッケージに含めるとサイズが肥大化する
* Bad: os/cpu による出し分けができず無駄が大きい

## More Information

- 参考: Rust 版 ccusage(https://github.com/ccusage/ccusage)の npm パッケージ構成
- 同種の仕組み: esbuild / biome / swc の optionalDependencies パターン
- 関連実装: `npm/`(メイン + `npm/packages/linux-x64`)、`.github/workflows/release.yml`
- 静的バイナリのビルド: `flake.nix` の `packages.static`([[ADR-0004]] の取得方式とは別軸)
