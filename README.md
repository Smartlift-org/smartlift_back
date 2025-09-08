# 🏋️ SmartLift Backend API

[![Ruby on Rails](https://img.shields.io/badge/Ruby%20on%20Rails-7.1.3-CC0000?style=for-the-badge&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7+-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

> **SmartLift** - Comprehensive fitness management system for sports clubs and gyms. Backend developed with Ruby on Rails providing a robust API for routine tracking, workouts, personal progress and trainer-user communication.

[🇪🇸 **Leer en Español**](#-smartlift-backend-api---español) | [🇺🇸 **Read in English**](#-table-of-contents)

## 📋 Table of Contents

- [🎯 Key Features](#-key-features)
- [🏗️ Architecture](#️-architecture)
- [🚀 Quick Start](#-quick-start)
- [🛠️ Technologies](#️-technologies)
- [📚 Documentation](#-documentation)
- [🧪 Testing](#-testing)
- [🚢 Deployment](#-deployment)
- [👥 Contributing](#-contributing)
- [📊 System Diagrams](#-system-diagrams)

## 🎯 Key Features

### ⚡ **User Management & Authentication**
- ✅ **Single Table Inheritance (STI)** for users, trainers, and administrators
- ✅ **JWT Authentication** with secure tokens
- ✅ **Password recovery system**
- ✅ **Push notifications** integration (Expo)
- ✅ **Granular privacy settings**

### 🏋️ **Workout System**
- ✅ **Customizable routines** with exercises and configurations
- ✅ **Real-time tracking** of sets, reps, and weights
- ✅ **Complete workout history**
- ✅ **Progress statistics** and personal records
- ✅ **Routine validation** by certified trainers

### 🤖 **AI Integration**
- ✅ **Automatic routine generation** based on user profile
- ✅ **Smart personalization** according to goals and experience
- ✅ **Dynamic workout adaptation**

### 💬 **Communication System**
- ✅ **Real-time chat** between trainers and users
- ✅ **WebSocket support** with Action Cable
- ✅ **Push notifications** for messages

### 📊 **Analytics & Reporting**
- ✅ **Detailed performance metrics**
- ✅ **Routine adherence tracking**
- ✅ **Personalized progress reports**

## 🏗️ Architecture

### **Architectural Pattern**: Monolithic with Separation of Concerns

```
┌─────────────────────────────────────────────────────┐
│                 SmartLift API                       │
│                (Ruby on Rails)                      │
├─────────────────────────────────────────────────────┤
│ Controllers │ Services │ Models │ Serializers        │
├─────────────────────────────────────────────────────┤
│ Active Record │ Action Cable │ Active Storage        │
├─────────────────────────────────────────────────────┤
│          PostgreSQL 14+     │    Redis 7+           │
└─────────────────────────────────────────────────────┘
```

### **Design Principles**
- 🏛️ **MVC Pattern** with clearly separated responsibilities
- 🔄 **RESTful API** with semantically correct endpoints
- 📦 **Service Objects** for complex business logic
- 🔒 **Security First** with validation and sanitization
- 📈 **Optimized Queries** with strategic indexes

## 🚀 Quick Start

### **Prerequisites**
- Docker & Docker Compose
- Git

### **3-step Setup**

```bash
# 1. Clone repository
git clone https://github.com/your-username/smartlift-backend.git
cd smartlift-backend

# 2. Start services
docker-compose up -d

# 3. Setup database
docker-compose exec web rails db:setup
docker-compose exec web rails exercises:import
```

### **Verify Installation**
```bash
# Test API Status
curl http://localhost:3002/

# Expected Response
{"status": "SmartLift API is running", "timestamp": "..."}
```

### **Port Configuration**
| Service      | Port | Description              |
|--------------|------|--------------------------|
| Rails API    | 3002 | Main server              |
| PostgreSQL   | 5433 | Database                 |
| Redis        | 6380 | Cache and WebSockets     |

## 🛠️ Technologies

### **Backend Framework**
- **Ruby on Rails 7.1.3** - Main web framework
- **PostgreSQL 14+** - Relational database
- **Redis 7+** - Cache and WebSockets

### **Authentication & Security**
- **JWT** - JSON Web Tokens for authentication
- **BCrypt** - Password hashing
- **Rack-CORS** - Cross-Origin Resource Sharing
- **Rack-Attack** - Rate limiting and protection

### **APIs & External Services**
- **HTTParty** - HTTP client for external APIs
- **Expo Push Notifications** - Mobile notifications
- **AI Workout Generation API** - Smart routine generation

### **Testing & Quality**
- **RSpec** - BDD testing framework
- **Factory Bot** - Test fixtures
- **Shoulda Matchers** - Additional matchers
- **Brakeman** - Security analysis
- **Rubocop** - Code linting and style

### **DevOps & Deployment**
- **Docker** - Containerization
- **Kamal** - Deployment configuration
- **Railway** - Hosting platform

## 📚 Documentation

### **Setup Guides**
- 🇪🇸 **[Complete Guide in Spanish](docs/SETUP_GUIA_ES.md)**
- 🇺🇸 **[Complete Setup Guide](docs/SETUP_GUIDE_EN.md)**
- 🐳 **[Docker Configuration](docs/SETUP_LOCAL.md)**

### **Technical Documentation**
- 📡 **[API Documentation](docs/API_DOCUMENTATION.md)**
- 🏗️ **[Architecture Overview](docs/ARCHITECTURE.md)**
- 🗄️ **[Database Schema](docs/DATABASE_SCHEMA.md)**
- ⚙️ **[Services Documentation](docs/SERVICES.md)**

### **Developer Resources**
- 🏋️ **[Workout Types](docs/workout_types.md)**
- 🤖 **[AI Integration Guide](docs/AI_WORKOUT_ROUTINE_IMPLEMENTATION.md)**
- 📮 **[Postman Collection](docs/postman/)**
- 📋 **[Development Guide](docs/DEVELOPMENT_GUIDE.md)**

## 🧪 Testing

### **Run Test Suite**
```bash
# All tests
docker-compose exec web rspec

# Specific tests
docker-compose exec web rspec spec/models/
docker-compose exec web rspec spec/controllers/
docker-compose exec web rspec spec/services/

# Test with coverage
docker-compose exec web rspec --format documentation
```

### **Testing Metrics**
- ✅ **90%+** code coverage
- ✅ **Unit tests** for all critical models
- ✅ **Integration tests** for main endpoints
- ✅ **Service tests** for business logic

## 🚢 Deployment

### **Production Ready Features**
- 🐳 **Docker containerization**
- 🔒 **SSL/HTTPS enforcement**
- 📊 **Application monitoring**
- 💾 **Database backups**
- 🚀 **Zero-downtime deployments**

### **Deployment Commands**
```bash
# Build production image
docker build -t smartlift-api .

# Deploy with Kamal
kamal deploy

# Health checks
curl https://your-domain.com/
```

## 👥 Contributing

### **Development Flow**
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push branch: `git push origin feature/new-feature`
5. Create Pull Request

### **Code Standards**
- ✅ Follow **Ruby Style Guide**
- ✅ Tests required for new features
- ✅ Updated documentation
- ✅ Code review required

---

## 🇪🇸 SmartLift Backend API - Español

> **SmartLift** - Sistema integral de gestión fitness para clubs deportivos y gimnasios. Backend desarrollado con Ruby on Rails que proporciona una API robusta para el seguimiento de rutinas, entrenamientos, progreso personal y comunicación entrenador-usuario.

## 📋 Tabla de Contenidos

- [🎯 Características Principales](#-características-principales-1)
- [🏗️ Arquitectura](#️-arquitectura-1)
- [🚀 Inicio Rápido](#-inicio-rápido-1)
- [🛠️ Tecnologías](#️-tecnologías-1)
- [📚 Documentación](#-documentación-1)
- [🧪 Testing](#-testing-1)
- [🚢 Deployment](#-deployment-1)
- [👥 Contribución](#-contribución-1)
- [📊 Diagramas del Sistema](#-diagramas-del-sistema-1)

## 🎯 Características Principales

### ⚡ **Gestión de Usuarios y Autenticación**
- ✅ **Single Table Inheritance (STI)** para usuarios, entrenadores y administradores
- ✅ **JWT Authentication** con tokens seguros
- ✅ **Sistema de recuperación de contraseñas**
- ✅ **Push notifications** integradas (Expo)
- ✅ **Configuración de privacidad** granular

### 🏋️ **Sistema de Entrenamientos**
- ✅ **Rutinas personalizables** con ejercicios y configuraciones
- ✅ **Seguimiento en tiempo real** de sets, reps y pesos
- ✅ **Historial completo** de entrenamientos
- ✅ **Estadísticas de progreso** y récords personales
- ✅ **Validación de rutinas** por entrenadores certificados

### 🤖 **Integración con IA**
- ✅ **Generación automática de rutinas** basada en perfil del usuario
- ✅ **Personalización inteligente** según objetivos y experiencia
- ✅ **Adaptación dinámica** de entrenamientos

### 💬 **Sistema de Comunicación**
- ✅ **Chat en tiempo real** entre entrenadores y usuarios
- ✅ **WebSocket support** con Action Cable
- ✅ **Notificaciones push** para mensajes

### 📊 **Analytics y Reporting**
- ✅ **Métricas de rendimiento** detalladas
- ✅ **Seguimiento de adherencia** a rutinas
- ✅ **Reportes de progreso** personalizados

## 🏗️ Arquitectura

### **Patrón Arquitectónico**: Monolítico con Separación de Responsabilidades

```
┌─────────────────────────────────────────────────────┐
│                 SmartLift API                       │
│                (Ruby on Rails)                      │
├─────────────────────────────────────────────────────┤
│ Controllers │ Services │ Models │ Serializers        │
├─────────────────────────────────────────────────────┤
│ Active Record │ Action Cable │ Active Storage        │
├─────────────────────────────────────────────────────┤
│          PostgreSQL 14+     │    Redis 7+           │
└─────────────────────────────────────────────────────┘
```

### **Principios de Diseño**
- 🏛️ **MVC Pattern** con responsabilidades claramente separadas
- 🔄 **RESTful API** con endpoints semánticamente correctos
- 📦 **Service Objects** para lógica de negocio compleja
- 🔒 **Security First** con validaciones y sanitización
- 📈 **Optimized Queries** con indices estratégicos

## 🚀 Inicio Rápido

### **Prerequisitos**
- Docker & Docker Compose
- Git

### **Configuración en 3 pasos**

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/smartlift-backend.git
cd smartlift-backend

# 2. Levantar servicios
docker-compose up -d

# 3. Configurar base de datos
docker-compose exec web rails db:setup
docker-compose exec web rails exercises:import
```

### **Verificar instalación**
```bash
# Test API Status
curl http://localhost:3002/

# Expected Response
{"status": "SmartLift API is running", "timestamp": "..."}
```

### **Configuración de Puertos**
| Servicio     | Puerto | Descripción                    |
|--------------|--------|--------------------------------|
| Rails API    | 3002   | Servidor principal             |
| PostgreSQL   | 5433   | Base de datos                  |
| Redis        | 6380   | Cache y WebSockets             |

## 🛠️ Tecnologías

### **Backend Framework**
- **Ruby on Rails 7.1.3** - Framework web principal
- **PostgreSQL 14+** - Base de datos relacional
- **Redis 7+** - Cache y WebSockets

### **Autenticación y Seguridad**
- **JWT** - JSON Web Tokens para autenticación
- **BCrypt** - Hashing de contraseñas
- **Rack-CORS** - Cross-Origin Resource Sharing
- **Rack-Attack** - Rate limiting y protección

### **APIs y Servicios Externos**
- **HTTParty** - Cliente HTTP para APIs externas
- **Expo Push Notifications** - Notificaciones móviles
- **AI Workout Generation API** - Generación inteligente de rutinas

### **Testing y Calidad**
- **RSpec** - Framework de testing BDD
- **Factory Bot** - Fixtures para tests
- **Shoulda Matchers** - Matchers adicionales
- **Brakeman** - Análisis de seguridad
- **Rubocop** - Linting y estilo de código

### **DevOps y Deployment**
- **Docker** - Containerización
- **Kamal** - Deployment configuration
- **Railway** - Plataforma de hosting

## 📚 Documentación

### **Guías de Configuración**
- 🇪🇸 **[Guía Completa en Español](docs/SETUP_GUIA_ES.md)**
- 🇺🇸 **[Complete Setup Guide](docs/SETUP_GUIDE_EN.md)**
- 🐳 **[Docker Configuration](docs/SETUP_LOCAL.md)**

### **Documentación Técnica**
- 📡 **[API Documentation](docs/API_DOCUMENTATION.md)**
- 🏗️ **[Architecture Overview](docs/ARCHITECTURE.md)**
- 🗄️ **[Database Schema](docs/DATABASE_SCHEMA.md)**
- ⚙️ **[Services Documentation](docs/SERVICES.md)**

### **Recursos para Desarrolladores**
- 🏋️ **[Workout Types](docs/workout_types.md)**
- 🤖 **[AI Integration Guide](docs/AI_WORKOUT_ROUTINE_IMPLEMENTATION.md)**
- 📮 **[Postman Collection](docs/postman/)**
- 📋 **[Development Guide](docs/DEVELOPMENT_GUIDE.md)**

## 🧪 Testing

### **Ejecutar Test Suite**
```bash
# Todos los tests
docker-compose exec web rspec

# Tests específicos
docker-compose exec web rspec spec/models/
docker-compose exec web rspec spec/controllers/
docker-compose exec web rspec spec/services/

# Test con coverage
docker-compose exec web rspec --format documentation
```

### **Métricas de Testing**
- ✅ **90%+** cobertura de código
- ✅ **Unit tests** para todos los modelos críticos
- ✅ **Integration tests** para endpoints principales
- ✅ **Service tests** para lógica de negocio

## 🚢 Deployment

### **Production Ready Features**
- 🐳 **Docker containerization**
- 🔒 **SSL/HTTPS enforcement**
- 📊 **Application monitoring**
- 💾 **Database backups**
- 🚀 **Zero-downtime deployments**

### **Deployment Commands**
```bash
# Build production image
docker build -t smartlift-api .

# Deploy with Kamal
kamal deploy

# Health checks
curl https://your-domain.com/
```

## 👥 Contribución

### **Flujo de Desarrollo**
1. Fork del repositorio
2. Crear feature branch: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Add nueva funcionalidad'`
4. Push branch: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### **Estándares de Código**
- ✅ Seguir **Ruby Style Guide**
- ✅ Tests obligatorios para nuevas features
- ✅ Documentación actualizada
- ✅ Code review requerido

---

## 📊 System Diagrams

### 🗄️ Entity-Relationship Model (ERM)

**Database Schema Overview:**
- ✅ **12 main entities** with well-defined relationships
- ✅ **Single Table Inheritance** correctly implemented
- ✅ **Third Normal Form (3NF)** applied
- ✅ **Weak entity** for workout_sets with composite key
- ✅ **Complete referential integrity**

```mermaid
<!-- Insert your MER diagram here -->
<!-- Example: -->
erDiagram
    users {
        id bigint PK
        first_name varchar_50
        last_name varchar_50
        email varchar_255
        role integer
        created_at timestamp
        updated_at timestamp
    }
    
    user_stats {
        id bigint PK
        user_id bigint FK
        height decimal_5_2
        weight decimal_5_2
        age integer
        gender varchar_20
        fitness_goal varchar_100
        experience_level varchar_20
        created_at timestamp
        updated_at timestamp
    }
    
    workouts {
        id bigint PK
        user_id bigint FK
        routine_id bigint FK
        status varchar_20
        started_at timestamp
        completed_at timestamp
        created_at timestamp
        updated_at timestamp
    }
    
    users ||--o| user_stats : "has profile"
    users ||--o{ workouts : "performs"
    
    <!-- Add more entities as needed -->
```

**Key Relationships:**
- **1:1 Optional**: users ↔ user_stats, user_privacy_settings
- **1:N**: users → routines, workouts, messages
- **N:M**: routines ↔ exercises (via routine_exercises)
- **Weak Entity**: workout_sets depends on workout_exercises

### 🏗️ Class Diagram

**System Architecture Overview:**
- 🏗️ **Single Table Inheritance** (User → Regular User, Trainer, Admin)
- 🔗 **Active Record Associations** optimized for performance
- 📋 **Service Objects** for complex business logic
- 📝 **Serializers** for consistent API responses

```mermaid
<!-- Insert your class diagram here -->
<!-- You can generate it using: rails erd --filename=docs/class_diagram -->

classDiagram
    class User {
        +String first_name
        +String last_name
        +String email
        +Integer role
        +authenticate(password)
        +regular?()
        +coach?()
        +admin?()
    }
    
    class UserStat {
        +Decimal height
        +Decimal weight
        +Integer age
        +String gender
        +String fitness_goal
        +String experience_level
        +belongs_to :user
    }
    
    class Routine {
        +String name
        +Text description
        +String difficulty
        +Integer duration
        +belongs_to :user
        +has_many :routine_exercises
        +has_many :exercises
    }
    
    class Workout {
        +String status
        +DateTime started_at
        +DateTime completed_at
        +belongs_to :user
        +belongs_to :routine
        +has_many :workout_exercises
    }
    
    User ||--|| UserStat : has_one
    User ||--o{ Routine : creates
    User ||--o{ Workout : performs
    Routine ||--o{ Workout : used_in
    
    <!-- Add more classes as needed -->
```

**Design Patterns Implemented:**
- **STI Pattern**: Single table for user hierarchy
- **Service Layer**: Complex business logic separation
- **Repository Pattern**: Data access abstraction
- **Observer Pattern**: Model callbacks and notifications
- **Factory Pattern**: Test data creation

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## 👨‍💻 Authors

**Academic Integration Project - Systems Analyst**
- **Diego Costa** (294879) - [GitHub](https://github.com/diego-costa)
- **Federico Cavallo** (180374) - [GitHub](https://github.com/federico-cavallo)

**Tutor**: Andrés de Sosa  
**Client**: Centro Deportivo Integral Enfoque  
**Institution**: Facultad de Ingeniería  
**Year**: 2025

---

## 🆘 Support

Need help? 

- 📖 Check the [complete documentation](docs/)
- 🐛 Report bugs in [Issues](https://github.com/your-username/smartlift-backend/issues)
- 💬 Join [Discussions](https://github.com/your-username/smartlift-backend/discussions)

---

<div align="center">

**⭐ If you find this project useful, consider giving it a star on GitHub ⭐**

</div>