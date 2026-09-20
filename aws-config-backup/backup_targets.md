### ============================================================
### README
### ============================================================

### AWS Config Backup Targets
###
### format:
### output-file-name|aws cli command
###
### example:
### vpcs|aws ec2 describe-vpcs
###
### このファイルは aws_backup.zsh から読み込まれる。
### コメント行(#)と空行は無視される。


### ============================================================
### IAM 関連
### ============================================================

# IAM Group

## Group情報
iam-group-$グループ名 |aws iam get-group --group-name $グループ名

## GroupへアタッチされたPolicy一覧
iam-group-$グループ名-admin-attached-policies|aws iam list-attached-group-policies --group-name $グループ名
# IAM Policy

## Policy情報
iam-policy-$ポリシー名 |aws iam get-policy --policy-arn arn:aws:iam::XXXXXXXXXXXX:policy/$ポリシー名

## 注意
## get-policy は PolicyName、Arn、DefaultVersionId 等のメタ情報のみ取得する
## ポリシー本体(JSON Statement)は取得できない
## ポリシー本体を確認する場合は以下を実行する
## aws iam get-policy-version --policy-arn <arn> --version-id <DefaultVersionId>


# IAM Role

## Role情報(TrustPolicy含む)
iam-role-$ロール名|aws iam get-role --role-name $ロール名

## RoleへアタッチされたPolicy一覧（Managed Policy）
iam-role-$ロール名-attached-policies|aws iam list-attached-role-policies --role-name $ロール名

## RoleへアタッチされたPolicy一覧（Inline Policy）
iam-role-$ロール名-inline-policies|aws iam list-role-policies --role-name $ロール名


# ============================================================
# Network - VPC
# ============================================================
# VPC情報（一括取得）
vpcs|aws ec2 describe-vpcs

# Subnet情報（一括取得）
subnets|aws ec2 describe-subnets

# Internet Gateway情報（一括取得）
internet-gateways|aws ec2 describe-internet-gateways

# NAT Gateway情報（一括取得）
nat-gateways|aws ec2 describe-nat-gateways

# Route Table情報（一括取得）
route-tables|aws ec2 describe-route-tables

# VPC Endpoint情報（一括取得）
vpc-endpoints|aws ec2 describe-vpc-endpoints

# Security Group情報（一括取得）
security-groups|aws ec2 describe-security-groups


# ============================================================
# Lambda
# ============================================================
# Lambda本体情報
lambda-$Lambda名|aws lambda get-function --function-name $Lambda名

# Lambda設定情報
lambda-config-$Lambda名|aws lambda get-function-configuration --function-name $Lambda名


