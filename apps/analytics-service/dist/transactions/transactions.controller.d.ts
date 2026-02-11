import { TransactionsService } from './transactions.service';
export declare class TransactionsController {
    private service;
    constructor(service: TransactionsService);
    bulk(body: any): Promise<{
        status: string;
    }>;
    list(userId: string, q: any): Promise<{
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
