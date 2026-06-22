---
name: sync-ghci
description: プロジェクト直下の .ghci を src/app/test で実際に使っている import / home モジュールへ同期する。Haskell ソースの import を足したり減らしたりしたあと、「.ghci を更新」「.ghci を同期」「使っているモジュールを .ghci に反映」などと言われたときに使う。
---

# Sync .ghci with project imports

プロジェクトの `.ghci` を、`src/` `app/` `test/` の Haskell ソースで実際に
使っている import 文と home モジュールに同期する。`.ghci` は「このプロジェクトで
使うモジュールだけ」を import している前提なので、不要になったものは削除する。
(プロジェクト規約 `CLAUDE.md` の「GHCi (.ghci) との同期」を機械的に実行する skill)

## 手順

1. `.ghci` と、`src/*.hs` `app/*.hs` `test/*.hs` を読む。
1. 各ソースの `^import` 文を集める(複数行に分かれた import リストも 1 つとして扱う)。
1. 同じモジュールが複数ファイルで import されている場合は**明示インポートリストを和集合(union)にまとめる**。
   - どこか 1 箇所でもリスト無し(`import M`)で使われていればリスト無しを優先する。
   - `import qualified M as A` と素の `import M (...)` の両方があれば、両方を残す。
1. `src/` 直下の home モジュール(`module <Name>` を持つファイル)それぞれについて、`.ghci` に `:add <Name>` があることを確認する。新しい home モジュールがあれば `:add` を足し、消えたモジュールの `:add` は削除する。
1. 上記の和集合に基づき `.ghci` の import 行を**全面的に置き換える**。ソースに無くなった import は `.ghci` からも消す。
1. `.ghci` を書き出す。下記「.ghci の書式ルール」に従う。
1. `chmod go-w .ghci` を実行する(グループ/他ユーザ書き込み権限があると GHCi に無視されるため)。
1. 読み込み確認: `echo ':q' | nix develop --command ghci` を実行し、`error` / `not in scope` が出ず `Ok, ... module(s) added.` になることを確かめる。
1. import を変更した場合、関連ドキュメント(必要なら `CLAUDE.md` の記述)との齟齬がないか確認する。

## .ghci の書式ルール

- 先頭の `:set -isrc` / `:set -XOverloadedStrings` などの設定行と `:add` 行、コメントは維持する。
- import はアルファベット順(モジュール名順)に並べる。
- **qualified は前置形 `import qualified M as A` で書く。** `.ghci` は `ImportQualifiedPost` を有効にしていないため、ソース側の後置形 `import M qualified as A` をそのまま書くと読み込みに失敗する。
- 設定行・コメントの区切りや日本語表記は既存のスタイルに合わせる。Markdown の水平線は使わない(ここはコメント)。

## 注意

- `.ghci` に追加する import が devShell の `ghcWithPackages`(`flake.nix`)に含まれるパッケージか確認する。含まれないパッケージを import すると `ghci` 起動時にエラーになる。
- `app/` `test/` だけで使うパッケージ(例: `http-conduit` の `Network.HTTP.Simple`、`hspec` の `Test.Hspec`)も「プロジェクトで使うモジュール」として `.ghci` に含める。
- このプロジェクトは plain `ghci`(`-isrc`)で起動し、`cabal repl` は使わない前提。
