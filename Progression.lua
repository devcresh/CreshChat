local ADDON_NAME, CC = ...
if not CC then return end

local Progression = {
    version = CC.version,
    stepYards = 0.75,
    pollInterval = 1.0,
}
CC.GameProgression = Progression
if CC.RegisterModule then CC:RegisterModule("GameProgression", Progression) end

local floor, min, max, sqrt = math.floor, math.min, math.max, math.sqrt
local upper, lower = string.upper, string.lower

local GAME_NAMES = {
    FROGGER = "Frogger",
    DUNGEON = "Dungeon Dweller",
    CHESS = "Chess",
    HOLDEM = "Texas Hold'em",
    BLACKJACK = "Blackjack",
    HIGHERLOWER = "Higher or Lower",
    TETRIS = "Tetris",
    PONG = "Pong",
}

local function now()
    if type(_G.GetServerTime) == "function" then return _G.GetServerTime() end
    if type(_G.time) == "function" then return _G.time() end
    if type(_G.GetTime) == "function" then return floor(_G.GetTime()) end
    return 0
end

local function mapIDForPlayer()
    if _G.C_Map and _G.C_Map.GetBestMapForUnit then
        local ok, mapID = pcall(_G.C_Map.GetBestMapForUnit, "player")
        if ok then return tonumber(mapID) end
    end
end

