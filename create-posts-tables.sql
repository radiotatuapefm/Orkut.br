-- Script para criar tabelas de posts, likes e comments
-- Execute este script após criar profiles

-- Tabela de posts
CREATE TABLE IF NOT EXISTS public.posts (
    id bigserial PRIMARY KEY,
    author uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    visibility text CHECK (visibility IN ('public','friends')) DEFAULT 'public',
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Tabela de likes
CREATE TABLE IF NOT EXISTS public.likes (
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (post_id, profile_id)
);

-- Tabela de comentários
CREATE TABLE IF NOT EXISTS public.comments (
    id bigserial PRIMARY KEY,
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE,
    author uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Políticas para posts
CREATE POLICY "Posts públicos visíveis por todos"
    ON public.posts FOR SELECT
    USING (visibility = 'public' OR auth.uid() = author);

CREATE POLICY "Usuários podem criar posts"
    ON public.posts FOR INSERT
    WITH CHECK (auth.uid() = author);

CREATE POLICY "Usuários podem atualizar próprios posts"
    ON public.posts FOR UPDATE
    USING (auth.uid() = author);

-- Políticas para likes
CREATE POLICY "Likes visíveis por todos"
    ON public.likes FOR SELECT
    USING (true);

CREATE POLICY "Usuários podem gerenciar próprios likes"
    ON public.likes FOR ALL
    USING (auth.uid() = profile_id)
    WITH CHECK (auth.uid() = profile_id);

-- Políticas para comentários
CREATE POLICY "Comentários visíveis por todos"
    ON public.comments FOR SELECT
    USING (true);

CREATE POLICY "Usuários podem criar comentários"
    ON public.comments FOR INSERT
    WITH CHECK (auth.uid() = author);

CREATE POLICY "Usuários podem atualizar próprios comentários"
    ON public.comments FOR UPDATE
    USING (auth.uid() = author);
