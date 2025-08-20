-- ============================================================================
-- ORKUT RETRÔ - SETUP SEGURO DO BANCO DE DADOS
-- Execute este script no editor SQL do Supabase
-- Este script PRESERVA dados existentes e apenas adiciona o que está faltando
-- ============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. ATUALIZAR TABELA DE PERFIS (sem remover dados existentes)
-- ============================================================================

-- Adicionar colunas que podem estar faltando (se não existirem)
DO $$ 
BEGIN
    -- Verificar e adicionar coluna bio se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'bio') THEN
        ALTER TABLE public.profiles ADD COLUMN bio TEXT;
    END IF;

    -- Verificar e adicionar coluna location se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'location') THEN
        ALTER TABLE public.profiles ADD COLUMN location VARCHAR(100);
    END IF;

    -- Verificar e adicionar coluna birthday se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'birthday') THEN
        ALTER TABLE public.profiles ADD COLUMN birthday DATE;
    END IF;

    -- Verificar e adicionar coluna relationship se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'relationship') THEN
        ALTER TABLE public.profiles ADD COLUMN relationship VARCHAR(50);
    END IF;

    -- Verificar e adicionar coluna fans_count se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'fans_count') THEN
        ALTER TABLE public.profiles ADD COLUMN fans_count INTEGER DEFAULT 0;
    END IF;

    -- Verificar e adicionar coluna updated_at se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'updated_at') THEN
        ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- ============================================================================
-- 2. CRIAR TABELAS QUE NÃO EXISTEM
-- ============================================================================

-- Criar tabela friendships se não existir
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    requester_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    addressee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, addressee_id)
);

-- Criar tabela posts se não existir
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela messages se não existir
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar tabela user_status se não existir
CREATE TABLE IF NOT EXISTS public.user_status (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    status VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('online', 'away', 'busy', 'offline')),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 3. CRIAR ÍNDICES (se não existirem)
-- ============================================================================

-- Índices para profiles
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at);

-- Índices para friendships
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- Índices para posts
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);

-- Índices para messages
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

-- Índices para user_status
CREATE INDEX IF NOT EXISTS idx_user_status_status ON public.user_status(status);
CREATE INDEX IF NOT EXISTS idx_user_status_last_seen ON public.user_status(last_seen);

-- ============================================================================
-- 4. FUNÇÕES RPC (substituir/criar)
-- ============================================================================

-- Função para buscar perfil por username
CREATE OR REPLACE FUNCTION get_profile_by_username(username_param TEXT)
RETURNS TABLE (
    id UUID,
    username VARCHAR(50),
    name VARCHAR(100),
    email VARCHAR(255),
    avatar_url TEXT,
    phone VARCHAR(20),
    bio TEXT,
    location VARCHAR(100),
    birthday DATE,
    relationship VARCHAR(50),
    whatsapp_enabled BOOLEAN,
    privacy_settings JSONB,
    fans_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        p.name,
        p.email,
        p.avatar_url,
        p.phone,
        p.bio,
        p.location,
        p.birthday,
        p.relationship,
        p.whatsapp_enabled,
        p.privacy_settings,
        p.fans_count,
        p.created_at
    FROM public.profiles p
    WHERE p.username = username_param;
END;
$$;

-- Função para verificar se username existe
CREATE OR REPLACE FUNCTION check_username_exists(username_param TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE username = username_param
    );
END;
$$;

-- Função para buscar amigos
CREATE OR REPLACE FUNCTION get_user_friends(user_id_param UUID)
RETURNS TABLE (
    friend_id UUID,
    friend_username VARCHAR(50),
    friend_name VARCHAR(100),
    friend_avatar_url TEXT,
    friendship_created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN f.requester_id = user_id_param THEN f.addressee_id
            ELSE f.requester_id
        END as friend_id,
        p.username as friend_username,
        p.name as friend_name,
        p.avatar_url as friend_avatar_url,
        f.created_at as friendship_created_at
    FROM public.friendships f
    JOIN public.profiles p ON (
        CASE 
            WHEN f.requester_id = user_id_param THEN p.id = f.addressee_id
            ELSE p.id = f.requester_id
        END
    )
    WHERE (f.requester_id = user_id_param OR f.addressee_id = user_id_param)
    AND f.status = 'accepted'
    ORDER BY f.created_at DESC;
END;
$$;

-- ============================================================================
-- 5. CRIAR TRIGGERS PARA UPDATED_AT (se não existirem)
-- ============================================================================

-- Função genérica para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Criar triggers apenas se não existirem
DO $$
BEGIN
    -- Trigger para profiles
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
                   WHERE trigger_name = 'update_profiles_updated_at') THEN
        CREATE TRIGGER update_profiles_updated_at
            BEFORE UPDATE ON public.profiles
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- Trigger para friendships
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
                   WHERE trigger_name = 'update_friendships_updated_at') THEN
        CREATE TRIGGER update_friendships_updated_at
            BEFORE UPDATE ON public.friendships
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- Trigger para posts
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
                   WHERE trigger_name = 'update_posts_updated_at') THEN
        CREATE TRIGGER update_posts_updated_at
            BEFORE UPDATE ON public.posts
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- Trigger para user_status
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
                   WHERE trigger_name = 'update_user_status_updated_at') THEN
        CREATE TRIGGER update_user_status_updated_at
            BEFORE UPDATE ON public.user_status
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- ============================================================================
-- 6. CONFIGURAR RLS APENAS SE NÃO ESTIVER ATIVO
-- ============================================================================

