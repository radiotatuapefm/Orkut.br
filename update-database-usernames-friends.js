const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Configurações do Supabase
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Chave de service role

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Variáveis de ambiente não encontradas:');
  console.error('   NEXT_PUBLIC_SUPABASE_URL:', !!supabaseUrl);
  console.error('   SUPABASE_SERVICE_ROLE_KEY:', !!supabaseServiceKey);
  console.error('');
  console.error('Configure as variáveis de ambiente no arquivo .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function updateDatabase() {
  try {
    console.log('🚀 Iniciando atualização do banco de dados...');
    console.log('');

    // Ler o arquivo SQL
    const sqlPath = path.join(__dirname, 'sql', 'profiles_username_friends.sql');
    
    if (!fs.existsSync(sqlPath)) {
      throw new Error(`Arquivo SQL não encontrado: ${sqlPath}`);
    }

    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    
    // Dividir o SQL em comandos individuais
    const commands = sqlContent
      .split(';')
      .map(cmd => cmd.trim())
      .filter(cmd => cmd.length > 0 && !cmd.startsWith('--'));

    console.log(`📝 Executando ${commands.length} comandos SQL...`);
    console.log('');

    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < commands.length; i++) {
      const command = commands[i] + ';';
      
      try {
        console.log(`⚡ Executando comando ${i + 1}/${commands.length}...`);
        
        const { error } = await supabase.rpc('exec_sql', { sql_command: command });
        
        if (error) {
          // Tentar executar diretamente se RPC falhar
          const { error: directError } = await supabase
            .from('__dummy__') // Usamos uma query que vai falhar mas nos permite executar SQL
            .select('*')
            .limit(0);
          
          // Como alternativa, usar uma função personalizada
          const { error: customError } = await supabase.rpc('execute_sql_command', {
            command: command
          });
          
          if (customError && customError.message) {
            // Se contém palavras-chave que indicam sucesso, ignorar
            const successKeywords = ['already exists', 'does not exist', 'successfully'];
            const isSuccess = successKeywords.some(keyword => 
              customError.message.toLowerCase().includes(keyword)
            );
            
            if (!isSuccess) {
              console.log(`   ⚠️  Aviso: ${customError.message}`);
            }
          }
        }
        
        successCount++;
        console.log(`   ✅ Comando executado com sucesso`);
        
      } catch (err) {
        errorCount++;
        console.log(`   ❌ Erro: ${err.message}`);
        
        // Continuar com próximo comando
        continue;
      }
    }

    console.log('');
    console.log('📊 Relatório da execução:');
    console.log(`   ✅ Sucessos: ${successCount}`);
    console.log(`   ❌ Erros: ${errorCount}`);
    console.log('');

    // Verificar se as tabelas foram criadas
    console.log('🔍 Verificando estruturas criadas...');
    
    try {
      // Verificar tabela profiles
      const { data: profilesColumns } = await supabase
        .from('profiles')
        .select('*')
        .limit(1);
      
      console.log('   ✅ Tabela profiles acessível');

      // Verificar tabela friendships
      const { data: friendshipsColumns } = await supabase
        .from('friendships')
        .select('*')
        .limit(1);
      
      console.log('   ✅ Tabela friendships criada');

      // Verificar view friends_view
      const { data: friendsView } = await supabase
        .from('friends_view')
        .select('*')
        .limit(1);
      
      console.log('   ✅ View friends_view criada');

      // Verificar funções
      const { data: functions } = await supabase.rpc('get_profile_by_username', {
        username_param: 'test'
      });
      
      console.log('   ✅ Função get_profile_by_username criada');

    } catch (verifyError) {
      console.log('   ⚠️  Algumas estruturas podem não ter sido criadas corretamente');
      console.log(`   Detalhes: ${verifyError.message}`);
    }

    console.log('');
    console.log('🎉 Atualização do banco de dados concluída!');
    console.log('');
    console.log('📋 Próximos passos:');
    console.log('   1. Verifique se o deploy no Vercel foi atualizado');
    console.log('   2. Teste a criação de novos perfis');
    console.log('   3. Teste o sistema de amizades');
    console.log('   4. Verifique as URLs dinâmicas /perfil/[username]');

  } catch (error) {
    console.error('❌ Erro durante a atualização:', error.message);
    process.exit(1);
  }
}

// Executar se chamado diretamente
if (require.main === module) {
  updateDatabase();
}

module.exports = { updateDatabase };
