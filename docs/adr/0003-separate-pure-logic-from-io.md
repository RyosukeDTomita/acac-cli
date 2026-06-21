---
status: accepted
date: 2026-06-21
decision-makers: "@RyosukeDTomita"
---

# ADR-0003: 純粋ロジック(Acac)と I/O(Main)を分離する

## Context and Problem Statement

acac は、コマンドライン引数の解釈・AtCoder Problems API からの取得・JSON パース・
日ごとの集計・テーブル整形・標準出力、という複数の処理からなる。これらを1ファイル
(例: `Main.hs`)に混在させることもできるが、テストのしやすさと将来の配布形態
(npx 向けバイナリ化)を見据えて、コードの置き場所を決める必要がある。

## Decision Drivers

* ロジックをユニットテストしやすくしたい(ネットワークや時刻に依存させたくない)
* バグの起きやすい副作用(I/O)を局所化して見通しを良くしたい
* 最終ゴールの npx 配布(バイナリ化)でロジックを再利用したい
* GHCi でロジックだけを手軽に試したい([[test-description-language]] / `.ghci`)

## Considered Options

1. 純粋ロジックを `src/Acac.hs`、I/O を `app/Main.hs` に分離する
2. すべてを単一の `Main.hs` にまとめる

## Decision Outcome

Chosen option: "1(`src/Acac.hs` と `app/Main.hs` に分離)"。

`src/Acac.hs` には副作用のない純粋関数と型だけを置く
(`parseArgs`,`formatProblemId`,`toJstDay`,`aggregate`,`renderTable`,
`nextFromSecond`,`Submission` とその `FromJSON`)。`app/Main.hs` には `IO`
(引数取得・HTTP 取得・sleep・標準出力)だけを置き、`Acac` の純粋関数を呼び出す
薄い殻にする。テスト(`test/Spec.hs`)は `Acac` の純粋関数のみを対象にする。

ページング判定 `nextFromSecond` のように、本来 I/O ループの中にある判断ロジックも、
純粋関数として `Acac` 側へ切り出してテスト可能にする([[ADR-0002]])。

### Consequences

* Good: 純粋関数は「入力->期待出力」で決定的にテストできる(現状のテストはすべて
  `Acac` 対象で、`Main` の I/O には触れない)
* Good: 副作用が `Main` に局所化され、原因の切り分けがしやすい
* Good: `Acac` をライブラリとして再利用でき、npx 配布のバイナリ化でもそのまま使える
* Good: GHCi(`.ghci`)で `Acac` だけ読み込んで試せる
* Good: 将来 cabal 化する際、`library`(src) と `executable`(app) に素直に対応する
* Bad: ファイルとモジュールが分かれるぶん、小さいうちはやや冗長
* Bad: 実行に `-isrc -iapp` の指定が必要(cabal 化までの暫定手間)

### Confirmation

`test/Spec.hs` が `Acac` の公開関数のみを import してグリーンであること、および
`app/Main.hs` が `import Acac (...)` で純粋関数を呼ぶ薄い構成になっていることで確認する。

## Pros and Cons of the Options

### 1. src/Acac.hs(純粋) と app/Main.hs(I/O)に分離

* Good: テスト容易・再利用容易・副作用が局所化される
* Good: cabal 化(library/executable)への移行が素直
* Bad: 小規模なうちはファイル分割がやや冗長

### 2. 単一 Main.hs にまとめる

* Good: ファイルが1つで手軽、最初は書きやすい
* Bad: 純粋ロジックが `IO` と混ざりテストしにくい
* Bad: 再利用・バイナリ化・GHCi 試行のいずれでも取り回しが悪くなる

## More Information

- `plan.md` のアーキテクチャ節(モジュール構成)
- 関連 ADR: [[ADR-0002]](submissions API のページング判定を純粋関数に切り出した例)
