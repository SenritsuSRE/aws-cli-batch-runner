# AWS Config Backup

AWS環境を構造化データ(JSON)へ変換し、設計書作成および IaC(CDK) 化を支援するための基盤である。

本プロジェクトは単なる AWS バックアップツールではない。
AWS 環境の構成情報を継続的に収集し、GitHub 上で履歴管理し、さらに AI が解析可能な形式へ変換することで、ドキュメント作成と IaC 化を加速させることを目的としている。

---

## Background

既存 AWS 環境の調査では、一般的に以下のような作業が発生する。

```text
AWS Console
    ↓
画面確認
    ↓
Excel転記
    ↓
構成図作成
    ↓
パラメータシート作成
    ↓
基本設計書作成
```

この方法には以下の課題がある。

- 調査コストが高い
- 転記ミスが発生しやすい
- 設計書と実環境が乖離しやすい
- 属人化しやすい
- IaC 化の事前調査に多くの時間を要する

本プロジェクトは、この手作業中心のプロセスを自動化するために作られた。

---

## Concept

本プロジェクトの目的は AWS 環境を AI が理解可能な形式へ変換することである。

```text
AWS Environment
        ↓
AWS CLI
        ↓
JSON
        ↓
GitHub
        ↓
AI Analysis
        ↓
Parameter Sheet
        ↓
Design Document
        ↓
Infrastructure as Code
```

人間が AWS Console を見ながら設計書を書くのではなく、

- AWS から構成情報を取得する
- JSON として保存する
- GitHub で履歴管理する
- AI に分析させる
- 設計書を生成する
- CDKへ変換する

という流れを実現する。

---

## Architecture

```text
┌─────────────────┐
│ AWS Environment │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ aws_backup.zsh  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ backup_targets  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ JSON Snapshot   │
│ (latest/*.json) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GitHub          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Claude Code /   │
│ ChatGPT         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Documentation   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ CDK             │
└─────────────────┘
```

---

## Design Policy

### 1. Separation of Concerns

バックアップ対象と処理ロジックを分離する。

バックアップ対象は `backup_targets.md` に定義する。

形式:

```text
output-file-name|aws cli command
```

例:

```text
vpcs|aws ec2 describe-vpcs
security-groups|aws ec2 describe-security-groups
kms-keys|aws kms list-keys
```

バックアップ対象を追加する場合でも、スクリプト本体を修正する必要はない。
新しいAWSサービスをバックアップ対象へ追加する場合は、`backup_targets.md` にAWS CLIコマンドを1行追加するだけでよい。

これにより、

- 処理ロジックと設定を分離できる
- 保守性を向上できる
- 拡張性を向上できる
- AWSサービス追加時の対応コストを削減できる

というメリットがある。

---

### 2. Git First

取得した構成情報は JSON のまま Git 管理する。

```text
AWS
 ↓
JSON
 ↓
Git
```

これにより、

- 構成変更履歴の追跡
- git diff による差分確認
- Pull Request レビュー
- 構成監査
- 設計書と実環境の比較

が可能となる。

JSONをGit管理することで、AWS環境のスナップショットを継続的に蓄積できる。

また、過去のコミットを参照することで、

- いつ変更されたか
- 何が変更されたか
- 誰が変更したか

を追跡できるため、構成管理の品質向上にも繋がる。

本プロジェクトでは、Gitを単なるソースコード管理ツールではなく、AWS構成管理データベースとして活用する。

---

### 3. AI First

本プロジェクトは AI 活用を前提としている。

AI は AWS Console を直接参照できない。
一方で、JSON は構造化データであり、そのまま解析できる。

そのため本プロジェクトでは、`Human Readable` よりも `AI Readable` を重視している。

取得した JSON は単なるバックアップデータではない。
AI による分析やドキュメント生成のための入力データとして利用することを前提としている。

例えば、収集した JSON を Claude や ChatGPT に読み込ませることで、

- AWS 構成分析
- リソース依存関係分析
- パラメータシート作成
- 基本設計書作成
- 詳細設計書作成
- システム構成図作成
- CDK 化方針策定

などを支援できる。

