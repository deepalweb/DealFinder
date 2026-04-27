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
  promotionId: string;
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
  nearby: 'Nearby',
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
  nearby: [
    { value: 'boosted', label: 'Boost' },
    { value: 'hidden', label: 'Hide' },
  ],
};

const emptyForm: SectionForm = {
  promotionId: '',
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
  const [loading, setLoading] = useState(true);
  const [activeSectionKey, setActiveSectionKey] = useState('banner');
  const [form, setForm] = useState<SectionForm>({ ...emptyForm });
  const [saving, setSaving] = useState(false);
  const [publishing, setPublishing] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const [sectionData, conflictData] = await Promise.all([
        AdminAPI.getSections(),
        AdminAPI.getSectionConflicts(),
      ]);
      setSections(sectionData || []);
      setConflicts(conflictData || []);
      const firstKey = (sectionData?.[0]?.key as string | undefined) || 'banner';
      setActiveSectionKey((current) =>
        sectionData?.some((section: Section) => section.key === current) ? current : firstKey
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

  useEffect(() => {
    const nextMode = MODE_OPTIONS[activeSectionKey]?.[0]?.value || 'manual';
    setForm({
      ...emptyForm,
      mode: nextMode,
    });
  }, [activeSectionKey]);

  function getErrorMessage(error: unknown, fallback: string) {
    if (error instanceof Error && error.message) return error.message;
    return fallback;
  }

  const handleSave = async () => {
    if (!activeSection) return;
    if (!form.promotionId.trim()) {
      toast.error('Promotion ID is required.');
      return;
    }

    setSaving(true);
    try {
      await AdminAPI.saveSectionAssignment({
        sectionKey: activeSection.key,
        promotionId: form.promotionId.trim(),
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

  return (
    <div style={{ display: 'grid', gap: '1.25rem' }}>
      <div className="surface-panel panel-pad">
        <div className="flex items-center justify-between gap-4 flex-wrap">
          <div>
            <h1 style={{ fontSize: '1.75rem', fontWeight: 800, margin: 0, color: 'var(--text-primary)' }}>
              Section Manager
            </h1>
            <p style={{ margin: '0.35rem 0 0', color: 'var(--text-secondary)' }}>
              Curate banner, hot deals, new-this-week, and nearby without touching the all-deals feed.
            </p>
          </div>
          <button
            onClick={handlePublish}
            disabled={publishing}
            className="btn btn-primary"
            style={{ minWidth: '180px', justifyContent: 'center' }}
          >
            <i className="fas fa-cloud-upload-alt"></i>
            {publishing ? 'Publishing...' : 'Publish Changes'}
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
                          Add a promotion ID below to start curating this section.
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
                    <label>
                      <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Promotion ID</div>
                      <input
                        className="modern-input"
                        placeholder="Paste Mongo promotion ID"
                        value={form.promotionId}
                        onChange={(e) => setForm((current) => ({ ...current, promotionId: e.target.value }))}
                      />
                    </label>

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

                    {activeSection.key === 'nearby' ? (
                      <div className="grid grid-cols-3 gap-3">
                        <label>
                          <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Radius km</div>
                          <input
                            className="modern-input"
                            type="number"
                            value={form.radiusKm}
                            onChange={(e) => setForm((current) => ({ ...current, radiusKm: e.target.value }))}
                          />
                        </label>
                        <label>
                          <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Min km</div>
                          <input
                            className="modern-input"
                            type="number"
                            value={form.minDistanceKm}
                            onChange={(e) => setForm((current) => ({ ...current, minDistanceKm: e.target.value }))}
                          />
                        </label>
                        <label>
                          <div style={{ marginBottom: '0.35rem', fontSize: '0.85rem', fontWeight: 700 }}>Max km</div>
                          <input
                            className="modern-input"
                            type="number"
                            value={form.maxDistanceKm}
                            onChange={(e) => setForm((current) => ({ ...current, maxDistanceKm: e.target.value }))}
                          />
                        </label>
                      </div>
                    ) : null}

                    {activeSection.key === 'hot_deals' ? (
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
                  <div>Nearby only boosts ranking within geo results. It does not bypass location relevance.</div>
                </div>
              </div>
            </>
          ) : null}
        </div>
      </div>
    </div>
  );
}
