# CreshSuite Integration Contract (Optional)

CreshChat, CreshCollect, and CreshGames must each load and function with the other two absent, disabled, or not yet updated. This document defines the *optional* extension points the three addons may use to talk to each other when all are present. None of this is required for any addon to function — every API/event consumer must treat the producer as potentially missing.

## Detection

```lua
local function IsAddonLoaded(name)
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name)
        or IsAddOnLoaded and IsAddOnLoaded(name) -- TBC Anniversary fallback, pre-C_AddOns API
        or false
end
```

This helper is also exposed as `CreshGamesAPI.IsAddonLoaded(name)` for convenience. Do not assume the modern `C_AddOns` namespace exists on TBC Anniversary without checking.

## Public APIs (implemented)

Each addon exposes a small, versioned, read-mostly API global. No addon may read or write another addon's private SavedVariables or module tables directly.

```lua
CreshChatAPI    = CreshChatAPI    or {}; CreshChatAPI.version    = 1
CreshCollectAPI = CreshCollectAPI or {}; CreshCollectAPI.version = 1
CreshGamesAPI   = CreshGamesAPI   or {}; CreshGamesAPI.version   = 1
```

Rules for every public API function: validate all arguments; never return a live reference to an internal SavedVariables table; fail safely (`nil, "reason"`); bump `version` only on breaking changes.

### CreshGamesAPI functions (Phase 7)

- `CreshGamesAPI.IsReady()` — returns `true` after CreshGames' `PLAYER_LOGIN` handler completes.
- `CreshGamesAPI.IsAddonLoaded(name)` — TBC-compatible `IsAddOnLoaded` wrapper.
- `CreshGamesAPI.AddMainPassXP(amount, source)` — award XP to the main Battle Pass; returns the amount awarded, or `nil, "reason"` on failure.
- `CreshGamesAPI.AddMainPassCoins(amount, source)` — award Cresh Coins; same return convention.
- `CreshGamesAPI.RecordDungeonPassZone(zoneKey, zoneName)` — record a WoW zone visit for the Dungeon Dwellers Battle Pass; returns the XP awarded, or `nil, "reason"`.

### CreshCollectAPI / CreshChatAPI (stubs for Phase 7)

Both tables exist with `version = 1` and `IsReady()`. Substantive functions (e.g. achievement lookups) are future work — add them only when a concrete consumer exists.

## Readiness events (implemented)

Mechanism: `addon:On(event, fn)` registers a callback on the producing addon's listener table; `addon:Fire(event, ...)` dispatches it. A plain `_G.CRESH_*_READY = true` global is also set so late-loading consumers can check the flag rather than pre-registering.

| Event | Fired by | Status |
|---|---|---|
| `CRESH_CHAT_READY` | CreshChat `Core.lua` on `PLAYER_LOGIN` | **Implemented** |
| `CRESH_COLLECT_READY` | CreshCollect `Core.lua` on `PLAYER_LOGIN` | **Implemented** |
| `CRESH_GAMES_READY` | CreshGames `Core.lua` on `PLAYER_LOGIN` | **Implemented** |
| `CRESH_ACHIEVEMENT_EARNED` | CreshCollect (future) | Future work |
| `CRESH_GAME_REWARD_GRANTED` | CreshGames (future) | Future work |
| `CRESH_BATTLEPASS_LEVEL_CHANGED` | CreshGames (future) | Future work |
| `CRESH_CURRENCY_CHANGED` | CreshGames (future) | Future work |

## Replacing the existing direct cross-calls (implemented)

Three direct cross-calls replaced with `_G.CreshGamesAPI` calls (Phase 7):

1. `Progression.lua:RecordKill` — `CC.BattlePass:AddPassXP(1, "WoW mob defeated", true)` → `_G.CreshGamesAPI.AddMainPassXP(1, "WoW mob defeated")`.
2. `CreshCollect/AchievementExpansion.lua:RecordQuestTurnIn` — `CC.BattlePass:AddPassXP(5, "WoW quest", true)` → `_G.CreshGamesAPI.AddMainPassXP(5, "WoW quest")`.
3. `Progression.lua:CheckArea` — `CC.DungeonDwellersPass:RecordZone(key, name)` (gated by the now-obsolete `CC:IsFeatureEnabled("games")`) → `_G.CreshGamesAPI.RecordDungeonPassZone(key, name)` (gated by CreshGames being loaded, the correct independent check).

## Notification fallback rule

When CreshChat is not installed, CreshCollect and CreshGames must notify the player via `DEFAULT_CHAT_FRAME:AddMessage(...)` or a standalone toast/frame — never by assuming CreshChat's UI frames exist.

## What this migration does NOT build

No fourth addon, no mandatory dependency, no `RequiredDeps` referencing a sibling addon, no deep two-way data sync. The future events (`CRESH_ACHIEVEMENT_EARNED`, etc.) are designed above but not yet fired. Firing them requires `Achievements.lua` to call `addon:Fire(...)` on unlock, and interested addons to register listeners — that work awaits Phase 8 or a follow-up pass.
