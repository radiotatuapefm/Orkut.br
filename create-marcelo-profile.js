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
    // 1. Criar usuário na autenticação
    console.log('\n🔐 Etapa 1: Criando usuário na autenticação...')
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true // Confirma o email automaticamente
    })
    
    if (authError) {
      console.log('❌ Erro na autenticação:', authError.message)
      
      // Se o usuário já existe, tenta fazer login para pegar o ID
      if (authError.message.includes('already registered')) {
        console.log('👍 Usuário já existe, obtendo dados...')
        
        const { data: existingUsers, error: listError } = await supabase.auth.admin.listUsers()
        if (listError) throw listError
        
        const existingUser = existingUsers.users.find(u => u.email === email)
        if (!existingUser) throw new Error('Usuário não encontrado após criação')
        
        console.log('✅ Usuário encontrado:', existingUser.id)
        
        // 2. Verificar se perfil já existe
        console.log('\n📋 Etapa 2: Verificando perfil existente...')
        const { data: existingProfile, error: profileCheckError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', existingUser.id)
          .single()
        
        if (existingProfile) {
          console.log('✅ Perfil já existe!')
          console.log('📝 Dados do perfil:')
          console.log(`   🏷️  Username: ${existingProfile.username}`)
          console.log(`   📛 Nome: ${existingProfile.display_name}`)
          console.log(`   💕 Relacionamento: ${existingProfile.relationship}`)
          console.log(`   👥 Fãs: ${existingProfile.fans_count}`)
          return true
        }
        
        // Se perfil não existe, criar com o ID do usuário existente
        await createProfile(existingUser.id)
        return true
      }
      
      throw authError
    }
    
    console.log('✅ Usuário criado com sucesso!')
    console.log(`🆔 ID: ${authData.user.id}`)
    
    // 2. Criar perfil
    await createProfile(authData.user.id)
    
    return true
    
  } catch (error) {
    console.error('❌ Erro geral:', error.message)
    return false
  }
}

async function createProfile(userId) {
  console.log('\n📋 Etapa 2: Criando perfil...')
  
  const { error: profileError } = await supabase
    .from('profiles')
    .insert({
      id: userId,
      username: 'marcelooliver',
      display_name: 'Marcelo Oliver',
      photo_url: '/marcelo.png', // Usando a imagem local
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
  
  // 3. Criar configurações padrão
  console.log('\n⚙️ Etapa 3: Criando configurações...')
  
  try {
    const { error: settingsError } = await supabase
      .from('settings')
      .insert({
        profile_id: userId,
        // Configurações padrão serão aplicadas pelo banco
      })
    
    if (settingsError && !settingsError.message.includes('already exists')) {
      console.log('⚠️ Aviso nas configurações:', settingsError.message)
    } else {
      console.log('✅ Configurações criadas!')
    }
  } catch (settingsError) {
    console.log('⚠️ Configurações não criadas (possivelmente já existem)')
  }
  
  // 4. Configurar presença online
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
}

// Executar o script
createMarceloProfile().then((success) => {
  console.log('\n🎯 RESULTADO:')
  if (success) {
    console.log('✅ Perfil do Marcelo Oliver criado com sucesso!')
    console.log('📧 Email: zarzamorera@gmail.com')
    console.log('🔑 Senha: Mar@78451200')
    console.log('👤 Username: marcelooliver')
    console.log('🔗 URL do perfil: https://orkut-br.vercel.app/perfil/marcelooliver')
    console.log('\n🚀 PRONTO PARA FAZER LOGIN!')
  } else {
    console.log('❌ Falha ao criar perfil')
  }
})
