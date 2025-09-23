import { IsOptional, IsBoolean, IsString } from 'class-validator';

/**
 * DTO для обновления расписания тренировок
 */
export class UpdateWorkoutScheduleDto {
  @IsOptional()
  @IsString()
  muscleGroupId?: string;

  @IsOptional()
  @IsBoolean()
  isFullBody?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
