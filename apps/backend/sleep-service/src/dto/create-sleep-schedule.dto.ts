import { IsEnum, IsOptional, IsString, IsBoolean, Matches } from 'class-validator';
import { ScheduleType } from '../entities/sleep-schedule.entity';

export class CreateSleepScheduleDto {
  @IsEnum(ScheduleType)
  scheduleType: ScheduleType;

  // Индивидуальные времена для каждого дня (формат HH:mm)
  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  mondayWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  tuesdayWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  wednesdayWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  thursdayWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  fridayWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  saturdayWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  sundayWakeTime?: string;

  // Времена для режимов WEEKDAYS_WEEKENDS и SAME_TIME
  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  weekdaysWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  weekendsWakeTime?: string;

  @IsOptional()
  @IsString()
  @Matches(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/, { message: 'Время должно быть в формате HH:mm' })
  defaultWakeTime?: string;

  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;
} 