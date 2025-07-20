# Мобильное приложение Me-App

Flutter-приложение для трекинга питания, активности и профиля пользователя.

## Архитектура проекта

```
lib/
├── features/               # Функциональные модули
│   ├── auth/              # Аутентификация
│   ├── profile/           # Профиль пользователя и онбординг
│   ├── nutrition/         # Питание и КБЖУ
│   ├── activity/          # Физическая активность
│   └── gamification/      # Игрофикация
└── main.dart              # Точка входа
```

## Функционал питания

### Основные экраны
- **NutritionScreen** - главный экран питания с дневной сводкой
- **DishSelectionScreen** - выбор продуктов и блюд для добавления в приём пищи
- **CreateProductScreen** - создание нового продукта с КБЖУ
- **CreateRecipeScreen** - создание рецепта из продуктов с автоматическим расчетом КБЖУ
- **ProductPickerScreen** - выбор продуктов для добавления в рецепт

### Возможности
- ✅ Создание и управление приёмами пищи
- ✅ Добавление продуктов и блюд в приёмы пищи с указанием веса
- ✅ Автоматический расчёт КБЖУ
- ✅ Поиск продуктов и блюд с дебаунсингом
- ✅ Ленивая загрузка (пагинация) списков
- ✅ Кэширование данных с TTL для оптимизации производительности
- ✅ Отображение недавно использованных продуктов и блюд
- ✅ **Создание новых продуктов** с указанием КБЖУ на 100г
- ✅ **Создание рецептов** из продуктов с автоматическим расчетом КБЖУ на 100г
- ✅ Редактирование времени приёмов пищи
- ✅ Удаление приёмов пищи

### Оптимизации производительности
- 🚀 **Кэширование HTTP-запросов** с TTL и автоматической очисткой
- 🚀 **Connection pooling** для HTTP-клиента
- 🚀 **Debouncing** поисковых запросов (500мс)
- 🚀 **Ленивая загрузка** списков по 10 элементов
- 🚀 **RepaintBoundary** для изоляции перерисовок виджетов
- 🚀 **AutomaticKeepAliveClientMixin** для сохранения состояния экранов
- 🚀 **Const виджеты и стили** для минимизации пересборки
- 🚀 **ValueKey** для оптимизации списков
- 🚀 **Оптимизированная прокрутка** с кэшированием элементов

### Модели данных

#### Product (Продукт)
```dart
class Product {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final double servingWeight;
}
```

#### Dish (Блюдо/Рецепт)
```dart
class Dish {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final List<DishIngredient> ingredients;
}
```

#### DishIngredientInput (Ингредиент для создания рецепта)
```dart
class DishIngredientInput {
  final String productId;
  final double weight;
  final Product? product;
}
```

#### Meal (Приём пищи)
```dart
class Meal {
  final String id;
  final DateTime time;
  final List<MealItem> items;
  
  // Вычисляемые поля
  double get totalCalories;
  double get totalProteins;
  double get totalFats;
  double get totalCarbs;
}
```

### Сервисы

#### NutritionService
Основной сервис для работы с питанием:

**Получение данных:**
- `getMealsForDate(DateTime date)` - приёмы пищи за день
- `getDailySummary(DateTime date)` - сводка КБЖУ за день
- `getProducts(limit, offset, search)` - список продуктов с пагинацией
- `getDishes(limit, offset, search)` - список блюд с пагинацией
- `getRecentProducts()` - недавно использованные продукты
- `getRecentDishes()` - недавно использованные блюда

**Создание и модификация:**
- `createMeal(DateTime time)` - создание приёма пищи
- `createProduct(...)` - создание нового продукта
- `createDish(String name, List<DishIngredientInput> ingredients)` - создание рецепта
- `addProductToMeal(String mealId, String productId, double weight)` - добавление продукта
- `addDishToMeal(String mealId, String dishId, double weight)` - добавление блюда
- `updateMealTime(String mealId, DateTime newTime)` - изменение времени
- `deleteMeal(String mealId, DateTime time)` - удаление приёма пищи

**Кэширование:**
- Автоматическое кэширование всех запросов с TTL
- Умная очистка кэша при изменениях
- Connection pooling для оптимизации сетевых запросов

### Особенности расчета КБЖУ рецептов

При создании рецепта система автоматически рассчитывает КБЖУ на 100г готового блюда:

1. **Суммирование**: Подсчитывается общее КБЖУ всех ингредиентов
2. **Пропорциональный расчет**: КБЖУ пересчитывается на 100г исходя из общего веса рецепта

**Пример:**
- Рис: 600г (60% от общего веса)
- Курица: 400г (40% от общего веса)
- Итоговое КБЖУ на 100г = 60% КБЖУ риса + 40% КБЖУ курицы

### Интеграция с бэкендом

Приложение взаимодействует с NestJS бэкендом через REST API:

**Эндпоинты для создания:**
- `POST /products` - создание продукта
- `POST /dishes` - создание блюда/рецепта
- `POST /meals/:mealId/items` - добавление элемента в приём пищи

**Эндпоинты для получения данных:**
- `GET /meals?date=YYYY-MM-DD` - приёмы пищи за день  
- `GET /products?limit=10&offset=0&search=query` - продукты с пагинацией
- `GET /dishes?limit=10&offset=0&search=query` - блюда с пагинацией
- `GET /recent-products` - недавние продукты
- `GET /recent-dishes` - недавние блюда

## Установка и запуск

```bash
# Установка зависимостей
flutter pub get

# Запуск в режиме разработки
flutter run

# Сборка для Android
flutter build apk

# Сборка для iOS  
flutter build ios
```

## Зависимости

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0           # HTTP-клиент
  intl: ^0.18.1          # Интернационализация и форматирование
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0 # Линтер
```

## Производительность

Приложение оптимизировано для плавной работы:

- **Минимальные задержки UI** благодаря кэшированию и дебаунсингу
- **Эффективное использование памяти** с автоматической очисткой кэша
- **Плавная прокрутка** больших списков с ленивой загрузкой
- **Быстрый отклик** на пользовательские действия

Рекомендуется тестировать на физических устройствах для оценки реальной производительности.
