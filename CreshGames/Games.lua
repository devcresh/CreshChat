local ADDON_NAME, CC = ...
if not CC then return end

local Games = {
    prefix = "CRESHGAME",
    protocol = 5,
    version = CC.version,
    peers = {},
    targetIndex = 1,
    targetName = nil,
    pendingIncoming = nil,
    pendingOutgoing = nil,
    active = nil,
    gameViews = {},
}
CC.Games = Games
if CC.RegisterModule then CC:RegisterModule("Games", Games) end

local floor, min, max, abs = math.floor, math.min, math.max, math.abs
local insert, remove, sort = table.insert, table.remove, table.sort
local lower, upper = string.lower, string.upper
local format = string.format
local unpack = unpack or table.unpack

local function now()
    if type(GetTime) == "function" then return GetTime() end
    if type(time) == "function" then return time() end
    return 0
end

local function stamp()
    if type(time) == "function" then return time() end
    return floor(now())
end

local function trim(value)
    local text = tostring(value or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    return max(low, min(high, value))
end

local function split(text, delimiter)
    text = tostring(text or "")
    delimiter = tostring(delimiter or "~")
    local output, startAt = {}, 1
    while true do
        local first, last = string.find(text, delimiter, startAt, true)
        if not first then
            output[#output + 1] = string.sub(text, startAt)
            break
        end
        output[#output + 1] = string.sub(text, startAt, first - 1)
        startAt = last + 1
    end
    return output
end

local function join(values, delimiter)
    local output = {}
    for index, value in ipairs(values or {}) do output[index] = tostring(value or "") end
    return table.concat(output, delimiter or "~")
end

local function shortName(name)
    if CC.ShortName then return CC:ShortName(name) end
    return tostring(name or "Unknown")
end

local function cleanName(name)
    if CC.CleanPlayerName then return CC:CleanPlayerName(name) end
    return trim(name)
end

local function samePlayer(left, right)
    if CC.WhisperNamesEquivalent then return CC:WhisperNamesEquivalent(left, right) end
    return lower(cleanName(left)) == lower(cleanName(right))
end

local function routeName(name)
    name = cleanName(name)
    if CC.GetWhisperRoute then return CC:GetWhisperRoute(name) or name end
    return name
end

local function safeCall(func, ...)
    if type(func) ~= "function" then return false end
    return pcall(func, ...)
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

local EIGHTBIT_GAME_ICON_ROOT = "Interface\\AddOns\\CreshGames\\Media\\Games\\Icons8Bit\\"

local GAME_NAMES = {
    CHESS = "Chess",
    TETRIS = "Tetris Versus",
    HOLDEM = "Texas Hold'em",
    PONG = "Pong",
}

function Games:GetCatalog()
    return {
        { key = "CHESS", title = "Chess", description = "Labelled pieces · turn based · mouse or WASD", art = "WK  BQ", icon = EIGHTBIT_GAME_ICON_ROOT .. "Chess.tga" },
        { key = "TETRIS", title = "Tetris Versus", description = "Dual boards · Timed Endless or Endless Attack", art = "▦", icon = EIGHTBIT_GAME_ICON_ROOT .. "Tetris.tga" },
        { key = "HOLDEM", title = "Texas Hold'em", description = "Two-player heads-up poker with betting", art = "AS  KH", icon = EIGHTBIT_GAME_ICON_ROOT .. "Holdem.tga" },
        { key = "PONG", title = "Pong", description = "W/S paddle control · first to 5 points", art = "●", icon = EIGHTBIT_GAME_ICON_ROOT .. "Pong.tga" },
    }
end

function Games:GetGameName(game)
    return GAME_NAMES[upper(tostring(game or ""))] or tostring(game or "Game")
end

function Games:RegisterPrefix()
    if self.prefixRegistered then return true end
    local ok = false
    if _G.C_ChatInfo and type(_G.C_ChatInfo.RegisterAddonMessagePrefix) == "function" then
        ok = safeCall(_G.C_ChatInfo.RegisterAddonMessagePrefix, self.prefix)
    elseif type(_G.RegisterAddonMessagePrefix) == "function" then
        ok = safeCall(_G.RegisterAddonMessagePrefix, self.prefix)
    end
    self.prefixRegistered = ok and true or false
    return self.prefixRegistered
end

function Games:SendRaw(target, payload)
    target = routeName(target)
    payload = tostring(payload or "")
    if target == "" or payload == "" or string.len(payload) > 250 then return false end
    self:RegisterPrefix()
    local ok = false
    if _G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function" then
        ok = safeCall(_G.C_ChatInfo.SendAddonMessage, self.prefix, payload, "WHISPER", target)
    elseif type(_G.SendAddonMessage) == "function" then
        ok = safeCall(_G.SendAddonMessage, self.prefix, payload, "WHISPER", target)
    end
    return ok and true or false
end

function Games:Send(target, ...)
    local values = { ... }
    return self:SendRaw(target, join(values, "~"))
end

function Games:NewSessionID()
    self.sessionCounter = (self.sessionCounter or 0) + 1
    local player = CC.state and CC.state.playerName or "P"
    player = string.gsub(player, "[^%w]", "")
    player = string.sub(player, 1, 4)
    return format("%s%05d%02d", player, stamp() % 100000, self.sessionCounter % 100)
end

function Games:IsPeerAvailable(name)
    local key = lower(cleanName(name))
    local entry = self.peers[key]
    return entry and (now() - (entry.seen or 0) <= 300) or false
end

function Games:MarkPeer(name, version)
    name = cleanName(name)
    if name == "" then return end
    local existing = self.peers[lower(name)] or {}
    existing.name = name
    existing.version = version or existing.version or "CreshChat"
    existing.seen = now()
    self.peers[lower(name)] = existing
    self:RefreshHub()
    if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer() end
end

function Games:SendLeaderboard(target, force)
    target = cleanName(target)
    if target == "" or not CC.SoloGames or not CC.SoloGames.GetLeaderboardSnapshot then return false end
    self.lastLeaderboardSent = self.lastLeaderboardSent or {}
    local key = lower(target)
    local last = tonumber(self.lastLeaderboardSent[key]) or 0
    if not force and now() - last < 1.5 then return false end
    local snapshot = CC.SoloGames:GetLeaderboardSnapshot()
    if type(snapshot) ~= "table" then return false end
    self.lastLeaderboardSent[key] = now()
    return self:Send(target, "L", self.protocol,
        "F", snapshot.FROGGER or 0,
        "D", snapshot.DUNGEON or 0,
        "C", snapshot.CHESS or 0,
        "H", snapshot.HOLDEM or 0,
        "B", snapshot.BLACKJACK or 0,
        "R", snapshot.HIGHERLOWER or 0,
        "T", snapshot.TETRIS or 0)
end

function Games:BroadcastLeaderboard()
    local sent = 0
    for _, peer in pairs(self.peers or {}) do
        if sent >= 20 then break end
        if peer.name and now() - (tonumber(peer.seen) or 0) <= 300 and self:SendLeaderboard(peer.name, true) then sent = sent + 1 end
    end
    return sent
end

function Games:RecordResult(result, detail, roundKey)
    local active = self.active
    if not active then return false end
    result = upper(tostring(result or "DRAW"))
    if result ~= "WIN" and result ~= "LOSS" and result ~= "DRAW" then result = "DRAW" end
    local key = tostring(active.id or "match") .. ":" .. tostring(active.game or "GAME") .. ":" .. tostring(roundKey or "MATCH")
    self.recordedResults = self.recordedResults or {}
    if self.recordedResults[key] then return false end
    self.recordedResults[key] = true
    if CC.SoloGames and CC.SoloGames.RecordHistory then
        CC.SoloGames:RecordHistory(active.game, "MULTIPLAYER", result, active.opponent, detail)
    end
    if CC.db then
        CC.db.multiplayerStats = CC.db.multiplayerStats or {}
        local stats = CC.db.multiplayerStats[active.game] or { wins = 0, losses = 0, draws = 0, games = 0 }
        stats.games = (tonumber(stats.games) or 0) + 1
        if result == "WIN" then stats.wins = (tonumber(stats.wins) or 0) + 1
        elseif result == "LOSS" then stats.losses = (tonumber(stats.losses) or 0) + 1
        else stats.draws = (tonumber(stats.draws) or 0) + 1 end
        CC.db.multiplayerStats[active.game] = stats
    end
    return true
end

function Games:GetTargets()
    local output, seen = {}, {}
    local function add(name, online, source)
        name = cleanName(name)
        if name == "" or (CC.IsSelf and CC:IsSelf(name)) then return end
        local key = lower(name)
        if seen[key] then
            if online then seen[key].online = true end
            if seen[key].source == "WHISPER" and source ~= "WHISPER" then seen[key].source = source end
            seen[key].addon = self:IsPeerAvailable(name)
            return
        end
        local item = {
            name = name,
            online = online == true,
            source = source,
            addon = self:IsPeerAvailable(name),
        }
        seen[key] = item
        output[#output + 1] = item
    end

    -- Online character friends and saved whisper contacts remain the primary
    -- challenge list because private addon messages can be routed directly.
    if CC.Friends and CC.Friends.GetPlayerFriends then
        for _, friend in ipairs(CC.Friends:GetPlayerFriends() or {}) do
            if friend.online then add(friend.target or friend.name, true, "FRIEND") end
        end
    end
    if CC.db and CC.db.conversations then
        for target in pairs(CC.db.conversations) do add(target, false, "WHISPER") end
    end
    if CC.state and CC.state.lastWhisperTarget then add(CC.state.lastWhisperTarget, false, "WHISPER") end

    -- Future-facing discovery: party, raid and online guild players are added to
    -- the same handshake scanner. New multiplayer games can therefore use this
    -- directory without changing the drawer or challenge picker.
    local groupCount = type(_G.GetNumGroupMembers) == "function" and (_G.GetNumGroupMembers() or 0) or 0
    if groupCount > 0 then
        local raid = type(_G.IsInRaid) == "function" and _G.IsInRaid()
        if raid then
            for index = 1, groupCount do
                local name = type(_G.GetRaidRosterInfo) == "function" and _G.GetRaidRosterInfo(index) or nil
                if name then add(name, true, "RAID") end
            end
        else
            for index = 1, max(0, groupCount - 1) do
                local name = type(_G.UnitName) == "function" and _G.UnitName("party" .. index) or nil
                if name then add(name, true, "PARTY") end
            end
        end
    end

    if type(_G.GetNumGuildMembers) == "function" and type(_G.GetGuildRosterInfo) == "function" then
        local total = _G.GetNumGuildMembers() or 0
        for index = 1, min(total, 200) do
            local name, _, _, _, _, _, _, _, online = _G.GetGuildRosterInfo(index)
            if name and online then add(name, true, "GUILD") end
        end
    end

    if type(_G.UnitIsPlayer) == "function" and type(_G.UnitName) == "function" then
        for _, unit in ipairs({ "target", "focus", "mouseover" }) do
            local ok, isPlayer = pcall(_G.UnitIsPlayer, unit)
            if ok and isPlayer then
                local name = _G.UnitName(unit)
                if name then add(name, true, upper(unit)) end
            end
        end
    end

    sort(output, function(a, b)
        if a.addon ~= b.addon then return a.addon end
        if a.online ~= b.online then return a.online end
        return lower(shortName(a.name)) < lower(shortName(b.name))
    end)
    return output
end

function Games:SetTarget(name)
    name = cleanName(name)
    if name == "" then return false end
    self.targetName = name
    local targets = self:GetTargets()
    for index, item in ipairs(targets) do
        if samePlayer(item.name, name) then self.targetIndex = index; break end
    end
    self:Ping(name)
    self:RefreshHub()
    return true
end

function Games:CycleTarget(direction)
    local targets = self:GetTargets()
    if #targets == 0 then self.targetName = nil; self.targetIndex = 1; self:RefreshHub(); return end
    local index = tonumber(self.targetIndex) or 1
    index = index + (direction or 1)
    if index > #targets then index = 1 end
    if index < 1 then index = #targets end
    self.targetIndex = index
    self.targetName = targets[index].name
    self:Ping(self.targetName)
    self:RefreshHub()
end

function Games:Ping(target)
    target = cleanName(target)
    if target == "" then return false end
    local nonce = tostring(floor(now() * 1000) % 1000000)
    self.lastPingNonce = nonce
    return self:Send(target, "P", nonce, self.protocol)
end

function Games:ScanPeers(force)
    local current = now()
    if not force and current - (tonumber(self.lastPeerScanAt) or 0) < 15 then
        self:SetHubStatus("Peer scan recently completed. Try again in a few seconds.")
        self:RefreshHub()
        return false
    end
    self.lastPeerScanAt = current
    local targets = self:GetTargets()
    local limit = min(#targets, 12)
    if limit <= 0 then
        self:SetHubStatus("No online friends, group members or whisper contacts found.")
        return false
    end
    self:SetHubStatus("Checking " .. limit .. " player" .. (limit == 1 and "" or "s") .. " for CreshChat...")
    local index = 1
    local function sendNext()
        if index > limit then
            if _G.C_Timer and type(_G.C_Timer.After) == "function" then _G.C_Timer.After(1.5, function() Games:RefreshHub() end)
            else Games:RefreshHub() end
            return
        end
        local item = targets[index]
        index = index + 1
        if item and item.name then Games:Ping(item.name) end
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then _G.C_Timer.After(0.15, sendNext)
        else sendNext() end
    end
    sendNext()
    return true
end

function Games:SetHubStatus(text, color)
    color = color or palette().muted
    if self.hub and self.hub.status then
        self.hub.status:SetText(tostring(text or ""))
        self.hub.status:SetTextColor(color[1], color[2], color[3], 1)
    end
    if CC.UI and CC.UI.SetGameDrawerStatus then CC.UI:SetGameDrawerStatus(text, color) end
end

function Games:RefreshHub()
    local hub = self.hub
    local targets = self:GetTargets()
    if not hub then
        if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
        return
    end
    if #targets == 0 then
        self.targetName = nil
        self.targetIndex = 1
    else
        local found
        for index, item in ipairs(targets) do
            if self.targetName and samePlayer(item.name, self.targetName) then
                self.targetIndex = index
                self.targetName = item.name
                found = item
                break
            end
        end
        if not found then
            self.targetIndex = clamp(self.targetIndex or 1, 1, #targets)
            found = targets[self.targetIndex]
            self.targetName = found.name
        end
    end

    local target = self.targetName
    if hub.targetButton then
        if target then
            local verified = self:IsPeerAvailable(target)
            hub.targetButton.label:SetText("TARGET: " .. upper(shortName(target)) .. (verified and "  [CRESHCHAT]" or "  [?]"))
            setButtonEnabled(hub.targetButton, true)
        else
            hub.targetButton.label:SetText("NO AVAILABLE PLAYERS")
            setButtonEnabled(hub.targetButton, false)
        end
    end

    local canChallenge = target ~= nil and self.active == nil and self.pendingOutgoing == nil
    for _, button in pairs(hub.gameButtons or {}) do setButtonEnabled(button, canChallenge) end

    if self.active then
        self:SetHubStatus("Playing " .. self:GetGameName(self.active.game) .. " with " .. shortName(self.active.opponent) .. ".", palette().green)
        if hub.resume then hub.resume:Show() end
    elseif self.pendingOutgoing then
        self:SetHubStatus("Waiting for " .. shortName(self.pendingOutgoing.target) .. " to accept " .. self:GetGameName(self.pendingOutgoing.game) .. "...", palette().gold)
        if hub.resume then hub.resume:Hide() end
    elseif self.pendingIncoming then
        self:SetHubStatus(shortName(self.pendingIncoming.sender) .. " challenged you to " .. self:GetGameName(self.pendingIncoming.game) .. ".", palette().gold)
        if hub.resume then hub.resume:Hide() end
    else
        local verified = target and self:IsPeerAvailable(target)
        self:SetHubStatus(target and (verified and "CreshChat detected. Choose a game to send a challenge." or "Press SCAN to check whether this player has CreshChat.") or "Open a whisper or add an online friend to challenge them.", verified and palette().green or palette().muted)
        if hub.resume then hub.resume:Hide() end
    end
    if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
end

function Games:BuildHub(parent)
    if self.hub then return self.hub end
    local colors = palette()
    local hub = CreateFrame("Frame", nil, parent, templateName())
    hub:SetAllPoints(parent)
    applyBackdrop(hub, colors.panelSoft, colors.panelSoft)
    hub:Hide()
    self.hub = hub

    hub.banner = CreateFrame("Frame", nil, hub, templateName())
    hub.banner:SetPoint("TOPLEFT", hub, "TOPLEFT", 8, -8)
    hub.banner:SetPoint("TOPRIGHT", hub, "TOPRIGHT", -8, -8)
    hub.banner:SetHeight(66)
    applyBackdrop(hub.banner, darken(colors.accent, 0.30), colors.accent)

    hub.title = createText(hub.banner, 17, colors.text, "LEFT")
    hub.title:SetPoint("TOPLEFT", hub.banner, "TOPLEFT", 14, -10)
    hub.title:SetText("CRESH GAMES")
    hub.subtitle = createText(hub.banner, 9, colors.muted, "LEFT")
    hub.subtitle:SetPoint("TOPLEFT", hub.title, "BOTTOMLEFT", 0, -4)
    hub.subtitle:SetText("Addon-to-addon challenges · private game traffic · WASD and mouse controls")

    hub.scan = createButton(hub.banner, "SCAN", 58, 26, function() Games:ScanPeers() end)
    hub.scan:SetPoint("RIGHT", hub.banner, "RIGHT", -10, 0)
    setButtonAccent(hub.scan, colors.accent)

    hub.settings = createButton(hub.banner, "SET", 40, 26, function()
        if CC.UI and CC.UI.OpenSettings then CC.UI:OpenSettings() end
    end)
    hub.settings:SetPoint("RIGHT", hub.scan, "LEFT", -6, 0)
    hub.settings:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("CreshChat Settings", 1, 1, 1)
        GameTooltip:AddLine("Open Settings to configure modules and launcher.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    hub.settings:SetScript("OnLeave", function() GameTooltip:Hide() end)

    hub.targetButton = createButton(hub, "TARGET", 310, 30, function(_, mouseButton)
        Games:CycleTarget(mouseButton == "RightButton" and -1 or 1)
    end)
    hub.targetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    hub.targetButton:SetPoint("TOPLEFT", hub.banner, "BOTTOMLEFT", 0, -10)
    hub.targetButton:SetPoint("RIGHT", hub, "RIGHT", -8, 0)
    hub.targetButton:SetWidth(max(220, (hub:GetWidth() or 430) - 16))
    setButtonAccent(hub.targetButton, colors.accent)

    hub.status = createText(hub, 10, colors.muted, "LEFT")
    hub.status:SetPoint("TOPLEFT", hub.targetButton, "BOTTOMLEFT", 4, -8)
    hub.status:SetPoint("TOPRIGHT", hub.targetButton, "BOTTOMRIGHT", -4, -8)
    hub.status:SetHeight(28)
    hub.status:SetWordWrap(true)

    hub.gameButtons = {}
    local cards = {
        { key = "CHESS", label = "CHESS", desc = "Turn-based board play\nClick pieces or use WASD + Space" },
        { key = "TETRIS", label = "TETRIS", desc = "Live dual-board versus\nTimed Endless or Endless Attack" },
        { key = "HOLDEM", label = "TEXAS HOLD'EM", desc = "Heads-up fixed-raise poker\nMouse or A/D + Space" },
        { key = "PONG", label = "PONG", desc = "Host-authoritative first to 5\nW/S move your paddle" },
    }

    local cardWidth = 196
    local cardHeight = 102
    for index, info in ipairs(cards) do
        local card = CreateFrame("Frame", nil, hub, templateName())
        card:SetSize(cardWidth, cardHeight)
        local col = (index - 1) % 2
        local row = floor((index - 1) / 2)
        card:SetPoint("TOPLEFT", hub, "TOPLEFT", 8 + col * (cardWidth + 8), -156 - row * (cardHeight + 8))
        if col == 1 then card:SetPoint("RIGHT", hub, "RIGHT", -8, 0) end
        applyBackdrop(card, colors.panel, colors.border)
        card.title = createText(card, 13, colors.text, "LEFT")
        card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -9)
        card.title:SetText(info.label)
        card.desc = createText(card, 9, colors.muted, "LEFT")
        card.desc:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -5)
        card.desc:SetPoint("RIGHT", card, "RIGHT", -8, 0)
        card.desc:SetHeight(38)
        card.desc:SetWordWrap(true)
        card.desc:SetText(info.desc)
        card.play = createButton(card, "CHALLENGE", 88, 24, function() Games:Challenge(Games.targetName, info.key) end)
        card.play:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 7)
        setButtonAccent(card.play, colors.accent)
        hub.gameButtons[info.key] = card.play
    end

    hub.resume = createButton(hub, "RETURN TO ACTIVE GAME", 170, 28, function() Games:ShowGameWindow() end)
    hub.resume:SetPoint("BOTTOMLEFT", hub, "BOTTOMLEFT", 8, 8)
    setButtonAccent(hub.resume, colors.green)
    hub.resume:Hide()

    hub.note = createText(hub, 9, colors.muted, "RIGHT")
    hub.note:SetPoint("BOTTOMRIGHT", hub, "BOTTOMRIGHT", -8, 12)
    hub.note:SetText("Matching CreshChat build required · private addon traffic only")

    hub:SetScript("OnShow", function()
        Games:RefreshHub()
        Games:ScanPeers(false)
    end)
    return hub
end

function Games:SetHubVisible(visible)
    if not self.hub and CC.UI and CC.UI.main and CC.UI.main.body then self:BuildHub(CC.UI.main.body) end
    if not self.hub then return end
    self.hub:SetShown(visible == true)
    if visible then self:RefreshHub() end
end

function Games:OpenHub(target)
    if target then self:SetTarget(target) end
    if CC.UI and CC.UI.OpenGameDrawer then
        CC.UI:OpenGameDrawer("MULTIPLAYER", target)
    elseif self.hub then
        self.hub:Show()
    end
end

function Games:Challenge(target, game)
    target = cleanName(target)
    game = upper(tostring(game or ""))
    if not GAME_NAMES[game] then return false end
    if target == "" then CC:Print("Choose an online friend or whisper contact first."); return false end
    if self.active then CC:Print("Finish or close the current game before starting another challenge."); return false end
    if self.pendingOutgoing then CC:Print("A game challenge is already waiting for a response."); return false end

    local id = self:NewSessionID()
    self.pendingOutgoing = { id = id, target = target, game = game, sentAt = now() }
    self:Ping(target)
    if not self:Send(target, "C", id, game, self.protocol) then
        self.pendingOutgoing = nil
        CC:Print("Unable to send that game challenge.")
        self:RefreshHub()
        return false
    end
    CC:Print(self:GetGameName(game) .. " challenge sent to " .. shortName(target) .. ".")
    self:RefreshHub()
    if _G.C_Timer and type(_G.C_Timer.After) == "function" then
        _G.C_Timer.After(15, function()
            local pending = Games.pendingOutgoing
            if pending and pending.id == id then
                Games.pendingOutgoing = nil
                Games:SetHubStatus("No response from " .. shortName(target) .. ". They may be offline or using an older addon version.", palette().red)
                Games:RefreshHub()
            end
        end)
    end
    return true
end

function Games:ShowChallengePopup(sender, game, id)
    local colors = palette()
    if not self.challengePopup then
        local popup = CreateFrame("Frame", "CreshChatGameChallenge", UIParent, templateName())
        popup:SetSize(360, 176)
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
        popup:SetFrameStrata("DIALOG")
        popup:SetClampedToScreen(true)
        applyBackdrop(popup, colors.panel, colors.accent)
        popup.accent = popup:CreateTexture(nil, "ARTWORK")
        popup.accent:SetPoint("TOPLEFT", popup, "TOPLEFT", 1, -1)
        popup.accent:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -1, -1)
        popup.accent:SetHeight(4)
        popup.accent:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1)
        popup.title = createText(popup, 16, colors.text, "CENTER")
        popup.title:SetPoint("TOP", popup, "TOP", 0, -22)
        popup.title:SetText("GAME CHALLENGE")
        popup.message = createText(popup, 11, colors.muted, "CENTER")
        popup.message:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -55)
        popup.message:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -20, -55)
        popup.message:SetHeight(48)
        popup.message:SetWordWrap(true)
        popup.accept = createButton(popup, "ACCEPT", 104, 30, function() Games:AcceptChallenge() end)
        popup.accept:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 60, 20)
        setButtonAccent(popup.accept, colors.green)
        popup.decline = createButton(popup, "DECLINE", 104, 30, function() Games:DeclineChallenge("Declined") end)
        popup.decline:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -60, 20)
        setButtonAccent(popup.decline, colors.red)
        popup:Hide()
        self.challengePopup = popup
        if CC.UI and CC.UI.ApplySafeFrameScale then CC.UI:ApplySafeFrameScale(popup, (CC.db.ui and CC.db.ui.scale) or 1, 22) end
    end
    self.challengePopup.message:SetText(shortName(sender) .. " challenged you to " .. self:GetGameName(game) .. ".")
    self.challengePopup:Show()
    if (not CC.IsNotificationEnabled or CC:IsNotificationEnabled("GAME")) and CC.UI and CC.UI.NotifyLauncher then CC.UI:NotifyLauncher("GAME", sender, 12) end
    if CC.PlayAlertSound then CC:PlayAlertSound("GAME") end
