#Requires -Version 5.1
<#
.SYNOPSIS
    Validates all three CreshSuite addon directories.

.DESCRIPTION
    Checks for each addon:
      - TOC file exists
      - Every TOC-declared Lua file exists on disk
      - No zero-byte Lua files
      - No orphaned Lua files (on disk but not in TOC)
      - No duplicate SavedVariables across addons
    Cross-addon checks:
      - No Lua file reads another addon's SavedVariables table directly
      - No forbidden WoW-unsupported API calls (require, io, os, package)
    Media checks:
      - Interface\AddOns\... path strings in Lua files resolve to real files

.NOTES
    Run from any directory; the script locates the repo root from its own path.
    Exit code 0 = all checks passed (warnings are non-fatal).
    Exit code 1 = one or more errors found.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

# Parent of CreshChat/ in the AddOns folder — used for media path resolution
$AddOnsRoot = Split-Path -Parent $RepoRoot

$Addons = @(
    [ordered]@{ Name = "CreshChat";    Dir = $RepoRoot;                              Toc = "CreshChat.toc";    ExpectedSV = "CreshChatDB"    }
    [ordered]@{ Name = "CreshCollect"; Dir = (Join-Path $RepoRoot "CreshCollect");   Toc = "CreshCollect.toc"; ExpectedSV = "CreshCollectDB" }
    [ordered]@{ Name = "CreshGames";   Dir = (Join-Path $RepoRoot "CreshGames");     Toc = "CreshGames.toc";   ExpectedSV = "CreshGamesDB"   }
)

$Errors   = [System.Collections.Generic.List[string]]::new()
$Warnings = [System.Collections.Generic.List[string]]::new()

function Fail { param([string]$msg) $script:Errors.Add("  [FAIL] $msg") }
function Warn { param([string]$msg) $script:Warnings.Add("  [WARN] $msg") }
function Pass { param([string]$msg) Write-Host "  [OK]   $msg" -ForegroundColor Green }

# ---------------------------------------------------------------------------
# 1. Per-addon TOC + file existence checks
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== CreshSuite Addon Validator ===" -ForegroundColor Cyan
Write-Host "    Repo: $RepoRoot"

$AllSavedVars = [ordered]@{}   # sv-name -> addon-name

