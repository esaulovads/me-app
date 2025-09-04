import { Controller, Get, Post, Body, Param, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { WorkoutExerciseService } from '../services/workout-exercise.service';
import { CreateWorkoutExerciseDto } from '../dto/create-workout-exercise.dto';

@Controller('workout-exercises')
export class WorkoutExerciseController {
  constructor(private readonly workoutExerciseService: WorkoutExerciseService) {}

  /**
   * Добавление упражнения в тренировку
   */
  @Post()
  async create(@Body() createWorkoutExerciseDto: CreateWorkoutExerciseDto) {
    return this.workoutExerciseService.create(createWorkoutExerciseDto);
  }

  /**
   * Получение всех упражнений тренировки
   */
  @Get('by-workout/:workoutId')
  async findByWorkoutId(@Param('workoutId') workoutId: string) {
    return this.workoutExerciseService.findByWorkoutId(workoutId);
  }

  /**
   * Получение упражнения в тренировке по ID
   */
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.workoutExerciseService.findOne(id);
  }

  /**
   * Удаление упражнения из тренировки
   */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id') id: string) {
    return this.workoutExerciseService.delete(id);
  }
}
