# 🔧 Guia para Corrigir o Banco de Dados do Orkut

## ❌ Erro Atual:
```
ERROR: 42P01: relation "public.posts" does not exist
```

## ✅ Solução Completa:

### 1️⃣ **Acesse o Supabase Dashboard**
- Vá para: https://supabase.com/dashboard
- Faça login na sua conta
- Selecione o projeto do Orkut

### 2️⃣ **Abra o SQL Editor**
- No painel lateral esquerdo, clique em **"SQL Editor"**
- Ou vá para: **Database → SQL Editor**

### 3️⃣ **Execute o Script Principal**
- Abra o arquivo `CREATE_ALL_TABLES.sql` 
- **Copie TODO o conteúdo** do arquivo
- **Cole no SQL Editor** do Supabase
- Clique em **"RUN"** (botão verde)

### 4️⃣ **Aguarde a Execução**
- O script vai criar todas as tabelas necessárias
- Vai inserir dados demo para teste
- Vai configurar índices para performance

## 📋 O que o Script Cria:

### 🗂️ **Tabelas Principais:**
1. ✅ `profiles` - Perfis dos usuários
2. ✅ `posts` - Posts do feed
3. ✅ `communities` - Comunidades
4. ✅ `scraps` - Recados dos perfis
5. ✅ `messages` - Mensagens privadas
6. ✅ `friendships` - Sistema de amizades
7. ✅ `photos` - Galeria de fotos
8. ✅ `likes` - Curtidas nos posts
9. ✅ `comments` - Comentários nos posts
10. ✅ `community_members` - Membros das comunidades

### 🎯 **Dados Demo Inclusos:**
- 8 comunidades temáticas nostálgicas
- Posts de exemplo com emojis
- Scraps carinhosos entre usuários
- Fotos de exemplo
- Curtidas e comentários demo
- Relacionamentos de amizade

## 🔍 **Verificação Pós-Execução:**

Após executar o script, você deve ver uma tabela listando todas as tabelas criadas:

```
table_name          | table_type
--------------------|------------
comments            | BASE TABLE
communities         | BASE TABLE
community_members   | BASE TABLE
friendships         | BASE TABLE
likes              | BASE TABLE
messages           | BASE TABLE
photos             | BASE TABLE
posts              | BASE TABLE
profiles           | BASE TABLE
scraps             | BASE TABLE
```

## 🚨 **Se Houver Erros:**

### Erro de Permissão:
- Certifique-se de estar logado como owner do projeto
- Verifique se tem permissões de admin

### Erro de Tabela Existente:
- O script usa `DROP TABLE IF EXISTS` para tabelas que podem ter conflito
- Use `CREATE TABLE IF NOT EXISTS` para tabelas que devem ser preservadas

### Erro de Dados Duplicados:
- O script usa `ON CONFLICT DO NOTHING` para evitar dados duplicados

## 🎉 **Após Executar com Sucesso:**

1. **✅ Teste o Site**: Acesse o Orkut e veja se o erro desapareceu
2. **✅ Verifique o Feed**: Deve mostrar posts demo
3. **✅ Teste Perfis**: Acesse `/perfil` e veja scraps
4. **✅ Explore Comunidades**: Vá para `/comunidades`
5. **✅ Teste Mensagens**: Acesse `/recados`

## 📞 **Em Caso de Dúvidas:**

Se ainda houver problemas:
1. Verifique os logs de erro no console do browser
2. Confirme que todas as tabelas foram criadas no Supabase
3. Teste a conectividade com o banco
4. Verifique as variáveis de ambiente (.env.local)

---

## 🎯 **Resumo Rápido:**
1. **Copie** `CREATE_ALL_TABLES.sql`
2. **Cole** no SQL Editor do Supabase  
3. **Execute** clicando em RUN
4. **Teste** o site - erro deve sumir!

**🌟 Pronto! Seu Orkut estará funcionando perfeitamente!**
