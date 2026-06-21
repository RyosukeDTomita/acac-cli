---
status: accepted
date: 2026-06-21
decision-makers: "@RyosukeDTomita"
---

# ADR-0001: 純粋ロジックの文字列型として Text を採用

## Context and Problem Statement

`src/Acac.hs` の純粋ロジックでは、AtCoder Problems API から取得した提出データの
文字列(`problem_id`,`contest_id`,`result` など)を扱う。これらに対して大文字化・
サフィックス抽出・連結といった文字列処理を繰り返し行う(例: `formatProblemId`)。
この用途で標準の文字列型として何を使うかを決める必要がある。

Haskell には複数の文字列型があり、特性が大きく異なるため、プロジェクト方針として
1つを基準に据えたい。

## Decision Drivers

* 文字列処理(大文字化・サフィックス抽出・連結・分割)が多く、関数が充実していること
* 実データを扱うため、パフォーマンスとメモリ効率が良いこと
* 後続のHTTPステップで導入する`aeson`(JSONパース)との相性
* Unicodeを正しく扱えること(問題タイトル等で非ASCIIが混じる可能性)

## Considered Options

1. `Text`(`Data.Text`)
2. `String`(`[Char]`)
3. `ByteString`(`Data.ByteString.Char8`)

## Decision Outcome

Chosen option: "`Text`", because 文字列処理関数が体系的に揃っており、連結リストの
`String`より性能・メモリ効率が良く、`aeson`のJSONフィールドも標準で`Text`ベースの
ため変換コストが少ない。Unicodeも正しく扱える。`ByteString.Char8`はさらに軽量だが
ASCII前提でUnicodeを正しく扱えないため、本プロジェクトの用途には合わない。

### Consequences

* Good: `T.toUpper`,`T.takeWhileEnd`,`T.splitOn`など最適化された処理関数を直接使える
* Good: `aeson`の`FromJSON`が`Text`と自然に連携し、API取得部の実装が素直になる
* Good: パック配列でメモリ効率・キャッシュ効率が良い
* Bad: 文字列リテラルを`Text`として書くため`OverloadedStrings`拡張が必要
* Bad: パターンマッチに`(c:cs)`が使えず、`T.uncons`等を使う必要がある
* Bad: 標準I/O(`getLine`/`putStrLn`)は`String`基準のため、境界で`Data.Text.IO`や
  `pack`/`unpack`による変換が必要になる

### Confirmation

`src/Acac.hs`の公開関数(`formatProblemId`,`aggregate`)の型シグネチャが`Text`ベースで
あること、および`test/Spec.hs`が`OverloadedStrings`下でグリーンであることで確認する。

## Pros and Cons of the Options

### Text

* Good: 文字列処理関数が豊富で最適化されている
* Good: パック配列で高速・省メモリ
* Good: `aeson`等の主要ライブラリが標準対応
* Good: Unicodeを正しく扱える
* Neutral: リテラル利用に`OverloadedStrings`が要る
* Bad: パターンマッチが`String`ほど直感的でない

### String

* Good: `(c:cs)`でのパターンマッチが直感的
* Good: 追加拡張・import不要で、標準I/Oがそのまま使える
* Bad: `[Char]`(連結リスト)のため低速・メモリ効率が悪い
* Bad: 文字列処理は`Data.List`の汎用関数の流用や自前実装になりがち

### ByteString (Char8)

* Good: 最軽量・最速で、競プロの高速I/O等で有利
* Bad: ASCII前提でUnicodeを正しく扱えない
* Bad: 文字列としての意味論が弱く、表示用途には不向き

## More Information

- `Data.Text`: https://hackage.haskell.org/package/text
- 関連: `plan.md`(アーキテクチャ・モジュール構成)。表示専用の`renderTable`の戻り値は
  `putStr`との相性から`String`を採用する想定で、本ADRの対象外。
