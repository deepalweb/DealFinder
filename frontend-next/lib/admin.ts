import { getCategoryLabel, normalizeCategoryId } from '@/lib/categories';

export type PromotionLifecycleStatus =
  | 'active'
  | 'pending_approval'
  | 'scheduled'
  | 'rejected'
  | 'admin_paused'
  | 'expired'
  | 'draft';

export const ADMIN_STATUS_STYLES: Record<string, { bg: string; color: string }> = {
  active: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  approved: { bg: 'rgba(16,185,129,0.1)', color: '#059669' },
  pending_approval: { bg: 'rgba(245,158,11,0.1)', color: '#d97706' },
  scheduled: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
  rejected: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
  admin_paused: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  expired: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  draft: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  suspended: { bg: 'rgba(100,116,139,0.1)', color: '#64748b' },
  needs_review: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
  user: { bg: 'rgba(16,185,129,0.1)', color: '#10b981' },
  merchant: { bg: 'rgba(99,102,241,0.1)', color: '#6366f1' },
  admin: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
};

export function getPromotionId<T extends { _id?: string; id?: string }>(promotion: T) {
  return promotion._id || promotion.id || '';
}

export function getMerchantName(merchant: string | { name?: string } | null | undefined) {
  return typeof merchant === 'object' ? merchant?.name || '—' : merchant || '—';
}

export function getEffectivePromotionStatus(promotion: {
  status?: string;
  startDate?: string;
  endDate?: string;
}): PromotionLifecycleStatus {
  const rawStatus = promotion.status || 'draft';
  if (['pending_approval', 'rejected', 'admin_paused', 'draft'].includes(rawStatus)) {
    return rawStatus as PromotionLifecycleStatus;
  }

  const now = new Date();
  const startDate = promotion.startDate ? new Date(promotion.startDate) : null;
  const endDate = promotion.endDate ? new Date(promotion.endDate) : null;

  if (endDate && !Number.isNaN(endDate.getTime()) && endDate < now) return 'expired';
  if (startDate && !Number.isNaN(startDate.getTime()) && startDate > now) return 'scheduled';
  return 'active';
}

export function formatAdminDate(value?: string | Date | null) {
  if (!value) return '—';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

export function normalizeAdminSearchValue(value: unknown) {
  return String(value || '').trim().toLowerCase();
}

export function matchesAdminSearch(term: string, ...values: unknown[]) {
  const normalizedTerm = normalizeAdminSearchValue(term);
  if (!normalizedTerm) return true;
  return values.some((value) => normalizeAdminSearchValue(value).includes(normalizedTerm));
}

export function getNormalizedAdminCategory(category?: string | null) {
  return normalizeCategoryId(category);
}

export function getAdminCategoryLabel(category?: string | null) {
  return getCategoryLabel(category);
}
