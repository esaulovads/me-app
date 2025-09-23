import 'muscle_group_model.dart';

/// Модель расписания тренировок
class WorkoutSchedule {
  final String id;
  final String userId;
  final int dayOfWeek; // 0 = воскресенье, 1 = понедельник, ..., 6 = суббота
  final String? muscleGroupId;
  final bool isFullBody;
  final bool isActive;
  final MuscleGroup? muscleGroup;

  const WorkoutSchedule({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    this.muscleGroupId,
    required this.isFullBody,
    required this.isActive,
    this.muscleGroup,
  });

  /// Создание из JSON
  factory WorkoutSchedule.fromJson(Map<String, dynamic> json) {
    return WorkoutSchedule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      muscleGroupId: json['muscleGroupId'] as String?,
      isFullBody: json['isFullBody'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      muscleGroup: json['muscleGroup'] != null
          ? MuscleGroup.fromJson(json['muscleGroup'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dayOfWeek': dayOfWeek,
      'muscleGroupId': muscleGroupId,
      'isFullBody': isFullBody,
      'isActive': isActive,
      'muscleGroup': muscleGroup?.toJson(),
    };
  }

  /// Копирование с изменениями
  WorkoutSchedule copyWith({
    String? id,
    String? userId,
    int? dayOfWeek,
    String? muscleGroupId,
    bool? isFullBody,
    bool? isActive,
    MuscleGroup? muscleGroup,
  }) {
    return WorkoutSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      muscleGroupId: muscleGroupId ?? this.muscleGroupId,
      isFullBody: isFullBody ?? this.isFullBody,
      isActive: isActive ?? this.isActive,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }

  /// Получить название дня недели
  String get dayName {
    switch (dayOfWeek) {
      case 0:
        return 'Воскресенье';
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      default:
        return 'Неизвестный день';
    }
  }

  /// Получить короткое название дня недели
  String get shortDayName {
    switch (dayOfWeek) {
      case 0:
        return 'Вс';
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      default:
        return '??';
    }
  }

  /// Получить описание тренировки
  String get workoutDescription {
    if (!isActive) return 'Отдых';
    if (isFullBody) return 'Fullbody';
    if (muscleGroup != null) return muscleGroup!.name;
    return 'Тренировка';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
