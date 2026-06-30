local ADDON_NAME, addon = ...
_G.CreshCollect = addon

addon.name = ADDON_NAME or "CreshCollect"
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

-- FeatureManager.lua stays in CreshChat and isn't moving here; the multi-domain
-- suppression it provided is replaced by the addon split itself (CreshCollect's
-- achievement tracking is simply "on" whenever the addon is enabled). Achievement
-- files call CC:IsFeatureEnabled(key) unconditionally in several places, so this
-- stub must exist even though there's nothing left to gate.
function addon:IsFeatureEnabled(_)
    return true
end

local function GetTimestamp()
    if type(_G.GetServerTime) == "function" then return _G.GetServerTime() end
    if type(_G.time) == "function" then return _G.time() end
    if type(_G.GetTime) == "function" then return math.floor(_G.GetTime()) end
    return 0
end

local function EnsureDB()
    CreshCollectDB = CreshCollectDB or {}
    CreshCollectDB.schemaVersion = CreshCollectDB.schemaVersion or addon.schemaVersion
    CreshCollectDB.gameProgression = type(CreshCollectDB.gameProgression) == "table" and CreshCollectDB.gameProgression or {}
    addon.db = CreshCollectDB
end

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Fields owned by Achievements.lua/AchievementExpansion.lua/ClassAchievements.lua under
-- CC.db.gameProgression.achievements (== CreshChatDB.accountProgression.gameProgression.achievements
-- in the old monolith), per Docs/DATA_SCHEMA.md and Achievements.lua's progressionRoot().
local ACHIEVEMENT_FIELDS = {
    "unlocked", "stats", "uniqueBosses", "professionRanks", "visitedZones",
    "totalCoins", "totalPassXP", "expansion", "classProgress",
}

-- One-time, additive, non-destructive copy of achievement data out of the still-installed
-- CreshChat addon's combined SavedVariables. Source data is never modified or deleted; this
-- only runs once CreshChatDB is actually present this session (CreshChat must be enabled at
-- least once after CreshCollect is installed for this to have anything to copy). Writes into
-- CC.db.gameProgression.achievements (CreshCollectDB.gameProgression.achievements) so the
-- moved Achievements.lua's progressionRoot() finds it at the exact same relative path it
-- always has. See Docs/MIGRATION.md "SavedVariables migration map".
local function MigrateAchievementsFromCreshChat()
    if CreshCollectDB.migratedFromCreshChat then return end
    if type(CreshChatDB) ~= "table" then return end

    local sourceProgression = CreshChatDB.accountProgression
    local sourceGameProgression = type(sourceProgression) == "table" and sourceProgression.gameProgression or nil
    local sourceAchievements = type(sourceGameProgression) == "table" and sourceGameProgression.achievements or nil
    if type(sourceAchievements) ~= "table" then return end

    CreshCollectDB.gameProgression.achievements = type(CreshCollectDB.gameProgression.achievements) == "table"
        and CreshCollectDB.gameProgression.achievements or {}
    local dest = CreshCollectDB.gameProgression.achievements

    local copiedFields = 0
    for _, field in ipairs(ACHIEVEMENT_FIELDS) do
        if dest[field] == nil and sourceAchievements[field] ~= nil then
            dest[field] = DeepCopy(sourceAchievements[field])
            copiedFields = copiedFields + 1
        end
    end

    CreshCollectDB.migratedFromCreshChat = true
    CreshCollectDB.migratedFromCreshChatAt = GetTimestamp()
    CreshCollectDB.migratedFieldCount = copiedFields
end

-- TEMPORARY reverse compatibility bridge: Achievements.lua nil-guards calls into
-- CC.BattlePass / CC.UI / CC.GameAudio / CC.GameProgression / CC.ProgressRouter /
-- CC.currentProfile. CC.BattlePass/CC.GameAudio now live in CreshGames; CC.UI/CC.GameProgression
-- /CC.ProgressRouter/CC.currentProfile still in CreshChat. CreshChat's own shim (Core.lua)
-- first forwards the CreshGames ones into _G.CreshChat, so legacy.X below sees them all.
-- REMOVE WHEN: DungeonAchievements.lua and Progression.lua move (removing their CreshChat
-- references), and Achievements.lua's own reward/UI call sites switch to CreshGamesAPI/
-- CreshCollectAPI events instead of direct CC.BattlePass/CC.UI access.
local function LinkLegacyCreshChatModules()
    local legacy = _G.CreshChat
    if type(legacy) ~= "table" then return end
    addon.BattlePass = legacy.BattlePass
    addon.UI = legacy.UI
    addon.GameAudio = legacy.GameAudio
    addon.GameProgression = legacy.GameProgression
    addon.ProgressRouter = legacy.ProgressRouter
    addon.currentProfile = legacy.currentProfile
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == ADDON_NAME then
        EnsureDB()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        -- All addons' SavedVariables are guaranteed loaded by PLAYER_LOGIN, regardless of
        -- CreshChat/CreshCollect relative load order, so the migration runs here rather than
        -- in CreshCollect's own ADDON_LOADED handler.
        EnsureDB()
        MigrateAchievementsFromCreshChat()
        LinkLegacyCreshChatModules()
        self:UnregisterEvent("PLAYER_LOGIN")
        _G.CRESH_COLLECT_READY = true
        addon:Fire("CRESH_COLLECT_READY")
    end
end)

-- ── Integration contract (Phase 7) ─────────────────────────────────────────────
addon._listeners = addon._listeners or {}
function addon:On(event, fn)
    if type(event) ~= "string" or type(fn) ~= "function" then return end
    self._listeners[event] = self._listeners[event] or {}
    self._listeners[event][#self._listeners[event] + 1] = fn
end
function addon:Fire(event, ...)
    for _, fn in ipairs(self._listeners[event] or {}) do pcall(fn, ...) end
end

local function IsAddonLoaded(name)
    return (_G.C_AddOns and type(_G.C_AddOns.IsAddOnLoaded) == "function" and _G.C_AddOns.IsAddOnLoaded(name))
        or (type(_G.IsAddOnLoaded) == "function" and _G.IsAddOnLoaded(name))
        or false
end

CreshCollectAPI = CreshCollectAPI or {}
CreshCollectAPI.version = 1
CreshCollectAPI.IsReady = function() return _G.CRESH_COLLECT_READY == true end
CreshCollectAPI.IsAddonLoaded = IsAddonLoaded

SLASH_CRESHCOLLECT1 = "/creshcollect"
SLASH_CRESHCOLLECT2 = "/ccollect"
SlashCmdList.CRESHCOLLECT = function(message)
    message = tostring(message or ""):lower():match("^%s*(.-)%s*$")
    if message == "status" then
        EnsureDB()
        if CreshCollectDB.migratedFromCreshChat then
            print(("|cff33ccffCreshCollect|r migration: copied %d field(s) from CreshChatDB."):format(
                CreshCollectDB.migratedFieldCount or 0))
        elseif type(CreshChatDB) ~= "table" then
            print("|cff33ccffCreshCollect|r migration: pending - CreshChat is not currently loaded this session.")
        else
            print("|cff33ccffCreshCollect|r migration: pending - no achievement data found in CreshChatDB yet.")
        end
        return
    end
    print("|cff33ccffCreshCollect|r v" .. addon.version .. ". Try '/ccollect status'.")
end
