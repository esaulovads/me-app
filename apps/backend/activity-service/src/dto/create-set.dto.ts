import { IsUUID, IsNotEmpty, IsInt, IsNumber, Min } from 'class-validator';

export class CreateSetDto {
  @IsUUID()
  @IsNotEmpty()
  workoutExerciseId: string;

  @IsInt()
  @Min(1)
  reps: number;

  @IsNumber()
  @Min(0)
  weight: number;
}
