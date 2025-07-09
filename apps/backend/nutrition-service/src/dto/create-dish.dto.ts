import { IsString, IsNotEmpty, IsArray, ValidateNested, IsUUID, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

class DishIngredientDto {
  @IsUUID()
  productId: string;

  @IsNumber()
  @Min(0)
  weight: number;
}

export class CreateDishDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DishIngredientDto)
  ingredients: DishIngredientDto[];
} 