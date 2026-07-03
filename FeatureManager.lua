local _, CC = ...
if not CC then return end

-- ── CreshChat Feature Manager ─────────────────────────────────────────────────
-- Provides a named feature flag system that lets players disable major subsystems
-- while keeping the addon loaded. Modules check CC:IsFeatureEnabled(key) before
-- doing work, making them dormant rather than removed.
--
-- All features default to true so upgrading players see no change in behaviour.
--
-- Feature keys:
--   chat             CreshChat message capture, console, composer, Blizzard redirects
--   games            Games hub, solo games, Dungeon Dwellers, game audio
--   multiplayerGames Addon-message game protocol and invites
--   gameProgression  Game XP, records, Cresh Coins, game achievements
--   battlePass       Battle Pass rewards track and level progression
--   worldProgression Zone, exploration, dungeon, profession, class achievements
--   combatTracking   COMBAT_LOG_EVENT_UNFILTERED stat collection (CombatTracker.lua)
--   questCapture     Quest dialogue capture from NPC gossip / quest windows
--   friendsPresence  Online/offline monitoring and presence notification cards
--   voice            CreshChat voice call system
--   notifications    Notification card (toast) system

CC.defaultFeatures = {
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
}

-- When enabling X, these must also be enabled.
CC.featureDependencies = {
    battlePass       = { "gameProgression" },
    multiplayerGames = { "games" },
    gameProgression  = { "games" },
    voice            = { "chat" },
}

-- When disabling X, these are also disabled.
CC.featureDependents = {
    games        = { "battlePass", "multiplayerGames", "gameProgression" },
    gameProgression = { "battlePass" },
    chat         = { "voice" },
}

-- Named presets.
CC.featurePresets = {
    full = {
        chat=true,  games=true,  multiplayerGames=true,
        gameProgression=true,  battlePass=true,
        worldProgression=true, combatTracking=true,
        questCapture=true,  friendsPresence=true,
        voice=true,  notifications=true,
    },
    games = {
        chat=false, games=true,  multiplayerGames=true,
        gameProgression=true,  battlePass=true,
        worldProgression=false, combatTracking=false,
        questCapture=false, friendsPresence=false,
        voice=false, notifications=false,
    },
    chat = {
        chat=true,  games=false, multiplayerGames=false,
        gameProgression=false, battlePass=false,
        worldProgression=false, combatTracking=true,
        questCapture=true,  friendsPresence=true,
        voice=true,  notifications=true,
    },
    minimal = {
        chat=true,  games=false, multiplayerGames=false,
        gameProgression=false, battlePass=false,
        worldProgression=false, combatTracking=false,
        questCapture=false, friendsPresence=false,
        voice=false, notifications=false,
    },
}

-- Human-readable strings used by the Settings UI.
CC.featureDisplayNames = {
    chat             = "Chat and Console",
    games            = "Games",
    multiplayerGames = "Multiplayer Games",
    gameProgression  = "Game Progression",
    battlePass       = "Battle Pass",
    worldProgression = "World Progression",
    combatTracking   = "Combat Tracking",
    questCapture     = "Quest Capture",
    friendsPresence  = "Friends and Presence",
    voice            = "Voice Calls",
    notifications            = "Notifications",
    unifiedNotificationCards = "Unified Notification Cards",
}

CC.featureDescriptions = {
    chat             = "CreshChat message capture, console, quick composer and Blizzard chat redirects. Disable to keep Blizzard chat fully intact.",
    games            = "Games hub, solo games (Frogger, Tetris, Chess, card games), Dungeon Dwellers and game audio.",
    multiplayerGames = "Addon-message game protocol for multiplayer invites and gameplay. Requires Games.",
    gameProgression  = "Game XP, play records, Cresh Coins and game-specific achievements. Requires Games.",
    battlePass       = "Battle Pass level progression and reward track. Requires Game Progression.",
    worldProgression = "Exploration steps, zone discovery, dungeon tracking, profession scanning and class achievements.",
    combatTracking   = "Collects damage, healing and kill statistics from COMBAT_LOG_EVENT_UNFILTERED for achievement goals.",
    questCapture     = "Captures NPC gossip and quest dialogue into the Quest tab.",
    friendsPresence  = "Monitors friend online/offline state and shows presence notification cards.",
    voice            = "CreshChat voice call system. Requires Chat.",
    notifications            = "Notification cards (toasts) for whispers, guild, quests, party invites and system events.",
    unifiedNotificationCards = "Use the new unified card renderer instead of the legacy toast system. Requires Notifications to be enabled. Off by default for a controlled rollout.",
}

