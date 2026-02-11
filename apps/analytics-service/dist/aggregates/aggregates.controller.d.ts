import { MonthlyService } from './monthly.service';
import { CategoryService } from './category.service';
export declare class AggregatesController {
    private monthly;
    private category;
    constructor(monthly: MonthlyService, category: CategoryService);
    monthlyAgg(userId: string): Promise<any>;
    categoryAgg(userId: string): Promise<{
        totalDebit: number;
        totalCredit: number;
        debitByCategory: any;
        creditByCategory: any;
    }>;
}
