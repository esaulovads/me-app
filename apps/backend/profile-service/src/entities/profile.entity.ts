import { Entity, Column, PrimaryGeneratedColumn, BeforeInsert, BeforeUpdate } from 'typeorm';

// Enum для целей пользователя
export enum UserGoal {
  GAIN_WEIGHT = 'GAIN_WEIGHT',
  MAINTAIN_WEIGHT = 'MAINTAIN_WEIGHT',
  LOSE_WEIGHT = 'LOSE_WEIGHT',
}

// Enum для пола пользователя
export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE'
}

// Enum для статуса ИМТ
export enum BMIStatus {
  UNDERWEIGHT = 'UNDERWEIGHT',
  NORMAL = 'NORMAL',
  OVERWEIGHT = 'OVERWEIGHT',
  OBESE = 'OBESE'
}

// Enum для уровня физической активности
export enum ActivityLevel {
  SEDENTARY = 'SEDENTARY', // 1.2
  LIGHTLY_ACTIVE = 'LIGHTLY_ACTIVE', // 1.375
  MODERATELY_ACTIVE = 'MODERATELY_ACTIVE', // 1.55
  VERY_ACTIVE = 'VERY_ACTIVE', // 1.725
  EXTREMELY_ACTIVE = 'EXTREMELY_ACTIVE', // 1.9
}

// Матрица для расчета нормы белка (г/кг веса)
const PROTEIN_MATRIX = {
  [UserGoal.LOSE_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.5,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.7,
    [ActivityLevel.MODERATELY_ACTIVE]: 2.0,
    [ActivityLevel.VERY_ACTIVE]: 2.2,
    [ActivityLevel.EXTREMELY_ACTIVE]: 2.4,
  },
  [UserGoal.MAINTAIN_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.3,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.5,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.7,
    [ActivityLevel.VERY_ACTIVE]: 1.9,
    [ActivityLevel.EXTREMELY_ACTIVE]: 2.1,
  },
  [UserGoal.GAIN_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.5,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.7,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.9,
    [ActivityLevel.VERY_ACTIVE]: 2.1,
    [ActivityLevel.EXTREMELY_ACTIVE]: 2.3,
  },
};

// Матрица для расчета нормы жиров для женщин (г/кг веса)
const FAT_MATRIX_FEMALE = {
  [UserGoal.LOSE_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 0.95,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.0,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.1,
    [ActivityLevel.VERY_ACTIVE]: 1.2,
    [ActivityLevel.EXTREMELY_ACTIVE]: 1.3,
  },
  [UserGoal.MAINTAIN_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.1,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.1,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.2,
    [ActivityLevel.VERY_ACTIVE]: 1.3,
    [ActivityLevel.EXTREMELY_ACTIVE]: 1.3,
  },
  [UserGoal.GAIN_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.2,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.2,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.3,
    [ActivityLevel.VERY_ACTIVE]: 1.35,
    [ActivityLevel.EXTREMELY_ACTIVE]: 1.4,
  },
};

// Матрица для расчета нормы жиров для мужчин (г/кг веса)
const FAT_MATRIX_MALE = {
  [UserGoal.LOSE_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 0.9,
    [ActivityLevel.LIGHTLY_ACTIVE]: 0.95,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.05,
    [ActivityLevel.VERY_ACTIVE]: 1.1,
    [ActivityLevel.EXTREMELY_ACTIVE]: 1.15,
  },
  [UserGoal.MAINTAIN_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.0,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.05,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.1,
    [ActivityLevel.VERY_ACTIVE]: 1.2,
    [ActivityLevel.EXTREMELY_ACTIVE]: 1.25,
  },
  [UserGoal.GAIN_WEIGHT]: {
    [ActivityLevel.SEDENTARY]: 1.1,
    [ActivityLevel.LIGHTLY_ACTIVE]: 1.15,
    [ActivityLevel.MODERATELY_ACTIVE]: 1.25,
    [ActivityLevel.VERY_ACTIVE]: 1.3,
    [ActivityLevel.EXTREMELY_ACTIVE]: 1.35,
  },
};

// Матрица базовой длительности сна (в часах) по полу и возрасту
const BASE_SLEEP_MATRIX = {
  [Gender.MALE]: {
    '18-25': 7.5,
    '26-35': 7.5,
    '36-45': 7.0,
    '46-55': 7.0,
    '56-65': 6.5,
    '65+': 6.5,
  },
  [Gender.FEMALE]: {
    '18-25': 8.0,
    '26-35': 8.0,
    '36-45': 7.5,
    '46-55': 7.5,
    '56-65': 7.0,
    '65+': 6.5,
  },
};

