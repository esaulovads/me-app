import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

/**
 * Сущность группы мышц
 */
@Entity('muscle_groups')
export class MuscleGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  name: string; // Название группы мышц (например, "Ноги", "Спина")

  @Column({ nullable: true })
  description?: string; // Описание группы мышц

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
}
