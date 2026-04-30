# Fitness App

A fitness application for tracking nutrition, physical activity, and achieving healthy lifestyle goals.

## Architecture

The project is built with a microservices architecture and consists of the following components:

### Backend (NestJS):
- Auth Service - authorization and user management
- Profile Service - profile management and calorie/macronutrient calculations
- Nutrition Service - nutrition and recipe management
- Sleep Service - sleep schedule management and sleep duration tracking
- **Activity Service** - workout and physical activity tracking with automatic lifted-weight calculations
- Gamification Service - game mechanics and achievements
- Product Scanner Service - barcode scanner integration
- API Gateway - request routing

### Mobile App (Flutter):
- Cross-platform application for iOS and Android

## Core Features

1. User authorization
2. Individual calorie/macronutrient calculation
3. **Automatic recommended sleep duration calculation** - the system calculates a personalized sleep norm based on user gender, age, and physical activity level using science-based recommendations
4. **Sleep quality coefficient calculation** - automatic sleep quality analysis based on actual data from the last 2 weeks with calculation of the average ratio of actual sleep time to recommended sleep time
5. **Workout norm calculation** - automatic calculation of the optimal number of workout minutes per week and per day, considering user age (age coefficient) and sleep quality, with automatic recalculation when parameters change
6. Nutrition tracking with date filtering
7. Product and recipe management
8. Nutrition progress bar with color indicators on the main screen
9. Calculation of consumed calories as a percentage of daily norm
10. Date navigation in the nutrition screen with relative date support
11. Date picker integration for selecting a specific date
12. Performance optimization with caching and debounce
13. Improved network error handling without console output
14. **Detailed meal display** - each meal is displayed with time, list of dishes and their calories/macronutrients, and the total meal summary in the following format: time, dishes with calories/macronutrients, total meal calories/macronutrients
15. **Full-featured product and dish adding** - users can add products and dishes to meals:
    - Modal for entering weight with validation and preset values
    - Automatic calorie/macronutrient calculation based on entered weight
    - Instant adding to meals with updates to all nutrition data
    - Optimized caching for the fastest possible user experience
16. Product barcode scanning
17. **Sleep schedule management** - setting individual wake-up schedules with support for different modes (daily, weekdays/weekends, custom by day) and sleep duration tracking
18. **Workout tracking** - a full-featured workout management system:
    - Creating workouts with date and duration
    - **⏱️ Workout timer** - real-time workout duration tracking with global display
    - **📅 Workout schedule** - weekly schedule setup with muscle group selection for each day of the week (legs, back, biceps, shoulders, triceps, or full-body)
    - Adding exercises from a database with target muscle groups
    - **Inline set editing** - editing reps, weight, and deleting sets directly on the workout screen without navigating to a separate screen
    - Recording sets with rep count and equipment weight
    - Automatic lifted-weight calculation: `reps × weight × number of equipment units`
    - **Improved data type handling** - correct handling of string and numeric values when receiving data from the server
    - Workout statistics and user progress with display of today's planned workout
17. Game mechanics and achievements
18. Level and progress system

## Performance Optimizations

### 🚀 Implemented optimizations:

#### 1. Main thread optimization
- **Isolates for heavy calculations**: Age, BMI, TDEE, and nutrition data processing are moved to separate isolates
- **Isolate pool**: A pool of 2 isolates is created for parallel calculations
- **Asynchronous processing**: All heavy operations run asynchronously without blocking the UI

#### 2. Data caching
- **Profile caching**: Profile data is cached for 5 minutes
- **Nutrition caching**: Nutrition data is cached by date with automatic cleanup
- **Local caching**: Avoids repeated network requests for the same data

#### 3. Network request optimization
- **Batch operations**: Combining multiple requests into one for profile updates
- **Debounce**: Prevents frequent requests during rapid data changes
- **Timeouts**: Reasonable timeouts are set for all HTTP requests
- **Parallel loading**: Simultaneous loading of profile and nutrition data

#### 4. Widget optimization
- **RepaintBoundary**: Repaint boundaries are added to isolate updates
- **Const constructors**: Using const for immutable widgets
- **Lazy loading**: Data is loaded only when needed
- **Optimized lists**: Using SliverList for large lists

#### 5. Performance monitoring
- **FPS tracking**: Monitoring dropped frames and render time
- **Operation measurement**: Logging execution time of critical operations
- **Performance reports**: Generating detailed performance reports
- **Warnings**: Automatic warnings about slow operations

