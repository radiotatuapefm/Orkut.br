# Sistema de Chamadas WebRTC - Orkut Clone

Este sistema implementa funcionalidades completas de chamadas de áudio e vídeo usando WebRTC para o clone do Orkut.

## 🚀 Funcionalidades

- **Chamadas de áudio** com controles de mute/unmute
- **Chamadas de vídeo** com controles de câmera on/off  
- **Compartilhamento de tela** durante videochamadas
- **Notificações de chamadas** com som e vibração
- **Status online** em tempo real dos usuários
- **Interface responsiva** para desktop e mobile
- **Auto-away** após inatividade
- **Reconexão automática** em caso de desconexão

## 📁 Estrutura de Arquivos

```
src/
├── contexts/
│   ├── WebRTCContext.tsx          # Gerenciamento de conexões WebRTC
│   └── OnlineStatusContext.tsx    # Gerenciamento de status online
├── components/
│   ├── AudioCall.tsx              # Interface de chamada de áudio
│   ├── VideoCall.tsx              # Interface de chamada de vídeo
│   ├── CallNotification.tsx       # Notificação de chamadas recebidas
│   ├── CallButtons.tsx            # Botões para iniciar chamadas
│   ├── CallManager.tsx            # Gerenciador principal de chamadas
│   └── AppWithCalls.tsx           # Exemplo de integração
└── signaling-server/
    ├── server.js                  # Servidor de signaling Socket.io
    └── package.json               # Dependências do servidor
```

## 🛠️ Instalação e Configuração

### 1. Instalar Dependências do Cliente

```bash
npm install socket.io-client
```

### 2. Instalar Dependências do Servidor

```bash
cd signaling-server
npm install
```

### 3. Configurar o Servidor de Signaling

O servidor roda na porta 5001 por padrão. Para iniciar:

```bash
cd signaling-server
npm start
```

Para desenvolvimento com auto-reload:

```bash
npm run dev
```

### 4. Integrar na Aplicação

```tsx
import React from 'react';
import { WebRTCProvider } from './contexts/WebRTCContext';
import { OnlineStatusProvider } from './contexts/OnlineStatusContext';
import { CallManager } from './components/CallManager';

function App() {
  return (
    <OnlineStatusProvider>
      <WebRTCProvider>
        <CallManager>
          {/* Sua aplicação aqui */}
        </CallManager>
      </WebRTCProvider>
    </OnlineStatusProvider>
  );
}
```

## 🎯 Como Usar

### Botões de Chamada

```tsx
import { CallButtons } from './components/CallButtons';
import { useUserOnlineStatus } from './contexts/OnlineStatusContext';

function UserProfile({ userId, userName }) {
  const { isOnline } = useUserOnlineStatus(userId);
  
  return (
    <div>
      <h3>{userName}</h3>
      <CallButtons
        userId={userId}
        userName={userName}
        isOnline={isOnline}
        size="medium"           // 'small' | 'medium' | 'large'
        layout="horizontal"     // 'horizontal' | 'vertical'
        showLabels={false}      // mostrar texto nos botões
      />
    </div>
  );
}
```

### Verificar Status Online

```tsx
import { useUserOnlineStatus, useOnlineStatus } from './contexts/OnlineStatusContext';

function UserList() {
  const { onlineUsers } = useOnlineStatus();
  
  return (
    <div>
      {onlineUsers.map(user => (
        <UserItem key={user.userId} user={user} />
      ))}
    </div>
  );
}

function UserItem({ user }) {
  const { isOnline, status, lastSeen } = useUserOnlineStatus(user.userId);
  
  return (
    <div>
      <span>{user.userName}</span>
      <span className={`status-${status}`}>
        {isOnline ? status : 'offline'}
      </span>
    </div>
  );
}
```

### Hooks Disponíveis

#### useWebRTC()
```tsx
const {
  localStream,          // Stream local do usuário
  remoteStream,         // Stream remoto do outro usuário
  isCallActive,         // Chamada está ativa
  isAudioEnabled,       // Áudio está habilitado
  isVideoEnabled,       // Vídeo está habilitado
  isScreenSharing,      // Compartilhamento de tela ativo
  callType,            // 'audio' | 'video' | null
  incomingCall,        // Dados da chamada recebida
  startAudioCall,      // Iniciar chamada de áudio
  startVideoCall,      // Iniciar chamada de vídeo
  answerCall,          // Atender chamada
  rejectCall,          // Rejeitar chamada
  endCall,             // Encerrar chamada
  toggleAudio,         // Ligar/desligar áudio
  toggleVideo,         // Ligar/desligar vídeo
  toggleScreenShare    // Ligar/desligar compartilhamento
} = useWebRTC();
```

#### useOnlineStatus()
```tsx
const {
  onlineUsers,          // Lista de usuários online
  isUserOnline,         // Verificar se usuário está online
  getUserStatus,        // Obter status do usuário
  updateStatus,         // Atualizar próprio status
  getLastSeen,          // Última vez visto
  isConnected          // Conectado ao servidor
} = useOnlineStatus();
```

