import axios from 'axios';

export const aiFallback = async (raw: string) => {
  // const res = await axios.post(
  //   'https://api.groq.com/openai/v1/chat/completions',
  //   {
  //     model: 'llama-3-8b-8192',
  //     messages: [{ role: 'user', content: raw }],
  //     temperature: 0.1,
  //   },
  //   {
  //     headers: {
  //       Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
  //     },
  //   },
  // );

  // return JSON.parse(res.data.choices[0].message.content);
  return null
};
