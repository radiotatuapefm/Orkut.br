'use client'

import { useEffect, useState } from 'react'
import { useWebRTC } from '@/contexts/webrtc-context'
import { Dialog, DialogContent } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import {
  Phone,
  PhoneOff,
  Mic,
  MicOff,
  Video,
  VideoOff,
  Monitor,
  MonitorOff,
  Maximize2,
  Minimize2
} from 'lucide-react'

export function VideoCallModal() {
  const {
    callState,
    endCall,
    toggleMute,
    toggleVideo,
    acceptCall,
    rejectCall,
    isMuted,
    isVideoEnabled,
    localVideoRef,
    remoteVideoRef
  } = useWebRTC()

  const [callDuration, setCallDuration] = useState(0)
  const [isRinging, setIsRinging] = useState(true)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [isScreenSharing, setIsScreenSharing] = useState(false)

  // Timer for call duration
  useEffect(() => {
    let interval: NodeJS.Timeout
    
    if (callState.callAccepted && callState.isInCall) {
      setIsRinging(false)
      interval = setInterval(() => {
        setCallDuration(prev => prev + 1)
      }, 1000)
    } else if (callState.isInCall) {
      setIsRinging(true)
    }

    return () => {
      if (interval) clearInterval(interval)
    }
  }, [callState.callAccepted, callState.isInCall])

  // Reset duration when call ends
  useEffect(() => {
    if (!callState.isInCall) {
      setCallDuration(0)
      setIsRinging(true)
    }
  }, [callState.isInCall])

  // Format call duration
  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  const toggleFullscreen = () => {
    setIsFullscreen(!isFullscreen)
  }

  const startScreenShare = async () => {
    try {
      if (isScreenSharing) {
        // Stop screen sharing and return to camera
        setIsScreenSharing(false)
        // Implementation would replace screen stream with camera stream
      } else {
        // Start screen sharing
        const screenStream = await navigator.mediaDevices.getDisplayMedia({
          video: true,
          audio: true
        })
        setIsScreenSharing(true)
        
        // Implementation would replace camera stream with screen stream
        screenStream.getVideoTracks()[0].onended = () => {
          setIsScreenSharing(false)
        }
      }
    } catch (error) {
      console.error('Error with screen sharing:', error)
    }
  }

  if (!callState.isInCall || callState.callType !== 'video') {
    return null
  }

  return (
    <Dialog open={true} onOpenChange={() => {}}>
      <DialogContent 
        className={`${
          isFullscreen 
            ? 'max-w-full max-h-full w-screen h-screen p-0 m-0 fixed inset-0' 
            : 'sm:max-w-4xl max-h-[80vh]'
        } bg-black text-white`}
      >
        <div className="relative w-full h-full flex flex-col">
          
          {/* Header with user info and call status */}
          {!callState.callAccepted && (
            <div className="absolute top-4 left-1/2 transform -translate-x-1/2 z-20">
              <div className="bg-black bg-opacity-50 rounded-lg px-4 py-2 text-center">
                <h3 className="text-lg font-semibold text-white mb-1">
                  {callState.receivingCall ? 'Chamada Recebida' : 'Chamando...'}
                </h3>
                <p className="text-sm text-gray-300">
                  {callState.callingUser?.display_name}
                </p>
                {callState.receivingCall ? (
                  <Badge variant="default" className="bg-blue-500 mt-2">
                    Chamada de vídeo recebida
                  </Badge>
                ) : (
                  <Badge variant="default" className="bg-yellow-500 animate-pulse mt-2">
                    Estabelecendo conexão...
                  </Badge>
                )}
              </div>
            </div>
          )}

          {/* Call duration when connected */}
          {callState.callAccepted && (
            <div className="absolute top-4 left-4 z-20">
              <Badge variant="default" className="bg-green-500">
                {formatDuration(callDuration)}
              </Badge>
            </div>
          )}

          {/* Fullscreen toggle */}
          <Button
            onClick={toggleFullscreen}
            size="sm"
            variant="ghost"
            className="absolute top-4 right-4 z-20 text-white hover:bg-white hover:bg-opacity-20"
          >
            {isFullscreen ? (
              <Minimize2 className="h-4 w-4" />
            ) : (
              <Maximize2 className="h-4 w-4" />
            )}
          </Button>

          {/* Video Container */}
          <div className="flex-1 relative">
            
            {/* Remote Video (Full Screen) */}
            <div className="w-full h-full relative bg-gray-900">
              {callState.callAccepted && callState.remoteStream ? (
                <video
                  ref={remoteVideoRef}
                  autoPlay
                  playsInline
                  className="w-full h-full object-cover"
                />
              ) : (
                // Placeholder when no remote video
                <div className="w-full h-full flex items-center justify-center">
                  <div className="text-center">
                    <Avatar className="h-32 w-32 border-4 border-white shadow-lg mx-auto mb-4">
                      <AvatarImage 
                        src={callState.callingUser?.photo_url} 
                        alt={callState.callingUser?.display_name} 
                      />
                      <AvatarFallback className="text-2xl bg-purple-500 text-white">
                        {callState.callingUser?.display_name?.charAt(0).toUpperCase()}
                      </AvatarFallback>
                    </Avatar>
                    
                    {isRinging && (
                      <div className="absolute inset-0 flex items-center justify-center">
                        <div className="w-32 h-32 rounded-full border-4 border-green-400 animate-ping" />
                      </div>
                    )}
                  </div>
                </div>
              )}
              
              {/* Local Video (Picture in Picture) */}
              {callState.localStream && (
                <div className="absolute bottom-4 right-4 w-48 h-36 bg-gray-800 rounded-lg overflow-hidden border-2 border-white shadow-lg">
                  {isVideoEnabled ? (
                    <video
                      ref={localVideoRef}
                      autoPlay
                      playsInline
                      muted
                      className="w-full h-full object-cover transform scale-x-[-1]" // Mirror effect
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-gray-700">
                      <VideoOff className="h-8 w-8 text-gray-400" />
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>

          {/* Call Controls */}
          <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 z-20">
            <div className="bg-black bg-opacity-50 rounded-full px-6 py-4 flex items-center space-x-4">
              
              {callState.receivingCall ? (
                // Incoming call controls
                <>
                  <Button
                    onClick={rejectCall}
                    size="lg"
                    className="rounded-full bg-red-500 hover:bg-red-600 text-white w-16 h-16"
                  >
                    <PhoneOff className="h-6 w-6" />
                  </Button>
                  
                  <Button
                    onClick={acceptCall}
                    size="lg"
                    className="rounded-full bg-green-500 hover:bg-green-600 text-white w-16 h-16"
                  >
                    <Phone className="h-6 w-6" />
                  </Button>
                </>
              ) : (
                // Active call controls
                <>
                  {/* Mute/Unmute */}
                  <Button
                    onClick={toggleMute}
                    size="lg"
                    variant="ghost"
                    className={`rounded-full w-12 h-12 ${
                      isMuted 
                        ? 'bg-red-500 hover:bg-red-600 text-white' 
                        : 'bg-white bg-opacity-20 hover:bg-opacity-30 text-white'
                    }`}
                  >
                    {isMuted ? (
                      <MicOff className="h-5 w-5" />
                    ) : (
                      <Mic className="h-5 w-5" />
                    )}
                  </Button>

                  {/* Video On/Off */}
                  <Button
                    onClick={toggleVideo}
                    size="lg"
                    variant="ghost"
                    className={`rounded-full w-12 h-12 ${
                      !isVideoEnabled 
                        ? 'bg-red-500 hover:bg-red-600 text-white' 
                        : 'bg-white bg-opacity-20 hover:bg-opacity-30 text-white'
                    }`}
                  >
                    {isVideoEnabled ? (
                      <Video className="h-5 w-5" />
                    ) : (
                      <VideoOff className="h-5 w-5" />
                    )}
                  </Button>

                  {/* Screen Share */}
                  <Button
                    onClick={startScreenShare}
                    size="lg"
                    variant="ghost"
                    className={`rounded-full w-12 h-12 ${
                      isScreenSharing 
                        ? 'bg-blue-500 hover:bg-blue-600 text-white' 
                        : 'bg-white bg-opacity-20 hover:bg-opacity-30 text-white'
                    }`}
                  >
                    {isScreenSharing ? (
                      <MonitorOff className="h-5 w-5" />
                    ) : (
                      <Monitor className="h-5 w-5" />
                    )}
                  </Button>

                  {/* End Call */}
                  <Button
                    onClick={endCall}
                    size="lg"
                    className="rounded-full bg-red-500 hover:bg-red-600 text-white w-16 h-16"
                  >
                    <PhoneOff className="h-6 w-6" />
                  </Button>
                </>
              )}
            </div>
          </div>

          {/* Status indicators */}
          <div className="absolute bottom-24 left-4 z-20 space-y-2">
            {isMuted && (
              <Badge variant="destructive" className="bg-red-500">
                🔇 Microfone desligado
              </Badge>
            )}
            {!isVideoEnabled && (
              <Badge variant="destructive" className="bg-red-500">
                📷 Câmera desligada
              </Badge>
            )}
            {isScreenSharing && (
              <Badge variant="default" className="bg-blue-500">
                🖥️ Compartilhando tela
              </Badge>
            )}
          </div>

          {/* Connection status */}
          {!callState.callAccepted && !callState.receivingCall && (
            <div className="absolute bottom-24 right-4 z-20">
              <Badge variant="default" className="bg-yellow-500 animate-pulse">
                Conectando...
              </Badge>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
