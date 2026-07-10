$webflowDir = "d:\Workspace\Web\Youtap\New folder\Youtap Indonesia\youtap-indonesia.webflow"
$pagesDir   = "d:\Workspace\Web\Youtap\New folder\Youtap Indonesia\src\pages"

New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$htmlFiles = Get-ChildItem -Path $webflowDir -Filter "*.html" -File

$migrated = [System.Collections.Generic.List[string]]::new()
$skipped  = [System.Collections.Generic.List[string]]::new()
$failed   = [System.Collections.Generic.List[string]]::new()

foreach ($file in $htmlFiles) {
    $slug       = $file.BaseName
    $outputPath = Join-Path $pagesDir "$slug.astro"

    # Skip already-migrated pages
    if (Test-Path $outputPath) {
        $skipped.Add($slug)
        continue
    }

    try {
        $raw = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

        # --- Extract <title> ---
        $titleMatch = [regex]::Match($raw, '(?s)<title>(.*?)</title>')
        $title = if ($titleMatch.Success) {
            $titleMatch.Groups[1].Value.Trim() -replace '"', '&quot;'
        } else { 'Youtap Indonesia' }

        # --- Extract meta description (two attribute orders) ---
        $descMatch = [regex]::Match($raw, '<meta\s[^>]*name="description"[^>]*content="([^"]*)"')
        if (-not $descMatch.Success) {
            $descMatch = [regex]::Match($raw, '<meta\s[^>]*content="([^"]*)"[^>]*name="description"')
        }
        $description = if ($descMatch.Success) {
            $descMatch.Groups[1].Value.Trim() -replace '"', '&quot;'
        } else { 'Youtap Indonesia' }

        # --- Extract body content ---
        $bodyMatch = [regex]::Match($raw, '(?s)<body[^>]*>(.*)</body>')
        if (-not $bodyMatch.Success) {
            $failed.Add("$slug (no <body> found)")
            continue
        }
        $body = $bodyMatch.Groups[1].Value

        # --- Fix asset paths (relative → /public) ---
        # src attributes
        $body = $body -replace 'src="images/',  'src="/images/'
        $body = $body -replace "src='images/",  "src='/images/"
        $body = $body -replace 'src="js/',      'src="/js/'
        $body = $body -replace 'src="videos/',  'src="/videos/'
        $body = $body -replace 'src="fonts/',   'src="/fonts/'
        $body = $body -replace 'src="css/',     'src="/css/'
        # href attributes
        $body = $body -replace 'href="images/', 'href="/images/'
        $body = $body -replace 'href="css/',    'href="/css/'
        # srcset (start of value + comma-separated entries)
        $body = $body -replace 'srcset="images/', 'srcset="/images/'
        $body = $body -replace ' images/',      ' /images/'
        $body = $body -replace ',images/',      ',/images/'

        # --- Self-close bare void elements ---
        $body = $body -replace '(?<!</)(<br)>',   '$1 />'
        $body = $body -replace '(?<!</)(<hr)>',   '$1 />'
        # img / input / source / embed – add /> only when not already present
        $body = [regex]::Replace(
            $body,
            '(<(?:img|input|source|embed)(?:[^>]*?))(?<!\/)>',
            '$1 />'
        )

        # --- Ensure <script> tags use is:inline ---
        # Handles: <script> and <script attr=...>
        $body = $body -replace '(<script)(?! is:inline)([ >])', '$1 is:inline$2'

        # --- Compose Astro file ---
        $astro = @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="$title" description="$description">
$body
</BaseLayout>
"@

        [System.IO.File]::WriteAllText($outputPath, $astro, [System.Text.Encoding]::UTF8)
        $migrated.Add($slug)

    } catch {
        $failed.Add("$slug : $_")
    }
}

# --- Report ---
Write-Host "`n=== Migration Report ==="
Write-Host "Migrated : $($migrated.Count)"
Write-Host "Skipped  : $($skipped.Count)  (already existed)"
Write-Host "Failed   : $($failed.Count)"

if ($migrated.Count -gt 0) {
    Write-Host "`nMigrated pages:"
    $migrated | ForEach-Object { Write-Host "  + $_" }
}
if ($skipped.Count -gt 0) {
    Write-Host "`nSkipped (already exist):"
    $skipped | ForEach-Object { Write-Host "  ~ $_" }
}
if ($failed.Count -gt 0) {
    Write-Host "`nFailed:"
    $failed | ForEach-Object { Write-Host "  ! $_" }
}
