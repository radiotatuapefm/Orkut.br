-- =====================================================
-- ORKUT.BR - Database Setup Script
-- Execute this script in your Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. PROFILES AND FRIENDSHIPS
-- =====================================================

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  username text UNIQUE NOT NULL,
  display_name text NOT NULL,
  photo_url text DEFAULT 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
  relationship text DEFAULT 'Solteiro(a)',
  location text DEFAULT '',
  birthday date,
  bio text DEFAULT '',
  fans_count int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS friendships (
  id bigserial PRIMARY KEY,
  requester uuid REFERENCES profiles(id) ON DELETE CASCADE,
  addressee uuid REFERENCES profiles(id) ON DELETE CASCADE,
  status text CHECK (status IN ('pending','accepted','blocked')) DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  UNIQUE(requester, addressee)
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Profiles are viewable by everyone" 
  ON profiles FOR SELECT 
  USING (true);

CREATE POLICY "Users can update own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- RLS Policies for friendships
CREATE POLICY "Friendships viewable by involved users" 
  ON friendships FOR SELECT 
  USING (auth.uid() = requester OR auth.uid() = addressee);

CREATE POLICY "Users can create friendship requests" 
  ON friendships FOR INSERT 
  WITH CHECK (auth.uid() = requester);

CREATE POLICY "Users can update friendship status" 
  ON friendships FOR UPDATE 
  USING (auth.uid() = addressee);

-- =====================================================
-- 2. COMMUNITIES SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS communities (
  id bigserial PRIMARY KEY,
  name text UNIQUE NOT NULL,
  description text DEFAULT '',
  category text DEFAULT 'Geral',
  owner uuid REFERENCES profiles(id) ON DELETE CASCADE,
  members_count int DEFAULT 0,
  photo_url text DEFAULT 'https://images.pexels.com/photos/1595391/pexels-photo-1595391.jpeg?auto=compress&cs=tinysrgb&w=200',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_members (
  community_id bigint REFERENCES communities(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  role text CHECK (role IN ('member','mod','owner')) DEFAULT 'member',
  joined_at timestamptz DEFAULT now(),
  PRIMARY KEY (community_id, profile_id)
);

-- Enable RLS
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Communities are viewable by everyone"
  ON communities FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create communities"
  ON communities FOR INSERT
  WITH CHECK (auth.uid() = owner);

CREATE POLICY "Community owners can update their communities"
  ON communities FOR UPDATE
  USING (auth.uid() = owner);

CREATE POLICY "Community memberships viewable by members"
  ON community_members FOR SELECT
  USING (true);

CREATE POLICY "Users can join communities"
  ON community_members FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can leave communities"
  ON community_members FOR DELETE
  USING (auth.uid() = profile_id);

-- =====================================================
-- 3. POSTS, COMMENTS AND LIKES SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS posts (
  id bigserial PRIMARY KEY,
  author uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  visibility text CHECK (visibility IN ('public','friends')) DEFAULT 'public',
  likes_count int DEFAULT 0,
  comments_count int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS comments (
  id bigserial PRIMARY KEY,
  post_id bigint REFERENCES posts(id) ON DELETE CASCADE,
  author uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS likes (
  post_id bigint REFERENCES posts(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (post_id, profile_id)
);

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public posts viewable by everyone"
  ON posts FOR SELECT
  USING (visibility = 'public' OR auth.uid() = author);

CREATE POLICY "Users can create posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = author);

CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING (auth.uid() = author);

CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  USING (auth.uid() = author);

CREATE POLICY "Comments viewable with their posts"
  ON comments FOR SELECT
  USING (true);

CREATE POLICY "Users can create comments"
  ON comments FOR INSERT
  WITH CHECK (auth.uid() = author);

CREATE POLICY "Users can update own comments"
  ON comments FOR UPDATE
  USING (auth.uid() = author);

CREATE POLICY "Users can delete own comments"
  ON comments FOR DELETE
  USING (auth.uid() = author);

CREATE POLICY "Likes viewable by everyone"
  ON likes FOR SELECT
  USING (true);

CREATE POLICY "Users can manage own likes"
  ON likes FOR ALL
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- =====================================================
-- 4. SCRAPS AND TESTIMONIALS
-- =====================================================

CREATE TABLE IF NOT EXISTS scraps (
  id bigserial PRIMARY KEY,
  to_profile uuid REFERENCES profiles(id) ON DELETE CASCADE,
  from_profile uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS testimonials (
  id bigserial PRIMARY KEY,
  to_profile uuid REFERENCES profiles(id) ON DELETE CASCADE,
  from_profile uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  approved boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE scraps ENABLE ROW LEVEL SECURITY;
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for scraps
CREATE POLICY "Users can view scraps sent to them or by them"
  ON scraps FOR SELECT
  USING (auth.uid() = to_profile OR auth.uid() = from_profile);

CREATE POLICY "Users can create scraps"
  ON scraps FOR INSERT
  WITH CHECK (auth.uid() = from_profile);

CREATE POLICY "Users can delete scraps sent to them"
  ON scraps FOR DELETE
  USING (auth.uid() = to_profile);

-- RLS Policies for testimonials
CREATE POLICY "Approved testimonials viewable by everyone"
  ON testimonials FOR SELECT
  USING (approved = true OR auth.uid() = to_profile OR auth.uid() = from_profile);

CREATE POLICY "Users can create testimonials"
  ON testimonials FOR INSERT
  WITH CHECK (auth.uid() = from_profile);

CREATE POLICY "Users can approve testimonials sent to them"
  ON testimonials FOR UPDATE
  USING (auth.uid() = to_profile);

CREATE POLICY "Users can delete testimonials sent to them"
  ON testimonials FOR DELETE
  USING (auth.uid() = to_profile);

-- =====================================================
-- 5. MESSAGES AND NOTIFICATIONS SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS messages (
  id bigserial PRIMARY KEY,
  thread_id uuid DEFAULT gen_random_uuid(),
  sender uuid REFERENCES profiles(id) ON DELETE CASCADE,
  recipient uuid REFERENCES profiles(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  read boolean DEFAULT false,
  archived_by_sender boolean DEFAULT false,
  archived_by_recipient boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS notifications (
  id bigserial PRIMARY KEY,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL,
  payload jsonb DEFAULT '{}',
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for messages
CREATE POLICY "Users can view their messages"
  ON messages FOR SELECT
  USING (auth.uid() = sender OR auth.uid() = recipient);

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender);

CREATE POLICY "Users can update their messages"
  ON messages FOR UPDATE
  USING (auth.uid() = sender OR auth.uid() = recipient);

-- RLS Policies for notifications
CREATE POLICY "Users can view their notifications"
  ON notifications FOR ALL
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- =====================================================
-- 6. CALLS AND PRESENCE SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS calls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  caller uuid REFERENCES profiles(id) ON DELETE CASCADE,
  callee uuid REFERENCES profiles(id) ON DELETE CASCADE,
  type text CHECK (type IN ('audio','video')) NOT NULL,
  status text CHECK (status IN ('ringing','accepted','ended','missed')) DEFAULT 'ringing',
  sdp_offer text,
  sdp_answer text,
  ice_candidates jsonb DEFAULT '[]',
  created_at timestamptz DEFAULT now(),
  ended_at timestamptz
);

CREATE TABLE IF NOT EXISTS presence (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  last_seen timestamptz DEFAULT now(),
  online boolean DEFAULT false,
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE presence ENABLE ROW LEVEL SECURITY;

-- RLS Policies for calls
CREATE POLICY "Users can view calls involving them"
  ON calls FOR SELECT
  USING (auth.uid() = caller OR auth.uid() = callee);

CREATE POLICY "Users can create calls"
  ON calls FOR INSERT
  WITH CHECK (auth.uid() = caller);

CREATE POLICY "Users can update calls involving them"
  ON calls FOR UPDATE
  USING (auth.uid() = caller OR auth.uid() = callee);

-- RLS Policies for presence
CREATE POLICY "Presence is viewable by everyone"
  ON presence FOR SELECT
  USING (true);

CREATE POLICY "Users can update their own presence"
  ON presence FOR ALL
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- =====================================================
-- 7. SETTINGS AND AUDIT SYSTEM
-- =====================================================

CREATE TABLE IF NOT EXISTS settings (
  profile_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  voice_enabled boolean DEFAULT false,
  locale text DEFAULT 'pt-BR',
  notifications_enabled boolean DEFAULT true,
  tts_speed real DEFAULT 1.0,
  tts_volume real DEFAULT 0.8,
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_log (
  id bigserial PRIMARY KEY,
  actor uuid REFERENCES profiles(id) ON DELETE CASCADE,
  action text NOT NULL,
  target text,
  details jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for settings
CREATE POLICY "Users can manage their own settings"
  ON settings FOR ALL
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

-- RLS Policies for audit_log
CREATE POLICY "Users can view their own audit log"
  ON audit_log FOR SELECT
  USING (auth.uid() = actor);

CREATE POLICY "System can insert audit log"
  ON audit_log FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 8. INSERT DEMO DATA
-- =====================================================

-- Insert demo communities
INSERT INTO communities (name, description, category, photo_url) VALUES
('Nostalgia dos Anos 2000', 'Relembre os bons tempos dos anos 2000! Músicas, filmes, jogos e muito mais.', 'Nostalgia', 'https://images.pexels.com/photos/1319236/pexels-photo-1319236.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Música', 'Comunidade para compartilhar e descobrir novas músicas de todos os gêneros.', 'Música', 'https://images.pexels.com/photos/167636/pexels-photo-167636.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Tecnologia', 'Discussões sobre as últimas novidades em tecnologia, programação e inovação.', 'Tecnologia', 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Jogos Retrô', 'Para os amantes dos jogos clássicos! Arcade, Atari, Nintendo e muito mais.', 'Jogos', 'https://images.pexels.com/photos/1298601/pexels-photo-1298601.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Humor', 'O melhor do humor brasileiro! Piadas, memes e muita diversão.', 'Entretenimento', 'https://images.pexels.com/photos/1477166/pexels-photo-1477166.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Receitas da Vovó', 'Compartilhe e descubra receitas tradicionais e caseiras.', 'Culinária', 'https://images.pexels.com/photos/1556698/pexels-photo-1556698.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Filmes Cult', 'Para cinéfilos e amantes de filmes alternativos e cult.', 'Cinema', 'https://images.pexels.com/photos/918281/pexels-photo-918281.jpeg?auto=compress&cs=tinysrgb&w=200'),
('Viagens pelo Brasil', 'Descubra os destinos mais incríveis do nosso país!', 'Turismo', 'https://images.pexels.com/photos/1804177/pexels-photo-1804177.jpeg?auto=compress&cs=tinysrgb&w=200')
ON CONFLICT (name) DO NOTHING;

-- Update members count
UPDATE communities SET members_count = FLOOR(RANDOM() * 5000) + 100 WHERE members_count = 0;
