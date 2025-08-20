-- Adicionar campos username e telefone à tabela profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS username text UNIQUE,
ADD COLUMN IF NOT EXISTS phone text,
ADD COLUMN IF NOT EXISTS whatsapp_enabled boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS privacy_settings jsonb DEFAULT '{"profile_visibility": "public", "phone_visibility": "friends", "whatsapp_visible": true}'::jsonb;

-- Criar índice para username (case-insensitive)
CREATE INDEX IF NOT EXISTS profiles_username_idx ON profiles (LOWER(username));

-- Criar tabela de amizades
CREATE TABLE IF NOT EXISTS friendships (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    requester_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    addressee_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Evitar amizade duplicada
    UNIQUE(requester_id, addressee_id)
);

-- RLS para friendships
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Políticas para friendships
CREATE POLICY "Users can view their own friendship requests" ON friendships
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can create friendship requests" ON friendships
    FOR INSERT WITH CHECK (auth.uid() = requester_id AND requester_id != addressee_id);

CREATE POLICY "Users can update friendship status" ON friendships
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Users can delete their own friendship requests" ON friendships
    FOR DELETE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Trigger para atualizar updated_at em friendships
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_friendships_updated_at ON friendships;
CREATE TRIGGER update_friendships_updated_at
    BEFORE UPDATE ON friendships
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para gerar username único baseado no nome
CREATE OR REPLACE FUNCTION generate_username(base_name text)
RETURNS text AS $$
DECLARE
    username text;
    counter integer := 0;
    base_clean text;
BEGIN
    -- Limpar e normalizar o nome base
    base_clean := LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(base_name, '[áàâãäå]', 'a', 'g'),
            '[éèêë]', 'e', 'g'
        ),
        '[^a-z0-9]', '', 'g'
    ));
    
    -- Limitar a 20 caracteres
    base_clean := SUBSTRING(base_clean, 1, 20);
    
    -- Tentar username sem número
    username := base_clean;
    
    -- Se já existe, adicionar números sequenciais
    WHILE EXISTS (SELECT 1 FROM profiles WHERE LOWER(profiles.username) = username) LOOP
        counter := counter + 1;
        username := base_clean || counter::text;
    END LOOP;
    
    RETURN username;
END;
$$ LANGUAGE plpgsql;

-- Trigger para gerar username automaticamente se não fornecido
CREATE OR REPLACE FUNCTION auto_generate_username()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.username IS NULL OR NEW.username = '' THEN
        NEW.username := generate_username(COALESCE(NEW.name, NEW.email));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_username_trigger ON profiles;
CREATE TRIGGER auto_username_trigger
    BEFORE INSERT OR UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_username();

-- Atualizar usernames existentes que são nulos
UPDATE profiles 
SET username = generate_username(COALESCE(name, email))
WHERE username IS NULL;

-- View para amigos aceitos (facilita consultas)
CREATE OR REPLACE VIEW friends_view AS
SELECT 
    f.requester_id as user_id,
    f.addressee_id as friend_id,
    p.username as friend_username,
    p.name as friend_name,
    p.avatar_url as friend_avatar,
    p.phone as friend_phone,
    p.whatsapp_enabled as friend_whatsapp_enabled,
    p.privacy_settings as friend_privacy_settings,
    f.created_at as friendship_date
FROM friendships f
JOIN profiles p ON p.id = f.addressee_id
WHERE f.status = 'accepted'

UNION ALL

SELECT 
    f.addressee_id as user_id,
    f.requester_id as friend_id,
    p.username as friend_username,
    p.name as friend_name,
    p.avatar_url as friend_avatar,
    p.phone as friend_phone,
    p.whatsapp_enabled as friend_whatsapp_enabled,
    p.privacy_settings as friend_privacy_settings,
    f.created_at as friendship_date
FROM friendships f
JOIN profiles p ON p.id = f.requester_id
WHERE f.status = 'accepted';

-- RLS para a view
ALTER VIEW friends_view OWNER TO postgres;

-- Função para buscar usuário por username
CREATE OR REPLACE FUNCTION get_profile_by_username(username_param text)
RETURNS TABLE (
    id uuid,
    name text,
    username text,
    email text,
    avatar_url text,
    phone text,
    whatsapp_enabled boolean,
    privacy_settings jsonb,
    created_at timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.username,
        p.email,
        p.avatar_url,
        p.phone,
        p.whatsapp_enabled,
        p.privacy_settings,
        p.created_at
    FROM profiles p
    WHERE LOWER(p.username) = LOWER(username_param);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para verificar se username está disponível
CREATE OR REPLACE FUNCTION is_username_available(username_param text)
RETURNS boolean AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM profiles 
        WHERE LOWER(username) = LOWER(username_param)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
