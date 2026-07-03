local _, CC = ...
if not CC or not CC.UI then return end
local UI = CC.UI

local max, min, floor = math.max, math.min, math.floor
local function templateName()
    return _G.BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function backdrop(frame, r, g, b, a, br, bg, bb, ba)
    if frame.SetBackdrop then
        local chrome = frame.creshClassicChrome and UI.GetThemeChrome and UI:GetThemeChrome() or nil
        if chrome then
            frame:SetBackdrop({
                bgFile = chrome.bgFile,
                edgeFile = chrome.edgeFile,
                tile = true,
                tileSize = 32,
                edgeSize = chrome.edgeSize or 12,
                insets = chrome.insets or { left = 3, right = 3, top = 3, bottom = 3 },
            })
        else
            frame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
        end
        frame:SetBackdropColor(r or 0.06, g or 0.07, b or 0.09, a or 0.98)
        frame:SetBackdropBorderColor(br or 0.2, bg or 0.22, bb or 0.28, ba or 1)
    end
end

local function font(parent, size, justify)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetFont(STANDARD_TEXT_FONT, size or 11, "")
    f:SetTextColor(0.92, 0.94, 0.98, 1)
    f:SetJustifyH(justify or "LEFT")
    f:SetJustifyV("MIDDLE")
    return f
end

local function raiseFrame(frame, relativeTo, levelOffset)
    if not frame or not relativeTo then return end
    if frame.SetFrameStrata and relativeTo.GetFrameStrata then
        frame:SetFrameStrata(relativeTo:GetFrameStrata())
    end
    if frame.SetFrameLevel and relativeTo.GetFrameLevel then
        local target = (relativeTo:GetFrameLevel() or 0) + (levelOffset or 1)
        frame:SetFrameLevel(max(1, min(9000, target)))
    end
end

local function button(parent, text, width, height, callback)
    local b = CreateFrame("Button", nil, parent, templateName())
    b:SetSize(width or 100, height or 26)
    backdrop(b, 0.095, 0.108, 0.138, 1, 0.16, 0.19, 0.25, 1)
    b.text = font(b, 10, "CENTER")
    b.text:SetAllPoints()
    b.text:SetText(text or "")
    b:SetScript("OnClick", function(...)
        if UI.FullSettings and UI.FullSettings.frame and UI.FocusWindow then UI:FocusWindow(UI.FullSettings.frame) end
        if callback then callback(...) end
    end)
    b:SetScript("OnEnter", function(self)
        local c = CC.db and CC.db.colors and CC.db.colors.accent or { 0.11, 0.43, 0.95, 1 }
        if self.SetBackdropColor then self:SetBackdropColor(c[1] * 0.55, c[2] * 0.55, c[3] * 0.55, 1) end
    end)
    b:SetScript("OnLeave", function(self)
        if self.creshActive then return end
        if self.SetBackdropColor then self:SetBackdropColor(0.095, 0.108, 0.138, 1) end
    end)
    return b
end

local function ensureTables()
    CC.db.ui = CC.db.ui or {}
    CC.db.ui.consoleTabs = CC.db.ui.consoleTabs or {}
    CC.db.notifications = CC.db.notifications or {}
    CC.db.notificationPriorities = CC.db.notificationPriorities or {}
    CC.db.notificationSources = CC.db.notificationSources or {}
    CC.db.sounds = CC.db.sounds or { master = true, whisper = true, guild = true, party = true, partyInvite = true, partyMessage = true, quest = true, mentions = true, friends = true, game = true, system = false }
    CC.db.soundChoices = CC.db.soundChoices or {}
    CC.db.soundVolumes = CC.db.soundVolumes or {}
    CC.db.colors = CC.db.colors or {}
    CC.db.colors.channels = CC.db.colors.channels or {}
    CC.db.colors.guild = CC.db.colors.guild or {}
    CC.db.positions = CC.db.positions or {}
    CC.db.sizes = CC.db.sizes or {}
end

local function apply()
    ensureTables()
    CC.db.sound = CC.db.sounds.master ~= false
    -- Slider drags can fire many times per frame. The quality layer coalesces
    -- those visual rebuilds so settings remain smooth while values update live.
    if UI.RequestVisualApply then UI:RequestVisualApply()
    elseif UI.ApplyVisualSettings then UI:ApplyVisualSettings() end
end

local function repositionCards()
    if CC.Notifications and CC.Notifications.RepositionCards then
        CC.Notifications:RepositionCards()
    end
    if UI.RepositionToasts then UI:RepositionToasts() end
end

local function openColorPicker(color, changed)
    local previous = { color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1 }
    local function update()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        color[1], color[2], color[3] = r, g, b
        changed()
    end
    local function cancel(values)
        local v = values or previous
        color[1], color[2], color[3], color[4] = v[1], v[2], v[3], v[4]
        changed()
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = previous[1], g = previous[2], b = previous[3], hasOpacity = false,
            swatchFunc = update, cancelFunc = function() cancel(previous) end,
        })
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.previousValues = previous
        ColorPickerFrame.func = update
        ColorPickerFrame.opacityFunc = update
        ColorPickerFrame.cancelFunc = cancel
        ColorPickerFrame:SetColorRGB(previous[1], previous[2], previous[3])
        ColorPickerFrame:Hide(); ColorPickerFrame:Show()
    end
end

