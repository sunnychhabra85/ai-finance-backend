import { PrismaService } from '../prisma/prisma.service';
import { MemoryService } from '../categorization/memory.service';
import { FiltersService } from './filters.service';
export declare class TransactionsService {
    private readonly prisma;
    private readonly memory;
    private readonly filters;
    constructor(prisma: PrismaService, memory: MemoryService, filters: FiltersService);
    private fingerprint;
    bulkInsert({ userId, transactions }: any): Promise<{
        status: string;
    }>;
    list(userId: string, query: any): Promise<{
        id: string;
        userId: string;
        date: string;
        raw: string;
        amount: number;
        merchant: string;
        category: string;
        type: string;
        fingerprint: string;
    }[]>;
}
