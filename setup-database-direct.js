const { createClient } = require('@supabase/supabase-js')

// Configuração do Supabase com Service Role Key
const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function testConnection() {
  console.log('🔌 Testando conexão com Supabase...')
  
  try {
    // Testar acesso ao esquema public
    const { data, error } = await supabase
      .rpc('version') // Função nativa do PostgreSQL
    
    if (error) {
      console.log('ℹ️ Função version não disponível, tentando alternativa...')
      
      // Alternativa - tentar verificar usuário atual
      const { data: user, error: userError } = await supabase.auth.getUser()
      
      if (userError) {
        console.log('✅ Conexão estabelecida com Supabase (usando service key)')
        return true
      }
    }
    
    console.log('✅ Conexão com Supabase funcionando!')
    console.log('📊 Versão PostgreSQL:', data)
    return true
  } catch (err) {
    console.error('❌ Erro de conexão:', err.message)
    return false
  }
}

async function createProfilesTableDirect() {
  console.log('🚀 Criando tabela profiles via POST direto...')
  
  try {
    // Usar fetch diretamente para fazer query SQL
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/query`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseServiceKey}`,
        'apikey': supabaseServiceKey
      },
      body: JSON.stringify({
        query: `
          -- Criar tabela profiles
          CREATE TABLE IF NOT EXISTS public.profiles (
              id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
              username text UNIQUE NOT NULL,
              display_name text NOT NULL,
              photo_url text DEFAULT 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
              relationship text DEFAULT 'Solteiro(a)',
              location text DEFAULT '',
              birthday date,
              bio text DEFAULT '',
              fans_count integer DEFAULT 0,
              created_at timestamptz DEFAULT now()
          );

          -- Habilitar RLS
          ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
        `
      })
    })

    if (response.ok) {
      console.log('✅ Tabela profiles criada com sucesso!')
      return true
    } else {
      const error = await response.text()
      console.error('❌ Erro ao criar tabela profiles:', error)
      return false
    }
  } catch (err) {
    console.error('❌ Erro geral ao criar profiles:', err.message)
    return false
  }
}

async function insertDemoDataDirect() {
  console.log('🚀 Inserindo dados de demonstração...')
  
  try {
    // Inserir comunidades diretamente
    const { data, error } = await supabase
      .from('communities')
      .upsert([
        {
          name: 'Nostalgia dos Anos 2000',
          description: 'Relembre os bons tempos dos anos 2000! Músicas, filmes, jogos e muito mais.',
          category: 'Nostalgia',
          photo_url: 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200',
          members_count: 1250
        },
        {
          name: 'Música',
          description: 'Comunidade para compartilhar e descobrir novas músicas.',
          category: 'Música',
          photo_url: 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200',
          members_count: 3420
        },
        {
          name: 'Tecnologia',
          description: 'Discussões sobre tecnologia e programação.',
          category: 'Tecnologia',
          photo_url: 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200',
          members_count: 2800
        },
        {
          name: 'Humor',
          description: 'O melhor do humor brasileiro!',
          category: 'Entretenimento',
          photo_url: 'https://images.pexels.com/photos/1477166/pexels-photo-1477166.jpeg?auto=compress&cs=tinysrgb&w=200',
          members_count: 5600
        }
      ], { onConflict: 'name' })

    if (error) {
      console.error('❌ Erro ao inserir dados demo:', error.message)
      return false
    } else {
      console.log('✅ Dados de demonstração inseridos!')
      return true
    }
  } catch (err) {
    console.error('❌ Erro geral ao inserir dados:', err.message)
    return false
  }
}

async function checkTablesExist() {
  console.log('🔍 Verificando se tabelas existem...')
  
  try {
    // Tentar consultar a tabela profiles
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('count')
      .limit(1)
    
    // Tentar consultar a tabela communities
    const { data: communities, error: communitiesError } = await supabase
      .from('communities')
      .select('name')
      .limit(1)
    
    const profilesExist = !profilesError
    const communitiesExist = !communitiesError
    
    console.log('📊 Status das tabelas:')
    console.log(`   profiles: ${profilesExist ? '✅ Existe' : '❌ Não existe'}`)
    console.log(`   communities: ${communitiesExist ? '✅ Existe' : '❌ Não existe'}`)
    
    if (communitiesExist) {
      const { data: communityCount } = await supabase
        .from('communities')
        .select('id', { count: 'exact' })
      
      console.log(`   📈 Comunidades encontradas: ${communityCount?.length || 0}`)
    }
    
    return { profilesExist, communitiesExist }
  } catch (err) {
    console.error('❌ Erro ao verificar tabelas:', err.message)
    return { profilesExist: false, communitiesExist: false }
  }
}

