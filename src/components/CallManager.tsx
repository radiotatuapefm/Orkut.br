import React, { useState, useEffect } from 'react';
import { useWebRTC } from '../contexts/WebRTCContext';
import { AudioCall } from './AudioCall';
import { VideoCall } from './VideoCall';
import { CallNotification } from './CallNotification';

interface CallManagerProps {
  children?: React.ReactNode;
}

export const CallManager: React.FC<CallManagerProps> = ({ children }) => {
  const { 
    callType, 
    isCallActive, 
    incomingCall,
    endCall
  } = useWebRTC();
  
  const [currentContact, setCurrentContact] = useState<{
    name: string;
    id: string;
  } | null>(null);

  // Atualizar informações do contato quando há uma chamada ativa
  useEffect(() => {
    if (isCallActive && incomingCall) {
      setCurrentContact({
        name: incomingCall.fromName,
        id: incomingCall.from
      });
    } else if (!isCallActive) {
      setCurrentContact(null);
    }
  }, [isCallActive, incomingCall]);

  const handleCloseCall = () => {
    endCall();
    setCurrentContact(null);
  };

  return (
    <>
      {children}
      
      {/* Notificação de chamada recebida */}
      <CallNotification />
      
      {/* Interface de chamada ativa */}
      {isCallActive && currentContact && (
        <>
          {callType === 'audio' && (
            <AudioCall
              contactName={currentContact.name}
              onClose={handleCloseCall}
            />
          )}
          
          {callType === 'video' && (
            <VideoCall
              contactName={currentContact.name}
              onClose={handleCloseCall}
            />
          )}
        </>
      )}
    </>
  );
};
