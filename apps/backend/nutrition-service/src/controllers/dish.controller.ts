import { Controller, Get, Post, Delete, Body, Param, Headers, Query } from '@nestjs/common';
import { DishService } from '../services/dish.service';
import { CreateDishDto } from '../dto/create-dish.dto';
import { Dish } from '../entities/dish.entity';

@Controller('dishes')
export class DishController {
  constructor(private readonly dishService: DishService) {}

  @Post()
  async create(
    @Headers('user-id') userId: string,
    @Body() createDishDto: CreateDishDto,
  ): Promise<Dish> {
    return this.dishService.create(userId, createDishDto);
  }

  @Get()
  async findAll(
    @Headers('user-id') userId: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('search') search?: string,
  ): Promise<{ dishes: Dish[]; total: number }> {
    const limitNum = limit ? parseInt(limit, 10) : 10;
    const offsetNum = offset ? parseInt(offset, 10) : 0;
    return this.dishService.findAllByUserId(userId, limitNum, offsetNum, search);
  }

  @Get('recent')
  async getRecentDishes(@Headers('user-id') userId: string): Promise<Dish[]> {
    return this.dishService.getRecentDishes(userId);
  }

  @Get(':id')
  async findOne(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ): Promise<Dish> {
    return this.dishService.findOne(id, userId);
  }

  @Delete(':id')
  async delete(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ): Promise<void> {
    return this.dishService.delete(id, userId);
  }
} 