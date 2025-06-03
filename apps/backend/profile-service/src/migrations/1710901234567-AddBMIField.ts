import { MigrationInterface, QueryRunner } from "typeorm";

export class AddBMIField1710901234567 implements MigrationInterface {
    name = 'AddBMIField1710901234567'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "profiles" ADD "bmi" float`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "profiles" DROP COLUMN "bmi"`);
    }
} 