import { IsUUID, IsNotEmpty } from 'class-validator';

export class CreateWorkoutExerciseDto {
  @IsUUID()
  @IsNotEmpty()
  workoutId: string;

  @IsUUID()
  @IsNotEmpty()
  exerciseId: string;
}
