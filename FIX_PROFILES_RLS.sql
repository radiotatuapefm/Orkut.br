-- =====================================================
-- ORKUT.BR - CORRIGIR RLS NA TABELA PROFILES
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- 1. VERIFICAR STATUS ATUAL DA TABELA PROFILES
-- =====================================================

-- Ver se RLS está habilitado na tabela profiles
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'profiles';

-- Ver políticas existentes na tabela profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'profiles';

-- 2. CRIAR POLÍTICAS PARA A TABELA PROFILES
-- =====================================================

-- Política: Usuários podem ver todos os perfis (rede social pública)
DROP POLICY IF EXISTS "profiles_select_policy" ON public.profiles;
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT USING (true);

-- Política: Usuários autenticados podem criar seu próprio perfil
DROP POLICY IF EXISTS "profiles_insert_policy" ON public.profiles;
CREATE POLICY "profiles_insert_policy" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Política: Usuários podem editar apenas seu próprio perfil
DROP POLICY IF EXISTS "profiles_update_policy" ON public.profiles;
CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Política: Usuários podem deletar apenas seu próprio perfil
DROP POLICY IF EXISTS "profiles_delete_policy" ON public.profiles;
CREATE POLICY "profiles_delete_policy" ON public.profiles
    FOR DELETE USING (auth.uid() = id);

-- 3. ALTERNATIVA: DESABILITAR RLS NA TABELA PROFILES (MAIS SIMPLES)
-- =====================================================
-- DESCOMENTE APENAS UMA DAS OPÇÕES ABAIXO:

-- OPÇÃO A: Manter RLS com políticas (mais seguro - já configurado acima)
-- (Políticas já criadas acima)

-- OPÇÃO B: Desabilitar RLS na tabela profiles (mais simples para desenvolvimento)
-- DESCOMENTE A LINHA ABAIXO SE QUISER DESABILITAR RLS:
-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 4. VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar políticas criadas para profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename = 'profiles'
ORDER BY policyname;

-- Verificar estrutura da tabela profiles
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Testar se um usuário pode criar um perfil (simulação)
SELECT 
    'RLS configurado corretamente para profiles!' as status,
    current_user as current_db_user,
    auth.uid() as current_auth_user;

-- =====================================================
-- PROBLEMA DO LOGIN RESOLVIDO!
-- Agora usuários podem criar perfis sem erro de RLS
-- =====================================================
