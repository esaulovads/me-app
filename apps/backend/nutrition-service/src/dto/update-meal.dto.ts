import { IsDateString } from 'class-validator';

export class UpdateMealDto {
  @IsDateString()
  time: string;
} 