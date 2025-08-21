import { NextResponse } from 'next/server';

// Forçar renderização dinâmica
export const dynamic = 'force-dynamic';

// Cache simples em memória para evitar múltiplas requisições
let cachedData: any = null;
let lastFetch = 0;
const CACHE_DURATION = 60000; // 1 minuto de cache

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
      signal: AbortSignal.timeout(10000) // Timeout de 10 segundos
    });

    console.log(`📡 Response status: ${response.status}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const html = await response.text();
    console.log(`📄 HTML recebido (${html.length} chars)`);
    
    // Extrair "Current Song" do HTML
    let currentSong = 'Rádio Tatuapé FM';
    
    // No HTML, vemos: <td>03:43:25</td><td>Blur - M.O.R. - Live in Utrecht;2012 Remastered Version<td><b>Current Song</b></td>
    // Vamos buscar por "Current Song" e pegar o conteúdo da célula anterior
    
    console.log('🔍 Procurando por Current Song no HTML...');
    
    // Método 1: Buscar por "<b>Current Song</b>" e pegar o td anterior
    let match = html.match(/<td[^>]*>([^<]+)<td[^>]*><b>Current Song<\/b>/i);
    if (match) {
      currentSong = match[1].trim();
      console.log('🎵 Método 1 - Música encontrada:', currentSong);
    } else {
      // Método 2: Buscar pela primeira linha da tabela (música mais recente)
      const firstRowMatch = html.match(/<tr[^>]*>\s*<td[^>]*>(\d{2}:\d{2}:\d{2})<\/td>\s*<td[^>]*>([^<]+?)<\/td>/i);
      if (firstRowMatch) {
        const songTitle = firstRowMatch[2].trim();
        const timestamp = firstRowMatch[1];
        
        // Verificar se não é apenas o nome da rádio
        if (songTitle && songTitle !== 'Rádio Tatuapé FM' && songTitle.length > 3) {
          currentSong = songTitle;
          console.log('🎵 Método 2 - Primeira música encontrada:', currentSong);
          console.log('⏰ Timestamp:', timestamp);
        } else {
          console.log('⚠️ Primeira linha não contém música válida:', songTitle);
        }
      } else {
        console.log('❌ Nenhum padrão de música encontrado no HTML');
      }
    }
    
    // Contar quantas músicas foram tocadas (cada linha com timestamp)
    const songLines = html.match(/\d{2}:\d{2}:\d{2}\s+.+/g) || [];
    const songsCount = songLines.length;
    
    console.log(`🎼 Total de ${songsCount} músicas no histórico`);

    // Dados extraídos
    const radioData = {
      currentSong,
      serverStatus: 'Online',
      streamStatus: 'Ao Vivo',
      listeners: 0, // Esse endpoint não tem info de listeners
      lastUpdated: new Date().toISOString(),
      debug: {
        responseStatus: response.status,
        htmlLength: html.length,
        songsInHistory: songsCount,
        foundCurrentSong: match ? true : false
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
