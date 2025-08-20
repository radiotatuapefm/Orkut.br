const { createClient } = require('@supabase/supabase-js')

// Configuração do Supabase com Service Role Key (para operações administrativas)
const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function executeSQL(sql, description) {
  console.log(`🚀 ${description}...`)
  
  try {
    const { data, error } = await supabase.rpc('exec_sql', { sql })
    
    if (error) {
      console.error(`❌ Erro em ${description}:`, error.message)
      return false
    } else {
      console.log(`✅ ${description} - Sucesso!`)
      return true
    }
  } catch (err) {
    console.error(`❌ Erro geral em ${description}:`, err.message)
    return false
  }
}

async function createProfilesTable() {
  const sql = `
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

    -- Remover políticas existentes se houver
    DROP POLICY IF EXISTS "Profiles são visíveis por todos" ON public.profiles;
    DROP POLICY IF EXISTS "Usuários podem atualizar próprio perfil" ON public.profiles;
    DROP POLICY IF EXISTS "Usuários podem inserir próprio perfil" ON public.profiles;

    -- Criar políticas de acesso
    CREATE POLICY "Profiles são visíveis por todos" 
        ON public.profiles FOR SELECT 
        USING (true);

    CREATE POLICY "Usuários podem atualizar próprio perfil" 
        ON public.profiles FOR UPDATE 
        USING (auth.uid() = id);

    CREATE POLICY "Usuários podem inserir próprio perfil" 
        ON public.profiles FOR INSERT 
        WITH CHECK (auth.uid() = id);
  `
  
  return await executeSQL(sql, 'Criando tabela profiles')
}

async function createSettingsTable() {
  const sql = `
    -- Criar tabela settings
    CREATE TABLE IF NOT EXISTS public.settings (
        profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
        voice_enabled boolean DEFAULT false,
        locale text DEFAULT 'pt-BR',
        notifications_enabled boolean DEFAULT true,
        tts_speed real DEFAULT 1.0,
        tts_volume real DEFAULT 0.8,
        updated_at timestamptz DEFAULT now()
    );

    -- Habilitar RLS
    ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

    -- Remover política existente se houver
    DROP POLICY IF EXISTS "Usuários podem gerenciar próprias configurações" ON public.settings;

    -- Criar política de acesso
    CREATE POLICY "Usuários podem gerenciar próprias configurações"
        ON public.settings FOR ALL
        USING (auth.uid() = profile_id)
        WITH CHECK (auth.uid() = profile_id);
  `
  
  return await executeSQL(sql, 'Criando tabela settings')
}

async function createUserTrigger() {
  const sql = `
    -- Criar função trigger para criar perfil automaticamente
    CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS trigger AS $$
    BEGIN
        INSERT INTO public.profiles (id, username, display_name)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
            COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
        );
        
        -- Criar configurações padrão
        INSERT INTO public.settings (profile_id)
        VALUES (NEW.id)
        ON CONFLICT (profile_id) DO NOTHING;
        
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- Remover trigger existente se houver
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

    -- Criar trigger para executar quando um novo usuário se registra
    CREATE TRIGGER on_auth_user_created
        AFTER INSERT ON auth.users
        FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  `
  
  return await executeSQL(sql, 'Criando trigger de usuário')
}

async function createCommunitiesTable() {
  const sql = `
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

    -- Habilitar RLS
    ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

    -- Remover políticas existentes se houver
    DROP POLICY IF EXISTS "Communities são visíveis por todos" ON public.communities;
    DROP POLICY IF EXISTS "Usuários autenticados podem criar comunidades" ON public.communities;

    -- Criar políticas de acesso
    CREATE POLICY "Communities são visíveis por todos"
        ON public.communities FOR SELECT
        USING (true);

    CREATE POLICY "Usuários autenticados podem criar comunidades"
        ON public.communities FOR INSERT
        WITH CHECK (auth.uid() = owner);
  `
  
  return await executeSQL(sql, 'Criando tabela communities')
}

async function insertDemoData() {
  const sql = `
    -- Inserir comunidades de demonstração
    INSERT INTO public.communities (name, description, category, photo_url, members_count) VALUES
    ('Nostalgia dos Anos 2000', 'Relembre os bons tempos dos anos 2000! Músicas, filmes, jogos e muito mais.', 'Nostalgia', 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200', 1250),
    ('Música', 'Comunidade para compartilhar e descobrir novas músicas de todos os gêneros.', 'Música', 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200', 3420),
    ('Tecnologia', 'Discussões sobre as últimas novidades em tecnologia, programação e inovação.', 'Tecnologia', 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200', 2800),
    ('Jogos Retrô', 'Para os amantes dos jogos clássicos! Arcade, Atari, Nintendo e muito mais.', 'Jogos', 'https://images.pexels.com/photos/1298601/pexels-photo-1298601.jpeg?auto=compress&cs=tinysrgb&w=200', 890),
    ('Humor', 'O melhor do humor brasileiro! Piadas, memes e muita diversão.', 'Entretenimento', 'https://images.pexels.com/photos/1477166/pexels-photo-1477166.jpeg?auto=compress&cs=tinysrgb&w=200', 5600)
    ON CONFLICT (name) DO NOTHING;
  `
  
  return await executeSQL(sql, 'Inserindo dados de demonstração')
}

