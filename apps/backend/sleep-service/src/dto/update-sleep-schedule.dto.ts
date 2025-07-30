import { PartialType } from '@nestjs/mapped-types';
import { CreateSleepScheduleDto } from './create-sleep-schedule.dto';

export class UpdateSleepScheduleDto extends PartialType(CreateSleepScheduleDto) {} 