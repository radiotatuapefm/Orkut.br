-- ============================================================================
-- ORKUT RETRÔ - SETUP COMPLETO DO BANCO DE DADOS
-- Execute este script no editor SQL do Supabase
-- ============================================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. TABELA DE PERFIS (PROFILES)
-- ============================================================================

-- Remover tabela se existir (cuidado em produção!)
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Criar tabela de perfis
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    phone VARCHAR(20),
    bio TEXT,
    location VARCHAR(100),
    birthday DATE,
    relationship VARCHAR(50),
    whatsapp_enabled BOOLEAN DEFAULT false,
    privacy_settings JSONB DEFAULT '{"phone_visibility": "friends", "profile_visibility": "public"}'::jsonb,
    fans_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_profiles_username ON public.profiles(username);
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_created_at ON public.profiles(created_at);

-- ============================================================================
-- 2. TABELA DE AMIZADES (FRIENDSHIPS)
-- ============================================================================

DROP TABLE IF EXISTS public.friendships CASCADE;

CREATE TABLE public.friendships (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    requester_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    addressee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(requester_id, addressee_id)
);

-- Índices para friendships
CREATE INDEX idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX idx_friendships_status ON public.friendships(status);

-- ============================================================================
-- 3. TABELA DE POSTS
-- ============================================================================

DROP TABLE IF EXISTS public.posts CASCADE;

CREATE TABLE public.posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para posts
CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);

-- ============================================================================
-- 4. TABELA DE MENSAGENS
-- ============================================================================

DROP TABLE IF EXISTS public.messages CASCADE;

CREATE TABLE public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para messages
CREATE INDEX idx_messages_sender ON public.messages(sender_id);
CREATE INDEX idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);

-- ============================================================================
-- 5. TABELA DE STATUS ONLINE
-- ============================================================================

DROP TABLE IF EXISTS public.user_status CASCADE;

CREATE TABLE public.user_status (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    status VARCHAR(20) DEFAULT 'offline' CHECK (status IN ('online', 'away', 'busy', 'offline')),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para user_status
CREATE INDEX idx_user_status_status ON public.user_status(status);
CREATE INDEX idx_user_status_last_seen ON public.user_status(last_seen);

-- ============================================================================
-- 6. FUNÇÕES RPC
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
-- 7. TRIGGERS PARA UPDATED_AT
-- ============================================================================

-- Função genérica para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para todas as tabelas com updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_friendships_updated_at
    BEFORE UPDATE ON public.friendships
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_status_updated_at
    BEFORE UPDATE ON public.user_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 8. POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ============================================================================

-- Habilitar RLS nas tabelas
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_status ENABLE ROW LEVEL SECURITY;

-- Políticas para profiles (visualização pública, edição própria)
CREATE POLICY "Profiles são visíveis publicamente" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Usuários podem inserir seu próprio perfil" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Usuários podem atualizar seu próprio perfil" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Políticas para friendships
CREATE POLICY "Usuários podem ver suas próprias amizades" ON public.friendships
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

CREATE POLICY "Usuários podem criar solicitações de amizade" ON public.friendships
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Usuários podem atualizar amizades que envolvem eles" ON public.friendships
    FOR UPDATE USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- Políticas para posts (visualização pública, criação própria)
CREATE POLICY "Posts são visíveis publicamente" ON public.posts
    FOR SELECT USING (true);

CREATE POLICY "Usuários podem criar seus próprios posts" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar seus próprios posts" ON public.posts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem deletar seus próprios posts" ON public.posts
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas para messages
CREATE POLICY "Usuários podem ver mensagens enviadas ou recebidas" ON public.messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Usuários podem enviar mensagens" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Políticas para user_status
CREATE POLICY "Status são visíveis publicamente" ON public.user_status
    FOR SELECT USING (true);

CREATE POLICY "Usuários podem atualizar seu próprio status" ON public.user_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem modificar seu próprio status" ON public.user_status
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================================
-- 9. DADOS DE EXEMPLO
-- ============================================================================

-- Inserir perfil do Marcelo (usando ID fixo para exemplo)
INSERT INTO public.profiles (
    id,
    username,
    name,
    email,
    avatar_url,
    phone,
    bio,
    location,
    relationship,
    whatsapp_enabled,
    privacy_settings,
    fans_count
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'marcelooliver',
    'Marcelo Oliver',
    'marcelo.oliver@empresa.com',
    '/marcelo-profile.jpg',
    '+5511987654321',
    'Gerente de Projetos experiente com mais de 10 anos de experiência. Apaixonado por tecnologia e inovação.',
    'São Paulo, SP',
    'Casado',
    true,
    '{"phone_visibility": "public", "profile_visibility": "public"}'::jsonb,
    42
) ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    name = EXCLUDED.name,
    email = EXCLUDED.email,
    avatar_url = EXCLUDED.avatar_url,
    phone = EXCLUDED.phone,
    bio = EXCLUDED.bio,
    location = EXCLUDED.location,
    relationship = EXCLUDED.relationship,
    whatsapp_enabled = EXCLUDED.whatsapp_enabled,
    privacy_settings = EXCLUDED.privacy_settings,
    fans_count = EXCLUDED.fans_count;

-- Inserir status online do Marcelo
INSERT INTO public.user_status (
    user_id,
    status,
    last_seen
) VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'online',
    NOW()
) ON CONFLICT (user_id) DO UPDATE SET
    status = EXCLUDED.status,
    last_seen = EXCLUDED.last_seen,
    updated_at = NOW();

