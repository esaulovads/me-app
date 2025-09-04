import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModuleAsyncOptions } from '@nestjs/typeorm';
import databaseConfig from './database.config';

export const typeOrmConfig: TypeOrmModuleAsyncOptions = {
  imports: [
    ConfigModule.forRoot({
      load: [databaseConfig],
    }),
  ],
  useFactory: async (configService: ConfigService) => ({
    ...configService.get('database'),
  }),
  inject: [ConfigService],
};
