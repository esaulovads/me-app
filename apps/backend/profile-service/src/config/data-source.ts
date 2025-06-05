import { DataSource } from 'typeorm';
import { Profile } from '../entities/profile.entity';
import * as dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'fitness_profiles',
  entities: [Profile],
  migrations: ['src/migrations/*.ts'],
  synchronize: false,
}); 