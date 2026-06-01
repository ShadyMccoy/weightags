import { LoadStatus } from '../types';

interface StatusBadgeProps {
  status: LoadStatus;
}

// Status palette is built around three escalation registers:
//   - Calm / informational: draft, pending, resolved, invoiced
//   - Attention / amber: review (deltas above tolerance, needs human action)
//   - Alarm / red: disputed (active conflict)
// Goods-flow neutrals (warm browns/grays) carry the bookkeeping states;
// amber carries the "your eye should land here next" cases;
// red is reserved for the genuinely contentious state.
const statusConfig: Record<LoadStatus, { label: string; className: string }> = {
  draft: {
    label: 'Draft',
    className: 'bg-[#8b7d6b] text-white'
  },
  pending: {
    label: 'Pending Receiver',
    className: 'bg-[#d97706] text-white'
  },
  matched: {
    label: 'Matched',
    className: 'bg-[#059669] text-white'
  },
  review: {
    label: 'Review',
    className: 'bg-[#b45309] text-white'
  },
  disputed: {
    label: 'Disputed',
    className: 'bg-[#dc2626] text-white'
  },
  resolved: {
    label: 'Resolved',
    className: 'bg-[#0891b2] text-white'
  },
  invoiced: {
    label: 'Invoiced',
    className: 'bg-[#4f46e5] text-white'
  }
};

export function StatusBadge({ status }: StatusBadgeProps) {
  const config = statusConfig[status];
  
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${config.className}`}>
      {config.label}
    </span>
  );
}
