/**
 * Сервис профилей пользователей:
 * - Хранение и управление данными пользователя (рост, вес, пол, цели)
 * - Расчет рекомендуемого КБЖУ на основе параметров
 * - Отслеживание прогресса достижения целей
 */

import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Включаем валидацию DTO
  app.useGlobalPipes(new ValidationPipe());
  
  await app.listen(3001);
}

bootstrap(); 