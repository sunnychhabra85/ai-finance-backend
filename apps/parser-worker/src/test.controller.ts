import { Controller, Post, Body } from '@nestjs/common';
import { ParserService } from './parser/parser.service';

@Controller('internal')
export class TestController {
  constructor(private parser: ParserService) {}

  @Post('file-uploaded')
  async handle(@Body() body: any) {
    await this.parser.parseFile(body);
    return { status: 'parsed' };
  }
}
