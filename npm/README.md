# acac (npm wrapper)

直近の AtCoder の AC 履歴を週ごとのテーブルで表示する CLI。

```sh
npx acac-cli <atcoder-username>
```

> パッケージ名は `acac-cli`。素の `acac` は npm の名前類似ガードで publish 不可だったため
> `acac-cli` にしている。インストールされるコマンド名は `acac`。

## 仕組み (optionalDependencies 方式)

esbuild / ccusage と同じ、プラットフォーム別パッケージ方式。

- メインパッケージ `acac` は薄い JS シム(`bin/cli.js`)だけを持つ。
- `optionalDependencies` にプラットフォーム別パッケージ(`acac-linux-x64` など)を宣言し、
  npm が現在の `os`/`cpu` に合うものだけを自動インストールする。
- `bin/cli.js` が `acac-<platform>-<arch>/bin/acac` を `require.resolve` して起動する。
- install 時の追加ダウンロードは無い。

詳細な設計判断は `docs/adr/0005-npm-distribution-optional-dependencies.md` を参照。

## 対応プラットフォーム

- 現状 **linux-x64 のみ**(`acac-linux-x64`)。他環境では実行時にエラーで停止する。

## ローカルでの動作確認

```sh
nix build .#static
mkdir -p npm/packages/linux-x64/bin
install -m 0755 result/bin/acac npm/packages/linux-x64/bin/acac
node npm/bin/cli.js <atcoder-username>   # require.resolve できるよう npm i 後に実行
```
