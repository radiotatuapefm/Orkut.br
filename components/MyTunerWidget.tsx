'use client';

import React from 'react';

interface RadioWidgetProps {
  className?: string;
}

const RadioWidget: React.FC<RadioWidgetProps> = ({ 
  className = "" 
}) => {
  // Stream da Rádio Tatuapé FM do arquivo .m3u
  const radioStream = "http://82.145.41.50/stream.mp3?ipport=82.145.41.50_16784";

  return (
    <div className={`bg-white rounded-lg shadow-lg border overflow-hidden ${className}`}>
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-500 to-pink-500 p-4 text-white">
        <div className="flex items-center space-x-3">
          <img 
            src="https://static2.mytuner.mobi/media/tvos_radios/545/radio-tatuape-fm.b636f170.jpg" 
            alt="Rádio Tatuapé FM" 
            className="w-12 h-12 rounded-lg object-cover shadow-lg"
          />
          <div>
            <h3 className="font-bold text-lg">Rádio Tatuapé FM</h3>
            <div className="flex items-center space-x-2 text-sm opacity-90">
              <span className="w-2 h-2 bg-red-400 rounded-full animate-pulse"></span>
              <span>AO VIVO</span>
            </div>
          </div>
        </div>
      </div>

      {/* Video Player with Audio Stream */}
      <div className="p-4 bg-gray-50">
        <div className="w-full">
          <video 
            controls 
            autoPlay={false}
            name="media"
            className="w-full h-12 bg-gray-800 rounded-lg"
            style={{ maxHeight: '48px' }}
          >
            <source 
              src={radioStream} 
              type="audio/mpeg" 
            />
            Seu navegador não suporta o elemento de áudio.
          </video>
        </div>
        
        {/* Info */}
        <div className="mt-3 text-center">
          <p className="text-sm text-gray-600">
            🎵 Use os controles acima para ouvir a rádio
          </p>
        </div>
      </div>
    </div>
  );
};

export default RadioWidget;
