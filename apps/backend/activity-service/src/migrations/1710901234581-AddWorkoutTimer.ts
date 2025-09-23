import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddWorkoutTimer1710901234581 implements MigrationInterface {
  name = 'AddWorkoutTimer1710901234581';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Добавляем поля для таймера тренировки
    await queryRunner.query(`
      ALTER TABLE "workouts" 
      ADD COLUMN "startedAt" TIMESTAMP NULL
    `);

    await queryRunner.query(`
      ALTER TABLE "workouts" 
      ADD COLUMN "finishedAt" TIMESTAMP NULL
    `);

    await queryRunner.query(`
      ALTER TABLE "workouts" 
      ADD COLUMN "isActive" boolean NOT NULL DEFAULT false
    `);

    // Создаем индекс для быстрого поиска активных тренировок
    await queryRunner.query(`
      CREATE INDEX "IDX_workouts_userId_isActive" 
      ON "workouts" ("userId", "isActive")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Удаляем индекс
    await queryRunner.query(`DROP INDEX "IDX_workouts_userId_isActive"`);

    // Удаляем добавленные колонки
    await queryRunner.query(`ALTER TABLE "workouts" DROP COLUMN "isActive"`);
    await queryRunner.query(`ALTER TABLE "workouts" DROP COLUMN "finishedAt"`);
    await queryRunner.query(`ALTER TABLE "workouts" DROP COLUMN "startedAt"`);
  }
}
