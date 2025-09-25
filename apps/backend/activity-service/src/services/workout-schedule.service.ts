import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { WorkoutSchedule } from '../entities/workout-schedule.entity';
import { CreateWorkoutScheduleDto } from '../dto/create-workout-schedule.dto';
import { UpdateWorkoutScheduleDto } from '../dto/update-workout-schedule.dto';
import { servicesConfig } from '../config/services.config';

/**
 * Сервис для работы с расписанием тренировок
 */
@Injectable()
export class WorkoutScheduleService {
  private readonly logger = new Logger(WorkoutScheduleService.name);

  constructor(
    @InjectRepository(WorkoutSchedule)
    private workoutScheduleRepository: Repository<WorkoutSchedule>,
    private readonly httpService: HttpService,
  ) {}

  /**
   * Получить расписание пользователя на всю неделю
   */
  async getUserSchedule(userId: string): Promise<WorkoutSchedule[]> {
    return this.workoutScheduleRepository.find({
      where: { userId },
      relations: ['muscleGroup'],
      order: { dayOfWeek: 'ASC' }
    });
  }

  /**
   * Получить расписание на конкретный день недели
   */
  async getScheduleForDay(userId: string, dayOfWeek: number): Promise<WorkoutSchedule | null> {
    return this.workoutScheduleRepository.findOne({
      where: { userId, dayOfWeek },
      relations: ['muscleGroup']
    });
  }

  /**
   * Создать или обновить расписание для дня
   */
  async createOrUpdateSchedule(
    userId: string, 
    dayOfWeek: number, 
    updateDto: UpdateWorkoutScheduleDto
  ): Promise<WorkoutSchedule> {
    // Ищем существующую запись
    let schedule = await this.workoutScheduleRepository.findOne({
      where: { userId, dayOfWeek }
    });

    if (schedule) {
      // Обновляем существующую запись
      Object.assign(schedule, updateDto);
    } else {
      // Создаем новую запись
      schedule = this.workoutScheduleRepository.create({
        userId,
        dayOfWeek,
        ...updateDto
      });
    }

    const savedSchedule = await this.workoutScheduleRepository.save(schedule);
    
    // Уведомляем profile-service о изменении расписания для пересчёта норм тренировок
    await this.notifyProfileServiceAboutScheduleChange(userId);
    
    return savedSchedule;
  }

  /**
   * Удалить расписание для дня (сделать день отдыха)
   */
  async removeScheduleForDay(userId: string, dayOfWeek: number): Promise<void> {
    const schedule = await this.workoutScheduleRepository.findOne({
      where: { userId, dayOfWeek }
    });

    if (schedule) {
      schedule.isActive = false;
      schedule.muscleGroupId = null;
      schedule.isFullBody = false;
      await this.workoutScheduleRepository.save(schedule);
      
      // Уведомляем profile-service о изменении расписания для пересчёта норм тренировок
      await this.notifyProfileServiceAboutScheduleChange(userId);
    }
  }

  /**
   * Получить тренировку на сегодня
   */
  async getTodayWorkout(userId: string): Promise<WorkoutSchedule | null> {
    const today = new Date().getDay(); // 0 = воскресенье, 1 = понедельник и т.д.
    
    return this.workoutScheduleRepository.findOne({
      where: { 
        userId, 
        dayOfWeek: today, 
        isActive: true 
      },
      relations: ['muscleGroup']
    });
  }

  /**
   * Уведомляет profile-service об изменении расписания тренировок для пересчёта норм
   */
  private async notifyProfileServiceAboutScheduleChange(userId: string): Promise<void> {
    try {
      const url = `${servicesConfig.profileService.baseUrl}/profiles/recalculate-training-norms`;
      
      await firstValueFrom(
        this.httpService.post(url, {}, {
          headers: {
            'user-id': userId,
            'Content-Type': 'application/json',
          },
          timeout: 5000, // 5 секунд таймаут
        })
      );
      
      this.logger.log(`Нормы тренировок пересчитаны для пользователя ${userId}`);
    } catch (error) {
      this.logger.error(`Ошибка при пересчёте норм тренировок для пользователя ${userId}:`, error.message);
      // Не прерываем выполнение основной операции, если пересчёт норм не удался
    }
  }
}
