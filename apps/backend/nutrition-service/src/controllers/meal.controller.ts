import { Controller, Get, Post, Delete, Body, Param, Headers, Query } from '@nestjs/common';
import { MealService } from '../services/meal.service';
import { CreateMealDto } from '../dto/create-meal.dto';
import { Meal } from '../entities/meal.entity';

@Controller('meals')
export class MealController {
  constructor(private readonly mealService: MealService) {}

  @Post()
  async create(
    @Headers('user-id') userId: string,
    @Body() createMealDto: CreateMealDto,
  ): Promise<Meal> {
    return this.mealService.create(userId, createMealDto);
  }

  @Get()
  async findAllByDate(
    @Headers('user-id') userId: string,
    @Query('date') date: string,
  ): Promise<Meal[]> {
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
    return this.mealService.getDailySummary(userId, date);
  }

  @Delete(':id')
  async delete(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ): Promise<void> {
    return this.mealService.delete(id, userId);
  }
} 