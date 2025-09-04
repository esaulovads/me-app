import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateActivityTables1710901234580 implements MigrationInterface {
  name = 'CreateActivityTables1710901234580';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Создание таблицы упражнений
    await queryRunner.query(`
      CREATE TABLE "exercises" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying NOT NULL,
        "targetMuscleGroup" character varying NOT NULL,
        "equipmentCount" integer NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_exercises" PRIMARY KEY ("id")
      )
    `);

    // Создание таблицы тренировок
    await queryRunner.query(`
      CREATE TABLE "workouts" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" character varying NOT NULL,
        "date" date NOT NULL,
        "duration" integer NOT NULL DEFAULT '0',
        "targetMuscleGroups" text array NOT NULL DEFAULT '{}',
        "totalWeight" numeric(10,2) NOT NULL DEFAULT '0',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_workouts" PRIMARY KEY ("id")
      )
    `);

    // Создание таблицы упражнений в тренировке
    await queryRunner.query(`
      CREATE TABLE "workout_exercises" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "workoutId" uuid NOT NULL,
        "exerciseId" uuid NOT NULL,
        "totalWeight" numeric(10,2) NOT NULL DEFAULT '0',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_workout_exercises" PRIMARY KEY ("id")
      )
    `);

    // Создание таблицы подходов
    await queryRunner.query(`
      CREATE TABLE "sets" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "workoutExerciseId" uuid NOT NULL,
        "reps" integer NOT NULL,
        "weight" numeric(10,2) NOT NULL,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_sets" PRIMARY KEY ("id")
      )
    `);

    // Создание внешних ключей
    await queryRunner.query(`
      ALTER TABLE "workout_exercises" 
      ADD CONSTRAINT "FK_workout_exercises_workoutId" 
      FOREIGN KEY ("workoutId") REFERENCES "workouts"("id") 
      ON DELETE CASCADE ON UPDATE NO ACTION
    `);

    await queryRunner.query(`
      ALTER TABLE "workout_exercises" 
      ADD CONSTRAINT "FK_workout_exercises_exerciseId" 
      FOREIGN KEY ("exerciseId") REFERENCES "exercises"("id") 
      ON DELETE NO ACTION ON UPDATE NO ACTION
    `);

    await queryRunner.query(`
      ALTER TABLE "sets" 
      ADD CONSTRAINT "FK_sets_workoutExerciseId" 
      FOREIGN KEY ("workoutExerciseId") REFERENCES "workout_exercises"("id") 
      ON DELETE CASCADE ON UPDATE NO ACTION
    `);

    // Создание индексов для оптимизации запросов
    await queryRunner.query(`CREATE INDEX "IDX_workouts_userId" ON "workouts" ("userId")`);
    await queryRunner.query(`CREATE INDEX "IDX_workouts_date" ON "workouts" ("date")`);
    await queryRunner.query(`CREATE INDEX "IDX_workouts_userId_date" ON "workouts" ("userId", "date")`);
    await queryRunner.query(`CREATE INDEX "IDX_exercises_targetMuscleGroup" ON "exercises" ("targetMuscleGroup")`);
    await queryRunner.query(`CREATE INDEX "IDX_exercises_name" ON "exercises" ("name")`);
    await queryRunner.query(`CREATE INDEX "IDX_workout_exercises_workoutId" ON "workout_exercises" ("workoutId")`);
    await queryRunner.query(`CREATE INDEX "IDX_sets_workoutExerciseId" ON "sets" ("workoutExerciseId")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Удаление индексов
    await queryRunner.query(`DROP INDEX "IDX_sets_workoutExerciseId"`);
    await queryRunner.query(`DROP INDEX "IDX_workout_exercises_workoutId"`);
    await queryRunner.query(`DROP INDEX "IDX_exercises_name"`);
    await queryRunner.query(`DROP INDEX "IDX_exercises_targetMuscleGroup"`);
    await queryRunner.query(`DROP INDEX "IDX_workouts_userId_date"`);
    await queryRunner.query(`DROP INDEX "IDX_workouts_date"`);
    await queryRunner.query(`DROP INDEX "IDX_workouts_userId"`);

    // Удаление внешних ключей
    await queryRunner.query(`ALTER TABLE "sets" DROP CONSTRAINT "FK_sets_workoutExerciseId"`);
    await queryRunner.query(`ALTER TABLE "workout_exercises" DROP CONSTRAINT "FK_workout_exercises_exerciseId"`);
    await queryRunner.query(`ALTER TABLE "workout_exercises" DROP CONSTRAINT "FK_workout_exercises_workoutId"`);

    // Удаление таблиц
    await queryRunner.query(`DROP TABLE "sets"`);
    await queryRunner.query(`DROP TABLE "workout_exercises"`);
    await queryRunner.query(`DROP TABLE "workouts"`);
    await queryRunner.query(`DROP TABLE "exercises"`);
  }
}
