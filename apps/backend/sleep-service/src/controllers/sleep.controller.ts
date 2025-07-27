import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  Headers,
  ValidationPipe,
  BadRequestException,
} from '@nestjs/common';
import { SleepService } from '../services/sleep.service';
import { CreateSleepSessionDto } from '../dto/create-sleep-session.dto';
import { UpdateSleepSessionDto } from '../dto/update-sleep-session.dto';

@Controller('sleep')
export class SleepController {
  constructor(private readonly sleepService: SleepService) {}

  // Создание нового периода сна
  @Post()
  async createSleepSession(
    @Headers('user-id') userId: string,
    @Body(ValidationPipe) createSleepSessionDto: CreateSleepSessionDto,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    return this.sleepService.createSleepSession(userId, createSleepSessionDto);
  }

  // Получение всех периодов сна за дату
  @Get()
  async getSleepSessions(
    @Headers('user-id') userId: string,
    @Query('date') date?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    // Если указан диапазон дат
    if (startDate && endDate) {
      return this.sleepService.getSleepSessionsByDateRange(userId, startDate, endDate);
    }

    // Если указана конкретная дата
    if (date) {
      return this.sleepService.getSleepSessionsByDate(userId, date);
    }

    // Если не указаны параметры, возвращаем сегодняшний день
    const today = new Date().toISOString().split('T')[0];
    return this.sleepService.getSleepSessionsByDate(userId, today);
  }

  // Получение суммарной продолжительности сна за дату
  @Get('duration')
  async getTotalSleepDuration(
    @Headers('user-id') userId: string,
    @Query('date') date: string,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    if (!date) {
      throw new BadRequestException('Параметр date обязателен');
    }

    return this.sleepService.getTotalSleepDuration(userId, date);
  }

  // Получение конкретного периода сна
  @Get(':id')
  async getSleepSession(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    return this.sleepService.getSleepSessionById(id, userId);
  }

  // Обновление периода сна
  @Put(':id')
  async updateSleepSession(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
    @Body(ValidationPipe) updateSleepSessionDto: UpdateSleepSessionDto,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    return this.sleepService.updateSleepSession(id, userId, updateSleepSessionDto);
  }

  // Удаление периода сна
  @Delete(':id')
  async deleteSleepSession(
    @Headers('user-id') userId: string,
    @Param('id') id: string,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    await this.sleepService.deleteSleepSession(id, userId);
    return { message: 'Период сна успешно удален' };
  }
} 