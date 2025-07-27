import { IsDateString, IsOptional } from 'class-validator';

export class UpdateSleepSessionDto {
  @IsOptional()
  @IsDateString({}, { message: 'Время засыпания должно быть в формате ISO 8601' })
  sleepTime?: string; // Время засыпания

  @IsOptional()
  @IsDateString({}, { message: 'Время пробуждения должно быть в формате ISO 8601' })
  wakeTime?: string; // Время пробуждения
} 