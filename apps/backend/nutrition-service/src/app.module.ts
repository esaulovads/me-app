import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { Product } from './entities/product.entity';
import { Dish } from './entities/dish.entity';
import { DishIngredient } from './entities/dish-ingredient.entity';
import { Meal } from './entities/meal.entity';
import { MealItem } from './entities/meal-item.entity';
import { ProductController } from './controllers/product.controller';
import { DishController } from './controllers/dish.controller';
import { MealController } from './controllers/meal.controller';
import { ProductService } from './services/product.service';
import { DishService } from './services/dish.service';
import { MealService } from './services/meal.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync(typeOrmConfig),
    TypeOrmModule.forFeature([Product, Dish, DishIngredient, Meal, MealItem]),
  ],
  controllers: [ProductController, DishController, MealController],
  providers: [ProductService, DishService, MealService],
})
export class AppModule {} 