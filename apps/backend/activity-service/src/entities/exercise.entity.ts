import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { WorkoutExercise } from './workout-exercise.entity';

/**
 * Сущность упражнения из базы данных упражнений
 */
@Entity('exercises')
export class Exercise {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string; // Название упражнения

  @Column()
  targetMuscleGroup: string; // Целевая группа мышц

  @Column('int')
  equipmentCount: number; // Количество снарядов для выполнения упражнения

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Связь с упражнениями в тренировках
  @OneToMany(() => WorkoutExercise, workoutExercise => workoutExercise.exercise)
  workoutExercises: WorkoutExercise[];
}
