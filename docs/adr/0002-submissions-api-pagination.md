---
status: superseded by [[ADR-0004]]
date: 2026-06-21
decision-makers: "@RyosukeDTomita"
---

# ADR-0002: submissions API のページング方式

> **Note:** この ADR は [[ADR-0004]](取得期間と取得方式) によって置き換えられた。
> 当初は「全件をページングで集める」方針だったが、表示対象を「最低1週間・最大4週間」
> に変えたことで、ページングではなく「最大4週間を1リクエストで試し、満杯なら1週間に
> 絞って取り直す」方式に変更した。`nextFromSecond` 関数自体は「バッチが満杯か」の
> 判定に引き続き使われている。背景の理解のため本文は残す。

## Context and Problem Statement

AtCoder Problems API(kenkoooo)の `/v3/user/submissions` は、`from_second`(unix秒)
以降の提出を `epoch_second` 昇順で**最大500件**返す。ページ番号の仕組みは無く、
`from_second` をずらして続きを取る方式しかない。さらに API ドキュメントは
"Please don't hit API so often. Please sleep for more than 1 second between accesses."
と明記しており、リクエスト回数と頻度を抑える必要がある。

直近7日間の AC 履歴を取得するにあたり、(a)どの範囲を取りにいくか、(b)次の
`from_second` をどう決め、(c)いつ打ち切るか、を決める必要がある。

## Decision Drivers

* API への負荷を抑える(叩く回数を最小化し、リクエスト間は1秒超 sleep する)
* 取りこぼし(同一秒に固まった提出をスキップしない)とのバランス
* 判定ロジックをユニットテスト可能にしたい(IOから純粋部分を分離)

## Considered Options

1. 次の `from_second = 最後の提出の epoch_second + 1`、500件未満で打ち切り
2. 次の `from_second = 最後の提出の epoch_second`(同値) + 提出IDで重複除去
3. `from_second = 0` から全提出を取得(範囲を絞らない)

## Decision Outcome

Chosen option: "1(最大epoch+1で前進し、500件未満で停止)"。

取得範囲は**直近7日間に限定**する(`from_second = now - 7*86400`)。7日分なら通常
500件に収まり、多くの場合 API は1回しか叩かれない。1リクエストの結果が
`pageSize`(500)未満なら取り切ったとみなして停止、ちょうど500件なら最大
`epoch_second + 1` を次の `from_second` として続きを取る。ページングが発生する
場合のみ、リクエスト間に1秒超(`threadDelay 1_100_000`)の sleep を入れる。

この「続けるか / 次はどこからか」の判定だけを純粋関数 `nextFromSecond :: [Submission] -> Maybe Int`
として切り出し、IO のループはその戻り値で分岐するだけの薄い殻にする。

### Consequences

* Good: 直近7日に絞ることで通常は1リクエストで完了し、API 負荷が最小
* Good: `+1` で必ず前進するため無限ループにならない
* Good: 判定が純粋関数なのでテストできる([[test-description-language]] の方針で英語の it を付与)
* Bad: ちょうど500件目と同一秒に501件目以降が存在する場合、その提出を取りこぼす
  可能性がある(人間の提出ペースでは実質発生しない、かつ問題単位で重複除去するため
  影響は限定的)

### Confirmation

`test/Spec.hs` の `nextFromSecond` テストで、500件未満→`Nothing`、空→`Nothing`、
ちょうど500件→`Just (最大epoch+1)` を確認する。実 API 接続時は、直近7日の取得で
リクエストが1〜数回に収まり、ページング時に sleep が入ることを確認する。

## Pros and Cons of the Options

### 1. 最大epoch+1で前進・500件未満で停止

* Good: 前進が保証され実装がシンプル
* Good: 取得範囲を絞れば API 回数を最小化できる
* Bad: 500件境界かつ同一秒の提出を取りこぼす理論的リスク

### 2. 同値from_second + 提出IDで重複除去

* Good: 同一秒の取りこぼしが原理的に起きない
* Bad: ページ間で重複が出るため ID 集合の管理が必要
* Bad: 同じ秒を再取得するため、状況次第でリクエストが増える

### 3. from_second=0 から全件取得

* Good: ロジックが単純(範囲を考えない)
* Bad: 提出数の多いユーザでリクエスト回数が激増し、API 負荷の要請に反する
* Bad: 直近7日表示の用途に対して明らかに過剰

## More Information

- AtCoder Problems API ドキュメント: https://github.com/kenkoooo/AtCoderProblems/blob/main/doc/api.md
- 関連実装: `src/Acac.hs` の `nextFromSecond` / `pageSize`、HTTP ループは `app/Main.hs`
- Cloudflare 対策で `Accept-Encoding: gzip` が必要な点は `plan.md` を参照
