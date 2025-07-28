import { MigrationInterface, QueryRunner } from "typeorm";

export class AddRecommendedSleepDuration1753723614021 implements MigrationInterface {
    name = 'AddRecommendedSleepDuration1753723614021'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "profiles" ADD "recommendedSleepDuration" double precision`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "profiles" DROP COLUMN "recommendedSleepDuration"`);
    }

}
