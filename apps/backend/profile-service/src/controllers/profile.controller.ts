import { Controller, Get, Put, Body, Headers, UnauthorizedException } from '@nestjs/common';
import { ProfileService } from '../services/profile.service';
import { UpdateNameDto, UpdateAgeDto, UpdateHeightDto, UpdateWeightDto, UpdateGoalDto, UpdateGenderDto } from '../dto/update-profile.dto';
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

  @Put('age')
  async updateAge(
    @Headers('user-id') userId: string,
    @Body() updateAgeDto: UpdateAgeDto,
  ): Promise<Profile> {
    if (!userId) {
      throw new UnauthorizedException('Требуется авторизация');
    }
    return this.profileService.updateAge(userId, updateAgeDto);
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
} 