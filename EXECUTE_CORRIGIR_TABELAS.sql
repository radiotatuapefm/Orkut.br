-- =====================================================
-- ORKUT.BR - CORREÇÃO E CRIAÇÃO DE TABELAS
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- Corrigir tabela de scraps
DROP TABLE IF EXISTS public.scraps CASCADE;
CREATE TABLE public.scraps (
    id bigserial PRIMARY KEY,
    from_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    to_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Corrigir tabela de mensagens 
DROP TABLE IF EXISTS public.messages CASCADE;
CREATE TABLE public.messages (
    id bigserial PRIMARY KEY,
    from_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    to_profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    read_at timestamptz DEFAULT NULL
);

-- Corrigir tabela de amizades
DROP TABLE IF EXISTS public.friendships CASCADE;
CREATE TABLE public.friendships (
    id bigserial PRIMARY KEY,
    requester_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    addressee_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    status text CHECK (status IN ('pending','accepted','blocked')) DEFAULT 'pending',
    created_at timestamptz DEFAULT now(),
    UNIQUE(requester_id, addressee_id)
);

-- Criar tabela de fotos se não existir
CREATE TABLE IF NOT EXISTS public.photos (
    id bigserial PRIMARY KEY,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    caption text DEFAULT '',
    created_at timestamptz DEFAULT now()
);

-- Criar tabela de likes se não existir
CREATE TABLE IF NOT EXISTS public.likes (
    id bigserial PRIMARY KEY,
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE(post_id, profile_id)
);

-- Criar tabela de membros de comunidades se não existir
CREATE TABLE IF NOT EXISTS public.community_members (
    id bigserial PRIMARY KEY,
    community_id bigint REFERENCES public.communities(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at timestamptz DEFAULT now(),
    role text DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
    UNIQUE(community_id, profile_id)
);

-- Adicionar campos faltantes na tabela profiles se não existirem
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS profile_views integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS scrapy_count integer DEFAULT 0;

-- Inserir dados demo para desenvolvimento

-- Inserir scraps demo (apenas se não existirem)
INSERT INTO public.scraps (from_profile_id, to_profile_id, content) 
SELECT 
    p1.id as from_profile_id,
    p2.id as to_profile_id,
    unnest(ARRAY[
        'Que saudades dos anos 2000! Adorei seu perfil retrô! 😊',
        'Oiee! Vamos ser amigas? Tenho certeza que vamos nos dar super bem! 💕',
        'E aí! Como está sendo essa volta ao passado? Orkut era demais mesmo! 😄',
        'Seu perfil está lindo! Que nostalgia boa! 🌟',
        'Adoro sua página de recados! Me lembra tanto do Orkut original! ❤️'
    ]) as content
FROM 
    (SELECT id FROM public.profiles ORDER BY created_at LIMIT 2) p1,
    (SELECT id FROM public.profiles ORDER BY created_at DESC LIMIT 2) p2
WHERE p1.id != p2.id
ON CONFLICT DO NOTHING;

-- Inserir amizades demo
INSERT INTO public.friendships (requester_id, addressee_id, status)
SELECT 
    p1.id as requester_id,
    p2.id as addressee_id,
    'accepted' as status
FROM 
    (SELECT id FROM public.profiles ORDER BY created_at LIMIT 1) p1,
    (SELECT id FROM public.profiles ORDER BY created_at DESC LIMIT 1) p2
WHERE p1.id != p2.id
ON CONFLICT (requester_id, addressee_id) DO NOTHING;

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
        'Foto de perfil',
        'Lembranças dos anos 2000',
        'Nostalgia pura',
        'Momentos especiais',
        'Saudades dessa época'
    ]) as caption
FROM public.profiles
ON CONFLICT DO NOTHING;

-- Inserir alguns likes demo
INSERT INTO public.likes (post_id, profile_id)
SELECT 
    posts.id as post_id,
    profiles.id as profile_id
FROM 
    public.posts,
    public.profiles
WHERE posts.author != profiles.id
LIMIT 10
ON CONFLICT (post_id, profile_id) DO NOTHING;

-- Inserir membros de comunidades demo
INSERT INTO public.community_members (community_id, profile_id)
SELECT 
    communities.id as community_id,
    profiles.id as profile_id
FROM 
    public.communities,
    public.profiles
LIMIT 15
ON CONFLICT (community_id, profile_id) DO NOTHING;

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_scraps_to_profile ON public.scraps(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_scraps_from_profile ON public.scraps(from_profile_id);
CREATE INDEX IF NOT EXISTS idx_messages_to_profile ON public.messages(to_profile_id);
CREATE INDEX IF NOT EXISTS idx_messages_from_profile ON public.messages(from_profile_id);
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_photos_profile ON public.photos(profile_id);
CREATE INDEX IF NOT EXISTS idx_likes_post ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_profile ON public.likes(profile_id);
CREATE INDEX IF NOT EXISTS idx_community_members_community ON public.community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_profile ON public.community_members(profile_id);

-- Atualizar contadores
UPDATE public.profiles 
SET scrapy_count = (
    SELECT COUNT(*) FROM public.scraps WHERE to_profile_id = profiles.id
);

-- =====================================================
-- FIM DAS CORREÇÕES
-- Execute este script no Supabase SQL Editor
-- =====================================================
