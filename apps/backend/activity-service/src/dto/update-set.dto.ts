import { IsInt, IsNumber, Min, IsOptional } from 'class-validator';

export class UpdateSetDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  reps?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;
}