-- Habilitar RLS se não estiver habilitado
DO $$
BEGIN
    -- Profiles
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'profiles' AND rowsecurity = true) THEN
        ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Criar políticas básicas para profiles
DO $$
BEGIN
    -- Política de leitura pública
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Profiles são visíveis publicamente') THEN
        CREATE POLICY "Profiles são visíveis publicamente" ON public.profiles
            FOR SELECT USING (true);
    END IF;

    -- Política de inserção
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Usuários podem inserir seu próprio perfil') THEN
        CREATE POLICY "Usuários podem inserir seu próprio perfil" ON public.profiles
            FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;

    -- Política de atualização
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Usuários podem atualizar seu próprio perfil') THEN
        CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON public.profiles
            FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- ============================================================================
-- 7. PERMISSÕES
-- ============================================================================

-- Permitir acesso público às funções RPC
GRANT EXECUTE ON FUNCTION get_profile_by_username(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_username_exists(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_user_friends(UUID) TO authenticated;

-- Permitir acesso às tabelas
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

-- ============================================================================
-- 8. ATUALIZAR PERFIL DO MARCELO (usando ID real)
-- ============================================================================

-- Primeiro, vamos verificar se o Marcelo já existe e pegar o ID real
DO $$
DECLARE
    marcelo_id UUID;
BEGIN
    -- Buscar ID do Marcelo se ele já existir
    SELECT id INTO marcelo_id FROM public.profiles WHERE username = 'marcelooliver';
    
    -- Se encontrou, atualizar dados
    IF marcelo_id IS NOT NULL THEN
        UPDATE public.profiles SET
            name = 'Marcelo Oliver',
            email = 'marcelo.oliver@empresa.com',
            avatar_url = '/marcelo-profile.jpg',
            phone = '+5511987654321',
            bio = 'Gerente de Projetos experiente com mais de 10 anos de experiência. Apaixonado por tecnologia e inovação.',
            location = 'São Paulo, SP',
            relationship = 'Casado',
            whatsapp_enabled = true,
            privacy_settings = '{"phone_visibility": "public", "profile_visibility": "public"}'::jsonb,
            fans_count = 42
        WHERE id = marcelo_id;
        
        RAISE NOTICE '✅ Perfil do Marcelo atualizado com sucesso!';
    ELSE
        RAISE NOTICE '⚠️  Perfil do Marcelo não encontrado. Será necessário criar via cadastro normal.';
    END IF;
END $$;

-- ============================================================================
-- VERIFICAÇÃO FINAL
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Setup seguro concluído!';
    RAISE NOTICE '📊 Estrutura atualizada preservando dados existentes';
    RAISE NOTICE '🔧 Funções RPC criadas/atualizadas';
    RAISE NOTICE '🔒 Políticas RLS configuradas';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Execute agora: SELECT * FROM public.profiles; para verificar os dados';
END $$;
