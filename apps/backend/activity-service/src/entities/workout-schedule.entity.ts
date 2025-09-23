import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { MuscleGroup } from './muscle-group.entity';

/**
 * Сущность расписания тренировок пользователя
 */
@Entity('workout_schedules')
export class WorkoutSchedule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string; // ID пользователя

  @Column('int')
  dayOfWeek: number; // День недели (0 = воскресенье, 1 = понедельник, ..., 6 = суббота)

  @Column({ nullable: true })
  muscleGroupId?: string; // ID группы мышц (null для fullbody или дня отдыха)

  @Column('boolean', { default: false })
  isFullBody: boolean; // Флаг fullbody тренировки

  @Column('boolean', { default: true })
  isActive: boolean; // Активно ли расписание для этого дня

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Связь с группой мышц
  @ManyToOne(() => MuscleGroup, { nullable: true })
  @JoinColumn({ name: 'muscleGroupId' })
  muscleGroup?: MuscleGroup;
}
