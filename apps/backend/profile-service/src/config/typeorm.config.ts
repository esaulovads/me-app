import { DataSource } from 'typeorm';
import { Profile } from '../entities/profile.entity';
import { CreateProfilesTable1710901234570 } from '../migrations/1710901234570-CreateProfilesTable';
import { config } from 'dotenv';

// Загружаем переменные окружения
config();

export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [Profile],
  migrations: [CreateProfilesTable1710901234570],
  synchronize: false,
}); 