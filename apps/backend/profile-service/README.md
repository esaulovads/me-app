# Profile Service for Fitness App

This service manages user profiles in the fitness app, including storage and updates of personal data.

## Functionality

- Step-by-step profile setup
- Personal data storage (name, age, height, weight)
- Automatic BMI calculation and status detection
- User goals management (gain/maintain/lose weight)
- Profile completeness check
- BMR calculation (Mifflin-St Jeor formula)
- TDEE calculation based on activity level
- Recommended sleep duration calculation
- Daily macronutrient targets calculation
- Sleep quality coefficient calculation (last 2 weeks)
- Weekly and daily training norm calculation based on age and sleep quality

## Recommended Sleep Duration Calculation

Formula:
**Recommended duration = Base duration + Activity modifier**

### Base sleep duration (hours)

| Age      | Men | Women |
|----------|-----|-------|
| 18-25    | 7.5 | 8.0   |
| 26-35    | 7.5 | 8.0   |
| 36-45    | 7.0 | 7.5   |
| 46-55    | 7.0 | 7.5   |
| 56-65    | 6.5 | 7.0   |
| 65+      | 6.5 | 6.5   |

### Activity modifiers (hours)

**18-35 years**
- Men: Low +0.00, Moderate +0.25, High +0.50, Extreme +0.75
- Women: Low +0.00, Moderate +0.30, High +0.60, Extreme +0.85

**36-55 years**
- Men: Low +0.00, Moderate +0.20, High +0.45, Extreme +0.70
- Women: Low +0.00, Moderate +0.25, High +0.55, Extreme +0.80

**56+ years**
- Men: Low +0.00, Moderate +0.15, High +0.35, Extreme +0.60
- Women: Low +0.00, Moderate +0.20, High +0.40, Extreme +0.65

## Sleep Quality Coefficient

The coefficient is calculated using sleep data from the last 14 days:

**Sleep quality coefficient = Average(actual sleep / recommended sleep) per day**

Algorithm:
1. Get all sleep sessions for the last 14 days
2. Sum sleep time per day
3. Compute actual/recommended ratio for each day
4. Calculate arithmetic mean
5. Round to 3 decimal places

## Training Norm Calculation

Weekly formula:
**Optimal weekly minutes = 150 x Sleep quality coefficient x Age coefficient**

Age coefficients:
- Up to 30: 1.0
- 31-50: 0.8
- 51+: 0.6

Daily formula:
**Optimal daily minutes = Weekly norm / Number of training days**

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
createdb fitness_profiles
```

3. Open service directory:
```bash
cd apps/backend/profile-service
```

4. Install dependencies:
```bash
npm install
```

5. Create `.env`:
```
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_profiles
```

6. Run service:
```bash
# Development mode
npm run start:dev

# Production mode
npm run build
npm run start
```

## API Endpoints

- `GET /profiles` - get user profile
- `GET /profiles/complete` - check profile completeness
- `PUT /profiles/name` - update name
- `PUT /profiles/birth-date` - update birth date
- `PUT /profiles/height` - update height
- `PUT /profiles/weight` - update weight
- `PUT /profiles/goal` - update goal
- `PUT /profiles/gender` - update gender
- `PUT /profiles/activity-level` - update activity level
- `POST /profiles/recalculate-sleep` - recalculate recommended sleep duration
- `POST /profiles/calculate-sleep-quality` - calculate sleep quality coefficient
- `POST /profiles/calculate-training-norms` - calculate training norms
- `POST /profiles/recalculate-training-norms` - full training norms recalculation