async function createPostsTables() {
  const sql = `
    -- Criar tabela posts
    CREATE TABLE IF NOT EXISTS public.posts (
        id bigserial PRIMARY KEY,
        author uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
        content text NOT NULL,
        visibility text CHECK (visibility IN ('public','friends')) DEFAULT 'public',
        likes_count integer DEFAULT 0,
        comments_count integer DEFAULT 0,
        created_at timestamptz DEFAULT now()
    );

    -- Criar tabela likes
    CREATE TABLE IF NOT EXISTS public.likes (
        post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE,
        profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
        created_at timestamptz DEFAULT now(),
        PRIMARY KEY (post_id, profile_id)
    );

    -- Habilitar RLS
    ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

    -- Remover políticas existentes
    DROP POLICY IF EXISTS "Posts públicos visíveis por todos" ON public.posts;
    DROP POLICY IF EXISTS "Usuários podem criar posts" ON public.posts;
    DROP POLICY IF EXISTS "Likes visíveis por todos" ON public.likes;
    DROP POLICY IF EXISTS "Usuários podem gerenciar próprios likes" ON public.likes;

    -- Políticas para posts
    CREATE POLICY "Posts públicos visíveis por todos"
        ON public.posts FOR SELECT
        USING (visibility = 'public' OR auth.uid() = author);

    CREATE POLICY "Usuários podem criar posts"
        ON public.posts FOR INSERT
        WITH CHECK (auth.uid() = author);

    -- Políticas para likes
    CREATE POLICY "Likes visíveis por todos"
        ON public.likes FOR SELECT
        USING (true);

    CREATE POLICY "Usuários podem gerenciar próprios likes"
        ON public.likes FOR ALL
        USING (auth.uid() = profile_id)
        WITH CHECK (auth.uid() = profile_id);
  `
  
  return await executeSQL(sql, 'Criando tabelas de posts e likes')
}

async function checkTables() {
  console.log('🔍 Verificando tabelas criadas...')
  
  try {
    const { data: tables, error } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .in('table_name', ['profiles', 'settings', 'communities', 'posts', 'likes'])
    
    if (error) {
      console.error('❌ Erro ao verificar tabelas:', error.message)
      return false
    }
    
    const tableNames = tables.map(t => t.table_name).sort()
    console.log('📊 Tabelas encontradas:', tableNames)
    
    const expectedTables = ['communities', 'likes', 'posts', 'profiles', 'settings']
    const allTablesExist = expectedTables.every(table => tableNames.includes(table))
    
    if (allTablesExist) {
      console.log('✅ Todas as tabelas essenciais foram criadas!')
      return true
    } else {
      console.log('⚠️ Algumas tabelas ainda não foram criadas')
      return false
    }
  } catch (err) {
    console.error('❌ Erro geral ao verificar tabelas:', err.message)
    return false
  }
}

async function testDatabaseConnection() {
  console.log('🔌 Testando conexão com o banco de dados...')
  
  try {
    const { data, error } = await supabase
      .from('communities')
      .select('count(*)')
      .limit(1)
    
    if (error) {
      console.error('❌ Erro na conexão:', error.message)
      return false
    }
    
    console.log('✅ Conexão com banco de dados funcionando!')
    return true
  } catch (err) {
    console.error('❌ Erro de conexão:', err.message)
    return false
  }
}

async function main() {
  console.log('🗄️ CONFIGURAÇÃO DO BANCO DE DADOS ORKUT.BR')
  console.log('===============================================\n')
  
  let success = true
  
  // Testar conexão
  success = await testDatabaseConnection() && success
  
  // Criar tabelas em ordem
  success = await createProfilesTable() && success
  success = await createSettingsTable() && success
  success = await createUserTrigger() && success
  success = await createCommunitiesTable() && success
  success = await insertDemoData() && success
  success = await createPostsTables() && success
  
  // Verificar resultado
  console.log('\n===============================================')
  if (success && await checkTables()) {
    console.log('🎉 BANCO DE DADOS CONFIGURADO COM SUCESSO!')
    console.log('✅ Agora você pode testar a aplicação:')
    console.log('🔗 https://orkut-qa4td7ulz-astridnielsen-labs-projects.vercel.app')
    console.log('\n📝 Próximos passos:')
    console.log('1. Acesse o link acima')
    console.log('2. Clique em "Cadastrar"')
    console.log('3. Crie uma nova conta')
    console.log('4. O perfil será criado automaticamente!')
  } else {
    console.log('❌ Houve alguns problemas na configuração.')
    console.log('💡 Tente executar o script novamente ou configure manualmente no Supabase Dashboard.')
  }
}

main().catch(console.error)
