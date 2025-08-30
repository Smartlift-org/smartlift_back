# 🏋️ SmartLift API - Setup Guide

This guide will help you set up the SmartLift API project from scratch in your local development environment.

## 📋 Prerequisites

Before starting, make sure you have installed:

- **Docker** (version 20.0 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git**

### Verify Installation

```bash
docker --version
docker-compose --version
git --version
```

## 🚀 Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/diecoscai/smartlift_api.git
cd smartlift_api
```

### 2. Check Available Ports

The project uses the following ports:
- **PostgreSQL**: 5433
- **Redis**: 6380
- **Rails API**: 3002

Verify these ports are available:

```bash
# Check ports
lsof -i :5433
lsof -i :6380
lsof -i :3002
```

If any port is occupied, you can modify `docker-compose.yml` to use different ports.

### 3. Build and Start Services

```bash
# Build images
docker-compose build

# Start services (database and Redis)
docker-compose up -d db redis

# Wait for services to be healthy
docker-compose ps
```

### 4. Configure Database

```bash
# Create database
docker-compose run --rm web rails db:create

# Run migrations
docker-compose run --rm web rails db:migrate

# (Optional) Seed with test data
docker-compose run --rm web rails db:seed
```

### 5. Start Web Application

```bash
# Start Rails server
docker-compose up -d web

# Verify all services are running
docker-compose ps
```

### 6. Import Exercises (New - Optional)

```bash
# Import exercise database from free-exercise-db
docker-compose exec web rails exercises:import

# Verify import
docker-compose exec web rails runner "puts Exercise.count"
```

## ✅ Verification

### Check that the API works:

```bash
# Test main endpoint
curl http://localhost:3002/

# You should see a JSON response with available endpoints
# {"status":"online","version":"1.0.0","endpoints":{...}}
```

### Test database connection:

```bash
# Check database version
docker-compose run --rm web rails db:version

# Access Rails console
docker-compose exec web rails console
```

## 🛠️ Useful Development Commands

### Container Management

```bash
# View status of all services
docker-compose ps

# View logs of specific service
docker-compose logs web -f
docker-compose logs db -f

# Restart a service
docker-compose restart web

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v
```

### Rails Commands

```bash
# Rails console
docker-compose exec web rails console

# Generate a migration
docker-compose exec web rails generate migration MigrationName

# Run migrations
docker-compose run --rm web rails db:migrate

# Migration rollback
docker-compose run --rm web rails db:rollback

# Run tests
docker-compose run --rm web bundle exec rspec

# Execute specific command in container
docker-compose exec web bash
```

### Database Management

```bash
# Connect directly to PostgreSQL
docker-compose exec db psql -U postgres -d smartlift_development

# Backup database
docker-compose exec db pg_dump -U postgres smartlift_development > backup.sql

# Restore from backup
docker-compose exec -T db psql -U postgres smartlift_development < backup.sql

# View current schema
docker-compose run --rm web rails db:schema:dump
```

## 🐛 Common Troubleshooting

### Error: Port already in use

```bash
# Find what process is using the port
lsof -i :5433

# Kill the process (replace PID with process ID)
kill -9 PID

# Or change port in docker-compose.yml
```

### Error: Container won't start

```bash
# View detailed logs
docker-compose logs [service_name]

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Error: Database won't connect

```bash
# Verify PostgreSQL is running
docker-compose ps db

# Check database logs
docker-compose logs db

# Recreate database
docker-compose run --rm web rails db:drop db:create db:migrate
```

### Error: "connection to server on socket failed"

**Problem**: PostgreSQL connection error in entrypoint.
**Solution**: This issue has been fixed in the current version of the project.

If you encounter this error:
```bash
# Verify services are healthy
docker-compose ps

# If it persists, rebuild completely
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
docker-compose run --rm web rails db:drop db:create db:migrate
```

### Error: Migrations fail

```bash
# Check migration status
docker-compose run --rm web rails db:migrate:status

# Rollback and migrate again
docker-compose run --rm web rails db:rollback
docker-compose run --rm web rails db:migrate

# Extreme case: recreate from schema
docker-compose run --rm web rails db:schema:load
```

## 📁 Project Structure

```
smartlift_api/
├── app/
│   ├── controllers/     # API Controllers
│   ├── models/         # ActiveRecord Models
│   └── serializers/    # JSON Serializers
├── config/
│   ├── database.yml    # Database Config
│   └── routes.rb       # API Routes
├── db/
│   ├── migrate/        # Migrations
│   └── schema.rb       # Current Schema
├── docs/              # Documentation
├── spec/              # RSpec Tests
├── docker-compose.yml # Docker Configuration
└── Dockerfile.dev     # Development Docker Image
```

## 🔧 Environment Configuration

Important environment variables:

- `DATABASE_HOST`: localhost (from outside Docker)
- `DATABASE_PORT`: 5433
- `DATABASE_USERNAME`: postgres
- `DATABASE_PASSWORD`: password
- `REDIS_URL`: redis://localhost:6380/1

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Rails Guides](https://guides.rubyonrails.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 💡 Tips for Junior Developers

1. **Always check container status** with `docker-compose ps`
2. **Check logs** when something doesn't work: `docker-compose logs`
3. **Backup your database** before important changes
4. **Use Rails console** to test code: `docker-compose exec web rails console`
5. **Run tests** regularly: `docker-compose run --rm web bundle exec rspec`

## 🏗️ Migration Architecture

Our migrations follow a logical dependency order:

```
1. Users (foundation)
2. Exercises (independent)
3. Routines (depends on users)
4. Routine Exercises (depends on routines + exercises)
5. User enhancements (roles, stats, coaches)
6. Workouts (depends on users/routines)
7. Workout details (exercises, sets, pauses)
8. Performance indexes (optimization)
```

All migrations use proper timestamps (2025-06-24) and respect foreign key constraints.

## 🔄 Development Workflow

### Daily Development

```bash
# Start your day
docker-compose up -d

# Check everything is running
docker-compose ps

# Work on your features...

# Run tests before committing
docker-compose run --rm web bundle exec rspec

# End of day
docker-compose down
```

### Database Changes

```bash
# Create migration
docker-compose exec web rails generate migration DescriptiveName

# Edit the migration file
# Run migration
docker-compose run --rm web rails db:migrate

# Always check schema changes
docker-compose run --rm web rails db:schema:dump
```

---

Having issues? Check the troubleshooting section or consult detailed logs.

Happy coding! 🚀 