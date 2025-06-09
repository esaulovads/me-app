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
  notSpecified,
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

  Profile({
    this.name,
    this.birthDate,
    this.gender,
    this.height,
    this.weight,
    this.goal,
    this.activityLevel,
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
  }) {
    return Profile(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
} 