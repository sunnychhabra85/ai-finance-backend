const FOOD_KEYWORDS = [
  'SWEETS',
  'CAFE',
  'COFFEE',
  'RESTAURANT',
  'THELA',
  'XPRESS',
  'BAKERY',
  'PIZZA',
  'BURGER',
  'HOTEL',
];

const TRAVEL_KEYWORDS = [
  'UBER',
  'OLA',
  'METRO',
  'IRCTC',
  'AIR',
  'RAIL',
  'CAB',
];

const BILLS_KEYWORDS = [
  'CRED',
  'ELECTRICITY',
  'WATER',
  'GAS',
  'BROADBAND',
  'RECHARGE',
];

export const applyRules = (raw: string) => {
  const text = raw.toUpperCase();

  // -------- Structural rules --------
  if (text.includes('ATM-CASH'))
    return {
      merchant: 'ATM Withdrawal',
      category: 'ATM',
      type: 'SELF_TRANSFER',
    };

  if (text.includes('SALARY') || text.includes('PAYOUT'))
    return {
      merchant: 'Salary',
      category: 'Income',
      type: 'INCOME',
    };

  if (text.includes('ACH-DR') || text.includes('FIN LTD'))
    return {
      merchant: 'Loan EMI',
      category: 'EMI',
      type: 'MERCHANT',
    };

  if (text.includes('MUTUAL FUND'))
    return {
      merchant: 'Mutual Fund',
      category: 'Investment',
      type: 'MERCHANT',
    };

  // -------- UPI patterns --------
  if (text.includes('UPI/P2A'))
    return {
      merchant: extractName(text),
      category: 'Transfer',
      type: 'PERSON',
    };

  if (text.includes('UPI/P2M')) {
    const name = extractName(text);
    return classifyMerchant(name);
  }

  // -------- Direct merchant match --------
  return classifyMerchant(text);
};

// -------- Merchant classifier --------

const classifyMerchant = (name: string) => {
  const n = name.toUpperCase();

  if (FOOD_KEYWORDS.some(k => n.includes(k)))
    return { merchant: name, category: 'Food', type: 'MERCHANT' };

  if (TRAVEL_KEYWORDS.some(k => n.includes(k)))
    return { merchant: name, category: 'Travel', type: 'MERCHANT' };

  if (BILLS_KEYWORDS.some(k => n.includes(k)))
    return { merchant: name, category: 'Bills', type: 'MERCHANT' };

  return null; // let AI handle
};

const extractName = (text: string) => {
  const parts = text.split('/');
  return parts[parts.length - 3] || 'Unknown';
};
