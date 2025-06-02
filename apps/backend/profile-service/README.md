# Сервис профилей для фитнес-приложения

Этот сервис отвечает за управление профилями пользователей в фитнес-приложении, включая хранение и обновление персональных данных.

## Функциональность

- Пошаговое создание профиля пользователя
- Хранение персональных данных (имя, возраст, рост, вес)
- Хранение целей пользователя (набор/поддержание/снижение веса)
- Обновление данных профиля
- Проверка заполненности профиля

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
createdb fitness_profiles
```

3. Перейдите в директорию сервиса:
```bash
cd apps/backend/profile-service
```

4. Установите зависимости:
```bash
npm install
```

5. Создайте файл .env в директории profile-service и добавьте следующие переменные:
```
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_profiles
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

## Тестирование через Postman

1. Скачайте и установите Postman с [официального сайта](https://www.postman.com/downloads/)

2. Создайте новую коллекцию "Fitness App - Profile Service"

3. Добавьте следующие запросы:

### Получение профиля (GET /profiles)

- Метод: GET
- URL: http://localhost:3001/profiles
- Headers: 
  - user-id: test-user-123

### Проверка заполненности профиля (GET /profiles/complete)

- Метод: GET
- URL: http://localhost:3001/profiles/complete
- Headers: 
  - user-id: test-user-123

### Обновление имени (PUT /profiles/name)

- Метод: PUT
- URL: http://localhost:3001/profiles/name
- Headers: 
  - Content-Type: application/json
  - user-id: test-user-123
- Body (raw JSON):
```json
{
  "name": "Иван"
}
```

### Обновление возраста (PUT /profiles/age)

- Метод: PUT
- URL: http://localhost:3001/profiles/age
- Headers: 
  - Content-Type: application/json
  - user-id: test-user-123
- Body (raw JSON):
```json
{
  "age": 25
}
```

### Обновление роста (PUT /profiles/height)

- Метод: PUT
- URL: http://localhost:3001/profiles/height
- Headers: 
  - Content-Type: application/json
  - user-id: test-user-123
- Body (raw JSON):
```json
{
  "height": 180
}
```

### Обновление веса (PUT /profiles/weight)

- Метод: PUT
- URL: http://localhost:3001/profiles/weight
- Headers: 
  - Content-Type: application/json
  - user-id: test-user-123
- Body (raw JSON):
```json
{
  "weight": 75
}
```

### Обновление цели (PUT /profiles/goal)

- Метод: PUT
- URL: http://localhost:3001/profiles/goal
- Headers: 
  - Content-Type: application/json
  - user-id: test-user-123
- Body (raw JSON):
```json
{
  "goal": "MAINTAIN_WEIGHT"
}
```

## Ожидаемые ответы

### GET /profiles

Успешный ответ (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "test-user-123",
  "name": "Иван",
  "age": 25,
  "height": 180,
  "weight": 75,
  "goal": "MAINTAIN_WEIGHT",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### GET /profiles/complete

Успешный ответ (200 OK):
```json
{
  "isComplete": true
}
```

### PUT /profiles/*

Успешный ответ (200 OK) - возвращает обновленный профиль:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "test-user-123",
  "name": "Иван",
  "age": 25,
  "height": 180,
  "weight": 75,
  "goal": "MAINTAIN_WEIGHT",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## Возможные проблемы и их решение

1. **Ошибка подключения к PostgreSQL**
   - Проверьте, что PostgreSQL запущен: `brew services list`
   - Перезапустите PostgreSQL: `brew services restart postgresql@14`
   - Проверьте настройки подключения в .env файле

2. **Сервис не запускается**
   - Проверьте наличие файла .env и корректность его содержимого
   - Убедитесь, что все зависимости установлены: `npm install`
   - Проверьте логи на наличие ошибок

3. **Ошибка "Connection refused" в Postman**
   - Убедитесь, что сервис запущен и работает на порту 3001
   - Проверьте, что в URL используется правильный порт

## API Endpoints

### GET /profiles
Получение профиля пользователя.

Заголовки:
```
user-id: string
```

### GET /profiles/complete
Проверка заполненности профиля.

Заголовки:
```
user-id: string
```

### PUT /profiles/name
Обновление имени пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "name": "string"
}
```

### PUT /profiles/age
Обновление возраста пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "age": "number"
}
```

### PUT /profiles/height
Обновление роста пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "height": "number"
}
```

### PUT /profiles/weight
Обновление веса пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "weight": "number"
}
```

### PUT /profiles/goal
Обновление цели пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "goal": "GAIN_WEIGHT | MAINTAIN_WEIGHT | LOSE_WEIGHT"
}
``` 