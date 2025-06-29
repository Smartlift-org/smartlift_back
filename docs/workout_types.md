# 🏋️ Tipos de Workout en SmartLift API

SmartLift API soporta dos tipos de workouts para adaptarse a diferentes estilos de entrenamiento:

## 📋 **1. Workouts Basados en Rutinas** (routine_based)

Workouts que siguen una rutina predefinida. Los ejercicios se copian automáticamente al crear el workout.

### Crear Workout con Rutina
```bash
POST /workouts
{
  "workout": {
    "routine_id": 1
  }
}
```

### Características:
- ✅ Ejercicios copiados automáticamente de la rutina
- ✅ Se puede verificar si se siguió la rutina prescrita
- ✅ Ideal para seguimiento estructurado
- ✅ Mantiene referencia a la rutina original

---

## 🎯 **2. Workouts Libres** (free_style)

Workouts creados sin rutina base. El usuario va agregando ejercicios sobre la marcha.

### Crear Workout Libre
```bash
POST /workouts/free
{
  "workout": {
    "name": "Entrenamiento Improvisado"
  }
}
```

### Características:
- ✅ Sin ejercicios predefinidos
- ✅ Máxima flexibilidad durante el entrenamiento
- ✅ Ideal para entrenamientos espontáneos
- ✅ Se puede personalizar completamente

---

## 🔄 **Flujo de Uso - Workouts Libres**

### 1. Crear Workout Libre
```bash
POST /workouts/free
{
  "workout": {
    "name": "Push Day Improvisado"
  }
}

# Respuesta:
{
  "id": 1,
  "workout_type": "free_style",
  "name": "Push Day Improvisado",
  "status": "in_progress",
  "has_exercises": false,
  "routine_id": null,
  ...
}
```

### 2. Agregar Ejercicios Durante el Workout
```bash
POST /workout/exercises
{
  "workout_exercise": {
    "exercise_id": 1,  # Bench Press
    "target_sets": 4,
    "target_reps": 8,
    "suggested_weight": 80,
    "group_type": "regular"
  }
}
```

### 3. Crear Supersets (Opcional)
```bash
# Primer ejercicio del superset
POST /workout/exercises
{
  "workout_exercise": {
    "exercise_id": 2,  # Incline Press
    "target_sets": 3,
    "target_reps": 10,
    "group_type": "superset",
    "group_order": 1
  }
}

# Segundo ejercicio del superset
POST /workout/exercises
{
  "workout_exercise": {
    "exercise_id": 3,  # Flyes
    "target_sets": 3,
    "target_reps": 12,
    "group_type": "superset",
    "group_order": 1
  }
}
```

### 4. Registrar Series
```bash
POST /workout/exercises/1/record_set
{
  "set": {
    "weight": 80,
    "reps": 8,
    "rpe": 7
  }
}
```

### 5. Completar Workout
```bash
PUT /workouts/1/complete
{
  "workout_rating": 8,
  "notes": "Excellent pump today!",
  "total_duration_seconds": 3600
}
```

**Importante:** El frontend debe manejar su propio timer y enviar la duración total (`total_duration_seconds`) al completar el workout. Esto proporciona mayor precisión que el cálculo automático del backend.

---

## 🎛️ **Flexibilidad Adicional**

### Modificar Workouts con Rutina
Incluso los workouts basados en rutinas permiten agregar ejercicios extra:

```bash
# En un workout basado en rutina, agregar ejercicio adicional
POST /workout/exercises
{
  "workout_exercise": {
    "exercise_id": 10,  # Ejercicio extra
    "target_sets": 2,
    "target_reps": 15,
    "notes": "Ejercicio adicional para acabar"
  }
}
```

### Cambiar Objetivo de Ejercicios
```bash
# Modificar sets/reps objetivo durante el workout
PUT /workout/exercises/1
{
  "workout_exercise": {
    "target_sets": 5,     # Era 4, ahora 5
    "target_reps": 6,     # Era 8, ahora 6
    "suggested_weight": 85 # Aumentar peso
  }
}
```

---

## 📊 **Diferencias en Tracking**

| Característica | Routine-Based | Free-Style |
|---------------|---------------|------------|
| **Ejercicios Iniciales** | ✅ Copiados automáticamente | ❌ Se agregan manualmente |
| **Flexibilidad** | 🟡 Media (puede agregar extras) | ✅ Total |
| **Estructura** | ✅ Predefinida | 🔧 Definida por usuario |
| **Progresión** | ✅ Basada en historial de rutina | 🔧 Basada en ejercicios individuales |

---

## 🚀 **Endpoints Disponibles**

### Gestión de Workouts
```bash
POST   /workouts          # Crear workout con rutina
POST   /workouts/free     # Crear workout libre
GET    /workouts          # Listar todos los workouts
GET    /workouts/:id      # Ver workout específico
PUT    /workouts/:id/pause    # Pausar workout
PUT    /workouts/:id/resume   # Reanudar workout  
PUT    /workouts/:id/complete # Completar workout
PUT    /workouts/:id/abandon  # Abandonar workout
```

### Durante el Workout (Ambos Tipos)
```bash
GET    /workout/exercises              # Ver ejercicios del workout activo
POST   /workout/exercises              # Agregar ejercicio al workout activo
POST   /workout/exercises/:id/record_set # Registrar serie
PUT    /workout/exercises/:id/complete   # Completar ejercicio
POST   /workout/exercises/:id/sets       # Crear serie manualmente
PUT    /workout/exercises/:id/sets/:id/complete # Completar serie
```

---

## 💡 **Casos de Uso Recomendados**

### ✅ **Usar Routine-Based Cuando:**
- Sigues un programa de entrenamiento estructurado
- Quieres tracking de progresión consistente
- Entrenas con plan predefinido
- Necesitas métricas de cumplimiento

### ✅ **Usar Free-Style Cuando:**
- Entrenamientos espontáneos
- Disponibilidad limitada de equipamiento
- Días de "sentir el cuerpo"
- Workouts únicos o experimentales
- Entrenamiento en casa sin plan fijo

---

¡Ambos tipos de workout mantienen todas las características avanzadas como detección de récords personales, pausas, métricas de volumen, y más! 💪 