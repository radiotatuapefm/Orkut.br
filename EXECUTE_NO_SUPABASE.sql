-- =====================================================
-- ORKUT.BR - SCRIPT ESSENCIAL PARA SUPABASE
-- COPIE E COLE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- Criar tabela profiles (ESSENCIAL PARA LOGIN)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    username text UNIQUE NOT NULL,
    display_name text NOT NULL,
    photo_url text DEFAULT 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
    relationship text DEFAULT 'Solteiro(a)',
    location text DEFAULT '',
    birthday date,
    bio text DEFAULT '',
    fans_count integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Habilitar segurança RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY IF NOT EXISTS "Profiles visíveis por todos" 
    ON public.profiles FOR SELECT 
    USING (true);

CREATE POLICY IF NOT EXISTS "Usuários podem inserir próprio perfil" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

CREATE POLICY IF NOT EXISTS "Usuários podem atualizar próprio perfil" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

-- Criar função para trigger (CRIA PERFIL AUTOMATICAMENTE)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger (EXECUTADO QUANDO USUÁRIO SE CADASTRA)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Criar tabela communities
CREATE TABLE IF NOT EXISTS public.communities (
    id bigserial PRIMARY KEY,
    name text UNIQUE NOT NULL,
    description text DEFAULT '',
    category text DEFAULT 'Geral',
    owner uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    members_count integer DEFAULT 0,
    photo_url text DEFAULT 'https://images.pexels.com/photos/1595391/pexels-photo-1595391.jpeg?auto=compress&cs=tinysrgb&w=200',
    created_at timestamptz DEFAULT now()
);

-- Habilitar RLS para communities
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Communities visíveis por todos"
    ON public.communities FOR SELECT
    USING (true);

-- Criar tabela posts (PARA SISTEMA DE POSTS)
CREATE TABLE IF NOT EXISTS public.posts (
    id bigserial PRIMARY KEY,
    author uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    visibility text CHECK (visibility IN ('public','friends')) DEFAULT 'public',
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Posts públicos visíveis por todos"
    ON public.posts FOR SELECT
    USING (visibility = 'public' OR auth.uid() = author);

CREATE POLICY IF NOT EXISTS "Usuários podem criar posts"
    ON public.posts FOR INSERT
    WITH CHECK (auth.uid() = author);

-- Criar tabela likes
CREATE TABLE IF NOT EXISTS public.likes (
    post_id bigint REFERENCES public.posts(id) ON DELETE CASCADE,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    PRIMARY KEY (post_id, profile_id)
);

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "Likes visíveis por todos"
    ON public.likes FOR SELECT
    USING (true);

CREATE POLICY IF NOT EXISTS "Usuários podem gerenciar próprios likes"
    ON public.likes FOR ALL
    USING (auth.uid() = profile_id)
    WITH CHECK (auth.uid() = profile_id);

-- Inserir comunidades demo (DADOS DE TESTE)
INSERT INTO public.communities (name, description, category, photo_url, members_count) VALUES
('Nostalgia dos Anos 2000', 'Relembre os bons tempos dos anos 2000! Músicas, filmes, jogos e muito mais.', 'Nostalgia', 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200', 1250),
('Música', 'Comunidade para compartilhar e descobrir novas músicas de todos os gêneros.', 'Música', 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200', 3420),
('Tecnologia', 'Discussões sobre as últimas novidades em tecnologia, programação e inovação.', 'Tecnologia', 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200', 2800),
('Jogos Retrô', 'Para os amantes dos jogos clássicos! Arcade, Atari, Nintendo e muito mais.', 'Jogos', 'https://images.pexels.com/photos/1298601/pexels-photo-1298601.jpeg?auto=compress&cs=tinysrgb&w=200', 890),
('Humor', 'O melhor do humor brasileiro! Piadas, memes e muita diversão.', 'Entretenimento', 'https://images.pexels.com/photos/1477166/pexels-photo-1477166.jpeg?auto=compress&cs=tinysrgb&w=200', 5600),
('Receitas da Vovó', 'Compartilhe e descubra receitas tradicionais e caseiras.', 'Culinária', 'https://images.pexels.com/photos/1556698/pexels-photo-1556698.jpeg?auto=compress&cs=tinysrgb&w=200', 2100)
ON CONFLICT (name) DO NOTHING;

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
