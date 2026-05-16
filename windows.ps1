$Folder = "C:\Users\Farouk\Downloads\auto-wallpapers\images"
$TargetDownloads = 5

$Tags = @(
    "cyberpunk", "subnautica", "berserk", "witcher",
    "ghost of tsushima", "mass effect", "dead space",
    "dune", "space", "black hole", "nebula", "mountains",
    "forest", "rain", "samurai", "knight", "castle", "moon",
    "minimalist", "synthwave", "futuristic city",
    "post apocalyptic", "gothic", "cosmic horror"
)

$Tag = Get-Random -InputObject $Tags
Write-Host "Selected tag: $Tag"

# Ensure folder exists
if (-not (Test-Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder | Out-Null
    Write-Host "Created folder: $Folder"
}

$successful = 0
$page = 1

while ($successful -lt $TargetDownloads) {
    $ApiUrl = "https://wallhaven.cc/api/v1/search?q=$([uri]::EscapeDataString($Tag))&sorting=random&purity=100&ratios=16x9&atleast=1920x1080&page=$page"
    
    try {
        $response = Invoke-RestMethod -Uri $ApiUrl -ErrorAction Stop
    } catch {
        Write-Host "API request failed: $_"
        break
    }

    if (-not $response.data -or $response.data.Count -eq 0) {
        Write-Host "No more results for tag: $Tag"
        break
    }

    foreach ($wallpaper in $response.data) {
        if ($successful -ge $TargetDownloads) { break }

        $url = $wallpaper.path
        $fileName = Join-Path $Folder (Split-Path $url -Leaf)

        if (Test-Path $fileName) {
            Write-Host "Skipping (exists): $(Split-Path $fileName -Leaf)"
            continue
        }

        try {
            Invoke-WebRequest -Uri $url -OutFile $fileName -ErrorAction Stop

            if ((Test-Path $fileName) -and ((Get-Item $fileName).Length -gt 0)) {
                $successful++
                Write-Host "[$successful/$TargetDownloads] Downloaded: $(Split-Path $fileName -Leaf)"
            } else {
                Remove-Item $fileName -Force -ErrorAction SilentlyContinue
                Write-Host "Empty file, removed: $fileName"
            }
        } catch {
            Remove-Item $fileName -Force -ErrorAction SilentlyContinue
            Write-Host "Failed: $url - $_"
        }
    }

    $page++
    
    # Safety valve — don't hammer the API forever
    if ($page -gt 5) {
        Write-Host "Reached page limit, stopping."
        break
    }
}

Write-Host "`nDone. Downloaded $successful / $TargetDownloads wallpapers for tag: '$Tag'"