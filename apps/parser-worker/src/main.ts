import { NestFactory } from '@nestjs/core';
import { ParserModule } from './parser.module';

// async function bootstrap() {
//   await NestFactory.createApplicationContext(ParserModule);
//   console.log('🧠 Parser Worker Running...');
// }

//for testing with http server
async function bootstrap() {
  const app = await NestFactory.create(ParserModule);
  await app.listen(3004);
  console.log('🧠 Parser Worker running on 3004');
}
bootstrap();
