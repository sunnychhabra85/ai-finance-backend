import { PrismaService } from '../prisma/prisma.service';
export declare class MonthlyService {
    private prisma;
    constructor(prisma: PrismaService);
    get(userId: string): Promise<any>;
}
