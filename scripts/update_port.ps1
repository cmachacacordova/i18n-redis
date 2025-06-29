param([string]$Tag)

if (-not $Tag) {
    Write-Host "Usage: update_port.ps1 <tag-or-commit>" -ForegroundColor Red
    exit 1
}

$repo = "https://github.com/cmachacacordova/i18n-redis.git"

$commit = (git ls-remote $repo $Tag | Select-Object -First 1).Split()[0]
if (-not $commit) {
    $commit = $Tag
}

$tempTar = New-TemporaryFile
git archive --format=tar $commit -o $tempTar
$sha512 = (Get-FileHash $tempTar -Algorithm SHA512).Hash.ToLower()
Remove-Item $tempTar

# Update portfile.cmake
$content = Get-Content portfile.cmake -Raw
$content = $content -replace 'REF [0-9a-f]+ # tag [^ ]+', "REF $commit # tag $Tag"
$content = $content -replace 'SHA512 [0-9a-f]{128}', "SHA512 $sha512"
Set-Content portfile.cmake $content

# Update version in vcpkg.json
$version = $Tag.TrimStart('v')
$j = Get-Content vcpkg.json -Raw
$j = $j -replace '"version-string"\s*:\s*"[^"]+"', '"version-string": "' + $version + '"'
Set-Content vcpkg.json $j

Write-Host "Updated to $Tag"
Write-Host "Commit: $commit"
Write-Host "SHA512: $sha512"

