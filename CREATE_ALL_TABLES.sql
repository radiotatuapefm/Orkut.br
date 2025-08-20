-- =====================================================
-- ORKUT.BR - SCRIPT COMPLETO PARA CRIAR TODAS AS TABELAS
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- Habilitar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. TABELA DE PERFIS (se não existir)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    username text UNIQUE NOT NULL,
    display_name text NOT NULL,
    bio text,
    photo_url text,
    location text,
    birth_date date,
    relationship text,
    profile_views integer DEFAULT 0,
    scrapy_count integer DEFAULT 0,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- =====================================================
-- 2. TABELA DE POSTS
-- =====================================================
DROP TABLE IF EXISTS public.posts CASCADE;
CREATE TABLE public.posts (
    id bigserial PRIMARY KEY,
    author uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    photo_url text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- =====================================================
-- 3. TABELA DE COMUNIDADES
-- =====================================================
CREATE TABLE IF NOT EXISTS public.communities (
    id bigserial PRIMARY KEY,
    name text NOT NULL,
    description text NOT NULL,
    photo_url text NOT NULL,
    category text NOT NULL,
    members_count integer DEFAULT 0,
    owner_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now()
);

-- =====================================================
-- 4. TABELA DE SCRAPS (RECADOS)
-- =====================================================
DROP TABLE IF EXISTS public.scraps CASCADE;
CREATE TABLE public.scraps (
    id bigserial PRIMARY KEY,
    from_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    to_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- =====================================================
-- 5. TABELA DE MENSAGENS PRIVADAS
-- =====================================================
DROP TABLE IF EXISTS public.messages CASCADE;
CREATE TABLE public.messages (
    id bigserial PRIMARY KEY,
    from_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    to_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    read_at timestamptz DEFAULT NULL
);

-- =====================================================
-- 6. TABELA DE AMIZADES
-- =====================================================
DROP TABLE IF EXISTS public.friendships CASCADE;
CREATE TABLE public.friendships (
    id bigserial PRIMARY KEY,
    requester_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    addressee_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status text CHECK (status IN ('pending','accepted','blocked')) DEFAULT 'pending',
    created_at timestamptz DEFAULT now(),
    UNIQUE(requester_id, addressee_id)
);

-- =====================================================
-- 7. TABELA DE FOTOS
-- =====================================================
DROP TABLE IF EXISTS public.photos CASCADE;
CREATE TABLE public.photos (
    id bigserial PRIMARY KEY,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    photo_url text NOT NULL,
    caption text DEFAULT '',
    created_at timestamptz DEFAULT now()
);

-- =====================================================
-- 8. TABELA DE CURTIDAS
-- =====================================================
DROP TABLE IF EXISTS public.likes CASCADE;
CREATE TABLE public.likes (
    id bigserial PRIMARY KEY,
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at timestamptz DEFAULT now(),
    UNIQUE(post_id, profile_id)
);

-- =====================================================
-- 9. TABELA DE COMENTÁRIOS
-- =====================================================
DROP TABLE IF EXISTS public.comments CASCADE;
CREATE TABLE public.comments (
    id bigserial PRIMARY KEY,
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- =====================================================
-- 10. TABELA DE MEMBROS DE COMUNIDADES
-- =====================================================
DROP TABLE IF EXISTS public.community_members CASCADE;
CREATE TABLE public.community_members (
    id bigserial PRIMARY KEY,
    community_id bigint REFERENCES public.communities(id) ON DELETE CASCADE NOT NULL,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    joined_at timestamptz DEFAULT now(),
    role text DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
    UNIQUE(community_id, profile_id)
);

-- =====================================================
-- CRIAR ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para posts
CREATE INDEX IF NOT EXISTS idx_posts_author ON public.posts(author);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at);

-- Índices para scraps
CREATE INDEX IF NOT EXISTS idx_scraps_to_profile ON public.scraps(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_scraps_from_profile ON public.scraps(from_profile_id);
CREATE INDEX IF NOT EXISTS idx_scraps_created_at ON public.scraps(created_at);

-- Índices para mensagens
CREATE INDEX IF NOT EXISTS idx_messages_to_profile ON public.messages(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_messages_from_profile ON public.messages(from_profile_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- Índices para amizades
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON public.friendships(status);

-- Índices para fotos
CREATE INDEX IF NOT EXISTS idx_photos_profile ON public.photos(profile_id);
CREATE INDEX IF NOT EXISTS idx_photos_created_at ON public.photos(created_at);

-- Índices para curtidas
CREATE INDEX IF NOT EXISTS idx_likes_post ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_profile ON public.likes(profile_id);

-- Índices para comentários
CREATE INDEX IF NOT EXISTS idx_comments_post ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_profile ON public.comments(profile_id);

-- Índices para membros de comunidades
CREATE INDEX IF NOT EXISTS idx_community_members_community ON public.community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_profile ON public.community_members(profile_id);

-- Índices para perfis
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_display_name ON public.profiles(display_name);

-- =====================================================
-- INSERIR DADOS DEMO
-- =====================================================

-- Inserir comunidades demo (apenas se não existirem)
INSERT INTO public.communities (name, description, photo_url, category, members_count) VALUES
('Eu amo os anos 2000', 'Nostalgia pura dos anos 2000! Músicas, filmes, tecnologia e muito mais!', 'https://images.pexels.com/photos/1674752/pexels-photo-1674752.jpeg?auto=compress&cs=tinysrgb&w=400', 'Nostalgia', 15420),
('Programadores do Brasil', 'Comunidade para desenvolvedores brasileiros. Dicas, vagas, networking e muito código!', 'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg?auto=compress&cs=tinysrgb&w=400', 'Tecnologia', 8932),
('Músicas que marcaram época', 'As melhores músicas de todos os tempos! Rock, pop, MPB, internacional e muito mais!', 'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?auto=compress&cs=tinysrgb&w=400', 'Música', 12654),
('Gamers Retrô', 'Para quem ama jogos clássicos! Atari, Nintendo, Sega, PlayStation 1 e 2, e muito mais!', 'https://images.pexels.com/photos/1298601/pexels-photo-1298601.jpeg?auto=compress&cs=tinysrgb&w=400', 'Jogos', 7891),
('Eu odeio segunda-feira', 'Para desabafar sobre segundas-feiras e compartilhar memes do Garfield!', 'https://images.pexels.com/photos/1416736/pexels-photo-1416736.jpeg?auto=compress&cs=tinysrgb&w=400', 'Entretenimento', 23567),
('Receitas da Vovó', 'As melhores receitas caseiras! Doces, salgados, tradicionais e fáceis de fazer!', 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400', 'Culinária', 9876),
('Filmes Cult', 'Para discutir filmes clássicos, cult movies e cinema alternativo!', 'https://images.pexels.com/photos/1200450/pexels-photo-1200450.jpeg?auto=compress&cs=tinysrgb&w=400', 'Cinema', 5432),
('Viagens pelo Brasil', 'Descubra lugares incríveis no nosso Brasil! Dicas, fotos e roteiros!', 'https://images.pexels.com/photos/1533720/pexels-photo-1533720.jpeg?auto=compress&cs=tinysrgb&w=400', 'Turismo', 11234)
ON CONFLICT DO NOTHING;

-- Inserir posts demo apenas se existirem perfis
INSERT INTO public.posts (author, content)
SELECT 
    id as author,
    unnest(ARRAY[
        'Que saudades do Orkut original! Esta recriação está incrível! 🌟',
        'Alguém mais está amando poder usar comando de voz no Orkut? O Orky é demais! 🎤',
        'Encontrei vários amigos antigos aqui! A nostalgia bateu forte 🥰',
        'As comunidades estão voltando com tudo! Já entrei em 15 diferentes 👥',
        'Quem mais lembra dos scraps coloridos e cheios de HTML? 💕',
        'O design retrô ficou perfeito! Parabéns aos desenvolvedores! 👏',
        'Testando o sistema de chamadas de vídeo... funciona perfeitamente! 📹',
        'Que legal poder buscar pessoas e comunidades tão facilmente agora! 🔍',
        'Minha página de recados já está cheia de mensagens carinhosas 💌',
        'Adicionando fotos na galeria... que memories! 📸'
    ]) as content
FROM public.profiles
LIMIT 3
ON CONFLICT DO NOTHING;

-- Inserir scraps demo
INSERT INTO public.scraps (from_profile_id, to_profile_id, content) 
SELECT 
    p1.id as from_profile_id,
    p2.id as to_profile_id,
    unnest(ARRAY[
        'Oiee! Que bom te encontrar aqui no Orkut novamente! 😊',
        'Seu perfil está lindo! Adorei as fotos! 📸✨',
        'Vamos reviver os velhos tempos no Orkut! 🌟',
        'Que saudades de deixar recados assim! 💕',
        'Achei você aqui! Vamos ser amigos de novo? 🤗',
        'Testando o novo sistema de recados... está perfeito! 👌',
        'Você viu que tem assistente de voz agora? Muito inovador! 🎤',
        'Que nostalgia boa estar aqui novamente! ❤️'
    ]) as content
FROM 
    (SELECT id FROM public.profiles ORDER BY created_at LIMIT 2) p1,
    (SELECT id FROM public.profiles ORDER BY created_at DESC LIMIT 2) p2
WHERE p1.id != p2.id
ON CONFLICT DO NOTHING;

-- Inserir fotos demo
INSERT INTO public.photos (profile_id, photo_url, caption)
SELECT 
    id as profile_id,
    unnest(ARRAY[
        'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=400',
        'https://images.pexels.com/photos/1040880/pexels-photo-1040880.jpeg?auto=compress&cs=tinysrgb&w=400',
        'https://images.pexels.com/photos/1416820/pexels-photo-1416820.jpeg?auto=compress&cs=tinysrgb&w=400',
        'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=400',
        'https://images.pexels.com/photos/1024981/pexels-photo-1024981.jpeg?auto=compress&cs=tinysrgb&w=400'
    ]) as photo_url,
    unnest(ARRAY[
        'Foto de perfil nova! 📸',
        'Lembrança dos anos 2000 💫',
        'Nostalgia bateu forte 🥰',
        'Momentos especiais ✨',
        'Orkut is back! 🌟'
    ]) as caption
FROM public.profiles
LIMIT 2
ON CONFLICT DO NOTHING;

-- Inserir curtidas demo
INSERT INTO public.likes (post_id, profile_id)
SELECT DISTINCT
    posts.id as post_id,
    profiles.id as profile_id
FROM 
    public.posts,
    public.profiles
WHERE posts.author != profiles.id
LIMIT 20
ON CONFLICT (post_id, profile_id) DO NOTHING;

-- Inserir membros de comunidades demo
INSERT INTO public.community_members (community_id, profile_id)
SELECT DISTINCT
    communities.id as community_id,
    profiles.id as profile_id
FROM 
    public.communities,
    public.profiles
LIMIT 30
ON CONFLICT (community_id, profile_id) DO NOTHING;

-- Inserir comentários demo
INSERT INTO public.comments (post_id, profile_id, content)
SELECT DISTINCT
    posts.id as post_id,
    profiles.id as profile_id,
    unnest(ARRAY[
        'Concordo totalmente! 👍',
        'Que legal! Também sinto essa nostalgia 😊',
        'O Orkut nunca morreu em nossos corações! ❤️',
        'Incrível como está funcionando bem! 🌟',
        'Também estou amando essa volta! 🥰',
        'Que memories boas! 📸✨'
    ]) as content
FROM 
    public.posts,
    public.profiles
WHERE posts.author != profiles.id
LIMIT 15
ON CONFLICT DO NOTHING;

-- Atualizar contadores
UPDATE public.profiles 
SET scrapy_count = (
    SELECT COUNT(*) FROM public.scraps WHERE to_profile_id = profiles.id
);

-- =====================================================
-- CONFIGURAR RLS (Row Level Security) - DESABILITADO PARA DESENVOLVIMENTO
-- =====================================================

-- Desabilitar RLS temporariamente para facilitar desenvolvimento
-- Quando em produção, habilitar e configurar policies apropriadas

-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.scraps ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- TRIGGERS PARA ATUALIZAR TIMESTAMPS
-- =====================================================

-- Função para atualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para perfis e posts
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;
CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON public.posts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Listar todas as tabelas criadas
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'profiles', 'posts', 'communities', 'scraps', 'messages', 
    'friendships', 'photos', 'likes', 'comments', 'community_members'
)
ORDER BY table_name;

-- =====================================================
-- FIM DO SCRIPT
-- TODAS AS TABELAS FORAM CRIADAS COM SUCESSO!
-- =====================================================
