# Сервис питания для фитнес-приложения

Этот сервис отвечает за управление питанием пользователей в фитнес-приложении, включая создание продуктов, блюд и отслеживание приемов пищи.

## Функциональность

### Управление продуктами
- Создание новых продуктов с указанием КБЖУ на 100 грамм
- Указание веса одной порции продукта
- Автоматический расчет КБЖУ для порции продукта
- Получение списка всех продуктов пользователя
- Редактирование и удаление продуктов

### Управление блюдами
- Создание новых блюд из одного или нескольких продуктов
- Указание веса каждого продукта в составе блюда
- Автоматический расчет итогового КБЖУ блюда
- Расчет КБЖУ на 100 грамм блюда
- Получение списка всех блюд пользователя
- Редактирование и удаление блюд

### Управление приемами пищи
- Создание приемов пищи с указанием времени
- Добавление продуктов и блюд в прием пищи с указанием их веса
- Автоматический расчет КБЖУ приема пищи
- Получение всех приемов пищи за день
- Расчет суммарного КБЖУ за день
- Сравнение фактического потребления с нормой из профиля пользователя

## Технический стек

- Node.js
- NestJS
- TypeScript
- PostgreSQL
- TypeORM

## Установка и запуск

### Предварительные требования

1. Установите PostgreSQL (если еще не установлен):
```bash
brew install postgresql@14
```

### Запуск сервиса

1. Запустите PostgreSQL:
```bash
brew services start postgresql@14
```

2. Создайте базу данных:
```bash
createdb fitness_nutrition
```

3. Перейдите в директорию сервиса:
```bash
cd apps/backend/nutrition-service
```

4. Установите зависимости:
```bash
npm install
```

5. Создайте файл .env в директории nutrition-service и добавьте следующие переменные:
```
PORT=3002
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_nutrition
```

6. Запустите сервис:
```bash
# Режим разработки
npm run start:dev

# Продакшн режим
npm run build
npm run start
```

### Остановка сервиса

1. Остановите сервис: нажмите Ctrl + C в терминале, где запущен сервис
2. Остановите PostgreSQL:
```bash
brew services stop postgresql@14
```

## API Endpoints

### Продукты

#### POST /products
Создание нового продукта.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
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
Получение списка всех продуктов пользователя.

Заголовки:
```
user-id: string
```

### Блюда

#### POST /dishes
Создание нового блюда.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
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
Получение списка всех блюд пользователя.

Заголовки:
```
user-id: string
```

### Приемы пищи

#### POST /meals
Создание нового приема пищи.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
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
Получение всех приемов пищи за конкретный день.

Заголовки:
```
user-id: string
```

Параметры запроса:
```
date: YYYY-MM-DD (обязательный параметр)
```

Пример запроса:
```
GET /meals?date=2024-03-20
```

Ответ:
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
Получение суммарного КБЖУ за конкретный день.

Заголовки:
```
user-id: string
```

Параметры запроса:
```
date: YYYY-MM-DD (обязательный параметр)
```

Пример запроса:
```
GET /meals/summary?date=2024-03-20
```

Ответ:
```json
{
  "totalCalories": 1850,
  "totalProteins": 120,
  "totalFats": 65,
  "totalCarbs": 180
}
```

#### PUT /meals/:id
Обновление времени приема пищи.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "time": "2024-03-20T14:30:00Z"
}
```

Ответ:
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
Удаление приема пищи.

Заголовки:
```
user-id: string
```

Пример запроса:
```
DELETE /meals/meal-uuid
```

Ответ: HTTP 200 (без тела ответа)