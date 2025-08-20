-- Tabela para armazenar sinais WebRTC (offers, answers, ICE candidates)
CREATE TABLE call_signals (
  id BIGSERIAL PRIMARY KEY,
  from_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  signal_type VARCHAR(50) NOT NULL, -- 'offer', 'answer', 'ice-candidate', 'call-end'
  signal_data JSONB NOT NULL, -- Dados do sinal WebRTC
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed BOOLEAN DEFAULT FALSE
);

-- Índices para otimizar consultas
CREATE INDEX idx_call_signals_to_user ON call_signals(to_user_id);
CREATE INDEX idx_call_signals_created_at ON call_signals(created_at);
CREATE INDEX idx_call_signals_processed ON call_signals(processed);

-- Tabela para status de presença/online dos usuários
CREATE TABLE user_presence (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT FALSE,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status_message VARCHAR(255),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índice para consultas de usuários online
CREATE INDEX idx_user_presence_online ON user_presence(is_online, last_seen);

-- Função para atualizar automaticamente o timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para atualizar automaticamente updated_at na tabela user_presence
CREATE TRIGGER update_user_presence_updated_at 
  BEFORE UPDATE ON user_presence 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) para call_signals
ALTER TABLE call_signals ENABLE ROW LEVEL SECURITY;

-- Política para que usuários só vejam sinais enviados para eles
CREATE POLICY "Users can view their own call signals" ON call_signals
  FOR SELECT USING (to_user_id = auth.uid());

-- Política para que usuários só possam inserir sinais
CREATE POLICY "Users can insert call signals" ON call_signals
  FOR INSERT WITH CHECK (from_user_id = auth.uid());

-- Política para marcar sinais como processados
CREATE POLICY "Users can update their call signals" ON call_signals
  FOR UPDATE USING (to_user_id = auth.uid());

-- RLS para user_presence
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- Política para que usuários vejam status de presença de todos (para saber quem está online)
CREATE POLICY "Users can view all presence status" ON user_presence
  FOR SELECT USING (true);

-- Política para que usuários só possam atualizar seu próprio status
CREATE POLICY "Users can update their own presence" ON user_presence
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own presence status" ON user_presence
  FOR UPDATE USING (user_id = auth.uid());

-- Função para limpar sinais antigos (executar periodicamente)
CREATE OR REPLACE FUNCTION cleanup_old_call_signals()
RETURNS void AS $$
BEGIN
  DELETE FROM call_signals 
  WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

-- Comentários para documentação
COMMENT ON TABLE call_signals IS 'Armazena sinais WebRTC para coordenar chamadas peer-to-peer';
COMMENT ON TABLE user_presence IS 'Rastrea o status online/offline dos usuários';
COMMENT ON FUNCTION cleanup_old_call_signals() IS 'Limpa sinais WebRTC antigos para evitar acúmulo de dados';
