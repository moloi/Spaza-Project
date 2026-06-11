import { useEffect, useRef } from 'react';
import { useNotificationStore } from '../store/notificationStore';
import { useAuthStore } from '../store/authStore';

/**
 * useNotifications Hook
 * 
 * Initializes the notification system:
 * - Fetches initial notifications from the API
 * - Connects to SignalR for real-time updates
 * - Cleans up on unmount or logout
 * 
 * Place this once at a high level (e.g., AppLayout/AdminLayout).
 */
export function useNotifications() {
  const user = useAuthStore((s) => s.user);
  const {
    notifications,
    unreadCount,
    isLoading,
    isConnected,
    fetchNotifications,
    fetchUnreadCount,
    connectRealtime,
    disconnectRealtime,
  } = useNotificationStore();

  const initialized = useRef(false);

  useEffect(() => {
    if (!user?.token) {
      // No user — disconnect and reset
      disconnectRealtime();
      initialized.current = false;
      return;
    }

    if (initialized.current) return;
    initialized.current = true;

    // Fetch initial data + connect SignalR
    fetchNotifications();
    fetchUnreadCount();
    connectRealtime();

    return () => {
      disconnectRealtime();
      initialized.current = false;
    };
  }, [user?.token]);

  // Periodically refresh unread count as a fallback (every 60s)
  useEffect(() => {
    if (!user?.token) return;

    const interval = setInterval(() => {
      fetchUnreadCount();
    }, 60_000);

    return () => clearInterval(interval);
  }, [user?.token]);

  return {
    notifications,
    unreadCount,
    isLoading,
    isConnected,
  };
}

export default useNotifications;
