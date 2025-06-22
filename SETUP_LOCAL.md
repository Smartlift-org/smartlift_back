# 🚀 Guía de Configuración Local - SmartLift API

Esta guía te permitirá ejecutar el proyecto localmente con PostgreSQL en puerto 5433, manteniendo tu instancia de Docker en puerto 5432.

## 📋 Prerrequisitos

- PostgreSQL instalado via Homebrew
- Ruby (recomendado via rbenv o mise)
- Bundler

## 🛠️ Configuración Inicial (Solo una vez)

### 1. Instalar PostgreSQL (si no lo tienes)
```bash
brew install postgresql@14
```

### 2. Crear archivo de variables de entorno
```bash
# Crear archivo .env.local (NO se sube al repo)
cat > .env.local << EOF
DATABASE_USERNAME=diegocosta
DATABASE_PASSWORD=
DATABASE_HOST=localhost
DATABASE_PORT=5433
EOF
```

### 3. Verificar configuración de base de datos
El archivo `config/database.yml` ya está configurado para usar estas variables.

## 🚀 Ejecutar el Entorno (Diariamente)

### Paso 1: Iniciar PostgreSQL Local
```bash
# Iniciar PostgreSQL en puerto 5433
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 -o "-p 5433" start

# Verificar que está corriendo
lsof -i :5433
```

### Paso 2: Cargar Variables de Entorno
```bash
# Cargar variables desde .env.local
export $(cat .env.local | grep -v '^#' | xargs)

# O usar este comando si tienes problemas:
source .env.local
export DATABASE_USERNAME DATABASE_PASSWORD DATABASE_HOST DATABASE_PORT
```

### Paso 3: Configurar Ruby/Bundler (si hay problemas)
```bash
# Si tienes problemas con bundler, reinstalar gems
bundle install

# Si hay problemas con versiones de bundler
gem install bundler
bundle update --bundler
```

### Paso 4: Crear/Migrar Base de Datos
```bash
# Crear base de datos (solo primera vez)
bundle exec rails db:create

# Ejecutar migraciones
bundle exec rails db:migrate

# Ejecutar seeds (opcional)
bundle exec rails db:seed
```

### Paso 5: Ejecutar la Aplicación
```bash
# Iniciar servidor Rails
bundle exec rails server

# O usar el puerto específico
bundle exec rails server -p 3000
```

## 🛠️ Comandos Útiles

### Gestión de PostgreSQL
```bash
# Iniciar PostgreSQL
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 -o "-p 5433" start

# Detener PostgreSQL
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 stop

# Reiniciar PostgreSQL
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 restart

# Conectar a la base de datos
/usr/local/opt/postgresql@14/bin/psql -h localhost -p 5433 -U diegocosta -d smartlift_api_development
```

### Gestión de Base de Datos
```bash
# Resetear base de datos completa
bundle exec rails db:drop db:create db:migrate db:seed

# Solo migrar
bundle exec rails db:migrate

# Rollback última migración
bundle exec rails db:rollback

# Ver estado de migraciones
bundle exec rails db:migrate:status
```

### Testing
```bash
# Ejecutar todos los tests
bundle exec rspec

# Ejecutar tests específicos
bundle exec rspec spec/controllers/workouts_controller_spec.rb

# Ejecutar tests con cobertura
COVERAGE=true bundle exec rspec
```

### Rails Console
```bash
# Abrir consola Rails
bundle exec rails console

# Ejemplos de uso en consola:
# User.count
# Workout.last
# Exercise.all
```

## 🔧 Troubleshooting

### Problema: Puerto 5433 ocupado
```bash
# Ver qué proceso usa el puerto
lsof -i :5433

# Matar proceso si es necesario
kill -9 <PID>
```

### Problema: No se puede conectar a PostgreSQL
```bash
# Verificar que PostgreSQL está corriendo
ps aux | grep postgres

# Verificar logs de PostgreSQL
tail -f /usr/local/var/log/postgresql@14.log
```

### Problema: Bundler version mismatch
```bash
# Actualizar bundler
gem install bundler
bundle update --bundler

# O reinstalar gems
rm Gemfile.lock
bundle install
```

### Problema: Variables de entorno no cargan
```bash
# Método alternativo para cargar variables
set -a
source .env.local
set +a

# Verificar que están cargadas
echo $DATABASE_PORT
```

### Problema: Migraciones fallan
```bash
# Ver qué migraciones están pendientes
bundle exec rails db:migrate:status

# Ejecutar migración específica
bundle exec rails db:migrate:up VERSION=20250620000007
```

## 📊 Verificación del Entorno

### Verificar que todo funciona:
```bash
# 1. PostgreSQL corriendo
lsof -i :5433

# 2. Variables cargadas
env | grep DATABASE

# 3. Base de datos accesible
/usr/local/opt/postgresql@14/bin/psql -h localhost -p 5433 -U diegocosta -c "SELECT version();" smartlift_api_development

# 4. Rails puede conectar
bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"
```

## 🌐 URLs Importantes

Una vez que tengas todo corriendo:
- **API**: http://localhost:3000
- **Health Check**: http://localhost:3000/up
- **Rails Console**: `bundle exec rails console`

## 📝 Notas Importantes

1. **Dos PostgreSQL simultáneos**:
   - Puerto 5432: Tu instancia Docker
   - Puerto 5433: Esta aplicación local

2. **Archivo .env.local**:
   - NO se sube al repositorio
   - Contiene tu configuración local

3. **Para producción**:
   - Usar variables de entorno del sistema
   - No usar .env.local en producción

## 🆘 Comandos de Emergencia

Si algo sale mal y necesitas resetear todo:

```bash
# Detener PostgreSQL
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 stop

# Limpiar base de datos
bundle exec rails db:drop

# Reiniciar PostgreSQL
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 -o "-p 5433" start

# Recrear todo
bundle exec rails db:create db:migrate db:seed

# Ejecutar tests para verificar
bundle exec rspec
```

---

## 🤝 Script de Inicio Rápido

Puedes crear este script para automatizar el inicio:

```bash
# Crear archivo start_dev.sh
cat > start_dev.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando entorno SmartLift API..."

# Cargar variables de entorno
export $(cat .env.local | grep -v '^#' | xargs)

# Iniciar PostgreSQL
echo "📊 Iniciando PostgreSQL..."
/usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 -o "-p 5433" start

# Esperar un momento
sleep 2

# Verificar conexión
echo "🔍 Verificando conexión a base de datos..."
bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Base de datos conectada correctamente"
    echo "🚀 Iniciando servidor Rails..."
    bundle exec rails server
else
    echo "❌ Error conectando a la base de datos"
    echo "🔧 Verifica la configuración"
fi
EOF

# Hacer ejecutable
chmod +x start_dev.sh

# Usar con:
# ./start_dev.sh
``` 