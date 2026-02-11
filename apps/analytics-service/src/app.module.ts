import { Module } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';
import { TransactionsController } from './transactions/transactions.controller';
import { TransactionsService } from './transactions/transactions.service';
import { FiltersService } from './transactions/filters.service';
import { MonthlyService } from './aggregates/monthly.service';
import { CategoryService } from './aggregates/category.service';
import { MemoryService } from './categorization/memory.service';
import { AggregatesController } from './aggregates/aggregates.controller';

@Module({
  controllers: [TransactionsController, AggregatesController],
  providers: [
    PrismaService,
    TransactionsService,
    FiltersService,
    MonthlyService,
    CategoryService,
    MemoryService,
  ],
})
export class AppModule {}
