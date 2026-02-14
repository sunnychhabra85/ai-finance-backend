import { NestFactory } from '@nestjs/core';
import { ParserModule } from './parser.module';

// async function bootstrap() {
//   await NestFactory.createApplicationContext(ParserModule);
//   console.log('🧠 Parser Worker Running...');
// }

//for testing with http server
async function bootstrap() {
  const app = await NestFactory.create(ParserModule);
  const port = process.env.PORT || 3003;
  await app.listen(port, '0.0.0.0');
  console.log(`🧠 Parser Worker running on ${port}`);
}
bootstrap();
