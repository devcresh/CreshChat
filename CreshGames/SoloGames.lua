local ADDON_NAME, CC = ...
if not CC then return end

local Solo = {
    version = CC.version,
    activeGame = nil,
    views = {},
    selectedFroggerLevel = 1,
}
CC.SoloGames = Solo
if CC.RegisterModule then CC:RegisterModule("SoloGames", Solo) end

local floor, min, max, abs, sin = math.floor, math.min, math.max, math.abs, math.sin
local insert, sort, concat = table.insert, table.sort, table.concat
local upper, lower = string.upper, string.lower
local format = string.format
local unpack = unpack or table.unpack

local EIGHTBIT_GAME_ICON_ROOT = "Interface\\AddOns\\CreshGames\\Media\\Games\\Icons8Bit\\"

local function now()
    if type(GetTime) == "function" then return GetTime() end
    if type(time) == "function" then return time() end
    return 0
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    return max(low, min(high, value))
end

local function formatChips(value)
    local text = tostring(floor(max(0, tonumber(value) or 0)))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if grouped:sub(1, 1) == "," then grouped = grouped:sub(2) end
    return grouped
end

local function templateName()
    return _G.BackdropTemplateMixin and "BackdropTemplate" or nil
end

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local FALLBACK = {
    panel = { 0.022, 0.026, 0.034, 0.98 },
    panelSoft = { 0.038, 0.044, 0.056, 0.98 },
    panelRaised = { 0.066, 0.074, 0.092, 1 },
    border = { 0.105, 0.120, 0.145, 1 },
    accent = { 0.130, 0.620, 0.950, 1 },
    text = { 0.93, 0.95, 0.98, 1 },
    muted = { 0.56, 0.61, 0.69, 1 },
    green = { 0.18, 0.78, 0.36, 1 },
    red = { 0.92, 0.24, 0.25, 1 },
    gold = { 0.95, 0.70, 0.20, 1 },
    water = { 0.035, 0.18, 0.34, 1 },
    road = { 0.095, 0.10, 0.12, 1 },
}

local function palette()
    local colors = CC.db and CC.db.colors or {}
    return {
        panel = colors.panel or FALLBACK.panel,
        panelSoft = colors.panelSoft or FALLBACK.panelSoft,
        panelRaised = colors.panelRaised or FALLBACK.panelRaised,
        border = colors.border or FALLBACK.border,
        accent = colors.accent or FALLBACK.accent,
        text = FALLBACK.text,
        muted = FALLBACK.muted,
        green = FALLBACK.green,
        red = FALLBACK.red,
        gold = FALLBACK.gold,
        water = FALLBACK.water,
        road = FALLBACK.road,
    }
end

local function darken(color, amount)
    amount = tonumber(amount) or 0.18
    return {
        max(0, (color[1] or 0) - amount),
        max(0, (color[2] or 0) - amount),
        max(0, (color[3] or 0) - amount),
        color[4] or 1,
    }
end

local function brighten(color, amount)
    amount = tonumber(amount) or 0.10
    return {
        min(1, (color[1] or 0) + amount),
        min(1, (color[2] or 0) + amount),
        min(1, (color[3] or 0) + amount),
        color[4] or 1,
    }
end

local function applyBackdrop(frame, background, border)
    if not frame then return end
    if frame.SetBackdrop then frame:SetBackdrop(BACKDROP) end
    background = background or FALLBACK.panel
    border = border or FALLBACK.border
    if frame.SetBackdropColor then frame:SetBackdropColor(background[1], background[2], background[3], background[4] or 1) end
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1) end
end

local function createText(parent, size, color, justify)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont(_G.STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size or 11, "")
    color = color or FALLBACK.text
    font:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    font:SetJustifyH(justify or "LEFT")
    font:SetJustifyV("MIDDLE")
    return font
end

local function createButton(parent, label, width, height, callback)
    local colors = palette()
    local button = CreateFrame("Button", nil, parent, templateName())
    button:SetSize(width or 90, height or 28)
    applyBackdrop(button, colors.panelRaised, colors.border)
    button.label = createText(button, 10, colors.text, "CENTER")
    button.label:SetAllPoints()
    button.label:SetText(label or "BUTTON")
    button.creshBaseColor = colors.panelRaised
    button.creshHoverColor = brighten(colors.accent, 0.04)
    button.creshDisabled = false
    button:SetScript("OnEnter", function(self)
        if not self.creshDisabled then applyBackdrop(self, self.creshHoverColor or colors.accent, self.creshHoverColor or colors.accent) end
    end)
    button:SetScript("OnLeave", function(self)
        applyBackdrop(self, self.creshBaseColor or colors.panelRaised, self.creshSelected and colors.accent or colors.border)
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if self.creshDisabled then return end
        if CC.GameAudio and CC.GameAudio.PlayInteraction then CC.GameAudio:PlayInteraction("CLICK") end
        if callback then callback(self, mouseButton) end
    end)
    return button
end

local function setButtonEnabled(button, enabled)
    if not button then return end
    button.creshDisabled = not enabled
    button:SetAlpha(enabled and 1 or 0.38)
end

local function setButtonAccent(button, accent)
    if not button then return end
    local colors = palette()
    accent = accent or colors.accent
    button.creshBaseColor = darken(accent, 0.22)
    button.creshHoverColor = brighten(accent, 0.08)
    applyBackdrop(button, button.creshBaseColor, accent)
end

local function cardFrame(parent, width, height)
    local colors = palette()
    local card = CreateFrame("Frame", nil, parent, templateName())
    card:SetSize(width, height)
    applyBackdrop(card, colors.panel, colors.border)
    return card
end

local function makeRng(seed)
    local state = { value = tonumber(seed) or 1 }
    function state:Next(limit)
        self.value = (self.value * 1103515245 + 12345) % 2147483648
        if limit then return (self.value % limit) + 1 end
        return self.value
    end
    function state:Float()
        return self:Next() / 2147483648
    end
    return state
end

local function ensureSave()
    if not CC.db then return nil end
    CC.db.soloGames = CC.db.soloGames or {}
    local root = CC.db.soloGames
    root.frogger = root.frogger or { unlocked = 1, bestLevel = 0, highScore = 0, games = 0 }
    root.holdem = root.holdem or { wins = 0, losses = 0, bestChips = 100, games = 0, bankroll = 100 }
    root.blackjack = root.blackjack or { wins = 0, losses = 0, pushes = 0, bestBank = 100, games = 0, bankroll = 100 }
    root.dungeon = root.dungeon or { runs = 0, bestLevel = 0, bestRoom = 0, kills = 0, bosses = 0, minions = 0, highScore = 0, bossCoins = 0, class = "", enemyKillsByType = {}, bossKillsByType = {}, firstBossKills = {}, unlockedArmour = {}, equippedArmour = {}, crateInventory = {}, crateHistory = {}, pendingCrates = {}, permanentDamage = 0, armourPity = 0, voidCratePity = 0, armourShards = 0, portraitTokens = 0, fullBodyTokens = 0, classStats = {}, classStatsMigrated = false, unlockedMinions = {}, minionRecruitsByType = {}, unlockedMinionSkins = {}, minionSkinRecruits = {}, discoveredItems = {}, battlePass = { xp = 0, claimed = {}, buffs = {}, activity = {}, visitedZones = {}, achievements = {}, recent = {} } }
    root.chess = root.chess or { wins = 0, losses = 0, draws = 0, games = 0, level = 3, bestLevel = 0 }
    root.higherlower = root.higherlower or { wins = 0, losses = 0, draws = 0, games = 0, bankroll = 100, bestBank = 100, bestStreak = 0 }
    root.tetris = root.tetris or { wins = 0, losses = 0, games = 0, highScore = 0, bestLines = 0, totalLines = 0, vsWins = 0, vsLosses = 0, endlessRuns = 0, cpuLevel = 3, cpuVersusMode = "ENDLESS", multiplayerMode = "ENDLESS", multiplayerDuration = 10, soloDuration = 10, mode = "ENDLESS", revealLines = 0, revealCompleted = 0, revealThemeKey = "", revealBackgroundKey = "", passXP = 0, passClaimed = {}, unlockedThemes = { CLASSIC_BLOCKS = true }, themeUnlockSources = { CLASSIC_BLOCKS = "DEFAULT" }, selectedTheme = "CLASSIC_BLOCKS", unlockedBackgrounds = {}, backgroundUnlockSources = {}, selectedBackground = "" }
    root.frogger.unlocked = floor(max(1, tonumber(root.frogger.unlocked) or 1))
    root.frogger.bestLevel = floor(max(0, tonumber(root.frogger.bestLevel) or 0))
    root.holdem.bankroll = floor(max(0, tonumber(root.holdem.bankroll) or tonumber(root.holdem.bestChips) or 100))
    root.blackjack.bankroll = floor(max(0, tonumber(root.blackjack.bankroll) or tonumber(root.blackjack.bestBank) or 100))
    root.holdem.bestChips = floor(max(root.holdem.bestChips or 100, root.holdem.bankroll))
    root.blackjack.bestBank = floor(max(root.blackjack.bestBank or 100, root.blackjack.bankroll))
    root.dungeon.minions = floor(max(0, tonumber(root.dungeon.minions) or 0))
    root.dungeon.bossCoins = floor(max(0, tonumber(root.dungeon.bossCoins) or 0))
    root.dungeon.class = upper(tostring(root.dungeon.class or ""))
    root.dungeon.enemyKillsByType = type(root.dungeon.enemyKillsByType) == "table" and root.dungeon.enemyKillsByType or {}
    root.dungeon.unlockedArmour = type(root.dungeon.unlockedArmour) == "table" and root.dungeon.unlockedArmour or {}
    root.dungeon.equippedArmour = type(root.dungeon.equippedArmour) == "table" and root.dungeon.equippedArmour or {}
    root.dungeon.bossKillsByType = type(root.dungeon.bossKillsByType) == "table" and root.dungeon.bossKillsByType or {}
    root.dungeon.firstBossKills = type(root.dungeon.firstBossKills) == "table" and root.dungeon.firstBossKills or {}
    root.dungeon.crateInventory = type(root.dungeon.crateInventory) == "table" and root.dungeon.crateInventory or {}
    root.dungeon.crateHistory = type(root.dungeon.crateHistory) == "table" and root.dungeon.crateHistory or {}
    root.dungeon.pendingCrates = type(root.dungeon.pendingCrates) == "table" and root.dungeon.pendingCrates or {}
    root.dungeon.permanentDamage = floor(max(0, tonumber(root.dungeon.permanentDamage) or 0))
    root.dungeon.armourPity = floor(max(0, tonumber(root.dungeon.armourPity) or 0))
    root.dungeon.voidCratePity = floor(max(0, tonumber(root.dungeon.voidCratePity) or 0))
    root.dungeon.armourShards = floor(max(0, tonumber(root.dungeon.armourShards) or 0))
    root.dungeon.portraitTokens = floor(max(0, tonumber(root.dungeon.portraitTokens) or 0))
    root.dungeon.fullBodyTokens = floor(max(0, tonumber(root.dungeon.fullBodyTokens) or 0))
    root.dungeon.classStats = type(root.dungeon.classStats) == "table" and root.dungeon.classStats or {}
    root.dungeon.unlockedMinions = type(root.dungeon.unlockedMinions) == "table" and root.dungeon.unlockedMinions or {}
    root.dungeon.minionRecruitsByType = type(root.dungeon.minionRecruitsByType) == "table" and root.dungeon.minionRecruitsByType or {}
    root.dungeon.unlockedMinionSkins = type(root.dungeon.unlockedMinionSkins) == "table" and root.dungeon.unlockedMinionSkins or {}
    root.dungeon.minionSkinRecruits = type(root.dungeon.minionSkinRecruits) == "table" and root.dungeon.minionSkinRecruits or {}
    root.dungeon.discoveredItems = type(root.dungeon.discoveredItems) == "table" and root.dungeon.discoveredItems or {}
    root.dungeon.battlePass = type(root.dungeon.battlePass) == "table" and root.dungeon.battlePass or { xp = 0, claimed = {}, buffs = {}, activity = {}, visitedZones = {}, achievements = {}, recent = {} }
    root.chess.wins = floor(max(0, tonumber(root.chess.wins) or 0))
    root.chess.losses = floor(max(0, tonumber(root.chess.losses) or 0))
    root.chess.draws = floor(max(0, tonumber(root.chess.draws) or 0))
    root.chess.games = floor(max(root.chess.wins + root.chess.losses + root.chess.draws, tonumber(root.chess.games) or 0))
    root.chess.level = floor(clamp(root.chess.level or 3, 1, 5))
    root.chess.bestLevel = floor(clamp(root.chess.bestLevel or 0, 0, 5))
    root.higherlower.wins = floor(max(0, tonumber(root.higherlower.wins) or 0))
    root.higherlower.losses = floor(max(0, tonumber(root.higherlower.losses) or 0))
    root.higherlower.draws = floor(max(0, tonumber(root.higherlower.draws) or 0))
    root.higherlower.games = floor(max(root.higherlower.wins + root.higherlower.losses + root.higherlower.draws, tonumber(root.higherlower.games) or 0))
    root.higherlower.bankroll = floor(max(0, tonumber(root.higherlower.bankroll) or tonumber(root.higherlower.bestBank) or 100))
    root.higherlower.bestBank = floor(max(root.higherlower.bankroll, tonumber(root.higherlower.bestBank) or 100))
    root.higherlower.bestStreak = floor(max(0, tonumber(root.higherlower.bestStreak) or 0))
    root.tetris.wins = floor(max(0, tonumber(root.tetris.wins) or 0))
    root.tetris.losses = floor(max(0, tonumber(root.tetris.losses) or 0))
    root.tetris.games = floor(max(root.tetris.wins + root.tetris.losses, tonumber(root.tetris.games) or 0))
    root.tetris.highScore = floor(max(0, tonumber(root.tetris.highScore) or 0))
    root.tetris.bestLines = floor(max(0, tonumber(root.tetris.bestLines) or 0))
    root.tetris.totalLines = floor(max(root.tetris.bestLines, tonumber(root.tetris.totalLines) or 0))
    root.tetris.vsWins = floor(max(0, tonumber(root.tetris.vsWins) or 0))
    root.tetris.vsLosses = floor(max(0, tonumber(root.tetris.vsLosses) or 0))
    root.tetris.endlessRuns = floor(max(0, tonumber(root.tetris.endlessRuns) or 0))
    root.tetris.cpuLevel = floor(clamp(root.tetris.cpuLevel or 3, 1, 5))
    root.tetris.cpuVersusMode = upper(tostring(root.tetris.cpuVersusMode or "ENDLESS"))
    if root.tetris.cpuVersusMode ~= "ATTACK" then root.tetris.cpuVersusMode = "ENDLESS" end
    root.tetris.multiplayerMode = upper(tostring(root.tetris.multiplayerMode or "ENDLESS"))
    if root.tetris.multiplayerMode ~= "ATTACK" then root.tetris.multiplayerMode = "ENDLESS" end
    local allowedDuration = { [5]=true, [10]=true, [15]=true, [30]=true, [45]=true, [60]=true }
    root.tetris.multiplayerDuration = floor(clamp(root.tetris.multiplayerDuration or 10, 5, 60))
    if not allowedDuration[root.tetris.multiplayerDuration] then root.tetris.multiplayerDuration = 10 end
    root.tetris.soloDuration = floor(clamp(root.tetris.soloDuration or 10, 5, 60))
    if not allowedDuration[root.tetris.soloDuration] then root.tetris.soloDuration = 10 end
    root.tetris.mode = upper(tostring(root.tetris.mode or "ENDLESS"))
    if root.tetris.mode ~= "CPU" and root.tetris.mode ~= "ENDLESS" then root.tetris.mode = "ENDLESS" end
    root.tetris.revealLines = floor(max(0, tonumber(root.tetris.revealLines) or 0))
    root.tetris.revealCompleted = floor(max(0, tonumber(root.tetris.revealCompleted) or 0))
    root.tetris.revealBackgroundKey = upper(tostring(root.tetris.revealBackgroundKey or root.tetris.revealThemeKey or ""))
    root.tetris.revealThemeKey = root.tetris.revealBackgroundKey
    root.tetris.unlockedBackgrounds = type(root.tetris.unlockedBackgrounds) == "table" and root.tetris.unlockedBackgrounds or {}
    root.tetris.backgroundUnlockSources = type(root.tetris.backgroundUnlockSources) == "table" and root.tetris.backgroundUnlockSources or {}
    root.tetris.selectedBackground = upper(tostring(root.tetris.selectedBackground or ""))
    root.tetris.passXP = floor(max(0, tonumber(root.tetris.passXP) or 0))
    root.tetris.passClaimed = type(root.tetris.passClaimed) == "table" and root.tetris.passClaimed or {}
    root.tetris.unlockedThemes = type(root.tetris.unlockedThemes) == "table" and root.tetris.unlockedThemes or { CLASSIC_BLOCKS = true }
    root.tetris.themeUnlockSources = type(root.tetris.themeUnlockSources) == "table" and root.tetris.themeUnlockSources or { CLASSIC_BLOCKS = "DEFAULT" }
    root.tetris.selectedTheme = upper(tostring(root.tetris.selectedTheme or "CLASSIC_BLOCKS"))
    if CC.Tetris and CC.Tetris.Ensure then CC.Tetris:Ensure() end
    CC.db.gameHistory = type(CC.db.gameHistory) == "table" and CC.db.gameHistory or {}
    CC.db.gameLeaderboards = type(CC.db.gameLeaderboards) == "table" and CC.db.gameLeaderboards or {}
    CC.db.multiplayerStats = type(CC.db.multiplayerStats) == "table" and CC.db.multiplayerStats or {}
    return root
end

function Solo:GetSave()
    return ensureSave()
end

local SOLO_GAME_LABELS = {
    FROGGER = "Frogger", DUNGEON = "Dungeon Dweller", CHESS = "Solo Chess",
    HOLDEM = "Texas Hold'em", BLACKJACK = "Blackjack", HIGHERLOWER = "Higher or Lower",
    TETRIS = "Tetris", PONG = "Pong",
}

local LEADERBOARD_CODE_TO_GAME = { F="FROGGER", D="DUNGEON", C="CHESS", H="HOLDEM", B="BLACKJACK", R="HIGHERLOWER", T="TETRIS" }
local LEADERBOARD_METRIC = {
    FROGGER = "High score", DUNGEON = "Best room", CHESS = "Solo wins",
    HOLDEM = "Bankroll", BLACKJACK = "Bank", HIGHERLOWER = "Best streak", TETRIS = "High score",
}

local function localPlayerName()
    local state = CC.state or {}
    local name = state.playerFullName or state.playerName
    if (not name or name == "") and type(_G.UnitName) == "function" then name = _G.UnitName("player") end
    return tostring(name or "You")
end

local function cleanHistoryText(value, limit)
    local text = tostring(value or "")
    text = string.gsub(text, "[\r\n]+", " ")
    text = string.gsub(text, "|", "")
    if #text > (limit or 90) then text = string.sub(text, 1, (limit or 90) - 1) .. "…" end
    return text
end

function Solo:RecordHistory(game, mode, result, opponent, detail, score)
    ensureSave()
    if not CC.db then return false end
    game = upper(tostring(game or "GAME"))
    mode = upper(tostring(mode or "SOLO"))
    result = upper(tostring(result or "DRAW"))
    if result ~= "WIN" and result ~= "LOSS" and result ~= "DRAW" and result ~= "RUN" then result = "DRAW" end
    local entry = {
        game = game,
        mode = mode,
        result = result,
        opponent = cleanHistoryText(opponent or (mode == "SOLO" and "Computer" or "Player"), 40),
        detail = cleanHistoryText(detail, 100),
        score = floor(max(0, tonumber(score) or 0)),
        timestamp = type(_G.time) == "function" and _G.time() or floor(now()),
    }
    CC.db.gameHistory = CC.db.gameHistory or {}
    table.insert(CC.db.gameHistory, 1, entry)
    while #CC.db.gameHistory > 60 do table.remove(CC.db.gameHistory) end
    -- BattlePass:AwardForGame is intentionally not called here: GameProgression:OnGameCompleted
    -- (via AddGameXP/AwardGameLevel) is the sole game-completion path into the shared Battle Pass
    -- pools. Calling both double-funded Cresh Coins/Pass XP from a single game result.
    if CC.GameProgression and CC.GameProgression.OnGameCompleted then CC.GameProgression:OnGameCompleted(entry) end
    if self.socialPanel and self.socialPanel:IsShown() then self:RefreshSocialPanel() end
    return true
end

function Solo:GetHistory()
    ensureSave()
    return CC.db and CC.db.gameHistory or {}
end

function Solo:GetLeaderboardSnapshot()
    local save = ensureSave()
    if not save then return {} end
    return {
        FROGGER = floor(max(0, tonumber(save.frogger.highScore) or 0)),
        DUNGEON = floor(max(0, tonumber(save.dungeon.bestRoom) or tonumber(save.dungeon.bestLevel) or 0)),
        CHESS = floor(max(0, tonumber(save.chess.wins) or 0)),
        HOLDEM = floor(max(0, tonumber(save.holdem.bankroll) or 0)),
        BLACKJACK = floor(max(0, tonumber(save.blackjack.bankroll) or 0)),
        HIGHERLOWER = floor(max(0, tonumber(save.higherlower.bestStreak) or 0)),
        TETRIS = floor(max(0, tonumber(save.tetris.highScore) or 0)),
    }
end

function Solo:UpdateLocalLeaderboard()
    if not CC.db then return end
    CC.db.gameLeaderboards = CC.db.gameLeaderboards or {}
    local player = localPlayerName()
    local key = lower(player)
    local stampValue = type(_G.time) == "function" and _G.time() or floor(now())
    for game, score in pairs(self:GetLeaderboardSnapshot()) do
        CC.db.gameLeaderboards[game] = CC.db.gameLeaderboards[game] or {}
        CC.db.gameLeaderboards[game][key] = { name = player, score = score, updated = stampValue, localPlayer = true }
    end
end

function Solo:ReceiveLeaderboard(sender, parts)
    if not CC.db or type(parts) ~= "table" then return false end
    CC.db.gameLeaderboards = CC.db.gameLeaderboards or {}
    local senderName = tostring(sender or "Unknown")
    local stampValue = type(_G.time) == "function" and _G.time() or floor(now())
    local changed = false
    local index = 3
    while index <= #parts - 1 do
        local game = LEADERBOARD_CODE_TO_GAME[upper(tostring(parts[index] or ""))]
        local score = floor(max(0, tonumber(parts[index + 1]) or 0))
        if game then
            CC.db.gameLeaderboards[game] = CC.db.gameLeaderboards[game] or {}
            CC.db.gameLeaderboards[game][lower(senderName)] = { name = senderName, score = score, updated = stampValue }
            changed = true
        end
        index = index + 2
    end
    if changed and self.socialPanel and self.socialPanel:IsShown() then self:RefreshSocialPanel() end
    return changed
end

function Solo:GetLeaderboard(game)
    game = upper(tostring(game or "FROGGER"))
    self:UpdateLocalLeaderboard()
    local rows = {}
    local board = CC.db and CC.db.gameLeaderboards and CC.db.gameLeaderboards[game] or {}
    for _, entry in pairs(board or {}) do
        rows[#rows + 1] = {
            name = tostring(entry.name or "Unknown"),
            score = floor(max(0, tonumber(entry.score) or 0)),
            updated = tonumber(entry.updated) or 0,
            localPlayer = entry.localPlayer == true,
        }
    end
    sort(rows, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return lower(a.name) < lower(b.name)
    end)
    return rows
end

function Solo:GetLeaderboardMetric(game)
    return LEADERBOARD_METRIC[upper(tostring(game or ""))] or "Score"
end

function Solo:PushLeaderboards()
    self:UpdateLocalLeaderboard()
    if CC.Games and CC.Games.BroadcastLeaderboard then CC.Games:BroadcastLeaderboard() end
    if self.socialPanel and self.socialPanel:IsShown() then self:RefreshSocialPanel() end
end

function Solo:SetStatus(text, color)
    local frame = self:BuildWindow()
    frame.status:SetText(tostring(text or ""))
    color = color or palette().muted
    frame.status:SetTextColor(color[1], color[2], color[3], 1)
    if CC.GameProgression then CC.GameProgression:UpdateBar(frame.levelProgress, frame.levelText, self.activeGame) end
end

function Solo:HideViews()
    if self.hub then self.hub:Hide() end
    for _, view in pairs(self.views) do
        if view.frame then view.frame:Hide() end
    end
end

function Solo:BuildWindow()
    if self.window then return self.window end
    local colors = palette()
    local frame = CreateFrame("Frame", "CreshChatSoloArcade", UIParent, templateName())
    frame:SetSize(760, 700)
    frame:SetPoint("CENTER", UIParent, "CENTER", 55, 10)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:EnableKeyboard(true)
    if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(false) end
    applyBackdrop(frame, colors.panel, colors.border)
    frame:Hide()
    self.window = frame
    if CC.UI and CC.UI.ApplySafeFrameScale then CC.UI:ApplySafeFrameScale(frame, (CC.db.ui and CC.db.ui.scale) or 1, 22) end

    frame.header = CreateFrame("Frame", nil, frame, templateName())
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    frame.header:SetHeight(48)
    applyBackdrop(frame.header, colors.panelRaised, colors.border)
    frame.header:EnableMouse(true)
    frame.header:RegisterForDrag("LeftButton")
    frame.header:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    frame.title = createText(frame.header, 16, colors.text, "LEFT")
    frame.title:SetPoint("TOPLEFT", frame.header, "TOPLEFT", 12, -8)
    frame.title:SetText("CRESH SOLO ARCADE")
    frame.subtitle = createText(frame.header, 9, colors.muted, "LEFT")
    frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -3)
    frame.subtitle:SetText("Single-player games · WASD / arrows · mouse controls")

    frame.home = createButton(frame.header, "ARCADE", 62, 26, function() Solo:ShowHub() end)
    frame.home:SetPoint("RIGHT", frame.header, "RIGHT", -42, 0)
    setButtonAccent(frame.home, colors.accent)

    frame.settings = createButton(frame.header, "SET", 40, 26, function()
        if CC.UI and CC.UI.OpenSettings then CC.UI:OpenSettings() end
    end)
    frame.settings:SetPoint("RIGHT", frame.home, "LEFT", -6, 0)
    frame.settings:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("CreshChat Settings", 1, 1, 1)
        GameTooltip:AddLine("Open Settings to configure modules and launcher.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    frame.settings:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.close = createButton(frame.header, "X", 28, 26, function() frame:Hide() end)
    frame.close:SetPoint("RIGHT", frame.header, "RIGHT", -7, 0)
    setButtonAccent(frame.close, colors.red)

    frame.statusBar = CreateFrame("Frame", nil, frame, templateName())
    frame.statusBar:SetPoint("TOPLEFT", frame.header, "BOTTOMLEFT", 7, -7)
    frame.statusBar:SetPoint("TOPRIGHT", frame.header, "BOTTOMRIGHT", -7, -7)
    frame.statusBar:SetHeight(32)
    applyBackdrop(frame.statusBar, colors.panelSoft, colors.border)
    frame.status = createText(frame.statusBar, 10, colors.muted, "LEFT")
    frame.status:SetPoint("LEFT", frame.statusBar, "LEFT", 8, 2)
    frame.status:SetPoint("RIGHT", frame.statusBar, "RIGHT", -154, 2)
    frame.status:SetText("Choose a single-player game.")
    frame.levelText = createText(frame.statusBar, 8, colors.text, "RIGHT")
    frame.levelText:SetPoint("TOPRIGHT", frame.statusBar, "TOPRIGHT", -8, -5)
    frame.levelText:SetSize(138, 12)
    frame.levelProgress = CreateFrame("StatusBar", nil, frame.statusBar)
    frame.levelProgress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    frame.levelProgress:SetPoint("BOTTOMLEFT", frame.statusBar, "BOTTOMLEFT", 1, 1)
    frame.levelProgress:SetPoint("BOTTOMRIGHT", frame.statusBar, "BOTTOMRIGHT", -1, 1)
    frame.levelProgress:SetHeight(4)
    frame.levelProgress:SetMinMaxValues(0, 1)
    frame.levelProgress:SetValue(0)
    frame.levelProgress:SetStatusBarColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.95)

    frame.content = CreateFrame("Frame", nil, frame, templateName())
    frame.content:SetPoint("TOPLEFT", frame.statusBar, "BOTTOMLEFT", 0, -7)
    frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 7)
    applyBackdrop(frame.content, colors.panelSoft, colors.panelSoft)

    frame:SetScript("OnShow", function(selfFrame)
        selfFrame:EnableKeyboard(true)
        if selfFrame.SetPropagateKeyboardInput then selfFrame:SetPropagateKeyboardInput(false) end
    end)
    frame:SetScript("OnHide", function(selfFrame)
        selfFrame:EnableKeyboard(false)
        if CC.GameAudio and CC.GameAudio.StopMusic then CC.GameAudio:StopMusic() end
    end)
    frame:SetScript("OnKeyDown", function(_, key)
        key = upper(tostring(key or ""))
        if key == "ESCAPE" then
            local activeView = Solo.activeGame and Solo.views[Solo.activeGame]
            if activeView and activeView.CloseOverlay and activeView:CloseOverlay() then return end
            if Solo.activeGame then Solo:ShowHub() else frame:Hide() end
            return
        end
        local view = Solo.activeGame and Solo.views[Solo.activeGame]
        if view and CC.GameAudio and CC.GameAudio.PlayInteraction then
            local cards = Solo.activeGame == "HOLDEM" or Solo.activeGame == "BLACKJACK" or Solo.activeGame == "HIGHERLOWER"
            CC.GameAudio:PlayInteraction(cards and "CARD" or "MOVE")
        end
        if view and view.OnKeyDown then view:OnKeyDown(key) end
    end)
    frame:SetScript("OnKeyUp", function(_, key)
        local view = Solo.activeGame and Solo.views[Solo.activeGame]
        if view and view.OnKeyUp then view:OnKeyUp(upper(tostring(key or ""))) end
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        local view = Solo.activeGame and Solo.views[Solo.activeGame]
        if view and view.OnUpdate then view:OnUpdate(elapsed or 0) end
    end)
    return frame
end

function Solo:GetCatalog()
    local colors = palette()
    return {
        { key="FROGGER", title="FROGGER · ENDLESS", shortTitle="Frogger", desc="Endless RNG levels that begin gently and grow faster.\nWASD / arrows or on-screen direction pad.", accent=colors.green, art="F  ⇧", icon=EIGHTBIT_GAME_ICON_ROOT .. "Frogger.tga" },
        { key="DUNGEON", title="DUNGEON DWELLER · ENDLESS", shortTitle="Dungeon Dweller", desc="Uncapped dice combat with up to two attacking minions.\nBoss every 10 levels; earn crates, armour and permanent relics.", accent=colors.red, art="D20", icon=EIGHTBIT_GAME_ICON_ROOT .. "Dungeon.tga" },
        { key="CHESS", title="SOLO CHESS · LEVELS 1–5", shortTitle="Solo Chess", desc="Play White against a computer opponent.\nLegal chess rules and five search strengths.", accent=colors.accent, art="WK  BK", icon=EIGHTBIT_GAME_ICON_ROOT .. "Chess.tga" },
        { key="TETRIS", title="TETRIS · THREE MODES", shortTitle="Tetris", desc="Timed Endless, VS Computer and Endless Attack.\n50 block themes, 50 image backgrounds and a 1,000-level speed curve.", accent={0.62,0.32,0.90,1}, art="▦", icon=EIGHTBIT_GAME_ICON_ROOT .. "Tetris.tga" },
        { key="HOLDEM", title="TEXAS HOLD'EM", shortTitle="Texas Hold'em", desc="Heads-up poker against a computer player.\nSaved bankroll, live hand strength and odds.", accent=colors.gold, art="AS  KH", icon=EIGHTBIT_GAME_ICON_ROOT .. "Holdem.tga" },
        { key="BLACKJACK", title="BLACKJACK · 21", shortTitle="Blackjack", desc="Play against the dealer. Hit, stand or double.\nSaved bank; Blackjack pays 3:2.", accent=colors.accent, art="21", icon=EIGHTBIT_GAME_ICON_ROOT .. "Blackjack.tga" },
        { key="HIGHERLOWER", title="HIGHER OR LOWER", shortTitle="Higher or Lower", desc="Guess whether the next card is higher or lower.\nSaved bank, streaks and probability hints.", accent=colors.green, art="H/L", icon=EIGHTBIT_GAME_ICON_ROOT .. "HigherLower.tga" },
    }
end

function Solo:BuildHub()
    if self.hub then return self.hub end
    local frame = self:BuildWindow()
    local colors = palette()
    local hub = CreateFrame("Frame", nil, frame.content, templateName())
    hub:SetAllPoints()
    applyBackdrop(hub, colors.panelSoft, colors.panelSoft)
    hub:Hide()
    self.hub = hub

    hub.banner = cardFrame(hub, 710, 72)
    hub.banner:SetPoint("TOPLEFT", hub, "TOPLEFT", 12, -12)
    hub.banner:SetPoint("TOPRIGHT", hub, "TOPRIGHT", -12, -12)
    applyBackdrop(hub.banner, darken(colors.accent, 0.30), colors.accent)
    hub.title = createText(hub.banner, 18, colors.text, "LEFT")
    hub.title:SetPoint("TOPLEFT", hub.banner, "TOPLEFT", 16, -12)
    hub.title:SetText("SINGLE-PLAYER ARCADE")
    hub.subtitle = createText(hub.banner, 10, colors.muted, "LEFT")
    hub.subtitle:SetPoint("TOPLEFT", hub.title, "BOTTOMLEFT", 0, -5)
    hub.subtitle:SetText("Seven solo games. Game levels, records, leaderboards and bankrolls are saved.")
    hub.historyButton = createButton(hub.banner, "HISTORY", 74, 26, function() Solo:OpenHistory() end)
    hub.historyButton:SetPoint("TOPRIGHT", hub.banner, "TOPRIGHT", -12, -10)
    setButtonAccent(hub.historyButton, colors.muted)
    hub.leaderButton = createButton(hub.banner, "LEADERS", 74, 26, function() Solo:OpenLeaderboard() end)
    hub.leaderButton:SetPoint("RIGHT", hub.historyButton, "LEFT", -6, 0)
    setButtonAccent(hub.leaderButton, colors.gold)

    hub.cards = {}
    for index, info in ipairs(self:GetCatalog()) do
        local column = (index - 1) % 4
        local row = floor((index - 1) / 4)
        local card = cardFrame(hub, 172, 220)
        card:SetPoint("TOPLEFT", hub, "TOPLEFT", 12 + column * 180, -96 - row * 230)
        card.title = createText(card, 12, colors.text, "LEFT")
        card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
        card.title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -56, -10)
        card.title:SetText(info.shortTitle or info.title)
        card.art = CreateFrame("Frame", nil, card, templateName())
        card.art:SetPoint("TOPRIGHT", card, "TOPRIGHT", -9, -9)
        card.art:SetSize(46, 46)
        applyBackdrop(card.art, darken(info.accent, 0.42), info.accent)
        card.artTexture = card.art:CreateTexture(nil, "ARTWORK")
        card.artTexture:SetPoint("TOPLEFT", card.art, "TOPLEFT", 1, -1)
        card.artTexture:SetPoint("BOTTOMRIGHT", card.art, "BOTTOMRIGHT", -1, 1)
        card.artText = createText(card.art, info.key == "FROGGER" and 17 or 13, info.accent, "CENTER")
        card.artText:SetAllPoints()
        if info.icon then
            card.artTexture:SetTexture(info.icon)
            card.artTexture:Show()
            card.artText:Hide()
        else
            card.artText:SetText(info.art)
            card.artText:Show()
        end
        card.desc = createText(card, 10, colors.muted, "LEFT")
        card.desc:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -62)
        card.desc:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -62)
        card.desc:SetHeight(52)
        card.desc:SetWordWrap(true)
        card.desc:SetText(info.desc)
        card.stats = createText(card, 9, colors.muted, "LEFT")
        card.stats:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -120)
        card.stats:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -120)
        card.stats:SetHeight(36)
        card.levelBar = CreateFrame("StatusBar", nil, card)
        card.levelBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        card.levelBar:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 10, 14)
        card.levelBar:SetSize(82, 10)
        card.levelBar:SetMinMaxValues(0, 1)
        card.levelBar:SetValue(0)
        card.levelBar:SetStatusBarColor(info.accent[1], info.accent[2], info.accent[3], 0.95)
        card.levelText = createText(card.levelBar, 7, colors.text, "CENTER")
        card.levelText:SetAllPoints()
        card.play = createButton(card, "PLAY", 64, 27, function() Solo:StartGame(info.key) end)
        card.play:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -10, 8)
        setButtonAccent(card.play, info.accent)
        hub.cards[info.key] = card
    end

    hub.footer = createText(hub, 9, colors.muted, "CENTER")
    hub.footer:SetPoint("BOTTOMLEFT", hub, "BOTTOMLEFT", 12, 9)
    hub.footer:SetPoint("BOTTOMRIGHT", hub, "BOTTOMRIGHT", -12, 9)
    hub.footer:SetText("Escape returns here. Scores shared by addon-ready players appear in Leaders; recent results appear in History.")
    return hub
end


function Solo:BuildSocialPanel()
    if self.socialPanel then return self.socialPanel end
    local hub = self:BuildHub()
    local colors = palette()
    local panel = CreateFrame("Frame", nil, hub, templateName())
    panel:SetPoint("TOPLEFT", hub.banner, "BOTTOMLEFT", 0, -8)
    panel:SetPoint("BOTTOMRIGHT", hub, "BOTTOMRIGHT", -12, 12)
    panel:SetFrameLevel((hub:GetFrameLevel() or 1) + 20)
    applyBackdrop(panel, colors.panel, colors.border)
    panel:Hide()
    panel.mode = "LEADERBOARD"
    panel.game = "FROGGER"
    self.socialPanel = panel

    panel.title = createText(panel, 15, colors.text, "LEFT")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
    panel.title:SetText("SOLO LEADERBOARDS")
    panel.subtitle = createText(panel, 9, colors.muted, "LEFT")
    panel.subtitle:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -4)
    panel.subtitle:SetText("Scores discovered from players running a compatible CreshChat build.")
    panel.close = createButton(panel, "CLOSE", 62, 24, function() panel:Hide() end)
    panel.close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
    setButtonAccent(panel.close, colors.red)

    panel.summary = {}
    local summaryData = { {"W", "WINS", colors.green}, {"L", "LOSSES", colors.red}, {"D", "DRAWS", colors.gold} }
    for i, data in ipairs(summaryData) do
        local box = cardFrame(panel, 100, 40)
        box:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -84 - ((3 - i) * 106), -10)
        applyBackdrop(box, colors.panelSoft, colors.border)
        box.value = createText(box, 13, data[3], "CENTER")
        box.value:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -5)
        box.value:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -5)
        box.label = createText(box, 7, colors.muted, "CENTER")
        box.label:SetPoint("TOPLEFT", box.value, "BOTTOMLEFT", 0, -1)
        box.label:SetPoint("TOPRIGHT", box.value, "BOTTOMRIGHT", 0, -1)
        box.label:SetText(data[2])
        panel.summary[data[1]] = box
    end

    panel.filters = {}
    local filterGames = { "FROGGER", "DUNGEON", "CHESS", "TETRIS", "HOLDEM", "BLACKJACK", "HIGHERLOWER" }
    local filterNames = { "FROG", "DUNGEON", "CHESS", "TETRIS", "HOLDEM", "21", "HIGH/LOW" }
    local previous
    for i, game in ipairs(filterGames) do
        local button = createButton(panel, filterNames[i], i == 7 and 78 or 64, 24, function()
            panel.game = game
            Solo:RefreshSocialPanel()
        end)
        if previous then
            button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        else
            button:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -64)
        end
        panel.filters[game] = button
        previous = button
    end

    panel.columnHeader = cardFrame(panel, 100, 24)
    panel.columnHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -96)
    panel.columnHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -96)
    applyBackdrop(panel.columnHeader, colors.panelRaised, colors.border)
    panel.rankHeader = createText(panel.columnHeader, 8, colors.muted, "LEFT")
    panel.rankHeader:SetPoint("LEFT", panel.columnHeader, "LEFT", 10, 0)
    panel.rankHeader:SetText("RANK")
    panel.nameHeader = createText(panel.columnHeader, 8, colors.muted, "LEFT")
    panel.nameHeader:SetPoint("LEFT", panel.columnHeader, "LEFT", 60, 0)
    panel.nameHeader:SetText("PLAYER")
    panel.scoreHeader = createText(panel.columnHeader, 8, colors.muted, "RIGHT")
    panel.scoreHeader:SetPoint("RIGHT", panel.columnHeader, "RIGHT", -10, 0)
    panel.scoreHeader:SetText("SCORE")

    panel.rows = {}
    for index = 1, 10 do
        local row = cardFrame(panel, 100, 36)
        row:SetPoint("TOPLEFT", panel.columnHeader, "BOTTOMLEFT", 0, -5 - ((index - 1) * 40))
        row:SetPoint("TOPRIGHT", panel.columnHeader, "BOTTOMRIGHT", 0, -5 - ((index - 1) * 40))
        applyBackdrop(row, colors.panelSoft, colors.border)
        row.rank = createText(row, 10, colors.gold, "CENTER")
        row.rank:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.rank:SetWidth(38)
        row.main = createText(row, 10, colors.text, "LEFT")
        row.main:SetPoint("TOPLEFT", row, "TOPLEFT", 53, -5)
        row.main:SetPoint("TOPRIGHT", row, "TOPRIGHT", -110, -5)
        row.detail = createText(row, 8, colors.muted, "LEFT")
        row.detail:SetPoint("TOPLEFT", row.main, "BOTTOMLEFT", 0, -2)
        row.detail:SetPoint("TOPRIGHT", row.main, "BOTTOMRIGHT", 0, -2)
        row.score = createText(row, 11, colors.text, "RIGHT")
        row.score:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.score:SetWidth(95)
        panel.rows[index] = row
    end
    return panel
end

function Solo:RefreshSocialPanel()
    local panel = self:BuildSocialPanel()
    local colors = palette()
    local history = self:GetHistory()
    local wins, losses, draws = 0, 0, 0
    for _, entry in ipairs(history) do
        if entry.result == "WIN" then wins = wins + 1
        elseif entry.result == "LOSS" then losses = losses + 1
        elseif entry.result == "DRAW" then draws = draws + 1 end
    end
    panel.summary.W.value:SetText(tostring(wins))
    panel.summary.L.value:SetText(tostring(losses))
    panel.summary.D.value:SetText(tostring(draws))

    local leaderboardMode = panel.mode == "LEADERBOARD"
    panel.title:SetText(leaderboardMode and "SOLO LEADERBOARDS" or "GAME HISTORY")
    panel.subtitle:SetText(leaderboardMode and "Scores update when compatible CreshChat players are discovered or scanned." or "Recent solo and multiplayer outcomes. Run records are kept without counting as wins or losses.")
    panel.rankHeader:SetText(leaderboardMode and "RANK" or "RESULT")
    panel.nameHeader:SetText(leaderboardMode and "PLAYER" or "GAME / OPPONENT")
    panel.scoreHeader:SetText(leaderboardMode and upper(self:GetLeaderboardMetric(panel.game)) or "WHEN")
    for game, button in pairs(panel.filters) do
        if leaderboardMode then
            button:Show()
            setButtonAccent(button, game == panel.game and colors.gold or colors.accent)
        else
            button:Hide()
        end
    end
    if leaderboardMode then
        panel.columnHeader:ClearAllPoints()
        panel.columnHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -96)
        panel.columnHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -96)
        local rows = self:GetLeaderboard(panel.game)
        for index, row in ipairs(panel.rows) do
            local entry = rows[index]
            if entry then
                row:Show()
                row.rank:SetText(index == 1 and "#1" or tostring(index))
                row.rank:SetTextColor(index == 1 and colors.gold[1] or colors.muted[1], index == 1 and colors.gold[2] or colors.muted[2], index == 1 and colors.gold[3] or colors.muted[3], 1)
                row.main:SetText(entry.name .. (entry.localPlayer and "  · YOU" or ""))
                row.detail:SetText(entry.localPlayer and "Local score" or "Discovered addon player")
                row.score:SetText(formatChips(entry.score))
                applyBackdrop(row, entry.localPlayer and darken(colors.accent, 0.48) or colors.panelSoft, entry.localPlayer and colors.accent or colors.border)
            else
                row:Hide()
            end
        end
    else
        panel.columnHeader:ClearAllPoints()
        panel.columnHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -64)
        panel.columnHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -14, -64)
        for index, row in ipairs(panel.rows) do
            local entry = history[index]
            if entry then
                row:Show()
                local result = tostring(entry.result or "DRAW")
                row.rank:SetText(result == "RUN" and "RUN" or string.sub(result, 1, 1))
                local resultColor = result == "WIN" and colors.green or (result == "LOSS" and colors.red or (result == "DRAW" and colors.gold or colors.accent))
                row.rank:SetTextColor(resultColor[1], resultColor[2], resultColor[3], 1)
                local gameName = SOLO_GAME_LABELS[entry.game] or tostring(entry.game or "Game")
                local modeText = entry.mode == "MULTI" and "Multiplayer" or "Solo"
                row.main:SetText(gameName .. " · " .. modeText .. " · " .. tostring(entry.opponent or ""))
                row.detail:SetText(tostring(entry.detail or ""))
                local dateText = "Recent"
                if type(_G.date) == "function" and tonumber(entry.timestamp) then dateText = _G.date("%d/%m %H:%M", entry.timestamp) end
                row.score:SetText(dateText)
                applyBackdrop(row, darken(resultColor, 0.72), resultColor)
            else
                row:Hide()
            end
        end
    end
end

function Solo:ShowSocialPanel(mode)
    self:ShowHub()
    local panel = self:BuildSocialPanel()
    panel.mode = upper(tostring(mode or "LEADERBOARD"))
    if panel.mode ~= "HISTORY" then panel.mode = "LEADERBOARD" end
    self:RefreshSocialPanel()
    panel:Show()
    self:SetStatus(panel.mode == "HISTORY" and "Recent game history." or "Shared scores from compatible addon players.", palette().muted)
end

function Solo:OpenLeaderboard()
    self:ShowSocialPanel("LEADERBOARD")
end

function Solo:OpenHistory()
    self:ShowSocialPanel("HISTORY")
end

function Solo:RefreshHub()
    local hub = self:BuildHub()
    local save = ensureSave()
    if not save then return end
    hub.cards.FROGGER.stats:SetText(format("Current endless level: %d   Best: %d\nHigh score: %d", save.frogger.unlocked or 1, save.frogger.bestLevel or 0, save.frogger.highScore or 0))
    local dungeonPassLevel = CC.DungeonDwellersPass and CC.DungeonDwellersPass.GetProgress and CC.DungeonDwellersPass:GetProgress() or 1
    hub.cards.DUNGEON.stats:SetText(format("Best room: %d   Bosses: %d\nKills: %d · Boss coins: %d · Pass L%d", save.dungeon.bestRoom or save.dungeon.bestLevel or 0, save.dungeon.bosses or 0, save.dungeon.kills or 0, save.dungeon.bossCoins or 0, dungeonPassLevel or 1))
    hub.cards.CHESS.stats:SetText(format("Wins: %d   Losses: %d   Draws: %d\nBest win: Level %d", save.chess.wins or 0, save.chess.losses or 0, save.chess.draws or 0, save.chess.bestLevel or 0))
    hub.cards.HOLDEM.stats:SetText(format("Wins: %d   Losses: %d\nBankroll: %s", save.holdem.wins or 0, save.holdem.losses or 0, formatChips(save.holdem.bankroll or 100)))
    hub.cards.BLACKJACK.stats:SetText(format("Wins: %d   Losses: %d   Pushes: %d\nBank: %s", save.blackjack.wins or 0, save.blackjack.losses or 0, save.blackjack.pushes or 0, formatChips(save.blackjack.bankroll or 100)))
    hub.cards.HIGHERLOWER.stats:SetText(format("Wins: %d   Losses: %d   Draws: %d\nBank: %s · Best streak: %d", save.higherlower.wins or 0, save.higherlower.losses or 0, save.higherlower.draws or 0, formatChips(save.higherlower.bankroll or 100), save.higherlower.bestStreak or 0))
    do
        local passLevel = CC.Tetris and select(1, CC.Tetris:GetPassProgress()) or 1
        local unlocked = CC.Tetris and CC.Tetris:GetUnlockedCount() or 1
        local themeTotal = CC.Tetris and CC.Tetris:GetThemeCount() or 100
        local backgroundTotal = CC.Tetris and CC.Tetris:GetBackgroundThemeCount() or 70
        hub.cards.TETRIS.stats:SetText(format("Wins: %d · VS wins: %d · Endless: %d\nPass Lv %d · Themes %d/%d · Backgrounds %d · High %d", save.tetris.wins or 0, save.tetris.vsWins or 0, save.tetris.endlessRuns or 0, passLevel, unlocked, themeTotal, backgroundTotal, save.tetris.highScore or 0))
    end
    if CC.GameProgression then
        for key, card in pairs(hub.cards or {}) do CC.GameProgression:UpdateBar(card.levelBar, card.levelText, key) end
    end
    self:UpdateLocalLeaderboard()
end

function Solo:ShowHub()
    local frame = self:BuildWindow()
    self:HideViews()
    self.activeGame = nil
    if CC.GameAudio and CC.GameAudio.StopMusic then CC.GameAudio:StopMusic() end
    self:RefreshHub()
    self.hub:Show()
    if self.socialPanel then self.socialPanel:Hide() end
    frame.title:SetText("CRESH SOLO ARCADE")
    frame.subtitle:SetText("Single-player games · WASD / arrows · mouse controls")
    self:SetStatus("Choose Frogger, Dungeon Dweller, Chess, Tetris, Hold'em, Blackjack or Higher or Lower.", palette().muted)
    frame:Show()
end

function Solo:OpenHub()
    if not CC:IsFeatureEnabled("games") then return end
    self:ShowHub()
end

function Solo:StartGame(game)
    if not CC:IsFeatureEnabled("games") then return false end
    game = upper(tostring(game or ""))
    local builder = self["Build" .. game .. "View"]
    if not builder then return false end
    local frame = self:BuildWindow()
    if CC.UI and CC.UI.CloseGameDrawer then CC.UI:CloseGameDrawer(true) end
    self:HideViews()
    builder(self)
    local view = self.views[game]
    self.activeGame = game
    if CC.GameProgression and CC.GameProgression.OnGameStarted then CC.GameProgression:OnGameStarted(game, "SOLO") end
    if CC.GameAudio and CC.GameAudio.PlayMusic then CC.GameAudio:PlayMusic(game) end
    local titles = { FROGGER = "FROGGER · ENDLESS", DUNGEON = "DUNGEON DWELLER · ENDLESS", CHESS = "SOLO CHESS · LEVELS 1–5", TETRIS = "TETRIS · MODES, THEMES & PASS", HOLDEM = "TEXAS HOLD'EM · SOLO", BLACKJACK = "BLACKJACK · SOLO", HIGHERLOWER = "HIGHER OR LOWER · SOLO" }
    local subtitles = { FROGGER = "WASD / arrows to hop · P to pause · R to restart", DUNGEON = "Choose a class · A/D target · Space attacks · boss every 10 levels", CHESS = "Mouse or WASD · Space selects · keys 1–5 set enemy strength", TETRIS = "Timed Endless · VS CPU · 50 image backgrounds · 1,000 speed levels", HOLDEM = "A/D or arrows select · Space/Enter confirms · mouse buttons supported", BLACKJACK = "A/D or arrows select · Space/Enter confirms · mouse buttons supported", HIGHERLOWER = "A/D chooses Higher or Lower · W/S changes bet · Space confirms" }
    frame.title:SetText(titles[game] or game)
    frame.subtitle:SetText(subtitles[game] or "WASD / arrows and mouse controls")
    if view and view.frame then view.frame:Show() end
    if view and view.Start then view:Start() end
    if CC.GameAudio and (game == "HOLDEM" or game == "BLACKJACK" or game == "HIGHERLOWER") then CC.GameAudio:PlayEffect("CARD") end
    if CC.GameProgression then CC.GameProgression:UpdateBar(frame.levelProgress, frame.levelText, game) end
    frame:Show()
    return true
end

function Solo:OpenDungeonDwellers(mode)
    if not CC:IsFeatureEnabled("games") then return false end
    local frame = self:BuildWindow()
    if CC.UI and CC.UI.CloseGameDrawer then CC.UI:CloseGameDrawer(true) end
    self:HideViews()
    self:BuildDUNGEONView()
    local view = self.views.DUNGEON
    self.activeGame = "DUNGEON"
    frame.title:SetText("DUNGEON DWELLER · COLLECTION")
    frame.subtitle:SetText("Collection · lifetime statistics · Dungeon Dwellers Battle Pass")
    if view and view.frame then view.frame:Show() end
    if view and not view.rng and view.StartRun then view:StartRun() end
    frame:Show()
    if view and view.ShowDwellersPanel then view:ShowDwellersPanel(mode or "PASS") end
    return view ~= nil
end

function Solo:AttachHub(hub)
    if not hub or hub.soloGames then return end
    local colors = palette()
    hub.soloGames = createButton(hub.banner, "SOLO", 58, 26, function() Solo:OpenHub() end)
    hub.soloGames:SetPoint("RIGHT", hub.scan, "LEFT", -6, 0)
    setButtonAccent(hub.soloGames, colors.green)
end

if CC.Games and CC.Games.BuildHub then
    local originalBuildHub = CC.Games.BuildHub
    CC.Games.BuildHub = function(games, parent)
        local hub = originalBuildHub(games, parent)
        Solo:AttachHub(hub)
        return hub
    end
end

-- FROGGER ---------------------------------------------------------------------
local FROG_ROWS = 12
local FROG_COLUMNS = 13
local FROG_ROW_HEIGHT = 40
local FROG_CELL_WIDTH = 48
local FROG_BOARD_WIDTH = FROG_COLUMNS * FROG_CELL_WIDTH
local FROG_BOARD_HEIGHT = FROG_ROWS * FROG_ROW_HEIGHT

local function frogLevel(level)
    level = floor(max(1, tonumber(level) or 1))
    local step = level - 1
    return {
        level = level,
        -- Level one is deliberately calm. Difficulty rises in small increments
        -- and then continues forever without making the board mathematically full.
        time = max(32, 62 - floor(step * 0.45)),
        roadSpeed = min(118, 24 + step * 2.10),
        riverSpeed = min(84, 17 + step * 1.35),
        roadCount = min(6, 1 + floor(step / 4)),
        riverCount = min(5, 2 + floor(step / 7)),
        longVehicleChance = min(58, 9 + floor(step * 1.25)),
    }
end
function Solo:BuildFROGGERView()
    if self.views.FROGGER then return self.views.FROGGER end
    local colors = palette()
    local view = { game = "FROGGER", objects = {}, objectFrames = {}, keyLock = {}, level = 1 }
    local frame = CreateFrame("Frame", nil, self.window.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.info = CreateFrame("Frame", nil, frame, templateName())
    view.info:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
    view.info:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -6)
    view.info:SetHeight(30)
    applyBackdrop(view.info, colors.panel, colors.border)
    view.levelText = createText(view.info, 11, colors.text, "LEFT")
    view.levelText:SetPoint("LEFT", view.info, "LEFT", 10, 0)
    view.scoreText = createText(view.info, 11, colors.gold, "CENTER")
    view.scoreText:SetPoint("CENTER", view.info, "CENTER", 0, 0)
    view.livesText = createText(view.info, 11, colors.green, "RIGHT")
    view.livesText:SetPoint("RIGHT", view.info, "RIGHT", -10, 0)

    view.board = CreateFrame("Button", nil, frame, templateName())
    view.board:SetSize(FROG_BOARD_WIDTH, FROG_BOARD_HEIGHT)
    view.board:SetPoint("TOP", view.info, "BOTTOM", 0, -7)
    applyBackdrop(view.board, colors.panel, colors.border)
    view.board:RegisterForClicks("LeftButtonUp")
    view.board:SetScript("OnClick", function(_, mouseButton)
        if mouseButton ~= "LeftButton" or view.paused or view.gameOver or view.levelComplete then return end
        -- Board clicks intentionally move forward one lane; the on-screen pad handles exact directions.
        view:Move(0, 1)
    end)

    view.rows = {}
    for row = 0, FROG_ROWS - 1 do
        local lane = CreateFrame("Frame", nil, view.board, templateName())
        lane:SetPoint("BOTTOMLEFT", view.board, "BOTTOMLEFT", 0, row * FROG_ROW_HEIGHT)
        lane:SetPoint("BOTTOMRIGHT", view.board, "BOTTOMRIGHT", 0, row * FROG_ROW_HEIGHT)
        lane:SetHeight(FROG_ROW_HEIGHT)
        local background
        if row == 0 or row == 6 then background = { 0.03, 0.22, 0.08, 1 }
        elseif row >= 1 and row <= 5 then background = colors.road
        elseif row >= 7 and row <= 10 then background = colors.water
        else background = { 0.04, 0.28, 0.10, 1 } end
        applyBackdrop(lane, background, row == 6 and colors.green or darken(background, 0.01))
        lane.label = createText(lane, 8, {0.55,0.62,0.68,0.45}, "LEFT")
        lane.label:SetPoint("LEFT", lane, "LEFT", 4, 0)
        lane.label:SetText(row == 0 and "START" or (row == 6 and "SAFE" or (row == 11 and "GOAL" or "")))
        view.rows[row] = lane
    end

    for index = 1, 56 do
        local object = CreateFrame("Frame", nil, view.board, templateName())
        object:SetSize(48, 28)
        applyBackdrop(object, colors.panelRaised, colors.border)
        object.text = createText(object, 9, colors.text, "CENTER")
        object.text:SetAllPoints()
        object:Hide()
        view.objectFrames[index] = object
    end

    view.frog = CreateFrame("Frame", nil, view.board, templateName())
    view.frog:SetSize(30, 28)
    applyBackdrop(view.frog, {0.15,0.82,0.28,1}, {0.65,1.0,0.72,1})
    view.frog.text = createText(view.frog, 13, {0.01,0.10,0.02,1}, "CENTER")
    view.frog.text:SetAllPoints()
    view.frog.text:SetText("F")

    view.pauseOverlay = CreateFrame("Frame", nil, view.board, templateName())
    view.pauseOverlay:SetAllPoints()
    applyBackdrop(view.pauseOverlay, {0,0,0,0.72}, colors.accent)
    view.pauseOverlay.text = createText(view.pauseOverlay, 28, colors.text, "CENTER")
    view.pauseOverlay.text:SetAllPoints()
    view.pauseOverlay.text:SetText("PAUSED\nPress P to continue")
    view.pauseOverlay:Hide()

    view.controls = CreateFrame("Frame", nil, frame, templateName())
    view.controls:SetPoint("TOPLEFT", view.board, "BOTTOMLEFT", 0, -7)
    view.controls:SetPoint("TOPRIGHT", view.board, "BOTTOMRIGHT", 0, -7)
    view.controls:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    applyBackdrop(view.controls, colors.panel, colors.border)

    view.left = createButton(view.controls, "◀ / A", 74, 30, function() view:Move(-1, 0) end)
    view.left:SetPoint("LEFT", view.controls, "LEFT", 12, 0)
    view.up = createButton(view.controls, "▲ / W", 74, 30, function() view:Move(0, 1) end)
    view.up:SetPoint("LEFT", view.left, "RIGHT", 6, 0)
    view.down = createButton(view.controls, "▼ / S", 74, 30, function() view:Move(0, -1) end)
    view.down:SetPoint("LEFT", view.up, "RIGHT", 6, 0)
    view.right = createButton(view.controls, "▶ / D", 74, 30, function() view:Move(1, 0) end)
    view.right:SetPoint("LEFT", view.down, "RIGHT", 6, 0)
    view.levelDown = createButton(view.controls, "LV -", 58, 30, function() view:ChangeLevel(-1) end)
    view.levelDown:SetPoint("LEFT", view.right, "RIGHT", 12, 0)
    view.levelUp = createButton(view.controls, "LV +", 58, 30, function() view:ChangeLevel(1) end)
    view.levelUp:SetPoint("LEFT", view.levelDown, "RIGHT", 6, 0)
    view.pause = createButton(view.controls, "PAUSE", 74, 30, function() view:TogglePause() end)
    view.pause:SetPoint("RIGHT", view.controls, "RIGHT", -96, 0)
    view.restart = createButton(view.controls, "RESTART", 80, 30, function() view:RestartLevel() end)
    view.restart:SetPoint("RIGHT", view.controls, "RIGHT", -10, 0)
    for _, button in ipairs({view.left, view.up, view.down, view.right, view.levelDown, view.levelUp, view.pause, view.restart}) do setButtonAccent(button, colors.green) end

    function view:ClearObjects()
        self.objects = {}
        for _, objectFrame in ipairs(self.objectFrames) do objectFrame:Hide() end
    end

    function view:AddObject(kind, lane, x, width, speed, label)
        local index = #self.objects + 1
        local objectFrame = self.objectFrames[index]
        if not objectFrame then return end
        local object = { kind=kind, lane=lane, x=x, width=width, speed=speed, frame=objectFrame }
        self.objects[index] = object
        objectFrame:SetSize(width, FROG_ROW_HEIGHT - 10)
        objectFrame.text:SetText(label or (kind == "ROAD" and "CAR" or "LOG"))
        if kind == "ROAD" then
            local c = lane % 2 == 0 and {0.78,0.18,0.15,1} or {0.92,0.60,0.08,1}
            applyBackdrop(objectFrame, c, brighten(c, 0.10))
        else
            local c = lane % 2 == 0 and {0.34,0.20,0.08,1} or {0.24,0.38,0.14,1}
            applyBackdrop(objectFrame, c, brighten(c, 0.10))
        end
        objectFrame:Show()
    end

    function view:BuildLevel(level)
        self:ClearObjects()
        local cfg = frogLevel(level)
        self.config = cfg
        local seed = (self.runSeed or 7000) + level * 379 + floor((level - 1) / 5) * 997
        local rng = makeRng(seed)
        for lane = 1, 5 do
            local direction = ((lane + level) % 2 == 0) and 1 or -1
            local bonus = (level > 2 and ((lane + level) % 3 == 0)) and 1 or 0
            local count = min(6, cfg.roadCount + bonus)
            local vehicleCells = rng:Next(100) <= cfg.longVehicleChance and 1.80 or 1.10
            local width = floor(vehicleCells * FROG_CELL_WIDTH)
            local speed = direction * (cfg.roadSpeed + lane * 2.4 + rng:Next(7) - 1)
            local spacing = (FROG_BOARD_WIDTH + width * 2.5) / count
            for slot = 1, count do
                local x = (slot - 1) * spacing - width + rng:Next(max(1, floor(spacing * 0.14)))
                self:AddObject("ROAD", lane, x, width, speed, vehicleCells > 1.5 and "TRUCK" or "CAR")
            end
        end
        for lane = 7, 10 do
            local direction = ((lane + level) % 2 == 0) and 1 or -1
            local count = min(5, cfg.riverCount + ((level > 6 and (lane + level) % 4 == 0) and 1 or 0))
            local width = (2.65 + ((lane + level) % 2) * 0.75) * FROG_CELL_WIDTH
            local speed = direction * (cfg.riverSpeed + (lane - 6) * 2.5 + rng:Next(6) - 1)
            local spacing = (FROG_BOARD_WIDTH + width * 1.2) / count
            for slot = 1, count do
                local x = (slot - 1) * spacing - width * 0.45 + rng:Next(max(1, floor(spacing * 0.10)))
                self:AddObject("RIVER", lane, x, width, speed, (lane + slot + level) % 3 == 0 and "TURTLES" or "LOG")
            end
        end
    end
    function view:ResetFrog()
        self.playerX = FROG_BOARD_WIDTH / 2
        self.playerRow = 0
        self.highestRow = 0
        self.invulnerable = 0.85
        self.moveGrace = 0
        self:RefreshFrog()
    end

    function view:RefreshFrog()
        local x = clamp(self.playerX or FROG_BOARD_WIDTH / 2, 15, FROG_BOARD_WIDTH - 15)
        self.playerX = x
        self.frog:ClearAllPoints()
        self.frog:SetPoint("BOTTOMLEFT", self.board, "BOTTOMLEFT", x - 15, (self.playerRow or 0) * FROG_ROW_HEIGHT + 6)
    end

    function view:RefreshObjects()
        for _, object in ipairs(self.objects) do
            object.frame:ClearAllPoints()
            object.frame:SetPoint("BOTTOMLEFT", self.board, "BOTTOMLEFT", object.x, object.lane * FROG_ROW_HEIGHT + 5)
        end
    end

    function view:RefreshInfo()
        self.levelText:SetText(format("LEVEL %d · ENDLESS   TIME %02d", self.level or 1, max(0, floor((self.timeLeft or 0) + 0.99))))
        self.scoreText:SetText(format("SCORE %d", self.score or 0))
        self.livesText:SetText(format("LIVES %d", self.lives or 0))
        local save = ensureSave()
        local unlocked = save and save.frogger.unlocked or 1
        setButtonEnabled(self.levelDown, (self.level or 1) > 1)
        setButtonEnabled(self.levelUp, (self.level or 1) < unlocked)
    end

    function view:ChangeLevel(direction)
        local save = ensureSave()
        local unlocked = save and save.frogger.unlocked or 1
        local target = max(1, min(unlocked, floor((self.level or 1) + (direction or 0))))
        if target ~= self.level then self:StartLevel(target, false) end
    end

    function view:Move(dx, dy)
        if self.paused or self.gameOver or self.levelComplete then return end
        local oldRow = self.playerRow
        self.playerX = clamp((self.playerX or 0) + dx * FROG_CELL_WIDTH, 15, FROG_BOARD_WIDTH - 15)
        self.playerRow = clamp((self.playerRow or 0) + dy, 0, FROG_ROWS - 1)
        if self.playerRow > (self.highestRow or 0) then
            self.score = (self.score or 0) + 100 * (self.playerRow - (self.highestRow or 0))
            self.highestRow = self.playerRow
        elseif self.playerRow < oldRow then
            self.score = max(0, (self.score or 0) - 10)
        end
        self.moveGrace = 0.10
        self:RefreshFrog()
        self:CheckImmediate()
        self:RefreshInfo()
    end

    function view:RoadOverlaps(object)
        -- The rendered frog is 30 px wide, but the collision body is only 14 px.
        -- Vehicles also receive an inner padding so borders never cause phantom hits.
        local half = 7
        local padding = min(9, max(4, object.width * 0.10))
        local left = (self.playerX or 0) - half
        local right = (self.playerX or 0) + half
        return right > object.x + padding and left < object.x + object.width - padding
    end

    function view:RiverSupports(object)
        -- River platforms are intentionally more forgiving than road hazards.
        local center = self.playerX or 0
        local padding = min(8, object.width * 0.08)
        return center >= object.x + padding and center <= object.x + object.width - padding
    end
    function view:CheckImmediate()
        if self.playerRow == 11 then self:CompleteLevel(); return end
        if (self.invulnerable and self.invulnerable > 0) or (self.moveGrace and self.moveGrace > 0) then return end
        if self.playerRow >= 1 and self.playerRow <= 5 then
            for _, object in ipairs(self.objects) do
                if object.kind == "ROAD" and object.lane == self.playerRow and self:RoadOverlaps(object) then
                    self:LoseLife("Traffic collision")
                    return
                end
            end
        elseif self.playerRow >= 7 and self.playerRow <= 10 then
            local platform
            for _, object in ipairs(self.objects) do
                if object.kind == "RIVER" and object.lane == self.playerRow and self:RiverSupports(object) then platform = object; break end
            end
            if not platform then self:LoseLife("Fell in the river") end
        end
    end

    function view:LoseLife(reason)
        if self.gameOver or self.levelComplete then return end
        self.lives = (self.lives or 1) - 1
        if self.lives <= 0 then
            self.gameOver = true
            self.paused = false
            self.pauseOverlay:Show()
            self.pauseOverlay.text:SetText("GAME OVER\nPress R to restart level")
            Solo:SetStatus((reason or "Missed") .. ". Game over on level " .. tostring(self.level) .. ".", colors.red)
            local save = ensureSave()
            if save then
                save.frogger.highScore = max(save.frogger.highScore or 0, self.score or 0)
                save.frogger.games = (save.frogger.games or 0) + 1
            end
            Solo:RecordHistory("FROGGER", "SOLO", "RUN", "Traffic", format("Reached level %d · score %d", self.level or 1, self.score or 0), self.score or 0)
            Solo:PushLeaderboards()
        else
            Solo:SetStatus((reason or "Missed") .. ". " .. self.lives .. " lives left.", colors.red)
            self.timeLeft = self.config.time
            self:ResetFrog()
        end
        self:RefreshInfo()
    end

    function view:CompleteLevel()
        if self.levelComplete or self.gameOver then return end
        self.levelComplete = true
        local bonus = 1000 + max(0, floor(self.timeLeft or 0)) * 20 + (self.lives or 0) * 100 + (self.level or 1) * 25
        self.score = (self.score or 0) + bonus
        local save = ensureSave()
        if save then
            save.frogger.bestLevel = max(save.frogger.bestLevel or 0, self.level)
            save.frogger.highScore = max(save.frogger.highScore or 0, self.score)
            save.frogger.unlocked = max(save.frogger.unlocked or 1, self.level + 1)
        end
        self.pauseOverlay:Show()
        self.pauseOverlay.text:SetText("LEVEL " .. tostring(self.level) .. " COMPLETE\nEndless level " .. tostring(self.level + 1) .. " starting...")
        Solo:SetStatus("Level " .. tostring(self.level) .. " complete. Endless bonus: " .. tostring(bonus), colors.green)
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then
            _G.C_Timer.After(0.85, function()
                if Solo.activeGame == "FROGGER" and view.levelComplete and not view.gameOver then view:StartLevel(view.level + 1, true) end
            end)
        else
            self:StartLevel(self.level + 1, true)
        end
        self:RefreshInfo()
    end
    function view:StartLevel(level, keepScore)
        level = floor(max(1, tonumber(level) or 1))
        self.level = level
        self.levelComplete = false
        self.gameOver = false
        self.paused = false
        self.pauseOverlay:Hide()
        self.pause.label:SetText("PAUSE")
        self.config = frogLevel(level)
        self.timeLeft = self.config.time
        if not keepScore then
            self.score = 0
            self.lives = 3
        else
            self.lives = min(5, (self.lives or 3) + (level % 7 == 0 and 1 or 0))
        end
        self:BuildLevel(level)
        self:ResetFrog()
        self:RefreshObjects()
        self:RefreshInfo()
        Solo:SetStatus("Endless Frogger level " .. level .. ": reach the goal before time runs out.", colors.green)
    end

    function view:RestartLevel()
        self:StartLevel(self.level or 1, false)
    end

    function view:TogglePause()
        if self.gameOver or self.levelComplete then return end
        self.paused = not self.paused
        self.pauseOverlay:SetShown(self.paused)
        if self.paused then self.pauseOverlay.text:SetText("PAUSED\nPress P to continue") end
        self.pause.label:SetText(self.paused and "RESUME" or "PAUSE")
        Solo:SetStatus(self.paused and "Frogger paused." or "Frogger resumed.", self.paused and colors.gold or colors.green)
    end

    function view:OnKeyDown(key)
        if key == "R" then self:RestartLevel(); return end
        if key == "P" or key == "SPACE" then self:TogglePause(); return end
        if key == "W" or key == "UP" then self:Move(0, 1)
        elseif key == "S" or key == "DOWN" then self:Move(0, -1)
        elseif key == "A" or key == "LEFT" then self:Move(-1, 0)
        elseif key == "D" or key == "RIGHT" then self:Move(1, 0) end
    end

    function view:OnUpdate(elapsed)
        if self.paused or self.gameOver or self.levelComplete then return end
        elapsed = min(0.08, tonumber(elapsed) or 0)
        self.timeLeft = (self.timeLeft or 0) - elapsed
        if self.invulnerable and self.invulnerable > 0 then self.invulnerable = max(0, self.invulnerable - elapsed) end
        if self.moveGrace and self.moveGrace > 0 then self.moveGrace = max(0, self.moveGrace - elapsed) end
        if self.timeLeft <= 0 then self:LoseLife("Time expired"); return end

        for _, object in ipairs(self.objects) do
            object.x = object.x + object.speed * elapsed
            if object.speed > 0 and object.x > FROG_BOARD_WIDTH + 12 then object.x = -object.width - 12 end
            if object.speed < 0 and object.x + object.width < -12 then object.x = FROG_BOARD_WIDTH + 12 end
        end

        if self.invulnerable <= 0 and (not self.moveGrace or self.moveGrace <= 0) and self.playerRow >= 7 and self.playerRow <= 10 then
            local platform
            for _, object in ipairs(self.objects) do
                if object.kind == "RIVER" and object.lane == self.playerRow and self:RiverSupports(object) then platform = object; break end
            end
            if platform then
                self.playerX = self.playerX + platform.speed * elapsed
                if self.playerX < 10 or self.playerX > FROG_BOARD_WIDTH - 10 then self:LoseLife("Drifted off the river"); return end
            else
                self:LoseLife("Fell in the river")
                return
            end
        elseif self.invulnerable <= 0 and (not self.moveGrace or self.moveGrace <= 0) and self.playerRow >= 1 and self.playerRow <= 5 then
            for _, object in ipairs(self.objects) do
                if object.kind == "ROAD" and object.lane == self.playerRow and self:RoadOverlaps(object) then self:LoseLife("Traffic collision"); return end
            end
        end
        self:RefreshObjects()
        self:RefreshFrog()
        self.infoElapsed = (self.infoElapsed or 0) + elapsed
        if self.infoElapsed >= 0.12 then self.infoElapsed = 0; self:RefreshInfo() end
    end

    function view:Start()
        local save = ensureSave()
        local level = save and save.frogger.unlocked or 1
        self.runSeed = floor(now() * 1000) + (save and (save.frogger.games or 0) * 7919 or 0) + 7000
        self:StartLevel(level, false)
    end

    self.views.FROGGER = view
    return view
end

-- SHARED CARD HELPERS ---------------------------------------------------------
local SUITS = { "S", "H", "D", "C" }
local RANK_LABELS = { [2]="2",[3]="3",[4]="4",[5]="5",[6]="6",[7]="7",[8]="8",[9]="9",[10]="T",[11]="J",[12]="Q",[13]="K",[14]="A" }
local HAND_NAMES = { [0]="High Card",[1]="One Pair",[2]="Two Pair",[3]="Three of a Kind",[4]="Straight",[5]="Flush",[6]="Full House",[7]="Four of a Kind",[8]="Straight Flush" }

local function cardRank(card) return ((tonumber(card) - 1) % 13) + 2 end
local function cardSuit(card) return floor((tonumber(card) - 1) / 13) + 1 end
local function cardLabel(card)
    card = tonumber(card)
    if not card or card < 1 or card > 52 then return "--" end
    return RANK_LABELS[cardRank(card)] .. SUITS[cardSuit(card)]
end

local function shuffledDeck(seed)
    local deck = {}
    for card = 1, 52 do deck[card] = card end
    local rng = makeRng(seed or floor(now() * 1000) + 41)
    for index = 52, 2, -1 do
        local swap = rng:Next(index)
        deck[index], deck[swap] = deck[swap], deck[index]
    end
    return deck, rng
end

local function evaluateFive(cards)
    local ranks, counts, suits = {}, {}, {}
    for _, card in ipairs(cards) do
        local rank, suit = cardRank(card), cardSuit(card)
        ranks[#ranks + 1] = rank
        counts[rank] = (counts[rank] or 0) + 1
        suits[suit] = (suits[suit] or 0) + 1
    end
    sort(ranks, function(a,b) return a>b end)
    local unique = {}
    for rank in pairs(counts) do unique[#unique + 1] = rank end
    sort(unique, function(a,b) return a>b end)
    local straightHigh
    local sequence = {}
    for _, rank in ipairs(unique) do sequence[rank] = true end
    if sequence[14] and sequence[5] and sequence[4] and sequence[3] and sequence[2] then straightHigh = 5 end
    for high = 14, 6, -1 do
        if sequence[high] and sequence[high-1] and sequence[high-2] and sequence[high-3] and sequence[high-4] then straightHigh = high; break end
    end
    local flush = false
    for _, count in pairs(suits) do if count == 5 then flush = true end end
    local groups = {}
    for rank, count in pairs(counts) do groups[#groups + 1] = { count=count, rank=rank } end
    sort(groups, function(a,b) if a.count ~= b.count then return a.count > b.count end return a.rank > b.rank end)
    if flush and straightHigh then return {8, straightHigh} end
    if groups[1].count == 4 then return {7, groups[1].rank, groups[2].rank} end
    if groups[1].count == 3 and groups[2].count == 2 then return {6, groups[1].rank, groups[2].rank} end
    if flush then return {5, unpack(ranks)} end
    if straightHigh then return {4, straightHigh} end
    if groups[1].count == 3 then
        local kickers = {}
        for _, group in ipairs(groups) do if group.count == 1 then kickers[#kickers+1] = group.rank end end
        sort(kickers, function(a,b) return a>b end)
        return {3, groups[1].rank, kickers[1], kickers[2]}
    end
    if groups[1].count == 2 and groups[2].count == 2 then
        local highPair, lowPair = max(groups[1].rank, groups[2].rank), min(groups[1].rank, groups[2].rank)
        local kicker
        for _, group in ipairs(groups) do if group.count == 1 then kicker = group.rank end end
        return {2, highPair, lowPair, kicker}
    end
    if groups[1].count == 2 then
        local kickers = {}
        for _, group in ipairs(groups) do if group.count == 1 then kickers[#kickers+1] = group.rank end end
        sort(kickers, function(a,b) return a>b end)
        return {1, groups[1].rank, kickers[1], kickers[2], kickers[3]}
    end
    return {0, unpack(ranks)}
end

local function compareRanks(left, right)
    local count = max(#left, #right)
    for index = 1, count do
        local a, b = left[index] or 0, right[index] or 0
        if a ~= b then return a > b and 1 or -1 end
    end
    return 0
end

local function bestSeven(cards)
    local best
    for a = 1, 3 do
        for b = a + 1, 4 do
            for c = b + 1, 5 do
                for d = c + 1, 6 do
                    for e = d + 1, 7 do
                        local rank = evaluateFive({ cards[a], cards[b], cards[c], cards[d], cards[e] })
                        if not best or compareRanks(rank, best) > 0 then best = rank end
                    end
                end
            end
        end
    end
    return best
end

local RANK_WORDS = {
    [2]="Two", [3]="Three", [4]="Four", [5]="Five", [6]="Six", [7]="Seven",
    [8]="Eight", [9]="Nine", [10]="Ten", [11]="Jack", [12]="Queen", [13]="King", [14]="Ace",
}
local RANK_PLURALS = {
    [2]="Twos", [3]="Threes", [4]="Fours", [5]="Fives", [6]="Sixes", [7]="Sevens",
    [8]="Eights", [9]="Nines", [10]="Tens", [11]="Jacks", [12]="Queens", [13]="Kings", [14]="Aces",
}

local function bestAvailable(cards)
    local count = #(cards or {})
    if count == 0 then return {0, 0} end
    if count < 5 then
        local counts, groups = {}, {}
        for _, card in ipairs(cards) do
            local rank = cardRank(card)
            counts[rank] = (counts[rank] or 0) + 1
        end
        for rank, amount in pairs(counts) do groups[#groups+1] = { count=amount, rank=rank } end
        sort(groups, function(a,b) if a.count ~= b.count then return a.count > b.count end return a.rank > b.rank end)
        if groups[1] and groups[1].count == 4 then return {7, groups[1].rank} end
        if groups[1] and groups[1].count == 3 then return {3, groups[1].rank} end
        if groups[1] and groups[1].count == 2 and groups[2] and groups[2].count == 2 then
            return {2, max(groups[1].rank, groups[2].rank), min(groups[1].rank, groups[2].rank)}
        end
        if groups[1] and groups[1].count == 2 then return {1, groups[1].rank} end
        local high = 0
        for rank in pairs(counts) do high = max(high, rank) end
        return {0, high}
    end

    local best, chosen = nil, {}
    local function choose(startIndex, depth)
        if depth > 5 then
            local rank = evaluateFive(chosen)
            if not best or compareRanks(rank, best) > 0 then
                best = {}
                for index, value in ipairs(rank) do best[index] = value end
            end
            return
        end
        local finalStart = count - (5 - depth)
        for index = startIndex, finalStart do
            chosen[depth] = cards[index]
            choose(index + 1, depth + 1)
        end
    end
    choose(1, 1)
    return best or {0, 0}
end

local function describePokerRank(rank)
    rank = rank or {0, 0}
    local category = rank[1] or 0
    if category == 8 then return (RANK_WORDS[rank[2]] or "High") .. "-high Straight Flush" end
    if category == 7 then return "Four " .. (RANK_PLURALS[rank[2]] or "of a Kind") end
    if category == 6 then return (RANK_PLURALS[rank[2]] or "Trips") .. " full of " .. (RANK_PLURALS[rank[3]] or "a Pair") end
    if category == 5 then return (RANK_WORDS[rank[2]] or "High") .. "-high Flush" end
    if category == 4 then return (RANK_WORDS[rank[2]] or "High") .. "-high Straight" end
    if category == 3 then return "Three " .. (RANK_PLURALS[rank[2]] or "of a Kind") end
    if category == 2 then return "Two Pair · " .. (RANK_PLURALS[rank[2]] or "High") .. " / " .. (RANK_PLURALS[rank[3]] or "Low") end
    if category == 1 then return "Pair of " .. (RANK_PLURALS[rank[2]] or "Cards") end
    return (RANK_WORDS[rank[2]] or "No") .. "-high"
end

local function oddsStanding(winChance, tieChance)
    winChance = tonumber(winChance) or 0
    tieChance = tonumber(tieChance) or 0
    local equity = winChance + tieChance * 0.5
    if equity >= 0.68 then return "STRONG FAVOURITE" end
    if equity >= 0.56 then return "FAVOURED" end
    if equity >= 0.48 then return "CLOSE / EVEN" end
    if equity >= 0.36 then return "UNDERDOG" end
    return "BIG UNDERDOG"
end

local function estimateHoldemOdds(playerHole, community, sampleCount)
    if not playerHole or not playerHole[1] or not playerHole[2] then return 0, 0 end
    community = community or {}
    local known = {}
    known[playerHole[1]] = true
    known[playerHole[2]] = true
    local seed = 7919 + playerHole[1] * 31 + playerHole[2] * 47 + #community * 101
    for _, card in ipairs(community) do known[card] = true; seed = (seed * 33 + card * 17) % 2147483647 end
    local remaining = {}
    for card=1,52 do if not known[card] then remaining[#remaining+1] = card end end
    local boardNeeded = 5 - #community
    sampleCount = floor(clamp(sampleCount or 260, 80, 500))
    local rng = makeRng(seed)
    local wins, ties = 0, 0
    for _=1,sampleCount do
        local pool = {}
        for index, card in ipairs(remaining) do pool[index] = card end
        local drawCount = 2 + boardNeeded
        for index=1,drawCount do
            local swapIndex = index - 1 + rng:Next(#pool - index + 1)
            pool[index], pool[swapIndex] = pool[swapIndex], pool[index]
        end
        local board = {}
        for _, card in ipairs(community) do board[#board+1] = card end
        for index=1,boardNeeded do board[#board+1] = pool[2 + index] end
        local playerCards = { playerHole[1], playerHole[2] }
        local opponentCards = { pool[1], pool[2] }
        for _, card in ipairs(board) do
            playerCards[#playerCards+1] = card
            opponentCards[#opponentCards+1] = card
        end
        local result = compareRanks(bestSeven(playerCards), bestSeven(opponentCards))
        if result > 0 then wins = wins + 1 elseif result == 0 then ties = ties + 1 end
    end
    return wins / sampleCount, ties / sampleCount
end

local function createPlayingCard(parent, width, height, gameKey)
    local colors = palette()
    local card = CreateFrame("Frame", nil, parent, templateName())
    card:SetSize(width or 58, height or 78)
    applyBackdrop(card, {0.90,0.90,0.86,1}, colors.border)
    card.text = createText(card, 16, {0.08,0.08,0.10,1}, "CENTER")
    card.text:SetAllPoints()
    card.text:SetText("--")
    card.creshDeckGameKey = gameKey or "HOLDEM"
    return card
end

local function setCard(cardFrame, card, hidden)
    if hidden then
        applyBackdrop(cardFrame, {0.08,0.24,0.46,1}, {0.18,0.62,0.95,1})
        if CC.CardDecks and CC.CardDecks.ApplyCardFrame and CC.CardDecks:ApplyCardFrame(cardFrame, card, true, cardFrame.creshDeckGameKey) then return end
        if cardFrame.cardTexture then cardFrame.cardTexture:Hide() end
        cardFrame.text:Show()
        cardFrame.text:SetText("??")
        cardFrame.text:SetTextColor(0.82,0.92,1,1)
    else
        applyBackdrop(cardFrame, {0.90,0.90,0.86,1}, {0.20,0.22,0.26,1})
        if CC.CardDecks and CC.CardDecks.ApplyCardFrame and CC.CardDecks:ApplyCardFrame(cardFrame, card, false, cardFrame.creshDeckGameKey) then return end
        if cardFrame.cardTexture then cardFrame.cardTexture:Hide() end
        cardFrame.text:Show()
        cardFrame.text:SetText(cardLabel(card))
        local suit = card and cardSuit(card)
        if suit == 2 or suit == 3 then cardFrame.text:SetTextColor(0.70,0.06,0.08,1) else cardFrame.text:SetTextColor(0.06,0.07,0.09,1) end
    end
end

-- SOLO TEXAS HOLD'EM ----------------------------------------------------------
function Solo:BuildHOLDEMView()
    if self.views.HOLDEM then return self.views.HOLDEM end
    local colors = palette()
    local view = { game="HOLDEM", actionIndex=1, actionKeys={} }
    local frame = CreateFrame("Frame", nil, self.window.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.table = CreateFrame("Frame", nil, frame, templateName())
    view.table:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -10)
    view.table:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -10)
    view.table:SetHeight(410)
    applyBackdrop(view.table, {0.025,0.20,0.09,1}, {0.10,0.42,0.20,1})

    view.phase = createText(view.table, 12, colors.text, "CENTER")
    view.phase:SetPoint("TOP", view.table, "TOP", 0, -10)
    view.pot = createText(view.table, 14, colors.gold, "CENTER")
    view.pot:SetPoint("TOP", view.phase, "BOTTOM", 0, -5)
    view.deckButton = createButton(view.table, "DECK", 174, 26, function(_, mouseButton)
        if CC.CardDecks then CC.CardDecks:Cycle("HOLDEM", mouseButton == "RightButton" and -1 or 1) end
        if view.deckButton and view.deckButton.RefreshDeck then view.deckButton:RefreshDeck() end
        view:Refresh()
    end)
    view.deckButton:SetPoint("TOPRIGHT", view.table, "TOPRIGHT", -10, -9)
    setButtonAccent(view.deckButton, colors.gold)
    if CC.CardDecks and CC.CardDecks.StyleDeckButton then CC.CardDecks:StyleDeckButton(view.deckButton, "HOLDEM") end

    view.aiLabel = createText(view.table, 10, colors.muted, "LEFT")
    view.aiLabel:SetPoint("TOPLEFT", view.table, "TOPLEFT", 16, -52)
    view.aiCards = { createPlayingCard(view.table, nil, nil, "HOLDEM"), createPlayingCard(view.table, nil, nil, "HOLDEM") }
    view.aiCards[1]:SetPoint("TOP", view.table, "TOP", -34, -58)
    view.aiCards[2]:SetPoint("LEFT", view.aiCards[1], "RIGHT", 10, 0)

    view.communityLabel = createText(view.table, 9, colors.muted, "CENTER")
    view.communityLabel:SetPoint("CENTER", view.table, "CENTER", 0, 38)
    view.communityLabel:SetText("COMMUNITY")
    view.communityCards = {}
    for index=1,5 do
        local card = createPlayingCard(view.table, 56, 74, "HOLDEM")
        card:SetPoint("CENTER", view.table, "CENTER", (index-3)*64, -10)
        view.communityCards[index] = card
    end

    view.playerLabel = createText(view.table, 10, colors.text, "LEFT")
    view.playerLabel:SetPoint("BOTTOMLEFT", view.table, "BOTTOMLEFT", 16, 20)
    view.playerCards = { createPlayingCard(view.table, nil, nil, "HOLDEM"), createPlayingCard(view.table, nil, nil, "HOLDEM") }
    view.playerCards[1]:SetPoint("BOTTOM", view.table, "BOTTOM", -34, 16)
    view.playerCards[2]:SetPoint("LEFT", view.playerCards[1], "RIGHT", 10, 0)

    view.resultBanner = createText(view.table, 16, colors.gold, "RIGHT")
    view.resultBanner:SetPoint("TOPLEFT", view.table, "TOP", 116, -50)
    view.resultBanner:SetPoint("TOPRIGHT", view.table, "TOPRIGHT", -16, -50)
    view.resultBanner:SetHeight(24)
    view.resultBanner:Hide()

    view.handInfo = createText(view.table, 10, colors.text, "RIGHT")
    view.handInfo:SetPoint("BOTTOMLEFT", view.table, "BOTTOM", 112, 18)
    view.handInfo:SetPoint("BOTTOMRIGHT", view.table, "BOTTOMRIGHT", -16, 18)
    view.handInfo:SetHeight(58)
    view.handInfo:SetWordWrap(true)

    view.message = createText(frame, 10, colors.muted, "CENTER")
    view.message:SetPoint("TOPLEFT", view.table, "BOTTOMLEFT", 0, -7)
    view.message:SetPoint("TOPRIGHT", view.table, "BOTTOMRIGHT", 0, -7)
    view.message:SetHeight(28)

    view.actions = CreateFrame("Frame", nil, frame, templateName())
    view.actions:SetPoint("TOPLEFT", view.message, "BOTTOMLEFT", 0, -5)
    view.actions:SetPoint("TOPRIGHT", view.message, "BOTTOMRIGHT", 0, -5)
    view.actions:SetPoint("BOTTOM", frame, "BOTTOM", 0, 7)
    applyBackdrop(view.actions, colors.panel, colors.border)
    view.actionButtons = {}
    local labels = { "FOLD", "CHECK / CALL", "RAISE" }
    for index, label in ipairs(labels) do
        local button = createButton(view.actions, label, 150, 34, function() view:ChooseAction(index) end)
        button:SetPoint("CENTER", view.actions, "CENTER", (index-2)*170, 8)
        setButtonAccent(button, index==1 and colors.red or (index==3 and colors.gold or colors.green))
        view.actionButtons[index] = button
    end
    view.newMatch = createButton(view.actions, "NEW MATCH", 112, 24, function() view:StartMatch() end)
    view.newMatch:SetPoint("BOTTOM", view.actions, "BOTTOM", 0, 6)
    setButtonAccent(view.newMatch, colors.accent)
    view.newMatch:Hide()

    function view:Draw()
        local card = self.deck[self.deckIndex]
        self.deckIndex = self.deckIndex + 1
        return card
    end

    function view:Contribute(who, amount)
        amount = floor(max(0, tonumber(amount) or 0))
        local chipsKey = who == "PLAYER" and "playerChips" or "aiChips"
        local chips = self[chipsKey]
        amount = min(amount, chips)
        self[chipsKey] = chips - amount
        self.streetBets[who] = (self.streetBets[who] or 0) + amount
        self.totalBets[who] = (self.totalBets[who] or 0) + amount
        self.potValue = self.potValue + amount
        return amount
    end

    function view:Other(who) return who == "PLAYER" and "AI" or "PLAYER" end

    function view:RequiredCall(who)
        local other = self:Other(who)
        return max(0, (self.streetBets[other] or 0) - (self.streetBets[who] or 0))
    end

    function view:SaveBankroll()
        local save = ensureSave()
        if not save then return end
        save.holdem.bankroll = floor(max(0, tonumber(self.playerChips) or 0))
        save.holdem.bestChips = floor(max(save.holdem.bestChips or 100, save.holdem.bankroll))
    end

    function view:GetOdds()
        if not self.playerHole or not self.playerHole[1] or not self.playerHole[2] then return 0, 0 end
        local parts = { tostring(self.playerHole[1]), tostring(self.playerHole[2]) }
        for _, card in ipairs(self.community or {}) do parts[#parts+1] = tostring(card) end
        local key = concat(parts, ":")
        if self.oddsCacheKey == key then return self.cachedWinChance or 0, self.cachedTieChance or 0 end
        local samples = #(self.community or {}) == 0 and 220 or 300
        local winChance, tieChance = estimateHoldemOdds(self.playerHole, self.community, samples)
        self.oddsCacheKey, self.cachedWinChance, self.cachedTieChance = key, winChance, tieChance
        return winChance, tieChance
    end

    function view:Refresh()
        if self.deckButton and self.deckButton.RefreshDeck then self.deckButton:RefreshDeck() end
        self.phase:SetText((self.phaseName or "PREFLOP") .. (self.dealer == "PLAYER" and "  ·  YOU ARE DEALER" or "  ·  AI IS DEALER"))
        self.pot:SetText("POT " .. formatChips(self.potValue or 0))
        self.aiLabel:SetText("COMPUTER   CHIPS " .. formatChips(self.aiChips or 0) .. "   BET " .. formatChips(self.streetBets and self.streetBets.AI or 0))
        self.playerLabel:SetText("YOU   CHIPS " .. formatChips(self.playerChips or 0) .. "   BET " .. formatChips(self.streetBets and self.streetBets.PLAYER or 0))
        for i=1,2 do setCard(self.playerCards[i], self.playerHole and self.playerHole[i], false) end
        for i=1,2 do setCard(self.aiCards[i], self.aiHole and self.aiHole[i], not self.revealAI) end
        for i=1,5 do setCard(self.communityCards[i], self.community and self.community[i], false) end

        if self.winnerText and self.winnerText ~= "" then
            self.resultBanner:SetText(self.winnerText)
            self.resultBanner:SetTextColor((self.winnerColor or colors.gold)[1], (self.winnerColor or colors.gold)[2], (self.winnerColor or colors.gold)[3], 1)
            self.resultBanner:Show()
        else
            self.resultBanner:Hide()
        end

        if self.playerHole and self.playerHole[1] then
            local playerCards = { self.playerHole[1], self.playerHole[2] }
            for _, card in ipairs(self.community or {}) do playerCards[#playerCards+1] = card end
            local currentRank = self.finalPlayerRank or bestAvailable(playerCards)
            local handText = describePokerRank(currentRank)
            if self.handOver and self.finalAIRank then
                self.handInfo:SetText("YOUR HAND: " .. handText .. "\nCOMPUTER: " .. describePokerRank(self.finalAIRank))
            elseif self.handOver then
                self.handInfo:SetText("YOUR HAND: " .. handText .. "\nHAND COMPLETE")
            else
                local winChance, tieChance = self:GetOdds()
                self.handInfo:SetText(format("YOUR HAND: %s\n%s · ~%d%% WIN · %d%% TIE", handText, oddsStanding(winChance, tieChance), floor(winChance * 100 + 0.5), floor(tieChance * 100 + 0.5)))
            end
        else
            self.handInfo:SetText("CURRENT HAND: --\nWIN CHANCE: --")
        end

        self.message:SetText(self.resultText or (self.toAct == "PLAYER" and "Your turn." or "Computer is thinking..."))
        if self.matchOver then self.newMatch.label:SetText((self.playerChips or 0) <= 0 and "RESET TO 100" or "PLAY NEXT TABLE") end
        self:RefreshActions()
    end

    function view:RefreshActions()
        local myTurn = self.toAct == "PLAYER" and not self.handOver and not self.matchOver
        local call = self:RequiredCall("PLAYER")
        self.actionButtons[1].label:SetText("FOLD")
        self.actionButtons[2].label:SetText(call > 0 and ("CALL " .. formatChips(call)) or "CHECK")
        local raiseAmount = self.raiseSize or 2
        self.actionButtons[3].label:SetText(call > 0 and ("RAISE +" .. formatChips(raiseAmount)) or ("BET " .. formatChips(raiseAmount)))
        setButtonEnabled(self.actionButtons[1], myTurn and call > 0)
        setButtonEnabled(self.actionButtons[2], myTurn)
        setButtonEnabled(self.actionButtons[3], myTurn and self.raisesThisStreet < 2 and self.playerChips > call)
        for index, button in ipairs(self.actionButtons) do
            button.creshSelected = index == self.actionIndex
            applyBackdrop(button, button.creshBaseColor, button.creshSelected and colors.text or (index==1 and colors.red or (index==3 and colors.gold or colors.green)))
        end
    end

    function view:BeginHand()
        if self.playerChips <= 0 or self.aiChips <= 0 then self:FinishMatch(); return end
        self.handNumber = (self.handNumber or 0) + 1
        self.dealer = self.dealer == "PLAYER" and "AI" or "PLAYER"
        self.deck, self.rng = shuffledDeck(floor(now()*1000) + self.handNumber*937 + self.playerChips*17)
        self.deckIndex = 1
        self.playerHole = { self:Draw(), self:Draw() }
        self.aiHole = { self:Draw(), self:Draw() }
        self.community = {}
        self.phaseName = "PREFLOP"
        self.raiseSize = self.bigBlind or 2
        self.potValue = 0
        self.streetBets = { PLAYER=0, AI=0 }
        self.totalBets = { PLAYER=0, AI=0 }
        self.acted = { PLAYER=false, AI=false }
        self.raisesThisStreet = 0
        self.handOver = false
        self.matchOver = false
        self.revealAI = false
        self.resultText = nil
        self.winnerText = nil
        self.winnerColor = nil
        self.finalPlayerRank = nil
        self.finalAIRank = nil
        self.oddsCacheKey = nil
        local small = self.dealer
        local big = self:Other(small)
        self:Contribute(small, self.smallBlind or 1)
        self:Contribute(big, self.bigBlind or 2)
        self.toAct = small
        self.actionIndex = 2
        Solo:SetStatus("New Hold'em hand. Blinds are " .. formatChips(self.smallBlind or 1) .. " / " .. formatChips(self.bigBlind or 2) .. ".", colors.gold)
        self:Refresh()
        if self.toAct == "AI" then self:ScheduleAI() end
    end

    function view:StartMatch()
        local save = ensureSave()
        local bankroll = save and floor(max(0, tonumber(save.holdem.bankroll) or 100)) or 100
        local reset = bankroll < 2
        if reset then
            bankroll = 100
            if save then save.holdem.bankroll = bankroll end
        end
        self.playerChips = bankroll
        self.aiChips = bankroll
        self.startingStack = bankroll
        self.smallBlind = max(1, floor(bankroll / 100))
        self.bigBlind = self.smallBlind * 2
        self.dealer = "AI"
        self.handNumber = 0
        self.matchOver = false
        self.newMatch:Hide()
        self:BeginHand()
        if reset then Solo:SetStatus("Bankroll reset to 100 starter chips. Build it up across future tables.", colors.accent) end
    end

    function view:FinishMatch()
        self.matchOver = true
        self.handOver = true
        local won = self.playerChips > self.aiChips
        self:SaveBankroll()
        local save = ensureSave()
        if save then
            save.holdem.games = (save.holdem.games or 0) + 1
            if won then save.holdem.wins = (save.holdem.wins or 0) + 1 else save.holdem.losses = (save.holdem.losses or 0) + 1 end
        end
        self.resultText = won and ("You won the table with " .. formatChips(self.playerChips) .. " chips!") or "The computer won the table."
        self.winnerText = won and "YOU WON THE TABLE" or "COMPUTER WON THE TABLE"
        self.winnerColor = won and colors.green or colors.red
        self.newMatch:Show()
        Solo:RecordHistory("HOLDEM", "SOLO", won and "WIN" or "LOSS", "Computer", format("Table ended · bankroll %s", formatChips(self.playerChips or 0)), self.playerChips or 0)
        Solo:PushLeaderboards()
        Solo:SetStatus(self.resultText, won and colors.green or colors.red)
        self:Refresh()
        Solo:RefreshHub()
    end

    function view:NextStreet()
        self.streetBets = { PLAYER=0, AI=0 }
        self.acted = { PLAYER=false, AI=false }
        self.raisesThisStreet = 0
        if self.phaseName == "PREFLOP" then
            self.phaseName = "FLOP"
            self.community = { self:Draw(), self:Draw(), self:Draw() }
            self.raiseSize = self.bigBlind or 2
        elseif self.phaseName == "FLOP" then
            self.phaseName = "TURN"
            self.community[4] = self:Draw()
            self.raiseSize = (self.bigBlind or 2) * 2
        elseif self.phaseName == "TURN" then
            self.phaseName = "RIVER"
            self.community[5] = self:Draw()
            self.raiseSize = (self.bigBlind or 2) * 2
        else
            self:Showdown()
            return
        end
        self.toAct = self:Other(self.dealer)
        self.resultText = nil
        self.oddsCacheKey = nil
        self:Refresh()
        if self.toAct == "AI" then self:ScheduleAI() end
    end

    function view:RunOutBoard()
        while #self.community < 5 do self.community[#self.community+1] = self:Draw() end
        self.phaseName = "SHOWDOWN"
        self:Showdown()
    end

    function view:EndAction(who, raised)
        self.acted[who] = true
        if raised then self.acted[self:Other(who)] = false end
        local other = self:Other(who)
        local equal = (self.streetBets.PLAYER or 0) == (self.streetBets.AI or 0)
        if self.playerChips == 0 or self.aiChips == 0 then
            -- Heads-up all-ins cannot create a side pot. Return any unmatched excess
            -- to the larger bettor, then deal the remaining community cards.
            local playerBet, aiBet = self.streetBets.PLAYER or 0, self.streetBets.AI or 0
            if playerBet > aiBet then
                local refund = playerBet - aiBet
                self.streetBets.PLAYER = playerBet - refund
                self.totalBets.PLAYER = max(0, (self.totalBets.PLAYER or 0) - refund)
                self.playerChips = self.playerChips + refund
                self.potValue = max(0, self.potValue - refund)
            elseif aiBet > playerBet then
                local refund = aiBet - playerBet
                self.streetBets.AI = aiBet - refund
                self.totalBets.AI = max(0, (self.totalBets.AI or 0) - refund)
                self.aiChips = self.aiChips + refund
                self.potValue = max(0, self.potValue - refund)
            end
            self:RunOutBoard()
            return
        end
        if equal and self.acted.PLAYER and self.acted.AI then
            self:NextStreet()
        else
            self.toAct = other
            self:Refresh()
            if other == "AI" then self:ScheduleAI() end
        end
    end

    function view:Act(who, action)
        if self.handOver or self.matchOver or self.toAct ~= who then return end
        local call = self:RequiredCall(who)
        if action == "FOLD" then
            local winner = self:Other(who)
            self.handOver = true
            if winner == "PLAYER" then self.playerChips = self.playerChips + self.potValue else self.aiChips = self.aiChips + self.potValue end
            self.resultText = winner == "PLAYER" and "Computer folded. You win the pot." or "You folded. Computer wins the pot."
            self.winnerText = winner == "PLAYER" and "YOU WON" or "COMPUTER WON"
            self.winnerColor = winner == "PLAYER" and colors.green or colors.red
            self.potValue = 0
            self:SaveBankroll()
            Solo:SetStatus(self.resultText, winner == "PLAYER" and colors.green or colors.red)
            self:Refresh()
            self:ScheduleNextHand()
            return
        end
        if action == "CALL" or action == "CHECK" then
            self:Contribute(who, call)
            self:EndAction(who, false)
            return
        end
        if action == "RAISE" or action == "BET" then
            local paid = self:Contribute(who, call + self.raiseSize)
            if paid <= call then self:EndAction(who, false) else self.raisesThisStreet = self.raisesThisStreet + 1; self:EndAction(who, true) end
        end
    end

    function view:PlayerAction(index)
        local call = self:RequiredCall("PLAYER")
        if index == 1 then self:Act("PLAYER", "FOLD")
        elseif index == 2 then self:Act("PLAYER", call > 0 and "CALL" or "CHECK")
        elseif index == 3 then self:Act("PLAYER", call > 0 and "RAISE" or "BET") end
    end

    function view:ChooseAction(index)
        if self.toAct ~= "PLAYER" or self.handOver then return end
        self.actionIndex = clamp(index, 1, 3)
        self:PlayerAction(self.actionIndex)
    end

    function view:AIStrength()
        local r1, r2 = cardRank(self.aiHole[1]), cardRank(self.aiHole[2])
        if #self.community == 0 then
            local score = (r1 + r2) / 28
            if r1 == r2 then score = score + 0.35 end
            if cardSuit(self.aiHole[1]) == cardSuit(self.aiHole[2]) then score = score + 0.08 end
            if abs(r1-r2) <= 2 then score = score + 0.05 end
            return clamp(score, 0, 1)
        end
        local cards = { self.aiHole[1], self.aiHole[2] }
        for _, card in ipairs(self.community) do cards[#cards+1] = card end
        while #cards < 7 do cards[#cards+1] = self.deck[self.deckIndex + #cards] or self.aiHole[1] end
        local rank = bestSeven(cards)
        return clamp((rank[1] or 0) / 8 + ((rank[2] or 2) / 14) * 0.12, 0, 1)
    end

    function view:AIAction()
        if self.toAct ~= "AI" or self.handOver then return end
        local call = self:RequiredCall("AI")
        local strength = self:AIStrength()
        local roll = self.rng and self.rng:Float() or 0.5
        local action
        if call > 0 then
            local pressure = call / max(1, self.aiChips + call)
            if strength < 0.28 + pressure * 0.8 and roll < 0.72 then action = "FOLD"
            elseif strength > 0.72 and self.raisesThisStreet < 2 and self.aiChips > call + self.raiseSize and roll < 0.62 then action = "RAISE"
            else action = "CALL" end
        else
            if strength > 0.58 and self.raisesThisStreet < 2 and self.aiChips > self.raiseSize and roll < 0.70 then action = "BET" else action = "CHECK" end
        end
        self.resultText = "Computer chose " .. action .. "."
        self:Act("AI", action)
    end

    function view:ScheduleAI()
        self:Refresh()
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then
            _G.C_Timer.After(0.55, function() if Solo.activeGame == "HOLDEM" then view:AIAction() end end)
        else self:AIAction() end
    end

    function view:Showdown()
        self.handOver = true
        self.revealAI = true
        self.phaseName = "SHOWDOWN"
        while #self.community < 5 do self.community[#self.community+1] = self:Draw() end
        local playerCards = { self.playerHole[1], self.playerHole[2] }
        local aiCards = { self.aiHole[1], self.aiHole[2] }
        for _, card in ipairs(self.community) do playerCards[#playerCards+1] = card; aiCards[#aiCards+1] = card end
        local playerRank, aiRank = bestSeven(playerCards), bestSeven(aiCards)
        self.finalPlayerRank, self.finalAIRank = playerRank, aiRank
        local result = compareRanks(playerRank, aiRank)
        if result > 0 then
            self.playerChips = self.playerChips + self.potValue
            self.resultText = "You win with " .. describePokerRank(playerRank) .. "."
            self.winnerText = "YOU WON"
            self.winnerColor = colors.green
            Solo:SetStatus(self.resultText, colors.green)
        elseif result < 0 then
            self.aiChips = self.aiChips + self.potValue
            self.resultText = "Computer wins with " .. describePokerRank(aiRank) .. "."
            self.winnerText = "COMPUTER WON"
            self.winnerColor = colors.red
            Solo:SetStatus(self.resultText, colors.red)
        else
            local half = floor(self.potValue / 2)
            self.playerChips = self.playerChips + half
            self.aiChips = self.aiChips + (self.potValue - half)
            self.resultText = "Split pot: both have " .. describePokerRank(playerRank) .. "."
            self.winnerText = "SPLIT POT"
            self.winnerColor = colors.gold
            Solo:SetStatus(self.resultText, colors.gold)
        end
        self.potValue = 0
        self:SaveBankroll()
        self:Refresh()
        self:ScheduleNextHand()
    end

    function view:ScheduleNextHand()
        if self.playerChips <= 0 or self.aiChips <= 0 then self:FinishMatch(); return end
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then
            _G.C_Timer.After(2.8, function() if Solo.activeGame == "HOLDEM" and view.handOver and not view.matchOver then view:BeginHand() end end)
        else self:BeginHand() end
    end

    function view:OnKeyDown(key)
        if self.matchOver then if key == "SPACE" or key == "ENTER" or key == "R" then self:StartMatch() end; return end
        if self.toAct ~= "PLAYER" or self.handOver then return end
        if key == "A" or key == "LEFT" then self.actionIndex = self.actionIndex - 1; if self.actionIndex < 1 then self.actionIndex = 3 end; self:RefreshActions()
        elseif key == "D" or key == "RIGHT" then self.actionIndex = self.actionIndex + 1; if self.actionIndex > 3 then self.actionIndex = 1 end; self:RefreshActions()
        elseif key == "S" or key == "DOWN" then self.actionIndex = 2; self:PlayerAction(2)
        elseif key == "W" or key == "UP" then self.actionIndex = 3; self:PlayerAction(3)
        elseif key == "SPACE" or key == "ENTER" then self:PlayerAction(self.actionIndex) end
    end

    function view:Start() self:StartMatch() end

    self.views.HOLDEM = view
    return view
end

-- BLACKJACK -------------------------------------------------------------------
local function blackjackValueDetail(cards)
    local total, aces = 0, 0
    for _, card in ipairs(cards or {}) do
        local rank = cardRank(card)
        if rank == 14 then total = total + 11; aces = aces + 1
        elseif rank >= 10 then total = total + 10
        else total = total + rank end
    end
    while total > 21 and aces > 0 do total = total - 10; aces = aces - 1 end
    return total, aces > 0
end

local function blackjackValue(cards)
    local total = blackjackValueDetail(cards)
    return total
end

local function blackjackHandText(cards)
    local total, soft = blackjackValueDetail(cards)
    if total > 21 then return "BUST " .. tostring(total) end
    if total == 21 and #(cards or {}) == 2 then return "BLACKJACK 21" end
    return (soft and "SOFT " or "HARD ") .. tostring(total)
end

function Solo:BuildBLACKJACKView()
    if self.views.BLACKJACK then return self.views.BLACKJACK end
    local colors = palette()
    local view = { game="BLACKJACK", actionIndex=1, bet=10, bank=100 }
    local frame = CreateFrame("Frame", nil, self.window.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.table = CreateFrame("Frame", nil, frame, templateName())
    view.table:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -12)
    view.table:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -12)
    view.table:SetHeight(400)
    applyBackdrop(view.table, {0.025,0.18,0.08,1}, {0.10,0.42,0.20,1})

    view.bankText = createText(view.table, 13, colors.gold, "CENTER")
    view.bankText:SetPoint("TOP", view.table, "TOP", 0, -12)
    view.deckButton = createButton(view.table, "DECK", 174, 26, function(_, mouseButton)
        if CC.CardDecks then CC.CardDecks:Cycle("BLACKJACK", mouseButton == "RightButton" and -1 or 1) end
        if view.deckButton and view.deckButton.RefreshDeck then view.deckButton:RefreshDeck() end
        view:Refresh()
    end)
    view.deckButton:SetPoint("TOPRIGHT", view.table, "TOPRIGHT", -12, -9)
    setButtonAccent(view.deckButton, colors.gold)
    if CC.CardDecks and CC.CardDecks.StyleDeckButton then CC.CardDecks:StyleDeckButton(view.deckButton, "BLACKJACK") end
    view.dealerLabel = createText(view.table, 11, colors.muted, "LEFT")
    view.dealerLabel:SetPoint("TOPLEFT", view.table, "TOPLEFT", 18, -44)
    view.playerLabel = createText(view.table, 11, colors.text, "LEFT")
    view.playerLabel:SetPoint("BOTTOMLEFT", view.table, "BOTTOMLEFT", 18, 28)

    view.resultBanner = createText(view.table, 16, colors.gold, "RIGHT")
    view.resultBanner:SetPoint("TOPLEFT", view.table, "TOP", 120, -42)
    view.resultBanner:SetPoint("TOPRIGHT", view.table, "TOPRIGHT", -18, -42)
    view.resultBanner:SetHeight(24)
    view.resultBanner:Hide()

    view.standing = createText(view.table, 12, colors.text, "CENTER")
    view.standing:SetPoint("CENTER", view.table, "CENTER", 0, 0)
    view.standing:SetWidth(560)
    view.standing:SetHeight(54)
    view.standing:SetWordWrap(true)

    view.dealerCards = {}
    view.playerCards = {}
    for index=1,7 do
        local dealerCard = createPlayingCard(view.table, 58, 78, "BLACKJACK")
        dealerCard:SetPoint("TOPLEFT", view.table, "TOPLEFT", 120 + (index-1)*66, -68)
        dealerCard:Hide()
        view.dealerCards[index] = dealerCard
        local playerCard = createPlayingCard(view.table, 58, 78, "BLACKJACK")
        playerCard:SetPoint("BOTTOMLEFT", view.table, "BOTTOMLEFT", 120 + (index-1)*66, 18)
        playerCard:Hide()
        view.playerCards[index] = playerCard
    end

    view.message = createText(frame, 11, colors.muted, "CENTER")
    view.message:SetPoint("TOPLEFT", view.table, "BOTTOMLEFT", 0, -8)
    view.message:SetPoint("TOPRIGHT", view.table, "BOTTOMRIGHT", 0, -8)
    view.message:SetHeight(28)

    view.actions = CreateFrame("Frame", nil, frame, templateName())
    view.actions:SetPoint("TOPLEFT", view.message, "BOTTOMLEFT", 0, -5)
    view.actions:SetPoint("TOPRIGHT", view.message, "BOTTOMRIGHT", 0, -5)
    view.actions:SetPoint("BOTTOM", frame, "BOTTOM", 0, 7)
    applyBackdrop(view.actions, colors.panel, colors.border)

    view.actionButtons = {}
    local labels = { "HIT", "STAND", "DOUBLE" }
    for index,label in ipairs(labels) do
        local button = createButton(view.actions, label, 130, 34, function() view:ChooseAction(index) end)
        button:SetPoint("CENTER", view.actions, "CENTER", (index-2)*150, 12)
        setButtonAccent(button, index==1 and colors.green or (index==2 and colors.accent or colors.gold))
        view.actionButtons[index] = button
    end
    view.betDown = createButton(view.actions, "BET -", 82, 24, function() view:ChangeBet(-(view:BetStep())) end)
    view.betDown:SetPoint("BOTTOMLEFT", view.actions, "BOTTOMLEFT", 10, 6)
    view.betUp = createButton(view.actions, "BET +", 82, 24, function() view:ChangeBet(view:BetStep()) end)
    view.betUp:SetPoint("LEFT", view.betDown, "RIGHT", 6, 0)
    view.deal = createButton(view.actions, "DEAL", 108, 28, function() view:DealOrReset() end)
    view.deal:SetPoint("BOTTOMRIGHT", view.actions, "BOTTOMRIGHT", -10, 5)
    setButtonAccent(view.betDown, colors.gold); setButtonAccent(view.betUp, colors.gold); setButtonAccent(view.deal, colors.accent)

    function view:Draw()
        if not self.deck or self.deckIndex > #self.deck then self.deck = shuffledDeck(floor(now()*1000)+73); self.deckIndex=1 end
        local card = self.deck[self.deckIndex]
        self.deckIndex = self.deckIndex + 1
        return card
    end

    function view:BetStep()
        local bank = tonumber(self.bank) or 0
        if bank >= 5000 then return 250 end
        if bank >= 1000 then return 100 end
        if bank >= 250 then return 25 end
        return 5
    end

    function view:SaveBankroll()
        local save = ensureSave()
        if not save then return end
        save.blackjack.bankroll = floor(max(0, tonumber(self.bank) or 0))
        save.blackjack.bestBank = floor(max(save.blackjack.bestBank or 100, save.blackjack.bankroll))
    end

    function view:ResetBankroll()
        if self.inHand then return end
        self.bank = 100
        self.bet = 10
        self.resultCode = nil
        self.resultText = "Starter bank restored to 100. Set your bet and press Deal."
        self:SaveBankroll()
        Solo:SetStatus("Blackjack bank reset to 100 starter chips.", colors.accent)
        self:Refresh()
    end

    function view:DealOrReset()
        if (self.bank or 0) <= 0 then self:ResetBankroll() else self:DealHand() end
    end

    function view:Refresh()
        if self.deckButton and self.deckButton.RefreshDeck then self.deckButton:RefreshDeck() end
        local playerValue = blackjackValue(self.playerHand)
        local dealerValue = blackjackValue(self.dealerHand)
        local dealerShowing = self.dealerHand and self.dealerHand[1] and blackjackValue({ self.dealerHand[1] }) or 0
        self.bankText:SetText("BANK " .. formatChips(self.bank or 0) .. "   ·   BET " .. formatChips(self.bet or 0))
        self.playerLabel:SetText("YOU   ·   " .. blackjackHandText(self.playerHand))
        self.dealerLabel:SetText(self.revealDealer and ("DEALER   ·   " .. blackjackHandText(self.dealerHand)) or ("DEALER   ·   SHOWING " .. tostring(dealerShowing)))
        for index=1,7 do
            local card = self.playerHand and self.playerHand[index]
            self.playerCards[index]:SetShown(card ~= nil)
            if card then setCard(self.playerCards[index], card, false) end
            local dealerCard = self.dealerHand and self.dealerHand[index]
            self.dealerCards[index]:SetShown(dealerCard ~= nil)
            if dealerCard then setCard(self.dealerCards[index], dealerCard, index == 2 and not self.revealDealer) end
        end

        if self.resultCode then
            local banner, color = "HAND COMPLETE", colors.gold
            if self.resultCode == "WIN" then banner, color = "YOU WON", colors.green
            elseif self.resultCode == "BLACKJACK" then banner, color = "BLACKJACK · YOU WON", colors.green
            elseif self.resultCode == "LOSE" then banner, color = "DEALER WON", colors.red
            elseif self.resultCode == "PUSH" then banner, color = "PUSH · TIED", colors.gold end
            self.resultBanner:SetText(banner)
            self.resultBanner:SetTextColor(color[1], color[2], color[3], 1)
            self.resultBanner:Show()
        else
            self.resultBanner:Hide()
        end

        if self.revealDealer and self.dealerHand and #self.dealerHand > 0 and self.playerHand and #self.playerHand > 0 then
            local standing
            if playerValue > 21 then standing = "YOU BUSTED AT " .. tostring(playerValue)
            elseif dealerValue > 21 then standing = "DEALER BUSTED AT " .. tostring(dealerValue)
            elseif playerValue > dealerValue then standing = "YOU ARE AHEAD BY " .. tostring(playerValue - dealerValue)
            elseif playerValue < dealerValue then standing = "DEALER IS AHEAD BY " .. tostring(dealerValue - playerValue)
            else standing = "THE HAND IS TIED" end
            self.standing:SetText("YOUR HAND: " .. blackjackHandText(self.playerHand) .. "   ·   DEALER: " .. blackjackHandText(self.dealerHand) .. "\n" .. standing)
        elseif self.playerHand and #self.playerHand > 0 then
            self.standing:SetText("YOUR HAND: " .. blackjackHandText(self.playerHand) .. "   ·   " .. tostring(max(0, 21 - playerValue)) .. " TO 21\nDEALER SHOWS: " .. tostring(dealerShowing))
        else
            self.standing:SetText("CURRENT HAND: --\nChoose a bet to begin.")
        end

        self.message:SetText(self.resultText or (self.inHand and "Choose Hit, Stand or Double." or "Set your bet and press Deal."))
        local canAct = self.inHand and not self.handOver
        local minimumBet = (self.bank or 0) > 0 and min(5, self.bank) or 5
        local maximumBet = max(minimumBet, self.bank or minimumBet)
        local step = self:BetStep()
        self.betDown.label:SetText("BET -" .. formatChips(step))
        self.betUp.label:SetText("BET +" .. formatChips(step))
        self.deal.label:SetText((self.bank or 0) <= 0 and "RESET 100" or "DEAL")
        setButtonEnabled(self.actionButtons[1], canAct)
        setButtonEnabled(self.actionButtons[2], canAct)
        setButtonEnabled(self.actionButtons[3], canAct and #self.playerHand == 2 and self.bank >= self.bet)
        setButtonEnabled(self.betDown, not self.inHand and (self.bank or 0) > 0 and self.bet > minimumBet)
        setButtonEnabled(self.betUp, not self.inHand and (self.bank or 0) > 0 and self.bet < maximumBet)
        setButtonEnabled(self.deal, not self.inHand and ((self.bank or 0) <= 0 or self.bank >= self.bet))
        for index, button in ipairs(self.actionButtons) do
            button.creshSelected = index == self.actionIndex
            applyBackdrop(button, button.creshBaseColor, button.creshSelected and colors.text or (index==1 and colors.green or (index==2 and colors.accent or colors.gold)))
        end
    end

    function view:ChangeBet(delta)
        if self.inHand or (self.bank or 0) <= 0 then return end
        local minimumBet = min(5, self.bank)
        self.bet = floor(clamp((self.bet or minimumBet) + delta, minimumBet, self.bank))
        self:Refresh()
    end

    function view:DealHand()
        if self.inHand or self.bank < self.bet or self.bank <= 0 then return end
        if not self.deck or (#self.deck - (self.deckIndex or 1)) < 16 then self.deck, self.rng = shuffledDeck(floor(now()*1000) + self.bank*31); self.deckIndex = 1 end
        self.bank = self.bank - self.bet
        self.playerHand = { self:Draw(), self:Draw() }
        self.dealerHand = { self:Draw(), self:Draw() }
        self.inHand = true
        self.handOver = false
        self.revealDealer = false
        self.resultText = nil
        self.resultCode = nil
        self.actionIndex = 1
        local playerValue, dealerValue = blackjackValue(self.playerHand), blackjackValue(self.dealerHand)
        if playerValue == 21 or dealerValue == 21 then
            self.revealDealer = true
            if playerValue == 21 and dealerValue == 21 then self:Resolve("PUSH", "Both have Blackjack.")
            elseif playerValue == 21 then self:Resolve("BLACKJACK", "Blackjack! You win 3:2.")
            else self:Resolve("LOSE", "Dealer has Blackjack.") end
        else
            Solo:SetStatus("Blackjack hand started.", colors.green)
            self:Refresh()
        end
    end

    function view:Hit()
        if not self.inHand or self.handOver then return end
        self.playerHand[#self.playerHand+1] = self:Draw()
        local value = blackjackValue(self.playerHand)
        if value > 21 then self.revealDealer = true; self:Resolve("LOSE", "Bust. Dealer wins.")
        elseif value == 21 then self:Stand()
        else self.resultText = "You drew " .. cardLabel(self.playerHand[#self.playerHand]) .. "."; self:Refresh() end
    end

    function view:Double()
        if not self.inHand or self.handOver or #self.playerHand ~= 2 or self.bank < self.bet then return end
        self.bank = self.bank - self.bet
        self.bet = self.bet * 2
        self.playerHand[#self.playerHand+1] = self:Draw()
        if blackjackValue(self.playerHand) > 21 then self.revealDealer = true; self:Resolve("LOSE", "Double-down bust.") else self:Stand() end
    end

    function view:Stand()
        if not self.inHand or self.handOver then return end
        self.revealDealer = true
        while blackjackValue(self.dealerHand) < 17 do self.dealerHand[#self.dealerHand+1] = self:Draw() end
        local playerValue, dealerValue = blackjackValue(self.playerHand), blackjackValue(self.dealerHand)
        if dealerValue > 21 then self:Resolve("WIN", "Dealer busts. You win.")
        elseif playerValue > dealerValue then self:Resolve("WIN", "You beat the dealer " .. playerValue .. " to " .. dealerValue .. ".")
        elseif playerValue < dealerValue then self:Resolve("LOSE", "Dealer wins " .. dealerValue .. " to " .. playerValue .. ".")
        else self:Resolve("PUSH", "Push at " .. playerValue .. ".") end
    end

    function view:Resolve(result, text)
        if self.handOver then return end
        self.handOver = true
        self.inHand = false
        self.revealDealer = true
        self.resultCode = result
        local save = ensureSave()
        if result == "BLACKJACK" then
            self.bank = self.bank + floor(self.bet * 2.5)
            if save then save.blackjack.wins = (save.blackjack.wins or 0) + 1 end
        elseif result == "WIN" then
            self.bank = self.bank + self.bet * 2
            if save then save.blackjack.wins = (save.blackjack.wins or 0) + 1 end
        elseif result == "PUSH" then
            self.bank = self.bank + self.bet
            if save then save.blackjack.pushes = (save.blackjack.pushes or 0) + 1 end
        else
            if save then save.blackjack.losses = (save.blackjack.losses or 0) + 1 end
        end
        if save then save.blackjack.games = (save.blackjack.games or 0) + 1 end
        self:SaveBankroll()
        self.resultText = text
        if self.bank > 0 then
            local minimumBet = min(5, self.bank)
            self.bet = floor(clamp(min(self.bet, self.bank), minimumBet, self.bank))
        else
            self.bet = 5
            self.resultText = text .. " Bank empty — press RESET 100 to play again."
        end
        local historyResult = (result == "WIN" or result == "BLACKJACK") and "WIN" or (result == "PUSH" and "DRAW" or "LOSS")
        Solo:RecordHistory("BLACKJACK", "SOLO", historyResult, "Dealer", text .. " · bank " .. formatChips(self.bank or 0), self.bank or 0)
        Solo:PushLeaderboards()
        Solo:SetStatus(text, (result == "WIN" or result == "BLACKJACK") and colors.green or (result == "PUSH" and colors.gold or colors.red))
        self:Refresh()
        Solo:RefreshHub()
    end

    function view:ChooseAction(index)
        self.actionIndex = clamp(index, 1, 3)
        if index == 1 then self:Hit()
        elseif index == 2 then self:Stand()
        elseif index == 3 then self:Double() end
    end

    function view:OnKeyDown(key)
        if not self.inHand then
            if key == "SPACE" or key == "ENTER" then
                self:DealOrReset()
            elseif key == "A" or key == "LEFT" then self:ChangeBet(-(self:BetStep()))
            elseif key == "D" or key == "RIGHT" then self:ChangeBet(self:BetStep())
            elseif key == "R" then self:StartSession() end
            return
        end
        if key == "A" or key == "LEFT" then self.actionIndex = self.actionIndex - 1; if self.actionIndex < 1 then self.actionIndex = 3 end; self:Refresh()
        elseif key == "D" or key == "RIGHT" then self.actionIndex = self.actionIndex + 1; if self.actionIndex > 3 then self.actionIndex = 1 end; self:Refresh()
        elseif key == "W" or key == "UP" then self:Hit()
        elseif key == "S" or key == "DOWN" then self:Stand()
        elseif key == "SPACE" or key == "ENTER" then self:ChooseAction(self.actionIndex) end
    end

    function view:StartSession()
        local save = ensureSave()
        self.bank = save and floor(max(0, tonumber(save.blackjack.bankroll) or 100)) or 100
        if self.bank > 0 then self.bet = min(10, self.bank) else self.bet = 5 end
        self.playerHand = {}
        self.dealerHand = {}
        self.deck, self.rng = shuffledDeck(floor(now()*1000)+211+self.bank*7)
        self.deckIndex = 1
        self.inHand = false
        self.handOver = true
        self.revealDealer = true
        self.resultCode = nil
        self.resultText = self.bank > 0 and ("Saved bank restored: " .. formatChips(self.bank) .. " chips.") or "Bank empty — press RESET 100 to play again."
        self:Refresh()
        Solo:SetStatus("Blackjack ready. Your saved bank is " .. formatChips(self.bank) .. ".", colors.accent)
    end

    function view:Start() self:StartSession() end

    self.views.BLACKJACK = view
    return view
end



-- HIGHER OR LOWER -------------------------------------------------------------
local function higherLowerRankName(card)
    if not card then return "--" end
    local rank = cardRank(card)
    if rank == 14 then return "ACE"
    elseif rank == 13 then return "KING"
    elseif rank == 12 then return "QUEEN"
    elseif rank == 11 then return "JACK"
    else return tostring(rank) end
end

function Solo:BuildHIGHERLOWERView()
    if self.views.HIGHERLOWER then return self.views.HIGHERLOWER end
    local colors = palette()
    local view = { game="HIGHERLOWER", actionIndex=1, bet=10, bank=100, streak=0, waiting=false }
    local frame = CreateFrame("Frame", nil, self.window.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.table = CreateFrame("Frame", nil, frame, templateName())
    view.table:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -16)
    view.table:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -16)
    view.table:SetHeight(410)
    applyBackdrop(view.table, darken(colors.green, 0.76), colors.green)

    view.bankText = createText(view.table, 14, colors.gold, "CENTER")
    view.bankText:SetPoint("TOP", view.table, "TOP", 0, -14)
    view.deckButton = createButton(view.table, "DECK", 174, 26, function(_, mouseButton)
        if CC.CardDecks then CC.CardDecks:Cycle("HIGHERLOWER", mouseButton == "RightButton" and -1 or 1) end
        if view.deckButton and view.deckButton.RefreshDeck then view.deckButton:RefreshDeck() end
        view:Refresh()
    end)
    view.deckButton:SetPoint("TOPRIGHT", view.table, "TOPRIGHT", -12, -10)
    setButtonAccent(view.deckButton, colors.gold)
    if CC.CardDecks and CC.CardDecks.StyleDeckButton then CC.CardDecks:StyleDeckButton(view.deckButton, "HIGHERLOWER") end
    view.heading = createText(view.table, 11, colors.text, "CENTER")
    view.heading:SetPoint("TOP", view.bankText, "BOTTOM", 0, -8)
    view.heading:SetText("WILL THE NEXT CARD BE HIGHER OR LOWER?")

    view.currentLabel = createText(view.table, 9, colors.muted, "CENTER")
    view.currentLabel:SetPoint("TOP", view.heading, "BOTTOM", -100, -18)
    view.currentLabel:SetText("CURRENT CARD")
    view.nextLabel = createText(view.table, 9, colors.muted, "CENTER")
    view.nextLabel:SetPoint("TOP", view.heading, "BOTTOM", 100, -18)
    view.nextLabel:SetText("NEXT CARD")
    view.currentCardFrame = createPlayingCard(view.table, 92, 126, "HIGHERLOWER")
    view.currentCardFrame:SetPoint("TOP", view.currentLabel, "BOTTOM", 0, -7)
    view.nextCardFrame = createPlayingCard(view.table, 92, 126, "HIGHERLOWER")
    view.nextCardFrame:SetPoint("TOP", view.nextLabel, "BOTTOM", 0, -7)

    view.resultBanner = createText(view.table, 18, colors.gold, "CENTER")
    view.resultBanner:SetPoint("TOPLEFT", view.currentCardFrame, "BOTTOMLEFT", -90, -15)
    view.resultBanner:SetPoint("TOPRIGHT", view.nextCardFrame, "BOTTOMRIGHT", 90, -15)
    view.resultBanner:SetHeight(26)
    view.chanceText = createText(view.table, 10, colors.text, "CENTER")
    view.chanceText:SetPoint("TOPLEFT", view.resultBanner, "BOTTOMLEFT", 0, -8)
    view.chanceText:SetPoint("TOPRIGHT", view.resultBanner, "BOTTOMRIGHT", 0, -8)
    view.chanceText:SetHeight(42)
    view.chanceText:SetWordWrap(true)

    view.controls = CreateFrame("Frame", nil, frame, templateName())
    view.controls:SetPoint("TOPLEFT", view.table, "BOTTOMLEFT", 0, -10)
    view.controls:SetPoint("TOPRIGHT", view.table, "BOTTOMRIGHT", 0, -10)
    view.controls:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    applyBackdrop(view.controls, colors.panel, colors.border)

    view.higher = createButton(view.controls, "HIGHER", 150, 38, function() view:Guess("HIGHER") end)
    view.higher:SetPoint("TOP", view.controls, "TOP", -90, -18)
    setButtonAccent(view.higher, colors.green)
    view.lower = createButton(view.controls, "LOWER", 150, 38, function() view:Guess("LOWER") end)
    view.lower:SetPoint("TOP", view.controls, "TOP", 90, -18)
    setButtonAccent(view.lower, colors.red)
    view.next = createButton(view.controls, "NEXT CARD", 180, 32, function() view:AdvanceRound() end)
    view.next:SetPoint("TOP", view.higher, "BOTTOM", 90, -12)
    setButtonAccent(view.next, colors.accent)

    view.betDown = createButton(view.controls, "BET -", 95, 26, function() view:ChangeBet(-view:BetStep()) end)
    view.betDown:SetPoint("BOTTOMLEFT", view.controls, "BOTTOMLEFT", 12, 10)
    view.betUp = createButton(view.controls, "BET +", 95, 26, function() view:ChangeBet(view:BetStep()) end)
    view.betUp:SetPoint("LEFT", view.betDown, "RIGHT", 7, 0)
    view.reset = createButton(view.controls, "NEW DECK", 104, 26, function() view:DealOrReset() end)
    view.reset:SetPoint("BOTTOMRIGHT", view.controls, "BOTTOMRIGHT", -12, 10)
    setButtonAccent(view.betDown, colors.gold)
    setButtonAccent(view.betUp, colors.gold)
    setButtonAccent(view.reset, colors.accent)

    view.stats = createText(view.controls, 9, colors.muted, "CENTER")
    view.stats:SetPoint("BOTTOMLEFT", view.betUp, "BOTTOMRIGHT", 12, 0)
    view.stats:SetPoint("BOTTOMRIGHT", view.reset, "BOTTOMLEFT", -12, 0)
    view.stats:SetHeight(26)

    function view:Draw()
        if not self.deck or (self.deckIndex or 1) > #self.deck then
            self.deck = shuffledDeck(floor(now()*1000) + (self.bank or 0) * 17 + (self.streak or 0) * 31)
            self.deckIndex = 1
        end
        local card = self.deck[self.deckIndex]
        self.deckIndex = self.deckIndex + 1
        return card
    end

    function view:BetStep()
        local bank = tonumber(self.bank) or 0
        if bank >= 5000 then return 250 end
        if bank >= 1000 then return 100 end
        if bank >= 250 then return 25 end
        return 5
    end

    function view:Save()
        local save = ensureSave()
        if not save then return end
        save.higherlower.bankroll = floor(max(0, tonumber(self.bank) or 0))
        save.higherlower.bestBank = floor(max(save.higherlower.bestBank or 100, save.higherlower.bankroll))
        save.higherlower.bestStreak = floor(max(save.higherlower.bestStreak or 0, self.streak or 0))
    end

    function view:ChangeBet(delta)
        if self.waiting or (self.bank or 0) <= 0 then return end
        local minimum = min(5, self.bank)
        self.bet = floor(clamp((self.bet or minimum) + delta, minimum, self.bank))
        self:Refresh()
    end

    function view:ResetBankroll()
        self.bank, self.bet, self.streak = 100, 10, 0
        self.resultCode, self.resultText, self.nextCard, self.waiting = nil, "Starter bank restored to 100.", nil, false
        self.deck = shuffledDeck(floor(now()*1000) + 319)
        self.deckIndex = 1
        self.currentCard = self:Draw()
        self:Save()
        self:Refresh()
        Solo:SetStatus("Higher or Lower bank reset to 100 starter chips.", colors.accent)
    end

    function view:DealOrReset()
        if (self.bank or 0) <= 0 then self:ResetBankroll(); return end
        self.deck = shuffledDeck(floor(now()*1000) + self.bank * 13)
        self.deckIndex = 1
        self.currentCard = self:Draw()
        self.nextCard = nil
        self.waiting = false
        self.resultCode = nil
        self.resultText = "New deck. Choose Higher or Lower."
        self:Refresh()
    end

    function view:Guess(choice)
        if self.waiting or not self.currentCard or (self.bank or 0) < (self.bet or 0) or self.bank <= 0 then return end
        choice = upper(tostring(choice or "HIGHER"))
        if choice ~= "HIGHER" and choice ~= "LOWER" then return end
        local currentRank = cardRank(self.currentCard)
        self.nextCard = self:Draw()
        local nextRank = cardRank(self.nextCard)
        self.bank = self.bank - self.bet
        local result
        if nextRank == currentRank then
            result = "DRAW"
            self.bank = self.bank + self.bet
        elseif (choice == "HIGHER" and nextRank > currentRank) or (choice == "LOWER" and nextRank < currentRank) then
            result = "WIN"
            self.bank = self.bank + self.bet * 2
            self.streak = (self.streak or 0) + 1
        else
            result = "LOSS"
            self.streak = 0
        end
        local save = ensureSave()
        if save then
            save.higherlower.games = (save.higherlower.games or 0) + 1
            if result == "WIN" then save.higherlower.wins = (save.higherlower.wins or 0) + 1
            elseif result == "LOSS" then save.higherlower.losses = (save.higherlower.losses or 0) + 1
            else save.higherlower.draws = (save.higherlower.draws or 0) + 1 end
        end
        self.resultCode = result
        self.resultText = choice .. " · " .. higherLowerRankName(self.currentCard) .. " → " .. higherLowerRankName(self.nextCard)
        self.waiting = true
        self:Save()
        Solo:RecordHistory("HIGHERLOWER", "SOLO", result, "Deck", self.resultText .. " · bet " .. formatChips(self.bet), self.streak or 0)
        Solo:PushLeaderboards()
        Solo:RefreshHub()
        if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer() end
        self:Refresh()
        Solo:SetStatus(result == "WIN" and "Correct — your streak continues." or (result == "DRAW" and "Equal card — your bet was returned." or "Wrong guess — the deck wins."), result == "WIN" and colors.green or (result == "DRAW" and colors.gold or colors.red))
    end

    function view:AdvanceRound()
        if not self.waiting or not self.nextCard then return end
        self.currentCard = self.nextCard
        self.nextCard = nil
        self.waiting = false
        self.resultCode = nil
        self.resultText = nil
        if self.bank > 0 then
            local minimum = min(5, self.bank)
            self.bet = floor(clamp(min(self.bet, self.bank), minimum, self.bank))
        else
            self.bet = 5
        end
        self:Refresh()
    end

    function view:Refresh()
        if self.deckButton and self.deckButton.RefreshDeck then self.deckButton:RefreshDeck() end
        local save = ensureSave()
        local bank = floor(max(0, tonumber(self.bank) or 0))
        self.bankText:SetText("BANK " .. formatChips(bank) .. "   ·   BET " .. formatChips(self.bet or 0) .. "   ·   STREAK " .. tostring(self.streak or 0))
        if self.currentCard then setCard(self.currentCardFrame, self.currentCard, false); self.currentCardFrame:Show() else self.currentCardFrame:Hide() end
        if self.nextCard then setCard(self.nextCardFrame, self.nextCard, false) else setCard(self.nextCardFrame, "AS", true) end
        local currentRank = self.currentCard and cardRank(self.currentCard) or 8
        local higherChance = floor(((14 - currentRank) / 13) * 100 + 0.5)
        local lowerChance = floor(((currentRank - 2) / 13) * 100 + 0.5)
        local equalChance = 100 - higherChance - lowerChance
        self.chanceText:SetText(self.waiting and (self.resultText or "") or format("Chance from %s · Higher %d%% · Lower %d%% · Equal %d%%", higherLowerRankName(self.currentCard), higherChance, lowerChance, equalChance))
        if self.resultCode then
            local color = self.resultCode == "WIN" and colors.green or (self.resultCode == "DRAW" and colors.gold or colors.red)
            self.resultBanner:SetText(self.resultCode == "WIN" and "YOU WON" or (self.resultCode == "DRAW" and "EQUAL · BET RETURNED" or "YOU LOST"))
            self.resultBanner:SetTextColor(color[1], color[2], color[3], 1)
        else
            self.resultBanner:SetText(bank <= 0 and "BANK EMPTY" or "MAKE YOUR GUESS")
            self.resultBanner:SetTextColor(colors.text[1], colors.text[2], colors.text[3], 1)
        end
        self.higher.label:SetText(self.actionIndex == 1 and "▶ HIGHER" or "HIGHER")
        self.lower.label:SetText(self.actionIndex == 2 and "▶ LOWER" or "LOWER")
        setButtonEnabled(self.higher, not self.waiting and bank >= self.bet and bank > 0)
        setButtonEnabled(self.lower, not self.waiting and bank >= self.bet and bank > 0)
        setButtonEnabled(self.next, self.waiting and self.nextCard ~= nil and bank > 0)
        local minimum = bank > 0 and min(5, bank) or 5
        setButtonEnabled(self.betDown, not self.waiting and bank > 0 and self.bet > minimum)
        setButtonEnabled(self.betUp, not self.waiting and bank > 0 and self.bet < bank)
        local step = self:BetStep()
        self.betDown.label:SetText("BET -" .. formatChips(step))
        self.betUp.label:SetText("BET +" .. formatChips(step))
        self.reset.label:SetText(bank <= 0 and "RESET 100" or "NEW DECK")
        self.stats:SetText(format("W %d   L %d   D %d   ·   BEST STREAK %d", save and save.higherlower.wins or 0, save and save.higherlower.losses or 0, save and save.higherlower.draws or 0, save and save.higherlower.bestStreak or 0))
    end

    function view:OnKeyDown(key)
        if key == "A" or key == "LEFT" then self.actionIndex = 1; self:Refresh()
        elseif key == "D" or key == "RIGHT" then self.actionIndex = 2; self:Refresh()
        elseif key == "W" or key == "UP" then self:ChangeBet(self:BetStep())
        elseif key == "S" or key == "DOWN" then self:ChangeBet(-self:BetStep())
        elseif key == "N" or key == "R" then self:DealOrReset()
        elseif key == "SPACE" or key == "ENTER" then
            if self.waiting then self:AdvanceRound()
            elseif self.actionIndex == 1 then self:Guess("HIGHER") else self:Guess("LOWER") end
        end
    end

    function view:StartSession()
        local save = ensureSave()
        self.bank = save and floor(max(0, tonumber(save.higherlower.bankroll) or 100)) or 100
        self.bet = self.bank > 0 and min(10, self.bank) or 5
        self.streak = 0
        self.actionIndex = 1
        self.waiting = false
        self.nextCard = nil
        self.resultCode = nil
        self.resultText = self.bank > 0 and ("Saved bank restored: " .. formatChips(self.bank) .. ".") or "Bank empty — press RESET 100."
        self.deck = shuffledDeck(floor(now()*1000) + 487 + self.bank * 7)
        self.deckIndex = 1
        self.currentCard = self:Draw()
        self:Refresh()
        Solo:SetStatus("Higher or Lower ready. Guess the next card.", colors.accent)
    end

    function view:Start() self:StartSession() end

    self.views.HIGHERLOWER = view
    return view
end

-- SOLO TETRIS -----------------------------------------------------------------
local SOLO_TETRIS_SHAPES = {
    I = {
        { {0,1},{1,1},{2,1},{3,1} }, { {2,0},{2,1},{2,2},{2,3} },
        { {0,2},{1,2},{2,2},{3,2} }, { {1,0},{1,1},{1,2},{1,3} },
    },
    O = {
        { {1,1},{2,1},{1,2},{2,2} }, { {1,1},{2,1},{1,2},{2,2} },
        { {1,1},{2,1},{1,2},{2,2} }, { {1,1},{2,1},{1,2},{2,2} },
    },
    T = {
        { {1,0},{0,1},{1,1},{2,1} }, { {1,0},{1,1},{2,1},{1,2} },
        { {0,1},{1,1},{2,1},{1,2} }, { {1,0},{0,1},{1,1},{1,2} },
    },
    S = {
        { {1,0},{2,0},{0,1},{1,1} }, { {1,0},{1,1},{2,1},{2,2} },
        { {1,1},{2,1},{0,2},{1,2} }, { {0,0},{0,1},{1,1},{1,2} },
    },
    Z = {
        { {0,0},{1,0},{1,1},{2,1} }, { {2,0},{1,1},{2,1},{1,2} },
        { {0,1},{1,1},{1,2},{2,2} }, { {1,0},{0,1},{1,1},{0,2} },
    },
    J = {
        { {0,0},{0,1},{1,1},{2,1} }, { {1,0},{2,0},{1,1},{1,2} },
        { {0,1},{1,1},{2,1},{2,2} }, { {1,0},{1,1},{0,2},{1,2} },
    },
    L = {
        { {2,0},{0,1},{1,1},{2,1} }, { {1,0},{1,1},{1,2},{2,2} },
        { {0,1},{1,1},{2,1},{0,2} }, { {0,0},{1,0},{1,1},{1,2} },
    },
}
local SOLO_TETRIS_KEYS = { "I", "O", "T", "S", "Z", "J", "L" }
local SOLO_TETRIS_FALLBACK = {
    I={0.15,0.75,0.90,1}, O={0.95,0.78,0.18,1}, T={0.62,0.32,0.90,1},
    S={0.20,0.75,0.35,1}, Z={0.90,0.22,0.25,1}, J={0.20,0.42,0.90,1}, L={0.95,0.48,0.14,1},
}
local SOLO_TETRIS_CPU_NAMES = { "CASUAL", "EASY", "NORMAL", "HARD", "MASTER" }
local SOLO_TETRIS_CPU_INTERVAL = { 4.2, 3.45, 2.80, 2.20, 1.65 }
local TETRIS_REVEAL_SEGMENTS = 10

local function buildTetrisRevealStrips(boardFrame, inset)
    boardFrame.revealStrips = {}
    local innerWidth = boardFrame:GetWidth() - inset * 2
    local innerHeight = boardFrame:GetHeight() - inset * 2
    local stripHeight = innerHeight / TETRIS_REVEAL_SEGMENTS
    for index = 1, TETRIS_REVEAL_SEGMENTS do
        -- Legacy TBC backdrops can cover BORDER-layer child textures. Place
        -- reveal artwork above the backdrop but below blocks and grid lines.
        local strip = boardFrame:CreateTexture(nil, "ARTWORK")
        if strip.SetDrawLayer then strip:SetDrawLayer("ARTWORK", -6) end
        strip:SetPoint("BOTTOMLEFT", boardFrame, "BOTTOMLEFT", inset, inset + (index - 1) * stripHeight)
        strip:SetSize(innerWidth, stripHeight + 1)
        strip:SetTexCoord(0, 1, 1 - index / TETRIS_REVEAL_SEGMENTS, 1 - (index - 1) / TETRIS_REVEAL_SEGMENTS)
        strip:Hide()
        boardFrame.revealStrips[index] = strip
    end
end
local function buildTetrisBoardGrid(boardFrame, inset, cellSize, columns, rows)
    boardFrame.gridLines = {}
    local width, height = columns * cellSize, rows * cellSize
    for x = 0, columns do
        local line = boardFrame:CreateTexture(nil, "ARTWORK")
        if line.SetDrawLayer then line:SetDrawLayer("ARTWORK", 2) end
        line:SetPoint("BOTTOMLEFT", boardFrame, "BOTTOMLEFT", inset + x * cellSize, inset)
        line:SetSize(1, height)
        line:SetColorTexture(0.72, 0.78, 0.86, 0.24)
        boardFrame.gridLines[#boardFrame.gridLines + 1] = line
    end
    for y = 0, rows do
        local line = boardFrame:CreateTexture(nil, "ARTWORK")
        if line.SetDrawLayer then line:SetDrawLayer("ARTWORK", 2) end
        line:SetPoint("BOTTOMLEFT", boardFrame, "BOTTOMLEFT", inset, inset + y * cellSize)
        line:SetSize(width, 1)
        line:SetColorTexture(0.72, 0.78, 0.86, 0.24)
        boardFrame.gridLines[#boardFrame.gridLines + 1] = line
    end
end

local function updateTetrisRevealStrips(boardFrame, theme, stage, alpha, revealing)
    if not boardFrame or not boardFrame.backgroundArt then return end
    local texture = theme and (theme.backgroundTexture or theme.texture) or nil
    stage = floor(max(0, min(TETRIS_REVEAL_SEGMENTS, tonumber(stage) or 0)))
    alpha = max(0, min(1, tonumber(alpha) or 0.68))

    if texture then
        boardFrame.backgroundArt:SetTexture(texture)
        boardFrame.backgroundArt:SetTexCoord(0, 1, 0, 1)
        if revealing then
            -- Show the complete artwork as a very dark silhouette. Each
            -- ten-line milestone overlays a bright cropped image band.
            boardFrame.backgroundArt:SetAlpha(0.92)
            boardFrame.backgroundArt:SetVertexColor(0.12, 0.14, 0.18, 1)
        else
            boardFrame.backgroundArt:SetAlpha(max(0.68, alpha))
            boardFrame.backgroundArt:SetVertexColor(1, 1, 1, 1)
        end
    else
        boardFrame.backgroundArt:SetTexture("Interface\\Buttons\\WHITE8X8")
        boardFrame.backgroundArt:SetColorTexture(0.008, 0.010, 0.016, 1)
        boardFrame.backgroundArt:SetAlpha(1)
        boardFrame.backgroundArt:SetVertexColor(1, 1, 1, 1)
    end

    for index, strip in ipairs(boardFrame.revealStrips or {}) do
        if texture and revealing and index <= stage then
            strip:SetTexture(texture)
            strip:SetAlpha(0.96)
            strip:SetVertexColor(1, 1, 1, 1)
            strip:Show()
        else
            strip:Hide()
        end
    end
end
local function soloTetrisRandom(view)
    view.rng = (view.rng * 1103515245 + 12345) % 2147483648
    return SOLO_TETRIS_KEYS[(floor(view.rng / 65536) % 7) + 1]
end

local function soloTetrisCPURandom(view, limit)
    view.cpuRng = ((view.cpuRng or 17) * 1664525 + 1013904223) % 2147483648
    if limit then return (floor(view.cpuRng / 65536) % limit) + 1 end
    return view.cpuRng
end

function Solo:BuildTETRISView()
    if self.views.TETRIS then return self.views.TETRIS end
    local colors = palette()
    local view = {
        game = "TETRIS",
        cells = {}, guides = {}, shines = {}, cpuCells = {}, cpuShines = {},
        previewCells = {}, passRows = {}, themeRows = {}, backgroundRows = {},
        passPage = 1, themePage = 1, backgroundPage = 1,
        themeFilterUnlocked = false, backgroundFilter = "ALL", previewThemeKey = nil,
    }
    local frame = CreateFrame("Frame", nil, self.window.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.tabs = CreateFrame("Frame", nil, frame)
    view.tabs:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -10)
    view.tabs:SetSize(680, 30)
    view.tabButtons = {}
    local tabData = {
        { key="ENDLESS", label="TIMED ENDLESS", width=122 },
        { key="CPU", label="VS CPU", width=82 },
        { key="PASS", label="TETRIS PASS", width=104 },
        { key="THEMES", label="BLOCK THEMES", width=110 },
        { key="BACKGROUNDS", label="BACKGROUNDS", width=116 },
    }
    for index, info in ipairs(tabData) do
        local width = info.width or 92
        local button = createButton(view.tabs, info.label, width, 28, function() view:SelectTab(info.key) end)
        if index == 1 then button:SetPoint("LEFT", view.tabs, "LEFT", 0, 0) else button:SetPoint("LEFT", view.tabButtons[index - 1], "RIGHT", 6, 0) end
        view.tabButtons[index] = button
        view.tabButtons[info.key] = button
    end

    local boardCellSize = 18
    local function buildBoard(parent, cells, shines)
        local boardFrame = CreateFrame("Frame", nil, parent, templateName())
        boardFrame:SetSize(196, 380)
        applyBackdrop(boardFrame, {0.018,0.022,0.030,1}, colors.border)
        boardFrame.backgroundArt = boardFrame:CreateTexture(nil, "ARTWORK")
        if boardFrame.backgroundArt.SetDrawLayer then boardFrame.backgroundArt:SetDrawLayer("ARTWORK", -8) end
        boardFrame.backgroundArt:SetPoint("TOPLEFT", boardFrame, "TOPLEFT", 7, -7)
        boardFrame.backgroundArt:SetPoint("BOTTOMRIGHT", boardFrame, "BOTTOMRIGHT", -7, 7)
        boardFrame.backgroundArt:SetTexture("Interface\\Buttons\\WHITE8X8")
        boardFrame.backgroundArt:SetAlpha(0.34)
        buildTetrisRevealStrips(boardFrame, 7)
        buildTetrisBoardGrid(boardFrame, 8, boardCellSize, 10, 20)
        for y = 1, 20 do
            cells[y], shines[y] = {}, {}
            for x = 1, 10 do
                local cell = boardFrame:CreateTexture(nil, "ARTWORK")
                cell:SetTexture("Interface\\Buttons\\WHITE8X8")
                cell:SetSize(boardCellSize - 1, boardCellSize - 1)
                cell:SetPoint("BOTTOMLEFT", boardFrame, "BOTTOMLEFT", 8 + (x - 1) * boardCellSize, 8 + (y - 1) * boardCellSize)
                cell:SetColorTexture(0.055, 0.062, 0.078, 1)
                cells[y][x] = cell
                local shine = boardFrame:CreateTexture(nil, "OVERLAY")
                shine:SetTexture("Interface\\Buttons\\WHITE8X8")
                shine:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
                shine:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -2, -2)
                shine:SetHeight(2)
                shine:Hide()
                shines[y][x] = shine
            end
        end
        return boardFrame
    end

    view.youLabel = createText(frame, 9, colors.accent, "CENTER")
    view.youLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -41)
    view.youLabel:SetWidth(196)
    view.youLabel:SetText("YOU")
    view.boardFrame = buildBoard(frame, view.cells, view.shines)
    view.boardFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -52)
    view.guides = {}
    for x = 1, 10 do
        local guide = view.boardFrame:CreateTexture(nil, "OVERLAY")
        guide:SetTexture("Interface\\Buttons\\WHITE8X8")
        guide:SetSize(1, 1)
        guide.boardFrame = view.boardFrame
        guide.column = x
        guide:Hide()
        view.guides[x] = guide
    end

    view.cpuLabel = createText(frame, 9, colors.gold, "CENTER")
    view.cpuLabel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -41)
    view.cpuLabel:SetWidth(196)
    view.cpuLabel:SetText("COMPUTER")
    view.cpuBoardFrame = buildBoard(frame, view.cpuCells, view.cpuShines)
    view.cpuBoardFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -52)
    view.cpuBoardFrame:Hide(); view.cpuLabel:Hide()

    view.side = CreateFrame("Frame", nil, frame, templateName())
    applyBackdrop(view.side, colors.panel, colors.border)
    view.title = createText(view.side, 16, colors.text, "LEFT")
    view.title:SetPoint("TOPLEFT", view.side, "TOPLEFT", 12, -12)
    view.title:SetPoint("RIGHT", view.side, "RIGHT", -12, 0)
    view.title:SetText("TIMED ENDLESS")

    view.themeLine = CreateFrame("Frame", nil, view.side)
    view.themeLine:SetPoint("TOPLEFT", view.title, "BOTTOMLEFT", 0, -5)
    view.themeLine:SetPoint("RIGHT", view.side, "RIGHT", -12, 0)
    view.themeLine:SetHeight(27)
    view.themePrev = createButton(view.themeLine, "<", 28, 23, function() view:CycleUnlockedTheme(-1) end)
    view.themePrev:SetPoint("LEFT", view.themeLine, "LEFT", 0, 0)
    view.themeText = createText(view.themeLine, 9, colors.muted, "CENTER")
    view.themeText:SetPoint("LEFT", view.themePrev, "RIGHT", 4, 0)
    view.themeText:SetPoint("RIGHT", view.themeLine, "RIGHT", -32, 0)
    view.themeNext = createButton(view.themeLine, ">", 28, 23, function() view:CycleUnlockedTheme(1) end)
    view.themeNext:SetPoint("RIGHT", view.themeLine, "RIGHT", 0, 0)

    view.backgroundLine = createButton(view.side, "IMAGE BACKGROUND", 120, 24, function() view:SelectTab("BACKGROUNDS") end)
    view.backgroundLine:ClearAllPoints()
    view.backgroundLine:SetPoint("TOPLEFT", view.themeLine, "BOTTOMLEFT", 0, -5)
    view.backgroundLine:SetPoint("RIGHT", view.side, "RIGHT", -12, 0)
    view.backgroundLine:SetHeight(24)
    setButtonAccent(view.backgroundLine, colors.green)

    local function createMetricCard(parent, label, accent)
        local card = CreateFrame("Frame", nil, parent, templateName())
        applyBackdrop(card, colors.panelSoft, colors.border)
        card.accent = card:CreateTexture(nil, "ARTWORK")
        card.accent:SetTexture("Interface\\Buttons\\WHITE8X8")
        card.accent:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
        card.accent:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
        card.accent:SetHeight(2)
        card.accent:SetColorTexture(accent[1], accent[2], accent[3], 0.95)
        card.label = createText(card, 8, colors.muted, "LEFT")
        card.label:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -6)
        card.label:SetText(label)
        card.value = createText(card, 15, colors.text, "LEFT")
        card.value:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 7, 5)
        card.value:SetPoint("RIGHT", card, "RIGHT", -5, 0)
        return card
    end

    view.metricGrid = CreateFrame("Frame", nil, view.side)
    view.metricGrid:SetPoint("TOPLEFT", view.backgroundLine, "BOTTOMLEFT", 0, -7)
    view.metricGrid:SetPoint("RIGHT", view.side, "RIGHT", -12, 0)
    view.metricGrid:SetHeight(76)
    view.scoreCard = createMetricCard(view.metricGrid, "SCORE", colors.accent)
    view.scoreCard:SetPoint("TOPLEFT", view.metricGrid, "TOPLEFT", 0, 0)
    view.scoreCard:SetPoint("RIGHT", view.metricGrid, "CENTER", -3, 0)
    view.scoreCard:SetHeight(35)
    view.linesCard = createMetricCard(view.metricGrid, "LINES", colors.gold)
    view.linesCard:SetPoint("TOPLEFT", view.metricGrid, "TOP", 3, 0)
    view.linesCard:SetPoint("RIGHT", view.metricGrid, "RIGHT", 0, 0)
    view.linesCard:SetHeight(35)
    view.speedCard = createMetricCard(view.metricGrid, "SPEED", colors.green)
    view.speedCard:SetPoint("BOTTOMLEFT", view.metricGrid, "BOTTOMLEFT", 0, 0)
    view.speedCard:SetPoint("RIGHT", view.metricGrid, "CENTER", -3, 0)
    view.speedCard:SetHeight(35)
    view.timeCard = createMetricCard(view.metricGrid, "TIME / MODE", colors.muted)
    view.timeCard:SetPoint("BOTTOMLEFT", view.metricGrid, "BOTTOM", 3, 0)
    view.timeCard:SetPoint("RIGHT", view.metricGrid, "RIGHT", 0, 0)
    view.timeCard:SetHeight(35)

    view.stats = createText(view.side, 1, colors.text, "LEFT")
    view.stats:Hide()

    view.revealCard = CreateFrame("Frame", nil, view.side, templateName())
    view.revealCard:SetPoint("TOPLEFT", view.metricGrid, "BOTTOMLEFT", 0, -6)
    view.revealCard:SetPoint("RIGHT", view.side, "RIGHT", -12, 0)
    view.revealCard:SetHeight(42)
    applyBackdrop(view.revealCard, colors.panelSoft, colors.border)
    view.revealTitle = createText(view.revealCard, 9, colors.text, "LEFT")
    view.revealTitle:SetPoint("TOPLEFT", view.revealCard, "TOPLEFT", 7, -5)
    view.revealTitle:SetPoint("RIGHT", view.revealCard, "RIGHT", -7, 0)
    view.revealBar = CreateFrame("StatusBar", nil, view.revealCard)
    view.revealBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    view.revealBar:SetPoint("BOTTOMLEFT", view.revealCard, "BOTTOMLEFT", 7, 7)
    view.revealBar:SetPoint("BOTTOMRIGHT", view.revealCard, "BOTTOMRIGHT", -7, 7)
    view.revealBar:SetHeight(9)
    view.revealBar:SetMinMaxValues(0, 100)
    view.revealBar:SetStatusBarColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.95)
    view.revealBarText = createText(view.revealBar, 7, colors.text, "CENTER")
    view.revealBarText:SetAllPoints()

    view.nextLabel = createText(view.side, 9, colors.muted, "LEFT")
    view.nextLabel:SetPoint("TOPLEFT", view.revealCard, "BOTTOMLEFT", 0, -5)
    view.nextLabel:SetText("NEXT PIECE")
    view.nextBox = CreateFrame("Frame", nil, view.side, templateName())
    view.nextBox:SetSize(68, 42)
    view.nextBox:SetPoint("TOPLEFT", view.nextLabel, "BOTTOMLEFT", 0, -3)
    applyBackdrop(view.nextBox, darken(colors.accent, 0.22), colors.accent)
    view.nextText = createText(view.nextBox, 21, colors.text, "CENTER")
    view.nextText:SetAllPoints()

    view.cpuInfo = CreateFrame("Frame", nil, view.side, templateName())
    view.cpuInfo:SetPoint("TOPLEFT", view.nextBox, "TOPRIGHT", 8, 0)
    view.cpuInfo:SetPoint("RIGHT", view.side, "RIGHT", -12, 0)
    view.cpuInfo:SetHeight(42)
    applyBackdrop(view.cpuInfo, colors.panelSoft, colors.border)
    view.cpuYou = createText(view.cpuInfo, 9, colors.accent, "LEFT")
    view.cpuYou:SetPoint("LEFT", view.cpuInfo, "LEFT", 7, 0)
    view.cpuYou:SetPoint("RIGHT", view.cpuInfo, "CENTER", -12, 0)
    view.cpuVs = createText(view.cpuInfo, 9, colors.gold, "CENTER")
    view.cpuVs:SetPoint("CENTER", view.cpuInfo, "CENTER", 0, 0)
    view.cpuVs:SetText("VS")
    view.cpuThem = createText(view.cpuInfo, 9, colors.gold, "RIGHT")
    view.cpuThem:SetPoint("LEFT", view.cpuInfo, "CENTER", 12, 0)
    view.cpuThem:SetPoint("RIGHT", view.cpuInfo, "RIGHT", -7, 0)

    view.cpuLevel = createButton(view.side, "CPU: NORMAL", 112, 24, function() view:CycleCPU() end)
    view.cpuLevel:SetPoint("BOTTOMLEFT", view.side, "BOTTOMLEFT", 12, 124)
    view.cpuFormat = createButton(view.side, "FORMAT: ENDLESS", 132, 24, function() view:CycleCPUFormat() end)
    view.cpuFormat:SetPoint("LEFT", view.cpuLevel, "RIGHT", 6, 0)
    view.durationButton = createButton(view.side, "TIME: 10 MIN", 132, 24, function() view:CycleSoloDuration() end)
    view.durationButton:SetPoint("BOTTOMLEFT", view.side, "BOTTOMLEFT", 12, 154)
    setButtonAccent(view.cpuLevel, colors.gold)
    setButtonAccent(view.cpuFormat, colors.accent)
    setButtonAccent(view.durationButton, colors.green)

    view.controlsPanel = CreateFrame("Frame", nil, view.side, templateName())
    view.controlsPanel:SetPoint("BOTTOMLEFT", view.side, "BOTTOMLEFT", 12, 79)
    view.controlsPanel:SetPoint("BOTTOMRIGHT", view.side, "BOTTOMRIGHT", -12, 79)
    view.controlsPanel:SetHeight(38)
    applyBackdrop(view.controlsPanel, colors.panelSoft, colors.border)
    view.help = createText(view.controlsPanel, 8, colors.muted, "CENTER")
    view.help:SetPoint("TOPLEFT", view.controlsPanel, "TOPLEFT", 5, -5)
    view.help:SetPoint("BOTTOMRIGHT", view.controlsPanel, "BOTTOMRIGHT", -5, 5)
    view.help:SetWordWrap(true)
    view.help:SetText("MOVE  A/D or arrows   ·   ROTATE  W/Up   ·   SOFT DROP  S/Down\nHARD DROP  Space   ·   PAUSE  P   ·   RESTART  R")

    view.left = createButton(view.side, "<", 42, 26, function() view:Move(-1, 0) end)
    view.left:SetPoint("BOTTOMLEFT", view.side, "BOTTOMLEFT", 12, 46)
    view.rotate = createButton(view.side, "ROT", 48, 26, function() view:Rotate() end)
    view.rotate:SetPoint("LEFT", view.left, "RIGHT", 5, 0)
    view.right = createButton(view.side, ">", 42, 26, function() view:Move(1, 0) end)
    view.right:SetPoint("LEFT", view.rotate, "RIGHT", 5, 0)
    view.drop = createButton(view.side, "DROP", 62, 26, function() view:HardDrop() end)
    view.drop:SetPoint("LEFT", view.right, "RIGHT", 5, 0)
    view.pause = createButton(view.side, "PAUSE", 66, 26, function() view:TogglePause() end)
    view.pause:SetPoint("BOTTOMLEFT", view.side, "BOTTOMLEFT", 12, 12)
    view.restart = createButton(view.side, "RESTART", 72, 26, function() view:Start() end)
    view.restart:SetPoint("LEFT", view.pause, "RIGHT", 6, 0)
    view.randomTheme = createButton(view.side, "THEMES", 70, 26, function() view:SelectTab("THEMES") end)
    view.randomTheme:SetPoint("LEFT", view.restart, "RIGHT", 6, 0)
    setButtonAccent(view.rotate, colors.accent); setButtonAccent(view.drop, colors.gold)
    setButtonAccent(view.pause, colors.muted); setButtonAccent(view.restart, colors.red); setButtonAccent(view.randomTheme, colors.accent)

    -- Tetris Pass panel -------------------------------------------------------
    view.passPanel = CreateFrame("Frame", nil, frame, templateName())
    view.passPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -50)
    view.passPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)
    applyBackdrop(view.passPanel, colors.panel, colors.border)
    view.passPanel:Hide()
    view.passTitle = createText(view.passPanel, 18, colors.text, "LEFT")
    view.passTitle:SetPoint("TOPLEFT", view.passPanel, "TOPLEFT", 16, -14)
    view.passTitle:SetText("TETRIS PASS · 100 LEVELS")
    view.passSummary = createText(view.passPanel, 10, colors.muted, "LEFT")
    view.passSummary:SetPoint("TOPLEFT", view.passTitle, "BOTTOMLEFT", 0, -5)
    view.passSummary:SetPoint("RIGHT", view.passPanel, "RIGHT", -180, 0)
    view.passBar = CreateFrame("StatusBar", nil, view.passPanel)
    view.passBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    view.passBar:SetPoint("TOPLEFT", view.passSummary, "BOTTOMLEFT", 0, -8)
    view.passBar:SetSize(470, 12)
    view.passBar:SetMinMaxValues(0, 1); view.passBar:SetValue(0)
    view.passBar:SetStatusBarColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.95)
    view.passBarText = createText(view.passBar, 8, colors.text, "CENTER"); view.passBarText:SetAllPoints()
    view.claimAll = createButton(view.passPanel, "CLAIM ALL", 96, 28, function()
        if CC.Tetris and CC.Tetris.ClaimAllPassRewards then CC.Tetris:ClaimAllPassRewards() end
    end)
    view.claimAll:SetPoint("TOPRIGHT", view.passPanel, "TOPRIGHT", -16, -16); setButtonAccent(view.claimAll, colors.gold)
    for index = 1, 8 do
        local row = CreateFrame("Frame", nil, view.passPanel, templateName())
        row:SetPoint("TOPLEFT", view.passPanel, "TOPLEFT", 16, -82 - (index - 1) * 50)
        row:SetPoint("RIGHT", view.passPanel, "RIGHT", -16, 0); row:SetHeight(44)
        applyBackdrop(row, colors.panelSoft, colors.border)
        row.title = createText(row, 10, colors.text, "LEFT"); row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -7); row.title:SetPoint("RIGHT", row, "RIGHT", -132, 0)
        row.detail = createText(row, 8, colors.muted, "LEFT"); row.detail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 6); row.detail:SetPoint("RIGHT", row, "RIGHT", -132, 0)
        row.button = createButton(row, "LOCKED", 104, 26, function() if row.level and CC.Tetris and CC.Tetris.ClaimPassReward then CC.Tetris:ClaimPassReward(row.level) end end)
        row.button:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        view.passRows[index] = row
    end
    view.passPrev = createButton(view.passPanel, "< PREV", 78, 26, function() view.passPage = max(1, (view.passPage or 1) - 1); view:RefreshPassPanel() end)
    view.passPrev:SetPoint("BOTTOMLEFT", view.passPanel, "BOTTOMLEFT", 16, 12)
    view.passPageText = createText(view.passPanel, 9, colors.muted, "CENTER"); view.passPageText:SetPoint("BOTTOM", view.passPanel, "BOTTOM", 0, 19)
    view.passNext = createButton(view.passPanel, "NEXT >", 78, 26, function() view.passPage = min(13, (view.passPage or 1) + 1); view:RefreshPassPanel() end)
    view.passNext:SetPoint("BOTTOMRIGHT", view.passPanel, "BOTTOMRIGHT", -16, 12)

    -- Theme collection panel -------------------------------------------------
    view.themePanel = CreateFrame("Frame", nil, frame, templateName())
    view.themePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -50)
    view.themePanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)
    applyBackdrop(view.themePanel, colors.panel, colors.border); view.themePanel:Hide()
    view.themeTitle = createText(view.themePanel, 18, colors.text, "LEFT")
    view.themeTitle:SetPoint("TOPLEFT", view.themePanel, "TOPLEFT", 16, -14); view.themeTitle:SetText("TETRIS BLOCK THEMES")
    view.themeSummary = createText(view.themePanel, 10, colors.muted, "LEFT")
    view.themeSummary:SetPoint("TOPLEFT", view.themeTitle, "BOTTOMLEFT", 0, -5); view.themeSummary:SetPoint("RIGHT", view.themePanel, "RIGHT", -132, 0)
    view.themeFilter = createButton(view.themePanel, "SHOW: ALL", 104, 26, function()
        view.themeFilterUnlocked = not view.themeFilterUnlocked; view.themePage = 1; view:RefreshThemePanel()
    end)
    view.themeFilter:SetPoint("TOPRIGHT", view.themePanel, "TOPRIGHT", -16, -16)

    for index = 1, 6 do
        local row = CreateFrame("Frame", nil, view.themePanel, templateName())
        row:SetPoint("TOPLEFT", view.themePanel, "TOPLEFT", 16, -68 - (index - 1) * 65)
        row:SetPoint("RIGHT", view.themePanel, "RIGHT", -312, 0); row:SetHeight(58)
        applyBackdrop(row, colors.panelSoft, colors.border); row:EnableMouse(true)
        row.backgroundFrame = cardFrame(row, 42, 42)
        row.backgroundFrame:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.backgroundTexture = row.backgroundFrame:CreateTexture(nil, "ARTWORK")
        row.backgroundTexture:SetPoint("TOPLEFT", row.backgroundFrame, "TOPLEFT", 2, -2)
        row.backgroundTexture:SetPoint("BOTTOMRIGHT", row.backgroundFrame, "BOTTOMRIGHT", -2, 2)
        row.backgroundTexture:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.name = createText(row, 10, colors.text, "LEFT"); row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 56, -7); row.name:SetPoint("RIGHT", row, "RIGHT", -104, 0)
        row.requirement = createText(row, 8, colors.muted, "LEFT"); row.requirement:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -4); row.requirement:SetPoint("RIGHT", row, "RIGHT", -104, 0)
        row.swatches = {}
        for swatchIndex = 1, 7 do
            local swatch = row:CreateTexture(nil, "ARTWORK")
            swatch:SetTexture("Interface\\Buttons\\WHITE8X8"); swatch:SetSize(15, 8)
            if swatchIndex == 1 then swatch:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 56, 7) else swatch:SetPoint("LEFT", row.swatches[swatchIndex - 1], "RIGHT", 3, 0) end
            row.swatches[swatchIndex] = swatch
        end
        row.button = createButton(row, "PREVIEW", 82, 27, function()
            if not row.themeKey or not CC.Tetris then return end
            if CC.Tetris:IsThemeUnlocked(row.themeKey) then
                local theme = CC.Tetris:GetTheme(row.themeKey)
                view.previewThemeKey = row.themeKey
                CC.Tetris:SelectTheme(row.themeKey)
                view:RefreshThemePanel()
                Solo:SetStatus(theme.name .. " Tetris pieces equipped.", colors.green)
            else view:PreviewTheme(row.themeKey) end
        end)
        row.button:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" and row.themeKey then view:PreviewTheme(row.themeKey) end end)
        view.themeRows[index] = row
    end
    view.themePrevPage = createButton(view.themePanel, "< PREV", 78, 26, function() view.themePage = max(1, (view.themePage or 1) - 1); view:RefreshThemePanel() end)
    view.themePrevPage:SetPoint("BOTTOMLEFT", view.themePanel, "BOTTOMLEFT", 16, 12)
    view.themePageText = createText(view.themePanel, 9, colors.muted, "CENTER"); view.themePageText:SetPoint("BOTTOM", view.themePanel, "BOTTOM", -142, 19)
    view.themeNextPage = createButton(view.themePanel, "NEXT >", 78, 26, function() view.themePage = (view.themePage or 1) + 1; view:RefreshThemePanel() end)
    view.themeNextPage:SetPoint("BOTTOM", view.themePanel, "BOTTOM", -45, 12)

    view.previewPanel = CreateFrame("Frame", nil, view.themePanel, templateName())
    view.previewPanel:SetPoint("TOPRIGHT", view.themePanel, "TOPRIGHT", -16, -68)
    view.previewPanel:SetPoint("BOTTOMRIGHT", view.themePanel, "BOTTOMRIGHT", -16, 12)
    view.previewPanel:SetWidth(280)
    applyBackdrop(view.previewPanel, colors.panelSoft, colors.border)
    view.previewTitle = createText(view.previewPanel, 14, colors.text, "CENTER")
    view.previewTitle:SetPoint("TOPLEFT", view.previewPanel, "TOPLEFT", 10, -10); view.previewTitle:SetPoint("RIGHT", view.previewPanel, "RIGHT", -10, 0)
    view.previewRequirement = createText(view.previewPanel, 8, colors.muted, "CENTER")
    view.previewRequirement:SetPoint("TOPLEFT", view.previewTitle, "BOTTOMLEFT", 0, -4); view.previewRequirement:SetPoint("RIGHT", view.previewPanel, "RIGHT", -10, 0)
    view.previewBoard = CreateFrame("Frame", nil, view.previewPanel, templateName())
    view.previewBoard:SetSize(196, 232); view.previewBoard:SetPoint("TOP", view.previewRequirement, "BOTTOM", 0, -8)
    view.previewBackground = view.previewBoard:CreateTexture(nil, "BACKGROUND")
    view.previewBackground:SetAllPoints()
    view.previewBackground:SetTexture("Interface\\Buttons\\WHITE8X8")
    view.previewBackground:SetAlpha(0.48)
    local previewCellSize = 18
    for y = 1, 12 do
        view.previewCells[y] = {}
        for x = 1, 10 do
            local cell = view.previewBoard:CreateTexture(nil, "ARTWORK")
            cell:SetTexture("Interface\\Buttons\\WHITE8X8"); cell:SetSize(previewCellSize - 1, previewCellSize - 1)
            cell:SetPoint("BOTTOMLEFT", view.previewBoard, "BOTTOMLEFT", 8 + (x - 1) * previewCellSize, 8 + (y - 1) * previewCellSize)
            view.previewCells[y][x] = cell
        end
    end
    view.previewNote = createText(view.previewPanel, 9, colors.muted, "CENTER")
    view.previewNote:SetPoint("TOPLEFT", view.previewBoard, "BOTTOMLEFT", -28, -8); view.previewNote:SetPoint("RIGHT", view.previewPanel, "RIGHT", -10, 0)
    view.previewNote:SetHeight(54); view.previewNote:SetWordWrap(true)
    view.previewAction = createButton(view.previewPanel, "EQUIP NOW", 144, 28, function() view:UsePreviewTheme() end)
    view.previewAction:SetPoint("BOTTOM", view.previewPanel, "BOTTOM", 0, 14)

    -- Reveal background collection -------------------------------------------
    view.backgroundPanel = CreateFrame("Frame", nil, frame, templateName())
    view.backgroundPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -50)
    view.backgroundPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)
    applyBackdrop(view.backgroundPanel, colors.panel, colors.border)
    view.backgroundPanel:Hide()
    view.backgroundTitle = createText(view.backgroundPanel, 18, colors.text, "LEFT")
    view.backgroundTitle:SetPoint("TOPLEFT", view.backgroundPanel, "TOPLEFT", 16, -14)
    view.backgroundTitle:SetText("TETRIS IMAGE BACKGROUNDS")
    view.backgroundSummary = createText(view.backgroundPanel, 10, colors.muted, "LEFT")
    view.backgroundSummary:SetPoint("TOPLEFT", view.backgroundTitle, "BOTTOMLEFT", 0, -5)
    view.backgroundSummary:SetPoint("RIGHT", view.backgroundPanel, "RIGHT", -150, 0)
    view.backgroundFilterButton = createButton(view.backgroundPanel, "SHOW: ALL", 118, 26, function()
        local order = { ALL="UNLOCKED", UNLOCKED="LOCKED", LOCKED="ALL" }
        view.backgroundFilter = order[view.backgroundFilter or "ALL"] or "ALL"
        view.backgroundPage = 1
        view:RefreshBackgroundPanel()
    end)
    view.backgroundFilterButton:SetPoint("TOPRIGHT", view.backgroundPanel, "TOPRIGHT", -16, -16)

    for index = 1, 8 do
        local col = (index - 1) % 4
        local rowIndex = floor((index - 1) / 4)
        local tile = CreateFrame("Frame", nil, view.backgroundPanel, templateName())
        tile:SetSize(164, 196)
        tile:SetPoint("TOPLEFT", view.backgroundPanel, "TOPLEFT", 16 + col * 174, -70 - rowIndex * 206)
        applyBackdrop(tile, colors.panelSoft, colors.border)
        tile.imageFrame = CreateFrame("Frame", nil, tile, templateName())
        tile.imageFrame:SetPoint("TOPLEFT", tile, "TOPLEFT", 7, -7)
        tile.imageFrame:SetPoint("TOPRIGHT", tile, "TOPRIGHT", -7, -7)
        tile.imageFrame:SetHeight(122)
        applyBackdrop(tile.imageFrame, colors.panelRaised, colors.border)
        tile.image = tile.imageFrame:CreateTexture(nil, "ARTWORK")
        tile.image:SetPoint("TOPLEFT", tile.imageFrame, "TOPLEFT", 2, -2)
        tile.image:SetPoint("BOTTOMRIGHT", tile.imageFrame, "BOTTOMRIGHT", -2, 2)
        tile.shade = tile.imageFrame:CreateTexture(nil, "OVERLAY")
        tile.shade:SetAllPoints(tile.image)
        tile.shade:SetColorTexture(0, 0, 0, 0.55)
        tile.name = createText(tile, 9, colors.text, "CENTER")
        tile.name:SetPoint("TOPLEFT", tile.imageFrame, "BOTTOMLEFT", 1, -6)
        tile.name:SetPoint("RIGHT", tile, "RIGHT", -8, 0)
        tile.state = createText(tile, 8, colors.muted, "CENTER")
        tile.state:SetPoint("TOPLEFT", tile.name, "BOTTOMLEFT", 0, -3)
        tile.state:SetPoint("RIGHT", tile, "RIGHT", -8, 0)
        tile.action = createButton(tile, "PREVIEW", 94, 24, function()
            if tile.themeKey then view:OpenBackgroundPreview(tile.themeKey) end
        end)
        tile:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and tile.themeKey then view:OpenBackgroundPreview(tile.themeKey) end
        end)
        tile.action:SetPoint("BOTTOM", tile, "BOTTOM", 0, 7)
        view.backgroundRows[index] = tile
    end
    view.backgroundPrev = createButton(view.backgroundPanel, "< PREV", 78, 26, function()
        view.backgroundPage = max(1, (view.backgroundPage or 1) - 1)
        view:RefreshBackgroundPanel()
    end)
    view.backgroundPrev:SetPoint("BOTTOMLEFT", view.backgroundPanel, "BOTTOMLEFT", 16, 12)
    view.backgroundPageText = createText(view.backgroundPanel, 9, colors.muted, "CENTER")
    view.backgroundPageText:SetPoint("BOTTOM", view.backgroundPanel, "BOTTOM", 0, 19)
    view.backgroundNext = createButton(view.backgroundPanel, "NEXT >", 78, 26, function()
        view.backgroundPage = (view.backgroundPage or 1) + 1
        view:RefreshBackgroundPanel()
    end)
    view.backgroundNext:SetPoint("BOTTOMRIGHT", view.backgroundPanel, "BOTTOMRIGHT", -16, 12)

    view.backgroundPreview = CreateFrame("Frame", nil, view.backgroundPanel, templateName())
    view.backgroundPreview:SetSize(500, 500)
    view.backgroundPreview:SetPoint("CENTER", view.backgroundPanel, "CENTER", 0, -4)
    view.backgroundPreview:SetFrameLevel(view.backgroundPanel:GetFrameLevel() + 30)
    applyBackdrop(view.backgroundPreview, colors.panel, colors.accent)
    view.backgroundPreview:Hide()
    view.backgroundPreviewTitle = createText(view.backgroundPreview, 17, colors.text, "CENTER")
    view.backgroundPreviewTitle:SetPoint("TOPLEFT", view.backgroundPreview, "TOPLEFT", 14, -13)
    view.backgroundPreviewTitle:SetPoint("RIGHT", view.backgroundPreview, "RIGHT", -14, 0)
    view.backgroundPreviewImageFrame = CreateFrame("Frame", nil, view.backgroundPreview, templateName())
    view.backgroundPreviewImageFrame:SetSize(360, 360)
    view.backgroundPreviewImageFrame:SetPoint("TOP", view.backgroundPreviewTitle, "BOTTOM", 0, -10)
    applyBackdrop(view.backgroundPreviewImageFrame, colors.panelRaised, colors.border)
    view.backgroundPreviewImage = view.backgroundPreviewImageFrame:CreateTexture(nil, "ARTWORK")
    view.backgroundPreviewImage:SetPoint("TOPLEFT", view.backgroundPreviewImageFrame, "TOPLEFT", 3, -3)
    view.backgroundPreviewImage:SetPoint("BOTTOMRIGHT", view.backgroundPreviewImageFrame, "BOTTOMRIGHT", -3, 3)
    view.backgroundPreviewShade = view.backgroundPreviewImageFrame:CreateTexture(nil, "OVERLAY")
    view.backgroundPreviewShade:SetAllPoints(view.backgroundPreviewImage)
    view.backgroundPreviewState = createText(view.backgroundPreview, 9, colors.muted, "CENTER")
    view.backgroundPreviewState:SetPoint("TOP", view.backgroundPreviewImageFrame, "BOTTOM", 0, -8)
    view.backgroundPreviewState:SetPoint("LEFT", view.backgroundPreview, "LEFT", 18, 0)
    view.backgroundPreviewState:SetPoint("RIGHT", view.backgroundPreview, "RIGHT", -18, 0)
    view.backgroundPreviewEquip = createButton(view.backgroundPreview, "EQUIP BACKGROUND", 148, 28, function()
        if not view.previewBackgroundKey or not CC.Tetris then return end
        local background = CC.Tetris:GetBackground(view.previewBackgroundKey)
        if CC.Tetris:IsBackgroundUnlocked(view.previewBackgroundKey) and CC.Tetris:SelectBackground(view.previewBackgroundKey) then
            Solo:SetStatus(background.name .. " image background equipped.", colors.green)
            view:OpenBackgroundPreview(view.previewBackgroundKey)
            view:RefreshBackgroundPanel()
        end
    end)
    view.backgroundPreviewEquip:SetPoint("BOTTOMLEFT", view.backgroundPreview, "BOTTOMLEFT", 88, 14)
    view.backgroundPreviewClose = createButton(view.backgroundPreview, "CLOSE", 92, 28, function() view.backgroundPreview:Hide() end)
    view.backgroundPreviewClose:SetPoint("BOTTOMRIGHT", view.backgroundPreview, "BOTTOMRIGHT", -88, 14)
    setButtonAccent(view.backgroundPreviewEquip, colors.accent)
    setButtonAccent(view.backgroundPreviewClose, colors.red)

    local ATTACK_LINES = { [1] = 1, [2] = 2, [3] = 4, [4] = 6 }
    local ENDLESS_DURATIONS = { 5, 10, 15, 30, 45, 60 }
    local PREVIEW_PATTERN = {
        "JJJ....LLL", "JSS..ZZ..L", ".SS.TTZZ.L", "OO.TTT..II", "OO..S...II", "ZZ.SS.JJII",
        ".ZZSS.J.LL", "TTT.OO.J.L", ".T..OO.JLL", "I...SS.ZZ.", "I..SS...ZZ", "IIII..TTT.",
    }

    local function newBoard()
        local board = {}
        for y = 1, 20 do board[y] = {}; for x = 1, 10 do board[y][x] = false end end
        return board
    end

    local function copyBoard(board)
        local output = {}
        for y = 1, 20 do output[y] = {}; for x = 1, 10 do output[y][x] = board[y][x] end end
        return output
    end

    local function shapeCells(piece, rotation, px, py)
        local shape = SOLO_TETRIS_SHAPES[piece]
        local points = shape and shape[rotation or 1] or nil
        local output = {}
        if not points then return output end
        for _, point in ipairs(points) do output[#output + 1] = { x = (px or 0) + point[1], y = (py or 0) + point[2] } end
        return output
    end

    local function canPlaceOn(board, piece, rotation, px, py)
        for _, point in ipairs(shapeCells(piece, rotation, px, py)) do
            if point.x < 1 or point.x > 10 or point.y < 1 or point.y > 20 then return false end
            if board[point.y][point.x] then return false end
        end
        return true
    end

    local function clearBoardLines(board)
        local cleared, y = 0, 1
        while y <= 20 do
            local full = true
            for x = 1, 10 do if not board[y][x] then full = false; break end end
            if full then
                table.remove(board, y)
                local row = {}; for x = 1, 10 do row[x] = false end
                insert(board, row); cleared = cleared + 1
            else y = y + 1 end
        end
        return cleared
    end

    local function addGarbage(board, lines, owner, rngField)
        lines = floor(max(0, tonumber(lines) or 0))
        for _ = 1, lines do
            local topOccupied = false
            for x = 1, 10 do if board[20][x] then topOccupied = true; break end end
            table.remove(board, 20)
            owner[rngField] = ((owner[rngField] or 17) * 1103515245 + 12345) % 2147483648
            local hole = (floor(owner[rngField] / 65536) % 10) + 1
            local row = {}; for x = 1, 10 do row[x] = x == hole and false or "G" end
            insert(board, 1, row)
            if topOccupied then return false end
        end
        return true
    end

    local function boardHeuristic(board, cleared)
        local heights, aggregate, holes = {}, 0, 0
        for x = 1, 10 do
            local height = 0
            for y = 20, 1, -1 do if board[y][x] then height = y; break end end
            heights[x] = height; aggregate = aggregate + height
            local found = false
            for y = height, 1, -1 do
                if board[y][x] then found = true elseif found then holes = holes + 1 end
            end
        end
        local bump = 0
        for x = 1, 9 do bump = bump + abs((heights[x] or 0) - (heights[x + 1] or 0)) end
        return aggregate * 2.2 + holes * 13 + bump * 1.4 - (cleared or 0) * 120
    end

    function view:ShapeCells(piece, rotation, px, py)
        return shapeCells(piece or self.piece, rotation or self.rotation, px or self.px, py or self.py)
    end

    function view:CanPlace(piece, rotation, px, py)
        return canPlaceOn(self.board, piece, rotation, px, py)
    end

    function view:GetLandingY()
        local landing = self.py or 18
        while self:CanPlace(self.piece, self.rotation, self.px, landing - 1) do landing = landing - 1 end
        return landing
    end

    function view:SetTabState(active)
        for key, button in pairs(self.tabButtons) do
            if type(key) == "string" then
                button.creshSelected = key == active
                applyBackdrop(button, key == active and darken(colors.accent, 0.18) or colors.panelRaised, key == active and colors.accent or colors.border)
            end
        end
    end

    function view:UpdateGameLayout()
        self.side:ClearAllPoints()
        if self.mode == "CPU" then
            self.cpuBoardFrame:Show(); self.cpuLabel:Show()
            self.side:SetPoint("TOPLEFT", self.boardFrame, "TOPRIGHT", 12, 0)
            self.side:SetPoint("RIGHT", self.cpuBoardFrame, "LEFT", -12, 0)
            self.side:SetPoint("BOTTOM", frame, "BOTTOM", 0, 16)
        else
            self.cpuBoardFrame:Hide(); self.cpuLabel:Hide()
            self.side:SetPoint("TOPLEFT", self.boardFrame, "TOPRIGHT", 16, 0)
            self.side:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 16)
        end
    end

    function view:SelectTab(tab)
        tab = upper(tostring(tab or "ENDLESS"))
        self.passPanel:Hide(); self.themePanel:Hide(); self.backgroundPanel:Hide()
        self.boardFrame:Hide(); self.youLabel:Hide(); self.side:Hide(); self.cpuBoardFrame:Hide(); self.cpuLabel:Hide()
        if tab == "PASS" then
            self.display = "PASS"
            self.passPanel:Show(); self:SetTabState("PASS"); self:RefreshPassPanel()
            Solo:SetStatus("Tetris Pass rewards grant Cresh Coins and exclusive piece themes.", colors.accent)
        elseif tab == "THEMES" then
            self.display = "THEMES"
            self.themePanel:Show(); self:SetTabState("THEMES"); self:RefreshThemePanel()
            Solo:SetStatus("Preview and equip Tetris piece sets.", colors.accent)
        elseif tab == "BACKGROUNDS" then
            self.display = "BACKGROUNDS"
            self.backgroundPanel:Show(); self:SetTabState("BACKGROUNDS"); self:RefreshBackgroundPanel()
            Solo:SetStatus("Browse every reveal background and see which images are locked or unlocked.", colors.accent)
        else
            self.display = "GAME"
            self.boardFrame:Show(); self.youLabel:Show(); self.side:Show()
            self:SetTabState(tab)
            if self.mode ~= tab or self.finished then self:StartMode(tab) else self:UpdateGameLayout(); self:Refresh() end
        end
    end

    function view:RefreshPassPanel()
        if not CC.Tetris then return end
        local level, current, required = CC.Tetris:GetPassProgress()
        local save = CC.Tetris:Ensure()
        self.passSummary:SetText(format("Level %d · %d/%d XP · Tetris runs award this pass separately from the main Battle Pass.", level, current, required))
        self.passBar:SetMinMaxValues(0, max(1, required)); self.passBar:SetValue(current)
        self.passBarText:SetText(level >= 100 and "MAX LEVEL" or (tostring(current) .. " / " .. tostring(required)))
        local startLevel = ((self.passPage or 1) - 1) * 8 + 1
        for index, row in ipairs(self.passRows) do
            local rewardLevel = startLevel + index - 1
            row.level = rewardLevel <= 100 and rewardLevel or nil
            if row.level then
                local reward = CC.Tetris:GetPassReward(row.level)
                local reached = CC.Tetris:IsPassLevelReached(row.level)
                local claimed = CC.Tetris:IsPassRewardClaimed(row.level)
                row:Show(); row.title:SetText("LEVEL " .. row.level .. " · " .. reward.title .. " · +" .. reward.coins .. " Cresh Coins" .. (reward.themeName and (" · THEME: " .. reward.themeName) or ""))
                if claimed then row.detail:SetText("Claimed") elseif reached then row.detail:SetText("Requirement complete — reward ready") else row.detail:SetText(tostring(max(0, CC.Tetris:GetPassCumulativeXP(row.level) - (save.passXP or 0))) .. " more Tetris XP") end
                row.button.label:SetText(claimed and "CLAIMED" or (reached and "CLAIM" or "LOCKED")); setButtonEnabled(row.button, reached and not claimed)
                if reached and not claimed then setButtonAccent(row.button, colors.gold) end
            else row:Hide() end
        end
        self.passPageText:SetText("PAGE " .. tostring(self.passPage or 1) .. " / 13")
        setButtonEnabled(self.passPrev, (self.passPage or 1) > 1); setButtonEnabled(self.passNext, (self.passPage or 1) < 13)
    end

    function view:GetVisibleThemes()
        local output = {}
        if not CC.Tetris then return output end
        for _, theme in ipairs(CC.Tetris:GetCatalog()) do
            if not self.themeFilterUnlocked or CC.Tetris:IsThemeUnlocked(theme.key) then output[#output + 1] = theme end
        end
        return output
    end

    function view:PreviewTheme(key)
        if not CC.Tetris then return end
        local theme = CC.Tetris:GetTheme(key)
        self.previewThemeKey = theme.key
        self:RefreshThemePanel()
        Solo:SetStatus("Previewing " .. theme.name .. ".", colors.accent)
    end

    function view:UsePreviewTheme()
        if not CC.Tetris then return end
        local theme = CC.Tetris:GetTheme(self.previewThemeKey or CC.Tetris:GetSelectedTheme().key)
        if CC.Tetris:IsThemeUnlocked(theme.key) then
            CC.Tetris:SelectTheme(theme.key)
            Solo:SetStatus(theme.name .. " Tetris pieces equipped.", colors.green)
            self:RefreshThemePanel()
        elseif theme.source == "TETRIS_PASS" then
            self.passPage = floor((theme.requirement - 1) / 8) + 1; self:SelectTab("PASS")
            Solo:SetStatus("Reach and claim Tetris Pass level " .. tostring(theme.requirement) .. ".", colors.gold)
        elseif theme.source == "MAIN_PASS" and CC.BattlePass and CC.BattlePass.SelectRequirement then
            CC.BattlePass:SelectRequirement(theme.requirement)
        else Solo:SetStatus("Reach Tetris game level " .. tostring(theme.requirement) .. " to unlock " .. theme.name .. ".", colors.gold) end
    end

    function view:RefreshThemePreview()
        if not CC.Tetris then return end
        local selected = CC.Tetris:GetSelectedTheme()
        local theme = CC.Tetris:GetTheme(self.previewThemeKey or selected.key)
        self.previewThemeKey = theme.key
        local unlocked = CC.Tetris:IsThemeUnlocked(theme.key)
        self.previewTitle:SetText(theme.name .. (selected and selected.key == theme.key and " · EQUIPPED" or ""))
        self.previewRequirement:SetText((unlocked and "UNLOCKED · " or "LOCKED · ") .. CC.Tetris:GetThemeRequirementText(theme.key))
        self.previewNote:SetText(theme.note .. "\nBlock themes only change tetromino colours and highlights.")
        applyBackdrop(self.previewBoard, theme.background, theme.guide)
        if self.previewBackground then
            self.previewBackground:SetTexture(theme.backgroundTexture or "Interface\\Buttons\\WHITE8X8")
            self.previewBackground:SetAlpha(theme.backgroundTexture and 0.48 or 0.14)
            if not theme.backgroundTexture then self.previewBackground:SetColorTexture(theme.background[1], theme.background[2], theme.background[3], 1) end
        end
        for y = 1, 12 do
            local pattern = PREVIEW_PATTERN[y] or ".........."
            for x = 1, 10 do
                local piece = string.sub(pattern, x, x)
                local color = theme.colors[piece] or theme.background
                self.previewCells[y][x]:SetColorTexture(color[1], color[2], color[3], piece == "." and 0.22 or 0.96)
            end
        end
        if unlocked then
            self.previewAction.label:SetText(selected.key == theme.key and "EQUIPPED" or "EQUIP NOW")
            setButtonEnabled(self.previewAction, selected.key ~= theme.key); setButtonAccent(self.previewAction, colors.accent)
        else
            self.previewAction.label:SetText(theme.source == "TETRIS_PASS" and "VIEW TETRIS PASS" or (theme.source == "MAIN_PASS" and "VIEW MAIN PASS" or "VIEW REQUIREMENT"))
            setButtonEnabled(self.previewAction, true); setButtonAccent(self.previewAction, colors.gold)
        end
    end

    function view:RefreshThemePanel()
        if not CC.Tetris then return end
        local catalog = self:GetVisibleThemes()
        local selected = CC.Tetris:GetSelectedTheme()
        local pageCount = max(1, floor((#catalog + 5) / 6))
        self.themePage = clamp(self.themePage or 1, 1, pageCount)
        local pieceTotal, pieceUnlocked = 0, 0
        for _, theme in ipairs(CC.Tetris:GetCatalog()) do
            pieceTotal = pieceTotal + 1
            if CC.Tetris:IsThemeUnlocked(theme.key) then pieceUnlocked = pieceUnlocked + 1 end
        end
        self.themeTitle:SetText("TETRIS BLOCK THEMES · " .. tostring(pieceTotal) .. " SETS")
        self.themeSummary:SetText(tostring(pieceUnlocked) .. "/" .. tostring(pieceTotal) .. " unlocked · active blocks: " .. selected.name .. " · image backgrounds are selected separately")
        self.themeFilter.label:SetText(self.themeFilterUnlocked and "SHOW: UNLOCKED" or "SHOW: ALL")
        local startIndex = (self.themePage - 1) * 6 + 1
        for index, row in ipairs(self.themeRows) do
            local theme = catalog[startIndex + index - 1]
            if theme then
                row:Show(); row.themeKey = theme.key
                local unlocked = CC.Tetris:IsThemeUnlocked(theme.key)
                if row.backgroundTexture then
                    row.backgroundTexture:SetTexture(theme.backgroundTexture or "Interface\\Buttons\\WHITE8X8")
                    if not theme.backgroundTexture then row.backgroundTexture:SetColorTexture(theme.background[1], theme.background[2], theme.background[3], 1) end
                end
                local equipped = selected.key == theme.key
                local previewed = self.previewThemeKey == theme.key
                row.name:SetText(theme.name .. (equipped and " · EQUIPPED" or (previewed and " · PREVIEW" or "")))
                row.requirement:SetText((unlocked and "Unlocked · " or "Locked · ") .. CC.Tetris:GetThemeRequirementText(theme.key))
                for swatchIndex, piece in ipairs(SOLO_TETRIS_KEYS) do
                    local color = theme.colors[piece]; row.swatches[swatchIndex]:SetColorTexture(color[1], color[2], color[3], 1)
                end
                row.button.label:SetText(equipped and "EQUIPPED" or (unlocked and "EQUIP" or "PREVIEW"))
                setButtonEnabled(row.button, not equipped)
                if equipped then applyBackdrop(row, darken(colors.accent, 0.24), colors.accent)
                elseif previewed then applyBackdrop(row, colors.panelRaised, colors.gold)
                else applyBackdrop(row, colors.panelSoft, colors.border) end
                if unlocked and not equipped then setButtonAccent(row.button, colors.accent) elseif not unlocked then setButtonAccent(row.button, colors.muted) end
            else row:Hide(); row.themeKey = nil end
        end
        self.themePageText:SetText("PAGE " .. tostring(self.themePage) .. " / " .. tostring(pageCount))
        setButtonEnabled(self.themePrevPage, self.themePage > 1); setButtonEnabled(self.themeNextPage, self.themePage < pageCount)
        if not self.previewThemeKey then self.previewThemeKey = selected.key end
        self:RefreshThemePreview()
    end

    function view:CloseOverlay()
        if self.backgroundPreview and self.backgroundPreview:IsShown() then
            self.backgroundPreview:Hide()
            return true
        end
        return false
    end

    function view:OpenBackgroundPreview(key)
        if not CC.Tetris or not self.backgroundPreview then return end
        local background = CC.Tetris:GetBackground(key)
        if not background then return end
        self.previewBackgroundKey = background.key
        local unlocked = CC.Tetris:IsBackgroundUnlocked(background.key)
        local selected = CC.Tetris:GetSelectedBackground()
        local current, lines, stage, _, remaining, _, revealing = CC.Tetris:GetRevealProgress()
        local activeReveal = revealing and current and current.key == background.key
        self.backgroundPreviewTitle:SetText(background.name .. " · IMAGE BACKGROUND")
        self.backgroundPreviewImage:SetTexture(background.texture or background.backgroundTexture)
        self.backgroundPreviewImage:SetVertexColor(1, 1, 1, unlocked and 1 or 0.78)
        self.backgroundPreviewShade:SetColorTexture(0, 0, 0, unlocked and 0 or 0.28)
        if unlocked then
            self.backgroundPreviewState:SetText((selected and selected.key == background.key and "EQUIPPED · " or "UNLOCKED · ") .. "full image preview")
            self.backgroundPreviewEquip.label:SetText(selected and selected.key == background.key and "EQUIPPED" or "EQUIP BACKGROUND")
            setButtonEnabled(self.backgroundPreviewEquip, not (selected and selected.key == background.key))
        elseif activeReveal then
            self.backgroundPreviewState:SetText("LOCKED · current reveal " .. tostring(lines) .. "/100 lines · " .. tostring(stage) .. "/10 rows · " .. tostring(remaining) .. " lines remaining")
            self.backgroundPreviewEquip.label:SetText("LOCKED")
            setButtonEnabled(self.backgroundPreviewEquip, false)
        else
            self.backgroundPreviewState:SetText("LOCKED · " .. CC.Tetris:GetBackgroundRequirementText(background.key))
            self.backgroundPreviewEquip.label:SetText("LOCKED")
            setButtonEnabled(self.backgroundPreviewEquip, false)
        end
        self.backgroundPreview:Show()
    end

    function view:GetVisibleBackgrounds()
        if not CC.Tetris or not CC.Tetris.GetBackgroundCatalog then return {} end
        return CC.Tetris:GetBackgroundCatalog(self.backgroundFilter or "ALL")
    end

    function view:RefreshBackgroundPanel()
        if not CC.Tetris then return end
        local catalog = self:GetVisibleBackgrounds()
        local total = CC.Tetris:GetBackgroundThemeCount()
        local unlocked = CC.Tetris.GetUnlockedBackgroundCount and CC.Tetris:GetUnlockedBackgroundCount() or 0
        local current, lines, stage, nextPart, remaining, _, revealing = CC.Tetris:GetRevealProgress()
        local pageCount = max(1, floor((#catalog + 7) / 8))
        self.backgroundPage = clamp(self.backgroundPage or 1, 1, pageCount)
        self.backgroundTitle:SetText("TETRIS IMAGE BACKGROUNDS · " .. tostring(total) .. " IMAGES")
        local progressText
        if revealing and current then
            progressText = current.name .. " · " .. tostring(lines) .. "/100 lines · next section in " .. tostring(nextPart) .. " · full image in " .. tostring(remaining)
        else
            progressText = "All reveal backgrounds complete"
        end
        self.backgroundSummary:SetText(tostring(unlocked) .. "/" .. tostring(total) .. " unlocked · " .. progressText)
        self.backgroundFilterButton.label:SetText("SHOW: " .. tostring(self.backgroundFilter or "ALL"))
        local startIndex = (self.backgroundPage - 1) * 8 + 1
        local selected = CC.Tetris:GetSelectedBackground()
        for index, tile in ipairs(self.backgroundRows) do
            local theme = catalog[startIndex + index - 1]
            if theme then
                tile:Show(); tile.themeKey = theme.key
                local isUnlocked = CC.Tetris:IsBackgroundUnlocked(theme.key)
                local isCurrent = revealing and current and current.key == theme.key
                tile.image:SetTexture(theme.texture or theme.backgroundTexture)
                tile.image:SetVertexColor(1, 1, 1, isUnlocked and 0.92 or (isCurrent and 0.72 or 0.42))
                tile.shade:SetShown(not isUnlocked)
                if isCurrent then tile.shade:SetColorTexture(0, 0, 0, 0.18) else tile.shade:SetColorTexture(0, 0, 0, 0.55) end
                tile.name:SetText(theme.name .. (selected and selected.key == theme.key and " · EQUIPPED" or ""))
                if isUnlocked then
                    tile.state:SetText("UNLOCKED · full image")
                    tile.action.label:SetText("PREVIEW")
                    setButtonEnabled(tile.action, true)
                    setButtonAccent(tile.action, colors.accent)
                    applyBackdrop(tile, selected and selected.key == theme.key and darken(colors.accent, 0.24) or colors.panelSoft, selected and selected.key == theme.key and colors.accent or colors.border)
                elseif isCurrent then
                    tile.state:SetText("CURRENT · " .. tostring(lines) .. "/100 · " .. tostring(stage) .. "/10 parts")
                    tile.action.label:SetText("PREVIEW")
                    setButtonEnabled(tile.action, true)
                    setButtonAccent(tile.action, colors.gold)
                    applyBackdrop(tile, colors.panelRaised, colors.gold)
                else
                    tile.state:SetText("LOCKED · " .. CC.Tetris:GetBackgroundRequirementText(theme.key))
                    tile.action.label:SetText("PREVIEW")
                    setButtonEnabled(tile.action, true)
                    setButtonAccent(tile.action, colors.muted)
                    applyBackdrop(tile, colors.panelSoft, colors.border)
                end
            else
                tile:Hide(); tile.themeKey = nil
            end
        end
        self.backgroundPageText:SetText("PAGE " .. tostring(self.backgroundPage) .. " / " .. tostring(pageCount))
        setButtonEnabled(self.backgroundPrev, self.backgroundPage > 1)
        setButtonEnabled(self.backgroundNext, self.backgroundPage < pageCount)
    end

    function view:CycleUnlockedTheme(direction)
        if not CC.Tetris then return end
        local catalog = CC.Tetris:GetCatalog(); if #catalog == 0 then return end
        local selected = CC.Tetris:GetSelectedTheme(); local selectedIndex = 1
        for index, theme in ipairs(catalog) do if theme.key == selected.key then selectedIndex = index; break end end
        direction = direction < 0 and -1 or 1
        for step = 1, #catalog do
            local index = ((selectedIndex - 1 + direction * step) % #catalog) + 1
            local theme = catalog[index]
            if CC.Tetris:IsThemeUnlocked(theme.key) then
                self.previewThemeKey = theme.key; CC.Tetris:SelectTheme(theme.key)
                Solo:SetStatus(theme.name .. " block theme equipped.", colors.green); self:Refresh(); return
            end
        end
    end

    function view:CycleCPU()
        local save = CC.Tetris and CC.Tetris:Ensure() or ensureSave().tetris
        save.cpuLevel = ((save.cpuLevel or 3) % 5) + 1
        self.cpuLevelValue = save.cpuLevel; self.cpuLevel.label:SetText("CPU: " .. SOLO_TETRIS_CPU_NAMES[self.cpuLevelValue])
        if self.mode == "CPU" then self:Start() else self:Refresh() end
    end

    function view:CycleCPUFormat()
        local save = CC.Tetris and CC.Tetris:Ensure() or ensureSave().tetris
        self.cpuVersusMode = self.cpuVersusMode == "ATTACK" and "ENDLESS" or "ATTACK"
        save.cpuVersusMode = self.cpuVersusMode
        if self.mode == "CPU" then self:Start() else self:Refresh() end
    end

    function view:CycleSoloDuration()
        local save = CC.Tetris and CC.Tetris:Ensure() or ensureSave().tetris
        local current, nextValue = self.durationMinutes or save.soloDuration or 10, ENDLESS_DURATIONS[1]
        for index, value in ipairs(ENDLESS_DURATIONS) do
            if value == current then nextValue = ENDLESS_DURATIONS[(index % #ENDLESS_DURATIONS) + 1]; break end
        end
        self.durationMinutes = nextValue
        save.soloDuration = nextValue
        if self.mode == "ENDLESS" or (self.mode == "CPU" and self.cpuVersusMode == "ENDLESS") then self:Start() else self:Refresh() end
    end

    function view:Finish(result, detail)
        if self.finished then return end
        self.finished = true; self.alive = false; self.gameOver = true
        local saveRoot = ensureSave(); local save = CC.Tetris and CC.Tetris:Ensure() or (saveRoot and saveRoot.tetris)
        if save then
            save.games = (save.games or 0) + 1
            save.highScore = max(save.highScore or 0, self.score or 0)
            save.bestLines = max(save.bestLines or 0, self.lines or 0)
            save.totalLines = (save.totalLines or 0) + (self.lines or 0)
            if self.mode == "ENDLESS" then save.endlessRuns = (save.endlessRuns or 0) + 1
            elseif self.mode == "CPU" then
                if result == "WIN" then save.wins = (save.wins or 0) + 1; save.vsWins = (save.vsWins or 0) + 1
                elseif result == "LOSS" then save.losses = (save.losses or 0) + 1; save.vsLosses = (save.vsLosses or 0) + 1 end
            end
        end
        local historyResult = self.mode == "ENDLESS" and "RUN" or result
        local historyMode = self.mode == "CPU" and "VS_CPU" or "SOLO"
        local formatName = self.mode == "CPU" and (self.cpuVersusMode == "ATTACK" and "Endless Attack" or ("Timed Endless · " .. tostring(self.durationMinutes or 10) .. " min")) or ("Timed Endless · " .. tostring(self.durationMinutes or 10) .. " min")
        local opponent = self.mode == "CPU" and ("Computer " .. SOLO_TETRIS_CPU_NAMES[self.cpuLevelValue or 3] .. " · " .. formatName) or formatName
        Solo:RecordHistory("TETRIS", historyMode, historyResult, opponent, detail, self.score or 0)
        if CC.Tetris and CC.Tetris.AwardRun then CC.Tetris:AwardRun(historyResult, self.mode, self.score or 0, self.lines or 0) end
        local status
        if self.mode == "ENDLESS" then
            status = "Timed Endless finished — " .. tostring(self.lines or 0) .. " lines and " .. tostring(self.score or 0) .. " points."
        elseif self.cpuVersusMode == "ATTACK" then
            status = result == "WIN" and "The computer topped out. You win Endless Attack!" or "Your stack topped out. The computer wins Endless Attack."
        else
            status = result == "WIN" and "Time expired — you won Timed Endless against the computer!" or (result == "LOSS" and "Time expired — the computer won Timed Endless." or "Time expired — Timed Endless drawn.")
        end
        Solo:SetStatus(status, result == "WIN" and colors.green or (result == "LOSS" and colors.red or colors.gold))
        self:Refresh(); self:RefreshPassPanel(); self:RefreshThemePanel()
    end

    function view:FinishTimed()
        if self.finished then return end
        if self.mode == "ENDLESS" then
            self:Finish("RUN", "Timed Endless · " .. tostring(self.durationMinutes or 10) .. " minutes")
            return
        end
        local result = "DRAW"
        if (self.score or 0) ~= (self.cpuScore or 0) then result = (self.score or 0) > (self.cpuScore or 0) and "WIN" or "LOSS"
        elseif (self.lines or 0) ~= (self.cpuLines or 0) then result = (self.lines or 0) > (self.cpuLines or 0) and "WIN" or "LOSS"
        elseif (self.topouts or 0) ~= (self.cpuTopouts or 0) then result = (self.topouts or 0) < (self.cpuTopouts or 0) and "WIN" or "LOSS" end
        self:Finish(result, "Timed Endless · " .. tostring(self.durationMinutes or 10) .. " minutes")
    end

    function view:Spawn()
        self.piece = self.nextPiece or soloTetrisRandom(self); self.nextPiece = soloTetrisRandom(self)
        self.rotation, self.px, self.py = 1, 4, 18
        if not self:CanPlace(self.piece, self.rotation, self.px, self.py) then
            local timed = self.mode == "ENDLESS" or (self.mode == "CPU" and self.cpuVersusMode == "ENDLESS")
            if timed then
                self.topouts = (self.topouts or 0) + 1
                self.score = max(0, (self.score or 0) - 500)
                self.board = newBoard(); self.pendingGarbage = 0
                self.piece = nil; self.nextPiece = soloTetrisRandom(self)
                Solo:SetStatus("Board reset after a top-out · -500 score. Timed Endless continues.", colors.gold)
                self:Spawn(); return
            end
            self:Finish("LOSS", "Topped out at " .. tostring(self.lines or 0) .. " lines")
        end
    end

    function view:Move(dx, dy)
        if not self.alive or self.gameOver or self.paused or self.display ~= "GAME" then return false end
        if self:CanPlace(self.piece, self.rotation, self.px + dx, self.py + dy) then self.px, self.py = self.px + dx, self.py + dy; self:Refresh(); return true end
        if dy < 0 then self:LockPiece() end
        return false
    end

    function view:Rotate()
        if not self.alive or self.gameOver or self.paused or self.display ~= "GAME" then return end
        local nextRotation = (self.rotation % 4) + 1
        for _, kick in ipairs({0, -1, 1, -2, 2}) do if self:CanPlace(self.piece, nextRotation, self.px + kick, self.py) then self.rotation, self.px = nextRotation, self.px + kick; self:Refresh(); return end end
    end

    function view:HardDrop()
        if not self.alive or self.gameOver or self.paused or self.display ~= "GAME" then return end
        local distance = 0
        while self:CanPlace(self.piece, self.rotation, self.px, self.py - 1) do self.py = self.py - 1; distance = distance + 1 end
        self.score = self.score + distance * 2; self:LockPiece()
    end

    function view:ApplyPlayerGarbage()
        local lines = floor(max(0, tonumber(self.pendingGarbage) or 0)); self.pendingGarbage = 0
        if lines > 0 and not addGarbage(self.board, lines, self, "garbageRng") then self:Finish("LOSS", "Incoming garbage pushed the stack over the top"); return false end
        return true
    end

    function view:LockPiece()
        if not self.alive then return end
        local lockedPiece = self.piece
        for _, point in ipairs(self:ShapeCells()) do self.board[point.y][point.x] = lockedPiece end
        self.piece = nil
        local cleared = clearBoardLines(self.board)
        if cleared > 0 then
            local scores = { [1]=100, [2]=300, [3]=500, [4]=800 }
            self.lines = self.lines + cleared
            self.score = self.score + (scores[cleared] or 1000) * (1 + floor(self.lines / 5))
            if CC.GameAudio and CC.GameAudio.PlayEffect then CC.GameAudio:PlayEffect("LINE_CLEAR") end
            if CC.Tetris and CC.Tetris.AddRevealLines then
                local completed, completedTheme = CC.Tetris:AddRevealLines(cleared)
                if completed and completedTheme then
                    self.completedRevealTheme = completedTheme
                    self.revealTransitionRemaining = 1.65
                end
            end
            if self.mode == "CPU" and self.cpuVersusMode == "ATTACK" then
                local attack = ATTACK_LINES[cleared] or (cleared + 2)
                local cancelled = min(attack, self.pendingGarbage or 0); self.pendingGarbage = max(0, (self.pendingGarbage or 0) - cancelled); attack = attack - cancelled
                self.cpuPendingGarbage = (self.cpuPendingGarbage or 0) + attack
            end
        else self.score = self.score + 10 end
        self.dropInterval = CC.Tetris and CC.Tetris:GetDropInterval(self.lines) or max(0.10, 0.90 - (self.lines * 0.00008))
        if self.mode == "CPU" and self.cpuVersusMode == "ATTACK" then if not self:ApplyPlayerGarbage() then return end end
        if not self.finished then self:Spawn() end
        self:Refresh()
    end

    function view:TogglePause()
        if self.gameOver or self.display ~= "GAME" then return end
        self.paused = not self.paused; self.pause.label:SetText(self.paused and "RESUME" or "PAUSE")
        Solo:SetStatus(self.paused and "Tetris paused." or "Tetris resumed.", self.paused and colors.gold or colors.green); self:Refresh()
    end

    function view:ChooseCPUPlacement(piece)
        local level = self.cpuLevelValue or 3; local best
        for rotation = 1, 4 do
            for x = -1, 10 do
                local y = 18
                if canPlaceOn(self.cpuBoard, piece, rotation, x, y) then
                    while canPlaceOn(self.cpuBoard, piece, rotation, x, y - 1) do y = y - 1 end
                    local simulated = copyBoard(self.cpuBoard)
                    for _, point in ipairs(shapeCells(piece, rotation, x, y)) do simulated[point.y][point.x] = piece end
                    local cleared = clearBoardLines(simulated)
                    local noiseRange = max(1, (6 - level) * 22)
                    local score = boardHeuristic(simulated, cleared) + soloTetrisCPURandom(self, noiseRange)
                    if not best or score < best.score then best = { score=score, rotation=rotation, x=x, y=y, cleared=cleared } end
                end
            end
        end
        return best
    end

    function view:CPUPlacePiece()
        if self.mode ~= "CPU" or self.finished then return end
        local piece = self.cpuNextPiece or SOLO_TETRIS_KEYS[soloTetrisCPURandom(self, 7)]
        self.cpuNextPiece = SOLO_TETRIS_KEYS[soloTetrisCPURandom(self, 7)]
        local placement = self:ChooseCPUPlacement(piece)
        if not placement then
            if self.cpuVersusMode == "ENDLESS" then
                self.cpuTopouts = (self.cpuTopouts or 0) + 1
                self.cpuScore = max(0, (self.cpuScore or 0) - 500)
                self.cpuBoard = newBoard(); self.cpuPendingGarbage = 0
                return
            end
            self.cpuAlive = false; self:Finish("WIN", "Computer topped out"); return
        end
        for _, point in ipairs(shapeCells(piece, placement.rotation, placement.x, placement.y)) do self.cpuBoard[point.y][point.x] = piece end
        local cleared = clearBoardLines(self.cpuBoard)
        self.cpuLines = (self.cpuLines or 0) + cleared
        self.cpuScore = (self.cpuScore or 0) + (cleared > 0 and (({[1]=100,[2]=300,[3]=500,[4]=800})[cleared] or 1000) or 10)
        if self.cpuVersusMode == "ATTACK" and cleared > 0 then
            local attack = ATTACK_LINES[cleared] or (cleared + 2)
            local cancelled = min(attack, self.cpuPendingGarbage or 0); self.cpuPendingGarbage = max(0, (self.cpuPendingGarbage or 0) - cancelled); attack = attack - cancelled
            self.pendingGarbage = (self.pendingGarbage or 0) + attack
        end
        if self.cpuVersusMode == "ATTACK" and (self.cpuPendingGarbage or 0) > 0 then
            local garbage = self.cpuPendingGarbage; self.cpuPendingGarbage = 0
            if not addGarbage(self.cpuBoard, garbage, self, "cpuGarbageRng") then self.cpuAlive = false; self:Finish("WIN", "Computer topped out from garbage"); return end
        end
    end

    function view:UpdateCPU(elapsed)
        if self.mode ~= "CPU" or self.finished or self.paused then return end
        self.cpuElapsed = (self.cpuElapsed or 0) + (elapsed or 0)
        local intervals = { 1.45, 1.18, 0.94, 0.74, 0.56 }
        local interval = intervals[self.cpuLevelValue or 3]
        while self.cpuElapsed >= interval and not self.finished do self.cpuElapsed = self.cpuElapsed - interval; self:CPUPlacePiece() end
    end

    local function renderBoard(cells, shines, board, theme, activePiece, rotation, px, py, guides, paused, showGhost, hasImageBackground)
        local background = theme and theme.background or {0.055,0.062,0.078,1}; local guideColor = theme and theme.guide or colors.accent; local highlight = theme and theme.highlight or colors.text
        local active, ghost, currentByColumn, landingByColumn = {}, {}, {}, {}
        if activePiece and canPlaceOn(board, activePiece, rotation or 1, px or 4, py or 18) then
            local landingY = py or 18
            while canPlaceOn(board, activePiece, rotation or 1, px or 4, landingY - 1) do landingY = landingY - 1 end
            for _, point in ipairs(shapeCells(activePiece, rotation or 1, px or 4, py or 18)) do active[point.y .. ":" .. point.x] = activePiece; currentByColumn[point.x] = min(currentByColumn[point.x] or 99, point.y) end
            if showGhost then for _, point in ipairs(shapeCells(activePiece, rotation or 1, px or 4, landingY)) do if not board[point.y][point.x] then ghost[point.y .. ":" .. point.x] = activePiece end; landingByColumn[point.x] = max(landingByColumn[point.x] or 0, point.y) end end
        end
        for _, guide in ipairs(guides or {}) do guide:Hide() end
        for y = 1, 20 do
            for x = 1, 10 do
                local activePieceValue = active[y .. ":" .. x]; local boardPiece = board[y][x]; local ghostPiece = ghost[y .. ":" .. x]; local piece = activePieceValue or boardPiece or ghostPiece
                local color
                if piece == "G" then color = { guideColor[1] * 0.65, guideColor[2] * 0.65, guideColor[3] * 0.65, 1 }
                elseif piece then color = (theme and theme.colors[piece]) or SOLO_TETRIS_FALLBACK[piece]
                elseif hasImageBackground then color = { 0.008, 0.010, 0.016, 1 }
                else color = background end
                local alpha
                if ghostPiece and not activePieceValue and not boardPiece then alpha = paused and 0.08 or 0.15
                elseif not piece and hasImageBackground then alpha = paused and 0.14 or 0.025
                else alpha = paused and 0.35 or 1 end
                cells[y][x]:SetColorTexture(color[1], color[2], color[3], alpha)
                if (activePieceValue or boardPiece) and not paused then shines[y][x]:SetColorTexture(highlight[1], highlight[2], highlight[3], 0.36); shines[y][x]:Show() else shines[y][x]:Hide() end
            end
        end
        if guides and showGhost then
            for x, currentBottom in pairs(currentByColumn) do
                local landingTop = landingByColumn[x] or 0
                local gap = currentBottom - landingTop - 1
                local guide = guides[x]
                if guide and gap > 0 then
                    guide:ClearAllPoints()
                    guide:SetPoint("BOTTOMLEFT", guide.boardFrame, "BOTTOMLEFT", 8 + (x - 1) * boardCellSize + 8, 8 + landingTop * boardCellSize + 2)
                    guide:SetSize(1, max(1, gap * boardCellSize - 4))
                    guide:SetColorTexture(min(1, guideColor[1] + 0.16), min(1, guideColor[2] + 0.16), min(1, guideColor[3] + 0.16), paused and 0.07 or 0.20)
                    guide:Show()
                end
            end
        end
    end

    function view:Refresh()
        if not self.board then return end
        self:UpdateGameLayout()
        local pieceTheme = CC.Tetris and CC.Tetris:GetSelectedTheme() or nil
        local imageBackground, revealLines, revealStage, linesToNextPart, linesToUnlock, revealFraction, isRevealing = nil, 0, 0, 0, 0, 0, false
        local revealAlpha = 0.58
        if CC.Tetris and CC.Tetris.GetRevealProgress then
            imageBackground, revealLines, revealStage, linesToNextPart, linesToUnlock, revealFraction, isRevealing = CC.Tetris:GetRevealProgress()
        elseif CC.Tetris and CC.Tetris.GetRevealTheme then
            imageBackground, revealLines, revealFraction, isRevealing = CC.Tetris:GetRevealTheme()
            revealStage = floor(max(0, min(10, (revealLines or 0) / 10)))
            linesToNextPart = isRevealing and (10 - ((revealLines or 0) % 10)) or 0
            linesToUnlock = isRevealing and max(0, 100 - (revealLines or 0)) or 0
        end
        if CC.Tetris and CC.Tetris.GetRevealOpacity then revealAlpha = CC.Tetris:GetRevealOpacity() end
        local boardBackground = imageBackground
        if self.completedRevealTheme and (self.revealTransitionRemaining or 0) > 0 then
            boardBackground = self.completedRevealTheme
            revealLines, revealStage, linesToNextPart, linesToUnlock, revealFraction, revealAlpha, isRevealing = 100, 10, 0, 0, 1, 0.72, false
        end
        local background = boardBackground and boardBackground.background or (pieceTheme and pieceTheme.background) or {0.055,0.062,0.078,1}
        local boardBackdrop = boardBackground and {0.006,0.008,0.014,1} or background
        local guideColor = pieceTheme and pieceTheme.guide or colors.accent
        applyBackdrop(self.boardFrame, boardBackdrop, guideColor); applyBackdrop(self.nextBox, darken(guideColor, 0.25), guideColor)
        updateTetrisRevealStrips(self.boardFrame, boardBackground, revealStage, revealAlpha, isRevealing)
        updateTetrisRevealStrips(self.cpuBoardFrame, boardBackground, revealStage, min(0.38, revealAlpha), isRevealing)
        if not (boardBackground and boardBackground.backgroundTexture) then
            self.boardFrame.backgroundArt:SetColorTexture(background[1], background[2], background[3], 1)
            self.cpuBoardFrame.backgroundArt:SetColorTexture(background[1], background[2], background[3], 1)
        end
        renderBoard(self.cells, self.shines, self.board, pieceTheme, self.alive and self.piece or nil, self.rotation, self.px, self.py, self.guides, self.paused, true, boardBackground ~= nil)
        if self.mode == "CPU" then applyBackdrop(self.cpuBoardFrame, boardBackdrop, colors.gold); renderBoard(self.cpuCells, self.cpuShines, self.cpuBoard, pieceTheme, nil, 1, 4, 18, nil, self.paused, false, boardBackground ~= nil) end
        local passLevel, passCurrent, passNeed = 1, 0, 35
        if CC.Tetris and CC.Tetris.GetPassProgress then passLevel, passCurrent, passNeed = CC.Tetris:GetPassProgress() end
        local timed = self.mode == "ENDLESS" or (self.mode == "CPU" and self.cpuVersusMode == "ENDLESS")
        local modeName = self.mode == "CPU" and (self.cpuVersusMode == "ATTACK" and "VS COMPUTER · ENDLESS ATTACK" or "VS COMPUTER · TIMED ENDLESS") or "TIMED ENDLESS"
        local timeText = timed and format("%02d:%02d", floor(max(0, self.timeRemaining or 0) / 60), floor(max(0, self.timeRemaining or 0) % 60)) or "NO LIMIT"
        self.title:SetText(modeName)
        self.themeText:SetText("BLOCKS · " .. (pieceTheme and pieceTheme.name or "Classic Blocks"))
        local imageName = boardBackground and boardBackground.name or "None"
        local imageSuffix = isRevealing and (" · " .. tostring(revealStage) .. "/10 rows") or " · unlocked"
        self.backgroundLine.label:SetText("IMAGE · " .. imageName .. imageSuffix)
        local speedLevel = CC.Tetris and CC.Tetris:GetGameLevel(self.lines or 0) or (1 + floor((self.lines or 0) / 10))
        self.scoreCard.value:SetText(format("%d", self.score or 0))
        self.linesCard.value:SetText(tostring(self.lines or 0))
        self.speedCard.value:SetText(format("LV %d · %.2fs", speedLevel, self.dropInterval or 0.90))
        self.timeCard.value:SetText(timeText)
        self.timeCard.label:SetText(timed and "TIME LEFT" or "MODE")
        local revealName = boardBackground and boardBackground.name or "No image background"
        if isRevealing then
            self.revealTitle:SetText(revealName .. " · next image row in " .. tostring(linesToNextPart) .. " lines")
            self.revealBar:SetMinMaxValues(0, 100); self.revealBar:SetValue(revealLines or 0)
            self.revealBarText:SetText(tostring(revealLines or 0) .. "/100 · full image in " .. tostring(linesToUnlock) .. " lines")
        else
            self.revealTitle:SetText(revealName .. " · background unlocked")
            self.revealBar:SetMinMaxValues(0, 100); self.revealBar:SetValue(100)
            self.revealBarText:SetText("FULL IMAGE UNLOCKED")
        end
        self.nextText:SetText(self.nextPiece or "-"); local nextColor = (pieceTheme and pieceTheme.colors[self.nextPiece or "I"]) or SOLO_TETRIS_FALLBACK[self.nextPiece or "I"]; self.nextText:SetTextColor(nextColor[1], nextColor[2], nextColor[3], 1)
        self.cpuLevelValue = self.cpuLevelValue or 3; self.cpuLevel.label:SetText("CPU: " .. SOLO_TETRIS_CPU_NAMES[self.cpuLevelValue])
        self.cpuFormat.label:SetText(self.cpuVersusMode == "ATTACK" and "FORMAT: ATTACK" or "FORMAT: ENDLESS")
        self.durationButton.label:SetText("TIME: " .. tostring(self.durationMinutes or 10) .. " MIN")
        local durationActive = self.mode == "ENDLESS" or (self.mode == "CPU" and self.cpuVersusMode == "ENDLESS")
        setButtonEnabled(self.durationButton, durationActive); self.durationButton:SetShown(durationActive)
        if self.mode == "CPU" then
            self.cpuYou:SetText(format("YOU\n%d lines", self.lines or 0))
            self.cpuVs:SetText((self.cpuVersusMode == "ATTACK" and tostring(self.pendingGarbage or 0) .. " <-> " .. tostring(self.cpuPendingGarbage or 0)) or "VS")
            self.cpuThem:SetText(format("CPU\n%d lines", self.cpuLines or 0))
            self.cpuInfo:Show(); self.cpuLevel:Show(); self.cpuFormat:Show()
        else
            self.cpuYou:SetText(format("RUN\n%d resets", self.topouts or 0))
            self.cpuVs:SetText("•")
            self.cpuThem:SetText(format("PASS\n%d/%d XP", passCurrent, passNeed))
            self.cpuInfo:Show(); self.cpuLevel:Hide(); self.cpuFormat:Hide()
        end
    end

    function view:OnKeyDown(key)
        key = upper(tostring(key or ""))
        if key == "1" then self:SelectTab("ENDLESS") elseif key == "2" then self:SelectTab("CPU")
        elseif key == "3" and self.mode == "CPU" then self:CycleCPUFormat()
        elseif key == "4" then self:CycleSoloDuration()
        elseif key == "A" or key == "LEFT" then self:Move(-1, 0) elseif key == "D" or key == "RIGHT" then self:Move(1, 0)
        elseif key == "W" or key == "UP" then self:Rotate() elseif key == "S" or key == "DOWN" then self:Move(0, -1)
        elseif key == "SPACE" then self:HardDrop() elseif key == "P" then self:TogglePause() elseif key == "R" then self:Start() end
    end

    function view:OnUpdate(elapsed)
        elapsed = elapsed or 0
        if self.revealTransitionRemaining and self.revealTransitionRemaining > 0 then
            self.revealTransitionRemaining = max(0, self.revealTransitionRemaining - elapsed)
            if self.revealTransitionRemaining <= 0 then
                self.completedRevealTheme = nil
                self:Refresh()
            end
        end
        if not self.alive or self.gameOver or self.paused or self.display ~= "GAME" then return end
        self.dropElapsed = (self.dropElapsed or 0) + elapsed
        local timed = self.mode == "ENDLESS" or (self.mode == "CPU" and self.cpuVersusMode == "ENDLESS")
        if timed then
            self.matchElapsed = (self.matchElapsed or 0) + elapsed
            self.timeRemaining = max(0, (self.durationMinutes or 10) * 60 - self.matchElapsed)
            if self.timeRemaining <= 0 then self:FinishTimed(); return end
        end
        if self.dropElapsed >= self.dropInterval then self.dropElapsed = self.dropElapsed - self.dropInterval; self:Move(0, -1) end
        self:UpdateCPU(elapsed)
        self.refreshElapsed = (self.refreshElapsed or 0) + elapsed
        if self.refreshElapsed >= 0.15 then self.refreshElapsed = 0; self:Refresh() end
    end

    function view:StartMode(mode)
        mode = upper(tostring(mode or "ENDLESS")); if mode ~= "CPU" and mode ~= "ENDLESS" then mode = "ENDLESS" end
        self.mode = mode; local save = CC.Tetris and CC.Tetris:Ensure() or ensureSave().tetris; save.mode = mode
        self.display = "GAME"; self.passPanel:Hide(); self.themePanel:Hide(); self.backgroundPanel:Hide(); self.boardFrame:Show(); self.youLabel:Show(); self.side:Show(); self:SetTabState(mode); self:Start()
    end

    function view:Start()
        local save = CC.Tetris and CC.Tetris:Ensure() or ensureSave().tetris
        self.mode = self.mode or save.mode or "ENDLESS"; if self.mode ~= "CPU" then self.mode = "ENDLESS" end
        self.cpuVersusMode = upper(tostring(save.cpuVersusMode or self.cpuVersusMode or "ENDLESS")); if self.cpuVersusMode ~= "ATTACK" then self.cpuVersusMode = "ENDLESS" end
        save.cpuVersusMode = self.cpuVersusMode
        self.durationMinutes = tonumber(save.soloDuration) or self.durationMinutes or 10
        save.soloDuration = self.durationMinutes
        self.display = "GAME"; self.passPanel:Hide(); self.themePanel:Hide(); self.backgroundPanel:Hide(); self.boardFrame:Show(); self.youLabel:Show(); self.side:Show(); self:SetTabState(self.mode); self:UpdateGameLayout()
        self.cpuLevelValue = save.cpuLevel or 3; self.rng = floor(now() * 1000) + 441; self.cpuRng = self.rng + 773; self.garbageRng = self.rng + 111; self.cpuGarbageRng = self.rng + 222
        self.board = newBoard(); self.cpuBoard = newBoard()
        self.score, self.lines, self.cpuScore, self.cpuLines = 0, 0, 0, 0
        self.pendingGarbage, self.cpuPendingGarbage = 0, 0
        self.topouts, self.cpuTopouts = 0, 0
        self.matchElapsed, self.timeRemaining = 0, self.durationMinutes * 60
        self.alive, self.cpuAlive, self.gameOver, self.finished, self.paused = true, true, false, false, false
        self.dropElapsed, self.dropInterval, self.refreshElapsed, self.cpuElapsed = 0, (CC.Tetris and CC.Tetris:GetDropInterval(0) or 0.90), 0, 0
        self.pause.label:SetText("PAUSE"); self.nextPiece = soloTetrisRandom(self); self.cpuNextPiece = SOLO_TETRIS_KEYS[soloTetrisCPURandom(self, 7)]
        self:Spawn(); self:Refresh(); self:RefreshPassPanel(); self:RefreshThemePanel()
        if self.mode == "CPU" and self.cpuVersusMode == "ATTACK" then Solo:SetStatus("Endless Attack started — clear lines to send garbage to the computer.", colors.green)
        elseif self.mode == "CPU" then Solo:SetStatus("Timed Endless against the computer started for " .. tostring(self.durationMinutes) .. " minutes.", colors.green)
        else Solo:SetStatus("Timed Endless started for " .. tostring(self.durationMinutes) .. " minutes. Top-outs reset the board.", colors.green) end
    end

    self.views.TETRIS = view
    return view
end
function Solo:RefreshTetrisPanels(forceBoard)
    local view = self.views and self.views.TETRIS
    if not view then return end
    if view.RefreshPassPanel then view:RefreshPassPanel() end
    if view.RefreshThemePanel then view:RefreshThemePanel() end
    if view.RefreshBackgroundPanel then view:RefreshBackgroundPanel() end
    if forceBoard and view.Refresh then view:Refresh() end
end

-- SOLO CHESS ------------------------------------------------------------------
-- The solo engine follows standard move legality (including check, castling,
-- en passant and queen promotion) and uses progressively deeper alpha-beta
-- searches. It is intentionally lightweight enough to run inside WoW's Lua UI.
local SOLO_CHESS_BACK = { "R", "N", "B", "Q", "K", "B", "N", "R" }
local SOLO_CHESS_VALUE = { P = 100, N = 320, B = 330, R = 500, Q = 900, K = 20000 }
local SOLO_CHESS_TEXTURES = (_G.CreshGamesChessTextures and _G.CreshGamesChessTextures.Notation) or {
    WK = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\King_White.tga",
    WQ = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Queen_White.tga",
    WR = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Rook_White.tga",
    WB = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Bishop_White.tga",
    WN = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Knight_White.tga",
    WP = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\White\\Pawn_White.tga",
    BK = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\King_Black.tga",
    BQ = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Queen_Black.tga",
    BR = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Rook_Black.tga",
    BB = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Bishop_Black.tga",
    BN = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Knight_Black.tga",
    BP = "Interface\\AddOns\\CreshGames\\Media\\Games\\Chess\\Black\\Pawn_Black.tga",
}
local SOLO_CHESS_PIECE_SIZE = 44
local SOLO_CHESS_MATE = 100000
local SOLO_CHESS_LEVELS = {
    [1] = { name = "CASUAL", depth = 0, nodes = 1, noise = 9999 },
    [2] = { name = "EASY", depth = 1, nodes = 350, noise = 150 },
    [3] = { name = "NORMAL", depth = 2, nodes = 1800, noise = 32 },
    [4] = { name = "HARD", depth = 3, nodes = 7000, noise = 8 },
    [5] = { name = "EXPERT", depth = 4, nodes = 22000, noise = 0 },
}

local function soloChessPiece(color, kind)
    return { color = color, kind = kind, moved = false }
end

local function soloChessInitialBoard()
    local board = {}
    for x = 1, 8 do board[x] = {} end
    for x = 1, 8 do
        board[x][1] = soloChessPiece("W", SOLO_CHESS_BACK[x])
        board[x][2] = soloChessPiece("W", "P")
        board[x][7] = soloChessPiece("B", "P")
        board[x][8] = soloChessPiece("B", SOLO_CHESS_BACK[x])
    end
    return board
end

local function soloChessCopyBoard(board)
    local output = {}
    for x = 1, 8 do
        output[x] = {}
        for y = 1, 8 do
            local piece = board[x] and board[x][y]
            if piece then output[x][y] = { color = piece.color, kind = piece.kind, moved = piece.moved == true } end
        end
    end
    return output
end

local function soloChessCopyState(state)
    state = state or {}
    return {
        enPassantX = state.enPassantX,
        enPassantY = state.enPassantY,
        halfmove = tonumber(state.halfmove) or 0,
        moveNumber = tonumber(state.moveNumber) or 1,
    }
end

local function soloChessInside(x, y)
    return x >= 1 and x <= 8 and y >= 1 and y <= 8
end

local function soloChessFindKing(board, color)
    for x = 1, 8 do
        for y = 1, 8 do
            local piece = board[x][y]
            if piece and piece.color == color and piece.kind == "K" then return x, y end
        end
    end
end

local function soloChessIsAttacked(board, x, y, byColor)
    local pawnRow = byColor == "W" and (y - 1) or (y + 1)
    for _, px in ipairs({ x - 1, x + 1 }) do
        if soloChessInside(px, pawnRow) then
            local piece = board[px][pawnRow]
            if piece and piece.color == byColor and piece.kind == "P" then return true end
        end
    end

    local knightSteps = { {1,2},{2,1},{2,-1},{1,-2},{-1,-2},{-2,-1},{-2,1},{-1,2} }
    for _, step in ipairs(knightSteps) do
        local nx, ny = x + step[1], y + step[2]
        if soloChessInside(nx, ny) then
            local piece = board[nx][ny]
            if piece and piece.color == byColor and piece.kind == "N" then return true end
        end
    end

    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local kx, ky = x + dx, y + dy
                if soloChessInside(kx, ky) then
                    local piece = board[kx][ky]
                    if piece and piece.color == byColor and piece.kind == "K" then return true end
                end
            end
        end
    end

    local rays = {
        { 1, 0, "R" }, { -1, 0, "R" }, { 0, 1, "R" }, { 0, -1, "R" },
        { 1, 1, "B" }, { 1, -1, "B" }, { -1, 1, "B" }, { -1, -1, "B" },
    }
    for _, ray in ipairs(rays) do
        local rx, ry = x + ray[1], y + ray[2]
        while soloChessInside(rx, ry) do
            local piece = board[rx][ry]
            if piece then
                if piece.color == byColor and (piece.kind == ray[3] or piece.kind == "Q") then return true end
                break
            end
            rx, ry = rx + ray[1], ry + ray[2]
        end
    end
    return false
end

local function soloChessInCheck(board, color)
    local kingX, kingY = soloChessFindKing(board, color)
    if not kingX then return true end
    return soloChessIsAttacked(board, kingX, kingY, color == "W" and "B" or "W")
end

local function soloChessAddMove(moves, x1, y1, x2, y2, extra)
    local move = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
    if extra then for key, value in pairs(extra) do move[key] = value end end
    moves[#moves + 1] = move
end

local function soloChessPseudoMoves(board, state, color, capturesOnly)
    local moves = {}
    state = state or {}
    for x = 1, 8 do
        for y = 1, 8 do
            local piece = board[x][y]
            if piece and piece.color == color then
                if piece.kind == "P" then
                    local direction = color == "W" and 1 or -1
                    local startRow = color == "W" and 2 or 7
                    local promotionRow = color == "W" and 8 or 1
                    if not capturesOnly then
                        local oneY = y + direction
                        if soloChessInside(x, oneY) and not board[x][oneY] then
                            soloChessAddMove(moves, x, y, x, oneY, { promotion = oneY == promotionRow })
                            local twoY = y + direction * 2
                            if y == startRow and not piece.moved and soloChessInside(x, twoY) and not board[x][twoY] then
                                soloChessAddMove(moves, x, y, x, twoY, { doublePawn = true })
                            end
                        end
                    end
                    for _, dx in ipairs({ -1, 1 }) do
                        local tx, ty = x + dx, y + direction
                        if soloChessInside(tx, ty) then
                            local target = board[tx][ty]
                            if target and target.color ~= color then
                                soloChessAddMove(moves, x, y, tx, ty, { promotion = ty == promotionRow })
                            elseif state.enPassantX == tx and state.enPassantY == ty then
                                local victim = board[tx][y]
                                if victim and victim.color ~= color and victim.kind == "P" then
                                    soloChessAddMove(moves, x, y, tx, ty, { enPassant = true })
                                end
                            end
                        end
                    end
                elseif piece.kind == "N" then
                    local steps = { {1,2},{2,1},{2,-1},{1,-2},{-1,-2},{-2,-1},{-2,1},{-1,2} }
                    for _, step in ipairs(steps) do
                        local tx, ty = x + step[1], y + step[2]
                        if soloChessInside(tx, ty) then
                            local target = board[tx][ty]
                            if (not target or target.color ~= color) and (not capturesOnly or target) then
                                soloChessAddMove(moves, x, y, tx, ty)
                            end
                        end
                    end
                elseif piece.kind == "B" or piece.kind == "R" or piece.kind == "Q" then
                    local directions = {}
                    if piece.kind == "B" or piece.kind == "Q" then
                        directions[#directions + 1] = {1,1}; directions[#directions + 1] = {1,-1}
                        directions[#directions + 1] = {-1,1}; directions[#directions + 1] = {-1,-1}
                    end
                    if piece.kind == "R" or piece.kind == "Q" then
                        directions[#directions + 1] = {1,0}; directions[#directions + 1] = {-1,0}
                        directions[#directions + 1] = {0,1}; directions[#directions + 1] = {0,-1}
                    end
                    for _, direction in ipairs(directions) do
                        local tx, ty = x + direction[1], y + direction[2]
                        while soloChessInside(tx, ty) do
                            local target = board[tx][ty]
                            if target then
                                if target.color ~= color then soloChessAddMove(moves, x, y, tx, ty) end
                                break
                            elseif not capturesOnly then
                                soloChessAddMove(moves, x, y, tx, ty)
                            end
                            tx, ty = tx + direction[1], ty + direction[2]
                        end
                    end
                elseif piece.kind == "K" then
                    for dx = -1, 1 do
                        for dy = -1, 1 do
                            if not (dx == 0 and dy == 0) then
                                local tx, ty = x + dx, y + dy
                                if soloChessInside(tx, ty) then
                                    local target = board[tx][ty]
                                    if (not target or target.color ~= color) and (not capturesOnly or target) then
                                        soloChessAddMove(moves, x, y, tx, ty)
                                    end
                                end
                            end
                        end
                    end
                    if not capturesOnly and not piece.moved and x == 5 and not soloChessInCheck(board, color) then
                        local enemy = color == "W" and "B" or "W"
                        local rook = board[8][y]
                        if rook and rook.color == color and rook.kind == "R" and not rook.moved and
                           not board[6][y] and not board[7][y] and
                           not soloChessIsAttacked(board, 6, y, enemy) and not soloChessIsAttacked(board, 7, y, enemy) then
                            soloChessAddMove(moves, x, y, 7, y, { castle = "K" })
                        end
                        rook = board[1][y]
                        if rook and rook.color == color and rook.kind == "R" and not rook.moved and
                           not board[2][y] and not board[3][y] and not board[4][y] and
                           not soloChessIsAttacked(board, 4, y, enemy) and not soloChessIsAttacked(board, 3, y, enemy) then
                            soloChessAddMove(moves, x, y, 3, y, { castle = "Q" })
                        end
                    end
                end
            end
        end
    end
    return moves
end

local function soloChessApplyMove(board, state, move)
    local nextBoard = soloChessCopyBoard(board)
    local nextState = soloChessCopyState(state)
    local piece = nextBoard[move.x1][move.y1]
    if not piece then return nextBoard, nextState, nil end
    local wasPawn = piece.kind == "P"
    local captured = nextBoard[move.x2][move.y2]
    if move.enPassant then
        captured = nextBoard[move.x2][move.y1]
        nextBoard[move.x2][move.y1] = nil
    end
    nextBoard[move.x2][move.y2] = piece
    nextBoard[move.x1][move.y1] = nil
    piece.moved = true
    if move.castle == "K" then
        local rook = nextBoard[8][move.y1]
        nextBoard[6][move.y1] = rook
        nextBoard[8][move.y1] = nil
        if rook then rook.moved = true end
    elseif move.castle == "Q" then
        local rook = nextBoard[1][move.y1]
        nextBoard[4][move.y1] = rook
        nextBoard[1][move.y1] = nil
        if rook then rook.moved = true end
    end
    if wasPawn and (move.y2 == 1 or move.y2 == 8 or move.promotion) then piece.kind = "Q" end
    nextState.enPassantX, nextState.enPassantY = nil, nil
    if wasPawn and abs(move.y2 - move.y1) == 2 then
        nextState.enPassantX = move.x1
        nextState.enPassantY = floor((move.y1 + move.y2) / 2)
    end
    if wasPawn or captured then nextState.halfmove = 0 else nextState.halfmove = (nextState.halfmove or 0) + 1 end
    if piece.color == "B" then nextState.moveNumber = (nextState.moveNumber or 1) + 1 end
    return nextBoard, nextState, captured
end

local function soloChessLegalMoves(board, state, color, capturesOnly)
    local legal = {}
    for _, move in ipairs(soloChessPseudoMoves(board, state, color, capturesOnly)) do
        local nextBoard = soloChessApplyMove(board, state, move)
        if not soloChessInCheck(nextBoard, color) then legal[#legal + 1] = move end
    end
    return legal
end

local function soloChessMoveTarget(move)
    return tostring(move.x2) .. ":" .. tostring(move.y2)
end

local function soloChessCapturedPiece(board, move)
    if move.enPassant then return board[move.x2] and board[move.x2][move.y1] end
    return board[move.x2] and board[move.x2][move.y2]
end

local function soloChessPositionValue(piece, x, y)
    local center = (3.5 - abs(4.5 - x)) + (3.5 - abs(4.5 - y))
    if piece.kind == "P" then
        local advance = piece.color == "W" and (y - 2) or (7 - y)
        return advance * 9 + center * 2
    elseif piece.kind == "N" then
        return center * 11 - ((x == 1 or x == 8 or y == 1 or y == 8) and 14 or 0)
    elseif piece.kind == "B" then
        return center * 7
    elseif piece.kind == "R" then
        return (piece.moved and 1 or 0) + center
    elseif piece.kind == "Q" then
        return center * 2
    elseif piece.kind == "K" then
        local castled = piece.moved and (x == 3 or x == 7)
        return (castled and 32 or 0) - center * 4
    end
    return 0
end

local function soloChessEvaluate(board)
    local score = 0
    local bishops = { W = 0, B = 0 }
    for x = 1, 8 do
        for y = 1, 8 do
            local piece = board[x][y]
            if piece then
                local sign = piece.color == "B" and 1 or -1
                score = score + sign * ((SOLO_CHESS_VALUE[piece.kind] or 0) + soloChessPositionValue(piece, x, y))
                if piece.kind == "B" then bishops[piece.color] = bishops[piece.color] + 1 end
            end
        end
    end
    if bishops.B >= 2 then score = score + 24 end
    if bishops.W >= 2 then score = score - 24 end
    if soloChessInCheck(board, "W") then score = score + 22 end
    if soloChessInCheck(board, "B") then score = score - 22 end
    return score
end

local function soloChessMoveOrder(board, move)
    local moving = board[move.x1][move.y1]
    local captured = soloChessCapturedPiece(board, move)
    local score = 0
    if captured then score = score + (SOLO_CHESS_VALUE[captured.kind] or 0) * 10 - (SOLO_CHESS_VALUE[moving and moving.kind] or 0) end
    if move.promotion then score = score + 8000 end
    if move.castle then score = score + 120 end
    local center = (3.5 - abs(4.5 - move.x2)) + (3.5 - abs(4.5 - move.y2))
    score = score + center
    return score
end

local function soloChessSortMoves(board, moves)
    sort(moves, function(left, right) return soloChessMoveOrder(board, left) > soloChessMoveOrder(board, right) end)
end

local function soloChessSearch(board, state, color, depth, alpha, beta, context, ply)
    context.nodes = context.nodes + 1
    if context.nodes >= context.nextYield then
        context.nextYield = context.nextYield + context.yieldEvery
        coroutine.yield(context.nodes, context.currentDepth)
    end
    if context.nodes >= context.limit then
        context.aborted = true
        return soloChessEvaluate(board)
    end

    local moves = soloChessLegalMoves(board, state, color, false)
    if #moves == 0 then
        if soloChessInCheck(board, color) then
            return color == "B" and (-SOLO_CHESS_MATE + ply) or (SOLO_CHESS_MATE - ply)
        end
        return 0
    end
    if depth <= 0 then return soloChessEvaluate(board) end
    soloChessSortMoves(board, moves)

    if color == "B" then
        local best = -SOLO_CHESS_MATE * 2
        for _, move in ipairs(moves) do
            local nextBoard, nextState = soloChessApplyMove(board, state, move)
            local value = soloChessSearch(nextBoard, nextState, "W", depth - 1, alpha, beta, context, ply + 1)
            if value > best then best = value end
            if best > alpha then alpha = best end
            if beta <= alpha or context.aborted then break end
        end
        return best
    end

    local best = SOLO_CHESS_MATE * 2
    for _, move in ipairs(moves) do
        local nextBoard, nextState = soloChessApplyMove(board, state, move)
        local value = soloChessSearch(nextBoard, nextState, "B", depth - 1, alpha, beta, context, ply + 1)
        if value < best then best = value end
        if best < beta then beta = best end
        if beta <= alpha or context.aborted then break end
    end
    return best
end

local function soloChessOpeningMove(board, moves, level)
    if level < 3 then return nil end
    local preferred
    if board[5][4] and board[5][4].color == "W" and board[5][4].kind == "P" then preferred = { 5, 7, 5, 5 }
    elseif board[4][4] and board[4][4].color == "W" and board[4][4].kind == "P" then preferred = { 4, 7, 4, 5 }
    elseif board[3][4] and board[3][4].color == "W" and board[3][4].kind == "P" then preferred = { 5, 7, 5, 5 }
    end
    if preferred then
        for _, move in ipairs(moves) do
            if move.x1 == preferred[1] and move.y1 == preferred[2] and move.x2 == preferred[3] and move.y2 == preferred[4] then return move end
        end
    end
end

local function soloChessFindBestMove(board, state, level, rng)
    local config = SOLO_CHESS_LEVELS[level] or SOLO_CHESS_LEVELS[3]
    local moves = soloChessLegalMoves(board, state, "B", false)
    if #moves == 0 then return nil, 0, 0, 0 end
    local opening = soloChessOpeningMove(board, moves, level)
    if opening then return opening, 0, 0, 1 end
    if level == 1 then return moves[rng:Next(#moves)], 0, 0, 1 end

    soloChessSortMoves(board, moves)
    local context = {
        nodes = 0,
        limit = config.nodes,
        yieldEvery = 220,
        nextYield = 220,
        currentDepth = 1,
        aborted = false,
    }
    local completedMove = moves[1]
    local completedScore = -SOLO_CHESS_MATE * 2
    local completedDepth = 0

    for searchDepth = 1, config.depth do
        context.currentDepth = searchDepth
        context.aborted = false
        local bestMove, bestScore = nil, -SOLO_CHESS_MATE * 2
        local rootAlpha = -SOLO_CHESS_MATE * 2
        for _, move in ipairs(moves) do
            local nextBoard, nextState = soloChessApplyMove(board, state, move)
            local value = soloChessSearch(nextBoard, nextState, "W", searchDepth - 1, rootAlpha, SOLO_CHESS_MATE * 2, context, 1)
            if config.noise > 0 then value = value + rng:Next(config.noise * 2 + 1) - config.noise - 1 end
            if value > bestScore then bestScore, bestMove = value, move end
            if bestScore > rootAlpha then rootAlpha = bestScore end
            if context.aborted then break end
        end
        if not context.aborted and bestMove then
            completedMove, completedScore, completedDepth = bestMove, bestScore, searchDepth
            -- Search the strongest candidate first on the next iteration.
            for index, move in ipairs(moves) do
                if move == completedMove then table.remove(moves, index); break end
            end
            table.insert(moves, 1, completedMove)
        else
            break
        end
    end
    return completedMove, completedScore, completedDepth, context.nodes
end

local function soloChessInsufficientMaterial(board)
    local nonKings = {}
    for x = 1, 8 do
        for y = 1, 8 do
            local piece = board[x][y]
            if piece and piece.kind ~= "K" then nonKings[#nonKings + 1] = piece.kind end
        end
    end
    if #nonKings == 0 then return true end
    if #nonKings == 1 and (nonKings[1] == "B" or nonKings[1] == "N") then return true end
    return false
end

local function soloChessMoveText(board, move, captured)
    local piece = board[move.x1] and board[move.x1][move.y1]
    if move.castle == "K" then return "O-O" end
    if move.castle == "Q" then return "O-O-O" end
    local prefix = piece and piece.kind ~= "P" and piece.kind or ""
    local capture = captured and "x" or "-"
    local from = string.char(96 + move.x1) .. tostring(move.y1)
    local destination = string.char(96 + move.x2) .. tostring(move.y2)
    return prefix .. from .. capture .. destination .. (move.promotion and "=Q" or "")
end

function Solo:BuildCHESSView()
    if self.views.CHESS then return self.views.CHESS end
    local colors = palette()
    local view = { game = "CHESS", buttons = {}, cursorX = 5, cursorY = 2, level = 3 }
    local frame = CreateFrame("Frame", nil, self.window.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.boardFrame = CreateFrame("Frame", nil, frame, templateName())
    view.boardFrame:SetSize(416, 416)
    view.boardFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -18)
    applyBackdrop(view.boardFrame, colors.panel, colors.border)

    for displayRow = 1, 8 do
        for displayCol = 1, 8 do
            local button = CreateFrame("Button", nil, view.boardFrame, templateName())
            button:SetSize(50, 50)
            button:SetPoint("TOPLEFT", view.boardFrame, "TOPLEFT", 8 + (displayCol - 1) * 50, -8 - (displayRow - 1) * 50)
            button.pieceTexture = button:CreateTexture(nil, "ARTWORK")
            button.pieceTexture:SetSize(SOLO_CHESS_PIECE_SIZE, SOLO_CHESS_PIECE_SIZE)
            button.pieceTexture:SetPoint("CENTER", button, "CENTER", 0, 1)
            button.pieceTexture:SetTexCoord(0, 1, 0, 1)
            button.pieceTexture:Hide()
            button.fallbackLabel = createText(button, 11, colors.text, "CENTER")
            button.fallbackLabel:SetSize(30, 30)
            button.fallbackLabel:SetPoint("CENTER", button, "CENTER", 0, 0)
            button.fallbackLabel:Hide()
            button.coord = createText(button, 7, colors.muted, "RIGHT")
            button.coord:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 1)
            button.displayCol, button.displayRow = displayCol, displayRow
            button:SetScript("OnClick", function(selfButton) view:ClickDisplay(selfButton.displayCol, selfButton.displayRow) end)
            view.buttons[#view.buttons + 1] = button
        end
    end

    view.info = CreateFrame("Frame", nil, frame, templateName())
    view.info:SetPoint("TOPLEFT", view.boardFrame, "TOPRIGHT", 12, 0)
    view.info:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
    applyBackdrop(view.info, colors.panel, colors.border)

    view.turnText = createText(view.info, 14, colors.text, "CENTER")
    view.turnText:SetPoint("TOPLEFT", view.info, "TOPLEFT", 8, -12)
    view.turnText:SetPoint("TOPRIGHT", view.info, "TOPRIGHT", -8, -12)
    view.difficultyText = createText(view.info, 10, colors.gold, "CENTER")
    view.difficultyText:SetPoint("TOPLEFT", view.turnText, "BOTTOMLEFT", 0, -7)
    view.difficultyText:SetPoint("RIGHT", view.turnText, "RIGHT", 0, 0)

    view.levelLabel = createText(view.info, 9, colors.muted, "LEFT")
    view.levelLabel:SetPoint("TOPLEFT", view.difficultyText, "BOTTOMLEFT", 0, -16)
    view.levelLabel:SetText("ENEMY LEVEL")
    view.levelButtons = {}
    local previous
    for level = 1, 5 do
        local button = createButton(view.info, tostring(level), 38, 26, function() view:SetLevel(level) end)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 5, 0) else button:SetPoint("TOPLEFT", view.levelLabel, "BOTTOMLEFT", 0, -6) end
        view.levelButtons[level] = button
        previous = button
    end

    view.analysis = createText(view.info, 9, colors.muted, "LEFT")
    view.analysis:SetPoint("TOPLEFT", view.levelButtons[1], "BOTTOMLEFT", 0, -14)
    view.analysis:SetPoint("RIGHT", view.info, "RIGHT", -8, 0)
    view.analysis:SetHeight(48)
    view.analysis:SetWordWrap(true)

    view.lastMoveText = createText(view.info, 9, colors.text, "LEFT")
    view.lastMoveText:SetPoint("TOPLEFT", view.analysis, "BOTTOMLEFT", 0, -8)
    view.lastMoveText:SetPoint("RIGHT", view.info, "RIGHT", -8, 0)
    view.lastMoveText:SetHeight(34)
    view.lastMoveText:SetWordWrap(true)

    view.help = createText(view.info, 9, colors.muted, "LEFT")
    view.help:SetPoint("TOPLEFT", view.lastMoveText, "BOTTOMLEFT", 0, -12)
    view.help:SetPoint("RIGHT", view.info, "RIGHT", -8, 0)
    view.help:SetHeight(135)
    view.help:SetWordWrap(true)
    view.help:SetText("CONTROLS\nMouse: select a piece, then a square.\nWASD / arrows: move cursor.\nSpace / Enter: select or move.\n1–5: change enemy level. N: new game.\n\nIncludes check, checkmate, stalemate, castling, en passant and queen promotion.")

    view.newGame = createButton(view.info, "NEW GAME", 100, 28, function() view:Start() end)
    view.newGame:SetPoint("BOTTOMLEFT", view.info, "BOTTOMLEFT", 12, 14)
    setButtonAccent(view.newGame, colors.green)
    view.resign = createButton(view.info, "RESIGN", 82, 28, function() view:Resign() end)
    view.resign:SetPoint("BOTTOMRIGHT", view.info, "BOTTOMRIGHT", -12, 14)
    setButtonAccent(view.resign, colors.red)

    function view:DisplayToBoard(col, row) return col, 9 - row end
    function view:BoardToDisplay(x, y) return x, 9 - y end

    function view:SetLevel(level)
        self.level = clamp(level, 1, 5)
        local save = ensureSave()
        if save and save.chess then save.chess.level = self.level end
        self:Refresh()
        Solo:SetStatus("Chess enemy set to Level " .. tostring(self.level) .. " · " .. SOLO_CHESS_LEVELS[self.level].name .. ".", colors.gold)
    end

    function view:GetSelectedMoves()
        local targets = {}
        if self.selected and self.turn == "W" then
            for _, move in ipairs(soloChessLegalMoves(self.board, self.state, "W", false)) do
                if move.x1 == self.selected.x and move.y1 == self.selected.y then targets[soloChessMoveTarget(move)] = true end
            end
        end
        return targets
    end

    function view:Refresh()
        local targets = self:GetSelectedMoves()
        local whiteKingX, whiteKingY = soloChessFindKing(self.board, "W")
        local blackKingX, blackKingY = soloChessFindKing(self.board, "B")
        local whiteCheck = soloChessInCheck(self.board, "W")
        local blackCheck = soloChessInCheck(self.board, "B")
        for _, button in ipairs(self.buttons) do
            local x, y = self:DisplayToBoard(button.displayCol, button.displayRow)
            local piece = self.board[x][y]
            local light = ((x + y) % 2 == 0)
            local base = light and { 0.58, 0.60, 0.62, 1 } or { 0.19, 0.21, 0.24, 1 }
            local border = colors.border
            if self.selected and self.selected.x == x and self.selected.y == y then
                base, border = darken(colors.accent, 0.18), colors.accent
            elseif targets[tostring(x) .. ":" .. tostring(y)] then
                border = colors.green
            elseif self.cursorX == x and self.cursorY == y then
                border = colors.gold
            end
            if (whiteCheck and x == whiteKingX and y == whiteKingY) or (blackCheck and x == blackKingX and y == blackKingY) then
                base, border = darken(colors.red, 0.30), colors.red
            end
            applyBackdrop(button, base, border)
            if piece then
                local texturePath = SOLO_CHESS_TEXTURES[piece.color .. piece.kind]
                if texturePath then
                    button.pieceTexture:SetTexture(texturePath)
                    button.pieceTexture:SetVertexColor(1, 1, 1, 1)
                    button.pieceTexture:Show()
                    button.fallbackLabel:Hide()
                else
                    button.pieceTexture:Hide()
                    button.fallbackLabel:SetText(piece.color .. piece.kind)
                    button.fallbackLabel:SetTextColor(piece.color == "W" and 0.98 or 0.08, piece.color == "W" and 0.98 or 0.08, piece.color == "W" and 0.98 or 0.08, 1)
                    button.fallbackLabel:Show()
                end
            else
                button.pieceTexture:Hide()
                button.fallbackLabel:Hide()
                button.fallbackLabel:SetText("")
            end
            button.coord:SetText(string.char(96 + x) .. tostring(y))
        end

        local config = SOLO_CHESS_LEVELS[self.level] or SOLO_CHESS_LEVELS[3]
        self.difficultyText:SetText("LEVEL " .. tostring(self.level) .. " · " .. config.name)
        for level, button in ipairs(self.levelButtons) do
            local selected = level == self.level
            button.creshSelected = selected
            applyBackdrop(button, selected and darken(colors.gold, 0.28) or colors.panelRaised, selected and colors.gold or colors.border)
        end

        if self.gameOver then
            self.turnText:SetText(self.resultText or "GAME OVER")
            self.turnText:SetTextColor((self.result == "WIN" and colors.green or self.result == "LOSS" and colors.red or colors.gold)[1], (self.result == "WIN" and colors.green or self.result == "LOSS" and colors.red or colors.gold)[2], (self.result == "WIN" and colors.green or self.result == "LOSS" and colors.red or colors.gold)[3], 1)
        elseif self.aiThinking then
            self.turnText:SetText("ENEMY THINKING…")
            self.turnText:SetTextColor(colors.gold[1], colors.gold[2], colors.gold[3], 1)
        elseif self.turn == "W" then
            self.turnText:SetText(whiteCheck and "YOUR TURN · CHECK" or "YOUR TURN")
            self.turnText:SetTextColor(colors.green[1], colors.green[2], colors.green[3], 1)
        else
            self.turnText:SetText(blackCheck and "ENEMY IN CHECK" or "ENEMY TURN")
            self.turnText:SetTextColor(colors.gold[1], colors.gold[2], colors.gold[3], 1)
        end
        self.analysis:SetText(self.aiThinking and format("Searching depth %d · %d positions", self.aiDepth or 1, self.aiNodes or 0) or format("Level %d searches up to %d ply. Higher levels evaluate more replies and make fewer random choices.", self.level, config.depth))
        self.lastMoveText:SetText(self.lastMove and ("LAST MOVE  " .. self.lastMove) or "YOU ARE WHITE · Move first")
        setButtonEnabled(self.resign, not self.gameOver)
    end

    function view:Finish(result, reason)
        if self.gameOver then return end
        self.gameOver = true
        self.aiThinking, self.aiCoroutine = false, nil
        self.result = result
        self.resultText = result == "WIN" and "YOU WON" or result == "LOSS" and "ENEMY WON" or "DRAW"
        self.selected = nil
        local save = ensureSave()
        if save and save.chess then
            save.chess.games = (save.chess.games or 0) + 1
            if result == "WIN" then
                save.chess.wins = (save.chess.wins or 0) + 1
                save.chess.bestLevel = max(save.chess.bestLevel or 0, self.level)
            elseif result == "LOSS" then save.chess.losses = (save.chess.losses or 0) + 1
            else save.chess.draws = (save.chess.draws or 0) + 1 end
        end
        local detail = "Level " .. tostring(self.level) .. (reason and (" · " .. reason) or "")
        Solo:RecordHistory("CHESS", "SOLO", result, "Computer L" .. tostring(self.level), detail, self.level)
        Solo:PushLeaderboards()
        Solo:SetStatus(self.resultText .. (reason and (" · " .. reason) or ""), result == "WIN" and colors.green or result == "LOSS" and colors.red or colors.gold)
        self:Refresh()
        Solo:RefreshHub()
        if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
    end

    function view:CheckOutcome(sideToMove)
        if soloChessInsufficientMaterial(self.board) then self:Finish("DRAW", "insufficient material"); return true end
        if (self.state.halfmove or 0) >= 100 then self:Finish("DRAW", "50-move rule"); return true end
        local moves = soloChessLegalMoves(self.board, self.state, sideToMove, false)
        if #moves > 0 then return false end
        if soloChessInCheck(self.board, sideToMove) then
            self:Finish(sideToMove == "B" and "WIN" or "LOSS", "checkmate")
        else
            self:Finish("DRAW", "stalemate")
        end
        return true
    end

    function view:FindMove(x1, y1, x2, y2)
        for _, move in ipairs(soloChessLegalMoves(self.board, self.state, "W", false)) do
            if move.x1 == x1 and move.y1 == y1 and move.x2 == x2 and move.y2 == y2 then return move end
        end
    end

    function view:ApplyPlayerMove(move)
        local oldBoard = self.board
        local nextBoard, nextState, captured = soloChessApplyMove(self.board, self.state, move)
        self.board, self.state = nextBoard, nextState
        self.lastMove = "YOU  " .. soloChessMoveText(oldBoard, move, captured)
        self.selected = nil
        self.cursorX, self.cursorY = move.x2, move.y2
        if self:CheckOutcome("B") then return end
        self.turn = "B"
        self:BeginAI()
    end

    function view:ClickBoard(x, y)
        if self.gameOver or self.aiThinking or self.turn ~= "W" then return end
        self.cursorX, self.cursorY = x, y
        local piece = self.board[x][y]
        if not self.selected then
            if piece and piece.color == "W" then self.selected = { x = x, y = y } end
            self:Refresh()
            return
        end
        if piece and piece.color == "W" then
            self.selected = { x = x, y = y }
            self:Refresh()
            return
        end
        local move = self:FindMove(self.selected.x, self.selected.y, x, y)
        if move then
            self:ApplyPlayerMove(move)
        else
            Solo:SetStatus("That move is not legal. Your king may not be left in check.", colors.red)
            self:Refresh()
        end
    end

    function view:ClickDisplay(col, row)
        local x, y = self:DisplayToBoard(col, row)
        self:ClickBoard(x, y)
    end

    function view:BeginAI()
        if self.gameOver then return end
        self.aiThinking = true
        self.aiNodes, self.aiDepth = 0, 1
        self.searchToken = (self.searchToken or 0) + 1
        local token = self.searchToken
        local board = soloChessCopyBoard(self.board)
        local state = soloChessCopyState(self.state)
        local level = self.level
        local rng = self.rng
        self.aiCoroutine = coroutine.create(function()
            local move, score, depth, nodes = soloChessFindBestMove(board, state, level, rng)
            return token, move, score, depth, nodes
        end)
        Solo:SetStatus("Chess enemy is thinking…", colors.gold)
        self:Refresh()
    end

    function view:CompleteAI(move, score, depth, nodes)
        self.aiThinking, self.aiCoroutine = false, nil
        if self.gameOver then return end
        if not move then
            self:CheckOutcome("B")
            return
        end
        local oldBoard = self.board
        local nextBoard, nextState, captured = soloChessApplyMove(self.board, self.state, move)
        self.board, self.state = nextBoard, nextState
        self.lastMove = "ENEMY  " .. soloChessMoveText(oldBoard, move, captured)
        self.aiScore, self.aiDepth, self.aiNodes = score or 0, depth or 0, nodes or self.aiNodes
        self.cursorX, self.cursorY = move.x2, move.y2
        if self:CheckOutcome("W") then return end
        self.turn = "W"
        Solo:SetStatus(soloChessInCheck(self.board, "W") and "Your king is in check." or "Your move.", soloChessInCheck(self.board, "W") and colors.red or colors.green)
        self:Refresh()
    end

    function view:OnUpdate()
        if not self.aiThinking or not self.aiCoroutine then return end
        local ok, first, second, third, fourth, fifth = coroutine.resume(self.aiCoroutine)
        if not ok then
            self.aiThinking, self.aiCoroutine = false, nil
            local legal = soloChessLegalMoves(self.board, self.state, "B", false)
            local fallback = legal[1]
            Solo:SetStatus("Chess search recovered from an error and used a safe move.", colors.red)
            self:CompleteAI(fallback, 0, 0, 0)
            return
        end
        if coroutine.status(self.aiCoroutine) == "dead" then
            local token, move, score, depth, nodes = first, second, third, fourth, fifth
            if token == self.searchToken then self:CompleteAI(move, score, depth, nodes) end
        else
            self.aiNodes, self.aiDepth = tonumber(first) or self.aiNodes, tonumber(second) or self.aiDepth
            self:Refresh()
        end
    end

    function view:Resign()
        if self.gameOver then return end
        self:Finish("LOSS", "you resigned")
    end

    function view:OnKeyDown(key)
        key = upper(tostring(key or ""))
        if key == "N" then self:Start(); return end
        local level = tonumber(key)
        if level and level >= 1 and level <= 5 then self:SetLevel(level); return end
        if self.gameOver or self.aiThinking then return end
        local dx, dy = 0, 0
        if key == "A" or key == "LEFT" then dx = -1
        elseif key == "D" or key == "RIGHT" then dx = 1
        elseif key == "W" or key == "UP" then dy = 1
        elseif key == "S" or key == "DOWN" then dy = -1
        elseif key == "SPACE" or key == "ENTER" then self:ClickBoard(self.cursorX, self.cursorY); return
        else return end
        self.cursorX = clamp(self.cursorX + dx, 1, 8)
        self.cursorY = clamp(self.cursorY + dy, 1, 8)
        self:Refresh()
    end

    function view:Start()
        local save = ensureSave()
        self.searchToken = (self.searchToken or 0) + 1
        self.level = clamp(save and save.chess and save.chess.level or self.level or 3, 1, 5)
        self.rng = makeRng(floor(now() * 1000) + self.level * 7919 + ((save and save.chess and save.chess.games or 0) * 97))
        self.board = soloChessInitialBoard()
        self.state = { halfmove = 0, moveNumber = 1 }
        self.turn = "W"
        self.selected = nil
        self.cursorX, self.cursorY = 5, 2
        self.gameOver, self.aiThinking, self.aiCoroutine = false, false, nil
        self.result, self.resultText, self.lastMove = nil, nil, nil
        self.aiNodes, self.aiDepth, self.aiScore = 0, 0, 0
        Solo:SetStatus("Solo Chess started. You are White.", colors.green)
        self:Refresh()
    end

    self.views.CHESS = view
    return view
end


-- DUNGEON DWELLER -------------------------------------------------------------
local DUNGEON_CLASS_ORDER = { "PALADIN", "WARRIOR", "ROGUE", "RANGER", "MAGE", "PRIEST", "WARLOCK", "DEFENDER" }
local DUNGEON_CLASSES = {
    PALADIN = {
        name = "Paladin", asset = "HumanPaladin", baseHP = 12, baseAttack = 2,
        healthGain = 2, healthHeal = 4, attackGain = 1, attackDie = 6,
        blockChance = 18, blockAmount = 1, bossDamage = 2,
        bossHP = 2, bossAttack = 1, bossFullHeal = true,
        short = "BLOCK · BOSS SLAYER",
        strength = "Balanced fighter. Blocks some damage, deals bonus damage to bosses and fully heals after a boss relic.",
        weakness = "Reliable rather than explosive; Attack upgrades are modest.",
    },
    WARRIOR = {
        name = "Warrior", asset = "OrcWarrior", baseHP = 14, baseAttack = 3,
        healthGain = 2, healthHeal = 3, attackGain = 2, attackDie = 6,
        flatDamage = 1, bossHP = 2, bossAttack = 2, bossHeal = 4,
        short = "HEAVY DAMAGE · HIGH HP",
        strength = "Highest direct physical pressure. Every hit gains bonus damage and Attack upgrades are larger.",
        weakness = "No block, evasion or passive healing.",
    },
    ROGUE = {
        name = "Rogue", asset = "UndeadRogue", baseHP = 9, baseAttack = 2,
        healthGain = 1, healthHeal = 2, attackGain = 2, attackDie = 6,
        evadeChance = 20, critAt = 5, critMultiplier = 1.65,
        bossHP = 1, bossAttack = 2, bossHeal = 3,
        short = "CRITICALS · 20% EVADE",
        strength = "Rolls of 5 or 6 critically strike and enemy attacks can be completely evaded.",
        weakness = "Lowest sustained health and the smallest Health upgrades.",
    },
    RANGER = {
        name = "Ranger", asset = "ElfRanger", baseHP = 11, baseAttack = 2,
        healthGain = 2, healthHeal = 3, attackGain = 1, attackDie = 6,
        minionBonus = 1, multiTargetBonus = 1,
        bossHP = 2, bossAttack = 1, bossHeal = 4, bossMinionBonus = 1,
        short = "MINION MASTER · CROWD BONUS",
        strength = "Deals bonus damage in crowded rooms and gives every minion +1 damage.",
        weakness = "Average single-target damage when fighting without minions.",
    },
    MAGE = {
        name = "Mage", asset = "HumanMage", baseHP = 8, baseAttack = 3,
        healthGain = 1, healthHeal = 2, attackGain = 2, attackDie = 8,
        burstAt = 7, burstBonus = 2,
        bossHP = 1, bossAttack = 2, bossHeal = 3,
        short = "D8 SPELLS · ARCANE BURST",
        strength = "Attacks with a D8. Rolls of 7 or 8 trigger extra arcane burst damage.",
        weakness = "Very fragile and gains little health from upgrades or relics.",
    },
    PRIEST = {
        name = "Priest", asset = "HumanPriest", baseHP = 12, baseAttack = 1,
        healthGain = 3, healthHeal = 5, attackGain = 1, attackDie = 6,
        roomHeal = 2, healOnAttackAt = 6, healOnAttack = 1,
        bossHP = 3, bossAttack = 1, bossFullHeal = true,
        short = "ROOM HEALING · SURVIVOR",
        strength = "Heals after every cleared room, heals on a perfect attack roll and has excellent Health upgrades.",
        weakness = "Lowest starting attack and slow damage growth.",
    },
    WARLOCK = {
        name = "Warlock", asset = "VoidWarlock", baseHP = 10, baseAttack = 2,
        healthGain = 2, healthHeal = 2, attackGain = 1, attackDie = 6,
        minionBonus = 1, lifeStealAt = 5, lifeSteal = 1,
        bossHP = 2, bossAttack = 1, bossHeal = 3, bossMinionBonus = 1,
        short = "LIFE STEAL · EMPOWER MINIONS",
        strength = "High rolls steal life and all minions deal +1 damage.",
        weakness = "Direct stat upgrades are smaller than aggressive classes.",
    },
    DEFENDER = {
        name = "Defender", asset = "DwarfDefender", baseHP = 16, baseAttack = 1,
        healthGain = 4, healthHeal = 4, attackGain = 1, attackDie = 6,
        flatBlock = 1, blockChance = 25, blockAmount = 1,
        bossHP = 4, bossAttack = 1, bossHeal = 5,
        short = "ARMOUR · MASSIVE HEALTH",
        strength = "Reduces every successful enemy hit and has the largest health pool and Health upgrades.",
        weakness = "Slowest damage output and relies on attrition or minions.",
    },
}
local DUNGEON_CONTENT = CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
for classKey, classData in pairs(DUNGEON_CLASSES) do
    classData.armourSets = DUNGEON_CONTENT and DUNGEON_CONTENT.GetArmourSets and DUNGEON_CONTENT:GetArmourSets(classKey) or {}
end

local DUNGEON_DEFAULT_CLASS = {
    PALADIN = "PALADIN", WARRIOR = "WARRIOR", ROGUE = "ROGUE", HUNTER = "RANGER",
    MAGE = "MAGE", PRIEST = "PRIEST", WARLOCK = "WARLOCK", DRUID = "RANGER", SHAMAN = "WARRIOR",
}
local DUNGEON_BODY_SET = {
    SkeletonKing="05_Boss_FullBody_Set_A", LichLord="05_Boss_FullBody_Set_A",
    DemonWarlord="05_Boss_FullBody_Set_A", VoidPriest="05_Boss_FullBody_Set_A",
    OrcChampion="05_Boss_FullBody_Set_A", TrollWitchDoctor="05_Boss_FullBody_Set_A",
    DarkPaladin="05_Boss_FullBody_Set_A", FireMageBoss="05_Boss_FullBody_Set_A",
    IceQueen="05_Boss_FullBody_Set_A", SpiderMatriarch="05_Boss_FullBody_Set_A",
    WolfAlpha="07_Boss_FullBody_Set_B", BatLord="07_Boss_FullBody_Set_B",
    SlimeTyrant="07_Boss_FullBody_Set_B", GoblinMechBoss="07_Boss_FullBody_Set_B",
    CultMaster="07_Boss_FullBody_Set_B", Necromancer="07_Boss_FullBody_Set_B",
    FelKnight="07_Boss_FullBody_Set_B", ShadowAssassin="07_Boss_FullBody_Set_B",
    StoneGolem="07_Boss_FullBody_Set_B", DragonkinBoss="07_Boss_FullBody_Set_B",
}
local DUNGEON_ICON_SET = {
    SkeletonKing="04_Boss_Icons_Set_A", LichLord="04_Boss_Icons_Set_A",
    DemonWarlord="04_Boss_Icons_Set_A", VoidPriest="04_Boss_Icons_Set_A",
    OrcChampion="04_Boss_Icons_Set_A", TrollWitchDoctor="04_Boss_Icons_Set_A",
    DarkPaladin="04_Boss_Icons_Set_A", FireMageBoss="04_Boss_Icons_Set_A",
    IceQueen="04_Boss_Icons_Set_A", SpiderMatriarch="04_Boss_Icons_Set_A",
    WolfAlpha="06_Boss_Icons_Set_B", BatLord="06_Boss_Icons_Set_B",
    SlimeTyrant="06_Boss_Icons_Set_B", GoblinMechBoss="06_Boss_Icons_Set_B",
    CultMaster="06_Boss_Icons_Set_B", Necromancer="06_Boss_Icons_Set_B",
    FelKnight="06_Boss_Icons_Set_B", ShadowAssassin="06_Boss_Icons_Set_B",
    StoneGolem="06_Boss_Icons_Set_B", DragonkinBoss="06_Boss_Icons_Set_B",
}
local DUNGEON_BODY_KEYS = {
    "SkeletonKing", "LichLord", "DemonWarlord", "VoidPriest", "OrcChampion",
    "TrollWitchDoctor", "DarkPaladin", "FireMageBoss", "IceQueen", "SpiderMatriarch",
    "WolfAlpha", "BatLord", "SlimeTyrant", "GoblinMechBoss", "CultMaster",
    "Necromancer", "FelKnight", "ShadowAssassin", "StoneGolem", "DragonkinBoss",
}
local DUNGEON_MINION_VARIANTS = {
    Bat={"Bat_Black_01","Bat_Blue_03","Bat_Brown_02","Bat_Violet_04"},
    Beetle={"Spider_Brown_02","Spider_Night_03"},
    Familiar={"Imp_Blue_03","Imp_Purple_02","Cultist_Purple_01"},
    Imp={"Imp_Red_01","Imp_Purple_02","Imp_Blue_03"},
    Mimic={"Goblin_Hood_03","Goblin_Guard_02"},
    Moth={"Bat_Blue_03","Bat_Violet_04"},
    Ooze={"Slime_Green_01","Slime_Yellow_02"},
    Rat={"Wolf_Dark_02","Wolf_Grey_01"},
    Sprite={"Imp_Blue_03","Demon_Blue_03"},
    Wisp={"Demon_Blue_03","Cultist_Horned_04"},
}

local function dungeonTexture(setKey, assetKey)
    if type(_G.CreshGamesDDGetTexture) == "function" then
        return _G.CreshGamesDDGetTexture(setKey, assetKey)
    end
    local sets = _G.CreshGamesDungeonDwellersSets
    local set = sets and sets[setKey]
    return set and set.assets and set.assets[assetKey] or nil
end

local function dungeonCreateOpaqueTexture(parent, duplicateLayers)
    local duplicates = {}
    for _ = 1, max(0, floor(tonumber(duplicateLayers) or 0)) do
        local layer = parent:CreateTexture(nil, "ARTWORK")
        layer:SetAllPoints()
        layer:SetBlendMode("BLEND")
        duplicates[#duplicates + 1] = layer
    end
    local region = parent:CreateTexture(nil, "OVERLAY")
    region:SetAllPoints()
    region:SetBlendMode("BLEND")
    region.creshOpacityLayers = duplicates
    return region
end

local function dungeonEachTexture(region, callback)
    if not region or not callback then return end
    for _, layer in ipairs(region.creshOpacityLayers or {}) do callback(layer) end
    callback(region)
end

local function dungeonSetTexture(region, path)
    if not region then return end
    path = path or "Interface\\Icons\\INV_Misc_QuestionMark"
    dungeonEachTexture(region, function(layer)
        layer:SetTexture(path)
        layer:SetVertexColor(1, 1, 1, 1)
        layer:SetAlpha(1)
        layer:Show()
    end)
end

local function dungeonSetDesaturated(region, value)
    dungeonEachTexture(region, function(layer) if layer.SetDesaturated then layer:SetDesaturated(value and true or false) end end)
end

local function dungeonSetVertexColor(region, r, g, b, a)
    dungeonEachTexture(region, function(layer) layer:SetVertexColor(r or 1, g or 1, b or 1, a or 1) end)
end

local function dungeonDefaultClassKey()
    local classToken
    if type(UnitClass) == "function" then
        local _, token = UnitClass("player")
        classToken = token
    end
    return DUNGEON_DEFAULT_CLASS[classToken or ""] or "PALADIN"
end

local function dungeonClassData(classKey)
    classKey = upper(tostring(classKey or ""))
    return DUNGEON_CLASSES[classKey] or DUNGEON_CLASSES.PALADIN, DUNGEON_CLASSES[classKey] and classKey or "PALADIN"
end

local function dungeonArmourStatText(stats)
    stats = type(stats) == "table" and stats or {}
    local parts = {}
    if (stats.maxHP or 0) ~= 0 then parts[#parts + 1] = "+" .. tostring(stats.maxHP) .. " HP" end
    if (stats.attack or 0) ~= 0 then parts[#parts + 1] = "+" .. tostring(stats.attack) .. " ATK" end
    if (stats.extraDice or 0) > 0 then parts[#parts + 1] = "+" .. tostring(stats.extraDice) .. " die" .. ((stats.extraDice or 0) == 1 and "" or "s") end
    if (stats.extraDieChance or 0) > 0 then parts[#parts + 1] = tostring(stats.extraDieChance) .. "% bonus die" end
    if (stats.doubleDamageChance or 0) > 0 then parts[#parts + 1] = tostring(stats.doubleDamageChance) .. "% double" end
    if (stats.bleedChance or 0) > 0 then parts[#parts + 1] = tostring(stats.bleedChance) .. "% bleed " .. tostring(stats.bleedDamage or 1) .. "x" .. tostring(stats.bleedTurns or 1) end
    if (stats.regenTurn or 0) > 0 then parts[#parts + 1] = "+" .. tostring(stats.regenTurn) .. " regen/turn" end
    if (stats.regenRoom or 0) > 0 then parts[#parts + 1] = "+" .. tostring(stats.regenRoom) .. " heal/room" end
    if (stats.flatBlock or 0) > 0 then parts[#parts + 1] = "-" .. tostring(stats.flatBlock) .. " damage" end
    if (stats.blockChance or 0) > 0 then parts[#parts + 1] = tostring(stats.blockChance) .. "% block" end
    if (stats.evadeChance or 0) > 0 then parts[#parts + 1] = tostring(stats.evadeChance) .. "% evade" end
    if (stats.bossDamage or 0) > 0 then parts[#parts + 1] = "+" .. tostring(stats.bossDamage) .. " boss damage" end
    if (stats.minionBonus or 0) > 0 then parts[#parts + 1] = "+" .. tostring(stats.minionBonus) .. " minion" end
    return #parts > 0 and concat(parts, " · ") or "Cosmetic only"
end

local DUNGEON_DICE_ROOT = "Interface\\AddOns\\CreshGames\\Media\\Games\\DungeonDwellers\\Dice\\"
local function dungeonDiceTexture(value)
    if value == "WEB" then return DUNGEON_DICE_ROOT .. "Dice_Web.tga" end
    value = max(1, min(8, floor(tonumber(value) or 1)))
    return DUNGEON_DICE_ROOT .. "Dice_" .. tostring(value) .. ".tga"
end

local function dungeonPlayerKey(classKey)
    local class = dungeonClassData(classKey)
    return class.asset or "HumanPaladin"
end

local function dungeonBossVisualKey(name)
    name = lower(tostring(name or ""))
    if name:find("bone") then return "SkeletonKing" end
    if name:find("doomscale") or name:find("maw") then return "DragonkinBoss" end
    if name:find("grimfang") then return "WolfAlpha" end
    if name:find("sludge") then return "SlimeTyrant" end
    if name:find("cinder") then return "FireMageBoss" end
    if name:find("mordrak") then return "LichLord" end
    if name:find("iron") then return "StoneGolem" end
    if name:find("vexra") then return "SpiderMatriarch" end
    if name:find("null") then return "VoidPriest" end
    return nil
end

local function dungeonEnemyVisual(name, boss, rng)
    local lowered = lower(tostring(name or ""))
    local bodyKey = boss and dungeonBossVisualKey(name) or nil
    local iconKey
    if lowered:find("goblin") then bodyKey, iconKey = bodyKey or "GoblinMechBoss", "Goblin_Raider_01"
    elseif lowered:find("imp") then bodyKey, iconKey = bodyKey or "DemonWarlord", "Imp_Red_01"
    elseif lowered:find("ooze") or lowered:find("slime") then bodyKey, iconKey = bodyKey or "SlimeTyrant", "Slime_Green_01"
    elseif lowered:find("skeleton") or lowered:find("bone") then bodyKey, iconKey = bodyKey or "SkeletonKing", "Skeleton_Armored_02"
    elseif lowered:find("spider") or lowered:find("crawler") or lowered:find("many%-eyed") then bodyKey, iconKey = bodyKey or "SpiderMatriarch", "Spider_Shadow_01"
    elseif lowered:find("wolf") or lowered:find("fang") then bodyKey, iconKey = bodyKey or "WolfAlpha", "Wolf_Grey_01"
    elseif lowered:find("shade") or lowered:find("void") or lowered:find("gloom") or lowered:find("night") then bodyKey, iconKey = bodyKey or "ShadowAssassin", "Cultist_Black_03"
    elseif lowered:find("whelp") or lowered:find("wyrm") then bodyKey, iconKey = bodyKey or "DragonkinBoss", "Demon_Blue_Armored_04"
    elseif lowered:find("marauder") or lowered:find("raider") then bodyKey, iconKey = bodyKey or "OrcChampion", "Goblin_Guard_02"
    elseif lowered:find("rat") then bodyKey, iconKey = bodyKey or "BatLord", "Wolf_Dark_02"
    end
    bodyKey = bodyKey or DUNGEON_BODY_KEYS[(rng and rng:Next(#DUNGEON_BODY_KEYS)) or 1]
    if boss then
        iconKey = bodyKey
        return bodyKey, DUNGEON_BODY_SET[bodyKey], iconKey, DUNGEON_ICON_SET[bodyKey]
    end
    iconKey = iconKey or "Cultist_Red_02"
    return bodyKey, DUNGEON_BODY_SET[bodyKey], iconKey, "03_Minion_Portraits_Core"
end

local function dungeonMinionVisual(kind, rng)
    local variants = DUNGEON_MINION_VARIANTS[kind] or DUNGEON_MINION_VARIANTS.Familiar
    return variants[(rng and rng:Next(#variants)) or 1]
end

local function dungeonHealthBar(parent, width, height, color)
    local colors = palette()
    local bar = CreateFrame("StatusBar", nil, parent, templateName())
    bar:SetSize(width, height)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    color = color or colors.green
    bar:SetStatusBarColor(color[1], color[2], color[3], 1)
    applyBackdrop(bar, darken(colors.panel, 0.01), colors.border)
    bar.text = createText(bar, max(7, height - 3), colors.text, "CENTER")
    bar.text:SetAllPoints()
    return bar
end

local DUNGEON_PREFIXES = { "Ash", "Bone", "Cinder", "Dread", "Ember", "Fang", "Gloom", "Iron", "Mire", "Night", "Rot", "Stone", "Void", "Wyrm" }
local DUNGEON_CREATURES = { "Crawler", "Goblin", "Imp", "Marauder", "Ooze", "Raider", "Rat", "Shade", "Skeleton", "Slime", "Spider", "Whelp", "Wolf" }
local DUNGEON_TITLES = { "the Bent", "the Cracked", "the Hungry", "the Lost", "the Loud", "the Rancid", "the Restless", "the Sneaky", "the Unlucky" }
local DUNGEON_BOSSES = { "The Ashen Maw", "Baron Bonegrind", "Doomscale", "Grimfang the Deep", "King Sludge", "Lady Cinderveil", "Mordrak the Hollow", "The Iron Warden", "Vexra the Many-Eyed", "Warden Null" }
local DUNGEON_MINION_FIRST = { "Biscuit", "Blink", "Bramble", "Cinder", "Clank", "Fidget", "Gizmo", "Moss", "Nib", "Pebble", "Pip", "Rattle", "Rune", "Soot", "Spark", "Twig" }
local DUNGEON_MINION_TYPES = { "Bat", "Beetle", "Familiar", "Imp", "Mimic", "Moth", "Ooze", "Rat", "Sprite", "Wisp" }

local function dungeonNewEnemyDefinition(level, rng)
    local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
    if not content or type(content.GetEnemyPool) ~= "function" or not rng then return nil end
    local chance = min(72, 34 + floor(max(1, tonumber(level) or 1) / 3))
    if rng:Next(100) > chance then return nil end
    local pool = content:GetEnemyPool(level)
    if not pool or #pool == 0 then return nil end
    return pool[rng:Next(#pool)]
end

local function dungeonEnemyName(rng, boss)
    if boss then return DUNGEON_BOSSES[rng:Next(#DUNGEON_BOSSES)] end
    local base = DUNGEON_PREFIXES[rng:Next(#DUNGEON_PREFIXES)] .. " " .. DUNGEON_CREATURES[rng:Next(#DUNGEON_CREATURES)]
    if rng:Next(100) <= 38 then base = base .. " " .. DUNGEON_TITLES[rng:Next(#DUNGEON_TITLES)] end
    return base
end

local function dungeonEnemy(level, index, boss, rng)
    level = floor(max(1, tonumber(level) or 1))
    local tier = floor((level - 1) / 5)
    local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
    local hp, attack
    if content and type(content.GetScaledEnemyStats) == "function" then
        hp, attack = content:GetScaledEnemyStats(level, boss == true, rng)
    else
        hp = 3 + floor((level - 1) / 4) + floor(tier / 2) + rng:Next(3)
        attack = 1 + floor((level - 1) / 10) + (rng:Next(2) - 1)
        if boss then
            hp = hp * 2 + 5 + tier * 2
            attack = attack + 1 + floor(tier / 3)
        end
    end
    local definition
    if boss and content and type(content.GetBossForLevel) == "function" then
        definition = content:GetBossForLevel(level)
    elseif not boss then
        definition = dungeonNewEnemyDefinition(level, rng)
    end
    local name = definition and definition.name or dungeonEnemyName(rng, boss)
    if definition then
        hp = max(1, floor(hp * (tonumber(definition.hpMultiplier) or 1) + 0.5))
        attack = max(1, attack + floor(tonumber(definition.attackBonus) or 0))
    end
    local bodyKey, bodySet, iconKey, iconSet = dungeonEnemyVisual(name, boss, rng)
    local enemy = {
        id = index,
        level = level,
        powerTier = floor((level - 1) / 10) + 1,
        balanceVersion = content and content.enemyBalance and content.enemyBalance.version or 1,
        name = name,
        enemyType = definition and (definition.family or definition.type) or nil,
        contentKey = not boss and definition and definition.key or nil,
        bossKey = boss and definition and definition.key or nil,
        bossLevel = boss and definition and definition.level or nil,
        mechanic = boss and definition and definition.mechanic or nil,
        bossDefinition = boss and definition or nil,
        abilityKey = definition and (definition.abilityKey or definition.mechanic) or nil,
        abilityName = definition and definition.abilityName or nil,
        abilityDescription = definition and definition.abilityDescription or nil,
        abilityImplemented = definition and definition.abilityImplemented == true or false,
        hp = max(1, hp),
        maxHP = max(1, hp),
        attack = max(1, attack),
        baseAttack = max(1, attack),
        boss = boss == true,
        alive = true,
        lastRoll = 0,
        turn = 0,
        bodyPath = definition and definition.fullBody or nil,
        iconPath = definition and definition.icon or nil,
        bodyKey = bodyKey,
        bodySet = bodySet,
        iconKey = iconKey,
        iconSet = iconSet,
    }
    if enemy.mechanic == "CANDLE" then enemy.candleLit = true end
    if enemy.mechanic == "BARK" then enemy.armourLayers = 3 end
    if enemy.mechanic == "MODES" then enemy.mode = "ARMOUR" end
    if enemy.mechanic == "RAGE" then enemy.rageStage = 0 end
    return enemy
end

local function dungeonMinion(room, rng)
    room = floor(max(1, tonumber(room) or 1))
    local level = max(1, floor(room / 12) + rng:Next(2))
    local power = max(1, 1 + floor(room / 15) + rng:Next(3) - 1)
    local kind = DUNGEON_MINION_TYPES[rng:Next(#DUNGEON_MINION_TYPES)]
    return {
        name = DUNGEON_MINION_FIRST[rng:Next(#DUNGEON_MINION_FIRST)] .. " the " .. kind,
        kind = kind,
        assetKey = dungeonMinionVisual(kind, rng),
        level = level,
        power = power,
    }
end

function Solo:BuildDUNGEONView()
    if self.views.DUNGEON then return self.views.DUNGEON end
    local frame = self:BuildWindow()
    local colors = palette()
    local view = {
        game = "DUNGEON", enemies = {}, minions = {}, targetIndex = 1,
        room = 1, kills = 0, score = 0, upgradePoints = 0,
        pendingUpgrade = false, roomCleared = false, dead = false,
        pendingCrates = {}, activeCrate = nil, crateChoices = nil, crateRevealed = false,
    }
    view.frame = CreateFrame("Frame", nil, frame.content, templateName())
    view.frame:SetAllPoints()
    applyBackdrop(view.frame, colors.panelSoft, colors.panelSoft)
    view.frame:Hide()

    view.breathActors = {}
    function view:RegisterBreath(actorFrame, point, relativeTo, relativePoint, x, y, amplitude, speed, phase)
        self.breathActors[#self.breathActors + 1] = {
            frame = actorFrame, point = point, relativeTo = relativeTo, relativePoint = relativePoint,
            x = x or 0, y = y or 0, amplitude = amplitude or 1.5,
            speed = speed or 1.0, phase = phase or 0,
        }
        actorFrame:ClearAllPoints()
        actorFrame:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
    end

    view.depthBanner = cardFrame(view.frame, 722, 58)
    view.depthBanner:SetPoint("TOPLEFT", view.frame, "TOPLEFT", 12, -12)
    applyBackdrop(view.depthBanner, darken(colors.accent, 0.30), colors.accent)
    view.dwellersButton = createButton(view.depthBanner, "DWELLERS", 102, 23, function() view:ShowDwellersPanel("COLLECTION") end)
    view.dwellersButton:SetPoint("TOPLEFT", view.depthBanner, "TOPLEFT", 8, -6)
    setButtonAccent(view.dwellersButton, colors.accent)
    view.depthLabel = createText(view.depthBanner, 12, colors.text, "LEFT")
    view.depthLabel:SetPoint("TOPLEFT", view.depthBanner, "TOPLEFT", 120, -8)
    view.roomTitle = createText(view.depthBanner, 16, colors.gold, "CENTER")
    view.roomTitle:SetPoint("TOP", view.depthBanner, "TOP", 0, -7)
    view.scoreLabel = createText(view.depthBanner, 11, colors.text, "RIGHT")
    view.scoreLabel:SetPoint("TOPRIGHT", view.depthBanner, "TOPRIGHT", -12, -9)
    view.roomText = createText(view.depthBanner, 9, colors.muted, "CENTER")
    view.roomText:SetPoint("TOPLEFT", view.depthBanner, "TOPLEFT", 130, -29)
    view.roomText:SetPoint("TOPRIGHT", view.depthBanner, "TOPRIGHT", -130, -29)
    view.depthBar = dungeonHealthBar(view.depthBanner, 696, 8, colors.gold)
    view.depthBar:SetPoint("BOTTOM", view.depthBanner, "BOTTOM", 0, 7)

    view.stage = cardFrame(view.frame, 722, 382)
    view.stage:SetPoint("TOPLEFT", view.depthBanner, "BOTTOMLEFT", 0, -8)
    applyBackdrop(view.stage, darken(colors.panelSoft, 0.015), colors.border)

    view.heroPanel = cardFrame(view.stage, 238, 366)
    view.heroPanel:SetPoint("TOPLEFT", view.stage, "TOPLEFT", 8, -8)
    applyBackdrop(view.heroPanel, darken(colors.green, 0.56), darken(colors.green, 0.10))
    view.heroIconFrame = cardFrame(view.heroPanel, 54, 54)
    view.heroIconFrame:SetPoint("TOPLEFT", view.heroPanel, "TOPLEFT", 8, -8)
    view.heroIcon = dungeonCreateOpaqueTexture(view.heroIconFrame, 1)
    view.heroIcon:ClearAllPoints()
    view.heroIcon:SetPoint("TOPLEFT", view.heroIconFrame, "TOPLEFT", 2, -2)
    view.heroIcon:SetPoint("BOTTOMRIGHT", view.heroIconFrame, "BOTTOMRIGHT", -2, 2)
    for _, layer in ipairs(view.heroIcon.creshOpacityLayers or {}) do
        layer:ClearAllPoints(); layer:SetPoint("TOPLEFT", view.heroIconFrame, "TOPLEFT", 2, -2); layer:SetPoint("BOTTOMRIGHT", view.heroIconFrame, "BOTTOMRIGHT", -2, 2)
    end
    view.heroName = createText(view.heroPanel, 11, colors.text, "LEFT")
    view.heroName:SetPoint("TOPLEFT", view.heroPanel, "TOPLEFT", 70, -10)
    view.heroName:SetPoint("RIGHT", view.heroPanel, "RIGHT", -8, 0)
    view.heroTier = createText(view.heroPanel, 8, colors.muted, "LEFT")
    view.heroTier:SetPoint("TOPLEFT", view.heroName, "BOTTOMLEFT", 0, -2)
    view.heroTier:SetPoint("RIGHT", view.heroPanel, "RIGHT", -8, 0)
    view.heroTier:SetHeight(12)
    view.heroTier:SetWordWrap(false)
    view.heroHP = dungeonHealthBar(view.heroPanel, 158, 13, colors.green)
    view.heroHP:SetPoint("TOPLEFT", view.heroPanel, "TOPLEFT", 70, -42)
    view.classButton = createButton(view.heroPanel, "CLASS", 58, 24, function() view:ShowClassPicker() end)
    view.classButton:SetPoint("TOPLEFT", view.heroPanel, "TOPLEFT", 8, -68)
    setButtonAccent(view.classButton, colors.accent)
    view.armourButton = createButton(view.heroPanel, "ARMOUR", 158, 24, function() view:ShowArmourPicker() end)
    view.armourButton:SetPoint("TOPLEFT", view.heroPanel, "TOPLEFT", 72, -68)
    setButtonAccent(view.armourButton, colors.gold)

    view.heroBodyPlate = cardFrame(view.heroPanel, 116, 166)
    view.heroBodyPlate:SetPoint("BOTTOM", view.heroPanel, "BOTTOM", 0, 94)
    applyBackdrop(view.heroBodyPlate, {0.018, 0.024, 0.028, 1}, darken(colors.green, 0.18))
    view.heroBodyHolder = CreateFrame("Frame", nil, view.heroBodyPlate)
    view.heroBodyHolder:SetSize(110, 160)
    view.heroBody = dungeonCreateOpaqueTexture(view.heroBodyHolder, 2)
    view:RegisterBreath(view.heroBodyHolder, "CENTER", view.heroBodyPlate, "CENTER", 0, 0, 2.1, 1.05, 0)

    view.heroStats = createText(view.heroPanel, 9, colors.text, "CENTER")
    view.heroStats:SetPoint("BOTTOMLEFT", view.heroPanel, "BOTTOMLEFT", 8, 70)
    view.heroStats:SetPoint("BOTTOMRIGHT", view.heroPanel, "BOTTOMRIGHT", -8, 70)
    view.heroStats:SetHeight(18)

    view.minionCards = {}
    for i = 1, 2 do
        local card = cardFrame(view.heroPanel, 106, 58)
        card:SetPoint("BOTTOMLEFT", view.heroPanel, "BOTTOMLEFT", 8 + (i - 1) * 116, 7)
        card.iconHolder = CreateFrame("Frame", nil, card)
        card.iconHolder:SetSize(43, 43)
        card.icon = dungeonCreateOpaqueTexture(card.iconHolder, 1)
        view:RegisterBreath(card.iconHolder, "LEFT", card, "LEFT", 5, 0, 1.0, 1.35 + i * 0.08, i * 0.9)
        card.name = createText(card, 8, colors.text, "LEFT")
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 52, -7)
        card.name:SetPoint("RIGHT", card, "RIGHT", -4, 0)
        card.stats = createText(card, 8, colors.muted, "LEFT")
        card.stats:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -3)
        card.stats:SetPoint("RIGHT", card, "RIGHT", -4, 0)
        view.minionCards[i] = card
    end

    view.actionPanel = cardFrame(view.stage, 210, 366)
    view.actionPanel:SetPoint("TOP", view.stage, "TOP", 0, -8)
    applyBackdrop(view.actionPanel, colors.panel, colors.border)
    view.actionRoom = createText(view.actionPanel, 18, colors.gold, "CENTER")
    view.actionRoom:SetPoint("TOPLEFT", view.actionPanel, "TOPLEFT", 8, -10)
    view.actionRoom:SetPoint("TOPRIGHT", view.actionPanel, "TOPRIGHT", -8, -10)
    view.actionStatus = createText(view.actionPanel, 9, colors.muted, "CENTER")
    view.actionStatus:SetPoint("TOPLEFT", view.actionRoom, "BOTTOMLEFT", 0, -4)
    view.actionStatus:SetPoint("TOPRIGHT", view.actionRoom, "BOTTOMRIGHT", 0, -4)
    view.actionStatus:SetHeight(32)
    view.actionStatus:SetWordWrap(true)

    view.diceCard = cardFrame(view.actionPanel, 190, 100)
    view.diceCard:SetPoint("TOP", view.actionPanel, "TOP", 0, -72)
    applyBackdrop(view.diceCard, darken(colors.accent, 0.42), colors.accent)
    view.diceTitle = createText(view.diceCard, 8, colors.muted, "CENTER")
    view.diceTitle:SetPoint("TOPLEFT", view.diceCard, "TOPLEFT", 6, -5)
    view.diceTitle:SetPoint("TOPRIGHT", view.diceCard, "TOPRIGHT", -6, -5)
    view.diceTitle:SetText("ATTACK DICE · PARTY + FOE")
    view.diceIcons = {}
    for dieIndex = 1, 4 do
        local die = CreateFrame("Frame", nil, view.diceCard, templateName())
        die:SetSize(32, 32)
        die.baseX, die.baseY = 12 + (dieIndex - 1) * 38, -30
        die:SetPoint("TOPLEFT", view.diceCard, "TOPLEFT", die.baseX, die.baseY)
        applyBackdrop(die, {0.018, 0.024, 0.032, 0.96}, darken(colors.accent, 0.04))
        die.texture = die:CreateTexture(nil, "ARTWORK")
        die.texture:SetPoint("TOPLEFT", die, "TOPLEFT", 2, -2)
        die.texture:SetPoint("BOTTOMRIGHT", die, "BOTTOMRIGHT", -2, 2)
        die.texture:SetTexture(dungeonDiceTexture(1))
        die:Hide()
        view.diceIcons[dieIndex] = die
    end
    view.enemyDie = CreateFrame("Frame", nil, view.diceCard, templateName())
    view.enemyDie:SetSize(32, 32)
    view.enemyDie.baseX, view.enemyDie.baseY = 150, -30
    view.enemyDie:SetPoint("TOPLEFT", view.diceCard, "TOPLEFT", view.enemyDie.baseX, view.enemyDie.baseY)
    applyBackdrop(view.enemyDie, {0.036, 0.018, 0.020, 0.96}, colors.red)
    view.enemyDie.texture = view.enemyDie:CreateTexture(nil, "ARTWORK")
    view.enemyDie.texture:SetPoint("TOPLEFT", view.enemyDie, "TOPLEFT", 2, -2)
    view.enemyDie.texture:SetPoint("BOTTOMRIGHT", view.enemyDie, "BOTTOMRIGHT", -2, 2)
    view.enemyDie.texture:SetTexture(dungeonDiceTexture(1))
    view.enemyDie.texture:SetVertexColor(1.00, 0.82, 0.82, 1)
    view.enemyDie:Hide()
    view.enemyDieLabel = createText(view.diceCard, 7, colors.red, "CENTER")
    view.enemyDieLabel:SetText("FOE")
    view.enemyDieLabel:Hide()
    view.diceText = createText(view.diceCard, 8, colors.text, "CENTER")
    view.diceText:SetPoint("BOTTOMLEFT", view.diceCard, "BOTTOMLEFT", 5, 9)
    view.diceText:SetPoint("BOTTOMRIGHT", view.diceCard, "BOTTOMRIGHT", -5, 9)
    view.diceText:SetHeight(12)
    view.diceDetail = createText(view.diceCard, 7, colors.muted, "CENTER")
    view.diceDetail:SetPoint("BOTTOMLEFT", view.diceCard, "BOTTOMLEFT", 5, 1)
    view.diceDetail:SetPoint("BOTTOMRIGHT", view.diceCard, "BOTTOMRIGHT", -5, 1)
    view.diceDetail:SetHeight(1)
    view.diceDetail:Hide()

    view.attackButton = createButton(view.actionPanel, "ROLL ATTACK", 178, 38, function() view:PlayerAttack() end)
    view.attackButton:SetPoint("TOP", view.actionPanel, "TOP", 0, -180)
    setButtonAccent(view.attackButton, colors.red)
    view.attackButton:Show()
    view.healthButton = createButton(view.actionPanel, "+ HEALTH", 178, 34, function() view:ChooseUpgrade("HEALTH") end)
    view.healthButton:SetPoint("TOP", view.actionPanel, "TOP", 0, -222)
    setButtonAccent(view.healthButton, colors.green)
    view.attackUpgradeButton = createButton(view.actionPanel, "+ ATTACK", 178, 34, function() view:ChooseUpgrade("ATTACK") end)
    view.attackUpgradeButton:SetPoint("TOP", view.actionPanel, "TOP", 0, -260)
    setButtonAccent(view.attackUpgradeButton, colors.gold)
    view.minionButton = createButton(view.actionPanel, "MINION", 178, 34, function() view:ChooseUpgrade("MINION") end)
    view.minionButton:SetPoint("TOP", view.actionPanel, "TOP", 0, -298)
    setButtonAccent(view.minionButton, colors.accent)
    view.nextButton = createButton(view.actionPanel, "DESCEND", 178, 38, function() view:NextRoom() end)
    view.nextButton:SetPoint("BOTTOM", view.actionPanel, "BOTTOM", 0, 38)
    setButtonAccent(view.nextButton, colors.accent)
    view.newRunButton = createButton(view.actionPanel, "NEW RUN", 178, 38, function() view:StartRun() end)
    view.newRunButton:SetPoint("BOTTOM", view.actionPanel, "BOTTOM", 0, 38)
    setButtonAccent(view.newRunButton, colors.red)
    view.actionHint = createText(view.actionPanel, 8, colors.muted, "CENTER")
    view.actionHint:SetPoint("BOTTOMLEFT", view.actionPanel, "BOTTOMLEFT", 8, 8)
    view.actionHint:SetPoint("BOTTOMRIGHT", view.actionPanel, "BOTTOMRIGHT", -8, 8)
    view.actionHint:SetHeight(23)
    view.actionHint:SetWordWrap(true)

    view.enemyPanel = cardFrame(view.stage, 238, 366)
    view.enemyPanel:SetPoint("TOPRIGHT", view.stage, "TOPRIGHT", -8, -8)
    applyBackdrop(view.enemyPanel, darken(colors.red, 0.62), darken(colors.red, 0.10))
    view.enemyIconFrame = cardFrame(view.enemyPanel, 54, 54)
    view.enemyIconFrame:SetPoint("TOPRIGHT", view.enemyPanel, "TOPRIGHT", -8, -8)
    view.enemyIcon = dungeonCreateOpaqueTexture(view.enemyIconFrame, 1)
    view.enemyIcon:ClearAllPoints()
    view.enemyIcon:SetPoint("TOPLEFT", view.enemyIconFrame, "TOPLEFT", 2, -2)
    view.enemyIcon:SetPoint("BOTTOMRIGHT", view.enemyIconFrame, "BOTTOMRIGHT", -2, 2)
    for _, layer in ipairs(view.enemyIcon.creshOpacityLayers or {}) do
        layer:ClearAllPoints(); layer:SetPoint("TOPLEFT", view.enemyIconFrame, "TOPLEFT", 2, -2); layer:SetPoint("BOTTOMRIGHT", view.enemyIconFrame, "BOTTOMRIGHT", -2, 2)
    end
    view.enemyName = createText(view.enemyPanel, 11, colors.text, "RIGHT")
    view.enemyName:SetPoint("TOPLEFT", view.enemyPanel, "TOPLEFT", 8, -10)
    view.enemyName:SetPoint("RIGHT", view.enemyPanel, "RIGHT", -70, 0)
    view.enemyTier = createText(view.enemyPanel, 8, colors.muted, "RIGHT")
    view.enemyTier:SetPoint("TOPLEFT", view.enemyName, "BOTTOMLEFT", 0, -2)
    view.enemyTier:SetPoint("RIGHT", view.enemyPanel, "RIGHT", -70, 0)
    view.enemyHP = dungeonHealthBar(view.enemyPanel, 158, 13, colors.red)
    view.enemyHP:SetPoint("TOPRIGHT", view.enemyPanel, "TOPRIGHT", -70, -42)

    view.enemyBodyPlate = cardFrame(view.enemyPanel, 116, 202)
    view.enemyBodyPlate:SetPoint("BOTTOM", view.enemyPanel, "BOTTOM", 0, 94)
    applyBackdrop(view.enemyBodyPlate, {0.028, 0.016, 0.018, 1}, darken(colors.red, 0.16))
    view.enemyBodyHolder = CreateFrame("Frame", nil, view.enemyBodyPlate)
    view.enemyBodyHolder:SetSize(110, 196)
    view.enemyBody = dungeonCreateOpaqueTexture(view.enemyBodyHolder, 2)
    view:RegisterBreath(view.enemyBodyHolder, "CENTER", view.enemyBodyPlate, "CENTER", 0, 0, 2.5, 0.92, 1.7)

    view.enemyStats = createText(view.enemyPanel, 9, colors.text, "CENTER")
    view.enemyStats:SetPoint("BOTTOMLEFT", view.enemyPanel, "BOTTOMLEFT", 8, 70)
    view.enemyStats:SetPoint("BOTTOMRIGHT", view.enemyPanel, "BOTTOMRIGHT", -8, 70)
    view.enemyStats:SetHeight(18)

    view.enemySelectors = {}
    for i = 1, 3 do
        local card = CreateFrame("Button", nil, view.enemyPanel, templateName())
        card:SetSize(68, 58)
        card:SetPoint("BOTTOMLEFT", view.enemyPanel, "BOTTOMLEFT", 8 + (i - 1) * 77, 7)
        applyBackdrop(card, colors.panel, colors.border)
        card.iconHolder = CreateFrame("Frame", nil, card)
        card.iconHolder:SetSize(38, 38)
        card.iconHolder:SetPoint("TOP", card, "TOP", 0, -3)
        card.icon = dungeonCreateOpaqueTexture(card.iconHolder, 1)
        card.hp = dungeonHealthBar(card, 60, 8, colors.red)
        card.hp:SetPoint("BOTTOM", card, "BOTTOM", 0, 4)
        local index = i
        card:SetScript("OnClick", function()
            if view.enemies[index] and view.enemies[index].alive and not view.pendingUpgrade and not view.dead then
                view.targetIndex = index
                view:Refresh()
            end
        end)
        view.enemySelectors[i] = card
    end

    view.logCard = cardFrame(view.frame, 722, 96)
    view.logCard:SetPoint("TOPLEFT", view.stage, "BOTTOMLEFT", 0, -8)
    view.logTitle = createText(view.logCard, 9, colors.accent, "LEFT")
    view.logTitle:SetPoint("TOPLEFT", view.logCard, "TOPLEFT", 10, -7)
    view.logTitle:SetText("COMBAT FEED")
    view.log = createText(view.logCard, 9, colors.muted, "LEFT")
    view.log:SetPoint("TOPLEFT", view.logTitle, "BOTTOMLEFT", 0, -5)
    view.log:SetPoint("BOTTOMRIGHT", view.logCard, "BOTTOMRIGHT", -10, 7)
    view.log:SetJustifyV("TOP")
    view.log:SetWordWrap(true)

    if view.classButton and view.classButton.HookScript then
        view.classButton:HookScript("OnEnter", function(selfButton)
            local class = view:GetClassData()
            if _G.GameTooltip then
                GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Change Dungeon Class", 1, 0.82, 0.25)
                GameTooltip:AddLine(class.name .. " · " .. class.short, 0.75, 0.84, 1, true)
                GameTooltip:AddLine("Strength: " .. class.strength, 0.35, 0.95, 0.55, true)
                GameTooltip:AddLine("Weakness: " .. class.weakness, 1, 0.42, 0.35, true)
                GameTooltip:AddLine("Changing class begins a new run.", 0.65, 0.70, 0.78, true)
                GameTooltip:Show()
            end
        end)
        view.classButton:HookScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    end
    if view.armourButton and view.armourButton.HookScript then
        view.armourButton:HookScript("OnEnter", function(selfButton)
            local armour = view:GetEquippedArmour()
            if _G.GameTooltip then
                GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
                GameTooltip:AddLine(armour and armour.name or "Dungeon Armour", 1, 0.82, 0.25)
                GameTooltip:AddLine(armour and dungeonArmourStatText(armour.stats) or "No armour is equipped.", 0.35, 0.95, 0.55, true)
                GameTooltip:AddLine("Click to view, compare and equip unlocked armour skins.", 0.70, 0.78, 0.90, true)
                GameTooltip:Show()
            end
        end)
        view.armourButton:HookScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
    end

    view.classPicker = cardFrame(view.frame, 560, 322)
    view.classPicker:SetPoint("CENTER", view.frame, "CENTER", 0, 0)
    view.classPicker:SetFrameLevel((view.stage:GetFrameLevel() or 1) + 30)
    view.classPicker:EnableMouse(true)
    applyBackdrop(view.classPicker, {0.018, 0.022, 0.030, 1}, colors.accent)
    view.classPicker:Hide()
    view.classPickerTitle = createText(view.classPicker, 16, colors.gold, "LEFT")
    view.classPickerTitle:SetPoint("TOPLEFT", view.classPicker, "TOPLEFT", 14, -10)
    view.classPickerTitle:SetText("CHOOSE YOUR DUNGEON CLASS")
    view.classPickerHint = createText(view.classPicker, 8, colors.muted, "LEFT")
    view.classPickerHint:SetPoint("TOPLEFT", view.classPickerTitle, "BOTTOMLEFT", 0, -3)
    view.classPickerHint:SetText("Changing class starts a fresh run. Each class has different base stats, upgrades, perks and weaknesses.")
    view.classPickerClose = createButton(view.classPicker, "X", 28, 25, function() view.classPicker:Hide() end)
    view.classPickerClose:SetPoint("TOPRIGHT", view.classPicker, "TOPRIGHT", -8, -8)
    view.classCards = {}
    for index, classKey in ipairs(DUNGEON_CLASS_ORDER) do
        local class = DUNGEON_CLASSES[classKey]
        local selectedKey, selectedClass = classKey, class
        local column = (index - 1) % 2
        local rowIndex = floor((index - 1) / 2)
        local card = CreateFrame("Button", nil, view.classPicker, templateName())
        card:SetSize(262, 58)
        card:SetPoint("TOPLEFT", view.classPicker, "TOPLEFT", 12 + column * 274, -57 - rowIndex * 63)
        applyBackdrop(card, colors.panel, colors.border)
        card.classKey = classKey
        card.iconFrame = cardFrame(card, 46, 46)
        card.iconFrame:SetPoint("LEFT", card, "LEFT", 6, 0)
        card.icon = dungeonCreateOpaqueTexture(card.iconFrame, 1)
        dungeonSetTexture(card.icon, dungeonTexture("01_Player_Portraits_Classic", class.asset))
        card.name = createText(card, 10, colors.text, "LEFT")
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 59, -6)
        card.name:SetText(upper(class.name))
        card.stats = createText(card, 8, colors.gold, "LEFT")
        card.stats:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -2)
        card.stats:SetText(format("HP %d · ATK %d · D%d", class.baseHP, class.baseAttack, class.attackDie or 6))
        card.trait = createText(card, 7, colors.muted, "LEFT")
        card.trait:SetPoint("TOPLEFT", card.stats, "BOTTOMLEFT", 0, -2)
        card.trait:SetPoint("RIGHT", card, "RIGHT", -5, 0)
        card.trait:SetText(class.short)
        card:SetScript("OnClick", function() view:SetClass(selectedKey, true) end)
        card:SetScript("OnEnter", function(selfCard)
            applyBackdrop(selfCard, darken(colors.accent, 0.28), colors.accent)
            if _G.GameTooltip then
                GameTooltip:SetOwner(selfCard, "ANCHOR_RIGHT")
                GameTooltip:AddLine(selectedClass.name, 1, 0.82, 0.25)
                GameTooltip:AddLine("Strength: " .. selectedClass.strength, 0.35, 0.95, 0.55, true)
                GameTooltip:AddLine("Weakness: " .. selectedClass.weakness, 1, 0.42, 0.35, true)
                GameTooltip:Show()
            end
        end)
        card:SetScript("OnLeave", function(selfCard)
            view:RefreshClassPicker()
            if _G.GameTooltip then GameTooltip:Hide() end
        end)
        view.classCards[classKey] = card
    end

    view.armourPicker = cardFrame(view.frame, 620, 400)
    view.armourPicker:SetPoint("CENTER", view.frame, "CENTER", 0, 0)
    view.armourPicker:SetFrameLevel((view.stage:GetFrameLevel() or 1) + 31)
    view.armourPicker:EnableMouse(true)
    applyBackdrop(view.armourPicker, {0.018, 0.022, 0.030, 1}, colors.gold)
    view.armourPicker:Hide()
    view.armourPickerTitle = createText(view.armourPicker, 16, colors.gold, "LEFT")
    view.armourPickerTitle:SetPoint("TOPLEFT", view.armourPicker, "TOPLEFT", 14, -10)
    view.armourPickerTitle:SetPoint("RIGHT", view.armourPicker, "RIGHT", -52, 0)
    view.armourPickerTitle:SetText("DUNGEON ARMOUR LOADOUT")
    view.armourPickerHint = createText(view.armourPicker, 8, colors.muted, "LEFT")
    view.armourPickerHint:SetPoint("TOPLEFT", view.armourPickerTitle, "BOTTOMLEFT", 0, -3)
    view.armourPickerHint:SetPoint("RIGHT", view.armourPicker, "RIGHT", -52, 0)
    view.armourPickerHint:SetHeight(28)
    view.armourPickerHint:SetWordWrap(true)
    view.armourPickerHint:SetText("Each skin has unique combat stats. Equipping or removing armour begins a fresh run.")
    view.armourPickerClose = createButton(view.armourPicker, "X", 28, 25, function() view.armourPicker:Hide() end)
    view.armourPickerClose:SetPoint("TOPRIGHT", view.armourPicker, "TOPRIGHT", -8, -8)
    view.armourCards = {}
    for index = 1, 5 do
        local card = CreateFrame("Button", nil, view.armourPicker, templateName())
        card:SetSize(590, 57)
        card:SetPoint("TOPLEFT", view.armourPicker, "TOPLEFT", 14, -55 - (index - 1) * 61)
        applyBackdrop(card, colors.panel, colors.border)
        card.iconFrame = cardFrame(card, 45, 45)
        card.iconFrame:SetPoint("LEFT", card, "LEFT", 6, 0)
        card.icon = dungeonCreateOpaqueTexture(card.iconFrame, 1)
        card.name = createText(card, 10, colors.text, "LEFT")
        card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 59, -6)
        card.name:SetPoint("RIGHT", card, "RIGHT", -112, 0)
        card.stats = createText(card, 8, colors.gold, "LEFT")
        card.stats:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -3)
        card.stats:SetPoint("RIGHT", card, "RIGHT", -124, 0)
        card.stats:SetHeight(22)
        card.stats:SetWordWrap(true)
        card.state = createText(card, 9, colors.muted, "RIGHT")
        card.state:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        card.state:SetWidth(108)
        card:SetScript("OnClick", function(selfCard)
            local set = selfCard.armourSet
            if not set then return end
            if selfCard.armourUnlocked then
                view:SetArmour(set.key, true)
            else
                view.armourPickerHint:SetText("LOCKED: defeat milestone bosses and open higher-quality crates to unlock " .. set.name .. ".")
            end
        end)
        card:SetScript("OnEnter", function(selfCard)
            local set = selfCard.armourSet
            if not set or not _G.GameTooltip then return end
            GameTooltip:SetOwner(selfCard, "ANCHOR_RIGHT")
            GameTooltip:AddLine(set.name, 1, 0.82, 0.25)
            GameTooltip:AddLine("Tier " .. tostring(set.tier or index) .. " · Level " .. tostring(set.unlockLevel or 0) .. " reward pool", 0.72, 0.78, 0.88)
            GameTooltip:AddLine(dungeonArmourStatText(set.stats), 0.35, 0.95, 0.55, true)
            GameTooltip:AddLine(selfCard.armourUnlocked and "Click to equip and start a fresh run." or "Locked: earn from bosses, armour rolls or shards.", selfCard.armourUnlocked and 0.75 or 1, selfCard.armourUnlocked and 0.86 or 0.45, selfCard.armourUnlocked and 1 or 0.35, true)
            GameTooltip:Show()
        end)
        card:SetScript("OnLeave", function() if _G.GameTooltip then GameTooltip:Hide() end end)
        view.armourCards[index] = card
    end
    view.armourUnequip = createButton(view.armourPicker, "NO ARMOUR · START FRESH", 220, 28, function() view:SetArmour(nil, true) end)
    view.armourUnequip:SetPoint("BOTTOMLEFT", view.armourPicker, "BOTTOMLEFT", 14, 12)
    setButtonAccent(view.armourUnequip, colors.muted)
    view.armourCollection = createText(view.armourPicker, 9, colors.muted, "RIGHT")
    view.armourCollection:SetPoint("BOTTOMRIGHT", view.armourPicker, "BOTTOMRIGHT", -14, 19)

    -- Unified Dungeon Dwellers archive. Collection, lifetime statistics and the
    -- dedicated activity Battle Pass share one overlay so the combat board stays compact.
    view.dwellersPanel = cardFrame(view.frame, 680, 470)
    view.dwellersPanel:SetPoint("CENTER", view.frame, "CENTER", 0, 0)
    view.dwellersPanel:SetFrameLevel((view.stage:GetFrameLevel() or 1) + 40)
    view.dwellersPanel:EnableMouse(true)
    view.dwellersPanel:EnableMouseWheel(true)
    applyBackdrop(view.dwellersPanel, {0.014, 0.019, 0.027, 1}, colors.accent)
    view.dwellersPanel:Hide()
    view.dwellersMode = "COLLECTION"
    view.collectionType = "ALL"
    view.collectionState = "ALL"
    view.collectionClass = "ALL"
    view.collectionOffset = 0
    view.passOffset = 0

    view.dwellersTitle = createText(view.dwellersPanel, 16, colors.gold, "LEFT")
    view.dwellersTitle:SetPoint("TOPLEFT", view.dwellersPanel, "TOPLEFT", 14, -10)
    view.dwellersTitle:SetText("DUNGEON DWELLERS")
    view.dwellersClose = createButton(view.dwellersPanel, "X", 28, 25, function() view.dwellersPanel:Hide() end)
    view.dwellersClose:SetPoint("TOPRIGHT", view.dwellersPanel, "TOPRIGHT", -8, -8)

    view.dwellersTabs = {}
    local dwellersTabInfo = {
        { key = "COLLECTION", label = "COLLECTION" },
        { key = "STATS", label = "STATS" },
        { key = "PASS", label = "DWELLER PASS" },
    }
    for index, info in ipairs(dwellersTabInfo) do
        local tabKey, tabLabel = info.key, info.label
        local tab = createButton(view.dwellersPanel, tabLabel, index == 3 and 126 or 104, 25, function() view:SetDwellersMode(tabKey) end)
        tab:SetPoint("TOPLEFT", view.dwellersPanel, "TOPLEFT", 184 + (index - 1) * 116, -9)
        tab.dwellersKey = tabKey
        view.dwellersTabs[tabKey] = tab
    end

    view.collectionControls = CreateFrame("Frame", nil, view.dwellersPanel)
    view.collectionControls:SetPoint("TOPLEFT", view.dwellersPanel, "TOPLEFT", 12, -44)
    view.collectionControls:SetPoint("TOPRIGHT", view.dwellersPanel, "TOPRIGHT", -12, -44)
    view.collectionControls:SetHeight(48)

    view.collectionTypeButtons = {}
    local collectionTypes = {
        {"ALL", "ALL"}, {"MINION", "MINIONS"}, {"CLASS", "CLASSES"},
        {"ARMOUR", "ARMOUR"}, {"ITEM", "ITEMS"},
    }
    for index, info in ipairs(collectionTypes) do
        local filterKey, filterLabel = info[1], info[2]
        local button = createButton(view.collectionControls, filterLabel, index == 2 and 78 or 68, 22, function()
            view.collectionType = filterKey
            view.collectionOffset = 0
            view:RefreshDwellersPanel()
        end)
        button:SetPoint("TOPLEFT", view.collectionControls, "TOPLEFT", (index - 1) * 74, 0)
        button.filterKey = filterKey
        view.collectionTypeButtons[filterKey] = button
    end

    view.collectionStateButtons = {}
    local collectionStates = {{"ALL", "ALL"}, {"UNLOCKED", "UNLOCKED"}, {"LOCKED", "LOCKED"}}
    for index, info in ipairs(collectionStates) do
        local filterKey, filterLabel = info[1], info[2]
        local button = createButton(view.collectionControls, filterLabel, index == 1 and 62 or 82, 22, function()
            view.collectionState = filterKey
            view.collectionOffset = 0
            view:RefreshDwellersPanel()
        end)
        button:SetPoint("BOTTOMLEFT", view.collectionControls, "BOTTOMLEFT", (index - 1) * 88, 0)
        button.filterKey = filterKey
        view.collectionStateButtons[filterKey] = button
    end

    view.collectionClassButton = createButton(view.collectionControls, "CLASS: ALL", 164, 22, function()
        view:CycleCollectionClass(1)
    end)
    view.collectionClassButton:SetPoint("BOTTOMRIGHT", view.collectionControls, "BOTTOMRIGHT", 0, 0)
    setButtonAccent(view.collectionClassButton, colors.gold)

    view.collectionRows = {}
    for index = 1, 6 do
        local row = CreateFrame("Button", nil, view.dwellersPanel, templateName())
        row:SetSize(650, 54)
        row:SetPoint("TOPLEFT", view.dwellersPanel, "TOPLEFT", 14, -100 - (index - 1) * 57)
        applyBackdrop(row, colors.panel, colors.border)
        row.iconFrame = cardFrame(row, 42, 42)
        row.iconFrame:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.icon = dungeonCreateOpaqueTexture(row.iconFrame, 1)
        row.category = createText(row, 7, colors.accent, "LEFT")
        row.category:SetPoint("TOPLEFT", row, "TOPLEFT", 57, -6)
        row.name = createText(row, 10, colors.text, "LEFT")
        row.name:SetPoint("TOPLEFT", row.category, "BOTTOMLEFT", 0, -1)
        row.name:SetPoint("RIGHT", row, "RIGHT", -126, 0)
        row.detail = createText(row, 8, colors.muted, "LEFT")
        row.detail:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
        row.detail:SetPoint("RIGHT", row, "RIGHT", -126, 0)
        row.detail:SetHeight(14)
        row.state = createText(row, 9, colors.muted, "RIGHT")
        row.state:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.state:SetWidth(110)
        row:SetScript("OnEnter", function(selfRow)
            if not selfRow.entry or not _G.GameTooltip then return end
            applyBackdrop(selfRow, darken(colors.accent, 0.30), colors.accent)
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:AddLine(selfRow.entry.name or "Dungeon collection", 1, 0.82, 0.25)
            if selfRow.entry.detail then GameTooltip:AddLine(selfRow.entry.detail, 0.72, 0.80, 0.92, true) end
            GameTooltip:AddLine(selfRow.entry.unlocked and "Unlocked" or "Locked", selfRow.entry.unlocked and 0.35 or 1, selfRow.entry.unlocked and 0.95 or 0.42, selfRow.entry.unlocked and 0.55 or 0.35)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(selfRow)
            if selfRow.entry then
                applyBackdrop(selfRow, selfRow.entry.unlocked and colors.panel or darken(colors.panel, 0.04), selfRow.entry.unlocked and colors.border or darken(colors.border, 0.20))
            end
            if _G.GameTooltip then GameTooltip:Hide() end
        end)
        view.collectionRows[index] = row
    end
    view.collectionFooter = createText(view.dwellersPanel, 8, colors.muted, "LEFT")
    view.collectionFooter:SetPoint("BOTTOMLEFT", view.dwellersPanel, "BOTTOMLEFT", 16, 12)
    view.collectionFooter:SetPoint("RIGHT", view.dwellersPanel, "RIGHT", -120, 0)
    view.collectionPage = createText(view.dwellersPanel, 8, colors.muted, "RIGHT")
    view.collectionPage:SetPoint("BOTTOMRIGHT", view.dwellersPanel, "BOTTOMRIGHT", -16, 12)

    view.statsPanel = CreateFrame("Frame", nil, view.dwellersPanel)
    view.statsPanel:SetPoint("TOPLEFT", view.dwellersPanel, "TOPLEFT", 14, -50)
    view.statsPanel:SetPoint("BOTTOMRIGHT", view.dwellersPanel, "BOTTOMRIGHT", -14, 14)
    view.statsSummary = createText(view.statsPanel, 11, colors.text, "LEFT")
    view.statsSummary:SetPoint("TOPLEFT", view.statsPanel, "TOPLEFT", 8, -8)
    view.statsSummary:SetPoint("TOPRIGHT", view.statsPanel, "TOPRIGHT", -8, -8)
    view.statsSummary:SetHeight(82)
    view.statsSummary:SetJustifyV("TOP")
    view.statsClassTitle = createText(view.statsPanel, 11, colors.gold, "LEFT")
    view.statsClassTitle:SetPoint("TOPLEFT", view.statsSummary, "BOTTOMLEFT", 0, -10)
    view.statsClassTitle:SetText("MAXIMUM LEVEL BY CLASS")
    view.statsClassText = createText(view.statsPanel, 10, colors.muted, "LEFT")
    view.statsClassText:SetPoint("TOPLEFT", view.statsClassTitle, "BOTTOMLEFT", 0, -8)
    view.statsClassText:SetPoint("BOTTOMRIGHT", view.statsPanel, "BOTTOMRIGHT", -8, 8)
    view.statsClassText:SetJustifyV("TOP")
    view.statsPanel:Hide()

    view.passPanel = CreateFrame("Frame", nil, view.dwellersPanel)
    view.passPanel:SetPoint("TOPLEFT", view.dwellersPanel, "TOPLEFT", 14, -48)
    view.passPanel:SetPoint("BOTTOMRIGHT", view.dwellersPanel, "BOTTOMRIGHT", -14, 14)
    view.passLevel = createText(view.passPanel, 13, colors.gold, "LEFT")
    view.passLevel:SetPoint("TOPLEFT", view.passPanel, "TOPLEFT", 4, -4)
    view.passXP = createText(view.passPanel, 9, colors.muted, "RIGHT")
    view.passXP:SetPoint("TOPRIGHT", view.passPanel, "TOPRIGHT", -4, -6)
    view.passBar = dungeonHealthBar(view.passPanel, 640, 10, colors.accent)
    view.passBar:SetPoint("TOP", view.passPanel, "TOP", 0, -28)
    view.passActivity = createText(view.passPanel, 8, colors.muted, "LEFT")
    view.passActivity:SetPoint("TOPLEFT", view.passPanel, "TOPLEFT", 4, -44)
    view.passActivity:SetPoint("RIGHT", view.passPanel, "RIGHT", -4, 0)
    view.passClaimAll = createButton(view.passPanel, "CLAIM ALL READY", 142, 24, function()
        if CC.DungeonDwellersPass and CC.DungeonDwellersPass.ClaimAllAvailable then CC.DungeonDwellersPass:ClaimAllAvailable() end
    end)
    view.passClaimAll:SetPoint("TOPRIGHT", view.passPanel, "TOPRIGHT", -4, -65)
    setButtonAccent(view.passClaimAll, colors.gold)
    view.passBuffs = createText(view.passPanel, 8, colors.green, "LEFT")
    view.passBuffs:SetPoint("TOPLEFT", view.passPanel, "TOPLEFT", 4, -68)
    view.passBuffs:SetPoint("RIGHT", view.passClaimAll, "LEFT", -8, 0)
    view.passBuffs:SetHeight(28)
    view.passBuffs:SetWordWrap(true)
    view.passRows = {}
    for index = 1, 6 do
        local row = CreateFrame("Button", nil, view.passPanel, templateName())
        row:SetSize(640, 48)
        row:SetPoint("TOPLEFT", view.passPanel, "TOPLEFT", 0, -104 - (index - 1) * 51)
        applyBackdrop(row, colors.panel, colors.border)
        row.level = createText(row, 12, colors.gold, "CENTER")
        row.level:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.level:SetWidth(48)
        row.title = createText(row, 9, colors.text, "LEFT")
        row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 62, -7)
        row.title:SetPoint("RIGHT", row, "RIGHT", -126, 0)
        row.reward = createText(row, 8, colors.muted, "LEFT")
        row.reward:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4)
        row.reward:SetPoint("RIGHT", row, "RIGHT", -126, 0)
        row.state = createText(row, 9, colors.muted, "RIGHT")
        row.state:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        row.state:SetWidth(108)
        row:SetScript("OnClick", function(selfRow)
            if selfRow.passLevel and CC.DungeonDwellersPass and CC.DungeonDwellersPass.ClaimReward then
                CC.DungeonDwellersPass:ClaimReward(selfRow.passLevel)
            end
        end)
        view.passRows[index] = row
    end
    view.passPanel:Hide()

    view.dwellersPanel:SetScript("OnMouseWheel", function(_, delta)
        if view.dwellersMode == "COLLECTION" then
            local entries = view.collectionEntries or {}
            view.collectionOffset = max(0, min(max(0, #entries - #view.collectionRows), (view.collectionOffset or 0) - delta))
        elseif view.dwellersMode == "PASS" then
            view.passOffset = max(0, min(94, (view.passOffset or 0) - delta))
        end
        view:RefreshDwellersPanel()
    end)

    -- Chest drops pause the dungeon and present a themed reveal. The player
    -- opens the chest, sees three generated rewards and claims exactly one.
    view.crateBlocker = CreateFrame("Frame", nil, view.frame, templateName())
    view.crateBlocker:SetAllPoints()
    view.crateBlocker:SetFrameLevel((view.stage:GetFrameLevel() or 1) + 45)
    view.crateBlocker:EnableMouse(true)
    applyBackdrop(view.crateBlocker, {0.004, 0.006, 0.010, 0.86}, {0, 0, 0, 0})
    view.crateBlocker:Hide()

    view.cratePopup = cardFrame(view.crateBlocker, 650, 390)
    view.cratePopup:SetPoint("CENTER", view.crateBlocker, "CENTER", 0, 0)
    view.cratePopup:SetFrameLevel((view.crateBlocker:GetFrameLevel() or 1) + 1)
    view.cratePopup:EnableMouse(true)
    applyBackdrop(view.cratePopup, {0.018, 0.022, 0.030, 1}, colors.gold)

    view.crateTitle = createText(view.cratePopup, 18, colors.gold, "CENTER")
    view.crateTitle:SetPoint("TOPLEFT", view.cratePopup, "TOPLEFT", 16, -12)
    view.crateTitle:SetPoint("TOPRIGHT", view.cratePopup, "TOPRIGHT", -16, -12)
    view.crateTitle:SetText("CHEST DROPPED")
    view.crateRarity = createText(view.cratePopup, 10, colors.muted, "CENTER")
    view.crateRarity:SetPoint("TOPLEFT", view.crateTitle, "BOTTOMLEFT", 0, -3)
    view.crateRarity:SetPoint("TOPRIGHT", view.crateTitle, "BOTTOMRIGHT", 0, -3)

    view.crateArtPlate = cardFrame(view.cratePopup, 164, 166)
    view.crateArtPlate:SetPoint("TOPLEFT", view.cratePopup, "TOPLEFT", 20, -60)
    applyBackdrop(view.crateArtPlate, {0.010, 0.014, 0.020, 1}, colors.border)
    view.crateArt = dungeonCreateOpaqueTexture(view.crateArtPlate, 2)
    view.crateArt:ClearAllPoints()
    view.crateArt:SetPoint("TOPLEFT", view.crateArtPlate, "TOPLEFT", 6, -6)
    view.crateArt:SetPoint("BOTTOMRIGHT", view.crateArtPlate, "BOTTOMRIGHT", -6, 6)
    for _, layer in ipairs(view.crateArt.creshOpacityLayers or {}) do
        layer:ClearAllPoints()
        layer:SetPoint("TOPLEFT", view.crateArtPlate, "TOPLEFT", 6, -6)
        layer:SetPoint("BOTTOMRIGHT", view.crateArtPlate, "BOTTOMRIGHT", -6, 6)
    end

    view.crateBadgeFrame = cardFrame(view.cratePopup, 46, 46)
    view.crateBadgeFrame:SetPoint("TOPRIGHT", view.cratePopup, "TOPRIGHT", -18, -58)
    applyBackdrop(view.crateBadgeFrame, {0.010, 0.014, 0.020, 1}, colors.gold)
    view.crateBadge = dungeonCreateOpaqueTexture(view.crateBadgeFrame, 2)
    view.crateBadge:ClearAllPoints()
    view.crateBadge:SetPoint("TOPLEFT", view.crateBadgeFrame, "TOPLEFT", 3, -3)
    view.crateBadge:SetPoint("BOTTOMRIGHT", view.crateBadgeFrame, "BOTTOMRIGHT", -3, 3)

    view.crateName = createText(view.cratePopup, 15, colors.text, "LEFT")
    view.crateName:SetPoint("TOPLEFT", view.cratePopup, "TOPLEFT", 204, -66)
    view.crateName:SetPoint("RIGHT", view.cratePopup, "RIGHT", -76, 0)
    view.crateDescription = createText(view.cratePopup, 9, colors.muted, "LEFT")
    view.crateDescription:SetPoint("TOPLEFT", view.crateName, "BOTTOMLEFT", 0, -7)
    view.crateDescription:SetPoint("RIGHT", view.cratePopup, "RIGHT", -20, 0)
    view.crateDescription:SetHeight(42)
    view.crateDescription:SetWordWrap(true)
    view.crateSource = createText(view.cratePopup, 9, colors.gold, "LEFT")
    view.crateSource:SetPoint("TOPLEFT", view.crateDescription, "BOTTOMLEFT", 0, -5)
    view.crateSource:SetPoint("RIGHT", view.cratePopup, "RIGHT", -20, 0)
    view.crateOdds = createText(view.cratePopup, 8, colors.muted, "LEFT")
    view.crateOdds:SetPoint("TOPLEFT", view.crateSource, "BOTTOMLEFT", 0, -7)
    view.crateOdds:SetPoint("RIGHT", view.cratePopup, "RIGHT", -20, 0)
    view.crateOdds:SetHeight(42)
    view.crateOdds:SetWordWrap(true)

    view.crateOpenButton = createButton(view.cratePopup, "OPEN CHEST", 250, 38, function() view:RevealActiveCrate() end)
    view.crateOpenButton:SetPoint("TOPLEFT", view.cratePopup, "TOPLEFT", 204, -181)
    setButtonAccent(view.crateOpenButton, colors.gold)
    view.crateInstruction = createText(view.cratePopup, 8, colors.muted, "CENTER")
    view.crateInstruction:SetPoint("TOPLEFT", view.crateOpenButton, "BOTTOMLEFT", 0, -5)
    view.crateInstruction:SetPoint("RIGHT", view.cratePopup, "RIGHT", -20, 0)
    view.crateInstruction:SetText("Press Space/Enter to open · after opening choose one reward")

    view.crateChoiceCards = {}
    for index = 1, 3 do
        local card = CreateFrame("Button", nil, view.cratePopup, templateName())
        card:SetSize(196, 126)
        card:SetPoint("BOTTOMLEFT", view.cratePopup, "BOTTOMLEFT", 20 + (index - 1) * 207, 18)
        applyBackdrop(card, colors.panel, colors.border)
        card.rewardIndex = index
        card.number = createText(card, 8, colors.muted, "LEFT")
        card.number:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -7)
        card.number:SetText(tostring(index))
        card.iconFrame = cardFrame(card, 40, 40)
        card.iconFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -18)
        card.icon = dungeonCreateOpaqueTexture(card.iconFrame, 1)
        card.icon:ClearAllPoints()
        card.icon:SetPoint("TOPLEFT", card.iconFrame, "TOPLEFT", 2, -2)
        card.icon:SetPoint("BOTTOMRIGHT", card.iconFrame, "BOTTOMRIGHT", -2, 2)
        card.title = createText(card, 9, colors.gold, "LEFT")
        card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 60, -18)
        card.title:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -18)
        card.reward = createText(card, 11, colors.text, "LEFT")
        card.reward:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -5)
        card.reward:SetPoint("TOPRIGHT", card.title, "BOTTOMRIGHT", 0, -5)
        card.detail = createText(card, 8, colors.muted, "CENTER")
        card.detail:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -64)
        card.detail:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -7, 19)
        card.detail:SetWordWrap(true)
        card.select = createText(card, 8, colors.gold, "CENTER")
        card.select:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 6, 6)
        card.select:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -6, 6)
        card.select:SetText("SELECT REWARD")
        card:SetScript("OnClick", function(selfCard) view:ClaimCrateChoice(selfCard.rewardIndex) end)
        card:SetScript("OnEnter", function(selfCard)
            if selfCard.rewardChoice then applyBackdrop(selfCard, darken(colors.gold, 0.38), colors.gold) end
        end)
        card:SetScript("OnLeave", function(selfCard)
            if selfCard.rewardChoice then applyBackdrop(selfCard, colors.panel, colors.border) end
        end)
        card:Hide()
        view.crateChoiceCards[index] = card
    end

    function view:GetClassData()
        local class, key = dungeonClassData(self.classKey)
        self.classKey = key
        return class
    end

    function view:GetEquippedArmour()
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        if not content or not save or not save.dungeon then return nil end
        local classKey = upper(tostring(self.classKey or "PALADIN"))
        local setKey = save.dungeon.equippedArmour and save.dungeon.equippedArmour[classKey]
        if not setKey or not save.dungeon.unlockedArmour[setKey] then return nil end
        return content:GetArmourSet(classKey, setKey)
    end

    function view:GetDungeonPassBuffs()
        if CC.DungeonDwellersPass and CC.DungeonDwellersPass.GetBuffs then
            return CC.DungeonDwellersPass:GetBuffs() or {}
        end
        return {}
    end

    function view:GetArmourStats()
        local source = type(self.armourStats) == "table" and self.armourStats or {}
        local buffs = self:GetDungeonPassBuffs()
        local combined = {}
        for key, value in pairs(source) do combined[key] = value end
        combined.maxHP = (combined.maxHP or 0) + (buffs.maxHP or 0)
        combined.attack = (combined.attack or 0) + (buffs.attack or 0)
        combined.regenRoom = (combined.regenRoom or 0) + (buffs.regenRoom or 0)
        combined.regenTurn = (combined.regenTurn or 0) + (buffs.regenTurn or 0)
        combined.bossDamage = (combined.bossDamage or 0) + (buffs.bossDamage or 0)
        combined.extraDieChance = (combined.extraDieChance or 0) + (buffs.extraDieChance or 0)
        combined.passMinionPower = buffs.minionPower or 0
        combined.passCoinBonus = buffs.coinBonus or 0
        return combined
    end

    function view:GetClassStat(classKey)
        local save = ensureSave()
        if not save or not save.dungeon then return nil end
        classKey = upper(tostring(classKey or self.classKey or "PALADIN"))
        save.dungeon.classStats = type(save.dungeon.classStats) == "table" and save.dungeon.classStats or {}
        local stat = save.dungeon.classStats[classKey]
        if type(stat) ~= "table" then
            stat = { runs = 0, maxRoom = 0, kills = 0, bosses = 0, highScore = 0, deaths = 0 }
            save.dungeon.classStats[classKey] = stat
        end
        stat.runs = floor(max(0, tonumber(stat.runs) or 0))
        stat.maxRoom = floor(max(0, tonumber(stat.maxRoom) or 0))
        stat.kills = floor(max(0, tonumber(stat.kills) or 0))
        stat.bosses = floor(max(0, tonumber(stat.bosses) or 0))
        stat.highScore = floor(max(0, tonumber(stat.highScore) or 0))
        stat.deaths = floor(max(0, tonumber(stat.deaths) or 0))
        return stat
    end

    function view:CycleCollectionClass(direction)
        local order = { "ALL", "PALADIN", "WARRIOR", "ROGUE", "RANGER", "MAGE", "PRIEST", "WARLOCK", "DEFENDER", "DRUID", "SHAMAN" }
        local current = 1
        for index, key in ipairs(order) do if key == self.collectionClass then current = index break end end
        current = ((current - 1 + (direction or 1)) % #order) + 1
        self.collectionClass = order[current]
        self.collectionOffset = 0
        self:RefreshDwellersPanel()
    end

    function view:BuildCollectionEntries()
        local save = ensureSave()
        local dungeon = save and save.dungeon or {}
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local entries = {}
        local typeFilter = upper(tostring(self.collectionType or "ALL"))
        local stateFilter = upper(tostring(self.collectionState or "ALL"))
        local classFilter = upper(tostring(self.collectionClass or "ALL"))

        local function include(entry)
            if typeFilter ~= "ALL" and entry.category ~= typeFilter then return end
            if stateFilter == "UNLOCKED" and not entry.unlocked then return end
            if stateFilter == "LOCKED" and entry.unlocked then return end
            if classFilter ~= "ALL" and entry.classKey and entry.classKey ~= classFilter then return end
            entries[#entries + 1] = entry
        end

        for _, kind in ipairs(DUNGEON_MINION_TYPES) do
            local variants = DUNGEON_MINION_VARIANTS[kind] or {}
            if #variants == 0 then variants = { kind } end
            for _, variant in ipairs(variants) do
                local count = dungeon.minionSkinRecruits and dungeon.minionSkinRecruits[variant] or 0
                local display = tostring(variant):gsub("_", " ")
                include({
                    category = "MINION", key = variant, name = display,
                    detail = kind .. " companion skin · recruited " .. tostring(count) .. " time" .. (count == 1 and "" or "s"),
                    texture = dungeonTexture("03_Minion_Portraits_Core", variant) or "Interface\\Icons\\Ability_Hunter_Pet_Bat",
                    unlocked = dungeon.unlockedMinionSkins and dungeon.unlockedMinionSkins[variant] == true,
                })
            end
        end

        for _, classKey in ipairs(DUNGEON_CLASS_ORDER) do
            local class = DUNGEON_CLASSES[classKey]
            local stat = self:GetClassStat(classKey) or {}
            include({
                category = "CLASS", key = classKey, classKey = classKey,
                name = class.name, detail = class.short .. " · best room " .. tostring(stat.maxRoom or 0),
                texture = dungeonTexture("01_Player_Portraits_Classic", class.asset), unlocked = true,
            })
        end

        local armourClassOrder = { "PALADIN", "WARRIOR", "ROGUE", "RANGER", "MAGE", "PRIEST", "WARLOCK", "DEFENDER", "DRUID", "SHAMAN" }
        if content and content.armourSets then
            for _, classKey in ipairs(armourClassOrder) do
                for _, set in ipairs(content.armourSets[classKey] or {}) do
                    local unlocked = dungeon.unlockedArmour and dungeon.unlockedArmour[set.key] == true
                    include({
                        category = "ARMOUR", key = set.key, classKey = classKey,
                        name = set.name, detail = (set.className or classKey) .. " · Tier " .. tostring(set.tier or 1) .. " · " .. dungeonArmourStatText(set.stats),
                        texture = set.icon, unlocked = unlocked,
                    })
                end
            end
        end

        local crateCounts = {}
        for key, count in pairs(dungeon.crateInventory or {}) do crateCounts[key] = (crateCounts[key] or 0) + (tonumber(count) or 0) end
        for _, record in ipairs(dungeon.crateHistory or {}) do
            local key = upper(tostring(record.key or ""))
            if key ~= "" then crateCounts[key] = (crateCounts[key] or 0) + 1 end
        end
        if content then
            for _, key in ipairs(content.crateOrder or {}) do
                local crate = content.crates and content.crates[key]
                if crate then
                    local count = crateCounts[key] or 0
                    include({ category = "ITEM", key = "CRATE:" .. key, name = crate.name,
                        detail = crate.rarity .. " chest · acquired/opened " .. tostring(count), texture = crate.icon, unlocked = count > 0 })
                end
            end
            for _, level in ipairs(content.milestoneChestOrder or {}) do
                local chest = content.milestoneChests and content.milestoneChests[level]
                if chest then
                    include({ category = "ITEM", key = "MILESTONE:" .. tostring(level), name = chest.name,
                        detail = "Reach Dungeon level " .. tostring(level), texture = chest.icon, unlocked = (dungeon.bestRoom or 0) >= level })
                end
            end
            local itemStates = {
                COINS = (dungeon.bossCoins or 0) > 0,
                DAMAGE = (dungeon.permanentDamage or 0) > 0,
                PORTRAIT = (dungeon.portraitTokens or 0) > 0,
                FULLBODY = (dungeon.fullBodyTokens or 0) > 0,
                SHARDS = (dungeon.armourShards or 0) > 0,
            }
            local itemDetails = {
                COINS = tostring(dungeon.bossCoins or 0) .. " boss coins earned",
                DAMAGE = "+" .. tostring(dungeon.permanentDamage or 0) .. " permanent starting damage",
                PORTRAIT = tostring(dungeon.portraitTokens or 0) .. " portrait tokens held",
                FULLBODY = tostring(dungeon.fullBodyTokens or 0) .. " full-body tokens held",
                SHARDS = tostring(dungeon.armourShards or 0) .. " armour shards held",
            }
            for _, key in ipairs({ "COINS", "DAMAGE", "PORTRAIT", "FULLBODY", "SHARDS" }) do
                local item = content.rewardIcons and content.rewardIcons[key]
                if item then include({ category = "ITEM", key = "REWARD:" .. key, name = item.name, detail = itemDetails[key], texture = item.icon, unlocked = itemStates[key] }) end
            end
        end

        table.sort(entries, function(a, b)
            if a.category ~= b.category then return a.category < b.category end
            if (a.classKey or "") ~= (b.classKey or "") then return (a.classKey or "") < (b.classKey or "") end
            return tostring(a.name or "") < tostring(b.name or "")
        end)
        return entries
    end

    function view:RefreshCollectionPanel()
        local entries = self:BuildCollectionEntries()
        self.collectionEntries = entries
        self.collectionOffset = max(0, min(max(0, #entries - #self.collectionRows), self.collectionOffset or 0))
        local totalUnlocked = 0
        for _, entry in ipairs(entries) do if entry.unlocked then totalUnlocked = totalUnlocked + 1 end end

        for key, button in pairs(self.collectionTypeButtons or {}) do
            applyBackdrop(button, key == self.collectionType and darken(colors.accent, 0.26) or colors.panel, key == self.collectionType and colors.accent or colors.border)
        end
        for key, button in pairs(self.collectionStateButtons or {}) do
            applyBackdrop(button, key == self.collectionState and darken(colors.green, 0.34) or colors.panel, key == self.collectionState and colors.green or colors.border)
        end
        if self.collectionClassButton and self.collectionClassButton.label then self.collectionClassButton.label:SetText("CLASS: " .. tostring(self.collectionClass or "ALL")) end

        for index, row in ipairs(self.collectionRows or {}) do
            local entry = entries[(self.collectionOffset or 0) + index]
            row.entry = entry
            if entry then
                row:Show()
                dungeonSetTexture(row.icon, entry.texture)
                dungeonSetDesaturated(row.icon, not entry.unlocked)
                dungeonSetVertexColor(row.icon, entry.unlocked and 1 or 0.50, entry.unlocked and 1 or 0.50, entry.unlocked and 1 or 0.50, 1)
                row.category:SetText(entry.category .. (entry.classKey and (" · " .. entry.classKey) or ""))
                row.name:SetText(upper(tostring(entry.name or entry.key)))
                row.detail:SetText(tostring(entry.detail or ""))
                row.state:SetText(entry.unlocked and "UNLOCKED" or "LOCKED")
                row.state:SetTextColor(entry.unlocked and colors.green[1] or colors.muted[1], entry.unlocked and colors.green[2] or colors.muted[2], entry.unlocked and colors.green[3] or colors.muted[3], 1)
                row:SetAlpha(entry.unlocked and 1 or 0.72)
                applyBackdrop(row, entry.unlocked and colors.panel or darken(colors.panel, 0.04), entry.unlocked and colors.border or darken(colors.border, 0.20))
            else
                row:Hide()
            end
        end
        self.collectionFooter:SetText(tostring(totalUnlocked) .. " / " .. tostring(#entries) .. " shown entries unlocked · mouse wheel scrolls")
        local first = #entries > 0 and ((self.collectionOffset or 0) + 1) or 0
        local last = min(#entries, (self.collectionOffset or 0) + #self.collectionRows)
        self.collectionPage:SetText(tostring(first) .. "–" .. tostring(last) .. " / " .. tostring(#entries))
    end

    function view:RefreshStatsPanel()
        local save = ensureSave()
        local dungeon = save and save.dungeon or {}
        local armourCount = 0
        for _, unlocked in pairs(dungeon.unlockedArmour or {}) do if unlocked then armourCount = armourCount + 1 end end
        local chestCount = #(dungeon.crateHistory or {})
        self.statsSummary:SetText(format(
            "TOTAL RUNS  %d     BEST LEVEL  %d     HIGH SCORE  %d\nTOTAL KILLS  %d     BOSSES  %d     MINIONS RECRUITED  %d\nCHESTS OPENED  %d     ARMOUR SETS  %d     BOSS COINS  %d",
            dungeon.runs or 0, dungeon.bestRoom or dungeon.bestLevel or 0, dungeon.highScore or 0,
            dungeon.kills or 0, dungeon.bosses or 0, dungeon.minions or 0,
            chestCount, armourCount, dungeon.bossCoins or 0
        ))
        local lines = {}
        for _, classKey in ipairs(DUNGEON_CLASS_ORDER) do
            local class = DUNGEON_CLASSES[classKey]
            local stat = self:GetClassStat(classKey) or {}
            lines[#lines + 1] = format("%-10s  MAX %4d   RUNS %4d   KILLS %5d   BOSSES %4d   BEST SCORE %6d",
                upper(class.name), stat.maxRoom or 0, stat.runs or 0, stat.kills or 0, stat.bosses or 0, stat.highScore or 0)
        end
        self.statsClassText:SetText(concat(lines, "\n"))
    end

    function view:RefreshPassPanel()
        local pass = CC.DungeonDwellersPass
        if not pass then
            self.passLevel:SetText("DUNGEON DWELLERS PASS UNAVAILABLE")
            return
        end
        local level, current, needed, ratio = pass:GetProgress()
        local save = pass:Ensure()
        local activity = pass:GetActivitySummary()
        local buffs = pass:GetBuffs()
        self.passLevel:SetText("DUNGEON DWELLERS PASS · LEVEL " .. tostring(level))
        self.passXP:SetText(tostring(current) .. " / " .. tostring(needed) .. " XP")
        self.passBar:SetMinMaxValues(0, max(1, needed))
        self.passBar:SetValue(level >= pass.maxLevel and needed or current)
        self.passActivity:SetText(format("WOW MOBS %d · DUNGEON ENEMIES %d · QUESTS %d · ZONES %d · ACHIEVEMENTS %d",
            activity.mobKills or 0, activity.dungeonKills or 0, activity.quests or 0, activity.zones or 0, activity.achievements or 0))
        self.passBuffs:SetText(format("ACTIVE BOONS: +%d HP · +%d ATK · +%d MINION · +%d ROOM HEAL · +%d BOSS DMG · %d%% BONUS DIE · %d%% COINS",
            buffs.maxHP or 0, buffs.attack or 0, buffs.minionPower or 0, buffs.regenRoom or 0, buffs.bossDamage or 0, buffs.extraDieChance or 0, buffs.coinBonus or 0))

        local ready = 0
        for rewardLevel = 1, pass.maxLevel do if pass:IsLevelReached(rewardLevel) and not pass:IsRewardClaimed(rewardLevel) then ready = ready + 1 end end
        if self.passClaimAll and self.passClaimAll.label then self.passClaimAll.label:SetText(ready > 0 and ("CLAIM ALL · " .. tostring(ready)) or "NO REWARDS READY") end
        setButtonEnabled(self.passClaimAll, ready > 0)

        self.passOffset = max(0, min(pass.maxLevel - #self.passRows, self.passOffset or 0))
        for index, row in ipairs(self.passRows or {}) do
            local rewardLevel = self.passOffset + index
            local reward = pass:GetReward(rewardLevel)
            local reached = pass:IsLevelReached(rewardLevel)
            local claimed = pass:IsRewardClaimed(rewardLevel)
            row.passLevel = rewardLevel
            row:Show()
            row.level:SetText("LV " .. tostring(rewardLevel))
            row.title:SetText(upper(reward.title))
            row.reward:SetText(pass:GetRewardText(rewardLevel))
            row.state:SetText(claimed and "CLAIMED" or (reached and "CLAIM" or "LOCKED"))
            row.state:SetTextColor(claimed and colors.green[1] or (reached and colors.gold[1] or colors.muted[1]), claimed and colors.green[2] or (reached and colors.gold[2] or colors.muted[2]), claimed and colors.green[3] or (reached and colors.gold[3] or colors.muted[3]), 1)
            row:SetAlpha(claimed and 0.72 or (reached and 1 or 0.62))
            applyBackdrop(row, reached and darken(colors.gold, claimed and 0.48 or 0.38) or colors.panel, reached and colors.gold or colors.border)
        end
    end

    function view:SetDwellersMode(mode)
        mode = upper(tostring(mode or "COLLECTION"))
        if mode ~= "STATS" and mode ~= "PASS" then mode = "COLLECTION" end
        self.dwellersMode = mode
        if mode == "PASS" and CC.DungeonDwellersPass then
            local level = CC.DungeonDwellersPass:GetProgress()
            self.passOffset = max(0, min(94, (tonumber(level) or 1) - 3))
        end
        self:RefreshDwellersPanel()
    end

    function view:ShowDwellersPanel(mode)
        if self.classPicker then self.classPicker:Hide() end
        if self.armourPicker then self.armourPicker:Hide() end
        self.dwellersPanel:Show()
        self:SetDwellersMode(mode or self.dwellersMode or "COLLECTION")
    end

    function view:RefreshDwellersPanel()
        if not self.dwellersPanel then return end
        local mode = self.dwellersMode or "COLLECTION"
        self.collectionControls:SetShown(mode == "COLLECTION")
        for _, row in ipairs(self.collectionRows or {}) do row:SetShown(mode == "COLLECTION") end
        self.collectionFooter:SetShown(mode == "COLLECTION")
        self.collectionPage:SetShown(mode == "COLLECTION")
        self.statsPanel:SetShown(mode == "STATS")
        self.passPanel:SetShown(mode == "PASS")
        for key, tab in pairs(self.dwellersTabs or {}) do
            applyBackdrop(tab, key == mode and darken(colors.accent, 0.26) or colors.panel, key == mode and colors.accent or colors.border)
        end
        self.dwellersTitle:SetText(mode == "COLLECTION" and "DUNGEON COLLECTION" or (mode == "STATS" and "DUNGEON STATISTICS" or "DUNGEON DWELLERS BATTLE PASS"))
        if mode == "COLLECTION" then self:RefreshCollectionPanel()
        elseif mode == "STATS" then self:RefreshStatsPanel()
        else self:RefreshPassPanel() end
    end

    function view:ApplyClassVisuals()
        local class = self:GetClassData()
        local armour = self:GetEquippedArmour()
        local assetKey = dungeonPlayerKey(self.classKey)
        self.heroAssetKey = assetKey
        self.equippedArmour = armour
        self.armourStats = armour and armour.stats or {}
        dungeonSetTexture(self.heroIcon, armour and armour.icon or dungeonTexture("01_Player_Portraits_Classic", assetKey))
        dungeonSetTexture(self.heroBody, armour and armour.fullBody or dungeonTexture("02_Player_FullBody_Classic", assetKey))
        if self.classButton and self.classButton.label then self.classButton.label:SetText("CLASS") end
        if self.armourButton and self.armourButton.label then
            self.armourButton.label:SetText(armour and ("ARMOUR · T" .. tostring(armour.tier or 1)) or "ARMOUR · NONE")
        end
        return class
    end

    function view:RefreshArmourPicker()
        local class = self:GetClassData()
        local save = ensureSave()
        local current = self:GetEquippedArmour()
        local unlockedCount = 0
        local sets = class.armourSets or {}
        for index, card in ipairs(self.armourCards or {}) do
            local set = sets[index]
            card.armourSet = set
            if set then
                local unlocked = save and save.dungeon and save.dungeon.unlockedArmour[set.key] == true
                local equipped = current and current.key == set.key
                card.armourUnlocked = unlocked
                if unlocked then unlockedCount = unlockedCount + 1 end
                card:Show()
                dungeonSetTexture(card.icon, set.icon)
                dungeonSetDesaturated(card.icon, not unlocked)
                card:SetAlpha(unlocked and 1 or 0.66)
                card.name:SetText("TIER " .. tostring(set.tier or index) .. " · " .. upper(set.name))
                card.stats:SetText(dungeonArmourStatText(set.stats))
                card.state:SetText(equipped and "EQUIPPED" or (unlocked and "EQUIP" or "LOCKED"))
                applyBackdrop(card, equipped and darken(colors.green, 0.36) or (unlocked and colors.panel or darken(colors.panel, 0.04)), equipped and colors.green or (unlocked and colors.gold or colors.border))
            else
                card:Hide()
            end
        end
        self.armourPickerTitle:SetText(upper(class.name) .. " ARMOUR LOADOUT")
        self.armourPickerHint:SetText(current and (current.name .. " · " .. dungeonArmourStatText(current.stats)) or "No armour equipped. Select any unlocked set to apply its combat statistics.")
        self.armourCollection:SetText(tostring(unlockedCount) .. " / " .. tostring(#sets) .. " UNLOCKED")
    end

    function view:ShowArmourPicker()
        if not self.armourPicker then return end
        if self.classPicker then self.classPicker:Hide() end
        self:RefreshArmourPicker()
        self.armourPicker:Show()
    end

    function view:SetArmour(setKey, restart)
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        if not content or not save or not save.dungeon then return end
        local classKey = upper(tostring(self.classKey or "PALADIN"))
        local set = setKey and content:GetArmourSet(classKey, setKey) or nil
        if set and not save.dungeon.unlockedArmour[set.key] then return end
        save.dungeon.equippedArmour[classKey] = set and set.key or nil
        self:ApplyClassVisuals()
        self:RefreshArmourPicker()
        if self.armourPicker then self.armourPicker:Hide() end
        if restart then
            self:StartRun(set and ("Equipped " .. set.name .. ". " .. dungeonArmourStatText(set.stats) .. ".") or "Armour removed. A fresh unarmoured run begins.", true)
        else
            self:Refresh()
        end
    end

    function view:RefreshClassPicker()
        local selected = upper(tostring(self.classKey or ""))
        for classKey, card in pairs(self.classCards or {}) do
            local active = classKey == selected
            card.creshSelected = active
            applyBackdrop(card, active and darken(colors.green, 0.38) or colors.panel, active and colors.green or colors.border)
        end
    end

    function view:ShowClassPicker()
        if not self.classPicker then return end
        self:RefreshClassPicker()
        self.classPicker:Show()
    end

    function view:SetClass(classKey, restart)
        local class, validKey = dungeonClassData(classKey)
        self.classKey = validKey
        local save = ensureSave()
        if save and save.dungeon then save.dungeon.class = validKey end
        self:ApplyClassVisuals()
        self:RefreshClassPicker()
        if self.classPicker then self.classPicker:Hide() end
        if restart then
            self:StartRun("Class changed to " .. class.name .. ". " .. class.short .. ".", true)
        else
            self:Refresh()
        end
    end

    function view:AddLog(line)
        self.logLines = self.logLines or {}
        insert(self.logLines, 1, tostring(line or ""))
        while #self.logLines > 5 do table.remove(self.logLines) end
        self.log:SetText(concat(self.logLines, "\n"))
    end

    function view:LivingEnemies()
        local count = 0
        for _, enemy in ipairs(self.enemies) do if enemy.alive then count = count + 1 end end
        return count
    end

    function view:RandomLivingEnemy()
        local living = {}
        for _, enemy in ipairs(self.enemies) do if enemy.alive then living[#living + 1] = enemy end end
        if #living == 0 then return nil end
        return living[self.rng:Next(#living)]
    end

    function view:SelectLiving(direction)
        if self:LivingEnemies() == 0 then return end
        local start = self.targetIndex or 1
        for offset = 1, 3 do
            local index = ((start - 1 + (direction or 1) * offset) % 3) + 1
            if self.enemies[index] and self.enemies[index].alive then self.targetIndex = index; self:Refresh(); return end
        end
    end

    function view:WeakestMinionIndex()
        local bestIndex, bestValue
        for index, minion in ipairs(self.minions or {}) do
            local value = (minion.power or 1) * 10 + (minion.level or 1)
            if not bestValue or value < bestValue then bestIndex, bestValue = index, value end
        end
        return bestIndex
    end

    function view:MinionActionText()
        if self.minionOffer then
            if #(self.minions or {}) < 2 then return "RECRUIT MINION" end
            return "REPLACE MINION"
        end
        if #(self.minions or {}) > 0 then return "+ MINION POWER" end
        return "NO MINION FOUND"
    end

    function view:RefreshDiceVisuals()
        local rolling = (self.diceShakeRemaining or 0) > 0
        local heroRolling = rolling and self.diceHeroRolling
        local enemyRolling = rolling and self.diceEnemyRolling
        local tick = floor((self.diceShakeClock or 0) * 24)
        local heroCount = 0
        for index = 1, 4 do
            if self.lastHeroDiceValues and self.lastHeroDiceValues[index] then heroCount = heroCount + 1 end
        end
        local enemyValue = self.lastEnemyDieValue
        local totalCount = heroCount + (enemyValue and 1 or 0)
        local dieSize, gap = 32, 6
        local totalWidth = totalCount > 0 and (totalCount * dieSize + (totalCount - 1) * gap) or 0
        local startX = floor((190 - totalWidth) / 2)
        local shownIndex = 0
        for index, die in ipairs(self.diceIcons or {}) do
            local final = self.lastHeroDiceValues and self.lastHeroDiceValues[index] or nil
            if final then
                shownIndex = shownIndex + 1
                die.baseX, die.baseY = startX + (shownIndex - 1) * (dieSize + gap), -31
                die:ClearAllPoints(); die:SetPoint("TOPLEFT", self.diceCard, "TOPLEFT", die.baseX, die.baseY)
                local value = heroRolling and (((tick + index * 3) % 8) + 1) or final
                die.texture:SetTexture(dungeonDiceTexture(value))
                die:Show()
            else
                die:Hide()
            end
        end
        if enemyValue then
            shownIndex = shownIndex + 1
            self.enemyDie.baseX, self.enemyDie.baseY = startX + (shownIndex - 1) * (dieSize + gap), -31
            self.enemyDie:ClearAllPoints(); self.enemyDie:SetPoint("TOPLEFT", self.diceCard, "TOPLEFT", self.enemyDie.baseX, self.enemyDie.baseY)
            local value = enemyRolling and (((tick + 5) % 8) + 1) or enemyValue
            self.enemyDie.texture:SetTexture(dungeonDiceTexture(value))
            self.enemyDie:Show()
            self.enemyDieLabel:ClearAllPoints()
            self.enemyDieLabel:SetPoint("BOTTOM", self.enemyDie, "TOP", 0, 1)
            self.enemyDieLabel:Show()
        else
            self.enemyDie:Hide(); self.enemyDieLabel:Hide()
        end
    end

    function view:StartDiceAnimation(heroValues, enemyValue)
        self.diceHeroRolling = type(heroValues) == "table"
        self.diceEnemyRolling = enemyValue ~= nil
        if self.diceHeroRolling then
            self.lastHeroDiceValues = {}
            for index = 1, min(4, #heroValues) do self.lastHeroDiceValues[index] = heroValues[index] end
        end
        if self.diceEnemyRolling then self.lastEnemyDieValue = enemyValue end
        self.diceShakeRemaining = 0.44
        self.diceShakeClock = 0
        self.rolling = true
        self:RefreshDiceVisuals()
    end

    function view:Refresh()
        self.pendingUpgrade = (self.upgradePoints or 0) > 0
        local isBossRoom = self.room % 10 == 0
        local tier = floor(((self.room or 1) - 1) / 10) + 1
        local playerName = type(UnitName) == "function" and UnitName("player") or "Dungeon Dweller"
        local class = self:GetClassData()
        self.heroName:SetText(upper(tostring(playerName or "DUNGEON DWELLER")))
        local armour = self.equippedArmour
        local armourStats = self:GetArmourStats()
        self.heroTier:SetText(armour and (upper(class.name) .. " · ARMOUR T" .. tostring(armour.tier or 1)) or ("DUNGEON TIER " .. tostring(tier) .. " · " .. upper(class.name)))
        self.heroHP:SetMinMaxValues(0, max(1, self.maxHP or 1))
        self.heroHP:SetValue(max(0, self.hp or 0))
        self.heroHP.text:SetText(format("HP %d / %d", self.hp or 0, self.maxHP or 0))
        local fixedHeroDice = 1 + max(0, floor(tonumber(armourStats.extraDice) or 0))
        self.heroStats:SetText(format("ATK %d · DICE %d · KILLS %d", self.attack or 1, fixedHeroDice, self.kills or 0))

        self.depthLabel:SetText(format("DEPTH %02d · TIER %d", self.room or 1, tier))
        self.scoreLabel:SetText(format("%d SCORE · %d KILLS", self.score or 0, self.kills or 0))
        self.roomTitle:SetText(isBossRoom and ("BOSS CHAMBER " .. tostring(self.room or 1)) or ("ROOM " .. tostring(self.room or 1)))
        self.actionRoom:SetText(isBossRoom and "BOSS" or format("ROOM %02d", self.room or 1))
        local depthProgress = (self.room or 1) % 10
        if depthProgress == 0 then depthProgress = 10 end
        self.depthBar:SetMinMaxValues(0, 10)
        self.depthBar:SetValue(depthProgress)
        self.depthBar.text:SetText(isBossRoom and "MILESTONE BOSS · CRATE + ARMOUR CHANCE" or format("%d LEVEL%s TO NEXT BOSS", 10 - ((self.room or 1) % 10), (10 - ((self.room or 1) % 10)) == 1 and "" or "S"))

        local living = self:LivingEnemies()
        local chestPending = self:HasPendingCrate()
        if chestPending then
            self.roomText:SetText("CHEST DROPPED · CHOOSE ONE REWARD")
            self.actionStatus:SetText("Open the chest and select one generated reward before continuing.")
        elseif self.dead then
            self.roomText:SetText(self.bossRetryAvailable and "MILESTONE BOSS CHECKPOINT READY" or "The dungeon claims another run.")
            self.actionStatus:SetText(self.bossRetryAvailable and "Retry restores your pre-boss stats and party." or "Your party has fallen. Begin a new run when ready.")
        elseif self.pendingUpgrade then
            local offer = self.minionOffer and (" · " .. self.minionOffer.name .. " waits to join") or ""
            self.roomText:SetText(format("%d UPGRADE POINT%s AVAILABLE%s", self.upgradePoints, self.upgradePoints == 1 and "" or "S", offer))
            self.actionStatus:SetText("Choose Health, Attack or strengthen your minion party.")
        elseif self.roomCleared then
            self.roomText:SetText("ROOM CLEARED · THE PATH BELOW IS OPEN")
            self.actionStatus:SetText("Recover your breath, then descend deeper.")
        else
            self.roomText:SetText(format("%d ENEM%s REMAIN · SELECT A TARGET", living, living == 1 and "Y" or "IES"))
            self.actionStatus:SetText(isBossRoom and (class.name .. " faces a powerful guardian. " .. class.short) or (class.name .. " · " .. class.short))
        end

        self.diceText:SetText(format("YOU %s  ·  FOE %s", self.lastPlayerRoll or "–", self.lastEnemyRoll or "–"))
        if self.RefreshDiceVisuals then self:RefreshDiceVisuals() end

        for i = 1, 2 do
            local card = self.minionCards[i]
            local minion = self.minions[i]
            if minion then
                card:Show()
                dungeonSetTexture(card.icon, dungeonTexture("03_Minion_Portraits_Core", minion.assetKey or dungeonMinionVisual(minion.kind or "Familiar", self.rng)))
                card.name:SetText(format("M%d · %s", i, minion.name or "MINION"))
                card.stats:SetText(format("LV %d · POWER +%d", minion.level or 1, minion.power or 1))
                applyBackdrop(card, darken(colors.accent, 0.45), colors.accent)
            elseif self.minionOffer and i == min(2, #self.minions + 1) then
                card:Show()
                dungeonSetTexture(card.icon, dungeonTexture("03_Minion_Portraits_Core", self.minionOffer.assetKey))
                card.name:SetText("NEW MINION")
                card.stats:SetText(format("LV %d · +%d · OFFER", self.minionOffer.level or 1, self.minionOffer.power or 1))
                applyBackdrop(card, darken(colors.gold, 0.45), colors.gold)
            else
                card:Show()
                dungeonSetTexture(card.icon, "Interface\\Icons\\INV_Misc_QuestionMark")
                dungeonSetVertexColor(card.icon, 0.36, 0.39, 0.44, 0.82)
                card.name:SetText(format("M%d · EMPTY", i))
                card.stats:SetText("Recruit after a kill")
                applyBackdrop(card, colors.panel, colors.border)
            end
        end

        local enemy = self.enemies[self.targetIndex]
        if not enemy then
            for _, candidate in ipairs(self.enemies) do if candidate then enemy = candidate; break end end
        end
        if enemy then
            self.enemyName:SetText((enemy.boss and "BOSS · " or "") .. upper(enemy.name or "ENEMY"))
            self.enemyTier:SetText(format("LVL %d · ATK %d · %s", enemy.level or self.room or 1, enemy.attack or 1, enemy.enemyType and upper(enemy.enemyType) or (enemy.boss and "BOSS D8" or "D6")))
            self.enemyHP:SetMinMaxValues(0, max(1, enemy.maxHP or 1))
            self.enemyHP:SetValue(max(0, enemy.hp or 0))
            self.enemyHP.text:SetText(enemy.alive and format("HP %d / %d", enemy.hp or 0, enemy.maxHP or 0) or "DEFEATED")
            dungeonSetTexture(self.enemyBody, enemy.bodyPath or dungeonTexture(enemy.bodySet, enemy.bodyKey))
            dungeonSetTexture(self.enemyIcon, enemy.iconPath or dungeonTexture(enemy.iconSet, enemy.iconKey))
            dungeonSetDesaturated(self.enemyBody, not enemy.alive)
            dungeonSetDesaturated(self.enemyIcon, not enemy.alive)
            self.enemyBodyHolder:SetAlpha(enemy.alive and 1 or 0.38)
            self.enemyStats:SetText(enemy.alive and format("TARGET %d · %s", enemy.id or self.targetIndex or 1, enemy.abilityName or format("ROLL %s · DAMAGE %d", enemy.lastRoll or "–", enemy.attack or 1)) or "TARGET DEFEATED")
            applyBackdrop(self.enemyPanel, enemy.boss and darken(colors.gold, 0.56) or darken(colors.red, 0.62), enemy.boss and colors.gold or colors.red)
        else
            self.enemyName:SetText("NO ENEMY")
            self.enemyTier:SetText("ROOM CLEARED")
            self.enemyHP:SetMinMaxValues(0, 1); self.enemyHP:SetValue(0); self.enemyHP.text:SetText("DEFEATED")
            dungeonSetTexture(self.enemyBody, "Interface\\Icons\\INV_Misc_QuestionMark")
            dungeonSetTexture(self.enemyIcon, "Interface\\Icons\\INV_Misc_QuestionMark")
            self.enemyStats:SetText("DESCEND TO CONTINUE")
        end

        for i = 1, 3 do
            local card, listedEnemy = self.enemySelectors[i], self.enemies[i]
            if listedEnemy then
                card:Show()
                dungeonSetTexture(card.icon, listedEnemy.iconPath or dungeonTexture(listedEnemy.iconSet, listedEnemy.iconKey))
                dungeonSetDesaturated(card.icon, not listedEnemy.alive)
                card:SetAlpha(listedEnemy.alive and 1 or 0.45)
                card.hp:SetMinMaxValues(0, max(1, listedEnemy.maxHP or 1))
                card.hp:SetValue(max(0, listedEnemy.hp or 0))
                card.hp.text:SetText(listedEnemy.alive and tostring(listedEnemy.hp or 0) or "X")
                applyBackdrop(card, i == self.targetIndex and darken(colors.red, 0.34) or colors.panel, i == self.targetIndex and colors.gold or colors.border)
            else
                card:Hide()
            end
        end

        local canAttack = not chestPending and not self.rolling and not self.dead and not self.pendingUpgrade and not self.roomCleared and living > 0
        -- Keep the attack control visible and mouse-enabled at all times. PlayerAttack
        -- still guards blocked states, while the label below explains why a roll cannot
        -- start yet. This avoids the main combat control disappearing or becoming
        -- visually unavailable during chest, upgrade and room-transition states.
        setButtonEnabled(self.attackButton, true)
        self.attackButton:Show()
        local totalFixedDice = fixedHeroDice + #(self.minions or {})
        local attackLabel = (armourStats.extraDieChance or 0) > 0 and format("ROLL ATTACK · %d DICE · %d%% BONUS", totalFixedDice, armourStats.extraDieChance) or format("ROLL ATTACK · %d DICE", totalFixedDice)
        if chestPending then attackLabel = "CHEST REWARD PENDING"
        elseif self.rolling then attackLabel = "DICE ROLLING..."
        elseif self.dead then attackLabel = "RUN ENDED"
        elseif self.pendingUpgrade then attackLabel = "CHOOSE AN UPGRADE"
        elseif self.roomCleared then attackLabel = "ROOM CLEARED"
        elseif living <= 0 then attackLabel = "NO TARGET" end
        self.attackButton.label:SetText(attackLabel)
        self.healthButton:SetShown(self.pendingUpgrade and not chestPending)
        self.attackUpgradeButton:SetShown(self.pendingUpgrade and not chestPending)
        self.minionButton:SetShown(self.pendingUpgrade and not chestPending)
        setButtonEnabled(self.healthButton, self.pendingUpgrade and not chestPending)
        setButtonEnabled(self.attackUpgradeButton, self.pendingUpgrade and not chestPending)
        local canMinion = self.pendingUpgrade and not chestPending and (self.minionOffer ~= nil or #(self.minions or {}) > 0)
        setButtonEnabled(self.minionButton, canMinion)
        self.healthButton.label:SetText(format("+ HEALTH · %d → %d · HEAL %d", self.maxHP or 0, (self.maxHP or 0) + (class.healthGain or 1), class.healthHeal or 2))
        self.attackUpgradeButton.label:SetText(format("+ ATTACK · %d → %d", self.attack or 1, (self.attack or 1) + (class.attackGain or 1)))
        self.minionButton.label:SetText(self:MinionActionText())
        self.nextButton:SetShown(not chestPending and not self.dead and self.roomCleared and not self.pendingUpgrade)
        self.newRunButton:SetShown(not chestPending and self.dead == true)
        if chestPending then
            self.actionHint:SetText(self.crateRevealed and "Choose reward 1, 2 or 3" or "Space or Enter opens the chest")
        elseif self.dead then
            self.newRunButton.label:SetText(self.bossRetryAvailable and "RETRY BOSS" or "NEW RUN")
            self.actionHint:SetText(self.bossRetryAvailable and "R or RETRY BOSS · checkpoint restored" or "R or NEW RUN · stats and minions reset")
        elseif self.pendingUpgrade then
            self.actionHint:SetText("H/W Health · J/S Attack · M Minion")
        elseif self.roomCleared then
            self.actionHint:SetText("Space or DESCEND · boss every 10 levels")
        else
            self.actionHint:SetText("A/D target · Space attack · C class · V armour")
        end
    end

    function view:CopyMinions(source)
        local copy = {}
        for index, minion in ipairs(source or {}) do
            copy[index] = {}
            for key, value in pairs(minion) do copy[index][key] = value end
        end
        return copy
    end

    function view:CreateBossCheckpoint()
        self.bossCheckpoint = {
            room = self.room, maxHP = self.maxHP, attack = self.attack,
            minions = self:CopyMinions(self.minions), kills = self.kills, score = self.score,
        }
        self.bossRetryAvailable = false
    end

    function view:RetryBoss()
        local checkpoint = self.bossCheckpoint
        if not checkpoint then self:StartRun("A fresh run begins.", true); return end
        self.room = checkpoint.room
        self.maxHP, self.hp, self.attack = checkpoint.maxHP, checkpoint.maxHP, checkpoint.attack
        self.minions = self:CopyMinions(checkpoint.minions)
        self.kills, self.score = checkpoint.kills, checkpoint.score
        self.dead, self.pendingUpgrade, self.roomCleared = false, false, false
        self.upgradePoints, self.minionOffer = 0, nil
        self.bossRetryAvailable, self.pendingBossReward = false, nil
        self:AddLog("Boss checkpoint restored. The guardian returns at full health.")
        self:GenerateRoom(true)
        Solo:SetStatus("Boss checkpoint restored at level " .. tostring(self.room) .. ".", colors.gold)
    end

    function view:SummonBossAdd(name, hp, attack, visualName)
        if #(self.enemies or {}) >= 3 then return false end
        local bodyKey, bodySet, iconKey, iconSet = dungeonEnemyVisual(visualName or name, false, self.rng)
        self.enemies[#self.enemies + 1] = {
            id = #self.enemies + 1, name = name, enemyType = "Boss Minion", hp = hp, maxHP = hp,
            attack = attack, boss = false, alive = true, lastRoll = 0, bodyKey = bodyKey, bodySet = bodySet,
            iconKey = iconKey, iconSet = iconSet,
        }
        self:AddLog(name .. " joins the boss battle.")
        return true
    end

    function view:ModifyBossIncomingDamage(enemy, roll, damage, source)
        if not enemy or not enemy.boss or not enemy.alive then return damage, "" end
        local mechanic = enemy.mechanic
        local note = ""
        if mechanic == "CANDLE" and enemy.candleLit and roll >= 5 then
            enemy.candleLit = false
            enemy.attack = max(1, (enemy.attack or 1) - 2)
            note = note .. " · CANDLE EXTINGUISHED"
        elseif mechanic == "COIL" and enemy.shieldActive then
            damage = max(1, floor(damage * 0.50))
            note = note .. " · COILGUARD"
        elseif mechanic == "AIRBORNE" and enemy.airborne then
            enemy.airborne = false
            enemy.diveReady = true
            damage = 0
            note = note .. " · EVADED IN FLIGHT"
        elseif mechanic == "PHASE" and enemy.phased then
            enemy.phased = false
            enemy.ambushReady = true
            damage = 0
            note = note .. " · PHASED"
        elseif mechanic == "BARK" and (enemy.armourLayers or 0) > 0 then
            damage = max(1, damage - 3)
            enemy.armourLayers = max(0, enemy.armourLayers - 1)
            note = note .. " · BARK " .. tostring(enemy.armourLayers)
        elseif mechanic == "MODES" and enemy.mode == "ARMOUR" then
            damage = max(1, floor(damage * 0.50))
            note = note .. " · ARMOUR MODE"
        elseif mechanic == "MANA" and roll >= 5 then
            damage = max(1, damage - 2)
            enemy.arcaneCharges = (enemy.arcaneCharges or 0) + 1
            note = note .. " · ARCANE ABSORB"
        end
        if enemy.webbedHero then
            damage = max(1, damage - 2)
            enemy.webbedHero = false
            note = note .. " · WEBBED"
        end
        if enemy.frozenHero then
            damage = max(1, damage - 2)
            enemy.frozenHero = false
            note = note .. " · FROZEN"
        end
        return damage, note
    end

    function view:AfterBossHit(enemy, roll)
        if not enemy or not enemy.alive or not enemy.boss then return end
        if enemy.mechanic == "TIDE" and roll >= 5 then enemy.tideInterrupted = true end
        if enemy.mechanic == "RAGE" then
            local percent = (enemy.hp or 0) / max(1, enemy.maxHP or 1)
            local targetStage = percent <= 0.25 and 3 or (percent <= 0.50 and 2 or (percent <= 0.75 and 1 or 0))
            while (enemy.rageStage or 0) < targetStage do
                enemy.rageStage = (enemy.rageStage or 0) + 1
                enemy.attack = (enemy.attack or 1) + 1
                self:AddLog(enemy.name .. " gains Unchained Rage: +1 Attack.")
            end
        elseif enemy.mechanic == "CATS" then
            local percent = (enemy.hp or 0) / max(1, enemy.maxHP or 1)
            local stage = percent <= 0.33 and 3 or (percent <= 0.66 and 2 or 1)
            if stage > (enemy.phase or 1) then
                enemy.phase = stage
                enemy.attack = (enemy.attack or 1) + 1
                self:SummonBossAdd("CATS Assault Drone", max(4, floor(enemy.maxHP * 0.08)), max(1, floor(enemy.attack / 2)), "imp")
                self:AddLog("CATS enters phase " .. tostring(stage) .. ": ALL YOUR BASE ARE BELONG TO US.")
            end
        end
    end

    function view:BossTurnEffects(enemy, damage, result)
        if not enemy or not enemy.boss then return damage, result end
        enemy.turn = (enemy.turn or 0) + 1
        local turn, mechanic = enemy.turn, enemy.mechanic
        if mechanic == "PACK" and turn % 3 == 0 then
            self:SummonBossAdd("Redtooth Packling", max(4, floor(enemy.maxHP * 0.10)), max(1, floor(enemy.attack / 2)), "wolf")
        elseif mechanic == "TIDE" and turn % 3 == 0 then
            if enemy.tideInterrupted then
                enemy.tideInterrupted = false
                self:AddLog("The Tidal Totem is interrupted.")
            else
                local heal = max(2, floor(enemy.maxHP * 0.10))
                enemy.hp = min(enemy.maxHP, enemy.hp + heal)
                self:AddLog(enemy.name .. " restores " .. tostring(heal) .. " HP through the Tidal Totem.")
            end
        elseif mechanic == "COIL" then
            enemy.shieldActive = not enemy.shieldActive
            if enemy.shieldActive then self:AddLog("Zariss raises Coilguard: the next attacks deal reduced damage.")
            else damage = damage + 2; result = tostring(damage) .. " assault" end
        elseif mechanic == "QUAKE" then
            if turn % 3 == 2 then self:AddLog("WARNING: Grumbar begins charging Earthbreaker.") end
            if turn % 3 == 0 then damage = damage + 4; result = tostring(damage) .. " EARTHQUAKE" end
        elseif mechanic == "AIRBORNE" then
            if enemy.diveReady then damage = damage + 3; enemy.diveReady = false; result = tostring(damage) .. " STORM DIVE"
            elseif turn % 3 == 0 then enemy.airborne = true; self:AddLog("Stormtalon takes flight and will evade the next strike.") end
        elseif mechanic == "DRAIN" and turn % 3 == 0 then
            damage = damage + 2
            local heal = max(1, floor(damage / 2))
            enemy.hp = min(enemy.maxHP, enemy.hp + heal)
            result = tostring(damage) .. " FEL DRAIN"
        elseif mechanic == "WEB" and turn % 3 == 0 then
            local bound
            for _, minion in ipairs(self.minions or {}) do
                if not minion.webbedTurns or minion.webbedTurns <= 0 then minion.webbedTurns = 1; bound = minion; break end
            end
            if bound then self:AddLog(bound.name .. " is trapped in Royal Webbing for one attack.") else enemy.webbedHero = true; self:AddLog("Royal Webbing weakens your next attack.") end
        elseif mechanic == "FROST" and turn % 3 == 0 then
            enemy.frozenHero = true
            self:AddLog("Coldgrave freezes your next attack.")
        elseif mechanic == "BOMB" then
            if turn % 4 == 1 then enemy.bombTimer = 2; self:AddLog("WARNING: Blackfuse plants a bomb. Detonation in two turns.")
            elseif enemy.bombTimer then
                enemy.bombTimer = enemy.bombTimer - 1
                if enemy.bombTimer <= 0 then damage = damage + 5; result = tostring(damage) .. " BOMB"; enemy.bombTimer = nil end
            end
        elseif mechanic == "PHASE" then
            if enemy.ambushReady then damage = damage + 3; enemy.ambushReady = false; result = tostring(damage) .. " PHASE AMBUSH"
            elseif turn % 4 == 0 then enemy.phased = true; self:AddLog("Vaelrix phases out and will avoid the next strike.") end
        elseif mechanic == "WINDS" and turn % 3 == 0 then
            enemy.windStacks = min(3, (enemy.windStacks or 0) + 1)
            enemy.attack = (enemy.baseAttack or enemy.attack or 1) + enemy.windStacks
            self:AddLog("War Winds rise: Skyrend gains +1 Attack (" .. tostring(enemy.windStacks) .. "/3).")
        elseif mechanic == "SOUL" and turn % 4 == 0 then
            self:SummonBossAdd("Forsaken Soul Echo", max(5, floor(enemy.maxHP * 0.08)), max(1, floor(enemy.attack / 2)), "shade")
        elseif mechanic == "STEAL" and turn % 4 == 0 then
            if (self.attack or 1) > 1 then self.attack = self.attack - 1; enemy.attack = enemy.attack + 1; self:AddLog("Spell Theft steals 1 Attack from your hero.") end
        elseif mechanic == "BARK" and turn % 4 == 0 then
            enemy.armourLayers = min(3, (enemy.armourLayers or 0) + 1)
            enemy.hp = min(enemy.maxHP, enemy.hp + 3)
            self:AddLog("Ancient Bark regenerates one armour layer and 3 HP.")
        elseif mechanic == "MANA" and (enemy.arcaneCharges or 0) >= 2 then
            damage = damage + enemy.arcaneCharges * 2
            result = tostring(damage) .. " ARCANE DISCHARGE"
            enemy.arcaneCharges = 0
        elseif mechanic == "MODES" then
            local modes = { "ARMOUR", "ASSAULT", "REPAIR" }
            local index = (turn % 3) + 1
            enemy.mode = modes[index]
            if enemy.mode == "ASSAULT" then damage = damage + 3; result = tostring(damage) .. " ASSAULT MODE"
            elseif enemy.mode == "REPAIR" then enemy.hp = min(enemy.maxHP, enemy.hp + 4); self:AddLog("Omega-Reaver repairs 4 HP.") end
        elseif mechanic == "ARENA" and turn % 3 == 0 then
            damage = damage * 2
            result = tostring(damage) .. " DOUBLE TAP"
        elseif mechanic == "CATS" then
            if enemy.laserReady then damage = damage + 6 + (enemy.phase or 1); enemy.laserReady = false; result = tostring(damage) .. " BASE LASER"
            elseif turn % 3 == 2 then enemy.laserReady = true; self:AddLog("WARNING: CATS charges the Base Laser.") end
        end
        return damage, result
    end

    function view:GenerateRoom(isRetry)
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local bossRoom = content and type(content.IsBossLevel) == "function" and content:IsBossLevel(self.room) or self.room % 10 == 0
        local count = bossRoom and 1 or self.rng:Next(3)
        if bossRoom and not isRetry then self:CreateBossCheckpoint() end
        self.enemies = {}
        for i = 1, count do self.enemies[i] = dungeonEnemy(self.room, i, bossRoom and i == 1, self.rng) end
        self.targetIndex = 1
        self.roomCleared = false
        self.upgradePoints = 0
        self.pendingUpgrade = false
        self.minionOffer = nil
        self.lastPlayerRoll, self.lastEnemyRoll = nil, nil
        local boss = bossRoom and self.enemies[1] or nil
        self.lastDiceDetail = boss and ((boss.abilityName or "Boss mechanic") .. ": " .. (boss.abilityDescription or "Defeat the guardian to descend.")) or "Each attack rolls once for you and once for every minion."
        self:AddLog((bossRoom and ("MILESTONE BOSS " .. tostring(self.room) .. ": " .. tostring(boss and boss.name or "Guardian") .. ". ") or "Room entered: ") .. tostring(count) .. " enem" .. (count == 1 and "y." or "ies."))
        if boss and boss.abilityDescription then self:AddLog((boss.abilityName or "Boss ability") .. ": " .. boss.abilityDescription) end
        self:Refresh()
    end

    function view:OfferMinion()
        local chance = self.room % 10 == 0 and 100 or min(58, 18 + floor(self.room / 3))
        if self.rng:Next(100) <= chance then
            self.minionOffer = dungeonMinion(self.room, self.rng)
            local passPower = self:GetArmourStats().passMinionPower or 0
            if passPower > 0 then self.minionOffer.power = (self.minionOffer.power or 1) + passPower end
            self:AddLog(self.minionOffer.name .. " offers to join. Spend an upgrade point to recruit or replace.")
        end
    end

    function view:AddCoins(amount, reason)
        amount = max(0, floor(tonumber(amount) or 0))
        local coinBonus = self:GetArmourStats().passCoinBonus or 0
        if amount > 0 and coinBonus > 0 then amount = amount + floor((amount * coinBonus) / 100 + 0.5) end
        if amount <= 0 then return 0 end
        if CC.BattlePass and CC.BattlePass.AddCoins then
            CC.BattlePass:AddCoins(amount, reason or "GAME")
            if CC.BattlePass.RefreshDrawer then CC.BattlePass:RefreshDrawer() end
        end
        return amount
    end

    function view:HasPendingCrate()
        return self.activeCrate ~= nil or #(self.pendingCrates or {}) > 0
    end

    function view:TryPurchaseArmourWithShards()
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        if not content or not save or not save.dungeon then return nil end
        local threshold = (content.pity and content.pity.shardsForArmour) or 10
        if (save.dungeon.armourShards or 0) < threshold then return nil end
        local classKey = upper(tostring(self.classKey or "PALADIN"))
        for _, set in ipairs(content:GetEligibleArmour(classKey, 5)) do
            if not save.dungeon.unlockedArmour[set.key] then
                save.dungeon.armourShards = save.dungeon.armourShards - threshold
                save.dungeon.unlockedArmour[set.key] = true
                if not save.dungeon.equippedArmour[classKey] then save.dungeon.equippedArmour[classKey] = set.key end
                self:AddLog("ARMOUR SHARD PURCHASE: " .. set.name .. ".")
                return set
            end
        end
        return nil
    end

    function view:QueueBossCrate(crateKey, boss, rewardParts, sourceLabel)
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        local crate = content and content:GetCrate(crateKey) or nil
        if not crate or not save or not save.dungeon then return nil end
        save.dungeon.pendingCrates = type(save.dungeon.pendingCrates) == "table" and save.dungeon.pendingCrates or {}
        self.pendingCrates = save.dungeon.pendingCrates
        local drop = {
            key = crate.key,
            level = self.room or 1,
            bossKey = boss and boss.bossKey or "",
            bossName = boss and boss.name or "Dungeon encounter",
            tierMax = (boss and boss.bossDefinition and boss.bossDefinition.armourTierMax) or max(1, min(5, floor((self.room or 1) / 20) + 1)),
            source = sourceLabel or (boss and (boss.name .. " · Level " .. tostring(self.room or 1)) or ("Dungeon level " .. tostring(self.room or 1))),
            classKey = upper(tostring(self.classKey or "PALADIN")),
        }
        self.pendingCrates[#self.pendingCrates + 1] = drop
        save.dungeon.crateInventory[crate.key] = (save.dungeon.crateInventory[crate.key] or 0) + 1
        if rewardParts then rewardParts[#rewardParts + 1] = crate.name .. " dropped" end
        return crate
    end

    function view:FindCrateArmourChoice(maxTier)
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        if not content or not save or not save.dungeon then return nil end
        local classKey = upper(tostring(self.classKey or "PALADIN"))
        local missing = {}
        for _, set in ipairs(content:GetEligibleArmour(classKey, maxTier or 1)) do
            if not save.dungeon.unlockedArmour[set.key] then missing[#missing + 1] = set end
        end
        if #missing == 0 then return nil end
        return missing[self.rng:Next(#missing)]
    end

    function view:BuildCrateChoices(drop)
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local crate = content and content:GetCrate(drop and drop.key) or nil
        if not crate then return {} end
        local quality = ({ COMMON = 1, UNCOMMON = 2, RARE = 3, EPIC = 4 })[upper(tostring(crate.rarity or "COMMON"))] or 1
        local coinAmount = crate.coinMin + self.rng:Next(max(1, crate.coinMax - crate.coinMin + 1)) - 1
        local choices = {
            {
                type = "COINS", amount = coinAmount,
                title = "CRESH COIN CACHE", reward = "+" .. tostring(coinAmount) .. " COINS",
                detail = "Spend these across CreshChat unlocks and Battle Pass rewards.",
            },
        }
        if self.rng:Next(100) <= (crate.damageChance or 0) then
            local amount = quality >= 4 and 2 or 1
            choices[2] = {
                type = "DAMAGE", amount = amount,
                title = "DAMAGE RELIC", reward = "+" .. tostring(amount) .. " PERMANENT ATK",
                detail = "Permanently increases the starting Attack of every future Dungeon run.",
            }
        else
            local amount = quality + (quality >= 3 and 1 or 0)
            choices[2] = {
                type = "SHARDS", amount = amount,
                title = "ARMOUR SHARDS", reward = "+" .. tostring(amount) .. " SHARDS",
                detail = "Collect 10 shards to automatically unlock a missing class armour set.",
            }
        end
        local rareRoll = self.rng:Next(100)
        local fullBodyEnd = crate.fullBodyChance or 0
        local portraitEnd = fullBodyEnd + (crate.portraitChance or 0)
        local armourEnd = portraitEnd + (crate.armourChance or 0)
        if rareRoll <= fullBodyEnd then
            choices[3] = {
                type = "FULLBODY", amount = 1,
                title = "FULL-BODY TOKEN", reward = "+1 PROFILE SKIN TOKEN",
                detail = "Reserved for a future custom full-body Dungeon profile image.",
            }
        elseif rareRoll <= portraitEnd then
            choices[3] = {
                type = "PORTRAIT", amount = 1,
                title = "PORTRAIT TOKEN", reward = "+1 PROFILE ICON TOKEN",
                detail = "Reserved for a future custom Dungeon player-profile portrait.",
            }
        elseif rareRoll <= armourEnd then
            local set = self:FindCrateArmourChoice(drop.tierMax or 1)
            if set then
                choices[3] = {
                    type = "ARMOUR", amount = 1, set = set, tier = set.tier,
                    title = "CLASS ARMOUR", reward = upper(set.name),
                    detail = "Unlock this Tier " .. tostring(set.tier or 1) .. " " .. tostring(set.className or "class") .. " armour loadout.",
                }
            end
        end
        if not choices[3] then
            if choices[2].type == "SHARDS" then
                local bonus = floor(coinAmount * (1.25 + quality * 0.15) + 0.5)
                choices[3] = {
                    type = "COINS", amount = bonus,
                    title = "GILDED COIN CACHE", reward = "+" .. tostring(bonus) .. " COINS",
                    detail = "A larger coin payout generated by this chest's quality.",
                }
            else
                local amount = quality + 1
                choices[3] = {
                    type = "SHARDS", amount = amount,
                    title = "ENCHANTED SHARDS", reward = "+" .. tostring(amount) .. " SHARDS",
                    detail = "A stronger armour-shard bundle from a higher-quality chest.",
                }
            end
        end
        return choices
    end

    function view:ShowNextCrate()
        if self.activeCrate or #(self.pendingCrates or {}) == 0 then return end
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        self.activeCrate = self.pendingCrates[1]
        self.crateChoices = nil
        self.crateRevealed = false
        local crate = content and content:GetCrate(self.activeCrate.key) or nil
        if not crate then table.remove(self.pendingCrates, 1); self.activeCrate = nil; return self:ShowNextCrate() end
        if self.classPicker then self.classPicker:Hide() end
        if self.armourPicker then self.armourPicker:Hide() end
        self.crateTitle:SetText("CHEST DROPPED")
        self.crateName:SetText(upper(crate.name))
        self.crateRarity:SetText(upper(crate.rarity or "CHEST") .. " · CHOOSE ONE GENERATED REWARD")
        self.crateDescription:SetText(crate.description or "Open this chest to reveal three possible rewards.")
        self.crateSource:SetText("DROPPED BY: " .. upper(self.activeCrate.source or "DUNGEON ENCOUNTER"))
        self.crateOdds:SetText(format("COINS %d–%d · DAMAGE %d%% · ARMOUR %d%% · PORTRAIT %d%% · FULL BODY %d%%", crate.coinMin or 0, crate.coinMax or 0, crate.damageChance or 0, crate.armourChance or 0, crate.portraitChance or 0, crate.fullBodyChance or 0))
        local milestoneChest = content and content:GetMilestoneChest(self.activeCrate.level or self.room or 1) or nil
        dungeonSetTexture(self.crateArt, (milestoneChest and milestoneChest.display) or crate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        dungeonSetTexture(self.crateBadge, (milestoneChest and milestoneChest.icon) or crate.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        self.crateOpenButton:Show()
        self.crateInstruction:SetText("Press Space/Enter to open · after opening choose one reward")
        for _, card in ipairs(self.crateChoiceCards or {}) do card.rewardChoice = nil; card:Hide() end
        self.crateBlocker:Show()
        self:AddLog("CHEST DROPPED: " .. crate.name .. ". Open it and choose one reward.")
        self:Refresh()
    end

    function view:RevealActiveCrate()
        if not self.activeCrate or self.crateRevealed then return end
        self.crateChoices = self:BuildCrateChoices(self.activeCrate)
        self.crateRevealed = true
        self.crateTitle:SetText("CHOOSE ONE REWARD")
        self.crateOpenButton:Hide()
        self.crateInstruction:SetText("Click a card or press 1, 2 or 3 · unselected rewards are discarded")
        for index, card in ipairs(self.crateChoiceCards or {}) do
            local choice = self.crateChoices[index]
            card.rewardChoice = choice
            if choice then
                card.title:SetText(choice.title or "REWARD")
                card.reward:SetText(choice.reward or "REWARD")
                card.detail:SetText(choice.detail or "Select this reward.")
                local rewardAsset = content and content:GetRewardIcon(choice.type) or nil
                local rewardTexture = choice.type == "ARMOUR" and choice.set and choice.set.icon or (rewardAsset and rewardAsset.icon)
                dungeonSetTexture(card.icon, rewardTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
                card:Show()
            else
                card:Hide()
            end
        end
    end

    function view:ClaimCrateChoice(index)
        if not self.activeCrate or not self.crateRevealed then return end
        local choice = self.crateChoices and self.crateChoices[tonumber(index) or 0]
        if not choice then return end
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        local crate = content and content:GetCrate(self.activeCrate.key) or nil
        if not save or not save.dungeon or not crate then return end
        local rewardText = choice.reward or choice.title or "Chest reward"
        if choice.type == "COINS" then
            self:AddCoins(choice.amount or 0, "DUNGEON_CRATE_CHOICE")
        elseif choice.type == "DAMAGE" then
            local amount = max(1, floor(tonumber(choice.amount) or 1))
            save.dungeon.permanentDamage = (save.dungeon.permanentDamage or 0) + amount
            self.attack = (self.attack or 1) + amount
        elseif choice.type == "SHARDS" then
            save.dungeon.armourShards = (save.dungeon.armourShards or 0) + max(1, floor(tonumber(choice.amount) or 1))
            local purchased = self:TryPurchaseArmourWithShards()
            if purchased then rewardText = rewardText .. " · unlocked " .. purchased.name end
        elseif choice.type == "PORTRAIT" then
            save.dungeon.portraitTokens = (save.dungeon.portraitTokens or 0) + 1
        elseif choice.type == "FULLBODY" then
            save.dungeon.fullBodyTokens = (save.dungeon.fullBodyTokens or 0) + 1
        elseif choice.type == "ARMOUR" then
            local set, unlocked = self:AwardArmour(choice.tier or self.activeCrate.tierMax or 1, crate.name .. " choice", choice.tier)
            if unlocked and set then rewardText = "UNLOCKED " .. upper(set.name) end
        end
        save.dungeon.crateHistory[#save.dungeon.crateHistory + 1] = {
            key = crate.key, level = self.activeCrate.level or self.room, boss = self.activeCrate.bossKey or "",
            openedAt = type(time) == "function" and time() or 0,
            reward = choice.type, rewardLabel = rewardText,
        }
        while #save.dungeon.crateHistory > 40 do table.remove(save.dungeon.crateHistory, 1) end
        self:AddLog("CHEST CLAIMED: " .. crate.name .. " → " .. rewardText .. ".")
        if CC.UI and CC.UI.ShowGameToast then CC.UI:ShowGameToast(crate.name, rewardText, "SUCCESS", "DUNGEONCRATE:" .. tostring(crate.key or crate.name)) end
        if self.pendingCrates and self.pendingCrates[1] == self.activeCrate then table.remove(self.pendingCrates, 1) end
        self.activeCrate, self.crateChoices, self.crateRevealed = nil, nil, false
        self.crateBlocker:Hide()
        if #(self.pendingCrates or {}) > 0 then self:ShowNextCrate() else self:Refresh() end
    end

    function view:AwardArmour(maxTier, sourceLabel, exactTier)
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local save = ensureSave()
        if not content or not save or not save.dungeon then return nil, false end
        local classKey = upper(tostring(self.classKey or "PALADIN"))
        local candidates = {}
        if exactTier then
            local exact = content:GetArmourByTier(classKey, exactTier)
            if exact then candidates[1] = exact end
        else
            for _, set in ipairs(content:GetEligibleArmour(classKey, maxTier or 1)) do candidates[#candidates + 1] = set end
            table.sort(candidates, function(a, b) return (a.tier or 0) > (b.tier or 0) end)
        end
        for _, set in ipairs(candidates) do
            if not save.dungeon.unlockedArmour[set.key] then
                save.dungeon.unlockedArmour[set.key] = true
                if not save.dungeon.equippedArmour[classKey] then
                    save.dungeon.equippedArmour[classKey] = set.key
                    self:AddLog("ARMOUR UNLOCKED + AUTO-EQUIPPED FOR NEXT RUN: " .. set.name .. ".")
                else
                    self:AddLog("ARMOUR UNLOCKED: " .. set.name .. " (" .. tostring(sourceLabel or "Boss") .. ").")
                end
                return set, true
            end
        end
        local pity = content.pity or {}
        local shards = pity.duplicateArmourShards or 2
        save.dungeon.armourShards = (save.dungeon.armourShards or 0) + shards
        self:AddLog("Duplicate armour converted into " .. tostring(shards) .. " Armour Shards.")
        local purchased = self:TryPurchaseArmourWithShards()
        if purchased then return purchased, true end
        return nil, false
    end

    function view:SelectBossCrate(boss)
        local definition = boss and boss.bossDefinition or nil
        local weights = definition and definition.crateWeights or { ADVENTURER = 70, WARBOUND = 20, ROYAL = 9, VOID = 1 }
        local save = ensureSave()
        local content = DUNGEON_CONTENT or CC.DungeonCrawlerContent or _G.CreshGamesDungeonCrawlerContent
        local pity = content and content.pity or {}
        if save and save.dungeon and (save.dungeon.voidCratePity or 0) >= ((pity.voidCrates or 10) - 1) then return "VOID" end
        local roll = self.rng:Next(100)
        local cursor = weights.ADVENTURER or 0
        if roll <= cursor then return "ADVENTURER" end
        cursor = cursor + (weights.WARBOUND or 0)
        if roll <= cursor then return "WARBOUND" end
        cursor = cursor + (weights.ROYAL or 0)
        if roll <= cursor then return "ROYAL" end
        return "VOID"
    end

    function view:ApplyFirstBossReward(boss, rewardParts)
        local definition, save = boss and boss.bossDefinition, ensureSave()
        if not definition or not save or not save.dungeon or save.dungeon.firstBossKills[definition.key] then return end
        save.dungeon.firstBossKills[definition.key] = true
        local reward = definition.firstKill or {}
        if reward.type == "DAMAGE" then
            local amount = tonumber(reward.value) or 1
            save.dungeon.permanentDamage = (save.dungeon.permanentDamage or 0) + amount
            self.attack = (self.attack or 1) + amount
            rewardParts[#rewardParts + 1] = reward.label or ("+" .. tostring(amount) .. " permanent damage")
        elseif reward.type == "COINS" then
            local amount = tonumber(reward.value) or 0
            self:AddCoins(amount, "DUNGEON_FIRST_KILL")
            rewardParts[#rewardParts + 1] = reward.label or (tostring(amount) .. " coins")
        elseif reward.type == "CRATE" then
            self:QueueBossCrate(tostring(reward.value or "ADVENTURER"), boss, rewardParts, "First defeat of " .. tostring(boss.name or "milestone boss"))
        elseif reward.type == "ARMOUR" then
            local set, unlocked = self:AwardArmour(tonumber(reward.value) or 1, "First kill", tonumber(reward.value) or 1)
            if unlocked and set then rewardParts[#rewardParts + 1] = set.name end
        elseif reward.type == "SHARDS" then
            local amount = tonumber(reward.value) or 1
            save.dungeon.armourShards = (save.dungeon.armourShards or 0) + amount
            rewardParts[#rewardParts + 1] = reward.label or (tostring(amount) .. " Armour Shards")
        elseif reward.type == "PORTRAIT_TOKEN" then
            local amount = tonumber(reward.value) or 1
            save.dungeon.portraitTokens = (save.dungeon.portraitTokens or 0) + amount
            rewardParts[#rewardParts + 1] = reward.label or "portrait token"
        elseif reward.type == "FULLBODY_TOKEN" then
            local amount = tonumber(reward.value) or 1
            save.dungeon.fullBodyTokens = (save.dungeon.fullBodyTokens or 0) + amount
            rewardParts[#rewardParts + 1] = reward.label or "full-body token"
        end
    end

    function view:AwardBossReward(enemy)
        if not enemy or not enemy.boss or enemy.creshRewarded then return end
        enemy.creshRewarded = true
        self.bossRetryAvailable = false
        local definition = enemy.bossDefinition or {}
        local class = self:GetClassData()
        local rewardParts = {}
        local coinMin, coinMax = tonumber(definition.coinMin) or 10, tonumber(definition.coinMax) or 20
        local coins = coinMin + self.rng:Next(max(1, coinMax - coinMin + 1)) - 1
        self:AddCoins(coins, "DUNGEON_BOSS")
        rewardParts[#rewardParts + 1] = "+" .. tostring(coins) .. " boss coins"
        local hpBonus, attackBonus = class.bossHP or 2, class.bossAttack or 1
        self.maxHP = (self.maxHP or 1) + hpBonus
        self.attack = (self.attack or 1) + attackBonus
        self.hp = class.bossFullHeal and self.maxHP or min(self.maxHP, (self.hp or 0) + (class.bossHeal or 4) + hpBonus)
        if (class.bossMinionBonus or 0) > 0 then for _, minion in ipairs(self.minions or {}) do minion.power = (minion.power or 1) + class.bossMinionBonus end end
        local save = ensureSave()
        if save and save.dungeon then
            save.dungeon.bossCoins = (save.dungeon.bossCoins or 0) + coins
            save.dungeon.bossKillsByType[enemy.bossKey or enemy.name] = (save.dungeon.bossKillsByType[enemy.bossKey or enemy.name] or 0) + 1
        end
        local crateKey = self:SelectBossCrate(enemy)
        self:QueueBossCrate(crateKey, enemy, rewardParts, enemy.name .. " · Milestone " .. tostring(self.room or 1))
        if save and save.dungeon then
            if crateKey == "VOID" then save.dungeon.voidCratePity = 0 else save.dungeon.voidCratePity = (save.dungeon.voidCratePity or 0) + 1 end
            local forceArmour = (save.dungeon.armourPity or 0) >= 4
            local armourRoll = forceArmour or self.rng:Next(100) <= (tonumber(definition.armourChance) or 0)
            if armourRoll then
                local set, unlocked = self:AwardArmour(definition.armourTierMax or 1, forceArmour and "Armour pity" or "Boss drop")
                save.dungeon.armourPity = 0
                if unlocked and set then rewardParts[#rewardParts + 1] = set.name end
            else
                save.dungeon.armourPity = (save.dungeon.armourPity or 0) + 1
            end
        end
        self:ApplyFirstBossReward(enemy, rewardParts)
        self:AddLog("BOSS REWARDS: " .. concat(rewardParts, " · ") .. ".")
        if CC.UI and CC.UI.ShowGameToast then CC.UI:ShowGameToast("Milestone Boss Defeated", concat(rewardParts, " · "), "SUCCESS", "DUNGEONBOSS:" .. tostring(self.room or time())) end
        self:ShowNextCrate()
    end

    function view:RecordDefeat(enemy, source)
        if not enemy or not enemy.alive then return false end
        enemy.alive = false
        self.kills = self.kills + 1
        self.score = self.score + 10 + self.room + (enemy.boss and 50 or 0)
        self.upgradePoints = (self.upgradePoints or 0) + 1
        self.pendingUpgrade = true
        self:AddLog(enemy.name .. " is defeated by " .. tostring(source or "your party") .. ". Upgrade point earned.")
        local save = ensureSave()
        if save then
            save.dungeon.kills = (save.dungeon.kills or 0) + 1
            save.dungeon.highScore = max(save.dungeon.highScore or 0, self.score)
            if enemy.boss then save.dungeon.bosses = (save.dungeon.bosses or 0) + 1 end
            local stat = self:GetClassStat(self.classKey)
            if stat then
                stat.kills = (stat.kills or 0) + 1
                if enemy.boss then stat.bosses = (stat.bosses or 0) + 1 end
                stat.maxRoom = max(stat.maxRoom or 0, self.room or 1)
                stat.highScore = max(stat.highScore or 0, self.score or 0)
            end
            if enemy.contentKey then
                save.dungeon.enemyKillsByType = type(save.dungeon.enemyKillsByType) == "table" and save.dungeon.enemyKillsByType or {}
                save.dungeon.enemyKillsByType[enemy.contentKey] = (save.dungeon.enemyKillsByType[enemy.contentKey] or 0) + 1
            end
        end
        if CC.DungeonDwellersPass and CC.DungeonDwellersPass.RecordDungeonKill then
            CC.DungeonDwellersPass:RecordDungeonKill(enemy.boss == true)
        end
        if enemy.boss then self.pendingBossReward = enemy end
        if self:LivingEnemies() == 0 then
            self.roomCleared = true
            if self.pendingBossReward then
                self:AwardBossReward(self.pendingBossReward)
                self.pendingBossReward = nil
                self.bossCheckpoint, self.bossRetryAvailable = nil, false
            end
            local class = self:GetClassData()
            local armourStats = self:GetArmourStats()
            local roomRecovery = (enemy.boss and 0 or (class.roomHeal or 0)) + (armourStats.regenRoom or 0)
            if roomRecovery > 0 then
                local before = self.hp or 0
                self.hp = min(self.maxHP, before + roomRecovery)
                if self.hp > before then self:AddLog((self.equippedArmour and self.equippedArmour.name or class.name) .. " restores " .. tostring(self.hp - before) .. " HP after clearing the room.") end
            end
            self:OfferMinion()
        else
            self:SelectLiving(1)
        end
        return true
    end

    function view:DamageEnemy(enemy, damage, source)
        if not enemy or not enemy.alive then return false end
        enemy.hp = max(0, enemy.hp - max(1, floor(damage or 1)))
        if enemy.hp <= 0 then return self:RecordDefeat(enemy, source) end
        return false
    end

    function view:TryApplyArmourBleed(enemy, details)
        local stats = self:GetArmourStats()
        if not enemy or not enemy.alive or (stats.bleedChance or 0) <= 0 then return false end
        if self.rng:Next(100) > stats.bleedChance then return false end
        enemy.bleedDamage = max(enemy.bleedDamage or 0, stats.bleedDamage or 1)
        enemy.bleedTurns = max(enemy.bleedTurns or 0, stats.bleedTurns or 1)
        if details then details[#details + 1] = enemy.name .. " BLEEDS " .. tostring(enemy.bleedDamage) .. " for " .. tostring(enemy.bleedTurns) .. " turns" end
        return true
    end

    function view:TickArmourBleeds()
        local ticks, defeated = {}, 0
        for _, enemy in ipairs(self.enemies or {}) do
            if enemy.alive and (enemy.bleedTurns or 0) > 0 then
                local amount = max(1, floor(enemy.bleedDamage or 1))
                enemy.bleedTurns = max(0, enemy.bleedTurns - 1)
                ticks[#ticks + 1] = enemy.name .. " -" .. tostring(amount)
                if self:DamageEnemy(enemy, amount, "bleed") then defeated = defeated + 1 end
            end
        end
        if #ticks > 0 then self:AddLog("BLEED: " .. concat(ticks, " · ") .. ".") end
        if defeated > 0 or self.roomCleared or self.pendingUpgrade then
            self:Refresh()
            return true
        end
        return false
    end

    function view:EnemyTurn()
        if self.dead then return end
        if self:TickArmourBleeds() then return end
        local class = self:GetClassData()
        local armour = self:GetArmourStats()
        local totalDamage, rolls, enemyVisualRolls = 0, {}, {}
        local evadeChance = min(60, (class.evadeChance or 0) + (armour.evadeChance or 0))
        local flatBlock = (class.flatBlock or 0) + (armour.flatBlock or 0)
        local blockChance = min(75, (class.blockChance or 0) + (armour.blockChance or 0))
        local blockAmount = (class.blockAmount or 1) + (armour.blockAmount or 0)
        for _, enemy in ipairs(self.enemies) do
            if enemy.alive then
                local sides = enemy.boss and 8 or 6
                local roll = self.rng:Next(sides)
                enemy.lastRoll = roll
                enemyVisualRolls[#enemyVisualRolls + 1] = roll
                local damage = 0
                local result = "miss"
                if roll >= 3 then
                    damage = max(1, floor((roll + enemy.attack) / 3))
                    if evadeChance > 0 and self.rng:Next(100) <= evadeChance then
                        damage, result = 0, "evaded"
                    else
                        damage = max(0, damage - flatBlock)
                        if damage > 0 and blockChance > 0 and self.rng:Next(100) <= blockChance then
                            damage = max(0, damage - blockAmount)
                            result = damage > 0 and (tostring(damage) .. " after block") or "blocked"
                        else
                            result = damage > 0 and tostring(damage) or "blocked"
                        end
                    end
                end
                if enemy.boss then damage, result = self:BossTurnEffects(enemy, damage, result) end
                totalDamage = totalDamage + damage
                rolls[#rolls + 1] = enemy.name .. " " .. tostring(roll) .. " (" .. result .. ")"
            end
        end
        self.lastEnemyRoll = #rolls > 0 and string.match(rolls[1], " (%d+)") or "–"
        self:StartDiceAnimation(nil, enemyVisualRolls[1])
        self.hp = max(0, self.hp - totalDamage)
        self.lastDiceDetail = concat(rolls, " · ")
        if totalDamage > 0 then self:AddLog("Enemies deal " .. tostring(totalDamage) .. " total damage.") else self:AddLog("Your class and armour avoid all incoming damage.") end
        if self.hp <= 0 then
            self:Die()
        else
            local regen = max(0, floor(armour.regenTurn or 0))
            if regen > 0 then
                local before = self.hp
                self.hp = min(self.maxHP, self.hp + regen)
                if self.hp > before then self:AddLog((self.equippedArmour and self.equippedArmour.name or "Armour") .. " regenerates " .. tostring(self.hp - before) .. " HP.") end
            end
            self:Refresh()
        end
    end

    function view:PlayerAttack()
        if self.rolling or self.dead or self.pendingUpgrade or self.roomCleared then return end
        local enemy = self.enemies[self.targetIndex]
        if not enemy or not enemy.alive then self:SelectLiving(1); enemy = self.enemies[self.targetIndex] end
        if not enemy or not enemy.alive then return end

        local class = self:GetClassData()
        local armour = self:GetArmourStats()
        local rolls, details, visualRolls, defeated = {}, {}, {}, 0
        local heroDice = 1 + max(0, floor(armour.extraDice or 0))
        if (armour.extraDieChance or 0) > 0 and self.rng:Next(100) <= armour.extraDieChance then
            heroDice = heroDice + 1
            details[#details + 1] = "Armour grants a bonus die"
        end
        for dieIndex = 1, heroDice do
            local target = dieIndex == 1 and enemy or self:RandomLivingEnemy()
            if target and target.alive then
                local roll = self.rng:Next(class.attackDie or 6)
                local damage = max(1, roll + floor((self.attack - 1) / 2) + (class.flatDamage or 0))
                local effect = dieIndex > 1 and " BONUS DIE" or ""
                if dieIndex > 1 then damage = max(1, floor(damage * (armour.extraDiePower or 65) / 100 + 0.5)) end
                if target.boss then
                    damage = damage + (class.bossDamage or 0) + (armour.bossDamage or 0)
                    if (class.bossDamage or 0) + (armour.bossDamage or 0) > 0 then effect = effect .. " boss bonus" end
                end
                if self:LivingEnemies() > 1 and (class.multiTargetBonus or 0) > 0 then damage = damage + class.multiTargetBonus; effect = effect .. " crowd bonus" end
                if class.critAt and roll >= class.critAt then damage = max(1, floor(damage * (class.critMultiplier or 1.5) + 0.5)); effect = effect .. " CRIT" end
                if class.burstAt and roll >= class.burstAt then damage = damage + (class.burstBonus or 1); effect = effect .. " ARCANE BURST" end
                if (armour.doubleDamageChance or 0) > 0 and self.rng:Next(100) <= armour.doubleDamageChance then
                    damage = damage * 2
                    effect = effect .. " DOUBLE DAMAGE"
                end
                rolls[#rolls + 1] = tostring(roll)
                visualRolls[#visualRolls + 1] = roll
                local bossNote
                damage, bossNote = self:ModifyBossIncomingDamage(target, roll, damage, dieIndex == 1 and "you" or "armour die")
                effect = effect .. (bossNote or "")
                details[#details + 1] = (dieIndex == 1 and "You " or ("Die " .. tostring(dieIndex) .. " ")) .. tostring(roll) .. " → " .. target.name .. " for " .. tostring(damage) .. effect
                if damage > 0 and self:DamageEnemy(target, damage, dieIndex == 1 and "you" or "bonus armour die") then
                    defeated = defeated + 1
                elseif damage > 0 then
                    self:TryApplyArmourBleed(target, details)
                end
                if target.boss and target.alive then self:AfterBossHit(target, roll) end
                if class.lifeStealAt and roll >= class.lifeStealAt and (self.hp or 0) > 0 then
                    local before = self.hp
                    self.hp = min(self.maxHP, self.hp + (class.lifeSteal or 1))
                    if self.hp > before then details[#details + 1] = "Life steal +" .. tostring(self.hp - before) .. " HP" end
                end
                if class.healOnAttackAt and roll >= class.healOnAttackAt and (self.hp or 0) > 0 then
                    local before = self.hp
                    self.hp = min(self.maxHP, self.hp + (class.healOnAttack or 1))
                    if self.hp > before then details[#details + 1] = "Holy recovery +" .. tostring(self.hp - before) .. " HP" end
                end
            end
        end

        for _, minion in ipairs(self.minions or {}) do
            local target = self:RandomLivingEnemy()
            if target then
                local minionRoll = self.rng:Next(6)
                local minionDamage = max(1, minionRoll + (minion.power or 1) - 2 + floor((minion.level or 1) / 3) + (class.minionBonus or 0) + (armour.minionBonus or 0))
                if (minion.webbedTurns or 0) > 0 then
                    minion.webbedTurns = minion.webbedTurns - 1
                    rolls[#rolls + 1] = "WEB"
                    visualRolls[#visualRolls + 1] = "WEB"
                    details[#details + 1] = minion.name .. " is trapped and cannot attack"
                else
                    local minionNote
                    minionDamage, minionNote = self:ModifyBossIncomingDamage(target, minionRoll, minionDamage, minion.name)
                    rolls[#rolls + 1] = tostring(minionRoll)
                    visualRolls[#visualRolls + 1] = minionRoll
                    details[#details + 1] = minion.name .. " " .. tostring(minionRoll) .. " → " .. target.name .. " for " .. tostring(minionDamage) .. (minionNote or "")
                    if minionDamage > 0 and self:DamageEnemy(target, minionDamage, minion.name) then defeated = defeated + 1 end
                    if target.boss and target.alive then self:AfterBossHit(target, minionRoll) end
                end
            end
        end

        self.lastPlayerRoll = concat(rolls, "+")
        self.lastDiceDetail = concat(details, " · ")
        self:AddLog(self.lastDiceDetail)
        self:StartDiceAnimation(visualRolls, nil)
        if defeated > 0 then
            self:Refresh()
        else
            self.pendingEnemyTurnDelay = 0.46
            self:Refresh()
        end
    end

    function view:UseMinionPoint()
        if self.minionOffer then
            local minion = self.minionOffer
            if #self.minions < 2 then
                self.minions[#self.minions + 1] = minion
                self:AddLog(minion.name .. " joins your party at level " .. tostring(minion.level) .. ".")
            else
                local index = self:WeakestMinionIndex() or 1
                local old = self.minions[index]
                self.minions[index] = minion
                self:AddLog(minion.name .. " replaces " .. tostring(old and old.name or "a minion") .. ".")
            end
            self.minionOffer = nil
            local save = ensureSave()
            if save then
                save.dungeon.minions = (save.dungeon.minions or 0) + 1
                save.dungeon.unlockedMinions = type(save.dungeon.unlockedMinions) == "table" and save.dungeon.unlockedMinions or {}
                save.dungeon.minionRecruitsByType = type(save.dungeon.minionRecruitsByType) == "table" and save.dungeon.minionRecruitsByType or {}
                save.dungeon.unlockedMinions[minion.kind or "Unknown"] = true
                save.dungeon.minionRecruitsByType[minion.kind or "Unknown"] = (save.dungeon.minionRecruitsByType[minion.kind or "Unknown"] or 0) + 1
                save.dungeon.unlockedMinionSkins = type(save.dungeon.unlockedMinionSkins) == "table" and save.dungeon.unlockedMinionSkins or {}
                save.dungeon.minionSkinRecruits = type(save.dungeon.minionSkinRecruits) == "table" and save.dungeon.minionSkinRecruits or {}
                if minion.assetKey then
                    save.dungeon.unlockedMinionSkins[minion.assetKey] = true
                    save.dungeon.minionSkinRecruits[minion.assetKey] = (save.dungeon.minionSkinRecruits[minion.assetKey] or 0) + 1
                end
            end
            return true
        end
        local index = self:WeakestMinionIndex()
        local minion = index and self.minions[index]
        if minion then
            minion.level = (minion.level or 1) + 1
            minion.power = (minion.power or 1) + 1
            self:AddLog(minion.name .. " improves to level " .. tostring(minion.level) .. " and +" .. tostring(minion.power) .. " damage.")
            return true
        end
        return false
    end

    function view:ChooseUpgrade(kind)
        if not self.pendingUpgrade or self.dead or (self.upgradePoints or 0) <= 0 then return end
        kind = upper(tostring(kind or ""))
        local spent = false
        local class = self:GetClassData()
        if kind == "HEALTH" then
            local gain = class.healthGain or 1
            local heal = class.healthHeal or 2
            self.maxHP = self.maxHP + gain
            self.hp = min(self.maxHP, self.hp + heal)
            self:AddLog(class.name .. " Health upgrade: +" .. tostring(gain) .. " Max HP and " .. tostring(heal) .. " HP recovered.")
            spent = true
        elseif kind == "ATTACK" then
            local gain = class.attackGain or 1
            self.attack = self.attack + gain
            self:AddLog(class.name .. " Attack upgrade: +" .. tostring(gain) .. " Attack.")
            spent = true
        elseif kind == "MINION" then
            spent = self:UseMinionPoint()
        end
        if not spent then return end
        self.upgradePoints = max(0, (self.upgradePoints or 0) - 1)
        self.pendingUpgrade = self.upgradePoints > 0
        if not self.pendingUpgrade and self.minionOffer then
            self:AddLog(self.minionOffer.name .. " disappears into the dungeon because no point was spent on it.")
            self.minionOffer = nil
        end
        if not self.pendingUpgrade and not self.roomCleared then self:EnemyTurn() else self:Refresh() end
    end

    function view:NextRoom()
        if self.dead then self:StartRun(); return end
        if not self.roomCleared or self.pendingUpgrade then return end
        self.room = self.room + 1
        local save = ensureSave()
        if save then
            save.dungeon.bestLevel = max(save.dungeon.bestLevel or 0, self.room)
            save.dungeon.bestRoom = max(save.dungeon.bestRoom or 0, self.room)
            local stat = self:GetClassStat(self.classKey)
            if stat then stat.maxRoom = max(stat.maxRoom or 0, self.room) end
        end
        self:GenerateRoom()
        Solo:SetStatus("Endless dungeon room " .. tostring(self.room) .. ".", self.room % 10 == 0 and colors.red or colors.gold)
    end

    function view:Die()
        if self.dead then return end
        self.dead = true
        local save = ensureSave()
        if save then
            save.dungeon.bestLevel = max(save.dungeon.bestLevel or 0, self.room or 1)
            save.dungeon.bestRoom = max(save.dungeon.bestRoom or 0, self.room or 1)
            save.dungeon.highScore = max(save.dungeon.highScore or 0, self.score or 0)
            local stat = self:GetClassStat(self.classKey)
            if stat then
                stat.maxRoom = max(stat.maxRoom or 0, self.room or 1)
                stat.highScore = max(stat.highScore or 0, self.score or 0)
                stat.deaths = (stat.deaths or 0) + 1
            end
        end
        local bossRoom = self.room % 10 == 0 and self.bossCheckpoint ~= nil
        self.bossRetryAvailable = bossRoom
        self:AddLog(bossRoom and "You were defeated by the milestone boss. Your boss checkpoint is ready." or "You were defeated. Your stats and minions are lost.")
        Solo:RecordHistory("DUNGEON", "SOLO", "RUN", "Dungeon", format("Room %d · %d kills · %d score", self.room or 1, self.kills or 0, self.score or 0), self.room or 1)
        Solo:PushLeaderboards()
        Solo:SetStatus(self.bossRetryAvailable and format("BOSS RETRY READY · Level %d", self.room or 10) or format("RUN OVER · Room %d · %d kills · %d score", self.room or 1, self.kills or 0, self.score or 0), colors.red)
        self:Refresh()
        Solo:RefreshHub()
    end

    function view:StartRun(reason, forceFresh)
        if self.dead and self.bossRetryAvailable and self.bossCheckpoint and not forceFresh then self:RetryBoss(); return end
        local save = ensureSave()
        if save then save.dungeon.runs = (save.dungeon.runs or 0) + 1 end
        local savedClass = save and save.dungeon and upper(tostring(save.dungeon.class or "")) or ""
        local hadSavedClass = DUNGEON_CLASSES[savedClass] ~= nil
        if not hadSavedClass then savedClass = dungeonDefaultClassKey() end
        self.classKey = savedClass
        if save and save.dungeon then save.dungeon.class = savedClass end
        local classStat = self:GetClassStat(savedClass)
        if classStat then classStat.runs = (classStat.runs or 0) + 1 end
        local class = self:ApplyClassVisuals()
        local armourStats = self:GetArmourStats()
        self.rng = makeRng(floor(now() * 1000) + ((save and save.dungeon.runs or 1) * 7919))
        self.room, self.kills, self.score = 1, 0, 0
        self.maxHP = class.baseHP + (armourStats.maxHP or 0)
        self.hp = self.maxHP
        self.attack = class.baseAttack + (save and save.dungeon and save.dungeon.permanentDamage or 0) + (armourStats.attack or 0)
        self.minions, self.minionOffer = {}, nil
        self.upgradePoints = 0
        self.dead, self.pendingUpgrade, self.roomCleared = false, false, false
        self.rolling, self.pendingEnemyTurnDelay, self.diceShakeRemaining = false, nil, 0
        self.lastHeroDiceValues, self.lastEnemyDieValue = nil, nil
        if self.RefreshDiceVisuals then self:RefreshDiceVisuals() end
        self.bossCheckpoint, self.bossRetryAvailable, self.pendingBossReward = nil, false, nil
        self.pendingCrates = save and save.dungeon and save.dungeon.pendingCrates or {}
        self.activeCrate, self.crateChoices, self.crateRevealed = nil, nil, false
        if self.crateBlocker then self.crateBlocker:Hide() end
        self.logLines = {}
        self:AddLog(reason or ("A fresh " .. class.name .. " run begins. " .. class.short .. "."))
        if self.equippedArmour then self:AddLog("EQUIPPED: " .. self.equippedArmour.name .. " · " .. dungeonArmourStatText(self.equippedArmour.stats) .. ".") end
        self:AddLog("Enemy health and damage now scale sharply with dungeon level. Bosses guard every 10th level and award crates, class armour, first-kill rewards and permanent relics.")
        self:GenerateRoom()
        self:RefreshClassPicker()
        if not hadSavedClass and not reason then self:ShowClassPicker() end
        if #(self.pendingCrates or {}) > 0 then self:ShowNextCrate() end
        Solo:SetStatus("Dungeon Dweller " .. class.name .. " run started. Roll to attack.", colors.green)
    end

    function view:OnKeyDown(key)
        if key == "ESCAPE" then
            if self.dwellersPanel and self.dwellersPanel:IsShown() then self.dwellersPanel:Hide(); return end
            if self.classPicker and self.classPicker:IsShown() then self.classPicker:Hide(); return end
            if self.armourPicker and self.armourPicker:IsShown() then self.armourPicker:Hide(); return end
        end
        if self:HasPendingCrate() then
            if not self.crateRevealed and (key == "SPACE" or key == "ENTER") then self:RevealActiveCrate()
            elseif self.crateRevealed and (key == "1" or key == "2" or key == "3") then self:ClaimCrateChoice(tonumber(key)) end
            return
        end
        if key == "R" and self.dead then self:StartRun(); return end
        if key == "C" then self:ShowClassPicker(); return end
        if key == "V" then self:ShowArmourPicker(); return end
        if key == "A" or key == "LEFT" then self:SelectLiving(-1)
        elseif key == "D" or key == "RIGHT" then self:SelectLiving(1)
        elseif self.pendingUpgrade and (key == "H" or key == "W" or key == "UP") then self:ChooseUpgrade("HEALTH")
        elseif self.pendingUpgrade and (key == "J" or key == "S" or key == "DOWN") then self:ChooseUpgrade("ATTACK")
        elseif self.pendingUpgrade and key == "M" then self:ChooseUpgrade("MINION")
        elseif key == "SPACE" or key == "ENTER" then
            if self.dead then self:StartRun()
            elseif self.roomCleared and not self.pendingUpgrade then self:NextRoom()
            elseif not self.pendingUpgrade then self:PlayerAttack() end
        end
    end

    function view:OnUpdate(elapsed)
        if not self.frame or not self.frame:IsShown() then return end
        elapsed = elapsed or 0
        if self.pendingEnemyTurnDelay then
            self.pendingEnemyTurnDelay = self.pendingEnemyTurnDelay - elapsed
            if self.pendingEnemyTurnDelay <= 0 then
                self.pendingEnemyTurnDelay = nil
                self:EnemyTurn()
            end
        end
        self.breathClock = (self.breathClock or 0) + elapsed
        self.breathStep = (self.breathStep or 0) + elapsed
        self.diceShakeClock = (self.diceShakeClock or 0) + elapsed
        if self.diceShakeRemaining and self.diceShakeRemaining > 0 then
            self.diceShakeRemaining = max(0, self.diceShakeRemaining - elapsed)
        end
        if self.breathStep < 0.035 then return end
        self.breathStep = 0
        for _, actor in ipairs(self.breathActors or {}) do
            if actor.frame and actor.frame:IsShown() then
                local offset = sin((self.breathClock * actor.speed * 2.0) + actor.phase) * actor.amplitude
                actor.frame:ClearAllPoints()
                actor.frame:SetPoint(actor.point, actor.relativeTo, actor.relativePoint, actor.x, actor.y + offset)
            end
        end
        local shaking = (self.diceShakeRemaining or 0) > 0
        local strength = shaking and min(1, (self.diceShakeRemaining or 0) / 0.44) or 0
        for index, die in ipairs(self.diceIcons or {}) do
            if die:IsShown() then
                local heroShaking = shaking and self.diceHeroRolling
                local dx = heroShaking and sin((self.diceShakeClock * 42) + index * 1.9) * 3.2 * strength or 0
                local dy = heroShaking and sin((self.diceShakeClock * 55) + index * 2.7) * 2.3 * strength or 0
                die:ClearAllPoints(); die:SetPoint("TOPLEFT", self.diceCard, "TOPLEFT", die.baseX + dx, die.baseY + dy)
            end
        end
        if self.enemyDie and self.enemyDie:IsShown() then
            local enemyShaking = shaking and self.diceEnemyRolling
            local dx = enemyShaking and sin((self.diceShakeClock * 47) + 0.8) * 3.0 * strength or 0
            local dy = enemyShaking and sin((self.diceShakeClock * 59) + 2.1) * 2.2 * strength or 0
            self.enemyDie:ClearAllPoints(); self.enemyDie:SetPoint("TOPLEFT", self.diceCard, "TOPLEFT", self.enemyDie.baseX + dx, self.enemyDie.baseY + dy)
        end
        self:RefreshDiceVisuals()
        if not shaking then self.diceHeroRolling, self.diceEnemyRolling = false, false end
        if not shaking and not self.pendingEnemyTurnDelay then self.rolling = false end
    end

    function view:Start() self:StartRun() end

    self.views.DUNGEON = view
    return view
end
function Solo:ApplyTheme()
    local colors = palette()
    if self.window then
        applyBackdrop(self.window, colors.panel, colors.border)
        applyBackdrop(self.window.header, colors.panelRaised, colors.border)
        applyBackdrop(self.window.statusBar, colors.panelSoft, colors.border)
        setButtonAccent(self.window.home, colors.accent)
        setButtonAccent(self.window.close, colors.red)
    end
    if self.hub then
        applyBackdrop(self.hub, colors.panelSoft, colors.panelSoft)
        applyBackdrop(self.hub.banner, darken(colors.accent, 0.30), colors.accent)
        if self.hub.historyButton then setButtonAccent(self.hub.historyButton, colors.muted) end
        if self.hub.leaderButton then setButtonAccent(self.hub.leaderButton, colors.gold) end
        for _, info in ipairs(self:GetCatalog()) do
            local card = self.hub.cards and self.hub.cards[info.key]
            if card then
                applyBackdrop(card, colors.panel, colors.border)
                if card.art then applyBackdrop(card.art, darken(info.accent, 0.42), info.accent) end
                if card.play then setButtonAccent(card.play, info.accent) end
            end
        end
    end
    if self.socialPanel then
        applyBackdrop(self.socialPanel, colors.panel, colors.border)
        applyBackdrop(self.socialPanel.columnHeader, colors.panelRaised, colors.border)
        setButtonAccent(self.socialPanel.close, colors.red)
        for _, box in pairs(self.socialPanel.summary or {}) do applyBackdrop(box, colors.panelSoft, colors.border) end
        self:RefreshSocialPanel()
    end
    local highLow = self.views and self.views.HIGHERLOWER
    if highLow then
        applyBackdrop(highLow.frame, colors.panelSoft, colors.panelSoft)
        applyBackdrop(highLow.table, darken(colors.green, 0.76), colors.green)
        applyBackdrop(highLow.controls, colors.panel, colors.border)
        setButtonAccent(highLow.higher, colors.green)
        setButtonAccent(highLow.lower, colors.red)
        setButtonAccent(highLow.next, colors.accent)
        setButtonAccent(highLow.betDown, colors.gold)
        setButtonAccent(highLow.betUp, colors.gold)
        setButtonAccent(highLow.reset, colors.accent)
    end
end
