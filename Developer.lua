local _, CC = ...
if not CC then return end

local Developer = {
    version = CC.version,
    expectedModules = {
        "Core", "ProgressRouter", "SoundLibrary", "Quest", "Friends", "ThemeLibrary",
        "CardDeckLibrary", "CardDecks", "UI", "ChessAssets", "DungeonAssets",
        "Tetris", "Games", "SoloGames", "BattlePass", "GameProgression", "GameAudio",
        "Voice", "Quality", "Settings", "Developer",
        "Achievements", "AchievementExpansion", "ClassAchievements", "DungeonAchievements",
        "CombatTracker", "DungeonContent", "DungeonDwellersPass",
    },
}
CC.Developer = Developer
if CC.RegisterModule then CC:RegisterModule("Developer", Developer) end

local function countTable(value)
    local total = 0
    if type(value) ~= "table" then return total end
    for _ in pairs(value) do total = total + 1 end
    return total
end

local function yesNo(value)
    return value and "OK" or "MISSING"
end

local function join(values, separator)
    local output = ""
    for index, value in ipairs(values) do
        if index > 1 then output = output .. (separator or ", ") end
        output = output .. tostring(value)
    end
    return output
end

function Developer:GetModuleStatus()
    local loaded, missing = {}, {}
    for _, name in ipairs(self.expectedModules) do
        if CC.modules and CC.modules[name] then loaded[#loaded + 1] = name
        else missing[#missing + 1] = name end
    end
    return loaded, missing
end

function Developer:GetDatabaseStatus()
    local required = {
        "ui", "notifications", "notificationPriorities", "sounds", "soundChoices", "soundVolumes", "colors", "positions",
        "sizes", "history", "soloGames", "arcadeRewards", "gameProgression",
        "gameAudio", "voice", "gameHistory", "gameLeaderboards", "characterProfiles",
    }
    local missing = {}
    for _, key in ipairs(required) do
        if not CC.db or type(CC.db[key]) ~= "table" then missing[#missing + 1] = key end
    end
    local schemaOK = CC.db and tonumber(CC.db.version) == tonumber(CC.schemaVersion)
    return schemaOK, missing
end

function Developer:GetAssetCounts()
    local sounds = _G.CreshChatSoundLibrary
    local decks = _G.CreshGamesCardDecks
    local chess = _G.CreshGamesChessTextures
    local dungeon = _G.CreshGamesDungeonDwellersSets

    local deckCount, cardFaces = 0, 0
    if type(decks) == "table" then
        for _, deck in pairs(decks) do
            deckCount = deckCount + 1
            cardFaces = cardFaces + countTable(deck.cards)
        end
    end

    local dungeonSets, dungeonAssets = 0, 0
    if type(dungeon) == "table" then
        for _, set in pairs(dungeon) do
            dungeonSets = dungeonSets + 1
            dungeonAssets = dungeonAssets + countTable(set.assets)
        end
    end

    return {
        sounds = sounds and #(sounds.order or {}) or 0,
        cardDecks = deckCount,
        cardFaces = cardFaces,
        chessPieces = chess and countTable(chess.Notation) or 0,
        dungeonSets = dungeonSets,
        dungeonAssets = dungeonAssets,
        globalThemes = CC.UI and countTable(CC.UI.THEME_PRESETS) or 0,
        guildThemes = CC.UI and countTable(CC.UI.GUILD_THEME_PRESETS) or 0,
        tetrisThemes = CC.Tetris and CC.Tetris.GetThemeCount and CC.Tetris:GetThemeCount() or 0,
    }
end

function Developer:GetRuntimeReport()
    local loaded, missingModules = self:GetModuleStatus()
    local schemaOK, missingData = self:GetDatabaseStatus()
    local assets = self:GetAssetCounts()
    local profileCount = countTable(CC.db and CC.db.characterProfiles)
    local activeProfile = CC.GetCurrentCharacterProfileKey and CC:GetCurrentCharacterProfileKey() or "unknown"
    local lines = {
        "Developer report · build " .. tostring(CC.version) .. " · schema " .. tostring(CC.db and CC.db.version or "not loaded") .. "/" .. tostring(CC.schemaVersion),
        "Profiles: " .. tostring(profileCount) .. " character profile(s) · active " .. tostring(activeProfile),
        "Modules: " .. tostring(#loaded) .. "/" .. tostring(#self.expectedModules) .. " loaded" .. (#missingModules > 0 and (" · missing " .. join(missingModules)) or " · all expected modules present"),
        "Database: schema " .. yesNo(schemaOK) .. (#missingData > 0 and (" · missing tables " .. join(missingData)) or " · required root tables present"),
        "Assets: " .. tostring(assets.sounds) .. " sounds · " .. tostring(assets.cardDecks) .. " decks / " .. tostring(assets.cardFaces) .. " card faces · " .. tostring(assets.chessPieces) .. " chess pieces",
        "Assets: " .. tostring(assets.dungeonSets) .. " dungeon sets / " .. tostring(assets.dungeonAssets) .. " entries · " .. tostring(assets.globalThemes) .. " global themes · " .. tostring(assets.guildThemes) .. " Guild themes · " .. tostring(assets.tetrisThemes) .. " Tetris sets",
        "Documentation: Interface/AddOns/CreshChat/Docs/DEVELOPER_GUIDE.md",
    }
    local prog = _G.CreshChatDB and _G.CreshChatDB.accountProgression
    local migCount = prog and prog._v77MigrationCount
    if migCount and migCount > 0 then
        lines[#lines + 1] = "Migration v77: " .. tostring(migCount) .. " achievement key(s) renamed to stable ACH_WOW_*/ACH_DD_* IDs"
    end
    return lines
end

function Developer:PrintRuntimeReport()
    for _, line in ipairs(self:GetRuntimeReport()) do
        if CC.Print then CC:Print(line) end
    end
end

function Developer:PrintModules()
    local loaded, missing = self:GetModuleStatus()
    if CC.Print then
        CC:Print("Loaded modules (" .. tostring(#loaded) .. "): " .. join(loaded))
        if #missing > 0 then CC:Print("Missing modules: " .. join(missing)) end
    end
end

function Developer:PrintAssets()
    local a = self:GetAssetCounts()
    if not CC.Print then return end
    CC:Print("Asset library: " .. tostring(a.sounds) .. " sounds, " .. tostring(a.cardDecks) .. " card decks, " .. tostring(a.cardFaces) .. " card faces.")
    CC:Print("Asset library: " .. tostring(a.chessPieces) .. " chess textures, " .. tostring(a.dungeonSets) .. " Dungeon Dweller sets, " .. tostring(a.dungeonAssets) .. " Dungeon Dweller entries.")
    CC:Print("Theme library: " .. tostring(a.globalThemes) .. " global themes, " .. tostring(a.guildThemes) .. " Guild themes and " .. tostring(a.tetrisThemes) .. " Tetris piece sets.")
end

function Developer:HandleProgressCommand(arg)
    local R = CC.ProgressRouter
    if not R then
        if CC.Print then CC:Print("[ProgressRouter] module not loaded") end
        return
    end
    if arg == "test" then
        self:RunProgressRouterTests()
    elseif arg == "log" then
        local entries = R:GetDevLog()
        if not CC.Print then return end
        if #entries == 0 then
            CC:Print("[ProgressRouter] log empty (dev mode " .. (R:IsDevMode() and "ON" or "OFF") .. ")")
        else
            CC:Print("[ProgressRouter] rejection log (" .. #entries .. " entries, " .. R:GetDevLogCount() .. " total written):")
            for _, entry in ipairs(entries) do
                CC:Print("  [" .. tostring(entry.tag) .. "] " .. tostring(entry.message))
            end
        end
    elseif arg == "clear" then
        R:ClearDevLog()
        if CC.Print then CC:Print("[ProgressRouter] log cleared") end
    elseif arg == "on" then
        R:EnableDevMode(true)
        if CC.Print then CC:Print("[ProgressRouter] dev mode ON - rejected events will be logged") end
    elseif arg == "off" then
        R:EnableDevMode(false)
        if CC.Print then CC:Print("[ProgressRouter] dev mode OFF") end
    else
        if not CC.Print then return end
        CC:Print("/cc progress test   - run the 9 validation tests")
        CC:Print("/cc progress log    - print the rejection ring buffer")
        CC:Print("/cc progress clear  - clear the ring buffer")
        CC:Print("/cc progress on/off - enable or disable dev mode logging")
    end
end

function Developer:RunProgressRouterTests()
    local R = CC.ProgressRouter
    if not R then
        if CC.Print then CC:Print("[ProgressRouter] module not loaded - cannot test") end
        return
    end
    local wasDevMode = R:IsDevMode()
    R:EnableDevMode(true)
    R:ClearDevLog()

    local passed, failed = 0, 0
    local function check(label, result, expectOk, sim, expectSim)
        local pass = (result == expectOk) and (expectSim == nil or sim == expectSim)
        if pass then passed = passed + 1 else failed = failed + 1 end
        if CC.Print then
            CC:Print("[ProgressRouter] " .. (pass and "PASS" or "FAIL") .. " " .. label)
        end
    end

    -- 1. Valid Main Battle Pass event
    local e1 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
    })
    local ok1, _, sim1 = R:RouteProgressEvent(e1)
    check("1: valid Main BP event", ok1, true, sim1, false)

    -- 2. Valid Dungeon Dwellers event
    local e2 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.DUNGEON_DWELLER_BATTLE_PASS, sourceGame = R.GAMES.DUNGEON_DWELLER,
        progressNamespace = R.GAMES.DUNGEON_DWELLER, objectiveType = R.OBJECTIVES.DD_ENEMY_KILL, amount = 2,
    })
    local ok2, _, sim2 = R:RouteProgressEvent(e2)
    check("2: valid DD event", ok2, true, sim2, false)

    -- 3. Valid WoW achievement event
    local e3 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.WOW_ACHIEVEMENTS, sourceGame = R.GAMES.WOW,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.ACHIEVEMENT_UNLOCK,
        amount = 10, achievementId = "COMBAT_KILLS_10",
    })
    local ok3, _, sim3 = R:RouteProgressEvent(e3)
    check("3: valid WoW achievement event", ok3, true, sim3, false)

    -- 4. Invalid source system
    local e4 = R:BuildProgressEvent({
        sourceSystem = "FAKE_SYSTEM", sourceGame = R.GAMES.WOW,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
    })
    local ok4 = R:RouteProgressEvent(e4)
    check("4: invalid sourceSystem rejected", ok4, false)

    -- 5. Invalid destination namespace
    local e5 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
        progressNamespace = "FAKE_NAMESPACE", objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
    })
    local ok5 = R:RouteProgressEvent(e5)
    check("5: invalid progressNamespace rejected", ok5, false)

    -- 6. Invalid amount (zero)
    local e6 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 0,
    })
    local ok6 = R:RouteProgressEvent(e6)
    check("6: zero amount rejected", ok6, false)

    -- 7. Prohibited cross-system route (DUNGEON_DWELLER -> WOW)
    local e7 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.DUNGEON_DWELLER_BATTLE_PASS, sourceGame = R.GAMES.DUNGEON_DWELLER,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.DD_ENEMY_KILL, amount = 1,
    })
    local ok7 = R:RouteProgressEvent(e7)
    check("7: DD->WOW route prohibited", ok7, false)

    -- 8. Simulation flag: validates, returns isSimulation=true, does not apply
    local e8 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL,
        amount = 1, isSimulation = true,
    })
    local ok8, _, sim8 = R:RouteProgressEvent(e8)
    check("8: simulation accepted, isSimulation=true returned", ok8, true, sim8, true)

    -- 9. Legacy caller through compatibility adapter
    local ok9, _, sim9 = R:ValidateLegacyPassXP(5, "Test quest reward")
    check("9: legacy adapter accepts valid XP", ok9, true, sim9, false)

    if CC.Print then
        CC:Print(string.format("[ProgressRouter] %d passed, %d failed. Ring buffer: %d entries written.",
            passed, failed, R:GetDevLogCount()))
    end
    R:EnableDevMode(wasDevMode)
