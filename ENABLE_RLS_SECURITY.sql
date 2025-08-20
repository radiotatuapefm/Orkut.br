-- =====================================================
-- ORKUT.BR - HABILITAR ROW LEVEL SECURITY (RLS)
-- EXECUTE NO SQL EDITOR DO SUPABASE APÓS O SCRIPT PRINCIPAL
-- =====================================================

-- 1. HABILITAR RLS EM TODAS AS TABELAS
-- =====================================================

-- Habilitar RLS na tabela posts
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela scraps
ALTER TABLE public.scraps ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela friendships
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela photos
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela likes
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela comments
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela community_members
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela communities (por segurança)
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

-- 2. POLÍTICAS DE SEGURANÇA PARA POSTS
-- =====================================================

-- Política: Usuários podem ver todos os posts (feed público)
CREATE POLICY "posts_select_policy" ON public.posts
    FOR SELECT USING (true);

-- Política: Usuários autenticados podem criar posts
CREATE POLICY "posts_insert_policy" ON public.posts
    FOR INSERT WITH CHECK (auth.uid() = author);

-- Política: Usuários podem editar apenas seus próprios posts
CREATE POLICY "posts_update_policy" ON public.posts
    FOR UPDATE USING (auth.uid() = author);

-- Política: Usuários podem deletar apenas seus próprios posts
CREATE POLICY "posts_delete_policy" ON public.posts
    FOR DELETE USING (auth.uid() = author);

-- 3. POLÍTICAS DE SEGURANÇA PARA MESSAGES
-- =====================================================

-- Política: Usuários só podem ver mensagens que enviaram ou receberam
CREATE POLICY "messages_select_policy" ON public.messages
    FOR SELECT USING (
        auth.uid() = from_profile_id OR 
        auth.uid() = to_profile_id
    );

-- Política: Usuários autenticados podem enviar mensagens
CREATE POLICY "messages_insert_policy" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = from_profile_id);

-- Política: Usuários podem atualizar apenas mensagens que receberam (marcar como lida)
CREATE POLICY "messages_update_policy" ON public.messages
    FOR UPDATE USING (auth.uid() = to_profile_id);

-- 4. POLÍTICAS DE SEGURANÇA PARA SCRAPS
-- =====================================================

-- Política: Usuários podem ver scraps direcionados a eles ou que enviaram
CREATE POLICY "scraps_select_policy" ON public.scraps
    FOR SELECT USING (
        auth.uid() = from_profile_id OR 
        auth.uid() = to_profile_id
    );

-- Política: Usuários autenticados podem criar scraps
CREATE POLICY "scraps_insert_policy" ON public.scraps
    FOR INSERT WITH CHECK (auth.uid() = from_profile_id);

-- Política: Usuários podem deletar scraps que enviaram ou receberam
CREATE POLICY "scraps_delete_policy" ON public.scraps
    FOR DELETE USING (
        auth.uid() = from_profile_id OR 
        auth.uid() = to_profile_id
    );

-- 5. POLÍTICAS DE SEGURANÇA PARA FRIENDSHIPS
-- =====================================================

-- Política: Usuários podem ver amizades que envolvem eles
CREATE POLICY "friendships_select_policy" ON public.friendships
    FOR SELECT USING (
        auth.uid() = requester_id OR 
        auth.uid() = addressee_id
    );

-- Política: Usuários autenticados podem criar solicitações de amizade
CREATE POLICY "friendships_insert_policy" ON public.friendships
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

-- Política: Usuários podem atualizar amizades direcionadas a eles (aceitar/rejeitar)
CREATE POLICY "friendships_update_policy" ON public.friendships
    FOR UPDATE USING (auth.uid() = addressee_id);

-- Política: Usuários podem deletar amizades que criaram ou que envolvem eles
CREATE POLICY "friendships_delete_policy" ON public.friendships
    FOR DELETE USING (
        auth.uid() = requester_id OR 
        auth.uid() = addressee_id
    );

-- 6. POLÍTICAS DE SEGURANÇA PARA PHOTOS
-- =====================================================

-- Política: Usuários podem ver todas as fotos (galeria pública)
CREATE POLICY "photos_select_policy" ON public.photos
    FOR SELECT USING (true);

-- Política: Usuários podem enviar fotos para seu próprio perfil
CREATE POLICY "photos_insert_policy" ON public.photos
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Política: Usuários podem editar apenas suas próprias fotos
CREATE POLICY "photos_update_policy" ON public.photos
    FOR UPDATE USING (auth.uid() = profile_id);

-- Política: Usuários podem deletar apenas suas próprias fotos
CREATE POLICY "photos_delete_policy" ON public.photos
    FOR DELETE USING (auth.uid() = profile_id);

-- 7. POLÍTICAS DE SEGURANÇA PARA LIKES
-- =====================================================

-- Política: Usuários podem ver todas as curtidas
CREATE POLICY "likes_select_policy" ON public.likes
    FOR SELECT USING (true);

-- Política: Usuários autenticados podem curtir posts
CREATE POLICY "likes_insert_policy" ON public.likes
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Política: Usuários podem deletar apenas suas próprias curtidas
CREATE POLICY "likes_delete_policy" ON public.likes
    FOR DELETE USING (auth.uid() = profile_id);

-- 8. POLÍTICAS DE SEGURANÇA PARA COMMENTS
-- =====================================================

-- Política: Usuários podem ver todos os comentários
CREATE POLICY "comments_select_policy" ON public.comments
    FOR SELECT USING (true);

-- Política: Usuários autenticados podem comentar
CREATE POLICY "comments_insert_policy" ON public.comments
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Política: Usuários podem editar apenas seus próprios comentários
CREATE POLICY "comments_update_policy" ON public.comments
    FOR UPDATE USING (auth.uid() = profile_id);

-- Política: Usuários podem deletar apenas seus próprios comentários
CREATE POLICY "comments_delete_policy" ON public.comments
    FOR DELETE USING (auth.uid() = profile_id);

-- 9. POLÍTICAS DE SEGURANÇA PARA COMMUNITIES
-- =====================================================

-- Política: Usuários podem ver todas as comunidades
CREATE POLICY "communities_select_policy" ON public.communities
    FOR SELECT USING (true);

-- Política: Usuários autenticados podem criar comunidades
CREATE POLICY "communities_insert_policy" ON public.communities
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Política: Apenas donos podem editar comunidades
CREATE POLICY "communities_update_policy" ON public.communities
    FOR UPDATE USING (auth.uid() = owner_id);

-- Política: Apenas donos podem deletar comunidades
CREATE POLICY "communities_delete_policy" ON public.communities
    FOR DELETE USING (auth.uid() = owner_id);

-- 10. POLÍTICAS DE SEGURANÇA PARA COMMUNITY_MEMBERS
-- =====================================================

-- Política: Usuários podem ver membros das comunidades
CREATE POLICY "community_members_select_policy" ON public.community_members
    FOR SELECT USING (true);

-- Política: Usuários podem se juntar a comunidades
CREATE POLICY "community_members_insert_policy" ON public.community_members
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Política: Usuários podem sair de comunidades que participam
CREATE POLICY "community_members_delete_policy" ON public.community_members
    FOR DELETE USING (auth.uid() = profile_id);

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se RLS foi habilitado em todas as tabelas
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'posts', 'messages', 'scraps', 'friendships', 
    'photos', 'likes', 'comments', 'communities', 'community_members'
)
ORDER BY tablename;

-- Contar políticas criadas
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =====================================================
-- RLS CONFIGURADO COM SUCESSO!
-- Agora todas as tabelas estão seguras e funcionais
-- =====================================================
