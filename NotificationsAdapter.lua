local _, CC = ...
if not CC or not CC.UI or not CC.Notifications then return end

-- Routes CreshChat's existing UI toast functions into the new Notifications
-- card system when the "notifications" feature flag is enabled.  When the flag
-- is OFF every wrapper falls through to the original function unchanged, so the
-- old toast system continues to work exactly as before.
--
-- Intercept points:
--   UI:ShowToast          chat messages (WHISPER / GUILD / QUEST / GENERAL)
--   UI:ShowSlideToast     presence, battle-pass, game rewards, and misc slide cards
--   UI:ShowSecondaryToast system messages and secondary-slot cards
--   UI:ShowPartyInvite    actionable party-invite card with ACCEPT / DECLINE
--   UI:CancelPartyInviteToasts  dismiss active invite cards when invite resolves
--
-- Area-discovery coalescing (ShowSecondaryToast + ShowSlideToast):
--   WoW fires "Discovered X: N XP" (CHAT_MSG_SYSTEM) and "Discovered: X"
--   (UI_INFO_MESSAGE) after ZONE_CHANGED_NEW_AREA, which triggers Progression's
--   ShowGameToast "New Area Discovered".  We suppress the two WoW cards and
--   append the XP to the Progression card once it arrives (via C_Timer.After).

local UI            = CC.UI
local Notifications = CC.Notifications

local function featureOn()
    return CC.IsFeatureEnabled
        and CC:IsFeatureEnabled("notifications")
        and CC:IsFeatureEnabled("unifiedNotificationCards")
end

-- kind / notifKind → registered CRESHCHAT category
local KIND_CAT = {
    FRIEND        = "FRIEND",
    BATTLEPASS    = "GAME",
    DUNGEONPASS   = "GAME",
    GAME          = "GAME",
    WHISPER       = "WHISPER",
    BN_WHISPER    = "WHISPER",
    GUILD         = "GUILD",
    OFFICER       = "GUILD",
    PARTY_MESSAGE = "PARTY_MESSAGE",
    PARTY_LEADER  = "PARTY_MESSAGE",
    GENERAL       = "GENERAL",
    SYSTEM        = "SYSTEM",
    VOICE         = "VOICE",
    QUEST         = "QUEST",
}

-- default display priority per category
local CAT_PRI = {
    WHISPER       = "HIGH",
    GUILD         = "NORMAL",
    PARTY_MESSAGE = "HIGH",
    GENERAL       = "NORMAL",
    FRIEND        = "LOW",
    GAME          = "LOW",
    SYSTEM        = "NORMAL",
    VOICE         = "NORMAL",
    QUEST         = "HIGH",
    PARTY_INVITE  = "CRITICAL",
}

-- ----------------------------------------------------------------
-- Area-discovery helpers
-- WoW fires two system messages for every area/zone discovery:
--   CHAT_MSG_SYSTEM  → "Discovered The Stonefield Farm: 52 experience gained"
--   UI_INFO_MESSAGE  → "Discovered: The Stonefield Farm"
-- Both are suppressed when the notifications feature is ON; we store the XP
-- so the richer Progression card can absorb it.
-- ----------------------------------------------------------------

local function extractDiscoveryXP(text)
    -- "Discovered <Area>: N experience gained"
    local xp = string.match(tostring(text), "^Discovered .+: (%d+) experience gained$")
    return tonumber(xp)
end

local function isRedundantDiscovery(text)
    -- "Discovered: <Area>" (the UI_INFO_MESSAGE variant)
    return string.match(tostring(text), "^Discovered: ") ~= nil
end

local DISCOVERY_TITLES = {
    ["New Area Discovered"] = true,
    ["New Zone Discovered"] = true,
    ["Dungeon Cleared"]     = true,
}

-- ----------------------------------------------------------------
-- Suite source routing  (CreshGames + CreshCollect)
-- ShowSlideToast calls whose coalesce key matches a known prefix belong
-- to CRESHGAMES or CRESHCOLLECT rather than CRESHCHAT.  If the owning
-- addon is not loaded/registered, the notification falls back to
-- CRESHCHAT/GAME so it is never silently dropped.
-- ----------------------------------------------------------------

