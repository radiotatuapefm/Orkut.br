-- =====================================================
-- ORKUT.BR - TABELAS ADICIONAIS PARA FUNCIONALIDADES
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- Tabela de scraps (recados)
CREATE TABLE IF NOT EXISTS public.scraps (
    id bigserial PRIMARY KEY,
    to_profile uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    from_profile uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Tabela de depoimentos
CREATE TABLE IF NOT EXISTS public.testimonials (
    id bigserial PRIMARY KEY,
    to_profile uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    from_profile uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    approved boolean DEFAULT false,
    created_at timestamptz DEFAULT now()
);

-- Tabela de mensagens privadas
CREATE TABLE IF NOT EXISTS public.messages (
    id bigserial PRIMARY KEY,
    thread_id uuid DEFAULT gen_random_uuid(),
    sender uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    read boolean DEFAULT false,
    archived_by_sender boolean DEFAULT false,
    archived_by_recipient boolean DEFAULT false
);

-- Tabela de amizades
CREATE TABLE IF NOT EXISTS public.friendships (
    id bigserial PRIMARY KEY,
    requester uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    addressee uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    status text CHECK (status IN ('pending','accepted','blocked')) DEFAULT 'pending',
    created_at timestamptz DEFAULT now(),
    UNIQUE(requester, addressee)
);

-- Tabela de fotos
CREATE TABLE IF NOT EXISTS public.photos (
    id bigserial PRIMARY KEY,
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    description text DEFAULT '',
    created_at timestamptz DEFAULT now()
);

-- Habilitar RLS (desabilitado temporariamente para facilitar desenvolvimento)
-- ALTER TABLE public.scraps ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.testimonials ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;

-- Inserir dados demo para scraps
INSERT INTO public.scraps (to_profile, from_profile, content) VALUES
((SELECT id FROM public.profiles LIMIT 1), (SELECT id FROM public.profiles LIMIT 1), 'Que saudades dos anos 2000! Adorei seu perfil retrô! 😊'),
((SELECT id FROM public.profiles LIMIT 1), (SELECT id FROM public.profiles LIMIT 1), 'Oiee! Vamos ser amigas? Tenho certeza que vamos nos dar super bem! 💕'),
((SELECT id FROM public.profiles LIMIT 1), (SELECT id FROM public.profiles LIMIT 1), 'E aí! Como está sendo essa volta ao passado? Orkut era demais mesmo! 😄')
ON CONFLICT DO NOTHING;

-- Inserir amigos demo
INSERT INTO public.friendships (requester, addressee, status) VALUES
((SELECT id FROM public.profiles LIMIT 1), (SELECT id FROM public.profiles LIMIT 1), 'accepted')
ON CONFLICT (requester, addressee) DO NOTHING;

-- Inserir fotos demo
INSERT INTO public.photos (profile_id, photo_url, description) VALUES
((SELECT id FROM public.profiles LIMIT 1), 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=200', 'Foto de perfil'),
((SELECT id FROM public.profiles LIMIT 1), 'https://images.pexels.com/photos/1040880/pexels-photo-1040880.jpeg?auto=compress&cs=tinysrgb&w=200', 'Lembranças dos anos 2000'),
((SELECT id FROM public.profiles LIMIT 1), 'https://images.pexels.com/photos/1416820/pexels-photo-1416820.jpeg?auto=compress&cs=tinysrgb&w=200', 'Nostalgia pura')
ON CONFLICT DO NOTHING;

-- =====================================================
-- FIM DAS TABELAS ADICIONAIS
-- =====================================================
