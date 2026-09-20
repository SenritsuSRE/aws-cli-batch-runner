#!/usr/bin/env zsh
# ==============================================================================
# AWS CLI Batch Runner for AI Context / Backup
# ==============================================================================
# セキュリティと安全なエラーハンドリングの有効化
set -euo pipefail

# ==============================================================================
# パスおよび環境変数の定義
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# バックアップのルートディレクトリと各種設定ファイルのパス
BACKUP_ROOT="${BACKUP_ROOT:-${REPO_ROOT}/aws-config-backup}"
CONFIG_FILE="${CONFIG_FILE:-${BACKUP_ROOT}/backup_targets.md}"
TARGET_DIR="${TARGET_DIR:-${BACKUP_ROOT}/latest}"
LOG_DIR="${LOG_DIR:-${BACKUP_ROOT}/logs}"

# 【改善】ログファイルが肥大化しないよう、日付（YYYYMMDD）ごとにファイルを分割して保存する
CURRENT_DATE="$(date +%Y%m%d)"
LOG_FILE="${LOG_DIR}/backup_${CURRENT_DATE}.log"

# 出力先ディレクトリの自動作成
mkdir -p "${TARGET_DIR}" "${LOG_DIR}"

# 標準出力および標準エラーをログファイルへ同時に出力（日付別ログに対応）
exec > >(tee -a "$LOG_FILE") 2>&1

# ==============================================================================
# 事前チェック
# ==============================================================================
# バックアップ対象を定義した設定ファイルが存在するか確認する
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR : Config file not found." >&2
    echo "File  : $CONFIG_FILE" >&2
    exit 1
fi

echo "===== AWS Config Backup Start ====="
echo "Config File : $CONFIG_FILE"
echo "Target Dir  : $TARGET_DIR"
echo "Log File    : $LOG_FILE"
date

# ==============================================================================
# バックアップ実行ループ
# ==============================================================================
# 設定ファイルから1行ずつ読み込み、ファイル名とAWS CLIコマンドに分割する
while IFS='|' read -r FILE_NAME AWS_CMD
do
    # コメント行や空行はスキップする
    [[ -z "${FILE_NAME}" || "${FILE_NAME}" =~ ^# ]] && continue

    echo "--> Backup Start : ${FILE_NAME}"

    OUTPUT_FILE="${TARGET_DIR}/${FILE_NAME}.json"
    
    # 【改善】将来コードが長くなり途中で終了した場合でも、一時ファイルが確実に破棄されるよう
    # mktempで作成した直後にtrapでクリーンアップを登録する（あるいは安全なスコープで管理）
    ERROR_FILE="$(mktemp)"
    trap 'rm -f "${ERROR_FILE}"' EXIT

    # AWS CLIコマンドを実行し、結果をJSONとして保存する
    if eval "${AWS_CMD}" > "${OUTPUT_FILE}" 2>"${ERROR_FILE}"; then
        echo "    SUCCESS : ${FILE_NAME}"
    else
        # 特定のエラー（リソースが存在しない等）の場合は無視して空のJSONを保存する
        if grep -qE "NoSuchLifecycleConfiguration|NoSuchBucketPolicy" "${ERROR_FILE}"; then
            echo '{}' > "${OUTPUT_FILE}"
            echo "    INFO (Not Configured) : ${FILE_NAME}"
        else
            # 予期せぬエラーの場合は処理を中断する
            echo "    FAILED : ${FILE_NAME}" >&2
            cat "${ERROR_FILE}" >&2
            rm -f "${ERROR_FILE}"
            exit 1
        fi
    fi

    # 正常終了時は一時ファイルを明示的に削除
    rm -f "${ERROR_FILE}"
    # trapのスコープをリセット
    trap - EXIT

done < "$CONFIG_FILE"

echo "===== AWS Config Backup Complete ====="
date

