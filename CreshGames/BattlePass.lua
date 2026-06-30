local ADDON_NAME, CC = ...
if not CC then return end

local Pass = {
    version = CC.version,
    maxLevel = 200,
}
CC.BattlePass = Pass
if CC.RegisterModule then CC:RegisterModule("BattlePass", Pass) end

local floor, min, max = math.floor, math.min, math.max
local upper = string.upper
local format = string.format

Pass.themeOrder = { "UBUNTU", "WINDOWS_95", "MSN_MESSENGER", "WOW_CLASSIC", "ZLR" }

Pass.levelNames = {
    "Arcade Initiate", "First Hop", "Lucky Draw", "Dungeon Scout", "Bronze Cache",
    "Opening Move", "River Reader", "Twenty-One", "Minion Recruit", "Silver Cache",
    "Traffic Dodger", "Pair Maker", "Room Delver", "Board Tactician", "Challenger Cache",
    "Line Breaker", "Paddle Keeper", "Dice Fighter", "Streak Seeker", "Gold Cache",
    "Frogger Veteran", "Card Shark", "Dungeon Captain", "Chess Strategist", "Heroic Cache",
    "Tetris Racer", "Pong Contender", "Blackjack Ace", "Boss Hunter", "Platinum Cache",
    "Endless Hopper", "Table Veteran", "Minion Master", "Chess Expert", "Champion Cache",
    "High Roller", "Dungeon Survivor", "Perfect Read", "Multiplayer Rival", "Mythic Cache",
    "Arcade Elite", "Board Master", "River King", "Endless Dweller", "Legend Cache",
    "Grandmaster Trial", "Casino Champion", "Game Night Hero", "Cresh Challenger", "Grand Arcade Vault",
    "Azeroth Rambler", "Faction Standard", "Forest Pathfinder", "Desert Runner", "Explorer Cache",
    "City Defender", "Crypt Delver", "Arena Reader", "Portal Walker", "Veteran Cache",
    "Outland Scout", "Marsh Navigator", "Nagrand Rider", "Shadowmoon Seeker", "Expedition Cache",
    "Sunwell Spark", "Tempest Tactician", "Serpent Challenger", "Black Temple Raider", "Epic Cache",
    "Alliance Vanguard", "Horde Vanguard", "Forsaken Survivor", "Moonlit Sentinel", "Faction Cache",
    "Draenei Crystal", "Blood Elf Dawn", "Tauren Spirit", "Dwarven Forge", "Masterwork Cache",
    "Arcane Gambler", "Fel Challenger", "Storm Caller", "Grove Keeper", "Exalted Cache",
    "Endless Champion", "Dungeon Warlord", "Chess Virtuoso", "Card Table Legend", "Conqueror Cache",
    "Hundred-Room Hero", "Perfect Crossing", "Grand Rival", "Theme Collector", "Ascendant Cache",
    "Azeroth Icon", "Outland Icon", "Social Arcade Legend", "Cresh Immortal", "Grand Theme Vault",
    -- Levels 101-200
    "Legendary Initiate", "Second Horizon", "Grander Fortune", "Realm Walker", "Imperial Cache",
    "Dawn Herald", "Starfall Seeker", "Crystal Warden", "Vault Delver", "Sovereign Cache",
    "Flame Warder", "Storm Victor", "Iron Sentinel", "Rift Scout", "Twilight Cache",
    "Void Wanderer", "Ember Tactician", "Tide Caller", "Sky Marshal", "Celestial Cache",
    "Rune Keeper", "Pact Forger", "Shadow Dancer", "Oath Bearer", "Eternity Cache",
    "World Wanderer", "Shard Hunter", "Pinnacle Walker", "Crucible Lord", "Dominion Cache",
    "Primal Champion", "Ancient Caller", "Lore Master", "Power Forger", "Valor Cache",
    "Sacred Keeper", "Gate Warden", "Horizon Runner", "Relic Finder", "Conquest Cache",
    "Titan's Disciple", "Boundless Wanderer", "Throne Seeker", "Beacon Holder", "Primordial Cache",
    "Storm's Edge", "Void Champion", "Abyss Walker", "Crown Seeker", "Grand Conqueror's Vault",
    "Arcane Sovereign", "Battle Forged", "Realm Master", "Undying Seeker", "Eternal Cache",
    "Last Bastion", "Crucible Veteran", "Starlit Rival", "Ironclad Sage", "Timeless Cache",
    "Light's Ascendant", "Sunlit Keeper", "Radiant Warden", "Dawnbringer", "Unbowed Cache",
    "Arcane Vanguard", "Fel Warden", "Storm Sentinel", "Grove Champion", "Radiant Cache",
    "Azeroth Paragon", "Relentless Paragon", "Realm Forger", "Cresh Transcendent", "Ancient Cache",
    "Bastion Breaker", "Immortal Delver", "Final Rival", "Lore Champion", "Undying Cache",
    "Arena Paragon", "Void Walker", "Eternal Dawn", "Kingdom's Edge", "Titan Cache",
    "Forge Mastery", "Pinnacle Seeker", "Immortal Rival", "Grand Arcanist", "Transcendent Cache",
    "Azeroth Eternal", "Boundless Champion", "Cresh Paragon", "Immortal Seeker", "Infinite Cache",
    "Last Legend", "Timeless Champion", "Cresh Ascendant", "Immortal of Azeroth", "Grand Eternal Champion",
}

Pass.requirementRoutes = {
    { game = "FROGGER", name = "Frogger", action = "PLAY FROGGER", hint = "Complete an endless Frogger run to earn Pass Points and Cresh Coins." },
    { game = "DUNGEON", name = "Dungeon Dweller", action = "PLAY DUNGEON", hint = "Clear rooms, defeat bosses and extend a Dungeon Dweller run." },
    { game = "CHESS", name = "Solo Chess", action = "PLAY CHESS", hint = "Play Solo Chess; stronger computer levels reward the same pass progress for a completed result." },
    { game = "HOLDEM", name = "Texas Hold'em", action = "PLAY HOLDEM", hint = "Complete a Hold'em hand and build your persistent bankroll." },
    { game = "BLACKJACK", name = "Blackjack", action = "PLAY BLACKJACK", hint = "Finish a Blackjack hand to add natural Battle Pass progress." },
    { game = "HIGHERLOWER", name = "Higher or Lower", action = "PLAY HIGH/LOW", hint = "Build a streak in Higher or Lower and complete the round." },
    { mode = "MULTIPLAYER", name = "Multiplayer", action = "FIND A RIVAL", hint = "Challenge an addon-ready friend. Multiplayer results award an additional Pass Point bonus." },
}

Pass.premiumThemes = {
    UBUNTU = {
        name = "Ubuntu",
        price = 100,
        note = "Warm aubergine panels with vivid orange accents.",
        swatches = { {0.105,0.028,0.090,1}, {0.925,0.315,0.080,1}, {0.640,0.175,0.055,1} },
    },
    WINDOWS_95 = {
        name = "Windows 95",
        price = 200,
        note = "Teal desktop surfaces with classic grey controls.",
        swatches = { {0.015,0.190,0.190,1}, {0.720,0.730,0.750,1}, {0.000,0.500,0.760,1} },
    },
    MSN_MESSENGER = {
        name = "MSN Messenger",
        price = 300,
        note = "Bright blue messenger styling inspired by early chat clients.",
        swatches = { {0.025,0.060,0.115,1}, {0.090,0.650,1.000,1}, {0.055,0.385,0.720,1} },
    },
    WOW_CLASSIC = {
        name = "WoW Classic",
        price = 400,
        note = "Bronze, parchment and gold surfaces for a classic Azeroth feel.",
        swatches = { {0.205,0.135,0.060,1}, {1.000,0.790,0.260,1}, {0.090,0.285,0.535,1} },
    },
    ZLR = {
        name = "ZLR Arena",
        price = 500,
        note = "Blackened arena-tech panels, Q3A launcher text and red-orange glow.",
        swatches = { {0.012,0.016,0.020,1}, {0.940,0.205,0.035,1}, {0.405,0.060,0.028,1} },
    },
}

local function paletteInfo(key, name, price, note, source, level)
    local preset = CC.UI and CC.UI.THEME_PRESETS and CC.UI.THEME_PRESETS[key]
    if not preset then return end
    Pass.premiumThemes[key] = {
        name = name, price = price, note = note,
        swatches = { preset.panel, preset.accent, preset.outgoing },
        source = source or "SHOP", level = level,
    }
end

