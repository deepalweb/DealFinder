export default function SkeletonCard() {
  return (
    <div className="skeleton-card">
      <div className="skeleton" style={{ height: '180px' }}></div>
      <div style={{ padding: '1rem' }}>
        <div className="skeleton mb-2" style={{ height: '12px', width: '40%' }}></div>
        <div className="skeleton mb-2" style={{ height: '16px', width: '80%' }}></div>
        <div className="skeleton mb-3" style={{ height: '12px', width: '60%' }}></div>
        <div className="skeleton" style={{ height: '36px' }}></div>
      </div>
    </div>
  );
}
