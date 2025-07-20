// Модель для элемента приёма пищи
class MealItem {
  final String id;
  final String type; // PRODUCT или DISH
  final String? productId;
  final String? dishId;
  final String name; // Название продукта или блюда
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
    required this.name,
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
      name: json['name'] ?? 'Неизвестно',
      weight: _parseDouble(json['weight']),
      calories: _parseDouble(json['calories']),
      proteins: _parseDouble(json['proteins']),
      fats: _parseDouble(json['fats']),
      carbs: _parseDouble(json['carbs']),
    );
  }

  // Безопасное преобразование в double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'productId': productId,
      'dishId': dishId,
      'name': name,
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
  final String name; // Название приёма пищи
  final DateTime time;
  final double totalCalories;
  final double totalProteins;
  final double totalFats;
  final double totalCarbs;
  final List<MealItem> items;

  Meal({
    required this.id,
    required this.userId,
    required this.name,
    required this.time,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalFats,
    required this.totalCarbs,
    required this.items,
  });

  // Геттер для совместимости с кодом
  double get calories => totalCalories;
  
  // Форматированное время для отображения
  String get formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Создание объекта из JSON
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      userId: json['userId'],
      name: json['name'] ?? _getMealNameFromTime(DateTime.parse(json['time'])),
      time: DateTime.parse(json['time']),
      totalCalories: _parseDouble(json['totalCalories']),
      totalProteins: _parseDouble(json['totalProteins']),
      totalFats: _parseDouble(json['totalFats']),
      totalCarbs: _parseDouble(json['totalCarbs']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => MealItem.fromJson(item))
          .toList() ?? [],
    );
  }

  // Безопасное преобразование в double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Определение названия приёма пищи по времени
  static String _getMealNameFromTime(DateTime time) {
    final hour = time.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Завтрак';
    } else if (hour >= 12 && hour < 17) {
      return 'Обед';
    } else if (hour >= 17 && hour < 22) {
      return 'Ужин';
    } else {
      return 'Перекус';
    }
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
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
      totalCalories: _parseDouble(json['totalCalories']),
      totalProteins: _parseDouble(json['totalProteins']),
      totalFats: _parseDouble(json['totalFats']),
      totalCarbs: _parseDouble(json['totalCarbs']),
    );
  }

  // Безопасное преобразование в double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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

// Модель для дневных норм питания пользователя
class NutritionTargets {
  final double calories;    // ккал
  final double proteins;    // г
  final double fats;        // г
  final double carbs;       // г

  NutritionTargets({
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  // Создание объекта из данных профиля
  factory NutritionTargets.fromProfile(dynamic profile) {
    return NutritionTargets(
      calories: profile.tdee?.toDouble() ?? 0.0,
      proteins: profile.proteinTarget?.toDouble() ?? 0.0,
      fats: profile.fatTarget?.toDouble() ?? 0.0,
      carbs: profile.carbTarget?.toDouble() ?? 0.0,
    );
  }

  // Проверка, заполнены ли все нормы
  bool get isComplete {
    return calories > 0 && proteins > 0 && fats > 0 && carbs > 0;
  }

  // Расчет процента выполнения нормы
  double calculatePercentage(double actual, double target) {
    if (target <= 0) return 0.0;
    return (actual / target) * 100;
  }

  // Форматирование для отображения калорий с процентом
  String formatCalories(double actual) {
    if (calories <= 0) return '${actual.toInt()} ккал';
    final percentage = calculatePercentage(actual, calories);
    return '${actual.toInt()}/${calories.toInt()} ккал (${percentage.toStringAsFixed(1)}%)';
  }

  // Форматирование для отображения белков с процентом
  String formatProteins(double actual) {
    if (proteins <= 0) return '${actual.toInt()} г';
    final percentage = calculatePercentage(actual, proteins);
    return '${actual.toInt()}/${proteins.toInt()} г (${percentage.toStringAsFixed(1)}%)';
  }

  // Форматирование для отображения жиров с процентом
  String formatFats(double actual) {
    if (fats <= 0) return '${actual.toInt()} г';
    final percentage = calculatePercentage(actual, fats);
    return '${actual.toInt()}/${fats.toInt()} г (${percentage.toStringAsFixed(1)}%)';
  }

  // Форматирование для отображения углеводов с процентом
  String formatCarbs(double actual) {
    if (carbs <= 0) return '${actual.toInt()} г';
    final percentage = calculatePercentage(actual, carbs);
    return '${actual.toInt()}/${carbs.toInt()} г (${percentage.toStringAsFixed(1)}%)';
  }
} 