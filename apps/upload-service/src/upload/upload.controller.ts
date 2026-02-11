import { Controller, Post, Get, Req, Query } from '@nestjs/common';
import { UploadService } from './upload.service';

@Controller('upload')
export class UploadController {
  constructor(private readonly service: UploadService) {}

  /**
   * POST /upload
   * Accepts multipart/form-data
   * Key: file
   */
  @Post()
  async uploadFile(@Req() req: any) {
    // Fastify way to read file
    const file = await req.file();

    if (!file) {
      throw new Error('No file received');
    }

    // Convert stream to buffer
    const buffer = await file.toBuffer();

    const userId = req.headers['x-user-id'];

    return this.service.createUpload(userId, {
      originalname: file.filename,
      size: buffer.length,
      buffer,
    });
  }

  /**
   * GET /upload
   * List uploads for user
   */
  @Get()
  async listUploads(@Req() req: any) {
    const userId = req.headers['x-user-id'];
    return this.service.list(userId);
  }

   @Get('recent')
  async recent(@Query('userId') userId: string) {
    const uploads = await this.service.list(userId);

    return uploads.map((u) => ({
      id: u.id,
      fileName: u.fileName,
      size: this.formatSize(u.fileSize),
      uploadedAt: this.formatDate(u.createdAt),
      status: u.status === 'UPLOADED' ? 'Done' : 'Processing',
    }));
  }

  private formatSize(bytes: number) {
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  }

  private formatDate(date: Date) {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: '2-digit',
    });
  }
}
