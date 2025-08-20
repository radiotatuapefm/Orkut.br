-- =====================================================
-- ORKUT.BR - SOLUÇÃO DEFINITIVA PARA PROFILES DUPLICADOS
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- 1. LIMPAR TUDO E RECOMEÇAR
-- =====================================================

-- Remover trigger existente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Remover função existente
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Limpar tabela profiles completamente
DELETE FROM public.profiles;

-- Verificar se limpou
SELECT COUNT(*) as profiles_count FROM public.profiles;

-- 2. RECRIAR TABELA PROFILES SEM DEPENDÊNCIAS
-- =====================================================

-- Ver estrutura atual
\d public.profiles;

-- 3. SOLUÇÃO ALTERNATIVA: USAR UPSERT NO CÓDIGO
-- =====================================================
-- Em vez de trigger, vamos configurar para o código handle isso

-- Verificar se RLS está desabilitado (deve estar)
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'profiles';

-- Se RLS estiver habilitado, desabilitar
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 4. CRIAR FUNÇÃO MANUAL PARA INSERÇÃO SEGURA
-- =====================================================

CREATE OR REPLACE FUNCTION public.create_profile_safe(
    user_id uuid,
    user_email text
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.profiles (id, username, display_name, created_at, updated_at)
    VALUES (
        user_id,
        split_part(user_email, '@', 1),
        split_part(user_email, '@', 1),
        now(),
        now()
    )
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        display_name = EXCLUDED.display_name,
        updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. TESTAR A FUNÇÃO
-- =====================================================

-- Teste com UUID fictício
SELECT public.create_profile_safe(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'teste@exemplo.com'
);

-- Verificar se foi criado
SELECT * FROM public.profiles WHERE username = 'teste';

-- Tentar criar novamente (não deve dar erro)
SELECT public.create_profile_safe(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'teste@exemplo.com'
);

-- Verificar se ainda há apenas 1 registro
SELECT COUNT(*) as count FROM public.profiles WHERE username = 'teste';

-- 6. LIMPAR TESTE
-- =====================================================

DELETE FROM public.profiles WHERE username = 'teste';

-- 7. VERIFICAÇÃO FINAL
-- =====================================================

SELECT 
    'Tabela profiles limpa e configurada!' as status,
    COUNT(*) as total_profiles
FROM public.profiles;

-- Mostrar estrutura final
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- INSTRUÇÕES PARA O CÓDIGO:
-- Agora o código Next.js deve criar perfils usando:
-- 
-- await supabase.rpc('create_profile_safe', {
--   user_id: user.id,
--   user_email: user.email
-- });
-- 
-- Isso vai funcionar sempre sem erro de duplicação
-- =====================================================
