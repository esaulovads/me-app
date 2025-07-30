import { MigrationInterface, QueryRunner, Table } from 'typeorm';

export class CreateSleepSchedulesTable1710901234591 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Создаем enum для типа расписания
    await queryRunner.query(`
      CREATE TYPE "schedule_type_enum" AS ENUM('INDIVIDUAL', 'WEEKDAYS_WEEKENDS', 'SAME_TIME')
    `);

    // Создаем таблицу sleep_schedules
    await queryRunner.createTable(
      new Table({
        name: 'sleep_schedules',
        columns: [
          {
            name: 'id',
            type: 'uuid',
            isPrimary: true,
            generationStrategy: 'uuid',
            default: 'uuid_generate_v4()',
          },
          {
            name: 'user_id',
            type: 'varchar',
            isUnique: true,
          },
          {
            name: 'schedule_type',
            type: 'schedule_type_enum',
            default: "'SAME_TIME'",
          },
          {
            name: 'monday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'tuesday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'wednesday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'thursday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'friday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'saturday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'sunday_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'weekdays_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'weekends_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'default_wake_time',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'is_enabled',
            type: 'boolean',
            default: true,
          },
          {
            name: 'created_at',
            type: 'timestamp with time zone',
            default: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'updated_at',
            type: 'timestamp with time zone',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
        indices: [
          {
            name: 'IDX_sleep_schedules_user_id',
            columnNames: ['user_id'],
          },
        ],
      }),
      true,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Удаляем таблицу (индексы удалятся автоматически)
    await queryRunner.dropTable('sleep_schedules');
    
    // Удаляем enum
    await queryRunner.query(`DROP TYPE "schedule_type_enum"`);
  }
} 