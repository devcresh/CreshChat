# CreshSuite — Development Workspace Design (Phase 0)

**Status:** Decision recorded. Implementation begins in Phase 1.
**Decision:** Primary relocation to `D:\CreshSuite\` (approved 2026-07-03).
**Branch:** `folder-fixing`
**Produced:** 2026-07-03

---

## Background

The git repository currently lives at:

```
D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshChat\
```

That is also the live CreshChat addon directory that WoW loads at runtime. Dev files
(`.git\`, `AGENTS.md`, `CLAUDE.md`, `tools\`, `ArtSource\`, `Docs\`) co-reside with
the runtime Lua/TGA/ogg files that WoW actually reads.

There are also two unversioned standalone addon folders already present in AddOns:
- `...\AddOns\CreshGames\`  — stub, not tracked by git
- `...\AddOns\CreshCollect\` — stub, not tracked by git

The `tripple-addon` branch explored one approach (keep repo at CreshChat root, add
CreshGames/ and CreshCollect/ as subfolders, use junctions). That work is preserved on
that branch. This document describes the preferred design going forward and a junction
fallback if relocation is not immediately feasible.

---

## 1. Proposed monorepo folder structure

```
D:\CreshSuite\                          ← git root  (outside AddOns)
│
├── .git\
├── .gitignore
├── .gitattributes
├── .vscode\
│
├── AGENTS.md                           ← suite-level dev instructions
├── CLAUDE.md                           ← identical content (AI assistant config)
│
├── ArtSource\                          ← design source files, never deployed
├── Docs\                               ← architecture, migration, contract docs
├── quarantine\                         ← accidental-file holding area
│
├── release\                            ← built ZIPs (gitignored at root level)
│   ├── CreshChat-v0.2.3-TBC-Anniversary.zip
│   ├── CreshGames-v0.1.0-TBC-Anniversary.zip
│   └── CreshCollect-v0.1.0-TBC-Anniversary.zip
│
├── tools\
│   ├── Build-CurseForgeRelease.ps1     ← updated to package all three addons
│   ├── Deploy-Local.ps1                ← new: copy source to live AddOn folders
│   └── validate-addons.ps1             ← lint/TOC validation (from tripple-addon)
│
├── CreshChat\                          ← addon 1 runtime source
│   ├── CreshChat.toc
│   ├── Core.lua
│   ├── UI.lua
│   ├── Settings.lua
│   ├── FeatureManager.lua
│   ├── NotificationCard.lua
│   ├── NotificationsAdapter.lua
│   ├── Notifications.lua
│   ├── Friends.lua, Voice.lua, Quest.lua, Themes.lua, SoundLibrary.lua
│   ├── ProgressRouter.lua, ProgressHub.lua
│   ├── Quality.lua, Developer.lua, CombatTracker.lua
│   └── Media\
│
├── CreshGames\                         ← addon 2 runtime source
│   ├── CreshGames.toc
│   ├── Core.lua         (future — currently in CreshGames\CreshGames.lua stub)
│   ├── Games.lua        (to be extracted from CreshChat\Games.lua)
│   ├── SoloGames.lua    (to be extracted)
│   ├── BattlePass.lua   (to be extracted)
│   ├── DungeonDwellersProgression.lua, DungeonCrawlerContent.lua, ...
│   ├── CardDeckLibrary.lua, CardDecks.lua, TetrisThemes.lua, ...
│   ├── GameAudio.lua, ChessTextureManifest.lua, DungeonDwellersAssetSets.lua
│   └── Media\
│
└── CreshCollect\                       ← addon 3 runtime source
    ├── CreshCollect.toc
    ├── Core.lua         (future — currently a stub)
    ├── Achievements.lua        (to be extracted)
    ├── AchievementExpansion.lua (to be extracted)
    ├── ClassAchievements.lua   (to be extracted)
    └── DungeonAchievements.lua (to be extracted)
