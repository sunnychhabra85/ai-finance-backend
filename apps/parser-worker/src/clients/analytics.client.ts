import axios from 'axios';

export class AnalyticsClient {
  async sendTransactions(userId: string, txns: any[]) {
    await axios.post(
      'http://localhost:3002/transactions/bulk',
      {
        userId,
        transactions: txns,
      },
    );

    console.log('📤 Sent to Analytics');
  }
}
