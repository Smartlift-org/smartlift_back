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

# Setup database (runs automatically now)
# Import exercises
docker-compose exec web rails exercises:import

# Test API
curl http://localhost:3002/
```

### Ports Configuration

- **PostgreSQL**: localhost:5433
- **Redis**: localhost:6380
- **Rails API**: localhost:3002

## 📚 Documentation

All documentation is available in the [`docs/`](docs/) folder:

- **[🐳 Docker Setup Guide (Spanish)](docs/SETUP_GUIA_ES.md)** - Recommended for most users
- **[🐳 Docker Setup Guide (English)](docs/SETUP_GUIDE_EN.md)** - Recommended for most users  
- **[🔧 Local Setup Guide](docs/SETUP_LOCAL.md)** - For advanced users/local development
- **[📡 API Documentation](docs/postman/)** - Postman collection
- **[🏋️ Workout Types](docs/workout_types.md)** - Exercise system documentation

## Exercise IDs

The exercise IDs in this system range from 98 to 970. This range is maintained to ensure compatibility with the external exercise database we integrate with. When working with exercises in the API, make sure to use IDs within this range.

Ongoing...
