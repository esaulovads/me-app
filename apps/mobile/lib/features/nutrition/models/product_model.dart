// Модель продукта для экрана питания
class Product {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;
  final double carbsPer100g;
  final double servingWeight;
  final double caloriesPerServing;
  final double proteinsPerServing;
  final double fatsPerServing;
  final double carbsPerServing;

  const Product({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
    required this.carbsPer100g,
    required this.servingWeight,
    required this.caloriesPerServing,
    required this.proteinsPerServing,
    required this.fatsPerServing,
    required this.carbsPerServing,
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
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      caloriesPer100g: _parseDouble(json['caloriesPer100g']),
      proteinsPer100g: _parseDouble(json['proteinsPer100g']),
      fatsPer100g: _parseDouble(json['fatsPer100g']),
      carbsPer100g: _parseDouble(json['carbsPer100g']),
      servingWeight: _parseDouble(json['servingWeight']),
      caloriesPerServing: _parseDouble(json['caloriesPerServing']),
      proteinsPerServing: _parseDouble(json['proteinsPerServing']),
      fatsPerServing: _parseDouble(json['fatsPerServing']),
      carbsPerServing: _parseDouble(json['carbsPerServing']),
    );
  }

  // Форматированное отображение КБЖУ на 100г
  String get formattedNutrition {
    return '${caloriesPer100g.toInt()} ккал / ${proteinsPer100g.toInt()} б / ${fatsPer100g.toInt()} ж / ${carbsPer100g.toInt()} у';
  }

  // Форматированное отображение КБЖУ на порцию
  String get formattedServingNutrition {
    return '${caloriesPerServing.toInt()} ккал / ${proteinsPerServing.toInt()} б / ${fatsPerServing.toInt()} ж / ${carbsPerServing.toInt()} у (${servingWeight.toInt()}г)';
  }
}

// Ответ API для списка продуктов с пагинацией
class ProductsResponse {
  final List<Product> products;
  final int total;

  const ProductsResponse({
    required this.products,
    required this.total,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      products: (json['products'] as List?)
          ?.map((productJson) => Product.fromJson(productJson))
          .toList() ?? [],
      total: (json['total'] is int) 
          ? json['total'] as int 
          : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
    );
  }
} 