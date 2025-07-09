import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Dish } from '../entities/dish.entity';
import { DishIngredient } from '../entities/dish-ingredient.entity';
import { Product } from '../entities/product.entity';
import { CreateDishDto } from '../dto/create-dish.dto';

@Injectable()
export class DishService {
  private readonly logger = new Logger(DishService.name);

  constructor(
    @InjectRepository(Dish)
    private dishRepository: Repository<Dish>,
    @InjectRepository(DishIngredient)
    private dishIngredientRepository: Repository<DishIngredient>,
    @InjectRepository(Product)
    private productRepository: Repository<Product>,
  ) {}

  async create(userId: string, createDishDto: CreateDishDto): Promise<Dish> {
    this.logger.debug(`Creating dish for user ${userId}`);
    
    // Загружаем все продукты для блюда
    const productIds = createDishDto.ingredients.map(i => i.productId);
    this.logger.debug(`Product IDs: ${productIds.join(', ')}`);
    
    const products = await this.productRepository.findBy({
      id: In(productIds),
      userId
    });
    
    this.logger.debug(`Found ${products.length} products`);

    // Проверяем, что все продукты существуют и принадлежат пользователю
    if (products.length !== productIds.length) {
      throw new NotFoundException('Some products not found or do not belong to the user');
    }

    // Рассчитываем общие значения
    let totalWeight = 0;
    let totalCalories = 0;
    let totalProteins = 0;
    let totalFats = 0;
    let totalCarbs = 0;

    // Создаем массив для хранения данных ингредиентов
    const ingredientsData = createDishDto.ingredients.map(ingredientDto => {
      const product = products.find(p => p.id === ingredientDto.productId);
      if (!product) {
        throw new NotFoundException(`Product with id ${ingredientDto.productId} not found`);
      }
      
      const weight = Number(ingredientDto.weight);
      if (isNaN(weight) || weight <= 0) {
        throw new BadRequestException(`Invalid weight for product ${product.name}`);
      }

      this.logger.debug(`Processing ingredient: ${product.name}, weight: ${weight}g`);
      this.logger.debug(`Product values per 100g: calories=${product.caloriesPer100g}, proteins=${product.proteinsPer100g}, fats=${product.fatsPer100g}, carbs=${product.carbsPer100g}`);

      // Добавляем значения к общим
      totalWeight += weight;
      totalCalories += (Number(product.caloriesPer100g) / 100) * weight;
      totalProteins += (Number(product.proteinsPer100g) / 100) * weight;
      totalFats += (Number(product.fatsPer100g) / 100) * weight;
      totalCarbs += (Number(product.carbsPer100g) / 100) * weight;

      this.logger.debug(`Running totals: weight=${totalWeight}g, calories=${totalCalories}, proteins=${totalProteins}, fats=${totalFats}, carbs=${totalCarbs}`);

      return {
        productId: product.id,
        weight
      };
    });

    if (totalWeight <= 0) {
      throw new BadRequestException('Total weight must be greater than 0');
    }

    // Рассчитываем значения на 100 грамм
    const caloriesPer100g = Number((totalCalories / totalWeight * 100).toFixed(2));
    const proteinsPer100g = Number((totalProteins / totalWeight * 100).toFixed(2));
    const fatsPer100g = Number((totalFats / totalWeight * 100).toFixed(2));
    const carbsPer100g = Number((totalCarbs / totalWeight * 100).toFixed(2));

    this.logger.debug(`Final values per 100g: calories=${caloriesPer100g}, proteins=${proteinsPer100g}, fats=${fatsPer100g}, carbs=${carbsPer100g}`);

    try {
      // Создаем и сохраняем блюдо со всеми рассчитанными значениями
      const dish = new Dish();
      dish.userId = userId;
      dish.name = createDishDto.name;
      dish.totalWeight = Number(totalWeight.toFixed(2));
      dish.totalCalories = Number(totalCalories.toFixed(2));
      dish.totalProteins = Number(totalProteins.toFixed(2));
      dish.totalFats = Number(totalFats.toFixed(2));
      dish.totalCarbs = Number(totalCarbs.toFixed(2));
      dish.caloriesPer100g = caloriesPer100g;
      dish.proteinsPer100g = proteinsPer100g;
      dish.fatsPer100g = fatsPer100g;
      dish.carbsPer100g = carbsPer100g;

      this.logger.debug('Saving dish:', dish);
      const savedDish = await this.dishRepository.save(dish);
      this.logger.debug('Dish saved successfully:', savedDish);

      // Создаем и сохраняем ингредиенты
      const ingredients = ingredientsData.map(data => 
        this.dishIngredientRepository.create({
          dishId: savedDish.id,
          ...data
        })
      );

      await this.dishIngredientRepository.save(ingredients);
      this.logger.debug(`Saved ${ingredients.length} ingredients`);

      return savedDish;
    } catch (error) {
      this.logger.error('Error saving dish:', error);
      throw error;
    }
  }

  async findAllByUserId(userId: string): Promise<Dish[]> {
    return this.dishRepository.find({
      where: { userId },
      relations: ['ingredients', 'ingredients.product'],
      order: { name: 'ASC' },
    });
  }

  async findOne(id: string, userId: string): Promise<Dish> {
    const dish = await this.dishRepository.findOne({
      where: { id, userId },
      relations: ['ingredients', 'ingredients.product'],
    });
    
    if (!dish) {
      throw new NotFoundException('Dish not found');
    }
    
    return dish;
  }

  async delete(id: string, userId: string): Promise<void> {
    const result = await this.dishRepository.delete({ id, userId });
    if (result.affected === 0) {
      throw new NotFoundException('Dish not found');
    }
  }
} 