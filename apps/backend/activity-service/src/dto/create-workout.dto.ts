import { IsDateString, IsInt, Min, IsOptional, IsArray, IsString } from 'class-validator';

export class CreateWorkoutDto {
  @IsDateString()
  date: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  duration?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetMuscleGroups?: string[];
}
