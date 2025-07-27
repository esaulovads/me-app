import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Включаем глобальную валидацию
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, // Удаляет свойства, которых нет в DTO
    forbidNonWhitelisted: true, // Выбрасывает ошибку при наличии неизвестных свойств
    transform: true, // Автоматически преобразует типы
  }));

  // Включаем CORS для взаимодействия с фронтендом
  app.enableCors();

  const port = process.env.PORT || 3003;
  await app.listen(port);
  
  console.log(`🌙 Sleep Service запущен на порту ${port}`);
}

bootstrap(); 