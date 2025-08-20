-- =====================================================
-- ORKUT.BR - CORRIGIR REGISTROS DUPLICADOS NA TABELA PROFILES
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- 1. VERIFICAR ESTADO ATUAL DA TABELA PROFILES
-- =====================================================

-- Ver quantos registros existem na tabela profiles
SELECT COUNT(*) as total_profiles FROM public.profiles;

-- Ver estrutura da tabela profiles
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Ver todos os perfis existentes
SELECT 
    id,
    username,
    display_name,
    created_at
FROM public.profiles
ORDER BY created_at DESC;

-- Verificar usuários no Supabase Auth (se existirem)
-- SELECT id, email FROM auth.users ORDER BY created_at DESC;

-- 2. VERIFICAR DUPLICATAS ESPECÍFICAS
-- =====================================================

-- Procurar IDs duplicados (não deveria ter nenhum)
SELECT 
    id,
    COUNT(*) as occurrences
FROM public.profiles
GROUP BY id
HAVING COUNT(*) > 1;

-- Procurar usernames duplicados
SELECT 
    username,
    COUNT(*) as occurrences
FROM public.profiles
WHERE username IS NOT NULL
GROUP BY username
HAVING COUNT(*) > 1;

-- 3. SOLUÇÃO A: LIMPAR TODOS OS PERFIS (RESET COMPLETO)
-- =====================================================
-- DESCOMENTE APENAS SE QUISER FAZER RESET COMPLETO:

-- DELETE FROM public.profiles;
-- SELECT 'Todos os perfis foram removidos!' as status;

-- 4. SOLUÇÃO B: REMOVER APENAS PERFIS ÓRFÃOS (SEM AUTH)
-- =====================================================
-- Esta consulta remove perfis que não têm usuário correspondente no auth

-- Primeiro, vamos ver quais perfis podem estar órfãos
SELECT 
    p.id,
    p.username,
    p.display_name,
    p.created_at,
    'Perfil pode estar órfão' as status
FROM public.profiles p
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = p.id
);

-- DESCOMENTE PARA REMOVER PERFIS ÓRFÃOS:
-- DELETE FROM public.profiles 
-- WHERE NOT EXISTS (
--     SELECT 1 FROM auth.users u WHERE u.id = profiles.id
-- );

-- 5. SOLUÇÃO C: RESOLVER CONFLITO ESPECÍFICO
-- =====================================================
-- Se você souber o ID específico que está causando problema

-- Exemplo: Remover perfil específico (substitua o UUID pelo problemático)
-- DELETE FROM public.profiles WHERE id = 'UUID_AQUI';

-- 6. PREVENÇÃO: CONFIGURAR TRIGGER PARA AUTO-CRIAÇÃO
-- =====================================================

-- Função para criar perfil automaticamente quando usuário se registra
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    COALESCE(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING; -- Evita erro de duplicação
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger que executa a função quando novo usuário é criado
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. VERIFICAÇÃO FINAL
-- =====================================================

-- Contar perfis após limpeza
SELECT COUNT(*) as total_profiles_after_fix FROM public.profiles;

-- Verificar se não há mais duplicatas
SELECT 
    id,
    COUNT(*) as occurrences
FROM public.profiles
GROUP BY id
HAVING COUNT(*) > 1;

-- Mostrar perfis restantes
SELECT 
    id,
    username,
    display_name,
    created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- INSTRUÇÕES DE USO:
-- 1. Execute as seções 1 e 2 primeiro para diagnosticar
-- 2. Escolha UMA das soluções (A, B ou C) conforme o caso
-- 3. Execute a seção 6 para prevenir futuros problemas
-- 4. Execute a seção 7 para verificar o resultado
-- =====================================================
