import { Entity, Column, PrimaryGeneratedColumn, OneToMany } from 'typeorm';
import { DishIngredient } from './dish-ingredient.entity';

@Entity('dishes')
export class Dish {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  name: string;

  @Column('decimal', { precision: 10, scale: 2 })
  totalWeight: number;

  @Column('decimal', { precision: 10, scale: 2 })
  caloriesPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  proteinsPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  fatsPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  carbsPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  totalCalories: number;

  @Column('decimal', { precision: 10, scale: 2 })
  totalProteins: number;

  @Column('decimal', { precision: 10, scale: 2 })
  totalFats: number;

  @Column('decimal', { precision: 10, scale: 2 })
  totalCarbs: number;

  @OneToMany(() => DishIngredient, ingredient => ingredient.dish, { cascade: true })
  ingredients: DishIngredient[];

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
} 