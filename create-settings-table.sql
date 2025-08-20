-- Script para criar a tabela settings
-- Execute este script após criar a tabela profiles

CREATE TABLE IF NOT EXISTS public.settings (
    profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    voice_enabled boolean DEFAULT false,
    locale text DEFAULT 'pt-BR',
    notifications_enabled boolean DEFAULT true,
    tts_speed real DEFAULT 1.0,
    tts_volume real DEFAULT 0.8,
    updated_at timestamptz DEFAULT now()
);

-- Habilitar RLS
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- Políticas de acesso
CREATE POLICY "Usuários podem gerenciar próprias configurações"
    ON public.settings FOR ALL
    USING (auth.uid() = profile_id)
    WITH CHECK (auth.uid() = profile_id);
