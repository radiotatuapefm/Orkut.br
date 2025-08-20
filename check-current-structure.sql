-- ============================================================================
-- VERIFICAR ESTRUTURA ATUAL - Execute no Supabase SQL Editor
-- ============================================================================

-- Ver todas as colunas da tabela profiles
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Ver dados existentes (sem especificar colunas)
SELECT 'Contagem de registros:' as info;
SELECT COUNT(*) as total_profiles FROM public.profiles;

-- Ver primeiros registros
SELECT 'Primeiros registros:' as info;
SELECT * FROM public.profiles LIMIT 3;
