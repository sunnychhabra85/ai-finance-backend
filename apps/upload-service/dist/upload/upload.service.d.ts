import { PrismaService } from '../prisma/prisma.service';
import { EventPublisher } from '../events/event.publisher';
export declare class UploadService {
    private prisma;
    private events;
    constructor(prisma: PrismaService, events: EventPublisher);
    private getHash;
    createUpload(userId: string, file: any): Promise<{
        id: string;
        userId: string;
        fileName: string;
        fileSize: number;
        fileHash: string;
        status: import("../../../generated/upload-client").$Enums.UploadStatus;
        createdAt: Date;
    }>;
    list(userId: string): Promise<{
        id: string;
        userId: string;
        fileName: string;
        fileSize: number;
        fileHash: string;
        status: import("../../../generated/upload-client").$Enums.UploadStatus;
        createdAt: Date;
    }[]>;
}
