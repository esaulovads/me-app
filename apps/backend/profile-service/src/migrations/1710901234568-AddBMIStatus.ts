import { MigrationInterface, QueryRunner } from "typeorm";

export class AddBMIStatus1710901234568 implements MigrationInterface {
    name = 'AddBMIStatus1710901234568'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Добавляем колонку bmiStatus
        await queryRunner.query(`ALTER TABLE "profiles" ADD "bmiStatus" "public"."profiles_bmistatus_enum"`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Удаляем колонку bmiStatus
        await queryRunner.query(`ALTER TABLE "profiles" DROP COLUMN "bmiStatus"`);
    }
} 