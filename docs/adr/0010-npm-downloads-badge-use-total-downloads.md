---

## status: accepted date: 2026-07-09 decision-makers: "@RyosukeDTomita"

# ADR-0010: npm DL バッジは18か月合計の過去最大で出す

Supersedes: \[[ADR-0009]\]

## Context and Problem Statement

ADR-0009 では、npm DL バッジを本体 `acac-cli` 単体ではなく、プラットフォーム別
パッケージ5つの合計で出すことを決めた。この判断自体は維持する。

一方で、実装は npm download counts API の `last-week` を使っていたため、README の
バッジは週間 DL を表示していた。shields.io の `https://img.shields.io/npm/d18m/acac-cli.svg`
のようなバッジでは、npm download API が保持する最大範囲である18か月ぶんを使える。
現在のパッケージ年齢では、この18か月範囲は実質的に累計 DL として扱える。

README のバッジでは週間の勢いよりも、これまでの利用量を示したい。ただし npm download API から
厳密な全期間累計は取得できず、shields.io の `npm/dt` も実質的には `npm/d18m` に寄せられる。
そのため、18か月合計を毎日計算し、過去最大値を `badges` ブランチに保存して、バッジにはその最大値を表示する。

## Decision Drivers

- README 上で npm DL の累計感が分かる、単調減少しない数を出したい
- ADR-0009 の「本体を含めず、プラットフォーム別5パッケージを合計する」判断は維持したい
- shields.io の `npm/d18m` と同等の期間で、既存の endpoint badge 生成方式を保ちたい

## Considered Options

1. 5つのプラットフォーム別パッケージの18か月 DL を合計し、その過去最大を表示する
1. 5つのプラットフォーム別パッケージの週間 DL のままにする
1. 本体 `acac-cli` の `npm/d18m` バッジへ戻す

## Decision Outcome

Chosen option: "1(5つのプラットフォーム別パッケージの18か月 DL を合計し、その過去最大を表示する)"。

`.github/workflows/downloads-badge.yml` で、npm download counts API の取得を
`point/last-week/<pkg1>,<pkg2>,...` から、shields.io の `npm/d18m` と同じ
`range/1000-01-01:3000-01-01/<pkg>` に変更する。

npm の `range` endpoint は複数パッケージの一括指定に対応していないため、5つの
プラットフォーム別パッケージを1つずつ取得し、`.downloads[]` の日別 DL 数を `jq` で合計する。

取得 URL は次の形式にする。

```text
https://api.npmjs.org/downloads/range/1000-01-01:3000-01-01/<pkg>
```

計算した現在の18か月合計を、`badges` ブランチ上の `downloads-max.txt` に保存された過去最大値と比較する。
現在値が過去最大値より大きい場合は最大値を更新し、そうでない場合は過去最大値を維持する。
出力する shields endpoint JSON の message は `<n>/week` ではなく `<n> total` にする。
あわせて、確認用に当日の18か月合計を `downloads-current-18m.txt` に出力する。

### Consequences

- Good: README のバッジが週間 DL ではなく累計に近い値を表示する
- Good: 本体シムを含めないため、ADR-0009 の二重計上回避は維持できる
- Good: 18か月窓から古い DL が落ちても、バッジ表示値は過去最大を維持できる
- Good: 既存の GitHub Actions + endpoint badge 構成をそのまま使える
- Bad: 週間の bulk point API と違い、range API は5パッケージぶんの HTTP request が必要になる
- Bad: 初回導入前に18か月窓から落ちた DL は復元できないため、厳密な全期間累計ではない
- Bad: バイナリ側は CI の再取得で上振れしうるため、引き続き厳密な install 数ではない

### Confirmation

`workflow_dispatch` で手動実行し、`badges` ブランチに `downloads.json`、`downloads-max.txt`、
`downloads-current-18m.txt` が生成されることを確認する。`downloads.json` は
`{"schemaVersion":1,"label":"npm downloads","message":"<n> total","color":"blue"}` の形にする。

## More Information

- Superseded ADR: \[[ADR-0009]\]
- 関連実装: `.github/workflows/downloads-badge.yml`
- npm download counts API: https://github.com/npm/registry/blob/main/docs/download-counts.md
- shields.io npm downloads badge: `https://img.shields.io/npm/d18m/acac-cli.svg`
