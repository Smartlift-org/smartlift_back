#!/bin/bash

echo "🚀 Iniciando entorno SmartLift API..."

# Verificar que existe .env.local
if [ ! -f .env.local ]; then
    echo "❌ Archivo .env.local no encontrado"
    echo "📝 Creando archivo .env.local..."
    cat > .env.local << EOF
DATABASE_USERNAME=diegocosta
DATABASE_PASSWORD=
DATABASE_HOST=localhost
DATABASE_PORT=5433
EOF
    echo "✅ Archivo .env.local creado"
fi

# Cargar variables de entorno
echo "📋 Cargando variables de entorno..."
export $(cat .env.local | grep -v '^#' | xargs)

# Verificar si PostgreSQL ya está corriendo
if lsof -i :5433 > /dev/null 2>&1; then
    echo "✅ PostgreSQL ya está corriendo en puerto 5433"
else
    # Iniciar PostgreSQL
    echo "📊 Iniciando PostgreSQL en puerto 5433..."
    /usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14 -o "-p 5433" start
    
    # Esperar un momento para que inicie
    echo "⏳ Esperando que PostgreSQL inicie..."
    sleep 3
fi

# Verificar conexión a base de datos
echo "🔍 Verificando conexión a base de datos..."
if bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
    echo "✅ Base de datos conectada correctamente"
    
    # Verificar si necesita migraciones
    echo "🔄 Verificando migraciones pendientes..."
    if bundle exec rails db:migrate:status | grep -q "down"; then
        echo "📈 Ejecutando migraciones pendientes..."
        bundle exec rails db:migrate
    else
        echo "✅ Todas las migraciones están al día"
    fi
    
    echo ""
    echo "🌐 URLs disponibles:"
    echo "   - API: http://localhost:3002"
    echo "   - Health Check: http://localhost:3002/up"
    echo ""
    echo "🚀 Iniciando servidor Rails..."
    echo "   Presiona Ctrl+C para detener el servidor"
    echo ""
    
    bundle exec rails server -p 3002
else
    echo "❌ Error conectando a la base de datos"
    echo ""
    echo "🔧 Posibles soluciones:"
    echo "   1. Verificar que PostgreSQL esté corriendo:"
    echo "      lsof -i :5433"
    echo ""
    echo "   2. Crear la base de datos si no existe:"
    echo "      bundle exec rails db:create"
    echo ""
    echo "   3. Verificar variables de entorno:"
    echo "      env | grep DATABASE"
    echo ""
    echo "   4. Conectar manualmente a PostgreSQL:"
    echo "      /usr/local/opt/postgresql@14/bin/psql -h localhost -p 5433 -U diegocosta"
fi 