local function suiteSourceFromKey(keyStr)
    local gSrc, gCat
    -- CreshGames keys
    if string.match(keyStr, "^TETRIS:PASS") or string.match(keyStr, "^TETRIS:CLAIMALL") then
        gSrc, gCat = "CRESHGAMES", "BATTLE_PASS"
    elseif string.match(keyStr, "^TETRIS:") then
        gSrc, gCat = "CRESHGAMES", "REWARD"
    elseif string.match(keyStr, "^BP:") then
        gSrc, gCat = "CRESHGAMES", "BATTLE_PASS"
    elseif string.match(keyStr, "^DUNGEONCRATE:") then
        gSrc, gCat = "CRESHGAMES", "REWARD"
    elseif string.match(keyStr, "^DUNGEONBOSS:") then
        gSrc, gCat = "CRESHGAMES", "GAME_RESULT"
    -- CreshCollect keys
    elseif string.match(keyStr, "^ACHIEVEMENT:") or string.match(keyStr, "^DD_ACH:") then
        gSrc, gCat = "CRESHCOLLECT", "ACHIEVEMENT"
    end
    if not gSrc then return nil end
    -- Graceful fallback when the owning addon is not loaded
    if not Notifications:IsSourceEnabled(gSrc) then
        return "CRESHCHAT", "GAME"
    end
    return gSrc, gCat
end

-- ----------------------------------------------------------------
-- UI:ShowSlideToast  (presence, battle-pass, game, dungeon rewards)
-- Parameters: title, message, status, key, playerName, kind, target
-- ----------------------------------------------------------------

local _origSlide = UI.ShowSlideToast
function UI:ShowSlideToast(title, message, status, key, playerName, kind, target)
    if featureOn() then
        local k        = string.upper(tostring(kind   or "SYSTEM"))
        local ttl      = tostring(title   or "")
        local keyStr   = tostring(key or "")
        local category = KIND_CAT[k] or k

        -- Re-route game-owned toasts to CRESHGAMES categories
        local gSrc, gCat = suiteSourceFromKey(keyStr)
        if gSrc then
            if Notifications:IsCategoryEnabled(gSrc, gCat) then
                Notifications:Push({
                    sourceAddon = gSrc,
                    category    = gCat,
                    priority    = "LOW",
                    status      = status or k,
                    title       = ttl,
                    detail      = tostring(message or ""),
                    coalesceKey = keyStr ~= "" and keyStr or (gCat .. ":" .. ttl),
                })
            end
            return
        end

        if CC.IsNotificationEnabled and CC:IsNotificationEnabled(category) then
            local detail     = tostring(message or "")
            local coalesceKey = tostring(key or (category .. ":" .. ttl))

            -- For discovery/dungeon cards: combine with pending WoW XP if
            -- already available, or schedule a short look-ahead.
            if category == "GAME" and DISCOVERY_TITLES[ttl] then
                local pending = CC.state._pendingAreaXP
                if pending and (GetTime() - pending.time) < 3 then
                    CC.state._pendingAreaXP = nil
                    detail = detail .. " · " .. pending.xp .. " WoW XP"
                elseif C_Timer and C_Timer.After then
                    -- XP hasn't arrived yet; check once after 0.4 s and coalesce
                    local capturedKey    = coalesceKey
                    local capturedDetail = detail
                    local capturedStatus = status or k
                    C_Timer.After(0.40, function()
                        local p = CC.state._pendingAreaXP
                        if p and (GetTime() - p.time) < 3 then
                            CC.state._pendingAreaXP = nil
                            Notifications:Push({
                                sourceAddon = "CRESHCHAT",
                                category    = category,
                                priority    = CAT_PRI[category] or "NORMAL",
                                status      = capturedStatus,
                                title       = ttl,
                                detail      = capturedDetail .. " · " .. p.xp .. " WoW XP",
                                coalesceKey = capturedKey,
                            })
                        end
                    end)
                end
            end

            local evt = {
                sourceAddon = "CRESHCHAT",
                category    = category,
                priority    = CAT_PRI[category] or "NORMAL",
                status      = status or k,
                title       = ttl,
                detail      = detail,
                coalesceKey = coalesceKey,
            }
            if k == "FRIEND" and playerName and playerName ~= "" then
                local cached = CC.GetCachedPlayerInfo
                               and CC:GetCachedPlayerInfo(tostring(playerName)) or nil
                if cached then evt.classFile = cached.classFile end
            end
            Notifications:Push(evt)
        end
        return
    end
    return _origSlide(self, title, message, status, key, playerName, kind, target)
