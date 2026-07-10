$webflowDir = "youtap-indonesia.webflow"
$pagesDir = "src\pages"

If (!(Test-Path $pagesDir)) {
    New-Item -ItemType Directory -Force -Path $pagesDir | Out-Null
}

$voidElements = @('img', 'input', 'source', 'embed', 'area', 'base', 'col', 'hr', 'br', 'link', 'meta', 'param', 'track', 'wbr')
$voidPattern = "(?i)<(" + ($voidElements -join '|') + ")(\s[^>]*?)?(?<!\/)>"

$files = Get-ChildItem -Path $webflowDir -Filter "*.html" -File

$migrated = @()
$skipped = @()
$failed = @()

foreach ($file in $files) {
    $slug = $file.BaseName
    $outputPath = Join-Path $pagesDir "$slug.astro"

    if (Test-Path $outputPath) {
        $skipped += $slug
        continue
    }

    try {
        $html = Get-Content $file.FullName -Raw

        # Title
        $title = "Youtap Indonesia"
        if ($html -match '(?i)<title>([\s\S]*?)<\/title>') {
            $title = $matches[1].Trim() -replace '"', '&quot;'
        }

        # Description
        $description = ""
        if ($html -match '(?i)<meta[^>]+name="description"[^>]+content="([^"]*)"') {
            $description = $matches[1] -replace '"', '&quot;'
        } elseif ($html -match '(?i)<meta[^>]+content="([^"]*)"[^>]+name="description"') {
            $description = $matches[1] -replace '"', '&quot;'
        }

        # Body
        if ($html -match '(?i)<body[^>]*>([\s\S]*)<\/body>') {
            $body = $matches[1]
        } else {
            throw "No <body> tag found"
        }

        # Replacements
        $body = $body -replace 'src="images/', 'src="/images/'
        $body = $body -replace 'href="images/', 'href="/images/'
        $body = $body -replace 'srcset="images/', 'srcset="/images/'
        $body = [regex]::Replace($body, '([\s,])images/', '$1/images/')
        $body = $body -replace 'src="js/', 'src="/js/'
        $body = $body -replace 'src="videos/', 'src="/videos/'
        $body = $body -replace 'src="fonts/', 'src="/fonts/'
        $body = $body -replace 'href="css/', 'href="/css/'
        $body = $body -replace 'src="css/', 'src="/css/'

        # Void elements self closing
        $body = [regex]::Replace($body, $voidPattern, {
            param($m)
            $attrs = if ($m.Groups[2].Success) { $m.Groups[2].Value } else { "" }
            return "<$($m.Groups[1].Value)$attrs />"
        })
        $body = $body -replace '\s+/>', ' />'

        # is:inline
        $body = [regex]::Replace($body, '(?i)<script(?! is:inline)(\s|>)', '<script is:inline$1')

        $astro = @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="$title" description="$description">
$body
</BaseLayout>
"@

        Set-Content -Path $outputPath -Value $astro -Encoding UTF8
        $migrated += $slug
    } catch {
        $failed += "$slug: $_"
    }
}

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
