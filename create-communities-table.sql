-- Script para criar a tabela communities
-- Execute este script após criar profiles

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

-- Habilitar RLS
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Communities são visíveis por todos"
    ON public.communities FOR SELECT
    USING (true);

CREATE POLICY "Usuários autenticados podem criar comunidades"
    ON public.communities FOR INSERT
    WITH CHECK (auth.uid() = owner);

-- Inserir comunidades de demonstração
INSERT INTO public.communities (name, description, category, photo_url, members_count) VALUES
('Nostalgia dos Anos 2000', 'Relembre os bons tempos dos anos 2000!', 'Nostalgia', 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200', 1250),
('Música', 'Comunidade para compartilhar músicas', 'Música', 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200', 3420),
('Tecnologia', 'Discussões sobre tecnologia', 'Tecnologia', 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200', 2800),
('Jogos Retrô', 'Para amantes dos jogos clássicos', 'Jogos', 'https://images.pexels.com/photos/1298601/pexels-photo-1298601.jpeg?auto=compress&cs=tinysrgb&w=200', 890),
('Humor', 'O melhor do humor brasileiro', 'Entretenimento', 'https://images.pexels.com/photos/1477166/pexels-photo-1477166.jpeg?auto=compress&cs=tinysrgb&w=200', 5600)
ON CONFLICT (name) DO NOTHING;
