# Script para adicionar variáveis de ambiente no Vercel

Write-Host "Configurando variáveis de ambiente no Vercel..."

# Adicionar NEXT_PUBLIC_SUPABASE_URL
Write-Host "Adicionando NEXT_PUBLIC_SUPABASE_URL..."
"https://woyyikaztjrhqzgvbhmn.supabase.co" | vercel env add NEXT_PUBLIC_SUPABASE_URL production

# Adicionar NEXT_PUBLIC_SUPABASE_ANON_KEY
Write-Host "Adicionando NEXT_PUBLIC_SUPABASE_ANON_KEY..."
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndveXlpa2F6dGpyaHF6Z3ZiaG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2NjUwOTUsImV4cCI6MjA3MTI0MTA5NX0.rXp7c0167cjPXfp6kYDNKq6s4RrD8E7C2-NzukKPQnQ" | vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY production

Write-Host "Variáveis de ambiente configuradas com sucesso!"
Write-Host "Agora você pode fazer o deploy com: vercel --prod"
