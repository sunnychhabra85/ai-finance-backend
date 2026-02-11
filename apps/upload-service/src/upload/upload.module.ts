import { Module } from '@nestjs/common';
import { UploadController } from './upload.controller';
import { UploadService } from './upload.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventPublisher } from '../events/event.publisher';

@Module({
  controllers: [UploadController],
  providers: [UploadService, PrismaService, EventPublisher],
})
export class UploadModule {}