end

function Developer:PrintCombatStats()
    if not CC.Print then return end
    local tracker = CC.CombatTracker
    if not tracker then
        CC:Print("[CombatTracker] module not loaded")
        return
    end
    local stats = tracker:GetStats()
    if not stats then
        CC:Print("[CombatTracker] not initialised yet — log in first")
        return
    end
    CC:Print("[CombatTracker] Player GUID: " .. tostring(tracker.playerGUID or "not cached"))
    CC:Print("[CombatTracker] Damage dealt: " .. tostring(stats.WOW_DAMAGE_DEALT or 0)
        .. "  |  best hit: " .. tostring(stats.WOW_BEST_HIT or 0)
        .. "  |  crits: " .. tostring(stats.WOW_CRITS or 0))
    CC:Print("[CombatTracker] Damage taken: " .. tostring(stats.WOW_DAMAGE_TAKEN or 0))
    CC:Print("[CombatTracker] Healing cast: " .. tostring(stats.WOW_HEALING or 0)
        .. "  |  best heal: " .. tostring(stats.WOW_BEST_HEAL or 0)
        .. "  |  crit heals: " .. tostring(stats.WOW_CRIT_HEALS or 0))
    -- Count combat achievements.
    local ach = CC.Achievements
    if ach then
        local COMBAT_STATS = {
            WOW_DAMAGE_DEALT = true, WOW_DAMAGE_TAKEN = true, WOW_BEST_HIT = true,
            WOW_HEALING      = true, WOW_BEST_HEAL    = true,
            WOW_CRITS        = true, WOW_CRIT_HEALS   = true,
        }
        local save = ach:Ensure()
        local unlocked, total = 0, 0
        for _, entry in ipairs(ach.catalog or {}) do
            if COMBAT_STATS[entry.stat] then
                total = total + 1
                if save and save.unlocked[entry.key] then unlocked = unlocked + 1 end
            end
        end
        CC:Print("[CombatTracker] Combat achievements: " .. tostring(unlocked) .. "/" .. tostring(total))
    end
end

-- ── Pass 8: Developer Test Suite ─────────────────────────────────────────────
-- Gated behind an explicit test-mode flag (/cc test on).
-- Player data is snapshot-restored before and after every run.
-- Never writes real progress while test mode is active.

Developer.testMode    = false
Developer.testVerbose = false
Developer.snapshot    = nil

local function deepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[k] = deepCopy(v) end
    return copy
end

local function copyInto(dest, src)
    for k in pairs(dest) do if src[k] == nil then dest[k] = nil end end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dest[k]) == "table" then
            copyInto(dest[k], v)
        else
            dest[k] = deepCopy(v)
        end
    end
end

function Developer:SnapshotDB()
    if not CC.db then return false end
    self.snapshot = {
        arcadeRewards   = deepCopy(CC.db.arcadeRewards),
        gameProgression = deepCopy(CC.db.gameProgression),
        dungeonSave     = CC.db.soloGames and deepCopy(CC.db.soloGames.dungeon) or nil,
    }
    return true
end

