-- =====================================================
-- ORKUT.BR - SCRIPT SIMPLES (EXECUTE PARTE POR PARTE)
-- =====================================================

-- PARTE 1: Criar tabela profiles
-- Execute este bloco primeiro:

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

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PARTE 2: Criar políticas para profiles
-- Execute este bloco em seguida:

CREATE POLICY "Profiles visíveis por todos" 
    ON public.profiles FOR SELECT 
    USING (true);

CREATE POLICY "Usuários podem inserir próprio perfil" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- =====================================================
-- PARTE 3: Criar trigger automático
-- Execute este bloco:

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

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- PARTE 4: Criar tabela communities
-- Execute este bloco:

CREATE TABLE IF NOT EXISTS public.communities (
    id bigserial PRIMARY KEY,
    name text UNIQUE NOT NULL,
    description text DEFAULT '',
    category text DEFAULT 'Geral',
    owner uuid,
    members_count integer DEFAULT 0,
    photo_url text DEFAULT 'https://images.pexels.com/photos/1595391/pexels-photo-1595391.jpeg?auto=compress&cs=tinysrgb&w=200',
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Communities visíveis por todos"
    ON public.communities FOR SELECT
    USING (true);

-- =====================================================
-- PARTE 5: Inserir dados demo
-- Execute este bloco:

INSERT INTO public.communities (name, description, category, photo_url, members_count) VALUES
('Nostalgia dos Anos 2000', 'Relembre os bons tempos!', 'Nostalgia', 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200', 1250),
('Música', 'Compartilhe músicas', 'Música', 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200', 3420),
('Tecnologia', 'Discussões tech', 'Tecnologia', 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200', 2800),
('Humor', 'Humor brasileiro', 'Entretenimento', 'https://images.pexels.com/photos/1477166/pexels-photo-1477166.jpeg?auto=compress&cs=tinysrgb&w=200', 5600);

-- =====================================================
-- FIM - Agora teste a aplicação!
-- =====================================================