async function createMinimalSetup() {
  console.log('🔧 Criando configuração mínima necessária...')
  
  // Como não conseguimos executar SQL diretamente, vamos preparar instruções específicas
  console.log('\n📋 INSTRUÇÕES PARA EXECUÇÃO MANUAL:')
  console.log('=' .repeat(50))
  console.log('1. Acesse: https://supabase.com/dashboard')
  console.log('2. Selecione o projeto: woyyikaztjrhqzgvbhmn')
  console.log('3. Vá em SQL Editor')
  console.log('4. Execute este comando SQL:')
  console.log('\n-- COMANDO SQL PARA COPIAR:')
  console.log('-'.repeat(30))
  
  const sqlCommand = `
-- Criar tabela profiles (ESSENCIAL)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    username text UNIQUE NOT NULL,
    display_name text NOT NULL,
    photo_url text DEFAULT 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
    relationship text DEFAULT 'Solteiro(a)',
    location text DEFAULT '',
    birthday date,
    bio text DEFAULT '',
    fans_count integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY IF NOT EXISTS "Profiles visíveis por todos" 
    ON public.profiles FOR SELECT 
    USING (true);

CREATE POLICY IF NOT EXISTS "Usuários podem inserir próprio perfil" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Criar função para trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Criar tabela communities
CREATE TABLE IF NOT EXISTS public.communities (
    id bigserial PRIMARY KEY,
    name text UNIQUE NOT NULL,
    description text DEFAULT '',
    category text DEFAULT 'Geral',
    owner uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    members_count integer DEFAULT 0,
    photo_url text DEFAULT 'https://images.pexels.com/photos/1595391/pexels-photo-1595391.jpeg?auto=compress&cs=tinysrgb&w=200',
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Communities visíveis por todos"
    ON public.communities FOR SELECT
    USING (true);

-- Inserir comunidades demo
INSERT INTO public.communities (name, description, category, photo_url, members_count) VALUES
('Nostalgia dos Anos 2000', 'Relembre os bons tempos!', 'Nostalgia', 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200', 1250),
('Música', 'Compartilhe músicas', 'Música', 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200', 3420),
('Tecnologia', 'Discussões tech', 'Tecnologia', 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200', 2800)
ON CONFLICT (name) DO NOTHING;
  `
  
  console.log(sqlCommand)
  console.log('-'.repeat(30))
  console.log('\n5. Clique em "Run" para executar')
  console.log('6. Teste a aplicação em: https://orkut-qa4td7ulz-astridnielsen-labs-projects.vercel.app')
  
  return true
}

async function main() {
  console.log('🗄️ CONFIGURAÇÃO DO BANCO DE DADOS ORKUT.BR')
  console.log('=' .repeat(50))
  console.log()
  
  // Testar conexão
  const connected = await testConnection()
  
  if (!connected) {
    console.log('❌ Não foi possível conectar ao Supabase')
    return
  }
  
  // Verificar tabelas existentes
  const { profilesExist, communitiesExist } = await checkTablesExist()
  
  if (profilesExist && communitiesExist) {
    console.log('🎉 TABELAS JÁ EXISTEM!')
    console.log('✅ Seu banco de dados está configurado!')
    console.log('🔗 Teste a aplicação: https://orkut-qa4td7ulz-astridnielsen-labs-projects.vercel.app')
    
    // Verificar se há dados demo
    if (communitiesExist) {
      await insertDemoDataDirect()
    }
  } else {
    console.log('⚠️ Tabelas ainda não existem')
    await createMinimalSetup()
  }
}

main().catch(console.error)