end

function Games:AcceptChallenge()
    local pending = self.pendingIncoming
    if not pending then return false end
    if self.active then self:DeclineChallenge("Busy"); return false end
    self.pendingIncoming = nil
    if self.challengePopup then self.challengePopup:Hide() end
    self.active = {
        id = pending.id,
        game = pending.game,
        opponent = pending.sender,
        host = false,
        role = "G",
        started = false,
    }
    self:Send(pending.sender, "A", pending.id, pending.game, self.protocol)
    self:RefreshHub()
    self:ShowWaitingGameWindow("Waiting for " .. shortName(pending.sender) .. " to start " .. self:GetGameName(pending.game) .. "...")
    return true
end

function Games:DeclineChallenge(reason)
    local pending = self.pendingIncoming
    if not pending then return false end
    self:Send(pending.sender, "D", pending.id, tostring(reason or "Declined"))
    self.pendingIncoming = nil
    if self.challengePopup then self.challengePopup:Hide() end
    self:RefreshHub()
    return true
end

function Games:CloseActive(reason, notify)
    local active = self.active
    if active and notify ~= false then self:Send(active.opponent, "X", active.id, tostring(reason or "Closed")) end
    self.active = nil
    if CC.GameAudio and CC.GameAudio.StopMusic then CC.GameAudio:StopMusic() end
    if self.gameWindow then self.gameWindow:Hide() end
    self:RefreshHub()
end

function Games:OnChallenge(sender, parts)
    local id, game = parts[2], upper(parts[3] or "")
    local peerProtocol = tonumber(parts[4]) or 1
    if not id or not GAME_NAMES[game] then return end
    if game == "TETRIS" and peerProtocol < 3 then
        self:Send(sender, "D", id, "Update CreshChat for timed Endless and live Tetris boards")
        return
    end
    if self.active or self.pendingIncoming or self.pendingOutgoing then
        self:Send(sender, "D", id, "Busy")
        return
    end
    self:MarkPeer(sender, "CreshChat")
    self.pendingIncoming = { id = id, game = game, sender = sender, receivedAt = now() }
    self:ShowChallengePopup(sender, game, id)
    self:RefreshHub()
end

function Games:OnAccept(sender, parts)
    local pending = self.pendingOutgoing
    local id, game = parts[2], upper(parts[3] or "")
    local peerProtocol = tonumber(parts[4]) or 1
    if not pending or pending.id ~= id or not samePlayer(sender, pending.target) or pending.game ~= game then return end
    if game == "TETRIS" and peerProtocol < 3 then
        self.pendingOutgoing = nil
        self:SetHubStatus(shortName(sender) .. " needs the latest CreshChat version for timed Endless and live Tetris boards.", palette().red)
        self:RefreshHub()
        return
    end
    self.pendingOutgoing = nil
    self.active = {
        id = id,
        game = game,
        opponent = sender,
        host = true,
        role = "H",
        started = false,
    }
    local seed = (stamp() * 37 + floor(now() * 1000)) % 2147483647
    if seed <= 0 then seed = 104729 end
    self:Send(sender, "S", id, game, seed, self.protocol)
    self:BeginGame(seed)
end

function Games:OnStart(sender, parts)
    local active = self.active
    local id, game, seed = parts[2], upper(parts[3] or ""), tonumber(parts[4]) or 1
    if not active or active.id ~= id or active.game ~= game or not samePlayer(sender, active.opponent) then return end
    self:BeginGame(seed)
end

function Games:OnDecline(sender, parts)
    local pending = self.pendingOutgoing
    if not pending or pending.id ~= parts[2] or not samePlayer(sender, pending.target) then return end
    local reason = parts[3] or "Declined"
    self.pendingOutgoing = nil
    self:SetHubStatus(shortName(sender) .. " declined the challenge: " .. reason .. ".", palette().red)
    self:RefreshHub()
end

function Games:OnClose(sender, parts)
    local active = self.active
    if not active or active.id ~= parts[2] or not samePlayer(sender, active.opponent) then return end
    local reason = parts[3] or "Closed"
    if self.gameWindow then
        self:SetGameStatus(shortName(sender) .. " closed the game: " .. reason, palette().red)
    end
    self.active = nil
    self:RefreshHub()
end

function Games:HandleAddonMessage(prefix, payload, channel, sender)
    if prefix ~= self.prefix or upper(tostring(channel or "")) ~= "WHISPER" then return end
    sender = cleanName(sender)
    if sender == "" or (CC.IsSelf and CC:IsSelf(sender)) then return end
    local parts = split(payload, "~")
    local kind = parts[1]
    if kind == "P" then
        self:MarkPeer(sender, "CreshChat")
        self:Send(sender, "R", parts[2] or "0", self.version, self.protocol)
        self:SendLeaderboard(sender)
    elseif kind == "R" then
        self:MarkPeer(sender, parts[3] or "CreshChat")
        self:SendLeaderboard(sender)
    elseif kind == "L" then
        self:MarkPeer(sender, "CreshChat")
        if CC.SoloGames and CC.SoloGames.ReceiveLeaderboard then CC.SoloGames:ReceiveLeaderboard(sender, parts) end
    elseif kind == "C" then
        self:OnChallenge(sender, parts)
    elseif kind == "A" then
        self:OnAccept(sender, parts)
    elseif kind == "D" then
        self:OnDecline(sender, parts)
    elseif kind == "S" then
        self:OnStart(sender, parts)
    elseif kind == "X" then
        self:OnClose(sender, parts)
    elseif kind == "M" then
        self:HandleGameMessage(sender, parts)
    end
end

function Games:SendGame(op, ...)
    local active = self.active
    if not active then return false end
    local values = { "M", active.id, active.game, op, ... }
    return self:Send(active.opponent, unpack(values))
end

