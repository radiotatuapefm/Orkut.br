const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function setupDatabase() {
  console.log('🚀 Configurando estrutura completa do banco de dados...\n')

  try {
    // 1. Criar tabela de perfis (se não existir)
    console.log('1️⃣ Configurando tabela PROFILES...')
    await supabase.rpc('exec_sql', {
      sql: `
        -- Tabela de perfis de usuários
        CREATE TABLE IF NOT EXISTS profiles (
          id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
          username VARCHAR(50) UNIQUE NOT NULL,
          display_name VARCHAR(100) NOT NULL,
          email VARCHAR(255) NOT NULL,
          phone VARCHAR(20),
          photo_url TEXT,
          bio TEXT,
          location VARCHAR(100),
          relationship VARCHAR(50),
          website VARCHAR(255),
          fans_count INTEGER DEFAULT 0,
          views_count INTEGER DEFAULT 0,
          whatsapp_enabled BOOLEAN DEFAULT false,
          privacy_settings JSONB DEFAULT '{"profile": "public", "phone": "friends"}',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        -- Índices para performance
        CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
        CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
        CREATE INDEX IF NOT EXISTS idx_profiles_display_name ON profiles(display_name);
      `
    })
    console.log('✅ Tabela PROFILES configurada')

    // 2. Criar tabela de posts
    console.log('2️⃣ Configurando tabela POSTS...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS posts (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          content TEXT NOT NULL,
          image_url TEXT,
          likes_count INTEGER DEFAULT 0,
          comments_count INTEGER DEFAULT 0,
          privacy VARCHAR(20) DEFAULT 'public' CHECK (privacy IN ('public', 'friends', 'private')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
        CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at);
      `
    })
    console.log('✅ Tabela POSTS configurada')

    // 3. Criar tabela de amizades
    console.log('3️⃣ Configurando tabela FRIENDSHIPS...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS friendships (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          accepted_at TIMESTAMP WITH TIME ZONE,
          UNIQUE(user_id, friend_id)
        );

        CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
        CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
        CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);
      `
    })
    console.log('✅ Tabela FRIENDSHIPS configurada')

    // 4. Criar tabela de mensagens
    console.log('4️⃣ Configurando tabela MESSAGES...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS messages (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          content TEXT NOT NULL,
          read_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
        CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
        CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);
      `
    })
    console.log('✅ Tabela MESSAGES configurada')

    // 5. Criar tabela de comunidades
    console.log('5️⃣ Configurando tabela COMMUNITIES...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS communities (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name VARCHAR(100) NOT NULL,
          description TEXT,
          image_url TEXT,
          creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          members_count INTEGER DEFAULT 0,
          privacy VARCHAR(20) DEFAULT 'public' CHECK (privacy IN ('public', 'private')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_communities_creator_id ON communities(creator_id);
        CREATE INDEX IF NOT EXISTS idx_communities_name ON communities(name);
      `
    })
    console.log('✅ Tabela COMMUNITIES configurada')

    // 6. Criar tabela de membros de comunidades
    console.log('6️⃣ Configurando tabela COMMUNITY_MEMBERS...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS community_members (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
          user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
          joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(community_id, user_id)
        );

        CREATE INDEX IF NOT EXISTS idx_community_members_community_id ON community_members(community_id);
        CREATE INDEX IF NOT EXISTS idx_community_members_user_id ON community_members(user_id);
      `
    })
    console.log('✅ Tabela COMMUNITY_MEMBERS configurada')

    // 7. Criar tabela de presença online
    console.log('7️⃣ Configurando tabela PRESENCE...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS presence (
          profile_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
          online BOOLEAN DEFAULT false,
          status VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('online', 'away', 'busy', 'offline')),
          last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      `
    })
    console.log('✅ Tabela PRESENCE configurada')

    console.log('\n🎉 Estrutura do banco de dados criada com sucesso!')

  } catch (error) {
    console.error('❌ Erro ao configurar banco:', error.message)
  }
}

setupDatabase()
