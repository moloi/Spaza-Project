import { useState } from 'react';
import { Bell, CheckCircle, ShoppingCart, AlertTriangle, Package, X, Settings, Filter } from 'lucide-react';
import { format, isToday, isYesterday } from 'date-fns';
import clsx from 'clsx';

type NotifType = 'order' | 'compliance' | 'product' | 'system';

interface Notification {
  id: string;
  type: NotifType;
  title: string;
  message: string;
  createdAt: string;
  read: boolean;
  priority?: 'high' | 'normal';
}

const mockNotifications: Notification[] = [
  { id: 'n1', type: 'order',      title: 'New Order Received',       message: "Mama's Spaza placed order ORD-2025-0004 for R1,450.00",                          createdAt: new Date(Date.now() - 1000 * 60 * 15).toISOString(),       read: false, priority: 'high' },
  { id: 'n2', type: 'order',      title: 'Order Delivered',          message: 'ORD-2025-0003 confirmed as delivered. Payment of R1,547.96 released.',            createdAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),  read: false },
  { id: 'n3', type: 'compliance', title: 'Document Expiring Soon',   message: 'Your Tax Clearance Certificate expires in 14 days. Please upload a renewed copy.', createdAt: new Date(Date.now() - 1000 * 60 * 60 * 5).toISOString(),  read: false, priority: 'high' },
  { id: 'n4', type: 'product',    title: 'Product Approved',         message: 'Sunflower Oil 2L has been approved and is now live on the marketplace.',           createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(), read: true },
  { id: 'n5', type: 'order',      title: 'Order Cancelled',          message: 'ORD-2025-0002 was cancelled by Zulu Corner Shop.',                                 createdAt: new Date(Date.now() - 1000 * 60 * 60 * 26).toISOString(), read: true },
  { id: 'n6', type: 'system',     title: 'Profile Verified',         message: 'Your supplier profile has been verified. You can now list unlimited products.',    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(), read: true },
  { id: 'n7', type: 'order',      title: 'New Order Received',       message: 'Ndlovu General placed order ORD-2025-0005 for R2,100.00',                          createdAt: new Date(Date.now() - 1000 * 60 * 60 * 50).toISOString(), read: true },
  { id: 'n8', type: 'compliance', title: 'BEE Certificate Pending',  message: 'Your BEE Certificate is under review. Expected completion: 2 business days.',     createdAt: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString(), read: true },
];

const typeConfig: Record<NotifType, { icon: React.ReactNode; color: string; bg: string }> = {
  order:      { icon: <ShoppingCart size={16} />,   color: 'text-blue-600',   bg: 'bg-blue-100' },
  compliance: { icon: <AlertTriangle size={16} />,  color: 'text-amber-600',  bg: 'bg-amber-100' },
  product:    { icon: <Package size={16} />,        color: 'text-emerald-600', bg: 'bg-emerald-100' },
  system:     { icon: <Bell size={16} />,           color: 'text-gray-600',   bg: 'bg-gray-100' },
};

const typeFilters: { value: string; label: string }[] = [
  { value: 'all',        label: 'All' },
  { value: 'order',      label: 'Orders' },
  { value: 'compliance', label: 'Compliance' },
  { value: 'product',    label: 'Products' },
  { value: 'system',     label: 'System' },
];

