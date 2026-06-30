local _, CC = ...
if not CC then return end

-- ── Module ────────────────────────────────────────────────────────────────────
-- Tracks player combat statistics from COMBAT_LOG_EVENT_UNFILTERED and wires
-- them to the WoW achievement catalog (ACH_WOW_DAMAGE_DEALT_*, etc.).
--
-- Attribution rules
--   Outgoing damage/healing : sourceGUID == playerGUID only.
--   Incoming damage         : destGUID   == playerGUID only.
--   Pets, guardians, party and raid members have distinct GUIDs and are never
--   counted unless they happen to deal damage *to* the player (incoming).
--   Dungeon Dwellers and Dungeon Crawler simulate combat inside the UI; they
--   never write COMBAT_LOG_EVENT_UNFILTERED events and are excluded naturally.
--   Environmental damage (fall, drowning, fire) is tracked as incoming damage
--   when the destination is the player; there is no source GUID.
--
-- Subevents handled
--   SWING_DAMAGE, SPELL_DAMAGE, SPELL_PERIODIC_DAMAGE, RANGE_DAMAGE
--   ENVIRONMENTAL_DAMAGE
--   SPELL_HEAL, SPELL_PERIODIC_HEAL
--
-- Stats stored in CC.db.gameProgression.achievements.stats:
--   WOW_DAMAGE_DEALT  WOW_DAMAGE_TAKEN  WOW_BEST_HIT
--   WOW_HEALING       WOW_BEST_HEAL
--   WOW_CRITS         WOW_CRIT_HEALS
--
-- All keys match Achievements.lua stat names so the GetStat() fallback
-- (save.stats[stat]) reads them without explicit handlers.

local CombatTracker = { version = CC.version }
CC.CombatTracker = CombatTracker
if CC.RegisterModule then CC:RegisterModule("CombatTracker", CombatTracker) end

local floor, max = math.floor, math.max

-- ── Upvalue cache (refreshed on each PLAYER_LOGIN / PLAYER_ENTERING_WORLD) ──
-- Using upvalues avoids per-event global lookups and table traversals.

local playerGUID   = nil   -- set at login, never nil after that
local statsRef     = nil   -- account-aggregate save.stats (all characters combined)
local charCombatRef = nil  -- per-character profile.characterCombat (current char only)
local dirty        = false -- any stat changed since last EvaluateAll?
local lastEval     = 0     -- GetTime() timestamp of last EvaluateAll call
local EVAL_SECS    = 30    -- minimum seconds between mid-combat evaluations

-- Check for TBC-compatible combat log API once at load time.
local CombatLogGet
do
    local ok, fn = pcall(function() return _G.CombatLogGetCurrentEventInfo end)
    CombatLogGet = (ok and type(fn) == "function") and fn or nil
end

-- ── Safe amount helper ────────────────────────────────────────────────────────
-- Returns the integer value of v if v is a positive number, otherwise 0.
-- Guards against nil, false, NaN-like strings, and negative amounts.

local function safeAmt(v)
    local n = tonumber(v)
    return (n and n > 0) and floor(n) or 0
end

-- ── Throttled evaluation ──────────────────────────────────────────────────────

local function tryEval(force)
    if not dirty or not statsRef then return end
    local t = GetTime and GetTime() or 0
    if not force and (t - lastEval) < EVAL_SECS then return end
    dirty    = false
    lastEval = t
    if CC.Achievements and CC.Achievements.EvaluateAll then
        CC.Achievements:EvaluateAll(true)  -- silent=true; no toast spam during combat
    end
end

