import { NextResponse } from 'next/server';

// Forçar renderização dinâmica
export const dynamic = 'force-dynamic';

// Cache simples em memória para evitar múltiplas requisições
let cachedData: any = null;
let lastFetch = 0;
const CACHE_DURATION = 120000; // 2 minutos de cache para reduzir carga

export async function GET() {
  try {
    const now = Date.now();
    
    // Se temos dados em cache e ainda são válidos, retornar do cache
    if (cachedData && (now - lastFetch) < CACHE_DURATION) {
      console.log('📦 Retornando dados do cache:', cachedData.currentSong);
      return NextResponse.json({
        ...cachedData,
        fromCache: true,
        cacheAge: now - lastFetch
      });
    }
    
    console.log('🎵 Buscando dados da rádio via /played.html...');
    
    // Credentials para acessar o painel da rádio
    const credentials = Buffer.from('admin:784512235689').toString('base64');
    
    // Fazer requisição para o endpoint /played.html que tem as músicas
    const response = await fetch('http://82.145.41.50:16784/played.html', {
      headers: {
        'Authorization': `Basic ${credentials}`,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Connection': 'keep-alive'
      },
      cache: 'no-store', // Sempre buscar dados frescos
      signal: AbortSignal.timeout(8000) // Reduzir timeout para 8 segundos
    });

    console.log(`📡 Response status: ${response.status}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const html = await response.text();
    console.log(`📄 HTML recebido (${html.length} chars)`);
    
    // Extrair músicas do HTML baseado na estrutura real da tabela
    let currentSong = 'Rádio Tatuapé FM';
    const recentSongs = [];
    
    console.log('🔍 Extraindo músicas da tabela HTML...');
    
    // Extrair músicas baseado na estrutura HTML real (com tags <td>)
    // Primeiro, buscar pela música atual (linha com "Current Song")
    const currentSongMatch = html.match(/(\d{2}:\d{2}:\d{2})<\/td><td>([^<]+)<td><b>Current Song<\/b>/);
    if (currentSongMatch) {
      currentSong = currentSongMatch[2].trim();
      console.log('🎵 Música atual encontrada:', currentSong);
    }
    
    // Extrair todas as músicas usando a estrutura HTML correta
    const songRegex = /(\d{2}:\d{2}:\d{2})<\/td><td>([^<]+)/gi;
    let match;
    
    while ((match = songRegex.exec(html)) !== null && recentSongs.length < 5) {
      const time = match[1];
      const title = match[2].trim();
      const isCurrent = html.includes(`${time}</td><td>${title}<td><b>Current Song</b>`);
      
      // Filtrar entradas válidas (ignorar cabeçalhos e texto irrelevante)
      if (title && title.length > 3 && 
          !title.includes('Song Title') && 
          !title.includes('Played @') &&
          !title.includes('Written by') &&
          !title.includes('SHOUTcast')) {
        
        recentSongs.push({
          title,
          time,
          isCurrent: isCurrent
        });
        
        console.log(`🎵 Histórico [${recentSongs.length}]: ${time} - ${title}${isCurrent ? ' (ATUAL)' : ''}`);
      }
    }
    
    console.log('🎵 Extração concluída:');
    console.log('🎵 Música atual:', currentSong);
    console.log('🎵 Histórico:', recentSongs);
    
    // Contar quantas músicas foram tocadas (cada linha com timestamp)
    const songLines = html.match(/\d{2}:\d{2}:\d{2}\s+.+/g) || [];
    const songsCount = songLines.length;
    
    console.log(`🎼 Total de ${songsCount} músicas no histórico`);
    console.log(`🎵 Extraídas ${recentSongs.length} músicas recentes:`, recentSongs);

    // Dados extraídos
    const radioData = {
      currentSong,
      serverStatus: 'Online',
      streamStatus: 'Ao Vivo',
      listeners: 0, // Esse endpoint não tem info de listeners
      recentSongs, // Adicionar o histórico de músicas
      lastUpdated: new Date().toISOString(),
      debug: {
        responseStatus: response.status,
        htmlLength: html.length,
        songsInHistory: songsCount,
        foundCurrentSong: currentSong !== 'Rádio Tatuapé FM',
        recentSongsCount: recentSongs.length
      }
    };

    console.log('✅ Dados extraídos:', radioData);
    
    // Salvar no cache
    cachedData = radioData;
    lastFetch = now;
    
    return NextResponse.json(radioData);
    
  } catch (error) {
    console.error('❌ Erro ao buscar status da rádio:', error);
    
    // Retornar dados padrão em caso de erro
    const fallbackData = {
      currentSong: 'Rádio Tatuapé FM - Ao Vivo',
      serverStatus: 'Online',
      streamStatus: 'Ao Vivo',
      listeners: 0,
      recentSongs: [], // Array vazio para evitar erros
      lastUpdated: new Date().toISOString(),
      error: `Erro: ${error instanceof Error ? error.message : 'Desconhecido'}`,
      debug: {
        errorType: error instanceof Error ? error.name : 'Unknown',
        errorMessage: error instanceof Error ? error.message : String(error)
      }
    };
    
    console.log('⚠️ Retornando dados fallback:', fallbackData);
    return NextResponse.json(fallbackData);
  }
}
