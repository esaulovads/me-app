import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Profile } from '../entities/profile.entity';

export const databaseConfig: TypeOrmModuleOptions = {
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'fitness_profiles',
  entities: [Profile],
  synchronize: process.env.NODE_ENV !== 'production', // В продакшене лучше использовать миграции
}; 