local THEME_DISPLAY = {
    CRESH_MINIMAL = "Cresh Minimal", ELVUI_CHARCOAL = "ElvUI Charcoal", TUKUI_OBSIDIAN = "Tukui Obsidian",
    WIM_CLASSIC = "WIM Messenger", PRAT_GLASS = "Prat Glass", LS_GLASS = "LS Glass",
    CHATTYNATOR_SLATE = "Chattynator Slate", SPARTAN_STEEL = "Spartan Steel", NDUI_AZURE = "NDui Azure",
    BENIK_TEAL = "Benik Teal", GINGI_NEON = "Gingi Neon", NORD_FROST = "Nord Frost",
    WOW_CLASSIC = "WoW Classic", ZLR = "ZLR Arena", CLASSIC_BRONZE = "Classic Bronze", HIGH_CONTRAST = "High Contrast",
    MESSENGER = "Messenger Blue", SNAPCHAT = "Snapchat Contrast", DISCORD = "Discord Dark",
    ICQ = "ICQ", MSN_MESSENGER = "MSN Messenger", WINDOWS_31 = "Windows 3.1",
    WINDOWS_95 = "Windows 95", UBUNTU = "Ubuntu",
    MIDNIGHT = "Midnight", CUSTOM = "Custom colours",
}
local THEME_VALUES = {
    "CRESH_MINIMAL", "WOW_CLASSIC", "ZLR", "ELVUI_CHARCOAL", "TUKUI_OBSIDIAN", "WIM_CLASSIC",
    "PRAT_GLASS", "LS_GLASS", "CHATTYNATOR_SLATE", "SPARTAN_STEEL", "NDUI_AZURE",
    "BENIK_TEAL", "GINGI_NEON", "NORD_FROST", "CLASSIC_BRONZE", "HIGH_CONTRAST",
    "MESSENGER", "SNAPCHAT", "DISCORD", "ICQ", "MSN_MESSENGER", "WINDOWS_31",
    "WINDOWS_95", "UBUNTU", "MIDNIGHT", "CUSTOM",
}
local GUILD_THEME_VALUES = {
    "AUTO", "VERDANT", "EMERALD", "JADE_NIGHT", "MOSS_STONE", "SAGE_PARCHMENT",
    "FEL_GREEN", "DEEP_FOREST", "ALLIANCE", "ALLIANCE_ARCANE", "HORDE", "HORDE_IRON", "CUSTOM",
}
local GUILD_THEME_DISPLAY = UI.GUILD_THEME_DISPLAY or {}
if CC.ThemeLibrary then
    local rebuilt, seen = {}, {}
    for _, key in ipairs(THEME_VALUES) do if key ~= "CUSTOM" and not seen[key] then rebuilt[#rebuilt + 1] = key; seen[key] = true end end
    for _, key in ipairs(CC.ThemeLibrary.order or {}) do
        if not seen[key] then rebuilt[#rebuilt + 1] = key; seen[key] = true end
        THEME_DISPLAY[key] = (CC.ThemeLibrary.display or {})[key] or key
    end
    rebuilt[#rebuilt + 1] = "CUSTOM"
    THEME_VALUES = rebuilt

    local guildRebuilt, guildSeen = {}, {}
    for _, key in ipairs(GUILD_THEME_VALUES) do if key ~= "CUSTOM" and not guildSeen[key] then guildRebuilt[#guildRebuilt + 1] = key; guildSeen[key] = true end end
    for _, key in ipairs(CC.ThemeLibrary.guildOrder or {}) do
        if not guildSeen[key] then guildRebuilt[#guildRebuilt + 1] = key; guildSeen[key] = true end
        GUILD_THEME_DISPLAY[key] = (CC.ThemeLibrary.guildDisplay or {})[key] or key
    end
    guildRebuilt[#guildRebuilt + 1] = "CUSTOM"
    GUILD_THEME_VALUES = guildRebuilt
end
local ANIM_DISPLAY = {
    SLIDE_DOCK = "Slide from dock", SLIDE_LEFT = "Slide from left", SLIDE_RIGHT = "Slide from right",
    SLIDE_UP = "Slide upward", SLIDE_DOWN = "Slide downward", POP = "Pop", FAN_UP = "Fan upward",
    FAN_DOWN = "Fan downward", SWOOP = "Swoop", FADE = "Fade", ZOOM = "Zoom", BOUNCE = "Bounce", NONE = "None",
}
local ANIM_VALUES = { "SLIDE_DOCK", "SLIDE_LEFT", "SLIDE_RIGHT", "SLIDE_UP", "SLIDE_DOWN", "POP", "FAN_UP", "FAN_DOWN", "SWOOP", "FADE", "ZOOM", "BOUNCE", "NONE" }
local PROFILE_VALUES = { "BALANCED", "MINIMAL", "MESSENGER", "POPOUT", "PERFORMANCE" }
local PROFILE_DISPLAY = { BALANCED="Balanced", MINIMAL="Minimal", MESSENGER="Messenger", POPOUT="Pop-out focus", PERFORMANCE="Performance" }
local SOUND_DISPLAY = {
    OFF="Off", DING="Clear ding", CHIME="Bright chime", WHISPER="Whisper message",
    SOFT="Soft tick", MESSAGE="Message scroll", QUEST="Quest chime", READY="Ready check",
    WARNING="Warning pulse", OPEN="Window open", COIN="Coin bell",
}
local ALL_SOUND_VALUES = { "OFF", "DING", "CHIME", "WHISPER", "SOFT", "MESSAGE", "QUEST", "READY", "WARNING", "OPEN", "COIN" }
local CUSTOM_SOUND_LIBRARY = _G.CreshChatSoundLibrary
if CUSTOM_SOUND_LIBRARY then
    for _, key in ipairs(CUSTOM_SOUND_LIBRARY.order or {}) do
        ALL_SOUND_VALUES[#ALL_SOUND_VALUES + 1] = key
        SOUND_DISPLAY[key] = (CUSTOM_SOUND_LIBRARY.display or {})[key] or key
    end
end
local SOUND_VALUES = {
    whisper = ALL_SOUND_VALUES,
    guild = ALL_SOUND_VALUES,
    partyInvite = ALL_SOUND_VALUES,
    partyMessage = ALL_SOUND_VALUES,
    quest = ALL_SOUND_VALUES,
    mentions = ALL_SOUND_VALUES,
    friends = ALL_SOUND_VALUES,
    game = ALL_SOUND_VALUES,
    system = ALL_SOUND_VALUES,
}
local NOTIFICATION_PRIORITY_VALUES = { "CRITICAL", "HIGH", "NORMAL", "LOW" }
local NOTIFICATION_PRIORITY_DISPLAY = {
    CRITICAL = "Critical - full-size and longest",
    HIGH = "High - full-size",
    NORMAL = "Normal - slide-out",
    LOW = "Low - compact and shorter",
}
local NOTIFICATION_ANIMATION_VALUES = { "FAN_UP", "FAN_DOWN", "SLIDE_LEFT", "SLIDE_RIGHT", "SLIDE_UP", "SLIDE_DOWN", "POP", "SWOOP", "FADE", "ZOOM", "BOUNCE", "NONE" }
local function previewNotification(channel)
    if CC.PlayAlertSound then CC:PlayAlertSound(channel, true) end
    if UI.PreviewLauncherNotification then UI:PreviewLauncherNotification(channel) end
end

local function chooseSound(key, channel, value)
    if CC.SetSoundChoice then CC:SetSoundChoice(key, value) end
    if value ~= "OFF" then previewNotification(channel) end
end

local Settings = { version = CC.version }
local SETTINGS_FRAME_LEVEL = 7000
local SETTINGS_DROPDOWN_LEVEL = 500
UI.FullSettings = Settings
if CC.RegisterModule then CC:RegisterModule("Settings", Settings) end
UI.fullSettings = Settings

function Settings:RegisterLayout(control, kind, column)
    control.creshLayoutKind = kind or "full"
    control.creshLayoutColumn = column or 1
    if control.HookScript then
        control:HookScript("OnMouseDown", function()
            if Settings.frame and UI.FocusWindow then UI:FocusWindow(Settings.frame) end
        end)
    end
    self.layoutControls[#self.layoutControls + 1] = control
end

function Settings:CreateToggle(parent, label, getter, setter, x, y, width, kind, column)
    local row = CreateFrame("Button", nil, parent, templateName())
    row:SetSize(width, 27)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    backdrop(row, 0.075, 0.086, 0.112, 0.97, 0.13, 0.15, 0.20, 1)
    row.label = font(row, 10, "LEFT")
    row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -52, 0)
    row.label:SetText(label)
    row.value = font(row, 9, "RIGHT")
    row.value:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row:SetScript("OnClick", function()
        setter(not getter()); apply(); Settings:Refresh()
    end)
    row.Refresh = function(self)
        local on = getter() and true or false
        self.value:SetText(on and "ON" or "OFF")
        self.value:SetTextColor(on and 0.35 or 0.95, on and 0.90 or 0.35, on and 0.55 or 0.35, 1)
    end
    self.refreshables[#self.refreshables + 1] = row
    self:RegisterLayout(row, kind, column)
    return row
end

function Settings:CloseDropdown(except)
    local open = self.openDropdown
    if open and open ~= except and open.menu then open.menu:Hide() end
    if not except then self.openDropdown = nil end
end

function Settings:CreateDropdown(parent, label, getter, setter, values, display, x, y, width, options)
    options = options or {}
    self.dropdownCounter = (self.dropdownCounter or 0) + 1
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, 31)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row.label = font(row, 10, "LEFT")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -228, 0)
    row.label:SetText(label)

    row.button = button(row, "", 218, 27, function()
        if row.menu:IsShown() then
            row.menu:Hide(); Settings.openDropdown = nil
        else
            Settings:CloseDropdown(row)
            Settings.openDropdown = row
            if UI.FullSettings and UI.FullSettings.frame and UI.FocusWindow then UI:FocusWindow(UI.FullSettings.frame) end
            row:LayoutMenu(true)
            row.menu:Show()
        end
    end)
    row.button:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.button.text:ClearAllPoints()
    row.button.text:SetPoint("LEFT", row.button, "LEFT", 9, 0)
    row.button.text:SetPoint("RIGHT", row.button, "RIGHT", -26, 0)
    row.button.text:SetJustifyH("LEFT")
    row.button.arrow = font(row.button, 10, "CENTER")
    row.button.arrow:SetPoint("RIGHT", row.button, "RIGHT", -8, 0)
    row.button.arrow:SetText("v")
    row.button.arrow:SetTextColor(0.56, 0.72, 0.96, 1)

    local menuName = "CreshChatSettingsDropdown" .. self.dropdownCounter
    local menu = CreateFrame("Frame", menuName, UIParent, templateName())
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(SETTINGS_DROPDOWN_LEVEL)
    menu:SetClampedToScreen(true)
    backdrop(menu, 0.045, 0.052, 0.070, 1, 0.20, 0.25, 0.34, 1)
    menu:Hide()
    row.menu = menu
    row.items = {}
    row.menuPage = 1
    row.menuPages = 1
    row.menuCapacity = #values

    for index, value in ipairs(values) do
        local item = CreateFrame("Button", nil, menu, templateName())
        item:SetHeight(24)
        backdrop(item, 0.065, 0.074, 0.096, 1, 0.11, 0.13, 0.17, 0)
        item.check = font(item, 10, "CENTER")
        item.check:SetPoint("LEFT", item, "LEFT", 7, 0)
        item.check:SetWidth(14)
        item.text = font(item, 10, "LEFT")
        item.text:SetPoint("LEFT", item, "LEFT", 25, 0)
        item.text:SetPoint("RIGHT", item, "RIGHT", -7, 0)
        item.value = value
        item.creshHovered = false
        item.RefreshAppearance = function(selfItem)
            local selected = selfItem.creshSelected == true
            local locked = options.isLocked and options.isLocked(value) == true or false
            selfItem.creshLocked = locked
            local name = display[value] or tostring(value)
            selfItem.text:SetText(locked and (name .. "  [LOCKED]") or name)
            if locked then
                if selfItem.creshHovered then
                    backdrop(selfItem, 0.050, 0.054, 0.064, 1, 0.16, 0.17, 0.20, 1)
                else
                    backdrop(selfItem, 0.024, 0.027, 0.034, 1, 0.075, 0.082, 0.096, 1)
                end
                selfItem.text:SetTextColor(0.38, 0.40, 0.45, 1)
                selfItem.check:SetTextColor(0.34, 0.36, 0.40, 1)
            else
                local c = CC.db and CC.db.colors and CC.db.colors.accent or { 0.11, 0.43, 0.95, 1 }
                if selfItem.creshHovered then
                    backdrop(selfItem, c[1] * 0.35, c[2] * 0.35, c[3] * 0.35, 1, c[1] * 0.60, c[2] * 0.60, c[3] * 0.60, 0.9)
                else
                    backdrop(selfItem, 0.065, 0.074, 0.096, 1, 0.11, 0.13, 0.17, 0)
                end
                selfItem.text:SetTextColor(selected and 0.45 or 0.92, selected and 0.80 or 0.94, selected and 1.00 or 0.98, 1)
                selfItem.check:SetTextColor(0.56, 0.78, 1.00, 1)
            end
        end
        item:SetScript("OnEnter", function(selfItem)
            selfItem.creshHovered = true
            selfItem:RefreshAppearance()
        end)
        item:SetScript("OnLeave", function(selfItem)
            selfItem.creshHovered = false
            selfItem:RefreshAppearance()
        end)
        item:SetScript("OnClick", function()
            local locked = options.isLocked and options.isLocked(value) == true or false
            menu:Hide(); Settings.openDropdown = nil
            if options.onSelect then
                options.onSelect(value, locked, row)
            else
                setter(value)
                apply()
            end
            if options.refreshAfter ~= false then Settings:Refresh() end
        end)
        row.items[index] = { frame = item, value = value }
    end

    row.pageText = font(menu, 9, "CENTER")
    row.pageText:SetTextColor(0.62, 0.70, 0.82, 1)
    row.previousPage = button(menu, "<", 30, 23, function()
        if row.menuPage > 1 then row.menuPage = row.menuPage - 1; row:LayoutMenu(false) end
    end)
    row.nextPage = button(menu, ">", 30, 23, function()
        if row.menuPage < row.menuPages then row.menuPage = row.menuPage + 1; row:LayoutMenu(false) end
    end)

    local function settingsMenuScale()
        local settingsFrame = Settings.frame
        local frameScale = settingsFrame and settingsFrame.GetEffectiveScale and settingsFrame:GetEffectiveScale()
            or (settingsFrame and settingsFrame.GetScale and settingsFrame:GetScale()) or 1
        local parentScale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
            or (UIParent and UIParent.GetScale and UIParent:GetScale()) or 1
        if not parentScale or parentScale <= 0 then parentScale = 1 end
        return max(0.45, frameScale / parentScale)
    end

    function row:LayoutMenu(focusCurrent)
        local scale = settingsMenuScale()
        menu:SetScale(scale)

        local screenWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth() or 1920
        local screenHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight() or 1080
        local availableWidth = max(210, (screenWidth / scale) - 24)
        local availableHeight = max(180, (screenHeight / scale) - 24)
        local preferredItemWidth = #values > 40 and 154 or 218
        local itemWidth = min(preferredItemWidth, max(132, availableWidth - 6))
        local maximumColumns = max(1, min(6, floor((availableWidth - 6) / itemWidth)))
        local footerHeight = 30
        local maximumRows = max(5, floor((availableHeight - footerHeight - 8) / 25))
        local preferredColumns = #values > 60 and 4 or (#values > 12 and 2 or 1)
        local requiredColumns = math.ceil(#values / maximumRows)
        local columns = max(1, min(maximumColumns, max(preferredColumns, requiredColumns)))
        local capacity = max(1, columns * maximumRows)
        local pages = max(1, math.ceil(#values / capacity))

        self.menuCapacity = capacity
        self.menuPages = pages
        if focusCurrent then
            local current = getter()
            for index, item in ipairs(self.items) do
                if item.value == current then self.menuPage = math.ceil(index / capacity); break end
            end
        end
        self.menuPage = max(1, min(pages, self.menuPage or 1))

        local firstIndex = ((self.menuPage - 1) * capacity) + 1
        local itemCount = min(capacity, max(0, #values - firstIndex + 1))
        local rows = max(1, min(maximumRows, math.ceil(itemCount / columns)))
        local visibleColumns = max(1, math.ceil(itemCount / rows))
        local menuWidth = max(itemWidth, itemWidth * visibleColumns)
        local menuHeight = rows * 25 + 6 + (pages > 1 and footerHeight or 0)
        menu:SetSize(menuWidth, menuHeight)

        for index, item in ipairs(self.items) do
            local localIndex = index - firstIndex + 1
            if localIndex >= 1 and localIndex <= itemCount then
                local column = floor((localIndex - 1) / rows)
                local rowIndex = (localIndex - 1) % rows
                item.frame:ClearAllPoints()
                item.frame:SetPoint("TOPLEFT", menu, "TOPLEFT", 3 + column * itemWidth, -3 - rowIndex * 25)
                item.frame:SetWidth(itemWidth - 6)
                item.frame:Show()
            else
                item.frame:Hide()
            end
        end

        if pages > 1 then
            self.previousPage:ClearAllPoints()
            self.previousPage:SetPoint("BOTTOMLEFT", menu, "BOTTOMLEFT", 4, 3)
            self.nextPage:ClearAllPoints()
            self.nextPage:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -4, 3)
            self.pageText:ClearAllPoints()
            self.pageText:SetPoint("LEFT", self.previousPage, "RIGHT", 5, 0)
            self.pageText:SetPoint("RIGHT", self.nextPage, "LEFT", -5, 0)
            self.pageText:SetText("Page " .. tostring(self.menuPage) .. " / " .. tostring(pages))
            if self.menuPage > 1 then self.previousPage:Enable() else self.previousPage:Disable() end
            if self.menuPage < pages then self.nextPage:Enable() else self.nextPage:Disable() end
            self.previousPage:SetAlpha(self.menuPage > 1 and 1 or 0.38)
            self.nextPage:SetAlpha(self.menuPage < pages and 1 or 0.38)
            self.previousPage:Show(); self.nextPage:Show(); self.pageText:Show()
        else
            self.previousPage:Hide(); self.nextPage:Hide(); self.pageText:Hide()
        end

        menu:ClearAllPoints()
        local buttonBottom = self.button.GetBottom and self.button:GetBottom() or 0
        local buttonTop = self.button.GetTop and self.button:GetTop() or 0
        local menuHeightOnParent = menuHeight * scale
        local roomBelow = buttonBottom
        local roomAbove = screenHeight - buttonTop
        if roomBelow >= menuHeightOnParent + 8 or roomBelow >= roomAbove then
            menu:SetPoint("TOPRIGHT", self.button, "BOTTOMRIGHT", 0, -2)
        else
            menu:SetPoint("BOTTOMRIGHT", self.button, "TOPRIGHT", 0, 2)
        end
    end

    menu:EnableMouseWheel(true)
    menu:SetScript("OnMouseWheel", function(_, delta)
        if row.menuPages <= 1 then return end
        if delta < 0 and row.menuPage < row.menuPages then row.menuPage = row.menuPage + 1; row:LayoutMenu(false)
        elseif delta > 0 and row.menuPage > 1 then row.menuPage = row.menuPage - 1; row:LayoutMenu(false) end
    end)
    menu:SetScript("OnShow", function() row:LayoutMenu(false) end)
    menu:SetScript("OnHide", function()
        if Settings.openDropdown == row then Settings.openDropdown = nil end
    end)
    row.Relayout = function(self)
        local buttonWidth = min(218, max(145, floor((self:GetWidth() or width) * 0.44)))
        self.button:SetWidth(buttonWidth)
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", self, "LEFT", 0, 0)
        self.label:SetPoint("RIGHT", self, "RIGHT", -(buttonWidth + 10), 0)
        if self.menu:IsShown() then self:LayoutMenu(false) end
    end
    row.Refresh = function(self)
        local current = getter()
        self.button.text:SetText(display[current] or tostring(current))
        for _, item in ipairs(self.items) do
            local selected = item.value == current
            item.frame.creshSelected = selected
            item.frame.check:SetText(selected and "*" or "")
            if item.frame.RefreshAppearance then item.frame:RefreshAppearance() end
        end
    end
    self.refreshables[#self.refreshables + 1] = row
    self:RegisterLayout(row, "full", 1)
    return row
end

-- Backwards-compatible internal name. All cycle controls now render as dropdowns.
function Settings:CreateCycle(parent, label, getter, setter, values, display, x, y, width, options)
    return self:CreateDropdown(parent, label, getter, setter, values, display, x, y, width, options)
end

function Settings:CreateSlider(parent, label, minValue, maxValue, step, getter, setter, x, y, width, format)
    self.sliderCounter = (self.sliderCounter or 0) + 1
    local row = CreateFrame("Frame", nil, parent, templateName())
    row:SetSize(width, 48)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    backdrop(row, 0.070, 0.081, 0.105, 0.98, 0.14, 0.17, 0.23, 1)

    row.label = font(row, 10, "LEFT")
    row.label:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -6)
    row.label:SetPoint("RIGHT", row, "RIGHT", -92, 0)
    row.label:SetText(label)
    row.value = font(row, 10, "RIGHT")
    row.value:SetPoint("TOPRIGHT", row, "TOPRIGHT", -9, -6)
    row.value:SetWidth(82)

    row.track = CreateFrame("Frame", nil, row, templateName())
    row.track:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 10, 8)
    row.track:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -10, 8)
    row.track:SetHeight(10)
    backdrop(row.track, 0.025, 0.030, 0.040, 1, 0.12, 0.15, 0.20, 1)

    row.fill = row.track:CreateTexture(nil, "ARTWORK")
    row.fill:SetPoint("TOPLEFT", row.track, "TOPLEFT", 2, -2)
    row.fill:SetPoint("BOTTOMLEFT", row.track, "BOTTOMLEFT", 2, 2)
    row.fill:SetWidth(1)

    row.slider = CreateFrame("Slider", nil, row)
    row.slider:SetOrientation("HORIZONTAL")
    row.slider:SetPoint("LEFT", row.track, "LEFT", 5, 0)
    row.slider:SetPoint("RIGHT", row.track, "RIGHT", -5, 0)
    row.slider:SetHeight(18)
    row.slider:SetMinMaxValues(minValue, maxValue)
    row.slider:SetValueStep(step)
    row.slider:EnableMouse(true)
    if row.slider.SetObeyStepOnDrag then row.slider:SetObeyStepOnDrag(true) end
    row.slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = row.slider:GetThumbTexture()
    if thumb then thumb:SetSize(11, 18) end

    local function updateVisual(value)
        local ratio = (tonumber(value) or minValue) - minValue
        ratio = ratio / max(0.0001, maxValue - minValue)
        ratio = max(0, min(1, ratio))
        local c = CC.db and CC.db.colors and CC.db.colors.accent or { 0.11, 0.43, 0.95, 1 }
        row.fill:SetColorTexture(c[1], c[2], c[3], 0.92)
        if thumb and thumb.SetColorTexture then thumb:SetColorTexture(min(1, c[1] + 0.18), min(1, c[2] + 0.18), min(1, c[3] + 0.18), 1) end
        local trackWidth = max(1, (row.track:GetWidth() or (row:GetWidth() - 20)) - 4)
        row.fill:SetWidth(max(1, floor(trackWidth * ratio + 0.5)))
    end

    row.slider:SetScript("OnValueChanged", function(_, value)
        value = floor((value / step) + 0.5) * step
        row.value:SetText(format and format(value) or tostring(value))
        updateVisual(value)
        if row.creshRefreshing then return end
        setter(value)
        apply()
    end)
    row.slider:SetScript("OnEnter", function()
        local c = CC.db and CC.db.colors and CC.db.colors.accent or { 0.11, 0.43, 0.95, 1 }
        if row.SetBackdropBorderColor then row:SetBackdropBorderColor(c[1], c[2], c[3], 1) end
    end)
    row.slider:SetScript("OnLeave", function()
        if row.SetBackdropBorderColor then row:SetBackdropBorderColor(0.14, 0.17, 0.23, 1) end
    end)
    row:SetScript("OnSizeChanged", function() updateVisual(row.slider:GetValue()) end)
    row.Refresh = function(self)
        local value = tonumber(getter()) or minValue
        self.creshRefreshing = true
        self.slider:SetValue(value)
        self.creshRefreshing = false
        self.value:SetText(format and format(value) or tostring(value))
        updateVisual(value)
    end
    self.refreshables[#self.refreshables + 1] = row
    self:RegisterLayout(row, "full", 1)
    return row
end

function Settings:CreateColorRow(parent, label, colorGetter, x, y, width, kind, column, customKind)
    local row = CreateFrame("Button", nil, parent, templateName())
    row:SetSize(width, 27)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    backdrop(row, 0.075, 0.086, 0.112, 0.97, 0.13, 0.15, 0.20, 1)
    row.label = font(row, 10, "LEFT")
    row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", -48, 0)
    row.label:SetText(label)
    row.swatch = row:CreateTexture(nil, "ARTWORK")
    row.swatch:SetSize(34, 15)
    row.swatch:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    row:SetScript("OnClick", function()
        local color = colorGetter()
        openColorPicker(color, function()
            if customKind == "GUILD" then CC.db.ui.guildThemePreset = "CUSTOM"
            else CC.db.ui.themePreset = "CUSTOM" end
            apply(); Settings:Refresh()
        end)
    end)
    row.Refresh = function(self)
        local c = colorGetter()
        self.swatch:SetColorTexture(c[1] or 1, c[2] or 1, c[3] or 1, 1)
    end
    self.refreshables[#self.refreshables + 1] = row
    self:RegisterLayout(row, kind or "half", column or 1)
    return row
end

local Builder = {}
Builder.__index = Builder

function Settings:NewBuilder(page, title, description)
    local b = setmetatable({ settings = self, page = page, parent = page.canvas, y = -12, nextColumn = 1 }, Builder)
    local heading = font(b.parent, 16, "LEFT")
    heading:SetPoint("TOPLEFT", b.parent, "TOPLEFT", 12, b.y)
    heading:SetText(title)
    b.y = b.y - 25
    if description and description ~= "" then
        local note = font(b.parent, 9, "LEFT")
        note:SetPoint("TOPLEFT", b.parent, "TOPLEFT", 12, b.y)
        note:SetPoint("RIGHT", b.parent, "RIGHT", -12, 0)
        note:SetTextColor(0.58, 0.64, 0.73, 1)
        note:SetJustifyV("TOP")
        note:SetWordWrap(true)
        note:SetText(description)
        local h = max(26, note:GetStringHeight() + 4)
        note:SetHeight(h)
        b.y = b.y - h - 4
    end
    return b
end

function Builder:Flush()
    if self.nextColumn == 2 then
        self.nextColumn = 1
        self.y = self.y - 33
    end
end

function Builder:Section(title)
    self:Flush()
    local line = self.parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.18, 0.21, 0.28, 0.65)
    line:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 12, self.y - 11)
    line:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", -12, self.y - 11)
    line:SetHeight(1)
    local text = font(self.parent, 10, "LEFT")
    text:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 12, self.y)
    text:SetTextColor(0.48, 0.72, 1.00, 1)
    text:SetText(string.upper(title))
    self.y = self.y - 27
end

function Builder:HalfToggle(label, getter, setter)
    local col = self.nextColumn
    local row = self.settings:CreateToggle(self.parent, label, getter, setter, 12, self.y, 250, "half", col)
    self.nextColumn = col == 1 and 2 or 1
    if self.nextColumn == 1 then self.y = self.y - 33 end
    return row
end

function Builder:HalfColor(label, getter, customKind)
    local col = self.nextColumn
    local row = self.settings:CreateColorRow(self.parent, label, getter, 12, self.y, 250, "half", col, customKind)
    self.nextColumn = col == 1 and 2 or 1
    if self.nextColumn == 1 then self.y = self.y - 33 end
    return row
end

function Builder:Dropdown(label, getter, setter, values, display, options)
    self:Flush()
    local row = self.settings:CreateDropdown(self.parent, label, getter, setter, values, display, 12, self.y, 520, options)
    self.y = self.y - 37
    return row
end

function Builder:Cycle(label, getter, setter, values, display, options)
    return self:Dropdown(label, getter, setter, values, display, options)
end

function Builder:Slider(label, minValue, maxValue, step, getter, setter, format)
    self:Flush()
    local row = self.settings:CreateSlider(self.parent, label, minValue, maxValue, step, getter, setter, 12, self.y, 520, format)
    self.y = self.y - 54
    return row
end

function Builder:Note(text)
    self:Flush()
    local note = font(self.parent, 9, "LEFT")
    note:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 12, self.y)
    note:SetPoint("RIGHT", self.parent, "RIGHT", -12, 0)
    note:SetTextColor(0.58, 0.64, 0.73, 1)
    note:SetJustifyV("TOP")
    note:SetWordWrap(true)
    note:SetText(text)
    local h = max(24, note:GetStringHeight() + 4)
    note:SetHeight(h)
    self.y = self.y - h - 5
    return note
end

function Builder:Buttons(items)
    self:Flush()
    local group = CreateFrame("Frame", nil, self.parent)
    group:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 12, self.y)
    group:SetSize(520, 27)
    group.buttons = {}
    group.preferred = {}
    for index, item in ipairs(items) do
        local preferred = item[3] or 140
        local control = button(group, item[1], preferred, 27, item[2])
        group.buttons[index] = control
        group.preferred[index] = preferred
    end
    group.Relayout = function(selfGroup)
        local count = #selfGroup.buttons
        if count == 0 then return end
        local gap = 7
        local width = max(120, selfGroup:GetWidth() or 520)
        local available = max(80 * count, width - gap * (count - 1))
        local preferredTotal = 0
        for _, preferred in ipairs(selfGroup.preferred) do preferredTotal = preferredTotal + preferred end
        local previous
        local used = 0
        for index, control in ipairs(selfGroup.buttons) do
            local buttonWidth
            if preferredTotal + gap * (count - 1) <= width then
                buttonWidth = selfGroup.preferred[index]
            elseif index == count then
                buttonWidth = max(72, available - used)
            else
                buttonWidth = max(72, floor(available * selfGroup.preferred[index] / max(1, preferredTotal)))
            end
            control:SetWidth(buttonWidth)
            control:ClearAllPoints()
            if previous then control:SetPoint("LEFT", previous, "RIGHT", gap, 0)
            else control:SetPoint("LEFT", selfGroup, "LEFT", 0, 0) end
            previous = control
            used = used + buttonWidth
        end
    end
    self.settings:RegisterLayout(group, "full", 1)
    group:Relayout()
    self.y = self.y - 34
    return group
end

function Builder:Finish()
    self:Flush()
    self.parent:SetHeight(max(420, -self.y + 18))
end

local function pct(value) return floor(value * 100 + 0.5) .. "%" end
local function px(value) return floor(value + 0.5) .. " px" end
local function sec(value) return string.format("%.1f sec", value) end

function Settings:BuildGeneral(page)
    local b = self:NewBuilder(page, "General", "Core behaviour, launcher controls, portraits and overall message density.")
    b:Section("Quick setup profile")
    b:Dropdown("Profile", function() return CC.db.ui.qualityProfile or "BALANCED" end,
        function(v) if CC.Quality then CC.Quality:ApplyProfile(v) else CC.db.ui.qualityProfile = v end end,
        PROFILE_VALUES, PROFILE_DISPLAY)
    b:Note("Profiles change related options together without deleting messages, colours or saved window positions. You can still fine-tune every setting below.")
    b:Section("Core")
    b:HalfToggle("Disable Blizzard chat visually", function() return CC.db.hideBlizzard end, function(v) CC.db.hideBlizzard = v; CC:ApplyBlizzardChatVisibility() end)
    b:HalfToggle("Show floating C launcher", function() return CC.db.bubbleVisible end, function(v) CC.db.bubbleVisible = v end)
    b:HalfToggle("Enable Combat Log capture", function() return CC.db.combatEnabled end, function(v) CC.db.combatEnabled = v end)
    b:HalfToggle("Enable CreshChat voice calls", function() return not CC.db.voice or CC.db.voice.enabled ~= false end, function(v) CC.db.voice=CC.db.voice or {}; CC.db.voice.enabled=v; if not v and CC.Voice then CC.Voice:EndCall(true) end end)
    b:Note("Voice call requests use addon-to-addon handshakes and Blizzard voice services. Both players need CreshChat; client/account voice availability is still controlled by WoW.")
    b:HalfToggle("Automatic window arrangement", function() return CC.db.ui.autoArrange ~= false end, function(v) CC.db.ui.autoArrange = v end)
    b:HalfToggle("Shift-drag window resizing", function() return CC.db.ui.shiftResize ~= false end, function(v) CC.db.ui.shiftResize = v end)
    b:HalfToggle("Compact navigation", function() return CC.db.ui.compactNavigation ~= false end, function(v) CC.db.ui.compactNavigation = v end)

    b:Section("Launcher")
    b:Dropdown("Default launcher action", function() return CC.db.ui.launcherDefault or "LAST" end, function(v) CC.db.ui.launcherDefault = v end,
        { "LAST", "CHAT", "GAMES", "ACHIEVEMENTS", "PROGRESS", "SETTINGS" },
        { LAST = "Last used", CHAT = "Chat", GAMES = "Games", ACHIEVEMENTS = "Achievements", PROGRESS = "Progress Hub", SETTINGS = "Settings" })
    b:Note("Left-click on C opens this destination. If it's disabled in Modules, CreshChat falls back to the first enabled destination automatically. Shift+click always opens Settings.")
    b:Dropdown("Launcher buttons", function() return CC.db.ui.launcherMode or "SINGLE" end, function(v) CC.db.ui.launcherMode = v end,
        { "SINGLE", "EXPANDED" }, { SINGLE = "C only", EXPANDED = "C + quick buttons" })
    b:HalfToggle("Whisper quick button", function() return CC.db.ui.showWhisperButton == true end, function(v) CC.db.ui.showWhisperButton = v end)
    b:HalfToggle("General quick button", function() return CC.db.ui.showGeneralButton == true end, function(v) CC.db.ui.showGeneralButton = v end)
    b:HalfToggle("Combat quick button", function() return CC.db.ui.showCombatButton == true end, function(v) CC.db.ui.showCombatButton = v end)
    b:HalfToggle("Games quick button", function() return CC.db.ui.showGamesButton == true end, function(v) CC.db.ui.showGamesButton = v end)
    b:HalfToggle("Achievements quick button", function() return CC.db.ui.showAchievementsButton == true end, function(v) CC.db.ui.showAchievementsButton = v end)
    b:HalfToggle("Progress Hub quick button", function() return CC.db.ui.showProgressButton == true end, function(v) CC.db.ui.showProgressButton = v end)
    b:Note("Games, Achievements and Progress Hub quick buttons always show next to C when chat is disabled in Modules, regardless of this toggle.")
    b:HalfToggle("Group consecutive messages", function() return CC.db.ui.groupedMessages ~= false end, function(v) CC.db.ui.groupedMessages = v end)

    b:Section("Progress Hub")
    b:Note("World Progression, Quest Capture and Combat Tracking run in the background. Open /cc progress (or the Prg quick button) any time to see exploration, quest and combat stats, even if Chat and Games are disabled.")
    b:Buttons({
        { "OPEN PROGRESS HUB", function() if CC.ProgressHub then CC.ProgressHub:Toggle() end end, 160 },
    })

    b:Section("Portraits and scale")
    b:HalfToggle("Show player portraits", function() return CC.db.ui.showPortraits ~= false end, function(v) CC.db.ui.showPortraits = v end)
    b:Dropdown("Portrait style", function() return CC.db.ui.portraitStyle or "CLASS" end, function(v) CC.db.ui.portraitStyle = v end,
        { "CLASS", "2D", "3D" }, { CLASS = "Class + race", ["2D"] = "2D portrait", ["3D"] = "3D model" })
    b:Slider("Overall UI size", 0.70, 1.50, 0.05, function() return CC.db.ui.scale or 1 end, function(v) CC.db.ui.scale = v end, pct)
    b:Note("This scales the console, Games drawer, Settings, pop-outs and solo/multiplayer game windows. Oversized windows are automatically limited to the visible screen so controls cannot hang off an edge.")
    b:Slider("Message text scale", 0.80, 1.35, 0.05, function() return CC.db.ui.messageScale or 1 end, function(v) CC.db.ui.messageScale = v end, pct)
    b:Slider("Player icon size", 22, 44, 2, function() return CC.db.ui.iconSize or 26 end, function(v) CC.db.ui.iconSize = v end, px)

    b:Section("Game audio")
    CC.db.gameAudio = CC.db.gameAudio or { musicEnabled=true,musicVolume=0.35,effectsEnabled=true,effectsVolume=0.55 }
    b:HalfToggle("Background music", function() return CC.db.gameAudio.musicEnabled ~= false end, function(v) CC.db.gameAudio.musicEnabled=v; if CC.GameAudio then if v then CC.GameAudio:RestartMusic() else CC.GameAudio:StopMusic() end end end)
    b:HalfToggle("Game sound effects", function() return CC.db.gameAudio.effectsEnabled ~= false end, function(v) CC.db.gameAudio.effectsEnabled=v end)
    b:Slider("Game music volume", 0, 1, 0.05, function() return CC.db.gameAudio.musicVolume or 0.35 end, function(v) CC.db.gameAudio.musicVolume=v; if CC.GameAudio then CC.GameAudio:RestartMusic() end end, pct)
    b:Slider("Game effects volume", 0, 1, 0.05, function() return CC.db.gameAudio.effectsVolume or 0.55 end, function(v) CC.db.gameAudio.effectsVolume=v; if CC.GameAudio then CC.GameAudio:PlayEffect("CLICK") end end, pct)
    b:Note("Mini-game music and gameplay effects live here. Notification-card sounds are controlled only from the Notifications page.")
    b:Finish()
end

function Settings:BuildDock(page)
    local b = self:NewBuilder(page, "C Dock and Composer", "The saved dock width always means the complete visible C button plus Blizzard-native command field.")
    b:Section("Dimensions")
    b:Slider("Total C + command width", 320, 720, 10, function() return CC.db.ui.sharedDockWidth or 470 end,
        function(v) if UI.SetSharedDockWidth then UI:SetSharedDockWidth(v) else CC.db.ui.sharedDockWidth = v end end, px)
    b:Slider("C button width", 38, 64, 2, function() return CC.db.ui.dockButtonWidth or 46 end,
        function(v) CC.db.ui.dockButtonWidth = v; if UI.ApplyConnectedDockDimensions then UI:ApplyConnectedDockDimensions() end end, px)
    b:Slider("Composer scale", 0.70, 1.50, 0.05, function() return CC.db.ui.composerScale or 1 end, function(v) CC.db.ui.composerScale = v end, pct)
    b:Dropdown("Default composer destination", function() return CC.db.quickChannel or "GENERAL" end,
        function(v) CC.db.quickChannel = v; if UI.SetQuickDestination then UI:SetQuickDestination(v) end end,
        { "GENERAL", "GUILD", "PARTY", "RAID", "INSTANCE", "SAY" },
        { GENERAL = "General", GUILD = "Guild", PARTY = "Party", RAID = "Raid", INSTANCE = "Instance", SAY = "Say" })

    b:Section("Behaviour")
    b:HalfToggle("Typing opens main history", function() return CC.db.ui.openMainOnType ~= false end, function(v) CC.db.ui.openMainOnType = v end)
    b:HalfToggle("C opens composer + main", function() return CC.db.ui.launcherOpensComposer ~= false end, function(v) CC.db.ui.launcherOpensComposer = v end)
    b:HalfToggle("Composer attached to C", function() return CC.db.ui.composerAttached ~= false end, function(v) CC.db.ui.composerAttached = v end)
    b:HalfToggle("Lock composer movement", function() return CC.db.ui.composerLocked == true end, function(v) CC.db.ui.composerLocked = v end)
    b:HalfToggle("Show composer portrait", function() return CC.db.ui.composerShowPortrait ~= false end, function(v) CC.db.ui.composerShowPortrait = v end)
    b:HalfToggle("Show SEND button", function() return CC.db.ui.composerShowSend == true end, function(v) CC.db.ui.composerShowSend = v end)
    b:HalfToggle("Close composer after send", function() return CC.db.ui.composerCloseAfterSend ~= false end, function(v) CC.db.ui.composerCloseAfterSend = v end)

    b:Section("Motion")
    b:Dropdown("Composer reveal", function() return CC.db.ui.composerAnimation or "SLIDE_DOCK" end, function(v) CC.db.ui.composerAnimation = v end, ANIM_VALUES, ANIM_DISPLAY)
    b:Dropdown("Main history reveal", function() return CC.db.ui.dockAnimation or "SLIDE_DOCK" end, function(v) CC.db.ui.dockAnimation = v end, ANIM_VALUES, ANIM_DISPLAY)
    b:Slider("Animation duration", 0.10, 0.45, 0.05, function() return CC.db.ui.animationDuration or 0.20 end, function(v) CC.db.ui.animationDuration = v end, sec)
    b:Buttons({
        { "RESET DOCK", function()
            CC.db.positions.composer = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 72, y = 92 }
            if UI.quickInput then UI.quickInput.creshPositionApplied = false; UI:PositionQuickInput(true) end
        end, 128 },
        { "TEST DOCK", function() if UI.CloseDockChat then UI:CloseDockChat() end; if UI.OpenDockChat then UI:OpenDockChat() end end, 120 },
    })
    b:Finish()
end

function Settings:BuildWindows(page)
    local b = self:NewBuilder(page, "Windows and Pop-outs", "Choose full messenger bubbles or a lightweight wrapped table, then control fading, rows and placement.")
    b:Section("Main and detached windows")
    b:Dropdown("Other window animation", function() return CC.db.ui.windowAnimation or "SLIDE_LEFT" end, function(v) CC.db.ui.windowAnimation = v end, ANIM_VALUES, ANIM_DISPLAY)
    b:Note("Detached pop-outs are independent: they never snap to the C dock, steal Enter, or move again after you place them.")

    b:Section("Pop-out style")
    b:Dropdown("Message style", function() return CC.db.ui.popoutStyle or "NORMAL" end,
        function(v) CC.db.ui.popoutStyle = v; if UI.RefreshPopoutStyles then UI:RefreshPopoutStyles() end end,
        { "NORMAL", "COMPACT" }, { NORMAL = "Normal messenger bubbles", COMPACT = "Compact wrapped table" })
    b:Slider("Pop-out width", 300, 620, 10, function() return CC.db.ui.popoutWidth or 400 end,
        function(v) if UI.SetPopoutWidth then UI:SetPopoutWidth(v) else CC.db.ui.popoutWidth = v end end, px)
    b:Slider("Visible message rows", 4, 10, 1, function() return CC.db.ui.popoutRows or 6 end, function(v) CC.db.ui.popoutRows = v end, function(v) return floor(v + 0.5) .. " rows" end)
    b:Slider("Compact row height", 36, 68, 1, function() return CC.db.ui.popoutRowHeight or 44 end,
        function(v) CC.db.ui.popoutRowHeight = v; if UI.RefreshPopoutStyles then UI:RefreshPopoutStyles() end end, px)
    b:HalfToggle("Show native command field", function() return CC.db.ui.popoutShowCommand ~= false end, function(v) CC.db.ui.popoutShowCommand = v end)
    b:HalfToggle("Fade inactive pop-outs", function() return CC.db.ui.popoutFade == true end, function(v) CC.db.ui.popoutFade = v end)
    b:Slider("Pop-out fade delay", 1, 15, 1, function() return CC.db.ui.popoutFadeDelay or 4 end, function(v) CC.db.ui.popoutFadeDelay = v end, sec)
    b:Slider("Faded opacity", 0.10, 0.70, 0.05, function() return CC.db.ui.popoutFadeAlpha or 0.22 end, function(v) CC.db.ui.popoutFadeAlpha = v end, pct)
    b:Note("Normal uses the same wrapped messenger bubbles as the main chat. Compact keeps the table layout but uses incoming/outgoing bubble colours and wraps long text. C always opens or closes the connected dock, even with pop-outs open.")

    local function setRosterVisibility(key, value)
        CC.db.ui[key] = value and true or false
        if UI.RefreshConversationList then UI:RefreshConversationList() end
    end
    b:Section("Console roster cards")
    b:HalfToggle("Start with roster collapsed", function() return CC.db.ui.rosterCollapsed == true end,
        function(v) if UI.SetRosterCollapsed then UI:SetRosterCollapsed(v) else CC.db.ui.rosterCollapsed = v and true or false end end)
    b:HalfToggle("Game Friends: online", function() return CC.db.ui.showGameFriendsOnline ~= false end, function(v) setRosterVisibility("showGameFriendsOnline", v) end)
    b:HalfToggle("Game Friends: offline", function() return CC.db.ui.showGameFriendsOffline ~= false end, function(v) setRosterVisibility("showGameFriendsOffline", v) end)
    b:HalfToggle("Battle.net: online", function() return CC.db.ui.showBattleNetFriendsOnline ~= false end, function(v) setRosterVisibility("showBattleNetFriendsOnline", v) end)
    b:HalfToggle("Battle.net: offline", function() return CC.db.ui.showBattleNetFriendsOffline ~= false end, function(v) setRosterVisibility("showBattleNetFriendsOffline", v) end)
    b:HalfToggle("Guild members: online", function() return CC.db.ui.showGuildMembersOnline ~= false end, function(v) setRosterVisibility("showGuildMembersOnline", v) end)
    b:HalfToggle("Guild members: offline", function() return CC.db.ui.showGuildMembersOffline ~= false end, function(v) setRosterVisibility("showGuildMembersOffline", v) end)
    b:Note("These switches control the name cards shown beside chat. Friends use only Blizzard's actual Game Friends and Battle.net lists; Guild members remain separate.")
    b:Finish()
end

function Settings:BuildAlerts(page)
    local b = self:NewBuilder(page, "Notifications", "Control every CreshChat card popup from one place: visibility, priority, animation, placement, sound and volume.")

    b:Section("Master controls")
    b:HalfToggle("Enable all card popups", function() return CC.db.ui.notificationCardsEnabled ~= false end,
        function(v)
            CC.db.ui.notificationCardsEnabled = v and true or false
            if not v then
                while UI.toasts and #UI.toasts > 0 do if UI.DismissToast then UI:DismissToast(UI.toasts[#UI.toasts], true) else break end end
                while UI.secondaryToasts and #UI.secondaryToasts > 0 do if UI.DismissToast then UI:DismissToast(UI.secondaryToasts[#UI.secondaryToasts], true) else break end end
            end
            if UI.RefreshLauncherNotification then UI:RefreshLauncherNotification() end
        end)
    b:HalfToggle("Unified notification cards", function() return CC:IsFeatureEnabled("unifiedNotificationCards") end,
        function(v)
            CC:SetFeatureEnabled("unifiedNotificationCards", v)
            if not v and CC.Notifications and CC.Notifications.DismissAll then
                CC.Notifications:DismissAll()
            end
        end)
    b:HalfToggle("All notification sounds", function() return CC.db.sounds.master ~= false end, function(v) CC.db.sounds.master = v end)
    b:HalfToggle("Animated C notification outline", function() return CC.db.ui.launcherNotificationPulse ~= false end,
        function(v) CC.db.ui.launcherNotificationPulse = v; if UI.RefreshLauncherNotification then UI:RefreshLauncherNotification() end end)
    b:HalfToggle("Use CreshChat party invite only", function() return CC.db.ui.replacePartyInvitePopup == true end,
        function(v)
            CC.db.ui.replacePartyInvitePopup = v
            if v and CC.state.partyInvitePending and CC.SuppressBlizzardPartyInvitePopups then CC:SuppressBlizzardPartyInvitePopups()
            elseif not v and CC.RestoreBlizzardPartyInvitePopups then CC:RestoreBlizzardPartyInvitePopups() end
        end)
    b:Note("Card visibility and notification sounds are independent. Disabling cards hides their popup and launcher glow, while each category's Sound control still decides whether audio plays. Party invitations fall back to Blizzard's normal invitation window when their card type is disabled. Unified cards requires the master Notifications flag; disabling Notifications disables both renderers. Toggle with /cc notifcards on|off.")

    b:Section("Animation and placement")
    b:Dropdown("Overall card animation", function() return CC.db.ui.toastAnimation or "FAN_UP" end,
        function(v) CC.db.ui.toastAnimation = v end, NOTIFICATION_ANIMATION_VALUES, ANIM_DISPLAY)
    b:Slider("Animation speed", 0.08, 0.55, 0.01, function() return CC.db.ui.animationDuration or 0.20 end, function(v) CC.db.ui.animationDuration = v end, sec)
    b:Dropdown("Card anchor", function() return CC.db.ui.cardLocation or "DOCK" end, function(v) CC.db.ui.cardLocation = v; repositionCards() end,
        { "DOCK", "MAIN", "SCREEN", "CUSTOM" }, { DOCK = "Attached to C", MAIN = "Above main chat", SCREEN = "Screen grid", CUSTOM = "Custom right-drag" })
    b:Dropdown("Horizontal position", function() return CC.db.ui.cardHorizontal or "LEFT" end, function(v) CC.db.ui.cardHorizontal = v; CC.db.ui.cardLocation = "SCREEN"; repositionCards() end,
        { "LEFT", "CENTER", "RIGHT" }, { LEFT = "Left", CENTER = "Middle", RIGHT = "Right" })
    b:Dropdown("Vertical position", function() return CC.db.ui.cardVertical or "BOTTOM" end, function(v) CC.db.ui.cardVertical = v; CC.db.ui.cardLocation = "SCREEN"; repositionCards() end,
        { "TOP", "MIDDLE", "BOTTOM" }, { TOP = "Top", MIDDLE = "Middle", BOTTOM = "Bottom" })
    b:Dropdown("Notification stack direction",
        function() return CC.db.ui.notifStackDirection or CC.db.ui.cardStack or "UP" end,
        function(v) CC.db.ui.notifStackDirection = v; repositionCards() end,
        { "UP", "DOWN", "LEFT", "RIGHT" },
        { UP = "Stack upward", DOWN = "Stack downward", LEFT = "Stack leftward", RIGHT = "Stack rightward" })
    b:Dropdown("Slide-out direction", function() return CC.db.ui.notificationSlideDirection or "BOTTOM" end, function(v) CC.db.ui.notificationSlideDirection = v; repositionCards() end,
        { "TOP", "BOTTOM", "LEFT", "RIGHT" }, { TOP = "Above the main card", BOTTOM = "Below the main card", LEFT = "Left of the main card", RIGHT = "Right of the main card" })

    b:Section("Card size and timing")
    b:Slider("Normal slide-out time", 3, 30, 1, function() return CC.db.ui.priorityCardDuration or 10 end, function(v) CC.db.ui.priorityCardDuration = v; CC.db.alertDuration = v end, sec)
    b:Slider("Full-size main-card time", 2, 20, 1, function() return CC.db.ui.secondaryCardDuration or 6 end, function(v) CC.db.ui.secondaryCardDuration = v end, sec)
    b:Slider("Card width", 230, 440, 10, function() return CC.db.ui.cardWidth or 300 end, function(v) CC.db.ui.cardWidth = v; repositionCards() end, px)
    b:Slider("Card height", 56, 104, 2, function() return CC.db.ui.cardHeight or 68 end, function(v) CC.db.ui.cardHeight = v; repositionCards() end, px)
    b:Slider("Overall card scale", 0.65, 1.50, 0.05, function() return CC.db.ui.notificationScale or CC.db.ui.cardScale or 0.95 end, function(v) CC.db.ui.notificationScale = v; CC.db.ui.cardScale = v; repositionCards() end, pct)
    b:Slider("Stack spacing", 0, 16, 1, function() return CC.db.ui.cardSpacing or 6 end, function(v) CC.db.ui.cardSpacing = v; repositionCards() end, px)
    b:Slider("Maximum slide-outs", 1, 10, 1, function() return CC.db.ui.cardMaxVisible or 6 end, function(v) CC.db.ui.cardMaxVisible = v end, function(v) return floor(v + 0.5) end)
    b:Slider("Maximum main cards", 1, 8, 1, function() return CC.db.ui.secondaryCardMaxVisible or 4 end, function(v) CC.db.ui.secondaryCardMaxVisible = v end, function(v) return floor(v + 0.5) end)
    b:Slider("Card accent thickness", 2, 6, 1, function() return CC.db.ui.notificationLineHeight or 3 end,
        function(v) CC.db.ui.notificationLineHeight = v; repositionCards() end, px)
    b:Slider("Compact card width", 0.72, 0.96, 0.02, function() return CC.db.ui.secondaryCardWidthRatio or 0.88 end,
        function(v) CC.db.ui.secondaryCardWidthRatio = v; if UI.RepositionToasts then UI:RepositionToasts() end end, pct)
    b:Slider("Compact card height", 0.62, 0.92, 0.02, function() return CC.db.ui.secondaryCardHeightRatio or 0.80 end,
        function(v) CC.db.ui.secondaryCardHeightRatio = v; if UI.RepositionToasts then UI:RepositionToasts() end end, pct)
    b:Slider("Dock whisper preview width", 140, 280, 10, function() return CC.db.ui.dockWhisperWidth or 190 end,
        function(v) CC.db.ui.dockWhisperWidth = v; if UI.PositionWhisperDockAlert then UI:PositionWhisperDockAlert() end end, px)
    b:Slider("Dock whisper preview time", 3, 15, 1, function() return CC.db.ui.dockWhisperDuration or 6 end,
        function(v) CC.db.ui.dockWhisperDuration = v end, sec)
    b:HalfToggle("Lock card position", function() return CC.db.ui.cardLocked == true end, function(v) CC.db.ui.cardLocked = v end)
    b:HalfToggle("Merge repeat whispers", function() return CC.db.ui.cardCoalesce ~= false end, function(v) CC.db.ui.cardCoalesce = v end)
    b:HalfToggle("Whisper preview chip from C", function() return CC.db.ui.showDockWhisperAlert ~= false end, function(v) CC.db.ui.showDockWhisperAlert = v; if not v and UI.DismissWhisperDockAlert then UI:DismissWhisperDockAlert(true) end end)

    local sections = {
        { "Whispers", "whisper", "WHISPER", "Direct messages and Battle.net whispers.", "CRESH_CRYSTAL_01", 0.65 },
        { "Guild", "guild", "GUILD", "Guild and Officer messages matching the trigger below.", "CRESH_SOFT_BELL_02", 0.55 },
        { "Party invitations", "partyInvite", "PARTY_INVITE", "Actionable incoming party invitations.", "CRESH_ARCANE_02", 0.65 },
        { "Party messages", "partyMessage", "PARTY_MESSAGE", "Party, raid and instance-group messages.", "CRESH_WOOD_TICK_02", 0.50 },
        { "Public mentions", "mentions", "GENERAL", "Public-channel messages that mention your character.", "CRESH_WOOD_TICK_02", 0.50 },
        { "Friends", "friends", "FRIEND", "Battle.net and character-friend online/offline notices.", "CRESH_SOFT_BELL_01", 0.45 },
        { "Quest dialogue", "quest", "QUEST", "Quest dialogue captured by CreshChat.", "CRESH_SOFT_BELL_04", 0.55 },
        { "System", "system", "SYSTEM", "CreshChat status, group-state and system cards.", "OFF", 0.45 },
        { "Games and rewards", "game", "GAME", "Battle Pass, unlock, game invite and reward cards.", "COIN", 0.55 },
    }
    CC.db.notificationPriorities = CC.db.notificationPriorities or {}
    CC.db.soundChoices = CC.db.soundChoices or {}
    CC.db.soundVolumes = CC.db.soundVolumes or {}
    for _, item in ipairs(sections) do
        local title, key, kind, description, fallbackSound, fallbackVolume = item[1], item[2], item[3], item[4], item[5], item[6]
        b:Section(title)
        b:HalfToggle("Show card popup", function() return CC.db.notifications[key] ~= false end,
            function(v)
                CC.db.notifications[key] = v and true or false
                if key == "system" then CC.db.ui.showSystemCards = v and true or false end
                if not v and UI.DismissToast and CC.GetNotificationKey then
                    for _, list in ipairs({ UI.toasts or {}, UI.secondaryToasts or {} }) do
                        for index = #list, 1, -1 do
                            local toast = list[index]
                            if CC:GetNotificationKey(toast.kind or toast.channel) == key then UI:DismissToast(toast, true) end
                        end
                    end
                end
                if UI.RefreshLauncherNotification then UI:RefreshLauncherNotification() end
            end)
        b:Dropdown("Priority", function() return CC.GetNotificationPriority and CC:GetNotificationPriority(kind) or (CC.db.notificationPriorities[key] or "NORMAL") end,
            function(v)
                if CC.SetNotificationPriority then CC:SetNotificationPriority(kind, v) else CC.db.notificationPriorities[key] = v end
                if UI.RepositionToasts then UI:RepositionToasts() end
            end, NOTIFICATION_PRIORITY_VALUES, NOTIFICATION_PRIORITY_DISPLAY)
        b:Dropdown("Sound", function() return CC.db.soundChoices[key] or fallbackSound end,
            function(v) chooseSound(key, kind, v) end, SOUND_VALUES[key] or ALL_SOUND_VALUES, SOUND_DISPLAY)
        b:Slider("Sound volume", 0, 1, 0.05, function() return tonumber(CC.db.soundVolumes[key]) or fallbackVolume end,
            function(v) CC.db.soundVolumes[key] = v end, pct)
        if key == "guild" then
            b:Dropdown("Guild card trigger", function() return CC.db.guildAlerts or "all" end, function(v) CC.db.guildAlerts = v end,
                { "all", "mentions", "off" }, { all = "All Guild messages", mentions = "Mentions only", off = "Never" })
        elseif key == "system" then
            b:HalfToggle("Hide unavailable-player whisper line", function() return CC.db.ui.suppressOfflineWhisperErrors ~= false end,
                function(v) CC.db.ui.suppressOfflineWhisperErrors = v and true or false; if CC.RegisterChatFilters then CC:RegisterChatFilters() end end)
            b:Note("Hides only Blizzard's ‘No player named … is currently online/playing’ line. The attempted CreshChat whisper remains visible and is marked failed instead.")
        end
        b:Note(description)
    end

    -- CreshGames and CreshCollect: per-category toggles built from the live
    -- registry.  Settings:Build() is called lazily on first open, so all
    -- addon stubs have already loaded and registered their categories.
    if CC.Notifications then
        local extSources = {
            { "CRESHGAMES",   "CreshGames" },
            { "CRESHCOLLECT", "CreshCollect" },
        }
        for _, srcItem in ipairs(extSources) do
            local srcKey, srcLabel = srcItem[1], srcItem[2]
            if CC.Notifications:GetRegisteredSources()[srcKey] then
                local cats     = CC.Notifications:GetRegisteredCategories(srcKey)
                local catOrder = {}
                for catKey in pairs(cats) do catOrder[#catOrder + 1] = catKey end
                table.sort(catOrder)
                b:Section(srcLabel .. " notifications")
                for _, catKey in ipairs(catOrder) do
                    local info    = cats[catKey]
                    local cSrc    = srcKey
                    local cCat    = catKey
                    b:HalfToggle(info.label,
                        function()
                            local s = CC.db.notificationSources and CC.db.notificationSources[cSrc]
                            return not s or s[cCat] ~= false
                        end,
                        function(v)
                            CC.db.notificationSources = CC.db.notificationSources or {}
                            CC.db.notificationSources[cSrc] = CC.db.notificationSources[cSrc] or {}
                            CC.db.notificationSources[cSrc][cCat] = v and true or false
                        end
                    )
                end
            end
        end
    end

    b:Section("C launcher visibility")
    b:HalfToggle("Fade C button when idle", function() return CC.db.ui.launcherIdleFade == true end,
        function(v) CC.db.ui.launcherIdleFade = v; if UI.MarkLauncherActive then UI:MarkLauncherActive() end end)
    b:HalfToggle("Hide C button during combat", function() return CC.db.ui.launcherHideInCombat == true end,
        function(v) CC.db.ui.launcherHideInCombat = v; if UI.SetBubbleGroupShown then UI:SetBubbleGroupShown(CC.db.bubbleVisible) end end)
    b:Slider("Idle fade delay", 1, 30, 1, function() return CC.db.ui.launcherIdleDelay or 5 end,
        function(v) CC.db.ui.launcherIdleDelay = v; if UI.MarkLauncherActive then UI:MarkLauncherActive() end end, sec)
    b:Slider("Idle opacity", 0.05, 0.75, 0.05, function() return CC.db.ui.launcherIdleAlpha or 0.18 end,
        function(v) CC.db.ui.launcherIdleAlpha = v; if UI.RefreshLauncherVisibility then UI:RefreshLauncherVisibility(true) end end, pct)

    b:Section("Preview")
    b:Buttons({
        { "WHISPER", function() previewNotification("WHISPER"); if UI.ShowSlideToast then UI:ShowSlideToast("Whisper preview", "A direct-message card using your current settings.", "WHISPER", "PREVIEW:WHISPER", nil, "WHISPER", "Preview") end end, 104 },
        { "GUILD", function() previewNotification("GUILD"); if UI.ShowSlideToast then UI:ShowSlideToast("Guild preview", "A Guild notification card using your current settings.", "GUILD", "PREVIEW:GUILD", nil, "GUILD", nil) end end, 96 },
        { "PARTY", function() previewNotification("PARTY_MESSAGE"); if UI.ShowSlideToast then UI:ShowSlideToast("Party preview", "A party-message notification card.", "PARTY", "PREVIEW:PARTY", nil, "PARTY_MESSAGE", nil) end end, 96 },
    })
    b:Buttons({
        { "FRIEND", function() if UI.ShowPresenceToast then UI:ShowPresenceToast("Preview Friend", true) end end, 104 },
        { "REWARD", function() if UI.ShowBattlePassToast then UI:ShowBattlePassToast("Reward preview", "A Battle Pass or game reward card.", "BATTLEPASS", "PREVIEW:GAME") end end, 96 },
        { "SYSTEM", function() if UI.ShowSystemToast then UI:ShowSystemToast("System preview", "A system notification using your current settings.", "INFO") end end, 96 },
    })
    b:Note("Priority controls presentation: Critical and High use the full-size main-card lane; Normal and Low use compact slide-outs. Low-priority cards also expire sooner.")
    b:Finish()
end


local CONSOLE_TAB_LABELS = {
    FRIENDS="Friends", WHISPER="Whispers", GUILD="Guild", GENERAL="General feed", QUEST="Quest chats", COMBAT="Combat log",
    TRADE="Trade", PARTY="Party", RAID="Raid", INSTANCE="Instance", LFG="Looking For Group",
    SAY="Say", YELL="Yell", EMOTE="Emotes", LOCALDEFENSE="Local Defense",
}

local function setConsoleTab(key, value)
    CC.db.ui.consoleTabs = CC.db.ui.consoleTabs or {}
    CC.db.ui.consoleTabs[key] = value and true or false
    local any = false
    for _, definition in ipairs(UI.CONSOLE_TAB_DEFINITIONS or {}) do
        if CC.db.ui.consoleTabs[definition.key] == true then any = true; break end
    end
    if not any then CC.db.ui.consoleTabs.FRIENDS = true end
    if UI.RefreshConsoleTabs then UI:RefreshConsoleTabs() end
end

function Settings:BuildConsole(page)
    local b = self:NewBuilder(page, "Console Tabs", "Choose exactly which chat tabs appear in the CreshChat console. Card popups, priorities, animations and sounds are now controlled only from Notifications.")
    b:Section("Core console tabs")
    local core = { "FRIENDS", "WHISPER", "GUILD", "GENERAL", "QUEST", "COMBAT" }
    for _, key in ipairs(core) do
        local tabKey = key
        b:HalfToggle(CONSOLE_TAB_LABELS[tabKey], function() return CC.db.ui.consoleTabs[tabKey] ~= false end, function(v) setConsoleTab(tabKey, v) end)
    end

    b:Section("Optional channel tabs")
    local optional = { "TRADE", "PARTY", "RAID", "INSTANCE", "LFG", "SAY", "YELL", "EMOTE", "LOCALDEFENSE" }
    for _, key in ipairs(optional) do
        local tabKey = key
        b:HalfToggle(CONSOLE_TAB_LABELS[tabKey], function() return CC.db.ui.consoleTabs[tabKey] == true end, function(v) setConsoleTab(tabKey, v) end)
    end
    b:Note("Optional channel tabs filter the existing General history rather than duplicating messages. When selected, the shared composer sends directly to that channel. Tabs wrap onto additional rows so they stay inside the console width.")

    b:Buttons({
        { "CORE ONLY", function()
            local enabled = { FRIENDS=true, WHISPER=true, GUILD=true, GENERAL=true, QUEST=true, COMBAT=true }
            for _, definition in ipairs(UI.CONSOLE_TAB_DEFINITIONS or {}) do CC.db.ui.consoleTabs[definition.key] = enabled[definition.key] == true end
            if UI.RefreshConsoleTabs then UI:RefreshConsoleTabs() end
        end, 112 },
        { "CHAT FOCUS", function()
            local enabled = { FRIENDS=true, WHISPER=true, GUILD=true, GENERAL=true, TRADE=true, PARTY=true, RAID=true, INSTANCE=true, LFG=true }
            for _, definition in ipairs(UI.CONSOLE_TAB_DEFINITIONS or {}) do CC.db.ui.consoleTabs[definition.key] = enabled[definition.key] == true end
            if UI.RefreshConsoleTabs then UI:RefreshConsoleTabs() end
        end, 112 },
    })
    b:Finish()
end

function Settings:BuildThemes(page)
    local b = self:NewBuilder(page, "Global Theme", "Choose an unlocked theme to apply it immediately. Locked Battle Pass and Cresh Coin themes remain visible so you can jump directly to their unlock requirement.")
    b:Section("Theme selection")
    b:Dropdown("Active theme", function()
            return CC.db.ui.themePreset or "CRESH_MINIMAL"
        end,
        function() end,
        THEME_VALUES, THEME_DISPLAY, {
            isLocked = function(theme)
                if theme == "CUSTOM" then return false end
                return CC.BattlePass and CC.BattlePass.IsThemeUnlocked and not CC.BattlePass:IsThemeUnlocked(theme) or false
            end,
            onSelect = function(theme, locked)
                if locked then
                    Settings:CloseDropdown()
                    if Settings.frame then Settings.frame:Hide() end
                    if CC.BattlePass and CC.BattlePass.OpenThemeUnlock then
                        CC.BattlePass:OpenThemeUnlock(theme)
                    elseif UI.OpenGameDrawer then
                        UI:OpenGameDrawer("THEMES")
                    end
                    return
                end
                if UI.CancelThemePreview and UI.IsThemePreviewActive and UI:IsThemePreviewActive() then
                    UI:CancelThemePreview(true)
                end
                if theme == "CUSTOM" then
                    CC.db.ui.themePreset = "CUSTOM"
                    if UI.ApplyVisualSettings then UI:ApplyVisualSettings() end
                elseif UI.ApplyThemePreset then
                    UI:ApplyThemePreset(theme)
                end
            end,
        })
    b:Note("Unlocked themes apply as soon as you select them. Locked themes use a darker grey row marked [LOCKED]; selecting one closes Settings and opens Games > Unlock Themes at that exact theme.")
    b:Section("Surface colours")
    b:HalfColor("Accent / buttons", function() return CC.db.colors.accent end)
    b:HalfColor("Panel background", function() return CC.db.colors.panel end)
    b:HalfColor("Secondary panels", function() return CC.db.colors.panelSoft end)
    b:HalfColor("Raised surfaces", function() return CC.db.colors.panelRaised end)
    b:HalfColor("Borders", function() return CC.db.colors.border end)
    b:HalfColor("Incoming messages", function() return CC.db.colors.incoming end)
    b:HalfColor("Your messages", function() return CC.db.colors.outgoing end)
    b:Finish()
end

local function guildColor(key)
    CC.db.colors.guild = CC.db.colors.guild or {}
    CC.db.colors.guild[key] = CC.db.colors.guild[key] or { 0.18, 0.78, 0.36, 1 }
    return CC.db.colors.guild[key]
end

function Settings:BuildGuild(page)
    local b = self:NewBuilder(page, "Guild Chat", "Guild styling is independent from the global theme. Choose verdant, emerald, jade, moss, parchment, fel, Alliance or Horde palettes with separate backgrounds and chat-bubble colours.")
    b:Section("Guild identity")
    b:HalfToggle("Use dedicated Guild theme", function() return CC.db.ui.guildTheme ~= false end, function(v) CC.db.ui.guildTheme = v end)
    b:Dropdown("Guild theme", function() return CC.db.ui.guildThemePreset or "AUTO" end,
        function() end,
        GUILD_THEME_VALUES, GUILD_THEME_DISPLAY, {
            isLocked = function(theme)
                return UI.IsGuildThemeUnlocked and not UI:IsGuildThemeUnlocked(theme) or false
            end,
            onSelect = function(theme, locked)
                if locked then
                    local unlockKey = UI.GetGuildThemeUnlockKey and UI:GetGuildThemeUnlockKey(theme) or nil
                    Settings:CloseDropdown()
                    if Settings.frame then Settings.frame:Hide() end
                    if unlockKey and CC.BattlePass and CC.BattlePass.OpenThemeUnlock then
                        CC.BattlePass:OpenThemeUnlock(unlockKey)
                    elseif UI.OpenGameDrawer then
                        UI:OpenGameDrawer("THEMES")
                    end
                    return
                end
                if UI.ApplyGuildThemePreset then UI:ApplyGuildThemePreset(theme)
                else CC.db.ui.guildThemePreset = theme end
            end,
        })
    b:Note("The Guild header and pop-outs use your tabard crest when the client exposes it. Guild card triggers, priority, sound and volume are controlled from Notifications. Premium matching Guild palettes are darkened and marked [LOCKED] until their Global Theme is unlocked.")

    b:Section("Custom Guild colours")
    b:HalfColor("Guild accent", function() return guildColor("accent") end, "GUILD")
    b:HalfColor("Guild border", function() return guildColor("border") end, "GUILD")
    b:HalfColor("Guild background", function() return guildColor("panel") end, "GUILD")
    b:HalfColor("Raised Guild boxes", function() return guildColor("panelRaised") end, "GUILD")
    b:HalfColor("Incoming Guild rows", function() return guildColor("incoming") end, "GUILD")
    b:HalfColor("Your Guild rows", function() return guildColor("outgoing") end, "GUILD")
    b:HalfColor("Officer accent", function() return guildColor("officer") end, "GUILD")
    b:HalfColor("Muted Guild text", function() return guildColor("muted") end, "GUILD")
    b:Finish()
end

local CHANNELS = {
    { "GENERAL", "General" }, { "TRADE", "Trade" }, { "LOCALDEFENSE", "LocalDefense" },
    { "LFG", "LookingForGroup" }, { "SAY", "Say" }, { "YELL", "Yell" },
    { "PARTY", "Party" }, { "RAID", "Raid" }, { "INSTANCE", "Instance" },
    { "GUILD", "Guild accent" }, { "OFFICER", "Officer" }, { "EMOTE", "Emote" },
    { "WHISPER", "Whisper" }, { "CHANNEL", "Custom channels" },
}

function Settings:BuildChannels(page)
    local b = self:NewBuilder(page, "Channel Colours", "Each General-feed message uses a small coloured rail so channels can be recognised instantly.")
    b:Section("General feed rails")
    for _, item in ipairs(CHANNELS) do
        b:HalfColor(item[2], function()
            CC.db.colors.channels[item[1]] = CC.db.colors.channels[item[1]] or { 0.5, 0.6, 0.8, 1 }
            return CC.db.colors.channels[item[1]]
        end)
    end
    b:Finish()
end

function Settings:BuildProfiles(page)
    local currentKey = CC.GetCurrentCharacterProfileKey and CC:GetCurrentCharacterProfileKey() or "Current character"
    local currentName = CC.GetCharacterProfileDisplay and CC:GetCharacterProfileDisplay(currentKey) or currentKey
    local values, display = {}, {}
    if CC.GetCharacterProfileOptions then values, display = CC:GetCharacterProfileOptions(true) end

    local b = self:NewBuilder(page, "Character Profiles", "Game XP, Battle Pass progress, Cresh Coins, unlocks and achievements are account-wide. This page copies only interface appearance and placement between characters.")
    b:Section("Current character")
    b:Note("Active profile: " .. tostring(currentName))
    b:Note("Direct whispers and Battle.net conversations are shared across your characters and kept between logins. Guild, General, Combat and quest conversations remain session-only and clear on login or reload.")

    b:Section("Copy interface from another character")
    if #values > 0 then
        if not self.profileCopySelection or not display[self.profileCopySelection] then self.profileCopySelection = values[1] end
        b:Dropdown("Source character", function() return Settings.profileCopySelection or values[1] end,
            function(v) Settings.profileCopySelection = v end, values, display)
        b:Buttons({
            { "COPY UI + LAYOUT", function()
                local source = Settings.profileCopySelection
                if source and CC.CopyUIFromCharacterProfile and CC:CopyUIFromCharacterProfile(source) then
                    local saved = CC.db.sizes and CC.db.sizes.settings
                    if Settings.frame and saved then
                        Settings.frame:SetSize(tonumber(saved.width) or Settings.frame:GetWidth(), tonumber(saved.height) or Settings.frame:GetHeight())
                    end
                    Settings:Relayout()
                    Settings:Refresh()
                    if CC.Print then CC:Print("Copied interface and window placement from " .. tostring(display[source] or source) .. ".") end
                elseif CC.Print then
                    CC:Print("That character profile could not be copied.")
                end
            end, 180 },
        })
    else
        b:Note("No other character profiles are available yet. Log into an alt once to create its profile, then return here to copy an interface setup.")
    end
    b:Note("Copied: theme and colours, UI scale, console and launcher settings, window sizes and positions, cards, sound choices and channel settings. Account-wide progression is shared automatically and is never overwritten by copying an interface profile.")
    b:Finish()
end

function Settings:BuildModules(page)
    local b = self:NewBuilder(page, "Feature Modules",
        "Enable or disable major CreshChat subsystems. Disabled modules become genuinely dormant — event handlers return early, hooks no-op, background processing stops. Changes require /reload to fully activate.")

    b:Section("Presets")
    b:Buttons({
        { "Full CreshChat", function() CC:ApplyFeaturePreset("full");    Settings:Refresh() end, 120 },
        { "Games Only",     function() CC:ApplyFeaturePreset("games");   Settings:Refresh() end, 120 },
        { "Chat Only",      function() CC:ApplyFeaturePreset("chat");    Settings:Refresh() end, 120 },
        { "Minimal",        function() CC:ApplyFeaturePreset("minimal"); Settings:Refresh() end, 120 },
    })
    b:Note("Presets switch groups of modules at once. After choosing a preset, type /reload in chat to activate. Message history and progression data are never deleted by changing modules.")

    b:Section("Individual modules")
    for _, key in ipairs(CC.featureOrder or {}) do
        local displayName = (CC.featureDisplayNames and CC.featureDisplayNames[key]) or key
        b:HalfToggle(
            displayName,
            function() return CC:IsFeatureEnabled(key) end,
            function(v) CC:SetFeatureEnabled(key, v) end
        )
    end
    b:Note("Dependency cascades apply automatically: disabling Games also disables Multiplayer Games, Game Progression and Battle Pass; disabling Chat also disables Voice. Type /reload after any individual change.")

    b:Finish()
end

function Settings:BuildAdvanced(page)
    local b = self:NewBuilder(page, "Advanced and Maintenance", "Native slash-command routing, diagnostic tools and safe UI resets.")
    b:Section("Blizzard command compatibility")
    b:HalfToggle("Native WoW slash commands", function() return CC.db.ui.nativeSlashCommands ~= false end, function(v) CC.db.ui.nativeSlashCommands = v end)
    b:HalfToggle("Remember command history", function() return CC.db.ui.commandHistory ~= false end, function(v) CC.db.ui.commandHistory = v end)
    b:HalfToggle("Single shared composer", function() return CC.db.ui.singleComposer ~= false end, function(v) CC.db.ui.singleComposer = v end)
    b:Note("Slash-prefixed text is passed to Blizzard's native parser, supporting /reload, /sit, emotes, targeting, macros, channels and commands registered by other addons.")

    b:Section("History and diagnostics")
    b:Slider("Chat history per feed", 40, 500, 10, function() return CC.db.historyLimit or 120 end,
        function(v) CC.db.historyLimit = v; if CC.Quality and CC.Quality.SanitizeDatabase then CC.Quality:SanitizeDatabase() end end,
        function(v) return floor(v + 0.5) .. " messages" end)
    b:Slider("Combat history limit", 80, 600, 20, function() return CC.db.combatHistoryLimit or 220 end,
        function(v) CC.db.combatHistoryLimit = v; if CC.Quality and CC.Quality.SanitizeDatabase then CC.Quality:SanitizeDatabase() end end,
        function(v) return floor(v + 0.5) .. " events" end)
    b:HalfToggle("Show build badge in console", function() return CC.db.ui.showBuildBadge == true end,
        function(v) CC.db.ui.showBuildBadge = v and true or false; if UI.LayoutMainHeader then UI:LayoutMainHeader() end end)
    b:Note("The build badge automatically hides when the console is too narrow to display it without covering chat controls.")
    b:Buttons({
        { "REFRESH SOCIAL", function()
            if _G.C_FriendList and type(_G.C_FriendList.ShowFriends) == "function" then pcall(_G.C_FriendList.ShowFriends) end
            if type(_G.ShowFriends) == "function" then pcall(_G.ShowFriends) end
            if type(_G.GuildRoster) == "function" then pcall(_G.GuildRoster) end
            if CC.Friends and CC.Friends.Refresh then pcall(CC.Friends.Refresh, CC.Friends, true) end
            if UI.RefreshConversationList then UI:RefreshConversationList() end
        end, 138 },
        { "HEALTH", function() CC:HandleSlashCommand("health") end, 100 },
    })
    b:Section("Diagnostics")
    b:Buttons({
        { "OPTIMISE", function() CC:HandleSlashCommand("optimise") end, 108 },
        { "STATUS", function() CC:HandleSlashCommand("status") end, 96 },
    })
    b:Buttons({
        { "TEST ALL", function() CC:HandleSlashCommand("test") end, 100 },
        { "VERSION", function() CC:HandleSlashCommand("version") end, 100 },
        { "DEV REPORT", function() CC:HandleSlashCommand("devreport") end, 118 },
    })
    b:Buttons({
        { "MODULES", function() CC:HandleSlashCommand("modules") end, 100 },
        { "ASSETS", function() CC:HandleSlashCommand("assets") end, 100 },
    })
    b:Note("Health reports live event sources and refresh activity. Dev Report verifies module loading, SavedVariables structure and registered asset libraries. Optimise validates saved values and enforces safe history/cache limits.")
    b:Section("Reset")
    b:Buttons({
        { "RESET UI", function() if CC.ResetUISettings then CC:ResetUISettings() end end, 120 },
        { "RESTORE BLIZZARD CHAT", function() CC.db.hideBlizzard = false; CC:ApplyBlizzardChatVisibility(); Settings:Refresh() end, 180 },
    })
    b:Note("Reset UI restores CreshChat layout and appearance defaults but keeps message history. Completely deleting SavedVariables is the only full database reset.")
    b:Finish()
end

function Settings:CreatePage(name)
    local scroll = CreateFrame("ScrollFrame", nil, self.content, "UIPanelScrollFrameTemplate")
    raiseFrame(scroll, self.content, 6)
    scroll:SetAllPoints()
    if scroll.SetAlpha then scroll:SetAlpha(1) end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(selfScroll, delta)
        local current = selfScroll:GetVerticalScroll() or 0
        local maximum = selfScroll:GetVerticalScrollRange() or 0
        selfScroll:SetVerticalScroll(max(0, min(maximum, current - delta * 42)))
    end)
    local canvas = CreateFrame("Frame", nil, scroll)
    raiseFrame(canvas, scroll, 1)
    canvas:SetSize(self.pageWidth, 520)
    if canvas.SetAlpha then canvas:SetAlpha(1) end
    scroll:SetScrollChild(canvas)
    scroll.canvas = canvas
    if scroll.ScrollBar then
        raiseFrame(scroll.ScrollBar, scroll, 3)
        if scroll.ScrollBarScrollUpButton then raiseFrame(scroll.ScrollBarScrollUpButton, scroll.ScrollBar, 1) end
        if scroll.ScrollBarScrollDownButton then raiseFrame(scroll.ScrollBarScrollDownButton, scroll.ScrollBar, 1) end
    end
    scroll:Hide()
    self.pages[name] = scroll
    return scroll
end

function Settings:SetPage(name)
    self:CloseDropdown()
    self.activePage = name
    for pageName, page in pairs(self.pages) do
        page:SetShown(pageName == name)
        if pageName == name then
            if page.SetAlpha then page:SetAlpha(1) end
            if page.canvas and page.canvas.SetAlpha then page.canvas:SetAlpha(1) end
        end
    end
    self:RestorePageVisibility()
    local accent = CC.db and CC.db.colors and CC.db.colors.accent or { 0.11, 0.43, 0.95, 1 }
    for pageName, tab in pairs(self.tabs) do
        tab.creshActive = pageName == name
        if tab.SetBackdropColor then
            if tab.creshActive then tab:SetBackdropColor(accent[1] * 0.65, accent[2] * 0.65, accent[3] * 0.65, 1)
            else tab:SetBackdropColor(0.075, 0.086, 0.112, 1) end
        end
        if tab.text then tab.text:SetTextColor(tab.creshActive and 1 or 0.72, tab.creshActive and 1 or 0.77, tab.creshActive and 1 or 0.84, 1) end
    end
end

function Settings:Relayout()
    if not self.frame or not self.content then return end
    local sidebarWidth = self.sidebarWidth or 132
    local frameWidth, frameHeight = self.frame:GetWidth(), self.frame:GetHeight()
    local contentWidth = max(360, frameWidth - sidebarWidth - 30)
    local contentHeight = max(300, frameHeight - 88)
    if self.compactLabel then self.compactLabel:SetShown(frameWidth >= 650) end
    self.sidebar:SetSize(sidebarWidth, contentHeight)
    self.content:SetSize(contentWidth, contentHeight)
    self.pageWidth = max(340, contentWidth - 24)
    local fullWidth = max(320, self.pageWidth - 24)
    local halfWidth = max(150, (fullWidth - 8) / 2)
    for _, page in pairs(self.pages or {}) do
        page:SetSize(contentWidth, contentHeight)
        page.canvas:SetWidth(self.pageWidth)
    end
    for _, control in ipairs(self.layoutControls or {}) do
        if control.creshLayoutKind == "half" then
            control:SetWidth(halfWidth)
            local x = 12 + ((control.creshLayoutColumn or 1) - 1) * (halfWidth + 8)
            local point, relativeTo, relativePoint, _, y = control:GetPoint(1)
            control:ClearAllPoints(); control:SetPoint(point or "TOPLEFT", relativeTo or control:GetParent(), relativePoint or "TOPLEFT", x, y or 0)
        else
            control:SetWidth(fullWidth)
        end
        if control.Relayout then control:Relayout() end
    end
end

local function restoreFontAlpha(frame, depth)
    if not frame or (depth or 0) > 8 then return end
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for _, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.SetAlpha then
                region:SetAlpha(1)
            end
        end
    end
    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do restoreFontAlpha(child, (depth or 0) + 1) end
    end
end

function Settings:RestorePageVisibility()
    if self.content and self.content.SetAlpha then self.content:SetAlpha(1) end
    if self.sidebar and self.sidebar.SetAlpha then self.sidebar:SetAlpha(1) end
    for _, page in pairs(self.pages or {}) do
        if page.SetAlpha then page:SetAlpha(1) end
        if page.canvas and page.canvas.SetAlpha then page.canvas:SetAlpha(1) end
        restoreFontAlpha(page, 0)
    end
end

function Settings:KeepOnTop()
    local frame = self.frame
    if not frame then return end
    frame.creshAlwaysOnTop = true
    if frame.SetFrameStrata then frame:SetFrameStrata("FULLSCREEN_DIALOG") end
    if frame.SetFrameLevel then frame:SetFrameLevel(SETTINGS_FRAME_LEVEL) end
    if frame.SetToplevel then frame:SetToplevel(true) end
    if frame.SetAlpha then frame:SetAlpha(1) end

    -- Keep every Settings layer below the client frame-level ceiling. Using
    -- 9999 caused child panels to collide at the ceiling and the content
    -- backdrop could render above its own text on TBC Anniversary clients.
    if self.sidebar then raiseFrame(self.sidebar, frame, 2) end
    if self.content then raiseFrame(self.content, frame, 2) end
    if self.header then raiseFrame(self.header, frame, 8) end
    for _, page in pairs(self.pages or {}) do
        raiseFrame(page, self.content or frame, 6)
        if page.canvas then raiseFrame(page.canvas, page, 2) end
        if page.ScrollBar then raiseFrame(page.ScrollBar, page, 4) end
    end
    self:RestorePageVisibility()
end

function Settings:Refresh()
    ensureTables()
    self:KeepOnTop()
    if UI.SyncGuildTheme then UI:SyncGuildTheme() end
    for _, control in ipairs(self.refreshables or {}) do if control.Refresh then control:Refresh() end end
    if self.frame then
        local c = CC.db.colors
        backdrop(self.frame, c.panel[1], c.panel[2], c.panel[3], 0.99, c.border[1], c.border[2], c.border[3], 1)
        backdrop(self.content, c.panelSoft[1], c.panelSoft[2], c.panelSoft[3], 1, c.border[1], c.border[2], c.border[3], 1)
        backdrop(self.sidebar, c.panel[1], c.panel[2], c.panel[3], 0.98, c.border[1], c.border[2], c.border[3], 1)
        self:RestorePageVisibility()
        if self.status then
            local profile = CC.db.ui and CC.db.ui.qualityProfile or "BALANCED"
            self.status:SetText("Build " .. tostring(CC.version or "") .. "  ·  schema " .. tostring(CC.db.version or "?") .. "  ·  profile " .. tostring(profile))
        end
        self:SetPage(self.activePage or "GENERAL")
    end
end

function Settings:Build()
    if self.frame then return end
    ensureTables()
    self.refreshables, self.layoutControls, self.pages, self.tabs = {}, {}, {}, {}
    self.sidebarWidth = 132

    local screenWidth = UIParent.GetWidth and UIParent:GetWidth() or 1920
    local screenHeight = UIParent.GetHeight and UIParent:GetHeight() or 1080
    local savedSize = CC.db.sizes and CC.db.sizes.settings or nil
    local requestedWidth = savedSize and tonumber(savedSize.width) or 740
    local requestedHeight = savedSize and tonumber(savedSize.height) or 600
    local maximumWidth = max(420, screenWidth - 28)
    local maximumHeight = max(350, screenHeight - 28)
    local minimumWidth = min(560, maximumWidth)
    local minimumHeight = min(420, maximumHeight)
    local frameWidth = max(minimumWidth, min(requestedWidth, min(900, maximumWidth)))
    local frameHeight = max(minimumHeight, min(requestedHeight, min(760, maximumHeight)))
    CC.db.sizes.settings = { width = frameWidth, height = frameHeight }

    local frame = CreateFrame("Frame", "CreshChatSettingsFrame", UIParent, templateName())
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame.creshAlwaysOnTop = true
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(SETTINGS_FRAME_LEVEL)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame.creshClassicChrome = true
    if frame.SetResizable then frame:SetResizable(true) end
    if frame.SetResizeBounds then
        frame:SetResizeBounds(minimumWidth, minimumHeight, max(minimumWidth, min(900, screenWidth - 10)), max(minimumHeight, min(760, screenHeight - 10)))
    end
    backdrop(frame, 0.055, 0.067, 0.09, 0.99, 0.18, 0.21, 0.28, 1)
    frame:Hide()
    frame:SetScript("OnHide", function()
        Settings:CloseDropdown()
        if UI.CancelThemePreview and UI.IsThemePreviewActive and UI:IsThemePreviewActive() then UI:CancelThemePreview(true) end
        Settings.themePreviewSelection = CC.db and CC.db.ui and CC.db.ui.themePreset or "CRESH_MINIMAL"
    end)
    frame:SetScript("OnShow", function()
        Settings:Relayout()
        Settings:KeepOnTop()
    end)
    self.frame = frame
    if UI.InstallWindowFocus then UI:InstallWindowFocus(frame) end

    local header = CreateFrame("Frame", nil, frame)
    self.header = header
    raiseFrame(header, frame, 8)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    header:SetHeight(40)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if UI.FocusWindow then UI:FocusWindow(frame) end
        if CC.db.ui.shiftResize ~= false and IsShiftKeyDown and IsShiftKeyDown() and frame.StartSizing then frame:StartSizing("BOTTOMRIGHT")
        else frame:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing(); Settings:Relayout()
        CC.db.sizes.settings = { width = frame:GetWidth(), height = frame:GetHeight() }
    end)

    local title = font(header, 15, "LEFT")
    title:SetPoint("LEFT", header, "LEFT", 13, 0)
    title:SetText("CreshChat Settings")
    local compact = font(header, 9, "LEFT")
    compact:SetPoint("LEFT", title, "RIGHT", 9, 0)
    compact:SetTextColor(0.52, 0.65, 0.82, 1)
    compact:SetText("COMPACT CONTROL CENTRE")
    self.compactLabel = compact
    local close = button(header, "X", 28, 27, function() frame:Hide() end)
    close:SetPoint("RIGHT", header, "RIGHT", -7, 0)

    local sidebar = CreateFrame("Frame", nil, frame, templateName())
    raiseFrame(sidebar, frame, 2)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -44)
    sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 27)
    backdrop(sidebar, 0.045, 0.055, 0.075, 0.98, 0.13, 0.16, 0.21, 1)
    self.sidebar = sidebar

    local content = CreateFrame("Frame", nil, frame, templateName())
    raiseFrame(content, frame, 2)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 27)
    backdrop(content, 0.078, 0.090, 0.118, 1, 0.13, 0.16, 0.21, 1)
    self.content = content
    self.pageWidth = max(340, frameWidth - self.sidebarWidth - 54)

    local categories = {
        { "GENERAL", "General" }, { "MODULES", "Modules" }, { "CONSOLE", "Console" }, { "DOCK", "C Dock" }, { "WINDOWS", "Windows" },
        { "ALERTS", "Notifications" }, { "THEMES", "Themes" },
        { "GUILD", "Guild" }, { "CHANNELS", "Channels" }, { "PROFILES", "Profiles" }, { "ADVANCED", "Advanced" },
    }
    local previous
    local categoryHeight = #categories > 9 and 27 or 29
    local categoryGap = #categories > 9 and 3 or 5
    for index, item in ipairs(categories) do
        local tab = button(sidebar, item[2], self.sidebarWidth - 12, categoryHeight, function() Settings:SetPage(item[1]) end)
        if previous then tab:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -categoryGap)
        else tab:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, -7) end
        previous = tab
        self.tabs[item[1]] = tab
        self:CreatePage(item[1])
    end

    self:BuildGeneral(self.pages.GENERAL)
    self:BuildModules(self.pages.MODULES)
    self:BuildConsole(self.pages.CONSOLE)
    self:BuildDock(self.pages.DOCK)
    self:BuildWindows(self.pages.WINDOWS)
    self:BuildAlerts(self.pages.ALERTS)
    self:BuildThemes(self.pages.THEMES)
    self:BuildGuild(self.pages.GUILD)
    self:BuildChannels(self.pages.CHANNELS)
    self:BuildProfiles(self.pages.PROFILES)
    self:BuildAdvanced(self.pages.ADVANCED)

    local status = font(frame, 9, "LEFT")
    status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 11, 7)
    status:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    status:SetTextColor(0.50, 0.58, 0.68, 1)
    self.status = status

    frame:SetScript("OnSizeChanged", function()
        Settings:Relayout()
    end)
    self:Relayout()
    self:SetPage("GENERAL")
    self:Refresh()
end

function UI:OpenSettings()
    Settings:Build()
    if not (UI.IsThemePreviewActive and UI:IsThemePreviewActive()) then
        Settings.themePreviewSelection = CC.db and CC.db.ui and CC.db.ui.themePreset or "CRESH_MINIMAL"
    end
    Settings:Refresh()
    if Settings.frame:IsShown() then Settings.frame:Hide()
    else
        Settings:Relayout()
        if UI.ApplySafeFrameScale then UI:ApplySafeFrameScale(Settings.frame, (CC.db.ui and CC.db.ui.scale) or 1, 22) end
        if UI.ShowAnimated then UI:ShowAnimated(Settings.frame, "POP") else Settings.frame:Show() end
        Settings:KeepOnTop()
        if UI.FocusWindow then UI:FocusWindow(Settings.frame) end
    end
end
