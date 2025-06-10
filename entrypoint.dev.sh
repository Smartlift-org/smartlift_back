#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /rails/tmp/pids/server.pid

# Wait for database to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Postgres is up - executing command"

# Run database migrations
bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:create db:migrate

# Then exec the container's main process (what's set as CMD in the Dockerfile)
exec "$@" 