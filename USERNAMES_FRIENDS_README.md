# Sistema de Usernames Únicos, Amizades e WhatsApp - Orkut Clone

Este documento descreve as novas funcionalidades implementadas no sistema, incluindo usernames únicos, sistema de amizades e integração com WhatsApp.

## 🎯 Funcionalidades Implementadas

### 1. Sistema de Username Único
- **URLs dinâmicas**: `/perfil/[username]` (ex: `/perfil/juliocamposmachado`)
- **Validação em tempo real**: Verifica disponibilidade durante digitação
- **Geração automática**: Username baseado no nome se não fornecido
- **Normalização**: Remove caracteres especiais e acentos

### 2. Sistema de Amizades Completo
- **Solicitações de amizade**: Enviar, aceitar, rejeitar
- **Bloqueio de usuários**: Sistema de bloqueio bidirecional
- **Status de amizade**: `none`, `pending_sent`, `pending_received`, `friends`, `blocked`
- **Gerenciamento**: Interface completa para todas as ações

### 3. Integração WhatsApp
- **Links automáticos**: Gera URLs `wa.me/5511970603441` automaticamente
- **Mensagem padrão**: Personalizada com nome do usuário
- **Validação telefone**: Números brasileiros com formatação
- **Configurações**: Usuário pode habilitar/desabilitar WhatsApp

### 4. Configurações de Privacidade
- **Visibilidade do perfil**: Público, amigos apenas, privado
- **Visibilidade do telefone**: Público, amigos apenas, privado
- **WhatsApp**: Controle de exibição do botão

## 📊 Estrutura do Banco de Dados

### Tabela `profiles` (atualizada)
```sql
ALTER TABLE profiles 
ADD COLUMN username text UNIQUE,
ADD COLUMN phone text,
ADD COLUMN whatsapp_enabled boolean DEFAULT true,
ADD COLUMN privacy_settings jsonb DEFAULT '{"profile_visibility": "public", "phone_visibility": "friends", "whatsapp_visible": true}';
```

### Tabela `friendships` (nova)
```sql
CREATE TABLE friendships (
    id uuid PRIMARY KEY,
    requester_id uuid REFERENCES profiles(id),
    addressee_id uuid REFERENCES profiles(id),
    status text CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(requester_id, addressee_id)
);
```

### View `friends_view` (nova)
Facilita consultas de amigos aceitos com informações do perfil.

### Funções SQL Criadas
- `generate_username(base_name)`: Gera username único
- `get_profile_by_username(username)`: Busca perfil por username
- `is_username_available(username)`: Verifica disponibilidade
- `auto_generate_username()`: Trigger para gerar username automaticamente

## 🚀 Como Usar

### 1. Integração nos Providers
```tsx
import { FriendsProvider } from '@/contexts/FriendsContext';
import { OnlineStatusProvider } from '@/contexts/OnlineStatusContext';

function App() {
  return (
    <OnlineStatusProvider>
      <FriendsProvider>
        {/* Sua aplicação */}
      </FriendsProvider>
    </OnlineStatusProvider>
  );
}
```

### 2. Botões de Amizade
```tsx
import { FriendshipButtons } from '@/components/FriendshipButtons';

<FriendshipButtons
  userId="user-uuid"
  userName="João Silva"
  userPhone="11999999999"
  whatsappEnabled={true}
  size="medium"
  layout="horizontal"
/>
```

### 3. Integração WhatsApp
```tsx
import { WhatsAppButton } from '@/components/WhatsAppButton';

<WhatsAppButton
  phone="11999999999"
  name="João Silva"
  message="Olá! Vi seu perfil no Orkut"
  size="medium"
  variant="default"
/>
```

### 4. Validação de Telefone
```tsx
import { usePhoneValidation } from '@/components/WhatsAppButton';

const { validateBrazilianPhone, formatPhoneInput } = usePhoneValidation();

const validation = validateBrazilianPhone("11999999999");
const formatted = formatPhoneInput("11999999999"); // (11) 99999-9999
```

## 🔧 APIs e Hooks

### Context `useFriends()`
```tsx
const {
  friends,                    // Lista de amigos
  pendingRequests,           // Solicitações recebidas
  sentRequests,              // Solicitações enviadas
  sendFriendRequest,         // Enviar solicitação
  acceptFriendRequest,       // Aceitar solicitação
  rejectFriendRequest,       // Rejeitar solicitação
  removeFriend,              // Remover amizade
  blockUser,                 // Bloquear usuário
  getFriendshipStatus,       // Verificar status
  searchUsers,               // Buscar usuários
  refreshFriends,            // Atualizar lista
  getFriendCount             // Contar amigos
} = useFriends();
```