// Матрица модификаторов активности для сна (в часах)
const SLEEP_ACTIVITY_MODIFIER_MATRIX = {
  '18-35': {
    [Gender.MALE]: {
      [ActivityLevel.SEDENTARY]: 0.00,
      [ActivityLevel.LIGHTLY_ACTIVE]: 0.00, // "низкая активность"
      [ActivityLevel.MODERATELY_ACTIVE]: 0.25, // "умеренная"
      [ActivityLevel.VERY_ACTIVE]: 0.50, // "высокая"
      [ActivityLevel.EXTREMELY_ACTIVE]: 0.75, // "экстремальная"
    },
    [Gender.FEMALE]: {
      [ActivityLevel.SEDENTARY]: 0.00,
      [ActivityLevel.LIGHTLY_ACTIVE]: 0.00, // "низкая активность"
      [ActivityLevel.MODERATELY_ACTIVE]: 0.30, // "умеренная"
      [ActivityLevel.VERY_ACTIVE]: 0.60, // "высокая"
      [ActivityLevel.EXTREMELY_ACTIVE]: 0.85, // "экстремальная"
    },
  },
  '36-55': {
    [Gender.MALE]: {
      [ActivityLevel.SEDENTARY]: 0.00,
      [ActivityLevel.LIGHTLY_ACTIVE]: 0.00,
      [ActivityLevel.MODERATELY_ACTIVE]: 0.20,
      [ActivityLevel.VERY_ACTIVE]: 0.45,
      [ActivityLevel.EXTREMELY_ACTIVE]: 0.70,
    },
    [Gender.FEMALE]: {
      [ActivityLevel.SEDENTARY]: 0.00,
      [ActivityLevel.LIGHTLY_ACTIVE]: 0.00,
      [ActivityLevel.MODERATELY_ACTIVE]: 0.25,
      [ActivityLevel.VERY_ACTIVE]: 0.55,
      [ActivityLevel.EXTREMELY_ACTIVE]: 0.80,
    },
  },
  '56+': {
    [Gender.MALE]: {
      [ActivityLevel.SEDENTARY]: 0.00,
      [ActivityLevel.LIGHTLY_ACTIVE]: 0.00,
      [ActivityLevel.MODERATELY_ACTIVE]: 0.15,
      [ActivityLevel.VERY_ACTIVE]: 0.35,
      [ActivityLevel.EXTREMELY_ACTIVE]: 0.60,
    },
    [Gender.FEMALE]: {
      [ActivityLevel.SEDENTARY]: 0.00,
      [ActivityLevel.LIGHTLY_ACTIVE]: 0.00,
      [ActivityLevel.MODERATELY_ACTIVE]: 0.20,
      [ActivityLevel.VERY_ACTIVE]: 0.40,
      [ActivityLevel.EXTREMELY_ACTIVE]: 0.65,
    },
  },
};

