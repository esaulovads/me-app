/// Модель подхода
class WorkoutSet {
  final String id;
  final String workoutExerciseId;
  final int reps; // Количество повторений
  final double weight; // Вес снаряда
  final double totalWeight; // Общий поднятый вес (рассчитывается автоматически)

  const WorkoutSet({
    required this.id,
    required this.workoutExerciseId,
    required this.reps,
    required this.weight,
    required this.totalWeight,
  });

  /// Создание модели подхода из JSON
  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      workoutExerciseId: json['workoutExerciseId'] as String,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      totalWeight: (json['totalWeight'] as num).toDouble(),
    );
  }

  /// Преобразование модели подхода в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutExerciseId': workoutExerciseId,
      'reps': reps,
      'weight': weight,
      'totalWeight': totalWeight,
    };
  }

  /// Создание копии подхода с изменениями
  WorkoutSet copyWith({
    String? id,
    String? workoutExerciseId,
    int? reps,
    double? weight,
    double? totalWeight,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      totalWeight: totalWeight ?? this.totalWeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutSet(id: $id, reps: $reps, weight: $weight, totalWeight: $totalWeight)';
  }
}

/// Модель упражнения в тренировке
class WorkoutExercise {
  final String id;
  final String workoutId;
  final String exerciseId;
  final String exerciseName;
  final String targetMuscleGroup;
  final int equipmentCount;
  final double totalWeight; // Общий вес всех подходов упражнения
  final List<WorkoutSet> sets; // Подходы упражнения

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetMuscleGroup,
    required this.equipmentCount,
    required this.totalWeight,
    required this.sets,
  });

  /// Создание модели упражнения в тренировке из JSON
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String? ?? '',
      workoutId: json['workoutId'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      exerciseName: json['exerciseName'] as String? ?? 'Неизвестное упражнение',
      targetMuscleGroup: json['targetMuscleGroup'] as String? ?? 'Неизвестная группа',
      equipmentCount: json['equipmentCount'] as int? ?? 1,
      totalWeight: json['totalWeight'] is String 
          ? double.tryParse(json['totalWeight'] as String) ?? 0.0
          : (json['totalWeight'] as num?)?.toDouble() ?? 0.0,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((setJson) => WorkoutSet.fromJson(setJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Преобразование модели упражнения в тренировке в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'targetMuscleGroup': targetMuscleGroup,
      'equipmentCount': equipmentCount,
      'totalWeight': totalWeight,
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }

  /// Создание копии упражнения в тренировке с изменениями
  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    String? exerciseName,
    String? targetMuscleGroup,
    int? equipmentCount,
    double? totalWeight,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetMuscleGroup: targetMuscleGroup ?? this.targetMuscleGroup,
      equipmentCount: equipmentCount ?? this.equipmentCount,
      totalWeight: totalWeight ?? this.totalWeight,
      sets: sets ?? this.sets,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkoutExercise(id: $id, exerciseName: $exerciseName, totalWeight: $totalWeight, sets: ${sets.length})';
  }
}

/// Модель тренировки
class Workout {
  final String id;
  final String userId;
  final DateTime date;
  final int? duration; // Продолжительность в минутах
  final List<String> targetMuscleGroups; // Целевые группы мышц
  final double totalWeight; // Общий поднятый вес в тренировке
  final List<WorkoutExercise> exercises; // Упражнения в тренировке

  const Workout({
    required this.id,
    required this.userId,
    required this.date,
    this.duration,
    required this.targetMuscleGroups,
    required this.totalWeight,
    required this.exercises,
  });

  /// Создание модели тренировки из JSON
  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      duration: json['duration'] != null 
          ? (json['duration'] is String 
              ? int.tryParse(json['duration'] as String) 
              : json['duration'] as int?)
          : null,
      targetMuscleGroups: (json['targetMuscleGroups'] as List<dynamic>)
          .map((group) => group as String)
          .toList(),
      totalWeight: json['totalWeight'] is String 
          ? double.tryParse(json['totalWeight'] as String) ?? 0.0
          : (json['totalWeight'] as num).toDouble(),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((exerciseJson) => WorkoutExercise.fromJson(exerciseJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Преобразование модели тренировки в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String().split('T')[0], // Только дата
      'duration': duration,
      'targetMuscleGroups': targetMuscleGroups,
      'totalWeight': totalWeight,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  /// Создание копии тренировки с изменениями
  Workout copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? duration,
    List<String>? targetMuscleGroups,
    double? totalWeight,
    List<WorkoutExercise>? exercises,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      totalWeight: totalWeight ?? this.totalWeight,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Форматированная строка продолжительности тренировки
  String get formattedDuration {
    if (duration == null) return 'Не указано';
    
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours} ч ${minutes} мин' : '${hours} ч';
    }
    return '${minutes} мин';
  }

  /// Форматированная строка целевых групп мышц
  String get formattedTargetMuscleGroups {
    if (targetMuscleGroups.isEmpty) return 'Не указано';
    return targetMuscleGroups.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Workout(id: $id, date: $date, duration: $duration, totalWeight: $totalWeight, exercises: ${exercises.length})';
  }
}

/// Ответ API для списка тренировок с пагинацией
class WorkoutsResponse {
  final List<Workout> workouts;
  final int total;
  final int limit;
  final int offset;

  const WorkoutsResponse({
    required this.workouts,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// Создание модели ответа из JSON
  factory WorkoutsResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutsResponse(
      workouts: (json['data'] as List<dynamic>)
          .map((workoutJson) => Workout.fromJson(workoutJson as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }

  /// Проверяет, есть ли еще данные для загрузки
  bool get hasMore => offset + workouts.length < total;
}

/// Статистика тренировок пользователя
class WorkoutStatistics {
  final int totalWorkouts; // Общее количество тренировок
  final double totalWeight; // Общий поднятый вес
  final int totalDuration; // Общая продолжительность в минутах
  final double averageWeight; // Средний поднятый вес за тренировку
  final int averageDuration; // Средняя продолжительность тренировки в минутах

  const WorkoutStatistics({
    required this.totalWorkouts,
    required this.totalWeight,
    required this.totalDuration,
    required this.averageWeight,
    required this.averageDuration,
  });

  /// Создание модели статистики из JSON
  factory WorkoutStatistics.fromJson(Map<String, dynamic> json) {
    return WorkoutStatistics(
      totalWorkouts: json['totalWorkouts'] as int,
      totalWeight: (json['totalWeight'] as num).toDouble(),
      totalDuration: json['totalDuration'] as int,
      averageWeight: (json['averageWeight'] as num).toDouble(),
      averageDuration: json['averageDuration'] as int,
    );
  }

  /// Преобразование модели статистики в JSON
  Map<String, dynamic> toJson() {
    return {
      'totalWorkouts': totalWorkouts,
      'totalWeight': totalWeight,
      'totalDuration': totalDuration,
      'averageWeight': averageWeight,
      'averageDuration': averageDuration,
    };
  }

  /// Форматированная строка общей продолжительности
  String get formattedTotalDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours} ч ${minutes} мин' : '${hours} ч';
    }
    return '${minutes} мин';
  }

  /// Форматированная строка средней продолжительности
  String get formattedAverageDuration {
    final hours = averageDuration ~/ 60;
    final minutes = averageDuration % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours} ч ${minutes} мин' : '${hours} ч';
    }
    return '${minutes} мин';
  }

  @override
  String toString() {
    return 'WorkoutStatistics(totalWorkouts: $totalWorkouts, totalWeight: $totalWeight, totalDuration: $totalDuration)';
  }
}