function Games:BuildGameWindow()
    if self.gameWindow then return self.gameWindow end
    local colors = palette()
    local frame = CreateFrame("Frame", "CreshChatGameWindow", UIParent, templateName())
    frame:SetSize(660, 560)
    frame:SetPoint("CENTER", UIParent, "CENTER", 40, 10)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:EnableKeyboard(true)
    if frame.SetPropagateKeyboardInput then frame:SetPropagateKeyboardInput(false) end
    applyBackdrop(frame, colors.panel, colors.border)
    frame:Hide()
    self.gameWindow = frame
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

    frame.title = createText(frame.header, 15, colors.text, "LEFT")
    frame.title:SetPoint("TOPLEFT", frame.header, "TOPLEFT", 12, -8)
    frame.title:SetText("CRESH GAMES")
    frame.opponent = createText(frame.header, 9, colors.muted, "LEFT")
    frame.opponent:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -3)
    frame.opponent:SetText("Waiting for opponent")

    frame.close = createButton(frame.header, "X", 28, 26, function() Games:CloseActive("Window closed", true) end)
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
    frame.status:SetText("Waiting...")
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
    frame:SetScript("OnHide", function(selfFrame) selfFrame:EnableKeyboard(false); if CC.GameAudio and CC.GameAudio.StopMusic then CC.GameAudio:StopMusic() end end)
    frame:SetScript("OnKeyDown", function(_, key)
        local active = Games.active
        if not active or not active.started then return end
        local view = Games.gameViews[active.game]
        if view and CC.GameAudio and CC.GameAudio.PlayInteraction then
            CC.GameAudio:PlayInteraction(active.game == "HOLDEM" and "CARD" or "MOVE")
        end
        if view and view.OnKeyDown then view:OnKeyDown(key) end
    end)
    frame:SetScript("OnKeyUp", function(_, key)
        local active = Games.active
        if not active or not active.started then return end
        local view = Games.gameViews[active.game]
        if view and view.OnKeyUp then view:OnKeyUp(key) end
    end)
    frame:SetScript("OnUpdate", function(_, elapsed)
        local active = Games.active
        if not active or not active.started then return end
        local view = Games.gameViews[active.game]
        if view and view.OnUpdate then view:OnUpdate(elapsed or 0) end
    end)
    return frame
end

function Games:HideAllGameViews()
    for _, view in pairs(self.gameViews) do
        if view.frame then view.frame:Hide() end
        if view.Stop then view:Stop() end
    end
end

function Games:SetGameStatus(text, color)
    local frame = self:BuildGameWindow()
    frame.status:SetText(tostring(text or ""))
    color = color or palette().muted
    frame.status:SetTextColor(color[1], color[2], color[3], 1)
    if CC.GameProgression then CC.GameProgression:UpdateBar(frame.levelProgress, frame.levelText, self.active and self.active.game) end
end

function Games:ShowWaitingGameWindow(text)
    local frame = self:BuildGameWindow()
    self:HideAllGameViews()
    frame.title:SetText("CRESH GAMES")
    frame.opponent:SetText(self.active and ("Opponent: " .. shortName(self.active.opponent)) or "Waiting")
    self:SetGameStatus(text or "Waiting...")
    frame:Show()
end

function Games:ShowGameWindow()
    if not self.active then return false end
    local frame = self:BuildGameWindow()
    frame:Show()
    return true
end

function Games:BeginGame(seed)
    local active = self.active
    if not active then return end
    if not active.creshProgressionStarted then
        active.creshProgressionStarted = true
        if CC.GameProgression and CC.GameProgression.OnGameStarted then CC.GameProgression:OnGameStarted(active.game, "MULTIPLAYER") end
    end
    if CC.GameAudio and CC.GameAudio.PlayMusic then CC.GameAudio:PlayMusic(active.game) end
    if CC.UI and CC.UI.CloseGameDrawer then CC.UI:CloseGameDrawer(true) end
    active.seed = tonumber(seed) or 1
    active.started = true
    local frame = self:BuildGameWindow()
    self:HideAllGameViews()
    frame.title:SetText(self:GetGameName(active.game))
    frame.opponent:SetText("Opponent: " .. shortName(active.opponent) .. (active.host and " · Host" or " · Guest"))
    local builder = self["Build" .. active.game .. "View"]
    if builder then builder(self) end
    local view = self.gameViews[active.game]
    if view and view.Start then view:Start(active.seed) end
    if view and view.frame then view.frame:Show() end
    frame:Show()
    self:RefreshHub()
end

function Games:HandleGameMessage(sender, parts)
    local active = self.active
    local id, game, op = parts[2], upper(parts[3] or ""), parts[4]
    if not active or active.id ~= id or active.game ~= game or not samePlayer(sender, active.opponent) then return end
    local view = self.gameViews[game]
    if view and view.OnMessage then view:OnMessage(op, parts) end
end

