import React, { createContext, useContext, useRef, useState, useEffect } from 'react';
import { io, Socket } from 'socket.io-client';
import { useAuth } from './AuthContext';

interface WebRTCContextType {
  localStream: MediaStream | null;
  remoteStream: MediaStream | null;
  isCallActive: boolean;
  isAudioEnabled: boolean;
  isVideoEnabled: boolean;
  isScreenSharing: boolean;
  callType: 'audio' | 'video' | null;
  incomingCall: {
    from: string;
    fromName: string;
    type: 'audio' | 'video';
  } | null;
  startAudioCall: (userId: string) => void;
  startVideoCall: (userId: string) => void;
  answerCall: () => void;
  rejectCall: () => void;
  endCall: () => void;
  toggleAudio: () => void;
  toggleVideo: () => void;
  toggleScreenShare: () => void;
}

const WebRTCContext = createContext<WebRTCContextType | undefined>(undefined);

const ICE_SERVERS = [
  { urls: 'stun:stun.l.google.com:19302' },
  { urls: 'stun:stun1.l.google.com:19302' }
];

export const WebRTCProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const socketRef = useRef<Socket | null>(null);
  const peerConnectionRef = useRef<RTCPeerConnection | null>(null);
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [remoteStream, setRemoteStream] = useState<MediaStream | null>(null);
  const [isCallActive, setIsCallActive] = useState(false);
  const [isAudioEnabled, setIsAudioEnabled] = useState(true);
  const [isVideoEnabled, setIsVideoEnabled] = useState(true);
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const [callType, setCallType] = useState<'audio' | 'video' | null>(null);
  const [incomingCall, setIncomingCall] = useState<{
    from: string;
    fromName: string;
    type: 'audio' | 'video';
  } | null>(null);

  // Inicializar socket.io
  useEffect(() => {
    if (user) {
      socketRef.current = io('http://localhost:5001', {
        auth: {
          userId: user.id
        }
      });

      socketRef.current.on('incoming-call', (data) => {
        setIncomingCall({
          from: data.from,
          fromName: data.fromName,
          type: data.type
        });
      });

      socketRef.current.on('call-answered', handleCallAnswered);
      socketRef.current.on('call-rejected', handleCallRejected);
      socketRef.current.on('call-ended', handleCallEnded);
      socketRef.current.on('ice-candidate', handleIceCandidate);
      socketRef.current.on('offer', handleOffer);
      socketRef.current.on('answer', handleAnswer);

      return () => {
        socketRef.current?.disconnect();
      };
    }
  }, [user]);

  const createPeerConnection = () => {
    const peerConnection = new RTCPeerConnection({ iceServers: ICE_SERVERS });

    peerConnection.onicecandidate = (event) => {
      if (event.candidate && socketRef.current) {
        socketRef.current.emit('ice-candidate', {
          candidate: event.candidate,
          to: incomingCall?.from
        });
      }
    };

    peerConnection.ontrack = (event) => {
      setRemoteStream(event.streams[0]);
    };

    peerConnectionRef.current = peerConnection;
    return peerConnection;
  };

  const getMediaStream = async (audio: boolean, video: boolean) => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio,
        video: video ? { width: 1280, height: 720 } : false
      });
      setLocalStream(stream);
      return stream;
    } catch (error) {
      console.error('Error accessing media devices:', error);
      throw error;
    }
  };

  const startAudioCall = async (userId: string) => {
    try {
      const stream = await getMediaStream(true, false);
      const peerConnection = createPeerConnection();
      
      stream.getTracks().forEach(track => {
        peerConnection.addTrack(track, stream);
      });

      const offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      setCallType('audio');
      setIsCallActive(true);

      socketRef.current?.emit('call-user', {
        to: userId,
        type: 'audio',
        offer
      });
    } catch (error) {
      console.error('Error starting audio call:', error);
    }
  };

  const startVideoCall = async (userId: string) => {
    try {
      const stream = await getMediaStream(true, true);
      const peerConnection = createPeerConnection();
      
      stream.getTracks().forEach(track => {
        peerConnection.addTrack(track, stream);
      });

      const offer = await peerConnection.createOffer();
      await peerConnection.setLocalDescription(offer);

      setCallType('video');
      setIsCallActive(true);

      socketRef.current?.emit('call-user', {
        to: userId,
        type: 'video',
        offer
      });
    } catch (error) {
      console.error('Error starting video call:', error);
    }
  };

  const answerCall = async () => {
    if (!incomingCall) return;

    try {
      const stream = await getMediaStream(
        true,
        incomingCall.type === 'video'
      );
      
      const peerConnection = createPeerConnection();
      
      stream.getTracks().forEach(track => {
        peerConnection.addTrack(track, stream);
      });

      setCallType(incomingCall.type);
      setIsCallActive(true);
      setIncomingCall(null);

      socketRef.current?.emit('answer-call', {
        to: incomingCall.from,
        accepted: true
      });
    } catch (error) {
      console.error('Error answering call:', error);
      rejectCall();
    }
  };

  const rejectCall = () => {
    if (incomingCall) {
      socketRef.current?.emit('answer-call', {
        to: incomingCall.from,
        accepted: false
      });
      setIncomingCall(null);
    }
  };

  const endCall = () => {
    // Parar todas as tracks do stream local
    localStream?.getTracks().forEach(track => track.stop());
    
    // Fechar peer connection
    peerConnectionRef.current?.close();
    peerConnectionRef.current = null;

    // Limpar estados
    setLocalStream(null);
    setRemoteStream(null);
    setIsCallActive(false);
    setCallType(null);
    setIsAudioEnabled(true);
    setIsVideoEnabled(true);
    setIsScreenSharing(false);

    // Notificar o outro peer
    socketRef.current?.emit('end-call');
  };

  const toggleAudio = () => {
    if (localStream) {
      const audioTrack = localStream.getAudioTracks()[0];
      if (audioTrack) {
        audioTrack.enabled = !audioTrack.enabled;
        setIsAudioEnabled(audioTrack.enabled);
      }
    }
  };

  const toggleVideo = () => {
    if (localStream) {
      const videoTrack = localStream.getVideoTracks()[0];
      if (videoTrack) {
        videoTrack.enabled = !videoTrack.enabled;
        setIsVideoEnabled(videoTrack.enabled);
      }
    }
  };

  const toggleScreenShare = async () => {
    try {
      if (!isScreenSharing) {
        const screenStream = await navigator.mediaDevices.getDisplayMedia({
          video: true,
          audio: true
        });

        const videoTrack = screenStream.getVideoTracks()[0];
        const sender = peerConnectionRef.current
          ?.getSenders()
          .find(s => s.track && s.track.kind === 'video');

        if (sender) {
          await sender.replaceTrack(videoTrack);
        }

        videoTrack.onended = () => {
          // Voltar para a câmera quando o compartilhamento terminar
          toggleScreenShare();
        };

        setIsScreenSharing(true);
      } else {
        // Voltar para a câmera
        const stream = await getMediaStream(true, true);
        const videoTrack = stream.getVideoTracks()[0];
        const sender = peerConnectionRef.current
          ?.getSenders()
          .find(s => s.track && s.track.kind === 'video');

        if (sender) {
          await sender.replaceTrack(videoTrack);
        }

        setLocalStream(stream);
        setIsScreenSharing(false);
      }
    } catch (error) {
      console.error('Error toggling screen share:', error);
    }
  };

  // Handlers para eventos do socket
  const handleCallAnswered = async (data: { accepted: boolean; answer?: RTCSessionDescriptionInit }) => {
    if (data.accepted && data.answer) {
      await peerConnectionRef.current?.setRemoteDescription(data.answer);
    } else {
      // Chamada foi rejeitada
      endCall();
    }
  };

  const handleCallRejected = () => {
    endCall();
  };

  const handleCallEnded = () => {
    endCall();
  };

  const handleIceCandidate = async (data: { candidate: RTCIceCandidateInit }) => {
    try {
      await peerConnectionRef.current?.addIceCandidate(data.candidate);
    } catch (error) {
      console.error('Error adding ICE candidate:', error);
    }
  };

  const handleOffer = async (data: { offer: RTCSessionDescriptionInit; from: string }) => {
    const peerConnection = createPeerConnection();
    await peerConnection.setRemoteDescription(data.offer);

    const answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    socketRef.current?.emit('answer', {
      to: data.from,
      answer
    });
  };

  const handleAnswer = async (data: { answer: RTCSessionDescriptionInit }) => {
    await peerConnectionRef.current?.setRemoteDescription(data.answer);
  };

  const value: WebRTCContextType = {
    localStream,
    remoteStream,
    isCallActive,
    isAudioEnabled,
    isVideoEnabled,
    isScreenSharing,
    callType,
    incomingCall,
    startAudioCall,
    startVideoCall,
    answerCall,
    rejectCall,
    endCall,
    toggleAudio,
    toggleVideo,
    toggleScreenShare
  };

  return (
    <WebRTCContext.Provider value={value}>
      {children}
    </WebRTCContext.Provider>
  );
};

export const useWebRTC = () => {
  const context = useContext(WebRTCContext);
  if (!context) {
    throw new Error('useWebRTC must be used within a WebRTCProvider');
  }
  return context;
};