foreach ($addon in $Addons) {
    Write-Host ""
    Write-Host "-- $($addon.Name) --" -ForegroundColor Yellow

    $addonDir = $addon.Dir
    $tocPath  = Join-Path $addonDir $addon.Toc

    if (-not (Test-Path $addonDir)) {
        Fail "$($addon.Name) directory not found: $addonDir"
        $addon.DeclaredLua = @()
        continue
    }

    if (-not (Test-Path $tocPath)) {
        Fail "TOC not found: $($addon.Toc)"
        $addon.DeclaredLua = @()
        continue
    }
    Pass "TOC exists: $($addon.Toc)"

    # Parse TOC for file list and SavedVariables
    $declaredLua  = [System.Collections.Generic.List[string]]::new()
    $tocSavedVars = [System.Collections.Generic.List[string]]::new()

    foreach ($line in (Get-Content $tocPath)) {
        $t = $line.Trim()
        if ($t -match '^\s*##\s*SavedVariables\s*:\s*(.+)') {
            foreach ($sv in ($Matches[1].Trim() -split '\s*,\s*')) {
                if ($sv -ne "") { $tocSavedVars.Add($sv.Trim()) }
            }
        }
        if ($t -eq "" -or $t.StartsWith("#")) { continue }
        $declaredLua.Add($t.Replace("\", "/"))
    }

    # TOC-declared files must exist and be non-empty
    $missingCount = 0
    foreach ($rel in $declaredLua) {
        $abs = Join-Path $addonDir $rel
        if (-not (Test-Path $abs)) {
            Fail "$($addon.Name): TOC-declared file missing: $rel"
            $missingCount++
        } elseif ((Get-Item $abs).Length -eq 0) {
            Fail "$($addon.Name): Zero-byte Lua file: $rel"
            $missingCount++
        }
    }
    if ($missingCount -eq 0) { Pass "All $($declaredLua.Count) TOC-declared files exist" }

    # Orphaned Lua files (at addon root only; subdirs are media/asset folders)
    $rootLuaFiles = Get-ChildItem -Path $addonDir -Filter "*.lua" -File |
                    Select-Object -ExpandProperty Name
    $declaredNames = $declaredLua | ForEach-Object { Split-Path $_ -Leaf }
    foreach ($f in $rootLuaFiles) {
        if ($f -notin $declaredNames) {
            Warn "$($addon.Name): Orphaned Lua file (not in TOC): $f"
        }
    }
    if ($rootLuaFiles.Count -gt 0) { Pass "$($rootLuaFiles.Count) root Lua file(s) checked for orphans" }

    # SavedVariables declared in TOC must match expected name
    if ($tocSavedVars.Count -eq 0) {
        Warn "$($addon.Name): No SavedVariables declared in TOC"
    } else {
        if ($tocSavedVars -notcontains $addon.ExpectedSV) {
            Fail "$($addon.Name): Expected SavedVariables '$($addon.ExpectedSV)' not declared. Found: $($tocSavedVars -join ', ')"
        } else {
            Pass "SavedVariables: $($tocSavedVars -join ', ')"
        }
        foreach ($sv in $tocSavedVars) {
            if ($AllSavedVars.Contains($sv)) {
                Fail "Duplicate SavedVariables '$sv': declared by both $($AllSavedVars[$sv]) and $($addon.Name)"
            } else {
                $AllSavedVars[$sv] = $addon.Name
            }
        }
    }

    $addon.DeclaredLua   = $declaredLua
    $addon.TocSavedVars  = $tocSavedVars
}

# ---------------------------------------------------------------------------
# 2. Cross-addon SavedVariables boundary check
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "-- Cross-addon boundary checks --" -ForegroundColor Yellow

foreach ($addon in $Addons) {
    if (-not $addon.DeclaredLua -or $addon.DeclaredLua.Count -eq 0) { continue }

    # Other addons' SavedVariables names
    $otherDBs = $AllSavedVars.Keys | Where-Object { $AllSavedVars[$_] -ne $addon.Name }

    foreach ($rel in $addon.DeclaredLua) {
        $abs = Join-Path $addon.Dir $rel
        if (-not (Test-Path $abs)) { continue }
        $content = Get-Content $abs -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        foreach ($otherDB in $otherDBs) {
            # CreshCollect/Core.lua and CreshGames/Core.lua are allowed to read CreshChatDB
            # in their one-time, additive migration functions.
            $isMigrationExempt = ($rel -eq "Core.lua" -and $otherDB -eq "CreshChatDB" -and
                                   ($addon.Name -eq "CreshCollect" -or $addon.Name -eq "CreshGames"))
            if (-not $isMigrationExempt -and $content -match "\b$([regex]::Escape($otherDB))\b") {
                Warn "$($addon.Name)/$rel accesses $otherDB (another addon's SavedVariables)"
            }
        }
    }
}
Pass "Boundary check complete"

# ---------------------------------------------------------------------------
# 3. Forbidden WoW Lua patterns
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "-- Forbidden API patterns --" -ForegroundColor Yellow

$ForbiddenPatterns = @(
    @{ Regex = '\brequire\s*\('; Label = "require()" }
    @{ Regex = '\bio\.';          Label = "io.*" }
    @{ Regex = '\bos\.(time|date|clock|execute|exit|getenv|remove|rename|tmpname|setlocale|difftime)\b'; Label = "os.*" }
    @{ Regex = '\bpackage\.';     Label = "package.*" }
    @{ Regex = '\bdofile\s*\(';   Label = "dofile()" }
    @{ Regex = '\bloadfile\s*\('; Label = "loadfile()" }
)

$forbiddenFound = 0
foreach ($addon in $Addons) {
    if (-not $addon.DeclaredLua -or $addon.DeclaredLua.Count -eq 0) { continue }
    foreach ($rel in $addon.DeclaredLua) {
        $abs = Join-Path $addon.Dir $rel
        if (-not (Test-Path $abs)) { continue }
        $lineNum = 0
        foreach ($line in (Get-Content $abs)) {
            $lineNum++
            if ($line.Trim().StartsWith("--")) { continue }  # skip full-line comments
            foreach ($fp in $ForbiddenPatterns) {
                if ($line -match $fp.Regex) {
                    Fail "$($addon.Name)/$rel line $lineNum : forbidden $($fp.Label)"
                    $forbiddenFound++
                }
            }
        }
    }
}
if ($forbiddenFound -eq 0) { Pass "No forbidden API patterns found" }

# ---------------------------------------------------------------------------
# 4. Media path reference check
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "-- Media path references --" -ForegroundColor Yellow

# WoW Lua files embed media paths like:
#   "Interface\\AddOns\\CreshGames\\Media\\Games\\Cards\\..."
# The Lua source has literal \\ (two chars). PowerShell reads these as-is.
# Regex uses \\\\ to match two consecutive backslashes.
$mediaRegex = [regex]'Interface\\\\AddOns\\\\(\w+)\\\\([^"'']+)'

$mediaErrors = 0
foreach ($addon in $Addons) {
    if (-not $addon.DeclaredLua -or $addon.DeclaredLua.Count -eq 0) { continue }
    foreach ($rel in $addon.DeclaredLua) {
        $abs = Join-Path $addon.Dir $rel
        if (-not (Test-Path $abs)) { continue }
        $content = Get-Content $abs -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $hits = $mediaRegex.Matches($content)
        foreach ($hit in $hits) {
            $addonInPath = $hit.Groups[1].Value
            # Strip trailing quote/space and convert \\ -> \
            $assetRel = $hit.Groups[2].Value.TrimEnd('"', "'", ' ').Replace('\\', '\')
            $assetAbs = Join-Path (Join-Path $AddOnsRoot $addonInPath) $assetRel
            if (-not (Test-Path $assetAbs)) {
                Warn "$($addon.Name)/$rel : missing media: Interface\AddOns\$addonInPath\$assetRel"
                $mediaErrors++
            }
        }
    }
}
if ($mediaErrors -eq 0) { Pass "All resolved media references exist" }

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan

if ($Warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings ($($Warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $Warnings) { Write-Host $w -ForegroundColor Yellow }
}

if ($Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors ($($Errors.Count)):" -ForegroundColor Red
    foreach ($e in $Errors) { Write-Host $e -ForegroundColor Red }
    Write-Host ""
    Write-Host "VALIDATION FAILED" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "VALIDATION PASSED  ($($Warnings.Count) warning(s), 0 errors)" -ForegroundColor Green
    exit 0
}
