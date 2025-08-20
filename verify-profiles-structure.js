const { createClient } = require('@supabase/supabase-js')

const supabase = createClient('https://woyyikaztjrhqzgvbhmn.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY2NTA5NSwiZXhwIjoyMDcxMjQxMDk1fQ.nxVKHOalxeURcLkHPoe1JS3TtlmnJsO3C4bvwBEzpe0')

async function verifyStructure() {
  console.log('🔍 Verificando estrutura da tabela profiles...\n')
  
  try {
    // Tentar buscar todos os campos do perfil do Marcelo
    console.log('📋 Testando consulta completa...')
    const { data, error } = await supabase
      .from('profiles')
      .select(`
        id,
        display_name,
        username,
        email,
        photo_url,
        phone,
        whatsapp_enabled,
        privacy_settings,
        created_at,
        bio,
        location,
        relationship,
        website,
        fans_count,
        views_count
      `)
      .eq('username', 'marcelooliver')
      .single()
    
    if (error) {
      console.log('❌ Erro na consulta:', error.message)
      console.log('📋 Código do erro:', error.code)
      
      // Tentar consulta mais simples
      console.log('\n🔄 Tentando consulta básica...')
      const { data: basicData, error: basicError } = await supabase
        .from('profiles')
        .select('*')
        .eq('username', 'marcelooliver')
        .single()
      
      if (basicError) {
        console.log('❌ Erro na consulta básica:', basicError.message)
      } else {
        console.log('✅ Consulta básica funcionou!')
        console.log('📝 Campos disponíveis:')
        Object.keys(basicData).forEach(key => {
          console.log(`   - ${key}: ${basicData[key]}`)
        })
      }
      return
    }
    
    if (data) {
      console.log('✅ Consulta completa funcionou!')
      console.log('\n📝 Dados do perfil:')
      console.log('🆔 ID:', data.id)
      console.log('👤 Nome:', data.display_name)
      console.log('🔗 Username:', data.username)
      console.log('📧 Email:', data.email)
      console.log('📸 Foto:', data.photo_url)
      console.log('📍 Localização:', data.location)
      console.log('💼 Relacionamento:', data.relationship)
      console.log('📊 Bio:', data.bio)
      console.log('👥 Fãs:', data.fans_count)
      console.log('👁️ Visualizações:', data.views_count)
    } else {
      console.log('⚠️ Nenhum dado retornado')
    }
    
  } catch (e) {
    console.error('❌ Erro geral:', e.message)
  }
}

async function testProfileQuery() {
  console.log('\n🧪 Testando consulta como na aplicação...')
  
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select(`
        id,
        display_name as name,
        username,
        email,
        photo_url as avatar_url,
        phone,
        whatsapp_enabled,
        privacy_settings,
        created_at,
        bio,
        location,
        relationship,
        website,
        fans_count,
        views_count
      `)
      .eq('username', 'marcelooliver')
      .single()
    
    if (error) {
      console.log('❌ Erro:', error.message)
      return
    }
    
    if (data) {
      console.log('✅ Consulta da aplicação funcionou!')
      console.log('📝 Estrutura correta para TypeScript:')
      console.log(JSON.stringify(data, null, 2))
    }
    
  } catch (e) {
    console.error('❌ Erro:', e.message)
  }
}

async function main() {
  await verifyStructure()
  await testProfileQuery()
  
  console.log('\n📋 PRÓXIMOS PASSOS:')
  console.log('1. Execute o script fix-profiles-table.sql no Supabase')
  console.log('2. Execute este script novamente para verificar')
  console.log('3. Faça o deploy da aplicação')
}

main()
