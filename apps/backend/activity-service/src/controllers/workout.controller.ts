import { Controller, Get, Post, Body, Param, Query, Put, Delete, Headers, HttpCode, HttpStatus } from '@nestjs/common';
import { WorkoutService } from '../services/workout.service';
import { CreateWorkoutDto } from '../dto/create-workout.dto';
import { UpdateWorkoutDto } from '../dto/update-workout.dto';

@Controller('workouts')
export class WorkoutController {
  constructor(private readonly workoutService: WorkoutService) {}

  /**
   * Создание новой тренировки
   */
  @Post()
  async create(
    @Headers('user-id') userId: string,
    @Body() createWorkoutDto: CreateWorkoutDto,
  ) {
    return this.workoutService.create(userId, createWorkoutDto);
  }

  /**
   * Получение всех тренировок пользователя
   */
  @Get()
  async findAll(
    @Headers('user-id') userId: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.workoutService.findAllByUserId(
      userId,
      limit ? parseInt(limit) : 20,
      offset ? parseInt(offset) : 0,
      startDate,
      endDate,
    );
  }

  /**
   * Получение тренировок за конкретный день
   */
  @Get('by-date')
  async findByDate(
    @Headers('user-id') userId: string,
    @Query('date') date: string,
  ) {
    return this.workoutService.findByDate(userId, date);
  }

  /**
   * Получение статистики тренировок пользователя
   */
  @Get('statistics')
  async getStatistics(
    @Headers('user-id') userId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.workoutService.getStatistics(userId, startDate, endDate);
  }

  /**
   * Получение тренировки по ID
   */
  @Get(':id')
  async findOne(
    @Param('id') id: string,
    @Headers('user-id') userId: string,
  ) {
    return this.workoutService.findOne(id, userId);
  }

  /**
   * Обновление тренировки
   */
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Headers('user-id') userId: string,
    @Body() updateWorkoutDto: UpdateWorkoutDto,
  ) {
    return this.workoutService.update(id, userId, updateWorkoutDto);
  }

  /**
   * Удаление тренировки
   */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(
    @Param('id') id: string,
    @Headers('user-id') userId: string,
  ) {
    return this.workoutService.delete(id, userId);
  }
}
