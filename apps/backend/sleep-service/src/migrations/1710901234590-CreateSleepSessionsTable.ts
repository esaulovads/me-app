import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateSleepSessionsTable1710901234590 implements MigrationInterface {
  name = 'CreateSleepSessionsTable1710901234590';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Создаем таблицу sleep_sessions
    await queryRunner.query(`
      CREATE TABLE "sleep_sessions" (
        "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
        "user_id" character varying NOT NULL,
        "sleep_time" timestamp with time zone NOT NULL,
        "wake_time" timestamp with time zone NOT NULL,
        "duration_minutes" integer NOT NULL,
        "sleep_date" date NOT NULL,
        "created_at" timestamp with time zone NOT NULL DEFAULT now(),
        "updated_at" timestamp with time zone NOT NULL DEFAULT now()
      )
    `);

    // Создаем индексы для оптимизации запросов
    await queryRunner.query(`CREATE INDEX "IDX_sleep_sessions_user_id" ON "sleep_sessions" ("user_id")`);
    await queryRunner.query(`CREATE INDEX "IDX_sleep_sessions_user_id_sleep_date" ON "sleep_sessions" ("user_id", "sleep_date")`);
    await queryRunner.query(`CREATE INDEX "IDX_sleep_sessions_sleep_date" ON "sleep_sessions" ("sleep_date")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Удаляем индексы
    await queryRunner.query(`DROP INDEX "IDX_sleep_sessions_sleep_date"`);
    await queryRunner.query(`DROP INDEX "IDX_sleep_sessions_user_id_sleep_date"`);
    await queryRunner.query(`DROP INDEX "IDX_sleep_sessions_user_id"`);

    // Удаляем таблицу
    await queryRunner.query(`DROP TABLE "sleep_sessions"`);
  }
} 