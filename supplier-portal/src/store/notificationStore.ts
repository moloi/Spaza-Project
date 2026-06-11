import { create } from 'zustand';
import { HubConnectionState } from '@microsoft/signalr';
import { signalRService } from '../services/signalr';
import { notificationsApi } from '../services/notificationApi';
import type {
  Notification,
  NotificationType,
  NotificationPriority,
} from '../types/notification';
import toast from 'react-hot-toast';

// ─── Store Interface ──────────────────────────────────────────────────────────

interface NotificationState {
  // Data
  notifications: Notification[];
  unreadCount: number;
  total: number;
  page: number;
  pageSize: number;

  // UI State
  isLoading: boolean;
  isConnected: boolean;
  hasMore: boolean;

  // Filters
  typeFilter: NotificationType | 'all';
  readFilter: 'all' | 'unread' | 'read';

  // Actions
  fetchNotifications: (reset?: boolean) => Promise<void>;
  fetchUnreadCount: () => Promise<void>;
  loadMore: () => Promise<void>;
  markAsRead: (id: string) => Promise<void>;
  markAllAsRead: () => Promise<void>;
  archiveNotification: (id: string) => Promise<void>;
  deleteNotification: (id: string) => Promise<void>;
  setTypeFilter: (type: NotificationType | 'all') => void;
  setReadFilter: (filter: 'all' | 'unread' | 'read') => void;

  // SignalR lifecycle
  connectRealtime: () => Promise<void>;
  disconnectRealtime: () => Promise<void>;

  // Internal
  _addNotification: (notification: Notification) => void;
}

// ─── Store Implementation ─────────────────────────────────────────────────────

