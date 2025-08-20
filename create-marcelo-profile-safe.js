const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function createMarceloProfile() {
  const email = 'zarzamorera@gmail.com'
  const password = 'Mar@78451200'
  const username = 'marcelooliver'
  const displayName = 'Marcelo Oliver'
  
  console.log('👤 Criando perfil para Marcelo Oliver...')
  console.log(`📧 Email: ${email}`)
  console.log(`👤 Username: ${username}`)
  console.log(`📛 Nome: ${displayName}`)
  
  try {
    // 1. Verificar se usuário já existe por email
    console.log('\n🔍 Etapa 1: Verificando usuário existente...')
    
    const { data: existingUsers, error: listError } = await supabase.auth.admin.listUsers()
    if (listError) throw listError
    
    let userId = null
    const existingUser = existingUsers.users.find(u => u.email === email)
    
    if (existingUser) {
      console.log('👍 Usuário já existe!')
      console.log(`🆔 ID: ${existingUser.id}`)
      userId = existingUser.id
    } else {
      // Criar novo usuário
      console.log('🔐 Criando novo usuário na autenticação...')
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: email,
        password: password,
        email_confirm: true
      })
      
      if (authError) throw authError
      
      console.log('✅ Usuário criado com sucesso!')
      console.log(`🆔 ID: ${authData.user.id}`)
      userId = authData.user.id
    }
    
    // 2. Verificar se perfil já existe
    console.log('\n📋 Etapa 2: Verificando perfil existente...')
    const { data: existingProfile, error: profileCheckError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    
    if (existingProfile) {
      console.log('✅ Perfil já existe!')
      console.log('📝 Dados do perfil:')
      console.log(`   🏷️  Username: ${existingProfile.username}`)
      console.log(`   📛 Nome: ${existingProfile.display_name}`)
      console.log(`   💕 Relacionamento: ${existingProfile.relationship || 'Não informado'}`)
      console.log(`   📍 Localização: ${existingProfile.location || 'Não informado'}`)
      console.log(`   👥 Fãs: ${existingProfile.fans_count || 0}`)
      console.log(`   📅 Criado em: ${new Date(existingProfile.created_at).toLocaleString('pt-BR')}`)
      
      // Verificar se precisa atualizar dados
      if (existingProfile.username !== username || existingProfile.display_name !== displayName) {
        console.log('\n🔄 Atualizando dados do perfil...')
        
        const { error: updateError } = await supabase
          .from('profiles')
          .update({
            username: username,
            display_name: displayName,
            photo_url: '/marcelo.png',
            relationship: 'Casado(a)',
            bio: 'Gerente de Projetos especializado em desenvolvimento de software e gestão de equipes. Apaixonado por tecnologia e inovação.',
            location: 'São Paulo, SP'
          })
          .eq('id', userId)
        
        if (updateError) {
          console.log('⚠️ Erro ao atualizar perfil:', updateError.message)
        } else {
          console.log('✅ Perfil atualizado!')
        }
      }
      
      return true
    }
    
    // 3. Criar perfil se não existir
    console.log('📝 Criando novo perfil...')
    const { error: profileError } = await supabase
      .from('profiles')
      .insert({
        id: userId,
        username: username,
        display_name: displayName,
        photo_url: '/marcelo.png',
        relationship: 'Casado(a)',
        bio: 'Gerente de Projetos especializado em desenvolvimento de software e gestão de equipes. Apaixonado por tecnologia e inovação.',
        location: 'São Paulo, SP',
        fans_count: 0
      })
    
    if (profileError) {
      console.error('❌ Erro ao criar perfil:', profileError.message)
      throw profileError
    }
    
    console.log('✅ Perfil criado com sucesso!')
    
    // 4. Criar configurações padrão
    console.log('\n⚙️ Etapa 3: Criando configurações...')
    
    try {
      const { error: settingsError } = await supabase
        .from('settings')
        .upsert({
          profile_id: userId,
        })
      
      if (settingsError) {
        console.log('⚠️ Aviso nas configurações:', settingsError.message)
      } else {
        console.log('✅ Configurações criadas!')
      }
    } catch (settingsError) {
      console.log('⚠️ Configurações não criadas (possivelmente tabela não existe)')
    }
    
    // 5. Configurar presença online
    console.log('\n🟢 Etapa 4: Configurando presença...')
    
    try {
      const { error: presenceError } = await supabase
        .from('presence')
        .upsert({
          profile_id: userId,
          online: false,
          status: 'offline',
          last_seen: new Date().toISOString()
        })
      
      if (presenceError) {
        console.log('⚠️ Aviso na presença:', presenceError.message)
      } else {
        console.log('✅ Presença configurada!')
      }
    } catch (presenceError) {
      console.log('⚠️ Presença não configurada (tabela pode não existir)')
    }
    
    return true
    
  } catch (error) {
    console.error('❌ Erro geral:', error.message)
    return false
  }
}

// Executar o script
createMarceloProfile().then((success) => {
  console.log('\n🎯 RESULTADO FINAL:')
  if (success) {
    console.log('✅ Perfil do Marcelo Oliver pronto!')
    console.log('┌─────────────────────────────────────────┐')
    console.log('│           DADOS DE ACESSO               │')
    console.log('├─────────────────────────────────────────┤')
    console.log('│ 📧 Email: zarzamorera@gmail.com         │')
    console.log('│ 🔑 Senha: Mar@78451200                  │')
    console.log('│ 👤 Username: marcelooliver              │')
    console.log('│ 📛 Nome: Marcelo Oliver                 │')
    console.log('│ 💼 Cargo: Gerente de Projetos           │')
    console.log('├─────────────────────────────────────────┤')
    console.log('│ 🔗 URL do perfil:                       │')
    console.log('│ https://orkut-br.vercel.app/perfil/     │')
    console.log('│ marcelooliver                           │')
    console.log('└─────────────────────────────────────────┘')
    console.log('\n🚀 PRONTO PARA FAZER LOGIN!')
  } else {
    console.log('❌ Falha ao criar perfil')
  }
})
