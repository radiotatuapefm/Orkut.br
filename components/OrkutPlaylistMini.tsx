'use client';

import React from 'react';
import { OrkutCard, OrkutCardContent, OrkutCardHeader } from '@/components/ui/orkut-card';
import { Button } from '@/components/ui/button';
import { Music, ExternalLink } from 'lucide-react';
import Link from 'next/link';

interface OrkutPlaylistMiniProps {
  playlistId?: string;
  title?: string;
  trackCount?: number;
  showHeader?: boolean;
}

const OrkutPlaylistMini: React.FC<OrkutPlaylistMiniProps> = ({
  playlistId = '2a7srdzr6N0teReSG1i7vJ',
  title = 'Nostalgia 2000s',
  trackCount = 50,
  showHeader = true
}) => {
  return (
    <OrkutCard>
      {showHeader && (
        <OrkutCardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Music className="h-4 w-4 text-purple-500" />
              <span className="font-semibold text-gray-800 text-sm">Música</span>
            </div>
            <Link href="/playlists">
              <Button variant="ghost" size="sm" className="text-purple-600 hover:bg-purple-50 p-1">
                <ExternalLink className="h-3 w-3" />
              </Button>
            </Link>
          </div>
        </OrkutCardHeader>
      )}
      <OrkutCardContent>
        <div className="space-y-3">
          <div className="rounded-lg overflow-hidden border border-purple-100 shadow-sm">
            <iframe
              title="Spotify Mini Player"
              src={`https://open.spotify.com/embed/playlist/${playlistId}?utm_source=generator&theme=0`}
              width="100%"
              height="200"
              style={{ border: 'none' }}
              allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture"
              loading="lazy"
            />
          </div>
          
          <div className="flex items-center justify-between">
            <div>
              <h4 className="font-medium text-sm text-gray-800">{title}</h4>
              <p className="text-xs text-gray-600">{trackCount} músicas</p>
            </div>
            <Link href="/playlists">
              <Button 
                size="sm" 
                variant="outline" 
                className="text-xs border-purple-300 text-purple-700 hover:bg-purple-50"
              >
                Ver Mais
              </Button>
            </Link>
          </div>
        </div>
      </OrkutCardContent>
    </OrkutCard>
  );
};

export default OrkutPlaylistMini;
