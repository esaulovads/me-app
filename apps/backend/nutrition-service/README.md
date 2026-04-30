# Nutrition Service for Fitness App

This service is responsible for managing user nutrition in the fitness app, including creating products, dishes, and tracking meals.

## Functionality

### Product Management
- Creating new products with calories/macronutrients per 100 grams
- Specifying serving weight for a product
- Automatic calorie/macronutrient calculation for servings
- Retrieving the full list of user products
- Editing and deleting products

### Dish Management
- Creating new dishes from one or more products
- Specifying the weight of each product in a dish
- Automatic calculation of final dish calories/macronutrients
- Calories/macronutrients calculation per 100 grams of dish
- Retrieving the full list of user dishes
- Editing and deleting dishes

### Meal Management
- Creating meals with specified time
- Adding products and dishes to meals with specified weight
- Automatic meal calories/macronutrients calculation
- Retrieving all meals for a day
- Calculating total daily calories/macronutrients
- Comparing actual intake with the norm from the user profile

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
createdb fitness_nutrition
```

3. Go to the service directory:
```bash
cd apps/backend/nutrition-service
```

4. Install dependencies:
```bash
npm install
```

5. Create a `.env` file in the `nutrition-service` directory and add the following variables:
```
PORT=3002
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_nutrition
```

6. Start the service:
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

### Products

#### POST /products
Create a new product.

Headers:
```
user-id: string
Content-Type: application/json
```

Request body:
```json
{
  "name": "Куриная грудка",
  "caloriesPer100g": 110,
  "proteinsPer100g": 23,
  "fatsPer100g": 1.5,
  "carbsPer100g": 0,
  "servingWeight": 180
}

{
  "name": "Подсолнечное масло",
  "caloriesPer100g": 884,
  "proteinsPer100g": 0,
  "fatsPer100g": 100,
  "carbsPer100g": 0,
  "servingWeight": 14
}
```

#### GET /products
Get the full list of user products.

Headers:
```
user-id: string
```

### Dishes

#### POST /dishes
Create a new dish.

Headers:
```
user-id: string
Content-Type: application/json
```

Request body:
```json
{
  "name": "Жареная куриная грудка",
  "ingredients": [
    {
      "productId": "uuid",
      "weight": 180
    },
    {
      "productId": "uuid",
      "weight": 15
    }
  ]
}
```

#### GET /dishes
Get the full list of user dishes.

Headers:
```
user-id: string
```

### Meals

#### POST /meals
Create a new meal.

Headers:
```
user-id: string
Content-Type: application/json
```

Request body:
```json
{
  "time": "2024-03-20T12:00:00Z",
  "items": [
    {
      "type": "PRODUCT",
      "id": "product-uuid",
      "weight": 200
    },
    {
      "type": "DISH",
      "id": "dish-uuid",
      "weight": 300
    }
  ]
}
```

#### GET /meals
Get all meals for a specific day.

Headers:
```
user-id: string
```

Query parameters:
```
date: YYYY-MM-DD (required parameter)
```

Request example:
```
GET /meals?date=2024-03-20
```

Response:
```json
[
  {
    "id": "meal-uuid",
    "userId": "user-uuid",
    "time": "2024-03-20T12:00:00Z",
    "totalCalories": 450,
    "totalProteins": 35,
    "totalFats": 15,
    "totalCarbs": 40,
    "items": [
      {
        "id": "item-uuid",
        "type": "PRODUCT",
        "productId": "product-uuid",
        "weight": 200,
        "calories": 220,
        "proteins": 23,
        "fats": 1.5,
        "carbs": 0
      }
    ]
  }
]
```

#### GET /meals/summary
Get total calories/macronutrients for a specific day.

Headers:
```
user-id: string
```

Query parameters:
```
date: YYYY-MM-DD (required parameter)
```

Request example:
```
GET /meals/summary?date=2024-03-20
```

Response:
```json
{
  "totalCalories": 1850,
  "totalProteins": 120,
  "totalFats": 65,
  "totalCarbs": 180
}
```

#### PUT /meals/:id
Update meal time.

Headers:
```
user-id: string
Content-Type: application/json
```

Request body:
```json
{
  "time": "2024-03-20T14:30:00Z"
}
```

Response:
```json
{
  "id": "meal-uuid",
  "userId": "user-uuid",
  "time": "2024-03-20T14:30:00Z",
  "totalCalories": 450,
  "totalProteins": 35,
  "totalFats": 15,
  "totalCarbs": 40,
  "items": [...]
}
```

#### DELETE /meals/:id
Delete a meal.

Headers:
```
user-id: string
```

Request example:
```
DELETE /meals/meal-uuid
```

Response: HTTP 200 (without response body)