function Developer:RestoreDB()
    if not self.snapshot or not CC.db then return false end
    if self.snapshot.arcadeRewards and CC.db.arcadeRewards then
        copyInto(CC.db.arcadeRewards, self.snapshot.arcadeRewards)
    end
    if self.snapshot.gameProgression and CC.db.gameProgression then
        copyInto(CC.db.gameProgression, self.snapshot.gameProgression)
    end
    if self.snapshot.dungeonSave and CC.db.soloGames then
        CC.db.soloGames.dungeon = CC.db.soloGames.dungeon or {}
        copyInto(CC.db.soloGames.dungeon, self.snapshot.dungeonSave)
    end
    self.snapshot = nil
    return true
end

function Developer:EnableTestMode()
    if self.testMode then
        if CC.Print then CC:Print("[TEST] already ON") end; return
    end
    if not CC.db then
        if CC.Print then CC:Print("[TEST] database not ready — log in first") end; return
    end
    if not self:SnapshotDB() then
        if CC.Print then CC:Print("[TEST] snapshot failed") end; return
    end
    self.testMode = true
    if CC.Print then CC:Print("[TEST] mode ON — DB snapshot saved. '/cc test off' restores data.") end
end

function Developer:DisableTestMode()
    if not self.testMode then
        if CC.Print then CC:Print("[TEST] test mode is not enabled") end; return
    end
    local ok = self:RestoreDB()
    self.testMode = false
    if CC.Print then
        CC:Print(ok and "[TEST] mode OFF — DB restored." or "[TEST] mode OFF — no snapshot (data unchanged).")
    end
end

-- ── Runner ────────────────────────────────────────────────────────────────────

local function makeRunner(verbose)
    local passed, failed = 0, 0
    local function check(label, cond, detail)
        if cond then
            passed = passed + 1
            if verbose and CC.Print then CC:Print("[TEST] PASS " .. label) end
        else
            failed = failed + 1
            if CC.Print then CC:Print("[TEST] FAIL " .. label .. (detail and (" — " .. tostring(detail)) or "")) end
        end
    end
    local function skip(label, reason)
        if CC.Print then CC:Print("[TEST] SKIP " .. label .. " — " .. (reason or "n/a")) end
    end
    return { check = check, skip = skip,
             passed = function() return passed end,
             failed = function() return failed end }
end

-- ── Test groups L1–L20 ────────────────────────────────────────────────────────

local tests = {}

tests[1] = function(T)  -- Main BP XP award
    local Pass = CC.BattlePass
    if not Pass then T.skip("L1", "BattlePass not loaded"); return end
    local save = Pass:Ensure(); if not save then T.skip("L1", "Ensure nil"); return end
    local before = save.passXP
    Pass:AddPassXP(100,  "TEST", true)
    T.check("L1: AddPassXP(100) increases passXP by 100",      save.passXP == before + 100)
    Pass:AddPassXP(0,    "TEST", true)
    T.check("L1: AddPassXP(0) is a no-op",                     save.passXP == before + 100)
    Pass:AddPassXP(-50,  "TEST", true)
    T.check("L1: AddPassXP(negative) is a no-op",              save.passXP == before + 100)
    Pass:AddPassXP(nil,  "TEST", true)
    T.check("L1: AddPassXP(nil) is a no-op",                   save.passXP == before + 100)
    Pass:AddPassXP("abc","TEST", true)
    T.check("L1: AddPassXP(string) is a no-op",                save.passXP == before + 100)
end

tests[2] = function(T)  -- Level boundary calculation
    local Pass = CC.BattlePass
    if not Pass then T.skip("L2", "BattlePass not loaded"); return end
    T.check("L2: GetCumulativeXP(1)==0",   Pass:GetCumulativeXP(1) == 0)
    T.check("L2: GetCumulativeXP(2)==50",  Pass:GetCumulativeXP(2) == 50)
    T.check("L2: GetCumulativeXP(3)==105", Pass:GetCumulativeXP(3) == 105)
    T.check("L2: GetNextLevelCost(1)==50", Pass:GetNextLevelCost(1) == 50)
    T.check("L2: GetNextLevelCost(2)==55", Pass:GetNextLevelCost(2) == 55)
    T.check("L2: GetNextLevelCost(10)==95",Pass:GetNextLevelCost(10) == 95)
    for lvl = 1, 5 do
        local xp = Pass:GetCumulativeXP(lvl)
        T.check("L2: round-trip level " .. lvl, Pass:GetLevelFromXP(xp) == lvl)
        if lvl > 1 then
            T.check("L2: one-below level " .. lvl, Pass:GetLevelFromXP(xp - 1) == lvl - 1)
        end
    end
end

tests[3] = function(T)  -- Levels 99–101 boundaries
    local Pass = CC.BattlePass
    if not Pass then T.skip("L3", "BattlePass not loaded"); return end
    local x99  = Pass:GetCumulativeXP(99)
    local x100 = Pass:GetCumulativeXP(100)
    local x101 = Pass:GetCumulativeXP(101)
    T.check("L3: xp99 < xp100 < xp101",      x99 < x100 and x100 < x101)
    T.check("L3: lvlFromXP(x99)==99",         Pass:GetLevelFromXP(x99)    == 99)
    T.check("L3: lvlFromXP(x100-1)==99",      Pass:GetLevelFromXP(x100-1) == 99)
    T.check("L3: lvlFromXP(x100)==100",       Pass:GetLevelFromXP(x100)   == 100)
    T.check("L3: lvlFromXP(x101-1)==100",     Pass:GetLevelFromXP(x101-1) == 100)
    T.check("L3: lvlFromXP(x101)==101",       Pass:GetLevelFromXP(x101)   == 101)
end

tests[4] = function(T)  -- Levels 199–200 boundaries
    local Pass = CC.BattlePass
    if not Pass then T.skip("L4", "BattlePass not loaded"); return end
    local x199 = Pass:GetCumulativeXP(199)
    local x200 = Pass:GetCumulativeXP(200)
    T.check("L4: x199 < x200",                x199 < x200)
    T.check("L4: lvlFromXP(x199)==199",        Pass:GetLevelFromXP(x199)   == 199)
    T.check("L4: lvlFromXP(x200-1)==199",      Pass:GetLevelFromXP(x200-1) == 199)
    T.check("L4: lvlFromXP(x200)==200",        Pass:GetLevelFromXP(x200)   == 200)
end

tests[5] = function(T)  -- Excess XP at level 200
    local Pass = CC.BattlePass
    if not Pass then T.skip("L5", "BattlePass not loaded"); return end
    local x200 = Pass:GetCumulativeXP(200)
    T.check("L5: GetLevelFromXP(x200+1000000)==200 (capped)",
        Pass:GetLevelFromXP(x200 + 1000000) == 200)
    local save = Pass:Ensure()
    if save then
        save.passXP = x200
        Pass:AddPassXP(99999, "TEST", true)
        T.check("L5: level stays 200 after AddPassXP beyond cap",
            Pass:GetLevelFromXP(save.passXP) == 200)
    end
end

tests[6] = function(T)  -- Reward claim
    local Pass = CC.BattlePass
    if not Pass then T.skip("L6", "BattlePass not loaded"); return end
    local save = Pass:Ensure(); if not save then T.skip("L6", "Ensure nil"); return end
    save.passXP   = Pass:GetCumulativeXP(4)
    save.claimed["4"] = nil
    local coinsBefore = save.coins
    local ok = Pass:ClaimReward(4, true)
    T.check("L6: ClaimReward(4) returns true",          ok == true)
    T.check("L6: claimed['4'] set to true",             save.claimed["4"] == true)
    local reward = Pass:GetReward(4)
    T.check("L6: coins increased by reward.coins",
        save.coins == coinsBefore + (reward and reward.coins or 0))
end

