import { TypeOrmModuleAsyncOptions } from '@nestjs/typeorm';
import { databaseConfig } from './database.config';
import { SleepSession } from '../entities/sleep-session.entity';

export const typeOrmConfig: TypeOrmModuleAsyncOptions = {
  useFactory: () => ({
    type: 'postgres',
    host: databaseConfig.host,
    port: databaseConfig.port,
    username: databaseConfig.username,
    password: databaseConfig.password,
    database: databaseConfig.database,
    entities: [SleepSession],
    migrations: ['dist/migrations/*.js'],
    synchronize: false, // В продакшене отключаем синхронизацию
    logging: process.env.NODE_ENV === 'development',
  }),
}; 