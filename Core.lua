local ADDON_NAME, addonTable = ...
local CC = addonTable or {}
_G.CreshChat = CC

CC.name = ADDON_NAME or "CreshChat"
CC.BUILD = CC.BUILD or {
    version = "0.2.3",
    schema = 80,
    interface = 20505,
    stage = "Alpha",
}
CC.version = CC.BUILD.version
CC.schemaVersion = CC.BUILD.schema
CC.modules = CC.modules or {}
CC.Assets = CC.Assets or {}

function CC:RegisterModule(name, module)
    name = tostring(name or "")
    if name == "" or type(module) ~= "table" then return module end
    module.version = module.version or self.version
    self.modules[name] = module
    return module
end

function CC:GetModule(name)
    return self.modules and self.modules[tostring(name or "")] or nil
end

CC:RegisterModule("Core", CC)

CC.state = CC.state or {
    ready = false,
    playerName = "",
    playerFullName = "",
    unreadWhispers = 0,
    unreadGuild = 0,
    unreadGeneral = 0,
    unreadQuests = 0,
    lastWhisperTarget = nil,
    liveChatCount = 0,
    lastChatEvent = nil,
    lastChatAt = nil,
    registeredChatEvents = 0,
    whisperRedirects = 0,
}

local defaults = {
    version = CC.schemaVersion,
    hideBlizzard = true,
    bubbleVisible = true,
    sound = true,
    guildAlerts = "all", -- all, mentions, off
    alertDuration = 10,
    historyLimit = 120,
    combatHistoryLimit = 220,
    combatEnabled = true,
    quickChannel = "GENERAL",
    panelScale = 1,
    ui = {
        scale = 0.95,
        messageScale = 1,
        iconSize = 26,
        portraitStyle = "CLASS", -- CLASS, 2D, 3D
        showPortraits = true,
        showWhisperButton = false,
        showGeneralButton = false,
        showCombatButton = false,
        windowAnimation = "SLIDE_LEFT", -- animation preset for detached/main windows
        toastAnimation = "FAN_UP", -- overall notification-card entrance animation
        notificationCardsEnabled = true,
        notificationSlideDirection = "BOTTOM", -- TOP, BOTTOM, LEFT or RIGHT
        notificationScale = 0.95, -- resizes the full notification hub at once
        notificationLineHeight = 3,
        themePreset = "CRESH_MINIMAL", -- addon-inspired presets, WOW_CLASSIC, ZLR and CUSTOM
        groupedMessages = true,
        compactNavigation = true,
        composerAnimation = "SLIDE_DOCK", -- composer emerges from C
        dockAnimation = "SLIDE_DOCK", -- main chat emerges from the composer
        animationDuration = 0.20,
        openMainOnType = true,
        launcherOpensComposer = true,
        composerWidth = 360,
        composerScale = 1,
        composerLocked = false,
        composerAttached = true,
        composerShowPortrait = true,
        composerShowSend = false,
        composerCloseAfterSend = true,
        qcLayout = true,
        qualityProfile = "BALANCED", -- BALANCED, MINIMAL, MESSENGER, POPOUT, PERFORMANCE
        showBuildBadge = false,
        launcherMode = "SINGLE", -- SINGLE or EXPANDED
        launcherDefault = "LAST", -- LAST, CHAT, GAMES, ACHIEVEMENTS, or SETTINGS
        lastLauncherDest = nil, -- runtime-tracked, not a real default
        lastGameMode = "SOLO", -- remembers SOLO vs MULTIPLAYER for the games button
        showGamesButton = false, -- EXPANDED-mode satellite button (always shown when chat is disabled)
        showAchievementsButton = false, -- EXPANDED-mode satellite button (always shown when chat is disabled)
        showProgressButton = false, -- EXPANDED-mode satellite button for Progress Hub
        launcherNotificationPulse = true,
        launcherIdleFade = false,
        launcherIdleDelay = 5,
        launcherIdleAlpha = 0.18,
        launcherHideInCombat = false,
        autoArrange = false,
        shiftResize = true,
        minimalLayout = true,
        singleComposer = true,
        cardLocation = "DOCK", -- DOCK, MAIN, TOPLEFT, TOPRIGHT, BOTTOMLEFT, BOTTOMRIGHT, CUSTOM
        cardStack = "UP", -- UP or DOWN
        cardWidth = 300,
        cardHeight = 68,
        cardScale = 0.95,
        cardSpacing = 6,
        cardMaxVisible = 6,
        priorityCardDuration = 10,
        secondaryCardDuration = 6,
        secondaryCardMaxVisible = 4,
        secondaryCardWidthRatio = 0.88,
        secondaryCardHeightRatio = 0.80,
        cardHorizontal = "LEFT", -- LEFT, CENTER, RIGHT for SCREEN placement
        cardVertical = "BOTTOM", -- TOP, MIDDLE, BOTTOM for SCREEN placement
        cardCompact = true,
        cardCoalesce = true,
        showDockWhisperAlert = true,
        dockWhisperWidth = 190,
        dockWhisperDuration = 6,
        guildTheme = true,
        guildThemePreset = "AUTO", -- faction, green, nature and custom Guild palettes
        overheadBubbles = false,
        overheadBubbleMode = "VISIBLE", -- NEARBY, GROUP, VISIBLE
        overheadBubbleDuration = 5,
        overheadBubbleWidth = 180,
        overheadBubbleScale = 0.90,
        overheadBubbleGuildGreen = true,
        overheadBubbleSelf = true,
        cardLocked = false,
        nativeSlashCommands = true,
        commandHistory = true,
        showSystemCards = true,
        suppressOfflineWhisperErrors = true, -- hides only Blizzard's unavailable-player whisper line
        replacePartyInvitePopup = true,
        sharedDockWidth = 470, -- true on-screen width of C + the connected Blizzard command composer
        dockButtonWidth = 46,
        popoutWidth = 400,
        popoutStyle = "NORMAL", -- NORMAL uses messenger bubbles; COMPACT uses wrapped table rows
        popoutRows = 6,
        popoutRowHeight = 44,
        popoutShowCommand = true,
        popoutPrimary = false,
        rosterCollapsed = false, -- hides the left roster so chat can use the full console width
        showGameFriendsOnline = true,
        showGameFriendsOffline = true,
        showBattleNetFriendsOnline = true,
        showBattleNetFriendsOffline = true,
        showGuildMembersOnline = true,
        showGuildMembersOffline = true,
        popoutFade = false,
        popoutFadeDelay = 4,
        popoutFadeAlpha = 0.22,
        consoleTabs = {
            FRIENDS = true, WHISPER = true, GUILD = true, GENERAL = true, QUEST = true, COMBAT = true,
            TRADE = false, PARTY = false, RAID = false, INSTANCE = false, LFG = false,
            SAY = false, YELL = false, EMOTE = false, LOCALDEFENSE = false,
        },
    },
    notifications = {
        whisper = true,
        guild = true,
        quest = true,
        partyMessage = true,
        partyInvite = true,
        mentions = true,
        friends = true,
        system = true,
        game = true,
    },
    notificationPriorities = {
        whisper = "HIGH",
        guild = "NORMAL",
        quest = "HIGH",
        partyMessage = "HIGH",
        partyInvite = "CRITICAL",
        mentions = "NORMAL",
        friends = "LOW",
        system = "NORMAL",
        game = "LOW",
    },
    sounds = {
        master = true,
        whisper = true,
        guild = true,
        party = true, -- legacy alias for party invites
        partyInvite = true,
        partyMessage = true,
        quest = true,
        mentions = true,
        friends = true,
        game = true,
        system = false,
    },
    soundChoices = {
        whisper = "CRESH_CRYSTAL_01",
        guild = "CRESH_SOFT_BELL_02",
        partyInvite = "CRESH_ARCANE_02",
        partyMessage = "CRESH_WOOD_TICK_02",
        quest = "CRESH_SOFT_BELL_04",
        mentions = "CRESH_WOOD_TICK_02",
        friends = "CRESH_SOFT_BELL_01",
        game = "COIN",
        system = "OFF",
    },
    soundVolumes = {
        whisper = 0.65, guild = 0.55, partyInvite = 0.65,
        partyMessage = 0.50, quest = 0.55, mentions = 0.50,
        friends = 0.45, game = 0.55, system = 0.45,
    },
    gameAudio = { musicEnabled = true, musicVolume = 0.35, effectsEnabled = true, effectsVolume = 0.55 },
    voice = { enabled = true },
    colors = {
        panel = { 0.022, 0.026, 0.034, 0.96 },
        panelSoft = { 0.038, 0.044, 0.056, 0.96 },
        panelRaised = { 0.066, 0.074, 0.092, 0.98 },
        border = { 0.105, 0.120, 0.145, 0.95 },
        accent = { 0.130, 0.620, 0.950, 1.00 },
        incoming = { 0.070, 0.080, 0.100, 0.98 },
        outgoing = { 0.090, 0.430, 0.720, 0.98 },
        guild = {
            panel = { 0.018, 0.075, 0.038, 0.985 },
            panelSoft = { 0.026, 0.115, 0.055, 0.985 },
            panelRaised = { 0.040, 0.180, 0.082, 1.000 },
            border = { 0.090, 0.390, 0.185, 1.000 },
            accent = { 0.180, 0.780, 0.365, 1.000 },
            accentHover = { 0.260, 0.900, 0.455, 1.000 },
            incoming = { 0.032, 0.145, 0.068, 1.000 },
            outgoing = { 0.055, 0.315, 0.135, 1.000 },
            officer = { 0.390, 0.920, 0.555, 1.000 },
            muted = { 0.585, 0.790, 0.650, 1.000 },
        },
        channels = {
            GENERAL = { 0.35, 0.70, 1.00, 1.00 },
            TRADE = { 0.84, 0.62, 0.22, 1.00 },
            LOCALDEFENSE = { 0.88, 0.30, 0.26, 1.00 },
            LFG = { 0.70, 0.45, 0.95, 1.00 },
            SAY = { 0.92, 0.92, 0.92, 1.00 },
            YELL = { 1.00, 0.26, 0.26, 1.00 },
            PARTY = { 0.42, 0.68, 1.00, 1.00 },
            RAID = { 1.00, 0.50, 0.10, 1.00 },
            INSTANCE = { 1.00, 0.42, 0.78, 1.00 },
            GUILD = { 0.22, 0.82, 0.42, 1.00 },
            OFFICER = { 0.22, 0.78, 0.72, 1.00 },
            EMOTE = { 1.00, 0.50, 0.78, 1.00 },
            WHISPER = { 0.82, 0.42, 1.00, 1.00 },
            CHANNEL = { 0.48, 0.62, 0.82, 1.00 },
        },
    },
    playerCache = {},
    positions = {
        main = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 24, y = 150 },
        bubble = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 24, y = 92 },
        composer = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 72, y = 92 },
        alerts = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 18, y = 148 },
    },
    sizes = {
        main = { width = 470, height = 520 },
        combat = { width = 330, height = 250 },
        composer = { width = 424, height = 46 },
        popout = { width = 400, height = 238 },
        settings = { width = 740, height = 600 },
        card = { width = 300, height = 68 },
    },
    history = {
        whispers = {},
        guild = {},
        general = {},
        combat = {},
        quests = {},
    },
    conversations = {},
    questConversations = {},
    whisperRoutes = {},
    soloGames = {
        frogger = { unlocked = 1, bestLevel = 0, highScore = 0, games = 0 },
        holdem = { wins = 0, losses = 0, bestChips = 100, games = 0, bankroll = 100 },
        blackjack = { wins = 0, losses = 0, pushes = 0, bestBank = 100, games = 0, bankroll = 100 },
        dungeon = { runs = 0, bestLevel = 0, bestRoom = 0, kills = 0, bosses = 0, minions = 0, highScore = 0, bossCoins = 0, class = "", enemyKillsByType = {}, bossKillsByType = {}, firstBossKills = {}, unlockedArmour = {}, equippedArmour = {}, crateInventory = {}, crateHistory = {}, pendingCrates = {}, permanentDamage = 0, armourPity = 0, voidCratePity = 0, armourShards = 0, portraitTokens = 0, fullBodyTokens = 0, classStats = {}, classStatsMigrated = false, unlockedMinions = {}, minionRecruitsByType = {}, unlockedMinionSkins = {}, minionSkinRecruits = {}, discoveredItems = {}, battlePass = { xp = 0, claimed = {}, buffs = {}, activity = {}, visitedZones = {}, achievements = {}, recent = {} } },
        chess = { wins = 0, losses = 0, draws = 0, games = 0, level = 3, bestLevel = 0 },
        higherlower = { wins = 0, losses = 0, draws = 0, games = 0, bankroll = 100, bestBank = 100, bestStreak = 0 },
        tetris = { wins = 0, losses = 0, games = 0, highScore = 0, bestLines = 0, totalLines = 0, vsWins = 0, vsLosses = 0, endlessRuns = 0, cpuLevel = 3, cpuVersusMode = "ENDLESS", multiplayerMode = "ENDLESS", multiplayerDuration = 10, soloDuration = 10, mode = "ENDLESS", revealLines = 0, revealCompleted = 0, revealThemeKey = "", revealBackgroundKey = "", passXP = 0, passClaimed = {}, unlockedThemes = { CLASSIC_BLOCKS = true }, themeUnlockSources = { CLASSIC_BLOCKS = "DEFAULT" }, selectedTheme = "CLASSIC_BLOCKS", unlockedBackgrounds = {}, backgroundUnlockSources = {}, selectedBackground = "" },
    },
    arcadeRewards = {
        coins = 0,
        lifetimeCoins = 0,
        gameCoins = 0,
        activityCoins = 0,
        explorationCoins = 0,
        spentCoins = 0,
        passXP = 0,
        claimed = {},
        unlockedThemes = {},
        themeUnlockSources = {},
        recent = {},
        gamesRewarded = 0,
        milestoneGoals = {},
    },
    gameProgression = {
        games = {},
        exploration = { totalSteps = 0, rewardedStepBlocks = 0, distanceRemainder = 0, visitedAreas = {}, visitedZones = {}, newAreas = 0, newZones = 0, dungeonClears = 0, totalKills = 0, coins = 0, passXP = 0 },
        achievements = {},
    },
    gameHistory = {},
    gameLeaderboards = {},
    multiplayerStats = {},
    commandHistory = {},
    accountChat = {
        whispers = {},
        conversations = {},
        whisperRoutes = {},
        whisperKinds = {},
        whisperDisplayNames = {},
        battleNetRoutes = {},
        battleNetRouteKeys = {},
        battleNetFingerprints = {},
        battleNetFriends = {},
    },
    -- Feature flags: each key enables or disables a major subsystem.
    -- All default to true so upgrades see no behaviour change.
    features = {
        chat             = true,
        games            = true,
        multiplayerGames = true,
        gameProgression  = true,
        battlePass       = true,
        worldProgression = true,
        combatTracking   = true,
        questCapture     = true,
        friendsPresence  = true,
        voice            = true,
        notifications    = true,
        unifiedNotificationCards = false,
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local output = {}
    for key, child in pairs(value) do
        output[key] = deepCopy(child)
    end
    return output
end

local function mergeDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = deepCopy(value)
        elseif type(value) == "table" and type(target[key]) == "table" then
            mergeDefaults(target[key], value)
        end
    end
end

-- Character profiles keep progression and interface state separate for each alt
-- while retaining one account-wide SavedVariables file. The active profile is
-- rebound onto the legacy top-level fields so all existing modules continue to
-- use CC.db without requiring a large compatibility rewrite.
local PROFILE_UI_FIELDS = {
    "hideBlizzard", "bubbleVisible", "sound", "guildAlerts", "alertDuration",
    "historyLimit", "combatHistoryLimit", "combatEnabled", "quickChannel",
    "panelScale", "ui", "notifications", "notificationPriorities", "sounds", "soundChoices",
    "soundVolumes", "gameAudio", "voice", "colors", "playerCache",
    "positions", "sizes", "commandHistory", "features",
}

local PROFILE_PROGRESSION_FIELDS = {
    "soloGames", "arcadeRewards", "gameProgression", "gameHistory",
    "gameLeaderboards", "multiplayerStats", "cardDecks",
}

-- From schema 70 onward every game, currency, Battle Pass, unlock and
-- achievement table is shared by the whole account. Character profiles keep
-- their historical progression snapshots only as migration sources.
local function mergeAccountProgressionValue(target, source)
    if source == nil then return target end
    if target == nil then return deepCopy(source) end
    local targetType, sourceType = type(target), type(source)
    if targetType ~= sourceType then return target end
    if sourceType == "number" then return math.max(target, source) end
    if sourceType == "boolean" then return target or source end
    if sourceType == "string" then
        if target == "" and source ~= "" then return source end
        return target
    end
    if sourceType == "table" then
        for key, value in pairs(source) do
            target[key] = mergeAccountProgressionValue(target[key], value)
        end
    end
    return target
end

-- Explicit old-key → new stable-key map for every auto-generated achievement.
-- Keys in save.unlocked that match a left-hand entry are renamed to the right-hand
-- stable ID. This table is the single authoritative source for the v77 migration.
local ACHIEVEMENT_MIGRATION_V77 = {
    -- EXPLORATION / STEPS (10)
    ["EXPLORATION_STEPS_1000"]    = "ACH_WOW_STEPS_001",
    ["EXPLORATION_STEPS_2000"]    = "ACH_WOW_STEPS_002",
    ["EXPLORATION_STEPS_5000"]    = "ACH_WOW_STEPS_003",
    ["EXPLORATION_STEPS_10000"]   = "ACH_WOW_STEPS_004",
    ["EXPLORATION_STEPS_25000"]   = "ACH_WOW_STEPS_005",
    ["EXPLORATION_STEPS_50000"]   = "ACH_WOW_STEPS_006",
    ["EXPLORATION_STEPS_100000"]  = "ACH_WOW_STEPS_007",
    ["EXPLORATION_STEPS_250000"]  = "ACH_WOW_STEPS_008",
    ["EXPLORATION_STEPS_500000"]  = "ACH_WOW_STEPS_009",
    ["EXPLORATION_STEPS_1000000"] = "ACH_WOW_STEPS_010",
    -- EXPLORATION / ZONES (7)
    ["EXPLORATION_ZONES_1"]   = "ACH_WOW_ZONES_001",
    ["EXPLORATION_ZONES_5"]   = "ACH_WOW_ZONES_002",
    ["EXPLORATION_ZONES_10"]  = "ACH_WOW_ZONES_003",
    ["EXPLORATION_ZONES_25"]  = "ACH_WOW_ZONES_004",
    ["EXPLORATION_ZONES_50"]  = "ACH_WOW_ZONES_005",
    ["EXPLORATION_ZONES_75"]  = "ACH_WOW_ZONES_006",
    ["EXPLORATION_ZONES_100"] = "ACH_WOW_ZONES_007",
    -- EXPLORATION / FLIGHTS (7)
    ["EXPLORATION_FLIGHTS_1"]   = "ACH_WOW_FLIGHTS_001",
    ["EXPLORATION_FLIGHTS_5"]   = "ACH_WOW_FLIGHTS_002",
    ["EXPLORATION_FLIGHTS_10"]  = "ACH_WOW_FLIGHTS_003",
    ["EXPLORATION_FLIGHTS_25"]  = "ACH_WOW_FLIGHTS_004",
    ["EXPLORATION_FLIGHTS_50"]  = "ACH_WOW_FLIGHTS_005",
    ["EXPLORATION_FLIGHTS_100"] = "ACH_WOW_FLIGHTS_006",
    ["EXPLORATION_FLIGHTS_250"] = "ACH_WOW_FLIGHTS_007",
    -- COMBAT / KILLS (10)
    ["COMBAT_KILLS_10"]    = "ACH_WOW_KILLS_001",
    ["COMBAT_KILLS_25"]    = "ACH_WOW_KILLS_002",
    ["COMBAT_KILLS_50"]    = "ACH_WOW_KILLS_003",
    ["COMBAT_KILLS_100"]   = "ACH_WOW_KILLS_004",
    ["COMBAT_KILLS_250"]   = "ACH_WOW_KILLS_005",
    ["COMBAT_KILLS_500"]   = "ACH_WOW_KILLS_006",
    ["COMBAT_KILLS_1000"]  = "ACH_WOW_KILLS_007",
    ["COMBAT_KILLS_2500"]  = "ACH_WOW_KILLS_008",
    ["COMBAT_KILLS_5000"]  = "ACH_WOW_KILLS_009",
    ["COMBAT_KILLS_10000"] = "ACH_WOW_KILLS_010",
    -- COMBAT / DEATHS (6)
    ["COMBAT_DEATHS_1"]   = "ACH_WOW_DEATHS_001",
    ["COMBAT_DEATHS_5"]   = "ACH_WOW_DEATHS_002",
    ["COMBAT_DEATHS_10"]  = "ACH_WOW_DEATHS_003",
    ["COMBAT_DEATHS_25"]  = "ACH_WOW_DEATHS_004",
    ["COMBAT_DEATHS_50"]  = "ACH_WOW_DEATHS_005",
    ["COMBAT_DEATHS_100"] = "ACH_WOW_DEATHS_006",
    -- DUNGEONS / EXP|WOW_DUNGEON_MOBS| (10)
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_10"]    = "ACH_WOW_DUNGEON_MOBS_001",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_25"]    = "ACH_WOW_DUNGEON_MOBS_002",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_50"]    = "ACH_WOW_DUNGEON_MOBS_003",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_100"]   = "ACH_WOW_DUNGEON_MOBS_004",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_250"]   = "ACH_WOW_DUNGEON_MOBS_005",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_500"]   = "ACH_WOW_DUNGEON_MOBS_006",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_1000"]  = "ACH_WOW_DUNGEON_MOBS_007",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_2500"]  = "ACH_WOW_DUNGEON_MOBS_008",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_5000"]  = "ACH_WOW_DUNGEON_MOBS_009",
    ["DUNGEONS_EXP|WOW_DUNGEON_MOBS|_10000"] = "ACH_WOW_DUNGEON_MOBS_010",
    -- DUNGEONS / EXP|WOW_DUNGEON_BOSSES| (9)
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_1"]   = "ACH_WOW_DUNGEON_BOSSES_001",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_3"]   = "ACH_WOW_DUNGEON_BOSSES_002",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_5"]   = "ACH_WOW_DUNGEON_BOSSES_003",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_10"]  = "ACH_WOW_DUNGEON_BOSSES_004",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_25"]  = "ACH_WOW_DUNGEON_BOSSES_005",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_50"]  = "ACH_WOW_DUNGEON_BOSSES_006",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_100"] = "ACH_WOW_DUNGEON_BOSSES_007",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_250"] = "ACH_WOW_DUNGEON_BOSSES_008",
    ["DUNGEONS_EXP|WOW_DUNGEON_BOSSES|_500"] = "ACH_WOW_DUNGEON_BOSSES_009",
    -- DUNGEONS / EXP|UNIQUE_DUNGEON_FINAL_BOSSES| (7)
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_1"]  = "ACH_WOW_UNIQUE_FINAL_BOSSES_001",
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_3"]  = "ACH_WOW_UNIQUE_FINAL_BOSSES_002",
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_5"]  = "ACH_WOW_UNIQUE_FINAL_BOSSES_003",
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_8"]  = "ACH_WOW_UNIQUE_FINAL_BOSSES_004",
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_10"] = "ACH_WOW_UNIQUE_FINAL_BOSSES_005",
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_12"] = "ACH_WOW_UNIQUE_FINAL_BOSSES_006",
    ["DUNGEONS_EXP|UNIQUE_DUNGEON_FINAL_BOSSES|_15"] = "ACH_WOW_UNIQUE_FINAL_BOSSES_007",
    -- DUNGEONS / EXP|WOW_DUNGEON_COMPLETES_TOTAL| (7)
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_1"]   = "ACH_WOW_DUNGEON_CLEARS_001",
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_5"]   = "ACH_WOW_DUNGEON_CLEARS_002",
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_10"]  = "ACH_WOW_DUNGEON_CLEARS_003",
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_25"]  = "ACH_WOW_DUNGEON_CLEARS_004",
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_50"]  = "ACH_WOW_DUNGEON_CLEARS_005",
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_100"] = "ACH_WOW_DUNGEON_CLEARS_006",
    ["DUNGEONS_EXP|WOW_DUNGEON_COMPLETES_TOTAL|_250"] = "ACH_WOW_DUNGEON_CLEARS_007",
    -- PROFESSIONS / PROFESSION_RANK (4)
    ["PROFESSIONS_PROFESSION_RANK_75"]  = "ACH_WOW_PROF_RANK_001",
    ["PROFESSIONS_PROFESSION_RANK_150"] = "ACH_WOW_PROF_RANK_002",
    ["PROFESSIONS_PROFESSION_RANK_225"] = "ACH_WOW_PROF_RANK_003",
    ["PROFESSIONS_PROFESSION_RANK_300"] = "ACH_WOW_PROF_RANK_004",
    -- PROFESSIONS / PROFESSION_COUNT (4)
    ["PROFESSIONS_PROFESSION_COUNT_1"] = "ACH_WOW_PROF_COUNT_001",
    ["PROFESSIONS_PROFESSION_COUNT_2"] = "ACH_WOW_PROF_COUNT_002",
    ["PROFESSIONS_PROFESSION_COUNT_4"] = "ACH_WOW_PROF_COUNT_003",
    ["PROFESSIONS_PROFESSION_COUNT_6"] = "ACH_WOW_PROF_COUNT_004",
    -- PROFESSIONS / MASTER_PROFESSIONS (4)
    ["PROFESSIONS_MASTER_PROFESSIONS_1"] = "ACH_WOW_PROF_MASTER_001",
    ["PROFESSIONS_MASTER_PROFESSIONS_2"] = "ACH_WOW_PROF_MASTER_002",
    ["PROFESSIONS_MASTER_PROFESSIONS_4"] = "ACH_WOW_PROF_MASTER_003",
    ["PROFESSIONS_MASTER_PROFESSIONS_6"] = "ACH_WOW_PROF_MASTER_004",
    -- GAMES / DD_KILLS (10)
    ["GAMES_DD_KILLS_10"]    = "ACH_DD_KILLS_001",
    ["GAMES_DD_KILLS_25"]    = "ACH_DD_KILLS_002",
    ["GAMES_DD_KILLS_50"]    = "ACH_DD_KILLS_003",
    ["GAMES_DD_KILLS_100"]   = "ACH_DD_KILLS_004",
    ["GAMES_DD_KILLS_250"]   = "ACH_DD_KILLS_005",
    ["GAMES_DD_KILLS_500"]   = "ACH_DD_KILLS_006",
    ["GAMES_DD_KILLS_1000"]  = "ACH_DD_KILLS_007",
    ["GAMES_DD_KILLS_2500"]  = "ACH_DD_KILLS_008",
    ["GAMES_DD_KILLS_5000"]  = "ACH_DD_KILLS_009",
    ["GAMES_DD_KILLS_10000"] = "ACH_DD_KILLS_010",
    -- GAMES / DD_BOSSES (9)
    ["GAMES_DD_BOSSES_1"]   = "ACH_DD_BOSSES_001",
    ["GAMES_DD_BOSSES_3"]   = "ACH_DD_BOSSES_002",
    ["GAMES_DD_BOSSES_5"]   = "ACH_DD_BOSSES_003",
    ["GAMES_DD_BOSSES_10"]  = "ACH_DD_BOSSES_004",
    ["GAMES_DD_BOSSES_25"]  = "ACH_DD_BOSSES_005",
    ["GAMES_DD_BOSSES_50"]  = "ACH_DD_BOSSES_006",
    ["GAMES_DD_BOSSES_100"] = "ACH_DD_BOSSES_007",
    ["GAMES_DD_BOSSES_250"] = "ACH_DD_BOSSES_008",
    ["GAMES_DD_BOSSES_500"] = "ACH_DD_BOSSES_009",
    -- GAMES / DD_UNIQUE_BOSSES (7)
    ["GAMES_DD_UNIQUE_BOSSES_1"]   = "ACH_DD_UNIQUE_BOSSES_001",
    ["GAMES_DD_UNIQUE_BOSSES_5"]   = "ACH_DD_UNIQUE_BOSSES_002",
    ["GAMES_DD_UNIQUE_BOSSES_10"]  = "ACH_DD_UNIQUE_BOSSES_003",
    ["GAMES_DD_UNIQUE_BOSSES_25"]  = "ACH_DD_UNIQUE_BOSSES_004",
    ["GAMES_DD_UNIQUE_BOSSES_50"]  = "ACH_DD_UNIQUE_BOSSES_005",
    ["GAMES_DD_UNIQUE_BOSSES_75"]  = "ACH_DD_UNIQUE_BOSSES_006",
    ["GAMES_DD_UNIQUE_BOSSES_100"] = "ACH_DD_UNIQUE_BOSSES_007",
    -- GAMES / DD_RUNS (7)
    ["GAMES_DD_RUNS_1"]   = "ACH_DD_RUNS_001",
    ["GAMES_DD_RUNS_5"]   = "ACH_DD_RUNS_002",
    ["GAMES_DD_RUNS_10"]  = "ACH_DD_RUNS_003",
    ["GAMES_DD_RUNS_25"]  = "ACH_DD_RUNS_004",
    ["GAMES_DD_RUNS_50"]  = "ACH_DD_RUNS_005",
    ["GAMES_DD_RUNS_100"] = "ACH_DD_RUNS_006",
    ["GAMES_DD_RUNS_250"] = "ACH_DD_RUNS_007",
    -- GAMES / GAME_PLAYS (6)
    ["GAMES_GAME_PLAYS_1"]   = "ACH_WOW_GAME_PLAYS_001",
    ["GAMES_GAME_PLAYS_10"]  = "ACH_WOW_GAME_PLAYS_002",
    ["GAMES_GAME_PLAYS_25"]  = "ACH_WOW_GAME_PLAYS_003",
    ["GAMES_GAME_PLAYS_50"]  = "ACH_WOW_GAME_PLAYS_004",
    ["GAMES_GAME_PLAYS_100"] = "ACH_WOW_GAME_PLAYS_005",
    ["GAMES_GAME_PLAYS_250"] = "ACH_WOW_GAME_PLAYS_006",
    -- GAMES / GAME_WINS (5)
    ["GAMES_GAME_WINS_1"]   = "ACH_WOW_GAME_WINS_001",
    ["GAMES_GAME_WINS_10"]  = "ACH_WOW_GAME_WINS_002",
    ["GAMES_GAME_WINS_25"]  = "ACH_WOW_GAME_WINS_003",
    ["GAMES_GAME_WINS_50"]  = "ACH_WOW_GAME_WINS_004",
    ["GAMES_GAME_WINS_100"] = "ACH_WOW_GAME_WINS_005",
    -- GAMES / GAME_LEVELS (6)
    ["GAMES_GAME_LEVELS_5"]   = "ACH_WOW_GAME_LEVELS_001",
    ["GAMES_GAME_LEVELS_10"]  = "ACH_WOW_GAME_LEVELS_002",
    ["GAMES_GAME_LEVELS_25"]  = "ACH_WOW_GAME_LEVELS_003",
    ["GAMES_GAME_LEVELS_50"]  = "ACH_WOW_GAME_LEVELS_004",
    ["GAMES_GAME_LEVELS_100"] = "ACH_WOW_GAME_LEVELS_005",
    ["GAMES_GAME_LEVELS_250"] = "ACH_WOW_GAME_LEVELS_006",
    -- GAMES / UNLOCKS (6)
    ["GAMES_UNLOCKS_1"]   = "ACH_WOW_UNLOCKS_001",
    ["GAMES_UNLOCKS_5"]   = "ACH_WOW_UNLOCKS_002",
    ["GAMES_UNLOCKS_10"]  = "ACH_WOW_UNLOCKS_003",
    ["GAMES_UNLOCKS_25"]  = "ACH_WOW_UNLOCKS_004",
    ["GAMES_UNLOCKS_50"]  = "ACH_WOW_UNLOCKS_005",
    ["GAMES_UNLOCKS_100"] = "ACH_WOW_UNLOCKS_006",
}

