-- ============================================================================
-- BACKUP DA ESTRUTURA ATUAL - Execute primeiro no Supabase SQL Editor
-- ============================================================================

-- Este script vai gerar comandos para recriar a estrutura atual
-- Execute este comando para ver a estrutura atual das tabelas:

SELECT 
    'CREATE TABLE ' || schemaname || '.' || tablename || ' (' ||
    array_to_string(
        array_agg(
            column_name || ' ' || data_type ||
            CASE 
                WHEN character_maximum_length IS NOT NULL 
                THEN '(' || character_maximum_length || ')'
                ELSE ''
            END ||
            CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END
        ), 
        ', '
    ) || ');' as create_statement
FROM information_schema.tables t
JOIN information_schema.columns c ON c.table_name = t.tablename AND c.table_schema = t.schemaname
WHERE t.schemaname = 'public' 
AND t.tablename IN ('profiles', 'friendships', 'posts', 'messages', 'user_status')
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Também listar todas as funções existentes
SELECT 
    'CREATE FUNCTION ' || routine_name || '(' || 
    COALESCE(string_agg(parameter_name || ' ' || data_type, ', '), '') || ') RETURNS ' || 
    data_type || ';' as function_statement
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON p.specific_name = r.specific_name
WHERE r.routine_schema = 'public' 
AND r.routine_type = 'FUNCTION'
GROUP BY routine_name, r.data_type
ORDER BY routine_name;

-- Listar dados existentes na tabela profiles
SELECT 'Dados atuais na tabela profiles:' as info;
SELECT * FROM public.profiles LIMIT 10;
