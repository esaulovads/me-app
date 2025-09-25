// Модель данных профиля пользователя

// Enum для целей пользователя
enum UserGoal {
  GAIN_WEIGHT,
  MAINTAIN_WEIGHT,
  LOSE_WEIGHT,
}

// Enum для пола пользователя
enum Gender {
  male,
  female,
}

// Enum для уровня физической активности
enum ActivityLevel {
  SEDENTARY,
  LIGHTLY_ACTIVE,
  MODERATELY_ACTIVE,
  VERY_ACTIVE,
  EXTREMELY_ACTIVE,
}

// Класс для хранения данных профиля
class Profile {
  final String? name;
  final DateTime? birthDate;
  final Gender? gender;
  final double? height;
  final double? weight;
  final UserGoal? goal;
  final ActivityLevel? activityLevel;
  final double? tdee; // Общий расход энергии (дневная норма калорий)
  final double? proteinTarget; // Дневная норма белков
  final double? fatTarget; // Дневная норма жиров
  final double? carbTarget; // Дневная норма углеводов
  final double? recommendedSleepDuration; // Рекомендуемая продолжительность сна в часах
  final double? sleepQualityCoefficient; // Коэффициент качества сна
  final double? optimalWeeklyTrainingMinutes; // Оптимальное количество минут тренировок в неделю
  final double? optimalDailyTrainingMinutes; // Оптимальное количество минут тренировок в день

  Profile({
    this.name,
    this.birthDate,
    this.gender,
    this.height,
    this.weight,
    this.goal,
    this.activityLevel,
    this.tdee,
    this.proteinTarget,
    this.fatTarget,
    this.carbTarget,
    this.recommendedSleepDuration,
    this.sleepQualityCoefficient,
    this.optimalWeeklyTrainingMinutes,
    this.optimalDailyTrainingMinutes,
  });

  // Метод для создания копии объекта с новыми значениями
  Profile copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    double? height,
    double? weight,
    UserGoal? goal,
    ActivityLevel? activityLevel,
    double? tdee,
    double? proteinTarget,
    double? fatTarget,
    double? carbTarget,
    double? recommendedSleepDuration,
    double? sleepQualityCoefficient,
    double? optimalWeeklyTrainingMinutes,
    double? optimalDailyTrainingMinutes,
  }) {
    return Profile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
      tdee: tdee ?? this.tdee,
      proteinTarget: proteinTarget ?? this.proteinTarget,
      fatTarget: fatTarget ?? this.fatTarget,
      carbTarget: carbTarget ?? this.carbTarget,
      recommendedSleepDuration: recommendedSleepDuration ?? this.recommendedSleepDuration,
      sleepQualityCoefficient: sleepQualityCoefficient ?? this.sleepQualityCoefficient,
      optimalWeeklyTrainingMinutes: optimalWeeklyTrainingMinutes ?? this.optimalWeeklyTrainingMinutes,
      optimalDailyTrainingMinutes: optimalDailyTrainingMinutes ?? this.optimalDailyTrainingMinutes,
    );
  }
} 