local ADDON_NAME, CC = ...
if not CC or not CC.UI or not CC.Notifications then return end

-- Unified notification card for the Cresh suite (Phase 3 visual + Phase 4 stack).
-- Owns: card pool, passive stack, actionable lane, queue, 4-direction layout,
--       screen clamping, entry/exit animations, hover-pause, right-click dismiss.
-- Producer migration (Phase 5-7) and unified settings (Phase 8) follow.

local Notifications = CC.Notifications

-- ----------------------------------------------------------------
-- Semantic accent colours  { r, g, b, a }
-- ----------------------------------------------------------------

local ACCENT = {
    ONLINE             = { 0.28, 0.85, 0.48, 1 },
    OFFLINE            = { 0.48, 0.52, 0.60, 1 },
    SUCCESS            = { 0.28, 0.85, 0.48, 1 },
    WHISPER            = { 0.25, 0.82, 0.90, 1 },
    PARTY              = { 0.28, 0.55, 1.00, 1 },
    GUILD              = { 0.38, 0.88, 0.55, 1 },
    GAME               = { 0.68, 0.32, 1.00, 1 },
    ACHIEVEMENT        = { 0.95, 0.76, 0.22, 1 },
    REWARD             = { 1.00, 0.72, 0.15, 1 },
    BATTLEPASS         = { 0.95, 0.76, 0.22, 1 },
    DUNGEONPASS        = { 0.38, 0.88, 0.55, 1 },
    WARNING            = { 1.00, 0.68, 0.20, 1 },
    ERROR              = { 1.00, 0.32, 0.30, 1 },
    INFO               = { 0.44, 0.64, 0.94, 1 },
}
local ACCENT_DEFAULT = { 0.44, 0.64, 0.94, 1 }

local CATEGORY_ACCENT = {
    WHISPER = ACCENT.WHISPER, BN_WHISPER = ACCENT.WHISPER,
    GUILD   = ACCENT.GUILD,   OFFICER    = ACCENT.GUILD,
    PARTY_INVITE   = ACCENT.PARTY, PARTY_MESSAGE  = ACCENT.PARTY,
    FRIEND  = ACCENT.ONLINE,  PRESENCE   = ACCENT.ONLINE,
    GAME    = ACCENT.GAME,    BATTLE_PASS = ACCENT.BATTLEPASS,
    GAME_INVITE = ACCENT.GAME, GAME_RESULT = ACCENT.GAME,
    CHALLENGE   = ACCENT.GAME, MULTIPLAYER_EVENT = ACCENT.GAME,
    REWARD      = ACCENT.REWARD, ACHIEVEMENT = ACCENT.ACHIEVEMENT,
    ACHIEVEMENT_PROGRESS = ACCENT.ACHIEVEMENT,
    COLLECTION_UNLOCK = ACCENT.REWARD, COSMETIC_REWARD = ACCENT.REWARD,
    MILESTONE = ACCENT.REWARD,
}

local function resolveAccent(status, category)
    return ACCENT[string.upper(tostring(status   or ""))]
        or CATEGORY_ACCENT[string.upper(tostring(category or ""))]
        or ACCENT_DEFAULT
end

-- ----------------------------------------------------------------
-- Layout and animation constants
-- ----------------------------------------------------------------

local CARD_W       = 300
local CARD_H       = 72
local ICON_SIZE    = 40
local BADGE_SIZE   = 18
local ACCENT_H     = 3
local BTN_W, BTN_H = 58, 18
local ANIM_DUR     = 0.20   -- entry / exit animation seconds
local ANIM_OFFSET  = 44     -- entry slide distance in screen pixels

-- ----------------------------------------------------------------
-- Runtime config helpers
-- ----------------------------------------------------------------

local function getDir()
    if not CC.db or not CC.db.ui then return "UP" end
    local d = string.upper(tostring(CC.db.ui.notifStackDirection or CC.db.ui.cardStack or "UP"))
    if d ~= "UP" and d ~= "DOWN" and d ~= "LEFT" and d ~= "RIGHT" then return "UP" end
    return d
end

local function getMaxVisible()
    if not CC.db or not CC.db.ui then return 3 end
    return math.max(1, math.min(10, math.floor(
        tonumber(CC.db.ui.notifMaxVisible) or tonumber(CC.db.ui.cardMaxVisible) or 3
    )))