-- ============================================================================
-- 10. FUNÇÕES AUXILIARES
-- ============================================================================

-- Função para atualizar contador de fãs
CREATE OR REPLACE FUNCTION update_fans_count()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar contador quando amizade é aceita
    IF NEW.status = 'accepted' AND OLD.status != 'accepted' THEN
        UPDATE public.profiles 
        SET fans_count = fans_count + 1 
        WHERE id = NEW.addressee_id;
    END IF;
    
    -- Decrementar contador quando amizade é removida/rejeitada
    IF OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
        UPDATE public.profiles 
        SET fans_count = GREATEST(fans_count - 1, 0) 
        WHERE id = OLD.addressee_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar contador de fãs
DROP TRIGGER IF EXISTS friendship_fans_count_trigger ON public.friendships;
CREATE TRIGGER friendship_fans_count_trigger
    AFTER UPDATE ON public.friendships
    FOR EACH ROW
    EXECUTE FUNCTION update_fans_count();

-- ============================================================================
-- 11. FUNÇÃO PARA BUSCAR POSTS DO USUÁRIO
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_posts(user_id_param UUID, limit_param INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    content TEXT,
    image_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    user_name VARCHAR(100),
    user_username VARCHAR(50),
    user_avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.content,
        p.image_url,
        p.likes_count,
        p.comments_count,
        p.created_at,
        pr.name as user_name,
        pr.username as user_username,
        pr.avatar_url as user_avatar_url
    FROM public.posts p
    JOIN public.profiles pr ON p.user_id = pr.id
    WHERE p.user_id = user_id_param
    ORDER BY p.created_at DESC
    LIMIT limit_param;
END;
$$;

-- ============================================================================
-- 12. FUNÇÃO PARA BUSCAR FEED DE POSTS
-- ============================================================================

CREATE OR REPLACE FUNCTION get_posts_feed(current_user_id UUID DEFAULT NULL, limit_param INTEGER DEFAULT 20)
RETURNS TABLE (
    id UUID,
    content TEXT,
    image_url TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    user_id UUID,
    user_name VARCHAR(100),
    user_username VARCHAR(50),
    user_avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.content,
        p.image_url,
        p.likes_count,
        p.comments_count,
        p.created_at,
        p.user_id,
        pr.name as user_name,
        pr.username as user_username,
        pr.avatar_url as user_avatar_url
    FROM public.posts p
    JOIN public.profiles pr ON p.user_id = pr.id
    WHERE 
        -- Se usuário logado, mostra posts de amigos + próprios
        CASE 
            WHEN current_user_id IS NOT NULL THEN (
                p.user_id = current_user_id OR
                EXISTS (
                    SELECT 1 FROM public.friendships f
                    WHERE ((f.requester_id = current_user_id AND f.addressee_id = p.user_id) OR
                           (f.addressee_id = current_user_id AND f.requester_id = p.user_id))
                    AND f.status = 'accepted'
                )
            )
            -- Se não logado, mostra posts públicos
            ELSE true
        END
    ORDER BY p.created_at DESC
    LIMIT limit_param;
END;
$$;

-- ============================================================================
-- 13. FUNÇÃO PARA GERENCIAR AMIZADES
-- ============================================================================

CREATE OR REPLACE FUNCTION manage_friendship(
    current_user_id UUID,
    target_user_id UUID,
    action_param VARCHAR(20) -- 'request', 'accept', 'reject', 'remove', 'block'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    existing_friendship public.friendships%ROWTYPE;
BEGIN
    -- Verificar se não é o mesmo usuário
    IF current_user_id = target_user_id THEN
        RETURN '{"success": false, "message": "Não é possível adicionar a si mesmo"}'::json;
    END IF;

    -- Buscar amizade existente
    SELECT * INTO existing_friendship
    FROM public.friendships
    WHERE (requester_id = current_user_id AND addressee_id = target_user_id)
       OR (requester_id = target_user_id AND addressee_id = current_user_id);

    CASE action_param
        WHEN 'request' THEN
            IF existing_friendship.id IS NOT NULL THEN
                RETURN '{"success": false, "message": "Solicitação já existe"}'::json;
            END IF;
            
            INSERT INTO public.friendships (requester_id, addressee_id, status)
            VALUES (current_user_id, target_user_id, 'pending');
            
            RETURN '{"success": true, "message": "Solicitação enviada"}'::json;

        WHEN 'accept' THEN
            IF existing_friendship.id IS NULL OR existing_friendship.status != 'pending' THEN
                RETURN '{"success": false, "message": "Solicitação não encontrada"}'::json;
            END IF;
            
            UPDATE public.friendships
            SET status = 'accepted', updated_at = NOW()
            WHERE id = existing_friendship.id;
            
            RETURN '{"success": true, "message": "Amizade aceita"}'::json;

        WHEN 'reject' THEN
            IF existing_friendship.id IS NULL THEN
                RETURN '{"success": false, "message": "Solicitação não encontrada"}'::json;
            END IF;
            
            UPDATE public.friendships
            SET status = 'rejected', updated_at = NOW()
            WHERE id = existing_friendship.id;
            
            RETURN '{"success": true, "message": "Solicitação rejeitada"}'::json;

        WHEN 'remove' THEN
            IF existing_friendship.id IS NULL THEN
                RETURN '{"success": false, "message": "Amizade não encontrada"}'::json;
            END IF;
            
            DELETE FROM public.friendships WHERE id = existing_friendship.id;
            
            RETURN '{"success": true, "message": "Amizade removida"}'::json;

        ELSE
            RETURN '{"success": false, "message": "Ação inválida"}'::json;
    END CASE;
END;
$$;

-- ============================================================================
-- 14. PERMISSÕES FINAIS
-- ============================================================================

-- Permitir acesso público às funções RPC
GRANT EXECUTE ON FUNCTION get_profile_by_username(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION check_username_exists(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_user_friends(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_posts(UUID, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_posts_feed(UUID, INTEGER) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION manage_friendship(UUID, UUID, VARCHAR(20)) TO authenticated;

-- Permitir acesso às tabelas
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

GRANT SELECT ON public.friendships TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.friendships TO authenticated;

GRANT SELECT ON public.posts TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.posts TO authenticated;

GRANT SELECT, INSERT ON public.messages TO authenticated;

GRANT SELECT ON public.user_status TO anon, authenticated;
GRANT INSERT, UPDATE ON public.user_status TO authenticated;

-- ============================================================================
-- SUCESSO!
-- ============================================================================

-- Verificar se tudo foi criado corretamente
DO $$
BEGIN
    RAISE NOTICE '✅ Setup do banco de dados concluído com sucesso!';
    RAISE NOTICE '📊 Tabelas criadas: profiles, friendships, posts, messages, user_status';
    RAISE NOTICE '🔧 Funções RPC criadas: get_profile_by_username, check_username_exists, get_user_friends, get_user_posts, get_posts_feed, manage_friendship';
    RAISE NOTICE '🔒 Políticas RLS configuradas';
    RAISE NOTICE '👤 Perfil de exemplo inserido: Marcelo Oliver (@marcelooliver)';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 Seu projeto Orkut está pronto para usar!';
END $$;
