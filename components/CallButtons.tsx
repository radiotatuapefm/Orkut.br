import React, { useState } from 'react';
import { useWebRTC } from '@/contexts/webrtc-context';
// CSS removido temporariamente até ser criado

interface CallButtonsProps {
  userId: string;
  userName: string;
  isOnline?: boolean;
  size?: 'small' | 'medium' | 'large';
  layout?: 'horizontal' | 'vertical';
  showLabels?: boolean;
}

export const CallButtons: React.FC<CallButtonsProps> = ({
  userId,
  userName,
  isOnline = true,
  size = 'medium',
  layout = 'horizontal',
  showLabels = false
}) => {
  const { startAudioCall, startVideoCall, callState } = useWebRTC();
  const isCallActive = callState.isInCall;
  const [isLoading, setIsLoading] = useState<'audio' | 'video' | null>(null);

  const handleAudioCall = async () => {
    if (isCallActive || !isOnline) return;
    
    setIsLoading('audio');
    try {
      await startAudioCall(userId);
    } catch (error) {
      console.error('Erro ao iniciar chamada de áudio:', error);
    } finally {
      setIsLoading(null);
    }
  };

  const handleVideoCall = async () => {
    if (isCallActive || !isOnline) return;
    
    setIsLoading('video');
    try {
      await startVideoCall(userId);
    } catch (error) {
      console.error('Erro ao iniciar chamada de vídeo:', error);
    } finally {
      setIsLoading(null);
    }
  };

  const isDisabled = !isOnline || isCallActive;

  return (
    <div className={`call-buttons ${layout} ${size}`}>
      <button
        className={`call-button audio-call ${isLoading === 'audio' ? 'loading' : ''}`}
        onClick={handleAudioCall}
        disabled={isDisabled || isLoading !== null}
        title={
          !isOnline 
            ? `${userName} está offline`
            : isCallActive 
            ? 'Chamada em andamento'
            : `Ligar para ${userName}`
        }
      >
        {isLoading === 'audio' ? (
          <div className="loading-spinner">
            <svg viewBox="0 0 24 24" width="20" height="20">
              <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="none" strokeDasharray="31.416" strokeDashoffset="31.416">
                <animate attributeName="stroke-dasharray" dur="2s" values="0 31.416;15.708 15.708;0 31.416" repeatCount="indefinite"/>
                <animate attributeName="stroke-dashoffset" dur="2s" values="0;-15.708;-31.416" repeatCount="indefinite"/>
              </circle>
            </svg>
          </div>
        ) : (
          <svg viewBox="0 0 24 24" width="20" height="20">
            <path fill="currentColor" d="M6.62,10.79C8.06,13.62 10.38,15.94 13.21,17.38L15.41,15.18C15.69,14.9 16.08,14.82 16.43,14.93C17.55,15.3 18.75,15.5 20,15.5A1,1 0 0,1 21,16.5V20A1,1 0 0,1 20,21A17,17 0 0,1 3,4A1,1 0 0,1 4,3H7.5A1,1 0 0,1 8.5,4C8.5,5.25 8.7,6.45 9.07,7.57C9.18,7.92 9.1,8.31 8.82,8.59L6.62,10.79Z"/>
          </svg>
        )}
        {showLabels && <span>Áudio</span>}
      </button>

      <button
        className={`call-button video-call ${isLoading === 'video' ? 'loading' : ''}`}
        onClick={handleVideoCall}
        disabled={isDisabled || isLoading !== null}
        title={
          !isOnline 
            ? `${userName} está offline`
            : isCallActive 
            ? 'Chamada em andamento'
            : `Videochamada com ${userName}`
        }
      >
        {isLoading === 'video' ? (
          <div className="loading-spinner">
            <svg viewBox="0 0 24 24" width="20" height="20">
              <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="none" strokeDasharray="31.416" strokeDashoffset="31.416">
                <animate attributeName="stroke-dasharray" dur="2s" values="0 31.416;15.708 15.708;0 31.416" repeatCount="indefinite"/>
                <animate attributeName="stroke-dashoffset" dur="2s" values="0;-15.708;-31.416" repeatCount="indefinite"/>
              </circle>
            </svg>
          </div>
        ) : (
          <svg viewBox="0 0 24 24" width="20" height="20">
            <path fill="currentColor" d="M17,10.5V7A1,1 0 0,0 16,6H4A1,1 0 0,0 3,7V17A1,1 0 0,0 4,18H16A1,1 0 0,0 17,17V13.5L21,17.5V6.5L17,10.5Z"/>
          </svg>
        )}
        {showLabels && <span>Vídeo</span>}
      </button>

      {!isOnline && (
        <div className="offline-indicator">
          <svg viewBox="0 0 24 24" width="12" height="12">
            <circle cx="12" cy="12" r="8" fill="#9e9e9e"/>
          </svg>
          <span>Offline</span>
        </div>
      )}
    </div>
  );
};
