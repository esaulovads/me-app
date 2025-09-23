import { Controller, Get, Param } from '@nestjs/common';
import { MuscleGroupService } from '../services/muscle-group.service';
import { MuscleGroup } from '../entities/muscle-group.entity';

/**
 * Контроллер для работы с группами мышц
 */
@Controller('muscle-groups')
export class MuscleGroupController {
  constructor(private readonly muscleGroupService: MuscleGroupService) {}

  /**
   * Получить все группы мышц
   */
  @Get()
  async findAll(): Promise<MuscleGroup[]> {
    return this.muscleGroupService.findAll();
  }

  /**
   * Получить группу мышц по ID
   */
  @Get(':id')
  async findOne(@Param('id') id: string): Promise<MuscleGroup | null> {
    return this.muscleGroupService.findOne(id);
  }
}
