import React, { useEffect, useState } from 'react';
import { useWebRTC } from '../contexts/WebRTCContext';
import './CallNotification.css';

export const CallNotification: React.FC = () => {
  const { incomingCall, answerCall, rejectCall } = useWebRTC();
  const [isVisible, setIsVisible] = useState(false);
  const [ringtone, setRingtone] = useState<HTMLAudioElement | null>(null);

  useEffect(() => {
    // Criar ringtone
    const audio = new Audio();
    // Usando um tom de chamada simples via Web Audio API
    createRingtone().then(audioBuffer => {
      if (audioBuffer) {
        const audioUrl = URL.createObjectURL(audioBuffer);
        audio.src = audioUrl;
        audio.loop = true;
        audio.volume = 0.5;
        setRingtone(audio);
      }
    });

    return () => {
      if (audio) {
        audio.pause();
        audio.src = '';
      }
    };
  }, []);

  useEffect(() => {
    if (incomingCall) {
      setIsVisible(true);
      
      // Tocar ringtone
      if (ringtone) {
        ringtone.play().catch(console.error);
      }
      
      // Vibrar se disponível
      if ('vibrate' in navigator) {
        navigator.vibrate([500, 200, 500, 200, 500]);
      }
    } else {
      setIsVisible(false);
      
      // Parar ringtone
      if (ringtone) {
        ringtone.pause();
        ringtone.currentTime = 0;
      }
    }
  }, [incomingCall, ringtone]);

  const handleAnswer = () => {
    if (ringtone) {
      ringtone.pause();
      ringtone.currentTime = 0;
    }
    answerCall();
  };

  const handleReject = () => {
    if (ringtone) {
      ringtone.pause();
      ringtone.currentTime = 0;
    }
    rejectCall();
  };

  if (!incomingCall || !isVisible) return null;

  return (
    <div className="call-notification-overlay">
      <div className="call-notification-container">
        <div className="caller-info">
          <div className="caller-avatar">
            <svg viewBox="0 0 24 24" width="60" height="60">
              <path fill="currentColor" d="M12,4A4,4 0 0,1 16,8A4,4 0 0,1 12,12A4,4 0 0,1 8,8A4,4 0 0,1 12,4M12,14C16.42,14 20,15.79 20,18V20H4V18C4,15.79 7.58,14 12,14Z"/>
            </svg>
          </div>
          
          <div className="caller-details">
            <h3>{incomingCall.fromName}</h3>
            <p>
              {incomingCall.type === 'video' ? (
                <>
                  <svg viewBox="0 0 24 24" width="16" height="16">
                    <path fill="currentColor" d="M17,10.5V7A1,1 0 0,0 16,6H4A1,1 0 0,0 3,7V17A1,1 0 0,0 4,18H16A1,1 0 0,0 17,17V13.5L21,17.5V6.5L17,10.5Z"/>
                  </svg>
                  Chamada de vídeo
                </>
              ) : (
                <>
                  <svg viewBox="0 0 24 24" width="16" height="16">
                    <path fill="currentColor" d="M6.62,10.79C8.06,13.62 10.38,15.94 13.21,17.38L15.41,15.18C15.69,14.9 16.08,14.82 16.43,14.93C17.55,15.3 18.75,15.5 20,15.5A1,1 0 0,1 21,16.5V20A1,1 0 0,1 20,21A17,17 0 0,1 3,4A1,1 0 0,1 4,3H7.5A1,1 0 0,1 8.5,4C8.5,5.25 8.7,6.45 9.07,7.57C9.18,7.92 9.1,8.31 8.82,8.59L6.62,10.79Z"/>
                  </svg>
                  Chamada de áudio
                </>
              )}
            </p>
          </div>
        </div>

        <div className="call-actions">
          <button
            className="answer-button"
            onClick={handleAnswer}
            title="Atender chamada"
          >
            <svg viewBox="0 0 24 24" width="28" height="28">
              <path fill="currentColor" d="M6.62,10.79C8.06,13.62 10.38,15.94 13.21,17.38L15.41,15.18C15.69,14.9 16.08,14.82 16.43,14.93C17.55,15.3 18.75,15.5 20,15.5A1,1 0 0,1 21,16.5V20A1,1 0 0,1 20,21A17,17 0 0,1 3,4A1,1 0 0,1 4,3H7.5A1,1 0 0,1 8.5,4C8.5,5.25 8.7,6.45 9.07,7.57C9.18,7.92 9.1,8.31 8.82,8.59L6.62,10.79Z"/>
            </svg>
          </button>

          <button
            className="reject-button"
            onClick={handleReject}
            title="Rejeitar chamada"
          >
            <svg viewBox="0 0 24 24" width="28" height="28">
              <path fill="currentColor" d="M12,9C10.4,9,8.85,9.25,7.4,9.72L6.82,7.78C8.69,7.26,10.34,7,12,7C13.66,7,15.31,7.26,17.18,7.78L16.6,9.72C15.15,9.25,13.6,9,12,9M20.2,17.1L20.9,15.4C21.6,13.9,21.6,12.1,20.9,10.6L12,3L3.1,10.6C2.4,12.1,2.4,13.9,3.1,15.4L3.8,17.1H20.2Z"/>
            </svg>
          </button>
        </div>

        <div className="incoming-call-animation">
          <div className="pulse-ring"></div>
          <div className="pulse-ring"></div>
          <div className="pulse-ring"></div>
        </div>
      </div>
    </div>
  );
};

// Função para criar um ringtone simples usando Web Audio API
async function createRingtone(): Promise<Blob | null> {
  try {
    const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    const sampleRate = audioContext.sampleRate;
    const duration = 2; // 2 segundos
    const length = sampleRate * duration;
    const audioBuffer = audioContext.createBuffer(1, length, sampleRate);
    const data = audioBuffer.getChannelData(0);

    // Criar um tom de 440Hz (Lá) com fade in/out
    for (let i = 0; i < length; i++) {
      const time = i / sampleRate;
      let amplitude = Math.sin(2 * Math.PI * 440 * time) * 0.3;
      
      // Fade in/out
      if (time < 0.1) {
        amplitude *= time / 0.1;
      } else if (time > duration - 0.1) {
        amplitude *= (duration - time) / 0.1;
      }
      
      data[i] = amplitude;
    }

    // Converter para Blob
    const wavBuffer = audioBufferToWav(audioBuffer);
    return new Blob([wavBuffer], { type: 'audio/wav' });
  } catch (error) {
    console.error('Erro ao criar ringtone:', error);
    return null;
  }
}

// Função auxiliar para converter AudioBuffer para WAV
function audioBufferToWav(buffer: AudioBuffer): ArrayBuffer {
  const length = buffer.length;
  const arrayBuffer = new ArrayBuffer(44 + length * 2);
  const view = new DataView(arrayBuffer);

  // WAV header
  const writeString = (offset: number, string: string) => {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  };

  writeString(0, 'RIFF');
  view.setUint32(4, 36 + length * 2, true);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, 1, true);
  view.setUint32(24, buffer.sampleRate, true);
  view.setUint32(28, buffer.sampleRate * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  writeString(36, 'data');
  view.setUint32(40, length * 2, true);

  // Convert float samples to 16-bit PCM
  const data = buffer.getChannelData(0);
  let offset = 44;
  for (let i = 0; i < length; i++) {
    const sample = Math.max(-1, Math.min(1, data[i]));
    view.setInt16(offset, sample * 0x7FFF, true);
    offset += 2;
  }

  return arrayBuffer;
}
