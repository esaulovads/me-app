import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateProfilesTable1710901234570 implements MigrationInterface {
    name = 'CreateProfilesTable1710901234570'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Создаем enum типы
        await queryRunner.query(`CREATE TYPE "public"."profiles_goal_enum" AS ENUM('GAIN_WEIGHT', 'MAINTAIN_WEIGHT', 'LOSE_WEIGHT')`);
        await queryRunner.query(`CREATE TYPE "public"."profiles_gender_enum" AS ENUM('MALE', 'FEMALE')`);
        await queryRunner.query(`CREATE TYPE "public"."profiles_bmistatus_enum" AS ENUM('UNDERWEIGHT', 'NORMAL', 'OVERWEIGHT', 'OBESE')`);
        await queryRunner.query(`CREATE TYPE "public"."profiles_activitylevel_enum" AS ENUM('SEDENTARY', 'LIGHTLY_ACTIVE', 'MODERATELY_ACTIVE', 'VERY_ACTIVE', 'EXTREMELY_ACTIVE')`);

        // Создаем таблицу profiles
        await queryRunner.query(`
            CREATE TABLE "profiles" (
                "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
                "userId" character varying NOT NULL,
                "name" character varying,
                "age" integer,
                "height" double precision,
                "weight" double precision,
                "goal" "public"."profiles_goal_enum",
                "gender" "public"."profiles_gender_enum",
                "bmi" double precision,
                "bmiStatus" "public"."profiles_bmistatus_enum",
                "activityLevel" "public"."profiles_activitylevel_enum",
                "bmr" double precision,
                "tdee" double precision,
                "proteinTarget" double precision,
                "fatTarget" double precision,
                "carbTarget" double precision,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_8e520eb4da7dc01d0e190447c8e" PRIMARY KEY ("id"),
                CONSTRAINT "UQ_9e70fe39bef51acc73bad3ebdeb" UNIQUE ("userId")
            )
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Удаляем таблицу
        await queryRunner.query(`DROP TABLE "profiles"`);

        // Удаляем enum типы
        await queryRunner.query(`DROP TYPE "public"."profiles_activitylevel_enum"`);
        await queryRunner.query(`DROP TYPE "public"."profiles_bmistatus_enum"`);
        await queryRunner.query(`DROP TYPE "public"."profiles_gender_enum"`);
        await queryRunner.query(`DROP TYPE "public"."profiles_goal_enum"`);
    }
} 