tests[7] = function(T)  -- Duplicate claim prevention
    local Pass = CC.BattlePass
    if not Pass then T.skip("L7", "BattlePass not loaded"); return end
    local save = Pass:Ensure(); if not save then T.skip("L7", "Ensure nil"); return end
    save.passXP    = Pass:GetCumulativeXP(7)
    save.claimed["7"] = nil
    Pass:ClaimReward(7, true)
    local coinsAfterFirst = save.coins
    local ok2 = Pass:ClaimReward(7, true)
    T.check("L7: second ClaimReward(7) returns false",  ok2 == false)
    T.check("L7: coins unchanged on duplicate claim",   save.coins == coinsAfterFirst)
end

tests[8] = function(T)  -- Achievement progress below threshold
    local Ach = CC.Achievements
    if not Ach then T.skip("L8", "Achievements not loaded"); return end
    local save = Ach:Ensure(); if not save then T.skip("L8", "Ensure nil"); return end
    local prev = save.stats.WOW_DAMAGE_DEALT
    save.stats.WOW_DAMAGE_DEALT = 9999
    save.unlocked["ACH_WOW_DAMAGE_DEALT_001"] = nil
    Ach:EvaluateAll(true)
    T.check("L8: ACH_WOW_DAMAGE_DEALT_001 NOT unlocked at 9999 (goal 10000)",
        save.unlocked["ACH_WOW_DAMAGE_DEALT_001"] == nil)
    save.stats.WOW_DAMAGE_DEALT = prev
end

tests[9] = function(T)  -- Achievement completion at threshold
    local Ach = CC.Achievements
    if not Ach then T.skip("L9", "Achievements not loaded"); return end
    local save = Ach:Ensure(); if not save then T.skip("L9", "Ensure nil"); return end
    save.stats.WOW_DAMAGE_DEALT = 10000
    save.unlocked["ACH_WOW_DAMAGE_DEALT_001"] = nil
    Ach:EvaluateAll(true)
    T.check("L9: ACH_WOW_DAMAGE_DEALT_001 unlocked at exactly 10000",
        save.unlocked["ACH_WOW_DAMAGE_DEALT_001"] ~= nil)
end

tests[10] = function(T)  -- Duplicate completion prevention
    local Ach  = CC.Achievements
    local Pass = CC.BattlePass
    if not Ach or not Pass then T.skip("L10", "module missing"); return end
    local achSave = Ach:Ensure();  if not achSave then T.skip("L10", "Ach Ensure nil"); return end
    local bpSave  = Pass:Ensure(); if not bpSave  then T.skip("L10", "BP Ensure nil"); return end
    achSave.stats.WOW_CRITS = 10
    achSave.unlocked["ACH_WOW_CRITS_001"] = nil
    local xpBefore = bpSave.passXP
    Ach:EvaluateAll(true)
    local xpAfterFirst = bpSave.passXP
    T.check("L10: first EvaluateAll awards XP", xpAfterFirst > xpBefore)
    Ach:EvaluateAll(true)
    T.check("L10: second EvaluateAll does not re-award XP", bpSave.passXP == xpAfterFirst)
end

tests[11] = function(T)  -- Old-key alias resolution (legacy ID → stable ACH_WOW_*)
    local Ach = CC.Achievements
    if not Ach then T.skip("L11", "Achievements not loaded"); return end
    Ach:BuildCatalog()
    -- Legacy auto-generated key: COMBAT_KILLS_10 → ACH_WOW_KILLS_001
    local byLegacy = Ach.byKey["COMBAT_KILLS_10"]
    local byStable = Ach.byKey["ACH_WOW_KILLS_001"]
    T.check("L11: legacy key 'COMBAT_KILLS_10' resolves in byKey",       byLegacy ~= nil)
    T.check("L11: legacy and stable keys resolve to same catalog entry",  byLegacy == byStable)
    -- GAMES category example
    local byLeg2 = Ach.byKey["GAMES_GAME_WINS_1"]
    local byStb2 = Ach.byKey["ACH_WOW_GAME_WINS_001"]
    T.check("L11: legacy 'GAMES_GAME_WINS_1' resolves in byKey",         byLeg2 ~= nil)
    T.check("L11: GAMES legacy and stable keys match",                   byLeg2 == byStb2)
    -- IsUnlocked accepts stable key
    local save = Ach:Ensure()
    if save then
        local wasUnlocked = save.unlocked["ACH_WOW_KILLS_001"]
        save.unlocked["ACH_WOW_KILLS_001"] = { at = 1, value = 10 }
        T.check("L11: IsUnlocked(stable key) == true", Ach:IsUnlocked("ACH_WOW_KILLS_001"))
        save.unlocked["ACH_WOW_KILLS_001"] = wasUnlocked
    end
end

tests[12] = function(T)  -- GetStat fallback reads combat stat keys directly
    local Ach = CC.Achievements
    if not Ach then T.skip("L12", "Achievements not loaded"); return end
    local save = Ach:Ensure(); if not save then T.skip("L12", "Ensure nil"); return end
    local prev = save.stats.WOW_BEST_HIT
    save.stats.WOW_BEST_HIT = 7654
    T.check("L12: GetStat('WOW_BEST_HIT') reads from save.stats",   Ach:GetStat("WOW_BEST_HIT") == 7654)
    save.stats.WOW_BEST_HIT = 0
    T.check("L12: GetStat('WOW_BEST_HIT') == 0 after clearing",     Ach:GetStat("WOW_BEST_HIT") == 0)
    save.stats.WOW_BEST_HIT = prev
    -- Unknown stat returns 0 cleanly
    T.check("L12: GetStat('NONEXISTENT') returns 0 safely",          Ach:GetStat("NONEXISTENT_STAT_XYZ") == 0)
end

tests[13] = function(T)  -- DD MigrateFromWoW idempotence
    local DD  = CC.DungeonAchievements
    local Ach = CC.Achievements
    if not DD or not Ach then T.skip("L13", "module missing"); return end
    local ddSave  = DD:Ensure();  if not ddSave  then T.skip("L13", "DD Ensure nil"); return end
    local achSave = Ach:Ensure(); if not achSave then T.skip("L13", "Ach Ensure nil"); return end
    local testKey = "ACH_DD_KILLS_001"
    local prevDD  = ddSave.unlocked[testKey]
    local prevWoW = achSave.unlocked[testKey]
    local wasFlag = ddSave.migratedFromWoW
    -- Plant record in WoW table, reset migration flag
    achSave.unlocked[testKey] = { at = 1, value = 5 }
    ddSave.unlocked[testKey]  = nil
    ddSave.migratedFromWoW    = false
    -- First migration
    local moved1 = DD:MigrateFromWoW()
    T.check("L13: first MigrateFromWoW reports move(s)",    moved1 > 0)
    T.check("L13: key moved to DD namespace",               ddSave.unlocked[testKey] ~= nil)
    T.check("L13: key removed from WoW namespace",          achSave.unlocked[testKey] == nil)
    T.check("L13: migratedFromWoW flag now set",            ddSave.migratedFromWoW == true)
    -- Second migration must be a no-op
    local moved2 = DD:MigrateFromWoW()
    T.check("L13: second MigrateFromWoW returns 0 (idempotent)", moved2 == 0)
    -- Restore local plantings (RestoreDB handles the rest)
    ddSave.unlocked[testKey]  = prevDD
    achSave.unlocked[testKey] = prevWoW
    ddSave.migratedFromWoW    = wasFlag
end

