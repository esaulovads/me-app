import { Controller, Get, Post, Put, Delete, Body, Param, Headers, Query, BadRequestException } from '@nestjs/common';
import { MealService } from '../services/meal.service';
import { CreateMealDto } from '../dto/create-meal.dto';
import { UpdateMealDto } from '../dto/update-meal.dto';
import { Meal } from '../entities/meal.entity';
import { MealItemType } from '../entities/meal-item.entity';

@Controller('meals')
export class MealController {
  constructor(private readonly mealService: MealService) {}

  @Post()
  async create(
    @Headers('user-id') userId: string,
    @Body() createMealDto: CreateMealDto,
  ): Promise<Meal> {
    if (!userId) {
      throw new BadRequestException('User ID заголовок обязателен');
    }
    return this.mealService.create(userId, createMealDto);
  }

  @Get()
  async findAllByDate(
    @Headers('user-id') userId: string,
    @Query('date') date: string,
  ): Promise<Meal[]> {
    if (!userId) {
      throw new BadRequestException('User ID заголовок обязателен');
    }
    if (!date) {
      throw new BadRequestException('Параметр date обязателен');
    }
    return this.mealService.findAllByUserIdAndDate(userId, date);
  }

  @Get('summary')
  async getDailySummary(
    @Headers('user-id') userId: string,
    @Query('date') date: string,
  ): Promise<{
    totalCalories: number;
    totalProteins: number;
    totalFats: number;
    totalCarbs: number;
  }> {
    if (!userId) {
      throw new BadRequestException('User ID заголовок обязателен');
    }
    if (!date) {
      throw new BadRequestException('Параметр date обязателен');
    }
    return this.mealService.getDailySummary(userId, date);
  }

  @Put(':id')
  async update(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
    @Body() updateMealDto: UpdateMealDto,
  ): Promise<Meal> {
    if (!userId) {
      throw new BadRequestException('User ID заголовок обязателен');
    }
    return this.mealService.update(id, userId, updateMealDto);
  }

  @Delete(':id')
  async delete(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ): Promise<void> {
    if (!userId) {
      throw new BadRequestException('User ID заголовок обязателен');
    }
    return this.mealService.delete(id, userId);
  }

  @Post(':mealId/items')
  async addItemToMeal(
    @Headers('user-id') userId: string,
    @Param('mealId') mealId: string,
    @Body() addItemDto: {
      type: MealItemType;
      id: string; // productId или dishId
      weight: number;
    },
  ): Promise<Meal> {
    if (!userId) {
      throw new BadRequestException('User ID заголовок обязателен');
    }
    
    // Валидация данных
    if (!addItemDto.type || !addItemDto.id || !addItemDto.weight) {
      throw new BadRequestException('Поля type, id и weight обязательны');
    }

    if (addItemDto.weight <= 0) {
      throw new BadRequestException('Вес должен быть больше нуля');
    }

    if (!Object.values(MealItemType).includes(addItemDto.type)) {
      throw new BadRequestException('Неверный тип элемента');
    }

    return this.mealService.addItemToMeal(userId, mealId, addItemDto);
  }
} 