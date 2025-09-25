import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddSleepQualityCoefficient1753723614022 implements MigrationInterface {
  name = 'AddSleepQualityCoefficient1753723614022';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Добавляем поле sleepQualityCoefficient в таблицу profiles
    await queryRunner.addColumn(
      'profiles',
      new TableColumn({
        name: 'sleepQualityCoefficient',
        type: 'float',
        isNullable: true,
        comment: 'Коэффициент качества сна (среднее отношение факт/норма за 2 недели)',
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Удаляем поле sleepQualityCoefficient из таблицы profiles
    await queryRunner.dropColumn('profiles', 'sleepQualityCoefficient');
  }
}
