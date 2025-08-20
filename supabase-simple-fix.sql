-- ============================================================================
-- ORKUT RETRÔ - CORREÇÃO SIMPLES E SEGURA
-- Execute este script no editor SQL do Supabase
-- ============================================================================

-- ============================================================================
-- 1. ADICIONAR COLUNAS ESSENCIAIS (se não existirem)
-- ============================================================================

DO $$ 
BEGIN
    -- Adicionar coluna email se não existir
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
        RAISE NOTICE '✅ Coluna email adicionada';
    EXCEPTION WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  Coluna email já existe';
    END;

    -- Adicionar coluna phone se não existir
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN phone TEXT;
        RAISE NOTICE '✅ Coluna phone adicionada';
    EXCEPTION WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  Coluna phone já existe';
    END;

    -- Adicionar coluna whatsapp_enabled se não existir
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN whatsapp_enabled BOOLEAN DEFAULT false;
        RAISE NOTICE '✅ Coluna whatsapp_enabled adicionada';
    EXCEPTION WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  Coluna whatsapp_enabled já existe';
    END;

    -- Adicionar coluna privacy_settings se não existir
    BEGIN
        ALTER TABLE public.profiles ADD COLUMN privacy_settings JSONB DEFAULT '{"phone_visibility": "friends", "profile_visibility": "public"}'::jsonb;
        RAISE NOTICE '✅ Coluna privacy_settings adicionada';
    EXCEPTION WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  Coluna privacy_settings já existe';
    END;
END $$;

-- ============================================================================
-- 2. CRIAR FUNÇÃO RPC SIMPLES (usando tipos genéricos)
-- ============================================================================

-- Função para buscar perfil por username (versão simples e segura)
CREATE OR REPLACE FUNCTION get_profile_by_username(username_param TEXT)
RETURNS SETOF public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT p.*
    FROM public.profiles p
    WHERE p.username = username_param;
END;
$$;

-- ============================================================================
-- 3. FUNÇÃO PARA VERIFICAR USERNAME
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
-- 4. PERMISSÕES
-- ============================================================================

-- Permitir acesso público às funções
GRANT EXECUTE ON FUNCTION get_profile_by_username(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_username_exists(TEXT) TO anon, authenticated;

-- Permitir acesso às tabelas
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

-- ============================================================================
-- 5. CRIAR PERFIL DO MARCELO SE NÃO EXISTIR
-- ============================================================================

-- Inserir Marcelo se ele não existir (usando um ID que pode não estar no auth.users)
-- Vamos tentar uma abordagem diferente
DO $$
DECLARE
    marcelo_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM public.profiles WHERE username = 'marcelooliver') INTO marcelo_exists;
    
    IF NOT marcelo_exists THEN
        -- Tentar inserir perfil do Marcelo
        BEGIN
            INSERT INTO public.profiles (
                id,
                username,
                display_name,
                photo_url,
                relationship,
                location,
                bio,
                fans_count,
                email,
                phone,
                whatsapp_enabled
            ) VALUES (
                uuid_generate_v4(), -- Gerar novo UUID
                'marcelooliver',
                'Marcelo Oliver',
                '/marcelo-profile.jpg',
                'Casado',
                'São Paulo, SP',
                'Gerente de Projetos experiente com mais de 10 anos de experiência. Apaixonado por tecnologia e inovação.',
                42,
                'marcelo.oliver@empresa.com',
                '+5511987654321',
                true
            );
            RAISE NOTICE '✅ Perfil do Marcelo criado com sucesso!';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️  Não foi possível criar perfil do Marcelo: %', SQLERRM;
            RAISE NOTICE 'ℹ️  Isso é normal se a tabela tem restrições de foreign key com auth.users';
        END;
    ELSE
        -- Atualizar dados do Marcelo se ele já existir
        UPDATE public.profiles SET
            display_name = 'Marcelo Oliver',
            photo_url = '/marcelo-profile.jpg',
            relationship = 'Casado',
            location = 'São Paulo, SP',
            bio = 'Gerente de Projetos experiente com mais de 10 anos de experiência. Apaixonado por tecnologia e inovação.',
            fans_count = 42,
            email = 'marcelo.oliver@empresa.com',
            phone = '+5511987654321',
            whatsapp_enabled = true
        WHERE username = 'marcelooliver';
        
        RAISE NOTICE '✅ Perfil do Marcelo atualizado!';
    END IF;
END $$;

-- ============================================================================
-- 6. VERIFICAÇÃO FINAL
-- ============================================================================

-- Testar a função
SELECT 'Testando função get_profile_by_username:' as info;
SELECT * FROM get_profile_by_username('teste_audio') LIMIT 1;

-- Mostrar estrutura final
SELECT 'Colunas da tabela profiles:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Script executado com sucesso!';
    RAISE NOTICE '📊 Função get_profile_by_username criada';
    RAISE NOTICE '🔧 Colunas necessárias adicionadas';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Pronto para testar!';
END $$;
