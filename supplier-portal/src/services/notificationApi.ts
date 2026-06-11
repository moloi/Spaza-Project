import api from './api';
import type {
  Notification,
  NotificationListParams,
  NotificationListResponse,
  NotificationPreferences,
  SendNotificationRequest,
} from '../types/notification';

/**
 * Notification API Service
 * Communicates with the NotificationService backend endpoints.
 */

function mapNotification(raw: any): Notification {
  return {
    id: raw.id,
    type: raw.type ?? 'system',
    title: raw.title ?? '',
    message: raw.message ?? raw.body ?? '',
    priority: raw.priority ?? 'normal',
    isRead: raw.isRead ?? raw.read ?? false,
    isArchived: raw.isArchived ?? false,
    createdAt: raw.createdAt ?? new Date().toISOString(),
    readAt: raw.readAt ?? undefined,
    actionUrl: raw.actionUrl ?? undefined,
    metadata: raw.metadata ?? undefined,
  };
}

export const notificationsApi = {
  /** Get paginated notifications for the current user */
  list: async (params?: NotificationListParams): Promise<NotificationListResponse> => {
    const res = await api.get('/notifications', { params });
    const d = res.data?.data ?? res.data;
    const items = (d?.items ?? d?.data ?? d ?? []).map(mapNotification);
    return {
      data: items,
      total: d?.total ?? items.length,
      unreadCount: d?.unreadCount ?? items.filter((n: Notification) => !n.isRead).length,
      page: d?.page ?? params?.page ?? 1,
      pageSize: d?.pageSize ?? params?.pageSize ?? 20,
    };
  },

  /** Get a single notification by ID */
  get: async (id: string): Promise<Notification> => {
    const res = await api.get(`/notifications/${id}`);
    return mapNotification(res.data?.data ?? res.data);
  },

  /** Get unread count */
  getUnreadCount: async (): Promise<number> => {
    const res = await api.get('/notifications/unread-count');
    return res.data?.data ?? res.data?.count ?? res.data ?? 0;
  },

  /** Mark a single notification as read */
  markAsRead: async (id: string): Promise<void> => {
    await api.patch(`/notifications/${id}/read`);
  },

  /** Mark all notifications as read */
  markAllAsRead: async (): Promise<void> => {
    await api.patch('/notifications/read-all');
  },

  /** Archive a notification (soft delete) */
  archive: async (id: string): Promise<void> => {
    await api.patch(`/notifications/${id}/archive`);
  },

  /** Delete a notification permanently */
  delete: async (id: string): Promise<void> => {
    await api.delete(`/notifications/${id}`);
  },

  /** Get notification preferences */
  getPreferences: async (): Promise<NotificationPreferences> => {
    const res = await api.get('/notifications/preferences');
    return res.data?.data ?? res.data;
  },

  /** Update notification preferences */
  updatePreferences: async (prefs: Partial<NotificationPreferences>): Promise<void> => {
    await api.put('/notifications/preferences', prefs);
  },

  // ─── Admin Endpoints ────────────────────────────────────────────────────────

  /** Send a notification (admin only) */
  send: async (data: SendNotificationRequest): Promise<void> => {
    await api.post('/admin/notifications/send', data);
  },

  /** Get all platform notifications with admin metadata */
  listAdmin: async (params?: NotificationListParams): Promise<NotificationListResponse> => {
    const res = await api.get('/admin/notifications', { params });
    const d = res.data?.data ?? res.data;
    const items = (d?.items ?? d?.data ?? d ?? []).map(mapNotification);
    return {
      data: items,
      total: d?.total ?? items.length,
      unreadCount: d?.unreadCount ?? 0,
      page: d?.page ?? params?.page ?? 1,
      pageSize: d?.pageSize ?? params?.pageSize ?? 20,
    };
  },
};

export default notificationsApi;
