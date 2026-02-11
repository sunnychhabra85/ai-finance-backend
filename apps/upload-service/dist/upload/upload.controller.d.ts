import { UploadService } from './upload.service';
export declare class UploadController {
    private readonly service;
    constructor(service: UploadService);
    uploadFile(req: any): Promise<{
        id: string;
        userId: string;
        fileName: string;
        fileSize: number;
        fileHash: string;
        status: import("../../../generated/upload-client").$Enums.UploadStatus;
        createdAt: Date;
    }>;
    listUploads(req: any): Promise<{
        id: string;
        userId: string;
        fileName: string;
        fileSize: number;
        fileHash: string;
        status: import("../../../generated/upload-client").$Enums.UploadStatus;
        createdAt: Date;
    }[]>;
    recent(userId: string): Promise<{
        id: string;
        fileName: string;
        size: string;
        uploadedAt: string;
        status: string;
    }[]>;
    private formatSize;
    private formatDate;
}
