import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddNameToMealItems1710901234581 implements MigrationInterface {
    name = 'AddNameToMealItems1710901234581'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Добавляем поле name в таблицу meal_items
        await queryRunner.query(`ALTER TABLE "meal_items" ADD "name" varchar NOT NULL DEFAULT ''`);
        
        // Заполняем поле name для существующих записей
        await queryRunner.query(`
            UPDATE "meal_items" 
            SET "name" = COALESCE(
                (SELECT "products"."name" FROM "products" WHERE "products"."id" = "meal_items"."productId"),
                (SELECT "dishes"."name" FROM "dishes" WHERE "dishes"."id" = "meal_items"."dishId"),
                'Unknown Item'
            )
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Удаляем поле name
        await queryRunner.query(`ALTER TABLE "meal_items" DROP COLUMN "name"`);
    }
} 