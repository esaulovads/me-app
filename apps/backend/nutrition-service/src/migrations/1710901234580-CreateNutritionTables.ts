import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateNutritionTables1710901234580 implements MigrationInterface {
    name = 'CreateNutritionTables1710901234580'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // Создаем enum тип для meal_item_type
        await queryRunner.query(`CREATE TYPE "public"."meal_items_type_enum" AS ENUM('PRODUCT', 'DISH')`);

        // Создаем таблицу products
        await queryRunner.query(`
            CREATE TABLE "products" (
                "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" character varying NOT NULL,
                "name" character varying NOT NULL,
                "caloriesPer100g" decimal(10,2) NOT NULL,
                "proteinsPer100g" decimal(10,2) NOT NULL,
                "fatsPer100g" decimal(10,2) NOT NULL,
                "carbsPer100g" decimal(10,2) NOT NULL,
                "servingWeight" decimal(10,2) NOT NULL,
                "caloriesPerServing" decimal(10,2) NOT NULL,
                "proteinsPerServing" decimal(10,2) NOT NULL,
                "fatsPerServing" decimal(10,2) NOT NULL,
                "carbsPerServing" decimal(10,2) NOT NULL,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
            )
        `);

        // Создаем таблицу dishes
        await queryRunner.query(`
            CREATE TABLE "dishes" (
                "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" character varying NOT NULL,
                "name" character varying NOT NULL,
                "totalWeight" decimal(10,2) NOT NULL,
                "caloriesPer100g" decimal(10,2) NOT NULL,
                "proteinsPer100g" decimal(10,2) NOT NULL,
                "fatsPer100g" decimal(10,2) NOT NULL,
                "carbsPer100g" decimal(10,2) NOT NULL,
                "totalCalories" decimal(10,2) NOT NULL,
                "totalProteins" decimal(10,2) NOT NULL,
                "totalFats" decimal(10,2) NOT NULL,
                "totalCarbs" decimal(10,2) NOT NULL,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
            )
        `);

        // Создаем таблицу dish_ingredients
        await queryRunner.query(`
            CREATE TABLE "dish_ingredients" (
                "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                "dishId" uuid NOT NULL,
                "productId" uuid NOT NULL,
                "weight" decimal(10,2) NOT NULL,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "fk_dish_ingredients_dish" FOREIGN KEY ("dishId") 
                    REFERENCES "dishes" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
                CONSTRAINT "fk_dish_ingredients_product" FOREIGN KEY ("productId") 
                    REFERENCES "products" ("id") ON DELETE CASCADE ON UPDATE NO ACTION
            )
        `);

        // Создаем таблицу meals
        await queryRunner.query(`
            CREATE TABLE "meals" (
                "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                "userId" character varying NOT NULL,
                "time" TIMESTAMP NOT NULL,
                "totalCalories" decimal(10,2) NOT NULL,
                "totalProteins" decimal(10,2) NOT NULL,
                "totalFats" decimal(10,2) NOT NULL,
                "totalCarbs" decimal(10,2) NOT NULL,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now()
            )
        `);

        // Создаем таблицу meal_items
        await queryRunner.query(`
            CREATE TABLE "meal_items" (
                "id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
                "mealId" uuid NOT NULL,
                "type" "public"."meal_items_type_enum" NOT NULL,
                "productId" uuid,
                "dishId" uuid,
                "weight" decimal(10,2) NOT NULL,
                "calories" decimal(10,2) NOT NULL,
                "proteins" decimal(10,2) NOT NULL,
                "fats" decimal(10,2) NOT NULL,
                "carbs" decimal(10,2) NOT NULL,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "fk_meal_items_meal" FOREIGN KEY ("mealId") 
                    REFERENCES "meals" ("id") ON DELETE CASCADE ON UPDATE NO ACTION,
                CONSTRAINT "fk_meal_items_product" FOREIGN KEY ("productId") 
                    REFERENCES "products" ("id") ON DELETE SET NULL ON UPDATE NO ACTION,
                CONSTRAINT "fk_meal_items_dish" FOREIGN KEY ("dishId") 
                    REFERENCES "dishes" ("id") ON DELETE SET NULL ON UPDATE NO ACTION
            )
        `);

        // Создаем индексы
        await queryRunner.query(`CREATE INDEX "idx_products_userId" ON "products" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_dishes_userId" ON "dishes" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_meals_userId" ON "meals" ("userId")`);
        await queryRunner.query(`CREATE INDEX "idx_meals_time" ON "meals" ("time")`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Удаляем индексы
        await queryRunner.query(`DROP INDEX "idx_meals_time"`);
        await queryRunner.query(`DROP INDEX "idx_meals_userId"`);
        await queryRunner.query(`DROP INDEX "idx_dishes_userId"`);
        await queryRunner.query(`DROP INDEX "idx_products_userId"`);

        // Удаляем таблицы
        await queryRunner.query(`DROP TABLE "meal_items"`);
        await queryRunner.query(`DROP TABLE "meals"`);
        await queryRunner.query(`DROP TABLE "dish_ingredients"`);
        await queryRunner.query(`DROP TABLE "dishes"`);
        await queryRunner.query(`DROP TABLE "products"`);

        // Удаляем enum тип
        await queryRunner.query(`DROP TYPE "public"."meal_items_type_enum"`);
    }
} 