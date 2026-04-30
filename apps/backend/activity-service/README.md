# Workout Tracking Service for Fitness App

This service is responsible for managing user workouts in the fitness app, including workout creation, adding exercises, and tracking sets with automatic lifted-weight calculation.

## Functionality

### Exercise Management
- Creating new exercises in the database with target muscle groups
- Specifying the number of equipment units required for an exercise
- Retrieving all exercises with search and muscle-group filtering
- Editing and deleting exercises

### Workout Management
- Creating new workouts with a specified date
- Specifying workout duration and target muscle groups
- Automatic total lifted-weight calculation for workouts
- Retrieving workouts for a day, date range, or all user workouts
- User workout statistics

### Workout Exercise Management
- Adding exercises from the database to a specific workout
- Automatic update of workout target muscle groups
- Calculation of total weight lifted within a specific exercise

### Set Management
- Adding sets to exercises with reps and weight
- Automatic real-time weight calculation: `reps × equipment weight × number of equipment units`
- Bulk creation of exercise sets
- Editing and deleting sets with total weight recalculation

## Tech Stack

- Node.js
- NestJS
- TypeScript
- PostgreSQL
- TypeORM

## Installation and Launch

### Prerequisites

1. Install PostgreSQL (if not installed yet):
```bash
brew install postgresql@14
```

### Service Startup

1. Start PostgreSQL:
```bash
brew services start postgresql@14
```

2. Create a database:
```bash
createdb fitness_activity
```

3. Go to the service directory:
```bash
cd apps/backend/activity-service
```

4. Install dependencies:
```bash
npm install
```

5. Create a `.env` file in the `activity-service` directory and add the following variables:
```
PORT=3004
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_activity
```

6. Run migrations:
```bash
npm run migration:run
```

7. Start the service:
```bash
# Development mode
npm run start:dev

# Production mode
npm run build
npm run start
```

### Stopping the Service

1. Stop the service: press `Ctrl + C` in the terminal where the service is running
2. Stop PostgreSQL:
```bash
brew services stop postgresql@14
```

## API Endpoints

### Exercises

#### POST /exercises
Create a new exercise in the database.

Request body:
```json
{
  "name": "Жим лежа",
  "targetMuscleGroup": "Грудь",
  "equipmentCount": 1
}

{
  "name": "Жим гантелей лежа",
  "targetMuscleGroup": "Грудь", 
  "equipmentCount": 2
}
```

#### GET /exercises
Get all exercises with search and filtering.

Query parameters:
```
limit: number (default 50)
offset: number (default 0)
search: string (search by name)
muscleGroup: string (muscle group filter)
```

#### GET /exercises/muscle-groups
Get all unique muscle groups.

### Workouts

#### POST /workouts
Create a new workout.

Headers:
```
user-id: string
Content-Type: application/json
```

Request body:
```json
{
  "date": "2024-03-20",
  "duration": 90,
  "targetMuscleGroups": ["Грудь", "Трицепс"]
}
```

#### GET /workouts
Get all user workouts.

Headers:
```
user-id: string
```

Query parameters:
```
limit: number (default 20)
offset: number (default 0)
startDate: YYYY-MM-DD (from date filter)
endDate: YYYY-MM-DD (to date filter)
```

#### GET /workouts/by-date
Get all workouts for a specific day.

Headers:
```
user-id: string
```

Query parameters:
```
date: YYYY-MM-DD (required parameter)
```

#### GET /workouts/statistics
Get user workout statistics.

Headers:
```
user-id: string
```

Query parameters:
```
startDate: YYYY-MM-DD (optional)
endDate: YYYY-MM-DD (optional)
```

Response:
```json
{
  "totalWorkouts": 25,
  "totalWeight": 15750.5,
  "totalDuration": 2250,
  "averageWeight": 630.02,
  "averageDuration": 90
}
```

### Workout Exercises

#### POST /workout-exercises
Add an exercise to a workout.

Request body:
```json
{
  "workoutId": "workout-uuid",
  "exerciseId": "exercise-uuid"
}
```

#### GET /workout-exercises/by-workout/:workoutId
Get all exercises for a specific workout.

### Sets

#### POST /sets
Create a new set.

Request body:
```json
{
  "workoutExerciseId": "workout-exercise-uuid",
  "reps": 10,
  "weight": 80.5
}
```

#### POST /sets/bulk/:workoutExerciseId
Bulk create sets for an exercise.

Request body:
```json
[
  {
    "reps": 12,
    "weight": 80
  },
  {
    "reps": 10,
    "weight": 85
  },
  {
    "reps": 8,
    "weight": 90
  }
]
```

#### PUT /sets/:id
Update a set.

Request body:
```json
{
  "reps": 12,
  "weight": 85
}
```

#### DELETE /sets/:id
Delete a set.

## Weight Calculation

The system automatically calculates lifted weight on multiple levels:

### Set Weight
Calculated when creating/updating a set:
```
Set weight = number of reps × equipment weight × number of equipment units
```

### Exercise Weight in Workout
Calculated as the sum of all sets for the exercise:
```
Exercise weight = sum of all set weights
```

### Total Workout Weight
Calculated as the sum of weights of all workout exercises:
```
Total workout weight = sum of all exercise weights
```

All calculations are performed automatically when sets are added, changed, or deleted, ensuring real-time data consistency.
