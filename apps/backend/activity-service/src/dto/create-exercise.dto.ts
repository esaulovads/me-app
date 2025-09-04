import { IsString, IsNotEmpty, IsInt, Min } from 'class-validator';

export class CreateExerciseDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  targetMuscleGroup: string;

  @IsInt()
  @Min(1)
  equipmentCount: number;
}
