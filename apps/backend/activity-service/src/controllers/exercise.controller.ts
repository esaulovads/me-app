import { Controller, Get, Post, Body, Param, Query, Put, Delete, HttpCode, HttpStatus } from '@nestjs/common';
import { ExerciseService } from '../services/exercise.service';
import { CreateExerciseDto } from '../dto/create-exercise.dto';

@Controller('exercises')
export class ExerciseController {
  constructor(private readonly exerciseService: ExerciseService) {}

  /**
   * Создание нового упражнения в базе данных упражнений
   */
  @Post()
  async create(@Body() createExerciseDto: CreateExerciseDto) {
    return this.exerciseService.create(createExerciseDto);
  }

  /**
   * Получение всех упражнений с возможностью поиска и фильтрации
   */
  @Get()
  async findAll(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('search') search?: string,
    @Query('muscleGroup') muscleGroup?: string,
  ) {
    return this.exerciseService.findAll(
      limit ? parseInt(limit) : 50,
      offset ? parseInt(offset) : 0,
      search,
      muscleGroup,
    );
  }

  /**
   * Получение всех уникальных групп мышц
   */
  @Get('muscle-groups')
  async getMuscleGroups() {
    return this.exerciseService.getMuscleGroups();
  }

  /**
   * Получение упражнения по ID
   */
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.exerciseService.findOne(id);
  }

  /**
   * Обновление упражнения
   */
  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: Partial<CreateExerciseDto>,
  ) {
    return this.exerciseService.update(id, updateData);
  }

  /**
   * Удаление упражнения
   */
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id') id: string) {
    return this.exerciseService.delete(id);
  }
}
