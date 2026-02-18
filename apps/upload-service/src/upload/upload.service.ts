import { Injectable } from '@nestjs/common';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

@Injectable()
export class UploadService {
  private sqs: SQSClient;
  private transactionsQueueUrl: string;

  constructor(private prisma: PrismaService) {
    this.sqs = new SQSClient({
      region: process.env.AWS_REGION || 'us-east-1',
    });
    this.transactionsQueueUrl = process.env.TRANSACTIONS_QUEUE_URL || '';
  }

  async uploadFile(file: Express.Multer.File, userId: string) {
    try {
      // Generate file hash
      const fileHash = crypto.createHash('sha256').update(file.buffer).digest('hex');
      
      // 1. Save file metadata to database
      const upload = await this.prisma.upload.create({
        data: {
          fileName: file.originalname,
          fileSize: file.size,
          mimeType: file.mimetype,
          fileHash,
          userId,
          status: 'PROCESSING',
          s3Key: `uploads/${userId}/${Date.now()}-${file.originalname}`,
        },
      });

      console.log(`Upload created: ${upload.id}`);

      // 2. Send message to SQS for processing
      const message = {
        uploadId: upload.id,
        userId,
        fileName: file.originalname,
        fileSize: file.size,
        s3Key: upload.s3Key,
        timestamp: new Date().toISOString(),
      };

      const params = {
        QueueUrl: this.transactionsQueueUrl,
        MessageBody: JSON.stringify(message),
        MessageAttributes: {
          userId: {
            DataType: 'String',
            StringValue: userId,
          },
          uploadId: {
            DataType: 'String',
            StringValue: upload.id,
          },
        },
      };

      const result = await this.sqs.send(new SendMessageCommand(params));
      console.log(`Message sent to SQS: ${result.MessageId}`);

      return {
        id: upload.id,
        fileName: upload.fileName,
        status: upload.status,
        message: 'File uploaded and queued for processing',
      };
    } catch (error) {
      console.error('Upload error:', error);
      throw new Error(`Failed to upload file: ${error.message}`);
    }
  }

  async getUploads(userId: string) {
    return this.prisma.upload.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }
}