```

### What moves where — at migration time

| Current location | Moves to | Note |
|---|---|---|
| `AddOns\CreshChat\*.lua` (chat/UI files) | `D:\CreshSuite\CreshChat\` | All files in bulk |
| `AddOns\CreshChat\Media\` | `D:\CreshSuite\CreshChat\Media\` | Large binary tree |
| `AddOns\CreshChat\Games.lua`, `SoloGames.lua`, ... | `D:\CreshSuite\CreshGames\` | After extraction phase |
| `AddOns\CreshChat\Achievements.lua`, ... | `D:\CreshSuite\CreshCollect\` | After extraction phase |
| `AddOns\CreshChat\.git\`, `tools\`, `ArtSource\`, `Docs\` | `D:\CreshSuite\` (already at root) | Dev-only files |
| `AddOns\CreshChat\AGENTS.md`, `CLAUDE.md` | `D:\CreshSuite\` | Suite-level instructions |
| `AddOns\CreshGames\` (standalone stub) | Replaced by deploy target | Unversioned copy removed |
| `AddOns\CreshCollect\` (standalone stub) | Replaced by deploy target | Unversioned copy removed |

---

## 2. Three live deployment destinations

| Addon | Live path |
|---|---|
| **CreshChat** | `D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshChat\` |
| **CreshGames** | `D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshGames\` |
| **CreshCollect** | `D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshCollect\` |

These are WoW's loadable addon folders. After relocation the source repo at `D:\CreshSuite\`
has no overlap with any of these paths. `Deploy-Local.ps1` bridges the gap by copying
runtime files from the repo into the three destinations.

---

## 3. Safety rules for Deploy-Local.ps1

These rules govern the script that must be written in a later phase.

### Pre-flight checks (abort if any fail)

1. Detect if `Wow.exe` or `Wow_classic_era.exe` is running via `Get-Process`.
   If either is found, print an error and exit — writing to an open addon folder
   can corrupt WoW's memory-mapped files.
2. Verify the source subfolder for each requested addon contains its `.toc` file.
3. Parse each TOC and verify every declared file exists in the source tree before
   writing a single byte to any destination.

### Copy behaviour

4. **Allowlist-only**: copy only TOC-declared files plus the addon's own `Media\`
   subfolder. Never use directory mirroring (`robocopy /MIR`, `xcopy /S`, etc.).
5. **Never delete** files from the destination that are not in the source.
   WoW may leave `*.bak` or version files in the live folder; these must not be removed.
6. **SavedVariables untouchable**: if a `SavedVariables\` directory exists inside
   any destination, skip it silently and log a warning.

### Denied files (never deploy)

7. The following path fragments must never land in a live destination:
   `.git\`, `tools\`, `ArtSource\`, `Docs\`, `quarantine\`, `release\`,
   `AGENTS.md`, `CLAUDE.md`, `*.ps1`, `_staging_*`, `*.bak`, `*.log`,
   `*.tmp`, `*.zip`, `*.rar`, `*.7z`, `*.exe`, `*.dll`, `*.bat`, `*.cmd`.

### Reliability

8. **Dry-run mode** (`-WhatIf`): list every intended write without touching disk.
   Output must be stable and diffable between runs.
9. **Per-addon granularity**: accept a `-Addon` parameter (`CreshChat`,
   `CreshGames`, `CreshCollect`); default deploys all three.
10. **Post-deploy verification**: after each addon, compare the file count and
    cumulative byte size of what was written against the TOC allowlist.
    Exit non-zero if the counts diverge.
11. **Timestamped log**: write every file operation to
    `%TEMP%\CreshSuite-Deploy-<yyyyMMdd-HHmmss>.log`. Print the log path on exit.
12. **Repo-relative paths only**: locate the repo root from the script's own path
    (`Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)`) so
    the script works from any working directory.

---

## 4. Required AGENTS.md changes

The following sections in AGENTS.md must be updated when the workspace is migrated.
No changes are applied in this phase.

### Section: Project
Replace the "Live development folder" line with:

```
Git repository:     D:\CreshSuite\
Live addon roots:
  CreshChat         D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshChat\
  CreshGames        D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshGames\
  CreshCollect      D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns\CreshCollect\