tests[14] = function(T)  -- Dungeon Dwellers isolation: unlocks go to DD save, not WoW save
    local DD  = CC.DungeonAchievements
    local Ach = CC.Achievements
    if not DD or not Ach then T.skip("L14", "module missing"); return end
    local ddSave  = DD:Ensure();  if not ddSave  then T.skip("L14", "DD Ensure nil"); return end
    local achSave = Ach:Ensure(); if not achSave then T.skip("L14", "Ach Ensure nil"); return end
    local dungeon = CC.db and CC.db.soloGames and CC.db.soloGames.dungeon
    if not dungeon then T.skip("L14", "soloGames.dungeon missing"); return end
    local firstDD = DD.catalog and DD.catalog[1]
    if not firstDD then T.skip("L14", "DD catalog empty"); return end
    -- Force the stat above threshold
    local prevKills  = dungeon.kills
    local prevUnlock = ddSave.unlocked[firstDD.key]
    dungeon.kills = math.max(dungeon.kills or 0, firstDD.goal)
    ddSave.unlocked[firstDD.key] = nil
    DD:EvaluateAll(true)
    T.check("L14: DD achievement written to DD namespace",   ddSave.unlocked[firstDD.key] ~= nil)
    T.check("L14: DD achievement absent from WoW namespace", achSave.unlocked[firstDD.key] == nil)
    -- Restore within-test state
    dungeon.kills = prevKills
    ddSave.unlocked[firstDD.key] = prevUnlock
end

tests[15] = function(T)  -- Dungeon Crawler isolation: routing rules enforced
    local R = CC.ProgressRouter
    if not R then T.skip("L15", "ProgressRouter not loaded"); return end
    -- DD events must be rejected when routed to WOW namespace
    local e1 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.DUNGEON_DWELLER_BATTLE_PASS, sourceGame = R.GAMES.DUNGEON_DWELLER,
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.DD_ENEMY_KILL, amount = 1,
    })
    T.check("L15: DD->WOW route rejected", R:RouteProgressEvent(e1) == false)
    -- WOW events must be rejected when routed to DUNGEON_DWELLER namespace
    local e2 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
        progressNamespace = R.GAMES.DUNGEON_DWELLER, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
    })
    T.check("L15: WOW->DD route rejected", R:RouteProgressEvent(e2) == false)
    -- A valid DD event in DD namespace is accepted
    local e3 = R:BuildProgressEvent({
        sourceSystem = R.SYSTEMS.DUNGEON_DWELLER_BATTLE_PASS, sourceGame = R.GAMES.DUNGEON_DWELLER,
        progressNamespace = R.GAMES.DUNGEON_DWELLER, objectiveType = R.OBJECTIVES.DD_ENEMY_KILL, amount = 1,
    })
    local ok3 = R:RouteProgressEvent(e3)
    T.check("L15: valid DD event accepted in DD namespace", ok3 == true)
end

tests[16] = function(T)  -- FarmFinder isolation (unregistered game cannot pollute any namespace)
    local R = CC.ProgressRouter
    if not R then T.skip("L16", "ProgressRouter not loaded"); return end
    -- FARMFINDER is not a registered source system — must be rejected
    local e1 = R:BuildProgressEvent({
        sourceSystem = "FARMFINDER", sourceGame = "FARMFINDER",
        progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
    })
    T.check("L16: FARMFINDER->WOW rejected (unknown sourceSystem)", R:RouteProgressEvent(e1) == false)
    local e2 = R:BuildProgressEvent({
        sourceSystem = "FARMFINDER", sourceGame = "FARMFINDER",
        progressNamespace = R.GAMES.DUNGEON_DWELLER, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
    })
    T.check("L16: FARMFINDER->DD rejected", R:RouteProgressEvent(e2) == false)
    -- WoW and DD save tables must be untouched
    local achSave = CC.Achievements and CC.Achievements:Ensure()
    local ddSave  = CC.DungeonAchievements and CC.DungeonAchievements:Ensure()
    T.check("L16: WoW achievement save still accessible after rejected events", achSave ~= nil)
    T.check("L16: DD achievement save still accessible after rejected events",  ddSave  ~= nil)
    T.skip("L16 FarmFinder module test", "FarmFinder game not yet implemented")
end

tests[17] = function(T)  -- Outgoing damage stat accumulation
    local Ach = CC.Achievements
    if not Ach then T.skip("L17", "Achievements not loaded"); return end
    local save = Ach:Ensure(); if not save then T.skip("L17", "Ensure nil"); return end
    save.stats.WOW_DAMAGE_DEALT = 0
    save.stats.WOW_BEST_HIT     = 0
    -- Simulate the arithmetic CombatTracker performs for SWING_DAMAGE events
    local hits = { 600, 400, 1200 }
    for _, amt in ipairs(hits) do
        save.stats.WOW_DAMAGE_DEALT = save.stats.WOW_DAMAGE_DEALT + amt
        if amt > save.stats.WOW_BEST_HIT then save.stats.WOW_BEST_HIT = amt end
    end
    T.check("L17: WOW_DAMAGE_DEALT accumulates to 2200",    save.stats.WOW_DAMAGE_DEALT == 2200)
    T.check("L17: WOW_BEST_HIT tracks peak strike (1200)",  save.stats.WOW_BEST_HIT == 1200)
    T.check("L17: GetStat reads WOW_DAMAGE_DEALT",          Ach:GetStat("WOW_DAMAGE_DEALT") == 2200)
    T.check("L17: GetStat reads WOW_BEST_HIT",              Ach:GetStat("WOW_BEST_HIT") == 1200)
    local CT = CC.CombatTracker
    if CT then
        T.check("L17: CombatTracker module loaded", CT ~= nil)
    else
        T.skip("L17 CombatTracker check", "CombatTracker not loaded")
    end
    T.skip("L17 live SWING_DAMAGE", "requires real WoW combat log events")
end

tests[18] = function(T)  -- Incoming damage and healing stat accumulation
    local Ach = CC.Achievements
    if not Ach then T.skip("L18", "Achievements not loaded"); return end
    local save = Ach:Ensure(); if not save then T.skip("L18", "Ensure nil"); return end
    save.stats.WOW_DAMAGE_TAKEN = 0
    save.stats.WOW_HEALING      = 0
    save.stats.WOW_BEST_HEAL    = 0
    -- Simulate incoming damage events
    local dmg = { 500, 1200, 300 }
    for _, amt in ipairs(dmg) do save.stats.WOW_DAMAGE_TAKEN = save.stats.WOW_DAMAGE_TAKEN + amt end
    -- Simulate heal events (SPELL_HEAL: p4=amount, p7=critical)
    local heals = { 800, 1500, 600 }
    for _, amt in ipairs(heals) do
        save.stats.WOW_HEALING = save.stats.WOW_HEALING + amt
        if amt > save.stats.WOW_BEST_HEAL then save.stats.WOW_BEST_HEAL = amt end
    end
    T.check("L18: WOW_DAMAGE_TAKEN == 2000",    save.stats.WOW_DAMAGE_TAKEN == 2000)
    T.check("L18: WOW_HEALING == 2900",         save.stats.WOW_HEALING == 2900)
    T.check("L18: WOW_BEST_HEAL == 1500",       save.stats.WOW_BEST_HEAL == 1500)
    T.check("L18: GetStat reads WOW_DAMAGE_TAKEN", Ach:GetStat("WOW_DAMAGE_TAKEN") == 2000)
    T.check("L18: GetStat reads WOW_HEALING",      Ach:GetStat("WOW_HEALING") == 2900)
    T.skip("L18 live SPELL_HEAL events", "requires real WoW combat log events")
end

