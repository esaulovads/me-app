import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Profile } from '../entities/profile.entity';
import { 
  UpdateNameDto, 
  UpdateAgeDto, 
  UpdateHeightDto, 
  UpdateWeightDto, 
  UpdateGoalDto, 
  UpdateGenderDto,
  UpdateActivityLevelDto 
} from '../dto/update-profile.dto';

@Injectable()
export class ProfileService {
  constructor(
    @InjectRepository(Profile)
    private profileRepository: Repository<Profile>,
  ) {}

  // Инициализация профиля с userId
  async initializeProfile(userId: string): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = this.profileRepository.create({ userId });
      await this.profileRepository.save(profile);
    }
    return profile;
  }

  // Получение профиля пользователя
  async getProfile(userId: string): Promise<Profile> {
    const profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      throw new NotFoundException('Профиль не найден');
    }
    return profile;
  }

  // Обновление имени пользователя
  async updateName(userId: string, updateNameDto: UpdateNameDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.name = updateNameDto.name;
    return await this.profileRepository.save(profile);
  }

  // Обновление возраста пользователя
  async updateAge(userId: string, updateAgeDto: UpdateAgeDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.age = updateAgeDto.age;
    // Сохраняем профиль - это автоматически пересчитает BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление роста пользователя
  async updateHeight(userId: string, updateHeightDto: UpdateHeightDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.height = updateHeightDto.height;
    // Сохраняем профиль - это автоматически пересчитает BMI, BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление веса пользователя
  async updateWeight(userId: string, updateWeightDto: UpdateWeightDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.weight = updateWeightDto.weight;
    // Сохраняем профиль - это автоматически пересчитает BMI, BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление цели пользователя
  async updateGoal(userId: string, updateGoalDto: UpdateGoalDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.goal = updateGoalDto.goal;
    return await this.profileRepository.save(profile);
  }

  // Обновление пола пользователя
  async updateGender(userId: string, updateGenderDto: UpdateGenderDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.gender = updateGenderDto.gender;
    // Сохраняем профиль - это автоматически пересчитает BMR и TDEE
    return await this.profileRepository.save(profile);
  }

  // Обновление уровня активности пользователя
  async updateActivityLevel(userId: string, updateActivityLevelDto: UpdateActivityLevelDto): Promise<Profile> {
    let profile = await this.profileRepository.findOne({ where: { userId } });
    if (!profile) {
      profile = await this.initializeProfile(userId);
    }
    profile.activityLevel = updateActivityLevelDto.activityLevel;
    // Сохраняем профиль - это автоматически пересчитает TDEE
    return await this.profileRepository.save(profile);
  }

  // Проверка заполненности профиля
  async isProfileComplete(userId: string): Promise<boolean> {
    const profile = await this.getProfile(userId);
    return profile.isComplete();
  }
} 