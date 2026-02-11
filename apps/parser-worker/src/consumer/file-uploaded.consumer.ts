import { Injectable, OnModuleInit } from '@nestjs/common';
import { ParserService } from '../parser/parser.service';

@Injectable()
export class FileUploadedConsumer implements OnModuleInit {
  constructor(private parser: ParserService) {}

  async onModuleInit() {
    console.log('👂 Waiting for FILE_UPLOADED events...');
  }

  // This will be triggered by Upload Service via queue later
  async handle(event: any) {
    await this.parser.parseFile(event);
  }
}
