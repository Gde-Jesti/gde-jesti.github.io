# generate_pages.ps1
$restaurants = Get-Content _data\restaurants.json -Encoding UTF8 | ConvertFrom-Json
$restoraniDir = "_restorani"

if (!(Test-Path $restoraniDir)) {
    New-Item -ItemType Directory -Path $restoraniDir
}

foreach ($restaurant in $restaurants) {
    if (-not $restaurant.Name -or -not $restaurant.Location) {
        Write-Host "Skipping invalid restaurant data: $($restaurant | ConvertTo-Json)"
        continue
    }

    # Normalize and replace diacritics step-by-step for Name
    $tempName = $restaurant.Name
    $tempName = $tempName -replace '[žŽ]', 'z'
    $tempName = $tempName -replace '[šŠ]', 's'
    $tempName = $tempName -replace '[ćĆ]', 'c'
    $tempName = $tempName -replace '[čČ]', 'c'
    $tempName = $tempName -replace '[đĐ]', 'dj'
    $tempName = $tempName -replace '[^\w\s-]', ''
    $tempName = $tempName -replace '\s+', '-'

    # Normalize and replace diacritics step-by-step for Location
    $tempLocation = $restaurant.Location
    $tempLocation = $tempLocation -replace '[žŽ]', 'z'
    $tempLocation = $tempLocation -replace '[šŠ]', 's'
    $tempLocation = $tempLocation -replace '[ćĆ]', 'c'
    $tempLocation = $tempLocation -replace '[čČ]', 'c'
    $tempLocation = $tempLocation -replace '[đĐ]', 'dj'
    $tempLocation = $tempLocation -replace '[^\w\s-]', ''
    $tempLocation = $tempLocation -replace '\s+', '-'

    # Combine and finalize slug (URL-safe, no diacritics)
    $slug = ($tempName + "-" + $tempLocation) -replace '-+', '-' | ForEach-Object { $_.ToLower() }
    $fileName = "$slug.md"
    $filePath = Join-Path $restoraniDir $fileName
    $fullAddress = if ($restaurant.Address -and $restaurant.Location) { "$($restaurant.Address), $($restaurant.Location)" } else { $restaurant.Location }

    $address = if ($restaurant.Address) { $restaurant.Address } else { 'Nema dostupne adrese' }
    $phone = if ($restaurant.Phone) { $restaurant.Phone } else { 'Nema dostupan telefon' }
    $dishes = if ($restaurant.Dishes -and $restaurant.Dishes -is [array]) { $restaurant.Dishes -join ', ' } else { $restaurant.Dishes }

    # Preserve original Serbian characters in content
    $content = @"
---
layout: restaurant_detail
title: $($restaurant.Name)
description: $($restaurant.Description)
---

# $($restaurant.Name)
<p class="description">$($restaurant.Description)</p>

<div class="left-column text-content">
    <h2>Informacije</h2>
    <ul>
        <li><strong>Mesto:</strong> $($restaurant.Location)</li>
        <li><strong>Adresa:</strong> $address</li>
        <li><strong>Telefon:</strong> $phone</li>
        <li><strong>Web:</strong> $(if ($restaurant.Website) { "<a href='$($restaurant.Website)' target='_blank'>$($restaurant.Website)</a>" } else { "Nema" })</li>
        <li><strong>Meni:</strong> $dishes</li>
    </ul>

    <h2>Mapa</h2>
    <p>
    $(if ($restaurant.Address -and $restaurant.Location) { "<a href='https://www.google.com/maps/search/?api=1&query=$([uri]::EscapeDataString($fullAddress))' target='_blank'>Otvori u Google Maps</a>" } else { "Adresa nije dostupna za mapu." })
    </p>
</div>

<div class="right-column">
    <h2>Slike</h2>
    <div class="images-grid">
$(
        if ($restaurant.'Image URLs' -and $restaurant.'Image URLs'.Count -gt 0) {
            $restaurant.'Image URLs' | ForEach-Object { "<img src='$_' alt='$($restaurant.Name) - slika $([array]::IndexOf($restaurant.'Image URLs', $_) + 1)'>" }
        } else {
            "<p>Nema dostupnih slika.</p>"
        }
)
    </div>
</div>
"@

    # Write with UTF-8 without BOM
    [System.IO.File]::WriteAllText($filePath, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Created $filePath"
}