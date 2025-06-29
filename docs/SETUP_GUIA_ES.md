# 🏋️ SmartLift API - Guía de Configuración Inicial

Esta guía te ayudará a configurar el proyecto SmartLift API desde cero en tu entorno de desarrollo local.

## 📋 Prerrequisitos

Antes de comenzar, asegúrate de tener instalado:

- **Docker** (versión 20.0 o superior)
- **Docker Compose** (versión 2.0 o superior) 
- **Git**

### Verificar Instalación

```bash
docker --version
docker-compose --version
git --version
```

## 🚀 Configuración Inicial

### 1. Clonar el Repositorio

```bash
git clone https://github.com/diecoscai/smartlift_api.git
cd smartlift_api
```

### 2. Verificar Puertos Disponibles

El proyecto usa los siguientes puertos:
- **PostgreSQL**: 5433
- **Redis**: 6380
- **Rails API**: 3002

Verifica que estos puertos estén libres:

```bash
# Verificar puertos
lsof -i :5433
lsof -i :6380
lsof -i :3002
```

Si algún puerto está ocupado, puedes modificar `docker-compose.yml` para usar puertos diferentes.

### 3. Construir y Levantar los Servicios

```bash
# Construir las imágenes
docker-compose build

# Levantar los servicios (base de datos y Redis)
docker-compose up -d db redis

# Esperar que los servicios estén saludables
docker-compose ps
```

### 4. Configurar la Base de Datos

```bash
# Crear la base de datos
docker-compose run --rm web rails db:create

# Ejecutar migraciones
docker-compose run --rm web rails db:migrate

# (Opcional) Poblar con datos de prueba
docker-compose run --rm web rails db:seed
```

### 5. Levantar la Aplicación Web

```bash
# Iniciar el servidor Rails
docker-compose up -d web

# Verificar que todos los servicios estén corriendo
docker-compose ps
```

### 6. Importar Ejercicios (Nuevo - Opcional)

```bash
# Importar base de ejercicios desde free-exercise-db
docker-compose exec web rails exercises:import

# Verificar la importación
docker-compose exec web rails runner "puts Exercise.count"
```

## ✅ Verificación

### Comprobar que la API funciona:

```bash
# Probar el endpoint principal
curl http://localhost:3002/

# Deberías ver una respuesta JSON con los endpoints disponibles
# {"status":"online","version":"1.0.0","endpoints":{...}}
```

### Probar la conexión a la base de datos:

```bash
# Verificar versión de la base de datos
docker-compose run --rm web rails db:version

# Acceder a la consola de Rails
docker-compose exec web rails console
```

## 🛠️ Comandos Útiles para Desarrollo

### Gestión de Contenedores

```bash
# Ver estado de todos los servicios
docker-compose ps

# Ver logs de un servicio específico
docker-compose logs web -f
docker-compose logs db -f

# Reiniciar un servicio
docker-compose restart web

# Detener todos los servicios
docker-compose down

# Detener y eliminar volúmenes (CUIDADO: elimina datos)
docker-compose down -v
```

### Comandos de Rails

```bash
# Consola de Rails
docker-compose exec web rails console

# Generar una migración
docker-compose exec web rails generate migration NombreMigracion

# Ejecutar migraciones
docker-compose run --rm web rails db:migrate

# Rollback de migración
docker-compose run --rm web rails db:rollback

# Ejecutar tests
docker-compose run --rm web bundle exec rspec

# Ejecutar un comando específico en el contenedor
docker-compose exec web bash
```

### Gestión de la Base de Datos

```bash
# Conectar directamente a PostgreSQL
docker-compose exec db psql -U postgres -d smartlift_development

# Hacer backup de la base de datos
docker-compose exec db pg_dump -U postgres smartlift_development > backup.sql

# Restaurar desde backup
docker-compose exec -T db psql -U postgres smartlift_development < backup.sql

# Ver el esquema actual
docker-compose run --rm web rails db:schema:dump
```

## 🐛 Solución de Problemas Comunes

### Error: Puerto ya está en uso

```bash
# Encontrar qué proceso usa el puerto
lsof -i :5433

# Matar el proceso (reemplaza PID con el ID del proceso)
kill -9 PID

# O cambiar el puerto en docker-compose.yml
```

### Error: Contenedor no inicia

```bash
# Ver logs detallados
docker-compose logs [nombre_servicio]

# Reconstruir contenedores
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Error: "connection to server on socket failed"

**Problema**: Error de conexión a PostgreSQL en el entrypoint.
**Solución**: Este problema ha sido corregido en la versión actual del proyecto.

Si encuentras este error:
```bash
# Verificar que los servicios estén healthy
docker-compose ps

# Si persiste, reconstruir completamente
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Error: Base de datos no conecta

```bash
# Verificar que PostgreSQL esté corriendo
docker-compose ps db

# Verificar logs de la base de datos
docker-compose logs db

# Recrear la base de datos
docker-compose run --rm web rails db:drop db:create db:migrate
```

### Error: Migraciones fallan

```bash
# Ver el estado de las migraciones
docker-compose run --rm web rails db:migrate:status

# Hacer rollback y volver a migrar
docker-compose run --rm web rails db:rollback
docker-compose run --rm web rails db:migrate

# En caso extremo, recrear desde schema
docker-compose run --rm web rails db:schema:load
```

## 📁 Estructura del Proyecto

```
smartlift_api/
├── app/
│   ├── controllers/     # Controladores API
│   ├── models/         # Modelos ActiveRecord
│   └── serializers/    # Serializadores JSON
├── config/
│   ├── database.yml    # Configuración BD
│   └── routes.rb       # Rutas API
├── db/
│   ├── migrate/        # Migraciones
│   └── schema.rb       # Esquema actual
├── docs/              # Documentación
├── spec/              # Tests RSpec
├── docker-compose.yml # Configuración Docker
└── Dockerfile.dev     # Imagen Docker desarrollo
```

## 🔧 Configuración de Entorno

Las variables de entorno importantes:

- `DATABASE_HOST`: localhost (desde fuera de Docker)
- `DATABASE_PORT`: 5433
- `DATABASE_USERNAME`: postgres
- `DATABASE_PASSWORD`: password
- `REDIS_URL`: redis://localhost:6380/1

## 📚 Recursos Adicionales

- [Documentación de Docker](https://docs.docker.com/)
- [Guía de Rails](https://guides.rubyonrails.org/)
- [Documentación de PostgreSQL](https://www.postgresql.org/docs/)

## 💡 Consejos para Desarrolladores Junior

1. **Siempre verifica el estado** de los contenedores con `docker-compose ps`
2. **Consulta los logs** cuando algo no funcione: `docker-compose logs`
3. **Haz backup** de tu base de datos antes de cambios importantes
4. **Usa la consola de Rails** para probar código: `docker-compose exec web rails console`
5. **Ejecuta tests** regularmente: `docker-compose run --rm web bundle exec rspec`

---

¿Tienes problemas? Revisa la sección de solución de problemas o consulta los logs detallados.

¡Happy coding! 🚀 