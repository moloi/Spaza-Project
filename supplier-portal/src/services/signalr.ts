import * as signalR from '@microsoft/signalr';
import env from '../config/env';

/**
 * SignalR Connection Manager
 * Manages the WebSocket connection to the NotificationHub
 * with automatic reconnection and token refresh support.
 */

type ConnectionEventHandler = (state: signalR.HubConnectionState) => void;

class SignalRService {
  private connection: signalR.HubConnection | null = null;
  private connectionStateHandlers: ConnectionEventHandler[] = [];
  private isStarting = false;

  /** Build the hub URL from the API base (strip /api suffix, add /hubs/notifications) */
  private get hubUrl(): string {
    const base = env.apiUrl.replace(/\/api\/?$/, '');
    return `${base}/hubs/notifications`;
  }

  /** Get token from localStorage (same pattern as api.ts) */
  private getAccessToken(): string {
    try {
      const stored = localStorage.getItem('spazasure-auth-v2');
      if (stored) {
        const { state } = JSON.parse(stored);
        return state?.user?.token ?? '';
      }
    } catch {}
    return '';
  }

  /** Create and configure the connection */
  private createConnection(): signalR.HubConnection {
    const connection = new signalR.HubConnectionBuilder()
      .withUrl(this.hubUrl, {
        accessTokenFactory: () => this.getAccessToken(),
        transport: signalR.HttpTransportType.WebSockets | signalR.HttpTransportType.ServerSentEvents,
        withCredentials: false,
      })
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: (retryContext) => {
          // Exponential backoff: 1s, 2s, 4s, 8s, 16s, then cap at 30s
          const delay = Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 30000);
          return delay;
        },
      })
      .configureLogging(env.enableDebug ? signalR.LogLevel.Information : signalR.LogLevel.Warning)
      .build();

    // Connection lifecycle events
    connection.onreconnecting(() => {
      if (env.enableDebug) console.log('🔄 SignalR reconnecting...');
      this.notifyStateChange(signalR.HubConnectionState.Reconnecting);
    });

    connection.onreconnected(() => {
      if (env.enableDebug) console.log('✅ SignalR reconnected');
      this.notifyStateChange(signalR.HubConnectionState.Connected);
    });

    connection.onclose(() => {
      if (env.enableDebug) console.log('❌ SignalR disconnected');
      this.notifyStateChange(signalR.HubConnectionState.Disconnected);
    });

    return connection;
  }

  /** Start the connection */
  async start(): Promise<void> {
    if (this.isStarting) return;
    if (this.connection?.state === signalR.HubConnectionState.Connected) return;

    this.isStarting = true;

    try {
      if (!this.connection) {
        this.connection = this.createConnection();
      }

      if (this.connection.state === signalR.HubConnectionState.Disconnected) {
        await this.connection.start();
        if (env.enableDebug) console.log('✅ SignalR connected to NotificationHub');
        this.notifyStateChange(signalR.HubConnectionState.Connected);
      }
    } catch (error) {
      if (env.enableDebug) console.error('❌ SignalR connection failed:', error);
      // Will auto-retry via reconnect policy
    } finally {
      this.isStarting = false;
    }
  }

  /** Stop the connection */
  async stop(): Promise<void> {
    if (this.connection) {
      await this.connection.stop();
      this.connection = null;
    }
  }

  /** Register a handler for a hub method */
  on<T = any>(methodName: string, handler: (data: T) => void): void {
    if (!this.connection) {
      this.connection = this.createConnection();
    }
    this.connection.on(methodName, handler);
  }

  /** Remove a handler for a hub method */
  off(methodName: string, handler?: (...args: any[]) => void): void {
    if (this.connection) {
      if (handler) {
        this.connection.off(methodName, handler);
      } else {
        this.connection.off(methodName);
      }
    }
  }

  /** Invoke a hub method */
  async invoke<T = any>(methodName: string, ...args: any[]): Promise<T> {
    if (!this.connection || this.connection.state !== signalR.HubConnectionState.Connected) {
      throw new Error('SignalR not connected');
    }
    return this.connection.invoke<T>(methodName, ...args);
  }

  /** Get current connection state */
  get state(): signalR.HubConnectionState {
    return this.connection?.state ?? signalR.HubConnectionState.Disconnected;
  }

  /** Subscribe to connection state changes */
  onStateChange(handler: ConnectionEventHandler): () => void {
    this.connectionStateHandlers.push(handler);
    return () => {
      this.connectionStateHandlers = this.connectionStateHandlers.filter((h) => h !== handler);
    };
  }

  private notifyStateChange(state: signalR.HubConnectionState): void {
    this.connectionStateHandlers.forEach((h) => h(state));
  }
}

// Singleton instance
export const signalRService = new SignalRService();
export default signalRService;