end

local function getMaxActionable()
    if not CC.db or not CC.db.ui then return 3 end
    return math.max(1, math.min(6, math.floor(tonumber(CC.db.ui.notifMaxActionable) or 3)))
end

local function getScale()
    if not CC.db or not CC.db.ui then return 0.95 end
    return math.max(0.65, math.min(1.50, tonumber(CC.db.ui.notificationScale) or 0.95))
end

local function getBase()
    local x, y = 18, 148
    if CC.UI and CC.UI.GetNotificationHubAnchor then
        x, y = CC.UI:GetNotificationHubAnchor()
    end
    return x, y
end

local function getCardW()
    if not CC.db or not CC.db.ui then return 300 end
    return math.max(200, math.min(500, math.floor(tonumber(CC.db.ui.cardWidth) or 300)))
end

local function getCardH()
    if not CC.db or not CC.db.ui then return 72 end
    return math.max(40, math.min(120, math.floor(tonumber(CC.db.ui.cardHeight) or 72)))
end

local function getGap()
    if not CC.db or not CC.db.ui then return 6 end
    return math.max(0, math.min(20, math.floor(tonumber(CC.db.ui.cardSpacing) or 6)))
end

local function getAccentH()
    if not CC.db or not CC.db.ui then return 3 end
    return math.max(1, math.min(8, math.floor(tonumber(CC.db.ui.notificationLineHeight) or 3)))
end

local function getDurNormal()
    if not CC.db or not CC.db.ui then return 8 end
    return math.max(1, math.min(60, tonumber(CC.db.ui.priorityCardDuration) or 8))
end

local function getDurHigh()
    if not CC.db or not CC.db.ui then return 14 end
    return math.max(1, math.min(60, tonumber(CC.db.ui.secondaryCardDuration) or 14))
end

-- ----------------------------------------------------------------
-- Frame helpers
-- ----------------------------------------------------------------

local FONT        = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local BD_TEMPLATE = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
local CARD_BD = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
local BTN_BD = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local function applyBackdrop(f, bd, r, g, b, a, er, eg, eb, ea)
    if f.SetBackdrop then
        f:SetBackdrop(bd)
        f:SetBackdropColor(r, g, b, a)
        f:SetBackdropBorderColor(er, eg, eb, ea)
    end
end

local function makeFont(parent, size, r, g, b, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size, "")
    fs:SetTextColor(r, g, b, 1)
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function makeButton(parent, labelText, w, h, onClick)
    local btn = CreateFrame("Button", nil, parent, BD_TEMPLATE)
    btn:SetSize(w, h)
    applyBackdrop(btn, BTN_BD, 0.12, 0.14, 0.18, 0.90, 0.26, 0.30, 0.38, 0.70)
    btn.label = makeFont(btn, 9, 0.85, 0.88, 0.92, "CENTER")
    btn.label:SetAllPoints(btn)
    btn.label:SetText(labelText)
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.50, 0.62, 0.90, 1) end
    end)
    btn:SetScript("OnLeave", function(self)
        if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.26, 0.30, 0.38, 0.70) end
    end)
    return btn
end

-- ----------------------------------------------------------------
-- Card construction
-- ----------------------------------------------------------------

