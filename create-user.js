const { createClient } = require('@supabase/supabase-js')

// Configuração do Supabase com Service Role Key (para operações administrativas)
const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

async function createUser() {
  console.log('👤 Criando usuário Julio Campos Machado...')
  
  try {
    // Dados do usuário
    const userData = {
      email: 'juliocamposmachado@gmail.com',
      password: 'Julio@78451200',
      email_confirm: true,
      user_metadata: {
        username: 'juliocamposmachado',
        display_name: 'Julio Campos Machado'
      }
    }

    // Criar usuário usando Admin API
    const { data: user, error: authError } = await supabase.auth.admin.createUser(userData)

    if (authError) {
      console.error('❌ Erro ao criar usuário:', authError.message)
      return false
    }

    console.log('✅ Usuário criado com sucesso!')
    console.log(`📧 Email: ${user.user.email}`)
    console.log(`🆔 ID: ${user.user.id}`)

    // Criar perfil manualmente
    const { error: profileError } = await supabase
      .from('profiles')
      .insert({
        id: user.user.id,
        username: 'juliocamposmachado',
        display_name: 'Julio Campos Machado',
        photo_url: 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
        relationship: 'Solteiro(a)',
        fans_count: 0
      })

    if (profileError) {
      console.error('❌ Erro ao criar perfil:', profileError.message)
      console.log('ℹ️ Usuário foi criado, mas perfil falhou')
    } else {
      console.log('✅ Perfil criado com sucesso!')
    }

    return true

  } catch (error) {
    console.error('❌ Erro geral:', error.message)
    return false
  }
}

async function checkUserExists() {
  console.log('🔍 Verificando se usuário já existe...')
  
  try {
    // Verificar se o email já existe
    const { data: users, error } = await supabase.auth.admin.listUsers()
    
    if (error) {
      console.error('❌ Erro ao verificar usuários:', error.message)
      return false
    }

    const existingUser = users.users.find(user => user.email === 'juliocamposmachado@gmail.com')
    
    if (existingUser) {
      console.log('ℹ️ Usuário já existe!')
      console.log(`📧 Email: ${existingUser.email}`)
      console.log(`🆔 ID: ${existingUser.id}`)
      console.log(`📅 Criado em: ${new Date(existingUser.created_at).toLocaleString('pt-BR')}`)
      return true
    }

    console.log('✅ Email disponível para uso')
    return false

  } catch (error) {
    console.error('❌ Erro ao verificar usuário:', error.message)
    return false
  }
}

async function fixRLS() {
  console.log('🔧 Corrigindo RLS da tabela profiles...')
  
  try {
    // Primeiro, tentar desabilitar RLS
    const { error } = await supabase.rpc('exec_sql', {
      sql: 'ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;'
    })

    if (error) {
      console.log('ℹ️ Não foi possível executar SQL via RPC (esperado)')
      console.log('💡 Execute manualmente no Supabase: ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;')
    } else {
      console.log('✅ RLS desabilitado com sucesso!')
    }

    return true
  } catch (error) {
    console.log('ℹ️ RLS deve ser corrigido manualmente no Supabase Dashboard')
    return false
  }
}

async function main() {
  console.log('🚀 CRIANDO USUÁRIO JULIO CAMPOS MACHADO')
  console.log('=' .repeat(50))
  
  // Verificar se usuário já existe
  const userExists = await checkUserExists()
  
  if (userExists) {
    console.log('\n🎉 Usuário já existe no sistema!')
    console.log('🔗 Faça login em: https://orkut-8u2vb6qw4-astridnielsen-labs-projects.vercel.app')
    console.log('📧 Email: juliocamposmachado@gmail.com')
    console.log('🔒 Senha: Julio@78451200')
    return
  }

  // Corrigir RLS primeiro
  await fixRLS()
  
  // Criar usuário
  const success = await createUser()
  
  if (success) {
    console.log('\n🎉 USUÁRIO CRIADO COM SUCESSO!')
    console.log('=' .repeat(50))
    console.log('✅ Agora você pode fazer login com:')
    console.log('📧 Email: juliocamposmachado@gmail.com')
    console.log('🔒 Senha: Julio@78451200')
    console.log('🔗 Link: https://orkut-8u2vb6qw4-astridnielsen-labs-projects.vercel.app')
    console.log('\n👤 Dados do perfil:')
    console.log('🏷️  Username: juliocamposmachado')
    console.log('📝 Nome: Julio Campos Machado')
  } else {
    console.log('\n❌ Falha ao criar usuário')
    console.log('💡 Tente criar manualmente na aplicação')
  }
}

main().catch(console.error)
