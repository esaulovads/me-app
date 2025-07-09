import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Meal } from './meal.entity';
import { Product } from './product.entity';
import { Dish } from './dish.entity';

export enum MealItemType {
  PRODUCT = 'PRODUCT',
  DISH = 'DISH',
}

@Entity('meal_items')
export class MealItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Meal, meal => meal.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'mealId' })
  meal: Meal;

  @Column()
  mealId: string;

  @Column({
    type: 'enum',
    enum: MealItemType,
  })
  type: MealItemType;

  @ManyToOne(() => Product, { nullable: true })
  @JoinColumn({ name: 'productId' })
  product?: Product;

  @Column({ nullable: true })
  productId?: string;

  @ManyToOne(() => Dish, { nullable: true })
  @JoinColumn({ name: 'dishId' })
  dish?: Dish;

  @Column({ nullable: true })
  dishId?: string;

  @Column('decimal', { precision: 10, scale: 2 })
  weight: number;

  @Column('decimal', { precision: 10, scale: 2 })
  calories: number;

  @Column('decimal', { precision: 10, scale: 2 })
  proteins: number;

  @Column('decimal', { precision: 10, scale: 2 })
  fats: number;

  @Column('decimal', { precision: 10, scale: 2 })
  carbs: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
} 