-- CHESS -----------------------------------------------------------------------
local CHESS_BACK = { "R", "N", "B", "Q", "K", "B", "N", "R" }
local CHESS_TEXTURES = (_G.CreshGamesChessTextures and _G.CreshGamesChessTextures.Notation) or {
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
local CHESS_PIECE_SIZE = 44

local function chessPiece(color, kind)
    return { color = color, kind = kind }
end

local function chessInitialBoard()
    local board = {}
    for x = 1, 8 do board[x] = {} end
    for x = 1, 8 do
        board[x][1] = chessPiece("W", CHESS_BACK[x])
        board[x][2] = chessPiece("W", "P")
        board[x][7] = chessPiece("B", "P")
        board[x][8] = chessPiece("B", CHESS_BACK[x])
    end
    return board
end

local function chessPathClear(board, x1, y1, x2, y2)
    local dx = x2 == x1 and 0 or (x2 > x1 and 1 or -1)
    local dy = y2 == y1 and 0 or (y2 > y1 and 1 or -1)
    local x, y = x1 + dx, y1 + dy
    while x ~= x2 or y ~= y2 do
        if board[x] and board[x][y] then return false end
        x, y = x + dx, y + dy
    end
    return true
end

local function chessLegal(board, piece, x1, y1, x2, y2)
    if not piece or x2 < 1 or x2 > 8 or y2 < 1 or y2 > 8 or (x1 == x2 and y1 == y2) then return false end
    local target = board[x2][y2]
    if target and target.color == piece.color then return false end
    local dx, dy = x2 - x1, y2 - y1
    local ax, ay = abs(dx), abs(dy)
    if piece.kind == "P" then
        local direction = piece.color == "W" and 1 or -1
        local startRow = piece.color == "W" and 2 or 7
        if dx == 0 and dy == direction and not target then return true end
        if dx == 0 and y1 == startRow and dy == 2 * direction and not target and not board[x1][y1 + direction] then return true end
        if ax == 1 and dy == direction and target and target.color ~= piece.color then return true end
        return false
    elseif piece.kind == "N" then
        return (ax == 1 and ay == 2) or (ax == 2 and ay == 1)
    elseif piece.kind == "B" then
        return ax == ay and chessPathClear(board, x1, y1, x2, y2)
    elseif piece.kind == "R" then
        return (dx == 0 or dy == 0) and chessPathClear(board, x1, y1, x2, y2)
    elseif piece.kind == "Q" then
        return ((dx == 0 or dy == 0) or ax == ay) and chessPathClear(board, x1, y1, x2, y2)
    elseif piece.kind == "K" then
        return ax <= 1 and ay <= 1
    end
    return false
end

function Games:BuildCHESSView()
    if self.gameViews.CHESS then return self.gameViews.CHESS end
    local colors = palette()
    local view = { game = "CHESS", buttons = {}, cursorX = 1, cursorY = 1 }
    local frame = CreateFrame("Frame", nil, self.gameWindow.content, templateName())
    frame:SetAllPoints()
    applyBackdrop(frame, colors.panelSoft, colors.panelSoft)
    frame:Hide()
    view.frame = frame

    view.boardFrame = CreateFrame("Frame", nil, frame, templateName())
    view.boardFrame:SetSize(416, 416)
    view.boardFrame:SetPoint("CENTER", frame, "CENTER", -70, 0)
    applyBackdrop(view.boardFrame, colors.panel, colors.border)

    for displayRow = 1, 8 do
        for displayCol = 1, 8 do
            local button = CreateFrame("Button", nil, view.boardFrame, templateName())
            button:SetSize(50, 50)
            button:SetPoint("TOPLEFT", view.boardFrame, "TOPLEFT", 8 + (displayCol - 1) * 50, -8 - (displayRow - 1) * 50)
            button.pieceTexture = button:CreateTexture(nil, "ARTWORK")
            button.pieceTexture:SetSize(CHESS_PIECE_SIZE, CHESS_PIECE_SIZE)
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
    view.turnText = createText(view.info, 13, colors.text, "CENTER")
    view.turnText:SetPoint("TOPLEFT", view.info, "TOPLEFT", 8, -14)
    view.turnText:SetPoint("TOPRIGHT", view.info, "TOPRIGHT", -8, -14)
    view.sideText = createText(view.info, 10, colors.muted, "CENTER")
    view.sideText:SetPoint("TOPLEFT", view.turnText, "BOTTOMLEFT", 0, -8)
    view.sideText:SetPoint("RIGHT", view.turnText, "RIGHT", 0, 0)
    view.help = createText(view.info, 9, colors.muted, "LEFT")
    view.help:SetPoint("TOPLEFT", view.sideText, "BOTTOMLEFT", 6, -24)
    view.help:SetPoint("RIGHT", view.info, "RIGHT", -8, 0)
    view.help:SetHeight(170)
    view.help:SetWordWrap(true)
    view.help:SetText("CONTROLS\n\nMouse: select a piece, then its destination.\n\nWASD: move the square cursor.\nSpace / Enter: select or move.\n\nBasic rules: legal piece movement, captures, turns and queen promotion. The game ends when a king is captured.")
    view.resign = createButton(view.info, "RESIGN", 92, 28, function() view:Resign() end)
    view.resign:SetPoint("BOTTOM", view.info, "BOTTOM", 0, 14)
    setButtonAccent(view.resign, colors.red)

    function view:DisplayToBoard(col, row)
        if self.side == "B" then return 9 - col, row end
        return col, 9 - row
    end

    function view:BoardToDisplay(x, y)
        if self.side == "B" then return 9 - x, y end
        return x, 9 - y
    end

    function view:Refresh()
        for _, button in ipairs(self.buttons) do
            local x, y = self:DisplayToBoard(button.displayCol, button.displayRow)
            local piece = self.board[x][y]
            local isLight = ((x + y) % 2 == 0)
            local base = isLight and { 0.58, 0.60, 0.62, 1 } or { 0.19, 0.21, 0.24, 1 }
            local border = colors.border
            if self.selected and self.selected.x == x and self.selected.y == y then
                base, border = darken(colors.accent, 0.18), colors.accent
            elseif self.cursorX == x and self.cursorY == y then
                border = colors.gold
            end
            applyBackdrop(button, base, border)
            if piece then
                local texturePath = CHESS_TEXTURES[piece.color .. piece.kind]
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
        local turnName = self.turn == self.side and "YOUR TURN" or (shortName(Games.active.opponent) .. "'S TURN")
        self.turnText:SetText(turnName)
        self.turnText:SetTextColor((self.turn == self.side and colors.green or colors.gold)[1], (self.turn == self.side and colors.green or colors.gold)[2], (self.turn == self.side and colors.green or colors.gold)[3], 1)
        self.sideText:SetText("You are " .. (self.side == "W" and "WHITE" or "BLACK"))
    end

    function view:ApplyMove(x1, y1, x2, y2)
        local piece = self.board[x1] and self.board[x1][y1]
        if not piece or not chessLegal(self.board, piece, x1, y1, x2, y2) then return false end
        local captured = self.board[x2][y2]
        self.board[x2][y2] = piece
        self.board[x1][y1] = nil
        if piece.kind == "P" and (y2 == 8 or y2 == 1) then piece.kind = "Q" end
        self.turn = self.turn == "W" and "B" or "W"
        self.selected = nil
        self.cursorX, self.cursorY = x2, y2
        if captured and captured.kind == "K" then
            self.gameOver = true
            self.winner = piece.color
            local localResult = piece.color == self.side and "WIN" or "LOSS"
            Games:SetGameStatus((piece.color == self.side and "You win" or shortName(Games.active.opponent) .. " wins") .. " by king capture.", piece.color == self.side and colors.green or colors.red)
            Games:RecordResult(localResult, "King captured")
        end
        self:Refresh()
        return true, captured
    end

    function view:ClickBoard(x, y)
        if self.gameOver or self.turn ~= self.side then return end
        self.cursorX, self.cursorY = x, y
        local piece = self.board[x][y]
        if not self.selected then
            if piece and piece.color == self.side then self.selected = { x = x, y = y } end
            self:Refresh()
            return
        end
        local selectedPiece = self.board[self.selected.x][self.selected.y]
        if piece and piece.color == self.side then
            self.selected = { x = x, y = y }
            self:Refresh()
            return
        end
        local x1, y1 = self.selected.x, self.selected.y
        local ok, captured = self:ApplyMove(x1, y1, x, y)
        if ok then
            Games:SendGame("MOVE", x1, y1, x, y)
            if captured and captured.kind == "K" then Games:SendGame("END", self.side) end
            Games:SetGameStatus(self.gameOver and Games.gameWindow.status:GetText() or "Move sent. Waiting for " .. shortName(Games.active.opponent) .. ".", self.gameOver and colors.green or colors.muted)
        else
            Games:SetGameStatus("That piece cannot move there.", colors.red)
        end
    end

    function view:ClickDisplay(col, row)
        local x, y = self:DisplayToBoard(col, row)
        self:ClickBoard(x, y)
    end

    function view:OnKeyDown(key)
        key = upper(tostring(key or ""))
        local dx, dy = 0, 0
        if key == "A" or key == "LEFT" then dx = self.side == "B" and 1 or -1
        elseif key == "D" or key == "RIGHT" then dx = self.side == "B" and -1 or 1
        elseif key == "W" or key == "UP" then dy = self.side == "B" and -1 or 1
        elseif key == "S" or key == "DOWN" then dy = self.side == "B" and 1 or -1
        elseif key == "SPACE" or key == "ENTER" then self:ClickBoard(self.cursorX, self.cursorY); return
        else return end
        self.cursorX = clamp(self.cursorX + dx, 1, 8)
        self.cursorY = clamp(self.cursorY + dy, 1, 8)
        self:Refresh()
    end

    function view:Resign()
        if self.gameOver then return end
        self.gameOver = true
        self.winner = self.side == "W" and "B" or "W"
        Games:SendGame("RESIGN")
        Games:SetGameStatus("You resigned. " .. shortName(Games.active.opponent) .. " wins.", colors.red)
        Games:RecordResult("LOSS", "You resigned")
        self:Refresh()
    end

    function view:OnMessage(op, parts)
        if op == "MOVE" then
            if self.gameOver or self.turn == self.side then return end
            local x1, y1, x2, y2 = tonumber(parts[5]), tonumber(parts[6]), tonumber(parts[7]), tonumber(parts[8])
            local piece = x1 and self.board[x1] and self.board[x1][y1]
            if piece and piece.color ~= self.side then
                local ok, captured = self:ApplyMove(x1, y1, x2, y2)
                if ok and not self.gameOver then Games:SetGameStatus("Your turn.", colors.green) end
                if captured and captured.kind == "K" then Games:SetGameStatus(shortName(Games.active.opponent) .. " captured your king.", colors.red) end
            end
        elseif op == "RESIGN" then
            self.gameOver = true
            self.winner = self.side
            Games:SetGameStatus(shortName(Games.active.opponent) .. " resigned. You win.", colors.green)
            Games:RecordResult("WIN", "Opponent resigned")
            self:Refresh()
        elseif op == "END" then
            self.gameOver = true
            self.winner = parts[5]
            Games:RecordResult(self.winner == self.side and "WIN" or "LOSS", "King captured")
            self:Refresh()
        end
    end

    function view:Start()
        self.side = Games.active.host and "W" or "B"
        self.board = chessInitialBoard()
        self.turn = "W"
        self.selected = nil
        self.gameOver = false
        self.cursorX = self.side == "W" and 5 or 4
        self.cursorY = self.side == "W" and 2 or 7
        Games:SetGameStatus(self.side == "W" and "Your turn. Select a white piece." or "Waiting for White to move.", self.side == "W" and colors.green or colors.muted)
        self:Refresh()
    end

    self.gameViews.CHESS = view
    return view
end

-- TETRIS ----------------------------------------------------------------------
local TETRIS_SHAPES = {
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
local TETRIS_KEYS = { "I", "O", "T", "S", "Z", "J", "L" }
local TETRIS_COLORS = {
    I = {0.15,0.75,0.90,1}, O={0.95,0.78,0.18,1}, T={0.62,0.32,0.90,1},
    S={0.20,0.75,0.35,1}, Z={0.90,0.22,0.25,1}, J={0.20,0.42,0.90,1}, L={0.95,0.48,0.14,1},
}
local TETRIS_REVEAL_SEGMENTS = 10

local function buildVersusRevealStrips(boardFrame, inset)
    boardFrame.revealStrips = {}
    local innerWidth = boardFrame:GetWidth() - inset * 2
    local innerHeight = boardFrame:GetHeight() - inset * 2
    local stripHeight = innerHeight / TETRIS_REVEAL_SEGMENTS
    for index = 1, TETRIS_REVEAL_SEGMENTS do
        local strip = boardFrame:CreateTexture(nil, "ARTWORK")
        if strip.SetDrawLayer then strip:SetDrawLayer("ARTWORK", -6) end
        strip:SetPoint("BOTTOMLEFT", boardFrame, "BOTTOMLEFT", inset, inset + (index - 1) * stripHeight)
        strip:SetSize(innerWidth, stripHeight + 1)
        strip:SetTexCoord(0, 1, 1 - index / TETRIS_REVEAL_SEGMENTS, 1 - (index - 1) / TETRIS_REVEAL_SEGMENTS)
        strip:Hide()
        boardFrame.revealStrips[index] = strip
    end
end
local function buildVersusBoardGrid(boardFrame, inset, cellSize, columns, rows)
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

local function updateVersusRevealStrips(boardFrame, theme, stage, alpha, revealing)
    if not boardFrame or not boardFrame.backgroundArt then return end
    local texture = theme and (theme.backgroundTexture or theme.texture) or nil
    stage = floor(max(0, min(TETRIS_REVEAL_SEGMENTS, tonumber(stage) or 0)))
    alpha = max(0, min(1, tonumber(alpha) or 0.68))

    if texture then
        boardFrame.backgroundArt:SetTexture(texture)
        boardFrame.backgroundArt:SetTexCoord(0, 1, 0, 1)
        if revealing then
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
local function tetrisRandom(view)
    view.rng = (view.rng * 1103515245 + 12345) % 2147483648
    return TETRIS_KEYS[(floor(view.rng / 65536) % 7) + 1]
end

function Games:BuildTETRISView()
    if self.gameViews.TETRIS then return self.gameViews.TETRIS end
    local colors = palette()
    local view = {
        game = "TETRIS",
        cells = {}, guides = {}, shines = {},
        remoteCells = {}, remoteShines = {},
        keyDown = {}, versusMode = "ENDLESS", durationMinutes = 10, topouts = 0, remoteTopouts = 0,
    }
    local frame = CreateFrame("Frame", nil, self.gameWindow.content, templateName())
    frame:SetAllPoints(); applyBackdrop(frame, colors.panelSoft, colors.panelSoft); frame:Hide(); view.frame = frame

    local cellSize = 16
    local function buildBoard(parent, anchorPoint, relative, relativePoint, xOffset, yOffset, cellStore, shineStore)
        local boardFrame = CreateFrame("Frame", nil, parent, templateName())
        boardFrame:SetSize(180, 340)
        boardFrame:SetPoint(anchorPoint, relative, relativePoint, xOffset, yOffset)
        applyBackdrop(boardFrame, colors.panel, colors.border)
        boardFrame.backgroundArt = boardFrame:CreateTexture(nil, "ARTWORK")
        if boardFrame.backgroundArt.SetDrawLayer then boardFrame.backgroundArt:SetDrawLayer("ARTWORK", -8) end
        boardFrame.backgroundArt:SetPoint("TOPLEFT", boardFrame, "TOPLEFT", 9, -9)
        boardFrame.backgroundArt:SetPoint("BOTTOMRIGHT", boardFrame, "BOTTOMRIGHT", -9, 9)
        boardFrame.backgroundArt:SetTexture("Interface\\Buttons\\WHITE8X8")
        boardFrame.backgroundArt:SetAlpha(0.34)
        buildVersusRevealStrips(boardFrame, 9)
        buildVersusBoardGrid(boardFrame, 10, cellSize, 10, 20)
        for y = 1, 20 do
            cellStore[y], shineStore[y] = {}, {}
            for x = 1, 10 do
                local cell = boardFrame:CreateTexture(nil, "ARTWORK")
                cell:SetTexture("Interface\\Buttons\\WHITE8X8")
                cell:SetSize(cellSize - 1, cellSize - 1)
                cell:SetPoint("BOTTOMLEFT", boardFrame, "BOTTOMLEFT", 10 + (x - 1) * cellSize, 10 + (y - 1) * cellSize)
                cell:SetColorTexture(0.07, 0.08, 0.10, 1)
                cellStore[y][x] = cell
                local shine = boardFrame:CreateTexture(nil, "OVERLAY")
                shine:SetTexture("Interface\\Buttons\\WHITE8X8")
                shine:SetPoint("TOPLEFT", cell, "TOPLEFT", 2, -2)
                shine:SetPoint("TOPRIGHT", cell, "TOPRIGHT", -2, -2)
                shine:SetHeight(2)
                shine:Hide()
                shineStore[y][x] = shine
            end
        end
        return boardFrame
    end

    view.modeBar = CreateFrame("Frame", nil, frame, templateName())
    view.modeBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
    view.modeBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -8)
    view.modeBar:SetHeight(30)
    applyBackdrop(view.modeBar, colors.panel, colors.border)
    view.modeEndless = createButton(view.modeBar, "TIMED ENDLESS", 126, 24, function() view:SetVersusMode("ENDLESS", true) end)
    view.modeEndless:SetPoint("LEFT", view.modeBar, "LEFT", 104, 0)
    view.modeAttack = createButton(view.modeBar, "ENDLESS ATTACK", 126, 24, function() view:SetVersusMode("ATTACK", true) end)
    view.modeAttack:SetPoint("LEFT", view.modeEndless, "RIGHT", 8, 0)
    view.durationButton = createButton(view.modeBar, "TIME: 10 MIN", 104, 24, function() view:CycleDuration() end)
    view.durationButton:SetPoint("LEFT", view.modeAttack, "RIGHT", 8, 0)

    view.localName = createText(frame, 10, colors.accent, "CENTER")
    view.localName:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -39)
    view.localName:SetWidth(180)
    view.localName:SetText("YOU")
    view.remoteName = createText(frame, 10, colors.gold, "CENTER")
    view.remoteName:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -39)
    view.remoteName:SetWidth(180)

    view.boardFrame = buildBoard(frame, "TOPLEFT", frame, "TOPLEFT", 10, -54, view.cells, view.shines)
    view.remoteBoardFrame = buildBoard(frame, "TOPRIGHT", frame, "TOPRIGHT", -10, -54, view.remoteCells, view.remoteShines)

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

    view.center = CreateFrame("Frame", nil, frame, templateName())
    view.center:SetPoint("TOPLEFT", view.boardFrame, "TOPRIGHT", 12, 0)
    view.center:SetPoint("RIGHT", view.remoteBoardFrame, "LEFT", -12, 0)
    view.center:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    applyBackdrop(view.center, colors.panel, colors.border)

    view.matchTitle = createText(view.center, 13, colors.text, "CENTER")
    view.matchTitle:SetPoint("TOPLEFT", view.center, "TOPLEFT", 8, -10)
    view.matchTitle:SetPoint("RIGHT", view.center, "RIGHT", -8, 0)
    view.matchTitle:SetText("TETRIS VERSUS")
    view.styleText = createText(view.center, 7, colors.muted, "CENTER")
    view.styleText:SetPoint("TOPLEFT", view.matchTitle, "BOTTOMLEFT", 0, -3)
    view.styleText:SetPoint("RIGHT", view.center, "RIGHT", -8, 0)
    view.styleText:SetText("BLOCK THEME · IMAGE BACKGROUND")

    view.versusCard = CreateFrame("Frame", nil, view.center, templateName())
    view.versusCard:SetPoint("TOPLEFT", view.styleText, "BOTTOMLEFT", 0, -6)
    view.versusCard:SetPoint("RIGHT", view.center, "RIGHT", -8, 0)
    view.versusCard:SetHeight(62)
    applyBackdrop(view.versusCard, colors.panelSoft, colors.border)
    view.localBlock = CreateFrame("Frame", nil, view.versusCard)
    view.localBlock:SetPoint("TOPLEFT", view.versusCard, "TOPLEFT", 7, -6)
    view.localBlock:SetPoint("BOTTOM", view.versusCard, "BOTTOM", 0, 6)
    view.localBlock:SetPoint("RIGHT", view.versusCard, "CENTER", -18, 0)
    view.localBlockTitle = createText(view.localBlock, 8, colors.accent, "CENTER")
    view.localBlockTitle:SetPoint("TOP", view.localBlock, "TOP", 0, 0)
    view.localBlockTitle:SetText("YOU")
    view.localLinesValue = createText(view.localBlock, 21, colors.text, "CENTER")
    view.localLinesValue:SetPoint("CENTER", view.localBlock, "CENTER", 0, 0)
    view.localScoreValue = createText(view.localBlock, 8, colors.muted, "CENTER")
    view.localScoreValue:SetPoint("BOTTOM", view.localBlock, "BOTTOM", 0, 0)

    view.vsBadge = CreateFrame("Frame", nil, view.versusCard, templateName())
    view.vsBadge:SetSize(34, 34)
    view.vsBadge:SetPoint("CENTER", view.versusCard, "CENTER", 0, 0)
    applyBackdrop(view.vsBadge, darken(colors.gold, 0.28), colors.gold)
    view.vsText = createText(view.vsBadge, 10, colors.gold, "CENTER")
    view.vsText:SetAllPoints(); view.vsText:SetText("VS")

    view.remoteBlock = CreateFrame("Frame", nil, view.versusCard)
    view.remoteBlock:SetPoint("TOPRIGHT", view.versusCard, "TOPRIGHT", -7, -6)
    view.remoteBlock:SetPoint("BOTTOM", view.versusCard, "BOTTOM", 0, 6)
    view.remoteBlock:SetPoint("LEFT", view.versusCard, "CENTER", 18, 0)
    view.remoteBlockTitle = createText(view.remoteBlock, 8, colors.gold, "CENTER")
    view.remoteBlockTitle:SetPoint("TOP", view.remoteBlock, "TOP", 0, 0)
    view.remoteLinesValue = createText(view.remoteBlock, 21, colors.text, "CENTER")
    view.remoteLinesValue:SetPoint("CENTER", view.remoteBlock, "CENTER", 0, 0)
    view.remoteScoreValue = createText(view.remoteBlock, 8, colors.muted, "CENTER")
    view.remoteScoreValue:SetPoint("BOTTOM", view.remoteBlock, "BOTTOM", 0, 0)

    view.lineBattle = CreateFrame("Frame", nil, view.center, templateName())
    view.lineBattle:SetPoint("TOPLEFT", view.versusCard, "BOTTOMLEFT", 0, -7)
    view.lineBattle:SetPoint("RIGHT", view.center, "RIGHT", -8, 0)
    view.lineBattle:SetHeight(47)
    applyBackdrop(view.lineBattle, colors.panelSoft, colors.border)
    view.lineBattleTitle = createText(view.lineBattle, 8, colors.muted, "CENTER")
    view.lineBattleTitle:SetPoint("TOPLEFT", view.lineBattle, "TOPLEFT", 6, -5)
    view.lineBattleTitle:SetPoint("RIGHT", view.lineBattle, "RIGHT", -6, 0)
    view.localLineBar = CreateFrame("StatusBar", nil, view.lineBattle)
    view.localLineBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    view.localLineBar:SetPoint("TOPLEFT", view.lineBattle, "TOPLEFT", 7, -19)
    view.localLineBar:SetPoint("RIGHT", view.lineBattle, "RIGHT", -7, 0)
    view.localLineBar:SetHeight(8)
    view.localLineBar:SetStatusBarColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.95)
    view.remoteLineBar = CreateFrame("StatusBar", nil, view.lineBattle)
    view.remoteLineBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    view.remoteLineBar:SetPoint("TOPLEFT", view.localLineBar, "BOTTOMLEFT", 0, -5)
    view.remoteLineBar:SetPoint("RIGHT", view.lineBattle, "RIGHT", -7, 0)
    view.remoteLineBar:SetHeight(8)
    view.remoteLineBar:SetStatusBarColor(colors.gold[1], colors.gold[2], colors.gold[3], 0.95)

    view.revealInfo = CreateFrame("Frame", nil, view.center, templateName())
    view.revealInfo:SetPoint("TOPLEFT", view.lineBattle, "BOTTOMLEFT", 0, -7)
    view.revealInfo:SetPoint("RIGHT", view.center, "RIGHT", -8, 0)
    view.revealInfo:SetHeight(50)
    applyBackdrop(view.revealInfo, colors.panelSoft, colors.border)
    view.revealInfoTitle = createText(view.revealInfo, 8, colors.text, "LEFT")
    view.revealInfoTitle:SetPoint("TOPLEFT", view.revealInfo, "TOPLEFT", 7, -5)
    view.revealInfoTitle:SetPoint("RIGHT", view.revealInfo, "RIGHT", -7, 0)
    view.revealInfoBar = CreateFrame("StatusBar", nil, view.revealInfo)
    view.revealInfoBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    view.revealInfoBar:SetPoint("TOPLEFT", view.revealInfoTitle, "BOTTOMLEFT", 0, -5)
    view.revealInfoBar:SetPoint("RIGHT", view.revealInfo, "RIGHT", -7, 0)
    view.revealInfoBar:SetHeight(9)
    view.revealInfoBar:SetMinMaxValues(0, 100)
    view.revealInfoBar:SetStatusBarColor(colors.green[1], colors.green[2], colors.green[3], 0.95)
    view.revealInfoText = createText(view.revealInfo, 7, colors.muted, "LEFT")
    view.revealInfoText:SetPoint("BOTTOMLEFT", view.revealInfo, "BOTTOMLEFT", 7, 5)
    view.revealInfoText:SetPoint("RIGHT", view.revealInfo, "RIGHT", -7, 0)

    view.garbageText = createText(view.center, 9, colors.gold, "CENTER")
    view.garbageText:SetPoint("TOPLEFT", view.revealInfo, "BOTTOMLEFT", 0, -7)
    view.garbageText:SetPoint("RIGHT", view.center, "RIGHT", -8, 0)
    view.garbageText:SetHeight(28)

    view.controlsPanel = CreateFrame("Frame", nil, view.center, templateName())
    view.controlsPanel:SetPoint("BOTTOMLEFT", view.center, "BOTTOMLEFT", 8, 43)
    view.controlsPanel:SetPoint("BOTTOMRIGHT", view.center, "BOTTOMRIGHT", -8, 43)
    view.controlsPanel:SetHeight(40)
    applyBackdrop(view.controlsPanel, colors.panelSoft, colors.border)
    view.help = createText(view.controlsPanel, 8, colors.muted, "CENTER")
    view.help:SetPoint("TOPLEFT", view.controlsPanel, "TOPLEFT", 5, -5)
    view.help:SetPoint("BOTTOMRIGHT", view.controlsPanel, "BOTTOMRIGHT", -5, 5)
    view.help:SetWordWrap(true)
    view.help:SetText("MOVE  A/D or arrows · ROTATE  W/Up · SOFT DROP  S/Down\nHARD DROP  Space · MODES  1/2 · TIME  3")

    view.left = createButton(view.center, "<", 42, 26, function() view:Move(-1, 0) end)
    view.left:SetPoint("BOTTOMLEFT", view.center, "BOTTOMLEFT", 20, 10)
    view.rotate = createButton(view.center, "ROT", 48, 26, function() view:Rotate() end)
    view.rotate:SetPoint("LEFT", view.left, "RIGHT", 5, 0)
    view.right = createButton(view.center, ">", 42, 26, function() view:Move(1, 0) end)
    view.right:SetPoint("LEFT", view.rotate, "RIGHT", 5, 0)
    view.drop = createButton(view.center, "DROP", 68, 26, function() view:HardDrop() end)
    view.drop:SetPoint("LEFT", view.right, "RIGHT", 5, 0)
    setButtonAccent(view.rotate, colors.accent); setButtonAccent(view.drop, colors.gold)

    local POWERS = { 1, 2, 4, 8, 16, 32, 64, 128, 256, 512 }
    local ATTACK_LINES = { [1] = 1, [2] = 2, [3] = 4, [4] = 6 }

    local function newBoard()
        local board = {}
        for y = 1, 20 do
            board[y] = {}
            for x = 1, 10 do board[y][x] = false end
        end
        return board
    end

    local function encodeBoard(board)
        local rows = {}
        for y = 1, 20 do
            local mask = 0
            for x = 1, 10 do if board[y] and board[y][x] then mask = mask + POWERS[x] end end
            rows[y] = format("%03X", mask)
        end
        return table.concat(rows, "")
    end

    local function decodeBoard(encoded)
        local board = newBoard()
        encoded = tostring(encoded or "")
        if string.len(encoded) < 60 then return board end
        for y = 1, 20 do
            local mask = tonumber(string.sub(encoded, (y - 1) * 3 + 1, y * 3), 16) or 0
            for x = 1, 10 do board[y][x] = floor(mask / POWERS[x]) % 2 == 1 end
        end
        return board
    end

    local function shapeCells(piece, rotation, px, py)
        local shape = TETRIS_SHAPES[piece]
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

    local ENDLESS_DURATIONS = { 5, 10, 15, 30, 45, 60 }

    function view:UpdateModeButtons()
        local mode = self.versusMode or "ENDLESS"
        local endless, attack = mode == "ENDLESS", mode == "ATTACK"
        applyBackdrop(self.modeEndless, endless and darken(colors.green, 0.28) or colors.panelRaised, endless and colors.green or colors.border)
        applyBackdrop(self.modeAttack, attack and darken(colors.gold, 0.22) or colors.panelRaised, attack and colors.gold or colors.border)
        self.modeEndless.creshSelected, self.modeAttack.creshSelected = endless, attack
        self.durationButton.label:SetText("TIME: " .. tostring(self.durationMinutes or 10) .. " MIN")
        setButtonEnabled(self.durationButton, endless)
        setButtonAccent(self.durationButton, endless and colors.green or colors.muted)
    end

    function view:CycleDuration()
        if self.versusMode ~= "ENDLESS" then return end
        local current, nextValue = self.durationMinutes or 10, ENDLESS_DURATIONS[1]
        for index, value in ipairs(ENDLESS_DURATIONS) do
            if value == current then nextValue = ENDLESS_DURATIONS[(index % #ENDLESS_DURATIONS) + 1]; break end
        end
        self:SetDuration(nextValue, true)
    end

    function view:SetDuration(minutes, broadcast)
        minutes = floor(tonumber(minutes) or 10)
        local valid = false
        for _, value in ipairs(ENDLESS_DURATIONS) do if value == minutes then valid = true; break end end
        if not valid then minutes = 10 end
        self.durationMinutes = minutes
        local save = CC.Tetris and CC.Tetris:Ensure() or nil
        if save then save.multiplayerDuration = minutes end
        self:UpdateModeButtons()
        if self.versusMode == "ENDLESS" and self.seed then
            if broadcast and Games.active then Games:SendGame("MODE", self.versusMode, self.seed or 1, minutes) end
            self:Start(self.seed, self.versusMode, true, minutes)
        end
    end

    function view:SetVersusMode(mode, broadcast)
        mode = upper(tostring(mode or "ENDLESS"))
        if mode ~= "ATTACK" then mode = "ENDLESS" end
        if self.versusMode == mode and self.board then self:UpdateModeButtons(); return end
        self.versusMode = mode
        local save = CC.Tetris and CC.Tetris:Ensure() or nil
        if save then save.multiplayerMode = mode end
        self:UpdateModeButtons()
        if broadcast and Games.active then Games:SendGame("MODE", mode, self.seed or 1, self.durationMinutes or 10) end
        if self.seed then self:Start(self.seed, mode, true, self.durationMinutes) end
    end

    function view:SendSnapshot()
        if not Games.active or not self.board then return end
        local theme = CC.Tetris and CC.Tetris:GetSelectedTheme() or nil
        local revealBackground, revealLines, _, isRevealing = nil, 100, 1, false
        if CC.Tetris and CC.Tetris.GetRevealProgress then
            revealBackground, revealLines, _, _, _, _, isRevealing = CC.Tetris:GetRevealProgress()
        elseif CC.Tetris and CC.Tetris.GetRevealTheme then
            revealBackground, revealLines, _, isRevealing = CC.Tetris:GetRevealTheme()
        end
        local revealStage = isRevealing and floor(max(0, min(10, (revealLines or 0) / 10))) or 10
        Games:SendGame("STAT", self.score or 0, self.lines or 0, self.alive and 1 or 0,
            encodeBoard(self.board), self.piece or "", self.rotation or 1, self.px or 4, self.py or 18,
            self.pendingGarbage or 0, theme and theme.key or "CLASSIC_BLOCKS", self.versusMode or "ENDLESS",
            self.durationMinutes or 10, floor(max(0, self.timeRemaining or 0)), self.topouts or 0,
            revealBackground and revealBackground.key or "", revealStage)
    end

    function view:FinishLocal(result, detail)
        if self.gameOver then return end
        self.gameOver = true; self.alive = false
        Games:SendGame("END", result, self.score or 0, self.lines or 0, encodeBoard(self.board or newBoard()))
        local modeName = self.versusMode == "ATTACK" and "Endless Attack" or "Timed Endless"
        Games:SetGameStatus("Your stack reached the top. " .. shortName(Games.active.opponent) .. " wins.", colors.red)
        Games:RecordResult("LOSS", (detail or "Topped out") .. " · " .. modeName)
        self:Refresh()
    end

    function view:FinishTimedHost()
        if self.gameOver or self.versusMode ~= "ENDLESS" then return end
        self.gameOver, self.alive = true, false
        local localResult = timedCompare(self.score, self.lines, self.topouts, self.remoteScore, self.remoteLines, self.remoteTopouts)
        local guestResult = localResult == "WIN" and "LOSS" or (localResult == "LOSS" and "WIN" or "DRAW")
        Games:SendGame("TIMEUP", guestResult, self.score or 0, self.lines or 0, encodeBoard(self.board or newBoard()), self.topouts or 0)
        local message = localResult == "WIN" and "Time expired — you win the Endless match!" or (localResult == "LOSS" and "Time expired — your opponent wins the Endless match." or "Time expired — Endless match drawn.")
        Games:SetGameStatus(message, localResult == "WIN" and colors.green or (localResult == "LOSS" and colors.red or colors.gold))
        Games:RecordResult(localResult, "Timed Endless · " .. tostring(self.durationMinutes or 10) .. " minutes")
        self:Refresh()
    end

    function view:AddGarbage(lines)
        lines = floor(max(0, tonumber(lines) or 0))
        if lines <= 0 or not self.board then return true end
        for _ = 1, lines do
            local topOccupied = false
            for x = 1, 10 do if self.board[20][x] then topOccupied = true; break end end
            remove(self.board, 20)
            self.garbageRng = ((self.garbageRng or 19) * 1103515245 + 12345) % 2147483648
            local hole = (floor(self.garbageRng / 65536) % 10) + 1
            local row = {}
            for x = 1, 10 do row[x] = x == hole and false or "G" end
            insert(self.board, 1, row)
            if topOccupied then self:FinishLocal("TOPPED", "Garbage pushed the stack over the top"); return false end
        end
        if self.piece and not self:CanPlace(self.piece, self.rotation, self.px, self.py) then
            self:FinishLocal("TOPPED", "Incoming garbage blocked the active piece")
            return false
        end
        return true
    end

    function view:ApplyPendingGarbage()
        local lines = floor(max(0, tonumber(self.pendingGarbage) or 0))
        self.pendingGarbage = 0
        if lines > 0 then self:AddGarbage(lines) end
    end

    function view:Spawn()
        self.piece = self.nextPiece or tetrisRandom(self)
        self.nextPiece = tetrisRandom(self)
        self.rotation, self.px, self.py = 1, 4, 18
        if not self:CanPlace(self.piece, self.rotation, self.px, self.py) then
            if self.versusMode == "ENDLESS" then
                self.topouts = (self.topouts or 0) + 1
                self.score = max(0, (self.score or 0) - 500)
                self.board = newBoard(); self.pendingGarbage = 0
                Games:SetGameStatus("Board reset after a top-out · -500 score. Timed Endless continues.", colors.gold)
                self.piece = nil; self.nextPiece = tetrisRandom(self)
                self:Spawn(); return
            end
            self:FinishLocal("TOPPED", "Topped out at " .. tostring(self.lines or 0) .. " lines")
        end
    end

    function view:Move(dx, dy)
        if not self.alive or self.gameOver then return false end
        if self:CanPlace(self.piece, self.rotation, self.px + dx, self.py + dy) then
            self.px, self.py = self.px + dx, self.py + dy
            self:Refresh(); return true
        end
        if dy < 0 then self:LockPiece() end
        return false
    end

    function view:Rotate()
        if not self.alive or self.gameOver then return end
        local nextRotation = (self.rotation % 4) + 1
        for _, kick in ipairs({ 0, -1, 1, -2, 2 }) do
            if self:CanPlace(self.piece, nextRotation, self.px + kick, self.py) then
                self.rotation, self.px = nextRotation, self.px + kick
                self:Refresh(); return
            end
        end
    end

    function view:HardDrop()
        if not self.alive or self.gameOver then return end
        local distance = 0
        while self:CanPlace(self.piece, self.rotation, self.px, self.py - 1) do self.py = self.py - 1; distance = distance + 1 end
        self.score = self.score + distance * 2
        self:LockPiece()
    end

    function view:LockPiece()
        if not self.alive then return end
        local lockedPiece = self.piece
        for _, point in ipairs(self:ShapeCells()) do self.board[point.y][point.x] = lockedPiece end
        self.piece = nil
        local cleared, y = 0, 1
        while y <= 20 do
            local full = true
            for x = 1, 10 do if not self.board[y][x] then full = false; break end end
            if full then
                remove(self.board, y)
                local row = {}; for x = 1, 10 do row[x] = false end
                insert(self.board, row); cleared = cleared + 1
            else y = y + 1 end
        end
        if cleared > 0 then
            local scores = { [1] = 100, [2] = 300, [3] = 500, [4] = 800 }
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
            if self.versusMode == "ATTACK" then
                local attack = ATTACK_LINES[cleared] or (cleared + 2)
                local cancelled = min(attack, self.pendingGarbage or 0)
                self.pendingGarbage = max(0, (self.pendingGarbage or 0) - cancelled)
                attack = attack - cancelled
                if attack > 0 then Games:SendGame("ATTACK", attack) end
            end
        else self.score = self.score + 10 end
        self.dropInterval = CC.Tetris and CC.Tetris:GetDropInterval(self.lines) or max(0.10, 0.90 - self.lines * 0.00008)
        if self.versusMode == "ATTACK" then self:ApplyPendingGarbage() end
        if not self.gameOver then self:Spawn() end
        self:SendSnapshot(); self:Refresh()
    end

    local function renderBoard(cellStore, shineStore, board, activePiece, activeRotation, activeX, activeY, theme, showGhost, guideStore, hasImageBackground)
        board = board or newBoard()
        local background = theme and theme.background or { 0.07, 0.08, 0.10, 1 }
        local highlight = theme and theme.highlight or colors.text
        local active, ghost, currentByColumn, landingByColumn = {}, {}, {}, {}
        if activePiece and canPlaceOn(board, activePiece, activeRotation or 1, activeX or 4, activeY or 18) then
            local landingY = activeY or 18
            while canPlaceOn(board, activePiece, activeRotation or 1, activeX or 4, landingY - 1) do landingY = landingY - 1 end
            for _, point in ipairs(shapeCells(activePiece, activeRotation or 1, activeX or 4, activeY or 18)) do
                active[point.y .. ":" .. point.x] = activePiece
                currentByColumn[point.x] = min(currentByColumn[point.x] or 99, point.y)
            end
            if showGhost then
                for _, point in ipairs(shapeCells(activePiece, activeRotation or 1, activeX or 4, landingY)) do
                    if not board[point.y][point.x] then ghost[point.y .. ":" .. point.x] = activePiece end
                    landingByColumn[point.x] = max(landingByColumn[point.x] or 0, point.y)
                end
            end
        end
        for _, guide in ipairs(guideStore or {}) do guide:Hide() end
        for y = 1, 20 do
            for x = 1, 10 do
                local activeValue = active[y .. ":" .. x]
                local boardValue = board[y][x]
                local ghostValue = ghost[y .. ":" .. x]
                local piece = activeValue or boardValue or ghostValue
                local color
                if piece == "G" or piece == true then
                    local key = TETRIS_KEYS[((x + y) % 7) + 1]
                    color = (theme and theme.colors[key]) or TETRIS_COLORS[key]
                elseif piece then color = (theme and theme.colors[piece]) or TETRIS_COLORS[piece]
                elseif hasImageBackground then color = { 0.008, 0.010, 0.016, 1 }
                else color = background end
                local alpha = 1
                if ghostValue and not activeValue and not boardValue then alpha = 0.14
                elseif not piece and hasImageBackground then alpha = 0.025 end
                cellStore[y][x]:SetColorTexture(color[1], color[2], color[3], alpha)
                if (activeValue or boardValue) and shineStore[y] and shineStore[y][x] then
                    shineStore[y][x]:SetColorTexture(highlight[1], highlight[2], highlight[3], 0.32)
                    shineStore[y][x]:Show()
                elseif shineStore[y] and shineStore[y][x] then shineStore[y][x]:Hide() end
            end
        end
        if guideStore and showGhost then
            local guideColor = theme and theme.guide or colors.accent
            for x, currentBottom in pairs(currentByColumn) do
                local landingTop = landingByColumn[x] or 0
                local gap = currentBottom - landingTop - 1
                local guide = guideStore[x]
                if guide and gap > 0 then
                    guide:ClearAllPoints()
                    guide:SetPoint("BOTTOMLEFT", guide.boardFrame, "BOTTOMLEFT", 10 + (x - 1) * cellSize + 7, 10 + landingTop * cellSize + 2)
                    guide:SetSize(1, max(1, gap * cellSize - 4))
                    guide:SetColorTexture(min(1, guideColor[1] + 0.16), min(1, guideColor[2] + 0.16), min(1, guideColor[3] + 0.16), 0.19)
                    guide:Show()
                end
            end
        end
    end

    function view:Refresh()
        if not self.board then return end
        local localTheme = CC.Tetris and CC.Tetris:GetSelectedTheme() or nil
        local localBackground, revealLines, localRevealStage, linesToNextPart, linesToUnlock, _, isRevealing = nil, 100, 10, 0, 0, 1, false
        if CC.Tetris and CC.Tetris.GetRevealProgress then
            localBackground, revealLines, localRevealStage, linesToNextPart, linesToUnlock, _, isRevealing = CC.Tetris:GetRevealProgress()
        elseif CC.Tetris and CC.Tetris.GetRevealTheme then
            localBackground, revealLines, _, isRevealing = CC.Tetris:GetRevealTheme()
            localRevealStage = isRevealing and floor(max(0, min(10, (revealLines or 0) / 10))) or 10
            linesToNextPart = isRevealing and (10 - ((revealLines or 0) % 10)) or 0
            linesToUnlock = isRevealing and max(0, 100 - (revealLines or 0)) or 0
        end
        local localBoardBackground = localBackground
        if self.completedRevealTheme and (self.revealTransitionRemaining or 0) > 0 then
            localBoardBackground, revealLines, localRevealStage, linesToNextPart, linesToUnlock, isRevealing = self.completedRevealTheme, 100, 10, 0, 0, false
        end
        local remoteTheme = CC.Tetris and CC.Tetris:GetTheme(self.remoteThemeKey or "CLASSIC_BLOCKS") or localTheme
        local remoteBoardBackground = nil
        if CC.Tetris and self.remoteRevealThemeKey and self.remoteRevealThemeKey ~= "" and CC.Tetris.GetBackground then
            remoteBoardBackground = CC.Tetris:GetBackground(self.remoteRevealThemeKey)
        end
        local remoteRevealStage = floor(max(0, min(10, tonumber(self.remoteRevealStage) or 10)))
        local remoteRevealing = remoteBoardBackground and remoteRevealStage < 10
        local localBackdrop = localBoardBackground and {0.006,0.008,0.014,1} or ((localTheme and localTheme.background) or colors.panel)
        local remoteBackdrop = remoteBoardBackground and {0.006,0.008,0.014,1} or ((remoteTheme and remoteTheme.background) or colors.panel)
        applyBackdrop(self.boardFrame, localBackdrop, localTheme and localTheme.guide or colors.accent)
        applyBackdrop(self.remoteBoardFrame, remoteBackdrop, remoteTheme and remoteTheme.guide or colors.gold)
        updateVersusRevealStrips(self.boardFrame, localBoardBackground, localRevealStage, 0.58, isRevealing)
        updateVersusRevealStrips(self.remoteBoardFrame, remoteBoardBackground, remoteRevealStage, 0.40, remoteRevealing)
        if not localBoardBackground then self.boardFrame.backgroundArt:SetColorTexture(localBackdrop[1], localBackdrop[2], localBackdrop[3], 1) end
        if not remoteBoardBackground then self.remoteBoardFrame.backgroundArt:SetColorTexture(remoteBackdrop[1], remoteBackdrop[2], remoteBackdrop[3], 1) end
        renderBoard(self.cells, self.shines, self.board, self.alive and self.piece or nil, self.rotation, self.px, self.py, localTheme, true, self.guides, localBoardBackground ~= nil)
        renderBoard(self.remoteCells, self.remoteShines, self.remoteBoard, self.remoteAlive and self.remotePiece or nil, self.remoteRotation, self.remotePX, self.remotePY, remoteTheme, false, nil, remoteBoardBackground ~= nil)
        self.remoteName:SetText(upper(shortName(Games.active and Games.active.opponent or "OPPONENT")))
        local mode = self.versusMode or "ENDLESS"
        local targetText = mode == "ENDLESS" and format("%02d:%02d LEFT", floor((self.timeRemaining or 0) / 60), floor((self.timeRemaining or 0) % 60)) or "NO LINE LIMIT"
        self.matchTitle:SetText(mode == "ENDLESS" and ("TIMED ENDLESS · " .. tostring(self.durationMinutes or 10) .. " MIN") or "ENDLESS ATTACK")
        self.styleText:SetText("BLOCKS · " .. (localTheme and localTheme.name or "Classic Blocks") .. "  |  IMAGE · " .. (localBoardBackground and localBoardBackground.name or "None"))
        local speedLevel = CC.Tetris and CC.Tetris:GetGameLevel(self.lines or 0) or (1 + floor((self.lines or 0) / 10))
        self.localBlockTitle:SetText("YOU · LV " .. tostring(speedLevel))
        self.localLinesValue:SetText(tostring(self.lines or 0))
        self.localScoreValue:SetText(format("%d score · %.2fs drop · %d resets", self.score or 0, self.dropInterval or 0.90, self.topouts or 0))
        self.remoteBlockTitle:SetText(upper(shortName(Games.active and Games.active.opponent or "OPPONENT")))
        self.remoteLinesValue:SetText(tostring(self.remoteLines or 0))
        self.remoteScoreValue:SetText(format("%d score · %d/10 reveal · %d resets", self.remoteScore or 0, remoteRevealStage, self.remoteTopouts or 0))
        local maxLines = max(10, self.lines or 0, self.remoteLines or 0)
        self.localLineBar:SetMinMaxValues(0, maxLines); self.localLineBar:SetValue(self.lines or 0)
        self.remoteLineBar:SetMinMaxValues(0, maxLines); self.remoteLineBar:SetValue(self.remoteLines or 0)
        self.lineBattleTitle:SetText(format("LINE BATTLE · YOU %d  |  %s %d", self.lines or 0, upper(shortName(Games.active and Games.active.opponent or "THEM")), self.remoteLines or 0))
        local revealName = localBoardBackground and localBoardBackground.name or "No image background"
        if isRevealing then
            self.revealInfoTitle:SetText(revealName .. " · next image row in " .. tostring(linesToNextPart) .. " lines")
            self.revealInfoBar:SetValue(revealLines or 0)
            self.revealInfoText:SetText(tostring(revealLines or 0) .. "/100 · full image in " .. tostring(linesToUnlock) .. " lines · opponent " .. tostring(remoteRevealStage) .. "/10")
        else
            self.revealInfoTitle:SetText(revealName .. " · background unlocked")
            self.revealInfoBar:SetValue(100)
            self.revealInfoText:SetText("FULL IMAGE UNLOCKED · opponent reveal " .. tostring(remoteRevealStage) .. "/10")
        end
        if mode == "ATTACK" then
            self.vsText:SetText(tostring(self.pendingGarbage or 0) .. "/" .. tostring(self.remotePendingGarbage or 0))
            self.garbageText:SetText("GARBAGE · incoming " .. tostring(self.pendingGarbage or 0) .. " · clears cancel or send lines")
        else
            self.vsText:SetText("VS")
            self.garbageText:SetText(targetText .. " · top-outs reset the board with a score penalty")
        end
        self:UpdateModeButtons()
    end

    function view:OnKeyDown(key)
        key = upper(tostring(key or ""))
        if key == "A" or key == "LEFT" then self:Move(-1, 0)
        elseif key == "D" or key == "RIGHT" then self:Move(1, 0)
        elseif key == "W" or key == "UP" then self:Rotate()
        elseif key == "S" or key == "DOWN" then self:Move(0, -1)
        elseif key == "SPACE" then self:HardDrop()
        elseif key == "1" then self:SetVersusMode("ENDLESS", true)
        elseif key == "2" then self:SetVersusMode("ATTACK", true)
        elseif key == "3" then self:CycleDuration() end
    end

    function view:OnUpdate(elapsed)
        elapsed = elapsed or 0
        if self.revealTransitionRemaining and self.revealTransitionRemaining > 0 then
            self.revealTransitionRemaining = max(0, self.revealTransitionRemaining - elapsed)
            if self.revealTransitionRemaining <= 0 then self.completedRevealTheme = nil; self:Refresh() end
        end
        if not self.alive or self.gameOver then return end
        self.dropElapsed = (self.dropElapsed or 0) + elapsed
        self.statElapsed = (self.statElapsed or 0) + elapsed
        if self.versusMode == "ENDLESS" then
            self.matchElapsed = (self.matchElapsed or 0) + elapsed
            self.timeRemaining = max(0, (self.durationMinutes or 10) * 60 - self.matchElapsed)
            if self.timeRemaining <= 0 and Games.active and Games.active.host then self:FinishTimedHost(); return end
        end
        if self.dropElapsed >= self.dropInterval then self.dropElapsed = self.dropElapsed - self.dropInterval; self:Move(0, -1) end
        if self.statElapsed >= 0.50 then self.statElapsed = 0; self:SendSnapshot() end
    end

    function view:OnMessage(op, parts)
        if op == "STAT" then
            self.remoteScore = tonumber(parts[5]) or 0
            self.remoteLines = tonumber(parts[6]) or 0
            self.remoteAlive = tonumber(parts[7]) ~= 0
            self.remoteBoard = decodeBoard(parts[8])
            self.remotePiece = tostring(parts[9] or "")
            if self.remotePiece == "" then self.remotePiece = nil end
            self.remoteRotation = tonumber(parts[10]) or 1
            self.remotePX = tonumber(parts[11]) or 4
            self.remotePY = tonumber(parts[12]) or 18
            self.remotePendingGarbage = tonumber(parts[13]) or 0
            self.remoteThemeKey = tostring(parts[14] or "CLASSIC_BLOCKS")
            local remoteMode = upper(tostring(parts[15] or self.versusMode or "ENDLESS"))
            if remoteMode == "RACE" then remoteMode = "ENDLESS" end
            if remoteMode == "ENDLESS" or remoteMode == "ATTACK" then self.versusMode = remoteMode end
            self.durationMinutes = tonumber(parts[16]) or self.durationMinutes or 10
            self.remoteTimeRemaining = tonumber(parts[17]) or self.remoteTimeRemaining or 0
            self.remoteTopouts = tonumber(parts[18]) or self.remoteTopouts or 0
            self.remoteRevealThemeKey = tostring(parts[19] or self.remoteThemeKey or "")
            self.remoteRevealStage = floor(max(0, min(10, tonumber(parts[20]) or 10)))
            if self.versusMode == "ENDLESS" and not (Games.active and Games.active.host) then self.timeRemaining = self.remoteTimeRemaining end
            self:Refresh()
        elseif op == "ATTACK" and self.versusMode == "ATTACK" and not self.gameOver then
            local lines = floor(max(0, tonumber(parts[5]) or 0))
            self.pendingGarbage = (self.pendingGarbage or 0) + lines
            Games:SetGameStatus(shortName(Games.active.opponent) .. " sent " .. tostring(lines) .. " garbage line" .. (lines == 1 and "" or "s") .. ".", colors.gold)
            self:Refresh()
        elseif op == "MODE" then
            local mode = upper(tostring(parts[5] or "ENDLESS"))
            local seed = tonumber(parts[6]) or self.seed or 1
            local duration = tonumber(parts[7]) or self.durationMinutes or 10
            self:Start(seed, mode, true, duration)
        elseif op == "TIMEUP" and not self.gameOver then
            local result = upper(tostring(parts[5] or "DRAW"))
            self.remoteScore = tonumber(parts[6]) or self.remoteScore or 0
            self.remoteLines = tonumber(parts[7]) or self.remoteLines or 0
            self.remoteBoard = decodeBoard(parts[8])
            self.remoteTopouts = tonumber(parts[9]) or self.remoteTopouts or 0
            self.gameOver, self.alive, self.remoteAlive = true, false, false
            local message = result == "WIN" and "Time expired — you win the Endless match!" or (result == "LOSS" and "Time expired — your opponent wins the Endless match." or "Time expired — Endless match drawn.")
            Games:SetGameStatus(message, result == "WIN" and colors.green or (result == "LOSS" and colors.red or colors.gold))
            Games:RecordResult(result, "Timed Endless · " .. tostring(self.durationMinutes or 10) .. " minutes")
            self:Refresh()
        elseif op == "END" and not self.gameOver then
            local result = upper(tostring(parts[5] or "TOPPED"))
            self.remoteScore = tonumber(parts[6]) or self.remoteScore or 0
            self.remoteLines = tonumber(parts[7]) or self.remoteLines or 0
            self.remoteBoard = decodeBoard(parts[8])
            self.remoteAlive = false
            self.gameOver = true; self.alive = false
            Games:SetGameStatus(shortName(Games.active.opponent) .. " topped out. You win!", colors.green)
            Games:RecordResult("WIN", self.versusMode == "ATTACK" and "Opponent topped out in Endless Attack" or "Opponent topped out")
            self:Refresh()
        end
    end

    function view:Start(seed, mode, fromNetwork, durationMinutes)
        self.seed = tonumber(seed) or 1
        self.rng = self.seed
        self.garbageRng = self.seed + 991
        local tetrisSave = CC.Tetris and CC.Tetris:Ensure() or nil
        mode = upper(tostring(mode or (tetrisSave and tetrisSave.multiplayerMode) or self.versusMode or "ENDLESS"))
        if mode ~= "ATTACK" then mode = "ENDLESS" end
        self.versusMode = mode
        local save = CC.Tetris and CC.Tetris:Ensure() or nil
        self.durationMinutes = tonumber(durationMinutes) or (save and save.multiplayerDuration) or self.durationMinutes or 10
        if self.durationMinutes ~= 5 and self.durationMinutes ~= 10 and self.durationMinutes ~= 15 and self.durationMinutes ~= 30 and self.durationMinutes ~= 45 and self.durationMinutes ~= 60 then self.durationMinutes = 10 end
        if save then save.multiplayerMode = mode; save.multiplayerDuration = self.durationMinutes end
        self.board = newBoard(); self.remoteBoard = newBoard()
        self.score, self.lines, self.remoteScore, self.remoteLines = 0, 0, 0, 0
        self.pendingGarbage, self.remotePendingGarbage = 0, 0
        self.topouts, self.remoteTopouts = 0, 0
        self.matchElapsed, self.timeRemaining = 0, self.durationMinutes * 60
        self.remoteAlive, self.alive, self.gameOver = true, true, false
        self.remotePiece, self.remoteRotation, self.remotePX, self.remotePY = nil, 1, 4, 18
        self.remoteRevealThemeKey, self.remoteRevealStage = "", 0
        self.completedRevealTheme, self.revealTransitionRemaining = nil, 0
        self.dropElapsed, self.statElapsed, self.dropInterval = 0, 0, (CC.Tetris and CC.Tetris:GetDropInterval(0) or 0.90)
        self.nextPiece = tetrisRandom(self)
        self:Spawn(); self:Refresh(); self:SendSnapshot()
        if mode == "ATTACK" then
            Games:SetGameStatus("Endless Attack started. Clear lines to send garbage and survive the longest.", colors.green)
        else
            Games:SetGameStatus("Timed Endless started for " .. tostring(self.durationMinutes) .. " minutes. Top-outs reset the board and play continues.", colors.green)
        end
        if not fromNetwork and Games.active and Games.active.host then Games:SendGame("MODE", mode, self.seed, self.durationMinutes) end
    end

    self.gameViews.TETRIS = view
    return view
end
-- PONG ------------------------------------------------------------------------
function Games:BuildPONGView()
    if self.gameViews.PONG then return self.gameViews.PONG end
    local colors = palette()
    local view = { game = "PONG", keyDown = {} }
    local frame = CreateFrame("Frame", nil, self.gameWindow.content, templateName())
    frame:SetAllPoints(); applyBackdrop(frame, colors.panelSoft, colors.panelSoft); frame:Hide(); view.frame = frame

    view.field = CreateFrame("Frame", nil, frame, templateName())
    view.field:SetSize(540, 380); view.field:SetPoint("TOP", frame, "TOP", 0, -12); applyBackdrop(view.field, {0.015,0.018,0.024,1}, colors.border)
    view.centerLine = view.field:CreateTexture(nil, "ARTWORK")
    view.centerLine:SetTexture("Interface\\Buttons\\WHITE8X8"); view.centerLine:SetSize(2, 350); view.centerLine:SetPoint("CENTER"); view.centerLine:SetColorTexture(colors.border[1], colors.border[2], colors.border[3], 0.7)
    view.leftPaddle = view.field:CreateTexture(nil, "OVERLAY"); view.leftPaddle:SetTexture("Interface\\Buttons\\WHITE8X8"); view.leftPaddle:SetSize(10, 70); view.leftPaddle:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1)
    view.rightPaddle = view.field:CreateTexture(nil, "OVERLAY"); view.rightPaddle:SetTexture("Interface\\Buttons\\WHITE8X8"); view.rightPaddle:SetSize(10, 70); view.rightPaddle:SetColorTexture(colors.gold[1], colors.gold[2], colors.gold[3], 1)
    view.ball = view.field:CreateTexture(nil, "OVERLAY"); view.ball:SetTexture("Interface\\Buttons\\WHITE8X8"); view.ball:SetSize(12, 12); view.ball:SetColorTexture(1,1,1,1)
    view.score = createText(view.field, 22, colors.text, "CENTER"); view.score:SetPoint("TOP", view.field, "TOP", 0, -12); view.score:SetText("0  :  0")
    view.leftName = createText(view.field, 9, colors.accent, "LEFT"); view.leftName:SetPoint("BOTTOMLEFT", view.field, "BOTTOMLEFT", 12, 8)
    view.rightName = createText(view.field, 9, colors.gold, "RIGHT"); view.rightName:SetPoint("BOTTOMRIGHT", view.field, "BOTTOMRIGHT", -12, 8)

    view.controls = createText(frame, 9, colors.muted, "CENTER")
    view.controls:SetPoint("TOP", view.field, "BOTTOM", 0, -10); view.controls:SetText("W / S or Up / Down moves your paddle · First to 5")
    view.up = createButton(frame, "UP", 70, 28, function() view:MovePaddle(40) end); view.up:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 184, 8)
    view.down = createButton(frame, "DOWN", 70, 28, function() view:MovePaddle(-40) end); view.down:SetPoint("LEFT", view.up, "RIGHT", 12, 0)
    setButtonAccent(view.up, colors.accent); setButtonAccent(view.down, colors.accent)

    function view:MovePaddle(delta)
        if self.gameOver then return end
        self.localPaddle = clamp((self.localPaddle or 155) + delta, 0, 280)
        if not Games.active.host then Games:SendGame("PADDLE", floor(self.localPaddle + 0.5)) end
        self:Refresh()
    end

    function view:ResetBall(direction)
        self.ballX, self.ballY = 264, 174
        local speed = 210
        self.ballVX = (direction or 1) * speed
        self.ballVY = ((self.scoreLeft + self.scoreRight) % 2 == 0 and 1 or -1) * 115
        self.serveDelay = 0.8
    end

    function view:Refresh()
        local leftY = Games.active.host and self.localPaddle or self.remotePaddle
        local rightY = Games.active.host and self.remotePaddle or self.localPaddle
        self.leftPaddle:ClearAllPoints(); self.leftPaddle:SetPoint("BOTTOMLEFT", self.field, "BOTTOMLEFT", 18, 15 + (leftY or 155))
        self.rightPaddle:ClearAllPoints(); self.rightPaddle:SetPoint("BOTTOMRIGHT", self.field, "BOTTOMRIGHT", -18, 15 + (rightY or 155))
        self.ball:ClearAllPoints(); self.ball:SetPoint("BOTTOMLEFT", self.field, "BOTTOMLEFT", 6 + (self.ballX or 264), 6 + (self.ballY or 174))
        self.score:SetText(tostring(self.scoreLeft or 0) .. "  :  " .. tostring(self.scoreRight or 0))
        self.leftName:SetText(Games.active.host and "YOU" or upper(shortName(Games.active.opponent)))
        self.rightName:SetText(Games.active.host and upper(shortName(Games.active.opponent)) or "YOU")
    end

    function view:HostUpdateBall(elapsed)
        if self.serveDelay and self.serveDelay > 0 then self.serveDelay = self.serveDelay - elapsed; return end
        self.ballX = self.ballX + self.ballVX * elapsed
        self.ballY = self.ballY + self.ballVY * elapsed
        if self.ballY <= 0 then self.ballY = 0; self.ballVY = abs(self.ballVY)
        elseif self.ballY >= 348 then self.ballY = 348; self.ballVY = -abs(self.ballVY) end

        local leftY, rightY = self.localPaddle or 155, self.remotePaddle or 155
        if self.ballVX < 0 and self.ballX <= 30 and self.ballX >= 16 and self.ballY + 12 >= leftY and self.ballY <= leftY + 70 then
            self.ballX = 30; self.ballVX = abs(self.ballVX) * 1.035
            self.ballVY = self.ballVY + ((self.ballY + 6) - (leftY + 35)) * 4
        elseif self.ballVX > 0 and self.ballX >= 498 and self.ballX <= 516 and self.ballY + 12 >= rightY and self.ballY <= rightY + 70 then
            self.ballX = 498; self.ballVX = -abs(self.ballVX) * 1.035
            self.ballVY = self.ballVY + ((self.ballY + 6) - (rightY + 35)) * 4
        end

        if self.ballX < -18 then
            self.scoreRight = self.scoreRight + 1
            self:AfterScore("R")
        elseif self.ballX > 550 then
            self.scoreLeft = self.scoreLeft + 1
            self:AfterScore("L")
        end
    end

    function view:AfterScore(side)
        if self.scoreLeft >= 5 or self.scoreRight >= 5 then
            self.gameOver = true
            local winner = self.scoreLeft >= 5 and "H" or "G"
            Games:SendGame("END", winner, self.scoreLeft, self.scoreRight)
            Games:SetGameStatus(winner == Games.active.role and "You win Pong!" or shortName(Games.active.opponent) .. " wins Pong.", winner == Games.active.role and colors.green or colors.red)
            Games:RecordResult(winner == Games.active.role and "WIN" or "LOSS", tostring(self.scoreLeft) .. "–" .. tostring(self.scoreRight))
        else self:ResetBall(side == "L" and -1 or 1) end
    end

    function view:SendState()
        Games:SendGame("STATE", floor(self.ballX + 0.5), floor(self.ballY + 0.5), floor(self.ballVX + 0.5), floor(self.ballVY + 0.5), floor(self.localPaddle + 0.5), floor(self.remotePaddle + 0.5), self.scoreLeft, self.scoreRight)
    end

    function view:OnKeyDown(key)
        key = upper(tostring(key or ""))
        if key == "W" or key == "UP" then self.keyDown.UP = true
        elseif key == "S" or key == "DOWN" then self.keyDown.DOWN = true end
    end
    function view:OnKeyUp(key)
        key = upper(tostring(key or ""))
        if key == "W" or key == "UP" then self.keyDown.UP = false
        elseif key == "S" or key == "DOWN" then self.keyDown.DOWN = false end
    end

    function view:OnUpdate(elapsed)
        if self.gameOver then return end
        local direction = (self.keyDown.UP and 1 or 0) - (self.keyDown.DOWN and 1 or 0)
        if direction ~= 0 then self.localPaddle = clamp(self.localPaddle + direction * 250 * elapsed, 0, 280) end
        self.networkElapsed = self.networkElapsed + elapsed
        if Games.active.host then
            self:HostUpdateBall(elapsed)
            if self.networkElapsed >= 0.12 then self.networkElapsed = 0; self:SendState() end
        else
            if self.networkElapsed >= 0.12 then self.networkElapsed = 0; Games:SendGame("PADDLE", floor(self.localPaddle + 0.5)) end
        end
        self:Refresh()
    end

    function view:OnMessage(op, parts)
        if op == "PADDLE" and Games.active.host then
            self.remotePaddle = clamp(tonumber(parts[5]) or self.remotePaddle, 0, 280)
        elseif op == "STATE" and not Games.active.host then
            self.ballX, self.ballY = tonumber(parts[5]) or self.ballX, tonumber(parts[6]) or self.ballY
            self.ballVX, self.ballVY = tonumber(parts[7]) or self.ballVX, tonumber(parts[8]) or self.ballVY
            self.remotePaddle = clamp(tonumber(parts[9]) or self.remotePaddle, 0, 280)
            self.scoreLeft, self.scoreRight = tonumber(parts[11]) or 0, tonumber(parts[12]) or 0
            self:Refresh()
        elseif op == "END" then
            self.gameOver = true
            local winner = parts[5]
            self.scoreLeft, self.scoreRight = tonumber(parts[6]) or self.scoreLeft, tonumber(parts[7]) or self.scoreRight
            Games:SetGameStatus(winner == Games.active.role and "You win Pong!" or shortName(Games.active.opponent) .. " wins Pong.", winner == Games.active.role and colors.green or colors.red)
            Games:RecordResult(winner == Games.active.role and "WIN" or "LOSS", tostring(self.scoreLeft) .. "–" .. tostring(self.scoreRight))
            self:Refresh()
        end
    end

    function view:Start()
        self.localPaddle, self.remotePaddle = 155, 155
        self.scoreLeft, self.scoreRight = 0, 0
        self.ballX, self.ballY, self.ballVX, self.ballVY = 264, 174, 210, 115
        self.serveDelay, self.networkElapsed, self.gameOver = 0.8, 0, false
        self.keyDown = {}
        Games:SetGameStatus(Games.active.host and "You serve first. First to 5 wins." or "Connected to host. First to 5 wins.", colors.green)
        self:Refresh()
        if Games.active.host then self:SendState() end
    end

    self.gameViews.PONG = view
    return view
