import { useEffect } from 'react';
import { Bell, CheckCircle, ShoppingCart, AlertTriangle, Package, X, Settings, Filter, Loader2, Wifi, WifiOff } from 'lucide-react';
import { format, isToday, isYesterday } from 'date-fns';
import clsx from 'clsx';
import { useNotificationStore } from '../../store/notificationStore';
import type { Notification, NotificationType } from '../../types/notification';

const typeConfig: Record<NotificationType, { icon: React.ReactNode; color: string; bg: string }> = {
  order:      { icon: <ShoppingCart size={16} />,   color: 'text-blue-600',    bg: 'bg-blue-100' },
  compliance: { icon: <AlertTriangle size={16} />,  color: 'text-amber-600',   bg: 'bg-amber-100' },
  product:    { icon: <Package size={16} />,        color: 'text-emerald-600', bg: 'bg-emerald-100' },
  system:     { icon: <Bell size={16} />,           color: 'text-gray-600',    bg: 'bg-gray-100' },
  supplier:   { icon: <Bell size={16} />,           color: 'text-purple-600',  bg: 'bg-purple-100' },
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
  const {
    notifications,
    unreadCount,
    isLoading,
    isConnected,
    hasMore,
    typeFilter,
    readFilter,
    fetchNotifications,
    loadMore,
    markAsRead,
    markAllAsRead,
    archiveNotification,
    setTypeFilter,
    setReadFilter,
  } = useNotificationStore();

  // Fetch on mount
  useEffect(() => {
    fetchNotifications(true);
  }, []);

  const highPriorityCount = notifications.filter(
    (n) => !n.isRead && (n.priority === 'high' || n.priority === 'urgent')
  ).length;

  // Group by date
  const grouped = notifications.reduce<Record<string, Notification[]>>((acc, n) => {
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
          <p className="page-subtitle flex items-center gap-2">
            {unreadCount > 0 ? `${unreadCount} unread notification${unreadCount !== 1 ? 's' : ''}` : 'All caught up!'}
            <span title={isConnected ? 'Live updates active' : 'Reconnecting...'}>
              {isConnected ? (
                <Wifi size={13} className="text-emerald-500" />
              ) : (
                <WifiOff size={13} className="text-gray-300" />
              )}
            </span>
          </p>
        </div>
        <div className="flex items-center gap-2">
          {unreadCount > 0 && (
            <button onClick={markAllAsRead} className="btn-secondary text-sm flex items-center gap-1.5">
              <CheckCircle size={14} /> Mark all read
            </button>
          )}
          <button className="btn-icon" aria-label="Notification settings">
            <Settings size={16} />
          </button>
        </div>
      </div>

      {/* High Priority Alert */}
      {highPriorityCount > 0 && (
        <div className="warning-box flex items-center gap-3">
          <AlertTriangle size={16} className="text-amber-600 flex-shrink-0" />
          <p>
            You have <strong>{highPriorityCount} high-priority</strong> notification{highPriorityCount !== 1 ? 's' : ''} that require your attention.
          </p>
        </div>
      )}

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        {/* Read filter */}
        <div className="flex items-center gap-0.5 bg-white border border-gray-200 rounded-xl p-1">
          {(['all', 'unread', 'read'] as const).map((f) => (
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
                <span
                  className={clsx(
                    'ml-1.5 text-[10px] font-black px-1.5 py-0.5 rounded-full',
                    readFilter === 'unread' ? 'bg-white text-primary' : 'bg-primary text-white'
                  )}
                >
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
              onClick={() => setTypeFilter(value as NotificationType | 'all')}
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

      {/* Loading State */}
      {isLoading && notifications.length === 0 && (
        <div className="card p-16 text-center">
          <Loader2 size={32} className="text-gray-300 mx-auto mb-3 animate-spin" />
          <p className="text-sm text-gray-400 font-medium">Loading notifications...</p>
        </div>
      )}

      {/* Notifications grouped by date */}
      {!isLoading && Object.keys(grouped).length === 0 ? (
        <div className="card p-16 text-center">
          <Bell size={36} className="text-gray-200 mx-auto mb-4" />
          <p className="font-bold text-gray-600">No notifications</p>
          <p className="text-gray-400 text-sm mt-1">You're all caught up! 🎉</p>
        </div>
      ) : (
        <>
          {Object.entries(grouped).map(([dateLabel, items]) => (
            <div key={dateLabel}>
              <p className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2 px-1">{dateLabel}</p>
              <div className="space-y-2">
                {items.map((n) => {
                  const config = typeConfig[n.type] ?? typeConfig.system;
                  return (
                    <div
                      key={n.id}
                      onClick={() => !n.isRead && markAsRead(n.id)}
                      className={clsx(
                        'card p-4 flex items-start gap-4 cursor-pointer hover:shadow-card-hover transition-all duration-200',
                        !n.isRead && 'border-l-4 border-l-primary',
                        (n.priority === 'high' || n.priority === 'urgent') && !n.isRead && 'bg-amber-50/30'
                      )}
                    >
                      <div className={clsx('p-2.5 rounded-xl flex-shrink-0', config.bg, config.color)}>
                        {config.icon}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex items-center gap-2 flex-wrap">
                            <p className={clsx('text-sm font-bold', !n.isRead ? 'text-gray-900' : 'text-gray-600')}>
                              {n.title}
                            </p>
                            {(n.priority === 'high' || n.priority === 'urgent') && !n.isRead && (
                              <span className="text-[10px] font-black bg-red-100 text-red-600 px-1.5 py-0.5 rounded-full">
                                {n.priority === 'urgent' ? 'URGENT' : 'HIGH'}
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-1.5 flex-shrink-0">
                            <p className="text-xs text-gray-400 whitespace-nowrap">
                              {format(new Date(n.createdAt), 'HH:mm')}
                            </p>
                            <button
                              onClick={(e) => { e.stopPropagation(); archiveNotification(n.id); }}
                              className="p-0.5 text-gray-300 hover:text-gray-500 transition-colors"
                              aria-label="Archive notification"
                            >
                              <X size={14} />
                            </button>
                          </div>
                        </div>
                        <p className="text-sm text-gray-500 mt-0.5 leading-relaxed">{n.message}</p>
                      </div>
                      {!n.isRead && (
                        <div className="w-2 h-2 rounded-full bg-primary flex-shrink-0 mt-1.5 animate-pulse-soft" />
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}

          {/* Load More */}
          {hasMore && (
            <div className="text-center pt-2">
              <button
                onClick={loadMore}
                disabled={isLoading}
                className="btn-secondary text-sm inline-flex items-center gap-2"
              >
                {isLoading ? <Loader2 size={14} className="animate-spin" /> : null}
                Load more
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