end

-- ----------------------------------------------------------------
-- UI:ShowSecondaryToast  (system messages and secondary-slot cards)
-- Parameters: title, message, status, key, playerName, kind
-- ----------------------------------------------------------------

local _origSecondary = UI.ShowSecondaryToast
function UI:ShowSecondaryToast(title, message, status, key, playerName, kind)
    if featureOn() then
        local k        = string.upper(tostring(kind or "SYSTEM"))
        local category = KIND_CAT[k] or k
        local msg      = tostring(message or "")

        -- Suppress WoW area-discovery duplicates and store XP for coalescing.
        local xp = extractDiscoveryXP(msg)
        if xp then
            CC.state._pendingAreaXP = { xp = xp, time = GetTime() }
            return
        end
        if isRedundantDiscovery(msg) then
            return
        end

        if CC.IsNotificationEnabled and CC:IsNotificationEnabled(category) then
            Notifications:Push({
                sourceAddon = "CRESHCHAT",
                category    = category,
                priority    = CAT_PRI[category] or "NORMAL",
                status      = status or k,
                title       = tostring(title or ""),
                detail      = msg,
                coalesceKey = tostring(key or (category .. ":" .. tostring(title))),
            })
        end
        return
    end
    return _origSecondary(self, title, message, status, key, playerName, kind)
end

-- ----------------------------------------------------------------
-- UI:ShowToast  (chat: WHISPER / GUILD / QUEST / GENERAL)
-- Parameters: channel, target, message
--   message = { text, sender, guid, timestamp, incoming, ... }
-- ----------------------------------------------------------------

local _origToast = UI.ShowToast
function UI:ShowToast(channel, target, message)
    if featureOn() then
        local notifKind = self.GetMessageNotificationKind
                          and self:GetMessageNotificationKind(channel, message)
                          or  string.upper(tostring(channel or "GENERAL"))
        if CC.IsNotificationEnabled and CC:IsNotificationEnabled(notifKind) then
            local category = KIND_CAT[notifKind] or notifKind
            local sender   = message and message.sender or target or "Unknown"
            local text     = type(message) == "table" and tostring(message.text or "") or ""
            local title
            if notifKind == "WHISPER" or notifKind == "BN_WHISPER" then
                title = CC.GetWhisperDisplayName
                        and CC:GetWhisperDisplayName(target)
                        or  CC:ShortName(target or "")
            else
                title = CC:ShortName(sender)
            end
            local guid   = message and message.guid or nil
            local cached = CC.GetCachedPlayerInfo
                           and CC:GetCachedPlayerInfo(tostring(sender), guid) or nil
            local replyTo = tostring(target or sender or "")
            local replyFn
            if (notifKind == "WHISPER" or notifKind == "BN_WHISPER") and replyTo ~= "" then
                replyFn = function(card)
                    Notifications:DismissCard(card)
                    if CC.EnsureWhisperConversation and CC.UI and CC.UI.OpenChannel then
                        local conv = CC:EnsureWhisperConversation(replyTo)
                        if conv then CC.UI:OpenChannel("WHISPER", conv) end
                    end
                end
            end
            Notifications:Push({
                sourceAddon = "CRESHCHAT",
                category    = category,
                priority    = CAT_PRI[category] or "NORMAL",
                status      = notifKind,
                title       = title,
                detail      = text,
                coalesceKey = category .. ":" .. tostring(target or sender),
                classFile   = cached and cached.classFile or nil,
                actions     = replyFn and { reply = replyFn } or nil,
            })
        end
        return
    end
    return _origToast(self, channel, target, message)
