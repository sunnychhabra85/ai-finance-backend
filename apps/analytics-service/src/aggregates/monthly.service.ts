import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MonthlyService {
  constructor(private prisma: PrismaService) {}

  async get(userId: string) {
    const txns = await this.prisma.transaction.findMany({
      where: { userId, type: 'MERCHANT' },
    });

    const map: any = {};

    txns.forEach((t) => {
      const month = t.date.slice(3, 10);
      map[month] = (map[month] || 0) + t.amount;
    });

    return map;
  }
}
