const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0'

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function checkProfile() {
  const userId = '137fa9a8-561c-4ae2-85c6-34919cd4bcad'
  
  console.log('👤 Verificando perfil do Julio Campos Machado...')
  console.log(`🆔 ID: ${userId}`)
  
  try {
    // Verificar se perfil existe
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    
    if (error) {
      console.log('❌ Perfil não encontrado:', error.message)
      console.log('🔧 Criando perfil...')
      
      // Criar perfil
      const { error: insertError } = await supabase
        .from('profiles')
        .insert({
          id: userId,
          username: 'juliocamposmachado',
          display_name: 'Julio Campos Machado',
          photo_url: 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
          relationship: 'Solteiro(a)',
          fans_count: 0
        })
      
      if (insertError) {
        console.error('❌ Erro ao criar perfil:', insertError.message)
        return false
      }
      
      console.log('✅ Perfil criado com sucesso!')
      return true
    }
    
    console.log('✅ Perfil encontrado!')
    console.log('📝 Dados do perfil:')
    console.log(`   🏷️  Username: ${profile.username}`)
    console.log(`   📛 Nome: ${profile.display_name}`)
    console.log(`   💕 Relacionamento: ${profile.relationship}`)
    console.log(`   👥 Fãs: ${profile.fans_count}`)
    console.log(`   📅 Criado em: ${new Date(profile.created_at).toLocaleString('pt-BR')}`)
    
    return true
    
  } catch (error) {
    console.error('❌ Erro ao verificar perfil:', error.message)
    return false
  }
}

checkProfile().then(() => {
  console.log('\n🎯 RESULTADO:')
  console.log('✅ Usuário: juliocamposmachado@gmail.com')
  console.log('✅ Senha: Julio@78451200') 
  console.log('✅ Link: https://orkut-8u2vb6qw4-astridnielsen-labs-projects.vercel.app')
  console.log('\n🚀 PRONTO PARA FAZER LOGIN!')
})
