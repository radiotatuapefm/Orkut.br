-- ========================================
-- CORREÇÃO DA ESTRUTURA DA TABELA PROFILES
-- Execute este script no SQL Editor do Supabase
-- ========================================

-- Primeiro, vamos verificar a estrutura atual
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'profiles';

-- Adicionar colunas que podem estar faltando (se não existirem)
DO $$ 
BEGIN
    -- Adicionar coluna email se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE profiles ADD COLUMN email VARCHAR(255);
        RAISE NOTICE 'Coluna email adicionada';
    END IF;

    -- Adicionar coluna phone se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'phone') THEN
        ALTER TABLE profiles ADD COLUMN phone VARCHAR(20);
        RAISE NOTICE 'Coluna phone adicionada';
    END IF;

    -- Adicionar coluna bio se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'bio') THEN
        ALTER TABLE profiles ADD COLUMN bio TEXT;
        RAISE NOTICE 'Coluna bio adicionada';
    END IF;

    -- Adicionar coluna location se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'location') THEN
        ALTER TABLE profiles ADD COLUMN location VARCHAR(100);
        RAISE NOTICE 'Coluna location adicionada';
    END IF;

    -- Adicionar coluna relationship se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'relationship') THEN
        ALTER TABLE profiles ADD COLUMN relationship VARCHAR(50);
        RAISE NOTICE 'Coluna relationship adicionada';
    END IF;

    -- Adicionar coluna website se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'website') THEN
        ALTER TABLE profiles ADD COLUMN website VARCHAR(255);
        RAISE NOTICE 'Coluna website adicionada';
    END IF;

    -- Adicionar coluna fans_count se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'fans_count') THEN
        ALTER TABLE profiles ADD COLUMN fans_count INTEGER DEFAULT 0;
        RAISE NOTICE 'Coluna fans_count adicionada';
    END IF;

    -- Adicionar coluna views_count se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'views_count') THEN
        ALTER TABLE profiles ADD COLUMN views_count INTEGER DEFAULT 0;
        RAISE NOTICE 'Coluna views_count adicionada';
    END IF;

    -- Adicionar coluna whatsapp_enabled se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'whatsapp_enabled') THEN
        ALTER TABLE profiles ADD COLUMN whatsapp_enabled BOOLEAN DEFAULT false;
        RAISE NOTICE 'Coluna whatsapp_enabled adicionada';
    END IF;

    -- Adicionar coluna privacy_settings se não existir
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'privacy_settings') THEN
        ALTER TABLE profiles ADD COLUMN privacy_settings JSONB DEFAULT '{"profile": "public", "phone": "friends"}';
        RAISE NOTICE 'Coluna privacy_settings adicionada';
    END IF;

    -- Verificar se display_name existe, se não, renomear 'name' para 'display_name'
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'display_name') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'name') THEN
            ALTER TABLE profiles RENAME COLUMN name TO display_name;
            RAISE NOTICE 'Coluna name renomeada para display_name';
        ELSE
            ALTER TABLE profiles ADD COLUMN display_name VARCHAR(100);
            RAISE NOTICE 'Coluna display_name adicionada';
        END IF;
    END IF;

    -- Verificar se photo_url existe, se não, renomear outras possíveis variações
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'photo_url') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
            ALTER TABLE profiles RENAME COLUMN avatar_url TO photo_url;
            RAISE NOTICE 'Coluna avatar_url renomeada para photo_url';
        ELSE
            ALTER TABLE profiles ADD COLUMN photo_url TEXT;
            RAISE NOTICE 'Coluna photo_url adicionada';
        END IF;
    END IF;
END $$;

-- Atualizar o perfil do Marcelo com o email correto
UPDATE profiles 
SET email = 'zarzamorera@gmail.com'
WHERE username = 'marcelooliver' AND email IS NULL;

-- Criar índices se não existirem
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_display_name ON profiles(display_name);

-- Verificar estrutura final
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;