end

-- ----------------------------------------------------------------
-- UI:ShowPartyInvite  (actionable card with ACCEPT / DECLINE)
-- Parameters: inviter, isTest
-- ----------------------------------------------------------------

local _origPartyInvite = UI.ShowPartyInvite
function UI:ShowPartyInvite(inviter, isTest)
    if featureOn() then
        if isTest or (CC.IsNotificationEnabled and CC:IsNotificationEnabled("PARTY_INVITE")) then
            local shortName = CC:ShortName(inviter or "Unknown")

            local function doAccept(card)
                Notifications:DismissCard(card)
                if isTest then
                    if CC.UI.ShowSystemToast then CC.UI:ShowSystemToast("Party invite accepted", "Test invitation from " .. shortName, "SUCCESS") end
                    return
                end
                CC.state.pendingPartyInviter = inviter
                CC.state.partyInvitePending  = true
                local ok, err
                if CC.AcceptPendingPartyInvite then ok, err = CC:AcceptPendingPartyInvite()
                else ok, err = false, "The party accept helper is unavailable." end
                if ok then
                    if CC.UI.ShowSystemToast then CC.UI:ShowSystemToast("Accepting party invite", "Joining " .. shortName .. "'s party", "SUCCESS") end
                else
                    if CC.UI.ShowSystemToast then CC.UI:ShowSystemToast("Party invite failed", tostring(err or "The client did not accept the invitation."), "ERROR") end
                end
            end

            local function doDecline(card)
                Notifications:DismissCard(card)
                if isTest then
                    if CC.UI.ShowSystemToast then CC.UI:ShowSystemToast("Party invite declined", "Test invitation from " .. shortName, "INFO") end
                    return
                end
                local ok, err
                if CC.DeclinePendingPartyInvite then ok, err = CC:DeclinePendingPartyInvite()
                else ok, err = false, "The party decline helper is unavailable." end
                if ok then
                    CC.state.partyInvitePending    = false
                    CC.state.pendingPartyInviter   = nil
                    CC.state.partyInviteAction     = nil
                    CC.state.partyInviteAcceptedAt = nil
                    if CC.FinalizeBlizzardPartyInvitePopups then CC:FinalizeBlizzardPartyInvitePopups() end
                    if CC.UI.RefreshLauncherNotification   then CC.UI:RefreshLauncherNotification() end
                    if CC.UI.ShowSystemToast               then CC.UI:ShowSystemToast("Party invite declined", "Invitation from " .. shortName, "INFO") end
                else
                    if CC.UI.ShowSystemToast then CC.UI:ShowSystemToast("Party decline failed", tostring(err or "The client did not decline the invitation."), "ERROR") end
                end
            end

            Notifications:Push({
                sourceAddon  = "CRESHCHAT",
                category     = "PARTY_INVITE",
                priority     = "CRITICAL",
                destination  = "ACTIONABLE",
                status       = "PARTY",
                title        = shortName,
                detail       = "invited you to join a party.",
                duration     = isTest and 10 or 30,
                coalesceKey  = "PARTY_INVITE:" .. tostring(inviter or ""),
                actions      = {
                    accept       = doAccept,
                    acceptLabel  = "ACCEPT",
                    decline      = doDecline,
                    declineLabel = "DECLINE",
                },
            })
        end
        return
    end
    return _origPartyInvite(self, inviter, isTest)
end

-- ----------------------------------------------------------------
-- UI:CancelPartyInviteToasts
-- Dismisses old-system party toasts AND new-system party invite cards.
-- ----------------------------------------------------------------

local _origCancelParty = UI.CancelPartyInviteToasts
function UI:CancelPartyInviteToasts()
    if featureOn() then
        for _, c in ipairs(Notifications._activeActionCards or {}) do
            if c._category == "PARTY_INVITE" and not c._exiting then
                Notifications:DismissCard(c)
            end
        end
    end
    return _origCancelParty(self)
end
