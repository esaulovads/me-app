import { IsString, IsNumber, IsEnum, Min, Max, IsDate } from 'class-validator';
import { UserGoal, Gender, ActivityLevel } from '../entities/profile.entity';
import { Type } from 'class-transformer';

export class UpdateNameDto {
  @IsString()
  name: string;
}

export class UpdateBirthDateDto {
  @Type(() => Date)
  @IsDate()
  birthDate: Date;
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