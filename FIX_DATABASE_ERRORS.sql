-- =====================================================
-- ORKUT.BR - CORREÇÃO DE ERROS ESPECÍFICOS NO BANCO
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- 1. CORRIGIR TABELA PROFILES - ADICIONAR COLUNAS FALTANTES
-- =====================================================
DO $$ 
BEGIN
    -- Adicionar coluna scrapy_count se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'scrapy_count'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN scrapy_count integer DEFAULT 0;
    END IF;
    
    -- Adicionar coluna profile_views se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'profile_views'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN profile_views integer DEFAULT 0;
    END IF;
    
    -- Adicionar coluna bio se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'bio'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN bio text;
    END IF;
    
    -- Adicionar coluna location se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'location'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN location text;
    END IF;
    
    -- Adicionar coluna birth_date se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'birth_date'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN birth_date date;
    END IF;
    
    -- Adicionar coluna relationship se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'relationship'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN relationship text;
    END IF;
END $$;

-- 2. CRIAR TABELA POSTS SE NÃO EXISTIR
-- =====================================================
CREATE TABLE IF NOT EXISTS public.posts (
    id bigserial PRIMARY KEY,
    author uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    photo_url text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3. CRIAR TABELAS COMPLEMENTARES SE NÃO EXISTIREM
-- =====================================================

-- Tabela de scraps
CREATE TABLE IF NOT EXISTS public.scraps (
    id bigserial PRIMARY KEY,
    from_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    to_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Tabela de mensagens
CREATE TABLE IF NOT EXISTS public.messages (
    id bigserial PRIMARY KEY,
    from_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    to_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    read_at timestamptz DEFAULT NULL
);

-- Tabela de amizades
CREATE TABLE IF NOT EXISTS public.friendships (
    id bigserial PRIMARY KEY,
    requester_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    addressee_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status text CHECK (status IN ('pending','accepted','blocked')) DEFAULT 'pending',
    created_at timestamptz DEFAULT now()
);

-- Adicionar constraint UNIQUE se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'friendships_requester_id_addressee_id_key'
    ) THEN
        ALTER TABLE public.friendships ADD CONSTRAINT friendships_requester_id_addressee_id_key 
        UNIQUE(requester_id, addressee_id);
    END IF;
END $$;

-- Tabela de fotos
CREATE TABLE IF NOT EXISTS public.photos (
    id bigserial PRIMARY KEY,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    photo_url text NOT NULL,
    caption text DEFAULT '',
    created_at timestamptz DEFAULT now()
);

-- Tabela de curtidas
CREATE TABLE IF NOT EXISTS public.likes (
    id bigserial PRIMARY KEY,
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Adicionar constraint UNIQUE para likes se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'likes_post_id_profile_id_key'
    ) THEN
        ALTER TABLE public.likes ADD CONSTRAINT likes_post_id_profile_id_key 
        UNIQUE(post_id, profile_id);
    END IF;
END $$;

-- Tabela de comentários
CREATE TABLE IF NOT EXISTS public.comments (
    id bigserial PRIMARY KEY,
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Tabela de comunidades
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

-- Tabela de membros de comunidades
CREATE TABLE IF NOT EXISTS public.community_members (
    id bigserial PRIMARY KEY,
    community_id bigint REFERENCES public.communities(id) ON DELETE CASCADE NOT NULL,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    joined_at timestamptz DEFAULT now(),
    role text DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin'))
);

-- Adicionar constraint UNIQUE para community_members se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'community_members_community_id_profile_id_key'
    ) THEN
        ALTER TABLE public.community_members ADD CONSTRAINT community_members_community_id_profile_id_key 
        UNIQUE(community_id, profile_id);
    END IF;
END $$;

-- 4. CRIAR ÍNDICES SE NÃO EXISTIREM
-- =====================================================

-- Índices para posts
CREATE INDEX IF NOT EXISTS idx_posts_author ON public.posts(author);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at);

