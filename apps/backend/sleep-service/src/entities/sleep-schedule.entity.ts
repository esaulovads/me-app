import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

// Enum для типа расписания сна
export enum ScheduleType {
  INDIVIDUAL = 'INDIVIDUAL', // Индивидуальное время для каждого дня
  WEEKDAYS_WEEKENDS = 'WEEKDAYS_WEEKENDS', // Будни и выходные отдельно
  SAME_TIME = 'SAME_TIME', // Одинаковое время для всех дней (рекомендуемое)
}

@Entity('sleep_schedules')
export class SleepSchedule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', unique: true })
  userId: string; // Идентификатор пользователя (один пользователь - одно расписание)

  @Column({
    type: 'enum',
    enum: ScheduleType,
    name: 'schedule_type',
    default: ScheduleType.SAME_TIME
  })
  scheduleType: ScheduleType; // Тип расписания

  // Время пробуждения для каждого дня недели (в формате HH:mm)
  @Column({ name: 'monday_wake_time', nullable: true })
  mondayWakeTime: string;

  @Column({ name: 'tuesday_wake_time', nullable: true })
  tuesdayWakeTime: string;

  @Column({ name: 'wednesday_wake_time', nullable: true })
  wednesdayWakeTime: string;

  @Column({ name: 'thursday_wake_time', nullable: true })
  thursdayWakeTime: string;

  @Column({ name: 'friday_wake_time', nullable: true })
  fridayWakeTime: string;

  @Column({ name: 'saturday_wake_time', nullable: true })
  saturdayWakeTime: string;

  @Column({ name: 'sunday_wake_time', nullable: true })
  sundayWakeTime: string;

  // Упрощенные поля для режимов WEEKDAYS_WEEKENDS и SAME_TIME
  @Column({ name: 'weekdays_wake_time', nullable: true })
  weekdaysWakeTime: string; // Время для будних дней

  @Column({ name: 'weekends_wake_time', nullable: true })
  weekendsWakeTime: string; // Время для выходных

  @Column({ name: 'default_wake_time', nullable: true })
  defaultWakeTime: string; // Время для всех дней (режим SAME_TIME)

  @Column({ name: 'is_enabled', default: true })
  isEnabled: boolean; // Включено ли расписание

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  // Метод для получения времени пробуждения для конкретного дня недели
  getWakeTimeForDay(dayOfWeek: number): string | null {
    // dayOfWeek: 0 = воскресенье, 1 = понедельник, ..., 6 = суббота
    
    switch (this.scheduleType) {
      case ScheduleType.SAME_TIME:
        return this.defaultWakeTime;
        
      case ScheduleType.WEEKDAYS_WEEKENDS:
        // Будни: понедельник-пятница (1-5), выходные: суббота-воскресенье (0,6)
        return (dayOfWeek >= 1 && dayOfWeek <= 5) 
          ? this.weekdaysWakeTime 
          : this.weekendsWakeTime;
          
      case ScheduleType.INDIVIDUAL:
        const dayTimes = [
          this.sundayWakeTime,    // 0
          this.mondayWakeTime,    // 1
          this.tuesdayWakeTime,   // 2
          this.wednesdayWakeTime, // 3
          this.thursdayWakeTime,  // 4
          this.fridayWakeTime,    // 5
          this.saturdayWakeTime   // 6
        ];
        return dayTimes[dayOfWeek] || null;
        
      default:
        return null;
    }
  }

  // Метод для установки времени пробуждения для конкретного дня
  setWakeTimeForDay(dayOfWeek: number, time: string): void {
    const dayFields = [
      'sundayWakeTime',    // 0
      'mondayWakeTime',    // 1
      'tuesdayWakeTime',   // 2
      'wednesdayWakeTime', // 3
      'thursdayWakeTime',  // 4
      'fridayWakeTime',    // 5
      'saturdayWakeTime'   // 6
    ];
    
    if (dayOfWeek >= 0 && dayOfWeek <= 6) {
      (this as any)[dayFields[dayOfWeek]] = time;
    }
  }
} 