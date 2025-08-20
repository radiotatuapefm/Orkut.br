# 🔧 Guia Passo a Passo - Configuração do Banco de Dados

## ⚠️ PROBLEMA ATUAL
As tabelas não foram criadas no banco de dados Supabase, impedindo login e criação de usuários.

## 📋 SOLUÇÃO - Execute os Scripts em Ordem

### PASSO 1: Acesse o Supabase Dashboard
1. Vá para: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto: **woyyikaztjrhqzgvbhmn**
4. Na barra lateral esquerda, clique em **SQL Editor**

### PASSO 2: Execute os Scripts em Ordem

#### 2.1 - Primeiro: Tabela Profiles (ESSENCIAL)
1. No SQL Editor, clique em **"+ New query"**
2. Copie TODO o conteúdo do arquivo: `create-profiles-table.sql`
3. Cole no editor e clique em **"Run"**
4. ✅ Verifique se apareceu a mensagem de sucesso

#### 2.2 - Segundo: Tabela Settings
1. Nova query no SQL Editor
2. Copie TODO o conteúdo do arquivo: `create-settings-table.sql`
3. Cole e execute
4. ✅ Confirme sucesso

#### 2.3 - Terceiro: Tabela Communities
1. Nova query no SQL Editor
2. Copie TODO o conteúdo do arquivo: `create-communities-table.sql`
3. Cole e execute
4. ✅ Confirme sucesso

#### 2.4 - Quarto: Tabelas de Posts
1. Nova query no SQL Editor
2. Copie TODO o conteúdo do arquivo: `create-posts-tables.sql`
3. Cole e execute
4. ✅ Confirme sucesso

### PASSO 3: Verificar se as Tabelas foram Criadas

1. Na barra lateral do Supabase, clique em **"Database"**
2. Clique em **"Tables"**
3. Você deve ver as seguintes tabelas:
   - ✅ `profiles` 
   - ✅ `settings`
   - ✅ `communities`
   - ✅ `posts`
   - ✅ `likes`
   - ✅ `comments`

### PASSO 4: Testar a Aplicação

1. Acesse: https://orkut-qa4td7ulz-astridnielsen-labs-projects.vercel.app
2. Clique em **"Cadastrar"** 
3. Crie uma conta com:
   - Email válido
   - Senha (mín. 6 caracteres)
   - Nome de usuário
   - Nome completo
4. ✅ O perfil deve ser criado automaticamente!

## 🔍 VERIFICAÇÃO EXTRA

Se ainda houver problemas, verifique no Supabase:

### Verificar Tabela Profiles:
1. Vá em **Database > Tables**
2. Clique na tabela **profiles**
3. Vá na aba **"Data"**
4. Após criar um usuário, deve aparecer uma linha com os dados

### Verificar Políticas RLS:
1. Na tabela **profiles**, clique na aba **"Policies"**
2. Deve ter 3 políticas ativas:
   - "Profiles são visíveis por todos"
   - "Usuários podem atualizar próprio perfil" 
   - "Usuários podem inserir próprio perfil"

## 🚨 EM CASO DE ERRO

### Erro: "relation already exists"
- ✅ **Normal!** Significa que a tabela já existe
- Continue com o próximo script

### Erro: "permission denied"
- Verifique se está logado no projeto correto
- Tente executar script por script

### Erro: "syntax error"
- Verifique se copiou TODO o conteúdo do arquivo
- Não deixe espaços extras no início/fim

### Tabelas não aparecem:
1. Recarregue a página do Supabase (F5)
2. Verifique se está no projeto **woyyikaztjrhqzgvbhmn**
3. Tente executar os scripts novamente

## ✅ CONFIRMAÇÃO FINAL

Quando tudo estiver funcionando:

1. ✅ Tabelas criadas no Database > Tables
2. ✅ Usuário consegue se cadastrar
3. ✅ Perfil aparece automaticamente na tabela profiles
4. ✅ Comunidades aparecem na página inicial
5. ✅ Não há mais erros de "table not found"

## 📞 PRÓXIMOS PASSOS

Depois que as tabelas básicas funcionarem, você pode executar o script completo (`setup-database.sql`) para adicionar todas as funcionalidades avançadas como:
- Amizades
- Mensagens
- Chamadas de vídeo
- Notificações
- etc.

---

**💡 DICA:** Execute os scripts um por vez e verifique se cada um funciona antes de continuar para o próximo!
