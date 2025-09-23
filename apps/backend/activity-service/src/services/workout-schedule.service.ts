import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WorkoutSchedule } from '../entities/workout-schedule.entity';
import { CreateWorkoutScheduleDto } from '../dto/create-workout-schedule.dto';
import { UpdateWorkoutScheduleDto } from '../dto/update-workout-schedule.dto';

/**
 * Сервис для работы с расписанием тренировок
 */
@Injectable()
export class WorkoutScheduleService {
  constructor(
    @InjectRepository(WorkoutSchedule)
    private workoutScheduleRepository: Repository<WorkoutSchedule>,
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

    return this.workoutScheduleRepository.save(schedule);
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
}
