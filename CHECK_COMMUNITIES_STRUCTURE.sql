-- =====================================================
-- VERIFICAR ESTRUTURA DA TABELA COMMUNITIES
-- =====================================================

-- Ver todas as colunas da tabela communities
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'communities' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Ver se existe coluna owner
SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'communities' 
    AND column_name = 'owner'
    AND table_schema = 'public'
) as has_owner_column;

-- Ver se existe coluna owner_id
SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'communities' 
    AND column_name = 'owner_id'
    AND table_schema = 'public'
) as has_owner_id_column;
