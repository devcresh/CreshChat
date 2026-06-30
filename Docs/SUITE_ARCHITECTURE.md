# CreshSuite Architecture (Target)

This document describes the target three-addon architecture for the CreshChat → CreshSuite split. It is the forward-looking companion to the existing [ARCHITECTURE.md](ARCHITECTURE.md), which still describes the current (pre-split) single-addon module layout and remains accurate until the relevant code is extracted.

## Repo / install layout

This git repository's root is `Interface/AddOns/CreshChat` (CreshChat's live development folder). Rather than nesting CreshChat inside a wrapper folder — which would break its direct live-test relationship with the WoW client — the suite is laid out as:

```
CreshChat/                  <- this repo root, unchanged, still the live CreshChat addon
├── CreshChat.toc
├── Core.lua, UI.lua, ...   <- existing chat/games/achievement files (not yet split)
├── CreshCollect/            <- new subfolder, its own addon
│   ├── CreshCollect.toc
│   └── Core.lua
├── CreshGames/               <- new subfolder, its own addon
│   ├── CreshGames.toc
│   └── Core.lua
├── Docs/
└── CreshSuite.code-workspace
```

`Interface/AddOns/CreshCollect` and `Interface/AddOns/CreshGames` are Windows directory junctions pointing at this repo's `CreshCollect/` and `CreshGames/` subfolders, so WoW loads all three addons independently while everything stays version-controlled in one repository. CreshChat itself may be nested into its own `CreshChat/` subfolder later as a deliberate, separately-reviewed step — it is intentionally left alone for now to avoid one large, risky move of thousands of tracked files (including binary art/audio) before any real extraction has happened.

## Three addons

- **CreshChat** — chat windows, tabs, history, filters, whispers, party/raid/guild/officer/instance/say/yell/emote/system channels, Friends, Voice, chat notifications, chat input/commands, chat appearance/settings.
- **CreshCollect** — achievements (base + 300 TBC expansion + class-only), achievement categories/criteria/progress/rewards/notifications, collection statistics, world-content tracking that feeds achievements (kills, zones, professions, quest turn-ins for WoW purposes), combat statistics.
- **CreshGames** — Dungeon Dwellers, solo/multiplayer minigames (Tetris, Chess, cards, Frogger, etc.), Battle Pass (main + Dungeon Dwellers), game progression/currency (Cresh Coins), minions/enemies/classes/equipment/armour, game audio, game-specific UI.

## Current → target module ownership

| Current file | Target addon | Notes |
|---|---|---|
| `Core.lua` (chat capture, BN routing, history) | CreshChat | Generic module-registry/migration boilerplate currently shared from here must be duplicated into each addon's own `Core.lua` |
| `Friends.lua`, `Voice.lua`, `Quest.lua`, `SoundLibrary.lua`, `Themes.lua` | CreshChat | |
| `UI.lua` | **split** | Console/Friends/conversation UI → CreshChat; game drawer, card pop-outs, BP bar → CreshGames |
| `Settings.lua` | **split** | One panel today (General + Modules tabs spanning all three domains) → three independent settings UIs |
| `FeatureManager.lua` | retired/absorbed | Its purpose (suppress chat OR games OR achievements within one installed addon) is replaced by the split itself |
| `Progression.lua` | CreshCollect | WoW kill/zone/walking tracking that feeds achievements; currently calls `BattlePass:AddPassXP` and `DungeonDwellersPass:RecordZone` directly — must become event-based (see [INTEGRATION-CONTRACT.md](INTEGRATION-CONTRACT.md)) |
| `Achievements.lua`, `AchievementExpansion.lua`, `ClassAchievements.lua`, `DungeonAchievements.lua` | CreshCollect | `AchievementExpansion:RecordQuestTurnIn` also calls `BattlePass:AddPassXP` directly — same bridge issue |
| `CombatTracker.lua` | CreshCollect | Feeds `Achievements` stats |
| `ProgressRouter.lua` | CreshCollect | Already polices WOW↔DUNGEON_DWELLER progress routing — becomes the seed of the formal integration contract |
| `ProgressHub.lua` | **split** (needs inspection) | Likely houses achievement browser + Battle Pass display together |
| `Games.lua`, `SoloGames.lua` | **split** | `SoloGames.lua` mixes minigame engines with the Dungeon Collection/Statistics/Pass UI |
| `BattlePass.lua`, `DungeonDwellersProgression.lua` | CreshGames | |
| `CardDeckLibrary.lua`, `CardDecks.lua`, `TetrisThemes.lua`, `ChessTextureManifest.lua`, `DungeonDwellersAssetSets.lua`, `DungeonCrawlerContent.lua`, `GameAudio.lua` | CreshGames | |
| `Quality.lua` | CreshChat (verify scope) | Named for chat-storage repair/clamping; confirm it doesn't also clamp `accountProgression` before moving |
| `Developer.lua` | split into 3 thin copies | Diagnostic tooling, acceptable duplication per the shared-code rules |

## Namespacing

Today every module shares one global table: `Core.lua` does `local ADDON_NAME, addonTable = ...; local CC = addonTable or {}; _G.CreshChat = CC`, and all 28 other files call `CC:RegisterModule(name, module)` into it. The target state gives each addon its own private `addon` table via `local addonName, addon = ...`, exposed only as `_G.CreshChat` / `_G.CreshCollect` / `_G.CreshGames` respectively — no more shared `CC` global once the split is complete.

## SavedVariables

See [SavedVariables migration map](MIGRATION.md#savedvariables-migration-map) in MIGRATION.md for the full field-by-field plan. Summary: today everything lives in one `CreshChatDB` (schema 79). The target is `CreshChatDB`, `CreshCollectDB`, `CreshGamesDB`, each with its own `schemaVersion`, split along the existing internal boundaries (`accountChat.*` → CreshChat, `accountProgression.gameProgression.achievements.*` → CreshCollect, `accountProgression.{soloGames,arcadeRewards,gameHistory,gameLeaderboards,multiplayerStats,cardDecks}` → CreshGames).
