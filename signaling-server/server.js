const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
const httpServer = createServer(app);

// Configurar CORS
app.use(cors({
  origin: process.env.CLIENT_URL || "http://localhost:3000",
  credentials: true
}));

// Socket.io com CORS
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_URL || "http://localhost:3000",
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Armazenar usuários conectados
const connectedUsers = new Map();
const userSockets = new Map();

io.on('connection', (socket) => {
  console.log('Usuário conectado:', socket.id);

  // Autenticação do usuário
  socket.on('join', (userData) => {
    const { userId, userName } = userData;
    
    // Armazenar informações do usuário
    connectedUsers.set(userId, {
      socketId: socket.id,
      userName,
      isOnline: true,
      lastSeen: new Date()
    });
    
    userSockets.set(socket.id, userId);
    
    console.log(`Usuário ${userName} (${userId}) entrou na sala`);
    
    // Notificar outros usuários que este usuário está online
    socket.broadcast.emit('user-online', {
      userId,
      userName,
      isOnline: true
    });
    
    // Enviar lista de usuários online para o usuário que acabou de conectar
    const onlineUsers = Array.from(connectedUsers.entries())
      .filter(([id]) => id !== userId)
      .map(([id, data]) => ({
        userId: id,
        userName: data.userName,
        isOnline: data.isOnline
      }));
    
    socket.emit('online-users', onlineUsers);
  });

  // Iniciar uma chamada
  socket.on('call-user', (data) => {
    const { to, type, offer } = data;
    const fromUserId = userSockets.get(socket.id);
    const fromUser = connectedUsers.get(fromUserId);
    const toUser = connectedUsers.get(to);
    
    if (toUser && toUser.isOnline) {
      const toSocket = io.sockets.sockets.get(toUser.socketId);
      
      if (toSocket) {
        toSocket.emit('incoming-call', {
          from: fromUserId,
          fromName: fromUser.userName,
          type,
          offer
        });
        
        console.log(`Chamada de ${fromUser.userName} para ${toUser.userName} (${type})`);
      }
    } else {
      socket.emit('call-failed', {
        reason: 'Usuário não está online'
      });
    }
  });

  // Responder a uma chamada (aceitar/rejeitar)
  socket.on('answer-call', (data) => {
    const { to, accepted, answer } = data;
    const fromUserId = userSockets.get(socket.id);
    const fromUser = connectedUsers.get(fromUserId);
    const toUser = connectedUsers.get(to);
    
    if (toUser && toUser.isOnline) {
      const toSocket = io.sockets.sockets.get(toUser.socketId);
      
      if (toSocket) {
        if (accepted) {
          toSocket.emit('call-answered', {
            accepted: true,
            answer,
            from: fromUserId
          });
          
          console.log(`${fromUser.userName} aceitou a chamada de ${toUser.userName}`);
        } else {
          toSocket.emit('call-rejected', {
            from: fromUserId
          });
          
          console.log(`${fromUser.userName} rejeitou a chamada de ${toUser.userName}`);
        }
      }
    }
  });

  // Trocar ofertas WebRTC
  socket.on('offer', (data) => {
    const { to, offer } = data;
    const fromUserId = userSockets.get(socket.id);
    const toUser = connectedUsers.get(to);
    
    if (toUser && toUser.isOnline) {
      const toSocket = io.sockets.sockets.get(toUser.socketId);
      
      if (toSocket) {
        toSocket.emit('offer', {
          offer,
          from: fromUserId
        });
      }
    }
  });

  // Trocar respostas WebRTC
  socket.on('answer', (data) => {
    const { to, answer } = data;
    const fromUserId = userSockets.get(socket.id);
    const toUser = connectedUsers.get(to);
    
    if (toUser && toUser.isOnline) {
      const toSocket = io.sockets.sockets.get(toUser.socketId);
      
      if (toSocket) {
        toSocket.emit('answer', {
          answer,
          from: fromUserId
        });
      }
    }
  });

  // Trocar ICE candidates
  socket.on('ice-candidate', (data) => {
    const { to, candidate } = data;
    const fromUserId = userSockets.get(socket.id);
    const toUser = connectedUsers.get(to);
    
    if (toUser && toUser.isOnline) {
      const toSocket = io.sockets.sockets.get(toUser.socketId);
      
      if (toSocket) {
        toSocket.emit('ice-candidate', {
          candidate,
          from: fromUserId
        });
      }
    }
  });

  // Encerrar chamada
  socket.on('end-call', (data) => {
    const { to } = data || {};
    const fromUserId = userSockets.get(socket.id);
    
    if (to) {
      const toUser = connectedUsers.get(to);
      
      if (toUser && toUser.isOnline) {
        const toSocket = io.sockets.sockets.get(toUser.socketId);
        
        if (toSocket) {
          toSocket.emit('call-ended', {
            from: fromUserId
          });
        }
      }
    } else {
      // Broadcast para todos os usuários conectados (fallback)
      socket.broadcast.emit('call-ended', {
        from: fromUserId
      });
    }
  });

  // Atualizar status de presença
  socket.on('update-presence', (data) => {
    const { status } = data; // 'online', 'away', 'busy', 'offline'
    const userId = userSockets.get(socket.id);
    const user = connectedUsers.get(userId);
    
    if (user) {
      user.status = status;
      user.lastSeen = new Date();
      
      // Notificar outros usuários sobre a mudança de status
      socket.broadcast.emit('user-status-changed', {
        userId,
        status,
        lastSeen: user.lastSeen
      });
    }
  });

  // Desconexão
  socket.on('disconnect', () => {
    const userId = userSockets.get(socket.id);
    
    if (userId) {
      const user = connectedUsers.get(userId);
      
      if (user) {
        user.isOnline = false;
        user.lastSeen = new Date();
        
        console.log(`Usuário ${user.userName} (${userId}) desconectado`);
        
        // Notificar outros usuários que este usuário saiu
        socket.broadcast.emit('user-offline', {
          userId,
          userName: user.userName,
          isOnline: false,
          lastSeen: user.lastSeen
        });
        
        // Notificar sobre chamada encerrada se houver alguma ativa
        socket.broadcast.emit('call-ended', {
          from: userId
        });
      }
      
      // Limpar referências após um tempo (para permitir reconexão rápida)
      setTimeout(() => {
        connectedUsers.delete(userId);
        userSockets.delete(socket.id);
      }, 30000); // 30 segundos
    }
    
    console.log('Socket desconectado:', socket.id);
  });

  // Heartbeat para manter conexão ativa
  socket.on('ping', () => {
    socket.emit('pong');
  });
});

// Middleware para logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Rota de health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    connectedUsers: connectedUsers.size
  });
});

// Rota para listar usuários online (para debug)
app.get('/users', (req, res) => {
  const users = Array.from(connectedUsers.entries()).map(([id, data]) => ({
    userId: id,
    userName: data.userName,
    isOnline: data.isOnline,
    lastSeen: data.lastSeen
  }));
  
  res.json(users);
});

const PORT = process.env.PORT || 5001;

httpServer.listen(PORT, () => {
  console.log(`🚀 Servidor de signaling rodando na porta ${PORT}`);
  console.log(`📡 Endpoint: http://localhost:${PORT}`);
  console.log(`🔗 Cliente esperado em: ${process.env.CLIENT_URL || "http://localhost:3000"}`);
});