-- Ten shop themes purchasable with Cresh Coins.
-- The ten Outland and endgame zone themes are reserved as Battle Pass rewards (levels 110-200).
local SHOP_THEMES = {
    {"FOR_THE_ALLIANCE", "For the Alliance", 150, "Royal blue, lion gold and bright Alliance trim."},
    {"FOR_THE_HORDE", "For the Horde", 150, "Crimson iron, war-banner red and ember highlights."},
    {"UNDEAD_FORSAKEN", "Undead Forsaken", 225, "Undercity violet, plague green and shadowed stone."},
    {"ELWYNN_FOREST", "Elwynn Forest", 250, "Warm woodland greens, trail brown and sunlit leaves."},
    {"DUROTAR", "Durotar", 275, "Dry red earth, canyon orange and Horde frontier iron."},
    {"STRANGLETHORN", "Stranglethorn Vale", 325, "Deep jungle green with treasure-gold accents."},
    {"TANARIS", "Tanaris", 350, "Sandstone panels, desert gold and weathered brass."},
    {"WINTERSPRING", "Winterspring", 400, "Frost blue, snow white and cold mountain shadows."},
    {"STORMWIND", "Stormwind City", 850, "Alliance blue, royal gold and bright city stone."},
    {"ORGRIMMAR", "Orgrimmar", 850, "Horde crimson, iron brown and fortress firelight."},
}

-- Twenty zone themes earned from the extended Battle Pass (levels 10-200, every 10 levels).
-- Levels 1-100: classic Azeroth and early Outland zones (exclusive to the pass).
-- Levels 110-200: Outland and endgame zones, moved from the shop to the pass.
--   Players who previously purchased these themes from the shop retain ownership.
Pass.passThemeRewards = {
    [10]  = "WESTFALL",         [20]  = "DUSKWOOD",           [30]  = "THE_BARRENS",
    [40]  = "ASHENVALE",        [50]  = "UNGORO",             [60]  = "EASTERN_PLAGUELANDS",
    [70]  = "TEROKKAR_FOREST",  [80]  = "BLADES_EDGE",        [90]  = "TEMPEST_KEEP",
    [100] = "SERPENTSHRINE",
    -- Extended pass rewards: levels 110-200
    [110] = "HELLFIRE_PENINSULA",  [120] = "ZANGARMARSH",      [130] = "NAGRAND",
    [140] = "NETHERSTORM",         [150] = "SHADOWMOON_VALLEY",[160] = "SHATTRATH",
    [170] = "SILVERMOON",          [180] = "BLACK_TEMPLE",     [190] = "SUNWELL",
    [200] = "DARK_PORTAL",
}

