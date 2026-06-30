local _, CC = ...
if not CC then return end

local Pass = {
    version = CC.version,
    maxLevel = 100,
}
CC.DungeonDwellersPass = Pass
if CC.RegisterModule then CC:RegisterModule("DungeonDwellersPass", Pass) end

local floor, max, min = math.floor, math.max, math.min
local upper = string.upper
local format = string.format

local function now()
    if type(_G.time) == "function" then return _G.time() end
    if type(_G.GetTime) == "function" then return floor(_G.GetTime()) end
    return 0
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    return max(low, min(high, value))
end

local function showDungeonPassToast(title, message, key)
    if not CC.UI then return end
    if CC.UI.ShowDungeonPassToast then
        CC.UI:ShowDungeonPassToast(title, message, key)
    elseif CC.UI.ShowBattlePassToast then
        CC.UI:ShowBattlePassToast(title, message, "BATTLEPASS", key)
    end
end

local function dungeonSave()
    if not CC.db then return nil end
    CC.db.soloGames = type(CC.db.soloGames) == "table" and CC.db.soloGames or {}
    CC.db.soloGames.dungeon = type(CC.db.soloGames.dungeon) == "table" and CC.db.soloGames.dungeon or {}
    return CC.db.soloGames.dungeon
end

function Pass:Ensure()
    local dungeon = dungeonSave()
    if not dungeon then return nil end

    dungeon.classStats = type(dungeon.classStats) == "table" and dungeon.classStats or {}
    if not dungeon.classStatsMigrated and next(dungeon.classStats) == nil and (tonumber(dungeon.runs) or 0) > 0 then
        local classKey = upper(tostring(dungeon.class or "PALADIN"))
        if classKey == "" then classKey = "PALADIN" end
        dungeon.classStats[classKey] = {
            runs = floor(max(0, tonumber(dungeon.runs) or 0)),
            maxRoom = floor(max(0, tonumber(dungeon.bestRoom) or tonumber(dungeon.bestLevel) or 0)),
            kills = floor(max(0, tonumber(dungeon.kills) or 0)),
            bosses = floor(max(0, tonumber(dungeon.bosses) or 0)),
            highScore = floor(max(0, tonumber(dungeon.highScore) or 0)),
            deaths = 0,
        }
    end
    dungeon.classStatsMigrated = true
    dungeon.unlockedMinions = type(dungeon.unlockedMinions) == "table" and dungeon.unlockedMinions or {}
    dungeon.minionRecruitsByType = type(dungeon.minionRecruitsByType) == "table" and dungeon.minionRecruitsByType or {}
    dungeon.unlockedMinionSkins = type(dungeon.unlockedMinionSkins) == "table" and dungeon.unlockedMinionSkins or {}
    dungeon.minionSkinRecruits = type(dungeon.minionSkinRecruits) == "table" and dungeon.minionSkinRecruits or {}
    dungeon.discoveredItems = type(dungeon.discoveredItems) == "table" and dungeon.discoveredItems or {}
    dungeon.battlePass = type(dungeon.battlePass) == "table" and dungeon.battlePass or {}

    local save = dungeon.battlePass
    save.xp = floor(max(0, tonumber(save.xp) or 0))
    save.claimed = type(save.claimed) == "table" and save.claimed or {}
    save.buffs = type(save.buffs) == "table" and save.buffs or {}
    save.activity = type(save.activity) == "table" and save.activity or {}
    save.visitedZones = type(save.visitedZones) == "table" and save.visitedZones or {}
    save.achievements = type(save.achievements) == "table" and save.achievements or {}
    save.recent = type(save.recent) == "table" and save.recent or {}

    local activity = save.activity
    activity.mobKills = floor(max(0, tonumber(activity.mobKills) or 0))
    activity.dungeonKills = floor(max(0, tonumber(activity.dungeonKills) or 0))
    activity.quests = floor(max(0, tonumber(activity.quests) or 0))
    activity.zones = floor(max(0, tonumber(activity.zones) or 0))
    activity.achievements = floor(max(0, tonumber(activity.achievements) or 0))

    local buffKeys = { "maxHP", "attack", "minionPower", "regenRoom", "regenTurn", "bossDamage", "extraDieChance", "coinBonus" }
    for _, key in ipairs(buffKeys) do save.buffs[key] = floor(max(0, tonumber(save.buffs[key]) or 0)) end
    return save, dungeon
end

function Pass:GetNextLevelCost(level)
    level = floor(clamp(level, 1, self.maxLevel))
    return 40 + ((level - 1) * 4)
end

function Pass:GetCumulativeXP(level)
    level = floor(clamp(level, 1, self.maxLevel))
    local completed = level - 1
    return completed * 40 + (4 * completed * (completed - 1)) / 2
end

function Pass:GetLevelFromXP(xp)
    xp = floor(max(0, tonumber(xp) or 0))
    local level = 1
    while level < self.maxLevel and xp >= self:GetCumulativeXP(level + 1) do level = level + 1 end
    return level