local function buildCard()
    local card = CreateFrame("Button", nil, UIParent, BD_TEMPLATE)
    card:SetSize(CARD_W, CARD_H)
    card:SetScale(0.95)
    card:SetClampedToScreen(false)
    card:EnableMouse(true)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card:SetFrameStrata("FULLSCREEN_DIALOG")
    card:Hide()
    applyBackdrop(card, CARD_BD, 0.08, 0.09, 0.11, 0.92, 0.18, 0.20, 0.25, 0.80)

    card.iconBg = card:CreateTexture(nil, "BACKGROUND")
    card.iconBg:SetSize(ICON_SIZE, ICON_SIZE)
    card.iconBg:SetPoint("LEFT", card, "LEFT", 10, 0)
    card.iconBg:SetColorTexture(0.12, 0.14, 0.18, 1)

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(ICON_SIZE - 4, ICON_SIZE - 4)
    card.icon:SetPoint("CENTER", card.iconBg, "CENTER", 0, 0)
    card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    card.icon:Hide()

    card.badge = card:CreateTexture(nil, "OVERLAY")
    card.badge:SetSize(BADGE_SIZE, BADGE_SIZE)
    card.badge:SetPoint("BOTTOMRIGHT", card.iconBg, "BOTTOMRIGHT", 3, -3)
    card.badge:Hide()

    card.iconInitial = makeFont(card, 15, 0.72, 0.76, 0.85, "CENTER")
    card.iconInitial:SetPoint("CENTER", card.iconBg, "CENTER", 0, 0)

    card.title = makeFont(card, 11, 0.92, 0.93, 0.95, "LEFT")
    card.title:SetPoint("TOPLEFT", card.iconBg, "TOPRIGHT",  9, -2)
    card.title:SetPoint("RIGHT",   card,        "RIGHT",   -46,  0)
    if card.title.SetMaxLines then card.title:SetMaxLines(1) end

    card.timeText = makeFont(card, 9, 0.48, 0.52, 0.58, "RIGHT")
    card.timeText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -8, -7)
    card.timeText:SetWidth(40)

    card.detail = makeFont(card, 10, 0.60, 0.63, 0.68, "LEFT")
    card.detail:SetPoint("TOPLEFT", card.title,  "BOTTOMLEFT", 0, -3)
    card.detail:SetPoint("RIGHT",   card,        "RIGHT",     -8,  0)
    if card.detail.SetMaxLines then card.detail:SetMaxLines(2) end
    if card.detail.SetWordWrap  then card.detail:SetWordWrap(true) end

    card.accentBar = card:CreateTexture(nil, "ARTWORK")
    card.accentBar:SetPoint("BOTTOMLEFT",  card, "BOTTOMLEFT",   1, 1)
    card.accentBar:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card.accentBar:SetHeight(ACCENT_H)
    card.accentBar:SetColorTexture(ACCENT_DEFAULT[1], ACCENT_DEFAULT[2], ACCENT_DEFAULT[3], 1)

    card.btnAccept = makeButton(card, "ACCEPT",  BTN_W, BTN_H, function(self)
        local o = self:GetParent(); if o._onAccept  then o._onAccept(o)  end end)
    card.btnAccept:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.btnAccept:Hide()

    card.btnDecline = makeButton(card, "DECLINE", BTN_W, BTN_H, function(self)
        local o = self:GetParent(); if o._onDecline then o._onDecline(o) end end)
    card.btnDecline:SetPoint("RIGHT", card.btnAccept, "LEFT", -5, 0)
    card.btnDecline:Hide()

    card.btnReply = makeButton(card, "REPLY", 50, BTN_H, function(self)
        local o = self:GetParent(); if o._onReply   then o._onReply(o)   end end)
    card.btnReply:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.btnReply:Hide()

    card:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            Notifications:DismissCard(self)
        elseif button == "LeftButton" and self._onPrimary then
            self._onPrimary(self)
        end
    end)
    card:SetScript("OnEnter", function(self)
        self._hovered = true
        self._pausedRemaining = math.max(0.5, (self._expiresAt or GetTime()) - GetTime())
        self:SetAlpha(1)
        if self._tooltipTitle and self._tooltipTitle ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
            GameTooltip:SetText(self._tooltipTitle, 1, 1, 1, 1, true)
            if self._tooltipBody and self._tooltipBody ~= "" then
                GameTooltip:AddLine(self._tooltipBody, 0.72, 0.76, 0.82, true)
            end
            GameTooltip:Show()
        end
    end)
    card:SetScript("OnLeave", function(self)
        self._hovered   = false
        self._expiresAt = GetTime() + math.max(0.5, self._pausedRemaining or getDurNormal())
        self._pausedRemaining = nil
        GameTooltip:Hide()
    end)

    return card
end

-- ----------------------------------------------------------------
-- Card pool state
-- ----------------------------------------------------------------

local cardPool           = {}
local activePassiveCards = {}   -- passive / standard lane (max MaxVisible)
local activeActionCards  = {}   -- actionable lane (no slot cap)
local cardQueue          = {}   -- pending passive events (FIFO)

