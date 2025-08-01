// Модель расписания сна
class SleepSchedule {
  final String id;
  final String userId;
  final ScheduleType scheduleType;
  final String? mondayWakeTime;
  final String? tuesdayWakeTime;
  final String? wednesdayWakeTime;
  final String? thursdayWakeTime;
  final String? fridayWakeTime;
  final String? saturdayWakeTime;
  final String? sundayWakeTime;
  final String? weekdaysWakeTime;
  final String? weekendsWakeTime;
  final String? defaultWakeTime;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SleepSchedule({
    required this.id,
    required this.userId,
    required this.scheduleType,
    this.mondayWakeTime,
    this.tuesdayWakeTime,
    this.wednesdayWakeTime,
    this.thursdayWakeTime,
    this.fridayWakeTime,
    this.saturdayWakeTime,
    this.sundayWakeTime,
    this.weekdaysWakeTime,
    this.weekendsWakeTime,
    this.defaultWakeTime,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  // Фабричный конструктор из JSON
  factory SleepSchedule.fromJson(Map<String, dynamic> json) {
    return SleepSchedule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      scheduleType: ScheduleType.values.firstWhere(
        (e) => e.value == json['scheduleType'],
        orElse: () => ScheduleType.sameTime,
      ),
      mondayWakeTime: json['mondayWakeTime'] as String?,
      tuesdayWakeTime: json['tuesdayWakeTime'] as String?,
      wednesdayWakeTime: json['wednesdayWakeTime'] as String?,
      thursdayWakeTime: json['thursdayWakeTime'] as String?,
      fridayWakeTime: json['fridayWakeTime'] as String?,
      saturdayWakeTime: json['saturdayWakeTime'] as String?,
      sundayWakeTime: json['sundayWakeTime'] as String?,
      weekdaysWakeTime: json['weekdaysWakeTime'] as String?,
      weekendsWakeTime: json['weekendsWakeTime'] as String?,
      defaultWakeTime: json['defaultWakeTime'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'scheduleType': scheduleType.value,
      'mondayWakeTime': mondayWakeTime,
      'tuesdayWakeTime': tuesdayWakeTime,
      'wednesdayWakeTime': wednesdayWakeTime,
      'thursdayWakeTime': thursdayWakeTime,
      'fridayWakeTime': fridayWakeTime,
      'saturdayWakeTime': saturdayWakeTime,
      'sundayWakeTime': sundayWakeTime,
      'weekdaysWakeTime': weekdaysWakeTime,
      'weekendsWakeTime': weekendsWakeTime,
      'defaultWakeTime': defaultWakeTime,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Метод для получения времени пробуждения для конкретного дня недели
  String? getWakeTimeForDay(int dayOfWeek) {
    // dayOfWeek: 1 = понедельник, 2 = вторник, ..., 7 = воскресенье
    
    switch (scheduleType) {
      case ScheduleType.sameTime:
        return defaultWakeTime;
        
      case ScheduleType.weekdaysWeekends:
        // Будни: понедельник-пятница (1-5), выходные: суббота-воскресенье (6,7)
        return (dayOfWeek >= 1 && dayOfWeek <= 5) 
          ? weekdaysWakeTime 
          : weekendsWakeTime;
          
      case ScheduleType.individual:
        switch (dayOfWeek) {
          case 1: return mondayWakeTime;
          case 2: return tuesdayWakeTime;
          case 3: return wednesdayWakeTime;
          case 4: return thursdayWakeTime;
          case 5: return fridayWakeTime;
          case 6: return saturdayWakeTime;
          case 7: return sundayWakeTime;
          default: return null;
        }
    }
  }

  // Метод для создания копии с изменениями
  SleepSchedule copyWith({
    String? id,
    String? userId,
    ScheduleType? scheduleType,
    String? mondayWakeTime,
    String? tuesdayWakeTime,
    String? wednesdayWakeTime,
    String? thursdayWakeTime,
    String? fridayWakeTime,
    String? saturdayWakeTime,
    String? sundayWakeTime,
    String? weekdaysWakeTime,
    String? weekendsWakeTime,
    String? defaultWakeTime,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scheduleType: scheduleType ?? this.scheduleType,
      mondayWakeTime: mondayWakeTime ?? this.mondayWakeTime,
      tuesdayWakeTime: tuesdayWakeTime ?? this.tuesdayWakeTime,
      wednesdayWakeTime: wednesdayWakeTime ?? this.wednesdayWakeTime,
      thursdayWakeTime: thursdayWakeTime ?? this.thursdayWakeTime,
      fridayWakeTime: fridayWakeTime ?? this.fridayWakeTime,
      saturdayWakeTime: saturdayWakeTime ?? this.saturdayWakeTime,
      sundayWakeTime: sundayWakeTime ?? this.sundayWakeTime,
      weekdaysWakeTime: weekdaysWakeTime ?? this.weekdaysWakeTime,
      weekendsWakeTime: weekendsWakeTime ?? this.weekendsWakeTime,
      defaultWakeTime: defaultWakeTime ?? this.defaultWakeTime,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SleepSchedule &&
      other.id == id &&
      other.userId == userId &&
      other.scheduleType == scheduleType &&
      other.mondayWakeTime == mondayWakeTime &&
      other.tuesdayWakeTime == tuesdayWakeTime &&
      other.wednesdayWakeTime == wednesdayWakeTime &&
      other.thursdayWakeTime == thursdayWakeTime &&
      other.fridayWakeTime == fridayWakeTime &&
      other.saturdayWakeTime == saturdayWakeTime &&
      other.sundayWakeTime == sundayWakeTime &&
      other.weekdaysWakeTime == weekdaysWakeTime &&
      other.weekendsWakeTime == weekendsWakeTime &&
      other.defaultWakeTime == defaultWakeTime &&
      other.isEnabled == isEnabled &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      scheduleType,
      mondayWakeTime,
      tuesdayWakeTime,
      wednesdayWakeTime,
      thursdayWakeTime,
      fridayWakeTime,
      saturdayWakeTime,
      sundayWakeTime,
      weekdaysWakeTime,
      weekendsWakeTime,
      defaultWakeTime,
      isEnabled,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'SleepSchedule(id: $id, userId: $userId, scheduleType: $scheduleType, isEnabled: $isEnabled)';
  }
}

// Enum для типа расписания сна
enum ScheduleType {
  individual('INDIVIDUAL', 'Индивидуальное для каждого дня'),
  weekdaysWeekends('WEEKDAYS_WEEKENDS', 'Будни и выходные отдельно'),
  sameTime('SAME_TIME', 'Одинаковое время (рекомендуется)');

  const ScheduleType(this.value, this.displayName);

  final String value;
  final String displayName;

  // Получение enum по строковому значению
  static ScheduleType fromString(String value) {
    return ScheduleType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ScheduleType.sameTime,
    );
  }
}

// DTO для создания/обновления расписания сна
class CreateSleepScheduleDto {
  final ScheduleType scheduleType;
  final String? mondayWakeTime;
  final String? tuesdayWakeTime;
  final String? wednesdayWakeTime;
  final String? thursdayWakeTime;
  final String? fridayWakeTime;
  final String? saturdayWakeTime;
  final String? sundayWakeTime;
  final String? weekdaysWakeTime;
  final String? weekendsWakeTime;
  final String? defaultWakeTime;
  final bool? isEnabled;

  const CreateSleepScheduleDto({
    required this.scheduleType,
    this.mondayWakeTime,
    this.tuesdayWakeTime,
    this.wednesdayWakeTime,
    this.thursdayWakeTime,
    this.fridayWakeTime,
    this.saturdayWakeTime,
    this.sundayWakeTime,
    this.weekdaysWakeTime,
    this.weekendsWakeTime,
    this.defaultWakeTime,
    this.isEnabled,
  });

  // Преобразование в JSON для отправки на сервер
  Map<String, dynamic> toJson() {
    return {
      'scheduleType': scheduleType.value,
      if (mondayWakeTime != null) 'mondayWakeTime': mondayWakeTime,
      if (tuesdayWakeTime != null) 'tuesdayWakeTime': tuesdayWakeTime,
      if (wednesdayWakeTime != null) 'wednesdayWakeTime': wednesdayWakeTime,
      if (thursdayWakeTime != null) 'thursdayWakeTime': thursdayWakeTime,
      if (fridayWakeTime != null) 'fridayWakeTime': fridayWakeTime,
      if (saturdayWakeTime != null) 'saturdayWakeTime': saturdayWakeTime,
      if (sundayWakeTime != null) 'sundayWakeTime': sundayWakeTime,
      if (weekdaysWakeTime != null) 'weekdaysWakeTime': weekdaysWakeTime,
      if (weekendsWakeTime != null) 'weekendsWakeTime': weekendsWakeTime,
      if (defaultWakeTime != null) 'defaultWakeTime': defaultWakeTime,
      if (isEnabled != null) 'isEnabled': isEnabled,
    };
  }
} 