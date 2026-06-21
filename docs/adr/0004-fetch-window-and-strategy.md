---
status: accepted
date: 2026-06-21
decision-makers: "@RyosukeDTomita"
---

# ADR-0004: 取得期間と取得方式(最低1週間・最大4週間)

## Context and Problem Statement

当初は「直近7日間の AC 履歴」を表示する想定で、submissions API を `from_second` で
ページングして集める方式を採っていた([[ADR-0002]])。しかし7日間だけでは表示が
味気ないため、表示対象を「**最低1週間、取得が軽ければ最大4週間**」に拡張し、
1週間ごとに表を区切って出すことにした。

一方で API ドキュメントは
"Please don't hit API so often. Please sleep for more than 1 second between accesses."
と明記しており、アクセス回数は引き続き最小限にしたい。`/v3/user/submissions` は
`from_second` 以降を `epoch_second` 昇順で**最大500件**返す(ページ番号は無い)。
この制約下で、取得期間と取得方式を決める必要がある。

## Decision Drivers

* 表示は最低1週間を保証しつつ、可能なら最大4週間まで見せたい
* API アクセス回数を最小化する(通常は1回で済ませたい)
* 古い側が切れた中途半端なデータ(500件上限に当たった際の最古500件)を表示しない

## Considered Options

1. 4週間を1リクエストで試し、満杯(500件)なら1週間に絞って取り直す
2. [[ADR-0002]] のように4週間ぶんを満杯が解消するまでページングして全取得する
3. 常に1週間だけ取得する(拡張しない)

## Decision Outcome

Chosen option: "1(4週間を1回試し、満杯なら1週間で取り直す)"。

まず `from_second = now - 28日` で1リクエストする。結果が `pageSize`(500)未満なら
「4週間が1アクセスに収まった」とみなしてそのまま使う(最大4週間表示)。ちょうど
500件なら「1アクセスに収まらない」と判断し、`from_second = now - 7日` で取り直して
直近1週間ぶんを表示する(最低1週間保証)。取り直しが発生する場合のみ、リクエスト間に
1秒超(`threadDelay 1_100_000`)の sleep を入れる。

満杯判定には既存の純粋関数 `nextFromSecond`(`Nothing` なら満杯でない)を再利用する。
取得後は `aggregate` で日ごとに集計し、`splitIntoWeeks` で今日(JST)から遡る7日刻みの
週に分け、`renderTable` で「ヘッダ1つ・週ごとに区切りと week total を持つ単一テーブル」
として描画する。

### Consequences

* Good: 通常(4週間で500件未満)は API アクセスが1回で済む
* Good: 取り直し時も最大2回までにアクセス回数を抑えられる
* Good: 4週間が重いユーザでも最低1週間は必ず表示できる
* Good: 満杯時は最古500件(直近を含まない可能性がある)を破棄し、1週間を取り直すので
  「中途半端な古いデータだけ表示される」事態を避けられる
* Bad: 4週間と1週間の両方が満杯になるほど多提出のユーザでは、1週間ぶんも最古500件で
  打ち切られ取りこぼす可能性がある(人間の提出ペースでは実質発生しない)
* Bad: 厳密な「ちょうど4週間」ではなく「1リクエストに収まる範囲(最大4週間)」になる

### Confirmation

`app/Main.hs` の `fetchRecent` が、4週間リクエスト→`nextFromSecond` が `Nothing` なら
そのまま、`Just _` なら sleep して1週間で取り直す、という分岐になっていることで確認する。
実 API では、通常ユーザで1リクエストに収まり週ごとのテーブルが表示されることを確認する。

## Pros and Cons of the Options

### 1. 4週間を1回試し、満杯なら1週間で取り直す

* Good: 通常1回・最大2回でアクセス回数が最小
* Good: 満杯時に最古500件を捨てるため表示が中途半端にならない
* Bad: 超多提出ユーザでは1週間ぶんも取りこぼし得る

### 2. 満杯解消までページング(ADR-0002)

* Good: 期間内の提出を厳密に全件取得できる
* Bad: 提出が多いほどアクセス回数が増え、API 負荷の要請に反する
* Bad: 「最大4週間/最低1週間」という表示要件に対して過剰

### 3. 常に1週間だけ

* Good: 実装が最も単純でアクセスも常に1回
* Bad: 表示が7日固定で味気ない(今回の変更の動機を満たさない)

## More Information

- AtCoder Problems API ドキュメント: https://github.com/kenkoooo/AtCoderProblems/blob/main/doc/api.md
- 置き換え元: [[ADR-0002]](submissions API のページング方式)
- 関連実装: `app/Main.hs` の `fetchRecent` / `fetchPage`、`src/Acac.hs` の
  `nextFromSecond` / `splitIntoWeeks` / `renderTable`
