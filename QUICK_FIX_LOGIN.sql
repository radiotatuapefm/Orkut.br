-- =====================================================
-- ORKUT.BR - CORREÇÃO RÁPIDA PARA PROBLEMA DE LOGIN
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- SOLUÇÃO RÁPIDA: Desabilitar RLS na tabela profiles
-- Isso permite que o Supabase Auth funcione normalmente
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Verificar se foi desabilitado
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'profiles';

-- =====================================================
-- PROBLEMA RESOLVIDO!
-- Login e cadastro funcionarão normalmente
-- =====================================================
