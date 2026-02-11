import { PrismaService } from '../prisma/prisma.service';
export declare class MemoryService {
    private prisma;
    constructor(prisma: PrismaService);
    find(raw: string): Promise<{
        id: string;
        raw: string;
        merchant: string;
        category: string;
        type: string;
    } | null>;
    save(raw: string, data: any): Promise<void>;
}
