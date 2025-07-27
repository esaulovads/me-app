import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('sleep_sessions')
export class SleepSession {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string; // Идентификатор пользователя

  @Column({ type: 'timestamp with time zone', name: 'sleep_time' })
  sleepTime: Date; // Время засыпания

  @Column({ type: 'timestamp with time zone', name: 'wake_time' })
  wakeTime: Date; // Время пробуждения

  @Column({ type: 'int', name: 'duration_minutes' })
  durationMinutes: number; // Продолжительность сна в минутах

  @Column({ type: 'date', name: 'sleep_date' })
  sleepDate: string; // Дата сна (в формате YYYY-MM-DD)

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
} 