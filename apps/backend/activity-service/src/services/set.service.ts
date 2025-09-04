import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Set } from '../entities/set.entity';
import { CreateSetDto } from '../dto/create-set.dto';
import { UpdateSetDto } from '../dto/update-set.dto';
import { WorkoutExerciseService } from './workout-exercise.service';

@Injectable()
export class SetService {
  constructor(
    @InjectRepository(Set)
    private setRepository: Repository<Set>,
    @Inject(forwardRef(() => WorkoutExerciseService))
    private workoutExerciseService: WorkoutExerciseService,
  ) {}

  /**
   * Создание нового подхода
   */
  async create(createSetDto: CreateSetDto): Promise<Set> {
    const set = this.setRepository.create(createSetDto);
    const savedSet = await this.setRepository.save(set);

    // Пересчитываем общий вес упражнения
    await this.workoutExerciseService.recalculateTotalWeight(createSetDto.workoutExerciseId);

    return savedSet;
  }

  /**
   * Получение всех подходов упражнения в тренировке
   */
  async findByWorkoutExerciseId(workoutExerciseId: string): Promise<Set[]> {
    return this.setRepository.find({
      where: { workoutExerciseId },
      order: { createdAt: 'ASC' },
    });
  }

  /**
   * Получение подхода по ID
   */
  async findOne(id: string): Promise<Set> {
    return this.setRepository.findOne({
      where: { id },
      relations: ['workoutExercise'],
    });
  }

  /**
   * Обновление подхода
   */
  async update(id: string, updateSetDto: UpdateSetDto): Promise<Set> {
    const set = await this.findOne(id);
    if (!set) {
      return null;
    }

    Object.assign(set, updateSetDto);
    const updatedSet = await this.setRepository.save(set);

    // Пересчитываем общий вес упражнения
    await this.workoutExerciseService.recalculateTotalWeight(set.workoutExerciseId);

    return updatedSet;
  }

  /**
   * Удаление подхода
   */
  async delete(id: string): Promise<void> {
    const set = await this.setRepository.findOne({
      where: { id },
    });

    if (set) {
      const workoutExerciseId = set.workoutExerciseId;
      await this.setRepository.delete({ id });
      
      // Пересчитываем общий вес упражнения
      await this.workoutExerciseService.recalculateTotalWeight(workoutExerciseId);
    }
  }

  /**
   * Массовое создание подходов для упражнения
   */
  async createMultiple(workoutExerciseId: string, setsData: Omit<CreateSetDto, 'workoutExerciseId'>[]): Promise<Set[]> {
    const sets = setsData.map(setData => 
      this.setRepository.create({
        ...setData,
        workoutExerciseId,
      })
    );

    const savedSets = await this.setRepository.save(sets);

    // Пересчитываем общий вес упражнения
    await this.workoutExerciseService.recalculateTotalWeight(workoutExerciseId);

    return savedSets;
  }
}
