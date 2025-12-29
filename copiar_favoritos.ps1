# ======================
# Configuración
# ======================

$DrivePath = "."
$FavPath   = ".\00_copiarfavoritos"
$LogDir    = Join-Path $FavPath "logs"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$DateStr        = Get-Date -Format "yyyy-MM-dd"
$LogFile        = Join-Path $LogDir "log_$DateStr.txt"
$FaltantesFile  = Join-Path $LogDir "faltantes_$DateStr.txt"

"" | Out-File $FaltantesFile -Encoding UTF8

$copiadas  = 0
$faltantes = 0
$skipped   = 0

function Log { param ($Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $line | Tee-Object -FilePath $LogFile -Append
}

function Decode-Xml { param ($Text)
    if ($null -eq $Text) { return "" }
    return [System.Net.WebUtility]::HtmlDecode($Text)
}

Log "===== INICIO ====="

Get-ChildItem -Path $DrivePath -Directory | ForEach-Object {
    $system = $_.Name
    if ($system -eq "ports") { Log "Sistema 'ports' ignorado"; return }

    $gamelist = Join-Path $_.FullName "gamelist.xml"
    if (-not (Test-Path $gamelist)) { Log "Sin gamelist.xml en $system"; return }

    [xml]$xml = Get-Content $gamelist -Encoding UTF8
    $games = $xml.gameList.game | Where-Object { $_.favorite -eq "true" }
    if (-not $games) { Log "Sin favoritos en $system"; return }

    $destSystem = Join-Path $FavPath $system
    New-Item -ItemType Directory -Path $destSystem -Force | Out-Null

    foreach ($game in $games) {
        $relPath  = Decode-Xml $game.path
        $name     = Decode-Xml $game.name
        $imageRel = Decode-Xml $game.image
        $romBase  = Split-Path $relPath -Leaf
        $romPath  = $null

        $exactPath = Join-Path $_.FullName $relPath
        if (Test-Path $exactPath) { $romPath = $exactPath }
        else {
            $romPath = Get-ChildItem -Path $_.FullName -Recurse -File -Filter $romBase -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $romPath) { $romPath = Get-ChildItem -Path $DrivePath -Recurse -File -Filter $romBase -ErrorAction SilentlyContinue | Select-Object -First 1 }
            if ($romPath) { $romPath = $romPath.FullName }
        }

        if ($romPath -and (Test-Path $romPath)) {
            $subfolder = Split-Path (Split-Path $romPath -Parent) -Leaf
            $destRomDir = Join-Path $destSystem $subfolder
            New-Item -ItemType Directory -Path $destRomDir -Force | Out-Null
            $destRom = Join-Path $destRomDir (Split-Path $romPath -Leaf)

            if (Test-Path $destRom) { Log "ROM ya existe, se omite: $name"; $skipped++; continue }

            Log "Copiando ROM: $name -> $subfolder/"
            Copy-Item -Path $romPath -Destination $destRom -Verbose | Tee-Object -FilePath $LogFile -Append
            $copiadas++

            # Copiar imagen
            $imagePath = $null
            if ($imageRel) {
                $exactImage = Join-Path $_.FullName $imageRel
                if (Test-Path $exactImage) { $imagePath = $exactImage }
            }
            if (-not $imagePath) {
                $romNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($romBase)
                $imagePath = Get-ChildItem -Path $_.FullName -Recurse -File -Include "$romNameNoExt.png","$romNameNoExt.jpg" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($imagePath) { $imagePath = $imagePath.FullName }
            }
            if ($imagePath -and (Test-Path $imagePath)) {
                $destImgDir = Join-Path $destRomDir "images"
                New-Item -ItemType Directory -Path $destImgDir -Force | Out-Null
                $destImg = Join-Path $destImgDir (Split-Path $imagePath -Leaf)
                if (-not (Test-Path $destImg)) { Log "Copiando imagen: $(Split-Path $imagePath -Leaf)"; Copy-Item -Path $imagePath -Destination $destImg -Verbose | Tee-Object -FilePath $LogFile -Append }
                else { Log "Imagen ya existe, se omite: $(Split-Path $imagePath -Leaf)" }
            } else { Log "Imagen no encontrada para: $name" }

        } else { Log "ROM no encontrada: $relPath"; "$system/$relPath" | Out-File $FaltantesFile -Append -Encoding UTF8; $faltantes++ }
    }
}

Write-Host ""
Write-Host "===== FIN DEL PROCESO ====="
Write-Host "ROMs copiadas correctamente: $copiadas"
Write-Host "ROMs ya existentes (omitidas): $skipped"
Write-Host "ROMs faltantes: $faltantes"
Write-Host "Log completo: $LogFile"

if ($faltantes -eq 0) { Write-Host "✔ Copia de favoritos completada sin errores." }
else { Write-Host "⚠ Copia de favoritos completada con errores."; Write-Host "Revisa el log y el archivo de faltantes: $FaltantesFile" }

Write-Host ""
Read-Host "Pulsa ENTER para salir"
