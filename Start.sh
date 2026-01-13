#!/bin/bash
set -eu -o pipefail

echo "==> Starting Diamond Manager..."

# Ensure directories exist with correct permissions
mkdir -p /app/data/uploads /app/data/config /run/nginx /run/supervisor
chown -R cloudron:cloudron /app/data /run/nginx /run/supervisor

# Initialize configuration on first run
if [ ! -f /app/data/.initialized ]; then
    echo "==> First run initialization..."
    
    # Create default configuration
    cat > /app/data/config/config.json <<EOF
{
  "database": {
    "host": "${CLOUDRON_POSTGRESQL_HOST}",
    "port": ${CLOUDRON_POSTGRESQL_PORT},
    "database": "${CLOUDRON_POSTGRESQL_DATABASE}",
    "username": "${CLOUDRON_POSTGRESQL_USERNAME}",
    "password": "${CLOUDRON_POSTGRESQL_PASSWORD}"
  },
  "app": {
    "port": 3000,
    "environment": "production"
  }
}
EOF
    
    chown cloudron:cloudron /app/data/config/config.json
    
    # Run database migrations
    echo "==> Running database migrations..."
    /usr/local/bin/gosu cloudron:cloudron node /app/code/server/migrate.js
    
    touch /app/data/.initialized
    echo "==> Initialization complete"
fi

# Display configuration
echo "==> Configuration:"
echo "    Data directory: /app/data"
echo "    Config file: /app/data/config/config.json"
echo "    Database: ${CLOUDRON_POSTGRESQL_HOST}:${CLOUDRON_POSTGRESQL_PORT}"
echo "    HTTP Port: 3000"

# Start supervisor (which manages nginx + node)
echo "==> Starting services via supervisor..."
exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisor/supervisord.conf
