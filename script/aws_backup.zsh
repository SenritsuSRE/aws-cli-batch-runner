#!/usr/bin/env zsh
# ==============================================================================
# AWS CLI Batch Runner for AI Context / Backup
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

BACKUP_ROOT="${BACKUP_ROOT:-${REPO_ROOT}/aws-config-backup}"
CONFIG_FILE="${CONFIG_FILE:-${BACKUP_ROOT}/backup_targets.md}"
TARGET_DIR="${TARGET_DIR:-${BACKUP_ROOT}/latest}"
LOG_DIR="${LOG_DIR:-${BACKUP_ROOT}/logs}"
LOG_FILE="${LOG_DIR}/backup.log"

mkdir -p "${TARGET_DIR}" "${LOG_DIR}"

exec > >(tee -a "$LOG_FILE") 2>&1

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

while IFS='|' read -r FILE_NAME AWS_CMD
do
    [[ -z "${FILE_NAME}" || "${FILE_NAME}" =~ ^# ]] && continue

    echo "--> Backup Start : ${FILE_NAME}"

    OUTPUT_FILE="${TARGET_DIR}/${FILE_NAME}.json"
    ERROR_FILE="$(mktemp)"

    if eval "${AWS_CMD}" > "${OUTPUT_FILE}" 2>"${ERROR_FILE}"; then
        echo "    SUCCESS : ${FILE_NAME}"
    else
        if grep -qE "NoSuchLifecycleConfiguration|NoSuchBucketPolicy" "${ERROR_FILE}"; then
            echo '{}' > "${OUTPUT_FILE}"
            echo "    INFO (Not Configured) : ${FILE_NAME}"
        else
            echo "    FAILED : ${FILE_NAME}" >&2
            cat "${ERROR_FILE}" >&2
            rm -f "${ERROR_FILE}"
            exit 1
        fi
    fi

    rm -f "${ERROR_FILE}"
done < "$CONFIG_FILE"

echo "===== AWS Config Backup Complete ====="
date
