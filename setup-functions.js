const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function setupFunctions() {
  console.log('⚙️ Configurando funções RPC...\n')

  try {
    // 1. Função para buscar perfil por username
    console.log('1️⃣ Criando função get_profile_by_username...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE OR REPLACE FUNCTION get_profile_by_username(username_param TEXT)
        RETURNS TABLE (
          id UUID,
          name TEXT,
          username TEXT,
          email TEXT,
          avatar_url TEXT,
          phone TEXT,
          whatsapp_enabled BOOLEAN,
          privacy_settings JSONB,
          created_at TIMESTAMP WITH TIME ZONE,
          bio TEXT,
          location TEXT,
          relationship TEXT,
          website TEXT,
          fans_count INTEGER,
          views_count INTEGER
        )
        LANGUAGE plpgsql
        AS $$
        BEGIN
          RETURN QUERY
          SELECT 
            p.id,
            p.display_name as name,
            p.username,
            p.email,
            p.photo_url as avatar_url,
            p.phone,
            p.whatsapp_enabled,
            p.privacy_settings,
            p.created_at,
            p.bio,
            p.location,
            p.relationship,
            p.website,
            p.fans_count,
            p.views_count
          FROM profiles p
          WHERE p.username = username_param;
        END;
        $$;
      `
    })
    console.log('✅ Função get_profile_by_username criada')

    // 2. Função para criar perfil completo
    console.log('2️⃣ Criando função create_user_profile...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE OR REPLACE FUNCTION create_user_profile(
          user_email TEXT,
          user_password TEXT,
          user_username TEXT,
          user_display_name TEXT,
          user_phone TEXT DEFAULT NULL,
          user_bio TEXT DEFAULT NULL,
          user_location TEXT DEFAULT NULL
        )
        RETURNS TABLE (
          user_id UUID,
          success BOOLEAN,
          message TEXT
        )
        LANGUAGE plpgsql
        AS $$
        DECLARE
          new_user_id UUID;
          auth_result RECORD;
        BEGIN
          -- Verificar se username já existe
          IF EXISTS (SELECT 1 FROM profiles WHERE username = user_username) THEN
            RETURN QUERY SELECT NULL::UUID, false, 'Username já está em uso';
            RETURN;
          END IF;
          
          -- Criar usuário na auth
          SELECT INTO auth_result * FROM auth.users WHERE email = user_email;
          
          IF auth_result.id IS NOT NULL THEN
            new_user_id := auth_result.id;
          ELSE
            -- Se não existe, criar novo usuário (isso normalmente seria feito via API auth)
            new_user_id := gen_random_uuid();
          END IF;
          
          -- Criar perfil
          INSERT INTO profiles (
            id, username, display_name, email, phone, bio, location,
            whatsapp_enabled, privacy_settings, fans_count, views_count
          ) VALUES (
            new_user_id, user_username, user_display_name, user_email, user_phone, user_bio, user_location,
            COALESCE(user_phone IS NOT NULL, false),
            '{"profile": "public", "phone": "friends"}',
            0, 0
          );
          
          -- Criar presença
          INSERT INTO presence (profile_id, online, status, last_seen) 
          VALUES (new_user_id, false, 'offline', NOW());
          
          RETURN QUERY SELECT new_user_id, true, 'Perfil criado com sucesso';
        END;
        $$;
      `
    })
    console.log('✅ Função create_user_profile criada')

    // 3. Função para buscar usuários
    console.log('3️⃣ Criando função search_users...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE OR REPLACE FUNCTION search_users(search_term TEXT)
        RETURNS TABLE (
          id UUID,
          username TEXT,
          display_name TEXT,
          photo_url TEXT,
          location TEXT
        )
        LANGUAGE plpgsql
        AS $$
        BEGIN
          RETURN QUERY
          SELECT 
            p.id,
            p.username,
            p.display_name,
            p.photo_url,
            p.location
          FROM profiles p
          WHERE 
            p.username ILIKE '%' || search_term || '%' OR
            p.display_name ILIKE '%' || search_term || '%' OR
            p.email ILIKE '%' || search_term || '%'
          ORDER BY p.display_name
          LIMIT 50;
        END;
        $$;
      `
    })
    console.log('✅ Função search_users criada')

    // 4. Função para atualizar contadores
    console.log('4️⃣ Criando função update_profile_counters...')
    await supabase.rpc('exec_sql', {
      sql: `
        CREATE OR REPLACE FUNCTION update_profile_counters()
        RETURNS TRIGGER
        LANGUAGE plpgsql
        AS $$
        BEGIN
          -- Atualizar contador de fãs quando amizade é aceita
          IF TG_TABLE_NAME = 'friendships' AND NEW.status = 'accepted' AND OLD.status != 'accepted' THEN
            UPDATE profiles SET fans_count = fans_count + 1 WHERE id = NEW.friend_id;
          END IF;
          
          RETURN NEW;
        END;
        $$;
        
        -- Criar trigger para amizades
        DROP TRIGGER IF EXISTS trigger_update_fans_count ON friendships;
        CREATE TRIGGER trigger_update_fans_count
          AFTER UPDATE ON friendships
          FOR EACH ROW
          EXECUTE FUNCTION update_profile_counters();
      `
    })
    console.log('✅ Funções de contadores criadas')

    console.log('\n🎉 Funções RPC configuradas com sucesso!')

  } catch (error) {
    console.error('❌ Erro ao configurar funções:', error.message)
  }
}

setupFunctions()