Notifications._cardPool           = cardPool
Notifications._activePassiveCards = activePassiveCards
Notifications._activeActionCards  = activeActionCards
Notifications._cardQueue          = cardQueue

-- ----------------------------------------------------------------
-- AcquireCard
-- ----------------------------------------------------------------

function Notifications:AcquireCard()
    local card = table.remove(cardPool)
    if not card then card = buildCard() end
    return card
end

-- ----------------------------------------------------------------
-- RecycleCard  (immediate — called after exit animation completes)
-- ----------------------------------------------------------------

function Notifications:RecycleCard(card)
    if not card then return end
    card:Hide()
    card:SetScript("OnUpdate", nil)

    for i = #activePassiveCards, 1, -1 do
        if activePassiveCards[i] == card then table.remove(activePassiveCards, i); break end
    end
    for i = #activeActionCards, 1, -1 do
        if activeActionCards[i] == card then table.remove(activeActionCards, i); break end
    end

    -- Clear animation state
    card._entering        = false
    card._exiting         = false
    card._enterElapsed    = nil
    card._exitElapsed     = nil
    card._currentX        = nil
    card._currentY        = nil
    card._targetX         = nil
    card._targetY         = nil
    card._entryDir        = nil
    card._cardScale       = nil
    -- Clear notification state
    card._hovered         = false
    card._expiresAt       = nil
    card._pausedRemaining = nil
    card._onAccept        = nil
    card._onDecline       = nil
    card._onReply         = nil
    card._onPrimary       = nil
    card._coalesceKey     = nil
    card._tooltipTitle    = nil
    card._tooltipBody     = nil
    card._sourceAddon     = nil
    card._category        = nil
    card._id              = nil
    -- Clear visuals
    card.title:SetText("")
    card.detail:SetText("")
    card.timeText:SetText("")
    card.iconInitial:SetText("")
    card.icon:SetTexture(nil)
    card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    card.icon:SetDesaturated(false)
    card.icon:Hide()
    card.badge:SetTexture(nil)
    card.badge:Hide()
    card.accentBar:SetColorTexture(ACCENT_DEFAULT[1], ACCENT_DEFAULT[2], ACCENT_DEFAULT[3], 1)
    card.iconBg:SetColorTexture(0.12, 0.14, 0.18, 1)
    card.btnAccept:Hide()
    card.btnDecline:Hide()
    card.btnReply:Hide()
    if card.btnAccept.label  then card.btnAccept.label:SetText("ACCEPT")   end
    if card.btnDecline.label then card.btnDecline.label:SetText("DECLINE") end
    card:SetAlpha(1)
    card:SetScale(0.95)

    -- Return to pool before dequeuing so AcquireCard can reuse it
    table.insert(cardPool, card)

    -- Promote next queued event if passive lane has room
    if #cardQueue > 0 and #activePassiveCards < getMaxVisible() then
        local nextEvent = table.remove(cardQueue, 1)
        self:ShowCard(nextEvent)
    else
        self:RepositionCards()
    end
end

-- ----------------------------------------------------------------
-- DismissCard  (starts exit animation; RecycleCard follows)
-- ----------------------------------------------------------------

function Notifications:DismissCard(card)
    if not card or card._exiting then return end
    card._exiting     = true
    card._exitElapsed = 0
end

-- ----------------------------------------------------------------
-- DismissAll  (dismiss all active cards and flush the pending queue)
-- ----------------------------------------------------------------

