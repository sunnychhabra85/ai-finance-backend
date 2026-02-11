import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventPublisher } from '../events/event.publisher';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

@Injectable()
export class UploadService {
  constructor(
    private prisma: PrismaService,
    private events: EventPublisher,
  ) {}

  private getHash(buffer: Buffer) {
    return crypto.createHash('sha256').update(buffer).digest('hex');
  }

  async createUpload(userId: string, file: any) {
    const hash = this.getHash(file.buffer);

    // ✅ Check duplicate file
    const exists = await this.prisma.upload.findUnique({
      where: { fileHash: hash },
    });

    if (exists) {
      throw new BadRequestException(
        'This document is already uploaded.',
      );
    }

    const uploadPath = path.resolve(
      __dirname,
      '../../uploads',
      file.originalname,
    );

    console.log('Saving file to:', uploadPath);
    fs.writeFileSync(uploadPath, file.buffer);

    // ✅ Save upload with hash
    const upload = await this.prisma.upload.create({
      data: {
        userId,
        fileName: file.originalname,
        fileSize: file.size,
        fileHash: hash,
        status: 'UPLOADED',
      },
    });

    console.log('Upload created with ID:', upload.id);

    // ✅ Notify parser-worker
    await this.events.publishFileUploaded({
      uploadId: upload.id,
      userId,
      path: uploadPath,
    });

    return upload;
  }

  async list(userId: string) {
    return this.prisma.upload.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
