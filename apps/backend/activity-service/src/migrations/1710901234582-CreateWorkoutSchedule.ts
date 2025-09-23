import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Миграция для создания таблиц групп мышц и расписания тренировок
 */
export class CreateWorkoutSchedule1710901234582 implements MigrationInterface {
  name = 'CreateWorkoutSchedule1710901234582';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Создаем таблицу групп мышц
    await queryRunner.query(`
      CREATE TABLE "muscle_groups" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "description" character varying,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "UQ_muscle_groups_name" UNIQUE ("name"),
        CONSTRAINT "PK_muscle_groups" PRIMARY KEY ("id")
      )
    `);

    // Создаем таблицу расписания тренировок
    await queryRunner.query(`
      CREATE TABLE "workout_schedules" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "dayOfWeek" integer NOT NULL,
        "muscleGroupId" uuid,
        "isFullBody" boolean NOT NULL DEFAULT false,
        "isActive" boolean NOT NULL DEFAULT true,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_workout_schedules" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_workout_schedules_user_day" UNIQUE ("userId", "dayOfWeek")
      )
    `);

    // Добавляем внешний ключ на группу мышц
    await queryRunner.query(`
      ALTER TABLE "workout_schedules" 
      ADD CONSTRAINT "FK_workout_schedules_muscle_group" 
      FOREIGN KEY ("muscleGroupId") REFERENCES "muscle_groups"("id") 
      ON DELETE SET NULL ON UPDATE NO ACTION
    `);

    // Добавляем индексы для производительности
    await queryRunner.query(`
      CREATE INDEX "IDX_workout_schedules_userId" 
      ON "workout_schedules" ("userId")
    `);

    await queryRunner.query(`
      CREATE INDEX "IDX_workout_schedules_dayOfWeek" 
      ON "workout_schedules" ("dayOfWeek")
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "IDX_workout_schedules_dayOfWeek"`);
    await queryRunner.query(`DROP INDEX "IDX_workout_schedules_userId"`);
    await queryRunner.query(`ALTER TABLE "workout_schedules" DROP CONSTRAINT "FK_workout_schedules_muscle_group"`);
    await queryRunner.query(`DROP TABLE "workout_schedules"`);
    await queryRunner.query(`DROP TABLE "muscle_groups"`);
  }
}
