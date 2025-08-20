import React from 'react';
import { WebRTCProvider } from '../contexts/WebRTCContext';
import { OnlineStatusProvider } from '../contexts/OnlineStatusContext';
import { CallManager } from './CallManager';
import { CallButtons } from './CallButtons';
import { useUserOnlineStatus } from '../contexts/OnlineStatusContext';

// Exemplo de componente de chat onde os botões de chamada seriam integrados
const ChatExample: React.FC = () => {
  const users = [
    { id: '1', name: 'João Silva' },
    { id: '2', name: 'Maria Santos' },
    { id: '3', name: 'Pedro Costa' }
  ];

  return (
    <div style={{ padding: '2rem' }}>
      <h2>Chat do Orkut - Com Chamadas</h2>
      
      <div style={{ marginBottom: '2rem' }}>
        <h3>Usuários Online</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {users.map(user => (
            <UserItem key={user.id} userId={user.id} userName={user.name} />
          ))}
        </div>
      </div>
    </div>
  );
};

// Componente individual do usuário com status online e botões de chamada
const UserItem: React.FC<{ userId: string; userName: string }> = ({ userId, userName }) => {
  const { isOnline, status, lastSeen } = useUserOnlineStatus(userId);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online': return '#4caf50';
      case 'away': return '#ff9800';
      case 'busy': return '#f44336';
      default: return '#9e9e9e';
    }
  };

  const formatLastSeen = (date: Date | null) => {
    if (!date) return '';
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'agora mesmo';
    if (minutes < 60) return `${minutes}min atrás`;
    
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h atrás`;
    
    const days = Math.floor(hours / 24);
    return `${days}d atrás`;
  };

  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      gap: '1rem',
      padding: '1rem',
      border: '1px solid #e0e0e0',
      borderRadius: '8px',
      backgroundColor: '#f9f9f9'
    }}>
      {/* Avatar e status */}
      <div style={{ position: 'relative' }}>
        <div style={{
          width: '50px',
          height: '50px',
          borderRadius: '50%',
          backgroundColor: '#ddd',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '1.5rem',
          fontWeight: 'bold',
          color: '#666'
        }}>
          {userName.charAt(0).toUpperCase()}
        </div>
        
        {/* Indicador de status */}
        <div style={{
          position: 'absolute',
          bottom: '2px',
          right: '2px',
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          backgroundColor: getStatusColor(status),
          border: '2px solid white'
        }} />
      </div>

      {/* Informações do usuário */}
      <div style={{ flex: 1 }}>
        <h4 style={{ margin: '0 0 0.25rem 0' }}>{userName}</h4>
        <p style={{ 
          margin: 0, 
          fontSize: '0.875rem', 
          color: '#666',
          textTransform: 'capitalize'
        }}>
          {isOnline ? status : `Offline • ${formatLastSeen(lastSeen)}`}
        </p>
      </div>

      {/* Botões de chamada */}
      <CallButtons
        userId={userId}
        userName={userName}
        isOnline={isOnline}
        size="medium"
        layout="horizontal"
      />
    </div>
  );
};

// Componente principal da aplicação com todos os providers
const AppWithCalls: React.FC = () => {
  return (
    <OnlineStatusProvider>
      <WebRTCProvider>
        <CallManager>
          <div style={{ 
            fontFamily: 'Arial, sans-serif',
            backgroundColor: '#f5f5f5',
            minHeight: '100vh'
          }}>
            <header style={{
              backgroundColor: '#E91E63',
              color: 'white',
              padding: '1rem',
              textAlign: 'center',
              marginBottom: '2rem'
            }}>
              <h1>Orkut Clone - Sistema de Chamadas</h1>
              <p>Funcionalidades de áudio e vídeo integradas</p>
            </header>
            
            <main>
              <ChatExample />
            </main>
          </div>
        </CallManager>
      </WebRTCProvider>
    </OnlineStatusProvider>
  );
};

export default AppWithCalls;
