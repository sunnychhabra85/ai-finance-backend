import { NestFactory } from '@nestjs/core';
import { FastifyAdapter } from '@nestjs/platform-fastify';
import { AppModule } from './app.module';
import { env } from './config/env';
import * as dotenv from 'dotenv';
dotenv.config(); // automatically reads ./apps/auth-service/.env


async function bootstrap() {
  const app = await NestFactory.create(
    AppModule,
    new FastifyAdapter(),
  );
  app.enableCors({
    origin: '*',
  });
  await app.listen(env.PORT, '0.0.0.0');
}
bootstrap();
