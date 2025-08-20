const { createClient } = require('@supabase/supabase-js')

const supabase = createClient('https://woyyikaztjrhqzgvbhmn.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0')

async function testProfile() {
  console.log('🧪 Testando perfil do Marcelo...\n')
  
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('username', 'marcelooliver')
      .single()
    
    if (error) {
      console.log('❌ Erro:', error.message)
      console.log('📋 Código:', error.code)
      return
    }
    
    if (data) {
      console.log('✅ Perfil encontrado!')
      console.log('👤 Nome:', data.display_name)
      console.log('🔗 Username:', data.username)
      console.log('📧 Email:', data.email)
      console.log('📍 Local:', data.location)
      console.log('💼 Relacionamento:', data.relationship)
      console.log('🆔 ID:', data.id)
    } else {
      console.log('⚠️ Nenhum dado retornado')
    }
  } catch (e) {
    console.error('❌ Erro geral:', e.message)
  }
}

testProfile()
