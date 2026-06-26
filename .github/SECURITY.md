# Security Policy

## Supported Versions

最新のリリース(npm の `acac` 最新版 / GitHub Releases の最新タグ)のみをサポート対象とします。
脆弱性の修正は最新版に対して行い、必要に応じて新しいパッチバージョンをリリースします。

| Version | Supported |
| ------- | --------- |
| latest  | ✅        |
| older   | ❌        |

## Reporting a Vulnerability

脆弱性を見つけた場合は **公開 Issue では報告しないでください**。以下のいずれかで非公開に連絡してください。

- GitHub の [Private vulnerability reporting](https://github.com/RyosukeDTomita/acac-cli/security/advisories/new)
  (推奨。リポジトリの **Security > Advisories** から報告できます)
- 上記が使えない場合は、メンテナ([@RyosukeDTomita](https://github.com/RyosukeDTomita))に連絡してください。

報告には以下を含めてもらえると対応が早くなります。

- 影響を受けるバージョン / プラットフォーム
- 再現手順(可能なら最小の再現コード)
- 想定される影響

## Response

- 受領後、可能な限り速やかに(目安として数日以内に)一次返信します。
- 影響を確認できた場合は修正版をリリースし、GitHub Security Advisory として公開します。
- 報告者のクレジットを希望される場合は Advisory に記載します。

## Verifying Releases

配布物の正当性は cosign 署名と SLSA provenance で検証できます。詳細は
[README の Supply chain / build transparency セクション](../README.md#supply-chain--build-transparency)を参照してください。
