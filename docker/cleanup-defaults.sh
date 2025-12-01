#!/bin/bash
#
# Remove default WordPress plugins and themes after container recreation
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load environment variables
if [ -f "${SCRIPT_DIR}/.env" ]; then
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
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

DOCKER_BIN="/usr/bin/docker"

echo "[$(date)] Removing default WordPress plugins and themes..."

${DOCKER_BIN} exec "${PROJECT_NAME}_app" bash -c '
    rm -rf /var/www/html/wp-content/plugins/akismet \
           /var/www/html/wp-content/plugins/hello.php \
           /var/www/html/wp-content/themes/twentytwenty* 2>/dev/null
    echo "✓ Default plugins removed (akismet, hello.php)"
    echo "✓ Default themes removed (twentytwenty*)"
' || {
    echo "[ERROR] Failed to remove defaults"
    exit 1
}

echo "[$(date)] Cleanup complete"
