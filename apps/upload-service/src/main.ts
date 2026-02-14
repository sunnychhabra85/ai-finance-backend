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

  const port = process.env.PORT || 3002;
  await app.listen(port, '0.0.0.0');
  console.log(`Upload service listening on port ${port}`);
}
bootstrap();