end

function Pass:GetProgress()
    local save = self:Ensure()
    if not save then return 1, 0, 40, 0 end
    local level = self:GetLevelFromXP(save.xp)
    if level >= self.maxLevel then return level, 1, 1, 1 end
    local base = self:GetCumulativeXP(level)
    local needed = self:GetNextLevelCost(level)
    local current = max(0, save.xp - base)
    return level, current, needed, clamp(current / max(1, needed), 0, 1)
end

local function addBuff(reward, key, value, label)
    reward.buffs[#reward.buffs + 1] = { key = key, value = value, label = label }
end

function Pass:GetReward(level)
    level = floor(clamp(level, 1, self.maxLevel))
    local reward = {
        level = level,
        coins = level == 100 and 500 or (10 + floor((level - 1) / 5) * 5),
        buffs = {},
        title = "Delver Rank " .. tostring(level),
        -- F1: reward routing metadata
        sourceSystem = "DUNGEON_DWELLER_BATTLE_PASS",
        sourceId     = "DDPASS_LEVEL_" .. level,
        targetGame   = "DUNGEON_DWELLER",
    }

    local cycle = level % 20
    if cycle == 5 then addBuff(reward, "maxHP", 1, "+1 starting Max HP") end
    if cycle == 10 then addBuff(reward, "minionPower", 1, "+1 recruited minion power") end
    if cycle == 15 then addBuff(reward, "regenRoom", 1, "+1 HP after each cleared room") end
    if cycle == 0 then addBuff(reward, "attack", 1, "+1 starting Attack") end

    if level == 25 or level == 50 or level == 75 or level == 100 then
        addBuff(reward, "bossDamage", 1, "+1 damage against bosses")
    end
    if level == 40 or level == 80 then
        addBuff(reward, "extraDieChance", 5, "+5% chance to roll a bonus die")
    end
    if level == 50 or level == 100 then
        addBuff(reward, "coinBonus", 5, "+5% Dungeon coin rewards")
    end
    if level == 60 or level == 100 then
        addBuff(reward, "regenTurn", 1, "+1 HP regeneration after enemy turns")
    end

    if #reward.buffs > 0 then reward.title = "Delver Boon " .. tostring(level) end
    return reward
end

function Pass:GetRewardText(level)
    local reward = self:GetReward(level)
    local parts = { "+" .. tostring(reward.coins) .. " Cresh Coins" }
    for _, buff in ipairs(reward.buffs) do parts[#parts + 1] = buff.label end
    return table.concat(parts, " · ")
end

function Pass:IsLevelReached(level)
    local save = self:Ensure()
    return save and save.xp >= self:GetCumulativeXP(level) or false
end

function Pass:IsRewardClaimed(level)
    local save = self:Ensure()
    return save and save.claimed[tostring(level)] == true or false
end

function Pass:GetBuffs()
    local save = self:Ensure()
    return save and save.buffs or {}
end

function Pass:RefreshUI()
    if CC.SoloGames and CC.SoloGames.views and CC.SoloGames.views.DUNGEON then
        local view = CC.SoloGames.views.DUNGEON
        if view.RefreshDwellersPanel then view:RefreshDwellersPanel() end
        if view.Refresh then view:Refresh() end
    end
    if CC.UI and CC.UI.RefreshConsoleEconomy then CC.UI:RefreshConsoleEconomy() end
end

function Pass:AddXP(amount, source, activityKey, silent, isSimulation)
    if isSimulation == true then return 0 end
    local save = self:Ensure()
    amount = floor(max(0, tonumber(amount) or 0))
    if not save or amount <= 0 then return 0 end

    local previousLevel = self:GetLevelFromXP(save.xp)
    save.xp = save.xp + amount
    local newLevel = self:GetLevelFromXP(save.xp)
    if activityKey and save.activity[activityKey] ~= nil then
        save.activity[activityKey] = save.activity[activityKey] + 1
    end
    save.recent = { source = tostring(source or "Activity"), xp = amount, level = newLevel, at = now() }

    if not silent and newLevel > previousLevel then
        showDungeonPassToast(
            "Dungeon Dwellers Pass Level " .. tostring(newLevel),
            "+" .. tostring(amount) .. " XP · " .. self:GetRewardText(newLevel) .. " ready",
            "DDPASS:LEVEL:" .. tostring(newLevel)
        )
    end

    self:RefreshUI()
    return amount, previousLevel, newLevel
end

-- DORMANT: no callers anywhere in the codebase as of the 2026-06-30 audit.
-- Predates the WOW/DD isolation fix (the "WoW mob defeated" label is a holdover
-- from before Progression:RecordKill was rerouted to call BattlePass:AddPassXP
-- directly instead of going through the DD Pass). Do not wire this to a live
-- WOW_MOB_KILL event without a sourceGame guard matching
-- AchievementExpansion:RecordBoss's pattern -- as written it has none, so any
-- caller would award DD progression for plain WoW kills.
function Pass:RecordMobKill()
    return self:AddXP(1, "WoW mob defeated", "mobKills", false)
end

function Pass:RecordDungeonKill(isBoss)
    return self:AddXP(isBoss and 5 or 2, isBoss and "Dungeon boss defeated" or "Dungeon enemy defeated", "dungeonKills", false)
end

-- DORMANT: no callers anywhere in the codebase as of the 2026-06-30 audit.
-- Same pre-isolation-fix origin as RecordMobKill above; has no sourceGame guard.
function Pass:RecordQuest(questID, title)
    return self:AddXP(15, title or ("Quest " .. tostring(questID or "completed")), "quests", false)
end

function Pass:RecordZone(zoneKey, zoneName)
    local save = self:Ensure()
    if not save then return 0 end
    zoneKey = tostring(zoneKey or zoneName or "")
    if zoneKey == "" or save.visitedZones[zoneKey] then return 0 end
    save.visitedZones[zoneKey] = { name = tostring(zoneName or zoneKey), at = now() }
    return self:AddXP(20, "New zone: " .. tostring(zoneName or zoneKey), "zones", false)
end

-- DORMANT: no callers anywhere in the codebase as of the 2026-06-30 audit.
-- Same pre-isolation-fix origin as RecordMobKill above; has no sourceGame guard.
function Pass:RecordAchievement(achievementID, name)
    local save = self:Ensure()
    if not save then return 0 end
    local key = tostring(achievementID or name or "")
    if key == "" or save.achievements[key] then return 0 end
    save.achievements[key] = { name = tostring(name or ("Achievement " .. key)), at = now() }
    return self:AddXP(50, "Achievement: " .. tostring(name or key), "achievements", false)
end

function Pass:ClaimReward(level, silent)
    local save = self:Ensure()
    level = floor(clamp(level, 1, self.maxLevel))
    if not save or not self:IsLevelReached(level) then return false end
    local key = tostring(level)
    if save.claimed[key] then return false end

    local reward = self:GetReward(level)
    save.claimed[key] = true
    if CC.BattlePass and CC.BattlePass.AddCoins then CC.BattlePass:AddCoins(reward.coins, "DUNGEON_PASS") end
    for _, buff in ipairs(reward.buffs) do
        local value = tonumber(buff.value) or 0
        save.buffs[buff.key] = floor(max(0, tonumber(save.buffs[buff.key]) or 0)) + value
        local view = CC.SoloGames and CC.SoloGames.views and CC.SoloGames.views.DUNGEON
        if view and view.frame and view.frame.IsShown and view.frame:IsShown() and not view.dead then
            if buff.key == "maxHP" then
                view.maxHP = (view.maxHP or 1) + value
                view.hp = min(view.maxHP, (view.hp or 0) + value)
            elseif buff.key == "attack" then
                view.attack = (view.attack or 1) + value
            elseif buff.key == "minionPower" then
                for _, minion in ipairs(view.minions or {}) do minion.power = (minion.power or 1) + value end
                if view.minionOffer then view.minionOffer.power = (view.minionOffer.power or 1) + value end
            end
        end
    end
    save.recent = { source = "Level " .. tostring(level) .. " reward claimed", coins = reward.coins, level = level, at = now() }

    if not silent then
        showDungeonPassToast(
            "Dungeon Dwellers reward claimed",
            "Level " .. tostring(level) .. " · " .. self:GetRewardText(level),
            "DDPASS:CLAIM:" .. tostring(level)
        )
    end
    self:RefreshUI()
    return true
end

function Pass:ClaimAllAvailable()
    local claimed, coins = 0, 0
    for level = 1, self.maxLevel do
        if self:IsLevelReached(level) and not self:IsRewardClaimed(level) then
            local reward = self:GetReward(level)
            if self:ClaimReward(level, true) then
                claimed = claimed + 1
                coins = coins + reward.coins
            end
        end
    end
    if claimed > 0 then
        showDungeonPassToast(
            "Dungeon Dwellers rewards claimed",
            tostring(claimed) .. " rewards · +" .. tostring(coins) .. " Cresh Coins",
            "DDPASS:CLAIMALL:" .. tostring(now())
        )
    end
    self:RefreshUI()
    return claimed, coins
end

function Pass:GetActivitySummary()
    local save = self:Ensure()
    local a = save and save.activity or {}
    return {
        mobKills = a.mobKills or 0,
        dungeonKills = a.dungeonKills or 0,
        quests = a.quests or 0,
        zones = a.zones or 0,
        achievements = a.achievements or 0,
    }
end

local eventFrame = CreateFrame("Frame")
local function safeRegister(event)
    if eventFrame and eventFrame.RegisterEvent then pcall(eventFrame.RegisterEvent, eventFrame, event) end
end
safeRegister("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Pass:Ensure()
    end
end)
