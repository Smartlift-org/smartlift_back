@echo off
setlocal

REM Remove a potentially pre-existing server.pid for Rails
if exist /rails/tmp/pids/server.pid del /rails/tmp/pids/server.pid

REM Install dependencies if they're missing
if not exist "node_modules" (
    yarn install
)

REM Wait for database to be ready
:WAIT_DB
pg_isready -h %POSTGRES_HOST% -U %POSTGRES_USER% -d %POSTGRES_DB%
if errorlevel 1 (
    echo Postgres is unavailable - sleeping
    timeout /t 1 /nobreak > nul
    goto WAIT_DB
)

echo Postgres is up - executing command

REM Run database migrations
bundle exec rails db:migrate 2>nul
if errorlevel 1 (
    bundle exec rails db:create db:migrate
)

REM Then exec the container's main process (what's set as CMD in the Dockerfile)
exec %* 