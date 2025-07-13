// Модель для элемента приёма пищи
class MealItem {
  final String id;
  final String type; // PRODUCT или DISH
  final String? productId;
  final String? dishId;
  final double weight;
  final double calories;
  final double proteins;
  final double fats;
  final double carbs;

  MealItem({
    required this.id,
    required this.type,
    this.productId,
    this.dishId,
    required this.weight,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  // Создание объекта из JSON
  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'],
      type: json['type'],
      productId: json['productId'],
      dishId: json['dishId'],
      weight: (json['weight'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      proteins: (json['proteins'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'productId': productId,
      'dishId': dishId,
      'weight': weight,
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
    };
  }
}

// Модель для приёма пищи
class Meal {
  final String id;
  final String userId;
  final DateTime time;
  final double totalCalories;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;
  final List<MealItem> items;

  Meal({
    required this.id,
    required this.userId,
    required this.time,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalFats,
    required this.totalCarbs,
    required this.items,
  });

  // Создание объекта из JSON
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      userId: json['userId'],
      time: DateTime.parse(json['time']),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProteins: (json['totalProteins'] as num).toDouble(),
      totalFats: (json['totalFats'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'time': time.toIso8601String(),
      'totalCalories': totalCalories,
      'totalProteins': totalProteins,
      'totalFats': totalFats,
      'totalCarbs': totalCarbs,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Модель для дневной сводки КБЖУ
class DailySummary {
  final double totalCalories;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;

  DailySummary({
    required this.totalCalories,
    required this.totalProteins,
    required this.totalFats,
    required this.totalCarbs,
  });

  // Создание объекта из JSON
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProteins: (json['totalProteins'] as num).toDouble(),
      totalFats: (json['totalFats'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'totalCalories': totalCalories,
      'totalProteins': totalProteins,
      'totalFats': totalFats,
      'totalCarbs': totalCarbs,
    };
  }
} 