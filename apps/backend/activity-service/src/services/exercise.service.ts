import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { Exercise } from '../entities/exercise.entity';
import { CreateExerciseDto } from '../dto/create-exercise.dto';

@Injectable()
export class ExerciseService {
  constructor(
    @InjectRepository(Exercise)
    private exerciseRepository: Repository<Exercise>,
  ) {}

  /**
   * Создание нового упражнения в базе данных упражнений
   */
  async create(createExerciseDto: CreateExerciseDto): Promise<Exercise> {
    const exercise = this.exerciseRepository.create(createExerciseDto);
    return this.exerciseRepository.save(exercise);
  }

  /**
   * Получение всех упражнений с возможностью поиска и фильтрации
   */
  async findAll(
    limit: number = 50,
    offset: number = 0,
    search?: string,
    muscleGroup?: string,
  ): Promise<{ exercises: Exercise[]; total: number }> {
    const where: any = {};
    
    // Добавляем поиск по названию, если задан
    if (search) {
      where.name = Like(`%${search}%`);
    }

    // Фильтр по группе мышц
    if (muscleGroup) {
      where.targetMuscleGroup = muscleGroup;
    }

    const [exercises, total] = await this.exerciseRepository.findAndCount({
      where,
      order: { name: 'ASC' },
      take: limit,
      skip: offset,
    });

    return { exercises, total };
  }

  /**
   * Получение упражнения по ID
   */
  async findOne(id: string): Promise<Exercise> {
    return this.exerciseRepository.findOne({
      where: { id },
    });
  }

  /**
   * Получение всех уникальных групп мышц
   */
  async getMuscleGroups(): Promise<string[]> {
    const result = await this.exerciseRepository
      .createQueryBuilder('exercise')
      .select('DISTINCT exercise.targetMuscleGroup', 'muscleGroup')
      .getRawMany();
    
    return result.map(item => item.muscleGroup);
  }

  /**
   * Обновление упражнения
   */
  async update(id: string, updateData: Partial<CreateExerciseDto>): Promise<Exercise> {
    const exercise = await this.findOne(id);
    if (!exercise) {
      return null;
    }

    Object.assign(exercise, updateData);
    return this.exerciseRepository.save(exercise);
  }

  /**
   * Удаление упражнения
   */
  async delete(id: string): Promise<void> {
    await this.exerciseRepository.delete({ id });
  }
}
