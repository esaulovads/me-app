# Сервис авторизации для фитнес-приложения

Этот сервис отвечает за аутентификацию пользователей и управление их учетными записями в фитнес-приложении.

## Функциональность

- Определение новых и существующих пользователей
- Создание новых учетных записей
- Получение данных существующих учетных записей

## Технический стек

- Node.js
- Express
- TypeScript
- MongoDB
- Mongoose

## Установка и запуск

### Предварительные требования

1. Установите MongoDB (если еще не установлена):
```bash
brew tap mongodb/brew
brew install mongodb-community
```

### Запуск сервиса

1. Запустите MongoDB:
```bash
brew services start mongodb-community
```

2. Перейдите в директорию сервиса:
```bash
cd apps/backend/auth-service
```

3. Установите зависимости (если еще не установлены):
```bash
npm install
```

4. Создайте файл .env в директории auth-service и добавьте следующие переменные:
```
PORT=3000
MONGODB_URI=mongodb://localhost:27017/fitness-app
```

5. Запустите сервис:
```bash
# Режим разработки
npm run dev

# Продакшн режим
npm run build
npm start
```

### Остановка сервиса

1. Остановите сервис: нажмите Ctrl + C в терминале, где запущен сервис
2. Остановите MongoDB:
```bash
brew services stop mongodb-community
```

## Тестирование через Postman

1. Скачайте и установите Postman с [официального сайта](https://www.postman.com/downloads/)

2. Создайте новую коллекцию "Fitness App"

3. Добавьте следующие запросы:

### Аутентификация пользователя (POST /auth)

- Метод: POST
- URL: http://localhost:3000/auth
- Headers: 
  - Content-Type: application/json
- Body (raw JSON):
```json
{
  "deviceId": "test-device-123"
}
```

### Получение данных пользователя (GET /users/:userId)

- Метод: GET
- URL: http://localhost:3000/users/test-device-123
- Headers: не требуются
- Body: не требуется

## Ожидаемые ответы

### POST /auth

Успешный ответ (200 OK):
```json
{
  "userId": "test-device-123",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

### GET /users/:userId

Успешный ответ (200 OK):
```json
{
  "userId": "test-device-123",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

Пользователь не найден (404 Not Found):
```json
{
  "error": "Пользователь не найден"
}
```

## Возможные проблемы и их решение

1. **Ошибка подключения к MongoDB**
   - Проверьте, что MongoDB запущена: `brew services list`
   - Перезапустите MongoDB: `brew services restart mongodb-community`

2. **Сервис не запускается**
   - Проверьте наличие файла .env и корректность его содержимого
   - Убедитесь, что все зависимости установлены: `npm install`
   - Проверьте логи на наличие ошибок

3. **Ошибка "Connection refused" в Postman**
   - Убедитесь, что сервис запущен и работает на порту 3000
   - Проверьте, что в URL используется правильный порт

## API Endpoints

### POST /auth
Аутентификация пользователя или создание новой учетной записи.

Запрос:
```json
{
  "deviceId": "unique-device-identifier"
}
```

Ответ:
```json
{
  "userId": "unique-device-identifier",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
```

### GET /users/:userId
Получение данных пользователя по ID.

Ответ:
```json
{
  "userId": "unique-device-identifier",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "lastLoginAt": "2024-01-01T00:00:00.000Z"
}
``` 

