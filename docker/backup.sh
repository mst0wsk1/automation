#!/bin/bash
#
# WordPress MySQL Backup Script
# Run via cron: 0 3 * * * /path/to/docker/backup.sh
#

set -eo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
RETENTION_DAYS=7
DOCKER_BIN="/usr/bin/docker"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        # Remove surrounding quotes from value
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        export "$key=$value"
    done < "${SCRIPT_DIR}/.env"
else
    echo "[ERROR] .env file not found"
    exit 1
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Generate filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="db_${TIMESTAMP}.sql.gz"
FILEPATH="${BACKUP_DIR}/${FILENAME}"

# Create backup
echo "[$(date)] Starting backup..."
${DOCKER_BIN} exec "${PROJECT_NAME}_db" mysqldump \
    -uroot \
    -p"${DB_ROOT_PASSWORD}" \
    "${DB_NAME}" \
    --single-transaction \
    --quick \
    | gzip > "${FILEPATH}"

# Verify backup
if [ -s "${FILEPATH}" ]; then
    SIZE=$(du -h "${FILEPATH}" | cut -f1)
    echo "[$(date)] Backup created: ${FILENAME} (${SIZE})"
else
    echo "[ERROR] Backup file is empty"
    rm -f "${FILEPATH}"
    exit 1
fi

# Remove old backups
echo "[$(date)] Cleaning backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "db_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

# List current backups
echo "[$(date)] Current backups:"
ls -lh "${BACKUP_DIR}"/db_*.sql.gz 2>/dev/null || echo "No backups found"

echo "[$(date)] Backup complete"
