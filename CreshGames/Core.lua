local ADDON_NAME, addon = ...
_G.CreshGames = addon

addon.name = ADDON_NAME or "CreshGames"
addon.BUILD = addon.BUILD or {
    version = "0.1.0",
    schema = 1,
    interface = 20505,
    stage = "Scaffold",
}
addon.version = addon.BUILD.version
addon.schemaVersion = addon.BUILD.schema
addon.modules = addon.modules or {}

function addon:RegisterModule(name, module)
    name = tostring(name or "")
    if name == "" or type(module) ~= "table" then return module end
    module.version = module.version or self.version
    self.modules[name] = module
    return module
end

function addon:GetModule(name)
    return self.modules and self.modules[tostring(name or "")] or nil
end

addon:RegisterModule("Core", addon)

-- FeatureManager.lua stays in CreshChat; see CreshCollect/Core.lua for the same rationale.
function addon:IsFeatureEnabled(_)
    return true
end

-- CardDecks.lua calls CC:Print (nil-guarded with CC.Print, so this isn't strictly required,
-- but keeps deck-unlock chat messages working standalone instead of silently dropping them).
function addon:Print(message)
    print("|cff33ccffCreshGames|r " .. tostring(message))
end

local function GetTimestamp()
    if type(_G.GetServerTime) == "function" then return _G.GetServerTime() end
    if type(_G.time) == "function" then return _G.time() end
    if type(_G.GetTime) == "function" then return math.floor(_G.GetTime()) end
    return 0
end

local function EnsureDB()
    CreshGamesDB = CreshGamesDB or {}
    CreshGamesDB.schemaVersion = CreshGamesDB.schemaVersion or addon.schemaVersion
    CreshGamesDB.gameProgression = type(CreshGamesDB.gameProgression) == "table" and CreshGamesDB.gameProgression or {}
    addon.db = CreshGamesDB
end

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Top-level CreshChatDB.accountProgression fields that are entirely CreshGames-owned, per
-- Docs/DATA_SCHEMA.md and Docs/MIGRATION.md. Note gameProgression.achievements/exploration
-- are NOT here - those went to CreshCollect; only gameProgression.games (per-minigame level
-- records) belongs here, handled separately below since it's nested one level deeper.
local TOP_LEVEL_FIELDS = {
    "soloGames", "arcadeRewards", "gameHistory", "gameLeaderboards", "multiplayerStats", "cardDecks",
}

-- One-time, additive, non-destructive copy out of the still-installed CreshChat addon's
-- combined SavedVariables. Source data is never modified or deleted; only runs once
-- CreshChatDB is actually present this session. See Docs/MIGRATION.md "SavedVariables
-- migration map". Mirrors CreshCollect/Core.lua:MigrateAchievementsFromCreshChat.
local function MigrateFromCreshChat()
    if CreshGamesDB.migratedFromCreshChat then return end
    if type(CreshChatDB) ~= "table" then return end

    local sourceProgression = CreshChatDB.accountProgression
    if type(sourceProgression) ~= "table" then return end

    local copiedFields = 0
    for _, field in ipairs(TOP_LEVEL_FIELDS) do
        if CreshGamesDB[field] == nil and sourceProgression[field] ~= nil then
            CreshGamesDB[field] = DeepCopy(sourceProgression[field])
            copiedFields = copiedFields + 1
        end
    end

    local sourceGameProgression = sourceProgression.gameProgression
    if type(sourceGameProgression) == "table" and sourceGameProgression.games ~= nil
        and CreshGamesDB.gameProgression.games == nil then
        CreshGamesDB.gameProgression.games = DeepCopy(sourceGameProgression.games)
        copiedFields = copiedFields + 1
    end

    CreshGamesDB.migratedFromCreshChat = true
    CreshGamesDB.migratedFromCreshChatAt = GetTimestamp()
    CreshGamesDB.migratedFieldCount = copiedFields
end

-- TEMPORARY reverse compatibility bridge: BattlePass.lua/SoloGames.lua nil-guard calls into
-- CC.UI/CC.ThemeLibrary/CC.GameProgression/CC.state, which haven't moved out of CreshChat.
-- CC.Tetris/CC.Games/CC.SoloGames are self-registered locally; not forwarded.
-- Must run before BattlePass.lua's own PLAYER_LOGIN handler — guaranteed by CreshGames.toc
-- load order (Core.lua before BattlePass.lua).
-- REMOVE WHEN: UI.lua and Settings.lua move to their respective addons and their call sites
-- inside BattlePass.lua/SoloGames.lua are updated to use CreshGamesAPI instead.
local function LinkLegacyCreshChatModules()
    local legacy = _G.CreshChat
    if type(legacy) ~= "table" then return end
    addon.UI = legacy.UI
    addon.ThemeLibrary = legacy.ThemeLibrary
    addon.GameProgression = legacy.GameProgression
    addon.state = legacy.state
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == ADDON_NAME then
        EnsureDB()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        EnsureDB()
        MigrateFromCreshChat()
        LinkLegacyCreshChatModules()
        self:UnregisterEvent("PLAYER_LOGIN")
        _G.CRESH_GAMES_READY = true
        addon:Fire("CRESH_GAMES_READY")
    end
