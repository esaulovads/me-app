import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { SleepSession } from '../entities/sleep-session.entity';
import { CreateSleepSessionDto } from '../dto/create-sleep-session.dto';
import { UpdateSleepSessionDto } from '../dto/update-sleep-session.dto';

@Injectable()
export class SleepService {
  constructor(
    @InjectRepository(SleepSession)
    private sleepSessionRepository: Repository<SleepSession>,
  ) {}

  // Создание нового периода сна
  async createSleepSession(userId: string, createSleepSessionDto: CreateSleepSessionDto): Promise<SleepSession> {
    const { sleepTime, wakeTime } = createSleepSessionDto;
    
    const sleepDateTime = new Date(sleepTime);
    const wakeDateTime = new Date(wakeTime);

    // Проверяем, что время пробуждения позже времени засыпания
    if (wakeDateTime <= sleepDateTime) {
      throw new BadRequestException('Время пробуждения должно быть позже времени засыпания');
    }

    // Вычисляем продолжительность сна в минутах
    const durationMinutes = Math.round((wakeDateTime.getTime() - sleepDateTime.getTime()) / (1000 * 60));

    // Определяем дату сна (по времени засыпания)
    const sleepDate = sleepDateTime.toISOString().split('T')[0];

    const sleepSession = this.sleepSessionRepository.create({
      userId,
      sleepTime: sleepDateTime,
      wakeTime: wakeDateTime,
      durationMinutes,
      sleepDate,
    });

    return this.sleepSessionRepository.save(sleepSession);
  }

  // Получение всех периодов сна пользователя за конкретную дату
  async getSleepSessionsByDate(userId: string, date: string): Promise<SleepSession[]> {
    return this.sleepSessionRepository.find({
      where: {
        userId,
        sleepDate: date,
      },
      order: {
        sleepTime: 'ASC',
      },
    });
  }

  // Получение всех периодов сна пользователя за диапазон дат
  async getSleepSessionsByDateRange(userId: string, startDate: string, endDate: string): Promise<SleepSession[]> {
    return this.sleepSessionRepository.find({
      where: {
        userId,
        sleepDate: Between(startDate, endDate),
      },
      order: {
        sleepDate: 'ASC',
        sleepTime: 'ASC',
      },
    });
  }

  // Получение суммарной продолжительности сна за дату
  async getTotalSleepDuration(userId: string, date: string): Promise<{ totalMinutes: number; totalHours: number }> {
    const sessions = await this.getSleepSessionsByDate(userId, date);
    const totalMinutes = sessions.reduce((sum, session) => sum + session.durationMinutes, 0);
    const totalHours = Math.round((totalMinutes / 60) * 100) / 100; // Округляем до 2 знаков

    return {
      totalMinutes,
      totalHours,
    };
  }

  // Обновление периода сна
  async updateSleepSession(id: string, userId: string, updateSleepSessionDto: UpdateSleepSessionDto): Promise<SleepSession> {
    const sleepSession = await this.sleepSessionRepository.findOne({
      where: { id, userId },
    });

    if (!sleepSession) {
      throw new NotFoundException('Период сна не найден');
    }

    const { sleepTime, wakeTime } = updateSleepSessionDto;

    // Обновляем поля, если они предоставлены
    if (sleepTime) {
      sleepSession.sleepTime = new Date(sleepTime);
    }
    if (wakeTime) {
      sleepSession.wakeTime = new Date(wakeTime);
    }

    // Проверяем, что время пробуждения позже времени засыпания
    if (sleepSession.wakeTime <= sleepSession.sleepTime) {
      throw new BadRequestException('Время пробуждения должно быть позже времени засыпания');
    }

    // Пересчитываем продолжительность и дату сна
    sleepSession.durationMinutes = Math.round(
      (sleepSession.wakeTime.getTime() - sleepSession.sleepTime.getTime()) / (1000 * 60)
    );
    sleepSession.sleepDate = sleepSession.sleepTime.toISOString().split('T')[0];

    return this.sleepSessionRepository.save(sleepSession);
  }

  // Удаление периода сна
  async deleteSleepSession(id: string, userId: string): Promise<void> {
    const result = await this.sleepSessionRepository.delete({ id, userId });
    
    if (result.affected === 0) {
      throw new NotFoundException('Период сна не найден');
    }
  }

  // Получение конкретного периода сна
  async getSleepSessionById(id: string, userId: string): Promise<SleepSession> {
    const sleepSession = await this.sleepSessionRepository.findOne({
      where: { id, userId },
    });

    if (!sleepSession) {
      throw new NotFoundException('Период сна не найден');
    }

    return sleepSession;
  }
} 