-- paletteInfo() depends on CC.UI.THEME_PRESETS, which (when BattlePass.lua and UI.lua are
-- ever in different addons) is only available after a PLAYER_LOGIN-time cross-addon bridge
-- has run. Building these two theme groups must therefore be deferred past file-load time -
-- see Docs/MIGRATION.md "BattlePass.lua: attempted, reverted, here's why" for the bug this
-- fixes. Harmless no-op timing change while BattlePass.lua stays in CreshChat (UI.lua already
-- loads earlier in the same TOC), and required before BattlePass.lua can safely move addons.
local paletteThemesBuilt = false
local function buildPaletteThemes()
    if paletteThemesBuilt then return end
    paletteThemesBuilt = true
    for _, row in ipairs(SHOP_THEMES) do
        paletteInfo(row[1], row[2], row[3], row[4], "SHOP")
        Pass.themeOrder[#Pass.themeOrder + 1] = row[1]
    end
    for level = 10, 200, 10 do
        local key = Pass.passThemeRewards[level]
        local name = CC.ThemeLibrary and CC.ThemeLibrary.display and CC.ThemeLibrary.display[key] or key
        paletteInfo(key, name, 0, "Exclusive Battle Pass theme unlocked at Level " .. level .. ".", "PASS", level)
        Pass.themeOrder[#Pass.themeOrder + 1] = key
    end
end

do
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_LOGIN")
    initFrame:SetScript("OnEvent", function(self)
        buildPaletteThemes()
        self:UnregisterEvent("PLAYER_LOGIN")
    end)
end

local function now()
    if type(_G.time) == "function" then return _G.time() end
    if type(_G.GetTime) == "function" then return floor(_G.GetTime()) end
    return 0
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    return max(low, min(high, value))
end

local function formatNumber(value)
    local text = tostring(floor(max(0, tonumber(value) or 0)))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if grouped:sub(1, 1) == "," then grouped = grouped:sub(2) end
    return grouped
end

function Pass:Ensure()
    if not CC.db then return nil end
    CC.db.arcadeRewards = type(CC.db.arcadeRewards) == "table" and CC.db.arcadeRewards or {}
    local save = CC.db.arcadeRewards
    save.coins = floor(max(0, tonumber(save.coins) or 0))
    save.lifetimeCoins = floor(max(save.coins, tonumber(save.lifetimeCoins) or save.coins))
    save.gameCoins = floor(max(0, tonumber(save.gameCoins) or 0))
    save.activityCoins = floor(max(0, tonumber(save.activityCoins) or 0))
    save.explorationCoins = floor(max(0, tonumber(save.explorationCoins) or 0))
    save.spentCoins = floor(max(0, tonumber(save.spentCoins) or 0))
    save.passXP = floor(max(0, tonumber(save.passXP) or 0))
    save.claimed = type(save.claimed) == "table" and save.claimed or {}
    save.unlockedThemes = type(save.unlockedThemes) == "table" and save.unlockedThemes or {}
    save.themeUnlockSources = type(save.themeUnlockSources) == "table" and save.themeUnlockSources or {}
    save.recent = type(save.recent) == "table" and save.recent or {}
    save.gamesRewarded = floor(max(0, tonumber(save.gamesRewarded) or 0))
    save.milestoneGoals = type(save.milestoneGoals) == "table" and save.milestoneGoals or {}

    -- Ownership must only come from a purchase or a claimed Battle Pass reward.
    -- Theme preview temporarily changes ui.themePreset, so inferring ownership from
    -- the selected preset would allow a locked preview to become permanently owned.
    for level, themeKey in pairs(self.passThemeRewards or {}) do
        if save.claimed[tostring(level)] then
            save.unlockedThemes[themeKey] = true
            save.themeUnlockSources[themeKey] = save.themeUnlockSources[themeKey] or ("PASS:" .. tostring(level))
        end
    end
    if CC.CardDecks and CC.CardDecks.BackfillFromClaimed then CC.CardDecks:BackfillFromClaimed(save.claimed) end
    return save
end

Pass.milestoneDefinitions = {
    { key="WALK_5000", kind="WALK", goal=5000, coins=10, xp=10, title="Trail Starter" },
    { key="WALK_10000", kind="WALK", goal=10000, coins=20, xp=15, title="Long Road" },
    { key="WALK_25000", kind="WALK", goal=25000, coins=40, xp=25, title="Zone Wanderer" },
    { key="WALK_50000", kind="WALK", goal=50000, coins=75, xp=40, title="Azeroth Walker" },
    { key="WALK_100000", kind="WALK", goal=100000, coins=150, xp=75, title="Endless Journey" },
    { key="KILL_25", kind="KILL", goal=25, coins=10, xp=10, title="First Hunt" },
    { key="KILL_100", kind="KILL", goal=100, coins=25, xp=20, title="Mob Breaker" },
    { key="KILL_250", kind="KILL", goal=250, coins=50, xp=35, title="Threat Cleaner" },
    { key="KILL_500", kind="KILL", goal=500, coins=100, xp=60, title="Enemy Reaper" },
    { key="KILL_1000", kind="KILL", goal=1000, coins=200, xp=100, title="Azeroth Defender" },
    -- Extended milestones for levels 101-200
    { key="WALK_250000",  kind="WALK", goal=250000,  coins=300,  xp=150, title="Marathon Marcher" },
    { key="WALK_500000",  kind="WALK", goal=500000,  coins=600,  xp=300, title="World Traverser" },
    { key="WALK_1000000", kind="WALK", goal=1000000, coins=1200, xp=600, title="Azeroth Pilgrim" },
    { key="KILL_2500",  kind="KILL", goal=2500,  coins=400,  xp=200, title="Unstoppable" },
    { key="KILL_5000",  kind="KILL", goal=5000,  coins=750,  xp=375, title="Five Thousand Felled" },
    { key="KILL_10000", kind="KILL", goal=10000, coins=1500, xp=750, title="Slayer of Thousands" },
}

function Pass:GetGoalProgress(kind)
    local steps, _, _, kills = 0,0,0,0
    if CC.GameProgression and CC.GameProgression.GetExplorationSummary then steps,_,_,kills = CC.GameProgression:GetExplorationSummary() end
    return kind == "KILL" and (kills or 0) or (steps or 0)
end
function Pass:GetNextMilestone(kind)
    local save=self:Ensure(); local value=self:GetGoalProgress(kind)
    for _,goal in ipairs(self.milestoneDefinitions) do
        if goal.kind==kind and not save.milestoneGoals[goal.key] then return goal,value end
    end
    return nil,value
end
function Pass:CheckMilestoneGoals(kind,value)
    local save=self:Ensure(); if not save then return end
    value=math.floor(math.max(0,tonumber(value) or 0))
    for _,goal in ipairs(self.milestoneDefinitions) do
        if goal.kind==kind and value>=goal.goal and not save.milestoneGoals[goal.key] then
            save.milestoneGoals[goal.key]=true
            self:AddCoins(goal.coins,"GOAL")
            self:AddPassXP(goal.xp,"MILESTONE",true)
            if CC.UI and CC.UI.ShowBattlePassToast then CC.UI:ShowBattlePassToast(goal.title, "+"..goal.coins.." Cresh Coins - +"..goal.xp.." Battle Pass XP", "BATTLEPASS", "BP:GOAL:"..tostring(goal.key)) end
        end
    end
    self:RefreshDrawer()
end
function Pass:GetPassPanelHeight() return 446 + ((self.maxLevel or 100) * 55) end

function Pass:IsPremiumTheme(theme)
    return self.premiumThemes[upper(tostring(theme or ""))] ~= nil
end

function Pass:IsThemeUnlocked(theme)
    theme = upper(tostring(theme or ""))
    if not self.premiumThemes[theme] then return true end
    local save = self:Ensure()
    return save and save.unlockedThemes[theme] == true or false
end

function Pass:GetLockedThemeCount()
    local count = 0
    for _, theme in ipairs(self.themeOrder or {}) do
        if not self:IsThemeUnlocked(theme) then count = count + 1 end
    end
    return count
end

function Pass:GetThemePanelHeight()
    return max(240, 140 + (self:GetLockedThemeCount() * 98))
end

function Pass:GetThemeInfo(theme)
    return self.premiumThemes[upper(tostring(theme or ""))]
end

function Pass:GetNextLevelCost(level)
    level = floor(clamp(level, 1, self.maxLevel))
    return 50 + ((level - 1) * 5)
end

function Pass:GetCumulativeXP(level)
    level = floor(clamp(level, 1, self.maxLevel))
    local completed = level - 1
    return completed * 50 + (5 * completed * (completed - 1)) / 2
end

function Pass:GetLevelFromXP(xp)
    xp = floor(max(0, tonumber(xp) or 0))
    -- Closed-form solution to 5k²+95k = 2·xp (k = level−1).
    -- At every level boundary the discriminant (10n+85)² is a perfect square,
    -- so the formula is exact at thresholds. The ±1 neighbour loop corrects
    -- any floating-point drift between boundaries.
    local k = floor((-95 + math.sqrt(9025 + 40 * xp)) / 10)
    local level = max(1, min(self.maxLevel, 1 + k))
    while level < self.maxLevel and xp >= self:GetCumulativeXP(level + 1) do level = level + 1 end
    while level > 1               and xp <  self:GetCumulativeXP(level)     do level = level - 1 end
    return level
end

function Pass:GetMaxXP()
    return self:GetCumulativeXP(self.maxLevel)
end

function Pass:GetProgress()
    local save = self:Ensure()
    if not save then return 1, 0, 50, 0 end
    local level = self:GetLevelFromXP(save.passXP)
    local base = self:GetCumulativeXP(level)
    if level >= self.maxLevel then return level, 1, 1, 1 end
    local required = self:GetNextLevelCost(level)
    local current = max(0, save.passXP - base)
    return level, current, required, clamp(current / max(1, required), 0, 1)
end

function Pass:GetReward(level)
    level = floor(clamp(level, 1, self.maxLevel))
    local coins
    if level == self.maxLevel then
        coins = 1000  -- capstone: completing all 200 levels
    elseif level % 10 == 0 then
        coins = 100 + level * 2
    elseif level % 5 == 0 then
        coins = 45 + level
    else
        coins = 15 + floor((level - 1) / 5) * 5
    end
    local themeKey = self.passThemeRewards and self.passThemeRewards[level]
    local themeInfo = themeKey and self.premiumThemes[themeKey] or nil
    local deckKey, deckInfo
    if CC.CardDecks and CC.CardDecks.GetBattlePassReward then deckKey, deckInfo = CC.CardDecks:GetBattlePassReward(level) end
    local tetrisThemeKey = CC.Tetris and CC.Tetris.mainPassThemeRewards and CC.Tetris.mainPassThemeRewards[level] or nil
    local tetrisTheme = tetrisThemeKey and CC.Tetris and CC.Tetris.GetTheme and CC.Tetris:GetTheme(tetrisThemeKey) or nil
    return {
        level = level, coins = coins,
        title = self.levelNames[level] or ("Battle Pass Level " .. level),
        themeKey = themeKey,
        themeName = themeInfo and themeInfo.name or nil,
        deckKey = deckKey,
        deckName = deckInfo and deckInfo.displayName or nil,
        tetrisThemeKey = tetrisThemeKey,
        tetrisThemeName = tetrisTheme and tetrisTheme.name or nil,
        -- F1: reward routing metadata
        sourceSystem = "WOW_BATTLE_PASS",
        sourceId     = "BATTLEPASS_LEVEL_" .. level,
        targetGame   = "GLOBAL",
    }
end

function Pass:GetRequirementRoute(level)
    level = floor(clamp(level, 1, self.maxLevel))
    return self.requirementRoutes[((level - 1) % #self.requirementRoutes) + 1]
end

function Pass:GetRequirement(level)
    level = floor(clamp(level, 1, self.maxLevel))
    local save = self:Ensure()
    local reward = self:GetReward(level)
    local target = self:GetCumulativeXP(level)
    local current = save and save.passXP or 0
    local needed = max(0, target - current)
    local reached = current >= target
    local route = self:GetRequirementRoute(level)
    local detail
    if reached then
        local extras = ""
        if reward.themeName then extras = extras .. " and the " .. reward.themeName .. " theme" end
        if reward.deckName then extras = extras .. " and the " .. reward.deckName .. " card deck" end
        if reward.tetrisThemeName then extras = extras .. " and the " .. reward.tetrisThemeName .. " Tetris set" end
        detail = "Requirement complete. Unlock " .. reward.title .. " to collect " .. reward.coins .. " Cresh Coins" .. extras .. "."
    else
        detail = formatNumber(needed) .. " more Pass Points required. " .. route.hint
    end
    return {
        level = level,
        reward = reward,
        target = target,
        current = current,
        needed = needed,
        reached = reached,
        route = route,
        detail = detail,
    }
end

function Pass:SelectRequirement(level)
    level = floor(clamp(level, 1, self.maxLevel))
    self.selectedLevel = level
    if CC.UI and CC.UI.OpenGameDrawer then
        if not CC.UI.gameDrawer or not CC.UI.gameDrawer.creshOpen then CC.UI:OpenGameDrawer("BATTLEPASS")
        else CC.UI:SetGameDrawerMode("BATTLEPASS") end
        CC.UI:RefreshGameDrawer(true)
        local drawer = CC.UI.gameDrawer
        if drawer then self:ScrollToPassLevel(drawer, level) end
        local requirement = self:GetRequirement(level)
        if CC.UI.SetGameDrawerStatus then
            CC.UI:SetGameDrawerStatus(requirement.reached and ("Level " .. level .. " requirement complete - unlock the reward.")
                or ("Level " .. level .. " needs " .. formatNumber(requirement.needed) .. " more Pass Points."),
                requirement.reached and ((CC.UI.COLORS and CC.UI.COLORS.green) or nil) or ((CC.UI.COLORS and CC.UI.COLORS.quest) or nil))
        end
    end
end

function Pass:StartRequirement(level)
    local requirement = self:GetRequirement(level)
    if requirement.reached then return self:ClaimReward(level) end
    local route = requirement.route
    if route.mode == "MULTIPLAYER" then
        if CC.UI and CC.UI.SetGameDrawerMode then CC.UI:SetGameDrawerMode("MULTIPLAYER") end
        if CC.Games and CC.Games.ScanPeers then CC.Games:ScanPeers() end
        return true
    end
    if route.game and CC.SoloGames and CC.SoloGames.StartGame then
        return CC.SoloGames:StartGame(route.game)
    end
    return false
end

function Pass:HandleRewardClick(level)
    if self:IsLevelReached(level) and not self:IsRewardClaimed(level) then return self:ClaimReward(level) end
    self:SelectRequirement(level)
    return true
end

function Pass:IsLevelReached(level)
    local save = self:Ensure()
    if not save then return false end
    return save.passXP >= self:GetCumulativeXP(level)
end

function Pass:IsRewardClaimed(level)
    local save = self:Ensure()
    return save and save.claimed[tostring(level)] == true or false
end

function Pass:AddCoins(amount, source, isSimulation)
    if isSimulation == true then return 0 end
    local save = self:Ensure()
    amount = floor(max(0, tonumber(amount) or 0))
    if not save or amount <= 0 then return 0 end
    save.coins = save.coins + amount
    save.lifetimeCoins = save.lifetimeCoins + amount
    if source == "GAME" then save.gameCoins = save.gameCoins + amount
    elseif source == "ACTIVITY" then save.activityCoins = save.activityCoins + amount
    elseif source == "EXPLORATION" or source == "GOAL" then save.explorationCoins = save.explorationCoins + amount end
    if CC.UI and CC.UI.RefreshConsoleEconomy then CC.UI:RefreshConsoleEconomy() end
    return amount
end

function Pass:AddPassXP(amount, source, silent, isSimulation)
    if isSimulation == true then return 0 end
    local save = self:Ensure()
    amount = floor(max(0, tonumber(amount) or 0))
    if not save or amount <= 0 then return 0 end
    local previousLevel = self:GetLevelFromXP(save.passXP)
    save.passXP = save.passXP + amount
    local newLevel = self:GetLevelFromXP(save.passXP)
    save.recent = { text = tostring(source or "Activity") .. " reward", xp = amount, level = newLevel, at = now() }
    if CC.UI and CC.UI.RefreshConsoleEconomy then CC.UI:RefreshConsoleEconomy() end
    if not silent then
        self:RefreshDrawer()
        if newLevel > previousLevel and CC.UI and CC.UI.ShowBattlePassToast then
            local reward = self:GetReward(newLevel)
            local detail = "+" .. amount .. " Pass Points - reward ready"
            if reward.themeName then detail = detail .. " - " .. reward.themeName .. " theme" end
            if reward.deckName then detail = detail .. " - " .. reward.deckName .. " deck" end
            if reward.tetrisThemeName then detail = detail .. " - " .. reward.tetrisThemeName .. " Tetris set" end
            CC.UI:ShowBattlePassToast("Battle Pass Level " .. newLevel, detail, "BATTLEPASS", "BP:LEVEL:" .. tostring(newLevel))
        end
    end
    return amount, previousLevel, newLevel
end

function Pass:ClaimReward(level, silent)
    local save = self:Ensure()
    level = floor(clamp(level, 1, self.maxLevel))
    if not save then return false end
    if not self:IsLevelReached(level) then
        local needed = max(0, self:GetCumulativeXP(level) - save.passXP)
        if not silent and CC.Print then CC:Print("Battle Pass Level " .. level .. " needs " .. formatNumber(needed) .. " more points.") end
        return false
    end
    local key = tostring(level)
    if save.claimed[key] then return false end
    local reward = self:GetReward(level)
    save.claimed[key] = true
    self:AddCoins(reward.coins, "PASS")
    if reward.themeKey then
        save.unlockedThemes[reward.themeKey] = true
        save.themeUnlockSources[reward.themeKey] = "PASS:" .. tostring(level)
    end
    if reward.deckKey and CC.CardDecks and CC.CardDecks.UnlockDeck then
        CC.CardDecks:UnlockDeck(reward.deckKey, "PASS:" .. tostring(level), true)
    end
    if reward.tetrisThemeKey and CC.Tetris and CC.Tetris.UnlockTheme then
        CC.Tetris:UnlockTheme(reward.tetrisThemeKey, "MAIN_PASS:" .. tostring(level), not silent, true)
    end
    save.recent = { text = "Level " .. level .. " unlocked", coins = reward.coins, theme = reward.themeKey, deck = reward.deckKey, at = now() }
    if not silent and CC.Print then
        local extra = ""
        if reward.themeName then extra = extra .. " + " .. reward.themeName .. " theme" end
        if reward.deckName then extra = extra .. " + " .. reward.deckName .. " card deck" end
        if reward.tetrisThemeName then extra = extra .. " + " .. reward.tetrisThemeName .. " Tetris set" end
        CC:Print("Battle Pass Level " .. level .. " unlocked: +" .. reward.coins .. " Cresh Coins" .. extra .. ".")
    end
    if not silent then
        self:RefreshDrawer()
        if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
        if CC.UI and CC.UI.ShowBattlePassToast then
            local detail = "+" .. tostring(reward.coins or 0) .. " Cresh Coins"
            if reward.themeName then detail = detail .. " - " .. reward.themeName .. " theme unlocked" end
            if reward.deckName then detail = detail .. " - " .. reward.deckName .. " deck unlocked" end
            if reward.tetrisThemeName then detail = detail .. " - " .. reward.tetrisThemeName .. " Tetris set unlocked" end
            CC.UI:ShowBattlePassToast("Battle Pass reward unlocked", "Level " .. level .. " - " .. detail, "BATTLEPASS", "BP:CLAIM:" .. tostring(level))
        end
    end
    return true
end

function Pass:ClaimAllAvailable()
    local claimed, total = 0, 0
    for level = 1, self.maxLevel do
        if self:IsLevelReached(level) and not self:IsRewardClaimed(level) then
            local reward = self:GetReward(level)
            if self:ClaimReward(level, true) then
                claimed = claimed + 1
                total = total + reward.coins
            end
        end
    end
    if CC.Print then
        if claimed == 0 then CC:Print("No Battle Pass rewards are ready to unlock.")
        else CC:Print(claimed .. " Battle Pass rewards unlocked: +" .. formatNumber(total) .. " Cresh Coins.") end
    end
    self:RefreshDrawer()
    if claimed > 0 then
        if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
        if CC.UI and CC.UI.ShowBattlePassToast then
            CC.UI:ShowBattlePassToast("Battle Pass rewards unlocked", tostring(claimed) .. " rewards - +" .. formatNumber(total) .. " Cresh Coins", "BATTLEPASS", "BP:CLAIMALL:" .. tostring(now()))
        end
    end
    return claimed, total
end

-- DORMANT: no callers as of the Phase 3 progression-routing audit (2026-06-30).
-- SoloGames:RecordHistory used to call this alongside GameProgression:OnGameCompleted,
-- double-funding Cresh Coins/Pass XP from a single game result. GameProgression's
-- AddGameXP/AwardGameLevel path is now the sole game-completion route into the
-- shared Battle Pass pools. Do not re-wire this without removing that duplication.
function Pass:AwardForGame(entry)
    local save = self:Ensure()
    if not save or type(entry) ~= "table" then return 0, 0 end
    local result = upper(tostring(entry.result or "RUN"))
    local mode = upper(tostring(entry.mode or "SOLO"))
    local score = floor(max(0, tonumber(entry.score) or 0))
    local previousLevel = self:GetLevelFromXP(save.passXP)

    local xp, coins = 20, 5
    if result == "WIN" then xp, coins = xp + 18, coins + 9
    elseif result == "DRAW" then xp, coins = xp + 10, coins + 5
    elseif result == "LOSS" then xp, coins = xp + 6, coins + 3
    elseif result == "RUN" then
        local runBonus = min(20, floor(score / 100))
        xp = xp + runBonus
        coins = coins + min(10, floor(runBonus / 2))
    end

    local game = upper(tostring(entry.game or "GAME"))
    if game == "DUNGEON" then xp = xp + min(20, floor(score / 5)) end
    if game == "FROGGER" then xp = xp + min(15, floor(score / 500)) end
    if mode == "MULTIPLAYER" or mode == "MULTI" then xp, coins = xp * 2, coins * 2 end

    save.passXP = save.passXP + xp
    save.gamesRewarded = save.gamesRewarded + 1
    self:AddCoins(coins, "GAME")
    local newLevel = self:GetLevelFromXP(save.passXP)
    save.recent = { text = tostring(entry.game or "Game") .. " completed", xp = xp, coins = coins, level = newLevel, at = now() }
    if newLevel > previousLevel and CC.UI and CC.UI.ShowBattlePassToast then
        local reward = self:GetReward(newLevel)
        local extra = " - reward ready"
        if reward.themeName then extra = extra .. " - " .. reward.themeName .. " theme" end
        if reward.deckName then extra = extra .. " - " .. reward.deckName .. " deck" end
        if reward.tetrisThemeName then extra = extra .. " - " .. reward.tetrisThemeName .. " Tetris" end
        CC.UI:ShowBattlePassToast("Battle Pass Level " .. newLevel, "+" .. xp .. " points - +" .. coins .. " Cresh Coins" .. extra, "BATTLEPASS", "BP:GAMELEVEL:" .. tostring(newLevel))
    elseif CC.UI and CC.UI.gameDrawer and CC.UI.gameDrawer.creshOpen and CC.UI.SetGameDrawerStatus then
        CC.UI:SetGameDrawerStatus("+" .. xp .. " Pass Points · +" .. coins .. " Cresh Coins from " .. tostring(entry.game or "game") .. ".")
    end
    self:RefreshDrawer()
    return xp, coins
end

function Pass:BuyTheme(theme)
    theme = upper(tostring(theme or ""))
    local info = self.premiumThemes[theme]
    local save = self:Ensure()
    if not info or not save then return false end
    if save.unlockedThemes[theme] then
        if CC.UI and CC.UI.ApplyThemePreset then CC.UI:ApplyThemePreset(theme) end
        self:RefreshDrawer()
        return true
    end
    if info.source == "PASS" and info.level then
        self.selectedTheme = theme
        self:SelectRequirement(info.level)
        return false
    end
    if save.coins < info.price then
        local needed = info.price - save.coins
        if CC.Print then CC:Print(info.name .. " needs " .. formatNumber(needed) .. " more Cresh Coins.") end
        return false
    end
    save.coins = save.coins - info.price
    save.spentCoins = save.spentCoins + info.price
    save.unlockedThemes[theme] = true
    save.themeUnlockSources[theme] = "SHOP"
    save.recent = { text = info.name .. " unlocked", coins = -info.price, at = now() }
    if CC.UI and CC.UI.ApplyThemePreset then CC.UI:ApplyThemePreset(theme) end
    if CC.Print then CC:Print(info.name .. " unlocked and equipped for " .. formatNumber(info.price) .. " Cresh Coins.") end
    if CC.UI and CC.UI.ShowBattlePassToast then
        CC.UI:ShowBattlePassToast("Theme unlocked", info.name .. " is now equipped", "BATTLEPASS", "BP:THEME:" .. tostring(theme))
    end
    self:RefreshDrawer()
    return true
end

function Pass:GetWalletText()
    local save = self:Ensure()
    return save and formatNumber(save.coins) or "0"
end

function Pass:GetLifetimeText()
    local save = self:Ensure()
    return save and formatNumber(save.lifetimeCoins) or "0"
end

function Pass:RefreshDrawer()
    if CC.UI and CC.UI.RefreshConsoleEconomy then CC.UI:RefreshConsoleEconomy() end
    if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
end

function Pass:OpenThemeUnlock(theme)
    theme = upper(tostring(theme or ""))
    if not self.premiumThemes[theme] then return false end
    self.selectedTheme = theme
    if CC.UI and CC.UI.OpenGameDrawer then
        CC.UI:OpenGameDrawer("THEMES")
        if CC.UI.ScrollGameDrawerToTheme then
            CC.UI:ScrollGameDrawerToTheme(theme)
            if _G.C_Timer and type(_G.C_Timer.After) == "function" then
                _G.C_Timer.After(0, function()
                    if CC.UI and CC.UI.ScrollGameDrawerToTheme then CC.UI:ScrollGameDrawerToTheme(theme) end
                end)
            end
        end
    end
    self:RefreshDrawer()
    return true
end

function Pass:ToggleThemePreview(theme)
    theme = upper(tostring(theme or ""))
    if not self.premiumThemes[theme] or not CC.UI then return false end
    self.selectedTheme = theme
    local drawer = CC.UI.gameDrawer
    local savedScroll = drawer and drawer.scroll and drawer.scroll:GetVerticalScroll() or nil
    local previewName = CC.UI.GetThemePreviewName and CC.UI:GetThemePreviewName() or nil
    local previewing = CC.UI.IsThemePreviewActive and CC.UI:IsThemePreviewActive() and previewName == theme
    local changed = false
    if previewing then
        if CC.UI.CancelThemePreview then changed = CC.UI:CancelThemePreview(false) end
    else
        if CC.UI.PreviewThemePreset then changed = CC.UI:PreviewThemePreset(theme) end
    end
    self:RefreshDrawer()
    if savedScroll and CC.UI.SetGameDrawerScroll then
        CC.UI:SetGameDrawerScroll(savedScroll)
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then
            _G.C_Timer.After(0, function()
                if CC.UI and CC.UI.SetGameDrawerScroll then CC.UI:SetGameDrawerScroll(savedScroll) end
            end)
        end
    end
    return changed
end

local function setButtonEnabled(button, enabled)
    if not button then return end
    button.creshDisabled = not enabled
    button:SetAlpha(enabled and 1 or 0.42)
    if enabled then button:Enable() else button:Disable() end
end

-- ── Virtual row pool ───────────────────────────────────────────────────────────
local ROWS_TOP   = 396   -- pixels from passPanel top to first row
local ROW_HEIGHT = 55    -- pixels per row slot (49px row + 6px gap)
local POOL_SIZE  = 14    -- recycled frames: covers viewport at all supported scales

-- Builds drawer.passLevelList — the ordered array of level numbers that pass
-- the active filter. Returns the list.
function Pass:BuildPassLevelList(drawer)
    local filter = drawer.passFilter or "ALL"
    local list = {}
    for level = 1, self.maxLevel do
        local reached = self:IsLevelReached(level)
        local claimed = self:IsRewardClaimed(level)
        local visible = filter == "ALL"
            or (filter == "READY"   and reached and not claimed)
            or (filter == "CLAIMED" and claimed)
            or (filter == "LOCKED"  and not reached)
        if visible then list[#list + 1] = level end
    end
    drawer.passLevelList = list
    return list
end

-- Writes fresh data into one recycled pool frame for the given level.
function Pass:PopulatePassRow(row, level, save, api)
    local colors       = api.colors
    local applyBackdrop = api.applyBackdrop
    local darken       = api.darken
    local setAccent    = api.setAccent

    local reward    = self:GetReward(level)
    local reached   = self:IsLevelReached(level)
    local claimed   = self:IsRewardClaimed(level)
    local selected  = (level == self.selectedLevel)
    local milestone = level % 5 == 0

    applyBackdrop(row.badge,
        milestone and darken(colors.blue, 0.32) or colors.panelRaised,
        milestone and colors.blue or colors.border)
    row.badgeText:SetText(tostring(level))
    local textColor = milestone and colors.text or colors.muted
    row.badgeText:SetTextColor(textColor[1], textColor[2], textColor[3], 1)

    row.title:SetText(reward.title .. "  ·  +" .. reward.coins .. " coins"
        .. (reward.themeName       and ("  ·  THEME: "  .. reward.themeName)       or "")
        .. (reward.deckName        and ("  ·  DECK: "   .. reward.deckName)         or "")
        .. (reward.tetrisThemeName and ("  ·  TETRIS: " .. reward.tetrisThemeName)  or ""))

    local borderColor = selected and (colors.quest or colors.blue) or colors.border
    if claimed then
        row.detail:SetText(selected and "Unlocked · selected" or "Unlocked")
        row.button.label:SetText("OWNED")
        setButtonEnabled(row.button, false)
        applyBackdrop(row, darken(colors.green, 0.72),
            selected and (colors.quest or colors.blue) or colors.green)
    elseif reached then
        row.detail:SetText(selected and "Ready to unlock · selected" or "Ready to unlock")
        row.button.label:SetText("UNLOCK NOW")
        setButtonEnabled(row.button, true)
        if setAccent then setAccent(row.button, colors.green) end
        applyBackdrop(row, darken(colors.green, 0.82),
            selected and (colors.quest or colors.blue) or colors.green)
    else
        local need = max(0, self:GetCumulativeXP(level) - save.passXP)
        row.detail:SetText(formatNumber(need) .. " points required"
            .. (selected and " · selected" or ""))
        row.button.label:SetText("VIEW GOAL")
        setButtonEnabled(row.button, true)
        if setAccent then setAccent(row.button, colors.quest or colors.blue) end
        local base = milestone and darken(colors.blue, 0.62) or colors.panelSoft
        local edge = selected and (colors.quest or colors.blue)
            or (milestone and colors.blue or borderColor)
        applyBackdrop(row, base, edge)
    end
end

-- Positions and (conditionally) repopulates pool frames to cover the viewport.
-- forceRepopulate=true re-applies content even when the frame's assigned level
-- has not changed — needed after filter/theme/selection changes.
function Pass:UpdatePassPool(drawer, forceRepopulate)
    local list = drawer.passLevelList
    local pool = drawer.passPool
    local api  = drawer.passApi
    if not list or not pool or not api then return end

    local save = self:Ensure()
    if not save then return end

    local scrollY  = drawer.scroll and (drawer.scroll:GetVerticalScroll() or 0) or 0
    local firstIdx = max(0, floor((scrollY - ROWS_TOP) / ROW_HEIGHT) - 1)
    firstIdx = min(firstIdx, max(0, #list - POOL_SIZE))

    for poolI = 1, POOL_SIZE do
        local listIdx = firstIdx + poolI - 1
        local level   = list[listIdx + 1]
        local frame   = pool[poolI]
        if level then
            local absY = -(ROWS_TOP + listIdx * ROW_HEIGHT)
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT",  drawer.passPanel, "TOPLEFT",  0, absY)
            frame:SetPoint("TOPRIGHT", drawer.passPanel, "TOPRIGHT", 0, absY)
            if forceRepopulate or frame.assignedLevel ~= level then
                frame.assignedLevel = level
                self:PopulatePassRow(frame, level, save, api)
            end
            frame:Show()
        else
            frame.assignedLevel = nil
            frame:Hide()
        end
    end
end

-- Scrolls the drawer so the row for the given level is centered in the viewport.
function Pass:ScrollToPassLevel(drawer, level)
    if not drawer or not drawer.passLevelList or not drawer.scroll then return end
    local targetIdx = nil
    for i, l in ipairs(drawer.passLevelList) do
        if l == level then targetIdx = i - 1; break end
    end
    if not targetIdx then return end
    local viewportH = drawer.scroll:GetHeight() or 400
    local rowY      = ROWS_TOP + targetIdx * ROW_HEIGHT
    local scrollTo  = max(0, rowY - floor(viewportH / 2) + floor(ROW_HEIGHT / 2))
    if CC.UI and CC.UI.SetGameDrawerScroll then
        CC.UI:SetGameDrawerScroll(scrollTo)
    else
        drawer.scroll:SetVerticalScroll(scrollTo)
    end
end

function Pass:BuildDrawerPanels(drawer, api)
    if not drawer or not api or drawer.passPanel then return end
    local createButton = api.createButton
    local createFont = api.createFont
    local applyBackdrop = api.applyBackdrop
    local darken = api.darken
    local colors = api.colors
    local templateName = api.templateName

    drawer.passPanel = CreateFrame("Frame", nil, drawer.content)
    drawer.passPanel:SetPoint("TOPLEFT", drawer.content, "TOPLEFT", 0, 0)
    drawer.passPanel:SetPoint("TOPRIGHT", drawer.content, "TOPRIGHT", 0, 0)
    drawer.passPanel:SetHeight(self:GetPassPanelHeight())
    drawer.passPanel:Hide()

    local hero = CreateFrame("Frame", nil, drawer.passPanel, templateName())
    hero:SetPoint("TOPLEFT", drawer.passPanel, "TOPLEFT", 0, 0)
    hero:SetPoint("TOPRIGHT", drawer.passPanel, "TOPRIGHT", 0, 0)
    hero:SetHeight(126)
    applyBackdrop(hero, darken(colors.blue, 0.42), colors.blue)
    drawer.passHero = hero

    hero.title = createFont(hero, 16, colors.text, "LEFT")
    hero.title:SetPoint("TOPLEFT", hero, "TOPLEFT", 12, -10)
    hero.title:SetText("CRESH BATTLE PASS")
    hero.subtitle = createFont(hero, 9, colors.muted, "LEFT")
    hero.subtitle:SetPoint("TOPLEFT", hero.title, "BOTTOMLEFT", 0, -4)
    hero.subtitle:SetText(tostring(self.maxLevel) .. " levels · play any solo or multiplayer game to earn Pass Points, coins and themes.")

    hero.level = createFont(hero, 24, colors.text, "LEFT")
    hero.level:SetPoint("TOPLEFT", hero, "TOPLEFT", 12, -49)
    hero.level:SetText("LEVEL 1")
    hero.wallet = createFont(hero, 10, colors.gold or colors.quest, "RIGHT")
    hero.wallet:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -12, -53)
    hero.wallet:SetText("0 COINS")

    hero.progressBack = CreateFrame("Frame", nil, hero, templateName())
    hero.progressBack:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 12, 16)
    hero.progressBack:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -12, 16)
    hero.progressBack:SetHeight(20)
    applyBackdrop(hero.progressBack, colors.panel, colors.border)
    hero.progress = CreateFrame("StatusBar", nil, hero.progressBack)
    hero.progress:SetPoint("TOPLEFT", hero.progressBack, "TOPLEFT", 2, -2)
    hero.progress:SetPoint("BOTTOMRIGHT", hero.progressBack, "BOTTOMRIGHT", -2, 2)
    hero.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hero.progress:SetStatusBarColor(colors.blue[1], colors.blue[2], colors.blue[3], 0.95)
    hero.progress:SetMinMaxValues(0, 1)
    hero.progress:SetValue(0)
    hero.progressText = createFont(hero.progressBack, 9, colors.text, "CENTER")
    hero.progressText:SetAllPoints()

    drawer.passRequirement = CreateFrame("Frame", nil, drawer.passPanel, templateName())
    drawer.passRequirement:SetPoint("TOPLEFT", drawer.passPanel, "TOPLEFT", 0, -136)
    drawer.passRequirement:SetPoint("TOPRIGHT", drawer.passPanel, "TOPRIGHT", 0, -136)
    drawer.passRequirement:SetHeight(76)
    applyBackdrop(drawer.passRequirement, colors.panelSoft, colors.quest or colors.blue)
    drawer.passRequirement.title = createFont(drawer.passRequirement, 11, colors.text, "LEFT")
    drawer.passRequirement.title:SetPoint("TOPLEFT", drawer.passRequirement, "TOPLEFT", 10, -9)
    drawer.passRequirement.title:SetPoint("RIGHT", drawer.passRequirement, "RIGHT", -116, 0)
    drawer.passRequirement.detail = createFont(drawer.passRequirement, 8, colors.muted, "LEFT")
    drawer.passRequirement.detail:SetPoint("TOPLEFT", drawer.passRequirement.title, "BOTTOMLEFT", 0, -5)
    drawer.passRequirement.detail:SetPoint("BOTTOMRIGHT", drawer.passRequirement, "BOTTOMRIGHT", -116, 8)
    drawer.passRequirement.detail:SetWordWrap(true)
    drawer.passRequirement.action = createButton(drawer.passRequirement, "PLAY", 98, 29, function()
        Pass:StartRequirement(drawer.passRequirementLevel or 1)
    end)
    drawer.passRequirement.action:SetPoint("RIGHT", drawer.passRequirement, "RIGHT", -8, 0)

    drawer.goalBox = CreateFrame("Frame", nil, drawer.passPanel, templateName())
    drawer.goalBox:SetPoint("TOPLEFT", drawer.passPanel, "TOPLEFT", 0, -222)
    drawer.goalBox:SetPoint("TOPRIGHT", drawer.passPanel, "TOPRIGHT", 0, -222)
    drawer.goalBox:SetHeight(92)
    applyBackdrop(drawer.goalBox, colors.panelSoft, colors.border)
    drawer.goalBox.title = createFont(drawer.goalBox, 10, colors.text, "LEFT")
    drawer.goalBox.title:SetPoint("TOPLEFT", drawer.goalBox, "TOPLEFT", 9, -7)
    drawer.goalBox.title:SetText("EXPLORATION GOALS")
    drawer.goalBox.walk = createFont(drawer.goalBox, 8, colors.muted, "LEFT")
    drawer.goalBox.walk:SetPoint("TOPLEFT", drawer.goalBox, "TOPLEFT", 9, -27)
    drawer.goalBox.walk:SetPoint("RIGHT", drawer.goalBox, "RIGHT", -9, 0)
    drawer.goalBox.walkBar = CreateFrame("StatusBar", nil, drawer.goalBox)
    drawer.goalBox.walkBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    drawer.goalBox.walkBar:SetPoint("TOPLEFT", drawer.goalBox, "TOPLEFT", 9, -42)
    drawer.goalBox.walkBar:SetPoint("TOPRIGHT", drawer.goalBox, "TOPRIGHT", -9, -42)
    drawer.goalBox.walkBar:SetHeight(5)
    drawer.goalBox.kill = createFont(drawer.goalBox, 8, colors.muted, "LEFT")
    drawer.goalBox.kill:SetPoint("TOPLEFT", drawer.goalBox, "TOPLEFT", 9, -55)
    drawer.goalBox.kill:SetPoint("RIGHT", drawer.goalBox, "RIGHT", -9, 0)
    drawer.goalBox.killBar = CreateFrame("StatusBar", nil, drawer.goalBox)
    drawer.goalBox.killBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    drawer.goalBox.killBar:SetPoint("TOPLEFT", drawer.goalBox, "TOPLEFT", 9, -70)
    drawer.goalBox.killBar:SetPoint("TOPRIGHT", drawer.goalBox, "TOPRIGHT", -9, -70)
    drawer.goalBox.killBar:SetHeight(5)

    drawer.passFilter = drawer.passFilter or "ALL"
    drawer.passFilterBar = CreateFrame("Frame", nil, drawer.passPanel)
    drawer.passFilterBar:SetPoint("TOPLEFT", drawer.passPanel, "TOPLEFT", 0, -324)
    drawer.passFilterBar:SetPoint("TOPRIGHT", drawer.passPanel, "TOPRIGHT", 0, -324)
    drawer.passFilterBar:SetHeight(28)
    drawer.passFilterButtons = {}
    local passFilters = {
        { "ALL", "ALL", 54 }, { "READY", "READY", 64 },
        { "CLAIMED", "CLAIMED", 76 }, { "LOCKED", "LOCKED", 68 },
    }
    local previousFilter
    for _, filter in ipairs(passFilters) do
        local key, label, width = filter[1], filter[2], filter[3]
        local filterButton = createButton(drawer.passFilterBar, label, width, 24, function()
            drawer.passFilter = key
            Pass:RefreshDrawer()
            if CC.UI and CC.UI.SetGameDrawerScroll then CC.UI:SetGameDrawerScroll(0) end
        end)
        if previousFilter then filterButton:SetPoint("LEFT", previousFilter, "RIGHT", 4, 0)
        else filterButton:SetPoint("LEFT", drawer.passFilterBar, "LEFT", 0, 0) end
        drawer.passFilterButtons[key] = filterButton
        previousFilter = filterButton
    end

    drawer.passClaimAll = createButton(drawer.passPanel, "UNLOCK ALL READY", 138, 27, function() Pass:ClaimAllAvailable() end)
    drawer.passClaimAll:SetPoint("TOPRIGHT", drawer.passPanel, "TOPRIGHT", 0, -358)
    drawer.passSummary = createFont(drawer.passPanel, 9, colors.muted, "LEFT")
    drawer.passSummary:SetPoint("TOPLEFT", drawer.passPanel, "TOPLEFT", 2, -364)
    drawer.passSummary:SetPoint("RIGHT", drawer.passClaimAll, "LEFT", -8, 0)

    -- Create a small recycled pool (POOL_SIZE frames) instead of 200 static rows.
    drawer.passPool = {}
    drawer.passApi  = api
    for i = 1, POOL_SIZE do
        local row = CreateFrame("Button", nil, drawer.passPanel, templateName())
        row:SetHeight(49)
        row.assignedLevel = nil
        row.badge = CreateFrame("Frame", nil, row, templateName())
        row.badge:SetSize(38, 34)
        row.badge:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.badgeText = createFont(row.badge, 11, colors.muted, "CENTER")
        row.badgeText:SetAllPoints()
        row.title = createFont(row, 10, colors.text, "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 53, -8)
        row.title:SetPoint("RIGHT", row, "RIGHT", -98, 0)
        row.detail = createFont(row, 8, colors.muted, "LEFT")
        row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -3)
        row.detail:SetPoint("RIGHT", row, "RIGHT", -98, 0)
        row.button = createButton(row, "LOCKED", 82, 26, function()
            if row.assignedLevel then Pass:HandleRewardClick(row.assignedLevel) end
        end)
        row.button:SetPoint("RIGHT", row, "RIGHT", -7, 0)
        row:SetScript("OnClick", function()
            if row.assignedLevel then Pass:SelectRequirement(row.assignedLevel) end
        end)
        row:SetScript("OnEnter", function(selfRow)
            if selfRow.SetBackdropBorderColor then
                local accent = colors.quest or colors.blue
                selfRow:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
            end
        end)
        row:SetScript("OnLeave", function() Pass:RefreshDrawer() end)
        row:Hide()
        drawer.passPool[i] = row
    end
    -- Reposition pool frames when the scroll position changes.
    drawer.scroll:SetScript("OnVerticalScroll", function()
        if drawer.mode == "BATTLEPASS" then Pass:UpdatePassPool(drawer, false) end
    end)

    drawer.themesPanel = CreateFrame("Frame", nil, drawer.content)
    drawer.themesPanel:SetPoint("TOPLEFT", drawer.content, "TOPLEFT", 0, 0)
    drawer.themesPanel:SetPoint("TOPRIGHT", drawer.content, "TOPRIGHT", 0, 0)
    drawer.themesPanel:SetHeight(self:GetThemePanelHeight())
    drawer.themesPanel:Hide()

    local themeHero = CreateFrame("Frame", nil, drawer.themesPanel, templateName())
    themeHero:SetPoint("TOPLEFT", drawer.themesPanel, "TOPLEFT", 0, 0)
    themeHero:SetPoint("TOPRIGHT", drawer.themesPanel, "TOPRIGHT", 0, 0)
    themeHero:SetHeight(112)
    applyBackdrop(themeHero, darken(colors.quest or colors.blue, 0.48), colors.quest or colors.blue)
    drawer.themeHero = themeHero
    themeHero.title = createFont(themeHero, 16, colors.text, "LEFT")
    themeHero.title:SetPoint("TOPLEFT", themeHero, "TOPLEFT", 12, -10)
    themeHero.title:SetText("UNLOCK THEMES")
    themeHero.subtitle = createFont(themeHero, 9, colors.muted, "LEFT")
    themeHero.subtitle:SetPoint("TOPLEFT", themeHero.title, "BOTTOMLEFT", 0, -4)
    themeHero.subtitle:SetText("Only themes you still need to unlock are shown. Use PREVIEW to test a palette before spending Cresh Coins or claiming its reward.")
    themeHero.wallet = createFont(themeHero, 18, colors.text, "LEFT")
    themeHero.wallet:SetPoint("BOTTOMLEFT", themeHero, "BOTTOMLEFT", 12, 13)
    themeHero.earned = createFont(themeHero, 9, colors.muted, "RIGHT")
    themeHero.earned:SetPoint("BOTTOMRIGHT", themeHero, "BOTTOMRIGHT", -12, 17)

    drawer.themeEmpty = createFont(drawer.themesPanel, 13, colors.muted, "CENTER")
    drawer.themeEmpty:SetPoint("TOPLEFT", drawer.themesPanel, "TOPLEFT", 24, -170)
    drawer.themeEmpty:SetPoint("TOPRIGHT", drawer.themesPanel, "TOPRIGHT", -24, -170)
    drawer.themeEmpty:SetHeight(70)
    drawer.themeEmpty:SetWordWrap(true)
    drawer.themeEmpty:SetText("ALL THEMES UNLOCKED\nChoose and apply your owned themes from Settings > Themes.")
    drawer.themeEmpty:Hide()

    drawer.themeRows = {}
    for index, theme in ipairs(self.themeOrder) do
        local themeKey = theme
        local info = self.premiumThemes[themeKey]
        local row = CreateFrame("Frame", nil, drawer.themesPanel, templateName())
        row:SetPoint("TOPLEFT", drawer.themesPanel, "TOPLEFT", 0, -122 - ((index - 1) * 98))
        row:SetPoint("TOPRIGHT", drawer.themesPanel, "TOPRIGHT", 0, -122 - ((index - 1) * 98))
        row:SetHeight(90)
        applyBackdrop(row, colors.panelSoft, colors.border)
        row.theme = themeKey
        row.themeIndex = index
        row.swatches = {}
        for swatchIndex = 1, 3 do
            local swatch = CreateFrame("Frame", nil, row, templateName())
            swatch:SetSize(22, 54)
            swatch:SetPoint("LEFT", row, "LEFT", 8 + ((swatchIndex - 1) * 18), 0)
            local value = info.swatches[swatchIndex]
            applyBackdrop(swatch, value, swatchIndex == 2 and value or colors.border)
            row.swatches[swatchIndex] = swatch
        end
        row.title = createFont(row, 11, colors.text, "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 72, -10)
        row.title:SetText(info.name)
        row.note = createFont(row, 8, colors.muted, "LEFT")
        row.note:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4)
        row.note:SetPoint("RIGHT", row, "RIGHT", -176, 0)
        row.note:SetHeight(32)
        row.note:SetWordWrap(true)
        row.note:SetText(info.note)
        row.price = createFont(row, 10, colors.gold or colors.quest, "LEFT")
        row.price:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 72, 10)
        row.preview = createButton(row, "PREVIEW", 82, 28, function() Pass:ToggleThemePreview(themeKey) end)
        row.preview:SetPoint("RIGHT", row, "RIGHT", -96, 0)
        row.button = createButton(row, "UNLOCK", 82, 28, function()
            Pass.selectedTheme = themeKey
            Pass:BuyTheme(themeKey)
        end)
        row.button:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        drawer.themeRows[themeKey] = row
    end
end

function Pass:RefreshDrawerPanel(drawer, api)
    local save = self:Ensure()
    if not drawer or not save or not drawer.passPanel then return end
    local colors = api.colors
    local applyBackdrop = api.applyBackdrop
    local darken = api.darken
    local setAccent = api.setAccent

    applyBackdrop(drawer.passHero, darken(colors.blue, 0.42), colors.blue)
    applyBackdrop(drawer.themeHero, darken(colors.quest or colors.blue, 0.48), colors.quest or colors.blue)
    if drawer.passHero.progress and drawer.passHero.progress.SetStatusBarColor then
        drawer.passHero.progress:SetStatusBarColor(colors.blue[1], colors.blue[2], colors.blue[3], 0.95)
    end

    local level, current, required, ratio = self:GetProgress()
    drawer.passHero.level:SetText("LEVEL " .. level .. " / " .. self.maxLevel)
    drawer.passHero.wallet:SetText(self:GetWalletText() .. " CRESH COINS")
    drawer.passHero.progress:SetMinMaxValues(0, max(1, required))
    drawer.passHero.progress:SetValue(level >= self.maxLevel and required or current)
    drawer.passHero.progressText:SetText(level >= self.maxLevel and "BATTLE PASS COMPLETE" or (formatNumber(current) .. " / " .. formatNumber(required) .. " POINTS TO LEVEL " .. (level + 1)))
    if drawer.goalBox then
        local worldOn = CC.IsFeatureEnabled and CC:IsFeatureEnabled("worldProgression")
        if worldOn == false then
            drawer.goalBox.title:SetText("EXPLORATION GOALS (MODULE OFF)")
            drawer.goalBox.walk:SetText("World Progression is disabled in Settings > Modules. Walking goals are paused.")
            drawer.goalBox.kill:SetText("Kill goals are paused until World Progression is re-enabled.")
            drawer.goalBox.walkBar:SetMinMaxValues(0,1); drawer.goalBox.walkBar:SetValue(0)
            drawer.goalBox.killBar:SetMinMaxValues(0,1); drawer.goalBox.killBar:SetValue(0)
        else
            drawer.goalBox.title:SetText("EXPLORATION GOALS")
            local walk,walkValue=self:GetNextMilestone("WALK")
            local kill,killValue=self:GetNextMilestone("KILL")
            if walk then
                drawer.goalBox.walk:SetText(walk.title .. " · " .. formatNumber(walkValue) .. "/" .. formatNumber(walk.goal) .. " steps · +" .. walk.coins .. " coins / +" .. walk.xp .. " XP")
                drawer.goalBox.walkBar:SetMinMaxValues(0,walk.goal); drawer.goalBox.walkBar:SetValue(math.min(walk.goal,walkValue))
            else drawer.goalBox.walk:SetText("All walking goals completed"); drawer.goalBox.walkBar:SetMinMaxValues(0,1); drawer.goalBox.walkBar:SetValue(1) end
            if kill then
                drawer.goalBox.kill:SetText(kill.title .. " · " .. formatNumber(killValue) .. "/" .. formatNumber(kill.goal) .. " kills · +" .. kill.coins .. " coins / +" .. kill.xp .. " XP")
                drawer.goalBox.killBar:SetMinMaxValues(0,kill.goal); drawer.goalBox.killBar:SetValue(math.min(kill.goal,killValue))
            else drawer.goalBox.kill:SetText("All kill goals completed"); drawer.goalBox.killBar:SetMinMaxValues(0,1); drawer.goalBox.killBar:SetValue(1) end
        end
        drawer.goalBox.walkBar:SetStatusBarColor(colors.blue[1],colors.blue[2],colors.blue[3],0.95)
        drawer.goalBox.killBar:SetStatusBarColor(colors.quest[1],colors.quest[2],colors.quest[3],0.95)
    end

    if not self.selectedLevel then
        self.selectedLevel = min(self.maxLevel, max(1, level + (self:IsRewardClaimed(level) and 1 or 0)))
    end
    local selectedRequirement = self:GetRequirement(self.selectedLevel)
    drawer.passRequirementLevel = selectedRequirement.level
    local route = selectedRequirement.route
    local gamesOn = CC.IsFeatureEnabled and CC:IsFeatureEnabled("games")
    local routeOn = gamesOn and (route.mode ~= "MULTIPLAYER" or CC:IsFeatureEnabled("multiplayerGames"))
    if not selectedRequirement.reached and not routeOn then
        drawer.passRequirement.title:SetText("LEVEL " .. selectedRequirement.level .. " REQUIREMENT · MODULE OFF")
        drawer.passRequirement.detail:SetText("Games is disabled in Settings > Modules, so this requirement can't progress. Re-enable Games to continue the Battle Pass.")
        drawer.passRequirement.action.label:SetText("MODULE OFF")
        setButtonEnabled(drawer.passRequirement.action, false)
        applyBackdrop(drawer.passRequirement, darken(colors.muted, 0.78), colors.muted)
        if setAccent then setAccent(drawer.passRequirement.action, colors.muted) end
    else
        drawer.passRequirement.title:SetText("LEVEL " .. selectedRequirement.level .. " REQUIREMENT · " .. selectedRequirement.reward.title)
        drawer.passRequirement.detail:SetText(selectedRequirement.detail)
        drawer.passRequirement.action.label:SetText(selectedRequirement.reached and (self:IsRewardClaimed(selectedRequirement.level) and "VIEW COMPLETE" or "UNLOCK NOW") or route.action)
        setButtonEnabled(drawer.passRequirement.action, not (selectedRequirement.reached and self:IsRewardClaimed(selectedRequirement.level)))
        applyBackdrop(drawer.passRequirement, darken(selectedRequirement.reached and colors.green or (colors.quest or colors.blue), 0.78), selectedRequirement.reached and colors.green or (colors.quest or colors.blue))
        if setAccent then setAccent(drawer.passRequirement.action, selectedRequirement.reached and colors.green or (colors.quest or colors.blue)) end
    end

    local ready = 0
    for rewardLevel = 1, self.maxLevel do
        if self:IsLevelReached(rewardLevel) and not self:IsRewardClaimed(rewardLevel) then ready = ready + 1 end
    end
    drawer.passSummary:SetText(format("%s lifetime · %s games · %s exploration/goals · %d ready", formatNumber(save.lifetimeCoins), formatNumber(save.gameCoins), formatNumber(save.explorationCoins), ready))
    setButtonEnabled(drawer.passClaimAll, ready > 0)
    if setAccent then setAccent(drawer.passClaimAll, ready > 0 and (colors.quest or colors.blue) or colors.muted) end
    for key, filterButton in pairs(drawer.passFilterButtons or {}) do
        local active = (drawer.passFilter or "ALL") == key
        if setAccent then setAccent(filterButton, active and (colors.quest or colors.blue) or colors.border, active) end
    end

    drawer.passApi = api
    self:BuildPassLevelList(drawer)
    local filteredPassHeight = max(446, 446 + (#drawer.passLevelList * ROW_HEIGHT))
    drawer.passPanel:SetHeight(filteredPassHeight)
    if drawer.mode == "BATTLEPASS" and drawer.content then drawer.content:SetHeight(filteredPassHeight) end
    self:UpdatePassPool(drawer, true)

    drawer.themeHero.wallet:SetText(self:GetWalletText() .. " COINS AVAILABLE")
    drawer.themeHero.earned:SetText("LIFETIME " .. self:GetLifetimeText() .. "  ·  GAMES " .. formatNumber(save.gameCoins) .. "  ·  EXPLORE/GOALS " .. formatNumber(save.explorationCoins))
    local previewName = CC.UI and CC.UI.GetThemePreviewName and CC.UI:GetThemePreviewName() or nil
    local previewActive = CC.UI and CC.UI.IsThemePreviewActive and CC.UI:IsThemePreviewActive() or false
    local currentTheme = CC.db.ui and upper(tostring(CC.db.ui.themePreset or "")) or ""
    if previewActive and CC.UI and CC.UI.themePreview and CC.UI.themePreview.savedPreset then
        currentTheme = upper(tostring(CC.UI.themePreview.savedPreset or currentTheme))
    end

    local savedThemeScroll = drawer.mode == "THEMES" and drawer.scroll and (drawer.scroll:GetVerticalScroll() or 0) or nil
    local visibleIndex = 0
    for _, theme in ipairs(self.themeOrder or {}) do
        local row = drawer.themeRows and drawer.themeRows[theme]
        local info = self.premiumThemes[theme]
        local unlocked = self:IsThemeUnlocked(theme)
        if row then
            if unlocked then
                row:Hide()
                row.visibleThemeIndex = nil
            else
                visibleIndex = visibleIndex + 1
                row.visibleThemeIndex = visibleIndex
                row.themeIndex = visibleIndex
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", drawer.themesPanel, "TOPLEFT", 0, -122 - ((visibleIndex - 1) * 98))
                row:SetPoint("TOPRIGHT", drawer.themesPanel, "TOPRIGHT", 0, -122 - ((visibleIndex - 1) * 98))
                row:Show()

                local previewing = previewActive and previewName == theme
                local selected = self.selectedTheme == theme
                if previewing then
                    if info.source == "PASS" and info.level then
                        row.price:SetText("PREVIEW ACTIVE · BATTLE PASS LEVEL " .. tostring(info.level))
                    else
                        row.price:SetText("PREVIEW ACTIVE · " .. formatNumber(info.price) .. " CRESH COINS")
                    end
                elseif info.source == "PASS" and info.level then
                    row.price:SetText("BATTLE PASS LEVEL " .. tostring(info.level))
                else
                    row.price:SetText(formatNumber(info.price) .. " CRESH COINS")
                end
                if row.preview then
                    row.preview.label:SetText(previewing and "REVERT" or "PREVIEW")
                    setButtonEnabled(row.preview, true)
                    if setAccent then setAccent(row.preview, previewing and colors.green or (colors.quest or colors.blue)) end
                end
                if info.source == "PASS" and info.level then
                    local reached = self:IsLevelReached(info.level)
                    row.button.label:SetText(reached and "VIEW REWARD" or "VIEW LEVEL")
                    setButtonEnabled(row.button, true)
                    if setAccent then setAccent(row.button, reached and colors.green or (colors.quest or colors.blue)) end
                    applyBackdrop(row, colors.panelSoft, (previewing or selected) and (colors.quest or colors.blue) or colors.border)
                else
                    local canBuy = save.coins >= info.price
                    row.button.label:SetText(canBuy and "UNLOCK NOW" or ("NEED " .. formatNumber(info.price - save.coins)))
                    setButtonEnabled(row.button, canBuy)
                    if setAccent then setAccent(row.button, canBuy and (colors.quest or colors.blue) or colors.muted) end
                    applyBackdrop(row, colors.panelSoft, (previewing or selected) and (colors.quest or colors.blue) or colors.border)
                end
            end
        end
    end

    if drawer.themeEmpty then drawer.themeEmpty:SetShown(visibleIndex == 0) end
    local themeHeight = max(240, 140 + (visibleIndex * 98))
    drawer.themesPanel:SetHeight(themeHeight)
    drawer.visibleLockedThemeCount = visibleIndex
    if drawer.mode == "THEMES" and drawer.content then
        drawer.content:SetHeight(max(240, themeHeight))
    end
    if self.selectedTheme and self:IsThemeUnlocked(self.selectedTheme) then
        self.selectedTheme = nil
    end
    if savedThemeScroll ~= nil and CC.UI and CC.UI.SetGameDrawerScroll then
        CC.UI:SetGameDrawerScroll(savedThemeScroll)
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then
            _G.C_Timer.After(0, function()
                if CC.UI and CC.UI.SetGameDrawerScroll then CC.UI:SetGameDrawerScroll(savedThemeScroll) end
            end)
        end
    end
end

Pass.formatNumber = formatNumber
