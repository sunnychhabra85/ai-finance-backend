import { PrismaService } from '../prisma/prisma.service';
export declare class CategoryService {
    private prisma;
    constructor(prisma: PrismaService);
    get(userId: string): Promise<{
        totalDebit: number;
        totalCredit: number;
        debitByCategory: any;
        creditByCategory: any;
    }>;
}