-- ── Combat log handler ────────────────────────────────────────────────────────
-- Called for every COMBAT_LOG_EVENT_UNFILTERED.
-- Hot path: no table allocations, no string operations, no global lookups.
--
-- TBC Anniversary argument layout from CombatLogGetCurrentEventInfo():
--   1  timestamp       2  subevent       3  hideCaster
--   4  sourceGUID      5  sourceName     6  sourceFlags    7  sourceRaidFlags
--   8  destGUID        9  destName       10 destFlags      11 destRaidFlags
--   12..N  subevent-specific suffix args (p1..p10 below)
--
-- SWING_DAMAGE suffix      : p1=amount  p2=overkill  p3=school  p4=resisted
--                            p5=blocked  p6=absorbed  p7=critical
-- SPELL_DAMAGE/PERIODIC/
-- RANGE_DAMAGE suffix      : p1=spellId  p2=spellName  p3=spellSchool
--                            p4=amount  p5=overkill  p6=school  p7=resisted
--                            p8=blocked  p9=absorbed  p10=critical
-- ENVIRONMENTAL_DAMAGE     : p1=envType  p2=amount  p3=overkill  ...
-- SPELL_HEAL/PERIODIC_HEAL : p1=spellId  p2=spellName  p3=spellSchool
--                            p4=amount  p5=overheal  p6=absorbed  p7=critical

local function onCombatLog()
    if not CC:IsFeatureEnabled("combatTracking") then return end
    if not statsRef or not playerGUID then return end

    local _, sub, _, src, _, _, _, dst, _, _, _,
          p1, p2, p3, p4, p5, p6, p7, p8, p9, p10
        = CombatLogGet()

    -- Early exit: event must involve the player as source or destination.
    local isSrc = src == playerGUID
    local isDst = dst == playerGUID
    if not isSrc and not isDst then return end

    -- c_ is the per-character table; may be nil when profile not yet ready.
    local c = charCombatRef

    if sub == "SWING_DAMAGE" then
        -- p1=amount, p7=critical
        if isSrc then
            local amt = safeAmt(p1)
            if amt > 0 then
                statsRef.WOW_DAMAGE_DEALT = statsRef.WOW_DAMAGE_DEALT + amt
                if amt > statsRef.WOW_BEST_HIT then statsRef.WOW_BEST_HIT = amt end
                if p7 then statsRef.WOW_CRITS = statsRef.WOW_CRITS + 1 end
                if c then
                    c.WOW_DAMAGE_DEALT = c.WOW_DAMAGE_DEALT + amt
                    if amt > c.WOW_BEST_HIT then c.WOW_BEST_HIT = amt end
                    if p7 then c.WOW_CRITS = c.WOW_CRITS + 1 end
                end
                dirty = true
            end
        elseif isDst then
            local amt = safeAmt(p1)
            if amt > 0 then
                statsRef.WOW_DAMAGE_TAKEN = statsRef.WOW_DAMAGE_TAKEN + amt
                if c then c.WOW_DAMAGE_TAKEN = c.WOW_DAMAGE_TAKEN + amt end
                dirty = true
            end
        end

    elseif sub == "SPELL_DAMAGE" or sub == "SPELL_PERIODIC_DAMAGE" or sub == "RANGE_DAMAGE" then
        -- p4=amount, p10=critical (spell prefix occupies p1-p3)
        if isSrc then
            local amt = safeAmt(p4)
            if amt > 0 then
                statsRef.WOW_DAMAGE_DEALT = statsRef.WOW_DAMAGE_DEALT + amt
                if amt > statsRef.WOW_BEST_HIT then statsRef.WOW_BEST_HIT = amt end
                if p10 then statsRef.WOW_CRITS = statsRef.WOW_CRITS + 1 end
                if c then
                    c.WOW_DAMAGE_DEALT = c.WOW_DAMAGE_DEALT + amt
                    if amt > c.WOW_BEST_HIT then c.WOW_BEST_HIT = amt end
                    if p10 then c.WOW_CRITS = c.WOW_CRITS + 1 end
                end
                dirty = true
            end
        elseif isDst then
            local amt = safeAmt(p4)
            if amt > 0 then
                statsRef.WOW_DAMAGE_TAKEN = statsRef.WOW_DAMAGE_TAKEN + amt
                if c then c.WOW_DAMAGE_TAKEN = c.WOW_DAMAGE_TAKEN + amt end
                dirty = true
            end
        end

    elseif sub == "ENVIRONMENTAL_DAMAGE" then
        -- p1=envType, p2=amount — source GUID is nil for environmental events
        if isDst then
            local amt = safeAmt(p2)
            if amt > 0 then
                statsRef.WOW_DAMAGE_TAKEN = statsRef.WOW_DAMAGE_TAKEN + amt
                if c then c.WOW_DAMAGE_TAKEN = c.WOW_DAMAGE_TAKEN + amt end
                dirty = true
            end
        end

    elseif sub == "SPELL_HEAL" or sub == "SPELL_PERIODIC_HEAL" then
        -- p4=amount (actual heal, excludes overheal), p7=critical
        -- Track outgoing healing only (player as caster).
        if isSrc then
            local amt = safeAmt(p4)
            if amt > 0 then
                statsRef.WOW_HEALING   = statsRef.WOW_HEALING + amt
                if amt > statsRef.WOW_BEST_HEAL then statsRef.WOW_BEST_HEAL = amt end
                if p7 then statsRef.WOW_CRIT_HEALS = statsRef.WOW_CRIT_HEALS + 1 end
                if c then
                    c.WOW_HEALING = c.WOW_HEALING + amt
                    if amt > c.WOW_BEST_HEAL then c.WOW_BEST_HEAL = amt end
                    if p7 then c.WOW_CRIT_HEALS = c.WOW_CRIT_HEALS + 1 end
                end
                dirty = true
            end
        end
    end

