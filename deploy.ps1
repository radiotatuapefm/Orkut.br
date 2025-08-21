# Script de Deploy do Orkut para Vercel
# Julio Campos Machado - Like Look Solutions

Write-Host "🚀 Iniciando processo de deploy do Orkut..." -ForegroundColor Cyan

# Verificar se estamos no diretório correto
if (!(Test-Path "package.json")) {
    Write-Host "❌ Erro: package.json não encontrado. Execute este script na raiz do projeto." -ForegroundColor Red
    exit 1
}

# Verificar se há mudanças não commitadas
Write-Host "📋 Verificando status do Git..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️  Há mudanças não commitadas:" -ForegroundColor Yellow
    git status --short
    
    $choice = Read-Host "Deseja fazer commit dessas mudanças? (S/N)"
    if ($choice -eq "S" -or $choice -eq "s") {
        $commitMessage = Read-Host "Digite a mensagem do commit"
        git add .
        git commit -m $commitMessage
        git push origin main
        Write-Host "✅ Mudanças commitadas e enviadas para o GitHub!" -ForegroundColor Green
    }
}

# Verificar se está sincronizado com origin
Write-Host "🔄 Verificando sincronização com GitHub..." -ForegroundColor Yellow
git fetch origin
$behind = git rev-list HEAD..origin/main --count
if ($behind -gt 0) {
    Write-Host "⚠️  Seu branch está $behind commits atrás do origin. Fazendo pull..." -ForegroundColor Yellow
    git pull origin main
}

# Limpar cache e fazer build
Write-Host "🧹 Limpando cache..." -ForegroundColor Yellow
Remove-Item -Recurse -Force ".next" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "node_modules/.cache" -ErrorAction SilentlyContinue

Write-Host "📦 Instalando dependências..." -ForegroundColor Yellow
npm install

Write-Host "🔨 Fazendo build de produção..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build concluído com sucesso!" -ForegroundColor Green
    
    # Tentar fazer deploy no Vercel
    Write-Host "🚀 Fazendo deploy no Vercel..." -ForegroundColor Cyan
    vercel --prod
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🎉 Deploy concluído com sucesso!" -ForegroundColor Green
        Write-Host "🌐 Seu site está online no Vercel!" -ForegroundColor Green
    } else {
        Write-Host "❌ Erro no deploy do Vercel. Verifique se não atingiu o limite diário." -ForegroundColor Red
        Write-Host "💡 Tente novamente em algumas horas ou amanhã." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Erro no build. Corrija os erros antes de fazer deploy." -ForegroundColor Red
    exit 1
}

Write-Host "✨ Processo finalizado!" -ForegroundColor Cyan
