const { createClient } = require('@supabase/supabase-js')

// Configuração do Supabase
const supabaseUrl = 'https://woyyikaztjrhqzgvbhmn.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NjUwOTUsImV4cCI6MjA3MTI0MTA5NX0.rXp7c0167cjPXfp6kYDNKq6s4RrD8E7C2-NzukKPQnQ'

const supabase = createClient(supabaseUrl, supabaseKey)

async function createProfilesTable() {
    console.log('🚀 Criando tabela profiles...')
    
    const { data, error } = await supabase.rpc('exec_sql', {
        sql: `
            CREATE TABLE IF NOT EXISTS public.profiles (
                id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
                username text UNIQUE NOT NULL,
                display_name text NOT NULL,
                photo_url text DEFAULT 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&w=150',
                relationship text DEFAULT 'Solteiro(a)',
                location text DEFAULT '',
                birthday date,
                bio text DEFAULT '',
                fans_count integer DEFAULT 0,
                created_at timestamptz DEFAULT now()
            );
            
            ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
            
            CREATE POLICY IF NOT EXISTS "Profiles são visíveis por todos" 
                ON public.profiles FOR SELECT 
                USING (true);
                
            CREATE POLICY IF NOT EXISTS "Usuários podem inserir próprio perfil" 
                ON public.profiles FOR INSERT 
                WITH CHECK (auth.uid() = id);
        `
    })
    
    if (error) {
        console.error('❌ Erro ao criar tabela profiles:', error)
    } else {
        console.log('✅ Tabela profiles criada com sucesso!')
    }
}

async function checkTables() {
    console.log('🔍 Verificando tabelas existentes...')
    
    const { data, error } = await supabase
        .from('information_schema.tables')
        .select('table_name')
        .eq('table_schema', 'public')
    
    if (error) {
        console.error('❌ Erro ao verificar tabelas:', error)
    } else {
        console.log('📊 Tabelas encontradas:', data.map(t => t.table_name))
    }
}

async function main() {
    try {
        await checkTables()
        await createProfilesTable()
        await checkTables()
    } catch (error) {
        console.error('❌ Erro geral:', error)
    }
}

main()