```

### Section: Addon source directories (new section, after Project)

```
Source subfolders in the repo:
  CreshChat\     — chat windows, UI, notifications, friends, voice, settings
  CreshGames\    — multiplayer/solo games, Battle Pass, dungeon games, audio
  CreshCollect\  — achievements, collection tracking, progression statistics
```

### Section: Local deployment (new section, before Scope)

```
To push source changes to WoW:
  cd D:\CreshSuite
  .\tools\Deploy-Local.ps1             # deploys all three addons
  .\tools\Deploy-Local.ps1 -Addon CreshChat  # deploys one addon only
  .\tools\Deploy-Local.ps1 -WhatIf     # dry run, no writes

Never edit files inside the live AddOns directories.
Always edit in the repo and run Deploy-Local.ps1.
```

### Section: Scope (add three rules)

- "Never edit files inside the live WoW AddOns directories. Always edit source
  in `D:\CreshSuite\` and deploy."
- "CreshChat, CreshGames and CreshCollect must each load if the other two
  are absent, disabled, or not yet installed."
- "Cross-addon calls must use the `CreshChatAPI` / `CreshGamesAPI` /
  `CreshCollectAPI` optional-chaining pattern (see Docs/INTEGRATION-CONTRACT.md).
  No direct table access across addon boundaries."

### Section: WoW requirements (add two rules)

- "Each addon's TOC must declare only its own files. Do not reference files from
  sibling addon folders."
- "Do not add hard `Dependencies:` or `LoadWith:` TOC directives between the
  three suite addons. All inter-addon wiring must be optional."

---

## 5. Plan for keeping Git source separate from WoW's live AddOns directory

### Why separation matters

With the repo at `...\AddOns\CreshChat\`:
- `.git\` is inside a folder WoW scans at startup (harmless but fragile).
- A single mistaken TOC entry could cause WoW to try loading `AGENTS.md` or a
  tools script as Lua.
- Running `git reset` or `git clean` inside an open addon folder risks leaving
  the live files in an inconsistent state mid-session.
- There is no clear boundary between "repo file" and "deployed file" — every file
  is both simultaneously.

### Migration steps (to be executed in Phase 1)

```
Step 1  Create D:\CreshSuite\
Step 2  git clone --local . D:\CreshSuite   (preserves full history, no network)
        OR: move .git + files and git remote set-url origin <url>
Step 3  git mv all CreshChat runtime files into CreshChat\  subfolder
        (single commit; large but reviewable)
Step 4  Confirm D:\CreshSuite\CreshChat\CreshChat.toc exists
Step 5  Run Deploy-Local.ps1 -WhatIf to preview the first deployment
Step 6  Run Deploy-Local.ps1 to populate the three live AddOn folders
Step 7  Remove the old AddOns\CreshChat live folder
        (after verifying the deployed copy works in-game)