local function mapPosition(mapID)
    mapID = tonumber(mapID)
    if not mapID or not _G.C_Map or not _G.C_Map.GetPlayerMapPosition then return nil end
    local ok, point = pcall(_G.C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok or not point then return nil end
    local x, y
    if point.GetXY then x, y = point:GetXY() else x, y = point.x, point.y end
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x, y
end

local function currentAreaName()
    local subzone = type(_G.GetSubZoneText) == "function" and _G.GetSubZoneText() or ""
    local zone = type(_G.GetRealZoneText) == "function" and _G.GetRealZoneText() or (type(_G.GetZoneText) == "function" and _G.GetZoneText() or "")
    if subzone and subzone ~= "" then return subzone, zone end
    if zone and zone ~= "" then return zone, zone end
    return "Unknown Area", "Unknown Zone"
end

local function worldDistance(mapID, x1, y1, x2, y2)
    if _G.C_Map and _G.C_Map.GetWorldPosFromMapPos and _G.CreateVector2D then
        local ok1, continent1, world1 = pcall(_G.C_Map.GetWorldPosFromMapPos, mapID, _G.CreateVector2D(x1, y1))
        local ok2, continent2, world2 = pcall(_G.C_Map.GetWorldPosFromMapPos, mapID, _G.CreateVector2D(x2, y2))
        if ok1 and ok2 and world1 and world2 and continent1 == continent2 then
            local wx1, wy1, wx2, wy2
            if world1.GetXY then wx1, wy1 = world1:GetXY() else wx1, wy1 = world1.x, world1.y end
            if world2.GetXY then wx2, wy2 = world2:GetXY() else wx2, wy2 = world2.x, world2.y end
            if wx1 and wy1 and wx2 and wy2 then
                local dx, dy = wx2 - wx1, wy2 - wy1
                return sqrt(dx * dx + dy * dy)
            end
        end
    end
    local dx, dy = (x2 - x1) * 5000, (y2 - y1) * 3333
    return sqrt(dx * dx + dy * dy)
end

function Progression:Ensure()
    if not CC.db then return nil end
    CC.db.gameProgression = type(CC.db.gameProgression) == "table" and CC.db.gameProgression or {}
    local root = CC.db.gameProgression
    root.games = type(root.games) == "table" and root.games or {}
    root.exploration = type(root.exploration) == "table" and root.exploration or {}
    local exploration = root.exploration
    exploration.totalSteps = floor(max(0, tonumber(exploration.totalSteps) or 0))
    exploration.rewardedStepBlocks = floor(max(0, tonumber(exploration.rewardedStepBlocks) or 0))
    exploration.distanceRemainder = max(0, tonumber(exploration.distanceRemainder) or 0)
    exploration.visitedAreas = type(exploration.visitedAreas) == "table" and exploration.visitedAreas or {}
    exploration.visitedZones = type(exploration.visitedZones) == "table" and exploration.visitedZones or {}
    exploration.newAreas = floor(max(0, tonumber(exploration.newAreas) or 0))
    exploration.newZones = floor(max(0, tonumber(exploration.newZones) or 0))
    exploration.dungeonClears = floor(max(0, tonumber(exploration.dungeonClears) or 0))
    exploration.totalKills = floor(max(0, tonumber(exploration.totalKills) or 0))
    exploration.coins = floor(max(0, tonumber(exploration.coins) or 0))
    exploration.passXP = floor(max(0, tonumber(exploration.passXP) or 0))
    return root
end

function Progression:XPNeeded(level)
    level = floor(max(1, tonumber(level) or 1))
    return 80 + ((level - 1) * 20)
end

function Progression:GetGameRecord(game)
    local root = self:Ensure()
    if not root then return nil end
    game = upper(tostring(game or "GAME"))
    root.games[game] = type(root.games[game]) == "table" and root.games[game] or {}
    local record = root.games[game]
    record.level = floor(max(1, tonumber(record.level) or 1))
    record.xp = floor(max(0, tonumber(record.xp) or 0))
    record.plays = floor(max(0, tonumber(record.plays) or 0))
    record.wins = floor(max(0, tonumber(record.wins) or 0))
    record.draws = floor(max(0, tonumber(record.draws) or 0))
    record.losses = floor(max(0, tonumber(record.losses) or 0))
    record.lastPlayed = tonumber(record.lastPlayed) or 0
    local needed = self:XPNeeded(record.level)
    while record.xp >= needed do
        record.xp = record.xp - needed
        record.level = record.level + 1
        needed = self:XPNeeded(record.level)
    end
    return record
end

function Progression:GetProgress(game)
    local record = self:GetGameRecord(game)
    if not record then return 1, 0, 80, 0 end
    local needed = self:XPNeeded(record.level)
    return record.level, record.xp, needed, min(1, record.xp / max(1, needed)), record
end

function Progression:UpdateBar(bar, label, game)
    if not game or game == "" then
        if bar then bar:SetMinMaxValues(0, 1); bar:SetValue(0) end
        if label then label:SetText("") end
        return
    end
    local level, current, needed = self:GetProgress(game)
    if bar then
        bar:SetMinMaxValues(0, max(1, needed))
        bar:SetValue(current)
        if bar.Show then bar:Show() end
    end
    if label then label:SetText("LV " .. level .. "  " .. current .. "/" .. needed) end
end

function Progression:RefreshUI()
    if CC.Achievements and CC.Achievements.EvaluateAll then CC.Achievements:EvaluateAll(false) end
    if CC.SoloGames and CC.SoloGames.hub and CC.SoloGames.RefreshHub then CC.SoloGames:RefreshHub() end
    if CC.UI and CC.UI.gameDrawer and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
    if CC.SoloGames and CC.SoloGames.window then
        self:UpdateBar(CC.SoloGames.window.levelProgress, CC.SoloGames.window.levelText, CC.SoloGames.activeGame)
    end
    if CC.Games and CC.Games.gameWindow then
        self:UpdateBar(CC.Games.gameWindow.levelProgress, CC.Games.gameWindow.levelText, CC.Games.active and CC.Games.active.game)
    end
end

function Progression:AwardGameLevel(game, level)
    local coins, passXP = 10, 10
    if CC.BattlePass then
        if CC.BattlePass.AddCoins then CC.BattlePass:AddCoins(coins, "GAME") end
        if CC.BattlePass.AddPassXP then CC.BattlePass:AddPassXP(passXP, "GAME LEVEL") end
    end
    if CC.UI and CC.UI.ShowGameToast then
        CC.UI:ShowGameToast((GAME_NAMES[game] or game) .. " Level " .. level,
            "+" .. coins .. " Cresh Coins · +" .. passXP .. " Battle Pass XP", "SUCCESS", "GAMELEVEL:" .. tostring(game) .. ":" .. tostring(level))
    end
    if CC.GameAudio and CC.GameAudio.PlayEffect then CC.GameAudio:PlayEffect("LEVEL") end
    if CC.UI and CC.UI.RefreshConsoleEconomy then CC.UI:RefreshConsoleEconomy() end
    return coins, passXP
end

function Progression:AddGameXP(game, amount)
    game = upper(tostring(game or "GAME"))
    amount = floor(max(0, tonumber(amount) or 0))
    local record = self:GetGameRecord(game)
    if not record or amount <= 0 then return 0, 0 end
    local levels = 0
    record.xp = record.xp + amount
    local needed = self:XPNeeded(record.level)
    while record.xp >= needed do
        record.xp = record.xp - needed
        record.level = record.level + 1
        levels = levels + 1
        self:AwardGameLevel(game, record.level)
        needed = self:XPNeeded(record.level)
    end
    if game == "TETRIS" and levels > 0 and CC.Tetris and CC.Tetris.SyncUnlocks then CC.Tetris:SyncUnlocks(true) end
    self:RefreshUI()
    return amount, levels
end

function Progression:OnGameStarted(game, mode)
    if not CC:IsFeatureEnabled("gameProgression") then return 0 end
    game = upper(tostring(game or "GAME"))
    mode = upper(tostring(mode or "SOLO"))
    local gain = (mode == "MULTIPLAYER" or mode == "MULTI") and 10 or 5
    local record = self:GetGameRecord(game)
    if record then record.starts = floor(max(0, tonumber(record.starts) or 0)) + 1 end
    self:AddGameXP(game, gain)
    if CC.Achievements and CC.Achievements.EvaluateAll then CC.Achievements:EvaluateAll(false) end
    if CC.GameAudio and CC.GameAudio.PlayEffect then CC.GameAudio:PlayEffect("CLICK") end
    return gain
end

function Progression:OnGameCompleted(entry)
    if not CC:IsFeatureEnabled("gameProgression") then return 0 end
    if type(entry) ~= "table" then return 0 end
    local game = upper(tostring(entry.game or "GAME"))
    local mode = upper(tostring(entry.mode or "SOLO"))
    local result = upper(tostring(entry.result or "RUN"))
    local score = floor(max(0, tonumber(entry.score) or 0))
    local record = self:GetGameRecord(game)
    if not record then return 0 end

    local gain = 10
    if result == "WIN" then gain = 30; record.wins = record.wins + 1
    elseif result == "DRAW" then gain = 20; record.draws = record.draws + 1
    elseif result == "LOSS" then gain = 15; record.losses = record.losses + 1
    elseif result == "RUN" then gain = 15 + min(20, floor(score / 250)) end
    if mode == "MULTIPLAYER" or mode == "MULTI" then gain = gain * 2 end

    record.plays = record.plays + 1
    record.lastPlayed = now()
    self:AddGameXP(game, gain)
    if CC.Achievements and CC.Achievements.EvaluateAll then CC.Achievements:EvaluateAll(false) end
    if CC.GameAudio and CC.GameAudio.PlayEffect then
        if result == "WIN" then CC.GameAudio:PlayEffect("WIN") elseif result == "LOSS" then CC.GameAudio:PlayEffect("LOSS") else CC.GameAudio:PlayEffect("CLICK") end
    end
    return gain
end

function Progression:AwardExploration(coins, passXP, title, detail, showToast)
    coins = floor(max(0, tonumber(coins) or 0))
    passXP = floor(max(0, tonumber(passXP) or 0))
    local root = self:Ensure()
    if not root then return end
    local exploration = root.exploration
    if CC.BattlePass then
        if coins > 0 and CC.BattlePass.AddCoins then CC.BattlePass:AddCoins(coins, "EXPLORATION") end
        if passXP > 0 and CC.BattlePass.AddPassXP then CC.BattlePass:AddPassXP(passXP, "EXPLORATION", not showToast) end
    end
    exploration.coins = exploration.coins + coins
    exploration.passXP = exploration.passXP + passXP
    if showToast and CC.UI and CC.UI.ShowGameToast then
        CC.UI:ShowGameToast(title or "Explorer Reward",
            tostring(detail or "") .. " · +" .. coins .. " Cresh Coins · +" .. passXP .. " Battle Pass XP", "SUCCESS", "EXPLORATION:" .. tostring(title or detail or time()))
    end
    if CC.UI and CC.UI.gameDrawer and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
end

function Progression:ProcessMovement()
    local root = self:Ensure()
    if not root then return end
    local exploration = root.exploration
    if CC.Achievements then
        if CC.Achievements.ProcessTaxiState then CC.Achievements:ProcessTaxiState() end
        if CC.Achievements.CaptureBossUnits then CC.Achievements:CaptureBossUnits() end
    end
    if type(_G.UnitOnTaxi) == "function" and _G.UnitOnTaxi("player") then
        self.lastMapID, self.lastX, self.lastY = nil, nil, nil
        return
    end
    local mapID = mapIDForPlayer()
    local x, y = mapPosition(mapID)
    if not mapID or not x or not y then return end
    if self.lastMapID == mapID and self.lastX and self.lastY then
        local distance = worldDistance(mapID, self.lastX, self.lastY, x, y)
        if distance and distance >= 0.8 and distance <= 50 then
            if CC.Achievements and CC.Achievements.RecordTravelDistance then
                local flying = type(_G.IsFlying) == "function" and _G.IsFlying() or false
                CC.Achievements:RecordTravelDistance(distance, flying)
            end
            local accumulated = exploration.distanceRemainder + distance
            local steps = floor(accumulated / self.stepYards)
            exploration.distanceRemainder = accumulated - (steps * self.stepYards)
            if steps > 0 then
                exploration.totalSteps = exploration.totalSteps + steps
                local blocks = floor(exploration.totalSteps / 1000)
                local newBlocks = blocks - exploration.rewardedStepBlocks
                if newBlocks > 0 then
                    exploration.rewardedStepBlocks = blocks
                    self:AwardExploration(newBlocks * 2, newBlocks * 2, "Explorer Steps", tostring(newBlocks * 1000) .. " steps travelled", true)
                end
                if CC.BattlePass and CC.BattlePass.CheckMilestoneGoals then CC.BattlePass:CheckMilestoneGoals("WALK", exploration.totalSteps) end
                if CC.Achievements and CC.Achievements.EvaluateAll then CC.Achievements:EvaluateAll(false) end
            end
        end
    end
    self.lastMapID, self.lastX, self.lastY = mapID, x, y
end

function Progression:CheckArea(initial)
    local root = self:Ensure()
    if not root then return end
    local exploration = root.exploration
    local mapID = mapIDForPlayer()
    if not mapID then return end
    local area, zone = currentAreaName()
    local key = tostring(mapID) .. ":" .. lower(tostring(area))
    if CC.Achievements and CC.Achievements.RecordArea then
        CC.Achievements:RecordArea(zone ~= "" and zone or area, area)
    end
    if exploration.visitedAreas[key] then return end
    exploration.visitedAreas[key] = { area = area, zone = zone, first = now() }
    exploration.newAreas = exploration.newAreas + 1
    local zoneKey = tostring(mapID) .. ":" .. lower(tostring(zone ~= "" and zone or area))
    if not exploration.visitedZones[zoneKey] then
        exploration.visitedZones[zoneKey] = { zone = zone ~= "" and zone or area, first = now() }
        exploration.newZones = exploration.newZones + 1
        self:AwardExploration(8, 5, "New Zone Discovered", zone ~= "" and zone or area, not initial)
        if CC.Achievements and CC.Achievements.RecordZone then CC.Achievements:RecordZone(mapID, zone ~= "" and zone or area) end
    else
        self:AwardExploration(3, 2, "New Area Discovered", area, not initial)
    end
    -- Cross-addon call (wire 3/3) — Docs/INTEGRATION-CONTRACT.md Phase 7.
    -- CreshGames being installed and loaded is now the guard; CC:IsFeatureEnabled("games")
    -- was an intra-addon flag that no longer applies across addon boundaries.
    if _G.CreshGamesAPI and _G.CreshGamesAPI.RecordDungeonPassZone then
        local dungeonZoneKey = tostring(mapID) .. ":" .. lower(tostring(zone ~= "" and zone or area))
        _G.CreshGamesAPI.RecordDungeonPassZone(dungeonZoneKey, zone ~= "" and zone or area)
    end
end

function Progression:AwardDungeonClear(dungeonName)
    local root = self:Ensure()
    if not root then return end
    root.exploration.dungeonClears = root.exploration.dungeonClears + 1
    self:AwardExploration(20, 15, "Dungeon Cleared", tostring(dungeonName or "Dungeon"), true)
    if CC.Achievements and CC.Achievements.RecordDungeonEntry then CC.Achievements:RecordDungeonEntry(dungeonName) end
end

function Progression:GetExplorationSummary()
    local root = self:Ensure()
    if not root then return 0, 0, 0, 0 end
    local e = root.exploration
    return e.totalSteps or 0, e.newAreas or 0, e.dungeonClears or 0, e.totalKills or 0
end

function Progression:RecordKill(destGUID, destName)
    local root = self:Ensure(); if not root then return end
    local key = tostring(destGUID or "")
    -- Only count creature/vehicle GUIDs so player PvP deaths never advance mob goals.
    if key ~= "" and not (string.find(key, "^Creature%-") or string.find(key, "^Vehicle%-")) then return end
    self.killCache = self.killCache or {}
    local stamp = now()
    if key ~= "" and stamp - (self.killCache[key] or 0) < 2 then return end
    if key ~= "" then self.killCache[key] = stamp end
    self.killCacheSize = (self.killCacheSize or 0) + 1
    if self.killCacheSize > 250 then self.killCache = {}; self.killCacheSize = 0 end
    root.exploration.totalKills = (root.exploration.totalKills or 0) + 1
    if CC.Achievements and CC.Achievements.RecordWorldKill then CC.Achievements:RecordWorldKill(destGUID, destName) end
    if CC.BattlePass and CC.BattlePass.CheckMilestoneGoals then CC.BattlePass:CheckMilestoneGoals("KILL", root.exploration.totalKills) end
    -- Cross-addon call (wire 1/3) — Docs/INTEGRATION-CONTRACT.md Phase 7.
    if _G.CreshGamesAPI and _G.CreshGamesAPI.AddMainPassXP then _G.CreshGamesAPI.AddMainPassXP(1, "WoW mob defeated") end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ZONE_CHANGED")
events:RegisterEvent("ZONE_CHANGED_INDOORS")
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
events:SetScript("OnEvent", function(_, event)
    if not CC:IsFeatureEnabled("worldProgression") then return end
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if type(_G.CombatLogGetCurrentEventInfo) == "function" then
            local _, subevent, _, sourceGUID, _, sourceFlags, _, destGUID, destName = _G.CombatLogGetCurrentEventInfo()
            if subevent == "PARTY_KILL" then Progression:RecordKill(destGUID, destName) end
        end
        return
    elseif event == "PLAYER_ENTERING_WORLD" then
        Progression:Ensure()
        Progression.lastMapID, Progression.lastX, Progression.lastY = nil, nil, nil
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(1.5, function() Progression:CheckArea(true) end)
        else
            Progression:CheckArea(true)
        end
    else
        if _G.C_Timer and _G.C_Timer.After then
            _G.C_Timer.After(0.6, function() Progression:CheckArea(false) end)
        else
            Progression:CheckArea(false)
        end
    end
end)

events:SetScript("OnUpdate", function(_, elapsed)
    if not CC:IsFeatureEnabled("worldProgression") then return end
    Progression.elapsed = (Progression.elapsed or 0) + (elapsed or 0)
    if Progression.elapsed < Progression.pollInterval then return end
    Progression.elapsed = 0
    Progression:ProcessMovement()
end)