-- Idempotent: skips when shared.migratedSchema >= 77. Renames every legacy
-- auto-generated achievement key to its stable ACH_WOW_* / ACH_DD_* equivalent.
-- Never calls AddCoins or AddPassXP — progress is preserved, not re-awarded.
-- When both old and new records coexist, the earlier unlock timestamp is kept
-- and the higher stat value is kept; the old key is then removed.
local function MigrateToV77(shared)
    if tonumber(shared.migratedSchema or 0) >= 77 then return 0 end
    local gameProgression = type(shared.gameProgression) == "table" and shared.gameProgression or nil
    if not gameProgression then shared.migratedSchema = 77; return 0 end
    local achievements = type(gameProgression.achievements) == "table" and gameProgression.achievements or nil
    if not achievements then shared.migratedSchema = 77; return 0 end
    local unlocked = type(achievements.unlocked) == "table" and achievements.unlocked or nil
    if not unlocked then shared.migratedSchema = 77; return 0 end

    local migrated = 0
    for oldKey, newKey in pairs(ACHIEVEMENT_MIGRATION_V77) do
        local oldRecord = unlocked[oldKey]
        if oldRecord then
            local newRecord = unlocked[newKey]
            if not newRecord then
                if type(oldRecord) == "table" then oldRecord.sourceId = newKey end
                unlocked[newKey] = oldRecord
            else
                -- Both keys present: keep the earliest unlock time, highest value.
                if type(oldRecord) == "table" and type(newRecord) == "table" then
                    local oldAt = tonumber(oldRecord.at) or 0
                    local newAt = tonumber(newRecord.at) or 0
                    if oldAt > 0 and (newAt == 0 or oldAt < newAt) then newRecord.at = oldAt end
                    local oldVal = tonumber(oldRecord.value) or 0
                    local newVal = tonumber(newRecord.value) or 0
                    if oldVal > newVal then newRecord.value = oldVal end
                end
            end
            unlocked[oldKey] = nil
            migrated = migrated + 1
        end
    end

    shared.migratedSchema = 77
    if migrated > 0 then shared._v77MigrationCount = migrated end
    return migrated
end

-- Renames all CLASS_*_NNN achievement keys to the stable ACH_CLASS_*_NNN format
-- and resequences hunter/mage/paladin/… offsets to per-class 001-010 numbers.
-- Idempotent: skips when shared.migratedSchema >= 78.
local ACHIEVEMENT_MIGRATION_V78 = {
    -- DRUID (001-010, no resequence)
    ["CLASS_DRUID_001"]="ACH_CLASS_DRUID_001", ["CLASS_DRUID_002"]="ACH_CLASS_DRUID_002",
    ["CLASS_DRUID_003"]="ACH_CLASS_DRUID_003", ["CLASS_DRUID_004"]="ACH_CLASS_DRUID_004",
    ["CLASS_DRUID_005"]="ACH_CLASS_DRUID_005", ["CLASS_DRUID_006"]="ACH_CLASS_DRUID_006",
    ["CLASS_DRUID_007"]="ACH_CLASS_DRUID_007", ["CLASS_DRUID_008"]="ACH_CLASS_DRUID_008",
    ["CLASS_DRUID_009"]="ACH_CLASS_DRUID_009", ["CLASS_DRUID_010"]="ACH_CLASS_DRUID_010",
    -- HUNTER (011-020 → 001-010)
    ["CLASS_HUNTER_011"]="ACH_CLASS_HUNTER_001", ["CLASS_HUNTER_012"]="ACH_CLASS_HUNTER_002",
    ["CLASS_HUNTER_013"]="ACH_CLASS_HUNTER_003", ["CLASS_HUNTER_014"]="ACH_CLASS_HUNTER_004",
    ["CLASS_HUNTER_015"]="ACH_CLASS_HUNTER_005", ["CLASS_HUNTER_016"]="ACH_CLASS_HUNTER_006",
    ["CLASS_HUNTER_017"]="ACH_CLASS_HUNTER_007", ["CLASS_HUNTER_018"]="ACH_CLASS_HUNTER_008",
    ["CLASS_HUNTER_019"]="ACH_CLASS_HUNTER_009", ["CLASS_HUNTER_020"]="ACH_CLASS_HUNTER_010",
    -- MAGE (021-030 → 001-010)
    ["CLASS_MAGE_021"]="ACH_CLASS_MAGE_001", ["CLASS_MAGE_022"]="ACH_CLASS_MAGE_002",
    ["CLASS_MAGE_023"]="ACH_CLASS_MAGE_003", ["CLASS_MAGE_024"]="ACH_CLASS_MAGE_004",
    ["CLASS_MAGE_025"]="ACH_CLASS_MAGE_005", ["CLASS_MAGE_026"]="ACH_CLASS_MAGE_006",
    ["CLASS_MAGE_027"]="ACH_CLASS_MAGE_007", ["CLASS_MAGE_028"]="ACH_CLASS_MAGE_008",
    ["CLASS_MAGE_029"]="ACH_CLASS_MAGE_009", ["CLASS_MAGE_030"]="ACH_CLASS_MAGE_010",
    -- PALADIN (031-040 → 001-010)
    ["CLASS_PALADIN_031"]="ACH_CLASS_PALADIN_001", ["CLASS_PALADIN_032"]="ACH_CLASS_PALADIN_002",
    ["CLASS_PALADIN_033"]="ACH_CLASS_PALADIN_003", ["CLASS_PALADIN_034"]="ACH_CLASS_PALADIN_004",
    ["CLASS_PALADIN_035"]="ACH_CLASS_PALADIN_005", ["CLASS_PALADIN_036"]="ACH_CLASS_PALADIN_006",
    ["CLASS_PALADIN_037"]="ACH_CLASS_PALADIN_007", ["CLASS_PALADIN_038"]="ACH_CLASS_PALADIN_008",
    ["CLASS_PALADIN_039"]="ACH_CLASS_PALADIN_009", ["CLASS_PALADIN_040"]="ACH_CLASS_PALADIN_010",
    -- PRIEST (041-050 → 001-010)
    ["CLASS_PRIEST_041"]="ACH_CLASS_PRIEST_001", ["CLASS_PRIEST_042"]="ACH_CLASS_PRIEST_002",
    ["CLASS_PRIEST_043"]="ACH_CLASS_PRIEST_003", ["CLASS_PRIEST_044"]="ACH_CLASS_PRIEST_004",
    ["CLASS_PRIEST_045"]="ACH_CLASS_PRIEST_005", ["CLASS_PRIEST_046"]="ACH_CLASS_PRIEST_006",
    ["CLASS_PRIEST_047"]="ACH_CLASS_PRIEST_007", ["CLASS_PRIEST_048"]="ACH_CLASS_PRIEST_008",
    ["CLASS_PRIEST_049"]="ACH_CLASS_PRIEST_009", ["CLASS_PRIEST_050"]="ACH_CLASS_PRIEST_010",
    -- ROGUE (051-060 → 001-010)
    ["CLASS_ROGUE_051"]="ACH_CLASS_ROGUE_001", ["CLASS_ROGUE_052"]="ACH_CLASS_ROGUE_002",
    ["CLASS_ROGUE_053"]="ACH_CLASS_ROGUE_003", ["CLASS_ROGUE_054"]="ACH_CLASS_ROGUE_004",
    ["CLASS_ROGUE_055"]="ACH_CLASS_ROGUE_005", ["CLASS_ROGUE_056"]="ACH_CLASS_ROGUE_006",
    ["CLASS_ROGUE_057"]="ACH_CLASS_ROGUE_007", ["CLASS_ROGUE_058"]="ACH_CLASS_ROGUE_008",
    ["CLASS_ROGUE_059"]="ACH_CLASS_ROGUE_009", ["CLASS_ROGUE_060"]="ACH_CLASS_ROGUE_010",
    -- SHAMAN (061-070 → 001-010)
    ["CLASS_SHAMAN_061"]="ACH_CLASS_SHAMAN_001", ["CLASS_SHAMAN_062"]="ACH_CLASS_SHAMAN_002",
    ["CLASS_SHAMAN_063"]="ACH_CLASS_SHAMAN_003", ["CLASS_SHAMAN_064"]="ACH_CLASS_SHAMAN_004",
    ["CLASS_SHAMAN_065"]="ACH_CLASS_SHAMAN_005", ["CLASS_SHAMAN_066"]="ACH_CLASS_SHAMAN_006",
    ["CLASS_SHAMAN_067"]="ACH_CLASS_SHAMAN_007", ["CLASS_SHAMAN_068"]="ACH_CLASS_SHAMAN_008",
    ["CLASS_SHAMAN_069"]="ACH_CLASS_SHAMAN_009", ["CLASS_SHAMAN_070"]="ACH_CLASS_SHAMAN_010",
    -- WARLOCK (071-080 → 001-010)
    ["CLASS_WARLOCK_071"]="ACH_CLASS_WARLOCK_001", ["CLASS_WARLOCK_072"]="ACH_CLASS_WARLOCK_002",
    ["CLASS_WARLOCK_073"]="ACH_CLASS_WARLOCK_003", ["CLASS_WARLOCK_074"]="ACH_CLASS_WARLOCK_004",
    ["CLASS_WARLOCK_075"]="ACH_CLASS_WARLOCK_005", ["CLASS_WARLOCK_076"]="ACH_CLASS_WARLOCK_006",
    ["CLASS_WARLOCK_077"]="ACH_CLASS_WARLOCK_007", ["CLASS_WARLOCK_078"]="ACH_CLASS_WARLOCK_008",
    ["CLASS_WARLOCK_079"]="ACH_CLASS_WARLOCK_009", ["CLASS_WARLOCK_080"]="ACH_CLASS_WARLOCK_010",
    -- WARRIOR (081-090 → 001-010)
    ["CLASS_WARRIOR_081"]="ACH_CLASS_WARRIOR_001", ["CLASS_WARRIOR_082"]="ACH_CLASS_WARRIOR_002",
    ["CLASS_WARRIOR_083"]="ACH_CLASS_WARRIOR_003", ["CLASS_WARRIOR_084"]="ACH_CLASS_WARRIOR_004",
    ["CLASS_WARRIOR_085"]="ACH_CLASS_WARRIOR_005", ["CLASS_WARRIOR_086"]="ACH_CLASS_WARRIOR_006",
    ["CLASS_WARRIOR_087"]="ACH_CLASS_WARRIOR_007", ["CLASS_WARRIOR_088"]="ACH_CLASS_WARRIOR_008",
    ["CLASS_WARRIOR_089"]="ACH_CLASS_WARRIOR_009", ["CLASS_WARRIOR_090"]="ACH_CLASS_WARRIOR_010",
}

local function MigrateToV78(shared)
    if tonumber(shared.migratedSchema or 0) >= 78 then return 0 end
    local gameProgression = type(shared.gameProgression) == "table" and shared.gameProgression or nil
    if not gameProgression then shared.migratedSchema = 78; return 0 end
    local achievements = type(gameProgression.achievements) == "table" and gameProgression.achievements or nil
    if not achievements then shared.migratedSchema = 78; return 0 end
    local unlocked = type(achievements.unlocked) == "table" and achievements.unlocked or nil
    if not unlocked then shared.migratedSchema = 78; return 0 end

    local migrated = 0
    for oldKey, newKey in pairs(ACHIEVEMENT_MIGRATION_V78) do
        local oldRecord = unlocked[oldKey]
        if oldRecord then
            local newRecord = unlocked[newKey]
            if not newRecord then
                if type(oldRecord) == "table" then oldRecord.sourceId = newKey end
                unlocked[newKey] = oldRecord
            else
                if type(oldRecord) == "table" and type(newRecord) == "table" then
                    local oldAt = tonumber(oldRecord.at) or 0
                    local newAt = tonumber(newRecord.at) or 0
                    if oldAt > 0 and (newAt == 0 or oldAt < newAt) then newRecord.at = oldAt end
                    local oldVal = tonumber(oldRecord.value) or 0
                    local newVal = tonumber(newRecord.value) or 0
                    if oldVal > newVal then newRecord.value = oldVal end
                end
            end
            unlocked[oldKey] = nil
            migrated = migrated + 1
        end
    end

    shared.migratedSchema = 78
    if migrated > 0 then shared._v78MigrationCount = migrated end
    return migrated
end

function CC:EnsureAccountProgressionStorage(forceMigration)
    CreshChatDB = CreshChatDB or {}
    CreshChatDB.accountProgression = type(CreshChatDB.accountProgression) == "table" and CreshChatDB.accountProgression or {}
    local shared = CreshChatDB.accountProgression
    local needsMigration = forceMigration or tonumber(shared.migratedSchema or 0) < 70
    if needsMigration then
        for _, field in ipairs(PROFILE_PROGRESSION_FIELDS) do
            local combined = {}
            combined = mergeAccountProgressionValue(combined, CreshChatDB[field])
            for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
                if profile.progression then
                    combined = mergeAccountProgressionValue(combined, profile.progression[field])
                end
            end
            mergeDefaults(combined, defaults[field] or {})
            shared[field] = combined
        end
        shared.migratedSchema = 70
        shared.migratedAt = time and time() or 0
    else
        for _, field in ipairs(PROFILE_PROGRESSION_FIELDS) do
            shared[field] = type(shared[field]) == "table" and shared[field] or {}
            mergeDefaults(shared[field], defaults[field] or {})
        end
    end
    MigrateToV77(shared)
    MigrateToV78(shared)
    return shared
end

function CC:BindAccountProgressionStorage()
    local shared = self:EnsureAccountProgressionStorage(false)
    for _, field in ipairs(PROFILE_PROGRESSION_FIELDS) do
        CreshChatDB[field] = shared[field]
    end
    return shared
end

-- Only local/session feeds remain character-specific. Direct-message history is
-- rebound to one account-wide store so every alt sees the same conversations.
local PROFILE_CHAT_FIELDS = {
    "history", "questConversations",
}

function CC:EnsureAccountWhisperStorage()
    CreshChatDB = CreshChatDB or {}
    CreshChatDB.accountChat = type(CreshChatDB.accountChat) == "table" and CreshChatDB.accountChat or {}
    local shared = CreshChatDB.accountChat
    shared.whispers = type(shared.whispers) == "table" and shared.whispers or {}
    shared.conversations = type(shared.conversations) == "table" and shared.conversations or {}
    shared.whisperRoutes = type(shared.whisperRoutes) == "table" and shared.whisperRoutes or {}
    shared.whisperKinds = type(shared.whisperKinds) == "table" and shared.whisperKinds or {}
    shared.whisperDisplayNames = type(shared.whisperDisplayNames) == "table" and shared.whisperDisplayNames or {}
    shared.battleNetRoutes = type(shared.battleNetRoutes) == "table" and shared.battleNetRoutes or {}
    shared.battleNetRouteKeys = type(shared.battleNetRouteKeys) == "table" and shared.battleNetRouteKeys or {}
    shared.battleNetFingerprints = type(shared.battleNetFingerprints) == "table" and shared.battleNetFingerprints or {}
    shared.battleNetFriends = type(shared.battleNetFriends) == "table" and shared.battleNetFriends or {}
    -- Account-level social data. Blizzard Battle.net friends are already account-wide,
    -- while ordinary WoW character friends can differ by character/client. CreshChat
    -- mirrors every observed or manually-added character friend here so all alts see
    -- one consistent Friends directory without changing Blizzard's own list.
    shared.accountFriends = type(shared.accountFriends) == "table" and shared.accountFriends or {}
    shared.removedAccountFriends = type(shared.removedAccountFriends) == "table" and shared.removedAccountFriends or {}
    shared.characterBattleNetLinks = type(shared.characterBattleNetLinks) == "table" and shared.characterBattleNetLinks or {}
    shared.battleNetCharacters = type(shared.battleNetCharacters) == "table" and shared.battleNetCharacters or {}

    -- Repair builds that wrote social data through the old top-level aliases.
    -- This runs on every login, not only during a one-time schema migration.
    local function mergeLegacyTable(field)
        local legacy = rawget(CreshChatDB, field)
        if type(legacy) ~= "table" or legacy == shared[field] then return end
        for key, value in pairs(legacy) do
            if shared[field][key] == nil then shared[field][key] = value end
        end
    end
    mergeLegacyTable("accountFriends")
    mergeLegacyTable("removedAccountFriends")
    mergeLegacyTable("characterBattleNetLinks")
    mergeLegacyTable("battleNetCharacters")
    mergeLegacyTable("battleNetFriends")
    return shared
end

function CC:AccountFriendKey(name)
    local clean = self:CleanPlayerName(name)
    if clean == "" then return nil end
    return string.lower(clean)
end

function CC:RememberAccountFriend(name, metadata)
    local clean = self:CleanPlayerName(name)
    local key = self:AccountFriendKey(clean)
    if not key then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    metadata = type(metadata) == "table" and metadata or {}

    -- Reuse an existing short/full-realm record instead of showing duplicates.
    for existingKey, existing in pairs(shared.accountFriends) do
        if existing and self:WhisperNamesEquivalent(existing.name or existingKey, clean) then key = existingKey; break end
    end
    local removedKey
    for existingKey in pairs(shared.removedAccountFriends) do
        if self:WhisperNamesEquivalent(existingKey, clean) then removedKey = existingKey; break end
    end
    if metadata.source == "MANUAL" then
        if removedKey then shared.removedAccountFriends[removedKey] = nil end
        shared.removedAccountFriends[key] = nil
    elseif removedKey or shared.removedAccountFriends[key] then
        return nil
    end

    local record = type(shared.accountFriends[key]) == "table" and shared.accountFriends[key] or {}
    record.name = clean
    record.addedAt = tonumber(record.addedAt) or tonumber(metadata.addedAt) or (time and time() or 0)
    record.lastSeen = tonumber(metadata.lastSeen) or tonumber(record.lastSeen) or (time and time() or 0)
    record.source = metadata.source or record.source or "ROSTER"
    record.seenByProfiles = type(record.seenByProfiles) == "table" and record.seenByProfiles or {}
    local profileKey = metadata.profileKey or self:GetCurrentCharacterProfileKey()
    if profileKey and profileKey ~= "" then record.seenByProfiles[profileKey] = tonumber(metadata.lastSeen) or (time and time() or 0) end
    for _, field in ipairs({ "level", "className", "classFile", "area", "note", "guid" }) do
        if metadata[field] ~= nil and metadata[field] ~= "" then record[field] = metadata[field] end
    end
    shared.accountFriends[key] = record

    local linked = shared.characterBattleNetLinks[key] or shared.characterBattleNetLinks[string.lower(self:ShortName(clean))]
    if linked then self:SetBattleNetPrimaryCharacter(linked, clean, false) end
    return record, key
end

function CC:ForgetAccountFriend(name)
    local key = self:AccountFriendKey(name)
    if not key then return false end
    local shared = self:EnsureAccountWhisperStorage()
    local existed = false
    for existingKey, record in pairs(shared.accountFriends) do
        if self:WhisperNamesEquivalent(record and record.name or existingKey, name) then
            shared.accountFriends[existingKey] = nil
            shared.removedAccountFriends[existingKey] = true
            existed = true
        end
    end
    shared.removedAccountFriends[key] = true
    return existed
end

function CC:GetAccountFriendRecords()
    return self:EnsureAccountWhisperStorage().accountFriends
end

function CC:SetBattleNetPrimaryCharacter(conversationTarget, characterTarget, force)
    conversationTarget = self:ResolveWhisperConversation(conversationTarget)
    characterTarget = self:CleanPlayerName(characterTarget)
    if not conversationTarget or not self:IsBattleNetConversation(conversationTarget) or characterTarget == "" then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    local record = type(shared.battleNetCharacters[conversationTarget]) == "table" and shared.battleNetCharacters[conversationTarget] or {}
    record.characters = type(record.characters) == "table" and record.characters or {}
    if force or not record.primaryTarget or record.primaryTarget == "" then record.primaryTarget = characterTarget end
    shared.battleNetCharacters[conversationTarget] = record
    return record.primaryTarget
end

function CC:UpdateBattleNetCharacterPresence(conversationTarget, characterTarget, displayName, inWoW)
    conversationTarget = self:ResolveWhisperConversation(conversationTarget)
    if not conversationTarget or not self:IsBattleNetConversation(conversationTarget) then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    local record = type(shared.battleNetCharacters[conversationTarget]) == "table" and shared.battleNetCharacters[conversationTarget] or {}
    record.characters = type(record.characters) == "table" and record.characters or {}
    record.displayName = displayName or record.displayName
    local clean = self:CleanPlayerName(characterTarget)
    if inWoW and clean ~= "" then
        local now = time and time() or 0
        local characterKey = string.lower(clean)
        record.characters[characterKey] = { name = clean, lastSeen = now }
        record.activeTarget = clean
        record.activeName = self:ShortName(clean)
        record.lastSeen = now
        shared.characterBattleNetLinks[characterKey] = conversationTarget
        local shortKey = string.lower(self:ShortName(clean))
        if not shared.characterBattleNetLinks[shortKey] or shared.characterBattleNetLinks[shortKey] == conversationTarget then
            shared.characterBattleNetLinks[shortKey] = conversationTarget
        end
        if shared.accountFriends[characterKey] then self:SetBattleNetPrimaryCharacter(conversationTarget, clean, false) end
    else
        record.activeTarget = nil
        record.activeName = nil
    end
    shared.battleNetCharacters[conversationTarget] = record
    return record
end

function CC:GetLinkedBattleNetConversation(characterTarget)
    local clean = self:CleanPlayerName(characterTarget)
    if clean == "" then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    return shared.characterBattleNetLinks[string.lower(clean)] or shared.characterBattleNetLinks[string.lower(self:ShortName(clean))]
end

function CC:GetBattleNetCharacterRecord(conversationTarget)
    conversationTarget = self:ResolveWhisperConversation(conversationTarget)
    if not conversationTarget or not self:IsBattleNetConversation(conversationTarget) then return nil end
    return self:EnsureAccountWhisperStorage().battleNetCharacters[conversationTarget]
end

