#Requires -Version 5.1
<#
.SYNOPSIS
    Packages all three CreshSuite addons into separate release ZIPs.

.DESCRIPTION
    Produces three ZIP files in the release/ directory:
        release/CreshChat-v<ver>-TBC-Anniversary.zip
        release/CreshCollect-v<ver>-TBC-Anniversary.zip
        release/CreshGames-v<ver>-TBC-Anniversary.zip

    Each ZIP contains only:
      - The addon's TOC file
      - Every Lua file declared in the TOC
      - The addon's Media/ subdirectory (if present)
    Development files (Docs/, tools/, ArtSource/, .git, etc.) are never included.

.NOTES
    Run from any directory; the script locates the repo root from its own path.
    Requires PowerShell 5.1+ and the built-in Compress-Archive cmdlet.
    Run validate-addons.ps1 first to confirm no errors before packaging.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot   = Split-Path -Parent $ScriptDir
$ReleaseDir = Join-Path $RepoRoot "release"
$StageDir   = Join-Path $RepoRoot "_staging_suite_"

# Addon definitions ---------------------------------------------------------
# Dir      : root directory for this addon's files
# Toc      : TOC filename (relative to Dir)
# HasMedia : whether a Media/ subfolder should be bundled
$AddonDefs = @(
    [ordered]@{
        Name     = "CreshChat"
        Dir      = $RepoRoot
        Toc      = "CreshChat.toc"
        HasMedia = $true
    }
    [ordered]@{
        Name     = "CreshCollect"
        Dir      = (Join-Path $RepoRoot "CreshCollect")
        Toc      = "CreshCollect.toc"
        HasMedia = $false    # no Media/ subfolder yet
    }
    [ordered]@{
        Name     = "CreshGames"
        Dir      = (Join-Path $RepoRoot "CreshGames")
        Toc      = "CreshGames.toc"
        HasMedia = $true
    }
)

# Forbidden file extensions / path fragments — never land in a release ZIP
$ForbiddenExts = @('.exe', '.dll', '.bat', '.cmd', '.msi', '.ps1', '.zip', '.rar', '.7z')
$ForbiddenPathFragments = @(
    '.git', '.gitignore', '.gitattributes', '.vscode', '.idea',
    'ArtSource', 'Docs/', 'tools/', 'quarantine/', '_staging_',
    'CLAUDE.md', 'AGENTS.md', 'QC_REPORT', 'FILE_MANIFEST',
    'SavedVariables', 'WTF'
)

