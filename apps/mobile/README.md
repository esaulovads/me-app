# Me-App Mobile Application

A Flutter application for tracking nutrition, activity, and user profile.

## Project Architecture

```
lib/
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── profile/           # User profile and onboarding
│   ├── nutrition/         # Nutrition and calories/macronutrients
│   ├── activity/          # Physical activity
│   └── gamification/      # Gamification
└── main.dart              # Entry point
```

## Nutrition Features

### Main Screens
- **NutritionScreen** - main nutrition screen with daily summary
- **DishSelectionScreen** - selecting products and dishes to add to a meal
- **CreateProductScreen** - creating a new product with calories/macronutrients
- **CreateRecipeScreen** - creating a recipe from products with automatic calorie/macronutrient calculation
- **ProductPickerScreen** - selecting products to add to a recipe

### Capabilities
- ✅ Creating and managing meals
- ✅ Adding products and dishes to meals with specified weight
- ✅ Automatic calorie/macronutrient calculation
- ✅ Product and dish search with debouncing
- ✅ Lazy loading (pagination) for lists
- ✅ Data caching with TTL for performance optimization
- ✅ Displaying recently used products and dishes
- ✅ **Creating new products** with calories/macronutrients per 100g
- ✅ **Creating recipes** from products with automatic calorie/macronutrient calculation per 100g
- ✅ Editing meal times
- ✅ Deleting meals

### Performance Optimizations
- 🚀 **HTTP request caching** with TTL and automatic cleanup
- 🚀 **Connection pooling** for the HTTP client
- 🚀 **Debouncing** search requests (500ms)
- 🚀 **Lazy loading** of lists in batches of 10 items
- 🚀 **RepaintBoundary** to isolate widget repaints
- 🚀 **AutomaticKeepAliveClientMixin** to preserve screen states
- 🚀 **Const widgets and styles** to minimize rebuilds
- 🚀 **ValueKey** for list optimization
- 🚀 **Optimized scrolling** with item caching

### Data Models

#### Product
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

#### Dish (Dish/Recipe)
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

#### DishIngredientInput (Ingredient for recipe creation)
```dart
class DishIngredientInput {
  final String productId;
  final double weight;
  final Product? product;
}
```

#### Meal
```dart
class Meal {
  final String id;
  final DateTime time;
  final List<MealItem> items;
  
  // Computed fields
  double get totalCalories;
  double get totalProteins;
  double get totalFats;
  double get totalCarbs;
}
```

### Services

#### NutritionService
Core service for nutrition operations:

**Data retrieval:**
- `getMealsForDate(DateTime date)` - meals for a day
- `getDailySummary(DateTime date)` - daily calorie/macronutrient summary
- `getProducts(limit, offset, search)` - paginated product list
- `getDishes(limit, offset, search)` - paginated dish list
- `getRecentProducts()` - recently used products
- `getRecentDishes()` - recently used dishes

**Creation and modification:**
- `createMeal(DateTime time)` - create a meal
- `createProduct(...)` - create a new product
- `createDish(String name, List<DishIngredientInput> ingredients)` - create a recipe
- `addProductToMeal(String mealId, String productId, double weight)` - add a product
- `addDishToMeal(String mealId, String dishId, double weight)` - add a dish
- `updateMealTime(String mealId, DateTime newTime)` - update time
- `deleteMeal(String mealId, DateTime time)` - delete a meal

**Caching:**
- Automatic caching for all requests with TTL
- Smart cache invalidation on changes
- Connection pooling for network request optimization

### Recipe Calorie/Macronutrient Calculation

When creating a recipe, the system automatically calculates calories/macronutrients per 100g of the prepared dish:

1. **Summation**: Total calories/macronutrients of all ingredients are calculated
2. **Proportional calculation**: Calories/macronutrients are recalculated per 100g based on total recipe weight

**Example:**
- Rice: 600g (60% of total weight)
- Chicken: 400g (40% of total weight)
- Final calories/macronutrients per 100g = 60% rice calories/macronutrients + 40% chicken calories/macronutrients

### Backend Integration

The app interacts with the NestJS backend through a REST API:

**Creation endpoints:**
- `POST /products` - create a product
- `POST /dishes` - create a dish/recipe
- `POST /meals/:mealId/items` - add an item to a meal

**Data retrieval endpoints:**
- `GET /meals?date=YYYY-MM-DD` - meals for a day  
- `GET /products?limit=10&offset=0&search=query` - paginated products
- `GET /dishes?limit=10&offset=0&search=query` - paginated dishes
- `GET /recent-products` - recent products
- `GET /recent-dishes` - recent dishes

## Installation and Launch

```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Build for Android
flutter build apk

# Build for iOS  
flutter build ios
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0           # HTTP client
  intl: ^0.18.1          # Internationalization and formatting
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0 # Linter
```

## Performance

The app is optimized for smooth operation:

- **Minimal UI delays** thanks to caching and debouncing
- **Efficient memory usage** with automatic cache cleanup
- **Smooth scrolling** of large lists with lazy loading
- **Fast response** to user actions

Testing on physical devices is recommended to evaluate real-world performance.
