import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { applyRules } from '../categorization/rule-engine';
import { MemoryService } from '../categorization/memory.service';
import { aiFallback } from '../categorization/ai-fallback';
import { paginate } from './pagination';
import { FiltersService } from './filters.service';
import * as crypto from 'crypto';

@Injectable()
export class TransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memory: MemoryService,
    private readonly filters: FiltersService,
  ) {}

  private fingerprint(txn: any) {
  const str = `${txn.date}-${txn.raw}-${txn.amount}`;
  return crypto.createHash('sha256').update(str).digest('hex');
}

  async bulkInsert({ userId, transactions }: any) {
    return this.prisma.$transaction(async (tx) => {
      for (const txn of transactions) {
        const fp = this.fingerprint(txn);
        const result =
          applyRules(txn.raw) ||
          (await this.memory.find(txn.raw)) ||
          (await aiFallback(txn.raw));

        if (!result) continue;

        await this.memory.save(txn.raw, result);

        // await tx.transaction.create({
        //   data: {
        //     userId,
        //     ...txn,
        //     ...result,
        //   },
        // });
        await this.prisma.transaction.upsert({
    where: {
      userId_fingerprint: {
        userId,
        fingerprint: fp,
      },
    },
    update: {
      ...txn,
      ...result,
    },
    create: {
      userId,
      ...txn,
      ...result,
      fingerprint: fp,
    },
  });
      }

      return { status: 'ok' };
    });
  }

async list(userId: string, query: any) {
  const where = this.filters.build(userId, query);

  return this.prisma.transaction.findMany({
    where,
    orderBy: { date: 'desc' },
    ...paginate(Number(query.page) || 1, Number(query.limit) || 20),
  });
}
}
