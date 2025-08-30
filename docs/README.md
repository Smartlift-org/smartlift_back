# 📚 SmartLift API Documentation

Welcome to the SmartLift API documentation folder. Here you'll find all the guides and resources to work with this project.

## 🚀 Setup Guides

Choose your preferred setup method:

### Docker Setup (Recommended)
- **[🐳🇪🇸 Docker Setup - Spanish](SETUP_GUIA_ES.md)** - Complete Docker guide in Spanish
- **[🐳🇺🇸 Docker Setup - English](SETUP_GUIDE_EN.md)** - Complete Docker guide in English

### Local Development Setup  
- **[🔧 Local Setup Guide](SETUP_LOCAL.md)** - For advanced users who prefer local PostgreSQL

All guides include:
- ✅ Prerequisites and installation
- ✅ Database setup and migrations  
- ✅ Exercise database import
- ✅ Development commands
- ✅ Troubleshooting common issues
- ✅ Project structure overview

## 📁 Other Documentation

- **[Workout Types](workout_types.md)** - Detailed explanation of workout types
- **[Postman Collection](postman/)** - API testing collection

## 🏗️ Architecture Overview

The SmartLift API is built with:
- **Ruby on Rails** 7.1.5 (API mode)
- **PostgreSQL** (database)
- **Redis** (caching)
- **Docker** (containerization)
- **RSpec** (testing)

## 🔗 Quick Links

- **Database**: localhost:5433
- **Redis**: localhost:6380  
- **API**: localhost:3002
- **Health Check**: `curl http://localhost:3002/`

## 🆘 Need Help?

1. Check the setup guides above
2. Review the troubleshooting sections
3. Check container logs: `docker-compose logs [service_name]`
4. Verify services status: `docker-compose ps`

---

**Happy coding!** 🏋️‍♂️ 