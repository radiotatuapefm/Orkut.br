-- ========================================
-- SCRIPT DE CONFIGURAÇÃO COMPLETA DO BANCO
-- Execute este script no SQL Editor do Supabase
-- ========================================

-- 1. CRIAR TABELA DE PERFIS (atualizada)
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

-- 2. CRIAR TABELA DE POSTS
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

-- 3. CRIAR TABELA DE AMIZADES
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

-- 4. CRIAR TABELA DE MENSAGENS
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

-- 5. CRIAR TABELA DE COMUNIDADES
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

-- 6. CRIAR TABELA DE MEMBROS DE COMUNIDADES
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

-- 7. CRIAR TABELA DE PRESENÇA ONLINE
CREATE TABLE IF NOT EXISTS presence (
  profile_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  online BOOLEAN DEFAULT false,
  status VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('online', 'away', 'busy', 'offline')),
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- FUNÇÕES RPC
-- ========================================

-- Função para buscar perfil por username
CREATE OR REPLACE FUNCTION get_profile_by_username(username_param TEXT)
RETURNS TABLE (
  id UUID,
  name TEXT,
  username TEXT,
  email TEXT,
  avatar_url TEXT,
  phone TEXT,
  whatsapp_enabled BOOLEAN,
  privacy_settings JSONB,
  created_at TIMESTAMP WITH TIME ZONE,
  bio TEXT,
  location TEXT,
  relationship TEXT,
  website TEXT,
  fans_count INTEGER,
  views_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.display_name as name,
    p.username,
    p.email,
    p.photo_url as avatar_url,
    p.phone,
    p.whatsapp_enabled,
    p.privacy_settings,
    p.created_at,
    p.bio,
    p.location,
    p.relationship,
    p.website,
    p.fans_count,
    p.views_count
  FROM profiles p
  WHERE p.username = username_param;
END;
$$;

-- Função para buscar usuários
CREATE OR REPLACE FUNCTION search_users(search_term TEXT)
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  photo_url TEXT,
  location TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.username,
    p.display_name,
    p.photo_url,
    p.location
  FROM profiles p
  WHERE 
    p.username ILIKE '%' || search_term || '%' OR
    p.display_name ILIKE '%' || search_term || '%' OR
    p.email ILIKE '%' || search_term || '%'
  ORDER BY p.display_name
  LIMIT 50;
END;
$$;

-- Função para criar perfil completo
CREATE OR REPLACE FUNCTION create_complete_user_profile(
  user_email TEXT,
  user_username TEXT,
  user_display_name TEXT,
  user_phone TEXT DEFAULT NULL,
  user_bio TEXT DEFAULT NULL,
  user_location TEXT DEFAULT NULL,
  user_photo_url TEXT DEFAULT NULL
)
RETURNS TABLE (
  user_id UUID,
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Verificar se username já existe
  IF EXISTS (SELECT 1 FROM profiles WHERE username = user_username) THEN
    RETURN QUERY SELECT NULL::UUID, false, 'Username já está em uso';
    RETURN;
  END IF;
  
  -- Verificar se email já existe
  IF EXISTS (SELECT 1 FROM profiles WHERE email = user_email) THEN
    RETURN QUERY SELECT NULL::UUID, false, 'Email já está em uso';
    RETURN;
  END IF;
  
  -- Gerar novo ID único
  new_user_id := gen_random_uuid();
  
  -- Criar perfil
  INSERT INTO profiles (
    id, username, display_name, email, phone, bio, location, photo_url,
    whatsapp_enabled, privacy_settings, fans_count, views_count
  ) VALUES (
    new_user_id, user_username, user_display_name, user_email, user_phone, 
    user_bio, user_location, user_photo_url,
    COALESCE(user_phone IS NOT NULL, false),
    '{"profile": "public", "phone": "friends"}',
    0, 0
  );
  
  -- Criar presença
  INSERT INTO presence (profile_id, online, status, last_seen) 
  VALUES (new_user_id, false, 'offline', NOW());
  
  RETURN QUERY SELECT new_user_id, true, 'Perfil criado com sucesso';
END;
$$;

-- ========================================
-- POLÍTICAS DE SEGURANÇA (RLS)
-- ========================================

-- Habilitar RLS nas tabelas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE presence ENABLE ROW LEVEL SECURITY;

-- Políticas para profiles (público para leitura, próprio usuário para escrita)
CREATE POLICY "Perfis públicos para leitura" ON profiles FOR SELECT USING (true);
CREATE POLICY "Usuários podem atualizar próprio perfil" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Usuários podem inserir próprio perfil" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Políticas para posts (público para leitura, próprio usuário para escrita)
CREATE POLICY "Posts públicos para leitura" ON posts FOR SELECT USING (privacy = 'public' OR user_id = auth.uid());
CREATE POLICY "Usuários podem criar posts" ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuários podem atualizar próprios posts" ON posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Usuários podem deletar próprios posts" ON posts FOR DELETE USING (auth.uid() = user_id);

-- Políticas para friendships
CREATE POLICY "Usuários podem ver próprias amizades" ON friendships FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Usuários podem criar pedidos de amizade" ON friendships FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Usuários podem atualizar próprias amizades" ON friendships FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Políticas para messages
CREATE POLICY "Usuários podem ver próprias mensagens" ON messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Usuários podem enviar mensagens" ON messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Usuários podem atualizar próprias mensagens" ON messages FOR UPDATE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Políticas para communities
CREATE POLICY "Comunidades públicas para leitura" ON communities FOR SELECT USING (privacy = 'public' OR creator_id = auth.uid());
CREATE POLICY "Usuários podem criar comunidades" ON communities FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Criadores podem atualizar comunidades" ON communities FOR UPDATE USING (auth.uid() = creator_id);

-- Políticas para community_members
CREATE POLICY "Membros podem ver comunidades que participam" ON community_members FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Usuários podem se juntar a comunidades" ON community_members FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para presence
CREATE POLICY "Presença pública para leitura" ON presence FOR SELECT USING (true);
CREATE POLICY "Usuários podem atualizar própria presença" ON presence FOR UPDATE USING (auth.uid() = profile_id);
CREATE POLICY "Usuários podem inserir própria presença" ON presence FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- ========================================
-- TRIGGERS PARA ATUALIZAÇÕES AUTOMÁTICAS
-- ========================================

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- DADOS INICIAIS (se necessário)
-- ========================================

-- Inserir perfil do Marcelo se não existir
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE username = 'marcelooliver') THEN
    -- Primeiro verificar se o usuário existe na auth
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = 'zarzamorera@gmail.com') THEN
      -- Inserir perfil usando o ID existente da auth
      INSERT INTO profiles (
        id, username, display_name, email, phone, photo_url, bio, location, relationship,
        whatsapp_enabled, privacy_settings, fans_count, views_count
      ) 
      SELECT 
        u.id, 'marcelooliver', 'Marcelo Oliver', 'zarzamorera@gmail.com', NULL, '/marcelo.png',
        'Gerente de Projetos especializado em desenvolvimento de software e gestão de equipes. Apaixonado por tecnologia e inovação.',
        'São Paulo, SP', 'Casado(a)', false, 
        '{"profile": "public", "phone": "friends"}', 0, 0
      FROM auth.users u 
      WHERE u.email = 'zarzamorera@gmail.com';
      
      -- Criar presença para Marcelo
      INSERT INTO presence (profile_id, online, status, last_seen)
      SELECT id, false, 'offline', NOW()
      FROM profiles WHERE username = 'marcelooliver';
    END IF;
  END IF;
END $$;
