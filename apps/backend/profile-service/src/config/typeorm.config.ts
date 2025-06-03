import { DataSource } from 'typeorm';
import { Profile } from '../entities/profile.entity';
import { AddBMIStatus1710901234568 } from '../migrations/1710901234568-AddBMIStatus';

export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'fitness_profiles',
  entities: [Profile],
  migrations: [AddBMIStatus1710901234568],
  synchronize: false,
}); 