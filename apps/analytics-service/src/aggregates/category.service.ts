import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CategoryService {
  constructor(private prisma: PrismaService) {}

  async get(userId: string) {
    const txns = await this.prisma.transaction.findMany({
      where: { userId },
    });

    let totalDebit = 0;
    let totalCredit = 0;

    const debitByCategory: any = {};
    const creditByCategory: any = {};

    txns.forEach((t) => {
      // Credit / Income
      if (t.type === 'INCOME') {
        totalCredit += t.amount;
        creditByCategory[t.category] =
          (creditByCategory[t.category] || 0) + t.amount;
      }

      // Debit / Spend
      else {
        totalDebit += t.amount;
        debitByCategory[t.category] =
          (debitByCategory[t.category] || 0) + t.amount;
      }
    });

    return {
      totalDebit,
      totalCredit,
      debitByCategory,
      creditByCategory,
    };
  }
}
