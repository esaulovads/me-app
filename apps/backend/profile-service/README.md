# Сервис профилей для фитнес-приложения

Этот сервис отвечает за управление профилями пользователей в фитнес-приложении, включая хранение и обновление персональных данных.

## Функциональность

- Пошаговое создание профиля пользователя
- Хранение персональных данных (имя, возраст, рост, вес)
- Автоматический расчет ИМТ (индекса массы тела) на основе роста и веса
- Определение статуса ИМТ (недостаточный вес/норма/избыточный вес/ожирение)
- Хранение целей пользователя (набор/поддержание/снижение веса)
- Обновление данных профиля
- Проверка заполненности профиля
- Расчет базового метаболизма (BMR) по формуле Миффлина-Джеора
- Расчет общего расхода энергии (TDEE) с учетом уровня активности
- Управление уровнем физической активности пользователя
- Автоматический расчет рекомендуемой продолжительности сна на основе пола, возраста и уровня активности
- Расчет дневных норм макронутриентов (белки, жиры, углеводы) с учетом цели и активности

## Расчёт рекомендуемой продолжительности сна

Система автоматически рассчитывает рекомендуемую продолжительность сна по формуле:
**Рекомендуемая продолжительность = Базовая длительность + Модификатор активности**

### Базовая длительность сна (часы)
Зависит от пола и возраста:

| Возраст   | Мужчины | Женщины |
|-----------|---------|---------|
| 18–25 лет | 7.5     | 8.0     |
| 26–35 лет | 7.5     | 8.0     |
| 36–45 лет | 7.0     | 7.5     |
| 46–55 лет | 7.0     | 7.5     |
| 56–65 лет | 6.5     | 7.0     |
| 65+ лет   | 6.5     | 6.5     |

### Модификаторы активности (часы)
Дополнительное время сна в зависимости от пола, возраста и уровня активности:

**18-35 лет:**
- Мужчины: Низкая +0.00, Умеренная +0.25, Высокая +0.50, Экстремальная +0.75
- Женщины: Низкая +0.00, Умеренная +0.30, Высокая +0.60, Экстремальная +0.85

**36-55 лет:**
- Мужчины: Низкая +0.00, Умеренная +0.20, Высокая +0.45, Экстремальная +0.70
- Женщины: Низкая +0.00, Умеренная +0.25, Высокая +0.55, Экстремальная +0.80

**56+ лет:**
- Мужчины: Низкая +0.00, Умеренная +0.15, Высокая +0.35, Экстремальная +0.60
- Женщины: Низкая +0.00, Умеренная +0.20, Высокая +0.40, Экстремальная +0.65

*Примечание: "Низкая активность" включает уровни "Нет активности" и "Небольшая активность"*

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

### Обновление даты рождения (PUT /profiles/birth-date)

- Метод: PUT
- URL: http://localhost:3001/profiles/birth-date
- Headers: 
  - Content-Type: application/json
  - user-id: test-user-123
- Body (raw JSON):
```json
{
  "birthDate": "2000-01-11"
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

### PUT /profiles/gender
Обновление пола пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "gender": "MALE | FEMALE"
}
```

### PUT /profiles/activity-level
Обновление уровня физической активности пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "activityLevel": "SEDENTARY | LIGHTLY_ACTIVE | MODERATELY_ACTIVE | VERY_ACTIVE | EXTREMELY_ACTIVE"
}
```

Уровни активности и их коэффициенты:
- SEDENTARY (сидячий образ жизни) - 1.2
- LIGHTLY_ACTIVE (легкая активность) - 1.375
- MODERATELY_ACTIVE (умеренная активность) - 1.55
- VERY_ACTIVE (высокая активность) - 1.725
- EXTREMELY_ACTIVE (очень высокая активность) - 1.9

## Ожидаемые ответы

### GET /profiles

Успешный ответ (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "test-user-123",
  "name": "Иван",
  "birthDate": "2000-01-11",
  "age": 25,
  "height": 180,
  "weight": 75,
  "bmi": 23.15,
  "bmiStatus": "NORMAL",
  "goal": "MAINTAIN_WEIGHT",
  "gender": "MALE",
  "activityLevel": "MODERATELY_ACTIVE",
  "bmr": 1745.5,
  "tdee": 2705.5,
  "proteinTarget": 127.5,
  "fatTarget": 82.5,
  "carbTarget": 338,
  "recommendedSleepDuration": 7.8,
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

При обновлении роста или веса автоматически пересчитывается ИМТ пользователя и его статус.

Статусы ИМТ:
- UNDERWEIGHT - Недостаточный вес (ИМТ < 18.5)
- NORMAL - Нормальный вес (ИМТ 18.5–24.9)
- OVERWEIGHT - Избыточный вес (ИМТ 25–29.9)
- OBESE - Ожирение (ИМТ ≥ 30)

Успешный ответ (200 OK) - возвращает обновленный профиль:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "test-user-123",
  "name": "Иван",
  "birthDate": "2000-01-11",
  "age": 25,
  "height": 180,
  "weight": 75,
  "bmi": 23.15,
  "bmiStatus": "NORMAL",
  "goal": "MAINTAIN_WEIGHT",
  "gender": "MALE",
  "activityLevel": "MODERATELY_ACTIVE",
  "bmr": 1745.5,
  "tdee": 2705.5,
  "proteinTarget": 127.5,
  "fatTarget": 82.5,
  "carbTarget": 338,
  "recommendedSleepDuration": 7.8,
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

### PUT /profiles/birth-date
Обновление даты рождения пользователя. Возраст будет рассчитан автоматически.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "birthDate": "2000-01-11"
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

### PUT /profiles/gender
Обновление пола пользователя.

Заголовки:
```
user-id: string
Content-Type: application/json
```

Тело запроса:
```json
{
  "gender": "MALE | FEMALE"
}
``` 