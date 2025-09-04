import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Workout } from '../entities/workout.entity';
import { CreateWorkoutDto } from '../dto/create-workout.dto';
import { UpdateWorkoutDto } from '../dto/update-workout.dto';

@Injectable()
export class WorkoutService {
  constructor(
    @InjectRepository(Workout)
    private workoutRepository: Repository<Workout>,
  ) {}

  /**
   * Создание новой тренировки
   */
  async create(userId: string, createWorkoutDto: CreateWorkoutDto): Promise<Workout> {
    const workout = this.workoutRepository.create({
      userId,
      ...createWorkoutDto,
      date: new Date(createWorkoutDto.date),
      targetMuscleGroups: createWorkoutDto.targetMuscleGroups || [],
    });

    return this.workoutRepository.save(workout);
  }

  /**
   * Получение всех тренировок пользователя с возможностью фильтрации по дате
   */
  async findAllByUserId(
    userId: string,
    limit: number = 20,
    offset: number = 0,
    startDate?: string,
    endDate?: string,
  ): Promise<{ workouts: Workout[]; total: number }> {
    const queryBuilder = this.workoutRepository
      .createQueryBuilder('workout')
      .leftJoinAndSelect('workout.exercises', 'workoutExercise')
      .leftJoinAndSelect('workoutExercise.exercise', 'exercise')
      .leftJoinAndSelect('workoutExercise.sets', 'set')
      .where('workout.userId = :userId', { userId });

    // Фильтр по дате
    if (startDate) {
      queryBuilder.andWhere('workout.date >= :startDate', { startDate });
    }
    if (endDate) {
      queryBuilder.andWhere('workout.date <= :endDate', { endDate });
    }

    queryBuilder
      .orderBy('workout.date', 'DESC')
      .addOrderBy('workout.createdAt', 'DESC')
      .take(limit)
      .skip(offset);

    const [workouts, total] = await queryBuilder.getManyAndCount();
    return { workouts, total };
  }

  /**
   * Получение тренировки по ID с полной информацией
   */
  async findOne(id: string, userId: string): Promise<Workout> {
    return this.workoutRepository.findOne({
      where: { id, userId },
      relations: ['exercises', 'exercises.exercise', 'exercises.sets'],
    });
  }

  /**
   * Получение тренировок за конкретный день
   */
  async findByDate(userId: string, date: string): Promise<Workout[]> {
    return this.workoutRepository.find({
      where: { 
        userId, 
        date: new Date(date) 
      },
      relations: ['exercises', 'exercises.exercise', 'exercises.sets'],
      order: { createdAt: 'ASC' },
    });
  }

  /**
   * Обновление тренировки
   */
  async update(id: string, userId: string, updateWorkoutDto: UpdateWorkoutDto): Promise<Workout> {
    const workout = await this.findOne(id, userId);
    if (!workout) {
      return null;
    }

    if (updateWorkoutDto.date) {
      workout.date = new Date(updateWorkoutDto.date);
    }
    if (updateWorkoutDto.duration !== undefined) {
      workout.duration = updateWorkoutDto.duration;
    }
    if (updateWorkoutDto.targetMuscleGroups) {
      workout.targetMuscleGroups = updateWorkoutDto.targetMuscleGroups;
    }

    return this.workoutRepository.save(workout);
  }

  /**
   * Пересчет общего веса тренировки
   */
  async recalculateTotalWeight(workoutId: string): Promise<void> {
    const workout = await this.workoutRepository.findOne({
      where: { id: workoutId },
      relations: ['exercises'],
    });

    if (!workout) {
      return;
    }

    // Суммируем вес всех упражнений в тренировке
    const totalWeight = workout.exercises.reduce((sum, exercise) => {
      return sum + Number(exercise.totalWeight);
    }, 0);

    workout.totalWeight = totalWeight;
    await this.workoutRepository.save(workout);
  }

  /**
   * Обновление целевых групп мышц тренировки на основе упражнений
   */
  async updateTargetMuscleGroups(workoutId: string): Promise<void> {
    const workout = await this.workoutRepository.findOne({
      where: { id: workoutId },
      relations: ['exercises', 'exercises.exercise'],
    });

    if (!workout) {
      return;
    }

    // Собираем уникальные группы мышц из всех упражнений
    const muscleGroups = new Set<string>();
    workout.exercises.forEach(workoutExercise => {
      if (workoutExercise.exercise) {
        muscleGroups.add(workoutExercise.exercise.targetMuscleGroup);
      }
    });

    workout.targetMuscleGroups = Array.from(muscleGroups);
    await this.workoutRepository.save(workout);
  }

  /**
   * Удаление тренировки
   */
  async delete(id: string, userId: string): Promise<void> {
    await this.workoutRepository.delete({ id, userId });
  }

  /**
   * Получение статистики тренировок пользователя
   */
  async getStatistics(userId: string, startDate?: string, endDate?: string): Promise<any> {
    const queryBuilder = this.workoutRepository
      .createQueryBuilder('workout')
      .where('workout.userId = :userId', { userId });

    if (startDate) {
      queryBuilder.andWhere('workout.date >= :startDate', { startDate });
    }
    if (endDate) {
      queryBuilder.andWhere('workout.date <= :endDate', { endDate });
    }

    const workouts = await queryBuilder.getMany();

    const totalWorkouts = workouts.length;
    const totalWeight = workouts.reduce((sum, workout) => sum + Number(workout.totalWeight), 0);
    const totalDuration = workouts.reduce((sum, workout) => sum + workout.duration, 0);

    return {
      totalWorkouts,
      totalWeight,
      totalDuration,
      averageWeight: totalWorkouts > 0 ? totalWeight / totalWorkouts : 0,
      averageDuration: totalWorkouts > 0 ? totalDuration / totalWorkouts : 0,
    };
  }
}
