import { IsDateString, IsNotEmpty } from 'class-validator';

export class CreateSleepSessionDto {
  @IsNotEmpty({ message: 'Время засыпания обязательно' })
  @IsDateString({}, { message: 'Время засыпания должно быть в формате ISO 8601' })
  sleepTime: string; // Время засыпания

  @IsNotEmpty({ message: 'Время пробуждения обязательно' })
  @IsDateString({}, { message: 'Время пробуждения должно быть в формате ISO 8601' })
  wakeTime: string; // Время пробуждения
} 