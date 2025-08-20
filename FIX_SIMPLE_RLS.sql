-- =====================================================
-- CORREÇÃO RÁPIDA - DESABILITAR RLS TEMPORARIAMENTE
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- Desabilitar RLS na tabela profiles
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- Verificar se funcionou
SELECT * FROM public.profiles LIMIT 1;

-- =====================================================
-- AGORA TESTE O CADASTRO NA APLICAÇÃO
-- =====================================================

-- Depois que funcionar, você pode reabilitar RLS:
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- E criar políticas mais simples:
-- CREATE POLICY "allow_all_profiles" ON public.profiles USING (true);

-- =====================================================
-- FIM DA CORREÇÃO RÁPIDA
-- =====================================================
