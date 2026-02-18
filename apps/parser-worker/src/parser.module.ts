import { Module } from '@nestjs/common';
import { FileUploadedConsumer } from './consumer/file-uploaded.consumer';
import { ParserService } from './parser/parser.service';
import { AIClient } from './clients/ai.client';
// import { AnalyticsClient } from './clients/analytics.client';
import { TestController } from './test.controller'

@Module({
  controllers: [TestController],
  providers: [
    FileUploadedConsumer,
    ParserService,
    AIClient,
    // AnalyticsClient, // No longer needed - using SQS instead
  ],
})
export class ParserModule {}