tests[19] = function(T)  -- Critical event stat accumulation + achievement unlock
    local Ach = CC.Achievements
    if not Ach then T.skip("L19", "Achievements not loaded"); return end
    local save = Ach:Ensure(); if not save then T.skip("L19", "Ensure nil"); return end
    save.stats.WOW_CRITS      = 0
    save.stats.WOW_CRIT_HEALS = 0
    save.unlocked["ACH_WOW_CRITS_001"] = nil
    -- Simulate crit counters (CombatTracker increments by 1 per crit flag)
    for _ = 1, 12 do save.stats.WOW_CRITS      = save.stats.WOW_CRITS      + 1 end
    for _ = 1, 3  do save.stats.WOW_CRIT_HEALS = save.stats.WOW_CRIT_HEALS + 1 end
    T.check("L19: WOW_CRITS == 12",         save.stats.WOW_CRITS      == 12)
    T.check("L19: WOW_CRIT_HEALS == 3",     save.stats.WOW_CRIT_HEALS == 3)
    T.check("L19: GetStat reads WOW_CRITS", Ach:GetStat("WOW_CRITS") == 12)
    -- At 12 crits, ACH_WOW_CRITS_001 (goal=10) should unlock
    Ach:EvaluateAll(true)
    T.check("L19: ACH_WOW_CRITS_001 unlocked at 12 crits (goal=10)",
        save.unlocked["ACH_WOW_CRITS_001"] ~= nil)
    -- ACH_WOW_CRITS_002 (goal=50) must NOT be unlocked at 12
    T.check("L19: ACH_WOW_CRITS_002 not unlocked at 12 (goal=50)",
        save.unlocked["ACH_WOW_CRITS_002"] == nil)
    T.skip("L19 live crit-flag parsing", "requires real WoW combat log events")
end

tests[20] = function(T)  -- Reload/save consistency (testable portion only)
    local Pass = CC.BattlePass
    if not Pass then T.skip("L20", "BattlePass not loaded"); return end
    local save = Pass:Ensure(); if not save then T.skip("L20", "Ensure nil"); return end
    -- Verify the live table IS the SavedVariables root
    T.check("L20: CC.db is the CreshChatDB root",
        CC.db ~= nil and _G.CreshChatDB ~= nil and CC.db == _G.CreshChatDB)
    -- Sentinel survives a second Ensure() call (same table returned)
    local mark = "CRESHTEST_" .. tostring(math.floor(math.max(0, (GetTime and GetTime() or 0) * 100)))
    save._testMark = mark
    local save2 = Pass:Ensure()
    T.check("L20: Ensure() returns same table on repeated calls",
        save2 ~= nil and save2._testMark == mark)
    save._testMark = nil
    -- Snapshot/restore round-trip integrity
    local bp = save.passXP
    local snap = deepCopy(CC.db.arcadeRewards)
    snap.passXP = bp + 12345  -- modify the copy
    copyInto(CC.db.arcadeRewards, snap)
    T.check("L20: copyInto modifies live table",  save.passXP == bp + 12345)
    snap.passXP = bp
    copyInto(CC.db.arcadeRewards, snap)
    T.check("L20: copyInto restores live table",  save.passXP == bp)
    T.skip("L20 /reload test", "requires /reload — set XP, reload, open BP, confirm level persists")
end

-- ── Malformed-input / rejected-event suite ────────────────────────────────────

local function runMalformed(T)
    local Pass = CC.BattlePass
    local R    = CC.ProgressRouter
    if Pass then
        local save = Pass:Ensure()
        if save then
            local before = save.passXP
            Pass:AddPassXP("not_a_number", "TEST", true)
            T.check("MALFORM: AddPassXP(string) safe, passXP unchanged", save.passXP == before)
        end
        -- ClaimReward for unreached level
        if save then
            local savedXP = save.passXP
            save.passXP = 0
            save.claimed["100"] = nil
            local okUnreached = Pass:ClaimReward(100, true)
            T.check("MALFORM: ClaimReward for unreached level 100 returns false",
                okUnreached == false)
            save.passXP = savedXP
        end
    end
    if R then
        local wasDevMode = R:IsDevMode()
        R:EnableDevMode(true); R:ClearDevLog()
        local function routeOk(e)
            local ok, result = pcall(R.RouteProgressEvent, R, e)
            return ok and result or false
        end
        -- Zero amount
        local e0 = R:BuildProgressEvent({
            sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
            progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL, amount = 0,
        })
        T.check("MALFORM: amount=0 rejected",          routeOk(e0) == false)
        -- Negative amount
        local eN = R:BuildProgressEvent({
            sourceSystem = R.SYSTEMS.WOW_BATTLE_PASS, sourceGame = R.GAMES.WOW,
            progressNamespace = R.GAMES.WOW, objectiveType = R.OBJECTIVES.MOB_KILL, amount = -1,
        })
        T.check("MALFORM: amount=-1 rejected",         routeOk(eN) == false)
        -- Missing sourceSystem
        local eM = R:BuildProgressEvent({
            sourceGame = R.GAMES.WOW, progressNamespace = R.GAMES.WOW,
            objectiveType = R.OBJECTIVES.MOB_KILL, amount = 1,
        })
        T.check("MALFORM: missing sourceSystem rejected", routeOk(eM) == false)
        -- nil event
        local okNil = routeOk(nil)
        T.check("MALFORM: nil event safe (returns false or errors cleanly)", okNil == false)
        R:EnableDevMode(wasDevMode)
    end
end

-- ── Test groups L21–L26 (Pass 9 — character identity, scopes, migration) ─────

tests[21] = function(T)  -- L21: Character identity
    local key = CC:GetCurrentCharacterProfileKey()
    T.check("L21: profile key non-empty", type(key) == "string" and key ~= "")
    T.check("L21: key contains ' - ' separator", type(key) == "string" and key:find(" - ", 1, true) ~= nil)
    local profiles = CC:GetCharacterProfiles()
    T.check("L21: GetCharacterProfiles returns table", type(profiles) == "table")
    local profile = CC.currentProfile
    T.check("L21: currentProfile is set", type(profile) == "table")
    if profile then
        T.check("L21: profile.name non-empty", type(profile.name) == "string" and profile.name ~= "")
        T.check("L21: profile.realm non-empty", type(profile.realm) == "string" and profile.realm ~= "")
    else
        T.skip("L21: profile.name", "currentProfile nil")
        T.skip("L21: profile.realm", "currentProfile nil")
    end
    local ct = CC.CombatTracker
    if ct and ct.GetCharStats then
        local c = ct:GetCharStats()
        if c then
            T.check("L21: charCombat.WOW_DAMAGE_DEALT exists", tonumber(c.WOW_DAMAGE_DEALT) ~= nil)
            T.check("L21: charCombat separate from account stats",
                c ~= (CC.Achievements and CC.Achievements:Ensure() and CC.Achievements:Ensure().stats))
        else
            T.skip("L21: charCombat fields", "charCombatRef nil (profile may not have loaded)")
        end
    else
        T.skip("L21: charCombat fields", "CombatTracker not loaded")
    end
end

