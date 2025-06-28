# 📋 SmartLift API - Tickets & Task Management

Esta carpeta contiene los tickets de desarrollo, tareas, y documentación técnica para el proyecto SmartLift API. Todos los archivos en esta carpeta están incluidos en `.gitignore` para mantener la gestión de tareas local al entorno de desarrollo.

## 📁 Estructura

```
tickets/
├── README.md                                    # Este archivo
├── TICKET_001_AI_WORKOUT_ROUTINE_GENERATION.md  # Integración de IA para rutinas
├── TEMPLATE_TICKET.md                           # Plantilla para nuevos tickets
└── [otros tickets...]
```

## 🎯 Convenciones de Nomenclatura

### Tickets de Desarrollo
```
TICKET_XXX_[DESCRIPCION_BREVE].md
```

Ejemplos:
- `TICKET_001_AI_WORKOUT_ROUTINE_GENERATION.md`
- `TICKET_002_USER_AUTHENTICATION_IMPROVEMENTS.md`
- `TICKET_003_EXERCISE_SEARCH_OPTIMIZATION.md`

### Estados de Tickets
- 📋 **Ready for Development** - Listo para implementar
- 🚧 **In Progress** - En desarrollo
- 🔍 **Code Review** - En revisión
- ✅ **Completed** - Completado
- ❌ **Cancelled** - Cancelado
- 🔄 **Blocked** - Bloqueado

### Prioridades
- 🔥 **High** - Alta prioridad
- 🟡 **Medium** - Prioridad media
- 🟢 **Low** - Prioridad baja

## 📝 Formato de Tickets

Cada ticket debe incluir:

1. **Header:** Estado, prioridad, tiempo estimado
2. **Título y Descripción:** Qué se va a construir
3. **Objetivo:** Por qué es importante
4. **Especificaciones Técnicas:** Cómo implementarlo
5. **Tareas Detalladas:** Lista de subtareas
6. **Criterios de Aceptación:** Cómo validar que está completo
7. **Consideraciones:** Riesgos, dependencias, notas

## 🚀 Uso

1. **Crear nuevo ticket:** Copia `TEMPLATE_TICKET.md` y renómbralo
2. **Actualizar estado:** Modifica el header cuando cambie el estado
3. **Agregar notas:** Usa la sección de notas para actualizaciones
4. **Cerrar ticket:** Cambia estado a ✅ Completed cuando termine

## 🔧 Herramientas Recomendadas

- **VSCode:** Con extensiones de Markdown para mejor visualización
- **Obsidian:** Para gestión avanzada de tickets interconectados
- **GitHub Issues:** Para tickets que requieren colaboración externa

---

**Nota:** Esta carpeta está en `.gitignore` para mantener la gestión de tareas local. Si necesitas compartir un ticket específico, cópialo a la carpeta `docs/` o créalo como GitHub Issue. 