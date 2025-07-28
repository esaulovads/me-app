/// Модель для сессии сна
class SleepSession {
  final String id;
  final String userId;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final int durationMinutes;
  final String sleepDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SleepSession({
    required this.id,
    required this.userId,
    required this.sleepTime,
    required this.wakeTime,
    required this.durationMinutes,
    required this.sleepDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает объект SleepSession из JSON
  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sleepTime: DateTime.parse(json['sleepTime'] as String),
      wakeTime: DateTime.parse(json['wakeTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      sleepDate: json['sleepDate'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует объект в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sleepTime': sleepTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'sleepDate': sleepDate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Продолжительность сна в часах
  double get durationHours => durationMinutes / 60.0;

  /// Копирование объекта с изменением отдельных полей
  SleepSession copyWith({
    String? id,
    String? userId,
    DateTime? sleepTime,
    DateTime? wakeTime,
    int? durationMinutes,
    String? sleepDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SleepSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sleepTime: sleepTime ?? this.sleepTime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sleepDate: sleepDate ?? this.sleepDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SleepSession(id: $id, userId: $userId, sleepDate: $sleepDate, durationMinutes: $durationMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepSession &&
        other.id == id &&
        other.userId == userId &&
        other.sleepTime == sleepTime &&
        other.wakeTime == wakeTime &&
        other.durationMinutes == durationMinutes &&
        other.sleepDate == sleepDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      sleepTime,
      wakeTime,
      durationMinutes,
      sleepDate,
    );
  }
} 