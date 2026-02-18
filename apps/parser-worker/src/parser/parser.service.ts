import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';
import { extractRawTransactions } from './pdf.parser';
// import { AIClient } from '../clients/ai.client';
// import { AnalyticsClient } from '../clients/analytics.client';

@Injectable()
export class ParserService {
  private sqs: SQSClient;
  private transactionsQueueUrl: string;

  constructor(
    //private ai: AIClient,
    // private analytics: AnalyticsClient,
  ) {
    this.sqs = new SQSClient({
      region: process.env.AWS_REGION || 'us-east-1',
    });
    this.transactionsQueueUrl = process.env.TRANSACTIONS_QUEUE_URL || '';
  }

  async parseFile(event: any) {
    console.log('📥 Parsing:', event.path);

    const buffer = fs.readFileSync(event.path);

    const rawTxns = await extractRawTransactions(buffer);

    const enriched: Array<{
      date: string;
      amount: number;
      // merchant: string;
      // category: string;
      // type: string;
      raw: string;
    }> = [];

    for (const txn of rawTxns) {
      // const ai = await this.ai.categorize(
      //   txn.raw_particular,
      // );

      // if (ai.confidence < 0.75) {
      //   ai.type = 'OTHERS';
      // }

      enriched.push({
        date: txn.date,
        amount: txn.amount,
        // merchant: ai.merchant,
        // category: ai.category,
        // type: ai.type,
        raw: txn.raw_particular,
      });
    }
    
    console.log('✅ Enriched Transactions:', enriched);
    await this.sendToSQS(event.userId, enriched);
  }

  private async sendToSQS(userId: string, transactions: any[]) {
    try {
      const message = {
        userId,
        transactions,
        timestamp: new Date().toISOString(),
      };

      const params = {
        QueueUrl: this.transactionsQueueUrl,
        MessageBody: JSON.stringify(message),
        MessageAttributes: {
          userId: {
            DataType: 'String',
            StringValue: userId,
          },
          transactionCount: {
            DataType: 'Number',
            StringValue: String(transactions.length),
          },
        },
      };

      const result = await this.sqs.send(new SendMessageCommand(params));
      console.log(`📤 Sent ${transactions.length} transactions to SQS. MessageId: ${result.MessageId}`);
    } catch (error) {
      console.error('❌ Failed to send to SQS:', error);
      throw error;
    }
  }
}
