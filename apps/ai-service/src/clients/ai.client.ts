import axios from 'axios';

export class AIClient {
  private OPENAI_URL = process.env.OPENAI_URL || 'https://api.openai.com/v1/chat/completions';
  private OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';

  async askWithContext(question: string, context: any) {
    const prompt = `
You are a personal finance assistant.

You are given user's financial data below in JSON.

DATA:
${JSON.stringify(context)}

Rules:
- Answer ONLY using this data.
- If answer not found, say "I cannot find this in your transactions."
- Be concise.

Question: ${question}
`;

    const res = await axios.post(
      this.OPENAI_URL,
      {
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.2,
      },
      {
        headers: {
          Authorization: `Bearer ${this.OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
      },
    );

    return res.data.choices[0].message.content.trim();
  }
}

