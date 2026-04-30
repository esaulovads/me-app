# Sleep Service for Fitness App

This service manages user sleep in the fitness app, including sleep sessions, sleep duration tracking, and sleep schedule configuration.

## Functionality

### Sleep Sessions
- Create sleep sessions with sleep and wake timestamps
- Automatic duration calculation in minutes and hours
- Support multiple sessions per day (for example, naps)
- Get sessions for a specific date or date range
- Edit and delete sessions

### Sleep Schedules
- Create and update personal sleep schedule
- Three schedule modes:
  - **SAME_TIME** (recommended): one wake time for all days
  - **WEEKDAYS_WEEKENDS**: different wake times for weekdays and weekends
  - **INDIVIDUAL**: separate wake time for each day of the week
- Enable/disable schedule
- Get wake time for a specific date

### Sleep Analysis
- Get total daily sleep duration
- Automatic sleep date detection by sleep time
- Validation (wake time must be later than sleep time)

## Tech Stack

- Node.js
- NestJS
- TypeScript
- PostgreSQL
- TypeORM

## Installation and Launch

### Prerequisites

1. Install PostgreSQL:
```bash
brew install postgresql@14
```

### Service Startup

1. Start PostgreSQL:
```bash
brew services start postgresql@14
```

2. Create database:
```bash
createdb fitness_sleep
```

3. Go to service directory:
```bash
cd apps/backend/sleep-service
```

4. Install dependencies:
```bash
npm install
```

5. Create `.env`:
```
PORT=3003
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_sleep
```

6. Run migrations:
```bash
npm run migration:run
```

7. Start service:
```bash
# Development mode
npm run start:dev

# Production mode
npm run build
npm run start
```

## API Endpoints

### Sleep Sessions
- `POST /sleep` - create session
- `GET /sleep` - get sessions by day or range
- `GET /sleep/duration` - get total duration for day
- `GET /sleep/sessions/range` - get sessions by date range
- `GET /sleep/:id` - get session by id
- `PUT /sleep/:id` - update session
- `DELETE /sleep/:id` - delete session

### Sleep Schedule
- `POST /sleep/schedule` - create/update schedule
- `GET /sleep/schedule` - get schedule
- `PUT /sleep/schedule` - update schedule
- `DELETE /sleep/schedule` - delete schedule
- `GET /sleep/schedule/wake-time` - get wake time for date

## Database Structure

### `sleep_sessions`
- `id` (uuid, primary key)
- `user_id` (varchar)
- `sleep_time` (timestamp with time zone)
- `wake_time` (timestamp with time zone)
- `duration_minutes` (int)
- `sleep_date` (date)
- `created_at` (timestamp with time zone)
- `updated_at` (timestamp with time zone)

### `sleep_schedules`
- `id` (uuid, primary key)
- `user_id` (varchar, unique)
- `schedule_type` (enum: `INDIVIDUAL`, `WEEKDAYS_WEEKENDS`, `SAME_TIME`)
- daily/weekly wake time fields in `HH:mm`
- `is_enabled` (boolean)
- `created_at` (timestamp with time zone)
- `updated_at` (timestamp with time zone)

## Schedule Types

### SAME_TIME
One wake time for all week days. Best for stable circadian rhythm.

### WEEKDAYS_WEEKENDS
Different wake times for weekdays and weekends.

### INDIVIDUAL
Custom wake time for each day. Most flexible mode.

## Errors and Validation

- `400 Bad Request` - wake time must be later than sleep time
- `400 Bad Request` - `user-id` header is required
- `400 Bad Request` - invalid date/time format
- `400 Bad Request` - invalid wake time format (must be `HH:mm`)
- `404 Not Found` - sleep session not found
- `404 Not Found` - sleep schedule not found

## Migrations

```bash
# Run migrations
npm run migration:run

# Create migration
npm run migration:create -- MigrationName

# Generate migration from entity changes
npm run migration:generate -- MigrationName

# Revert last migration
npm run migration:revert
```