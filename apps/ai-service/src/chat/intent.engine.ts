export const detectIntent = (q: string) => {
  const text = q.toLowerCase();

  if (text.includes('food')) return 'FOOD_SPEND';
  if (text.includes('income') || text.includes('salary')) return 'INCOME';
  if (text.includes('highest') && text.includes('spend')) return 'HIGHEST_CATEGORY';
  if (text.includes('month') && text.includes('spend')) return 'HIGHEST_MONTH';

  return 'AI';
};
