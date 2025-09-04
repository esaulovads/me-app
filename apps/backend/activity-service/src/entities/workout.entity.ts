import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { WorkoutExercise } from './workout-exercise.entity';

/**
 * Сущность тренировки пользователя
 */
@Entity('workouts')
export class Workout {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string; // ID пользователя

  @Column({ type: 'date' })
  date: Date; // Дата тренировки

  @Column('int', { default: 0 })
  duration: number; // Продолжительность тренировки в минутах

  @Column('text', { array: true, default: '{}' })
  targetMuscleGroups: string[]; // Целевые группы мышц

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  totalWeight: number; // Общий поднятый вес в тренировке

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Связь с упражнениями в тренировке
  @OneToMany(() => WorkoutExercise, workoutExercise => workoutExercise.workout, { cascade: true })
  exercises: WorkoutExercise[];
}
