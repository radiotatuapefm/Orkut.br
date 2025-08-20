import React, { useEffect, useRef } from 'react';
import { useWebRTC } from '../contexts/WebRTCContext';
import './VideoCall.css';

interface VideoCallProps {
  contactName: string;
  onClose: () => void;
}

export const VideoCall: React.FC<VideoCallProps> = ({ contactName, onClose }) => {
  const {
    localStream,
    remoteStream,
    isCallActive,
    isAudioEnabled,
    isVideoEnabled,
    isScreenSharing,
    endCall,
    toggleAudio,
    toggleVideo,
    toggleScreenShare
  } = useWebRTC();

  const localVideoRef = useRef<HTMLVideoElement>(null);
  const remoteVideoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    if (localVideoRef.current && localStream) {
      localVideoRef.current.srcObject = localStream;
    }
  }, [localStream]);

  useEffect(() => {
    if (remoteVideoRef.current && remoteStream) {
      remoteVideoRef.current.srcObject = remoteStream;
    }
  }, [remoteStream]);

  const handleEndCall = () => {
    endCall();
    onClose();
  };

  if (!isCallActive) return null;

  return (
    <div className="video-call-overlay">
      <div className="video-call-container">
        <div className="video-call-header">
          <h2>Chamada de Vídeo</h2>
          <p className="contact-name">{contactName}</p>
          <button className="minimize-button" onClick={onClose} title="Minimizar">
            <svg viewBox="0 0 24 24" width="20" height="20">
              <path fill="currentColor" d="M19,13H5V11H19V13Z"/>
            </svg>
          </button>
        </div>

        <div className="video-call-content">
          <div className="remote-video-container">
            {remoteStream ? (
              <video
                ref={remoteVideoRef}
                autoPlay
                playsInline
                className="remote-video"
              />
            ) : (
              <div className="video-placeholder">
                <div className="placeholder-avatar">
                  <svg viewBox="0 0 24 24" width="60" height="60">
                    <path fill="currentColor" d="M12,4A4,4 0 0,1 16,8A4,4 0 0,1 12,12A4,4 0 0,1 8,8A4,4 0 0,1 12,4M12,14C16.42,14 20,15.79 20,18V20H4V18C4,15.79 7.58,14 12,14Z"/>
                  </svg>
                </div>
                <p>Conectando...</p>
              </div>
            )}
            
            <div className="call-status">
              {remoteStream ? 'Conectado' : 'Conectando...'}
            </div>
          </div>

          <div className="local-video-container">
            {localStream && isVideoEnabled ? (
              <video
                ref={localVideoRef}
                autoPlay
                playsInline
                muted
                className="local-video"
              />
            ) : (
              <div className="video-placeholder local">
                <div className="placeholder-avatar">
                  <svg viewBox="0 0 24 24" width="40" height="40">
                    <path fill="currentColor" d="M12,4A4,4 0 0,1 16,8A4,4 0 0,1 12,12A4,4 0 0,1 8,8A4,4 0 0,1 12,4M12,14C16.42,14 20,15.79 20,18V20H4V18C4,15.79 7.58,14 12,14Z"/>
                  </svg>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="video-call-controls">
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
            className={`control-button ${isVideoEnabled ? 'active' : 'muted'}`}
            onClick={toggleVideo}
            title={isVideoEnabled ? 'Desligar câmera' : 'Ligar câmera'}
          >
            {isVideoEnabled ? (
              <svg viewBox="0 0 24 24" width="24" height="24">
                <path fill="currentColor" d="M17,10.5V7A1,1 0 0,0 16,6H4A1,1 0 0,0 3,7V17A1,1 0 0,0 4,18H16A1,1 0 0,0 17,17V13.5L21,17.5V6.5L17,10.5Z"/>
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" width="24" height="24">
                <path fill="currentColor" d="M3.27,2L2,3.27L4.73,6H4A1,1 0 0,0 3,7V17A1,1 0 0,0 4,18H16C16.21,18 16.39,17.92 16.55,17.82L19.73,21L21,19.73M21,6.5L17,10.5V7A1,1 0 0,0 16,6H9.82L21,17.18V6.5Z"/>
              </svg>
            )}
          </button>

          <button
            className={`control-button ${isScreenSharing ? 'active' : ''}`}
            onClick={toggleScreenShare}
            title={isScreenSharing ? 'Parar compartilhamento' : 'Compartilhar tela'}
          >
            <svg viewBox="0 0 24 24" width="24" height="24">
              <path fill="currentColor" d="M13,16.9V22.1C13,22.6 12.6,23 12.1,23H11.9C11.4,23 11,22.6 11,22.1V16.9C11,16.4 11.4,16 11.9,16H12.1C12.6,16 13,16.4 13,16.9M21,2H3A2,2 0 0,0 1,4V14A2,2 0 0,0 3,16H9V14H3V4H21V14H15V16H21A2,2 0 0,0 23,14V4A2,2 0 0,0 21,2Z"/>
            </svg>
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
      </div>
    </div>
  );
};