#### useUserOnlineStatus(userId)
```tsx
const {
  isOnline,            // Usuário está online
  status,              // Status atual ('online' | 'away' | 'busy' | 'offline')
  lastSeen            // Data da última atividade
} = useUserOnlineStatus(userId);
```

## 🎨 Personalização de Estilos

Todos os componentes incluem classes CSS que podem ser personalizadas:

### CallButtons
```css
.call-buttons { /* Container dos botões */ }
.call-button { /* Estilo base dos botões */ }
.call-button.audio-call { /* Botão de áudio */ }
.call-button.video-call { /* Botão de vídeo */ }
.call-button:disabled { /* Estado desabilitado */ }
.offline-indicator { /* Indicador offline */ }
```

### AudioCall
```css
.audio-call-overlay { /* Overlay da chamada */ }
.audio-call-container { /* Container principal */ }
.audio-wave { /* Visualizador de áudio */ }
.control-button { /* Botões de controle */ }
```

### VideoCall
```css
.video-call-overlay { /* Overlay da chamada */ }
.video-call-container { /* Container principal */ }
.remote-video { /* Vídeo remoto */ }
.local-video { /* Vídeo local */ }
.video-call-controls { /* Controles da chamada */ }
```

### CallNotification
```css
.call-notification-overlay { /* Overlay da notificação */ }
.call-notification-container { /* Container principal */ }
.caller-info { /* Informações do contato */ }
.call-actions { /* Botões de aceitar/rejeitar */ }
```

## 🔧 Configurações do Servidor

### Variáveis de Ambiente

```env
PORT=5001                           # Porta do servidor
CLIENT_URL=http://localhost:3000    # URL do cliente
```

### Eventos do Socket.io

#### Eventos do Cliente para o Servidor:
- `join` - Entrar na sala com ID do usuário
- `call-user` - Iniciar chamada para outro usuário
- `answer-call` - Responder a uma chamada
- `offer` - Enviar oferta WebRTC
- `answer` - Enviar resposta WebRTC
- `ice-candidate` - Enviar ICE candidate
- `end-call` - Encerrar chamada
- `update-presence` - Atualizar status de presença
- `ping` - Heartbeat

#### Eventos do Servidor para o Cliente:
- `online-users` - Lista de usuários online
- `user-online` - Usuário ficou online
- `user-offline` - Usuário ficou offline
- `user-status-changed` - Status do usuário mudou
- `incoming-call` - Chamada recebida
- `call-answered` - Chamada foi atendida
- `call-rejected` - Chamada foi rejeitada
- `call-ended` - Chamada foi encerrada
- `offer` - Oferta WebRTC recebida
- `answer` - Resposta WebRTC recebida
- `ice-candidate` - ICE candidate recebido
- `pong` - Resposta ao heartbeat

## 🚨 Considerações de Segurança

1. **HTTPS Obrigatório**: WebRTC requer HTTPS em produção
2. **STUN/TURN Servers**: Configure servidores próprios para produção
3. **Autenticação**: Implemente verificação de usuários no servidor
4. **Rate Limiting**: Limite tentativas de conexão por IP
5. **Validação**: Valide todos os dados recebidos pelo WebSocket

## 📱 Suporte a Dispositivos

### Desktop
- ✅ Chrome 60+
- ✅ Firefox 55+
- ✅ Safari 11+
- ✅ Edge 79+

### Mobile
- ✅ Chrome Mobile 60+
- ✅ Safari iOS 11+
- ✅ Firefox Mobile 55+
- ✅ Samsung Internet 8+

## 🐛 Solução de Problemas

### Erro: "getUserMedia não está disponível"
- Verifique se está usando HTTPS
- Confirme se o navegador suporta WebRTC
- Verifique permissões de câmera/microfone

### Erro: "Não foi possível conectar ao servidor"
- Confirme se o servidor de signaling está rodando
- Verifique a URL de conexão
- Confirme se não há firewall bloqueando a porta

### Erro: "ICE connection failed"
- Configure servidores STUN/TURN adequados
- Verifique conectividade de rede
- Teste em redes diferentes

### Chamadas não conectam
- Verifique se ambos os usuários estão online
- Confirme se o signaling está funcionando
- Teste a permissão de mídia nos dois lados

## 📋 TODO / Melhorias Futuras

- [ ] Gravação de chamadas
- [ ] Suporte a chamadas em grupo
- [ ] Filtros de vídeo e efeitos
- [ ] Qualidade adaptativa baseada na conexão
- [ ] Histórico de chamadas
- [ ] Integração com notificações push
- [ ] Suporte a múltiplas abas/dispositivos
- [ ] Análise de qualidade da chamada

## 📄 Licença

Este código é fornecido como exemplo educacional para o projeto Orkut Clone.
