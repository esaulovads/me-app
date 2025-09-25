import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddTrainingNormFields1710901234595 implements MigrationInterface {
  name = 'AddTrainingNormFields1710901234595';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Добавляем поля для оптимального количества минут тренировок
    await queryRunner.query(`
      ALTER TABLE "profiles" 
      ADD COLUMN "optimal_weekly_training_minutes" FLOAT NULL
    `);
    
    await queryRunner.query(`
      ALTER TABLE "profiles" 
      ADD COLUMN "optimal_daily_training_minutes" FLOAT NULL
    `);

    // Добавляем комментарии к полям
    await queryRunner.query(`
      COMMENT ON COLUMN "profiles"."optimal_weekly_training_minutes" IS 'Оптимальное количество минут тренировок в неделю'
    `);
    
    await queryRunner.query(`
      COMMENT ON COLUMN "profiles"."optimal_daily_training_minutes" IS 'Оптимальное количество минут тренировок в день'
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Удаляем добавленные поля
    await queryRunner.query(`
      ALTER TABLE "profiles" 
      DROP COLUMN "optimal_daily_training_minutes"
    `);
    
    await queryRunner.query(`
      ALTER TABLE "profiles" 
      DROP COLUMN "optimal_weekly_training_minutes"
    `);
  }
}
