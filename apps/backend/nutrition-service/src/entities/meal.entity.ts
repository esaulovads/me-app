import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { MealItem } from './meal-item.entity';

@Entity('meals')
export class Meal {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column({ type: 'timestamp' })
  time: Date;

  @Column('decimal', { 
    precision: 10, 
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value) || 0,
    }
  })
  totalCalories: number;

  @Column('decimal', { 
    precision: 10, 
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value) || 0,
    }
  })
  totalProteins: number;

  @Column('decimal', { 
    precision: 10, 
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value) || 0,
    }
  })
  totalFats: number;

  @Column('decimal', { 
    precision: 10, 
    scale: 2,
    transformer: {
      to: (value: number) => value,
      from: (value: string) => parseFloat(value) || 0,
    }
  })
  totalCarbs: number;

  @OneToMany(() => MealItem, item => item.meal, { cascade: true })
  items: MealItem[];

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
} 