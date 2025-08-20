-- ============================================================================
-- ORKUT RETRÔ - ADICIONAR COLUNAS NECESSÁRIAS DE FORMA SEGURA
-- Execute este script no editor SQL do Supabase
-- ============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ADICIONAR COLUNAS UMA POR UMA (se não existirem)
-- ============================================================================

DO $$ 
BEGIN
    RAISE NOTICE 'Iniciando verificação e adição de colunas...';

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

    -- Adicionar coluna bio se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'bio') THEN
        ALTER TABLE public.profiles ADD COLUMN bio TEXT;
        RAISE NOTICE '✅ Coluna bio adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna bio já existe';
    END IF;

    -- Adicionar coluna location se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'location') THEN
        ALTER TABLE public.profiles ADD COLUMN location VARCHAR(100);
        RAISE NOTICE '✅ Coluna location adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna location já existe';
    END IF;

    -- Adicionar coluna birthday se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'birthday') THEN
        ALTER TABLE public.profiles ADD COLUMN birthday DATE;
        RAISE NOTICE '✅ Coluna birthday adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna birthday já existe';
    END IF;

    -- Adicionar coluna relationship se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'relationship') THEN
        ALTER TABLE public.profiles ADD COLUMN relationship VARCHAR(50);
        RAISE NOTICE '✅ Coluna relationship adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna relationship já existe';
    END IF;

    -- Adicionar coluna fans_count se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'fans_count') THEN
        ALTER TABLE public.profiles ADD COLUMN fans_count INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Coluna fans_count adicionada';
    ELSE
        RAISE NOTICE 'ℹ️  Coluna fans_count já existe';
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
-- CRIAR FUNÇÃO RPC PRINCIPAL
-- ============================================================================

-- Função para buscar perfil por username (versão mais simples primeiro)
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
        COALESCE(p.email, '') as email,
        p.avatar_url,
        p.phone,
        p.bio,
        p.location,
        p.birthday,
        p.relationship,
        COALESCE(p.whatsapp_enabled, false) as whatsapp_enabled,
        COALESCE(p.privacy_settings, '{"phone_visibility": "friends", "profile_visibility": "public"}'::jsonb) as privacy_settings,
        COALESCE(p.fans_count, 0) as fans_count,
        p.created_at
    FROM public.profiles p
    WHERE p.username = username_param;
END;
$$;

-- Permitir acesso público à função
GRANT EXECUTE ON FUNCTION get_profile_by_username(TEXT) TO anon, authenticated;

-- ============================================================================
-- VERIFICAR ESTRUTURA FINAL
-- ============================================================================

-- Mostrar todas as colunas da tabela profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Mostrar dados existentes
SELECT 'Dados atuais:' as info;
SELECT 
    id,
    username,
    name,
    CASE WHEN email IS NOT NULL THEN email ELSE 'sem email' END as email_status,
    created_at
FROM public.profiles;

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Script executado com sucesso!';
    RAISE NOTICE '📊 Verifique os resultados acima';
    RAISE NOTICE '🔧 Função get_profile_by_username criada';
    RAISE NOTICE '';
    RAISE NOTICE '➡️  Próximo passo: testar a função com: SELECT * FROM get_profile_by_username(''marcelooliver'');';
END $$;
