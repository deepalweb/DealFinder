// Shared date/lifecycle helpers for promotions, used by both the Mongo and
// Postgres code paths in promotionRoutes.js / postgresPromotionService.js.
const COLOMBO_TIME_ZONE = 'Asia/Colombo';
const COLOMBO_OFFSET = '+05:30';
const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function getColomboDateKey(value = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: COLOMBO_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(value);

  const year = parts.find((part) => part.type === 'year')?.value;
  const month = parts.find((part) => part.type === 'month')?.value;
  const day = parts.find((part) => part.type === 'day')?.value;
  return `${year}-${month}-${day}`;
}

function getColomboDayRange(value = new Date()) {
  const dateKey = getColomboDateKey(value);
  const start = new Date(`${dateKey}T00:00:00.000${COLOMBO_OFFSET}`);
  const endExclusive = new Date(start.getTime() + 24 * 60 * 60 * 1000);
  return { start, endExclusive };
}

function normalizePromotionDateInput(value, boundary = 'start') {
  if (!value) return value;
  if (value instanceof Date) return value;

  if (typeof value === 'string' && DATE_ONLY_PATTERN.test(value)) {
    const time = boundary === 'end' ? '23:59:59.999' : '00:00:00.000';
    return new Date(`${value}T${time}${COLOMBO_OFFSET}`);
  }

  return new Date(value);
}

function resolveLifecycleStatus(startDate, endDate, value = new Date()) {
  const { start, endExclusive } = getColomboDayRange(value);

  if (endDate < start) return 'expired';
  if (startDate >= endExclusive) return 'scheduled';
  return 'active';
}

module.exports = {
  COLOMBO_TIME_ZONE,
  COLOMBO_OFFSET,
  DATE_ONLY_PATTERN,
  getColomboDateKey,
  getColomboDayRange,
  normalizePromotionDateInput,
  resolveLifecycleStatus,
};
