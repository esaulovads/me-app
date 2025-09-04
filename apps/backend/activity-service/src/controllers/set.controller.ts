import { Controller, Get, Post, Body, Param, Put, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { SetService } from '../services/set.service';
import { CreateSetDto } from '../dto/create-set.dto';
import { UpdateSetDto } from '../dto/update-set.dto';

@Controller('sets')
export class SetController {
  constructor(private readonly setService: SetService) {}

  /**
   * Создание нового подхода
   */
  @Post()
  async create(@Body() createSetDto: CreateSetDto) {
    return this.setService.create(createSetDto);
  }

  /**
   * Массовое создание подходов для упражнения
   */
  @Post('bulk/:workoutExerciseId')
  async createMultiple(
    @Param('workoutExerciseId') workoutExerciseId: string,
    @Body() setsData: Omit<CreateSetDto, 'workoutExerciseId'>[],
  ) {
    return this.setService.createMultiple(workoutExerciseId, setsData);
  }

  /**
   * Получение всех подходов упражнения в тренировке
   */
  @Get('by-workout-exercise/:workoutExerciseId')
  async findByWorkoutExerciseId(@Param('workoutExerciseId') workoutExerciseId: string) {
    return this.setService.findByWorkoutExerciseId(workoutExerciseId);
  }

  /**
   * Получение подхода по ID
   */
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.setService.findOne(id);
  }

  /**
   * Обновление подхода
   */
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateSetDto: UpdateSetDto,
  ) {
    return this.setService.update(id, updateSetDto);
  }

  /**
   * Удаление подхода
   */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id') id: string) {
    return this.setService.delete(id);
  }
}