export const useNotificationStore = create<NotificationState>((set, get) => ({
  // Initial state
  notifications: [],
  unreadCount: 0,
  total: 0,
  page: 1,
  pageSize: 20,
  isLoading: false,
  isConnected: false,
  hasMore: true,
  typeFilter: 'all',
  readFilter: 'all',

  // ─── Fetch Notifications ──────────────────────────────────────────────────

  fetchNotifications: async (reset = true) => {
    const { typeFilter, readFilter, pageSize } = get();
    set({ isLoading: true });

    try {
      const params: any = { page: 1, pageSize };
      if (typeFilter !== 'all') params.type = typeFilter;
      if (readFilter === 'unread') params.isRead = false;
      if (readFilter === 'read') params.isRead = true;

      const response = await notificationsApi.list(params);

      set({
        notifications: response.data,
        unreadCount: response.unreadCount,
        total: response.total,
        page: 1,
        hasMore: response.data.length < response.total,
        isLoading: false,
      });
    } catch (error) {
      set({ isLoading: false });
      // Silently fail — notifications shouldn't block the app
      if (import.meta.env.DEV) console.error('Failed to fetch notifications:', error);
    }
  },

  fetchUnreadCount: async () => {
    try {
      const count = await notificationsApi.getUnreadCount();
      set({ unreadCount: count });
    } catch {
      // Silent fail
    }
  },

  loadMore: async () => {
    const { page, pageSize, typeFilter, readFilter, notifications, total } = get();
    if (notifications.length >= total) return;

    set({ isLoading: true });
    try {
      const nextPage = page + 1;
      const params: any = { page: nextPage, pageSize };
      if (typeFilter !== 'all') params.type = typeFilter;
      if (readFilter === 'unread') params.isRead = false;
      if (readFilter === 'read') params.isRead = true;

      const response = await notificationsApi.list(params);

      set({
        notifications: [...notifications, ...response.data],
        page: nextPage,
        hasMore: notifications.length + response.data.length < response.total,
        isLoading: false,
      });
    } catch {
      set({ isLoading: false });
    }
  },

  // ─── Actions ──────────────────────────────────────────────────────────────

  markAsRead: async (id: string) => {
    // Optimistic update
    set((state) => ({
      notifications: state.notifications.map((n) =>
        n.id === id ? { ...n, isRead: true, readAt: new Date().toISOString() } : n
      ),
      unreadCount: Math.max(0, state.unreadCount - 1),
    }));

    try {
      await notificationsApi.markAsRead(id);
    } catch {
      // Revert on failure
      set((state) => ({
        notifications: state.notifications.map((n) =>
          n.id === id ? { ...n, isRead: false, readAt: undefined } : n
        ),
        unreadCount: state.unreadCount + 1,
      }));
    }
  },

  markAllAsRead: async () => {
    const prevNotifications = get().notifications;
    const prevUnread = get().unreadCount;

    // Optimistic update
    set((state) => ({
      notifications: state.notifications.map((n) => ({
        ...n,
        isRead: true,
        readAt: n.readAt ?? new Date().toISOString(),
      })),
      unreadCount: 0,
    }));

    try {
      await notificationsApi.markAllAsRead();
    } catch {
      // Revert on failure
      set({ notifications: prevNotifications, unreadCount: prevUnread });
    }
  },

  archiveNotification: async (id: string) => {
    const prev = get().notifications;

    set((state) => ({
      notifications: state.notifications.filter((n) => n.id !== id),
      total: state.total - 1,
    }));

    try {
      await notificationsApi.archive(id);
    } catch {
      set({ notifications: prev, total: prev.length });
    }
  },

  deleteNotification: async (id: string) => {
    const prev = get().notifications;
    const wasUnread = prev.find((n) => n.id === id)?.isRead === false;

    set((state) => ({
      notifications: state.notifications.filter((n) => n.id !== id),
      total: state.total - 1,
      unreadCount: wasUnread ? state.unreadCount - 1 : state.unreadCount,
    }));

    try {
      await notificationsApi.delete(id);
    } catch {
      set({ notifications: prev, total: prev.length });
    }
  },

  // ─── Filters ──────────────────────────────────────────────────────────────

  setTypeFilter: (type) => {
    set({ typeFilter: type });
    get().fetchNotifications(true);
  },

  setReadFilter: (filter) => {
    set({ readFilter: filter });
    get().fetchNotifications(true);
  },

  // ─── SignalR Real-Time ────────────────────────────────────────────────────

  connectRealtime: async () => {
    // Register handlers BEFORE starting connection
    signalRService.on<Notification>('ReceiveNotification', (notification) => {
      get()._addNotification(notification);

      // Show toast for high-priority notifications
      if (notification.priority === 'high' || notification.priority === 'urgent') {
        toast(notification.title, {
          icon: notification.priority === 'urgent' ? '🚨' : '🔔',
          duration: 5000,
        });
      }
    });

    signalRService.on<{ count: number }>('UnreadCountUpdated', ({ count }) => {
      set({ unreadCount: count });
    });

    signalRService.on<{ id: string }>('NotificationRead', ({ id }) => {
      set((state) => ({
        notifications: state.notifications.map((n) =>
          n.id === id ? { ...n, isRead: true } : n
        ),
      }));
    });

    // Track connection state
    signalRService.onStateChange((state) => {
      const connected = state === HubConnectionState.Connected;
      set({ isConnected: connected });
    });

    try {
      await signalRService.start();
      set({ isConnected: true });
    } catch {
      set({ isConnected: false });
    }
  },

  disconnectRealtime: async () => {
    signalRService.off('ReceiveNotification');
    signalRService.off('UnreadCountUpdated');
    signalRService.off('NotificationRead');
    await signalRService.stop();
    set({ isConnected: false });
  },

  // ─── Internal ─────────────────────────────────────────────────────────────

  _addNotification: (notification: Notification) => {
    set((state) => {
      // Avoid duplicates
      if (state.notifications.some((n) => n.id === notification.id)) return state;

      return {
        notifications: [notification, ...state.notifications],
        unreadCount: notification.isRead ? state.unreadCount : state.unreadCount + 1,
        total: state.total + 1,
      };
    });
  },
}));

export default useNotificationStore;