Step 8  Update VS Code workspace (CreshSuite.code-workspace) with new paths
Step 9  Update AGENTS.md, CLAUDE.md with new paths
Step 10 Verify CI / any remote scripts point to new location
```

Steps 3–4 (moving CreshChat's runtime files into a `CreshChat\` subfolder) are the
largest single operation: ~30 Lua files + all binaries. This should be one commit with
a clear message so the rename is visible in `git log --follow`.

CreshGames and CreshCollect are already stubs — moving them from
`CreshChat\CreshGames\` and `CreshChat\CreshCollect\` to `CreshSuite\CreshGames\` and
`CreshSuite\CreshCollect\` is straightforward.

---

## 6. Fallback plan using Windows junctions

Use this approach if relocating the repository is not feasible immediately (e.g.,
the path is referenced in external tools, or the large binary move requires a
dedicated review).

### Layout (junction approach)

The repo stays at `...\AddOns\CreshChat\`. CreshGames and CreshCollect are
subfolder trees inside it. The two standalone AddOn entries are NTFS directory
junctions pointing into those subfolders.

```
Interface\AddOns\
├── CreshChat\                  ← git root (unchanged location)
│   ├── .git\
│   ├── CreshChat.toc
│   ├── Core.lua, UI.lua, ...
│   ├── Media\
│   ├── CreshGames\             ← addon 2 source, inside repo
│   │   ├── CreshGames.toc
│   │   └── *.lua
│   └── CreshCollect\           ← addon 3 source, inside repo
│       ├── CreshCollect.toc
│       └── *.lua
│
├── CreshGames              ← NTFS junction → AddOns\CreshChat\CreshGames\
└── CreshCollect            ← NTFS junction → AddOns\CreshChat\CreshCollect\
```

WoW sees three independent addon folders. Edits to
`AddOns\CreshChat\CreshGames\*.lua` are immediately reflected through the junction
with no deploy step needed for CreshGames or CreshCollect.

### One-time junction creation (requires Administrator)

```powershell
# Run once in an elevated PowerShell prompt after WoW is closed.
$AddOns = "D:\Battlenet\World of Warcraft\_anniversary_\Interface\AddOns"
$Src    = "$AddOns\CreshChat"

# Remove any plain directories that currently exist at those paths
Remove-Item "$AddOns\CreshGames"   -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$AddOns\CreshCollect" -Recurse -Force -ErrorAction SilentlyContinue

# Create junctions
cmd /c mklink /J "$AddOns\CreshGames"   "$Src\CreshGames"
cmd /c mklink /J "$AddOns\CreshCollect" "$Src\CreshCollect"

# Verify
(Get-Item "$AddOns\CreshGames").LinkType      # should print: Junction
(Get-Item "$AddOns\CreshCollect").LinkType    # should print: Junction
```

### Junction limitations to accept

| Limitation | Impact |
|---|---|
| `.git\`, `AGENTS.md`, `tools\` still inside a WoW folder | Low: WoW ignores unknown files; but a bad TOC edit could expose them |
| CreshChat itself has no separation | Source edits to CreshChat are immediately live — no deploy step, but no safety buffer either |
| Requires Administrator once | Junction creation; subsequent edits do not need elevation |
| `tripple-addon` branch already executed this layout | Its work (full CreshGames\, CreshCollect\ code trees) can be rebased onto `folder-fixing` if this approach is chosen |

### When to use the fallback vs the primary plan

| Condition | Recommendation |
|---|---|
| Repo relocation reviewed and approved | Use primary plan (Section 5) |
| Large binary move needs a dedicated review window | Use junction fallback temporarily, plan relocation for next sprint |
| `tripple-addon` branch work is being merged | Merge first, then relocate; junctions provide a bridge |
| External CI or tools hardcode the current path | Use junction fallback until those references are updated |

---

## Summary

| Deliverable | Decision |
|---|---|
| Repo location (primary) | `D:\CreshSuite\` — outside AddOns entirely |
| Repo location (fallback) | Stay at `...\AddOns\CreshChat\`; use junctions for the other two |
| Three live destinations | `AddOns\CreshChat\`, `AddOns\CreshGames\`, `AddOns\CreshCollect\` |
| Deploy mechanism | `tools\Deploy-Local.ps1` — copy-based, allowlist-driven, WhatIf-capable |
| Admin required | No (copy deploy); yes, once (junction creation) |
| Dev files in AddOns | Zero after relocation; `.git + tools + docs` remain co-resident in fallback |
| Next phase action | Decide primary vs fallback, then implement in Phase 1 |
