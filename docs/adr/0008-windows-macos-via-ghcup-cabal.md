---
status: accepted
date: 2026-06-22
decision-makers: "@RyosukeDTomita"
---

# ADR-0008: Windows/macOS バイナリはネイティブ runner + ghcup/cabal でビルドする

## Context and Problem Statement

Linux 向けは nix の musl フル static + Cachix で配布できている([[ADR-0005]] [[ADR-0006]])。
これを Windows/macOS にも広げたい。配布方式(npm の optionalDependencies、[[ADR-0005]])は
共通で使えるが、**バイナリのビルド方法**を OS ごとに決める必要がある。

制約:

- **nix は Windows を実質サポートしない。**
- **macOS はフル static 不可**(libSystem を静的リンクできない)。さらに nix の macOS ビルドは
  `/nix/store` にリンクし**非可搬**。Rust 版 ccusage は macOS も nix でビルドしているが、それは
  **Rust バイナリが自己完結**(システムライブラリ以外を引きずらない)だから成立する。GHC の
  バイナリは自己完結度が低く、同じ手は使えない。
- **GHC の Linux→mac/Windows クロスコンパイルは難しい。**

## Decision Drivers

- 各 OS で**素の環境にあるシステムライブラリだけ**にリンクした可搬バイナリを作りたい
- npm の optionalDependencies 配布([[ADR-0005]])をそのまま再利用したい
- **利用者には追加ツールを一切要求しない**(ビルド道具は CI 側だけ)
- ローカル(Linux)で mac/Windows は検証できないので、CI で回して固める前提

## Considered Options

1. ネイティブ runner + ghcup/cabal(mac/Windows)。Linux は現状の nix+Cachix を維持
2. macOS も nix でビルド(ccusage と同方式)
3. Linux から mac/Windows へクロスコンパイル
4. Windows/macOS を対応しない(Linux のみ)

## Decision Outcome

Chosen option: "1(ネイティブ runner + ghcup/cabal)"。

- **Linux**: 現状維持(nix musl static + Cachix、[[ADR-0006]])。
- **macOS / Windows**: GitHub Actions の**実機 runner**(`macos-14`=arm64 / `macos-13`=x64 /
  `windows-latest`=x64)上で **`haskell-actions/setup`(中身は ghcup)で GHC+cabal を入れ、
  `cabal build` でネイティブバイナリを作る**。mac/Windows はフル static にせず、各 OS に
  標準で存在するシステムライブラリにリンクする(その OS では可搬)。
- 生成物を OS 別 npm パッケージ(`acac-darwin-arm64` / `acac-darwin-x64` / `acac-win32-x64`)に
  入れて publish する。`bin/cli.js` は Windows のとき `acac.exe` を解決するようにする。

ghcup/cabal/GHC/nix は**すべてビルド時(CI)の道具**で、利用者のマシンには不要。利用者は
`npx acac-cli <user>` で OS に合うビルド済みバイナリを取得して動かすだけ(Linux と同じ体験)。

選択肢2(mac も nix)は Rust だから成立する話で、GHC では非可搬になり不採用。選択肢3は
GHC クロスが困難で不採用。

### Consequences

- Good: 各 OS で可搬なバイナリを配れ、**利用者は追加ツール不要**
- Good: npm 配布(optionalDependencies)と `cli.js` の仕組みをそのまま流用できる
- Bad: ビルド道具が **nix(Linux) と cabal(mac/Windows) の2系統**になり保守点が増える
- Bad: mac/Windows はフル static でないため、**libgmp(mac)や mingw 系 DLL(Windows)**など
  ランタイム依存で詰まる可能性があり、CI での調整が要る(対処はこちら側。利用者は無関係)
- Bad: mac x64 は Intel runner(`macos-13`)を使う(Rust のような 1 runner クロスは GHC では難しい)
- Bad: ローカル(Linux)で mac/Windows を検証できず、CI 反復で緑にする必要がある

### Confirmation

`release.yml` が `darwin-arm64` / `darwin-x64` / `win32-x64` を `haskell-actions/setup` + cabal で
ビルドし、対応する npm パッケージを publish すること。各 OS で `npx acac-cli <user>` が
ビルド済みバイナリを取得して動作することで確認する。

## Pros and Cons of the Options

### 1. ネイティブ runner + ghcup/cabal(mac/Windows)

- Good: 各 OS で可搬、利用者は何も要らない、npm 配布を流用できる
- Bad: ビルド系統が2つ、static でないぶんランタイム依存の調整が要る

### 2. macOS も nix(ccusage 方式)

- Good: Linux と同じ nix で統一できる
- Bad: GHC バイナリは `/nix/store` 依存で非可搬。Rust だから成立する手で Haskell には不適

### 3. Linux からクロスコンパイル

- Good: 1 つの runner で済む可能性
- Bad: GHC の mac/Windows クロスは現実的でない

### 4. Windows/macOS 非対応

- Good: 構成が単純なまま
- Bad: 利用者が Linux に限られる

## More Information

- 参考(ccusage の構成調査): linux/mac は nix・Windows は cargo のネイティブ runner マトリクス。
  mac を nix で配れるのは Rust が自己完結だから。
- ビルド道具: `haskell-actions/setup`(ghcup ベースで GHC/cabal を導入)
- 関連: [[ADR-0005]](npm 配布) / [[ADR-0006]](Linux 静的ビルドと Cachix)
