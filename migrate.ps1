$content = Get-Content -Raw "youtap-indonesia.webflow\spektacuan.html"

# Replace paths
$content = $content -replace 'href="css/', 'href="/css/'
$content = $content -replace 'src="images/', 'src="/images/'
$content = $content -replace 'href="images/', 'href="/images/'
$content = $content -replace 'srcset="images/', 'srcset="/images/'
$content = $content -replace 'src="js/', 'src="/js/'
$content = $content -replace 'src="videos/', 'src="/videos/'
$content = $content -replace ', images/', ', /images/'
$content = $content -replace ',images/', ',/images/'

# Extract title
$titleMatch = [regex]::Match($content, '<title>(.*?)</title>')
$title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { "Youtap Indonesia" }

# Extract description
$descMatch = [regex]::Match($content, '<meta content="(.*?)" name="description">')
$description = if ($descMatch.Success) { $descMatch.Groups[1].Value } else { "" }

# Extract head content
$headMatch = [regex]::Match($content, '(?s)<head>(.*?)</head>')
$headContent = if ($headMatch.Success) { $headMatch.Groups[1].Value } else { "" }

$headContent = $headContent -replace '(?s)<meta charset="[^"]*">\r?\n?', ''
$headContent = $headContent -replace '(?s)<title>.*?</title>\r?\n?', ''
$headContent = $headContent -replace '(?s)<meta content=".*?" name="description">\r?\n?', ''
$headContent = $headContent -replace '(?s)<meta content="width=device-width, initial-scale=1" name="viewport">\r?\n?', ''

# Extract body content
$bodyMatch = [regex]::Match($content, '(?s)<body[^>]*>(.*?)</body>')
$bodyContent = if ($bodyMatch.Success) { $bodyMatch.Groups[1].Value } else { "" }

# Create Astro content
$astroContent = @"
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="$title" description="$description">
  <Fragment slot="head">
$headContent
  </Fragment>

$bodyContent
</BaseLayout>
"@

New-Item -ItemType Directory -Force "src\pages" | Out-Null
Set-Content -Path "src\pages\spektacuan.astro" -Value $astroContent
