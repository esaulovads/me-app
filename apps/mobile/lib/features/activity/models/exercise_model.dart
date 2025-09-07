/// Модель упражнения
class Exercise {
  final String id;
  final String name;
  final String targetMuscleGroup;
  final int equipmentCount;

  const Exercise({
    required this.id,
    required this.name,
    required this.targetMuscleGroup,
    required this.equipmentCount,
  });

  /// Создание модели упражнения из JSON
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      targetMuscleGroup: json['targetMuscleGroup'] as String,
      equipmentCount: json['equipmentCount'] as int? ?? 1,
    );
  }

  /// Преобразование модели упражнения в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetMuscleGroup': targetMuscleGroup,
      'equipmentCount': equipmentCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, targetMuscleGroup: $targetMuscleGroup, equipmentCount: $equipmentCount)';
  }
}

/// Ответ API для списка упражнений с пагинацией
class ExercisesResponse {
  final List<Exercise> exercises;
  final int total;
  final int limit;
  final int offset;

  const ExercisesResponse({
    required this.exercises,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// Создание модели ответа из JSON
  factory ExercisesResponse.fromJson(Map<String, dynamic> json) {
    return ExercisesResponse(
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((exerciseJson) => Exercise.fromJson(exerciseJson as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
    );
  }

  /// Проверяет, есть ли еще данные для загрузки
  bool get hasMore => offset + exercises.length < total;
}
