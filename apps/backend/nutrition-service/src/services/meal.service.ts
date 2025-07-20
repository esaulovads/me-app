import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Meal } from '../entities/meal.entity';
import { MealItem } from '../entities/meal-item.entity';
import { Product } from '../entities/product.entity';
import { Dish } from '../entities/dish.entity';
import { CreateMealDto } from '../dto/create-meal.dto';
import { UpdateMealDto } from '../dto/update-meal.dto';
import { MealItemType } from '../entities/meal-item.entity';

@Injectable()
export class MealService {
  constructor(
    @InjectRepository(Meal)
    private mealRepository: Repository<Meal>,
    @InjectRepository(MealItem)
    private mealItemRepository: Repository<MealItem>,
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
    @InjectRepository(Dish)
    private dishRepository: Repository<Dish>,
  ) {}

  async create(userId: string, createMealDto: CreateMealDto): Promise<Meal> {
    // Создаем прием пищи с начальными значениями
    const meal = this.mealRepository.create({
      userId,
      time: new Date(createMealDto.time),
      totalCalories: 0,
      totalProteins: 0,
      totalFats: 0,
      totalCarbs: 0,
    });

    // Сохраняем прием пищи для получения id
    const savedMeal = await this.mealRepository.save(meal);

    // Создаем элементы приема пищи
    const mealItems: MealItem[] = [];
    for (const itemDto of createMealDto.items) {
      let calories = 0;
      let proteins = 0;
      let fats = 0;
      let carbs = 0;

      if (itemDto.type === MealItemType.PRODUCT) {
        const product = await this.productRepository.findOne({
          where: { id: itemDto.id, userId },
        });
        if (!product) {
          throw new NotFoundException(`Product with id ${itemDto.id} not found`);
        }

        calories = (product.caloriesPer100g / 100) * itemDto.weight;
        proteins = (product.proteinsPer100g / 100) * itemDto.weight;
        fats = (product.fatsPer100g / 100) * itemDto.weight;
        carbs = (product.carbsPer100g / 100) * itemDto.weight;

        mealItems.push(
          this.mealItemRepository.create({
            mealId: savedMeal.id,
            type: MealItemType.PRODUCT,
            productId: product.id,
            weight: itemDto.weight,
            calories,
            proteins,
            fats,
            carbs,
          }),
        );
      } else {
        const dish = await this.dishRepository.findOne({
          where: { id: itemDto.id, userId },
        });
        if (!dish) {
          throw new NotFoundException(`Dish with id ${itemDto.id} not found`);
        }

        calories = (dish.caloriesPer100g / 100) * itemDto.weight;
        proteins = (dish.proteinsPer100g / 100) * itemDto.weight;
        fats = (dish.fatsPer100g / 100) * itemDto.weight;
        carbs = (dish.carbsPer100g / 100) * itemDto.weight;

        mealItems.push(
          this.mealItemRepository.create({
            mealId: savedMeal.id,
            type: MealItemType.DISH,
            dishId: dish.id,
            weight: itemDto.weight,
            calories,
            proteins,
            fats,
            carbs,
          }),
        );
      }

      // Добавляем значения к общим
      meal.totalCalories += calories;
      meal.totalProteins += proteins;
      meal.totalFats += fats;
      meal.totalCarbs += carbs;
    }

    // Сохраняем элементы приема пищи
    await this.mealItemRepository.save(mealItems);

    // Обновляем прием пищи с финальными значениями
    return this.mealRepository.save(meal);
  }

  async findAllByUserIdAndDate(userId: string, date: string): Promise<Meal[]> {
    const startDate = new Date(date);
    startDate.setHours(0, 0, 0, 0);

    const endDate = new Date(date);
    endDate.setHours(23, 59, 59, 999);

    return this.mealRepository.find({
      where: {
        userId,
        time: Between(startDate, endDate),
      },
      relations: ['items', 'items.product', 'items.dish'],
      order: { time: 'ASC' },
    });
  }

  async getDailySummary(userId: string, date: string): Promise<{
    totalCalories: number;
    totalProteins: number;
    totalFats: number;
    totalCarbs: number;
  }> {
    const meals = await this.findAllByUserIdAndDate(userId, date);

    return meals.reduce(
      (acc, meal) => ({
        totalCalories: acc.totalCalories + meal.totalCalories,
        totalProteins: acc.totalProteins + meal.totalProteins,
        totalFats: acc.totalFats + meal.totalFats,
        totalCarbs: acc.totalCarbs + meal.totalCarbs,
      }),
      { totalCalories: 0, totalProteins: 0, totalFats: 0, totalCarbs: 0 },
    );
  }

