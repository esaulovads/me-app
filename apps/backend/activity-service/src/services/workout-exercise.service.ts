import { Injectable, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WorkoutExercise } from '../entities/workout-exercise.entity';
import { CreateWorkoutExerciseDto } from '../dto/create-workout-exercise.dto';
import { WorkoutService } from './workout.service';

@Injectable()
export class WorkoutExerciseService {
  constructor(
    @InjectRepository(WorkoutExercise)
    private workoutExerciseRepository: Repository<WorkoutExercise>,
    @Inject(forwardRef(() => WorkoutService))
    private workoutService: WorkoutService,
  ) {}

  /**
   * Добавление упражнения в тренировку
   */
  async create(createWorkoutExerciseDto: CreateWorkoutExerciseDto): Promise<WorkoutExercise> {
    const workoutExercise = this.workoutExerciseRepository.create(createWorkoutExerciseDto);
    const savedWorkoutExercise = await this.workoutExerciseRepository.save(workoutExercise);

    // Обновляем целевые группы мышц тренировки
    await this.workoutService.updateTargetMuscleGroups(createWorkoutExerciseDto.workoutId);

    return savedWorkoutExercise;
  }

  /**
   * Получение всех упражнений тренировки
   */
  async findByWorkoutId(workoutId: string): Promise<WorkoutExercise[]> {
    return this.workoutExerciseRepository.find({
      where: { workoutId },
      relations: ['exercise', 'sets'],
      order: { createdAt: 'ASC' },
    });
  }

  /**
   * Получение упражнения в тренировке по ID
   */
  async findOne(id: string): Promise<WorkoutExercise> {
    return this.workoutExerciseRepository.findOne({
      where: { id },
      relations: ['exercise', 'sets', 'workout'],
    });
  }

  /**
   * Пересчет общего веса упражнения в тренировке
   */
  async recalculateTotalWeight(workoutExerciseId: string): Promise<void> {
    const workoutExercise = await this.workoutExerciseRepository.findOne({
      where: { id: workoutExerciseId },
      relations: ['sets', 'exercise'],
    });

    if (!workoutExercise) {
      return;
    }

    // Рассчитываем общий вес: сумма (повторения * вес * количество снарядов) для всех подходов
    const totalWeight = workoutExercise.sets.reduce((sum, set) => {
      const setWeight = set.reps * Number(set.weight) * workoutExercise.exercise.equipmentCount;
      return sum + setWeight;
    }, 0);

    workoutExercise.totalWeight = totalWeight;
    await this.workoutExerciseRepository.save(workoutExercise);

    // Пересчитываем общий вес тренировки
    await this.workoutService.recalculateTotalWeight(workoutExercise.workoutId);
  }

  /**
   * Удаление упражнения из тренировки
   */
  async delete(id: string): Promise<void> {
    const workoutExercise = await this.workoutExerciseRepository.findOne({
      where: { id },
    });

    if (workoutExercise) {
      const workoutId = workoutExercise.workoutId;
      await this.workoutExerciseRepository.delete({ id });
      
      // Обновляем целевые группы мышц и общий вес тренировки
      await this.workoutService.updateTargetMuscleGroups(workoutId);
      await this.workoutService.recalculateTotalWeight(workoutId);
    }
  }
}
