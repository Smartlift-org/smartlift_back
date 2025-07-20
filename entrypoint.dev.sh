#!/bin/bash
set -e

rm -f /rails/tmp/pids/server.pid

# Install dependencies if they're missing
if [ ! -d "node_modules" ]; then
  yarn install
fi

# Wait for database to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "postgres" -d "smartlift_development" -c '\q'; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Postgres is up - executing command"

# Run database migrations
bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:create db:migrate

# Import exercises if the Exercise table is empty
if [ "$(bundle exec rails runner 'puts Exercise.count')" = "0" ]; then
  echo "Exercise table is empty - importing exercises..."
  bundle exec rails exercises:import
else
  echo "Exercise table already has data - skipping import"
fi

# Setup crontab with whenever
echo "Setting up crontab..."
bundle exec whenever --update-crontab --set environment=development

# Start cron service
service cron start

# Then exec the container's main process (what's set as CMD in the Dockerfile)
exec bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'" 