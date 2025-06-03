import { Entity, Column, PrimaryGeneratedColumn, BeforeInsert, BeforeUpdate } from 'typeorm';

// Enum для целей пользователя
export enum UserGoal {
  GAIN_WEIGHT = 'GAIN_WEIGHT',
  MAINTAIN_WEIGHT = 'MAINTAIN_WEIGHT',
  LOSE_WEIGHT = 'LOSE_WEIGHT',
}

// Enum для пола пользователя
export enum Gender {
  MALE = 'MALE',
  FEMALE = 'FEMALE',
  NOT_SPECIFIED = 'NOT_SPECIFIED',
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

  @Column({
    type: 'enum',
    enum: Gender,
    default: Gender.NOT_SPECIFIED
  })
  gender: Gender;

  @Column('float', { nullable: true })
  bmi: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  updatedAt: Date;

  // Метод для проверки заполненности профиля
  isComplete(): boolean {
    return !!(this.name && this.age && this.height && this.weight && this.goal);
  }

  // Метод для расчета ИМТ
  calculateBMI(): number | null {
    if (!this.height || !this.weight) {
      return null;
    }
    // Переводим рост из см в метры
    const heightInMeters = this.height / 100;
    return Number((this.weight / (heightInMeters * heightInMeters)).toFixed(2));
  }

  // Автоматический расчет ИМТ перед сохранением или обновлением
  @BeforeInsert()
  @BeforeUpdate()
  updateBMI() {
    this.bmi = this.calculateBMI();
  }
} 