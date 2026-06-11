import { useState, useEffect } from 'react';
import { Bell, CheckCircle, AlertTriangle, ShoppingCart, Users, X, Send, Plus, Loader2, Wifi, WifiOff } from 'lucide-react';
import { format, isToday, isYesterday } from 'date-fns';
import clsx from 'clsx';
import toast from 'react-hot-toast';
import { useNotificationStore } from '../../store/notificationStore';
import { notificationsApi } from '../../services/notificationApi';
import type { Notification, NotificationType, NotificationPriority, SendNotificationRequest } from '../../types/notification';

const typeConfig: Record<NotificationType, { icon: React.ReactNode; color: string; bg: string }> = {
  system:     { icon: <Bell size={15} />,           color: 'text-slate-600',   bg: 'bg-slate-100' },
  compliance: { icon: <AlertTriangle size={15} />,  color: 'text-amber-600',   bg: 'bg-amber-100' },
  order:      { icon: <ShoppingCart size={15} />,   color: 'text-blue-600',    bg: 'bg-blue-100' },
  supplier:   { icon: <Users size={15} />,          color: 'text-emerald-600', bg: 'bg-emerald-100' },
  product:    { icon: <Bell size={15} />,           color: 'text-purple-600',  bg: 'bg-purple-100' },
};

function getDateLabel(d: string) {
  const date = new Date(d);
  if (isToday(date)) return 'Today';
  if (isYesterday(date)) return 'Yesterday';
  return format(date, 'EEEE, d MMMM');
}

interface ComposeState {
  title: string;
  message: string;
  type: NotificationType;
  priority: NotificationPriority;
  sentTo: 'all' | 'suppliers' | 'spaza_owners';
}

const initialCompose: ComposeState = {
  title: '',
  message: '',
  type: 'system',
  priority: 'normal',
  sentTo: 'all',
};

