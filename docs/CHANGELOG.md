# 📝 SmartLift API - Changelog

## [Recent Updates] - 2024-12-25

### 🔧 Fixed
- **PostgreSQL Connection Issue**: Fixed entrypoint script connection error that prevented proper container startup
- **gitignore Configuration**: Removed `config/database.yml` from `.gitignore` as it's required for the application and contains no sensitive data

### ✨ Added
- **Exercise Database Import**: Successfully integrated free-exercise-db with 873+ exercises
- **Configuration Templates**: Added `config/database.yml.example` for new developers
- **Documentation Consolidation**: Moved all documentation to `docs/` folder for better organization

### 📚 Documentation Updates
- **Setup Guides**: Updated Docker setup guides in both Spanish and English
- **Port Correction**: Fixed API port references (3000 → 3002) throughout documentation
- **New Sections**: Added exercise import instructions and enhanced troubleshooting
- **Documentation Structure**: Reorganized all documentation under `docs/` folder

### 🏗️ Project Structure
- Consolidated `SETUP_LOCAL.md` into `docs/` folder
- Updated main `README.md` with correct ports and simplified setup
- Enhanced `docs/README.md` as comprehensive documentation index

### 🚀 Developer Experience
- Environment now starts completely from scratch without manual database setup
- Automated exercise import available via `rails exercises:import`
- Clearer error messages and troubleshooting guides
- Better documentation organization and discoverability

### 🔍 Technical Details
- **Fixed**: Entrypoint script now correctly connects to PostgreSQL container (`db` host)
- **Imported**: 873 exercises from free-exercise-db successfully loaded
- **Verified**: Full environment setup tested from clean state
- **Optimized**: Documentation structure for maintainability 