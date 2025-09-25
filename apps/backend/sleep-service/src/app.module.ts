import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { typeOrmConfig } from './config/typeorm.config';
import { SleepSession } from './entities/sleep-session.entity';
import { SleepSchedule } from './entities/sleep-schedule.entity';
import { SleepController } from './controllers/sleep.controller';
import { SleepService } from './services/sleep.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync(typeOrmConfig),
    TypeOrmModule.forFeature([SleepSession, SleepSchedule]),
    HttpModule.register({
      timeout: 5000,
      maxRedirects: 5,
    }),
  ],
  controllers: [SleepController],
  providers: [SleepService],
})
export class AppModule {} 