export default function AdminNotificationsPage() {
  const {
    notifications,
    unreadCount,
    isLoading,
    isConnected,
    hasMore,
    typeFilter,
    fetchNotifications,
    loadMore,
    markAsRead,
    markAllAsRead,
    archiveNotification,
    setTypeFilter,
  } = useNotificationStore();

  const [showCompose, setShowCompose] = useState(false);
  const [compose, setCompose] = useState<ComposeState>(initialCompose);
  const [isSending, setIsSending] = useState(false);

  useEffect(() => {
    fetchNotifications(true);
  }, []);

  const grouped = notifications.reduce<Record<string, Notification[]>>((acc, n) => {
    const label = getDateLabel(n.createdAt);
    if (!acc[label]) acc[label] = [];
    acc[label].push(n);
    return acc;
  }, {});

  const sendNotification = async () => {
    if (!compose.title.trim() || !compose.message.trim()) {
      toast.error('Title and message are required');
      return;
    }

    setIsSending(true);
    try {
      const payload: SendNotificationRequest = {
        title: compose.title,
        message: compose.message,
        type: compose.type,
        priority: compose.priority,
        sentTo: compose.sentTo,
        channels: ['in_app'],
      };

      await notificationsApi.send(payload);

      toast.success(
        `Notification sent to ${compose.sentTo === 'all' ? 'everyone' : compose.sentTo === 'suppliers' ? 'all suppliers' : 'spaza owners'}`
      );
      setShowCompose(false);
      setCompose(initialCompose);
      // Refresh the list to show the new notification
      fetchNotifications(true);
    } catch (error: any) {
      toast.error(error?.response?.data?.message ?? 'Failed to send notification');
    } finally {
      setIsSending(false);
    }
  };

  const typeFilters: { value: 'all' | NotificationType; label: string }[] = [
    { value: 'all',        label: 'All' },
    { value: 'system',     label: 'System' },
    { value: 'compliance', label: 'Compliance' },
    { value: 'order',      label: 'Orders' },
    { value: 'supplier',   label: 'Suppliers' },
  ];

  return (
    <div className="p-6 space-y-5 animate-in max-w-3xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="page-title">Notifications</h1>
          <p className="page-subtitle flex items-center gap-2">
            {unreadCount > 0 ? `${unreadCount} unread` : 'All caught up'}
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
          <button onClick={() => setShowCompose(true)} className="btn-primary flex items-center gap-2">
            <Plus size={15} /> Send Notification
          </button>
        </div>
      </div>

      {/* Type Filters */}
      <div className="flex items-center gap-1.5 flex-wrap">
        {typeFilters.map(({ value, label }) => (
          <button
            key={value}
            onClick={() => setTypeFilter(value as NotificationType | 'all')}
            className={clsx(
              'px-3 py-1.5 rounded-xl text-xs font-semibold transition-all border',
              typeFilter === value
                ? 'bg-slate-800 text-white border-slate-800'
                : 'bg-white text-gray-500 border-gray-200 hover:border-slate-400 hover:text-slate-700'
            )}
          >
            {label}
          </button>
        ))}
      </div>

      {/* Loading */}
      {isLoading && notifications.length === 0 && (
        <div className="card p-16 text-center">
          <Loader2 size={32} className="text-gray-300 mx-auto mb-3 animate-spin" />
          <p className="text-sm text-gray-400 font-medium">Loading notifications...</p>
        </div>
      )}

      {/* Notifications */}
      {!isLoading && Object.keys(grouped).length === 0 ? (
        <div className="card p-16 text-center">
          <Bell size={36} className="text-gray-200 mx-auto mb-4" />
          <p className="font-bold text-gray-600">No notifications</p>
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
                        !n.isRead && 'border-l-4 border-l-slate-700',
                        (n.priority === 'high' || n.priority === 'urgent') && !n.isRead && 'bg-amber-50/20'
                      )}
                    >
                      <div className={clsx('p-2.5 rounded-xl flex-shrink-0', config.bg, config.color)}>{config.icon}</div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex items-center gap-2 flex-wrap">
                            <p className={clsx('text-sm font-bold', !n.isRead ? 'text-gray-900' : 'text-gray-600')}>{n.title}</p>
                            {(n.priority === 'high' || n.priority === 'urgent') && !n.isRead && (
                              <span className="text-[10px] font-black bg-red-100 text-red-600 px-1.5 py-0.5 rounded-full">
                                {n.priority === 'urgent' ? 'URGENT' : 'HIGH'}
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-1.5 flex-shrink-0">
                            <p className="text-xs text-gray-400 whitespace-nowrap">{format(new Date(n.createdAt), 'HH:mm')}</p>
                            <button
                              onClick={(e) => { e.stopPropagation(); archiveNotification(n.id); }}
                              className="p-0.5 text-gray-300 hover:text-gray-500 transition-colors"
                              aria-label="Archive"
                            >
                              <X size={14} />
                            </button>
                          </div>
                        </div>
                        <p className="text-sm text-gray-500 mt-0.5 leading-relaxed">{n.message}</p>
                      </div>
                      {!n.isRead && <div className="w-2 h-2 rounded-full bg-slate-700 flex-shrink-0 mt-1.5 animate-pulse-soft" />}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}

          {/* Load More */}
          {hasMore && (
            <div className="text-center pt-2">
              <button onClick={loadMore} disabled={isLoading} className="btn-secondary text-sm inline-flex items-center gap-2">
                {isLoading ? <Loader2 size={14} className="animate-spin" /> : null}
                Load more
              </button>
            </div>
          )}
        </>
      )}

      {/* Compose Modal */}
      {showCompose && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setShowCompose(false)} />
          <div className="relative bg-white rounded-2xl shadow-card-xl w-full max-w-md animate-scale-in">
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
              <h2 className="font-bold text-gray-900">Send Platform Notification</h2>
              <button onClick={() => setShowCompose(false)} className="btn-icon"><X size={18} /></button>
            </div>
            <div className="p-6 space-y-4">
              {/* Send To */}
              <div>
                <label className="label">Send To</label>
                <div className="flex gap-2">
                  {([
                    { value: 'all', label: 'Everyone' },
                    { value: 'suppliers', label: 'Suppliers' },
                    { value: 'spaza_owners', label: 'Spaza Owners' },
                  ] as const).map(({ value, label }) => (
                    <button
                      key={value}
                      onClick={() => setCompose((c) => ({ ...c, sentTo: value }))}
                      className={clsx(
                        'flex-1 py-2 rounded-xl text-sm font-semibold border transition-all',
                        compose.sentTo === value
                          ? 'bg-slate-800 text-white border-slate-800'
                          : 'bg-white text-gray-500 border-gray-200 hover:border-slate-400'
                      )}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Type & Priority */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Type</label>
                  <select
                    value={compose.type}
                    onChange={(e) => setCompose((c) => ({ ...c, type: e.target.value as NotificationType }))}
                    className="input"
                  >
                    <option value="system">System</option>
                    <option value="order">Order</option>
                    <option value="compliance">Compliance</option>
                    <option value="product">Product</option>
                    <option value="supplier">Supplier</option>
                  </select>
                </div>
                <div>
                  <label className="label">Priority</label>
                  <select
                    value={compose.priority}
                    onChange={(e) => setCompose((c) => ({ ...c, priority: e.target.value as NotificationPriority }))}
                    className="input"
                  >
                    <option value="low">Low</option>
                    <option value="normal">Normal</option>
                    <option value="high">High</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </div>
              </div>

              {/* Title */}
              <div>
                <label className="label">Title</label>
                <input
                  value={compose.title}
                  onChange={(e) => setCompose((c) => ({ ...c, title: e.target.value }))}
                  className="input"
                  placeholder="Notification title..."
                  maxLength={100}
                />
              </div>

              {/* Message */}
              <div>
                <label className="label">Message</label>
                <textarea
                  value={compose.message}
                  onChange={(e) => setCompose((c) => ({ ...c, message: e.target.value }))}
                  className="input resize-none"
                  rows={3}
                  placeholder="Write your message..."
                  maxLength={500}
                />
                <p className="text-xs text-gray-400 mt-1 text-right">{compose.message.length}/500</p>
              </div>

              {/* Actions */}
              <div className="flex gap-3 justify-end pt-1">
                <button onClick={() => setShowCompose(false)} className="btn-secondary">Cancel</button>
                <button
                  onClick={sendNotification}
                  disabled={isSending}
                  className="bg-slate-800 hover:bg-slate-900 text-white px-4 py-2.5 rounded-xl font-semibold text-sm flex items-center gap-2 transition-all disabled:opacity-50"
                >
                  {isSending ? <Loader2 size={14} className="animate-spin" /> : <Send size={14} />}
                  {isSending ? 'Sending...' : 'Send Now'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
