'use client';

import { useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import { AdminAPI } from '@/lib/api';

type Promotion = {
  _id?: string;
  title?: string;
  image?: string;
  discount?: string;
  category?: string;
  status?: string;
  merchant?: { name?: string };
};

type Assignment = {
  _id: string;
  sectionKey: string;
  promotion?: Promotion;
  enabled: boolean;
  mode: string;
  priority: number;
  startAt?: string | null;
  endAt?: string | null;
  bannerImageUrl?: string | null;
  radiusKm?: number | null;
  minDistanceKm?: number | null;
  maxDistanceKm?: number | null;
  excludeFromAuto?: boolean;
  metadata?: Record<string, unknown>;
  status: string;
};

type Section = {
  key: string;
  label: string;
  maxItems: number;
  mode: string;
  description: string;
  assignments: Assignment[];
};

type Conflict = {
  promotionId: string;
  title: string;
  sections: string[];
};

type SectionForm = {
  mode: string;
  priority: number;
  enabled: boolean;
  startAt: string;
  endAt: string;
  bannerImageUrl: string;
  radiusKm: string;
  minDistanceKm: string;
  maxDistanceKm: string;
  excludeFromAuto: boolean;
};

const SECTION_LABELS: Record<string, string> = {
  banner: 'Banner',
  hot_deals: 'Hot Deals',
  new_this_week: 'New This Week',
  flash_sales: 'Flash Sales',
};

const MODE_OPTIONS: Record<string, { value: string; label: string }[]> = {
  banner: [
    { value: 'manual', label: 'Manual' },
    { value: 'hidden', label: 'Hidden' },
  ],
  hot_deals: [
    { value: 'manual', label: 'Manual Pin' },
    { value: 'excluded', label: 'Exclude' },
    { value: 'hidden', label: 'Hidden' },
  ],
  new_this_week: [
    { value: 'forced', label: 'Force Show' },
    { value: 'hidden', label: 'Hide' },
  ],
  flash_sales: [
    { value: 'manual', label: 'Manual Pin' },
    { value: 'excluded', label: 'Exclude' },
    { value: 'hidden', label: 'Hidden' },
  ],
};

const emptyForm: SectionForm = {
  mode: 'manual',
  priority: 0,
  enabled: true,
  startAt: '',
  endAt: '',
  bannerImageUrl: '',
  radiusKm: '',
  minDistanceKm: '',
  maxDistanceKm: '',
  excludeFromAuto: false,
};

function fmtDate(value?: string | null) {
  if (!value) return 'Not scheduled';
  return new Date(value).toLocaleString();
}

export default function AdminSectionsPage() {
  const [sections, setSections] = useState<Section[]>([]);
  const [conflicts, setConflicts] = useState<Conflict[]>([]);
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeSectionKey, setActiveSectionKey] = useState('banner');
  const [form, setForm] = useState<SectionForm>({ ...emptyForm });
  const [saving, setSaving] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [promotionSearch, setPromotionSearch] = useState('');
  const [merchantFilter, setMerchantFilter] = useState('all');
  const [promotionStatusFilter, setPromotionStatusFilter] = useState('active');
  const [selectedPromotionIds, setSelectedPromotionIds] = useState<string[]>([]);

  const load = async () => {
    setLoading(true);
    try {
      const [sectionData, conflictData, promotionData] = await Promise.all([
        AdminAPI.getSections(),
        AdminAPI.getSectionConflicts(),
        AdminAPI.getAllPromotions(),
      ]);
      const availableSections = (sectionData || []).filter((section: Section) => section.key !== 'nearby');
      setSections(availableSections);
      setConflicts(conflictData || []);
      setPromotions(Array.isArray(promotionData) ? promotionData : []);
      const firstKey = (availableSections?.[0]?.key as string | undefined) || 'banner';
      setActiveSectionKey((current) =>
        availableSections?.some((section: Section) => section.key === current) ? current : firstKey
      );
    } catch (error) {
      console.error(error);
      toast.error('Failed to load section manager.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const activeSection = useMemo(
    () => sections.find((section) => section.key === activeSectionKey) || sections[0],
    [sections, activeSectionKey]
  );

  const assignedPromotionIds = useMemo(
    () =>
      new Set(
        sections.flatMap((section) =>
          section.assignments
            .map((assignment) => assignment.promotion?._id)
            .filter((promotionId): promotionId is string => Boolean(promotionId))
        )
      ),
    [sections]
  );

  const currentSectionAssignedPromotionIds = useMemo(
    () =>
      new Set(
        activeSection?.assignments
          .map((assignment) => assignment.promotion?._id)
          .filter((promotionId): promotionId is string => Boolean(promotionId)) || []
      ),
    [activeSection]
  );

  const merchantOptions = useMemo(
    () =>
      [...new Set(promotions.map((promotion) => promotion.merchant?.name).filter(Boolean))]
        .sort((a, b) => String(a).localeCompare(String(b))),
    [promotions]
  );

  const promotionStatusOptions = useMemo(
    () =>
      [...new Set(promotions.map((promotion) => promotion.status).filter(Boolean))]
        .sort((a, b) => String(a).localeCompare(String(b))),
    [promotions]
  );

  const filteredPromotions = useMemo(() => {
    const term = promotionSearch.trim().toLowerCase();
    return promotions.filter((promotion) => {
      const merchantName = promotion.merchant?.name || '';
      const matchesSearch =
        !term ||
        promotion.title?.toLowerCase().includes(term) ||
        merchantName.toLowerCase().includes(term) ||
        promotion.category?.toLowerCase().includes(term);
      const matchesMerchant =
        merchantFilter === 'all' || merchantName === merchantFilter;
      const matchesStatus =
        promotionStatusFilter === 'all' || promotion.status === promotionStatusFilter;

      return matchesSearch && matchesMerchant && matchesStatus;
    });
  }, [merchantFilter, promotionSearch, promotionStatusFilter, promotions]);

  const selectedPromotion = useMemo(
    () => promotions.find((promotion) => promotion._id === selectedPromotionIds[0]),
    [promotions, selectedPromotionIds]
  );

  useEffect(() => {
    const nextMode = MODE_OPTIONS[activeSectionKey]?.[0]?.value || 'manual';
    setForm({
      ...emptyForm,
      mode: nextMode,
    });
    setSelectedPromotionIds([]);
  }, [activeSectionKey]);

  function getErrorMessage(error: unknown, fallback: string) {
    if (error instanceof Error && error.message) return error.message;
    return fallback;
  }

  const handleSave = async () => {
    if (!activeSection) return;
    if (selectedPromotionIds.length === 0) {
      toast.error('Select at least one deal.');
      return;
    }

    setSaving(true);
    try {
      await AdminAPI.saveSectionAssignment({
        sectionKey: activeSection.key,
        promotionIds: selectedPromotionIds,
        mode: form.mode,
        priority: Number(form.priority) || 0,
        enabled: Boolean(form.enabled),
        startAt: form.startAt || null,
        endAt: form.endAt || null,
        bannerImageUrl: form.bannerImageUrl || null,
        radiusKm: form.radiusKm === '' ? null : Number(form.radiusKm),
        minDistanceKm: form.minDistanceKm === '' ? null : Number(form.minDistanceKm),
        maxDistanceKm: form.maxDistanceKm === '' ? null : Number(form.maxDistanceKm),
        excludeFromAuto: Boolean(form.excludeFromAuto),
      });
      toast.success(`${SECTION_LABELS[activeSection.key]} updated.`);
      setForm({
        ...emptyForm,
        mode: MODE_OPTIONS[activeSection.key]?.[0]?.value || 'manual',
      });
      setSelectedPromotionIds([]);
      await load();
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Failed to save assignment.'));
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (assignmentId: string) => {
    if (!confirm('Remove this assignment from the section?')) return;
    try {
      await AdminAPI.deleteSectionAssignment(assignmentId);
      toast.success('Assignment removed.');
      await load();
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Failed to delete assignment.'));
    }
  };

  const handlePublish = async () => {
    setPublishing(true);
    try {
      await AdminAPI.publishSections();
      toast.success('Section changes published.');
    } catch (error: unknown) {
      toast.error(getErrorMessage(error, 'Publish failed.'));
    } finally {
      setPublishing(false);
    }
  };

  const togglePromotionSelection = (promotionId: string) => {
    setSelectedPromotionIds((current) =>
      current.includes(promotionId)
        ? current.filter((id) => id !== promotionId)
        : [...current, promotionId]
    );
  };

  return (
    <div style={{ display: 'grid', gap: '1.25rem' }}>
      <div className="surface-panel panel-pad">
        <div className="flex items-center justify-between gap-4 flex-wrap">
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 800, margin: 0, color: 'var(--text-primary)' }}>
              Section Manager
            </h1>
            <p style={{ margin: '0.35rem 0 0', color: 'var(--text-secondary)' }}>
              Curate banner, hot deals, new-this-week, and flash sales for the mobile home page without touching the all-deals or nearby feeds.
            </p>
            <p style={{ margin: '0.35rem 0 0', color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              Saved assignments go live on the next mobile refresh. The cache refresh button is only for forcing a faster sync.
            </p>
          </div>
          <button
            onClick={handlePublish}
            disabled={publishing}
            className="btn btn-primary"
            style={{ minWidth: '180px', justifyContent: 'center' }}
          >
            <i className="fas fa-cloud-upload-alt"></i>
            {publishing ? 'Refreshing...' : 'Refresh Live Cache'}
          </button>
        </div>
      </div>

      {conflicts.length > 0 ? (
        <div className="surface-panel panel-pad" style={{ borderColor: 'rgba(245,158,11,0.35)', background: 'rgba(245,158,11,0.06)' }}>
          <div className="flex items-center gap-3" style={{ marginBottom: '0.75rem' }}>
            <i className="fas fa-triangle-exclamation" style={{ color: '#d97706' }}></i>
            <strong style={{ color: '#92400e' }}>Conflict Checker</strong>
          </div>
          <div style={{ display: 'grid', gap: '0.65rem' }}>
            {conflicts.map((conflict) => (
              <div
                key={conflict.promotionId}
                style={{
                  padding: '0.85rem 1rem',
                  borderRadius: '0.9rem',
                  background: '#fff',
                  border: '1px solid rgba(245,158,11,0.18)',
                }}
              >
                <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{conflict.title}</div>
                <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                  Live in {conflict.sections.map((section: string) => SECTION_LABELS[section] || section).join(', ')}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      <div className="surface-panel" style={{ overflow: 'hidden' }}>
        <div style={{ display: 'flex', gap: '0.5rem', padding: '1rem', borderBottom: '1px solid var(--border-color)', overflowX: 'auto' }}>
          {(sections.length ? sections : [{ key: 'banner', label: 'Banner', maxItems: 0, mode: 'manual_only', description: '', assignments: [] }]).map((section) => (
            <button
              key={section.key}
              onClick={() => setActiveSectionKey(section.key)}
              style={{
                border: 'none',
                cursor: 'pointer',
                borderRadius: '999px',
                padding: '0.7rem 1rem',
                whiteSpace: 'nowrap',
                fontWeight: 700,
                color: activeSectionKey === section.key ? '#fff' : 'var(--text-secondary)',
                background: activeSectionKey === section.key ? 'var(--primary-gradient)' : 'var(--light-gray)',
              }}
            >
              {section.label}
            </button>
          ))}
        </div>

        <div className="panel-pad" style={{ display: 'grid', gap: '1.2rem' }}>
          {activeSection ? (
            <>
              <div className="grid grid-cols-1 xl:grid-cols-[1.2fr_0.8fr] gap-5">
                <div className="surface-panel panel-pad" style={{ boxShadow: 'none' }}>
                  <div className="flex items-start justify-between gap-4 flex-wrap" style={{ marginBottom: '1rem' }}>
                    <div>
                      <h2 style={{ margin: 0, fontSize: '1.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                        {activeSection.label}
                      </h2>
                      <p style={{ margin: '0.35rem 0 0', color: 'var(--text-secondary)' }}>{activeSection.description}</p>
                    </div>
                    <div style={{ textAlign: 'right', color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                      <div>Max items: {activeSection.maxItems}</div>
                      <div>Mode: {activeSection.mode.replace(/_/g, ' ')}</div>
                    </div>
                  </div>

                  <div style={{ display: 'grid', gap: '0.85rem' }}>
                    {loading ? (
                      Array.from({ length: 3 }).map((_, index) => (
                        <div key={index} className="skeleton" style={{ height: '92px', borderRadius: '1rem' }}></div>
                      ))
                    ) : activeSection.assignments.length === 0 ? (
                      <div className="empty-state" style={{ padding: '2rem' }}>
                        <div className="empty-icon">
                          <i className="fas fa-layer-group"></i>
                        </div>
                        <h2 style={{ marginTop: 0, marginBottom: '0.4rem', fontWeight: 800 }}>No assignments yet</h2>
                        <p style={{ margin: 0, color: 'var(--text-secondary)' }}>
                          Select a merchant-created deal below to start curating this section. If you leave it empty, the mobile app can still fall back to automatic content.
                        </p>
                      </div>
                    ) : (
                      activeSection.assignments.map((assignment) => (
                        <div
                          key={assignment._id}
                          style={{
                            display: 'grid',
                            gridTemplateColumns: '72px 1fr auto',
                            gap: '0.9rem',
                            alignItems: 'center',
                            padding: '0.9rem',
                            borderRadius: '1rem',
                            background: 'var(--card-bg)',
                            border: '1px solid var(--border-color)',
                          }}
                        >
                          <div
                            style={{
                              width: '72px',
                              height: '72px',
                              borderRadius: '0.9rem',
                              overflow: 'hidden',
                              background: 'var(--light-gray)',
                              display: 'grid',
                              placeItems: 'center',
                            }}
                          >
                            {assignment.promotion?.image ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img
                                src={assignment.bannerImageUrl || assignment.promotion.image}
                                alt={assignment.promotion.title || 'Promotion'}
                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                              />
                            ) : (
                              <i className="fas fa-image" style={{ color: 'var(--text-secondary)' }}></i>
                            )}
                          </div>
                          <div>
                            <div className="flex items-center gap-2 flex-wrap" style={{ marginBottom: '0.25rem' }}>
                              <strong style={{ color: 'var(--text-primary)' }}>{assignment.promotion?.title || 'Unknown deal'}</strong>
                              <span className="status-chip">{assignment.status}</span>
                              <span className="status-chip" style={{ background: 'rgba(37,99,235,0.08)', color: 'var(--primary-color)' }}>
                                {assignment.mode.replace(/_/g, ' ')}
                              </span>
                            </div>
                            <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                              {assignment.promotion?.merchant?.name || 'Unknown merchant'} • Priority {assignment.priority}
                            </div>
                            <div style={{ color: 'var(--text-secondary)', fontSize: '0.8rem', marginTop: '0.35rem' }}>
                              Start: {fmtDate(assignment.startAt)} | End: {fmtDate(assignment.endAt)}
                            </div>
                          </div>
                          <button
                            onClick={() => handleDelete(assignment._id)}
                            style={{
                              border: '1px solid rgba(239,68,68,0.22)',
                              background: 'rgba(239,68,68,0.06)',
                              color: '#ef4444',
                              borderRadius: '0.75rem',
                              padding: '0.55rem 0.75rem',
                              cursor: 'pointer',
                              fontWeight: 700,
                            }}
                          >
                            Remove
                          </button>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                <div className="surface-panel panel-pad" style={{ boxShadow: 'none' }}>
                  <h3 style={{ marginTop: 0, marginBottom: '1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                    Assign Deal to {activeSection.label}
                  </h3>
                  <div style={{ display: 'grid', gap: '0.85rem' }}>
                    <div style={{ display: 'grid', gap: '0.75rem' }}>
                      <div style={{ marginBottom: '0.1rem', fontSize: '0.85rem', fontWeight: 700 }}>
                        Select Deal{selectedPromotionIds.length > 0 ? ` (${selectedPromotionIds.length} selected)` : ''}
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <div className="input-with-icon">
                          <i className="fas fa-search"></i>
                          <input
                            className="modern-input"
                            placeholder="Search by deal, merchant, or category"
                            value={promotionSearch}
                            onChange={(e) => setPromotionSearch(e.target.value)}
                          />
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                          <select
                            className="modern-select"
                            value={merchantFilter}
                            onChange={(e) => setMerchantFilter(e.target.value)}
                          >
                            <option value="all">All merchants</option>
                            {merchantOptions.map((merchantName) => (
                              <option key={merchantName} value={merchantName}>
                                {merchantName}
                              </option>
                            ))}
                          </select>
                          <select
                            className="modern-select"
                            value={promotionStatusFilter}
                            onChange={(e) => setPromotionStatusFilter(e.target.value)}
                          >
                            <option value="all">All statuses</option>
                            {promotionStatusOptions.map((status) => (
                              <option key={status} value={status}>
                                {status?.replace(/_/g, ' ')}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>

                      <div
                        style={{
                          maxHeight: '280px',
                          overflowY: 'auto',
                          display: 'grid',
                          gap: '0.7rem',
                          paddingRight: '0.2rem',
                        }}
                      >
                        {filteredPromotions.length === 0 ? (
                          <div
                            style={{
                              padding: '1rem',
                              borderRadius: '0.9rem',
                              border: '1px dashed var(--border-color)',
                              color: 'var(--text-secondary)',
                              textAlign: 'center',
                            }}
                          >
                            No promotions match your filters.
                          </div>
                        ) : (
                          filteredPromotions.slice(0, 30).map((promotion) => {
                            const promotionId = promotion._id || '';
                            const isSelected = selectedPromotionIds.includes(promotionId);
                            const alreadyAssigned = assignedPromotionIds.has(promotionId);
                            const assignedInCurrentSection = currentSectionAssignedPromotionIds.has(promotionId);

                            return (
                              <button
                                key={promotionId}
                                type="button"
                                onClick={() => togglePromotionSelection(promotionId)}
                                style={{
                                  textAlign: 'left',
                                  borderRadius: '1rem',
                                  border: isSelected
                                    ? '2px solid var(--primary-color)'
                                    : '1px solid var(--border-color)',
                                  background: isSelected
                                    ? 'rgba(37,99,235,0.06)'
                                    : 'var(--card-bg)',
                                  padding: '0.85rem',
                                  cursor: 'pointer',
                                  display: 'grid',
                                  gridTemplateColumns: '24px 56px 1fr',
                                  gap: '0.8rem',
                                  alignItems: 'center',
                                }}
                              >
                                <input
                                  type="checkbox"
                                  readOnly
                                  checked={isSelected}
                                  style={{ width: '16px', height: '16px', accentColor: 'var(--primary-color)' }}
                                />
                                <div
                                  style={{
                                    width: '56px',
                                    height: '56px',
                                    borderRadius: '0.85rem',
                                    overflow: 'hidden',
                                    background: 'var(--light-gray)',
                                    display: 'grid',
                                    placeItems: 'center',
                                  }}
                                >
                                  {promotion.image ? (
                                    // eslint-disable-next-line @next/next/no-img-element
                                    <img
                                      src={promotion.image}
                                      alt={promotion.title || 'Promotion'}
                                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                    />
                                  ) : (
                                    <i className="fas fa-image" style={{ color: 'var(--text-secondary)' }}></i>
                                  )}
                                </div>
                                <div>
                                  <div className="flex items-center gap-2 flex-wrap" style={{ marginBottom: '0.2rem' }}>
                                    <strong style={{ color: 'var(--text-primary)' }}>
                                      {promotion.title || 'Untitled deal'}
                                    </strong>
                                    {alreadyAssigned ? (
                                      <span
                                        className="status-chip"
                                        style={{
                                          background: 'rgba(245,158,11,0.1)',
                                          color: '#d97706',
                                        }}
                                      >
                                        {assignedInCurrentSection ? 'Already in this section' : 'Already in a section'}
                                      </span>
                                    ) : null}
                                  </div>
                                  <div style={{ color: 'var(--text-secondary)', fontSize: '0.84rem' }}>
                                    {promotion.merchant?.name || 'Unknown merchant'}
                                    {promotion.category ? ` • ${promotion.category}` : ''}
                                  </div>
                                  <div className="flex items-center gap-2 flex-wrap" style={{ marginTop: '0.35rem' }}>
                                    {promotion.discount ? (
                                      <span className="discount-badge" style={{ position: 'static', fontSize: '0.68rem' }}>
                                        {promotion.discount} OFF
                                      </span>
                                    ) : null}
                                    {promotion.status ? (
                                      <span className="status-chip">
                                        {promotion.status.replace(/_/g, ' ')}
                                      </span>
                                    ) : null}
                                  </div>
                                </div>
                              </button>
                            );
                          })
                        )}
                      </div>
                    </div>

                    {selectedPromotionIds.length > 0 ? (
                      <div
                        style={{
                          padding: '0.9rem 1rem',
                          borderRadius: '1rem',
                          border: '1px solid rgba(37,99,235,0.18)',
                          background: 'rgba(37,99,235,0.05)',
                        }}
                      >
                        <div style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--primary-color)', marginBottom: '0.35rem' }}>
                          Selected deals
                        </div>
                        <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>
                          {selectedPromotionIds.length === 1
                            ? (selectedPromotion?.title || '1 deal selected')
                            : `${selectedPromotionIds.length} deals selected`}
                        </div>
                        <div style={{ color: 'var(--text-secondary)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
                          {selectedPromotionIds.length === 1
                            ? `${selectedPromotion?.merchant?.name || 'Unknown merchant'}${selectedPromotion?.category ? ` • ${selectedPromotion.category}` : ''}${selectedPromotion?.status ? ` • ${selectedPromotion.status.replace(/_/g, ' ')}` : ''}`
                            : 'The same section settings will be applied to every selected deal.'}
                        </div>
                      </div>
                    ) : null}

                    <div className="grid grid-cols-2 gap-3">
                      <label>
                        <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Mode</div>
                        <select
                          className="modern-select"
                          value={form.mode}
                          onChange={(e) => setForm((current) => ({ ...current, mode: e.target.value }))}
                        >
                          {(MODE_OPTIONS[activeSection.key] || []).map((option) => (
                            <option key={option.value} value={option.value}>
                              {option.label}
                            </option>
                          ))}
                        </select>
                      </label>

                      <label>
                        <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Priority</div>
                        <input
                          className="modern-input"
                          type="number"
                          value={form.priority}
                          onChange={(e) => setForm((current) => ({ ...current, priority: Number(e.target.value) }))}
                        />
                      </label>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <label>
                        <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Start at</div>
                        <input
                          className="modern-input"
                          type="datetime-local"
                          value={form.startAt}
                          onChange={(e) => setForm((current) => ({ ...current, startAt: e.target.value }))}
                        />
                      </label>
                      <label>
                        <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>End at</div>
                        <input
                          className="modern-input"
                          type="datetime-local"
                          value={form.endAt}
                          onChange={(e) => setForm((current) => ({ ...current, endAt: e.target.value }))}
                        />
                      </label>
                    </div>

                    {activeSection.key === 'banner' ? (
                      <label>
                        <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Banner image override</div>
                        <input
                          className="modern-input"
                          placeholder="https://cdn.example.com/banner.jpg"
                          value={form.bannerImageUrl}
                          onChange={(e) => setForm((current) => ({ ...current, bannerImageUrl: e.target.value }))}
                        />
                      </label>
                    ) : null}

                    {['hot_deals', 'flash_sales'].includes(activeSection.key) ? (
                      <label style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', fontSize: '0.9rem', color: 'var(--text-primary)' }}>
                        <input
                          type="checkbox"
                          checked={form.excludeFromAuto}
                          onChange={(e) => setForm((current) => ({ ...current, excludeFromAuto: e.target.checked }))}
                        />
                        Exclude from auto-fill pool
                      </label>
                    ) : null}

                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', fontSize: '0.9rem', color: 'var(--text-primary)' }}>
                      <input
                        type="checkbox"
                        checked={form.enabled}
                        onChange={(e) => setForm((current) => ({ ...current, enabled: e.target.checked }))}
                      />
                      Enabled immediately
                    </label>

                    <button onClick={handleSave} disabled={saving} className="btn btn-primary" style={{ justifyContent: 'center' }}>
                      <i className="fas fa-save"></i>
                      {saving ? 'Saving...' : 'Save Assignment'}
                    </button>
                  </div>
                </div>
              </div>

              <div className="surface-panel panel-pad" style={{ boxShadow: 'none' }}>
                <h3 style={{ marginTop: 0, marginBottom: '1rem', fontWeight: 800, color: 'var(--text-primary)' }}>Operational Notes</h3>
                  <div style={{ display: 'grid', gap: '0.7rem', color: 'var(--text-secondary)' }}>
                    <div>Banner is manual-only and capped at five items. Use priority to control display order.</div>
                    <div>Hot Deals fills empty slots with trending deals when curated slots are not enough.</div>
                    <div>New This Week auto-includes fresh deals from the last seven days unless they are explicitly hidden.</div>
                    <div>Flash Sales can be curated manually, and the app can auto-fill with deals ending within the next 24 hours.</div>
                    <div>Banner image override is used by the mobile banner carousel when provided.</div>
                    <div>Deals that are not currently active can be assigned ahead of time, but they will not appear live until the promotion itself becomes active.</div>
                  </div>
              </div>
            </>
          ) : null}
        </div>
      </div>
    </div>
  );
}
