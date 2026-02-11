import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import { extractRawTransactions } from './pdf.parser';
// import { AIClient } from '../clients/ai.client';
import { AnalyticsClient } from '../clients/analytics.client';

@Injectable()
export class ParserService {
  constructor(
    //private ai: AIClient,
    private analytics: AnalyticsClient,
  ) { }

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
    await this.analytics.sendTransactions(
      event.userId,
      enriched,
    );
  }
}