@Entity('profiles')
export class Profile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // ID пользователя из сервиса аутентификации
  @Column({ unique: true })
  userId: string;

  @Column({ nullable: true })
  name: string;

  @Column({ type: 'date', nullable: true })
  birthDate: Date;

  @Column('int', { nullable: true })
  age: number;

  @Column('float', { nullable: true })
  height: number;

  @Column('float', { nullable: true })
  weight: number;

  @Column({
    type: 'enum',
    enum: UserGoal,
    nullable: true
  })
  goal: UserGoal;

  @Column({
    type: 'enum',
    enum: Gender,
    nullable: true
  })
  gender: Gender;

  @Column('float', { nullable: true })
  bmi: number;

  @Column({
    type: 'enum',
    enum: BMIStatus,
    nullable: true
  })
  bmiStatus: BMIStatus;

  @Column({
    type: 'enum',
    enum: ActivityLevel,
    nullable: true
  })
  activityLevel: ActivityLevel;

  @Column('float', { nullable: true })
  bmr: number; // Базовый дневной метаболизм

  @Column('float', { nullable: true })
  tdee: number; // Общий расход энергии

  @Column('float', { nullable: true })
  proteinTarget: number; // Дневная норма белков

  @Column('float', { nullable: true })
  fatTarget: number; // Дневная норма жиров

  @Column('float', { nullable: true })
  carbTarget: number; // Дневная норма углеводов

  @Column('float', { nullable: true })
  recommendedSleepDuration: number; // Рекомендуемая продолжительность сна

  @Column('float', { nullable: true })
  sleepQualityCoefficient: number; // Коэффициент качества сна (среднее отношение факт/норма за 2 недели)

  @Column('float', { nullable: true })
  optimalWeeklyTrainingMinutes: number; // Оптимальное количество минут тренировок в неделю

  @Column('float', { nullable: true })
  optimalDailyTrainingMinutes: number; // Оптимальное количество минут тренировок в день

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Метод для проверки заполненности профиля
  isComplete(): boolean {
    return !!(
      this.name && 
      this.birthDate && 
      this.height && 
      this.weight && 
      this.goal &&
      this.gender &&
      this.activityLevel
    );
  }

  // Метод для определения статуса ИМТ
  calculateBMIStatus(bmi: number | null): BMIStatus | null {
    if (bmi === null) return null;
    
    if (bmi < 18.5) return BMIStatus.UNDERWEIGHT;
    if (bmi >= 18.5 && bmi < 25) return BMIStatus.NORMAL;
    if (bmi >= 25 && bmi < 30) return BMIStatus.OVERWEIGHT;
    return BMIStatus.OBESE;
  }

  // Метод для расчета ИМТ
  calculateBMI(): number | null {
    if (!this.height || !this.weight) {
      return null;
    }
    // Переводим рост из см в метры
    const heightInMeters = this.height / 100;
    return Number((this.weight / (heightInMeters * heightInMeters)).toFixed(2));
  }

  // Расчет базового метаболизма (BMR)
  calculateBMR(): number | null {
    if (!this.weight || !this.height || !this.birthDate || !this.gender) {
      return null;
    }

    // Рассчитываем возраст на основе даты рождения
    const today = new Date();
    const birthDate = typeof this.birthDate === 'string' ? new Date(this.birthDate) : this.birthDate;
    const age = today.getFullYear() - birthDate.getFullYear();

    // Формула Миффлина-Джеора
    const baseBMR = 10 * this.weight + 6.25 * this.height - 5 * age;
    
    const result = Math.round(
      this.gender === Gender.MALE 
        ? baseBMR + 5 
        : baseBMR - 161
    );

    return result;
  }

  // Получение коэффициента активности
  getActivityMultiplier(): number | null {
    if (!this.activityLevel) return null;

    const multipliers = {
      [ActivityLevel.SEDENTARY]: 1.2,
      [ActivityLevel.LIGHTLY_ACTIVE]: 1.375,
      [ActivityLevel.MODERATELY_ACTIVE]: 1.55,
      [ActivityLevel.VERY_ACTIVE]: 1.725,
      [ActivityLevel.EXTREMELY_ACTIVE]: 1.9,
    };

    return multipliers[this.activityLevel];
  }

  // Расчет общего расхода энергии (TDEE)
  calculateTDEE(): number | null {
    const bmr = this.calculateBMR();
    const activityMultiplier = this.getActivityMultiplier();

    if (!bmr || !activityMultiplier) {
      return null;
    }

    return Math.round(bmr * activityMultiplier);
  }

  // Расчет дневной нормы белка
  calculateProteinTarget(): number | null {
    if (!this.weight || !this.goal || !this.activityLevel) {
      return null;
    }

    const proteinPerKg = PROTEIN_MATRIX[this.goal][this.activityLevel];
    return Math.round(this.weight * proteinPerKg);
  }

  // Расчет дневной нормы жиров
  calculateFatTarget(): number | null {
    if (!this.weight || !this.goal || !this.activityLevel) {
      return null;
    }

    // Выбираем матрицу в зависимости от пола
    const fatMatrix = this.gender === Gender.FEMALE ? FAT_MATRIX_FEMALE : FAT_MATRIX_MALE;
    const fatPerKg = fatMatrix[this.goal][this.activityLevel];
    return Math.round(this.weight * fatPerKg);
  }

  // Расчет дневной нормы углеводов
  calculateCarbTarget(): number | null {
    if (!this.tdee || !this.proteinTarget || !this.fatTarget) {
      return null;
    }

    // Калории из белков и жиров
    const proteinCalories = this.proteinTarget * 4; // 1г белка = 4 ккал
    const fatCalories = this.fatTarget * 9; // 1г жира = 9 ккал

    // Оставшиеся калории для углеводов
    const carbCalories = this.tdee - (proteinCalories + fatCalories);

    // Переводим калории в граммы (1г углеводов = 4 ккал)
    return Math.round(carbCalories / 4);
  }

  // Метод для определения возрастной группы
  private getAgeGroup(age: number): string {
    if (age >= 18 && age <= 25) return '18-25';
    if (age >= 26 && age <= 35) return '26-35';
    if (age >= 36 && age <= 45) return '36-45';
    if (age >= 46 && age <= 55) return '46-55';
    if (age >= 56 && age <= 65) return '56-65';
    return '65+';
  }

  // Метод для определения возрастной группы для модификаторов активности
  private getActivityAgeGroup(age: number): string {
    if (age >= 18 && age <= 35) return '18-35';
    if (age >= 36 && age <= 55) return '36-55';
    return '56+';
  }

  // Расчет рекомендуемой продолжительности сна
  calculateRecommendedSleepDuration(): number | null {
    if (!this.birthDate || !this.gender || !this.activityLevel) {
      return null;
    }

    // Рассчитываем возраст
    const today = new Date();
    const birthDate = typeof this.birthDate === 'string' ? new Date(this.birthDate) : this.birthDate;
    const age = today.getFullYear() - birthDate.getFullYear();

    // Получаем базовую длительность сна
    const ageGroup = this.getAgeGroup(age);
    const baseSleepDuration = BASE_SLEEP_MATRIX[this.gender][ageGroup];

    // Получаем модификатор активности
    const activityAgeGroup = this.getActivityAgeGroup(age);
    const activityModifier = SLEEP_ACTIVITY_MODIFIER_MATRIX[activityAgeGroup][this.gender][this.activityLevel];

    // Рассчитываем итоговую рекомендуемую продолжительность
    const recommendedDuration = baseSleepDuration + activityModifier;

    // Округляем до одного знака после запятой
    return Number(recommendedDuration.toFixed(1));
  }

  // Расчет коэффициента возраста для тренировок
  calculateAgeCoefficient(): number | null {
    if (!this.birthDate) {
      return null;
    }

    // Рассчитываем возраст
    const today = new Date();
    const birthDate = typeof this.birthDate === 'string' ? new Date(this.birthDate) : this.birthDate;
    const age = today.getFullYear() - birthDate.getFullYear();

    // Коэффициенты возраста для тренировок
    if (age <= 30) {
      return 1.0; // До 30 лет - коэффициент 1
    } else if (age >= 31 && age <= 50) {
      return 0.8; // От 31 до 50 лет - коэффициент 0.8
    } else {
      return 0.6; // Больше 51 года - коэффициент 0.6
    }
  }

  // Расчет оптимального количества минут тренировок в неделю
  calculateOptimalWeeklyTrainingMinutes(): number | null {
    const ageCoefficient = this.calculateAgeCoefficient();
    
    if (!ageCoefficient || !this.sleepQualityCoefficient) {
      return null;
    }

    // Базовый минимум 150 минут * коэффициент качества сна * коэффициент возраста
    const weeklyMinutes = 150 * this.sleepQualityCoefficient * ageCoefficient;
    
    // Округляем до целого числа
    return Math.round(weeklyMinutes);
  }

  // Расчет оптимального количества минут тренировок в день
  calculateOptimalDailyTrainingMinutes(trainingDaysPerWeek: number): number | null {
    const weeklyMinutes = this.calculateOptimalWeeklyTrainingMinutes();
    
    if (!weeklyMinutes || trainingDaysPerWeek <= 0) {
      return null;
    }

    // Делим недельную норму на количество дней тренировок
    const dailyMinutes = weeklyMinutes / trainingDaysPerWeek;
    
    // Округляем до целого числа
    return Math.round(dailyMinutes);
  }

  // Обновляем хук для автоматического расчета всех значений
  @BeforeInsert()
  @BeforeUpdate()
  updateCalculatedFields() {
    // Сначала рассчитываем BMI и его статус
    this.bmi = this.calculateBMI();
    this.bmiStatus = this.calculateBMIStatus(this.bmi);

    // Затем рассчитываем BMR и TDEE
    this.bmr = this.calculateBMR();
    this.tdee = this.calculateTDEE();

    // В конце рассчитываем макронутриенты
    this.proteinTarget = this.calculateProteinTarget();
    this.fatTarget = this.calculateFatTarget();
    this.carbTarget = this.calculateCarbTarget();
    this.recommendedSleepDuration = this.calculateRecommendedSleepDuration();
    
    // Рассчитываем оптимальное количество минут тренировок в неделю
    this.optimalWeeklyTrainingMinutes = this.calculateOptimalWeeklyTrainingMinutes();
    
    // Примечание: optimalDailyTrainingMinutes будет рассчитываться отдельно в сервисе,
    // так как требует данные о расписании тренировок из activity-service
  }
} 