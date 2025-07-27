import { DataSource } from 'typeorm';
import { databaseConfig } from './database.config';
import { SleepSession } from '../entities/sleep-session.entity';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: databaseConfig.host,
  port: databaseConfig.port,
  username: databaseConfig.username,
  password: databaseConfig.password,
  database: databaseConfig.database,
  entities: [SleepSession],
  migrations: ['src/migrations/*.ts'],
  synchronize: false,
});

export default AppDataSource; 