function CC:GetWhisperContactTabs(target)
    local conversationTarget = self:ResolveWhisperConversation(target)
    if not conversationTarget then return {} end
    local bnetTarget = self:IsBattleNetConversation(conversationTarget) and conversationTarget or self:GetLinkedBattleNetConversation(conversationTarget)
    if not bnetTarget then return {} end
    local record = self:GetBattleNetCharacterRecord(bnetTarget) or {}
    local tabs, seen = {}, {}
    local function add(label, route, description)
        route = self:ResolveWhisperConversation(route)
        if not route or route == "" or seen[route] then return end
        seen[route] = true
        tabs[#tabs + 1] = { label = label, target = route, description = description, active = route == conversationTarget }
    end
    add("B.NET", bnetTarget, "Battle.net account chat shared across every alt")
    local primary = self:CleanPlayerName(record.primaryTarget)
    if primary ~= "" then add("MAIN", primary, "Whisper the saved main character: " .. self:ShortName(primary)) end
    local active = self:CleanPlayerName(record.activeTarget)
    if active ~= "" and string.lower(active) ~= string.lower(primary) then
        add("ALT", active, "Whisper the character currently online: " .. self:ShortName(active))
    elseif active ~= "" and primary == "" then
        add("ALT", active, "Whisper the character currently online: " .. self:ShortName(active))
    end
    if not self:IsBattleNetConversation(conversationTarget) then
        add("CHAT", conversationTarget, "Return to this character conversation")
    end
    return tabs, bnetTarget, record
end

function CC:EnsureChatStorage()
    if not self.db then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    self.db.history = type(self.db.history) == "table" and self.db.history or {}
    self.db.history.whispers = shared.whispers
    self.db.history.guild = type(self.db.history.guild) == "table" and self.db.history.guild or {}
    self.db.history.general = type(self.db.history.general) == "table" and self.db.history.general or {}
    self.db.history.combat = type(self.db.history.combat) == "table" and self.db.history.combat or {}
    self.db.history.quests = type(self.db.history.quests) == "table" and self.db.history.quests or {}
    self.db.conversations = shared.conversations
    self.db.whisperRoutes = shared.whisperRoutes
    self.db.whisperKinds = shared.whisperKinds
    self.db.whisperDisplayNames = shared.whisperDisplayNames
    self.db.battleNetRoutes = shared.battleNetRoutes
    self.db.battleNetRouteKeys = shared.battleNetRouteKeys
    self.db.battleNetFingerprints = shared.battleNetFingerprints
    self.db.questConversations = type(self.db.questConversations) == "table" and self.db.questConversations or {}
    return self.db.history
end

function CC:NotifyChatUI(channel, target, message, shouldAlert)
    if not message or not self.UI or type(self.UI.OnNewMessage) ~= "function" then return false end
    local ok, err = pcall(self.UI.OnNewMessage, self.UI, channel, target, message, shouldAlert and true or false)
    if ok then return true end
    self.state.lastChatUIError = tostring(err or "Unknown chat UI error")
    self.state.lastChatUIErrorAt = time and time() or 0
    if type(self.UI.RefreshAll) == "function" then pcall(self.UI.RefreshAll, self.UI) end
    return false
end

function CC:ResetBattleNetLiveRoutes()
    local shared = self:EnsureAccountWhisperStorage()
    shared.battleNetRoutes = {}
    shared.battleNetRouteKeys = {}
    if self.db then
        self.db.battleNetRoutes = shared.battleNetRoutes
        self.db.battleNetRouteKeys = shared.battleNetRouteKeys
    end
end

function CC:BindSharedWhisperStorage()
    if not CreshChatDB then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    local sourceHistory = type(CreshChatDB.history) == "table" and CreshChatDB.history or {}
    local combinedHistory = {}
    for key, value in pairs(sourceHistory) do
        if key ~= "whispers" then combinedHistory[key] = value end
    end
    mergeDefaults(combinedHistory, defaults.history)
    combinedHistory.whispers = shared.whispers
    CreshChatDB.history = combinedHistory
    CreshChatDB.conversations = shared.conversations
    CreshChatDB.whisperRoutes = shared.whisperRoutes
    CreshChatDB.whisperKinds = shared.whisperKinds
    CreshChatDB.whisperDisplayNames = shared.whisperDisplayNames
    CreshChatDB.battleNetRoutes = shared.battleNetRoutes
    CreshChatDB.battleNetRouteKeys = shared.battleNetRouteKeys
    CreshChatDB.battleNetFingerprints = shared.battleNetFingerprints
    CreshChatDB.battleNetFriends = shared.battleNetFriends
    CreshChatDB.accountFriends = shared.accountFriends
    CreshChatDB.removedAccountFriends = shared.removedAccountFriends
    CreshChatDB.characterBattleNetLinks = shared.characterBattleNetLinks
    CreshChatDB.battleNetCharacters = shared.battleNetCharacters
    return shared
end

local function characterProfileIdentity()
    local name = type(UnitName) == "function" and UnitName("player") or nil
    local realm = type(GetRealmName) == "function" and GetRealmName() or nil
    name = tostring(name or "")
    realm = tostring(realm or "Unknown Realm")
    if realm == "" then realm = "Unknown Realm" end
    if name == "" or name == "Unknown" then return nil, "Unknown", realm end
    local key = name .. " - " .. realm
    return key, name, realm
end

local function profileTableCount(profiles)
    local count = 0
    for _ in pairs(profiles or {}) do count = count + 1 end
    return count
end

local function makeProfileSection(fields, source, fallback)
    local output = {}
    for _, field in ipairs(fields) do
        local value = source and source[field]
        if value == nil and fallback then value = fallback[field] end
        if value == nil then value = {} end
        output[field] = deepCopy(value)
    end
    return output
end

function CC:GetCurrentCharacterProfileKey()
    return self.currentProfileKey or select(1, characterProfileIdentity()) or "Unknown profile"
end

function CC:GetCharacterProfiles()
    return CreshChatDB and CreshChatDB.characterProfiles or {}
end

function CC:GetCharacterProfileDisplay(key)
    local profile = self:GetCharacterProfiles()[key]
    if profile and profile.name and profile.realm then
        return tostring(profile.name) .. " - " .. tostring(profile.realm)
    end
    return tostring(key or "Unknown profile")
end

function CC:GetCharacterProfileOptions(excludeCurrent)
    local values, display = {}, {}
    local current = self:GetCurrentCharacterProfileKey()
    for key, profile in pairs(self:GetCharacterProfiles()) do
        if not excludeCurrent or key ~= current then
            values[#values + 1] = key
            display[key] = self:GetCharacterProfileDisplay(key)
            if profile and profile.lastUsed and type(date) == "function" then
                display[key] = display[key] .. "  ·  last used " .. date("%d %b %Y", profile.lastUsed)
            end
        end
    end
    table.sort(values, function(a, b) return string.lower(display[a] or a) < string.lower(display[b] or b) end)
    return values, display
end

function CC:EnsureCharacterProfile(key, name, realm, migrateLegacy)
    CreshChatDB.characterProfiles = CreshChatDB.characterProfiles or {}
    local profile = CreshChatDB.characterProfiles[key]
    if not profile then
        local source = migrateLegacy and CreshChatDB or defaults
        profile = {
            key = key,
            name = name,
            realm = realm,
            version = self.schemaVersion,
            createdAt = time and time() or 0,
            lastUsed = time and time() or 0,
            uiData = makeProfileSection(PROFILE_UI_FIELDS, source, defaults),
            progression = makeProfileSection(PROFILE_PROGRESSION_FIELDS, source, defaults),
            chat = makeProfileSection(PROFILE_CHAT_FIELDS, migrateLegacy and source or nil, defaults),
        }
        -- Public/local feeds are session-only; direct messages are account-wide.
        profile.chat.history = deepCopy(defaults.history)
        profile.chat.questConversations = {}
        CreshChatDB.characterProfiles[key] = profile
    end
    profile.uiData = profile.uiData or makeProfileSection(PROFILE_UI_FIELDS, nil, defaults)
    profile.progression = profile.progression or makeProfileSection(PROFILE_PROGRESSION_FIELDS, nil, defaults)
    profile.chat = profile.chat or makeProfileSection(PROFILE_CHAT_FIELDS, nil, defaults)
    for _, field in ipairs(PROFILE_UI_FIELDS) do
        if profile.uiData[field] == nil then profile.uiData[field] = deepCopy(defaults[field] or {}) end
    end
    for _, field in ipairs(PROFILE_PROGRESSION_FIELDS) do
        if profile.progression[field] == nil then profile.progression[field] = deepCopy(defaults[field] or {}) end
    end
    for _, field in ipairs(PROFILE_CHAT_FIELDS) do
        if profile.chat[field] == nil then profile.chat[field] = deepCopy(defaults[field] or {}) end
    end
    profile.name, profile.realm, profile.version = name, realm, self.schemaVersion
    profile.lastUsed = time and time() or profile.lastUsed or 0
    return profile
end

function CC:BindCharacterProfile(profile, key)
    if not profile then return false end
    for _, field in ipairs(PROFILE_UI_FIELDS) do
        CreshChatDB[field] = profile.uiData[field]
    end
    -- Progression and unlocks are account-wide. Legacy per-character tables are
    -- retained for safe migration, but are never rebound as active data.
    self:BindAccountProgressionStorage()
    for _, field in ipairs(PROFILE_CHAT_FIELDS) do
        CreshChatDB[field] = profile.chat[field]
    end
    CreshChatDB.activeProfile = key
    self.currentProfileKey = key
    self.currentProfile = profile
    self.accountDB = CreshChatDB
    self.db = CreshChatDB
    self:BindSharedWhisperStorage()
    return true
end

function CC:ActivateCharacterProfile()
    if not CreshChatDB then return false end
    CreshChatDB.characterProfiles = CreshChatDB.characterProfiles or {}
    local key, name, realm = characterProfileIdentity()
    if not key then return false end
    local migrateLegacy = profileTableCount(CreshChatDB.characterProfiles) == 0
    local profile = self:EnsureCharacterProfile(key, name, realm, migrateLegacy)
    return self:BindCharacterProfile(profile, key)
end

function CC:SyncActiveCharacterProfile()
    local profile = self.currentProfile
    if not profile or not self.db then return false end
    profile.uiData = profile.uiData or {}
    profile.progression = profile.progression or {}
    profile.chat = profile.chat or {}
    for _, field in ipairs(PROFILE_UI_FIELDS) do profile.uiData[field] = self.db[field] end
    local sharedProgression = self:EnsureAccountProgressionStorage(false)
    for _, field in ipairs(PROFILE_PROGRESSION_FIELDS) do
        sharedProgression[field] = self.db[field]
    end
    local sessionHistory = deepCopy(self.db.history or defaults.history)
    sessionHistory.whispers = {}
    profile.chat.history = sessionHistory
    profile.chat.questConversations = deepCopy(self.db.questConversations or {})
    return true
end

function CC:ClearSessionChatHistory()
    if not self.db then return end
    local shared = self:EnsureAccountWhisperStorage()
    self.db.history = deepCopy(defaults.history)
    self.db.history.whispers = shared.whispers
    self.db.conversations = shared.conversations
    self.db.whisperRoutes = shared.whisperRoutes
    self.db.whisperKinds = shared.whisperKinds
    self.db.whisperDisplayNames = shared.whisperDisplayNames
    self.db.battleNetRoutes = shared.battleNetRoutes
    self.db.battleNetRouteKeys = shared.battleNetRouteKeys
    self.db.battleNetFingerprints = shared.battleNetFingerprints
    self.db.questConversations = {}
    if self.currentProfile and self.currentProfile.chat then
        self.currentProfile.chat.history = deepCopy(defaults.history)
        self.currentProfile.chat.questConversations = {}
    end
    self.state.unreadWhispers = 0
    self.state.unreadGuild = 0
    self.state.unreadGeneral = 0
    self.state.unreadQuests = 0
    local latestTarget, latestTime
    for target, updated in pairs(shared.conversations) do
        updated = tonumber(updated) or 0
        if not latestTime or updated > latestTime then
            latestTarget, latestTime = target, updated
        end
    end
    self.state.lastWhisperTarget = latestTarget
end

function CC:CopyUIFromCharacterProfile(sourceKey)
    local profiles = self:GetCharacterProfiles()
    local source = profiles[sourceKey]
    local target = self.currentProfile
    if not source or not source.uiData or not target or sourceKey == self.currentProfileKey then return false end
    target.uiData = target.uiData or {}
    for _, field in ipairs(PROFILE_UI_FIELDS) do
        target.uiData[field] = deepCopy(source.uiData[field] ~= nil and source.uiData[field] or defaults[field] or {})
        CreshChatDB[field] = target.uiData[field]
    end
    target.lastCopiedFrom = sourceKey
    target.lastCopiedAt = time and time() or 0
    self.db = CreshChatDB
    self:ApplyBlizzardChatVisibility()
    if self.UI then
        if self.UI.ApplyVisualSettings then self.UI:ApplyVisualSettings() end
        if self.UI.ApplySavedPositions then self.UI:ApplySavedPositions() end
        if self.UI.RefreshAll then self.UI:RefreshAll() end
    end
    return true
end

function CC:Print(message)
    local plainMessage = "CreshChat: " .. tostring(message)
    if self.ShouldHideBlizzardChat and self:ShouldHideBlizzardChat() and UIErrorsFrame then
        UIErrorsFrame:AddMessage(plainMessage, 0.31, 0.60, 1.00, 1.0)
        return
    end

    local prefix = "|cff4f9cffCreshChat|r"
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. ": " .. tostring(message))
    end
end

function CC:ShortName(name)
    if not name or name == "" then
        return "Unknown"
    end
    if Ambiguate then
        return Ambiguate(name, "short")
    end
    return string.match(name, "^[^-]+") or name
end

function CC:CleanText(text)
    text = tostring(text or "")
    text = string.gsub(text, "|T.-|t", "")
    text = string.gsub(text, "|A.-|a", "")
    return text
end

local notificationKeyMap = {
    WHISPER = "whisper", BN_WHISPER = "whisper",
    GUILD = "guild", OFFICER = "guild",
    QUEST = "quest",
    PARTY = "partyInvite", PARTY_INVITE = "partyInvite",
    PARTY_MESSAGE = "partyMessage", RAID_MESSAGE = "partyMessage", INSTANCE_MESSAGE = "partyMessage",
    GENERAL = "mentions", MENTION = "mentions",
    FRIEND = "friends", PRESENCE = "friends",
    SYSTEM = "system",
    GAME = "game", BATTLEPASS = "game", DUNGEONPASS = "game",
}

function CC:GetNotificationKey(kind)
    return notificationKeyMap[string.upper(tostring(kind or "SYSTEM"))]
end

function CC:IsNotificationEnabled(kind)
    if not self.db then return true end
    self.db.ui = self.db.ui or deepCopy(defaults.ui)
    if self.db.ui.notificationCardsEnabled == false then return false end
    self.db.notifications = self.db.notifications or deepCopy(defaults.notifications)
    local key = self:GetNotificationKey(kind)
    if not key then return true end
    if key == "system" and self.db.ui.showSystemCards == false then return false end
    return self.db.notifications[key] ~= false
end

function CC:GetNotificationPriority(kind)
    if not self.db then return "NORMAL" end
    self.db.notificationPriorities = self.db.notificationPriorities or deepCopy(defaults.notificationPriorities)
    local key = self:GetNotificationKey(kind) or "system"
    local priority = string.upper(tostring(self.db.notificationPriorities[key] or defaults.notificationPriorities[key] or "NORMAL"))
    if priority ~= "CRITICAL" and priority ~= "HIGH" and priority ~= "NORMAL" and priority ~= "LOW" then priority = "NORMAL" end
    return priority
end

function CC:SetNotificationPriority(kind, priority)
    if not self.db then return false end
    local key = self:GetNotificationKey(kind)
    if not key then return false end
    priority = string.upper(tostring(priority or "NORMAL"))
    if priority ~= "CRITICAL" and priority ~= "HIGH" and priority ~= "NORMAL" and priority ~= "LOW" then return false end
    self.db.notificationPriorities = self.db.notificationPriorities or deepCopy(defaults.notificationPriorities)
    self.db.notificationPriorities[key] = priority
    return true
end

function CC:GetNotificationPriorityRank(kind)
    local priority = self:GetNotificationPriority(kind)
    return priority == "CRITICAL" and 4 or (priority == "HIGH" and 3 or (priority == "NORMAL" and 2 or 1))
end

function CC:CleanPlayerName(name)
    local text = tostring(name or "")
    local linked = string.match(text, "|Hplayer:([^:|]+)")
    if linked and linked ~= "" then
        text = linked
    end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "^%[", "")
    text = string.gsub(text, "%]$", "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function CC:SplitPlayerName(name)
    local clean = self:CleanPlayerName(name)
    local short, realm = string.match(clean, "^([^-]+)%-(.+)$")
    if not short then
        short = clean
        realm = ""
    end
    return string.lower(short or ""), string.lower(realm or ""), clean
end

function CC:IsBattleNetConversation(target)
    return string.sub(tostring(target or ""), 1, 5) == "BNET:"
end

local function battleNetIdentityText(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

function CC:GetBattleNetAccountInfoByID(accountID)
    accountID = tonumber(accountID)
    if not accountID then return nil end
    if _G.C_BattleNet and type(_G.C_BattleNet.GetAccountInfoByID) == "function" then
        local ok, info = pcall(_G.C_BattleNet.GetAccountInfoByID, accountID)
        if ok and type(info) == "table" then return info end
    end
    if type(_G.BNGetFriendInfoByID) == "function" then
        local values = { pcall(_G.BNGetFriendInfoByID, accountID) }
        if values[1] then
            -- pcall occupies index 1. BNGetFriendInfoByID then returns
            -- presenceID, accountName, battleTag, isBattleTagPresence,
            -- toonName, toonID, client and online state.
            local gameInfo = {
                characterName = values[6],
                gameAccountID = values[7],
                clientProgram = values[8],
                isOnline = values[9] == true,
            }
            return {
                bnetAccountID = tonumber(values[2]) or accountID,
                accountName = values[3],
                battleTag = values[4],
                isBattleTagPresence = values[5] == true,
                gameAccountInfo = gameInfo,
                isOnline = gameInfo.isOnline,
            }
        end
    end
    return nil
end

function CC:RegisterBattleNetAccount(accountID, accountInfo, fallbackName)
    local shared = self:EnsureAccountWhisperStorage()
    accountID = tonumber(accountID or (accountInfo and accountInfo.bnetAccountID))
    accountInfo = type(accountInfo) == "table" and accountInfo or (accountID and self:GetBattleNetAccountInfoByID(accountID)) or {}
    local battleTag = battleNetIdentityText(accountInfo.battleTag)
    local accountName = battleNetIdentityText(accountInfo.accountName)
    local fallback = battleNetIdentityText(fallbackName)
    local fingerprint = battleTag ~= "" and battleTag or (accountName ~= "" and accountName or fallback)
    local fingerprintKey = string.lower(fingerprint)
    local conversationKey = fingerprintKey ~= "" and shared.battleNetFingerprints[fingerprintKey] or nil
    if not conversationKey and accountID then conversationKey = shared.battleNetRouteKeys[tostring(accountID)] end
    if not conversationKey then
        if fingerprintKey ~= "" then conversationKey = "BNET:" .. fingerprintKey
        elseif accountID then conversationKey = "BNET:ID-" .. tostring(accountID)
        else return nil end
    end

    local displayName = accountName ~= "" and accountName or (battleTag ~= "" and battleTag or (fallback ~= "" and fallback or "Battle.net Friend"))
    shared.whisperKinds[conversationKey] = "BNET"
    shared.whisperDisplayNames[conversationKey] = displayName
    if accountID then
        shared.battleNetRoutes[conversationKey] = accountID
        shared.battleNetRouteKeys[tostring(accountID)] = conversationKey
    end
    if fingerprintKey ~= "" then shared.battleNetFingerprints[fingerprintKey] = conversationKey end
    if battleTag ~= "" then shared.battleNetFingerprints[string.lower(battleTag)] = conversationKey end
    if accountName ~= "" then shared.battleNetFingerprints[string.lower(accountName)] = conversationKey end
    return conversationKey
end

function CC:GetBattleNetAccountID(target)
    local conversationTarget = self:ResolveWhisperConversation(target)
    if not conversationTarget or not self:IsBattleNetConversation(conversationTarget) then return nil end
    local shared = self:EnsureAccountWhisperStorage()
    return tonumber(shared.battleNetRoutes[conversationTarget])
end

function CC:GetWhisperDisplayName(target)
    local clean = self:CleanPlayerName(target)
    if clean == "" then return "Unknown" end
    local shared = CreshChatDB and self:EnsureAccountWhisperStorage() or nil
    if self:IsBattleNetConversation(clean) then
        local display = shared and shared.whisperDisplayNames[clean]
        if display and display ~= "" then return display end
        return string.gsub(string.sub(clean, 6), "^ID%-", "Battle.net ")
    end
    return self:ShortName(clean)
end

function CC:WhisperNamesEquivalent(left, right)
    local leftClean = self:CleanPlayerName(left)
    local rightClean = self:CleanPlayerName(right)
    local leftBN = self:IsBattleNetConversation(leftClean)
    local rightBN = self:IsBattleNetConversation(rightClean)
    if leftBN or rightBN then
        -- Battle.net accounts and character whispers are separate namespaces,
        -- even when an account name happens to match a character name.
        if leftBN and rightBN then return leftClean == rightClean end
        return false
    end
    local leftShort, leftRealm = self:SplitPlayerName(leftClean)
    local rightShort, rightRealm = self:SplitPlayerName(rightClean)
    if leftShort == "" or rightShort == "" or leftShort ~= rightShort then
        return false
    end
    return leftRealm == "" or rightRealm == "" or leftRealm == rightRealm
end

function CC:ResolveWhisperConversation(target)
    local clean = self:CleanPlayerName(target)
    if clean == "" then return nil end
    if not self.db then return clean end
    if self:IsBattleNetConversation(clean) then return clean end

    -- Character whispers and Battle.net account conversations must remain separate
    -- namespaces. A Battle.net account name can be identical to a character name;
    -- resolving arbitrary character text through account fingerprints could silently
    -- redirect a normal /whisper into the wrong history and sending route.
    for existing in pairs(self.db.history.whispers or {}) do
        if not self:IsBattleNetConversation(existing) and self:WhisperNamesEquivalent(existing, clean) then return existing end
    end
    for existing in pairs(self.db.conversations or {}) do
        if not self:IsBattleNetConversation(existing) and self:WhisperNamesEquivalent(existing, clean) then return existing end
    end
    return clean
end

function CC:RememberWhisperRoute(conversationTarget, routeTarget)
    if not self.db or not conversationTarget then
        return
    end
    self.db.whisperRoutes = self.db.whisperRoutes or {}
    if self:IsBattleNetConversation(conversationTarget) then return end
    local route = self:CleanPlayerName(routeTarget)
    if route == "" then return end
    local current = self.db.whisperRoutes[conversationTarget]
    if not current or current == "" or (not string.find(current, "-", 1, true) and string.find(route, "-", 1, true)) then
        self.db.whisperRoutes[conversationTarget] = route
    end
end

function CC:GetWhisperRoute(target)
    local conversationTarget = self:ResolveWhisperConversation(target)
    if not conversationTarget then
        return nil
    end
    return (self.db.whisperRoutes and self.db.whisperRoutes[conversationTarget]) or conversationTarget
end

function CC:IsSelf(name)
    if not name then
        return false
    end
    local short = self:ShortName(name)
    return string.lower(short) == string.lower(self.state.playerName or "")
end

function CC:UpdatePlayerIdentity()
    local name, realm = UnitName("player")
    self.state.playerName = name or "Player"
    realm = realm or GetRealmName() or ""
    realm = string.gsub(realm, "%s+", "")
    if realm ~= "" then
        self.state.playerFullName = (name or "Player") .. "-" .. realm
    else
        self.state.playerFullName = name or "Player"
    end
end

function CC:TouchConversation(target, timestamp)
    if not target or target == "" then
        return
    end
    self.db.conversations[target] = timestamp or time()
    self.state.lastWhisperTarget = target
end

function CC:TrimHistory(list, customLimit)
    local limit = tonumber(customLimit) or tonumber(self.db.historyLimit) or 120
    while #list > limit do
        table.remove(list, 1)
    end
end

function CC:EnsureWhisperConversation(target, timestamp)
    local routeTarget = self:CleanPlayerName(target)
    local conversationTarget
    if self:IsBattleNetConversation(routeTarget) then
        conversationTarget = routeTarget
        local shared = self:EnsureAccountWhisperStorage()
        shared.whisperKinds[conversationTarget] = "BNET"
    else
        conversationTarget = self:ResolveWhisperConversation(routeTarget)
    end
    if not conversationTarget then return nil end

    if not self.db.history.whispers[conversationTarget] then
        self.db.history.whispers[conversationTarget] = {}
    end
    self:RememberWhisperRoute(conversationTarget, routeTarget)
    self:TouchConversation(conversationTarget, timestamp or time())
    return conversationTarget
end

function CC:EnsureBattleNetConversation(accountID, displayName, timestamp)
    local conversationTarget = self:RegisterBattleNetAccount(accountID, nil, displayName)
    if not conversationTarget then return nil end
    if not self.db.history.whispers[conversationTarget] then self.db.history.whispers[conversationTarget] = {} end
    self:TouchConversation(conversationTarget, timestamp or time())
    return conversationTarget
end

function CC:PlayerCacheKey(name)
    local short, realm = self:SplitPlayerName(name)
    if short == "" then
        return nil
    end
    return short .. ((realm and realm ~= "") and ("-" .. realm) or "")
end

local MAX_PLAYER_CACHE = 500

local function prunePlayerCache(cache)
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    if count <= MAX_PLAYER_CACHE then return end
    local entries = {}
    for k, v in pairs(cache) do
        entries[#entries + 1] = { key = k, lastSeen = type(v) == "table" and (tonumber(v.lastSeen) or 0) or 0 }
    end
    table.sort(entries, function(a, b)
        if a.lastSeen ~= b.lastSeen then return a.lastSeen < b.lastSeen end
        return a.key < b.key
    end)
    local target = math.floor(MAX_PLAYER_CACHE * 0.9)
    local removeCount = count - target
    for i = 1, removeCount do
        local k = entries[i].key
        cache[k] = nil
        local shortK = string.match(k, "^([^-]+)-")
        if shortK then cache[shortK] = nil end
    end
end

function CC:CachePlayerInfo(name, guid)
    if not self.db then
        return nil
    end
    self.db.playerCache = self.db.playerCache or {}
    local clean = self:CleanPlayerName(name)
    local key = self:PlayerCacheKey(clean)
    if not key then
        return nil
    end

    local cached = self.db.playerCache[key] or {}
    cached.name = clean ~= "" and clean or cached.name
    cached.guid = guid or cached.guid
    cached.lastSeen = time()

    if guid and type(GetPlayerInfoByGUID) == "function" then
        local localizedClass, classFile, localizedRace, raceFile, sex, playerName, realmName = GetPlayerInfoByGUID(guid)
        if classFile and classFile ~= "" then cached.classFile = classFile end
        if raceFile and raceFile ~= "" then cached.raceFile = raceFile end
        if sex then cached.sex = sex end
        if localizedClass and localizedClass ~= "" then cached.localizedClass = localizedClass end
        if localizedRace and localizedRace ~= "" then cached.localizedRace = localizedRace end
        if playerName and playerName ~= "" then
            cached.name = playerName
            if realmName and realmName ~= "" then
                cached.fullName = playerName .. "-" .. string.gsub(realmName, "%s+", "")
            end
        end
    end

    self.db.playerCache[key] = cached
    local shortKey = string.match(key, "^[^-]+")
    if shortKey and shortKey ~= key and not self.db.playerCache[shortKey] then
        self.db.playerCache[shortKey] = cached
    end
    prunePlayerCache(self.db.playerCache)
    return cached
end

function CC:GetCachedPlayerInfo(name, guid)
    if not self.db then
        return nil
    end
    local clean = self:CleanPlayerName(name)
    local key = self:PlayerCacheKey(clean)
    local cached = key and self.db.playerCache and self.db.playerCache[key] or nil
    if not cached and key then
        local shortKey = string.match(key, "^[^-]+")
        cached = shortKey and self.db.playerCache and self.db.playerCache[shortKey] or nil
    end
    if guid or not cached then
        local ok, refreshed = pcall(self.CachePlayerInfo, self, clean, guid)
        if ok then cached = refreshed or cached end
    end
    return cached
end

function CC:ChannelColorKey(message)
    if not message then return "CHANNEL" end
    local chatType = string.upper(tostring(message.chatType or message.channel or ""))
    local label = string.upper(tostring(message.channelLabel or ""))
    if string.find(chatType, "PARTY", 1, true) then return "PARTY" end
    if string.find(chatType, "RAID", 1, true) then return "RAID" end
    if string.find(chatType, "INSTANCE", 1, true) or string.find(chatType, "BATTLEGROUND", 1, true) then return "INSTANCE" end
    if string.find(chatType, "YELL", 1, true) then return "YELL" end
    if string.find(chatType, "SAY", 1, true) then return "SAY" end
    if string.find(chatType, "EMOTE", 1, true) then return "EMOTE" end
    if string.find(chatType, "GUILD", 1, true) then return "GUILD" end
    if string.find(chatType, "OFFICER", 1, true) then return "OFFICER" end
    if string.find(chatType, "WHISPER", 1, true) then return "WHISPER" end
    if string.find(label, "TRADE", 1, true) then return "TRADE" end
    if string.find(label, "LOCALDEFENSE", 1, true) or string.find(label, "LOCAL DEFENSE", 1, true) then return "LOCALDEFENSE" end
    if string.find(label, "LOOKINGFORGROUP", 1, true) or string.find(label, "LOOKING FOR GROUP", 1, true) or label == "LFG" then return "LFG" end
    if label == "GENERAL" then return "GENERAL" end
    return "CHANNEL"
end

function CC:NormaliseChatType(chatType)
    chatType = string.upper(tostring(chatType or ""))
    local aliases = {
        CHAT_MSG_PARTY_LEADER = "CHAT_MSG_PARTY",
        CHAT_MSG_RAID_LEADER = "CHAT_MSG_RAID",
        CHAT_MSG_RAID_WARNING = "CHAT_MSG_RAID",
        CHAT_MSG_INSTANCE_CHAT_LEADER = "CHAT_MSG_INSTANCE_CHAT",
        CHAT_MSG_BATTLEGROUND_LEADER = "CHAT_MSG_BATTLEGROUND",
    }
    return aliases[chatType] or chatType
end

function CC:FindPendingOutgoing(list, text, timestamp, expectedType)
    local cleanText = self:CleanText(text)
    local now = tonumber(timestamp) or (time and time() or 0)
    expectedType = expectedType and self:NormaliseChatType(expectedType) or nil
    for index = #list, math.max(1, #list - 12), -1 do
        local message = list[index]
        local messageType = message and self:NormaliseChatType(message.chatType or message.channel or "") or ""
        local typeMatches = not expectedType or expectedType == "" or messageType == expectedType
        if message and typeMatches and message.incoming == false and message.pending == true and message.text == cleanText then
            if math.abs(now - (tonumber(message.timestamp) or now)) <= 15 then return message end
        end
    end
    return nil
end

function CC:MarkPendingMessageFailed(message, reason)
    if not message then return end
    message.pending = nil
    message.failed = true
    message.failureReason = tostring(reason or "Unable to send")
end

function CC:AddWhisper(target, text, incoming, guid, timestamp, pending)
    self:EnsureChatStorage()
    local routeTarget = self:CleanPlayerName(target)
    local conversationTarget = self:EnsureWhisperConversation(routeTarget, timestamp)
    if not conversationTarget then return end
    local list = self.db.history.whispers[conversationTarget]
    if not incoming and not pending then
        local existing = self:FindPendingOutgoing(list, text, timestamp)
        if existing then
            existing.pending = nil
            existing.delivered = true
            existing.timestamp = tonumber(timestamp) or existing.timestamp
            self:TouchConversation(conversationTarget, existing.timestamp)
            return existing, conversationTarget, true
        end
    end

    local senderName = incoming and routeTarget or self.state.playerName
    local senderGUID = incoming and guid or UnitGUID("player")
    local playerInfo = self:GetCachedPlayerInfo(senderName, senderGUID) or {}
    local message = {
        timestamp = timestamp or time(),
        text = self:CleanText(text),
        sender = senderName,
        incoming = incoming and true or false,
        guid = senderGUID,
        classFile = playerInfo.classFile,
        raceFile = playerInfo.raceFile,
        sex = playerInfo.sex,
        channel = "WHISPER",
        target = conversationTarget,
        pending = pending and true or nil,
    }

    table.insert(list, message)
    self:TrimHistory(list)
    self:TouchConversation(conversationTarget, message.timestamp)
    return message, conversationTarget
end

function CC:AddBattleNetWhisper(accountID, displayName, text, incoming, timestamp, pending)
    self:EnsureChatStorage()
    local conversationTarget = self:EnsureBattleNetConversation(accountID, displayName, timestamp)
    if not conversationTarget then return nil end
    local list = self.db.history.whispers[conversationTarget]
    if not incoming and not pending then
        local existing = self:FindPendingOutgoing(list, text, timestamp)
        if existing then
            existing.pending = nil
            existing.delivered = true
            existing.timestamp = tonumber(timestamp) or existing.timestamp
            existing.bnetAccountID = tonumber(accountID) or existing.bnetAccountID
            self:TouchConversation(conversationTarget, existing.timestamp)
            return existing, conversationTarget, true
        end
    end
    local friendlyName = self:GetWhisperDisplayName(conversationTarget)
    local message = {
        timestamp = timestamp or time(),
        text = self:CleanText(text),
        sender = incoming and friendlyName or self.state.playerName,
        incoming = incoming and true or false,
        channel = "WHISPER",
        chatType = "BN_WHISPER",
        target = conversationTarget,
        bnetAccountID = tonumber(accountID),
        battleNet = true,
        pending = pending and true or nil,
    }
    table.insert(list, message)
    self:TrimHistory(list)
    self:TouchConversation(conversationTarget, message.timestamp)
    return message, conversationTarget
end

function CC:AddGuildMessage(sender, text, incoming, guid, isOfficer, timestamp, pending)
    self:EnsureChatStorage()
    local list = self.db.history.guild
    local guildType = isOfficer and "OFFICER" or "GUILD"
    if not incoming and not pending then
        local existing = self:FindPendingOutgoing(list, text, timestamp, guildType)
        if existing then
            existing.pending = nil
            existing.delivered = true
            existing.timestamp = tonumber(timestamp) or existing.timestamp
            return existing, true
        end
    end
    local senderGUID = incoming and guid or UnitGUID("player")
    local playerInfo = self:GetCachedPlayerInfo(sender, senderGUID) or {}
    local message = {
        timestamp = timestamp or time(),
        text = self:CleanText(text),
        sender = sender or "Unknown",
        incoming = incoming and true or false,
        guid = senderGUID,
        classFile = playerInfo.classFile,
        raceFile = playerInfo.raceFile,
        sex = playerInfo.sex,
        channel = guildType,
        chatType = guildType,
        pending = pending and true or nil,
    }

    table.insert(list, message)
    self:TrimHistory(list)
    return message, false
end

function CC:AddGeneralMessage(sender, text, incoming, guid, timestamp, channelLabel, chatType, pending)
    self:EnsureChatStorage()
    local list = self.db.history.general
    chatType = chatType or "CHANNEL"
    if not incoming and not pending then
        local existing = self:FindPendingOutgoing(list, text, timestamp, chatType)
        if existing then
            existing.pending = nil
            existing.delivered = true
            existing.timestamp = tonumber(timestamp) or existing.timestamp
            existing.channelLabel = channelLabel or existing.channelLabel
            return existing, true
        end
    end
    local senderGUID = incoming and guid or UnitGUID("player")
    local playerInfo = self:GetCachedPlayerInfo(sender, senderGUID) or {}
    local message = {
        timestamp = timestamp or time(),
        text = self:CleanText(text),
        sender = sender or "Unknown",
        incoming = incoming and true or false,
        guid = senderGUID,
        classFile = playerInfo.classFile,
        raceFile = playerInfo.raceFile,
        sex = playerInfo.sex,
        channel = "GENERAL",
        channelLabel = channelLabel or "General",
        chatType = chatType,
        pending = pending and true or nil,
    }

    table.insert(list, message)
    self:TrimHistory(list)
    return message, false
end

function CC:AddCombatMessage(text, category, timestamp)
    local list = self.db.history.combat
    local message = {
        timestamp = timestamp or time(),
        text = self:CleanText(text),
        category = category or "event",
        channel = "COMBAT",
        incoming = false,
    }

    table.insert(list, message)
    self:TrimHistory(list, self.db.combatHistoryLimit)
    return message
end

function CC:IsGeneralChannel(zoneChannelID, channelBaseName, channelName)
    if tonumber(zoneChannelID) == 1 then
        return true
    end

    local generalName = tostring(_G.GENERAL or "General")
    local base = tostring(channelBaseName or "")
    local full = tostring(channelName or "")
    if base == generalName then
        return true
    end

    base = string.lower(base)
    full = string.lower(full)
    generalName = string.lower(generalName)
    return base == generalName or string.find(full, generalName, 1, true) ~= nil
end

local namedChannelAliases = {
    GENERAL = { function() return _G.GENERAL end, "General" },
    TRADE = { function() return _G.TRADE end, "Trade" },
    LOCALDEFENSE = { function() return _G.LOCAL_DEFENSE end, "LocalDefense", "Local Defense" },
    LFG = { function() return _G.LOOKING_FOR_GROUP end, "LookingForGroup", "Looking For Group", "LFG" },
}

local function normaliseChannelName(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "^%d+%.%s*", "")
    value = string.gsub(value, "%s*%-%s*.+$", "")
    value = string.gsub(value, "[%s%p]", "")
    return value
end

function CC:GetNamedChannelID(key)
    key = string.upper(tostring(key or "GENERAL"))
    local aliases = namedChannelAliases[key]
    if not aliases then return nil end
    local wanted = {}
    for _, alias in ipairs(aliases) do
        if type(alias) == "function" then alias = alias() end
        alias = tostring(alias or "")
        if alias ~= "" then
            wanted[normaliseChannelName(alias)] = true
            if GetChannelName then
                local id = GetChannelName(alias)
                if tonumber(id) and tonumber(id) > 0 then return tonumber(id) end
            end
        end
    end
    if GetChannelList then
        local channels = { GetChannelList() }
        for index = 1, #channels, 3 do
            local channelID = tonumber(channels[index])
            local channelName = normaliseChannelName(channels[index + 1])
            if channelID and wanted[channelName] then return channelID end
        end
    end
    return nil
end

function CC:GetGeneralChannelID()
    return self:GetNamedChannelID("GENERAL")
end

function CC:ShouldAlertGuild(text)
    local mode = self.db.guildAlerts or "all"
    if mode == "off" then
        return false
    end
    if mode == "mentions" then
        local player = string.lower(self.state.playerName or "")
        local haystack = string.lower(tostring(text or ""))
        return player ~= "" and string.find(haystack, player, 1, true) ~= nil
    end
    return true
end

local function escapeLuaPatternWord(value)
    return (tostring(value or ""):gsub("([^%w])", "%%%1"))
end

function CC:MessageMentionsPlayer(text)
    local haystack = string.lower(tostring(text or ""))
    if haystack == "" then return false end
    local candidates = {
        self.state and self.state.playerName or "",
        self.state and self.state.playerFullName or "",
    }
    for _, candidate in ipairs(candidates) do
        candidate = string.lower(tostring(candidate or ""))
        candidate = string.match(candidate, "^([^%-]+)") or candidate
        if candidate ~= "" then
            local pattern = "%f[%w]" .. escapeLuaPatternWord(candidate) .. "%f[%W]"
            if string.find(haystack, pattern) then return true end
        end
    end
    return false
end

local function getCustomSoundFiles()
    local library = _G.CreshChatSoundLibrary
    return type(library) == "table" and type(library.files) == "table" and library.files or {}
end

local SOUND_PRESET_CANDIDATES = {
    DING = { "TELL_MESSAGE", "IG_MAINMENU_OPTION_CHECKBOX_ON", "IG_CHAT_EMOTE_BUTTON", "READY_CHECK" },
    CHIME = { "IG_CHARACTER_INFO_OPEN", "IG_QUEST_LOG_OPEN", "IG_MAINMENU_OPEN", "READY_CHECK" },
    WHISPER = { "TELL_MESSAGE", "UI_BNET_TOAST", "IG_MAINMENU_OPTION_CHECKBOX_ON", "READY_CHECK" },
    SOFT = { "IG_MAINMENU_OPTION_CHECKBOX_ON", "IG_CHAT_SCROLL_DOWN", "IG_MAINMENU_OPTION_CHECKBOX_OFF", "READY_CHECK" },
    MESSAGE = { "IG_CHAT_SCROLL_DOWN", "IG_CHAT_EMOTE_BUTTON", "TELL_MESSAGE", "IG_MAINMENU_OPTION_CHECKBOX_ON", "READY_CHECK" },
    SCROLL = { "IG_CHAT_SCROLL_DOWN", "IG_CHAT_EMOTE_BUTTON", "IG_MAINMENU_OPTION_CHECKBOX_ON", "READY_CHECK" }, -- legacy v0.3.13 choice
    QUEST = { "IG_QUEST_LOG_OPEN", "IG_QUEST_LIST_OPEN", "UI_QUEST_ROLLING_FORWARD_01", "IG_MAINMENU_OPEN", "READY_CHECK" },
    READY = { "READY_CHECK", "PVP_THROUGH_QUEUE", "RAID_WARNING" },
    WARNING = { "RAID_WARNING", "RAID_BOSS_WHISPER_WARNING", "READY_CHECK" },
    OPEN = { "IG_MAINMENU_OPEN", "IG_CHARACTER_INFO_OPEN", "AUCTION_WINDOW_OPEN", "READY_CHECK" },
    COIN = { "LOOT_WINDOW_COIN_SOUND", "AUCTION_WINDOW_OPEN", "IG_MAINMENU_OPTION_CHECKBOX_ON", "READY_CHECK" },
}

local function resolveNamedSound(name)
    name = tostring(name or "")
    if name == "" then return nil end
    if type(SOUNDKIT) == "table" and SOUNDKIT[name] ~= nil then return SOUNDKIT[name] end
    if _G[name] ~= nil then return _G[name] end
    local legacy = _G["SOUNDKIT_" .. name]
    if legacy ~= nil then return legacy end
    return nil
end

local function tryPlaySound(soundID)
    if soundID == nil or type(PlaySound) ~= "function" then return false end
    local ok, willPlay = pcall(PlaySound, soundID, "Master")
    if not ok then return false end
    return willPlay ~= false
end

local function tryPlaySoundFile(path)
    if type(path) ~= "string" or path == "" or type(PlaySoundFile) ~= "function" then return false end
    local ok, willPlay = pcall(PlaySoundFile, path, "Master")
    if not ok then return false end
    return willPlay ~= false
end

local function soundVolumeBucket(value)
    value = math.max(0, math.min(1, tonumber(value) or 1))
    if value <= 0.01 then return 0 end
    if value < 0.38 then return 25 elseif value < 0.63 then return 50 elseif value < 0.88 then return 75 end
    return 100
end

local function customSoundPathForVolume(path, value)
    local bucket = soundVolumeBucket(value)
    if bucket == 0 then return nil end
    if bucket == 100 then return path end
    return string.gsub(path, "%.ogg$", "_v" .. tostring(bucket) .. ".ogg")
end

function CC:PlaySoundPreset(preset, volume)
    preset = string.upper(tostring(preset or "OFF"))
    if preset == "OFF" then return false end

    local customPath = getCustomSoundFiles()[preset]
    local volumePath = customPath and customSoundPathForVolume(customPath, volume)
    if customPath and not volumePath then return true end
    if volumePath and tryPlaySoundFile(volumePath) then
        self.state.lastResolvedSound = { preset = preset, name = preset, file = volumePath }
        return true
    end

    local candidates = SOUND_PRESET_CANDIDATES[preset] or SOUND_PRESET_CANDIDATES.DING
    local seen = {}
    for _, name in ipairs(candidates) do
        local soundID = resolveNamedSound(name)
        if soundID ~= nil and not seen[soundID] then
            seen[soundID] = true
            if tryPlaySound(soundID) then
                self.state.lastResolvedSound = { preset = preset, name = name, id = soundID }
                return true
            end
        end
    end
    return false
end

local notificationSoundKeyMap = {
    WHISPER = "whisper", BN_WHISPER = "whisper",
    GUILD = "guild", OFFICER = "guild",
    PARTY_INVITE = "partyInvite", PARTY = "partyInvite",
    PARTY_MESSAGE = "partyMessage", RAID_MESSAGE = "partyMessage", INSTANCE_MESSAGE = "partyMessage",
    QUEST = "quest",
    GENERAL = "mentions", MENTION = "mentions",
    FRIEND = "friends", PRESENCE = "friends",
    GAME = "game", BATTLEPASS = "game", DUNGEONPASS = "game",
    SYSTEM = "system",
}

function CC:GetNotificationSoundKey(channel)
    return notificationSoundKeyMap[string.upper(tostring(channel or "SYSTEM"))]
end

function CC:GetSoundChoice(channel)
    self.db.soundChoices = self.db.soundChoices or deepCopy(defaults.soundChoices)
    local key = self:GetNotificationSoundKey(channel)
    if not key then return "OFF" end
    return string.upper(tostring(self.db.soundChoices[key] or defaults.soundChoices[key] or "OFF"))
end

function CC:SetSoundChoice(key, preset)
    self.db.soundChoices = self.db.soundChoices or deepCopy(defaults.soundChoices)
    preset = string.upper(tostring(preset or "OFF"))
    self.db.soundChoices[key] = preset
    local enabled = preset ~= "OFF"
    self.db.sounds = self.db.sounds or deepCopy(defaults.sounds)
    self.db.sounds[key] = enabled
    if key == "partyInvite" then self.db.sounds.party = enabled end
end

function CC:GetAlertSoundVolume(channel)
    self.db.soundVolumes = self.db.soundVolumes or deepCopy(defaults.soundVolumes)
    local key = self:GetNotificationSoundKey(channel)
    return math.max(0, math.min(1, tonumber(key and self.db.soundVolumes[key]) or 1))
end

function CC:PlayAlertSound(channel, force)
    if not self.db then return end
    self.db.sounds = self.db.sounds or deepCopy(defaults.sounds)
    self.db.soundChoices = self.db.soundChoices or deepCopy(defaults.soundChoices)
    if self.db.sound == false or self.db.sounds.master == false then return end

    local key = self:GetNotificationSoundKey(channel)
    local preset = self:GetSoundChoice(channel)
    if preset == "OFF" then return end
    if key and self.db.sounds[key] == false then return end
    if key == "partyInvite" and self.db.sounds.partyInvite == nil and self.db.sounds.party == false then return end

    self.state.lastAlertSoundAt = self.state.lastAlertSoundAt or {}
    local now = type(GetTime) == "function" and GetTime() or time()
    local cooldown = channel == "QUEST" and 1.15 or 0.12
    local previous = tonumber(self.state.lastAlertSoundAt[channel]) or 0
    if not force and now - previous < cooldown then return end
    self.state.lastAlertSoundAt[channel] = now

    local played = self:PlaySoundPreset(preset, self:GetAlertSoundVolume(channel))
    if force and not played then
        self:Print("That sound is unavailable in this WoW client. Choose another notification sound.")
    end
end

function CC:QueueOutgoingFeedMessage(channel, text)
    channel = string.upper(tostring(channel or "GENERAL"))
    local now = time and time() or 0
    local player = self.state.playerFullName or self.state.playerName or "You"
    local message
    if channel == "GUILD" or channel == "OFFICER" then
        message = self:AddGuildMessage(player, text, false, UnitGUID("player"), channel == "OFFICER", now, true)
        self:NotifyChatUI("GUILD", nil, message, false)
        return message
    end

    local labels = {
        PARTY = "Party", RAID = "Raid", RAID_WARNING = "Raid Warning", INSTANCE = "Instance", BATTLEGROUND = "Battleground", SAY = "Say", YELL = "Yell", EMOTE = "Emote",
        GENERAL = "General", TRADE = "Trade", LOCALDEFENSE = "LocalDefense", LFG = "LookingForGroup",
    }
    local types = {
        PARTY = "CHAT_MSG_PARTY", RAID = "CHAT_MSG_RAID", RAID_WARNING = "CHAT_MSG_RAID_WARNING", INSTANCE = "CHAT_MSG_INSTANCE_CHAT", BATTLEGROUND = "CHAT_MSG_BATTLEGROUND",
        SAY = "CHAT_MSG_SAY", YELL = "CHAT_MSG_YELL", EMOTE = "CHAT_MSG_EMOTE",
        GENERAL = "CHAT_MSG_CHANNEL", TRADE = "CHAT_MSG_CHANNEL", LOCALDEFENSE = "CHAT_MSG_CHANNEL", LFG = "CHAT_MSG_CHANNEL",
    }
    local chatType = types[channel]
    if not chatType then return nil end
    message = self:AddGeneralMessage(player, text, false, UnitGUID("player"), now, labels[channel] or channel, chatType, true)
    self:NotifyChatUI("GENERAL", nil, message, false)
    return message
end

function CC:CallSendChatMessage(text, chatType, language, target)
    text = tostring(text or "")
    chatType = string.upper(tostring(chatType or "SAY"))
    local senders = {}
    if type(_G.SendChatMessage) == "function" then senders[#senders + 1] = _G.SendChatMessage end
    if _G.C_ChatInfo and type(_G.C_ChatInfo.SendChatMessage) == "function" then
        senders[#senders + 1] = _G.C_ChatInfo.SendChatMessage
    end
    if #senders == 0 then return false, "SendChatMessage is unavailable" end

    local lastError
    for _, sender in ipairs(senders) do
        local ok, result = pcall(sender, text, chatType, language, target)
        if ok and result ~= false then return true, result end
        lastError = ok and result or result
    end
    return false, lastError or "The chat API rejected the message"
end

function CC:CallBattleNetWhisper(accountID, text)
    accountID = tonumber(accountID)
    if not accountID then return false, "Battle.net account route is unavailable" end
    local senders = {}
    if type(_G.BNSendWhisper) == "function" then senders[#senders + 1] = _G.BNSendWhisper end
    if _G.C_BattleNet and type(_G.C_BattleNet.SendWhisper) == "function" then
        senders[#senders + 1] = _G.C_BattleNet.SendWhisper
    end
    if #senders == 0 then return false, "Battle.net whispers are unavailable" end

    local lastError
    for _, sender in ipairs(senders) do
        local ok, result = pcall(sender, accountID, tostring(text or ""))
        if ok and result ~= false then return true, result end
        lastError = ok and result or result
    end
    return false, lastError or "The Battle.net whisper API rejected the message"
end

function CC:SendMessage(channel, target, text)
    text = tostring(text or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    if text == "" then return false end
    if not self.db then return false end
    self:EnsureChatStorage()

    channel = string.upper(tostring(channel or "GENERAL"))
    if channel == "WHISPER" then
        target = self:EnsureWhisperConversation(target)
        if not target then
            self:Print("Choose a whisper conversation first.")
            return false
        end
        if self:IsBattleNetConversation(target) then
            local accountID = self:GetBattleNetAccountID(target)
            if not accountID then
                self:Print("That Battle.net friend is not currently available. Open Friends after they come online to refresh the route.")
                return false
            end
            local message, conversationTarget = self:AddBattleNetWhisper(accountID, self:GetWhisperDisplayName(target), text, false, time and time() or 0, true)
            self:NotifyChatUI("WHISPER", conversationTarget, message, false)
            local ok, result = self:CallBattleNetWhisper(accountID, text)
            if ok then return true end
            self:MarkPendingMessageFailed(message, result)
            self:NotifyChatUI("WHISPER", conversationTarget, message, false)
            self:Print("Unable to send that Battle.net whisper on this client.")
            return false
        end
        local routeTarget = self:GetWhisperRoute(target) or target
        local message, conversationTarget = self:AddWhisper(routeTarget, text, false, nil, time and time() or 0, true)
        self:NotifyChatUI("WHISPER", conversationTarget, message, false)
        local ok, result = self:CallSendChatMessage(text, "WHISPER", nil, routeTarget)
        if not ok or result == false then
            self:MarkPendingMessageFailed(message, result)
            self:NotifyChatUI("WHISPER", conversationTarget, message, false)
            self:Print("Unable to send that whisper on this client.")
            return false
        end
        return true
    end

    local pendingMessage = self:QueueOutgoingFeedMessage(channel, text)
    local ok, result = false, nil
    if channel == "GUILD" or channel == "OFFICER" or channel == "PARTY" or channel == "RAID" or channel == "RAID_WARNING" then
        ok, result = self:CallSendChatMessage(text, channel)
    elseif channel == "INSTANCE" then
        ok, result = self:CallSendChatMessage(text, "INSTANCE_CHAT")
    elseif channel == "BATTLEGROUND" then
        ok, result = self:CallSendChatMessage(text, "BATTLEGROUND")
        if not ok then ok, result = self:CallSendChatMessage(text, "INSTANCE_CHAT") end
    elseif channel == "SAY" or channel == "YELL" or channel == "EMOTE" then
        ok, result = self:CallSendChatMessage(text, channel)
    elseif channel == "GENERAL" or channel == "TRADE" or channel == "LOCALDEFENSE" or channel == "LFG" then
        local channelID = self:GetNamedChannelID(channel)
        if not channelID then
            local labels = { GENERAL = "General", TRADE = "Trade", LOCALDEFENSE = "LocalDefense", LFG = "LookingForGroup" }
            self:MarkPendingMessageFailed(pendingMessage, "Channel is not joined")
            self:NotifyChatUI("GENERAL", nil, pendingMessage, false)
            self:Print("Join the " .. tostring(labels[channel] or channel) .. " channel before sending a message.")
            return false
        end
        ok, result = self:CallSendChatMessage(text, "CHANNEL", nil, channelID)
    elseif channel == "CHANNEL" then
        local channelID = tonumber(target)
        if not channelID or channelID < 1 then
            self:MarkPendingMessageFailed(pendingMessage, "Channel number is invalid")
            self:NotifyChatUI("GENERAL", nil, pendingMessage, false)
            self:Print("That numbered chat channel is not available.")
            return false
        end
        ok, result = self:CallSendChatMessage(text, "CHANNEL", nil, channelID)
    else
        self:MarkPendingMessageFailed(pendingMessage, "Unknown chat destination")
        return false
    end

    if not ok or result == false then
        self:MarkPendingMessageFailed(pendingMessage, result)
        if channel == "GUILD" or channel == "OFFICER" then self:NotifyChatUI("GUILD", nil, pendingMessage, false)
        else self:NotifyChatUI("GENERAL", nil, pendingMessage, false) end
        self:Print("Unable to send that message on this client.")
        return false
    end
    return true
end

function CC:AddCommandHistory(text)
    if not self.db or not self.db.ui or self.db.ui.commandHistory == false then return end
    text = tostring(text or "")
    if string.sub(text, 1, 1) ~= "/" or text == "/" then return end
    self.db.commandHistory = self.db.commandHistory or {}
    if self.db.commandHistory[#self.db.commandHistory] == text then return end
    table.insert(self.db.commandHistory, text)
    while #self.db.commandHistory > 50 do table.remove(self.db.commandHistory, 1) end
end

function CC:GetCommandHistory()
    self.db.commandHistory = self.db.commandHistory or {}
    return self.db.commandHistory
end

local PARTY_INVITE_POPUP_TYPES = {
    PARTY_INVITE = true,
    PARTY_INVITE_XREALM = true,
    PARTY_INVITE_XREALM_GUID = true,
    PARTY_INVITE_XREALM_NO_NAME = true,
    PARTY_INVITE_XREALM_NO_NAME_GUID = true,
}

local function popupIsShown(popup)
    if not popup or type(popup.IsShown) ~= "function" then return false end
    local ok, shown = pcall(popup.IsShown, popup)
    return ok and shown and true or false
end

local function restoreSuppressedPopupFrame(popup, saved)
    if not popup then return end
    if popup.SetAlpha then popup:SetAlpha(tonumber(saved and saved.alpha) or 1) end
    if popup.EnableMouse then popup:EnableMouse(not saved or saved.mouseEnabled ~= false) end
end

function CC:IsPlayerInGroup()
    if type(IsInGroup) == "function" then
        local ok, grouped = pcall(IsInGroup)
        if ok then return grouped and true or false end
    end
    if type(GetNumGroupMembers) == "function" then
        local ok, count = pcall(GetNumGroupMembers)
        if ok and (tonumber(count) or 0) > 1 then return true end
    end
    if type(GetNumPartyMembers) == "function" then
        local ok, count = pcall(GetNumPartyMembers)
        if ok and (tonumber(count) or 0) > 0 then return true end
    end
    return false
end

function CC:IsPlayerInParty()
    if type(IsInRaid) == "function" then
        local ok, inRaid = pcall(IsInRaid)
        if ok and inRaid then return false end
    end
    return self:IsPlayerInGroup()
end

function CC:ShouldReplacePartyInvitePopup()
    if not self.db or not self.db.ui or self.db.ui.replacePartyInvitePopup ~= true then return false end
    if self.IsFeatureEnabled and not self:IsFeatureEnabled("notifications") then return false end
    if self.IsNotificationEnabled and not self:IsNotificationEnabled("PARTY_INVITE") then return false end
    return true
end

function CC:SuppressBlizzardPartyInvitePopups()
    if not self:ShouldReplacePartyInvitePopup() then return end
    self.state.suppressedPartyInvitePopups = self.state.suppressedPartyInvitePopups or {}
    local popupCount = tonumber(_G.STATICPOPUP_NUMDIALOGS) or 4
    for index = 1, popupCount do
        local popup = _G["StaticPopup" .. index]
        local popupType = popup and popup.which
        if popup and popupIsShown(popup) and PARTY_INVITE_POPUP_TYPES[popupType] then
            local saved = self.state.suppressedPartyInvitePopups[popup]
            if not saved then
                local mouseEnabled = true
                if popup.IsMouseEnabled then
                    local ok, value = pcall(popup.IsMouseEnabled, popup)
                    if ok then mouseEnabled = value and true or false end
                end
                saved = {
                    alpha = popup.GetAlpha and popup:GetAlpha() or 1,
                    mouseEnabled = mouseEnabled,
                    which = popupType,
                }
                self.state.suppressedPartyInvitePopups[popup] = saved
            end
            if popup.SetAlpha then popup:SetAlpha(0) end
            if popup.EnableMouse then popup:EnableMouse(false) end
        end
    end
end

-- Compatibility alias used by older UI code. The native popup is made fully
-- transparent and non-interactive instead of being hidden while the invitation
-- is unresolved. Hiding it too early can make Classic clients decline the invite.
function CC:HideBlizzardPartyInvitePopups()
    self:SuppressBlizzardPartyInvitePopups()
end

function CC:InstallPartyInvitePopupHook()
    if self.state.partyInvitePopupHookInstalled then return true end
    if type(_G.hooksecurefunc) ~= "function" or type(_G.StaticPopup_Show) ~= "function" then return false end
    local owner = self
    local ok = pcall(_G.hooksecurefunc, "StaticPopup_Show", function(which)
        if not PARTY_INVITE_POPUP_TYPES[which] or not owner:ShouldReplacePartyInvitePopup() then return end
        owner:SuppressBlizzardPartyInvitePopups()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() owner:SuppressBlizzardPartyInvitePopups() end)
        end
    end)
    if ok then self.state.partyInvitePopupHookInstalled = true end
    return ok
end

function CC:RestoreBlizzardPartyInvitePopups()
    local suppressed = self.state and self.state.suppressedPartyInvitePopups
    if type(suppressed) ~= "table" then return end
    for popup, saved in pairs(suppressed) do
        restoreSuppressedPopupFrame(popup, saved)
        suppressed[popup] = nil
    end
end

-- Use only after the invitation has resolved. The frame stays invisible while
-- Blizzard's dialog is dismissed, then its reusable frame properties are restored.
function CC:FinalizeBlizzardPartyInvitePopups()
    local suppressed = self.state and self.state.suppressedPartyInvitePopups
    if type(suppressed) ~= "table" then return end
    for popup, saved in pairs(suppressed) do
        local popupType = (popup and popup.which) or (saved and saved.which)
        if popup and popupIsShown(popup) and PARTY_INVITE_POPUP_TYPES[popupType] then
            if type(_G.StaticPopup_Hide) == "function" then
                pcall(_G.StaticPopup_Hide, popupType)
            end
            if popupIsShown(popup) and type(popup.Hide) == "function" then
                pcall(popup.Hide, popup)
            end
        end
        restoreSuppressedPopupFrame(popup, saved)
        suppressed[popup] = nil
    end
end

function CC:GetPendingPartyInvitePopup()
    local popupCount = tonumber(_G.STATICPOPUP_NUMDIALOGS) or 4
    for index = 1, popupCount do
        local popup = _G["StaticPopup" .. index]
        local popupType = popup and popup.which
        if popup and popupIsShown(popup) and PARTY_INVITE_POPUP_TYPES[popupType] then
            return popup
        end
    end
    return nil
end

function CC:AcceptPendingPartyInvite()
    if not self.state.partyInvitePending then return false, "No party invitation is pending." end
    self.state.partyInviteAction = "ACCEPTING"
    self.state.partyInviteAcceptedAt = type(GetTime) == "function" and GetTime() or (type(time) == "function" and time() or 0)

    -- The CreshChat ACCEPT button is already a hardware click, so the native
    -- group API can be called directly. The Blizzard dialog remains invisible
    -- until GROUP_ROSTER_UPDATE confirms the join, then it is safely dismissed.
    local lastError = "The party accept API is unavailable on this client."
    local attempts = {}
    if type(_G.AcceptGroup) == "function" then attempts[#attempts + 1] = _G.AcceptGroup end
    if _G.C_PartyInfo and type(_G.C_PartyInfo.AcceptInvite) == "function" then attempts[#attempts + 1] = _G.C_PartyInfo.AcceptInvite end
    for _, acceptInvite in ipairs(attempts) do
        local ok, result = pcall(acceptInvite)
        if ok and result ~= false then
            self:SuppressBlizzardPartyInvitePopups()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function() self:SuppressBlizzardPartyInvitePopups() end)
                C_Timer.After(0.20, function() self:SuppressBlizzardPartyInvitePopups() end)
            end
            return true, result
        end
        lastError = result or lastError
    end
    self.state.partyInviteAction = nil
    self.state.partyInviteAcceptedAt = nil
    return false, lastError
end

function CC:DeclinePendingPartyInvite()
    if not self.state.partyInvitePending then return false, "No party invitation is pending." end
    self.state.partyInviteAction = "DECLINING"

    local lastError = "The party decline API is unavailable on this client."
    local attempts = {}
    if type(_G.DeclineGroup) == "function" then attempts[#attempts + 1] = _G.DeclineGroup end
    if _G.C_PartyInfo and type(_G.C_PartyInfo.DeclineInvite) == "function" then attempts[#attempts + 1] = _G.C_PartyInfo.DeclineInvite end
    for _, declineInvite in ipairs(attempts) do
        local ok, result = pcall(declineInvite)
        if ok and result ~= false then
            self:SuppressBlizzardPartyInvitePopups()
            return true, result
        end
        lastError = result or lastError
    end
    self.state.partyInviteAction = nil
    return false, lastError
end

function CC:GetFirstEventMessage(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if type(value) == "string" and value ~= "" then return value end
    end
    return nil
end

function CC:ClearHistory()
    local shared = self:EnsureAccountWhisperStorage()
    shared.whispers = {}
    shared.conversations = {}
    shared.whisperRoutes = {}
    shared.whisperKinds = {}
    shared.whisperDisplayNames = {}
    shared.battleNetRoutes = {}
    shared.battleNetRouteKeys = {}
    shared.battleNetFingerprints = {}
    self:BindSharedWhisperStorage()
    self.db.history.guild = {}
    self.db.history.general = {}
    self.db.history.combat = {}
    self.db.history.quests = {}
    self.db.questConversations = {}
    self.state.unreadWhispers = 0
    self.state.unreadGuild = 0
    self.state.unreadGeneral = 0
    self.state.unreadQuests = 0
    self.state.lastWhisperTarget = nil
    if self.UI then
        self.UI.unreadByTarget = {}
        self.UI.unreadQuestByTarget = {}
        self.UI.currentQuestTarget = nil
    end
    if self.UI and self.UI.RefreshAll then self.UI:RefreshAll() end
end

local filteredEvents = {
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_BATTLEGROUND",
    "CHAT_MSG_BATTLEGROUND_LEADER",
    "CHAT_MSG_MONSTER_SAY",
    "CHAT_MSG_MONSTER_YELL",
    "CHAT_MSG_MONSTER_EMOTE",
    "CHAT_MSG_MONSTER_WHISPER",
    "CHAT_MSG_MONSTER_PARTY",
    "CHAT_MSG_RAID_BOSS_EMOTE",
    "CHAT_MSG_RAID_BOSS_WHISPER",
    "CHAT_MSG_LOOT",
    "CHAT_MSG_MONEY",
    "CHAT_MSG_COMBAT_XP_GAIN",
    "CHAT_MSG_COMBAT_HONOR_GAIN",
    "CHAT_MSG_COMBAT_FACTION_CHANGE",
    "CHAT_MSG_SKILL",
    "CHAT_MSG_TRADESKILLS",
    "CHAT_MSG_OPENING",
    "CHAT_MSG_BG_SYSTEM_NEUTRAL",
    "CHAT_MSG_BG_SYSTEM_ALLIANCE",
    "CHAT_MSG_BG_SYSTEM_HORDE",
}

local filteredEventLookup = {}
for _, eventName in ipairs(filteredEvents) do
    filteredEventLookup[eventName] = true
end

local function escapeLuaPattern(text)
    return (tostring(text or ""):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function formatStringCapturePattern(formatText)
    formatText = tostring(formatText or "")
    if formatText == "" then return nil end
    local token = "\001"
    formatText = formatText:gsub("%%%d+%$s", token):gsub("%%s", token)
    formatText = escapeLuaPattern(formatText)
    formatText = formatText:gsub(token, "(.+)")
    return "^" .. formatText .. "$"
end

function CC:IsPlayerNotFoundSystemMessage(message)
    if not self.db or not self.db.ui or self.db.ui.suppressOfflineWhisperErrors == false then return false end
    local raw = tostring(message or "")
    if raw == "" then return false end
    for _, globalName in ipairs({ "ERR_CHAT_PLAYER_NOT_FOUND_S", "ERR_CHAT_PLAYER_NOT_FOUND" }) do
        local pattern = formatStringCapturePattern(_G[globalName])
        if pattern and string.match(raw, pattern) then return true end
    end
    local lower = string.lower(raw)
    return string.find(lower, "no player named", 1, true) ~= nil
        and (string.find(lower, "currently online", 1, true) ~= nil
            or string.find(lower, "currently playing", 1, true) ~= nil
            or string.find(lower, "is online", 1, true) ~= nil)
end

function CC:ExtractPlayerNotFoundName(message)
    local raw = tostring(message or "")
    for _, globalName in ipairs({ "ERR_CHAT_PLAYER_NOT_FOUND_S", "ERR_CHAT_PLAYER_NOT_FOUND" }) do
        local pattern = formatStringCapturePattern(_G[globalName])
        if pattern then
            local name = string.match(raw, pattern)
            if name and name ~= "" then return self:CleanPlayerName(name) end
        end
    end
    local name = string.match(raw, "'([^']+)'") or string.match(raw, '\"([^\"]+)\"')
    if not name then
        name = string.match(raw, "[Nn]o player named%s+([^%s]+)")
    end
    return self:CleanPlayerName(name or "")
end

function CC:FindPendingWhisperMessage(target)
    if not self.db or not self.db.history or not self.db.history.whispers then return nil, nil end
    target = self:CleanPlayerName(target)
    local newest, newestTarget, newestTime
    for conversationTarget, list in pairs(self.db.history.whispers) do
        if not self:IsBattleNetConversation(conversationTarget) then
            local route = self:GetWhisperRoute(conversationTarget) or conversationTarget
            local matches = target == "" or self:WhisperNamesEquivalent(conversationTarget, target) or self:WhisperNamesEquivalent(route, target)
            if matches then
                for index = #list, math.max(1, #list - 8), -1 do
                    local message = list[index]
                    if message and message.pending == true and message.incoming == false then
                        local stamp = tonumber(message.timestamp) or 0
                        if not newest or stamp > (newestTime or 0) then
                            newest, newestTarget, newestTime = message, conversationTarget, stamp
                        end
                        break
                    end
                end
            end
        end
    end
    return newest, newestTarget
end

function CC:HandleSuppressedPlayerNotFound(message)
    local target = self:ExtractPlayerNotFoundName(message)
    local pending, conversationTarget = self:FindPendingWhisperMessage(target)
    if not pending and self.state.lastWhisperTarget then
        pending, conversationTarget = self:FindPendingWhisperMessage(self.state.lastWhisperTarget)
    end
    if pending then
        self:MarkPendingMessageFailed(pending, "Player is offline or unavailable")
        self:NotifyChatUI("WHISPER", conversationTarget, pending, false)
    end
    self.state.suppressedOfflineWhisperErrors = (tonumber(self.state.suppressedOfflineWhisperErrors) or 0) + 1
    self.state.lastUnavailableWhisperTarget = target ~= "" and target or nil
    return true
end

local function chatFilter(_, event, ...)
    -- This filter is also a third live-capture route. It never suppresses normal chat:
    -- ChatFrame1 stays transparent, while Blizzard still performs its normal internal
    -- bookkeeping for channels, replies and player-menu whispers.
    if CC.db and filteredEventLookup[event] then
        CC:DispatchChatEvent("FILTER", event, ...)
    end
    return false
end

local function systemMessageFilter(_, event, message, ...)
    if event == "CHAT_MSG_SYSTEM" and CC:IsPlayerNotFoundSystemMessage(message) then
        return true
    end
    return false
end

function CC:RegisterChatFilters()
    if type(_G.ChatFrame_AddMessageEventFilter) ~= "function" then
        self.state.chatFilterUnavailable = true
        return false
    end
    self.registeredChatFilterEvents = self.registeredChatFilterEvents or {}
    local registered = 0
    for _, event in ipairs(filteredEvents) do
        if not self.registeredChatFilterEvents[event] then
            local ok = pcall(_G.ChatFrame_AddMessageEventFilter, event, chatFilter)
            if ok then self.registeredChatFilterEvents[event] = true end
        end
        if self.registeredChatFilterEvents[event] then registered = registered + 1 end
    end
    if not self.systemMessageFilterRegistered then
        local ok = pcall(_G.ChatFrame_AddMessageEventFilter, "CHAT_MSG_SYSTEM", systemMessageFilter)
        self.systemMessageFilterRegistered = ok and true or false
    end
    self.state.registeredChatFilters = registered
    self.state.systemMessageFilterRegistered = self.systemMessageFilterRegistered and true or false
    self.filtersRegistered = registered > 0
    return self.filtersRegistered
end

function CC:ShouldHideBlizzardChat()
    return self.db and self.db.hideBlizzard == true and self.state.chatCaptureReady ~= false
end

local blizzardChatControlNames = {
    "GeneralDockManager",
    "ChatFrameMenuButton",
    "ChatFrameChannelButton",
    "ChatFrameToggleVoiceDeafenButton",
    "ChatFrameToggleVoiceMuteButton",
    "QuickJoinToastButton",
}

function CC:HookBlizzardChatFrames()
    if self.blizzardChatHooksInstalled then
        return
    end

    local count = tonumber(NUM_CHAT_WINDOWS) or 10
    for index = 1, count do
        local frame = _G["ChatFrame" .. index]
        local tab = _G["ChatFrame" .. index .. "Tab"]

        if frame and frame.HookScript then
            frame:HookScript("OnShow", function(selfFrame)
                if CC:ShouldHideBlizzardChat() then
                    local frameName = selfFrame.GetName and selfFrame:GetName() or ""
                    if frameName == "ChatFrame1" then
                        -- Keep the primary Blizzard chat frame alive as an invisible relay.
                        -- Several built-in chat and player-menu actions expect it to exist.
                        selfFrame:SetAlpha(0)
                        if selfFrame.EnableMouse then selfFrame:EnableMouse(false) end
                    else
                        selfFrame:Hide()
                    end
                end
            end)
        end
        if tab and tab.HookScript then
            tab:HookScript("OnShow", function(selfTab)
                if CC:ShouldHideBlizzardChat() then
                    selfTab:Hide()
                end
            end)
        end
    end

    for _, name in ipairs(blizzardChatControlNames) do
        local control = _G[name]
        if control and control.HookScript then
            control:HookScript("OnShow", function(selfControl)
                if CC:ShouldHideBlizzardChat() then
                    selfControl:Hide()
                end
            end)
        end
    end

    self.blizzardChatHooksInstalled = true
end

function CC:HideBlizzardEditBoxes()
    local count = tonumber(NUM_CHAT_WINDOWS) or 10
    for index = 1, count do
        local editBox = _G["ChatFrame" .. index .. "EditBox"]
        if editBox and editBox:IsShown() then
            if ChatEdit_DeactivateChat then
                pcall(ChatEdit_DeactivateChat, editBox)
            end
            editBox:ClearFocus()
            editBox:Hide()
        end
    end
end

function CC:ApplyBlizzardChatVisibility()
    if not self.db then
        return
    end

    self:HookBlizzardChatFrames()
    local hide = self:ShouldHideBlizzardChat()
    -- Never hide Blizzard chat when the Chat feature is disabled.
    -- The player must always have a working chat surface.
    if hide and self.IsFeatureEnabled and not self:IsFeatureEnabled("chat") then
        hide = false
    end
    if self.db.hideBlizzard and self.state.chatCaptureReady == false then
        -- Never hide Blizzard chat if this client rejected the core chat events.
        -- This leaves the user with a working fallback instead of a silent screen.
        hide = false
        self.state.blizzardChatSafetyFallback = true
    else
        self.state.blizzardChatSafetyFallback = false
    end
    local count = tonumber(NUM_CHAT_WINDOWS) or 10

    for index = 1, count do
        local frame = _G["ChatFrame" .. index]
        local tab = _G["ChatFrame" .. index .. "Tab"]
        local editBox = _G["ChatFrame" .. index .. "EditBox"]

        if hide then
            if index == 1 and frame then
                -- Do not fully hide ChatFrame1. Keeping it shown and transparent preserves
                -- Blizzard's chat routing, event handling and right-click whisper workflow.
                frame:SetAlpha(0)
                if frame.EnableMouse then frame:EnableMouse(false) end
                frame:Show()
            elseif frame then
                frame:Hide()
            end
            if tab then tab:Hide() end
            if editBox then
                editBox:ClearFocus()
                editBox:Hide()
            end
        elseif index == 1 then
            if frame then
                frame:SetAlpha(1)
                if frame.EnableMouse then frame:EnableMouse(true) end
                frame:Show()
            end
            if tab then tab:Show() end
        else
            if frame then frame:SetAlpha(1) end
        end
    end

    for _, name in ipairs(blizzardChatControlNames) do
        local control = _G[name]
        if control then
            if hide then
                control:Hide()
            elseif name == "GeneralDockManager" or name == "ChatFrameMenuButton" then
                control:Show()
            end
        end
    end

    if not hide and FCF_DockUpdate then
        FCF_DockUpdate()
    end
end

function CC:SetBlizzardChatHidden(hidden)
    self.db.hideBlizzard = hidden and true or false
    self:ApplyBlizzardChatVisibility()
    if self.UI and self.UI.RefreshSettingsPanel then
        self.UI:RefreshSettingsPanel()
    end
end

function CC:ChatEventKey(event, ...)
    local text, author = ...
    local lineID = select(11, ...)
    if lineID and tonumber(lineID) and tonumber(lineID) > 0 then
        return tostring(event) .. ":" .. tostring(lineID)
    end

    local bucket = math.floor((GetTime and GetTime() or 0) * 5)
    return table.concat({ tostring(event), tostring(author or ""), tostring(text or ""), tostring(bucket) }, ":")
end

function CC:ShouldProcessChatEvent(event, ...)
    self.processedChatEvents = self.processedChatEvents or {}
    local key = self:ChatEventKey(event, ...)
    local now = GetTime and GetTime() or 0
    local previous = self.processedChatEvents[key]
    return not (previous and (now - previous) < 2)
end

function CC:MarkChatEventProcessed(event, ...)
    self.processedChatEvents = self.processedChatEvents or {}
    local key = self:ChatEventKey(event, ...)
    local now = GetTime and GetTime() or 0
    self.processedChatEvents[key] = now
    self.processedChatEventCounter = (self.processedChatEventCounter or 0) + 1
    if self.processedChatEventCounter % 50 == 0 then
        for oldKey, seenAt in pairs(self.processedChatEvents) do
            if (now - seenAt) > 15 then self.processedChatEvents[oldKey] = nil end
        end
    end
end

function CC:ChannelDisplayName(channelName, channelBaseName)
    local label = tostring(channelBaseName or "")
    if label == "" then
        label = tostring(channelName or "")
    end
    label = string.gsub(label, "^%d+%.%s*", "")
    label = string.gsub(label, "%s*%-%s*.+$", "")
    if label == "" then
        label = "Channel"
    end
    return label
end

local liveFeedLabels = {
    CHAT_MSG_SAY = "Say",
    CHAT_MSG_YELL = "Yell",
    CHAT_MSG_EMOTE = "Emote",
    CHAT_MSG_TEXT_EMOTE = "Emote",
    CHAT_MSG_PARTY = "Party",
    CHAT_MSG_PARTY_LEADER = "Party Leader",
    CHAT_MSG_RAID = "Raid",
    CHAT_MSG_RAID_LEADER = "Raid Leader",
    CHAT_MSG_RAID_WARNING = "Raid Warning",
    CHAT_MSG_INSTANCE_CHAT = "Instance",
    CHAT_MSG_INSTANCE_CHAT_LEADER = "Instance Leader",
    CHAT_MSG_BATTLEGROUND = "Battleground",
    CHAT_MSG_BATTLEGROUND_LEADER = "Battleground Leader",
    CHAT_MSG_MONSTER_SAY = "NPC",
    CHAT_MSG_MONSTER_YELL = "NPC Yell",
    CHAT_MSG_MONSTER_EMOTE = "NPC Emote",
    CHAT_MSG_MONSTER_WHISPER = "NPC Whisper",
    CHAT_MSG_MONSTER_PARTY = "NPC Party",
    CHAT_MSG_RAID_BOSS_EMOTE = "Boss",
    CHAT_MSG_RAID_BOSS_WHISPER = "Boss Whisper",
    CHAT_MSG_LOOT = "Loot",
    CHAT_MSG_MONEY = "Money",
    CHAT_MSG_COMBAT_XP_GAIN = "Experience",
    CHAT_MSG_COMBAT_HONOR_GAIN = "Honor",
    CHAT_MSG_COMBAT_FACTION_CHANGE = "Reputation",
    CHAT_MSG_SKILL = "Skill",
    CHAT_MSG_TRADESKILLS = "Profession",
    CHAT_MSG_OPENING = "Opening",
    CHAT_MSG_BG_SYSTEM_NEUTRAL = "Battleground",
    CHAT_MSG_BG_SYSTEM_ALLIANCE = "Battleground",
    CHAT_MSG_BG_SYSTEM_HORDE = "Battleground",
}

function CC:DispatchChatEvent(source, event, ...)
    source = tostring(source or "UNKNOWN")
    if self.IsFeatureEnabled and not self:IsFeatureEnabled("chat") then return nil end
    if not self:ShouldProcessChatEvent(event, ...) then return nil end
    self.state.chatSourceCounts = self.state.chatSourceCounts or {}
    self.state.chatSourceCounts[source] = (self.state.chatSourceCounts[source] or 0) + 1
    self.state.lastChatSource = source
    self.state.currentChatSource = source
    local arguments = { n = select("#", ...), ... }
    local ok, result = pcall(self.HandleChatEvent, self, event, unpack(arguments, 1, arguments.n))
    self.state.currentChatSource = nil
    if not ok then
        self.state.chatErrors = (tonumber(self.state.chatErrors) or 0) + 1
        self.state.chatConsecutiveErrors = (tonumber(self.state.chatConsecutiveErrors) or 0) + 1
        self.state.lastChatError = tostring(result or "Unknown chat event error")
        self.state.lastChatErrorEvent = tostring(event or "UNKNOWN")
        self.state.lastChatErrorAt = time and time() or 0
        if self.state.chatConsecutiveErrors >= 3 then
            -- Never leave the player with no visible chat. After repeated processing
            -- failures, reveal Blizzard chat as a safety fallback while diagnostics
            -- remain available through /cc chatcheck.
            local wasReady = self.state.chatCaptureReady ~= false
            self.state.chatCaptureReady = false
            if self.db and self.db.hideBlizzard and self.ApplyBlizzardChatVisibility then
                pcall(self.ApplyBlizzardChatVisibility, self)
                if wasReady then CC:Print("Chat capture was disabled after repeated errors. Blizzard chat has been restored. Run /cc chatcheck to attempt repair.") end
            end
        end
        return nil
    end
    self.state.chatConsecutiveErrors = 0
    if result ~= nil then self:MarkChatEventProcessed(event, unpack(arguments, 1, arguments.n)) end
    return result
end

function CC:ResolveBattleNetEventAccountID(author, ...)
    local shared = self:EnsureAccountWhisperStorage()
    local cleanAuthor = string.lower(self:CleanPlayerName(author))
    local linked = cleanAuthor ~= "" and (shared.battleNetFingerprints[cleanAuthor] or nil) or nil
    if linked and shared.battleNetRoutes[linked] then return tonumber(shared.battleNetRoutes[linked]) end

    local preferred = tonumber(select(13, ...))
    if preferred and (shared.battleNetRouteKeys[tostring(preferred)] or self:GetBattleNetAccountInfoByID(preferred)) then return preferred end
    for index = select("#", ...), 1, -1 do
        local candidate = tonumber(select(index, ...))
        if candidate and candidate > 0 then
            if shared.battleNetRouteKeys[tostring(candidate)] or self:GetBattleNetAccountInfoByID(candidate) then return candidate end
        end
    end
    return preferred
end

function CC:HandleChatEvent(event, ...)
    if not self.db then return nil end
    self:EnsureChatStorage()

    local text, author, _, channelName, _, _, zoneChannelID, _, channelBaseName, _, _, guid = ...
    text = tostring(text or "")
    if text == "" then return nil end
    self.state.liveChatCount = (self.state.liveChatCount or 0) + 1
    self.state.lastChatEvent = event
    self.state.lastChatAt = time and time() or 0
    self.state.lastAcceptedChatSource = self.state.currentChatSource or "UNKNOWN"

    if event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM" then
        local accountID = self:ResolveBattleNetEventAccountID(author, ...)
        local incoming = event == "CHAT_MSG_BN_WHISPER"
        local message, conversationTarget = self:AddBattleNetWhisper(accountID, author or "Battle.net Friend", text, incoming, time and time() or 0)
        self:NotifyChatUI("WHISPER", conversationTarget, message, incoming)
        if incoming then self:PlayAlertSound("WHISPER") end
        return message
    end

    if event == "CHAT_MSG_WHISPER" then
        local target = author or "Unknown"
        local message, conversationTarget = self:AddWhisper(target, text, true, guid)
        self:NotifyChatUI("WHISPER", conversationTarget, message, true)
        self:PlayAlertSound("WHISPER")
        return message
    end

    if event == "CHAT_MSG_WHISPER_INFORM" then
        local target = author or self.state.lastWhisperTarget or "Unknown"
        local message, conversationTarget = self:AddWhisper(target, text, false, guid)
        self:NotifyChatUI("WHISPER", conversationTarget, message, false)
        return message
    end

    if event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" then
        local incoming = not self:IsSelf(author)
        local message = self:AddGuildMessage(author, text, incoming, guid, event == "CHAT_MSG_OFFICER")
        local shouldAlert = incoming and self:ShouldAlertGuild(text)
        self:NotifyChatUI("GUILD", nil, message, shouldAlert)
        if shouldAlert then self:PlayAlertSound(event == "CHAT_MSG_OFFICER" and "OFFICER" or "GUILD") end
        return message
    end

    if event == "CHAT_MSG_CHANNEL" then
        local incoming = not self:IsSelf(author)
        local label = self:ChannelDisplayName(channelName, channelBaseName)
        local message = self:AddGeneralMessage(author, text, incoming, guid, nil, label, event)
        self:NotifyChatUI("GENERAL", nil, message, false)
        return message
    end

    local feedLabel = liveFeedLabels[event]
    if feedLabel then
        local hasAuthor = author ~= nil and tostring(author) ~= ""
        local incoming = not hasAuthor or not self:IsSelf(author)
        local sender = hasAuthor and author or feedLabel
        local message = self:AddGeneralMessage(sender, text, incoming, guid, nil, feedLabel, event)
        self:NotifyChatUI("GENERAL", nil, message, false)
        if incoming and (event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER") then
            self:PlayAlertSound("PARTY_MESSAGE")
        end
        return message
    end

    return nil
end

function CC:InstallChatBridge()
    if not hooksecurefunc then return false end
    local installed = false

    -- Do not mark the bridge installed until the relevant Blizzard function exists.
    -- On Classic clients these functions can become available after ADDON_LOADED,
    -- so PLAYER_LOGIN and PLAYER_ENTERING_WORLD retry any missing route.
    if not self.messageHandlerHooked and type(ChatFrame_MessageEventHandler) == "function" then
        local ok = pcall(hooksecurefunc, "ChatFrame_MessageEventHandler", function(_, event, ...)
            if CC.db and filteredEventLookup[event] then
                CC:DispatchChatEvent("MESSAGE_HANDLER", event, ...)
            end
        end)
        self.messageHandlerHooked = ok and true or false
    end
    installed = self.messageHandlerHooked or installed

    -- Some Classic builds route chat through ChatFrame_OnEvent before the message handler.
    -- Hooking both paths is safe because ShouldProcessChatEvent removes duplicates.
    if not self.chatFrameEventHooked and type(ChatFrame_OnEvent) == "function" then
        local ok = pcall(hooksecurefunc, "ChatFrame_OnEvent", function(_, event, ...)
            if CC.db and filteredEventLookup[event] then
                CC:DispatchChatEvent("CHATFRAME_EVENT", event, ...)
            end
        end)
        self.chatFrameEventHooked = ok and true or false
    end
    installed = self.chatFrameEventHooked or installed

    self.chatBridgeInstalled = installed and true or false
    self.state.chatBridgeMessageHandler = self.messageHandlerHooked and true or false
    self.state.chatBridgeFrameEvent = self.chatFrameEventHooked and true or false
    return self.chatBridgeInstalled
end

local band = (bit and bit.band) or (bit32 and bit32.band)

function CC:IsMineCombatant(guid, flags)
    if not guid then
        return false
    end
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    if guid == playerGUID or (petGUID and guid == petGUID) then
        return true
    end
    if band and flags and COMBATLOG_OBJECT_AFFILIATION_MINE then
        return band(flags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0
    end
    return false
end

function CC:CombatActorName(guid, name, isSource)
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    if guid == playerGUID then
        return isSource and "You" or "you"
    end
    if petGUID and guid == petGUID then
        return "Your pet"
    end
    return self:ShortName(name or "Unknown")
end

function CC:HandleCombatLogEvent(...)
    if not self.db or not self.db.combatEnabled then
        return
    end

    local info
    if CombatLogGetCurrentEventInfo then
        info = { CombatLogGetCurrentEventInfo() }
    else
        info = { ... }
    end
    if not info[2] then
        return
    end
    local timestamp = info[1]
    local subevent = info[2]
    local sourceGUID, sourceName, sourceFlags = info[4], info[5], info[6]
    local destGUID, destName, destFlags = info[8], info[9], info[10]
    local sourceMine = self:IsMineCombatant(sourceGUID, sourceFlags)
    local destMine = self:IsMineCombatant(destGUID, destFlags)
    if not sourceMine and not destMine then
        return
    end

    local source = self:CombatActorName(sourceGUID, sourceName, true)
    local dest = self:CombatActorName(destGUID, destName, false)
    local text, category

    if subevent == "SWING_DAMAGE" then
        local amount = tonumber(info[12]) or 0
        if sourceMine and not destMine then
            text, category = source .. " hit " .. dest .. " for " .. amount, "damageOut"
        elseif destMine then
            text, category = source .. " hit " .. dest .. " for " .. amount, "damageIn"
        end
    elseif subevent == "RANGE_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" then
        local spellName = tostring(info[13] or "Spell")
        local amount = tonumber(info[15]) or 0
        if sourceMine and not destMine then
            text, category = source .. " used " .. spellName .. " on " .. dest .. " for " .. amount, "damageOut"
        elseif destMine then
            text, category = source .. " used " .. spellName .. " on " .. dest .. " for " .. amount, "damageIn"
        end
    elseif subevent == "ENVIRONMENTAL_DAMAGE" and destMine then
        local environment = tostring(info[12] or "Environment")
        local amount = tonumber(info[13]) or 0
        text, category = dest .. " took " .. amount .. " " .. string.lower(environment) .. " damage", "damageIn"
    elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
        local spellName = tostring(info[13] or "Heal")
        local amount = tonumber(info[15]) or 0
        text, category = source .. " healed " .. dest .. " with " .. spellName .. " for " .. amount, "heal"
    elseif subevent == "SPELL_MISSED" or subevent == "RANGE_MISSED" then
        local spellName = tostring(info[13] or "Spell")
        local missType = tostring(info[15] or "missed")
        if sourceMine then
            text, category = source .. "'s " .. spellName .. " " .. string.lower(missType) .. " " .. dest, "miss"
        elseif destMine then
            text, category = source .. "'s " .. spellName .. " " .. string.lower(missType) .. " " .. dest, "miss"
        end
    elseif subevent == "SWING_MISSED" then
        local missType = tostring(info[12] or "missed")
        text, category = source .. " " .. string.lower(missType) .. " " .. dest, "miss"
    elseif subevent == "SPELL_AURA_APPLIED" and destMine then
        text, category = dest .. " gained " .. tostring(info[13] or "an effect"), "aura"
    elseif subevent == "SPELL_AURA_REMOVED" and destMine then
        text, category = dest .. " lost " .. tostring(info[13] or "an effect"), "aura"
    elseif subevent == "SPELL_INTERRUPT" then
        local spellName = tostring(info[13] or "Interrupt")
        local interruptedSpell = tostring(info[16] or "a spell")
        text, category = source .. " interrupted " .. dest .. "'s " .. interruptedSpell .. " with " .. spellName, "utility"
    elseif subevent == "SPELL_DISPEL" then
        local spellName = tostring(info[13] or "Dispel")
        local removedSpell = tostring(info[16] or "an effect")
        text, category = source .. " removed " .. removedSpell .. " from " .. dest .. " with " .. spellName, "utility"
    elseif subevent == "PARTY_KILL" and sourceMine then
        text, category = source .. " defeated " .. dest, "kill"
    elseif subevent == "UNIT_DIED" and destMine then
        text, category = dest == "you" and "You died" or (dest .. " died"), "death"
    end

    if text then
        local message = self:AddCombatMessage(text, category, time())
        if self.UI and message then
            self.UI:OnNewMessage("COMBAT", nil, message, false)
        end
    end
end

function CC:ResetPositions()
    self.db.positions = deepCopy(defaults.positions)
    self:SyncActiveCharacterProfile()
    if self.UI and self.UI.ApplySavedPositions then
        self.UI:ApplySavedPositions()
    end
    self:Print("Window positions reset.")
end

function CC:ResetUISettings()
    if not self.db then return end
    self.db.ui = deepCopy(defaults.ui)
    self.db.colors = deepCopy(defaults.colors)
    self.db.panelScale = defaults.panelScale
    self.db.positions = self.db.positions or {}
    self.db.positions.main = deepCopy(defaults.positions.main)
    self.db.positions.bubble = deepCopy(defaults.positions.bubble)
    self.db.positions.composer = deepCopy(defaults.positions.composer)
    self.db.positions.alerts = deepCopy(defaults.positions.alerts)
    self.db.sizes = deepCopy(defaults.sizes)
    self:SyncActiveCharacterProfile()
    if self.UI then
        if self.UI.ApplySavedPositions then self.UI:ApplySavedPositions() end
        if self.UI.ApplyVisualSettings then self.UI:ApplyVisualSettings() end
    end
    self:Print("Modern UI settings reset for " .. self.version .. ". Chat history was preserved.")
end

function CC:ShowVersionInfo()
    local tocVersion = GetAddOnMetadata and GetAddOnMetadata(self.name, "Version") or self.version
    local schema = self.db and self.db.version or "not loaded"
    local composer = self.UI and self.UI.quickInput and "ready" or "not ready"
    local redirects = self.UI and self.UI.enterChatHooked and "active" or "inactive"
    self:Print("Build " .. tostring(tocVersion or self.version) .. " | database schema " .. tostring(schema) .. ".")
    self:Print("Motion dock composer: " .. composer .. " | Enter redirect: " .. redirects .. ".")
    self:Print("Native WoW commands: " .. ((self.db and self.db.ui and self.db.ui.nativeSlashCommands ~= false) and "active" or "disabled") .. " | directional notification hub: active.")
    if self.Quality then
        local profile = self.db and self.db.ui and self.db.ui.qualityProfile or "BALANCED"
        self:Print("Targeted refresh engine: active | quality profile: " .. tostring(profile) .. " | /cc health for diagnostics.")
    end
end

function CC:AnnounceLoadedBuild()
    if not self.db or self.db.lastAnnouncedBuild == self.version then return end
    self.db.lastAnnouncedBuild = self.version
    local message = "CreshChat " .. self.version .. " loaded - type /cc version to verify"
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(message, 0.10, 0.65, 1.00, 1.0)
    else
        self:Print(message)
    end
end

function CC:RunTest()
    local now = time()
    local whisperTarget = "Alyndra-TestRealm"
    local whisper
    whisper, whisperTarget = self:AddWhisper(whisperTarget, "Hey! Are you free for a dungeon?", true, nil, now)
    local guild = self:AddGuildMessage("Guildmate", "Karazhan group forming in ten minutes.", true, nil, false, now)
    local general = self:AddGeneralMessage("ZonePlayer", "Anyone for the elite quest nearby?", true, nil, now)
    local combat = self:AddCombatMessage("You used Mangle on Training Dummy for 742", "damageOut", now)
    if self.UI then
        self.UI:OnNewMessage("WHISPER", whisperTarget, whisper, true)
        self.UI:OnNewMessage("GUILD", nil, guild, true)
        self.UI:OnNewMessage("GENERAL", nil, general, false)
        self.UI:OnNewMessage("COMBAT", nil, combat, false)
        if self.UI.ShowPartyInvite then self.UI:ShowPartyInvite("Durnan-TestRealm", true) end
        if self.UI.ShowSystemToast then self.UI:ShowSystemToast("CreshChat notification", "This is the full-size main notification slot.", "SUCCESS") end
        if self.UI.ShowPresenceToast then self.UI:ShowPresenceToast("Alyndra-TestRealm", true) end
        if self.UI.ShowBattlePassToast then self.UI:ShowBattlePassToast("Battle Pass reward ready", "Level 10 unlock preview", "BATTLEPASS", "TEST:BATTLEPASS") end
    end
    self:PlayAlertSound("WHISPER")
    if C_Timer and C_Timer.After then
        C_Timer.After(0.65, function()
            CC:PlayAlertSound("GUILD")
        end)
    else
        self:PlayAlertSound("GUILD")
    end
    self:Print("Tested the main notification slot plus Whisper, Guild, friend, party and Battle Pass slide-outs.")
end

local function parseOnOff(value)
    value = string.lower(value or "")
    if value == "on" or value == "1" or value == "yes" or value == "true" then
        return true
    end
    if value == "off" or value == "0" or value == "no" or value == "false" then
        return false
    end
    return nil
end

function CC:ShowHelp()
    self:Print("/cc - open or close CreshChat")
    self:Print("/cc test - create test alerts")
    self:Print("/cc settings - open Themes, Cards, Composer, commands, colours, sizes, features and sounds")
    self:Print("/cc version - verify the loaded QC build and Enter redirect")
    self:Print("/cc preview - open the main chat and composer together")
    self:Print("/cc resetui - reset modern UI settings without deleting chat history")
    self:Print("/cc hideblizz on|off - disable/restore the original Blizzard chat window")
    self:Print("/cc guild all|mentions|off - guild alert mode")
    self:Print("/cc general - open General chat")
    self:Print("/cc friends - open online/offline friends and nearby saved quest givers")
    self:Print("/cc games - open the slide-out games drawer")
    self:Print("/cc achievements - open the Achievements tab")
    self:Print("/cc progress - open the Progress Hub (World Progression, Quests, Combat stats)")
    self:Print("/cc battlepass - open the 100-level Battle Pass")
    self:Print("/cc unlockthemes - spend Cresh Coins on premium themes")
    self:Print("/cc solo - open Frogger, Dungeon Dweller, Solo Chess, Tetris, Texas Hold'em, Blackjack and Higher or Lower")
    self:Print("/cc chess or /cc solochess - start Solo Chess")
    self:Print("/cc tetris or /cc solotetris - start Solo Tetris")
    self:Print("/cc higher or /cc lower - start Higher or Lower")
    self:Print("/cc leaderboard - open shared solo leaderboards")
    self:Print("/cc gamehistory - open recent solo and multiplayer results")
    self:Print("/cc call Name - request a CreshChat voice call")
    self:Print("/cc hangup - end the active CreshChat voice call")
    self:Print("/cc quests - open saved quest-giver conversations")
    self:Print("/cc questtest - add a local quest-chat test conversation")
    self:Print("/cc combat - open the compact Combat Log")
    self:Print("/cc input - open the minimal Enter-to-chat bar")
    self:Print("/cc status - show live chat and whisper-hook status")
    self:Print("/cc sound on|off - all CreshChat notification sounds")
    self:Print("/cc bubble on|off - floating button")
    self:Print("/cc clear - clear saved CreshChat history")
    self:Print("/cc reset - reset window positions")
    self:Print("/cc modules - show which features are currently enabled or disabled")
    self:Print("/cc preset full|games|chat|minimal - apply a feature preset")
    self:Print("/cc settings then Modules tab - per-feature toggle panel")
end

function CC:HandleSlashCommand(input)
    input = tostring(input or "")
    local command, rest = string.match(input, "^(%S*)%s*(.-)$")
    local rawRest = tostring(rest or "")
    command = string.lower(command or "")
    rest = string.lower(rest or "")

    if command == "" or command == "open" then
        if self.UI then
            self.UI:ToggleMain()
        end
        return
    end

    if command == "settings" or command == "options" or command == "config" then
        if self.UI and self.UI.OpenSettings then
            self.UI:OpenSettings()
        end
        return
    end

    if command == "version" or command == "qc" then
        self:ShowVersionInfo()
        return
    end

    if command == "preview" then
        if self.UI then
            self.UI:OpenChannel("GENERAL")
            if self.UI.OpenQuickInput then self.UI:OpenQuickInput("") end
        end
        return
    end

    if command == "resetui" or command == "reset-ui" then
        self:ResetUISettings()
        return
    end

    if command == "test" then
        self:RunTest()
        return
    end

    if command == "hideblizz" then
        local value = parseOnOff(rest)
        if value == nil then
            self:Print("Blizzard chat hiding is " .. (self.db.hideBlizzard and "ON" or "OFF") .. ".")
        else
            self:SetBlizzardChatHidden(value)
            self:Print("Original Blizzard chat window is now " .. (value and "DISABLED" or "ENABLED") .. ".")
        end
        return
    end

    if command == "general" then
        if self.UI then
            self.UI:OpenChannel("GENERAL")
        end
        return
    end

    if command == "friends" or command == "friend" then
        if self.UI then self.UI:OpenChannel("FRIENDS") end
        return
    end

    if command == "games" or command == "game" then
        if self.Games and self.Games.OpenHub then self.Games:OpenHub(self.UI and self.UI.currentTarget) end
        return
    end

    if command == "achievements" or command == "achievement" or command == "achieve" then
        if self.UI and self.UI.LauncherToggleMode then self.UI:LauncherToggleMode("ACHIEVEMENTS") end
        return
    end

    if command == "battlepass" or command == "pass" or command == "bp" then
        if self.UI and self.UI.OpenGameDrawer then self.UI:OpenGameDrawer("BATTLEPASS") end
        return
    end

    if command == "progress" or command == "hub" or command == "tracking" then
        if self.ProgressHub and self.ProgressHub.Toggle then self.ProgressHub:Toggle() end
        return
    end






    if command == "call" or command == "voicecall" then
        local target = rawRest ~= "" and rawRest or (self.UI and self.UI.currentTarget)
        if self.Voice and self.Voice.RequestCall and target and target ~= "" then
            self.Voice:RequestCall(target)
        else
            self:Print("Open a whisper or use /cc call CharacterName.")
        end
        return
    end

    if command == "hangup" or command == "endcall" then
        if self.Voice and self.Voice.EndCall then self.Voice:EndCall() end
        return
    end

    if command == "unlockthemes" or command == "gamethemes" or command == "themeunlock" then
        if self.UI and self.UI.OpenGameDrawer then self.UI:OpenGameDrawer("THEMES") end
        return
    end

    if command == "solo" or command == "arcade" then
        if self.SoloGames and self.SoloGames.OpenHub then self.SoloGames:OpenHub() end
        return
    end

    if command == "frogger" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("FROGGER") end
        return
    end

    if command == "dungeon" or command == "dungeondweller" or command == "dweller" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("DUNGEON") end
        return
    end

    if command == "blackjack" or command == "bj" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("BLACKJACK") end
        return
    end

    if command == "chess" or command == "solochess" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("CHESS") end
        return
    end

    if command == "tetris" or command == "solotetris" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("TETRIS") end
        return
    end

    if command == "poker" or command == "soloholdem" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("HOLDEM") end
        return
    end

    if command == "higher" or command == "lower" or command == "higherlower" or command == "hol" then
        if self.SoloGames and self.SoloGames.StartGame then self.SoloGames:StartGame("HIGHERLOWER") end
        return
    end

    if command == "leaderboard" or command == "leaderboards" or command == "scores" then
        if self.SoloGames and self.SoloGames.OpenLeaderboard then self.SoloGames:OpenLeaderboard() end
        return
    end

    if command == "gamehistory" or command == "matchhistory" then
        if self.SoloGames and self.SoloGames.OpenHistory then self.SoloGames:OpenHistory() end
        return
    end

    if command == "quests" or command == "quest" then
        if self.UI then self.UI:OpenChannel("QUEST", self.UI.currentQuestTarget) end
        return
    end

    if command == "questtest" then
        if self.AddQuestMessage then
            local npcName = "CreshChat Quest Giver"
            local zone = self.GetQuestZoneName and self:GetQuestZoneName() or "Test Zone"
            local message, target = self:AddQuestMessage(npcName, "Adventurer, this is a test of the new quest dialogue inbox.", "DETAIL", "Testing CreshChat", true, zone)
            if message and self.UI and self.UI.OnNewMessage then self.UI:OnNewMessage("QUEST", target, message, false) end
            local objective = self:AddQuestMessage(npcName, "Open the Quests tab and confirm this conversation appears under my name.", "OBJECTIVE", "Testing CreshChat", true, zone)
            if objective and self.UI and self.UI.OnNewMessage then self.UI:OnNewMessage("QUEST", target, objective, false) end
            if self.UI then self.UI:OpenChannel("QUEST", target) end
        else
            self:Print("Quest chat is not available in this build.")
        end
        return
    end

    if command == "combat" then
        if self.UI then
            self.UI:ToggleCombatPanel()
        end
        return
    end

    if command == "input" then
        if self.UI and self.UI.OpenQuickInput then
            self.UI:OpenQuickInput("")
        end
        return
    end

    if command == "status" then
        local channelID = self:GetGeneralChannelID()
        local frame1 = _G.ChatFrame1
        local relayState = frame1 and frame1:IsShown() and "active" or "inactive"
        local hookState = self.UI and self.UI.blizzardChatRedirectsInstalled and "active" or "inactive"
        self:Print("Live events registered: " .. tostring(self.state.registeredChatEvents or 0) .. ". Captured this session: " .. tostring(self.state.liveChatCount or 0) .. ".")
        self:Print("Last event: " .. tostring(self.state.lastChatEvent or "none") .. ". General channel ID: " .. tostring(channelID or "not joined") .. ".")
        self:Print("Invisible Blizzard relay: " .. relayState .. ". Whisper redirect: " .. hookState .. ".")
        return
    end

    if command == "guild" then
        if rest == "all" or rest == "mentions" or rest == "off" then
            self.db.guildAlerts = rest
            self:Print("Guild alerts set to " .. rest .. ".")
        else
            self:Print("Use /cc guild all, /cc guild mentions, or /cc guild off.")
        end
        return
    end

    if command == "sound" then
        local value = parseOnOff(rest)
        self.db.sounds = self.db.sounds or { master = self.db.sound ~= false, whisper = true, guild = true, party = true }
        if value == nil then
            local enabled = self.db.sound ~= false and self.db.sounds.master ~= false
            self:Print("Notification sounds are " .. (enabled and "ON" or "OFF") .. ".")
        else
            self.db.sound = value
            self.db.sounds.master = value
            self:Print("CreshChat notification sounds are now " .. (value and "ON" or "OFF") .. ".")
            if self.UI and self.UI.ApplyVisualSettings then self.UI:ApplyVisualSettings() end
        end
        return
    end

    if command == "bubble" then
        local value = parseOnOff(rest)
        if value == nil then
            self:Print("Floating button is " .. (self.db.bubbleVisible and "ON" or "OFF") .. ".")
        else
            self.db.bubbleVisible = value
            if self.UI and self.UI.SetBubbleGroupShown then
                self.UI:SetBubbleGroupShown(value)
            end
            self:Print("Floating button is now " .. (value and "ON" or "OFF") .. ".")
        end
        return
    end

    if command == "clear" then
        self:ClearHistory()
        self:Print("Saved CreshChat history cleared.")
        return
    end

    if command == "reset" then
        self:ResetPositions()
        return
    end

    -- Feature module commands ---------------------------------------------------

    if command == "modules" or command == "features" then
        if not self.GetFeatureStatusLine then
            self:Print("Feature system not available.")
            return
        end
        local lines = self:GetFeatureStatusLine()
        if type(lines) == "table" then
            for _, line in ipairs(lines) do self:Print(line) end
        else
            self:Print(tostring(lines))
        end
        return
    end

    if command == "preset" then
        local presetKey = string.lower(tostring(rawRest or rest or ""))
        if presetKey == "" then
            self:Print("Current preset: " .. string.upper(self:GetFeaturePreset()))
            self:Print("Available presets: full, games, chat, minimal")
            return
        end
        if not self.ApplyFeaturePreset or not self:ApplyFeaturePreset(presetKey) then
            self:Print("Unknown preset '" .. presetKey .. "'. Use: full, games, chat, minimal.")
            return
        end
        self:Print("Applied preset: " .. string.upper(presetKey) .. ". Reload (/reload) to fully apply all changes.")
        -- Apply immediate safe changes.
        self:ApplyBlizzardChatVisibility()
        if self.UI and self.UI.RefreshSettingsPanel then self.UI:RefreshSettingsPanel() end
        return
    end

    self:ShowHelp()
end

function CC:AddChatFriend(target)
    local conversationTarget = self:ResolveWhisperConversation(target)
    local friendName = self:GetWhisperRoute(conversationTarget) or self:CleanPlayerName(target)
    if not friendName or friendName == "" then
        self:Print("Open a whisper before adding a friend.")
        return false
    end
    if self.Friends and self.Friends.AddFriend then return self.Friends:AddFriend(friendName) end
    self:RememberAccountFriend(friendName, { source = "MANUAL" })
    local ok = false
    if C_FriendList and type(C_FriendList.AddFriend) == "function" then ok = pcall(C_FriendList.AddFriend, friendName)
    elseif type(AddFriend) == "function" then ok = pcall(AddFriend, friendName) end
    self:Print("Added " .. self:ShortName(friendName) .. " to CreshChat's account friends.")
    return ok or true
end

function CC:MergeWhisperDuplicates()
    if not self.db then
        return
    end
    self.db.history.whispers = self.db.history.whispers or {}
    self.db.conversations = self.db.conversations or {}
    self.db.whisperRoutes = self.db.whisperRoutes or {}

    local keys = {}
    local seen = {}
    for target in pairs(self.db.history.whispers) do
        if not seen[target] then table.insert(keys, target); seen[target] = true end
    end
    for target in pairs(self.db.conversations) do
        if not seen[target] then table.insert(keys, target); seen[target] = true end
    end

    local consumed = {}
    for _, base in ipairs(keys) do
        if not consumed[base] then
            local group = { base }
            consumed[base] = true
            for _, candidate in ipairs(keys) do
                if not consumed[candidate] and self:WhisperNamesEquivalent(base, candidate) then
                    table.insert(group, candidate)
                    consumed[candidate] = true
                end
            end

            local canonical = group[1]
            for _, candidate in ipairs(group) do
                if string.find(candidate, "-", 1, true) and not string.find(canonical, "-", 1, true) then
                    canonical = candidate
                end
            end

            local merged = {}
            local newest = 0
            local route = nil
            for _, candidate in ipairs(group) do
                for _, message in ipairs(self.db.history.whispers[candidate] or {}) do
                    message.target = canonical
                    table.insert(merged, message)
                end
                newest = math.max(newest, tonumber(self.db.conversations[candidate]) or 0)
                local candidateRoute = self.db.whisperRoutes[candidate] or candidate
                if not route or (string.find(candidateRoute, "-", 1, true) and not string.find(route, "-", 1, true)) then
                    route = candidateRoute
                end
                if candidate ~= canonical then
                    self.db.history.whispers[candidate] = nil
                    self.db.conversations[candidate] = nil
                    self.db.whisperRoutes[candidate] = nil
                end
            end

            table.sort(merged, function(a, b) return (a.timestamp or 0) < (b.timestamp or 0) end)
            local deduped = {}
            local signatures = {}
            for _, message in ipairs(merged) do
                local signature = tostring(message.timestamp or 0) .. "|" .. tostring(message.incoming) .. "|" .. tostring(message.sender) .. "|" .. tostring(message.text)
                if not signatures[signature] then
                    signatures[signature] = true
                    table.insert(deduped, message)
                end
            end
            self.db.history.whispers[canonical] = deduped
            if newest > 0 or #deduped > 0 then
                self.db.conversations[canonical] = newest > 0 and newest or (deduped[#deduped] and deduped[#deduped].timestamp or time())
            end
            self.db.whisperRoutes[canonical] = self:CleanPlayerName(route or canonical)
            self:TrimHistory(self.db.history.whispers[canonical])
        end
    end
end

function CC:InitializeDatabase()
    CreshChatDB = CreshChatDB or {}
    local previousVersion = tonumber(CreshChatDB.version) or 0
    mergeDefaults(CreshChatDB, defaults)
    if previousVersion < 2 then
        CreshChatDB.hideBlizzard = true
        CreshChatDB.sound = true
    end
    if previousVersion < 3 then
        CreshChatDB.combatEnabled = true
        CreshChatDB.history.general = CreshChatDB.history.general or {}
        CreshChatDB.history.combat = CreshChatDB.history.combat or {}
    end
    if previousVersion < 4 then
        CreshChatDB.quickChannel = CreshChatDB.quickChannel or "GENERAL"
    end
    if previousVersion < 5 then
        CreshChatDB.history.general = CreshChatDB.history.general or {}
    end
    if previousVersion < 6 then
        -- v6 keeps Blizzard's primary chat frame alive invisibly for reliable live routing.
        CreshChatDB.hideBlizzard = true
    end
    if previousVersion < 7 then
        -- v7 moves actionable notifications to the lower-left and uses a five-second timeout.
        CreshChatDB.alertDuration = 5
        CreshChatDB.positions = CreshChatDB.positions or {}
        CreshChatDB.positions.alerts = deepCopy(defaults.positions.alerts)
    end
    if previousVersion < 8 then
        CreshChatDB.whisperRoutes = CreshChatDB.whisperRoutes or {}
    end
    if previousVersion < 9 then
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.sounds = CreshChatDB.sounds or deepCopy(defaults.sounds)
        CreshChatDB.colors = CreshChatDB.colors or deepCopy(defaults.colors)
        CreshChatDB.playerCache = CreshChatDB.playerCache or {}
        CreshChatDB.ui.scale = tonumber(CreshChatDB.panelScale) or CreshChatDB.ui.scale or 1
        CreshChatDB.sounds.master = CreshChatDB.sound ~= false
    end
    if previousVersion < 10 then
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.positions = CreshChatDB.positions or {}
        CreshChatDB.positions.composer = CreshChatDB.positions.composer or deepCopy(defaults.positions.composer)
        CreshChatDB.ui.themePreset = CreshChatDB.ui.themePreset or "MESSENGER"
        CreshChatDB.ui.composerAnimation = CreshChatDB.ui.composerAnimation or "SLIDE"
        CreshChatDB.ui.composerWidth = tonumber(CreshChatDB.ui.composerWidth) or 480
        CreshChatDB.ui.composerScale = tonumber(CreshChatDB.ui.composerScale) or 1
        if CreshChatDB.ui.composerLocked == nil then CreshChatDB.ui.composerLocked = false end
        if CreshChatDB.ui.composerAttached == nil then CreshChatDB.ui.composerAttached = false end
        if CreshChatDB.ui.composerShowPortrait == nil then CreshChatDB.ui.composerShowPortrait = true end
        if CreshChatDB.ui.composerShowSend == nil then CreshChatDB.ui.composerShowSend = true end
        if CreshChatDB.ui.composerCloseAfterSend == nil then CreshChatDB.ui.composerCloseAfterSend = true end
        if CreshChatDB.ui.groupedMessages == nil then CreshChatDB.ui.groupedMessages = true end
        if CreshChatDB.ui.compactNavigation == nil then CreshChatDB.ui.compactNavigation = true end
    end
    if previousVersion < 11 then
        -- QC rebuild: make the redesigned composer and theme visibly different on upgrade.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.colors = CreshChatDB.colors or deepCopy(defaults.colors)
        CreshChatDB.positions = CreshChatDB.positions or {}
        CreshChatDB.ui.scale = 1.05
        CreshChatDB.ui.themePreset = "MESSENGER"
        CreshChatDB.ui.composerAnimation = "SLIDE"
        CreshChatDB.ui.composerWidth = 560
        CreshChatDB.ui.composerScale = 1
        CreshChatDB.ui.composerLocked = false
        CreshChatDB.ui.composerAttached = false
        CreshChatDB.ui.composerShowPortrait = true
        CreshChatDB.ui.composerShowSend = true
        CreshChatDB.ui.groupedMessages = true
        CreshChatDB.ui.qcLayout = true
        CreshChatDB.ui.showBuildBadge = true
        CreshChatDB.positions.composer = deepCopy(defaults.positions.composer)
        for key, value in pairs(defaults.colors) do
            if key ~= "channels" then CreshChatDB.colors[key] = deepCopy(value) end
        end
    end
    if previousVersion < 12 then
        -- v12 minimal dock rebuild: smaller collision-safe windows and a composer that emerges from C.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.colors = CreshChatDB.colors or deepCopy(defaults.colors)
        CreshChatDB.positions = CreshChatDB.positions or {}
        CreshChatDB.sizes = CreshChatDB.sizes or {}
        CreshChatDB.ui.scale = 0.95
        CreshChatDB.ui.iconSize = 26
        CreshChatDB.ui.themePreset = "CRESH_MINIMAL"
        CreshChatDB.ui.composerAnimation = "SLIDE"
        CreshChatDB.ui.composerWidth = 360
        CreshChatDB.ui.composerScale = 1
        CreshChatDB.ui.composerAttached = true
        CreshChatDB.ui.composerShowSend = false
        CreshChatDB.ui.launcherMode = "SINGLE"
        CreshChatDB.ui.showWhisperButton = false
        CreshChatDB.ui.showGeneralButton = false
        CreshChatDB.ui.showCombatButton = false
        CreshChatDB.ui.autoArrange = true
        CreshChatDB.ui.shiftResize = true
        CreshChatDB.ui.minimalLayout = true
        CreshChatDB.ui.showBuildBadge = false
        CreshChatDB.positions.bubble = deepCopy(defaults.positions.bubble)
        CreshChatDB.positions.composer = deepCopy(defaults.positions.composer)
        CreshChatDB.positions.main = deepCopy(defaults.positions.main)
        CreshChatDB.sizes = deepCopy(defaults.sizes)
        for key, value in pairs(defaults.colors) do
            if key ~= "channels" then CreshChatDB.colors[key] = deepCopy(value) end
        end
    end
    if previousVersion < 13 then
        -- v13 motion dock: typing reveals the main chat from the composer and C opens both surfaces.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.composerAnimation = "SLIDE_DOCK"
        CreshChatDB.ui.dockAnimation = "SLIDE_DOCK"
        CreshChatDB.ui.windowAnimation = CreshChatDB.ui.windowAnimation == "SLIDE" and "SLIDE_LEFT" or (CreshChatDB.ui.windowAnimation or "SLIDE_LEFT")
        CreshChatDB.ui.toastAnimation = CreshChatDB.ui.toastAnimation == "SLIDE" and "FAN_UP" or (CreshChatDB.ui.toastAnimation or "FAN_UP")
        CreshChatDB.ui.animationDuration = tonumber(CreshChatDB.ui.animationDuration) or 0.20
        CreshChatDB.ui.openMainOnType = true
        CreshChatDB.ui.launcherOpensComposer = true
    end
    if previousVersion < 14 then
        -- v14 separates Themes and Cards settings and enforces one shared composer.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.positions = CreshChatDB.positions or {}
        CreshChatDB.sizes = CreshChatDB.sizes or {}
        CreshChatDB.ui.singleComposer = true
        CreshChatDB.ui.cardLocation = CreshChatDB.ui.cardLocation or "DOCK"
        CreshChatDB.ui.cardStack = CreshChatDB.ui.cardStack or "UP"
        CreshChatDB.ui.cardWidth = tonumber(CreshChatDB.ui.cardWidth) or 340
        CreshChatDB.ui.cardHeight = tonumber(CreshChatDB.ui.cardHeight) or 86
        CreshChatDB.ui.cardScale = tonumber(CreshChatDB.ui.cardScale) or 1
        CreshChatDB.ui.cardSpacing = tonumber(CreshChatDB.ui.cardSpacing) or 8
        CreshChatDB.ui.cardMaxVisible = tonumber(CreshChatDB.ui.cardMaxVisible) or 4
        if CreshChatDB.ui.cardLocked == nil then CreshChatDB.ui.cardLocked = false end
        CreshChatDB.positions.alerts = CreshChatDB.positions.alerts or deepCopy(defaults.positions.alerts)
        CreshChatDB.sizes.card = CreshChatDB.sizes.card or deepCopy(defaults.sizes.card)
    end
    if previousVersion < 15 then
        -- v15 routes all slash commands through Blizzard's native command processor
        -- and presents party/system notifications through CreshChat cards.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        if CreshChatDB.ui.nativeSlashCommands == nil then CreshChatDB.ui.nativeSlashCommands = true end
        if CreshChatDB.ui.commandHistory == nil then CreshChatDB.ui.commandHistory = true end
        if CreshChatDB.ui.showSystemCards == nil then CreshChatDB.ui.showSystemCards = true end
        if CreshChatDB.ui.replacePartyInvitePopup == nil then CreshChatDB.ui.replacePartyInvitePopup = true end
        CreshChatDB.commandHistory = CreshChatDB.commandHistory or {}
        CreshChatDB.sounds = CreshChatDB.sounds or deepCopy(defaults.sounds)
        if CreshChatDB.sounds.system == nil then CreshChatDB.sounds.system = false end
    end
    if previousVersion < 16 then
        -- v16 compact table pop-outs become optional primary chat surfaces.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.sizes = CreshChatDB.sizes or deepCopy(defaults.sizes)
        local sharedWidth = tonumber(CreshChatDB.ui.sharedDockWidth)
            or (CreshChatDB.sizes.main and tonumber(CreshChatDB.sizes.main.width))
            or tonumber(CreshChatDB.ui.composerWidth)
            or 470
        sharedWidth = math.max(320, math.min(720, sharedWidth))
        CreshChatDB.ui.sharedDockWidth = sharedWidth
        CreshChatDB.ui.composerWidth = sharedWidth
        CreshChatDB.ui.popoutRows = tonumber(CreshChatDB.ui.popoutRows) or 6
        CreshChatDB.ui.popoutRowHeight = tonumber(CreshChatDB.ui.popoutRowHeight) or 30
        if CreshChatDB.ui.popoutShowCommand == nil then CreshChatDB.ui.popoutShowCommand = true end
        if CreshChatDB.ui.popoutPrimary == nil then CreshChatDB.ui.popoutPrimary = true end
        if CreshChatDB.ui.popoutFade == nil then CreshChatDB.ui.popoutFade = false end
        CreshChatDB.ui.popoutFadeDelay = tonumber(CreshChatDB.ui.popoutFadeDelay) or 4
        CreshChatDB.ui.popoutFadeAlpha = tonumber(CreshChatDB.ui.popoutFadeAlpha) or 0.22
        CreshChatDB.sizes.main = CreshChatDB.sizes.main or deepCopy(defaults.sizes.main)
        CreshChatDB.sizes.composer = CreshChatDB.sizes.composer or deepCopy(defaults.sizes.composer)
        CreshChatDB.sizes.popout = CreshChatDB.sizes.popout or deepCopy(defaults.sizes.popout)
        CreshChatDB.sizes.main.width = sharedWidth
        CreshChatDB.sizes.composer.width = sharedWidth
        CreshChatDB.sizes.popout.width = sharedWidth
    end
    if previousVersion < 17 then
        -- v17 makes C and the native command composer one connected dock.
        -- The saved shared width now describes the complete C + composer span.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.sizes = CreshChatDB.sizes or deepCopy(defaults.sizes)
        local sharedWidth = tonumber(CreshChatDB.ui.sharedDockWidth)
            or (CreshChatDB.sizes.main and tonumber(CreshChatDB.sizes.main.width))
            or 470
        sharedWidth = math.max(320, math.min(720, sharedWidth))
        local cWidth = math.max(38, math.min(64, tonumber(CreshChatDB.ui.dockButtonWidth) or 46))
        local previousPopout = CreshChatDB.sizes.popout and tonumber(CreshChatDB.sizes.popout.width)
        local popoutWidth = tonumber(CreshChatDB.ui.popoutWidth) or previousPopout or 400
        if previousPopout and previousPopout >= sharedWidth - 4 then popoutWidth = sharedWidth - 70 end
        popoutWidth = math.max(300, math.min(620, popoutWidth))
        CreshChatDB.ui.sharedDockWidth = sharedWidth
        CreshChatDB.ui.composerWidth = sharedWidth
        CreshChatDB.ui.dockButtonWidth = cWidth
        CreshChatDB.ui.popoutWidth = popoutWidth
        local migratedRowHeight = tonumber(CreshChatDB.ui.popoutRowHeight) or 28
        if migratedRowHeight == 30 then migratedRowHeight = 28 end
        CreshChatDB.ui.popoutRowHeight = math.max(24, math.min(40, migratedRowHeight))
        CreshChatDB.sizes.main = CreshChatDB.sizes.main or deepCopy(defaults.sizes.main)
        CreshChatDB.sizes.composer = CreshChatDB.sizes.composer or deepCopy(defaults.sizes.composer)
        CreshChatDB.sizes.popout = CreshChatDB.sizes.popout or deepCopy(defaults.sizes.popout)
        CreshChatDB.sizes.main.width = sharedWidth
        CreshChatDB.sizes.composer.width = math.max(250, sharedWidth - cWidth)
        CreshChatDB.sizes.composer.height = tonumber(CreshChatDB.sizes.composer.height) or 46
        CreshChatDB.sizes.popout.width = popoutWidth
    end
    if previousVersion < 18 then
        -- v18 makes notification cards smaller, coalesces repeat whispers,
        -- adds screen-grid placement and a compact whisper chip from C.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        local oldLocation = string.upper(tostring(CreshChatDB.ui.cardLocation or "DOCK"))
        if oldLocation == "TOPLEFT" then CreshChatDB.ui.cardLocation, CreshChatDB.ui.cardHorizontal, CreshChatDB.ui.cardVertical = "SCREEN", "LEFT", "TOP"
        elseif oldLocation == "TOPRIGHT" then CreshChatDB.ui.cardLocation, CreshChatDB.ui.cardHorizontal, CreshChatDB.ui.cardVertical = "SCREEN", "RIGHT", "TOP"
        elseif oldLocation == "BOTTOMLEFT" then CreshChatDB.ui.cardLocation, CreshChatDB.ui.cardHorizontal, CreshChatDB.ui.cardVertical = "SCREEN", "LEFT", "BOTTOM"
        elseif oldLocation == "BOTTOMRIGHT" then CreshChatDB.ui.cardLocation, CreshChatDB.ui.cardHorizontal, CreshChatDB.ui.cardVertical = "SCREEN", "RIGHT", "BOTTOM"
        end
        CreshChatDB.ui.cardHorizontal = CreshChatDB.ui.cardHorizontal or "LEFT"
        CreshChatDB.ui.cardVertical = CreshChatDB.ui.cardVertical or "BOTTOM"
        CreshChatDB.ui.guildTheme = true
        if tonumber(CreshChatDB.ui.cardWidth) == nil or tonumber(CreshChatDB.ui.cardWidth) == 340 then CreshChatDB.ui.cardWidth = 300 end
        if tonumber(CreshChatDB.ui.cardHeight) == nil or tonumber(CreshChatDB.ui.cardHeight) == 86 then CreshChatDB.ui.cardHeight = 68 end
        if tonumber(CreshChatDB.ui.cardScale) == nil or tonumber(CreshChatDB.ui.cardScale) == 1 then CreshChatDB.ui.cardScale = 0.95 end
        if tonumber(CreshChatDB.ui.cardSpacing) == nil or tonumber(CreshChatDB.ui.cardSpacing) == 8 then CreshChatDB.ui.cardSpacing = 6 end
        if tonumber(CreshChatDB.ui.cardMaxVisible) == nil or tonumber(CreshChatDB.ui.cardMaxVisible) == 4 then CreshChatDB.ui.cardMaxVisible = 3 end
        if CreshChatDB.ui.cardCompact == nil then CreshChatDB.ui.cardCompact = true end
        if CreshChatDB.ui.cardCoalesce == nil then CreshChatDB.ui.cardCoalesce = true end
        if CreshChatDB.ui.showDockWhisperAlert == nil then CreshChatDB.ui.showDockWhisperAlert = true end
        CreshChatDB.ui.dockWhisperWidth = tonumber(CreshChatDB.ui.dockWhisperWidth) or 190
        CreshChatDB.ui.dockWhisperDuration = tonumber(CreshChatDB.ui.dockWhisperDuration) or 6
        if CreshChatDB.ui.guildTheme == nil then CreshChatDB.ui.guildTheme = true end
        CreshChatDB.sizes = CreshChatDB.sizes or deepCopy(defaults.sizes)
        CreshChatDB.sizes.card = CreshChatDB.sizes.card or deepCopy(defaults.sizes.card)
        CreshChatDB.sizes.card.width = tonumber(CreshChatDB.ui.cardWidth) or 300
        CreshChatDB.sizes.card.height = tonumber(CreshChatDB.ui.cardHeight) or 68
    end
    if previousVersion < 19 then
        -- v19 splits cards into priority and secondary lanes.
        -- Party, guild and whisper cards stay above the UI for ten seconds;
        -- system and presence notices are smaller, silent and last five seconds.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.priorityCardDuration = tonumber(CreshChatDB.ui.priorityCardDuration) or 10
        CreshChatDB.ui.secondaryCardDuration = tonumber(CreshChatDB.ui.secondaryCardDuration) or 5
        CreshChatDB.ui.secondaryCardMaxVisible = tonumber(CreshChatDB.ui.secondaryCardMaxVisible) or 5
        CreshChatDB.ui.secondaryCardWidthRatio = tonumber(CreshChatDB.ui.secondaryCardWidthRatio) or 0.64
        CreshChatDB.ui.secondaryCardHeightRatio = tonumber(CreshChatDB.ui.secondaryCardHeightRatio) or 0.52
        if tonumber(CreshChatDB.ui.cardMaxVisible) == nil or tonumber(CreshChatDB.ui.cardMaxVisible) < 4 then CreshChatDB.ui.cardMaxVisible = 6 end
        CreshChatDB.alertDuration = CreshChatDB.ui.priorityCardDuration
        CreshChatDB.sounds = CreshChatDB.sounds or deepCopy(defaults.sounds)
        CreshChatDB.sounds.system = false
    end
    if previousVersion < 20 then
        -- v20 makes sharedDockWidth a true on-screen width. The main motion window,
        -- C button and native command composer now remain pixel-aligned at every scale.
        -- Guild surfaces use a fixed green palette that is independent of global themes.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.sizes = CreshChatDB.sizes or deepCopy(defaults.sizes)
        local totalWidth = tonumber(CreshChatDB.ui.sharedDockWidth)
            or tonumber(CreshChatDB.ui.composerWidth)
            or 470
        totalWidth = math.max(320, math.min(720, totalWidth))
        CreshChatDB.ui.sharedDockWidth = totalWidth
        CreshChatDB.ui.composerWidth = totalWidth
        CreshChatDB.ui.guildTheme = true
        CreshChatDB.sizes.main = CreshChatDB.sizes.main or deepCopy(defaults.sizes.main)
        CreshChatDB.sizes.composer = CreshChatDB.sizes.composer or deepCopy(defaults.sizes.composer)
        CreshChatDB.sizes.main.width = totalWidth
        local cWidth = math.max(38, math.min(64, tonumber(CreshChatDB.ui.dockButtonWidth) or 46))
        CreshChatDB.sizes.composer.width = math.max(180, totalWidth - cWidth)
    end
    if previousVersion < 21 then
        -- v21 fixes two-lane card geometry. Screen-grid cards sit flush against the
        -- selected edge, top/bottom anchors stack inward, and secondary notices attach
        -- directly to priority cards (or become the edge card when no priority exists).
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.cardHorizontal = CreshChatDB.ui.cardHorizontal or "LEFT"
        CreshChatDB.ui.cardVertical = CreshChatDB.ui.cardVertical or "BOTTOM"
        CreshChatDB.ui.guildTheme = true
    end
    if previousVersion < 22 then
        -- v22 adds visible-nameplate speech bubbles, faction-aware Guild themes and a
        -- compact responsive settings dashboard. Existing history and positions remain intact.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.colors = CreshChatDB.colors or deepCopy(defaults.colors)
        CreshChatDB.sizes = CreshChatDB.sizes or deepCopy(defaults.sizes)
        if CreshChatDB.ui.guildThemePreset == nil then CreshChatDB.ui.guildThemePreset = "AUTO" end
        if CreshChatDB.ui.overheadBubbles == nil then CreshChatDB.ui.overheadBubbles = true end
        if CreshChatDB.ui.overheadBubbleMode == nil then CreshChatDB.ui.overheadBubbleMode = "VISIBLE" end
        CreshChatDB.ui.overheadBubbleDuration = tonumber(CreshChatDB.ui.overheadBubbleDuration) or 5
        CreshChatDB.ui.overheadBubbleWidth = tonumber(CreshChatDB.ui.overheadBubbleWidth) or 180
        CreshChatDB.ui.overheadBubbleScale = tonumber(CreshChatDB.ui.overheadBubbleScale) or 0.90
        if CreshChatDB.ui.overheadBubbleGuildGreen == nil then CreshChatDB.ui.overheadBubbleGuildGreen = true end
        CreshChatDB.colors.guild = CreshChatDB.colors.guild or deepCopy(defaults.colors.guild)
        CreshChatDB.sizes.settings = { width = 740, height = 600 }
    end
    if previousVersion < 23 then
        -- v23 adds true Normal/Compact pop-out renderers, wrapped compact rows,
        -- restores independent C-dock toggling while pop-outs are open, and enables
        -- outgoing/self overhead bubbles with a personal-nameplate fallback.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.popoutStyle = string.upper(tostring(CreshChatDB.ui.popoutStyle or "NORMAL"))
        if CreshChatDB.ui.popoutStyle ~= "COMPACT" then CreshChatDB.ui.popoutStyle = "NORMAL" end
        local oldRowHeight = tonumber(CreshChatDB.ui.popoutRowHeight) or 28
        if oldRowHeight < 36 then oldRowHeight = 44 end
        CreshChatDB.ui.popoutRowHeight = math.max(36, math.min(68, oldRowHeight))
        CreshChatDB.ui.popoutRows = math.max(4, math.min(8, tonumber(CreshChatDB.ui.popoutRows) or 6))
        if CreshChatDB.ui.overheadBubbleSelf == nil then CreshChatDB.ui.overheadBubbleSelf = true end
    end
    if previousVersion < 24 then
        -- v24 adds targeted/coalesced UI refreshes, bounded cache validation,
        -- quick quality profiles and runtime diagnostics without deleting history.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.qualityProfile = CreshChatDB.ui.qualityProfile or "BALANCED"
        CreshChatDB.playerCache = CreshChatDB.playerCache or {}
        CreshChatDB.commandHistory = CreshChatDB.commandHistory or {}
    end
    if previousVersion < 25 then
        -- v25 makes detached windows truly independent, replaces fixed always-on-top
        -- layering with click-to-front stacking, removes overhead bubbles, and splits
        -- party invite/message sounds. Existing window positions and chat history remain.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.sounds = CreshChatDB.sounds or deepCopy(defaults.sounds)
        CreshChatDB.ui.autoArrange = false
        CreshChatDB.ui.popoutPrimary = false
        CreshChatDB.ui.overheadBubbles = false
        if CreshChatDB.sounds.partyInvite == nil then
            CreshChatDB.sounds.partyInvite = CreshChatDB.sounds.party ~= false
        end
        if CreshChatDB.sounds.partyMessage == nil then CreshChatDB.sounds.partyMessage = true end
    end
    if previousVersion < 26 then
        -- v26 replaces cycle buttons with explicit dropdowns and adds selectable
        -- sound presets while preserving the previous on/off sound choices.
        CreshChatDB.soundChoices = CreshChatDB.soundChoices or deepCopy(defaults.soundChoices)
        CreshChatDB.soundChoices.whisper = CreshChatDB.sounds.whisper == false and "OFF" or (CreshChatDB.soundChoices.whisper or "DING")
        CreshChatDB.soundChoices.guild = CreshChatDB.sounds.guild == false and "OFF" or (CreshChatDB.soundChoices.guild or "SOFT")
        local inviteEnabled = CreshChatDB.sounds.partyInvite
        if inviteEnabled == nil then inviteEnabled = CreshChatDB.sounds.party ~= false end
        CreshChatDB.soundChoices.partyInvite = inviteEnabled == false and "OFF" or (CreshChatDB.soundChoices.partyInvite or "READY")
        CreshChatDB.soundChoices.partyMessage = CreshChatDB.sounds.partyMessage == false and "OFF" or (CreshChatDB.soundChoices.partyMessage or "SOFT")
        CreshChatDB.soundChoices.quest = CreshChatDB.sounds.quest == false and "OFF" or (CreshChatDB.soundChoices.quest or "SCROLL")
        CreshChatDB.soundChoices.system = CreshChatDB.sounds.system == true and (CreshChatDB.soundChoices.system or "SOFT") or "OFF"
    end
    if previousVersion < 27 then
        -- v27 expands the global and Guild theme libraries. Themes are colour-only
        -- saved settings, so existing custom colours, positions and history remain intact.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.colors = CreshChatDB.colors or deepCopy(defaults.colors)
        CreshChatDB.colors.guild = CreshChatDB.colors.guild or deepCopy(defaults.colors.guild)
        CreshChatDB.ui.themePreset = CreshChatDB.ui.themePreset or "CRESH_MINIMAL"
        CreshChatDB.ui.guildThemePreset = CreshChatDB.ui.guildThemePreset or "AUTO"
    end
    if previousVersion < 28 then
        -- v28 adds the ZLR chess-inspired global theme. No existing colours,
        -- chat history, positions, sounds or Guild-theme choices are overwritten.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.themePreset = CreshChatDB.ui.themePreset or "CRESH_MINIMAL"
    end
    if previousVersion < 29 then
        -- v29 refines ZLR into a stronger monochrome chess presentation and
        -- adds a custom king-piece icon treatment when ZLR is selected.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.themePreset = CreshChatDB.ui.themePreset or "CRESH_MINIMAL"
    end
    if previousVersion < 30 then
        -- v30 reworks ZLR as an original arena-tech theme inspired by late-1990s
        -- industrial FPS interfaces. Saved history, positions and user choices remain intact.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.themePreset = CreshChatDB.ui.themePreset or "CRESH_MINIMAL"
    end
    if previousVersion < 31 then
        -- v31 adds persistent quest-giver conversations and a dedicated Quests inbox.
        CreshChatDB.history = CreshChatDB.history or {}
        CreshChatDB.history.quests = CreshChatDB.history.quests or {}
        CreshChatDB.questConversations = CreshChatDB.questConversations or {}
    end
    if previousVersion < 32 then
        -- v32 adds a Friends directory and keeps quest-giver metadata when a quest chat is hidden.
        -- Rebuild metadata for quest chats that were closed by v0.3.10, which kept the
        -- dialogue history but removed the directory entry.
        CreshChatDB.history = CreshChatDB.history or {}
        CreshChatDB.history.quests = CreshChatDB.history.quests or {}
        CreshChatDB.questConversations = CreshChatDB.questConversations or {}
        for key, messages in pairs(CreshChatDB.history.quests) do
            if not CreshChatDB.questConversations[key] and type(messages) == "table" and #messages > 0 then
                local last = messages[#messages] or {}
                CreshChatDB.questConversations[key] = {
                    npcName = last.npcName or last.sender or "Quest Giver",
                    zone = last.zone or "Unknown Zone",
                    updated = tonumber(last.timestamp) or 0,
                    hidden = true,
                }
            end
        end
    end
    if previousVersion < 33 then
        -- v33 adds per-category sound selection for quest dialogue and an animated
        -- theme-aware notification indicator on the floating C launcher.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        if CreshChatDB.ui.launcherNotificationPulse == nil then CreshChatDB.ui.launcherNotificationPulse = true end
        CreshChatDB.sounds = CreshChatDB.sounds or deepCopy(defaults.sounds)
        if CreshChatDB.sounds.quest == nil then CreshChatDB.sounds.quest = true end
        CreshChatDB.soundChoices = CreshChatDB.soundChoices or deepCopy(defaults.soundChoices)
        CreshChatDB.soundChoices.quest = CreshChatDB.sounds.quest == false and "OFF" or (CreshChatDB.soundChoices.quest or "SCROLL")
    end
    if previousVersion < 34 then
        -- v34 replaces fragile numeric sound fallbacks with runtime-verified native
        -- SoundKit choices and adds optional idle fading and combat hiding for C.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        if CreshChatDB.ui.launcherIdleFade == nil then CreshChatDB.ui.launcherIdleFade = false end
        CreshChatDB.ui.launcherIdleDelay = tonumber(CreshChatDB.ui.launcherIdleDelay) or 5
        CreshChatDB.ui.launcherIdleAlpha = tonumber(CreshChatDB.ui.launcherIdleAlpha) or 0.18
        if CreshChatDB.ui.launcherHideInCombat == nil then CreshChatDB.ui.launcherHideInCombat = false end
        CreshChatDB.soundChoices = CreshChatDB.soundChoices or deepCopy(defaults.soundChoices)
    end
    if previousVersion < 35 then
        -- v35 adds private addon-to-addon multiplayer game challenges. No active
        -- match state is saved, so chat history and all existing settings remain intact.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
    end
    if previousVersion < 36 then
        -- v36 adds single-player Frogger, Texas Hold'em and Blackjack. Only compact
        -- progress/statistics are saved; active hands and arcade sessions are not persisted.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
    end
    if previousVersion < 37 then
        -- v37 adds persistent solo poker/Blackjack bankrolls plus live hand and odds displays.
        -- Earlier releases only saved the highest stack, so use that as the safest starting bank.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.holdem = CreshChatDB.soloGames.holdem or deepCopy(defaults.soloGames.holdem)
        CreshChatDB.soloGames.blackjack = CreshChatDB.soloGames.blackjack or deepCopy(defaults.soloGames.blackjack)
        CreshChatDB.soloGames.holdem.bankroll = math.max(0, tonumber(CreshChatDB.soloGames.holdem.bestChips) or 100)
        CreshChatDB.soloGames.blackjack.bankroll = math.max(0, tonumber(CreshChatDB.soloGames.blackjack.bestBank) or 100)
    end
    if previousVersion < 38 then
        -- v38 adds Dungeon Dweller statistics and moves game discovery into a
        -- full-height slide-out drawer. Active runs and matches are intentionally
        -- not persisted, so a death or reload always starts a fresh dungeon run.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.dungeon = CreshChatDB.soloGames.dungeon or deepCopy(defaults.soloGames.dungeon)
    end
    if previousVersion < 39 then
        -- v39 adds Solo Chess records and the last selected computer level.
        -- Active boards and engine searches are intentionally not persisted.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.chess = CreshChatDB.soloGames.chess or deepCopy(defaults.soloGames.chess)
    end
    if previousVersion < 40 then
        -- v40 makes Frogger and Dungeon Dweller endless, adds dungeon minion
        -- recruitment statistics and preserves all prior solo-game records.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.frogger = CreshChatDB.soloGames.frogger or deepCopy(defaults.soloGames.frogger)
        CreshChatDB.soloGames.dungeon = CreshChatDB.soloGames.dungeon or deepCopy(defaults.soloGames.dungeon)
        CreshChatDB.soloGames.dungeon.minions = math.max(0, tonumber(CreshChatDB.soloGames.dungeon.minions) or 0)
    end
    if previousVersion < 41 then
        -- v41 adds Higher or Lower, peer-synchronised solo leaderboards, compact
        -- solo/multiplayer result history and five additional interface themes.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.higherlower = CreshChatDB.soloGames.higherlower or deepCopy(defaults.soloGames.higherlower)
        CreshChatDB.gameHistory = CreshChatDB.gameHistory or {}
        CreshChatDB.gameLeaderboards = CreshChatDB.gameLeaderboards or {}
        CreshChatDB.multiplayerStats = CreshChatDB.multiplayerStats or {}
    end
    if previousVersion < 42 then
        -- v42 adds independent visual-notification switches and configurable
        -- console tabs, including filtered Trade, Party, Raid and local feeds.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.consoleTabs = CreshChatDB.ui.consoleTabs or deepCopy(defaults.ui.consoleTabs)
        CreshChatDB.notifications = CreshChatDB.notifications or deepCopy(defaults.notifications)
    end
    if previousVersion < 43 then
        -- v43 adds Arcade Coins, a 50-level Battle Pass and five premium themes.
        -- The theme active during migration is grandfathered so no existing setup breaks.
        CreshChatDB.arcadeRewards = CreshChatDB.arcadeRewards or deepCopy(defaults.arcadeRewards)
        CreshChatDB.arcadeRewards.claimed = CreshChatDB.arcadeRewards.claimed or {}
        CreshChatDB.arcadeRewards.unlockedThemes = CreshChatDB.arcadeRewards.unlockedThemes or {}
        local activeTheme = CreshChatDB.ui and string.upper(tostring(CreshChatDB.ui.themePreset or "")) or ""
        if activeTheme == "UBUNTU" or activeTheme == "WINDOWS_95" or activeTheme == "MSN_MESSENGER" or activeTheme == "WOW_CLASSIC" or activeTheme == "ZLR" then
            CreshChatDB.arcadeRewards.unlockedThemes[activeTheme] = true
        end
    end
    if previousVersion < 44 then
        -- v44 refines settings scaling, replaces template sliders with compact boxed
        -- bars, keeps the full Settings window above CreshChat panels and adds
        -- navigable Battle Pass requirement cards. No history or progression is reset.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.scale = math.max(0.70, math.min(1.50, tonumber(CreshChatDB.ui.scale) or 0.95))
        CreshChatDB.arcadeRewards = CreshChatDB.arcadeRewards or deepCopy(defaults.arcadeRewards)
    end
    if previousVersion < 45 then
        -- v45 expands the named theme library to 100, extends the Battle Pass to
        -- 100 levels and replaces red unread counters with theme-aware pulse outlines.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.arcadeRewards = CreshChatDB.arcadeRewards or deepCopy(defaults.arcadeRewards)
        CreshChatDB.arcadeRewards.claimed = CreshChatDB.arcadeRewards.claimed or {}
        CreshChatDB.arcadeRewards.unlockedThemes = CreshChatDB.arcadeRewards.unlockedThemes or {}
    end
    if previousVersion < 46 then
        -- v46 adds per-character Daily/Weekly activities, Cresh Coin activity rewards,
        -- persistent exact-coordinate waypoints, a navigation arrow and map marker.
        CreshChatDB.activities = CreshChatDB.activities or deepCopy(defaults.activities)
        CreshChatDB.navigation = CreshChatDB.navigation or deepCopy(defaults.navigation)
        CreshChatDB.arcadeRewards = CreshChatDB.arcadeRewards or deepCopy(defaults.arcadeRewards)
        CreshChatDB.arcadeRewards.activityCoins = math.max(0, tonumber(CreshChatDB.arcadeRewards.activityCoins) or 0)
    end
    if previousVersion < 47 then
        -- v47 adds solo Tetris, per-game arcade levels and exploration rewards.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        CreshChatDB.gameProgression = CreshChatDB.gameProgression or deepCopy(defaults.gameProgression)
        CreshChatDB.arcadeRewards = CreshChatDB.arcadeRewards or deepCopy(defaults.arcadeRewards)
        CreshChatDB.arcadeRewards.explorationCoins = math.max(0, tonumber(CreshChatDB.arcadeRewards.explorationCoins) or 0)
    end
    if previousVersion < 48 then
        -- v48 removes Daily/Weekly navigation modules, adds per-channel sound volume,
        -- game audio, Battle Pass milestone goals, console economy display and voice calls.
        CreshChatDB.soundVolumes = CreshChatDB.soundVolumes or deepCopy(defaults.soundVolumes)
        CreshChatDB.gameAudio = CreshChatDB.gameAudio or deepCopy(defaults.gameAudio)
        CreshChatDB.voice = CreshChatDB.voice or deepCopy(defaults.voice)
        CreshChatDB.arcadeRewards = CreshChatDB.arcadeRewards or deepCopy(defaults.arcadeRewards)
        CreshChatDB.arcadeRewards.milestoneGoals = CreshChatDB.arcadeRewards.milestoneGoals or {}
        CreshChatDB.gameProgression = CreshChatDB.gameProgression or deepCopy(defaults.gameProgression)
        CreshChatDB.gameProgression.exploration = CreshChatDB.gameProgression.exploration or deepCopy(defaults.gameProgression.exploration)
        CreshChatDB.gameProgression.exploration.totalKills = math.max(0, tonumber(CreshChatDB.gameProgression.exploration.totalKills) or 0)
        -- Daily/Weekly activities and waypoint navigation were retired in v48.
        CreshChatDB.activities = nil
        CreshChatDB.navigation = nil
    end
    if previousVersion < 49 then
        -- v49 introduces per-character progression and interface profiles. The
        -- first character to load inherits the existing v48 data; new alts begin
        -- with fresh progression and may copy UI/layout from any known character.
        CreshChatDB.characterProfiles = CreshChatDB.characterProfiles or {}
    end
    if previousVersion < 50 then
        -- v50 adds the Tetris theme collection, 100-level mini pass, CPU race
        -- records and endless-mode statistics. Existing Tetris scores remain.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        local tetris = CreshChatDB.soloGames.tetris
        tetris.totalLines = math.max(tonumber(tetris.bestLines) or 0, tonumber(tetris.totalLines) or 0)
        tetris.vsWins = math.max(0, tonumber(tetris.vsWins) or 0)
        tetris.vsLosses = math.max(0, tonumber(tetris.vsLosses) or 0)
        tetris.endlessRuns = math.max(0, tonumber(tetris.endlessRuns) or 0)
        tetris.cpuLevel = math.max(1, math.min(5, tonumber(tetris.cpuLevel) or 3))
        tetris.mode = tostring(tetris.mode or "CLASSIC")
        tetris.passXP = math.max(0, tonumber(tetris.passXP) or 0)
        tetris.passClaimed = type(tetris.passClaimed) == "table" and tetris.passClaimed or {}
        tetris.unlockedThemes = type(tetris.unlockedThemes) == "table" and tetris.unlockedThemes or {}
        tetris.themeUnlockSources = type(tetris.themeUnlockSources) == "table" and tetris.themeUnlockSources or {}
        tetris.unlockedThemes.CLASSIC_BLOCKS = true
        tetris.themeUnlockSources.CLASSIC_BLOCKS = tetris.themeUnlockSources.CLASSIC_BLOCKS or "DEFAULT"
        tetris.selectedTheme = tostring(tetris.selectedTheme or "CLASSIC_BLOCKS")
    end
    if previousVersion < 51 then
        -- v51 adds visual theme previews, quick theme selection, live versus boards
        -- and Endless Attack formats for CPU and multiplayer Tetris.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        local tetris = CreshChatDB.soloGames.tetris
        tetris.cpuVersusMode = string.upper(tostring(tetris.cpuVersusMode or "RACE"))
        if tetris.cpuVersusMode ~= "ENDLESS" then tetris.cpuVersusMode = "RACE" end
        tetris.multiplayerMode = string.upper(tostring(tetris.multiplayerMode or "RACE"))
        if tetris.multiplayerMode ~= "ENDLESS" and tetris.multiplayerMode ~= "ATTACK" then tetris.multiplayerMode = "RACE" end
        tetris.multiplayerDuration = math.floor(math.max(5, math.min(60, tonumber(tetris.multiplayerDuration) or 10)))
        local allowedDuration = { [5]=true, [10]=true, [15]=true, [30]=true, [45]=true, [60]=true }
        if not allowedDuration[tetris.multiplayerDuration] then tetris.multiplayerDuration = 10 end
    end
    if previousVersion < 53 then
        -- v53 replaces the old five-room random boss loop with fixed ten-level
        -- milestone guardians, unique boss mechanics, boss crates, class-armour
        -- drops, first-kill rewards and account-safe pity counters.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.dungeon = CreshChatDB.soloGames.dungeon or deepCopy(defaults.soloGames.dungeon)
        local dungeon = CreshChatDB.soloGames.dungeon
        dungeon.bossKillsByType = type(dungeon.bossKillsByType) == "table" and dungeon.bossKillsByType or {}
        dungeon.firstBossKills = type(dungeon.firstBossKills) == "table" and dungeon.firstBossKills or {}
        dungeon.unlockedArmour = type(dungeon.unlockedArmour) == "table" and dungeon.unlockedArmour or {}
        dungeon.equippedArmour = type(dungeon.equippedArmour) == "table" and dungeon.equippedArmour or {}
        dungeon.crateInventory = type(dungeon.crateInventory) == "table" and dungeon.crateInventory or {}
        dungeon.crateHistory = type(dungeon.crateHistory) == "table" and dungeon.crateHistory or {}
        dungeon.permanentDamage = math.max(0, tonumber(dungeon.permanentDamage) or 0)
        dungeon.armourPity = math.max(0, tonumber(dungeon.armourPity) or 0)
        dungeon.voidCratePity = math.max(0, tonumber(dungeon.voidCratePity) or 0)
        dungeon.armourShards = math.max(0, tonumber(dungeon.armourShards) or 0)
        dungeon.portraitTokens = math.max(0, tonumber(dungeon.portraitTokens) or 0)
        dungeon.fullBodyTokens = math.max(0, tonumber(dungeon.fullBodyTokens) or 0)
    end
    if previousVersion < 54 then
        -- v54 activates gameplay statistics for equipped Dungeon armour and
        -- preserves each class's selected loadout. No ownership data is reset.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.dungeon = CreshChatDB.soloGames.dungeon or deepCopy(defaults.soloGames.dungeon)
        local dungeon = CreshChatDB.soloGames.dungeon
        dungeon.unlockedArmour = type(dungeon.unlockedArmour) == "table" and dungeon.unlockedArmour or {}
        dungeon.equippedArmour = type(dungeon.equippedArmour) == "table" and dungeon.equippedArmour or {}
    end
    if previousVersion < 55 then
        -- v55 adds persistent unopened Dungeon chest drops. A queued chest is
        -- restored after reload so first-kill and milestone rewards cannot be lost.
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.dungeon = CreshChatDB.soloGames.dungeon or deepCopy(defaults.soloGames.dungeon)
        local dungeon = CreshChatDB.soloGames.dungeon
        dungeon.pendingCrates = type(dungeon.pendingCrates) == "table" and dungeon.pendingCrates or {}
    end
    if previousVersion < 56 then
        -- v56 separates multiplayer Tetris into Race 10, timed Endless and
        -- Endless Attack, adds selectable 5–60 minute timers and expands the
        -- Tetris collection with textured background themes. In schema 55 the
        -- value ENDLESS meant the attack format, so it migrates to ATTACK.
        local allowedDuration = { [5]=true, [10]=true, [15]=true, [30]=true, [45]=true, [60]=true }
        local function migrateTetrisVersus(tetris)
            if type(tetris) ~= "table" then return end
            tetris.multiplayerMode = string.upper(tostring(tetris.multiplayerMode or "RACE"))
            if tetris.multiplayerMode == "ENDLESS" then tetris.multiplayerMode = "ATTACK" end
            if tetris.multiplayerMode ~= "ATTACK" then tetris.multiplayerMode = "RACE" end
            tetris.multiplayerDuration = math.floor(tonumber(tetris.multiplayerDuration) or 10)
            if not allowedDuration[tetris.multiplayerDuration] then tetris.multiplayerDuration = 10 end
        end
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        migrateTetrisVersus(CreshChatDB.soloGames.tetris)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            local profileVersion = tonumber(profile.version) or previousVersion
            if profileVersion < 56 and profile.progression and profile.progression.soloGames then
                migrateTetrisVersus(profile.progression.soloGames.tetris)
                profile.version = 56
            end
        end
    end
    if previousVersion < 57 then
        -- v57 retires Race 10, normalises both local and network Tetris to
        -- Timed Endless / Endless Attack, and adds solo background-reveal
        -- progression. Existing scores, themes and pass rewards are preserved.
        local allowedDuration = { [5]=true, [10]=true, [15]=true, [30]=true, [45]=true, [60]=true }
        local function migrateTetrisReveal(tetris)
            if type(tetris) ~= "table" then return end
            tetris.cpuVersusMode = string.upper(tostring(tetris.cpuVersusMode or "ENDLESS"))
            if tetris.cpuVersusMode ~= "ATTACK" then tetris.cpuVersusMode = "ENDLESS" end
            tetris.multiplayerMode = string.upper(tostring(tetris.multiplayerMode or "ENDLESS"))
            if tetris.multiplayerMode ~= "ATTACK" then tetris.multiplayerMode = "ENDLESS" end
            tetris.mode = string.upper(tostring(tetris.mode or "ENDLESS"))
            if tetris.mode ~= "CPU" then tetris.mode = "ENDLESS" end
            tetris.multiplayerDuration = math.floor(tonumber(tetris.multiplayerDuration) or 10)
            if not allowedDuration[tetris.multiplayerDuration] then tetris.multiplayerDuration = 10 end
            tetris.soloDuration = math.floor(tonumber(tetris.soloDuration) or 10)
            if not allowedDuration[tetris.soloDuration] then tetris.soloDuration = 10 end
            tetris.revealLines = math.floor(math.max(0, tonumber(tetris.revealLines) or 0))
            tetris.revealCompleted = math.floor(math.max(0, tonumber(tetris.revealCompleted) or 0))
            tetris.revealThemeKey = string.upper(tostring(tetris.revealThemeKey or ""))
        end
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        migrateTetrisReveal(CreshChatDB.soloGames.tetris)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            local profileVersion = tonumber(profile.version) or previousVersion
            if profileVersion < 57 and profile.progression and profile.progression.soloGames then
                migrateTetrisReveal(profile.progression.soloGames.tetris)
                profile.version = 57
            end
        end
    end
    if previousVersion < 58 then
        -- v58 replaces the separate priority/secondary card lanes with one
        -- notification hub: a full-size main slot plus directional slide-outs.
        local function migrateNotificationHub(ui)
            if type(ui) ~= "table" then return end
            ui.notificationSlideDirection = string.upper(tostring(ui.notificationSlideDirection or "BOTTOM"))
            if ui.notificationSlideDirection ~= "TOP" and ui.notificationSlideDirection ~= "BOTTOM" and ui.notificationSlideDirection ~= "LEFT" and ui.notificationSlideDirection ~= "RIGHT" then
                ui.notificationSlideDirection = "BOTTOM"
            end
            ui.notificationScale = tonumber(ui.cardScale) or tonumber(ui.notificationScale) or 0.95
            ui.notificationLineHeight = math.max(2, math.min(6, math.floor(tonumber(ui.notificationLineHeight) or 3)))
            if tonumber(ui.secondaryCardWidthRatio) == nil or tonumber(ui.secondaryCardWidthRatio) <= 0.70 then ui.secondaryCardWidthRatio = 0.88 end
            if tonumber(ui.secondaryCardHeightRatio) == nil or tonumber(ui.secondaryCardHeightRatio) <= 0.60 then ui.secondaryCardHeightRatio = 0.80 end
            ui.secondaryCardDuration = tonumber(ui.secondaryCardDuration) or 6
            ui.secondaryCardMaxVisible = tonumber(ui.secondaryCardMaxVisible) or 4
            ui.cardMaxVisible = math.max(1, tonumber(ui.cardMaxVisible) or 6)
        end
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        migrateNotificationHub(CreshChatDB.ui)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = profile.uiData or {}
            profile.uiData.ui = profile.uiData.ui or deepCopy(defaults.ui)
            migrateNotificationHub(profile.uiData.ui)
            profile.version = 58
        end
    end
    if previousVersion < 59 then
        -- v59 moves direct-message history into one account-wide store and adds
        -- Battle.net identity/route metadata. Existing character whisper logs are
        -- merged without changing local Guild, General, Combat or Quest feeds.
        local shared = self:EnsureAccountWhisperStorage()
        local function mergeWhispers(history, conversations, routes)
            local whispers = type(history) == "table" and history.whispers or nil
            if type(whispers) == "table" then
                for target, messages in pairs(whispers) do
                    shared.whispers[target] = shared.whispers[target] or {}
                    if messages ~= shared.whispers[target] then
                        for _, message in ipairs(messages or {}) do table.insert(shared.whispers[target], message) end
                    end
                end
            end
            for target, updated in pairs(type(conversations) == "table" and conversations or {}) do
                shared.conversations[target] = math.max(tonumber(shared.conversations[target]) or 0, tonumber(updated) or 0)
            end
            for target, route in pairs(type(routes) == "table" and routes or {}) do
                if not shared.whisperRoutes[target] then shared.whisperRoutes[target] = route end
            end
        end
        mergeWhispers(CreshChatDB.history, CreshChatDB.conversations, CreshChatDB.whisperRoutes)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.chat = profile.chat or {}
            mergeWhispers(profile.chat.history, profile.chat.conversations, profile.chat.whisperRoutes)
            profile.chat.conversations = nil
            profile.chat.whisperRoutes = nil
            profile.version = 59
        end
        for target, messages in pairs(shared.whispers) do
            table.sort(messages, function(a, b) return (tonumber(a.timestamp) or 0) < (tonumber(b.timestamp) or 0) end)
            local deduped, seen = {}, {}
            for _, message in ipairs(messages) do
                local signature = tostring(message.timestamp or 0) .. "|" .. tostring(message.incoming) .. "|" .. tostring(message.sender) .. "|" .. tostring(message.text)
                if not seen[signature] then seen[signature] = true; table.insert(deduped, message) end
            end
            shared.whispers[target] = deduped
            while #shared.whispers[target] > (tonumber(CreshChatDB.historyLimit) or 120) do table.remove(shared.whispers[target], 1) end
        end
    end
    if previousVersion < 60 then
        -- v60 expands Tetris to a 1,000-level gravity curve and makes the
        -- ten-stage background reveal shared by solo, CPU and multiplayer play.
        local function migrateTetrisV60(tetris)
            if type(tetris) ~= "table" then return end
            tetris.revealLines = math.floor(math.max(0, math.min(99, tonumber(tetris.revealLines) or 0)))
            tetris.revealCompleted = math.floor(math.max(0, tonumber(tetris.revealCompleted) or 0))
            tetris.revealThemeKey = string.upper(tostring(tetris.revealThemeKey or ""))
            tetris.unlockedThemes = type(tetris.unlockedThemes) == "table" and tetris.unlockedThemes or { CLASSIC_BLOCKS = true }
            tetris.themeUnlockSources = type(tetris.themeUnlockSources) == "table" and tetris.themeUnlockSources or { CLASSIC_BLOCKS = "DEFAULT" }
        end
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        migrateTetrisV60(CreshChatDB.soloGames.tetris)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            if profile.progression and profile.progression.soloGames then migrateTetrisV60(profile.progression.soloGames.tetris) end
            profile.version = 60
        end
    end
    if previousVersion < 62 then
        -- v62 repairs the ten-part Tetris background renderer and adds the
        -- background gallery/progress UI without resetting account progression.
        local function migrateTetrisV62(tetris)
            if type(tetris) ~= "table" then return end
            tetris.revealLines = math.floor(math.max(0, math.min(100, tonumber(tetris.revealLines) or 0)))
            tetris.revealCompleted = math.floor(math.max(0, tonumber(tetris.revealCompleted) or 0))
            tetris.revealThemeKey = string.upper(tostring(tetris.revealThemeKey or ""))
            tetris.unlockedThemes = type(tetris.unlockedThemes) == "table" and tetris.unlockedThemes or { CLASSIC_BLOCKS = true }
            tetris.unlockedThemes.CLASSIC_BLOCKS = true
            tetris.themeUnlockSources = type(tetris.themeUnlockSources) == "table" and tetris.themeUnlockSources or { CLASSIC_BLOCKS = "DEFAULT" }
            tetris.themeUnlockSources.CLASSIC_BLOCKS = tetris.themeUnlockSources.CLASSIC_BLOCKS or "DEFAULT"
        end
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        migrateTetrisV62(CreshChatDB.soloGames.tetris)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            if profile.progression and profile.progression.soloGames then migrateTetrisV62(profile.progression.soloGames.tetris) end
            profile.version = 62
        end
    end
    if previousVersion < 63 then
        -- v63 adds an account-wide character-friend directory and Battle.net
        -- character-link metadata. Existing direct-message histories remain intact.
        local shared = self:EnsureAccountWhisperStorage()
        shared.accountFriends = type(shared.accountFriends) == "table" and shared.accountFriends or {}
        shared.removedAccountFriends = type(shared.removedAccountFriends) == "table" and shared.removedAccountFriends or {}
        shared.characterBattleNetLinks = type(shared.characterBattleNetLinks) == "table" and shared.characterBattleNetLinks or {}
        shared.battleNetCharacters = type(shared.battleNetCharacters) == "table" and shared.battleNetCharacters or {}
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do profile.version = 63 end
    end
    if previousVersion < 64 then
        -- v64 separates tetromino colour themes from reveal-image backgrounds.
        -- Zone image ownership, selected images and partial reveal progress are
        -- preserved while retired block-texture backgrounds fall back safely.
        local function migrateTetrisV64(tetris)
            if type(tetris) ~= "table" then return end
            tetris.unlockedThemes = type(tetris.unlockedThemes) == "table" and tetris.unlockedThemes or { CLASSIC_BLOCKS = true }
            tetris.themeUnlockSources = type(tetris.themeUnlockSources) == "table" and tetris.themeUnlockSources or { CLASSIC_BLOCKS = "DEFAULT" }
            tetris.unlockedBackgrounds = type(tetris.unlockedBackgrounds) == "table" and tetris.unlockedBackgrounds or {}
            tetris.backgroundUnlockSources = type(tetris.backgroundUnlockSources) == "table" and tetris.backgroundUnlockSources or {}
            for key, unlocked in pairs(tetris.unlockedThemes) do
                if unlocked and string.sub(string.upper(tostring(key)), 1, 5) == "ZONE_" then
                    tetris.unlockedBackgrounds[string.upper(tostring(key))] = true
                    tetris.backgroundUnlockSources[string.upper(tostring(key))] = tetris.backgroundUnlockSources[string.upper(tostring(key))] or tetris.themeUnlockSources[key] or "MIGRATED"
                end
            end
            tetris.selectedTheme = string.upper(tostring(tetris.selectedTheme or "CLASSIC_BLOCKS"))
            tetris.selectedBackground = string.upper(tostring(tetris.selectedBackground or ""))
            if string.sub(tetris.selectedTheme, 1, 5) == "ZONE_" then
                if tetris.selectedBackground == "" then tetris.selectedBackground = tetris.selectedTheme end
                tetris.selectedTheme = "CLASSIC_BLOCKS"
            end
            tetris.revealBackgroundKey = string.upper(tostring(tetris.revealBackgroundKey or tetris.revealThemeKey or ""))
            tetris.revealThemeKey = tetris.revealBackgroundKey
            tetris.revealLines = math.floor(math.max(0, math.min(99, tonumber(tetris.revealLines) or 0)))
            tetris.unlockedThemes.CLASSIC_BLOCKS = true
            tetris.themeUnlockSources.CLASSIC_BLOCKS = tetris.themeUnlockSources.CLASSIC_BLOCKS or "DEFAULT"
        end
        CreshChatDB.soloGames = CreshChatDB.soloGames or deepCopy(defaults.soloGames)
        CreshChatDB.soloGames.tetris = CreshChatDB.soloGames.tetris or deepCopy(defaults.soloGames.tetris)
        migrateTetrisV64(CreshChatDB.soloGames.tetris)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            if profile.progression and profile.progression.soloGames then migrateTetrisV64(profile.progression.soloGames.tetris) end
            profile.version = 64
        end
    end
    if previousVersion < 65 then
        -- v65 repairs the chat foundation. Social directories are explicitly
        -- account-wide, cached Battle.net entries survive character switches,
        -- and all chat history tables are normalised without clearing whispers.
        local shared = self:EnsureAccountWhisperStorage()
        shared.accountFriends = type(shared.accountFriends) == "table" and shared.accountFriends or {}
        shared.removedAccountFriends = type(shared.removedAccountFriends) == "table" and shared.removedAccountFriends or {}
        shared.battleNetFriends = type(shared.battleNetFriends) == "table" and shared.battleNetFriends or {}
        shared.whispers = type(shared.whispers) == "table" and shared.whispers or {}
        shared.conversations = type(shared.conversations) == "table" and shared.conversations or {}
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.chat = type(profile.chat) == "table" and profile.chat or {}
            profile.chat.history = type(profile.chat.history) == "table" and profile.chat.history or deepCopy(defaults.history)
            profile.chat.history.whispers = {}
            profile.version = 65
        end
    end
    if previousVersion < 66 then
        -- v66 routes messaging aliases directly through the chat APIs, repairs
        -- Friends roster discovery and defaults party invites to the Blizzard-safe
        -- popup path. Existing chat, social and progression data are preserved.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.replacePartyInvitePopup = false
        CreshChatDB.ui.consoleTabs = CreshChatDB.ui.consoleTabs or deepCopy(defaults.ui.consoleTabs)
        CreshChatDB.ui.consoleTabs.FRIENDS = true
        local shared = self:EnsureAccountWhisperStorage()
        shared.accountFriends = type(shared.accountFriends) == "table" and shared.accountFriends or {}
        shared.battleNetFriends = type(shared.battleNetFriends) == "table" and shared.battleNetFriends or {}
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
            profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or deepCopy(defaults.ui)
            profile.uiData.ui.replacePartyInvitePopup = false
            profile.uiData.ui.consoleTabs = type(profile.uiData.ui.consoleTabs) == "table" and profile.uiData.ui.consoleTabs or deepCopy(defaults.ui.consoleTabs)
            profile.uiData.ui.consoleTabs.FRIENDS = true
            profile.version = 66
        end
    end
    if previousVersion < 67 then
        -- v67 restores the CreshChat-only party invitation card. Blizzard's
        -- native PARTY_INVITE popup is visually suppressed while unresolved,
        -- then dismissed only after the group join or decline has completed.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        CreshChatDB.ui.replacePartyInvitePopup = true
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
            profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or deepCopy(defaults.ui)
            profile.uiData.ui.replacePartyInvitePopup = true
            profile.version = 67
        end
    end
    if previousVersion < 68 then
        -- v68 consolidates all card-popup controls into one Notifications page,
        -- adds per-category priority/sound/volume settings and preserves every
        -- existing notification preference from earlier character profiles.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        if CreshChatDB.ui.notificationCardsEnabled == nil then CreshChatDB.ui.notificationCardsEnabled = true end
        CreshChatDB.notificationPriorities = CreshChatDB.notificationPriorities or deepCopy(defaults.notificationPriorities)
        CreshChatDB.notifications = CreshChatDB.notifications or deepCopy(defaults.notifications)
        if CreshChatDB.ui.showSystemCards == false then CreshChatDB.notifications.system = false end
        CreshChatDB.sounds = CreshChatDB.sounds or deepCopy(defaults.sounds)
        CreshChatDB.soundChoices = CreshChatDB.soundChoices or deepCopy(defaults.soundChoices)
        CreshChatDB.soundVolumes = CreshChatDB.soundVolumes or deepCopy(defaults.soundVolumes)
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
            profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or deepCopy(defaults.ui)
            if profile.uiData.ui.notificationCardsEnabled == nil then profile.uiData.ui.notificationCardsEnabled = true end
            profile.uiData.notificationPriorities = type(profile.uiData.notificationPriorities) == "table" and profile.uiData.notificationPriorities or deepCopy(defaults.notificationPriorities)
            profile.uiData.notifications = type(profile.uiData.notifications) == "table" and profile.uiData.notifications or deepCopy(defaults.notifications)
            if profile.uiData.ui.showSystemCards == false then profile.uiData.notifications.system = false end
            profile.uiData.sounds = type(profile.uiData.sounds) == "table" and profile.uiData.sounds or deepCopy(defaults.sounds)
            profile.uiData.soundChoices = type(profile.uiData.soundChoices) == "table" and profile.uiData.soundChoices or deepCopy(defaults.soundChoices)
            profile.uiData.soundVolumes = type(profile.uiData.soundVolumes) == "table" and profile.uiData.soundVolumes or deepCopy(defaults.soundVolumes)
            profile.version = 68
        end
    end
    if previousVersion < 69 then
        -- v69 repairs Guild chat refresh isolation, limits the Friends directory
        -- to real Blizzard friends, and adds a persistent collapsible roster rail.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        if CreshChatDB.ui.rosterCollapsed == nil then CreshChatDB.ui.rosterCollapsed = false end
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
            profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or deepCopy(defaults.ui)
            if profile.uiData.ui.rosterCollapsed == nil then profile.uiData.ui.rosterCollapsed = false end
            profile.version = 69
        end
    end
    if previousVersion < 70 then
        -- v70 merges all game progression, Battle Pass currency, collections,
        -- scores and unlocks into one account-wide store. Existing character
        -- profiles are merged by strongest progress and unioned collections so
        -- no unlock is discarded and duplicated legacy snapshots do not inflate
        -- balances. The new achievement system also lives in this shared store.
        self:EnsureAccountProgressionStorage(true)
        local sharedProgression = CreshChatDB.accountProgression
        sharedProgression.gameProgression = type(sharedProgression.gameProgression) == "table" and sharedProgression.gameProgression or deepCopy(defaults.gameProgression)
        sharedProgression.gameProgression.achievements = type(sharedProgression.gameProgression.achievements) == "table" and sharedProgression.gameProgression.achievements or {}
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do profile.version = 70 end
    end
    if previousVersion < 71 then
        -- v71 adds independent visibility controls for online/offline Game
        -- Friends, Battle.net Friends and Guild members. Friend lists remain
        -- sourced only from Blizzard friend APIs and never include guild rows.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        local visibilityKeys = {
            "showGameFriendsOnline", "showGameFriendsOffline",
            "showBattleNetFriendsOnline", "showBattleNetFriendsOffline",
            "showGuildMembersOnline", "showGuildMembersOffline",
        }
        for _, key in ipairs(visibilityKeys) do
            if CreshChatDB.ui[key] == nil then CreshChatDB.ui[key] = true end
        end
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
            profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or deepCopy(defaults.ui)
            for _, key in ipairs(visibilityKeys) do
                if profile.uiData.ui[key] == nil then profile.uiData.ui[key] = true end
            end
            profile.version = 71
        end
    end
    if previousVersion < 72 then
        -- v72 adds the 300-goal TBC achievement expansion, achievement and
        -- Battle Pass status filters, and moves social-roster visibility into
        -- the Windows settings page. Expansion counters begin safely at zero;
        -- current professions, reputations, friends and guild state backfill live.
        self:EnsureAccountProgressionStorage(true)
        local sharedProgression = CreshChatDB.accountProgression or {}
        sharedProgression.gameProgression = type(sharedProgression.gameProgression) == "table" and sharedProgression.gameProgression or deepCopy(defaults.gameProgression)
        sharedProgression.gameProgression.achievements = type(sharedProgression.gameProgression.achievements) == "table" and sharedProgression.gameProgression.achievements or {}
        sharedProgression.gameProgression.achievements.expansion = type(sharedProgression.gameProgression.achievements.expansion) == "table" and sharedProgression.gameProgression.achievements.expansion or {}
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do profile.version = 72 end
    end
    if previousVersion < 73 then
        -- v73 adds account-wide class achievement counters and separates real
        -- WoW dungeon progress from Dungeon Dwellers game progress. Existing
        -- rewards and unlock records are preserved; the new counters initialise
        -- safely and use the already-shared account progression store.
        self:EnsureAccountProgressionStorage(true)
        local sharedProgression = CreshChatDB.accountProgression or {}
        sharedProgression.gameProgression = type(sharedProgression.gameProgression) == "table" and sharedProgression.gameProgression or deepCopy(defaults.gameProgression)
        sharedProgression.gameProgression.achievements = type(sharedProgression.gameProgression.achievements) == "table" and sharedProgression.gameProgression.achievements or {}
        sharedProgression.gameProgression.achievements.classProgress = type(sharedProgression.gameProgression.achievements.classProgress) == "table" and sharedProgression.gameProgression.achievements.classProgress or {}
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do profile.version = 73 end
    end
    if previousVersion < 74 then
        -- v74 retries late Blizzard chat bridges, adds immediate live-view refresh,
        -- routes player/unit-frame whispers into CreshChat, and hides only the
        -- unavailable-player whisper system line while keeping an inline failed row.
        CreshChatDB.ui = CreshChatDB.ui or deepCopy(defaults.ui)
        if CreshChatDB.ui.suppressOfflineWhisperErrors == nil then CreshChatDB.ui.suppressOfflineWhisperErrors = true end
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
            profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or deepCopy(defaults.ui)
            if profile.uiData.ui.suppressOfflineWhisperErrors == nil then profile.uiData.ui.suppressOfflineWhisperErrors = true end
            profile.version = 74
        end
    end
    if previousVersion < 75 then
        CreshChatDB.ui = type(CreshChatDB.ui) == "table" and CreshChatDB.ui or {}
        local ui = CreshChatDB.ui
        if ui.showBuildBadge == nil then ui.showBuildBadge = false end
        if ui.rosterCollapsed == nil then ui.rosterCollapsed = false end
        ui.notificationLineHeight = math.max(2, math.min(6, math.floor(tonumber(ui.notificationLineHeight) or 3)))
        ui.secondaryCardWidthRatio = math.max(0.72, math.min(0.96, tonumber(ui.secondaryCardWidthRatio) or 0.88))
        ui.secondaryCardHeightRatio = math.max(0.62, math.min(0.92, tonumber(ui.secondaryCardHeightRatio) or 0.80))
        ui.dockWhisperWidth = math.max(140, math.min(280, tonumber(ui.dockWhisperWidth) or 190))
        ui.dockWhisperDuration = math.max(3, math.min(15, tonumber(ui.dockWhisperDuration) or 6))
        CreshChatDB.historyLimit = math.max(40, math.min(500, math.floor(tonumber(CreshChatDB.historyLimit) or 120)))
        CreshChatDB.combatHistoryLimit = math.max(80, math.min(600, math.floor(tonumber(CreshChatDB.combatHistoryLimit) or 220)))
        CreshChatDB.quickChannel = tostring(CreshChatDB.quickChannel or "GENERAL")
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            if type(profile) == "table" then
                profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
                profile.uiData.ui = type(profile.uiData.ui) == "table" and profile.uiData.ui or {}
                local profileUI = profile.uiData.ui
                if profileUI.showBuildBadge == nil then profileUI.showBuildBadge = false end
                if profileUI.rosterCollapsed == nil then profileUI.rosterCollapsed = false end
                profile.version = 75
            end
        end
    end

    if previousVersion < 76 then
        -- v76 removes non-table playerCache entries and trims any cache over the 500-entry cap, evicting the oldest-seen records first.
        local pc = CreshChatDB.playerCache
        if type(pc) == "table" then
            local pcEntries = {}
            for k, v in pairs(pc) do
                if type(v) == "table" then
                    pcEntries[#pcEntries + 1] = { key = k, lastSeen = tonumber(v.lastSeen) or 0 }
                else
                    pc[k] = nil
                end
            end
            if #pcEntries > MAX_PLAYER_CACHE then
                table.sort(pcEntries, function(a, b)
                    if a.lastSeen ~= b.lastSeen then return a.lastSeen < b.lastSeen end
                    return a.key < b.key
                end)
                local target = math.floor(MAX_PLAYER_CACHE * 0.9)
                for i = 1, #pcEntries - target do
                    local k = pcEntries[i].key
                    pc[k] = nil
                    local shortK = string.match(k, "^([^-]+)-")
                    if shortK then pc[shortK] = nil end
                end
            end
        end
    end

    if previousVersion < 79 then
        -- v79 introduces the modular feature system (FeatureManager.lua).
        -- All features default to enabled, so upgrading users see no behaviour change.
        -- The features table is populated automatically by mergeDefaults above.
        CreshChatDB.features = CreshChatDB.features or {}
        if type(CreshChatDB.features) == "table" then
            local featureDefaults = {
                chat=true, games=true, multiplayerGames=true,
                gameProgression=true, battlePass=true,
                worldProgression=true, combatTracking=true,
                questCapture=true, friendsPresence=true,
                voice=true, notifications=true,
            }
            for k, v in pairs(featureDefaults) do
                if CreshChatDB.features[k] == nil then CreshChatDB.features[k] = v end
            end
        end
        CreshChatDB.featurePreset = CreshChatDB.featurePreset or "full"
    end

    if previousVersion < 80 then
        -- v80 introduces the unified notification card renderer (NotificationCard.lua)
        -- and per-addon notification-source toggle storage (CreshGames, CreshCollect).
        -- unifiedNotificationCards defaults to false so existing players keep the
        -- legacy toast system and opt in via Settings → Notifications.
        CreshChatDB.features = type(CreshChatDB.features) == "table" and CreshChatDB.features or {}
        if CreshChatDB.features.unifiedNotificationCards == nil then
            CreshChatDB.features.unifiedNotificationCards = false
        end
        if type(CreshChatDB.notificationSources) ~= "table" then
            CreshChatDB.notificationSources = {}
        end
        for _, profile in pairs(CreshChatDB.characterProfiles or {}) do
            if type(profile) == "table" then
                profile.uiData = type(profile.uiData) == "table" and profile.uiData or {}
                profile.uiData.features = type(profile.uiData.features) == "table" and profile.uiData.features or {}
                if profile.uiData.features.unifiedNotificationCards == nil then
                    profile.uiData.features.unifiedNotificationCards = false
                end
                profile.version = 80
            end
        end
    end

    CreshChatDB.version = CC.schemaVersion
    self.db = CreshChatDB
    self.accountDB = CreshChatDB
    self:EnsureAccountWhisperStorage()
    self:ActivateCharacterProfile()
    self:BindSharedWhisperStorage()
    self:MergeWhisperDuplicates()
    if self.EnsureFeatures then self:EnsureFeatures() end
    if self.Quality and self.Quality.SanitizeDatabase then self.Quality:SanitizeDatabase() end
end


function CC:ResolveBattleNetPresenceName(accountID, fallback)
    local name
    if C_BattleNet and type(C_BattleNet.GetAccountInfoByID) == "function" then
        local ok, info = pcall(C_BattleNet.GetAccountInfoByID, accountID)
        if ok and type(info) == "table" then name = info.accountName or info.battleTag end
    end
    if (not name or name == "") and type(BNGetFriendInfoByID) == "function" then
        local ok, _, accountName, battleTag = pcall(BNGetFriendInfoByID, accountID)
        if ok then name = accountName or battleTag end
    end
    if not name or name == "" then
        local text = tostring(fallback or "")
        if text ~= "" and not string.match(text, "^%d+$") then name = text end
    end
    return name
end

function CC:ExtractPresenceNotice(message)
    local raw = tostring(message or "")
    if raw == "" then return nil end
    local lower = string.lower(raw)
    local online = string.find(lower, "has come online", 1, true) or string.find(lower, "is now online", 1, true)
    local offline = string.find(lower, "has gone offline", 1, true) or string.find(lower, "is now offline", 1, true)
    if not online and not offline then return nil end
    local name = string.match(raw, "|Hplayer:([^:|]+)")
    if not name then
        name = string.match(raw, "^%[([^%]]+)%]")
            or string.match(raw, "^(.+)%s+has come online")
            or string.match(raw, "^(.+)%s+has gone offline")
            or string.match(raw, "^(.+)%s+is now online")
            or string.match(raw, "^(.+)%s+is now offline")
    end
    name = self:CleanPlayerName(name or "Friend")
    return name, online and true or false
end

local eventFrame = CreateFrame("Frame", "CreshChatEventFrame")
CC.chatEventFrame = eventFrame
local coreEvents = {
    "ADDON_LOADED",
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PARTY_INVITE_REQUEST",
    "PARTY_INVITE_CANCEL",
    "GROUP_ROSTER_UPDATE",
    "CHAT_MSG_SYSTEM",
    "UI_INFO_MESSAGE",
    "BN_FRIEND_ACCOUNT_ONLINE",
    "BN_FRIEND_ACCOUNT_OFFLINE",
    "COMBAT_LOG_EVENT_UNFILTERED",
}
local coreEventLookup = {}
for _, eventName in ipairs(coreEvents) do coreEventLookup[eventName] = true end
for _, eventName in ipairs(filteredEvents) do
    if not coreEventLookup[eventName] then
        coreEvents[#coreEvents + 1] = eventName
        coreEventLookup[eventName] = true
    end
end

function CC:EnsureChatEventRegistration()
    local registered = 0
    local required = {
        CHAT_MSG_WHISPER = false, CHAT_MSG_GUILD = false,
        CHAT_MSG_CHANNEL = false, CHAT_MSG_PARTY = false,
    }
    self.state.chatRegistrationFailures = {}
    for _, eventName in ipairs(coreEvents) do
        local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, eventName)
        local active = ok
        if active and type(eventFrame.IsEventRegistered) == "function" then
            local checkOK, isRegistered = pcall(eventFrame.IsEventRegistered, eventFrame, eventName)
            if checkOK then active = isRegistered and true or false end
        end
        if active then
            registered = registered + 1
            if required[eventName] ~= nil then required[eventName] = true end
        else
            self.state.chatRegistrationFailures[eventName] = tostring(err or "not registered")
        end
    end
    local ready = true
    for _, available in pairs(required) do if not available then ready = false end end
    self.state.registeredCoreEvents = registered
    self.state.chatCaptureReady = ready
    self.state.chatCaptureCheckedAt = time and time() or 0
    return ready
end

CC:EnsureChatEventRegistration()

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == CC.name then
            CC:InitializeDatabase()
            CC:EnsureFeatures()
            local chatReady = CC:IsFeatureEnabled("chat")
            if chatReady then CC:InstallPartyInvitePopupHook() end
            CC:EnsureChatEventRegistration()
            if chatReady then
                CC:RegisterChatFilters()
                CC:InstallChatBridge()
            end
            CC:ApplyBlizzardChatVisibility()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        if not CC.db then
            CC:InitializeDatabase()
        end
        CC:UpdatePlayerIdentity()
        CC:ActivateCharacterProfile()
        CC:EnsureFeatures()
        local chatEnabled = CC:IsFeatureEnabled("chat")
        if chatEnabled then
            CC:InstallPartyInvitePopupHook()
            CC:EnsureChatStorage()
            CC:ResetBattleNetLiveRoutes()
            CC:ClearSessionChatHistory()
        end
        CC.state.wasGrouped = CC:IsPlayerInGroup()
        CC:EnsureChatEventRegistration()
        if chatEnabled then
            CC:RegisterChatFilters()
            CC:InstallChatBridge()
        end
        CC:ApplyBlizzardChatVisibility()
        if CC.UI and CC.UI.Initialize then
            CC.UI:Initialize()
        end
        CC:AnnounceLoadedBuild()
        if C_Timer and C_Timer.After then
            C_Timer.After(1.0, function() CC:ApplyBlizzardChatVisibility() end)
        end
        CC.state.ready = true
        return
    end

    if event == "PLAYER_LOGOUT" then
        CC:ClearSessionChatHistory()
        CC:SyncActiveCharacterProfile()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        CC:UpdatePlayerIdentity()
        local chatOK = CC:IsFeatureEnabled("chat")
        if chatOK then CC:EnsureChatStorage() end
        CC:EnsureChatEventRegistration()
        if chatOK then
            CC:RegisterChatFilters()
            CC:InstallChatBridge()
        end
        CC:ApplyBlizzardChatVisibility()
        if chatOK then
            if CC.UI and CC.UI.InstallBlizzardChatRedirects and CC.UI.initialized then CC.UI:InstallBlizzardChatRedirects() end
        end
        if CC.UI and CC.UI.SetBubbleGroupShown and CC.db then
            CC.UI:SetBubbleGroupShown(CC.db.bubbleVisible)
        end
        return
    end

    if not CC.db then
        return
    end

    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        if CC.UI and CC.UI.SetBubbleGroupShown then
            CC.UI:SetBubbleGroupShown(CC.db.bubbleVisible)
        end
        if CC.UI and CC.UI.RefreshLauncherVisibility then
            CC.UI:RefreshLauncherVisibility(true)
        end
        return
    end

    if event == "PARTY_INVITE_REQUEST" then
        local inviter = ...
        CC.state.pendingPartyInviter = inviter or "Unknown"
        CC.state.partyInvitePending = true
        CC.state.partyInviteAction = nil
        CC.state.partyInviteAcceptedAt = nil
        local notifEnabled = CC:IsFeatureEnabled("notifications")
        local showInviteAlert = notifEnabled and CC:IsNotificationEnabled("PARTY_INVITE")
        if showInviteAlert and CC.UI and CC.UI.ShowPartyInvite then
            CC.UI:ShowPartyInvite(CC.state.pendingPartyInviter, false)
        end
        if showInviteAlert and CC.UI and CC.UI.NotifyLauncher then CC.UI:NotifyLauncher("PARTY_INVITE", CC.state.pendingPartyInviter) end
        if notifEnabled then CC:PlayAlertSound("PARTY_INVITE") end
        if showInviteAlert and CC:ShouldReplacePartyInvitePopup() then
            CC:HideBlizzardPartyInvitePopups()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function() CC:SuppressBlizzardPartyInvitePopups() end)
                C_Timer.After(0.10, function() CC:SuppressBlizzardPartyInvitePopups() end)
                C_Timer.After(0.35, function() CC:SuppressBlizzardPartyInvitePopups() end)
            end
        end
        return
    end

    if event == "PARTY_INVITE_CANCEL" then
        if CC.state.partyInviteAction == "ACCEPTING" then
            -- Classic can emit the cancel event while the accepted invite is still
            -- becoming a group. Keep the state until GROUP_ROSTER_UPDATE confirms it.
            if C_Timer and C_Timer.After then
                C_Timer.After(0.20, function()
                    if CC.state.partyInviteAction == "ACCEPTING" then CC:SuppressBlizzardPartyInvitePopups() end
                end)
                C_Timer.After(1.00, function()
                    if CC.state.partyInviteAction == "ACCEPTING" then CC:SuppressBlizzardPartyInvitePopups() end
                end)
                C_Timer.After(4.00, function()
                    if not CC:IsPlayerInGroup() and CC.state.partyInviteAction == "ACCEPTING" then
                        -- By this point the server has not produced a group roster.
                        -- The cancellation is treated as final and the still-hidden
                        -- native dialog can be safely removed without flashing.
                        CC:FinalizeBlizzardPartyInvitePopups()
                        CC.state.partyInvitePending = false
                        CC.state.pendingPartyInviter = nil
                        CC.state.partyInviteAction = nil
                        CC.state.partyInviteAcceptedAt = nil
                        if CC.UI and CC.UI.CancelPartyInviteToasts then CC.UI:CancelPartyInviteToasts() end
                        if CC.UI and CC.UI.RefreshLauncherNotification then CC.UI:RefreshLauncherNotification() end
                    end
                end)
            end
            return
        end
        CC:FinalizeBlizzardPartyInvitePopups()
        CC.state.partyInvitePending = false
        CC.state.pendingPartyInviter = nil
        CC.state.partyInviteAction = nil
        CC.state.partyInviteAcceptedAt = nil
        if CC.UI and CC.UI.CancelPartyInviteToasts then CC.UI:CancelPartyInviteToasts() end
        if CC.UI and CC.UI.RefreshLauncherNotification then CC.UI:RefreshLauncherNotification() end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        local grouped = CC:IsPlayerInGroup()
        local wasGrouped = CC.state.wasGrouped and true or false
        if grouped then CC:FinalizeBlizzardPartyInvitePopups() end
        if grouped and not wasGrouped and CC.UI and CC.UI.ShowSystemToast then
            local inviter = CC.state.pendingPartyInviter
            CC.UI:ShowSystemToast("Party joined", inviter and ("You joined " .. CC:ShortName(inviter) .. "'s party") or "You joined a party", "SUCCESS")
        elseif not grouped and wasGrouped and CC.UI and CC.UI.ShowSystemToast then
            CC.UI:ShowSystemToast("Party left", "You are no longer in a party", "INFO")
        end
        CC.state.wasGrouped = grouped and true or false

        -- A roster update can occur while an invitation is still pending. Do not
        -- discard the invite merely because the player is not grouped yet.
        local resolveInvite = grouped or wasGrouped or CC.state.partyInviteAction == "DECLINING"
        if resolveInvite then
            CC.state.partyInvitePending = false
            CC.state.pendingPartyInviter = nil
            CC.state.partyInviteAction = nil
            CC.state.partyInviteAcceptedAt = nil
            if CC.UI and CC.UI.CancelPartyInviteToasts then CC.UI:CancelPartyInviteToasts() end
            if CC.UI and CC.UI.RefreshLauncherNotification then CC.UI:RefreshLauncherNotification() end
        end
        if CC.UI and CC.UI.RefreshConsoleTabs then CC.UI:RefreshConsoleTabs() end
        return
    end

    if event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" then
        if CC:IsFeatureEnabled("friendsPresence") and CC:IsFeatureEnabled("notifications") then
            local accountID, fallbackName = select(1, ...), select(2, ...)
            local accountName = CC:ResolveBattleNetPresenceName(accountID, fallbackName)
            if accountName and CC.UI and CC.UI.ShowPresenceToast then
                CC.UI:ShowPresenceToast(accountName, event == "BN_FRIEND_ACCOUNT_ONLINE")
                if CC.UI.NotifyLauncher then CC.UI:NotifyLauncher("FRIEND", accountName, 4.0) end
            end
        end
        return
    end

    if event == "CHAT_MSG_SYSTEM" or event == "UI_INFO_MESSAGE" then
        -- Always run the player-not-found suppressor when chat is enabled (it guards pending whispers).
        if CC:IsFeatureEnabled("chat") then
            local text = CC:GetFirstEventMessage(...)
            if text and event == "CHAT_MSG_SYSTEM" and CC:IsPlayerNotFoundSystemMessage(text) then
                CC:HandleSuppressedPlayerNotFound(text)
                return
            end
            if text then
                local historyMessage = CC:AddGeneralMessage("System", text, true, nil, nil, event == "UI_INFO_MESSAGE" and "Game" or "System", event)
                CC:NotifyChatUI("GENERAL", nil, historyMessage, false)
                if CC:IsFeatureEnabled("notifications") then
                    local presenceName, isOnline = CC:ExtractPresenceNotice(text)
                    if CC.UI then
                        if presenceName and CC.UI.ShowPresenceToast and CC:IsFeatureEnabled("friendsPresence") then
                            CC.UI:ShowPresenceToast(presenceName, isOnline)
                            if CC.UI.NotifyLauncher then CC.UI:NotifyLauncher("FRIEND", presenceName, 4.0) end
                        elseif CC.UI.ShowSystemToast then
                            CC.UI:ShowSystemToast(event == "UI_INFO_MESSAGE" and "Game notification" or "System", text, "INFO")
                            if CC.UI.NotifyLauncher then CC.UI:NotifyLauncher("SYSTEM", nil, 5.0) end
                        end
                    end
                end
            end
        end
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if CC:IsFeatureEnabled("chat") then
            CC:HandleCombatLogEvent(...)
        end
        return
    end

    CC:DispatchChatEvent("DIRECT", event, ...)
end)

SLASH_CRESHCHAT1 = "/creshchat"
SLASH_CRESHCHAT2 = "/cc"
SlashCmdList.CRESHCHAT = function(message)
    CC:HandleSlashCommand(message)
end
