import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { WorkoutExercise } from './workout-exercise.entity';

/**
 * Сущность подхода в упражнении
 */
@Entity('sets')
export class Set {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  workoutExerciseId: string;

  @Column('int')
  reps: number; // Количество повторений

  @Column('decimal', { precision: 10, scale: 2 })
  weight: number; // Вес снаряда

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Связь с упражнением в тренировке
  @ManyToOne(() => WorkoutExercise, workoutExercise => workoutExercise.sets, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'workoutExerciseId' })
  workoutExercise: WorkoutExercise;
}
