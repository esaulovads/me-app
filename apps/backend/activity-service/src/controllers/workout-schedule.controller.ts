import { Controller, Get, Post, Put, Delete, Param, Body, Query } from '@nestjs/common';
import { WorkoutScheduleService } from '../services/workout-schedule.service';
import { UpdateWorkoutScheduleDto } from '../dto/update-workout-schedule.dto';
import { WorkoutSchedule } from '../entities/workout-schedule.entity';

/**
 * Контроллер для работы с расписанием тренировок
 */
@Controller('workout-schedule')
export class WorkoutScheduleController {
  constructor(private readonly workoutScheduleService: WorkoutScheduleService) {}

  /**
   * Получить расписание пользователя на всю неделю
   */
  @Get('user/:userId')
  async getUserSchedule(@Param('userId') userId: string): Promise<WorkoutSchedule[]> {
    return this.workoutScheduleService.getUserSchedule(userId);
  }

  /**
   * Получить расписание на конкретный день недели
   */
  @Get('user/:userId/day/:dayOfWeek')
  async getScheduleForDay(
    @Param('userId') userId: string,
    @Param('dayOfWeek') dayOfWeek: number
  ): Promise<WorkoutSchedule | null> {
    return this.workoutScheduleService.getScheduleForDay(userId, dayOfWeek);
  }

  /**
   * Получить тренировку на сегодня
   */
  @Get('user/:userId/today')
  async getTodayWorkout(@Param('userId') userId: string): Promise<WorkoutSchedule | null> {
    return this.workoutScheduleService.getTodayWorkout(userId);
  }

  /**
   * Создать или обновить расписание для дня
   */
  @Put('user/:userId/day/:dayOfWeek')
  async createOrUpdateSchedule(
    @Param('userId') userId: string,
    @Param('dayOfWeek') dayOfWeek: number,
    @Body() updateDto: UpdateWorkoutScheduleDto
  ): Promise<WorkoutSchedule> {
    return this.workoutScheduleService.createOrUpdateSchedule(userId, dayOfWeek, updateDto);
  }

  /**
   * Удалить расписание для дня (сделать день отдыха)
   */
  @Delete('user/:userId/day/:dayOfWeek')
  async removeScheduleForDay(
    @Param('userId') userId: string,
    @Param('dayOfWeek') dayOfWeek: number
  ): Promise<{ message: string }> {
    await this.workoutScheduleService.removeScheduleForDay(userId, dayOfWeek);
    return { message: 'Расписание удалено' };
  }
}