function Test-ForbiddenPath {
    param([string]$rel)
    $ext = [System.IO.Path]::GetExtension($rel).ToLower()
    if ($ext -in $ForbiddenExts) { return $true }
    foreach ($frag in $ForbiddenPathFragments) {
        if ($rel -match [regex]::Escape($frag)) { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
function Build-AddonZip {
    param(
        [string]$AddonName,
        [string]$AddonDir,
        [string]$TocName,
        [bool]  $IncludeMedia,
        [string]$ReleaseDir,
        [string]$StageRoot
    )

    Write-Host ""
    Write-Host "=== Packaging $AddonName ===" -ForegroundColor Cyan

    $tocPath = Join-Path $AddonDir $TocName
    if (-not (Test-Path $tocPath)) {
        Write-Error "${AddonName}: TOC not found at: $tocPath"
        return $null
    }

    # Read version from TOC
    $version = $null
    foreach ($line in (Get-Content $tocPath)) {
        if ($line -match '^\s*##\s*Version\s*:\s*(.+)') {
            $version = $Matches[1].Trim(); break
        }
    }
    if (-not $version) {
        Write-Error "${AddonName}: Could not read ## Version from $TocName"
        return $null
    }

    $zipName = "${AddonName}-v${version}-TBC-Anniversary.zip"
    $zipPath = Join-Path $ReleaseDir $zipName
    Write-Host "  Version : $version"
    Write-Host "  Output  : $zipPath"

    # Build file list
    $files = [System.Collections.Generic.List[string]]::new()   # relative to AddonDir

    # TOC file itself
    $files.Add($TocName)

    # TOC-declared Lua files
    foreach ($line in (Get-Content $tocPath)) {
        $t = $line.Trim()
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $rel = $t.Replace("\", "/")
        $abs = Join-Path $AddonDir $rel
        if (-not (Test-Path $abs)) {
            Write-Error "${AddonName}: TOC-declared file missing: $rel"
            return $null
        }
        if ((Get-Item $abs).Length -eq 0) {
            Write-Error "${AddonName}: Zero-byte Lua file: $rel"
            return $null
        }
        if (Test-ForbiddenPath $rel) {
            Write-Error "${AddonName}: TOC entry matches forbidden pattern: $rel"
            return $null
        }
        $files.Add($rel)
    }
    Write-Host "  TOC-declared files : $($files.Count)"

    # Media/ subtree
    $mediaCount = 0
    if ($IncludeMedia) {
        $mediaDir = Join-Path $AddonDir "Media"
        if (Test-Path $mediaDir) {
            $mediaItems = Get-ChildItem -Path $mediaDir -Recurse -File
            foreach ($item in $mediaItems) {
                $rel = $item.FullName.Substring($AddonDir.Length).TrimStart('\', '/').Replace('\', '/')
                if (Test-ForbiddenPath $rel) {
                    Write-Warning "  Skipping forbidden media: $rel"
                    continue
                }
                $files.Add($rel)
                $mediaCount++
            }
            Write-Host "  Media files        : $mediaCount"
        } else {
            Write-Warning "  No Media/ directory found for $AddonName"
        }
    }

    Write-Host "  Total files        : $($files.Count)"

    # Build staging subdirectory for this addon
    $addonStageDir = Join-Path $StageRoot $AddonName
    if (Test-Path $addonStageDir) { Remove-Item -Recurse -Force $addonStageDir }
    New-Item -ItemType Directory -Path $addonStageDir | Out-Null

    foreach ($rel in $files) {
        $src    = Join-Path $AddonDir $rel
        $dst    = Join-Path $addonStageDir $rel
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item -Path $src -Destination $dst -Force
    }

    # Safety: no path traversal in staging
    foreach ($f in (Get-ChildItem -Path $addonStageDir -Recurse -File)) {
        if ($f.Name -match '\.\.' -or $f.Name.StartsWith('/') -or $f.Name.StartsWith('\')) {
            Write-Error "Path traversal entry in staging: $($f.FullName)"
            return $null
        }
    }

    # Create ZIP
    if (-not (Test-Path $ReleaseDir)) {
        New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
    }
    if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
    # Compress the folder itself so the ZIP top-level is AddonName/ (not flat files)
    Compress-Archive -Path $addonStageDir -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host "  ZIP created: $zipName"

    # Validate ZIP structure
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $entries = $zip.Entries

        # All top-level entries must live under AddonName/
        $topFolders = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($entry in $entries) {
            $seg = $entry.FullName.Replace('\', '/').Split('/')[0]
            if ($seg -ne "") { $topFolders.Add($seg) | Out-Null }
        }
        if ($topFolders.Count -ne 1 -or -not $topFolders.Contains($AddonName)) {
            Write-Error "ZIP top-level folder is wrong. Found: $($topFolders -join ', ')"
            return $null
        }

        # TOC must be present
        $hasToc = $entries | Where-Object { $_.FullName.Replace('\','/') -eq "$AddonName/$TocName" }
        if (-not $hasToc) {
            Write-Error "$AddonName/$TocName not found inside ZIP"
            return $null
        }

        # No executables, archives, traversal
        foreach ($entry in $entries) {
            $n   = $entry.FullName.Replace('\','/')
            $ext = [System.IO.Path]::GetExtension($entry.Name).ToLower()
            if ($n -match '\.\.' -or $n.StartsWith('/')) {
                Write-Error "Path traversal in ZIP: $($entry.FullName)"; return $null
            }
            if ($ext -in @('.exe','.dll','.bat','.cmd','.msi','.ps1')) {
                Write-Error "Executable in ZIP: $($entry.FullName)"; return $null
            }
            if ($ext -in @('.zip','.rar','.7z')) {
                Write-Error "Nested archive in ZIP: $($entry.FullName)"; return $null
            }
            if ($n -match 'SavedVariables|WTF') {
                Write-Error "SavedVariables data in ZIP: $($entry.FullName)"; return $null
            }
        }

        $entryCount       = $entries.Count
        $uncompressedSize = ($entries | Measure-Object -Property Length -Sum).Sum
    } finally {
        $zip.Dispose()
    }

    $zipInfo       = Get-Item $zipPath
    $compressedSize = $zipInfo.Length
    $hash          = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash

    Write-Host "  Entries            : $entryCount"
    Write-Host ("  Uncompressed       : {0:N2} MB" -f ($uncompressedSize / 1MB))
    Write-Host ("  Compressed         : {0:N2} MB" -f ($compressedSize / 1MB))
    Write-Host "  SHA-256            : $hash"

    return [ordered]@{
        Name             = $AddonName
        ZipName          = $zipName
        ZipPath          = $zipPath
        Version          = $version
        EntryCount       = $entryCount
        UncompressedSize = $uncompressedSize
        CompressedSize   = $compressedSize
        SHA256           = $hash
    }
}
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "=== CreshSuite Package Builder ===" -ForegroundColor Cyan
Write-Host "    Repo    : $RepoRoot"
Write-Host "    Release : $ReleaseDir"

# Clean and create staging root
if (Test-Path $StageDir) { Remove-Item -Recurse -Force $StageDir }
New-Item -ItemType Directory -Path $StageDir | Out-Null

$Results = [System.Collections.Generic.List[object]]::new()
$Failed  = $false

foreach ($def in $AddonDefs) {
    $result = Build-AddonZip `
        -AddonName    $def.Name `
        -AddonDir     $def.Dir `
        -TocName      $def.Toc `
        -IncludeMedia $def.HasMedia `
        -ReleaseDir   $ReleaseDir `
        -StageRoot    $StageDir

    if ($null -eq $result) {
        $Failed = $true
    } else {
        $Results.Add($result)
    }
}

# Clean staging
Remove-Item -Recurse -Force $StageDir

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Build Summary ===" -ForegroundColor Cyan

foreach ($r in $Results) {
    Write-Host ""
    Write-Host "  $($r.Name) v$($r.Version)" -ForegroundColor Green
    Write-Host "    ZIP     : $($r.ZipName)"
    Write-Host "    SHA-256 : $($r.SHA256)"
}

# Write machine-readable stats for CI/audit use
if (-not (Test-Path $ReleaseDir)) { New-Item -ItemType Directory -Path $ReleaseDir | Out-Null }
$statsPath = Join-Path $ReleaseDir "suite_build_stats.txt"
$lines = @("# CreshSuite build stats  $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "")
foreach ($r in $Results) {
    $lines += "[$($r.Name)]"
    $lines += "ZIP=$($r.ZipPath)"
    $lines += "VERSION=$($r.Version)"
    $lines += "FILE_COUNT=$($r.EntryCount)"
    $lines += "UNCOMPRESSED_BYTES=$($r.UncompressedSize)"
    $lines += "COMPRESSED_BYTES=$($r.CompressedSize)"
    $lines += "SHA256=$($r.SHA256)"
    $lines += ""
}
$lines | Set-Content -Path $statsPath -Encoding UTF8

if ($Failed) {
    Write-Host ""
    Write-Host "BUILD FAILED for one or more addons." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "ALL BUILDS SUCCESSFUL" -ForegroundColor Green
    exit 0
}
