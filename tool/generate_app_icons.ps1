<#
=============================================================================
 GENERATION DES ICONES DE L'APPLICATION — « Le Menu Express »
=============================================================================
 Logo fourni : logo-icone-seule.png (assiette + couverts sur fond terracotta
 a coins arrondis transparents, le tout en 1024x1024).

 Contraintes des plateformes :
   - iOS   : icone carree et PLEINE, aucune transparence (le systeme applique
             lui-meme l'arrondi) ;
   - Android adaptatif : un calque avant transparent + un fond uni, le visuel
             devant tenir dans la "safe zone" (66 dp sur 108 dp) ;
   - Web/PWA : une version pleine et une version "maskable" (cercle de 80 %).

 Fichiers produits :
   assets/images/logo-app-icon.png          1024 pleine et opaque
   assets/images/logo-icone-foreground.png  1024 transparente (assiette seule)
   web/icons/*.png, web/favicon.png

 Comment : le fond du logo est un degrade diagonal (R216 G113 B55 en haut a
 gauche -> R200 G95 B41 en bas a droite), tandis que le visuel utilise deux
 couleurs franches : creme (R251 G243 B231) et brique (R192 G86 B33). Ces
 couleurs ne se recoupent pas, ce qui permet de separate le visuel du fond de
 facon fiable, meme si les degrade et le contour sont voisins.

 Utilisation : powershell -ExecutionPolicy Bypass -File tool\generate_app_icons.ps1
 (a relancer uniquement si le logo change)
=============================================================================#>

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$racine = Split-Path -Parent $PSScriptRoot
$cheminSource = Join-Path $racine 'assets\images\logo-icone-seule.png'
$dossierSortie = Join-Path $racine 'assets\images'
$dossierWebIcones = Join-Path $racine 'web\icons'

# --- Helpers ---------------------------------------------------------------

function Get-Octets([System.Drawing.Bitmap]$bmp) {
    $rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
    $data = $bmp.LockBits($rect, 'ReadOnly', 'Format32bppArgb')
    $octets = New-Object byte[] ($data.Stride * $bmp.Height)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $octets, 0, $octets.Length)
    $bmp.UnlockBits($data)
    return , $octets
}

function Set-Octets([System.Drawing.Bitmap]$bmp, [byte[]]$octets) {
    $rect = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
    $data = $bmp.LockBits($rect, 'WriteOnly', 'Format32bppArgb')
    [System.Runtime.InteropServices.Marshal]::Copy($octets, 0, $data.Scan0, $octets.Length)
    $bmp.UnlockBits($data)
}

function Nouvelle-BitmapVide([int]$largeur, [int]$hauteur) {
    return New-Object System.Drawing.Bitmap($largeur, $hauteur, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}

function Enregistrer([System.Drawing.Bitmap]$bmp, [string]$chemin) {
    $bmp.Save($chemin, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host ("  {0} ({1}x{2})" -f $chemin.Replace("$racine\", ''), $bmp.Width, $bmp.Height)
}

function Graphiques-HauteQualite([System.Drawing.Graphics]$g) {
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
}

# --- 1. Lecture du logo ---------------------------------------------------

Write-Host "`n[1/5] Lecture du logo source" -ForegroundColor Cyan
$source = New-Object System.Drawing.Bitmap($cheminSource)
$l = $source.Width
$h = $source.Height
$pixels = Get-Octets $source
$stride = $l * 4
Write-Host "  Source : ${l}x${h}"

# Bornes exactes du fond, relevees sur le logo (canal R et G).
$fondRMin = 200; $fondRMax = 216
$fondGMin = 95;  $fondGMax = 113
# Visual : creme (clair) et brique (fonce), tous deux hors de ces bornes.
$cremeR = 222; $cremeG = 200
$briqueR = 194; $briqueG = 92

# Pour chaque ligne : 1er et dernier pixel non transparent. Sert a refermer les
# coins arrondis par extension de bord (le fond n'est pas uniforme, on ne peut
# donc pas le remplacer par une couleur unique).
$xMin = New-Object int[] $h
$xMax = New-Object int[] $h
for ($y = 0; $y -lt $h; $y++) {
    $base = $y * $stride
    $gauche = -1; $droite = -1
    for ($x = 0; $x -lt $l; $x++) {
        if ($pixels[$base + $x * 4 + 3] -ne 0) { $gauche = $x; break }
    }
    for ($x = $l - 1; $x -ge 0; $x--) {
        if ($pixels[$base + $x * 4 + 3] -ne 0) { $droite = $x; break }
    }
    $xMin[$y] = $gauche
    $xMax[$y] = $droite
}

# --- 2. Masque du visuel (assiette + couverts) ---------------------------

Write-Host "`n[2/5] Extraction du visuel" -ForegroundColor Cyan
$brut = New-Object bool[] ($l * $h)
$nbBrut = 0
for ($y = 0; $y -lt $h; $y++) {
    $base = $y * $stride
    for ($x = 0; $x -lt $l; $x++) {
        $i = $base + $x * 4
        if ($pixels[$i + 3] -eq 0) { continue }
        $r = $pixels[$i + 2]; $g = $pixels[$i + 1]
        if (($r -ge $cremeR -and $g -ge $cremeG) -or ($r -le $briqueR -and $g -le $briqueG)) {
            $brut[$y * $l + $x] = $true
            $nbBrut++
        }
    }
}
Write-Host "  Pixels candidats : $nbBrut"

# On ne garde que la plus grande composante connexe (supprime le bruit eventuel),
# puis on dilate de 2 px pour reintegrer les bords anti-ales.
$visite = New-Object bool[] ($l * $h)
$meilleure = $null
$pile = [System.Collections.Generic.Stack[int]]::new()
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $l; $x++) {
        $depart = $y * $l + $x
        if (-not $brut[$depart] -or $visite[$depart]) { continue }
        $composante = [System.Collections.Generic.List[int]]::new()
        $visite[$depart] = $true
        $pile.Push($depart)
        while ($pile.Count -gt 0) {
            $index = $pile.Pop()
            $composante.Add($index)
            $cx = $index % $l
            $cy = [Math]::Floor($index / $l)
            if ($cx -gt 0)     { $v = $cy * $l + ($cx - 1); if ($brut[$v] -and -not $visite[$v]) { $visite[$v] = $true; $pile.Push($v) } }
            if ($cx -lt $l - 1) { $v = $cy * $l + ($cx + 1); if ($brut[$v] -and -not $visite[$v]) { $visite[$v] = $true; $pile.Push($v) } }
            if ($cy -gt 0)     { $v = ($cy - 1) * $l + $cx; if ($brut[$v] -and -not $visite[$v]) { $visite[$v] = $true; $pile.Push($v) } }
            if ($cy -lt $h - 1) { $v = ($cy + 1) * $l + $cx; if ($brut[$v] -and -not $visite[$v]) { $visite[$v] = $true; $pile.Push($v) } }
        }
        if ($meilleure -eq $null -or $composante.Count -gt $meilleure.Count) { $meilleure = $composante }
    }
}
if ($meilleure -eq $null) { throw "Aucun visuel detecte dans le logo." }
Write-Host "  Composante principale : $($meilleure.Count) pixels"

$masque = New-Object bool[] ($l * $h)
foreach ($index in $meilleure) { $masque[$index] = $true }
for ($pass = 0; $pass -lt 2; $pass++) {
    $copie = [bool[]]$masque.Clone()
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $l; $x++) {
            if ($copie[$y * $l + $x]) { continue }
            if (($x -gt 0 -and $copie[$y * $l + $x - 1]) -or
                ($x -lt $l - 1 -and $copie[$y * $l + $x + 1]) -or
                ($y -gt 0 -and $copie[($y - 1) * $l + $x]) -or
                ($y -lt $h - 1 -and $copie[($y + 1) * $l + $x])) {
                $masque[$y * $l + $x] = $true
            }
        }
    }
}

$minX = $l; $maxX = -1; $minY = $h; $maxY = -1
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $l; $x++) {
        if (-not $masque[$y * $l + $x]) { continue }
        if ($x -lt $minX) { $minX = $x }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($y -gt $maxY) { $maxY = $y }
    }
}
$largeurPlate = $maxX - $minX + 1
$hauteurPlate = $maxY - $minY + 1
Write-Host "  Emprise : x[$minX..$maxX] y[$minY..$maxY] = ${largeurPlate}x${hauteurPlate}"

# --- 3. Icone pleine et opaque (iOS / legacy / web) -----------------------

Write-Host "`n[3/5] Creation de l'icone pleine (opaque)" -ForegroundColor Cyan

# Ligne de reference a copier pour les lignes entierement transparentes
# (extremites des coins arrondis).
$refLigne = New-Object int[] $h
for ($i = 0; $i -lt $h; $i++) { $refLigne[$i] = -1 }
$dernier = -1
for ($y = 0; $y -lt $h; $y++) {
    if ($xMin[$y] -ge 0) { $dernier = $y }
    if ($dernier -ge 0) { $refLigne[$y] = $dernier }
}
$prochain = -1
for ($y = $h - 1; $y -ge 0; $y--) {
    if ($xMin[$y] -ge 0) { $prochain = $y }
    if ($refLigne[$y] -lt 0 -and $prochain -ge 0) { $refLigne[$y] = $prochain }
}

$icone = Nouvelle-BitmapVide $l $h
$octetsIcone = New-Object byte[] ($stride * $h)
for ($y = 0; $y -lt $h; $y++) {
    $r = $refLigne[$y]
    if ($r -lt 0) { throw "Ligne $y sans reference." }
    $iGauche = $r * $stride + $xMin[$r] * 4
    $iDroite = $r * $stride + $xMax[$r] * 4
    $base = $y * $stride
    for ($x = 0; $x -lt $l; $x++) {
        $i = $base + $x * 4
        $sourceCouleur = if ($x -le $xMax[$r]) { $iGauche } else { $iDroite }
        $octetsIcone[$i + 0] = $pixels[$sourceCouleur + 0]
        $octetsIcone[$i + 1] = $pixels[$sourceCouleur + 1]
        $octetsIcone[$i + 2] = $pixels[$sourceCouleur + 2]
        $octetsIcone[$i + 3] = 255
    }
    # Recomposition du logo par-dessus, avec melange alpha.
    for ($x = 0; $x -lt $l; $x++) {
        $i = $base + $x * 4
        $a = $pixels[$i + 3]
        if ($a -eq 0) { continue }
        if ($a -eq 255) {
            $octetsIcone[$i + 0] = $pixels[$i + 0]
            $octetsIcone[$i + 1] = $pixels[$i + 1]
            $octetsIcone[$i + 2] = $pixels[$i + 2]
        } else {
            $k = $a / 255.0
            for ($c = 0; $c -lt 3; $c++) {
                $octetsIcone[$i + $c] = [int]($pixels[$i + $c] * $k + $octetsIcone[$i + $c] * (1 - $k))
            }
        }
    }
}
Set-Octets $icone $octetsIcone
Enregistrer $icone (Join-Path $dossierSortie 'logo-app-icon.png')
$icone.Dispose()

# --- 4. Calque avant adaptatif (assiette seule, transparente) -------------

Write-Host "`n[4/5] Creation du calque avant adaptatif" -ForegroundColor Cyan
$plate = Nouvelle-BitmapVide $largeurPlate $hauteurPlate
$octetsPlate = New-Object byte[] ($largeurPlate * 4 * $hauteurPlate)
for ($y = 0; $y -lt $hauteurPlate; $y++) {
    for ($x = 0; $x -lt $largeurPlate; $x++) {
        $src = ($y + $minY) * $stride + ($x + $minX) * 4
        $dst = $y * $largeurPlate * 4 + $x * 4
        if ($masque[($y + $minY) * $l + ($x + $minX)]) {
            $octetsPlate[$dst + 0] = $pixels[$src + 0]
            $octetsPlate[$dst + 1] = $pixels[$src + 1]
            $octetsPlate[$dst + 2] = $pixels[$src + 2]
            $octetsPlate[$dst + 3] = $pixels[$src + 3]
        }
    }
}
Set-Octets $plate $octetsPlate

# 54 % du canevas : le visuel reste entier dans la safe zone (66/108 dp) et
# demeure bien lisible dans la barre des taches (env. 48 dp de large).
$avant = Nouvelle-BitmapVide $l $h
$g = [System.Drawing.Graphics]::FromImage($avant)
Graphiques-HauteQualite $g
$cible = [int]($l * 0.54)
$decalage = [int](($l - $cible) / 2)
$g.DrawImage($plate, (New-Object System.Drawing.Rectangle $decalage, $decalage, $cible, $cible), 0, 0, $largeurPlate, $hauteurPlate, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
Enregistrer $avant (Join-Path $dossierSortie 'logo-icone-foreground.png')
$avant.Dispose()

# --- 5. Icones web / PWA --------------------------------------------------

Write-Host "`n[5/5] Generation des icones web" -ForegroundColor Cyan
$iconeComplete = New-Object System.Drawing.Bitmap((Join-Path $dossierSortie 'logo-app-icon.png'))

foreach ($taille in @(192, 512)) {
    $petite = Nouvelle-BitmapVide $taille $taille
    $g = [System.Drawing.Graphics]::FromImage($petite)
    Graphiques-HauteQualite $g
    $g.DrawImage($iconeComplete, (New-Object System.Drawing.Rectangle 0, 0, $taille, $taille), 0, 0, $l, $h, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    Enregistrer $petite (Join-Path $dossierWebIcones "Icon-$taille.png")
    $petite.Dispose()
}

# Version "maskable" : le visuel doit tenir dans un cercle de 80 %, on le
# reduit a 52 % et on le pose sur le terracotta moyen de la marque.
$terracotta = [System.Drawing.Color]::FromArgb(
    255,
    [int](($fondRMin + $fondRMax) / 2),
    [int](($fondGMin + $fondGMax) / 2),
    [int]((41 + 55) / 2))
foreach ($taille in @(192, 512)) {
    $maskable = Nouvelle-BitmapVide $taille $taille
    $g = [System.Drawing.Graphics]::FromImage($maskable)
    Graphiques-HauteQualite $g
    $g.Clear($terracotta)
    $tailleVisuel = [int]($taille * 0.52)
    $decalage = [int](($taille - $tailleVisuel) / 2)
    $g.DrawImage($plate, (New-Object System.Drawing.Rectangle $decalage, $decalage, $tailleVisuel, $tailleVisuel), 0, 0, $largeurPlate, $hauteurPlate, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    Enregistrer $maskable (Join-Path $dossierWebIcones "Icon-maskable-$taille.png")
    $maskable.Dispose()
}

$favicon = Nouvelle-BitmapVide 64 64
$g = [System.Drawing.Graphics]::FromImage($favicon)
Graphiques-HauteQualite $g
$g.DrawImage($iconeComplete, (New-Object System.Drawing.Rectangle 0, 0, 64, 64), 0, 0, $l, $h, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
Enregistrer $favicon (Join-Path (Join-Path $racine 'web') 'favicon.png')
$favicon.Dispose()

$iconeComplete.Dispose()
$plate.Dispose()
$source.Dispose()

$couleur = '#{0:X2}{1:X2}{2:X2}' -f $terracotta.R, $terracotta.G, $terracotta.B
Write-Host ("`nTermine. Fond adaptatif Android a utiliser dans pubspec.yaml : {0}" -f $couleur) -ForegroundColor Green
