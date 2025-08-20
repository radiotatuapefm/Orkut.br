// Contexts
export { WebRTCProvider, useWebRTC } from '../contexts/WebRTCContext';
export { 
  OnlineStatusProvider, 
  useOnlineStatus, 
  useUserOnlineStatus 
} from '../contexts/OnlineStatusContext';

// Components
export { AudioCall } from './AudioCall';
export { VideoCall } from './VideoCall';
export { CallNotification } from './CallNotification';
export { CallButtons } from './CallButtons';
export { CallManager } from './CallManager';

// Example App
export { default as AppWithCalls } from './AppWithCalls';

// Types
export interface OnlineUser {
  userId: string;
  userName: string;
  isOnline: boolean;
  lastSeen?: Date;
  status?: 'online' | 'away' | 'busy' | 'offline';
}

export interface IncomingCall {
  from: string;
  fromName: string;
  type: 'audio' | 'video';
}
