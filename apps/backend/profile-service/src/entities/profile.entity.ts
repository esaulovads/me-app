import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

// Enum для целей пользователя
export enum UserGoal {
  GAIN_WEIGHT = 'GAIN_WEIGHT',
  MAINTAIN_WEIGHT = 'MAINTAIN_WEIGHT',
  LOSE_WEIGHT = 'LOSE_WEIGHT',
}

@Entity('profiles')
export class Profile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // ID пользователя из сервиса аутентификации
  @Column({ unique: true })
  userId: string;

  @Column({ nullable: true })
  name: string;

  @Column('int', { nullable: true })
  age: number;

  @Column('float', { nullable: true })
  height: number;

  @Column('float', { nullable: true })
  weight: number;

  @Column({
    type: 'enum',
    enum: UserGoal,
    nullable: true
  })
  goal: UserGoal;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Метод для проверки заполненности профиля
  isComplete(): boolean {
    return !!(this.name && this.age && this.height && this.weight && this.goal);
  }
} 