import { IsString, IsNumber, IsNotEmpty, Min } from 'class-validator';

export class CreateProductDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsNumber()
  @Min(0)
  caloriesPer100g: number;

  @IsNumber()
  @Min(0)
  proteinsPer100g: number;

  @IsNumber()
  @Min(0)
  fatsPer100g: number;

  @IsNumber()
  @Min(0)
  carbsPer100g: number;

  @IsNumber()
  @Min(0)
  servingWeight: number;
} 