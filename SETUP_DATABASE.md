# 🗄️ Configuração do Banco de Dados Supabase

## ❌ Erro Atual
```
Could not find the table 'public.profiles' in the schema cache
```

## ✅ Solução

### Passo 1: Acesse o Supabase Dashboard
1. Vá para https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto: **woyyikaztjrhqzgvbhmn**

### Passo 2: Execute o Script SQL
1. No dashboard do Supabase, vá para **SQL Editor** (ícone de código na barra lateral)
2. Clique em **"New Query"**
3. Copie todo o conteúdo do arquivo `setup-database.sql` 
4. Cole no editor SQL
5. Clique em **"Run"** para executar

### Passo 3: Verifique as Tabelas
Depois de executar o script, vá para **Database** > **Tables** e confirme que foram criadas:

- ✅ `profiles`
- ✅ `friendships` 
- ✅ `communities`
- ✅ `community_members`
- ✅ `posts`
- ✅ `comments`
- ✅ `likes`
- ✅ `scraps`
- ✅ `testimonials`
- ✅ `messages`
- ✅ `notifications`
- ✅ `calls`
- ✅ `presence`
- ✅ `settings`
- ✅ `audit_log`

### Passo 4: Teste a Aplicação
Após executar o script:

1. Acesse: https://orkut-qa4td7ulz-astridnielsen-labs-projects.vercel.app
2. Tente criar um novo usuário
3. O perfil deve ser criado automaticamente

## 📝 O que o Script Faz

1. **Cria todas as tabelas** necessárias para o Orkut.br
2. **Configura Row Level Security (RLS)** para segurança
3. **Adiciona políticas de acesso** adequadas
4. **Insere dados de demonstração** (comunidades)
5. **Configura relacionamentos** entre tabelas

## ⚠️ Nota Importante

- O script usa `CREATE TABLE IF NOT EXISTS` - é seguro executar múltiplas vezes
- As políticas RLS garantem que usuários só vejam dados apropriados
- Os dados demo ajudam a testar a aplicação imediatamente

## 🔧 Em Caso de Problemas

Se ainda houver erros após executar o script:

1. Verifique se todas as tabelas foram criadas
2. Confirme se as políticas RLS estão ativas
3. Teste com um novo usuário para verificar a criação do perfil

## 📞 Funcionalidades Incluídas

- ✅ Sistema de Perfis e Amizades
- ✅ Comunidades
- ✅ Posts, Comentários e Likes  
- ✅ Scraps e Depoimentos (clássico Orkut)
- ✅ Sistema de Mensagens
- ✅ Notificações
- ✅ Chamadas de Vídeo/Áudio (WebRTC)
- ✅ Sistema de Presença (online/offline)
- ✅ Configurações de Usuário
- ✅ Log de Auditoria
