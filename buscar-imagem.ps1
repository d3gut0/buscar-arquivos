# Caminho do arquivo de configuração
$configPath = ".\config.txt"

if (!(Test-Path $configPath)) {
    Write-Host "Arquivo config.txt não encontrado!"
    exit
}

# Ler e limpar linhas (remove comentários e vazios)
$configLines = Get-Content $configPath | Where-Object {
    $_.Trim() -ne "" -and $_.Trim() -notlike "#*"
}

$origem = ($configLines | Where-Object { $_ -like "ORIGEM=*" }) -replace "ORIGEM=", ""
$destino = ($configLines | Where-Object { $_ -like "DESTINO=*" }) -replace "DESTINO=", ""

# Encontrar índice da linha NOMES=
$indiceNomes = -1
for ($i = 0; $i -lt $configLines.Count; $i++) {
    if ($configLines[$i] -like "NOMES=*") {
        $indiceNomes = $i
        break
    }
}

$nomes = @()

if ($indiceNomes -ge 0) {

    # Primeiro nome pode estar na mesma linha
    $primeiraLinha = $configLines[$indiceNomes] -replace "NOMES=", ""
    if ($primeiraLinha.Trim() -ne "") {
        $nomes += $primeiraLinha.Trim()
    }

    # Pega linhas abaixo
    for ($i = $indiceNomes + 1; $i -lt $configLines.Count; $i++) {

        $linha = $configLines[$i].Trim()

        # Se encontrar nova configuração, para
        if ($linha -match "^[A-Z]+=") {
            break
        }

        $nomes += $linha
    }
}

if (!(Test-Path $origem)) {
    Write-Host "Pasta de origem não encontrada!"
    exit
}

if (!(Test-Path $destino)) {
    New-Item -ItemType Directory -Path $destino | Out-Null
}

Write-Host "Procurando arquivos..."
$arquivosEncontrados = 0

$arquivosEncontrados = 0
$naoEncontrados = @()

# foreach ($nome in $nomes) {

#     $resultados = Get-ChildItem -Path $origem -Recurse -File -ErrorAction SilentlyContinue |
#         Where-Object { $_.Name -like "*$nome*" }

#     if (!$resultados) {
#         $naoEncontrados += $nome
#     }
#     else {
#         foreach ($arquivo in $resultados) {
#             Copy-Item $arquivo.FullName -Destination $destino -Force
#             Write-Host "Copiado: $($arquivo.FullName)" -ForegroundColor Green
#             $arquivosEncontrados++
#         }
#     }
# }

foreach ($nome in $nomes) {

    # Remove tudo depois de ponto ou hífen
    $codigoBase = $nome -replace '[\.\-].*$', ''

    $resultados = Get-ChildItem -Path $origem -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -like "$codigoBase*" }

    if (!$resultados) {
        $naoEncontrados += $nome
    }
    else {
        foreach ($arquivo in $resultados) {
            Copy-Item $arquivo.FullName -Destination $destino -Force
            Write-Host "Copiado: $($arquivo.FullName)" -ForegroundColor Green
            $arquivosEncontrados++
        }
    }
}

Write-Host ""
Write-Host "Processo finalizado!"
Write-Host "Total de arquivos copiados: $arquivosEncontrados"

if ($naoEncontrados.Count -gt 0) {
    Write-Host ""
    Write-Host "Arquivos nao encontrados:" -ForegroundColor Yellow
    foreach ($item in $naoEncontrados) {
        Write-Host "- $item" -ForegroundColor Yellow
    }
}
else {
    Write-Host ""
    Write-Host "Todos os nomes foram encontrados!" -ForegroundColor Cyan
}