### 📊 Optimization results:

**Before optimization:**
- Dropped frames: 418+ frames
- Render time: up to 2042ms
- Main thread blocking

**After optimization:**
- Significant reduction in dropped frames
- Smooth animations and transitions
- Fast data loading
- Responsive user interface

### 🛠️ Technical details:

#### Performance architecture:
```
┌─────────────────────────────────────────┐
│           UI Thread (Main)              │
│  ┌─────────────────────────────────────┐ │
│  │        Widget Tree                  │ │
│  │  ┌─────────────────────────────────┐│ │
│  │  │     RepaintBoundary            ││ │
│  │  └─────────────────────────────────┘│ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│         Performance Services            │
│  ┌─────────────────────────────────────┐ │
│  │     Isolate Pool (2 workers)       │ │
│  │  ┌─────────────┐ ┌─────────────────┐│ │
│  │  │  Isolate 1  │ │   Isolate 2     ││ │
│  │  │  (Age calc) │ │  (TDEE calc)    ││ │
│  │  └─────────────┘ └─────────────────┘│ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            Cache Layer                  │
│  ┌─────────────────────────────────────┐ │
│  │  Profile Cache (5 min TTL)          │ │
│  │  Nutrition Cache (by date)          │ │
│  │  Network Request Debounce           │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

#### Core services:
- **PerformanceService**: Manages isolates and heavy calculations
- **PerformanceMonitor**: Monitors FPS and operation execution time
- **ProfileService**: Caching and batch operations for profile data
- **NutritionService**: Optimized nutrition data loading

## Docker Launch

### Prerequisites

1. Create environment variable files:

**apps/backend/auth-service/.env:**
```env
# Service port
AUTH_SERVICE_PORT=3000

# JWT settings
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=1d

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=auth_db

# Application settings
NODE_ENV=development
API_PREFIX=/api/v1
```

**apps/backend/profile-service/.env:**
```env
# Service port
PROFILE_SERVICE_PORT=3001

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=profile_db

# Application settings
NODE_ENV=development
API_PREFIX=/api/v1
```

**apps/backend/nutrition-service/.env:**
```env
PORT=3002
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_nutrition
NODE_ENV=development
```

**apps/backend/sleep-service/.env:**
```env
PORT=3003
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_sleep
NODE_ENV=development
```

**apps/backend/activity-service/.env:**
```env
PORT=3004
DB_HOST=postgres
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_activity
NODE_ENV=development
```

### Container startup

1. Build and start containers:
```bash
docker-compose up --build
```

2. Start in detached mode:
```bash
docker-compose up -d --build
```

3. Stop containers:
```bash
docker-compose down
```

### Postman testing

1. Import test collections from service directories:
   - `apps/backend/auth-service/postman/collection.json`
   - `apps/backend/profile-service/postman/collection.json`

2. Services will be available at the following addresses:
   - Auth Service: http://localhost:3000
   - Profile Service: http://localhost:3001
   - Nutrition Service: http://localhost:3002
   - Sleep Service: http://localhost:3003
   - Activity Service: http://localhost:3004

### Viewing logs

```bash
# Logs for all services
docker-compose logs -f

# Logs for a specific service
docker-compose logs -f auth-service
docker-compose logs -f profile-service
docker-compose logs -f nutrition-service
docker-compose logs -f sleep-service
docker-compose logs -f activity-service
```

### Container management

```bash
# Restart a specific service
docker-compose restart auth-service
docker-compose restart profile-service
docker-compose restart nutrition-service
docker-compose restart sleep-service
docker-compose restart activity-service

# Stop a specific service
docker-compose stop auth-service
docker-compose stop profile-service
docker-compose stop nutrition-service
docker-compose stop sleep-service
docker-compose stop activity-service

# Start a specific service
docker-compose start auth-service
docker-compose start profile-service
docker-compose start nutrition-service
docker-compose start sleep-service
docker-compose start activity-service
```

## Performance Monitoring

### View performance logs:
```bash
flutter logs | grep PERF
```

### Generate performance report:
```dart
final monitor = PerformanceMonitor();
final report = monitor.generatePerformanceReport();
print(report);
```

### Measure operation time:
```dart
// Synchronous operations
final result = monitor.measureOperation('Operation name', () {
  // Your code
});

// Asynchronous operations
final result = await monitor.measureAsyncOperation('Async operation', () async {
  // Your async code
});
```