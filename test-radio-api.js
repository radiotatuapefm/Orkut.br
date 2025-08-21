// Script de teste para verificar a extração da música atual
const credentials = Buffer.from('admin:784512235689').toString('base64');

async function testRadioAPI() {
  try {
    console.log('🎵 Testando acesso direto ao servidor da rádio...');
    
    const response = await fetch('http://82.145.41.50:16784/index.html', {
      headers: {
        'Authorization': `Basic ${credentials}`,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Connection': 'keep-alive'
      },
      signal: AbortSignal.timeout(8000)
    });

    console.log(`📡 Status: ${response.status}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const html = await response.text();
    console.log(`📄 HTML recebido (${html.length} chars)`);
    console.log('📄 Primeiros 500 chars:', html.substring(0, 500));
    
    // Testar diferentes regex para extrair a música
    console.log('\n🔍 Testando diferentes regex...');
    
    // Regex 1: Buscar Current Song seguido de qualquer coisa
    const regex1 = /Current Song:\s*([^\n\r<]+)/i;
    const match1 = html.match(regex1);
    console.log('Regex 1 (Current Song):', match1 ? match1[1].trim() : 'Não encontrado');
    
    // Regex 2: Buscar tags <b> próximas de Current Song  
    const regex2 = /<b>([^<]+)<\/b>(?=.*Current Song)/i;
    const match2 = html.match(regex2);
    console.log('Regex 2 (<b> near Current Song):', match2 ? match2[1].trim() : 'Não encontrado');
    
    // Regex 3: Buscar qualquer tag <b>
    const regex3 = /<b>([^<]+)<\/b>/g;
    const matches3 = [...html.matchAll(regex3)];
    console.log('Regex 3 (todas as tags <b>):');
    matches3.forEach((match, i) => {
      console.log(`  ${i + 1}: ${match[1].trim()}`);
    });
    
    // Regex 4: Buscar baseado no contexto do site fornecido
    const regex4 = /Current Song:\s*([^\n\r]+)/i;
    const match4 = html.match(regex4);
    console.log('Regex 4 (Current Song com newline):', match4 ? match4[1].trim() : 'Não encontrado');
    
  } catch (error) {
    console.error('❌ Erro:', error.message);
  }
}

testRadioAPI();
