This is the backend component of the mobile application for sports clubs and gyms. Implemented with Ruby on Rails, this backend manages the core business logic, including user administration (members and trainers), training routine management (creation, storage, AI integration), user progress tracking, and the infrastructure for the social feed and other services.

It acts as the main API serving data to the mobile application (built with React Native) and orchestrates integration with external services such as the AI routine generation API and the exercise video storage system.

## Development Setup

### Prerequisites
- Docker and Docker Compose
- Ruby 3.2.2
- Node.js 18.x
- Yarn
- PostgreSQL

### Windows Users
We provide two options for Windows users:

#### Option 1: Using WSL2 (Recommended)
For the best development experience, we recommend using WSL2:

1. Install WSL2:
   ```powershell
   wsl --install
   ```

2. Install Docker Desktop for Windows:
   - Download from [Docker's official website](https://www.docker.com/products/docker-desktop)
   - Enable WSL2 integration in Docker Desktop settings

3. Install VS Code with Remote - WSL extension:
   - Install [VS Code](https://code.visualstudio.com/)
   - Install the "Remote - WSL" extension
   - Open your project folder through WSL

#### Option 2: Native Windows Setup
If you prefer not to use WSL2, you can use Docker Desktop for Windows directly:

1. Install Docker Desktop for Windows:
   - Download from [Docker's official website](https://www.docker.com/products/docker-desktop)
   - Make sure to enable the "Use the WSL 2 based engine" option in Docker Desktop settings

2. Install Git for Windows:
   - Download from [Git's official website](https://git-scm.com/download/win)
   - During installation, select "Use Git from Git Bash only"

3. Install VS Code:
   - Download from [VS Code's official website](https://code.visualstudio.com/)
   - Install the "Docker" extension

### Getting Started

1. Clone the repository
2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
3. Start the development environment:
   ```bash
   docker-compose up
   ```
4. In a new terminal, run the database setup:
   ```bash
   docker-compose exec web bundle exec rails db:create db:migrate
   ```

The API will be available at `http://localhost:3000`

## Exercise IDs

The exercise IDs in this system range from 98 to 970. This range is maintained to ensure compatibility with the external exercise database we integrate with. When working with exercises in the API, make sure to use IDs within this range.

Ongoing...
