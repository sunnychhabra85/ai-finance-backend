import { NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  NestFastifyApplication,
} from '@nestjs/platform-fastify';
import multipart from '@fastify/multipart';
import { AppModule } from './app.module';
import * as dotenv from 'dotenv';
dotenv.config(); // automatically reads ./apps/auth-service/.env

async function bootstrap() {
  const app =
    await NestFactory.create<NestFastifyApplication>(
      AppModule,
      new FastifyAdapter(),
    );

  await app.register(multipart); // ✅ no TS error now

  app.enableCors({ origin: '*' });

  await app.listen(3003, '0.0.0.0');
}
bootstrap();
