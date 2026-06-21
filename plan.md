# acac 実装プラン

## Context

AtCoder ユーザの直近7日間の AC 履歴を、ccusage 風の画面で表示する CLI ツール `acac` を作る。
`npx acac HathawayNoa` のように呼べる配布形態を最終ゴールにしつつ、作者は Haskell で
ロジックを書きたい。よって「Haskell でビルドしたバイナリを薄い npm パッケージでラップする」
方式を採る。ただし段階的に進め、**まず `runghc` で動くものを作り、その後 npx 配布に対応**する。

表示したい情報:

- 日付
- その日にACした一意な問題数(AC数)
- その日に解いた問題一覧(`abc457C` のような表記。リンクは貼らない)

---

## 確定した仕様 (ユーザ合意済み)

- 配布: 一旦 `runghc` で動かし、その後 npx 配布に対応する段階方式
- 表示する日: ACのあった日だけ(AC0件の日は行に出さない)
- AC数の定義: その日にACした一意な問題数(同じ問題を複数回ACしても1)
- 問題表記: `contest_id` + 問題サフィックスの大文字。例 `abc457` + `abc457_c` -> `abc457C`
- タイムゾーン: JST(UTC+9)で日付を区切る(AtCoderはJST基準)

---

## データソースと最重要な技術的制約

AtCoder Problems API (kenkoooo) を使う。

- エンドポイント: `https://kenkoooo.com/atcoder/atcoder-api/v3/user/submissions?user=<user>&from_second=<unix>`
- レスポンス: 提出のJSON配列。`epoch_second` 昇順。1回最大500件。`result == "AC"` がAC。
- 必要フィールド: `epoch_second`, `problem_id`, `contest_id`, `result`

### Cloudflare の制約(検証済み)

curl で疎通検証した結果、**`Accept-Encoding: gzip` ヘッダが無いと 403 Forbidden** になる
(User-Agentは無関係)。gzipを要求すれば 200 でJSONが取れる。

- Haskell側の対応: HTTPリクエストに `Accept-Encoding: gzip` を明示し、gzipレスポンスを解凍する。
- `http-conduit`(`Network.HTTP.Simple`)を使う。`parseRequest` 由来の `Request` は
  `decompress = browserDecompress` がデフォルトのため、手動でAccept-Encodingを付けても
  レスポンス側の自動解凍は効く想定。`runghc` 検証で実挙動を必ず確認する。

---

## アーキテクチャ

`runghc` 段階ではcabalを使わず、`ghcWithPackages` が提供するパッケージで動かす(競プロと同じ流儀)。

### モジュール構成

- `src/Acac.hs` … 純粋ロジック(テスト対象)
  - `formatProblemId :: Text -> Text -> Text` 問題表記変換(`abc457`,`abc457_c` -> `abc457C`)
  - `Submission` 型と `FromJSON` インスタンス(必要フィールドのみ)
  - `toJstDay :: Int -> Day` epoch秒 -> JSTの日付
  - `aggregate :: [Submission] -> [(Day, [Text])]` AC提出を日ごとに集計(一意な問題、降順 or 昇順)
  - `renderTable :: [(Day, [Text])] -> String` ccusage風テーブル文字列化
- `app/Main.hs` … I/O(引数からユーザ名取得、HTTP取得、`Acac` を呼んで表示)
- `test/Spec.hs` … hspec によるテスト

### 依存パッケージ(flake.nixの`ghcWithPackages`に追加)

- 今すぐ: `hspec`(最初のテスト用), `vector`(`Data.Array`より優先する方針 / GHCi のグローバル設定でも使用)
- HTTP実装ステップで追加: `aeson`, `http-conduit`
- `time`,`text`,`bytestring`,`containers` はGHC同梱/既存で利用可

---

## 出力イメージ(ccusage風)

```
┌────────────┬─────┬──────────────────────────────┐
│ Date       │ AC  │ Problems                     │
├────────────┼─────┼──────────────────────────────┤
│ 2026-06-17 │ 2   │ abc457C abc457D              │
│ 2026-06-15 │ 1   │ abc456A                      │
├────────────┼─────┼──────────────────────────────┤
│ Total      │ 3   │                              │
└────────────┴─────┴──────────────────────────────┘
```

(罫線スタイル・Total行の有無は実装時に微調整)

---

## 進め方(t-wada流TDD・小さいステップ)

Red -> Green -> Refactor を1サイクルずつ。最初のサイクルの対象は純粋関数 `formatProblemId`。

1. `formatProblemId` … 問題表記変換(最初のTDD対象)
   - Red: `formatProblemId "abc457" "abc457_c"` が `"abc457C"` を返すテストを書き、stubで失敗させる
   - Green: サフィックスを大文字化して連結する実装
1. `toJstDay` … epoch秒 -> JST日付
1. `aggregate` … 日ごとに一意な問題へ集計
1. `renderTable` … テーブル文字列化
1. HTTP取得(`app/Main.hs`)… `Accept-Encoding: gzip` 付き取得 + ページング + JSONパース
   - `runghc app/Main.hs HathawayNoa` で実データ表示を確認
1. (別フェーズ) npx配布対応
   - cabalプロジェクト化 + flake `packages.default`(`callCabal2nix`)でネイティブバイナリ生成
   - Linux向け静的バイナリ(musl)を作り、npmパッケージの`bin`でラップ
   - 必要ならマルチプラットフォーム(mac/arm64)はCIで段階対応

---

## テストの動かし方

```
nix develop --command runghc -isrc test/Spec.hs
```

(flakeに`hspec`追加後。direnv利用時は`direnv reload`してから`runghc -isrc test/Spec.hs`)

## GHCi での試行

プロジェクト直下に `.ghci` を置いており、`nix develop --command ghci` で起動すると
`-isrc` 設定と `Acac` の読み込み(`:add Acac`)、必要なモジュールの import が自動で行われる。

## 実データでの検証(HTTPステップ完了後)

```
nix develop --command runghc -isrc -iapp app/Main.hs HathawayNoa
```

直近7日のAC履歴がテーブル表示されればOK。`Accept-Encoding: gzip` が効いて403にならないことを確認する。
