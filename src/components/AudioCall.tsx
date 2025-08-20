import React, { useEffect, useRef } from 'react';
import { useWebRTC } from '../contexts/WebRTCContext';
import './AudioCall.css';

interface AudioCallProps {
  contactName: string;
  onClose: () => void;
}

export const AudioCall: React.FC<AudioCallProps> = ({ contactName, onClose }) => {
  const {
    localStream,
    remoteStream,
    isCallActive,
    isAudioEnabled,
    endCall,
    toggleAudio
  } = useWebRTC();

  const localAudioRef = useRef<HTMLAudioElement>(null);
  const remoteAudioRef = useRef<HTMLAudioElement>(null);

  useEffect(() => {
    if (localAudioRef.current && localStream) {
      localAudioRef.current.srcObject = localStream;
      // Silenciar áudio local para evitar eco
      localAudioRef.current.muted = true;
    }
  }, [localStream]);

  useEffect(() => {
    if (remoteAudioRef.current && remoteStream) {
      remoteAudioRef.current.srcObject = remoteStream;
    }
  }, [remoteStream]);

  const handleEndCall = () => {
    endCall();
    onClose();
  };

  if (!isCallActive) return null;

  return (
    <div className="audio-call-overlay">
      <div className="audio-call-container">
        <div className="audio-call-header">
          <h2>Chamada de Áudio</h2>
          <p className="contact-name">{contactName}</p>
        </div>

        <div className="audio-call-content">
          <div className="audio-visualizer">
            <div className={`audio-wave ${isAudioEnabled ? 'active' : 'muted'}`}>
              <div className="wave-bar"></div>
              <div className="wave-bar"></div>
              <div className="wave-bar"></div>
              <div className="wave-bar"></div>
              <div className="wave-bar"></div>
            </div>
            
            <div className="call-status">
              {remoteStream ? 'Conectado' : 'Conectando...'}
            </div>
          </div>
        </div>

        <div className="audio-call-controls">
          <button
            className={`control-button ${isAudioEnabled ? 'active' : 'muted'}`}
            onClick={toggleAudio}
            title={isAudioEnabled ? 'Silenciar' : 'Ativar áudio'}
          >
            {isAudioEnabled ? (
              <svg viewBox="0 0 24 24" width="24" height="24">
                <path fill="currentColor" d="M12 2C13.1 2 14 2.9 14 4V10C14 11.1 13.1 12 12 12C10.9 12 10 11.1 10 10V4C10 2.9 10.9 2 12 2M19 10V12C19 15.3 16.3 18 13 18V20H18V22H6V20H11V18C7.7 18 5 15.3 5 12V10H7V12C7 14.2 8.8 16 11 16H13C15.2 16 17 14.2 17 12V10H19Z"/>
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" width="24" height="24">
                <path fill="currentColor" d="M19 11H17.3C17.3 11.74 17.14 12.43 16.87 13.05L18.1 14.28C18.66 13.3 19 12.19 19 11M15.2 9.8L14 8.6C13.4 8.2 12.7 7.9 12 7.9V4C13.1 4 14 4.9 14 6V9.8H15.2M21 19.1L19.9 20.2L16.5 16.8C15.4 17.6 14.1 18.1 12.7 18.3V20H18V22H6V20H11.3V18.3C7.9 17.9 5 15 5 11.3V9.3H7V11.3C7 13.8 8.9 15.8 11.3 16.3C11.1 16.1 10.9 15.9 10.8 15.7L2.1 7L3.2 5.9L21 19.1Z"/>
              </svg>
            )}
          </button>

          <button
            className="control-button end-call"
            onClick={handleEndCall}
            title="Encerrar chamada"
          >
            <svg viewBox="0 0 24 24" width="24" height="24">
              <path fill="currentColor" d="M12,9C10.4,9,8.85,9.25,7.4,9.72L6.82,7.78C8.69,7.26,10.34,7,12,7C13.66,7,15.31,7.26,17.18,7.78L16.6,9.72C15.15,9.25,13.6,9,12,9M20.2,17.1L20.9,15.4C21.6,13.9,21.6,12.1,20.9,10.6L12,3L3.1,10.6C2.4,12.1,2.4,13.9,3.1,15.4L3.8,17.1H20.2Z"/>
            </svg>
          </button>
        </div>

        {/* Elementos de áudio ocultos */}
        <audio ref={localAudioRef} autoPlay />
        <audio ref={remoteAudioRef} autoPlay />
      </div>
    </div>
  );
};
