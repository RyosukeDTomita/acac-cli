---

## status: superseded date: 2026-06-24 decision-makers: "@RyosukeDTomita"

# ADR-0009: npm DL バッジはプラットフォーム別パッケージ5つの合計で出す

Superseded by: [[ADR-0010]]

## Context and Problem Statement

README には npm の DL 数バッジを貼っている。当初は `img.shields.io/npm/dw/acac-cli`
(本体 acac-cli の週間 DL)を使っていた。しかし配布構成([[ADR-0005]])上、本体 acac-cli は
薄い JS シム(`npm/bin/cli.js`)で、実体のバイナリはプラットフォーム別パッケージ
(`acac-linux-x64` ほか)側にある。

実際に npm の DL 数を見ると、本体 acac-cli より `acac-linux-x64` 単体の方が多かった。
原因は「本体は誰も使わない」ではなく、**集計のされ方の非対称**にある。

- npm の download count は registry まで取りに行った tarball fetch だけを数える
  (ローカル `~/.npm/_cacache` や npx キャッシュから返ったぶんは数えない)。
- 本体シムは ~1KB と軽く integrity も安定しているためキャッシュに乗りやすく、再取得され
  にくい → **過小**に出る。
- プラットフォーム別パッケージ(optionalDependency)は別管理で、CI などでの再解決・再取得が
  起きやすい → 相対的に多く出る。

このため本体単独のバッジは実 install 数より小さく出てしまう。実態に近い数を出したい。

## Decision Drivers

- 実 install 数に近い、過小でも過大でもない1つの数を出したい
- 既存ワークフロー規約(SHA ピン留め・最小 permissions・追加 secret を増やさない)に合わせたい
- 配布構成([[ADR-0005]])を変えずにバッジだけで完結させたい

## Considered Options

1. プラットフォーム別パッケージ5つの DL を合計する
1. 本体 + 5つの計6パッケージを合計する
1. 本体 acac-cli 単体のまま(従来)

## Decision Outcome

Chosen option: "1(プラットフォーム別5つの合計)"。

各 `npm install acac-cli` は本体シム1つと、`os`/`cpu` に一致する**ちょうど1つ**の
プラットフォームバイナリを引く。よって5つのバイナリ DL の合計 ≒ 実 install 数の近似に
なる。本体を足すと各 install を「本体1 + バイナリ1」で二重計上し、実数のほぼ2倍に過大化
するため、本体は合計に含めない。

shields.io には複数パッケージを合計する標準バッジが無く、dynamic badge にも加算機能が
ないため、**GitHub Actions(cron)で合計を計算 → shields の endpoint バッジ用 JSON を生成 →
生成物専用の `badges` ブランチへ force-push** する方式にする
(`.github/workflows/downloads-badge.yml`)。

- DL 取得は npm の bulk point API
  (`https://api.npmjs.org/downloads/point/last-week/<pkg1>,<pkg2>,...`)で5つを一括取得し、
  `jq` で `(.downloads // 0)` を合計する(未集計は0扱い)。期間は従来バッジ(`dw`)に
  合わせて週間(`last-week`)。
- 出力は `{"schemaVersion":1,"label":"npm downloads","message":"<n>/week","color":"blue"}`。
- `badges` ブランチは生成物だけを置く orphan ブランチとして毎回作り直して force-push する
  (履歴を溜めない)。認証は組み込みの `GITHUB_TOKEN`(`contents: write`)のみで、追加 secret
  は不要。
- README は `img.shields.io/endpoint?url=<badges ブランチの raw downloads.json>` を参照する。

### Consequences

- Good: 本体単独より実 install 数に近い数が出る(過小を是正)
- Good: 追加 secret 不要(`GITHUB_TOKEN` のみ)・第三者 action も増やさない
- Good: 配布構成([[ADR-0005]])に手を入れずバッジだけで完結する
- Bad: バイナリ側は CI の再取得で上振れしうるため、合計も「やや上振れした install 数の
  近似」であり厳密値ではない
- Bad: cron による更新のため、バッジは即時ではなく最大1日遅れる
- Bad: バイナリ名(`acac-linux-x64` ほか)を増減したらワークフローの `PKGS` も更新が要る

### Confirmation

`workflow_dispatch` で手動実行し、`badges` ブランチに `downloads.json` が生成され、
README のバッジが合計値で表示されることで確認する。ローカルでは bulk API を curl + jq で
叩いて合計が妥当か確認できる。

## Pros and Cons of the Options

### 1. プラットフォーム別5つの合計

- Good: 各 install = バイナリ1なので合計が実 install 数の近似になる
- Bad: バイナリ側の CI 再取得で上振れしうる

### 2. 本体 + 5つの計6パッケージ合計

- Good: 「全部入り」で分かりやすい見た目
- Bad: 各 install を本体1+バイナリ1で二重計上し、実数のほぼ2倍に過大化する

### 3. 本体単体のまま

- Good: 仕組みが要らない(shields 標準バッジ1つ)
- Bad: 本体シムがキャッシュに乗りやすく、実 install 数より過小に出る

## More Information

- 配布構成: [[ADR-0005]](npm 配布は optionalDependencies 方式)
- 関連実装: `.github/workflows/downloads-badge.yml`、`README.md` / `README.ja.md` のバッジ
- npm download counts API: https://github.com/npm/registry/blob/main/docs/download-counts.md
- shields.io endpoint badge: https://shields.io/badges/endpoint-badge
