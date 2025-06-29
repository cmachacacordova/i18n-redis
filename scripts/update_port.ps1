param([string]$Tag)

if (-not $Tag) {
    Write-Host "Usage: update_port.ps1 <tag-or-commit>" -ForegroundColor Red
    exit 1
}

$repo = "https://github.com/cmachacacordova/i18n-redis.git"

# Try to resolve the tag/commit locally first to avoid network access
$commit = git rev-parse $Tag 2>$null
if ($LASTEXITCODE -ne 0) {
    $commitLine = git ls-remote $repo $Tag | Select-Object -First 1
    if ($commitLine) {
        $commit = $commitLine.Split()[0]
    } else {
        $commit = $Tag
    }
}

$tempTar = New-TemporaryFile
git archive --format=tar $commit -o $tempTar
$sha512 = (Get-FileHash $tempTar -Algorithm SHA512).Hash.ToLower()
Remove-Item $tempTar

# Update portfile.cmake
$content = Get-Content portfile.cmake -Raw
$content = [regex]::Replace(
    $content,
    '(?m)^(\s*REF )[0-9a-f]+( # tag )[^\r\n]+',
    { param($m) "$($m.Groups[1].Value)$commit$($m.Groups[2].Value)$Tag" }
)
$content = [regex]::Replace(
    $content,
    '(?m)^(\s*SHA512 )[0-9a-f]{128}',
    { param($m) "$($m.Groups[1].Value)$sha512" }
)
Set-Content portfile.cmake $content

# Update version in vcpkg.json
$version = $Tag.TrimStart('v')
$j = Get-Content vcpkg.json -Raw
$replacement = '"version-string": "' + $version + '"'
$j = $j -replace '"version-string"\s*:\s*"[^"]+"', $replacement
Set-Content vcpkg.json $j

Write-Host "Updated to $Tag"
Write-Host "Commit: $commit"
Write-Host "SHA512: $sha512"

