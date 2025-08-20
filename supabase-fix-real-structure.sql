-- ============================================================================
-- ORKUT RETRÔ - CORRIGIR BASEADO NA ESTRUTURA REAL
-- Execute este script no editor SQL do Supabase
-- ============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. ADICIONAR COLUNAS QUE PODEM ESTAR FALTANDO
-- ============================================================================

DO $$ 
BEGIN
    RAISE NOTICE 'Verificando estrutura atual da tabela profiles...';

    -- Adicionar coluna email se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE public.profiles ADD COLUMN email VARCHAR(255);
        RAISE NOTICE '✅ Coluna email adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna email já existe';
    END IF;

    -- Adicionar coluna phone se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'phone') THEN
        ALTER TABLE public.profiles ADD COLUMN phone VARCHAR(20);
        RAISE NOTICE '✅ Coluna phone adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna phone já existe';
    END IF;

    -- Adicionar coluna whatsapp_enabled se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'whatsapp_enabled') THEN
        ALTER TABLE public.profiles ADD COLUMN whatsapp_enabled BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Coluna whatsapp_enabled adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna whatsapp_enabled já existe';
    END IF;

    -- Adicionar coluna privacy_settings se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'privacy_settings') THEN
        ALTER TABLE public.profiles ADD COLUMN privacy_settings JSONB DEFAULT '{"phone_visibility": "friends", "profile_visibility": "public"}'::jsonb;
        RAISE NOTICE '✅ Coluna privacy_settings adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna privacy_settings já existe';
    END IF;

    -- Adicionar coluna updated_at se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'updated_at') THEN
        ALTER TABLE public.profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Coluna updated_at adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna updated_at já existe';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '🎉 Verificação de colunas concluída!';
END $$;

-- ============================================================================
-- 2. CRIAR FUNÇÃO RPC BASEADA NA ESTRUTURA REAL
-- ============================================================================

-- Função para buscar perfil por username (usando colunas que existem)
CREATE OR REPLACE FUNCTION get_profile_by_username(username_param TEXT)
RETURNS TABLE (
    id UUID,
    username VARCHAR(50),
    display_name TEXT,
    photo_url TEXT,
    relationship TEXT,
    location TEXT,
    birthday DATE,
    bio TEXT,
    fans_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    scrapy_count INTEGER,
    profile_views INTEGER,
    birth_date DATE,
    email VARCHAR(255),
    phone VARCHAR(20),
    whatsapp_enabled BOOLEAN,
    privacy_settings JSONB,
    updated_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        p.display_name,
        p.photo_url,
        p.relationship,
        p.location,
        p.birthday,
        p.bio,
        p.fans_count,
        p.created_at,
        p.scrapy_count,
        p.profile_views,
        p.birth_date,
        COALESCE(p.email, '') as email,
        p.phone,
        COALESCE(p.whatsapp_enabled, false) as whatsapp_enabled,
        COALESCE(p.privacy_settings, '{"phone_visibility": "friends", "profile_visibility": "public"}'::jsonb) as privacy_settings,
        COALESCE(p.updated_at, p.created_at) as updated_at
    FROM public.profiles p
    WHERE p.username = username_param;
END;
$$;

-- ============================================================================
-- 3. FUNÇÃO PARA VERIFICAR SE USERNAME EXISTE
-- ============================================================================

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

-- ============================================================================
-- 4. CRIAR TABELAS AUXILIARES SE NÃO EXISTIREM
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

-- Criar tabela user_status se não existir
CREATE TABLE IF NOT EXISTS public.user_status (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    status VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('online', 'away', 'busy', 'offline')),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 5. PERMISSÕES
-- ============================================================================

-- Permitir acesso público às funções
GRANT EXECUTE ON FUNCTION get_profile_by_username(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_username_exists(TEXT) TO anon, authenticated;

-- Permitir acesso às tabelas
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

-- ============================================================================
-- 6. ATUALIZAR PERFIL DO MARCELO (se existir)
-- ============================================================================

-- Atualizar dados do Marcelo se ele existir
UPDATE public.profiles SET
    display_name = 'Marcelo Oliver',
    photo_url = '/marcelo-profile.jpg',
    relationship = 'Casado',
    location = 'São Paulo, SP',
    bio = 'Gerente de Projetos experiente com mais de 10 anos de experiência. Apaixonado por tecnologia e inovação.',
    fans_count = 42
WHERE username = 'marcelooliver';

-- Se o Marcelo não existir, vamos criar (mas precisamos de um ID válido)
-- Por enquanto, vamos apenas mostrar se ele existe
DO $$
DECLARE
    marcelo_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM public.profiles WHERE username = 'marcelooliver') INTO marcelo_exists;
    
    IF marcelo_exists THEN
        RAISE NOTICE '✅ Perfil do Marcelo encontrado e atualizado!';
    ELSE
        RAISE NOTICE '⚠️  Perfil do Marcelo não encontrado. Precisa ser criado via cadastro.';
    END IF;
END $$;

-- ============================================================================
-- 7. VERIFICAÇÃO FINAL
-- ============================================================================

-- Testar a função
SELECT 'Testando função get_profile_by_username:' as info;
SELECT * FROM get_profile_by_username('marcelooliver');

-- Se não retornar nada, testar com outros usuários
SELECT 'Testando com usuário existente:' as info;
SELECT * FROM get_profile_by_username('teste_audio');

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Script executado!';
    RAISE NOTICE '📊 Função get_profile_by_username criada';
    RAISE NOTICE '🔧 Estrutura baseada nas colunas reais';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Pronto para usar!';
END $$;
