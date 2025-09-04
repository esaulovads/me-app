import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { Workout } from './workout.entity';
import { Exercise } from './exercise.entity';
import { Set } from './set.entity';

/**
 * Сущность упражнения в рамках конкретной тренировки
 */
@Entity('workout_exercises')
export class WorkoutExercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  workoutId: string;

  @Column()
  exerciseId: string;

  @Column('decimal', { precision: 10, scale: 2, default: 0 })
  totalWeight: number; // Общий поднятый вес в этом упражнении

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Связи
  @ManyToOne(() => Workout, workout => workout.exercises, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'workoutId' })
  workout: Workout;

  @ManyToOne(() => Exercise, exercise => exercise.workoutExercises)
  @JoinColumn({ name: 'exerciseId' })
  exercise: Exercise;

  @OneToMany(() => Set, set => set.workoutExercise, { cascade: true })
  sets: Set[];
}
