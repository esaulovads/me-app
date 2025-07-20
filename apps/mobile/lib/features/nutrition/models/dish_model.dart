import 'product_model.dart';

// Входные данные для ингредиента при создании блюда
class DishIngredientInput {
  final String productId;
  final double weight;
  final Product? product; // Опциональная ссылка на продукт для отображения

  const DishIngredientInput({
    required this.productId,
    required this.weight,
    this.product,
  });

  // Конструктор из продукта
  factory DishIngredientInput.fromProduct(Product product, double weight) {
    return DishIngredientInput(
      productId: product.id,
      weight: weight,
      product: product,
    );
  }
}

// Ингредиент блюда
class DishIngredient {
  final String id;
  final String productId;
  final double weight;
  final Product? product; // Может быть null при загрузке

  const DishIngredient({
    required this.id,
    required this.productId,
    required this.weight,
    this.product,
  });

  factory DishIngredient.fromJson(Map<String, dynamic> json) {
    return DishIngredient(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      weight: _parseDouble(json['weight']),
      product: json['product'] != null 
          ? Product.fromJson(json['product']) 
          : null,
    );
  }

  // Безопасное преобразование в double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
}

// Модель блюда для экрана питания
class Dish {
  final String id;
  final String name;
  final double totalWeight;
  final double totalCalories;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final List<DishIngredient> ingredients;

  const Dish({
    required this.id,
    required this.name,
    required this.totalWeight,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalFats,
    required this.totalCarbs,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
    required this.carbsPer100g,
    required this.ingredients,
  });

  // Безопасное преобразование в double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  // Создание из JSON ответа API
  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      totalWeight: _parseDouble(json['totalWeight']),
      totalCalories: _parseDouble(json['totalCalories']),
      totalProteins: _parseDouble(json['totalProteins']),
      totalFats: _parseDouble(json['totalFats']),
      totalCarbs: _parseDouble(json['totalCarbs']),
      caloriesPer100g: _parseDouble(json['caloriesPer100g']),
      proteinsPer100g: _parseDouble(json['proteinsPer100g']),
      fatsPer100g: _parseDouble(json['fatsPer100g']),
      carbsPer100g: _parseDouble(json['carbsPer100g']),
      ingredients: (json['ingredients'] as List?)
          ?.map((ingredientJson) => DishIngredient.fromJson(ingredientJson))
          .toList() ?? [],
    );
  }

  // Форматированное отображение КБЖУ на 100г
  String get formattedNutrition {
    return '${caloriesPer100g.toInt()} ккал / ${proteinsPer100g.toInt()} б / ${fatsPer100g.toInt()} ж / ${carbsPer100g.toInt()} у';
  }

  // Форматированное отображение общего КБЖУ
  String get formattedTotalNutrition {
    return '${totalCalories.toInt()} ккал / ${totalProteins.toInt()} б / ${totalFats.toInt()} ж / ${totalCarbs.toInt()} у (${totalWeight.toInt()}г)';
  }

  // Количество ингредиентов
  String get ingredientsCount {
    return '${ingredients.length} ингредиент${ingredients.length == 1 ? '' : ingredients.length < 5 ? 'а' : 'ов'}';
  }
}

// Ответ API для списка блюд с пагинацией
class DishesResponse {
  final List<Dish> dishes;
  final int total;

  const DishesResponse({
    required this.dishes,
    required this.total,
  });

  factory DishesResponse.fromJson(Map<String, dynamic> json) {
    return DishesResponse(
      dishes: (json['dishes'] as List?)
          ?.map((dishJson) => Dish.fromJson(dishJson))
          .toList() ?? [],
      total: (json['total'] is int) 
          ? json['total'] as int 
          : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
    );
  }
} 