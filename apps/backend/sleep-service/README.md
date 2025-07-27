# Сервис сна для фитнес-приложения

Этот сервис отвечает за управление сном пользователей в фитнес-приложении, включая создание периодов сна и отслеживание их продолжительности.

## Функциональность

### Управление периодами сна
- Создание новых периодов сна с указанием времени засыпания и пробуждения
- Автоматический расчет продолжительности сна в минутах и часах
- Поддержка нескольких периодов сна за один день (например, дневной сон)
- Получение списка всех периодов сна за конкретную дату
- Получение периодов сна за диапазон дат
- Редактирование и удаление периодов сна

### Анализ сна
- Получение суммарной продолжительности сна за день
- Автоматическое определение даты сна по времени засыпания
- Валидация данных (время пробуждения должно быть позже времени засыпания)

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
createdb fitness_sleep
```

3. Перейдите в директорию сервиса:
```bash
cd apps/backend/sleep-service
```

4. Установите зависимости:
```bash
npm install
```

5. Создайте файл .env в директории sleep-service и добавьте следующие переменные:
```
PORT=3003
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=fitness_sleep
```

6. Запустите миграции для создания таблиц:
```bash
npm run migration:run
```

7. Запустите сервис:
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

### Периоды сна

#### POST /sleep
Создание нового периода сна.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "sleepTime": "2024-03-20T23:30:00Z",
  "wakeTime": "2024-03-21T07:30:00Z"
}
```

Ответ:
```json
{
  "id": "uuid",
  "userId": "user-uuid",
  "sleepTime": "2024-03-20T23:30:00Z",
  "wakeTime": "2024-03-21T07:30:00Z",
  "durationMinutes": 480,
  "sleepDate": "2024-03-20",
  "createdAt": "2024-03-21T07:30:00Z",
  "updatedAt": "2024-03-21T07:30:00Z"
}
```

#### GET /sleep
Получение периодов сна пользователя.

Заголовки:
```
user-id: string
```

Параметры запроса:
```
date: YYYY-MM-DD (необязательный, по умолчанию - сегодня)
startDate: YYYY-MM-DD (для диапазона дат)
endDate: YYYY-MM-DD (для диапазона дат)
```

Примеры запросов:
```
GET /sleep - периоды сна за сегодня
GET /sleep?date=2024-03-20 - периоды сна за конкретную дату
GET /sleep?startDate=2024-03-15&endDate=2024-03-20 - периоды сна за диапазон
```

Ответ:
```json
[
  {
    "id": "uuid",
    "userId": "user-uuid",
    "sleepTime": "2024-03-20T23:30:00Z",
    "wakeTime": "2024-03-21T07:30:00Z",
    "durationMinutes": 480,
    "sleepDate": "2024-03-20",
    "createdAt": "2024-03-21T07:30:00Z",
    "updatedAt": "2024-03-21T07:30:00Z"
  },
  {
    "id": "uuid2",
    "userId": "user-uuid",
    "sleepTime": "2024-03-20T14:00:00Z",
    "wakeTime": "2024-03-20T15:30:00Z",
    "durationMinutes": 90,
    "sleepDate": "2024-03-20",
    "createdAt": "2024-03-20T15:30:00Z",
    "updatedAt": "2024-03-20T15:30:00Z"
  }
]
```

#### GET /sleep/duration
Получение суммарной продолжительности сна за конкретную дату.

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
GET /sleep/duration?date=2024-03-20
```

Ответ:
```json
{
  "totalMinutes": 570,
  "totalHours": 9.5
}
```

#### GET /sleep/:id
Получение конкретного периода сна.

Заголовки:
```
user-id: string
```

Пример запроса:
```
GET /sleep/uuid
```

Ответ:
```json
{
  "id": "uuid",
  "userId": "user-uuid",
  "sleepTime": "2024-03-20T23:30:00Z",
  "wakeTime": "2024-03-21T07:30:00Z",
  "durationMinutes": 480,
  "sleepDate": "2024-03-20",
  "createdAt": "2024-03-21T07:30:00Z",
  "updatedAt": "2024-03-21T07:30:00Z"
}
```

#### PUT /sleep/:id
Обновление периода сна.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса (все поля необязательные):
```json
{
  "sleepTime": "2024-03-20T23:00:00Z",
  "wakeTime": "2024-03-21T08:00:00Z"
}
```

Ответ:
```json
{
  "id": "uuid",
  "userId": "user-uuid",
  "sleepTime": "2024-03-20T23:00:00Z",
  "wakeTime": "2024-03-21T08:00:00Z",
  "durationMinutes": 540,
  "sleepDate": "2024-03-20",
  "createdAt": "2024-03-21T07:30:00Z",
  "updatedAt": "2024-03-21T08:15:00Z"
}
```

#### DELETE /sleep/:id
Удаление периода сна.

Заголовки:
```
user-id: string
```

Пример запроса:
```
DELETE /sleep/uuid
```

Ответ:
```json
{
  "message": "Период сна успешно удален"
}
```

## Структура базы данных

### Таблица sleep_sessions

| Поле | Тип | Описание |
|------|-----|----------|
| id | uuid | Первичный ключ |
| user_id | varchar | Идентификатор пользователя |
| sleep_time | timestamp with time zone | Время засыпания |
| wake_time | timestamp with time zone | Время пробуждения |
| duration_minutes | int | Продолжительность сна в минутах |
| sleep_date | date | Дата сна (по времени засыпания) |
| created_at | timestamp with time zone | Время создания записи |
| updated_at | timestamp with time zone | Время последнего обновления |

### Индексы
- `IDX_sleep_sessions_user_id` - по идентификатору пользователя
- `IDX_sleep_sessions_user_id_sleep_date` - составной индекс по пользователю и дате сна
- `IDX_sleep_sessions_sleep_date` - по дате сна

## Примеры использования

### Создание периода ночного сна
```bash
curl -X POST http://localhost:3003/sleep \
  -H "Content-Type: application/json" \
  -H "user-id: user-123" \
  -d '{
    "sleepTime": "2024-03-20T23:30:00Z",
    "wakeTime": "2024-03-21T07:30:00Z"
  }'
```

### Создание дневного сна
```bash
curl -X POST http://localhost:3003/sleep \
  -H "Content-Type: application/json" \
  -H "user-id: user-123" \
  -d '{
    "sleepTime": "2024-03-20T14:00:00Z",
    "wakeTime": "2024-03-20T15:30:00Z"
  }'
```

### Получение всего сна за день
```bash
curl -X GET "http://localhost:3003/sleep?date=2024-03-20" \
  -H "user-id: user-123"
```

### Получение общей продолжительности сна
```bash
curl -X GET "http://localhost:3003/sleep/duration?date=2024-03-20" \
  -H "user-id: user-123"
```

## Ошибки и валидация

### Возможные ошибки:
- `400 Bad Request` - Время пробуждения должно быть позже времени засыпания
- `400 Bad Request` - Заголовок user-id обязателен
- `400 Bad Request` - Невалидный формат даты/времени
- `404 Not Found` - Период сна не найден

### Формат времени:
Все временные метки должны быть в формате ISO 8601 с временной зоной:
- `2024-03-20T23:30:00Z` (UTC)
- `2024-03-20T23:30:00+03:00` (с указанием часового пояса)

## Миграции

Для работы с миграциями используйте следующие команды:

```bash
# Запуск миграций
npm run migration:run

# Создание новой миграции
npm run migration:create -- MigrationName

# Генерация миграции на основе изменений в сущностях
npm run migration:generate -- MigrationName

# Откат последней миграции
npm run migration:revert
``` 