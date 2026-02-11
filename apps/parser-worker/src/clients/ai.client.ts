import OpenAI from 'openai';

export class AIClient {
  private openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
    baseURL: process.env.OPENAI_BASE_URL, // for local testing with Azure OpenAI or OpenAI API proxy
  });

  async categorize(raw: string) {
    //     const prompt = `
    // You are a banking transaction classifier.

    // From this raw bank transaction string:

    // "${raw}"

    // Extract:
    // - merchant (clean human readable)
    // - category from:
    //   [Food, Travel, Bills, Shopping, Income, ATM, Transfer, Investment, EMI]

    // Return ONLY JSON:
    // { "merchant": "...", "category": "..." }
    // `;

    // const prompt = `
    // You are a banking transaction classifier.

    // From this raw bank transaction string:

    // "${raw}"

    // Extract:

    // 1) merchant (clean human readable)
    // 2) category from:
    //    [Food, Travel, Bills, Shopping, Income, ATM, Transfer, Investment, EMI]
    // 3) type from:
    //    [MERCHANT, PERSON, SELF_TRANSFER, INCOME]

    // Rules:
    // - If paid to an individual person name → PERSON
    // - If salary / credit → INCOME
    // - If ATM / self bank transfer → SELF_TRANSFER
    // - If shop / brand / company → MERCHANT

    // Return ONLY JSON:
    // {
    //   "merchant": "...",
    //   "category": "...",
    //   "type": "..."
    // }
    // `;

    const prompt = `
You are an expert Indian banking transaction classifier used in a fintech app.

Your job is to understand messy bank statement transaction strings and convert them into clean financial data.

You will receive a raw transaction string exactly as printed in a bank statement.

RAW TRANSACTION:
"${raw}"

You must extract the following:

1) merchant: A clean human readable name
2) category from this fixed list:
   [Food, Travel, Bills, Shopping, Income, ATM, Transfer, Investment, EMI, Others]
3) type from:
   [MERCHANT, PERSON, SELF_TRANSFER, INCOME, OTHERS]
4) confidence: a number between 0 and 1 indicating how sure you are

Very important classification rules:

• If it is a shop, brand, cafe, fuel station, store, service, company → MERCHANT  
• If it is clearly a person name (UPI P2A, personal name) → PERSON  
• If it is salary, refund, credit interest → INCOME  
• If it is ATM withdrawal or transfer between own accounts/wallets → SELF_TRANSFER  
• If unsure whether it is a shop or person → OTHERS with low confidence (<0.7)

Examples:

"UPI/P2M/058698517441/Madras coffee house/Paymen/YES BANK LIMITED"
→ merchant: "Madras Coffee House", category: Food, type: MERCHANT

"UPI/P2A/705596882031/SACHIN DHIMAN/Paymen/ICICI Bank"
→ merchant: "Sachin Dhiman", category: Transfer, type: PERSON

"NEFT/123456/TLG INDIA PRIVATE LIMITED/SALARY PAYOUT"
→ merchant: "TLG India Pvt Ltd", category: Income, type: INCOME

"ACH-DR-Aditya Birla Fin Ltd"
→ merchant: "Aditya Birla Finance", category: EMI, type: MERCHANT

"ATM-CASH/NAYA RLY STN GHAZIABAD"
→ merchant: "ATM Withdrawal", category: ATM, type: SELF_TRANSFER

Return ONLY valid JSON in this format:

{
  "merchant": "...",
  "category": "...",
  "type": "...",
  "confidence": 0.00
}
`;



    const res = await this.openai.chat.completions.create({
      model: 'gpt-3.5-turbo', //'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
    });

    if (!res.choices[0].message.content) {
      throw new Error('No content returned from OpenAI');
    }
    return JSON.parse(res.choices[0].message.content);
  }
}
