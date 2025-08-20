-- Script mínimo para criar a tabela profiles
-- Execute este script primeiro no SQL Editor do Supabase

-- Criar a tabela profiles
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

-- Habilitar RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Profiles são visíveis por todos" 
    ON public.profiles FOR SELECT 
    USING (true);

CREATE POLICY "Usuários podem atualizar próprio perfil" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Usuários podem inserir próprio perfil" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Criar função trigger para criar perfil automaticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    
    -- Criar configurações padrão
    INSERT INTO public.settings (profile_id)
    VALUES (NEW.id)
    ON CONFLICT (profile_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Criar trigger para executar quando um novo usuário se registra
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