-- Índices para scraps
CREATE INDEX IF NOT EXISTS idx_scraps_to_profile ON public.scraps(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_scraps_from_profile ON public.scraps(from_profile_id);

-- Índices para mensagens
CREATE INDEX IF NOT EXISTS idx_messages_to_profile ON public.messages(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_messages_from_profile ON public.messages(from_profile_id);

-- Índices para amizades
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);

-- Índices para fotos
CREATE INDEX IF NOT EXISTS idx_photos_profile ON public.photos(profile_id);

-- Índices para curtidas
CREATE INDEX IF NOT EXISTS idx_likes_post ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_profile ON public.likes(profile_id);

-- Índices para comentários
CREATE INDEX IF NOT EXISTS idx_comments_post ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_profile ON public.comments(profile_id);

-- 5. INSERIR DADOS DEMO (APENAS SE AS TABELAS ESTIVEREM VAZIAS)
-- =====================================================

-- Inserir comunidades demo
INSERT INTO public.communities (name, description, photo_url, category, members_count) 
SELECT * FROM (VALUES
    ('Eu amo os anos 2000', 'Nostalgia pura dos anos 2000! Músicas, filmes, tecnologia e muito mais!', 'https://images.pexels.com/photos/1674752/pexels-photo-1674752.jpeg?auto=compress&cs=tinysrgb&w=400', 'Nostalgia', 15420),
    ('Programadores do Brasil', 'Comunidade para desenvolvedores brasileiros. Dicas, vagas, networking e muito código!', 'https://images.pexels.com/photos/1181244/pexels-photo-1181244.jpeg?auto=compress&cs=tinysrgb&w=400', 'Tecnologia', 8932),
    ('Músicas que marcaram época', 'As melhores músicas de todos os tempos! Rock, pop, MPB, internacional e muito mais!', 'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?auto=compress&cs=tinysrgb&w=400', 'Música', 12654),
    ('Gamers Retrô', 'Para quem ama jogos clássicos! Atari, Nintendo, Sega, PlayStation 1 e 2, e muito mais!', 'https://images.pexels.com/photos/1298601/pexels-photo-1298601.jpeg?auto=compress&cs=tinysrgb&w=400', 'Jogos', 7891),
    ('Receitas da Vovó', 'As melhores receitas caseiras! Doces, salgados, tradicionais e fáceis de fazer!', 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=400', 'Culinária', 9876)
) AS v(name, description, photo_url, category, members_count)
WHERE NOT EXISTS (SELECT 1 FROM public.communities LIMIT 1);

-- Inserir posts demo apenas se existirem perfis
INSERT INTO public.posts (author, content)
SELECT 
    id as author,
    content
FROM public.profiles, 
     (VALUES 
        ('Que saudades do Orkut original! Esta recriação está incrível! 🌟'),
        ('O assistente Orky está funcionando muito bem! 🎤'),
        ('Encontrei vários amigos antigos aqui! A nostalgia bateu forte 🥰'),
        ('As comunidades estão de volta! 👥')
     ) AS post_content(content)
WHERE EXISTS (SELECT 1 FROM public.profiles)
  AND NOT EXISTS (SELECT 1 FROM public.posts LIMIT 1)
LIMIT 10;

-- 6. ATUALIZAR CONTADORES (APENAS SE A COLUNA EXISTIR)
-- =====================================================
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'scrapy_count'
        AND table_schema = 'public'
    ) THEN
        UPDATE public.profiles 
        SET scrapy_count = COALESCE((
            SELECT COUNT(*) FROM public.scraps WHERE to_profile_id = profiles.id
        ), 0);
    END IF;
END $$;

-- 7. VERIFICAÇÃO FINAL
-- =====================================================

-- Mostrar estrutura da tabela profiles
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Listar todas as tabelas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Contar registros em cada tabela
SELECT 
    'profiles' as table_name, COUNT(*) as count FROM public.profiles
UNION ALL
SELECT 
    'posts' as table_name, COUNT(*) as count FROM public.posts
UNION ALL
SELECT 
    'communities' as table_name, COUNT(*) as count FROM public.communities
UNION ALL
SELECT 
    'scraps' as table_name, COUNT(*) as count FROM public.scraps
UNION ALL
SELECT 
    'messages' as table_name, COUNT(*) as count FROM public.messages
ORDER BY table_name;

-- =====================================================
-- SCRIPT DE CORREÇÃO CONCLUÍDO!
-- Agora todas as tabelas devem estar funcionando corretamente
-- =====================================================