  async update(id: string, userId: string, updateMealDto: UpdateMealDto): Promise<Meal> {
    // Найдем приём пищи для проверки существования и принадлежности пользователю
    const meal = await this.mealRepository.findOne({
      where: { id, userId },
      relations: ['items', 'items.product', 'items.dish'],
    });

    if (!meal) {
      throw new NotFoundException('Meal not found');
    }

    // Обновляем время
    meal.time = new Date(updateMealDto.time);

    // Сохраняем изменения
    return this.mealRepository.save(meal);
  }

  async delete(id: string, userId: string): Promise<void> {
    const result = await this.mealRepository.delete({ id, userId });
    if (result.affected === 0) {
      throw new NotFoundException('Meal not found');
    }
  }

  // Добавление элемента в приём пищи
  async addItemToMeal(
    userId: string,
    mealId: string,
    addItemDto: {
      type: MealItemType;
      id: string;
      weight: number;
    },
  ): Promise<Meal> {
    try {
      // Проверяем, что приём пищи существует и принадлежит пользователю
      const meal = await this.mealRepository.findOne({
        where: { id: mealId, userId },
        relations: ['items'],
      });

      if (!meal) {
        console.error(`Meal not found: mealId=${mealId}, userId=${userId}`);
        throw new NotFoundException('Meal not found');
      }

      console.log(`Adding item to meal: type=${addItemDto.type}, id=${addItemDto.id}, weight=${addItemDto.weight}`);

      let calories = 0;
      let proteins = 0;
      let fats = 0;
      let carbs = 0;
      let productId: string | null = null;
      let dishId: string | null = null;
      let itemName = '';

      // Получаем данные продукта или блюда и рассчитываем КБЖУ
      if (addItemDto.type === MealItemType.PRODUCT) {
        // Сначала ищем продукт пользователя, затем глобальный
        let product = await this.productRepository.findOne({
          where: { id: addItemDto.id, userId },
        });

        // Если не найден продукт пользователя, ищем глобальный (без userId)
        if (!product) {
          product = await this.productRepository.findOne({
            where: { id: addItemDto.id },
          });
        }

        if (!product) {
          throw new NotFoundException('Product not found');
        }

        productId = product.id;
        itemName = product.name;

        // Рассчитываем КБЖУ на основе веса
        const ratio = addItemDto.weight / 100;
        calories = product.caloriesPer100g * ratio;
        proteins = product.proteinsPer100g * ratio;
        fats = product.fatsPer100g * ratio;
        carbs = product.carbsPer100g * ratio;
      } else if (addItemDto.type === MealItemType.DISH) {
        // Сначала ищем блюдо пользователя, затем глобальное
        let dish = await this.dishRepository.findOne({
          where: { id: addItemDto.id, userId },
        });

        // Если не найдено блюдо пользователя, ищем глобальное (без userId)
        if (!dish) {
          dish = await this.dishRepository.findOne({
            where: { id: addItemDto.id },
          });
        }

        if (!dish) {
          throw new NotFoundException('Dish not found');
        }

        dishId = dish.id;
        itemName = dish.name;

        // Рассчитываем КБЖУ на основе веса
        const ratio = addItemDto.weight / 100;
        calories = dish.caloriesPer100g * ratio;
        proteins = dish.proteinsPer100g * ratio;
        fats = dish.fatsPer100g * ratio;
        carbs = dish.carbsPer100g * ratio;
      }

      // Создаем новый элемент приёма пищи
      const mealItem = this.mealItemRepository.create({
        mealId: meal.id,
        type: addItemDto.type,
        productId,
        dishId,
        name: itemName,
        weight: addItemDto.weight,
        calories: Number(calories.toFixed(2)),
        proteins: Number(proteins.toFixed(2)),
        fats: Number(fats.toFixed(2)),
        carbs: Number(carbs.toFixed(2)),
      });

      // Сохраняем элемент
      await this.mealItemRepository.save(mealItem);

      // Обновляем итоговые значения приёма пищи
      meal.totalCalories = Number((Number(meal.totalCalories) + calories).toFixed(2));
      meal.totalProteins = Number((Number(meal.totalProteins) + proteins).toFixed(2));
      meal.totalFats = Number((Number(meal.totalFats) + fats).toFixed(2));
      meal.totalCarbs = Number((Number(meal.totalCarbs) + carbs).toFixed(2));

      // Сохраняем обновлённый приём пищи
      await this.mealRepository.save(meal);

      // Возвращаем обновлённый приём пищи с элементами
      return this.mealRepository.findOne({
        where: { id: mealId },
        relations: ['items', 'items.product', 'items.dish'],
      });
    } catch (error) {
      console.error(`Error adding item to meal:`, error);
      throw error;
    }
  }
} 