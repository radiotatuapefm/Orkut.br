'use client'

import { useEffect, useState } from 'react'
import { useWebRTC } from '@/contexts/webrtc-context'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import {
  Phone,
  PhoneOff,
  Mic,
  MicOff,
  Volume2,
  VolumeX
} from 'lucide-react'

export function AudioCallModal() {
  const {
    callState,
    endCall,
    toggleMute,
    acceptCall,
    rejectCall,
    isMuted
  } = useWebRTC()

  const [callDuration, setCallDuration] = useState(0)
  const [isRinging, setIsRinging] = useState(true)

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

  if (!callState.isInCall || callState.callType !== 'audio') {
    return null
  }

  return (
    <Dialog open={true} onOpenChange={() => {}}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-center">
            {callState.receivingCall ? 'Chamada Recebida' : 'Chamada de Áudio'}
          </DialogTitle>
        </DialogHeader>

        <div className="flex flex-col items-center space-y-6 py-6">
          {/* User Avatar */}
          <div className="relative">
            <Avatar className="h-32 w-32 border-4 border-white shadow-lg">
              <AvatarImage 
                src={callState.callingUser?.photo_url} 
                alt={callState.callingUser?.display_name} 
              />
              <AvatarFallback className="text-2xl bg-purple-500 text-white">
                {callState.callingUser?.display_name?.charAt(0).toUpperCase()}
              </AvatarFallback>
            </Avatar>
            
            {/* Ringing animation */}
            {isRinging && (
              <div className="absolute inset-0 rounded-full border-4 border-green-400 animate-ping" />
            )}
          </div>

          {/* User Info */}
          <div className="text-center">
            <h3 className="text-xl font-semibold text-gray-800 mb-1">
              {callState.callingUser?.display_name}
            </h3>
            <p className="text-sm text-gray-600 mb-2">
              @{callState.callingUser?.username}
            </p>
            
            {/* Call Status */}
            <div className="flex justify-center">
              {callState.receivingCall ? (
                <Badge variant="default" className="bg-blue-500">
                  Chamada recebida
                </Badge>
              ) : callState.callAccepted ? (
                <Badge variant="default" className="bg-green-500">
                  {formatDuration(callDuration)}
                </Badge>
              ) : (
                <Badge variant="default" className="bg-yellow-500 animate-pulse">
                  Chamando...
                </Badge>
              )}
            </div>
          </div>

          {/* Audio Visualization */}
          {callState.callAccepted && (
            <div className="flex items-center space-x-2">
              <Volume2 className="h-5 w-5 text-green-500" />
              <div className="flex space-x-1">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div
                    key={i}
                    className="w-1 bg-green-500 rounded-full animate-pulse"
                    style={{
                      height: Math.random() * 20 + 10,
                      animationDelay: `${i * 0.1}s`
                    }}
                  />
                ))}
              </div>
            </div>
          )}

          {/* Call Controls */}
          <div className="flex items-center justify-center space-x-4">
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
                <Button
                  onClick={toggleMute}
                  size="lg"
                  variant={isMuted ? "default" : "outline"}
                  className={`rounded-full w-14 h-14 ${
                    isMuted 
                      ? 'bg-red-500 hover:bg-red-600 text-white' 
                      : 'border-gray-300 hover:bg-gray-50'
                  }`}
                >
                  {isMuted ? (
                    <MicOff className="h-5 w-5" />
                  ) : (
                    <Mic className="h-5 w-5" />
                  )}
                </Button>

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

          {/* Status Text */}
          <div className="text-center">
            {callState.receivingCall ? (
              <p className="text-sm text-gray-600">
                Toque em ✅ para aceitar ou ❌ para rejeitar
              </p>
            ) : callState.callAccepted ? (
              <p className="text-sm text-gray-600">
                {isMuted ? '🔇 Microfone desligado' : '🎤 Microfone ligado'}
              </p>
            ) : (
              <p className="text-sm text-gray-600 animate-pulse">
                Estabelecendo conexão...
              </p>
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
