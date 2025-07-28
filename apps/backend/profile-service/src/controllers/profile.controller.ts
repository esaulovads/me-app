import { Controller, Get, Put, Post, Body, Headers, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { ProfileService } from '../services/profile.service';
import { 
  UpdateNameDto, 
  UpdateBirthDateDto,
  UpdateHeightDto, 
  UpdateWeightDto, 
  UpdateGoalDto, 
  UpdateGenderDto,
  UpdateActivityLevelDto 
} from '../dto/update-profile.dto';
import { Profile } from '../entities/profile.entity';

@Controller('profiles')
export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  @Get()
  async getProfile(@Headers('user-id') userId: string): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.getProfile(userId);
  }

  @Get('complete')
  async isProfileComplete(@Headers('user-id') userId: string): Promise<{ isComplete: boolean }> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    const isComplete = await this.profileService.isProfileComplete(userId);
    return { isComplete };
  }

  @Put('batch')
  async updateProfileBatch(
    @Headers('user-id') userId: string,
    @Body() updates: Record<string, any>,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateProfileBatch(userId, updates);
  }

  @Put('name')
  async updateName(
    @Headers('user-id') userId: string,
    @Body() updateNameDto: UpdateNameDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateName(userId, updateNameDto);
  }

  @Put('birth-date')
  async updateBirthDate(
    @Headers('user-id') userId: string,
    @Body() updateBirthDateDto: UpdateBirthDateDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateBirthDate(userId, updateBirthDateDto);
  }

  @Put('height')
  async updateHeight(
    @Headers('user-id') userId: string,
    @Body() updateHeightDto: UpdateHeightDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateHeight(userId, updateHeightDto);
  }

  @Put('weight')
  async updateWeight(
    @Headers('user-id') userId: string,
    @Body() updateWeightDto: UpdateWeightDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateWeight(userId, updateWeightDto);
  }

  @Put('goal')
  async updateGoal(
    @Headers('user-id') userId: string,
    @Body() updateGoalDto: UpdateGoalDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateGoal(userId, updateGoalDto);
  }

  @Put('gender')
  async updateGender(
    @Headers('user-id') userId: string,
    @Body() updateGenderDto: UpdateGenderDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateGender(userId, updateGenderDto);
  }

  @Put('activity-level')
  async updateActivityLevel(
    @Headers('user-id') userId: string,
    @Body() updateActivityLevelDto: UpdateActivityLevelDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateActivityLevel(userId, updateActivityLevelDto);
  }

  // Принудительный пересчет рекомендуемой продолжительности сна
  @Post('recalculate-sleep')
  async recalculateSleepDuration(
    @Headers('user-id') userId: string,
  ) {
    if (!userId) {
      throw new BadRequestException('Заголовок user-id обязателен');
    }

    return this.profileService.recalculateRecommendedSleepDuration(userId);
  }
} 