function getDateLabel(dateStr: string): string {
  const date = new Date(dateStr);
  if (isToday(date)) return 'Today';
  if (isYesterday(date)) return 'Yesterday';
  return format(date, 'EEEE, d MMMM');
}

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>(mockNotifications);
  const [readFilter, setReadFilter] = useState<'all' | 'unread'>('all');
  const [typeFilter, setTypeFilter] = useState('all');

  const markAllRead = () => setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  const dismiss = (id: string) => setNotifications((prev) => prev.filter((n) => n.id !== id));
  const markRead = (id: string) => setNotifications((prev) => prev.map((n) => n.id === id ? { ...n, read: true } : n));

  const filtered = notifications.filter((n) => {
    const matchRead = readFilter === 'all' || !n.read;
    const matchType = typeFilter === 'all' || n.type === typeFilter;
    return matchRead && matchType;
  });

  const unreadCount = notifications.filter((n) => !n.read).length;
  const highPriorityCount = notifications.filter((n) => !n.read && n.priority === 'high').length;

  // Group by date
  const grouped = filtered.reduce<Record<string, Notification[]>>((acc, n) => {
    const label = getDateLabel(n.createdAt);
    if (!acc[label]) acc[label] = [];
    acc[label].push(n);
    return acc;
  }, {});

  return (
    <div className="p-6 space-y-5 animate-in max-w-3xl">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Notifications</h1>
          <p className="page-subtitle">
            {unreadCount > 0 ? `${unreadCount} unread notification${unreadCount !== 1 ? 's' : ''}` : 'All caught up!'}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {unreadCount > 0 && (
            <button onClick={markAllRead} className="btn-secondary text-sm flex items-center gap-1.5">
              <CheckCircle size={14} /> Mark all read
            </button>
          )}
          <button className="btn-icon">
            <Settings size={16} />
          </button>
        </div>
      </div>

      {/* High Priority Alert */}
      {highPriorityCount > 0 && (
        <div className="warning-box flex items-center gap-3">
          <AlertTriangle size={16} className="text-amber-600 flex-shrink-0" />
          <p>You have <strong>{highPriorityCount} high-priority</strong> notification{highPriorityCount !== 1 ? 's' : ''} that require your attention.</p>
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        {/* Read filter */}
        <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
          {(['all', 'unread'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setReadFilter(f)}
              className={clsx(
                'px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all',
                readFilter === f ? 'bg-primary text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'
              )}
            >
              {f}
              {f === 'unread' && unreadCount > 0 && (
                <span className={clsx('ml-1.5 text-[10px] font-black px-1.5 py-0.5 rounded-full',
                  readFilter === 'unread' ? 'bg-white text-primary' : 'bg-primary text-white'
                )}>
                  {unreadCount}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Type filter */}
        <div className="flex items-center gap-1.5 flex-wrap">
          <Filter size={14} className="text-gray-400" />
          {typeFilters.map(({ value, label }) => (
            <button
              key={value}
              onClick={() => setTypeFilter(value)}
              className={clsx(
                'px-3 py-1.5 rounded-xl text-xs font-semibold transition-all border',
                typeFilter === value
                  ? 'bg-primary text-white border-primary'
                  : 'bg-white text-gray-500 border-gray-200 hover:border-primary hover:text-primary'
              )}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Notifications grouped by date */}
      {Object.keys(grouped).length === 0 ? (
        <div className="card p-16 text-center">
          <Bell size={36} className="text-gray-200 mx-auto mb-4" />
          <p className="font-bold text-gray-600">No notifications</p>
          <p className="text-gray-400 text-sm mt-1">You're all caught up! 🎉</p>
        </div>
      ) : (
        Object.entries(grouped).map(([dateLabel, items]) => (
          <div key={dateLabel}>
            <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 px-1">{dateLabel}</p>
            <div className="space-y-2">
              {items.map((n) => {
                const { icon, color, bg } = typeConfig[n.type];
                return (
                  <div
                    key={n.id}
                    onClick={() => markRead(n.id)}
                    className={clsx(
                      'card p-4 flex items-start gap-4 cursor-pointer hover:shadow-card-hover transition-all duration-200',
                      !n.read && 'border-l-4 border-l-primary',
                      n.priority === 'high' && !n.read && 'bg-amber-50/30'
                    )}
                  >
                    <div className={clsx('p-2.5 rounded-xl flex-shrink-0', bg, color)}>
                      {icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-center gap-2 flex-wrap">
                          <p className={clsx('text-sm font-bold', !n.read ? 'text-gray-900' : 'text-gray-600')}>
                            {n.title}
                          </p>
                          {n.priority === 'high' && !n.read && (
                            <span className="text-[10px] font-black bg-red-100 text-red-600 px-1.5 py-0.5 rounded-full">URGENT</span>
                          )}
                        </div>
                        <div className="flex items-center gap-1.5 flex-shrink-0">
                          <p className="text-xs text-gray-400 whitespace-nowrap">
                            {format(new Date(n.createdAt), 'HH:mm')}
                          </p>
                          <button
                            onClick={(e) => { e.stopPropagation(); dismiss(n.id); }}
                            className="p-0.5 text-gray-300 hover:text-gray-500 transition-colors"
                          >
                            <X size={14} />
                          </button>
                        </div>
                      </div>
                      <p className="text-sm text-gray-500 mt-0.5 leading-relaxed">{n.message}</p>
                    </div>
                    {!n.read && (
                      <div className="w-2 h-2 rounded-full bg-primary flex-shrink-0 mt-1.5 animate-pulse-soft" />
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        ))
      )}
    </div>
  );
}
