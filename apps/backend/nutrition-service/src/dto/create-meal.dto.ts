import { IsString, IsNotEmpty, IsArray, ValidateNested, IsUUID, IsNumber, Min, IsEnum, IsDateString } from 'class-validator';
import { Type } from 'class-transformer';
import { MealItemType } from '../entities/meal-item.entity';

class MealItemDto {
  @IsEnum(MealItemType)
  type: MealItemType;

  @IsUUID()
  id: string;

  @IsNumber()
  @Min(0)
  weight: number;
}

export class CreateMealDto {
  @IsDateString()
  time: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MealItemDto)
  items: MealItemDto[];
} 