end)

-- ── Integration contract (Phase 7) ─────────────────────────────────────────────
-- Event dispatch (simple listener table; no external library needed on TBC Anniversary).
-- Other addons can call _G.CreshGames:On("CRESH_GAMES_READY", fn) before PLAYER_LOGIN fires,
-- or check _G.CRESH_GAMES_READY == true after the fact.
addon._listeners = addon._listeners or {}
function addon:On(event, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return end
    self._listeners[event] = self._listeners[event] or {}
    self._listeners[event][#self._listeners[event] + 1] = fn
end
function addon:Fire(event, ...)
    for _, fn in ipairs(self._listeners[event] or {}) do pcall(fn, ...) end
end

-- Detection helper per Docs/INTEGRATION-CONTRACT.md — TBC Anniversary may not have C_AddOns.
local function IsAddonLoaded(name)
    return (_G.C_AddOns and type(_G.C_AddOns.IsAddOnLoaded) == "function" and _G.C_AddOns.IsAddOnLoaded(name))
        or (type(_G.IsAddOnLoaded) == "function" and _G.IsAddOnLoaded(name))
        or false
end

-- Public API — small, versioned, read-mostly. See Docs/INTEGRATION-CONTRACT.md.
-- Never expose live SavedVariables table references; return copies or scalars only.
-- Fail safely: return nil, "reason" on bad input.
CreshGamesAPI = CreshGamesAPI or {}
CreshGamesAPI.version = 1
CreshGamesAPI.IsReady = function() return _G.CRESH_GAMES_READY == true end
CreshGamesAPI.IsAddonLoaded = IsAddonLoaded

-- Award main Battle Pass XP from an external source (Progression.lua, AchievementExpansion.lua).
-- Replaces the three direct cross-calls identified in Docs/INTEGRATION-CONTRACT.md Phase 7.
function CreshGamesAPI.AddMainPassXP(amount, source)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return nil, "amount must be a positive number" end
    local pass = addon:GetModule("BattlePass")
    if not pass or type(pass.AddPassXP) ~= "function" then return nil, "BattlePass not available" end
    return pass:AddPassXP(amount, tostring(source or "External"), true)
end

-- Award main Battle Pass Cresh Coins from an external source.
function CreshGamesAPI.AddMainPassCoins(amount, source)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return nil, "amount must be a positive number" end
    local pass = addon:GetModule("BattlePass")
    if not pass or type(pass.AddCoins) ~= "function" then return nil, "BattlePass not available" end
    return pass:AddCoins(amount, tostring(source or "External"))
end

-- Record a WoW zone visit for the Dungeon Dwellers Battle Pass (zone-discovery award).
function CreshGamesAPI.RecordDungeonPassZone(zoneKey, zoneName)
    if type(zoneKey) ~= "string" or zoneKey == "" then return nil, "zoneKey must be a non-empty string" end
    local ddPass = addon:GetModule("DungeonDwellersPass")
    if not ddPass or type(ddPass.RecordZone) ~= "function" then return nil, "DungeonDwellersPass not available" end
    return ddPass:RecordZone(tostring(zoneKey), zoneName)
end

SLASH_CRESHGAMES1 = "/creshgames"
SLASH_CRESHGAMES2 = "/cgames"
SlashCmdList.CRESHGAMES = function(message)
    message = tostring(message or ""):lower():match("^%s*(.-)%s*$")
    if message == "status" then
        EnsureDB()
        if CreshGamesDB.migratedFromCreshChat then
            print(("|cff33ccffCreshGames|r migration: copied %d field(s) from CreshChatDB."):format(
                CreshGamesDB.migratedFieldCount or 0))
        elseif type(CreshChatDB) ~= "table" then
            print("|cff33ccffCreshGames|r migration: pending - CreshChat is not currently loaded this session.")
        else
            print("|cff33ccffCreshGames|r migration: pending - no game data found in CreshChatDB yet.")
        end
        return
    end
    print("|cff33ccffCreshGames|r v" .. addon.version .. ". Try '/cgames status'.")
end
