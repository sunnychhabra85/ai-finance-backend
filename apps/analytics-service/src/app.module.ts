import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AnalyticsModule } from './analytics/analytics.module';
import { TransactionsModule } from './transactions/transactions.module';
import { PrismaService } from './prisma/prisma.service';
import { JwtStrategy } from './auth/jwt.strategy';
import { TransactionsController } from './transactions/transactions.controller';
import { TransactionsService } from './transactions/transactions.service';
import { FiltersService } from './transactions/filters.service';
import { MonthlyService } from './aggregates/monthly.service';
import { CategoryService } from './aggregates/category.service';
import { MemoryService } from './categorization/memory.service';
import { AggregatesController } from './aggregates/aggregates.controller';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'your-secret-key',
      signOptions: { expiresIn: '24h' },
    }),
    AnalyticsModule,
    TransactionsModule,
  ],
  controllers: [TransactionsController, AggregatesController],
  providers: [PrismaService, JwtStrategy, TransactionsService,
    FiltersService,
    MonthlyService,
    CategoryService,
    MemoryService,],
})
export class AppModule {}