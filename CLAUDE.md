# acac プロジェクト規約

## GHCi (.ghci) との同期

- `src/` 配下のモジュール(`Acac.hs` など)に新しい `import` 文を追加・変更したら、プロジェクト直下の `.ghci` にも同じ import を反映すること。`.ghci` は「このプロジェクトで使うモジュールだけ」を import している前提なので、不要になった import は `.ghci` からも削除する。
- 新しい home モジュール(`src/` のファイル)を追加した場合は `.ghci` に `:add <Module>` を足す。
- `.ghci` はグループ/他ユーザ書き込み権限があると GHCi に無視されるため、編集後は `chmod go-w .ghci` を確認する。
