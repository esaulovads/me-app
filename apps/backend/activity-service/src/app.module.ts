import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { Exercise } from './entities/exercise.entity';
import { Workout } from './entities/workout.entity';
import { WorkoutExercise } from './entities/workout-exercise.entity';
import { Set } from './entities/set.entity';
import { ExerciseController } from './controllers/exercise.controller';
import { WorkoutController } from './controllers/workout.controller';
import { WorkoutExerciseController } from './controllers/workout-exercise.controller';
import { SetController } from './controllers/set.controller';
import { ExerciseService } from './services/exercise.service';
import { WorkoutService } from './services/workout.service';
import { WorkoutExerciseService } from './services/workout-exercise.service';
import { SetService } from './services/set.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRootAsync(typeOrmConfig),
    TypeOrmModule.forFeature([Exercise, Workout, WorkoutExercise, Set]),
  ],
  controllers: [ExerciseController, WorkoutController, WorkoutExerciseController, SetController],
  providers: [ExerciseService, WorkoutService, WorkoutExerciseService, SetService],
})
export class AppModule {}
