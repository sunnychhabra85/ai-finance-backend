import { AnalyticsClient } from '../clients/analytics.client';
import { AIClient } from '../clients/ai.client';

import { detectIntent } from './intent.engine';

export class ChatService {
  private analytics = new AnalyticsClient();
  private ai = new AIClient();

  async ask(userId: string, question: string) {
    const intent = detectIntent(question);

    const categoryAgg = await this.analytics.getCategoryAgg(userId);
    const monthlyAgg = await this.analytics.getMonthlyAgg(userId);

    // ✅ DB based answers (no AI)
    if (intent === 'FOOD_SPEND') {
      return `You spent ₹${categoryAgg.debitByCategory?.Food || 0} on Food.`;
    }

    if (intent === 'INCOME') {
      return `Your total income is ₹${categoryAgg.totalCredit}.`;
    }

    if (intent === 'HIGHEST_CATEGORY') {
      const max = Object.entries(categoryAgg.debitByCategory)
        .sort((a: any, b: any) => b[1] - a[1])[0];

      return `Your highest spending category is ${max[0]} with ₹${max[1]}.`;
    }

    if (intent === 'HIGHEST_MONTH') {
      const max = Object.entries(monthlyAgg)
        .sort((a: any, b: any) => b[1] - a[1])[0];

      return `You spent the most in ${max[0]}: ₹${max[1]}.`;
    }

    // ❓ fallback to AI with context
    const transactions = await this.analytics.getTransactions(userId);
    const context = {
      categoryAgg,
      monthlyAgg,
      recentTransactions: transactions.slice(0, 30),
    };

    return this.ai.askWithContext(question, context);
  }
}


// export class ChatService {
//   private analytics = new AnalyticsClient();
//   private ai = new AIClient();

//   async ask(userId: string, question: string) {
//     const txns = await this.analytics.getTransactions(userId);
//     const agg = await this.analytics.getCategoryAgg(userId);

//     const q = question.toLowerCase();

//     // 🔎 Search from transactions
//     if (q.includes('food')) {
//       const food = agg.debitByCategory?.Food || 0;
//       return `You spent ₹${food} on Food.`;
//     }

//     if (q.includes('income') || q.includes('salary')) {
//       return `Your total income is ₹${agg.totalCredit}.`;
//     }

//     if (q.includes('highest spend')) {
//       const max = Object.entries(agg.debitByCategory)
//         .sort((a: any, b: any) => b[1] - a[1])[0];
//       return `Your highest spending category is ${max[0]} with ₹${max[1]}.`;
//     }

//     // ❓ Not found → AI fallback
//     return this.ai.ask(question);
//   }
// }
