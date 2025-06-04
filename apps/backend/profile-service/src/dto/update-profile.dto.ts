import { IsString, IsNumber, IsEnum, Min, Max } from 'class-validator';
import { UserGoal, Gender, ActivityLevel } from '../entities/profile.entity';

export class UpdateNameDto {
  @IsString()
  name: string;
}

export class UpdateAgeDto {
  @IsNumber()
  @Min(12) // Минимальный возраст
  @Max(100) // Максимальный возраст
  age: number;
}

export class UpdateHeightDto {
  @IsNumber()
  @Min(50) // Минимальный рост в см
  @Max(250) // Максимальный рост в см
  height: number;
}

export class UpdateWeightDto {
  @IsNumber()
  @Min(30) // Минимальный вес в кг
  @Max(300) // Максимальный вес в кг
  weight: number;
}

export class UpdateGoalDto {
  @IsEnum(UserGoal)
  goal: UserGoal;
}

export class UpdateGenderDto {
  @IsEnum(Gender)
  gender: Gender;
}

export class UpdateActivityLevelDto {
  @IsEnum(ActivityLevel)
  activityLevel: ActivityLevel;
} 