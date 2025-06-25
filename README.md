This is the backend component of the mobile application for sports clubs and gyms. Implemented with Ruby on Rails, this backend manages the core business logic, including user administration (members and trainers), training routine management (creation, storage, AI integration), user progress tracking, and the infrastructure for the social feed and other services.

It acts as the main API serving data to the mobile application (built with React Native) and orchestrates integration with external services such as the AI routine generation API and the exercise video storage system.

## 🚀 Quick Start

For detailed setup instructions, check our comprehensive guides:

- **[🇪🇸 Guía de Configuración en Español](docs/SETUP_GUIA_ES.md)**
- **[🇺🇸 Setup Guide in English](docs/SETUP_GUIDE_EN.md)**

### TL;DR Setup

```bash
# Clone the repository
git clone [repository-url]
cd smartlift_api

# Start services
docker-compose up -d

# Setup database
docker-compose run --rm web rails db:create db:migrate

# Test API
curl http://localhost:3000/
```

### Ports Configuration

- **PostgreSQL**: localhost:5433
- **Redis**: localhost:6380
- **Rails API**: localhost:3000

## 📚 Documentation

All documentation is available in the [`docs/`](docs/) folder:

- **[Setup Guides](docs/)** (Spanish & English)
- **[API Documentation](docs/postman/)**
- **[Workout Types](docs/workout_types.md)**
- **Troubleshooting & Architecture**

## Exercise IDs

The exercise IDs in this system range from 98 to 970. This range is maintained to ensure compatibility with the external exercise database we integrate with. When working with exercises in the API, make sure to use IDs within this range.

Ongoing...