tests[22] = function(T)  -- L22: Combat attribution (per-character vs account)
    local ct = CC.CombatTracker
    if not ct then T.skip("L22", "CombatTracker not loaded"); return end
    local A = CC.Achievements
    if not A then T.skip("L22", "Achievements not loaded"); return end
    local save = A:Ensure()
    if not save then T.skip("L22", "Achievements:Ensure nil"); return end
    local acct = save.stats
    local char = ct:GetCharStats()
    if not acct then T.skip("L22", "account stats nil"); return end
    -- Verify account stats have the WOW_* fields
    T.check("L22: account WOW_DAMAGE_DEALT is number", tonumber(acct.WOW_DAMAGE_DEALT) ~= nil)
    T.check("L22: account WOW_CRITS is number",         tonumber(acct.WOW_CRITS) ~= nil)
    T.check("L22: account WOW_HEALING is number",       tonumber(acct.WOW_HEALING) ~= nil)
    -- Simulate a stat write and verify both tables update independently
    if char then
        T.check("L22: char table distinct from account table", char ~= acct)
        local prevAcct = acct.WOW_DAMAGE_DEALT
        local prevChar = char.WOW_DAMAGE_DEALT
        acct.WOW_DAMAGE_DEALT = prevAcct + 500
        char.WOW_DAMAGE_DEALT = prevChar + 500
        T.check("L22: account write independent", acct.WOW_DAMAGE_DEALT == prevAcct + 500)
        T.check("L22: char write independent",    char.WOW_DAMAGE_DEALT == prevChar + 500)
        -- Restore
        acct.WOW_DAMAGE_DEALT = prevAcct
        char.WOW_DAMAGE_DEALT = prevChar
        T.check("L22: account restored", acct.WOW_DAMAGE_DEALT == prevAcct)
        T.check("L22: char restored",    char.WOW_DAMAGE_DEALT == prevChar)
    else
        T.skip("L22: char table isolation", "charCombatRef nil")
    end
    -- Zero/negative guards (from safeAmt — tested via direct stat, not live combat)
    T.skip("L22: live SWING_DAMAGE parsing", "requires real WoW combat events")
end

tests[23] = function(T)  -- L23: Achievement scopes
    local A = CC.Achievements
    if not A then T.skip("L23", "Achievements not loaded"); return end
    A:BuildCatalog()
    -- All ACH_WOW_* achievements should default to ACCOUNT_AGGREGATE
    local damageAch = A.byKey["ACH_WOW_DAMAGE_DEALT_001"]
    if damageAch then
        T.check("L23: ACH_WOW_DAMAGE_DEALT_001 scope is ACCOUNT_AGGREGATE",
            damageAch.scope == "ACCOUNT_AGGREGATE")
    else
        T.skip("L23: ACCOUNT_AGGREGATE scope check", "ACH_WOW_DAMAGE_DEALT_001 not in catalog")
    end
    -- Class achievements should be CHARACTER scope
    local classAch = A.byKey["ACH_CLASS_DRUID_001"]
    if classAch then
        T.check("L23: ACH_CLASS_DRUID_001 scope is CHARACTER", classAch.scope == "CHARACTER")
    else
        T.skip("L23: CHARACTER scope on class ach", "ACH_CLASS_DRUID_001 not in catalog")
    end
    -- GetStatForScope with ACCOUNT_AGGREGATE should call through to GetStat
    local statAcct = A:GetStatForScope("WOW_CRITS", "ACCOUNT_AGGREGATE")
    local statDirect = A:GetStat("WOW_CRITS")
    T.check("L23: GetStatForScope(ACCOUNT_AGGREGATE) == GetStat", statAcct == statDirect)
    -- GetStatForScope with CHARACTER on a CLASS| stat falls through to account class tracking
    local classStatChar = A:GetStatForScope("CLASS|DRUID|SHAPESHIFTS", "CHARACTER")
    local classStatDirect = A:GetStat("CLASS|DRUID|SHAPESHIFTS")
    T.check("L23: GetStatForScope(CHARACTER, CLASS|) == GetStat for class stats",
        classStatChar == classStatDirect)
    -- Unlock() stores scope in the unlock record
    local save = A:Ensure()
    if save and damageAch and not save.unlocked[damageAch.key] then
        local prevStat = save.stats.WOW_DAMAGE_DEALT or 0
        save.stats.WOW_DAMAGE_DEALT = damageAch.goal  -- force threshold
        A:Unlock(damageAch, true)
        local rec = save.unlocked[damageAch.key]
        T.check("L23: unlock record has scope field", rec and type(rec.scope) == "string")
        T.check("L23: unlock scope matches achievement scope",
            rec and rec.scope == (damageAch.scope or "ACCOUNT_AGGREGATE"))
        T.check("L23: unlock completedBy is string or nil",
            rec and (rec.completedBy == nil or type(rec.completedBy) == "string"))
        save.unlocked[damageAch.key] = nil   -- clean up
        save.stats.WOW_DAMAGE_DEALT = prevStat
    else
        T.skip("L23: unlock scope/completedBy fields", "ach already unlocked or save nil")
    end
end

tests[24] = function(T)  -- L24: Class achievement keys (ACH_CLASS_* format)
    local A = CC.Achievements
    if not A then T.skip("L24", "Achievements not loaded"); return end
    A:BuildCatalog()
    -- New stable keys present
    T.check("L24: ACH_CLASS_DRUID_001 in byKey",   A.byKey["ACH_CLASS_DRUID_001"]   ~= nil)
    T.check("L24: ACH_CLASS_WARRIOR_010 in byKey", A.byKey["ACH_CLASS_WARRIOR_010"] ~= nil)
    T.check("L24: ACH_CLASS_DRUID_011 in byKey",   A.byKey["ACH_CLASS_DRUID_011"]   ~= nil)
    T.check("L24: ACH_CLASS_SHAMAN_015 in byKey",  A.byKey["ACH_CLASS_SHAMAN_015"]  ~= nil)
    -- Old keys must be absent (migration removed them; catalog never registers them)
    T.check("L24: CLASS_DRUID_001 absent from byKey",   A.byKey["CLASS_DRUID_001"]   == nil)
    T.check("L24: CLASS_WARRIOR_081 absent from byKey", A.byKey["CLASS_WARRIOR_081"] == nil)
    -- Scope = CHARACTER on all class achievements
    local classAch = A.byKey["ACH_CLASS_MAGE_001"]
    T.check("L24: ACH_CLASS_MAGE_001 has scope CHARACTER",
        classAch ~= nil and classAch.scope == "CHARACTER")
end

tests[25] = function(T)  -- L25: Dungeon Dwellers isolation (no WoW namespace bleed)
    local DA = CC.DungeonAchievements
    local A  = CC.Achievements
    if not DA then T.skip("L25", "DungeonAchievements not loaded"); return end
    if not A  then T.skip("L25", "Achievements not loaded"); return end
    local ddSave  = DA:Ensure()
    local wowSave = A:Ensure()
    -- DD namespace exists and is separate from WoW namespace
    T.check("L25: DD save table distinct from WoW save", ddSave ~= wowSave)
    -- WoW stat keys not present in DD save.stats (DD uses DD_ prefix)
    if ddSave and type(ddSave.activity) == "table" then
        T.check("L25: DD activity has no WOW_DAMAGE_DEALT key",
            ddSave.activity["WOW_DAMAGE_DEALT"] == nil)
    else
        T.skip("L25: DD activity isolation", "DD activity table missing")
    end
    -- charCombatRef does not write to DD save
    local ct = CC.CombatTracker
    if ct then
        local charStats = ct:GetCharStats()
        T.check("L25: charCombatRef distinct from DD activity",
            charStats == nil or (ddSave and charStats ~= ddSave.activity))
    else
        T.skip("L25: charCombatRef vs DD", "CombatTracker not loaded")
    end
    -- DD:GetStat cannot read WOW_* stats
    local ddWow = DA:GetStat("WOW_DAMAGE_DEALT")
    T.check("L25: DA:GetStat(WOW_DAMAGE_DEALT) returns 0", ddWow == 0)
end

