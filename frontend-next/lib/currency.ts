export const CURRENCIES = [
  { code: 'USD', symbol: '$', name: 'US Dollar' },
  { code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee' },
  { code: 'EUR', symbol: '€', name: 'Euro' },
  { code: 'GBP', symbol: '£', name: 'British Pound' },
  { code: 'INR', symbol: '₹', name: 'Indian Rupee' },
  { code: 'AUD', symbol: 'A$', name: 'Australian Dollar' },
  { code: 'CAD', symbol: 'C$', name: 'Canadian Dollar' },
  { code: 'SGD', symbol: 'S$', name: 'Singapore Dollar' },
  { code: 'AED', symbol: 'AED', name: 'UAE Dirham' },
  { code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit' },
];

export const CURRENCY_SYMBOLS: Record<string, string> = Object.fromEntries(
  CURRENCIES.map(c => [c.code, c.symbol])
);

export function getCurrencySymbol(code?: string): string {
  return CURRENCY_SYMBOLS[code || 'USD'] || code || '$';
}

export function formatPrice(amount: number | string, currencyCode?: string): string {
  const symbol = getCurrencySymbol(currencyCode);
  return `${symbol}${Number(amount).toFixed(2)}`;
}