end

-- ── Initialisation ────────────────────────────────────────────────────────────

local function initCombatFields(s)
    if not tonumber(s.WOW_DAMAGE_DEALT)  then s.WOW_DAMAGE_DEALT  = 0 end
    if not tonumber(s.WOW_DAMAGE_TAKEN)  then s.WOW_DAMAGE_TAKEN  = 0 end
    if not tonumber(s.WOW_BEST_HIT)      then s.WOW_BEST_HIT      = 0 end
    if not tonumber(s.WOW_HEALING)       then s.WOW_HEALING        = 0 end
    if not tonumber(s.WOW_BEST_HEAL)     then s.WOW_BEST_HEAL      = 0 end
    if not tonumber(s.WOW_CRITS)         then s.WOW_CRITS          = 0 end
    if not tonumber(s.WOW_CRIT_HEALS)    then s.WOW_CRIT_HEALS     = 0 end
end

function CombatTracker:Init()
    -- Cache player GUID.
    local ok, guid = pcall(_G.UnitGUID, "player")
    playerGUID            = (ok and type(guid) == "string" and guid ~= "") and guid or nil
    CombatTracker.playerGUID = playerGUID

    -- Cache reference to the account-aggregate stats table.
    local ach = CC.Achievements and CC.Achievements:Ensure()
    if not ach or type(ach.stats) ~= "table" then statsRef = nil; charCombatRef = nil; return end
    initCombatFields(ach.stats)
    statsRef = ach.stats

    -- Cache per-character combat table from the active character profile.
    -- CC.currentProfile is set by Core.lua:ActivateCharacterProfile() before PLAYER_LOGIN.
    charCombatRef = nil
    local profile = CC.currentProfile
    if profile then
        if type(profile.characterCombat) ~= "table" then profile.characterCombat = {} end
        initCombatFields(profile.characterCombat)
        charCombatRef = profile.characterCombat
    end
end

function CombatTracker:GetStats()
    return statsRef
end

function CombatTracker:GetCharStats()
    return charCombatRef
end

-- ── Event frame ───────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
if CombatLogGet then
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        CombatTracker:Init()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Combat ended; evaluate now so achievements award outside the heat of battle.
        tryEval(true)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLog()
        -- Mid-combat throttle: evaluate at most once every EVAL_SECS seconds.
        if dirty then tryEval(false) end
    end
end)
