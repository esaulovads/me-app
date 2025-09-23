import { IsNotEmpty, IsNumber, IsOptional, IsBoolean, IsString } from 'class-validator';

/**
 * DTO для создания расписания тренировок
 */
export class CreateWorkoutScheduleDto {
  @IsNotEmpty()
  @IsString()
  userId: string;

  @IsNotEmpty()
  @IsNumber()
  dayOfWeek: number; // 0-6 (воскресенье-суббота)

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
