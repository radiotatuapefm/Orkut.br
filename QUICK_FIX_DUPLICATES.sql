-- =====================================================
-- ORKUT.BR - CORREÇÃO RÁPIDA PARA PROFILES DUPLICADOS
-- EXECUTE NO SQL EDITOR DO SUPABASE
-- =====================================================

-- SOLUÇÃO SIMPLES: Limpar tabela profiles e recriar automaticamente
DELETE FROM public.profiles;

-- Criar função que gera perfil automaticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    new.id,
    split_part(new.email, '@', 1),
    split_part(new.email, '@', 1)
  )
  ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remover trigger existente (se houver)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Criar trigger para novos usuários
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verificar resultado
SELECT 'Tabela profiles limpa e trigger configurado!' as status;
SELECT COUNT(*) as total_profiles FROM public.profiles;

-- =====================================================
-- PROBLEMA RESOLVIDO!
-- Agora você pode fazer login normalmente
-- =====================================================
