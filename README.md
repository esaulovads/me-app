# Fitness App

Фитнес-приложение для отслеживания питания, физической активности и достижения целей по здоровому образу жизни.

## Архитектура

Проект построен на микросервисной архитектуре и состоит из следующих компонентов:

### Бэкенд (NestJS):
- Auth Service - авторизация и управление пользователями
- Profile Service - управление профилями и расчет КБЖУ
- Nutrition Service - управление питанием и рецептами
- Activity Service - отслеживание физической активности
- Gamification Service - игровые механики и достижения
- Product Scanner Service - интеграция со сканером штрихкодов
- API Gateway - маршрутизация запросов

### Мобильное приложение (Flutter):
- Кроссплатформенное приложение для iOS и Android

## Основной функционал

1. Авторизация пользователей
2. Расчет индивидуального КБЖУ
3. Отслеживание питания
4. Управление продуктами и рецептами
5. Сканирование штрихкодов продуктов
6. Отслеживание физической активности
7. Учет тренировок
8. Игровые механики и достижения
9. Система уровней и прогресса

## Запуск в Docker

### Предварительная настройка

1. Создайте файлы с переменными окружения:

**apps/backend/auth-service/.env:**
```env
# Порт сервиса
AUTH_SERVICE_PORT=3000

# JWT настройки
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=1d

# База данных
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=auth_db

# Настройки приложения
NODE_ENV=development
API_PREFIX=/api/v1
```

**apps/backend/profile-service/.env:**
```env
# Порт сервиса
PROFILE_SERVICE_PORT=3001

# База данных
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE=profile_db

# Настройки приложения
NODE_ENV=development
API_PREFIX=/api/v1
```

### Запуск контейнеров

1. Соберите и запустите контейнеры:
```bash
docker-compose up --build
```

2. Для запуска в фоновом режиме:
```bash
docker-compose up -d --build
```

3. Для остановки контейнеров:
```bash
docker-compose down
```

### Тестирование в Postman

1. Импортируйте коллекции тестов из директорий сервисов:
   - `apps/backend/auth-service/postman/collection.json`
   - `apps/backend/profile-service/postman/collection.json`

2. Сервисы будут доступны по следующим адресам:
   - Auth Service: http://localhost:3000
   - Profile Service: http://localhost:3001

### Просмотр логов

```bash
# Логи всех сервисов
docker-compose logs -f

# Логи конкретного сервиса
docker-compose logs -f auth-service
docker-compose logs -f profile-service
```

### Управление контейнерами

```bash
# Перезапуск конкретного сервиса
docker-compose restart auth-service
docker-compose restart profile-service

# Остановка конкретного сервиса
docker-compose stop auth-service
docker-compose stop profile-service

# Запуск конкретного сервиса
docker-compose start auth-service
docker-compose start profile-service
``` 