end

-- TEXAS HOLD'EM ---------------------------------------------------------------
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

local function holdemRng(state)
    state.value = (state.value * 1103515245 + 12345) % 2147483648
    return state.value
end

local function holdemDeck(seed)
    local deck = {}; for card = 1, 52 do deck[card] = card end
    local state = { value = tonumber(seed) or 1 }
    for index = 52, 2, -1 do
        local swap = (holdemRng(state) % index) + 1
        deck[index], deck[swap] = deck[swap], deck[index]
    end
    return deck
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
    local unique = {}; for rank in pairs(counts) do unique[#unique + 1] = rank end
    sort(unique, function(a,b) return a>b end)
    local straightHigh
    local sequence = {}; for _, rank in ipairs(unique) do sequence[rank] = true end
    if sequence[14] and sequence[5] and sequence[4] and sequence[3] and sequence[2] then straightHigh = 5 end
    for high = 14, 6, -1 do
        if sequence[high] and sequence[high-1] and sequence[high-2] and sequence[high-3] and sequence[high-4] then straightHigh = high; break end
    end
    local flush = false; for _, count in pairs(suits) do if count == 5 then flush = true end end
    local groups = {}
    for rank, count in pairs(counts) do groups[#groups + 1] = { count=count, rank=rank } end
    sort(groups, function(a,b) if a.count ~= b.count then return a.count > b.count end return a.rank > b.rank end)
    if flush and straightHigh then return {8, straightHigh} end
    if groups[1].count == 4 then return {7, groups[1].rank, groups[2].rank} end
    if groups[1].count == 3 and groups[2].count == 2 then return {6, groups[1].rank, groups[2].rank} end
    if flush then return {5, unpack(ranks)} end
    if straightHigh then return {4, straightHigh} end
    if groups[1].count == 3 then
        local kickers = {}; for _, group in ipairs(groups) do if group.count == 1 then kickers[#kickers+1] = group.rank end end
        sort(kickers, function(a,b) return a>b end)
        return {3, groups[1].rank, kickers[1], kickers[2]}
    end
    if groups[1].count == 2 and groups[2].count == 2 then
        local highPair, lowPair = max(groups[1].rank, groups[2].rank), min(groups[1].rank, groups[2].rank)
        local kicker; for _, group in ipairs(groups) do if group.count == 1 then kicker = group.rank end end
        return {2, highPair, lowPair, kicker}
    end
    if groups[1].count == 2 then
        local kickers = {}; for _, group in ipairs(groups) do if group.count == 1 then kickers[#kickers+1] = group.rank end end
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

function Games:BuildHOLDEMView()
    if self.gameViews.HOLDEM then return self.gameViews.HOLDEM end
    local colors = palette()
    local view = { game = "HOLDEM", actionIndex = 1 }
    local frame = CreateFrame("Frame", nil, self.gameWindow.content, templateName())
    frame:SetAllPoints(); applyBackdrop(frame, colors.panelSoft, colors.panelSoft); frame:Hide(); view.frame = frame

    view.table = CreateFrame("Frame", nil, frame, templateName())
    view.table:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -12); view.table:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -12); view.table:SetHeight(330)
    applyBackdrop(view.table, {0.025,0.20,0.09,1}, {0.10,0.42,0.20,1})
    view.phase = createText(view.table, 12, colors.text, "CENTER"); view.phase:SetPoint("TOP", view.table, "TOP", 0, -12)
    view.pot = createText(view.table, 14, colors.gold, "CENTER"); view.pot:SetPoint("TOP", view.phase, "BOTTOM", 0, -8)
    view.deckButton = createButton(view.table, "DECK", 174, 26, function(_, mouseButton)
        if CC.CardDecks then CC.CardDecks:Cycle("HOLDEM", mouseButton == "RightButton" and -1 or 1) end
        if view.deckButton and view.deckButton.RefreshDeck then view.deckButton:RefreshDeck() end
        view:Refresh()
    end)
    view.deckButton:SetPoint("TOPLEFT", view.table, "TOPLEFT", 10, -9)
    setButtonAccent(view.deckButton, colors.gold)
    if CC.CardDecks and CC.CardDecks.StyleDeckButton then CC.CardDecks:StyleDeckButton(view.deckButton, "HOLDEM") end

    view.communityCards = {}
    for index = 1, 5 do
        local card = CreateFrame("Frame", nil, view.table, templateName())
        card:SetSize(58, 78); card:SetPoint("CENTER", view.table, "CENTER", (index - 3) * 66, 0); applyBackdrop(card, {0.90,0.90,0.86,1}, colors.border)
        card.text = createText(card, 16, {0.08,0.08,0.10,1}, "CENTER"); card.text:SetAllPoints(); card.text:SetText("--")
        card.creshDeckGameKey = "HOLDEM"
        view.communityCards[index] = card
    end

    view.myCards = {}
    for index = 1, 2 do
        local card = CreateFrame("Frame", nil, view.table, templateName())
        card:SetSize(54, 72); card:SetPoint("BOTTOM", view.table, "BOTTOM", (index == 1 and -31 or 31), 18); applyBackdrop(card, {0.94,0.94,0.90,1}, colors.border)
        card.text = createText(card, 15, {0.08,0.08,0.10,1}, "CENTER"); card.text:SetAllPoints(); card.text:SetText("--")
        card.creshDeckGameKey = "HOLDEM"
        view.myCards[index] = card
    end
    view.oppCards = {}
    for index = 1, 2 do
        local card = CreateFrame("Frame", nil, view.table, templateName())
        card:SetSize(48, 64); card:SetPoint("TOP", view.table, "TOP", (index == 1 and -28 or 28), -42); applyBackdrop(card, darken(colors.accent,0.25), colors.accent)
        card.text = createText(card, 13, colors.text, "CENTER"); card.text:SetAllPoints(); card.text:SetText("??")
        card.creshDeckGameKey = "HOLDEM"
        view.oppCards[index] = card
    end
    view.myLabel = createText(view.table, 10, colors.text, "LEFT"); view.myLabel:SetPoint("BOTTOMLEFT", view.table, "BOTTOMLEFT", 12, 18)
    view.oppLabel = createText(view.table, 10, colors.text, "RIGHT"); view.oppLabel:SetPoint("TOPRIGHT", view.table, "TOPRIGHT", -12, -18)

    view.info = createText(frame, 10, colors.text, "LEFT")
    view.info:SetPoint("TOPLEFT", view.table, "BOTTOMLEFT", 4, -12); view.info:SetPoint("RIGHT", frame, "RIGHT", -20, 0); view.info:SetHeight(58); view.info:SetWordWrap(true)
    view.fold = createButton(frame, "FOLD", 94, 32, function() view:ChooseAction("FOLD") end)
    view.fold:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 64, 18); setButtonAccent(view.fold, colors.red)
    view.call = createButton(frame, "CHECK / CALL", 124, 32, function() view:ChooseAction("CALL") end)
    view.call:SetPoint("LEFT", view.fold, "RIGHT", 12, 0); setButtonAccent(view.call, colors.accent)
    view.bet = createButton(frame, "BET / RAISE 5", 126, 32, function() view:ChooseAction("BET") end)
    view.bet:SetPoint("LEFT", view.call, "RIGHT", 12, 0); setButtonAccent(view.bet, colors.gold)
    view.nextHand = createButton(frame, "NEXT HAND", 106, 32, function() if Games.active.host then view:StartHostHand() end end)
    view.nextHand:SetPoint("LEFT", view.bet, "RIGHT", 12, 0); setButtonAccent(view.nextHand, colors.green); view.nextHand:Hide()
    view.actionButtons = { view.fold, view.call, view.bet }

    function view:RoleName(role)
        return role == Games.active.role and "You" or shortName(Games.active.opponent)
    end

    function view:SetCard(frameCard, card, hidden)
        if hidden then
            applyBackdrop(frameCard, darken(colors.accent, 0.25), colors.accent)
            if CC.CardDecks and CC.CardDecks.ApplyCardFrame and CC.CardDecks:ApplyCardFrame(frameCard, card, true, "HOLDEM") then return end
            if frameCard.cardTexture then frameCard.cardTexture:Hide() end
            frameCard.text:Show(); frameCard.text:SetText("??"); frameCard.text:SetTextColor(1,1,1,1)
        else
            applyBackdrop(frameCard, {0.94,0.94,0.90,1}, colors.border)
            if CC.CardDecks and CC.CardDecks.ApplyCardFrame and CC.CardDecks:ApplyCardFrame(frameCard, card, false, "HOLDEM") then return end
            if frameCard.cardTexture then frameCard.cardTexture:Hide() end
            frameCard.text:Show(); frameCard.text:SetText(cardLabel(card)); frameCard.text:SetTextColor(0.08,0.08,0.10,1)
        end
    end

    function view:Refresh()
        if self.deckButton and self.deckButton.RefreshDeck then self.deckButton:RefreshDeck() end
        self.phase:SetText(self.phaseName or "WAITING")
        self.pot:SetText("POT: " .. tostring(self.potValue or 0))
        for index = 1, 5 do self:SetCard(self.communityCards[index], self.community[index], self.community[index] == nil) end
        for index = 1, 2 do self:SetCard(self.myCards[index], self.myHole[index], self.myHole[index] == nil) end
        for index = 1, 2 do self:SetCard(self.oppCards[index], self.oppHole[index], not self.revealOpponent) end
        local myRole = Games.active.role
        local oppRole = myRole == "H" and "G" or "H"
        self.myLabel:SetText(format("YOU · %d CHIPS%s", self.chips[myRole] or 0, self.dealer == myRole and " · DEALER" or ""))
        self.oppLabel:SetText(format("%s · %d CHIPS%s", upper(shortName(Games.active.opponent)), self.chips[oppRole] or 0, self.dealer == oppRole and " · DEALER" or ""))
        local owed = max(0, (self.currentBet or 0) - (self.streetBets[myRole] or 0))
        local actionText = self.toAct == myRole and (owed > 0 and ("Your turn · Call " .. owed .. ", raise or fold") or "Your turn · Check, bet or fold") or (self.toAct and ("Waiting for " .. self:RoleName(self.toAct)) or (self.resultText or "Waiting"))
        self.info:SetText(actionText .. (self.resultText and ("\n" .. self.resultText) or ""))
        local enabled = self.toAct == myRole and not self.handOver
        for index, button in ipairs(self.actionButtons) do setButtonEnabled(button, enabled); button.creshSelected = enabled and index == self.actionIndex end
        self.call.label:SetText(owed > 0 and ("CALL " .. owed) or "CHECK")
        self.nextHand:SetShown(self.handOver and Games.active.host)
    end

    function view:BroadcastState()
        if not Games.active.host then return end
        Games:SendGame("STATE", self.phaseName, self.potValue, self.chips.H, self.chips.G, self.dealer, self.toAct or "-", self.currentBet, self.streetBets.H, self.streetBets.G, join(self.community, ","), self.handOver and 1 or 0)
    end

    function view:SendHole()
        self.myHole = { self.holes.H[1], self.holes.H[2] }
        Games:SendGame("HOLE", self.holes.G[1], self.holes.G[2])
    end

    function view:DealCommunity(count)
        for _ = 1, count do self.community[#self.community + 1] = remove(self.deck) end
    end

    function view:Pay(role, amount)
        amount = min(max(0, floor(amount or 0)), self.chips[role])
        self.chips[role] = self.chips[role] - amount
        self.streetBets[role] = (self.streetBets[role] or 0) + amount
        self.potValue = self.potValue + amount
        return amount
    end

    function view:StartHostHand()
        if not Games.active.host then return end
        self.handNumber = (self.handNumber or 0) + 1
        self.handOver, self.revealOpponent, self.resultText = false, false, nil
        self.oppHole = {}
        self.deck = holdemDeck((Games.active.seed or 1) + self.handNumber * 7919)
        self.holes = { H = { remove(self.deck), remove(self.deck) }, G = { remove(self.deck), remove(self.deck) } }
        self.community = {}
        self.dealer = self.handNumber % 2 == 1 and "H" or "G"
        self.chips = self.chips or { H = 100, G = 100 }
        if self.chips.H <= 0 or self.chips.G <= 0 then self.chips = { H = 100, G = 100 } end
        self.potValue, self.streetBets, self.currentBet = 0, {H=0,G=0}, 0
        self.phaseName = "PREFLOP"
        local small, big = self.dealer, self.dealer == "H" and "G" or "H"
        self:Pay(small, 1); self:Pay(big, 2); self.currentBet = 2
        self.acted = {H=false,G=false}; self.toAct = small
        self:SendHole(); self:BroadcastState(); self:Refresh()
        Games:SetGameStatus("New hand dealt. Blinds are 1 / 2.", colors.green)
    end

    function view:StreetComplete()
        return self.acted.H and self.acted.G and self.streetBets.H == self.streetBets.G
    end

    function view:BalanceAllIn()
        local difference = (self.streetBets.H or 0) - (self.streetBets.G or 0)
        if difference == 0 then return end
        local high = difference > 0 and "H" or "G"
        local refund = abs(difference)
        self.streetBets[high] = self.streetBets[high] - refund
        self.chips[high] = self.chips[high] + refund
        self.potValue = self.potValue - refund
        self.currentBet = min(self.streetBets.H, self.streetBets.G)
    end

    function view:AdvanceStreet()
        if self.chips.H == 0 or self.chips.G == 0 then self:BalanceAllIn() end
        self.streetBets, self.currentBet, self.acted = {H=0,G=0}, 0, {H=false,G=false}
        if self.phaseName == "PREFLOP" then self.phaseName = "FLOP"; self:DealCommunity(3)
        elseif self.phaseName == "FLOP" then self.phaseName = "TURN"; self:DealCommunity(1)
        elseif self.phaseName == "TURN" then self.phaseName = "RIVER"; self:DealCommunity(1)
        elseif self.phaseName == "RIVER" then self:Showdown(); return end
        if self.chips.H == 0 or self.chips.G == 0 then
            while #self.community < 5 do self:DealCommunity(1) end
            self.phaseName = "SHOWDOWN"
            self:Showdown()
            return
        end
        self.toAct = self.dealer == "H" and "G" or "H"
        self:BroadcastState(); self:Refresh()
    end

    function view:FinishFold(folder)
        local winner = folder == "H" and "G" or "H"
        self.chips[winner] = self.chips[winner] + self.potValue
        self.handOver, self.toAct = true, nil
        self.resultText = self:RoleName(folder) .. " folded. " .. self:RoleName(winner) .. " wins " .. self.potValue .. " chips."
        Games:SendGame("SHOW", winner, "Fold", self.holes.H[1], self.holes.H[2], self.holes.G[1], self.holes.G[2], self.chips.H, self.chips.G)
        self.revealOpponent = true
        local opponentRole = Games.active.role == "H" and "G" or "H"
        self.oppHole = { self.holes[opponentRole][1], self.holes[opponentRole][2] }
        self:BroadcastState(); self:Refresh(); Games:SetGameStatus(self.resultText, winner == Games.active.role and colors.green or colors.red)
        Games:RecordResult(winner == Games.active.role and "WIN" or "LOSS", "Hold'em hand · fold", self.handNumber or 0)
    end

    function view:Showdown()
        self.phaseName = "SHOWDOWN"
        local rankH = bestSeven({ self.holes.H[1], self.holes.H[2], unpack(self.community) })
        local rankG = bestSeven({ self.holes.G[1], self.holes.G[2], unpack(self.community) })
        local comparison = compareRanks(rankH, rankG)
        local winner = comparison > 0 and "H" or (comparison < 0 and "G" or "T")
        if winner == "T" then
            local half = floor(self.potValue / 2); self.chips.H = self.chips.H + half; self.chips.G = self.chips.G + (self.potValue - half)
            self.resultText = "Split pot · " .. HAND_NAMES[rankH[1]]
        else
            self.chips[winner] = self.chips[winner] + self.potValue
            local winningRank = winner == "H" and rankH or rankG
            self.resultText = self:RoleName(winner) .. " wins with " .. HAND_NAMES[winningRank[1]] .. "."
        end
        self.handOver, self.toAct, self.revealOpponent = true, nil, true
        self.oppHole = Games.active.role == "H" and {self.holes.G[1],self.holes.G[2]} or {self.holes.H[1],self.holes.H[2]}
        Games:SendGame("SHOW", winner, self.resultText, self.holes.H[1], self.holes.H[2], self.holes.G[1], self.holes.G[2], self.chips.H, self.chips.G)
        self:BroadcastState(); self:Refresh(); Games:SetGameStatus(self.resultText, winner == "T" and colors.gold or (winner == Games.active.role and colors.green or colors.red))
        Games:RecordResult(winner == "T" and "DRAW" or (winner == Games.active.role and "WIN" or "LOSS"), self.resultText, self.handNumber or 0)
    end

    function view:HostAction(role, action)
        if self.handOver or self.toAct ~= role then return false end
        action = upper(action or "")
        local other = role == "H" and "G" or "H"
        if action == "FOLD" then self:FinishFold(role); return true end
        local owed = max(0, self.currentBet - self.streetBets[role])
        if action == "BET" then
            local target = self.currentBet + 5
            local opponentMaximum = (self.streetBets[other] or 0) + (self.chips[other] or 0)
            target = min(target, opponentMaximum)
            local needed = target - self.streetBets[role]
            if needed > self.chips[role] then needed = self.chips[role]; target = self.streetBets[role] + needed end
            if needed <= owed then action = "CALL" else
                self:Pay(role, needed); self.currentBet = max(self.currentBet, self.streetBets[role])
                self.acted[role], self.acted[other], self.toAct = true, false, other
            end
        end
        if action == "CALL" then
            self:Pay(role, owed); self.acted[role] = true
            if self:StreetComplete() or self.chips.H == 0 or self.chips.G == 0 then self:AdvanceStreet() else self.toAct = other end
        end
        self:BroadcastState(); self:Refresh()
        return true
    end

    function view:ChooseAction(action)
        if self.handOver or self.toAct ~= Games.active.role then return end
        if Games.active.host then self:HostAction("H", action) else Games:SendGame("ACTION", action) end
    end

    function view:OnKeyDown(key)
        key = upper(tostring(key or ""))
        if key == "A" or key == "W" or key == "LEFT" or key == "UP" then self.actionIndex = self.actionIndex - 1; if self.actionIndex < 1 then self.actionIndex = #self.actionButtons end; self:Refresh()
        elseif key == "D" or key == "S" or key == "RIGHT" or key == "DOWN" then self.actionIndex = self.actionIndex + 1; if self.actionIndex > #self.actionButtons then self.actionIndex = 1 end; self:Refresh()
        elseif key == "SPACE" or key == "ENTER" then local actions={"FOLD","CALL","BET"}; self:ChooseAction(actions[self.actionIndex]) end
    end

    function view:OnMessage(op, parts)
        if op == "ACTION" and Games.active.host then
            self:HostAction("G", parts[5])
        elseif op == "HOLE" and not Games.active.host then
            self.myHole = { tonumber(parts[5]), tonumber(parts[6]) }; self:Refresh()
        elseif op == "STATE" and not Games.active.host then
            local wasHandOver = self.handOver == true
            local incomingPhase = parts[5]
            local incomingHandOver = tonumber(parts[15]) == 1
            self.phaseName, self.potValue = incomingPhase, tonumber(parts[6]) or 0
            if not incomingHandOver and (wasHandOver or incomingPhase == "PREFLOP") then
                self.revealOpponent, self.resultText, self.oppHole = false, nil, {}
            end
            self.chips = { H = tonumber(parts[7]) or 0, G = tonumber(parts[8]) or 0 }
            self.dealer, self.toAct = parts[9], parts[10] ~= "-" and parts[10] or nil
            self.currentBet = tonumber(parts[11]) or 0
            self.streetBets = { H = tonumber(parts[12]) or 0, G = tonumber(parts[13]) or 0 }
            self.community = {}; for _, card in ipairs(split(parts[14] or "", ",")) do if tonumber(card) then self.community[#self.community+1] = tonumber(card) end end
            self.handOver = incomingHandOver
            self:Refresh()
        elseif op == "SHOW" then
            local winner, text = parts[5], parts[6]
            local h1,h2,g1,g2 = tonumber(parts[7]),tonumber(parts[8]),tonumber(parts[9]),tonumber(parts[10])
            self.chips = { H = tonumber(parts[11]) or self.chips.H, G = tonumber(parts[12]) or self.chips.G }
            self.handOver, self.toAct, self.revealOpponent, self.resultText = true, nil, true, text
            self.oppHole = Games.active.role == "H" and {g1,g2} or {h1,h2}
            self.historyHand = (self.historyHand or 0) + 1
            self:Refresh(); Games:SetGameStatus(text, winner == "T" and colors.gold or (winner == Games.active.role and colors.green or colors.red))
            Games:RecordResult(winner == "T" and "DRAW" or (winner == Games.active.role and "WIN" or "LOSS"), text, self.historyHand)
        end
    end

    function view:Start()
        self.phaseName, self.potValue = "WAITING", 0
        self.chips, self.streetBets, self.community = {H=100,G=100}, {H=0,G=0}, {}
        self.currentBet, self.toAct, self.dealer, self.handOver = 0, nil, "H", false
        self.myHole, self.oppHole, self.revealOpponent, self.resultText = {}, {}, false, nil
        self.historyHand = 0
        self.actionIndex = 2
        self:Refresh()
        if Games.active.host then self:StartHostHand() else Games:SetGameStatus("Waiting for the host to deal the first hand.", colors.muted) end
    end

    self.gameViews.HOLDEM = view
    return view
end

function Games:ApplyTheme()
    local colors = palette()
    if self.hub then
        applyBackdrop(self.hub, colors.panelSoft, colors.panelSoft)
        if self.hub.banner then applyBackdrop(self.hub.banner, darken(colors.accent, 0.30), colors.accent) end
        if self.hub.scan then setButtonAccent(self.hub.scan, colors.accent) end
        if self.hub.targetButton then setButtonAccent(self.hub.targetButton, colors.accent) end
        for _, button in pairs(self.hub.gameButtons or {}) do setButtonAccent(button, colors.accent) end
        if self.hub.resume then setButtonAccent(self.hub.resume, colors.green) end
    end
    if self.challengePopup then applyBackdrop(self.challengePopup, colors.panel, colors.accent) end
    if self.gameWindow then
        applyBackdrop(self.gameWindow, colors.panel, colors.border)
        if self.gameWindow.header then applyBackdrop(self.gameWindow.header, colors.panelRaised, colors.border) end
        if self.gameWindow.statusBar then applyBackdrop(self.gameWindow.statusBar, colors.panelSoft, colors.border) end
        if self.gameWindow.content then applyBackdrop(self.gameWindow.content, colors.panelSoft, colors.panelSoft) end
    end
    self:RefreshHub()
    local active = self.active
    local view = active and self.gameViews[active.game]
    if view and view.Refresh then view:Refresh() end
end

-- Addon event bridge -----------------------------------------------------------
local eventFrame = CreateFrame("Frame", "CreshGamesEventFrame")
for _, eventName in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "CHAT_MSG_ADDON", "PLAYER_LOGOUT", "FRIENDLIST_UPDATE", "GROUP_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE", "PLAYER_TARGET_CHANGED" }) do pcall(eventFrame.RegisterEvent, eventFrame, eventName) end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loaded = ...
        if loaded == ADDON_NAME or loaded == CC.name then Games:RegisterPrefix() end
    elseif event == "PLAYER_LOGIN" then
        Games:RegisterPrefix()
        if _G.C_Timer and type(_G.C_Timer.After) == "function" then _G.C_Timer.After(2, function() Games:RefreshHub() end) end
    elseif event == "CHAT_MSG_ADDON" then
        if CC:IsFeatureEnabled("multiplayerGames") then Games:HandleAddonMessage(...) end
    elseif event == "FRIENDLIST_UPDATE" or event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_TARGET_CHANGED" then
        if CC.UI and CC.UI.RefreshGameDrawer then CC.UI:RefreshGameDrawer(true) end
    elseif event == "PLAYER_LOGOUT" then
        if Games.active then Games:Send(Games.active.opponent, "X", Games.active.id, "Logged out") end
    end
end)
