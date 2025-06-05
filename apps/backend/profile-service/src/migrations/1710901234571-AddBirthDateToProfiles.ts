import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddBirthDateToProfiles1710901234571 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // Добавляем колонку birthDate
        await queryRunner.query(`
            ALTER TABLE "profiles" 
            ADD COLUMN "birthDate" DATE;
        `);

        // Создаем функцию для вычисления возраста
        await queryRunner.query(`
            CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE)
            RETURNS INTEGER AS $$
            BEGIN
                RETURN EXTRACT(YEAR FROM age(birth_date));
            END;
            $$ LANGUAGE plpgsql;
        `);

        // Создаем триггерную функцию для автоматического обновления возраста
        await queryRunner.query(`
            CREATE OR REPLACE FUNCTION update_age()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW."age" := calculate_age(NEW."birthDate");
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        `);

        // Создаем триггер
        await queryRunner.query(`
            CREATE TRIGGER trigger_update_age
            BEFORE INSERT OR UPDATE OF "birthDate"
            ON profiles
            FOR EACH ROW
            WHEN (NEW."birthDate" IS NOT NULL)
            EXECUTE FUNCTION update_age();
        `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // Удаляем триггер
        await queryRunner.query(`DROP TRIGGER IF EXISTS trigger_update_age ON profiles;`);
        
        // Удаляем функции
        await queryRunner.query(`DROP FUNCTION IF EXISTS update_age;`);
        await queryRunner.query(`DROP FUNCTION IF EXISTS calculate_age;`);
        
        // Удаляем колонку birthDate
        await queryRunner.query(`
            ALTER TABLE "profiles" 
            DROP COLUMN "birthDate";
        `);
    }
} 