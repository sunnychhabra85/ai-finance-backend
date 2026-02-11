"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.applyRules = void 0;
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
const applyRules = (raw) => {
    const text = raw.toUpperCase();
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
    return classifyMerchant(text);
};
exports.applyRules = applyRules;
const classifyMerchant = (name) => {
    const n = name.toUpperCase();
    if (FOOD_KEYWORDS.some(k => n.includes(k)))
        return { merchant: name, category: 'Food', type: 'MERCHANT' };
    if (TRAVEL_KEYWORDS.some(k => n.includes(k)))
        return { merchant: name, category: 'Travel', type: 'MERCHANT' };
    if (BILLS_KEYWORDS.some(k => n.includes(k)))
        return { merchant: name, category: 'Bills', type: 'MERCHANT' };
    return null;
};
const extractName = (text) => {
    const parts = text.split('/');
    return parts[parts.length - 3] || 'Unknown';
};
//# sourceMappingURL=rule-engine.js.map