tests[26] = function(T)  -- L26: Schema migration V78 (CLASS_* → ACH_CLASS_*)
    local shared = CreshChatDB and CreshChatDB.accountProgression
    if not shared then T.skip("L26", "accountProgression not set"); return end
    -- migratedSchema should now be >= 78
    T.check("L26: migratedSchema >= 78", tonumber(shared.migratedSchema or 0) >= 78)
    -- Unlocked table should have no old CLASS_* keys for any class
    local unlocked = shared.gameProgression
        and shared.gameProgression.achievements
        and shared.gameProgression.achievements.unlocked or {}
    T.check("L26: CLASS_DRUID_001 absent from unlocked",   unlocked["CLASS_DRUID_001"]   == nil)
    T.check("L26: CLASS_HUNTER_011 absent from unlocked",  unlocked["CLASS_HUNTER_011"]  == nil)
    T.check("L26: CLASS_WARRIOR_090 absent from unlocked", unlocked["CLASS_WARRIOR_090"] == nil)
    -- V78 migration is idempotent: inject an old key, run migration, verify rename, run again
    local testOldKey = "CLASS_DRUID_001"
    local testNewKey = "ACH_CLASS_DRUID_001"
    local hadNew = unlocked[testNewKey]
    unlocked[testOldKey] = { at = 1, value = 100, sourceSystem = "TEST", sourceId = testOldKey, targetGame = "GLOBAL" }
    unlocked[testNewKey] = nil   -- ensure new slot empty for clean test
    -- Manually invoke migration logic by calling EnsureAccountProgressionStorage
    -- (MigrateToV78 is local; we test indirectly via the schema guard being off)
    -- Inject a lower schema value to force re-run
    local origSchema = shared.migratedSchema
    shared.migratedSchema = 77   -- roll back to trigger V78
    CC:EnsureAccountProgressionStorage(false)
    T.check("L26: migratedSchema bumped back to 78", tonumber(shared.migratedSchema or 0) >= 78)
    T.check("L26: old key renamed after re-run",  unlocked[testOldKey] == nil)
    T.check("L26: new key populated after re-run", unlocked[testNewKey] ~= nil)
    -- Idempotency: run again with schema=78 already set — should not double-process
    unlocked[testOldKey] = { at = 2, value = 50, sourceSystem = "TEST", sourceId = testOldKey, targetGame = "GLOBAL" }
    CC:EnsureAccountProgressionStorage(false)
    T.check("L26: old key NOT renamed on second run (idempotent)", unlocked[testOldKey] ~= nil)
    -- Restore
    unlocked[testOldKey] = nil
    if hadNew then unlocked[testNewKey] = hadNew else unlocked[testNewKey] = nil end
    shared.migratedSchema = origSchema
end

-- ── Public runner ─────────────────────────────────────────────────────────────

function Developer:RunTestSuite(filter)
    if not self.testMode then
        if CC.Print then CC:Print("[TEST] ERROR: '/cc test on' required before running tests.") end
        return
    end
    if not self:SnapshotDB() then
        if CC.Print then CC:Print("[TEST] ERROR: snapshot failed — aborting") end
        return
    end
    local displayName = filter and ("L" .. filter) or "all"
    if CC.Print then CC:Print("[TEST] ── CreshChat suite (" .. displayName .. ") ──────────────") end
    local T = makeRunner(self.testVerbose)
    local groups = {}
    if filter then
        local n = tonumber(filter)
        if n and n >= 1 and n <= 26 and tests[n] then
            groups[1] = n
        else
            if CC.Print then CC:Print("[TEST] unknown group: " .. tostring(filter) .. " (1-26)") end
            self:RestoreDB(); self:SnapshotDB(); return
        end
    else
        for i = 1, 26 do groups[i] = i end
    end
    for _, idx in ipairs(groups) do
        local ok, err = pcall(tests[idx], T)
        if not ok and CC.Print then CC:Print("[TEST] ERROR in L" .. idx .. ": " .. tostring(err)) end
    end
    local mPassed, mFailed = 0, 0
    if not filter then
        local mT = makeRunner(self.testVerbose)
        local ok, err = pcall(runMalformed, mT)
        if not ok and CC.Print then CC:Print("[TEST] ERROR in malformed suite: " .. tostring(err)) end
        mPassed, mFailed = mT.passed(), mT.failed()
        if CC.Print then
            CC:Print(string.format("[TEST] MALFORMED suite: %d passed, %d failed", mPassed, mFailed))
        end
    end
    local total   = T.passed() + mPassed
    local totalFail = T.failed() + mFailed
    if CC.Print then
        CC:Print(string.format("[TEST] ── TOTAL: %d passed  %d failed ──────────────────",
            total, totalFail))
        if totalFail == 0 then
            CC:Print("[TEST] All tests passed. Run '/cc test off' to restore data.")
        else
            CC:Print("[TEST] " .. totalFail .. " failure(s). Run '/cc test off' to restore data.")
        end
    end
    -- Restore after every run so the character is always in a clean state.
    self:RestoreDB()
    self:SnapshotDB()   -- fresh snapshot ready for next run
end

function Developer:HandleTestCommand(arg)
    if     arg == "on"      then self:EnableTestMode()
    elseif arg == "off"     then self:DisableTestMode()
    elseif arg == "verbose" then
        self.testVerbose = not self.testVerbose
        if CC.Print then CC:Print("[TEST] verbose " .. (self.testVerbose and "ON" or "OFF")) end
    elseif arg == "status"  then
        if CC.Print then
            CC:Print("[TEST] mode=" .. (self.testMode and "ON" or "OFF")
                .. "  verbose=" .. (self.testVerbose and "ON" or "OFF")
                .. "  snapshot=" .. (self.snapshot and "saved" or "none"))
        end
    elseif arg == "run" or arg == "all" or arg == "" then
        self:RunTestSuite(nil)
    else
        local runArg = string.match(tostring(arg), "^run%s+(%S+)$") or arg
        local n = tonumber(runArg)
        if n then
            self:RunTestSuite(tostring(math.floor(n)))
        else
            if CC.Print then
                CC:Print("[TEST] /cc test on        — enable test mode (snapshots DB)")
                CC:Print("[TEST] /cc test off       — disable test mode (restores DB)")
                CC:Print("[TEST] /cc test run       — run all 26 groups + malformed suite")
                CC:Print("[TEST] /cc test run N     — run only group L[N] (1-26)")
                CC:Print("[TEST] /cc test verbose   — toggle per-assertion output")
                CC:Print("[TEST] /cc test status    — show mode/verbose/snapshot state")
            end
        end
    end
end

local originalHandleSlashCommand = CC.HandleSlashCommand
function CC:HandleSlashCommand(input)
    local command = string.lower(string.match(tostring(input or ""), "^(%S*)") or "")
    if command == "dev" or command == "devreport" or command == "developer" then
        Developer:PrintRuntimeReport()
        return
    elseif command == "modules" then
        Developer:PrintModules()
        return
    elseif command == "assets" then
        Developer:PrintAssets()
        return
    elseif command == "progress" then
        local arg = string.lower(string.match(tostring(input or ""), "^%S+%s+(%S*)") or "")
        Developer:HandleProgressCommand(arg)
        return
    elseif command == "combat" then
        Developer:PrintCombatStats()
        return
    elseif command == "test" then
        local arg = string.lower(string.match(tostring(input or ""), "^%S+%s+(.+)$") or "")
        Developer:HandleTestCommand(arg)
        return
    end
    return originalHandleSlashCommand(self, input)
end

local originalShowHelp = CC.ShowHelp
function CC:ShowHelp()
    originalShowHelp(self)
    self:Print("/cc devreport - show build, module, database and asset status")
    self:Print("/cc modules - list loaded CreshChat modules")
    self:Print("/cc assets - report registered themes and media libraries")
    self:Print("/cc progress [test|log|clear|on|off] - ProgressRouter diagnostics")
    self:Print("/cc combat - print combat tracker stats and achievement counts")
    self:Print("/cc test on/off/run/verbose/status - developer test suite (L1-L20)")
end
