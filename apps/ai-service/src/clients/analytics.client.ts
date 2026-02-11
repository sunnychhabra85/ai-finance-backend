import axios from 'axios';

export class AnalyticsClient {
  async getTransactions(userId: string) {
    const res = await axios.get(
      `http://localhost:3002/transactions?userId=${userId}`
    );
    return res.data;
  }

  async getCategoryAgg(userId: string) {
    const res = await axios.get(
      `http://localhost:3002/aggregates/category?userId=${userId}`
    );
    return res.data;
  }

  async getMonthlyAgg(userId: string) {
    const res = await axios.get(
      `http://localhost:3002/aggregates/monthly?userId=${userId}`
    );
    return res.data;
  }
}
