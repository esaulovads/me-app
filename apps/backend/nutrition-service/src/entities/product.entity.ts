import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  userId: string;

  @Column()
  name: string;

  @Column('decimal', { precision: 10, scale: 2 })
  caloriesPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  proteinsPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  fatsPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  carbsPer100g: number;

  @Column('decimal', { precision: 10, scale: 2 })
  servingWeight: number;

  @Column('decimal', { precision: 10, scale: 2 })
  caloriesPerServing: number;

  @Column('decimal', { precision: 10, scale: 2 })
  proteinsPerServing: number;

  @Column('decimal', { precision: 10, scale: 2 })
  fatsPerServing: number;

  @Column('decimal', { precision: 10, scale: 2 })
  carbsPerServing: number;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  createdAt: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP', onUpdate: 'CURRENT_TIMESTAMP' })
  updatedAt: Date;
} 