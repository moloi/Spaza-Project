// ─── Notification Types ───────────────────────────────────────────────────────

export type NotificationType = 'order' | 'compliance' | 'product' | 'system' | 'supplier';
export type NotificationPriority = 'low' | 'normal' | 'high' | 'urgent';
export type NotificationChannel = 'in_app' | 'email' | 'sms' | 'push';

export interface Notification {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  priority: NotificationPriority;
  isRead: boolean;
  isArchived: boolean;
  createdAt: string;
  readAt?: string;
  /** Optional deep-link path, e.g. "/orders/ORD-2025-0004" */
  actionUrl?: string;
  /** Metadata for display (order number, product name, etc.) */
  metadata?: Record<string, string>;
}

export interface AdminNotification extends Notification {
  sentTo: 'all' | 'suppliers' | 'spaza_owners' | 'specific';
  recipientCount?: number;
  sentBy?: string;
}

export interface NotificationPreferences {
  order: { inApp: boolean; email: boolean; sms: boolean };
  compliance: { inApp: boolean; email: boolean; sms: boolean };
  product: { inApp: boolean; email: boolean; sms: boolean };
  system: { inApp: boolean; email: boolean; sms: boolean };
}

// ─── API Request/Response ─────────────────────────────────────────────────────

export interface NotificationListParams {
  page?: number;
  pageSize?: number;
  type?: NotificationType;
  isRead?: boolean;
  priority?: NotificationPriority;
}

export interface NotificationListResponse {
  data: Notification[];
  total: number;
  unreadCount: number;
  page: number;
  pageSize: number;
}

export interface SendNotificationRequest {
  title: string;
  message: string;
  type: NotificationType;
  priority: NotificationPriority;
  sentTo: 'all' | 'suppliers' | 'spaza_owners' | 'specific';
  recipientIds?: string[];
  actionUrl?: string;
  channels?: NotificationChannel[];
}

// ─── SignalR Events ───────────────────────────────────────────────────────────

export interface SignalRNotificationEvent {
  notification: Notification;
}

export interface SignalRUnreadCountEvent {
  count: number;
}
