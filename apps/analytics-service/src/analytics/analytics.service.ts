import { Injectable, OnModuleInit } from '@nestjs/common';
import { SQSClient, ReceiveMessageCommand, DeleteMessageCommand, Message } from '@aws-sdk/client-sqs';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AnalyticsService implements OnModuleInit {
  private sqs: SQSClient;
  private analyticsQueueUrl: string;

  constructor(private prisma: PrismaService) {
    this.sqs = new SQSClient({
      region: process.env.AWS_REGION || 'us-east-1',
    });
    this.analyticsQueueUrl = process.env.ANALYTICS_QUEUE_URL || '';
  }

  onModuleInit() {
    console.log('✅ Analytics service initialized');
    if (this.analyticsQueueUrl) {
      this.startPolling();
    } else {
      console.warn('⚠️  ANALYTICS_QUEUE_URL not configured');
    }
  }

  private startPolling() {
    console.log('🔄 Starting analytics queue polling...');
    
    setInterval(() => {
      this.pollAnalyticsEvents().catch(err => {
        console.error('Error polling:', err);
      });
    }, 5000);
  }

  private async pollAnalyticsEvents() {
    try {
      const command = new ReceiveMessageCommand({
        QueueUrl: this.analyticsQueueUrl,
        MaxNumberOfMessages: 10,
        WaitTimeSeconds: 20,
      });

      const data = await this.sqs.send(command);

      if (!data.Messages || data.Messages.length === 0) {
        return;
      }

      console.log(`📨 Received ${data.Messages.length} events`);

      for (const message of data.Messages) {
        await this.processEvent(message);
      }
    } catch (error) {
      console.error('❌ Queue polling error:', error);
    }
  }

  private async processEvent(message: Message) {
    try {
      const event = JSON.parse(message.Body || '{}');
      const { userId, uploadId, transactionCount } = event;

      console.log(`⚙️  Processing event for user: ${userId}`);

      // Get transactions for this user
      const transactions = await this.prisma.transaction.findMany({
        where: { userId },
      });

      if (transactions.length === 0) {
        console.log('No transactions found');
        return;
      }

      // Calculate analytics
      const totalAmount = transactions.reduce((sum, t) => sum + t.amount, 0);
      const avgAmount = totalAmount / transactions.length;
      const categoryBreakdown = this.calculateCategoryBreakdown(transactions);

      // Store analytics
      const analytics = await this.prisma.analytics.upsert({
        where: { userId },
        update: {
          totalTransactions: transactions.length,
          totalAmount,
          avgAmount,
          categoryBreakdown,
          lastUpdated: new Date(),
        },
        create: {
          userId,
          totalTransactions: transactions.length,
          totalAmount,
          avgAmount,
          categoryBreakdown,
          period: 'OVERALL',
          lastUpdated: new Date(),
        },
      });

      console.log(`✅ Analytics stored for ${userId}`);

      // Delete from queue
      const deleteCommand = new DeleteMessageCommand({
        QueueUrl: this.analyticsQueueUrl,
        ReceiptHandle: message.ReceiptHandle || '',
      });
      
      await this.sqs.send(deleteCommand);

    } catch (error) {
      console.error(`Error processing event: ${error.message}`);
    }
  }

  private calculateCategoryBreakdown(transactions: any[]): Record<string, number> {
    const breakdown: Record<string, number> = {};

    for (const transaction of transactions) {
      const category = transaction.category || 'OTHER';
      breakdown[category] = (breakdown[category] || 0) + transaction.amount;
    }

    return breakdown;
  }

  // ✅ API Methods

  async getSummary(userId: string) {
    const analytics = await this.prisma.analytics.findUnique({
      where: { userId },
    });

    if (!analytics) {
      return {
        userId,
        totalTransactions: 0,
        totalAmount: 0,
        avgAmount: 0,
        categoryBreakdown: {},
      };
    }

    return {
      userId,
      totalTransactions: analytics.totalTransactions,
      totalAmount: analytics.totalAmount,
      avgAmount: analytics.avgAmount,
      categoryBreakdown: analytics.categoryBreakdown,
      lastUpdated: analytics.lastUpdated,
    };
  }

  async getByCategory(userId: string) {
    const analytics = await this.prisma.analytics.findUnique({
      where: { userId },
    });

    if (!analytics) {
      return {
        userId,
        categories: [],
      };
    }

    const categoryData = Object.entries(analytics.categoryBreakdown || {})
      .map(([category, amount]: [string, any]) => ({
        category,
        amount: parseFloat(amount.toString()),
        percentage: analytics.totalAmount > 0
          ? ((parseFloat(amount.toString()) / analytics.totalAmount) * 100).toFixed(2)
          : '0.00',
      }))
      .sort((a, b) => b.amount - a.amount);

    return {
      userId,
      totalAmount: analytics.totalAmount,
      categories: categoryData,
    };
  }

  async getTopCategories(userId: string, limit: number = 5) {
    const analytics = await this.prisma.analytics.findUnique({
      where: { userId },
    });

    if (!analytics) {
      return { userId, topCategories: [] };
    }

    const topCategories = Object.entries(analytics.categoryBreakdown || {})
      .map(([category, amount]: [string, any]) => ({
        category,
        amount: parseFloat(amount.toString()),
      }))
      .sort((a, b) => b.amount - a.amount)
      .slice(0, limit);

    return { userId, topCategories };
  }

  async getTrends(userId: string, period: 'daily' | 'weekly' | 'monthly' = 'monthly') {
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'daily':
        startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        break;
      case 'weekly':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'monthly':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
    }

    const transactions = await this.prisma.transaction.findMany({
      where: {
        userId,
        date: {
          gte: startDate.toISOString().split('T')[0],
          lte: now.toISOString().split('T')[0],
        },
      },
      orderBy: { date: 'asc' },
    });

    const trendData = transactions.reduce((acc, t) => {
      const dateKey = t.date.split('T')[0];
      if (!acc[dateKey]) {
        acc[dateKey] = { date: dateKey, amount: 0, count: 0 };
      }
      acc[dateKey].amount += t.amount;
      acc[dateKey].count += 1;
      return acc;
    }, {} as Record<string, any>);

    return {
      userId,
      period,
      data: Object.values(trendData),
      totalAmount: transactions.reduce((sum, t) => sum + t.amount, 0),
    };
  }
}