-- Display order for the settings page.
CC.featureOrder = {
    "chat", "games", "multiplayerGames", "gameProgression", "battlePass",
    "worldProgression", "combatTracking", "questCapture", "friendsPresence",
    "voice", "notifications",
}

-- ── Core API ──────────────────────────────────────────────────────────────────

function CC:EnsureFeatures()
    if not self.db then return end
    if type(self.db.features) ~= "table" then
        self.db.features = {}
    end
    for key, default in pairs(self.defaultFeatures) do
        if self.db.features[key] == nil then
            self.db.features[key] = default
        end
    end
end

-- Returns true when the feature is active.
-- Defaults to true when CC.db is not yet loaded (startup safety).
function CC:IsFeatureEnabled(key)
    if not self.db or type(self.db.features) ~= "table" then return true end
    local value = self.db.features[key]
    return value ~= false
end

-- Enable or disable a feature with automatic dependency cascades.
-- skipCascade is used internally to prevent recursion.
function CC:SetFeatureEnabled(key, enabled, skipCascade)
    if not self.db then return false end
    self:EnsureFeatures()
    enabled = enabled == true
    self.db.features[key] = enabled
    if not skipCascade then
        if enabled then
            -- Enabling X: also enable anything X needs.
            for _, dep in ipairs(self.featureDependencies[key] or {}) do
                if self.db.features[dep] ~= true then
                    self:SetFeatureEnabled(dep, true, false)
                end
            end
        else
            -- Disabling X: also disable anything that requires X.
            for _, dep in ipairs(self.featureDependents[key] or {}) do
                if self.db.features[dep] ~= false then
                    self:SetFeatureEnabled(dep, false, false)
                end
            end
        end
    end
    self.db.featurePreset = nil
    return true
end

-- Apply a named preset.  Returns false when the name is unknown.
function CC:ApplyFeaturePreset(presetName)
    if not self.db then return false end
    local key = string.lower(tostring(presetName or ""))
    local preset = self.featurePresets[key]
    if not preset then return false end
    self:EnsureFeatures()
    for k, v in pairs(preset) do
        self.db.features[k] = v
    end
    self.db.featurePreset = key
    return true
end

-- Returns the last applied preset name ("full", "games", "chat", "minimal")
-- or "custom" if toggles were changed individually after the last preset.
function CC:GetFeaturePreset()
    if not self.db then return "custom" end
    return self.db.featurePreset or "custom"
end

function CC:GetFeatureDependencies(key)
    return self.featureDependencies[key] or {}
end

-- Convenience: returns a one-line status string for /cc modules status.
function CC:GetFeatureStatusLine()
    if not self.db or type(self.db.features) ~= "table" then
        return "Feature system not loaded."
    end
    local preset = self:GetFeaturePreset()
    local enabled, disabled = {}, {}
    for _, key in ipairs(self.featureOrder) do
        if self:IsFeatureEnabled(key) then
            enabled[#enabled + 1] = self.featureDisplayNames[key] or key
        else
            disabled[#disabled + 1] = self.featureDisplayNames[key] or key
        end
    end
    local lines = { "Preset: " .. string.upper(preset) }
    if #enabled > 0 then
        lines[#lines + 1] = "Enabled: " .. table.concat(enabled, ", ")
    end
    if #disabled > 0 then
        lines[#lines + 1] = "Disabled: " .. table.concat(disabled, ", ")
    end
    return lines
end