function Notifications:DismissAll()
    local toDiscard = {}
    for _, c in ipairs(activePassiveCards) do toDiscard[#toDiscard + 1] = c end
    for _, c in ipairs(activeActionCards)  do toDiscard[#toDiscard + 1] = c end
    for _, c in ipairs(toDiscard) do self:DismissCard(c) end
    for i = #cardQueue, 1, -1 do cardQueue[i] = nil end
end

-- ----------------------------------------------------------------
-- Dismiss(id)  — replaces the stub in Notifications.lua
-- Searches both active lanes for cards whose _id matches and
-- dismisses each one.  Returns true if at least one card was found.
-- ----------------------------------------------------------------

function Notifications:Dismiss(id)
    if not id then return false end
    local found = false
    for _, c in ipairs(activePassiveCards) do
        if c._id == id and not c._exiting then self:DismissCard(c); found = true end
    end
    for _, c in ipairs(activeActionCards) do
        if c._id == id and not c._exiting then self:DismissCard(c); found = true end
    end
    return found
end

-- ----------------------------------------------------------------
-- Per-card OnUpdate: entry → reflow → expiry → exit → recycle
-- ----------------------------------------------------------------

local function startCardAnimation(card)
    local dir   = card._entryDir  or "UP"
    local scale = card._cardScale or 0.95

    card:SetScript("OnUpdate", function(self, dt)
        dt = math.min(dt or 0, 0.05)
        local now = GetTime and GetTime() or 0

        -- Exit phase: fade + scale-down, then recycle
        if self._exiting then
            self._exitElapsed = (self._exitElapsed or 0) + dt
            local t = math.min(1, self._exitElapsed / ANIM_DUR)
            self:SetAlpha(1 - t)
            self:SetScale(scale * math.max(0.80, 1 - 0.20 * t))
            if t >= 1 then Notifications:RecycleCard(self) end
            return
        end

        -- Entry phase: slide in from direction offset + fade up
        if self._entering then
            self._enterElapsed = (self._enterElapsed or 0) + dt
            local t      = math.min(1, self._enterElapsed / ANIM_DUR)
            local eased  = 1 - (1 - t) * (1 - t)
            local remain = 1 - eased          -- 1→0 as animation progresses
            local tx = self._targetX or 0
            local ty = self._targetY or 0
            local cx, cy = tx, ty
            if dir == "UP"    then cy = ty - ANIM_OFFSET * remain
            elseif dir == "DOWN"  then cy = ty + ANIM_OFFSET * remain
            elseif dir == "LEFT"  then cx = tx + ANIM_OFFSET * remain
            else                       cx = tx - ANIM_OFFSET * remain end
            self._currentX = cx
            self._currentY = cy
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx, cy)
            self:SetAlpha(eased)
            self:SetScale(scale * (0.88 + 0.12 * eased))
            if t >= 1 then
                self._entering = false
                self._currentX = tx
                self._currentY = ty
                self:SetAlpha(1)
                self:SetScale(scale)
            end
            return
        end

        -- Smooth reflow: interpolate _currentX/Y toward _targetX/Y
        local tx = self._targetX or self._currentX or 0
        local ty = self._targetY or self._currentY or 0
        local cx = self._currentX or tx
        local cy = self._currentY or ty
        local dx, dy = tx - cx, ty - cy
        if dx * dx + dy * dy > 0.25 then
            local r = math.min(1, dt * 14)
            cx = cx + dx * r
            cy = cy + dy * r
            self._currentX = cx
            self._currentY = cy
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx, cy)
        end

        -- Expiry
        if not self._hovered then
            local remaining = (self._expiresAt or now) - now
            if remaining <= 0 then
                Notifications:DismissCard(self)
            elseif remaining < 0.5 then
                self:SetAlpha(math.max(0, remaining / 0.5))
            else
                self:SetAlpha(1)
            end
        end
    end)
end

-- ----------------------------------------------------------------
-- RepositionCards: compute _targetX/Y for all active cards
-- Handles all 4 stack directions, actionable lane, screen clamping.
-- Cards animate to new targets via their per-card OnUpdate.
-- ----------------------------------------------------------------

