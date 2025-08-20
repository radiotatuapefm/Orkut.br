-- =====================================================
-- CORREÇÃO PARA POLÍTICAS RLS - EXECUTE NO SUPABASE
-- =====================================================

-- Primeiro, vamos remover as políticas existentes
DROP POLICY IF EXISTS "Profiles visíveis por todos" ON public.profiles;
DROP POLICY IF EXISTS "Usuários podem inserir próprio perfil" ON public.profiles;
DROP POLICY IF EXISTS "Usuários podem atualizar próprio perfil" ON public.profiles;

-- Criar políticas corretas (uma por vez)
-- POLÍTICA 1: Permitir visualização
CREATE POLICY "profiles_select_policy"
ON public.profiles FOR SELECT
USING (true);

-- POLÍTICA 2: Permitir inserção (IMPORTANTE: usar auth.uid() = id)
CREATE POLICY "profiles_insert_policy"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

-- POLÍTICA 3: Permitir atualização própria
CREATE POLICY "profiles_update_policy"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Recriar função do trigger com tratamento de erro
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    -- Inserir com bypass temporário de RLS
    INSERT INTO public.profiles (id, username, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log do erro para debug
    RAISE LOG 'Erro ao criar perfil para usuário %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Recriar o trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ALTERNATIVA: DESABILITAR RLS TEMPORARIAMENTE
-- (Execute apenas se as políticas acima não funcionarem)
-- =====================================================

-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- FIM DA CORREÇÃO
-- =====================================================
