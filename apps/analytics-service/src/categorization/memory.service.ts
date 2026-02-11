import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MemoryService {
  constructor(private prisma: PrismaService) {}

  async find(raw: string) {
    return this.prisma.categorizationMemory.findUnique({
      where: { raw },
    });
  }

  async save(raw: string, data: any) {
    await this.prisma.categorizationMemory.create({
      data: { raw, ...data },
    });
  }
}