本プロジェクトの本質は、**AWS 環境を AI が理解可能な構造化データへ変換すること** にある。

---

## Use Cases

取得した JSON を Claude や ChatGPT に読み込ませることで、AWS 環境の分析および各種ドキュメント生成を支援できる。

### Parameter Sheet

AWS 環境のパラメータシートを自動生成する。

対象例:
- VPC / Subnet / Route Table / Security Group
- IAM / KMS / S3
- Lambda / API Gateway / Cognito / Aurora / RDS Proxy

従来は手作業で作成していた構成一覧や設定値一覧を効率的に作成できる。

---

### Design Documents

AWS 環境の設計書を生成する。

生成対象例:
- 基本設計書 / 詳細設計書
- システム構成図
- 運用設計書 / 監視設計書 / セキュリティ設計書

JSON を根拠データとして利用することで、設計書と実環境の整合性を高めることができる。

---

### Infrastructure Analysis & IaC

AWS 環境の分析および IaC 化を支援する。

分析例:
- AWS構成分析 / リソース依存関係分析 / セキュリティレビュー
- AWS CDK / Terraform / CloudFormation への移行検討・コード生成

特に既存環境の IaC 化を行う際の事前調査において、高い効果を発揮する。

---

## Directory Structure

```text
aws-config-backup/
├── README.md
├── .gitignore
├── script/aws_backup.zsh
└── aws-config-backup/
    ├── backup_targets.md
    ├── latest/
    │   ├── vpcs.json
    │   ├── subnets.json
    │   ├── security-groups.json
    │   └── ...
    └── logs/
        └── backup.log
```

---

## Security & Privacy (機密情報管理)

本リポジトリでは、実行ログや出力される構成情報（JSON）に含まれうるセンシティブデータ（アカウントID、IPアドレス、リソースARN等）の漏洩を防ぐため、`.gitignore` を活用した管理を推奨している。

`.gitignore` 設定例:

```gitignore
# 実行ログの除外
aws-config-backup/logs/
*.log

# 一時ファイルの除外
*.tmp

# (オプション) ローカルでのみ保持し、Git管理から除外する場合
# aws-config-backup/latest/
```

※ チーム内でリポジトリをプライベート運用し、構成変更履歴をGitで追跡する場合は `latest/*.json` をコミット対象とします。

---

## Quick Start

### 前提条件

以下がインストール済みであり、AWS CLI の認証設定が完了していること。

- AWS CLI
- Git
- zsh
- （オプション）biome
- （オプション）claudeなど


確認:
```bash
aws sts get-caller-identity
```

---

### セットアップ & バックアップ実行

1. スクリプトに実行権限を付与します。
   ```bash
   chmod +x backup.sh
   ```

2. 設定ファイル `aws-config-backup/backup_targets.md` を用意します。

3. スクリプトを実行します。
   ```bash
   ./backup.sh
   ```

実行後、`aws-config-backup/latest/` 配下に JSON ファイルが出力され、`aws-config-backup/logs/backup.log` にログが保存されます。

---

### バックアップ対象の追加

`aws-config-backup/backup_targets.md` に形式に従って1行追加するだけで対象を拡張できます。

形式:
```text
file-name|aws cli command
```

例:
```text
vpcs|aws ec2 describe-vpcs
security-groups|aws ec2 describe-security-groups
```

---

## Vision

本プロジェクトが最終的に目指す姿。

```text
AWS Environment
        ↓
Automatic Collection
        ↓
JSON Snapshot
        ↓
GitHub
        ↓
AI Analysis
        ↓
Parameter Sheet
        ↓
Design Document
        ↓
CDK Source Code
        ↓
Pull Request
```

AWS環境の構成情報を継続的に収集し、構成変更履歴を資産として蓄積する。

そして同じ情報源を利用して、
- 構成管理
- 設計書管理
- IaC管理

を実現する。

従来は個別に管理されていた「AWS環境」「パラメータシート」「設計書」「IaCコード」を、単一の情報源から生成できる状態を目指す。

最終的には、AWS環境の変更が設計書やIaCへ継続的に反映される仕組みを構築し、「実環境」と「ドキュメント」と「コード」の乖離をなくすことを目標とする。

