import { DataSource } from 'typeorm';
import { Profile } from '../entities/profile.entity';
import { AddBMIField1710901234567 } from '../migrations/1710901234567-AddBMIField';

export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'fitness_profiles',
  entities: [Profile],
  migrations: [AddBMIField1710901234567],
  synchronize: false,
}); 