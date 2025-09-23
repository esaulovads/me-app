import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MuscleGroup } from '../entities/muscle-group.entity';

/**
 * Сервис для работы с группами мышц
 */
@Injectable()
export class MuscleGroupService implements OnModuleInit {
  constructor(
    @InjectRepository(MuscleGroup)
    private muscleGroupRepository: Repository<MuscleGroup>,
  ) {}

  /**
   * Инициализация базовых групп мышц при запуске приложения
   */
  async onModuleInit() {
    await this.seedMuscleGroups();
  }

  /**
   * Получить все группы мышц
   */
  async findAll(): Promise<MuscleGroup[]> {
    return this.muscleGroupRepository.find({
      order: { name: 'ASC' }
    });
  }

  /**
   * Получить группу мышц по ID
   */
  async findOne(id: string): Promise<MuscleGroup | null> {
    return this.muscleGroupRepository.findOne({ where: { id } });
  }

  /**
   * Заполнить базовые группы мышц
   */
  private async seedMuscleGroups() {
    const count = await this.muscleGroupRepository.count();
    if (count > 0) return; // Уже есть данные

    const defaultGroups = [
      { name: 'Ноги', description: 'Квадрицепсы, бицепсы бедра, ягодицы, икры' },
      { name: 'Спина', description: 'Широчайшие, трапеции, ромбовидные, задние дельты' },
      { name: 'Бицепс', description: 'Бицепс плеча, предплечья' },
      { name: 'Плечи', description: 'Передние, средние и задние дельты' },
      { name: 'Трицепс', description: 'Трицепс плеча, грудь' },
    ];

    for (const group of defaultGroups) {
      await this.muscleGroupRepository.save(group);
    }
  }
}