function Notifications:RepositionCards()
    local dir    = getDir()
    local scale  = getScale()
    local baseX, baseY = getBase()
    local w = getCardW() * scale
    local h = getCardH() * scale
    local gap = getGap()

    -- Passive stack
    for i, card in ipairs(activePassiveCards) do
        local tx, ty = baseX, baseY
        if     dir == "UP"   then ty = baseY + (i - 1) * (h + gap)
        elseif dir == "DOWN" then ty = baseY - (i - 1) * (h + gap)
        elseif dir == "LEFT" then tx = baseX - (i - 1) * (w + gap)
        else                      tx = baseX + (i - 1) * (w + gap) end
        card._targetX = tx
        card._targetY = ty
        if not card._currentX then card._currentX = tx; card._currentY = ty end
    end

    -- Actionable lane: perpendicular to the main stack
    if #activeActionCards > 0 then
        local screenW = UIParent:GetWidth()  or 1920
        local screenH = UIParent:GetHeight() or 1080
        local laneX, laneY

        if dir == "UP" or dir == "DOWN" then
            local rightSpace = screenW - (baseX + w)
            laneX = (rightSpace >= baseX) and (baseX + w + gap) or (baseX - w - gap)
            laneY = baseY
            for i, card in ipairs(activeActionCards) do
                local ty = laneY
                if dir == "UP"   then ty = laneY + (i - 1) * (h + gap)
                else                  ty = laneY - (i - 1) * (h + gap) end
                card._targetX = laneX
                card._targetY = ty
                if not card._currentX then card._currentX = laneX; card._currentY = ty end
            end
        else
            local aboveSpace = screenH - (baseY + h)
            laneY = (aboveSpace >= baseY) and (baseY + h + gap) or (baseY - h - gap)
            laneX = baseX
            for i, card in ipairs(activeActionCards) do
                local tx = laneX
                if dir == "LEFT" then tx = laneX - (i - 1) * (w + gap)
                else                  tx = laneX + (i - 1) * (w + gap) end
                card._targetX = tx
                card._targetY = laneY
                if not card._currentX then card._currentX = tx; card._currentY = laneY end
            end
        end
    end

    -- Screen clamping: shift the entire stack if any card target is off-screen
    local allCards = {}
    for _, c in ipairs(activePassiveCards) do allCards[#allCards + 1] = c end
    for _, c in ipairs(activeActionCards)  do allCards[#allCards + 1] = c end

    if #allCards > 0 then
        local screenW = UIParent:GetWidth()  or 1920
        local screenH = UIParent:GetHeight() or 1080
        local c0 = allCards[1]
        local minX, minY = c0._targetX, c0._targetY
        local maxX, maxY = minX + w, minY + h
        for i = 2, #allCards do
            local c = allCards[i]
            if c._targetX < minX then minX = c._targetX end
            if c._targetY < minY then minY = c._targetY end
            if c._targetX + w > maxX then maxX = c._targetX + w end
            if c._targetY + h > maxY then maxY = c._targetY + h end
        end
        local sx = 0
        local sy = 0
        if     minX < 4              then sx =  4 - minX
        elseif maxX > screenW - 4   then sx = (screenW - 4) - maxX end
        if     minY < 4              then sy =  4 - minY
        elseif maxY > screenH - 4   then sy = (screenH - 4) - maxY end
        if sx ~= 0 or sy ~= 0 then
            for _, c in ipairs(allCards) do
                c._targetX = c._targetX + sx
                c._targetY = c._targetY + sy
            end
        end
    end
end

-- ----------------------------------------------------------------
-- Populate a card's visual content from a normalized event
-- ----------------------------------------------------------------

local function populateCard(card, event, accent, scale)
    card:SetSize(getCardW(), getCardH())
    card.accentBar:SetHeight(getAccentH())
    local status = string.upper(tostring(event.status or "INFO"))

    card.iconBg:SetColorTexture(accent[1] * 0.20, accent[2] * 0.20, accent[3] * 0.20, 1)

    local hasTexture = false
    if event.icon and event.icon ~= "" then
        card.icon:SetTexture(event.icon)
        card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        card.icon:SetDesaturated(status == "OFFLINE")
        card.icon:Show()
        card.iconInitial:SetText("")
        hasTexture = true
    elseif event.classFile then
        local cf     = string.upper(tostring(event.classFile))
        local coords = _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[cf]
        if coords then
            card.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            card.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            card.icon:SetDesaturated(status == "OFFLINE")
            card.icon:Show()
            card.iconInitial:SetText("")
            hasTexture = true
        end
    end
    if not hasTexture then
        card.icon:SetTexture(nil)
        card.icon:Hide()
        card.iconInitial:SetText(string.upper(string.sub(tostring(event.title or "?"), 1, 1)))
    end

    if event.badge and event.badge ~= "" then
        card.badge:SetTexture(event.badge)
        card.badge:Show()
    else
        card.badge:SetTexture(nil)
        card.badge:Hide()
    end

    card.title:SetText(tostring(event.title  or ""))
    card.detail:SetText(tostring(event.detail or ""))
    card.timeText:SetText(date("%H:%M", time()))
    card.accentBar:SetColorTexture(accent[1], accent[2], accent[3], 1)

    card._tooltipTitle = tostring(event.title  or "")
    card._tooltipBody  = tostring(event.detail or "")

    local actions = type(event.actions) == "table" and event.actions or {}
    card._onAccept  = actions.accept
    card._onDecline = actions.decline
    card._onReply   = actions.reply
    card._onPrimary = actions.primary

    if actions.accept then
        if card.btnAccept.label then card.btnAccept.label:SetText(actions.acceptLabel  or "ACCEPT")  end
        card.btnAccept:Show()
    else
        card.btnAccept:Hide()
    end
    if actions.decline and actions.accept then
        if card.btnDecline.label then card.btnDecline.label:SetText(actions.declineLabel or "DECLINE") end
        card.btnDecline:Show()
    else
        card.btnDecline:Hide()
    end
    if actions.reply and not actions.accept then
        card.btnReply:Show()
    else
        card.btnReply:Hide()
    end

    card:SetScale(scale)
    card._cardScale = scale
end

-- ----------------------------------------------------------------
-- ShowCard: show a card from a normalized event
-- force = true  bypasses IsCategoryEnabled (preview / test only)
-- ----------------------------------------------------------------

function Notifications:ShowCard(event, force)
    if type(event) ~= "table" then return nil end

    local src = string.upper(tostring(event.sourceAddon or "CRESHCHAT"))
    local cat = string.upper(tostring(event.category    or "SYSTEM"))
    if not force and not self:IsCategoryEnabled(src, cat) then return nil end

    local isActionable = event.destination == "ACTIONABLE"
        or (event.destination == nil and (cat == "PARTY_INVITE" or cat == "GAME_INVITE"))

    -- Passive lane overflow → queue (no queue for actionable cards)
    if not isActionable then
        local maxV = getMaxVisible()
        -- Check for an existing coalesce match before deciding to queue
        local hasCoalesce = false
        if event.coalesceKey then
            for _, c in ipairs(activePassiveCards) do
                if c._coalesceKey == event.coalesceKey and c:IsShown() then
                    hasCoalesce = true
                    break
                end
            end
        end
        if not hasCoalesce and #activePassiveCards >= maxV then
            -- Prevent duplicate coalesce keys from piling up in the queue
            if event.coalesceKey then
                for _, q in ipairs(cardQueue) do
                    if q.coalesceKey == event.coalesceKey then return nil end
                end
            end
            table.insert(cardQueue, event)
            return nil
        end
    else
        -- Actionable lane cap: if full, only allow through when a coalesce match exists
        if #activeActionCards >= getMaxActionable() then
            local hasCoalesce = false
            if event.coalesceKey then
                for _, c in ipairs(activeActionCards) do
                    if c._coalesceKey == event.coalesceKey and c:IsShown() then
                        hasCoalesce = true; break
                    end
                end
            end
            if not hasCoalesce then return nil end
        end
    end

    local accent   = (type(event.accent) == "table" and #event.accent >= 3)
                     and event.accent or resolveAccent(event.status, cat)
    local priority = string.upper(tostring(event.priority or "NORMAL"))
    local duration = tonumber(event.duration)
                     or ((priority == "CRITICAL" or priority == "HIGH") and getDurHigh() or getDurNormal())
    local scale     = getScale()
    local dir       = getDir()

    -- Coalesce: reuse an active matching card
    local card
    local activeList = isActionable and activeActionCards or activePassiveCards
    if event.coalesceKey then
        for _, c in ipairs(activeList) do
            if c._coalesceKey == event.coalesceKey and c:IsShown() then
                card = c
                break
            end
        end
    end
    local isNew = (card == nil)
    if isNew then card = self:AcquireCard() end

    -- Identity: preserve _id on coalesce so Dismiss(id) remains valid
    if isNew then
        card._id = event.id or (cat .. ":" .. tostring(GetTime and GetTime() or 0))
    end
    card._sourceAddon = src
    card._category    = cat
    card._coalesceKey = event.coalesceKey

    populateCard(card, event, accent, scale)

    -- Expiry timer
    card._expiresAt = (GetTime and GetTime() or 0) + duration

    if isNew then
        table.insert(activeList, card)
        card._entryDir = dir
        card._entering = true
        card._enterElapsed = 0
        card._exiting  = false
    end

    self:RepositionCards()
    card:SetAlpha(isNew and 0 or 1)
    card:Show()
    if isNew then
        startCardAnimation(card)
        -- PlayAlertSound's 0.12 s cooldown silently suppresses any duplicate
        -- that already fired from the Core.lua event handler in the same frame.
        if CC.PlayAlertSound then CC:PlayAlertSound(cat) end
    end
    return card
end

-- ----------------------------------------------------------------
-- Push  (wraps ShowCard; replaces Phase 2 stub)
-- ----------------------------------------------------------------

function Notifications:Push(event)
    if type(event) ~= "table" then return false end
    -- Master renderer guard: centralises the flag so callers don't have to.
    if CC.IsFeatureEnabled and not CC:IsFeatureEnabled("unifiedNotificationCards") then return false end
    local src = string.upper(tostring(event.sourceAddon or "CRESHCHAT"))
    local cat = string.upper(tostring(event.category    or "SYSTEM"))
    if not self:IsCategoryEnabled(src, cat) then return false end
    local card = self:ShowCard(event)
    return card and card._id or false
end

-- ----------------------------------------------------------------
-- Preview  (/cc notifpreview)
-- Shows one card per semantic category with force=true so all
-- three addon sources appear even when not registered.
-- Cards beyond MaxVisible queue and appear as earlier ones expire.
-- ----------------------------------------------------------------

local PREVIEW_EVENTS = {
    { title="Alyndra",       detail="hey, are you on?",            status="WHISPER",     category="WHISPER",       sourceAddon="CRESHCHAT" },
    { title="Korreth",       detail="has come online.",             status="ONLINE",      category="FRIEND",        sourceAddon="CRESHCHAT" },
    { title="Guild",         detail="Durnan: portal is up!",       status="GUILD",       category="GUILD",         sourceAddon="CRESHCHAT" },
    { title="Party invite",  detail="Solenne invited you to join.", status="PARTY",       category="PARTY_INVITE",  sourceAddon="CRESHCHAT", destination="ACTIONABLE" },
    { title="Battle Pass",   detail="Level 12 · +50 Cresh Coins",  status="BATTLEPASS",  category="GAME",          sourceAddon="CRESHCHAT" },
    { title="System",        detail="You joined Solenne's party.",  status="SUCCESS",     category="SYSTEM",        sourceAddon="CRESHCHAT" },
    { title="Game invite",   detail="Durnan challenged you.",       status="GAME",        category="GAME_INVITE",   sourceAddon="CRESHGAMES", destination="ACTIONABLE" },
    { title="Achievement",   detail="Explorer: visit 50 zones.",   status="ACHIEVEMENT", category="ACHIEVEMENT",   sourceAddon="CRESHCOLLECT" },
}

function Notifications:Preview()
    for _, evt in ipairs(PREVIEW_EVENTS) do
        self:ShowCard(evt, true)
    end
end

-- ----------------------------------------------------------------
-- Slash command extension  (/cc notifpreview)
-- ----------------------------------------------------------------

local _origSlash = CC.HandleSlashCommand
if type(_origSlash) == "function" then
    function CC:HandleSlashCommand(input)
        local cmd = string.match(tostring(input or ""), "^(%S*)") or ""
        local lc  = string.lower(cmd)

        if lc == "notifpreview" then
            Notifications:Preview()
            return
        end

        if lc == "notifcards" then
            local arg = string.lower(string.match(tostring(input), "^%S+%s+(%S*)") or "")
            if arg == "on" then
                self:SetFeatureEnabled("unifiedNotificationCards", true)
                self:Print("Unified notification cards: ON")
            elseif arg == "off" then
                self:SetFeatureEnabled("unifiedNotificationCards", false)
                self:Print("Unified notification cards: OFF")
            else
                local state = self:IsFeatureEnabled("unifiedNotificationCards") and "ON" or "OFF"
                self:Print("Unified notification cards: " .. state)
                self:Print("  /cc notifcards on   — enable the unified renderer")
                self:Print("  /cc notifcards off  — fall back to legacy toasts")
            end
            return
        end

        return _origSlash(self, input)
    end
end
