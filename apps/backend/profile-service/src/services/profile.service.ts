import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { Profile } from '../entities/profile.entity';
import { 
  UpdateNameDto, 
  UpdateBirthDateDto,
  UpdateHeightDto, 
  UpdateWeightDto, 
  UpdateGoalDto, 
  UpdateGenderDto,
  UpdateActivityLevelDto 
} from '../dto/update-profile.dto';
import { servicesConfig } from '../config/services.config';

// Интерфейс для данных о сне из sleep-service
interface SleepSessionData {
  id: string;
  userId: string;
  sleepTime: string;
  wakeTime: string;
  durationMinutes: number;
  sleepDate: string;
  createdAt: string;
  updatedAt: string;
}

// Интерфейс для данных о расписании тренировок из activity-service
interface WorkoutScheduleData {
  id: string;
  userId: string;
  dayOfWeek: number;
  muscleGroupId?: string;
  isFullBody: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

@Injectable()
export class ProfileService {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
    private readonly httpService: HttpService,
  ) {}

  // Инициализация профиля с userId
  async initializeProfile(userId: string): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = this.profileRepository.create({ userId });
      await this.profileRepository.save(profile);
    }
    return profile;
  }

  // Получение профиля пользователя
  async getProfile(userId: string): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      // Автоматически инициализируем профиль, если его нет
      profile = await this.initializeProfile(userId);
    }
    return profile;
  }

  // Батчевое обновление профиля
  async updateProfileBatch(userId: string, updates: Record<string, any>): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }

    // Применяем все обновления
    if (updates.name !== undefined) {
      profile.name = updates.name;
    }
    if (updates.birthDate !== undefined) {
      profile.birthDate = new Date(updates.birthDate);
    }
    if (updates.gender !== undefined) {
      profile.gender = updates.gender;
    }
    if (updates.height !== undefined) {
      profile.height = updates.height;
    }
    if (updates.weight !== undefined) {
      profile.weight = updates.weight;
    }
    if (updates.goal !== undefined) {
      profile.goal = updates.goal;
    }
    if (updates.activityLevel !== undefined) {
      profile.activityLevel = updates.activityLevel;
    }

    // Сохраняем профиль - это автоматически пересчитает все вычисляемые поля
    return await this.profileRepository.save(profile);
  }

  // Обновление имени пользователя
  async updateName(userId: string, updateNameDto: UpdateNameDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.name = updateNameDto.name;
    return await this.profileRepository.save(profile);
  }

  // Обновление даты рождения пользователя
  async updateBirthDate(userId: string, updateBirthDateDto: UpdateBirthDateDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.birthDate = updateBirthDateDto.birthDate;
    // Сохраняем профиль - это автоматически пересчитает age, BMR и TDEE через триггер
    return await this.profileRepository.save(profile);
  }

  // Обновление роста пользователя
  async updateHeight(userId: string, updateHeightDto: UpdateHeightDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.height = updateHeightDto.height;
    // Сохраняем профиль - это автоматически пересчитает BMI, BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление веса пользователя
  async updateWeight(userId: string, updateWeightDto: UpdateWeightDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.weight = updateWeightDto.weight;
    // Сохраняем профиль - это автоматически пересчитает BMI, BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление цели пользователя
  async updateGoal(userId: string, updateGoalDto: UpdateGoalDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.goal = updateGoalDto.goal;
    return await this.profileRepository.save(profile);
  }

  // Обновление пола пользователя
  async updateGender(userId: string, updateGenderDto: UpdateGenderDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.gender = updateGenderDto.gender;
    // Сохраняем профиль - это автоматически пересчитает BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление уровня активности пользователя
  async updateActivityLevel(userId: string, updateActivityLevelDto: UpdateActivityLevelDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.activityLevel = updateActivityLevelDto.activityLevel;
    // Сохраняем профиль - это автоматически пересчитает TDEE
    return await this.profileRepository.save(profile);
  }

  // Проверка заполненности профиля
  async isProfileComplete(userId: string): Promise<boolean> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    return profile.isComplete();
  }

  // Принудительный пересчет рекомендуемой продолжительности сна
  async recalculateRecommendedSleepDuration(userId: string): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      throw new NotFoundException('Профиль не найден');
    }

    // Пересчитываем recommendedSleepDuration принудительно
    const newSleepDuration = profile.calculateRecommendedSleepDuration();
    profile.recommendedSleepDuration = newSleepDuration;

    // Сохраняем обновленный профиль
    await this.profileRepository.save(profile);
    
    return profile;
  }

  // Расчёт коэффициента качества сна за последние 2 недели
  async calculateSleepQualityCoefficient(userId: string): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      throw new NotFoundException('Профиль не найден');
    }

    // Проверяем, что у пользователя есть норма сна
    if (!profile.recommendedSleepDuration) {
      this.logger.warn(`У пользователя ${userId} не установлена норма сна, устанавливаем коэффициент = 1`);
      profile.sleepQualityCoefficient = 1.0;
      await this.profileRepository.save(profile);
      return profile;
    }

    try {
      // Получаем данные о сне за последние 2 недели
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(endDate.getDate() - 14); // 2 недели назад

      const startDateStr = startDate.toISOString().split('T')[0];
      const endDateStr = endDate.toISOString().split('T')[0];

      // Запрос к sleep-service для получения данных о сне
      const sleepServiceUrl = `${servicesConfig.sleepService.baseUrl}/sleep/sessions/range`;
      this.logger.log(`Отправляем запрос к sleep-service: ${sleepServiceUrl}`);
      this.logger.log(`Параметры: userId=${userId}, startDate=${startDateStr}, endDate=${endDateStr}`);
      
      const response = await firstValueFrom(
        this.httpService.get<SleepSessionData[]>(sleepServiceUrl, {
          params: {
            userId,
            startDate: startDateStr,
            endDate: endDateStr,
          },
          headers: {
            'user-id': userId,
          },
        })
      );

      const sleepSessions: SleepSessionData[] = response.data;
      
      if (!sleepSessions || sleepSessions.length === 0) {
        this.logger.warn(`У пользователя ${userId} нет данных о сне за последние 2 недели, устанавливаем коэффициент = 1`);
        profile.sleepQualityCoefficient = 1.0;
        await this.profileRepository.save(profile);
        return profile;
      }

      // Группируем сессии сна по дням и суммируем продолжительность для каждого дня
      const dailySleepMap = new Map<string, number>();
      
      sleepSessions.forEach((session: SleepSessionData) => {
        const sleepDate = session.sleepDate;
        const durationHours = session.durationMinutes / 60;
        
        if (dailySleepMap.has(sleepDate)) {
          dailySleepMap.set(sleepDate, dailySleepMap.get(sleepDate)! + durationHours);
        } else {
          dailySleepMap.set(sleepDate, durationHours);
        }
      });

      // Рассчитываем коэффициенты качества сна для каждого дня
      const qualityCoefficients: number[] = [];
      
      dailySleepMap.forEach((actualSleepHours, date) => {
        const qualityRatio = actualSleepHours / profile.recommendedSleepDuration!;
        qualityCoefficients.push(qualityRatio);
        this.logger.debug(`Дата: ${date}, Факт: ${actualSleepHours.toFixed(2)}ч, Норма: ${profile.recommendedSleepDuration}ч, Коэффициент: ${qualityRatio.toFixed(3)}`);
      });

      // Рассчитываем средний коэффициент качества сна
      const averageQualityCoefficient = qualityCoefficients.reduce((sum, coeff) => sum + coeff, 0) / qualityCoefficients.length;
      
      // Округляем до 3 знаков после запятой
      profile.sleepQualityCoefficient = Number(averageQualityCoefficient.toFixed(3));
      
      this.logger.log(`Коэффициент качества сна для пользователя ${userId}: ${profile.sleepQualityCoefficient} (на основе ${qualityCoefficients.length} дней)`);

      // Сохраняем обновленный профиль
      await this.profileRepository.save(profile);
      
      return profile;

    } catch (error) {
      this.logger.error(`Ошибка при расчёте коэффициента качества сна для пользователя ${userId}:`, error);
      
      // В случае ошибки устанавливаем коэффициент = 1 (считаем, что пользователь не отслеживает сон)
      profile.sleepQualityCoefficient = 1.0;
      await this.profileRepository.save(profile);
      
      throw new NotFoundException('Не удалось получить данные о сне из sleep-service');
    }
  }

  // Получение количества активных дней тренировок из activity-service
  private async getActiveTrainingDaysCount(userId: string): Promise<number> {
    try {
      // Запрос к activity-service для получения расписания тренировок
      const activityServiceUrl = `${servicesConfig.activityService.baseUrl}/workout-schedule/user/${userId}`;
      this.logger.log(`Отправляем запрос к activity-service: ${activityServiceUrl}`);
      
      const response = await firstValueFrom(
        this.httpService.get<WorkoutScheduleData[]>(activityServiceUrl, {
          headers: {
            'user-id': userId,
          },
        })
      );

      const workoutSchedules: WorkoutScheduleData[] = response.data;
      
      if (!workoutSchedules || workoutSchedules.length === 0) {
        this.logger.warn(`У пользователя ${userId} нет расписания тренировок, используем значение по умолчанию: 3 дня`);
        return 3; // Значение по умолчанию
      }

      // Считаем количество активных дней тренировок
      const activeDays = workoutSchedules.filter(schedule => schedule.isActive).length;
      
      this.logger.log(`У пользователя ${userId} активных дней тренировок: ${activeDays}`);
      
      return activeDays > 0 ? activeDays : 3; // Минимум 3 дня, если нет активных дней

    } catch (error) {
      this.logger.error(`Ошибка при получении расписания тренировок для пользователя ${userId}:`, error);
      
      // В случае ошибки возвращаем значение по умолчанию
      return 3;
    }
  }

  // Расчёт и обновление норм тренировок
  async calculateTrainingNorms(userId: string): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      throw new NotFoundException('Профиль не найден');
    }

    // Получаем количество активных дней тренировок
    const trainingDaysPerWeek = await this.getActiveTrainingDaysCount(userId);

    // Рассчитываем недельную норму (уже рассчитывается автоматически в хуке)
    const weeklyMinutes = profile.calculateOptimalWeeklyTrainingMinutes();
    
    // Рассчитываем дневную норму
    const dailyMinutes = profile.calculateOptimalDailyTrainingMinutes(trainingDaysPerWeek);

    // Обновляем поля в профиле
    profile.optimalWeeklyTrainingMinutes = weeklyMinutes;
    profile.optimalDailyTrainingMinutes = dailyMinutes;

    // Сохраняем обновленный профиль
    await this.profileRepository.save(profile);
    
    this.logger.log(`Обновлены нормы тренировок для пользователя ${userId}: недельная=${weeklyMinutes}мин, дневная=${dailyMinutes}мин (${trainingDaysPerWeek} дней в неделю)`);
    
    return profile;
  }

  // Принудительный пересчет всех норм тренировок
  async recalculateTrainingNorms(userId: string): Promise<Profile> {
    // Сначала пересчитываем коэффициент качества сна (если нужно)
    let profile = await this.calculateSleepQualityCoefficient(userId);
    
    // Затем пересчитываем нормы тренировок
    profile = await this.calculateTrainingNorms(userId);
    
    return profile;
  }
} 