### Hook `useUserOnlineStatus(userId)`
```tsx
const { isOnline, status, lastSeen } = useUserOnlineStatus('user-id');
```

## 📱 Exemplos de URLs

### Perfis de Usuário
- `https://orkut-br.vercel.app/perfil/juliocamposmachado`
- `https://orkut-br.vercel.app/perfil/maria-silva`
- `https://orkut-br.vercel.app/perfil/pedro123`

### Links WhatsApp Gerados
- `https://wa.me/5511970603441?text=Olá%20João!%20Vi%20seu%20perfil%20no%20Orkut.br`
- `https://wa.me/5511999887766?text=Olá%20Maria!%20Vi%20seu%20perfil%20no%20Orkut.br`

## 🛠️ Instalação e Setup

### 1. Executar Script SQL
```bash
# Opção 1: Via script Node.js
node update-database-usernames-friends.js

# Opção 2: Manualmente no Supabase SQL Editor
# Execute o conteúdo de sql/profiles_username_friends.sql
```

### 2. Variáveis de Ambiente
```env
NEXT_PUBLIC_SUPABASE_URL=sua_url_aqui
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua_chave_anon
SUPABASE_SERVICE_ROLE_KEY=sua_chave_service_role
```

### 3. Deploy no Vercel
O sistema já está configurado para deploy automático. As funcionalidades são:
- Server-side rendering para páginas de perfil
- Rotas dinâmicas `/perfil/[username]`
- APIs do Supabase integradas
- Socket.io para status online

## 🎨 Componentes Principais

### `EditProfileForm`
Formulário completo para edição de perfil com:
- Validação de username em tempo real
- Formatação automática de telefone brasileiro
- Configurações de privacidade
- Preview da URL do perfil

### `FriendshipButtons`
Componente inteligente que mostra o botão correto baseado no status:
- "Adicionar" para não-amigos
- "Solicitação Enviada" para pendentes
- "Aceitar/Rejeitar" para solicitações recebidas
- "Amigos" + opções para amigos atuais

### `WhatsAppButton`
Botão que gera link WhatsApp automaticamente:
- Formata número brasileiro (+55)
- Mensagem personalizada
- Múltiplas variantes (default, compact, icon-only)
- Validação de número

## 🔐 Segurança e Privacidade

### Row Level Security (RLS)
- Políticas configuradas para tabela `friendships`
- Usuários só veem suas próprias solicitações
- Validação de propriedade em todas as operações

### Configurações de Privacidade
```json
{
  "profile_visibility": "public|friends|private",
  "phone_visibility": "public|friends|private", 
  "whatsapp_visible": true|false
}
```

### Validações
- Username: 3+ caracteres, apenas letras, números, _ e -
- Telefone: Formato brasileiro válido (10-11 dígitos)
- Duplicação: Username único no sistema
- Autoprevenção: Não pode adicionar a si mesmo

## 📋 Estados dos Componentes

### Status de Amizade
- `none`: Sem relação
- `pending_sent`: Solicitação enviada, aguardando
- `pending_received`: Solicitação recebida, aguardando resposta
- `friends`: Amigos confirmados
- `blocked`: Usuário bloqueado

### Status Online (integrado)
- `online`: Usuário ativo
- `away`: Inativo há 5+ minutos
- `busy`: Definido manualmente
- `offline`: Desconectado

## 🚀 Próximas Melhorias

### Funcionalidades Sugeridas
- [ ] Busca de usuários por username
- [ ] Sugestões de amizade baseadas em amigos mútuos
- [ ] Notificações push para solicitações
- [ ] Lista de usuários bloqueados
- [ ] Relatório de amizades (aceitas/rejeitadas)
- [ ] Integração com outros apps de mensagem
- [ ] Backup/exportação de dados de amizade

### Otimizações Técnicas
- [ ] Cache de consultas de amizade
- [ ] Paginação para listas grandes
- [ ] Índices otimizados no banco
- [ ] Compressão de dados JSON
- [ ] Rate limiting em solicitações

## 📞 Suporte

Para questões sobre implementação:
1. Verifique os logs do banco de dados
2. Teste as funções SQL individualmente
3. Valide as configurações de RLS
4. Confirme as variáveis de ambiente

---

**✨ Sistema completo pronto para uso em produção!**
