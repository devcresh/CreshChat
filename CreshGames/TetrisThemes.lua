local ADDON_NAME, CC = ...
if not CC then return end

local Tetris = {
    version = CC.version,
    maxPassLevel = 100,
    maxGameLevel = 1000,
    linesPerGameLevel = 10,
    themes = {},
    themeOrder = {},
    backgrounds = {},
    backgroundOrder = {},
    miniPassThemeRewards = {},
    mainPassThemeRewards = {
        [15] = "QUAKE_ARENA",
        [35] = "DARK_PORTAL_BLOCKS",
        [55] = "ASHBRINGER_LIGHT",
        [75] = "ILLIDARI_FEL",
        [95] = "COSMIC_GRANDMASTER",
    },
}
CC.Tetris = Tetris
if CC.RegisterModule then CC:RegisterModule("Tetris", Tetris) end

local floor, min, max = math.floor, math.min, math.max
local upper = string.upper

local PIECES = { "I", "O", "T", "S", "Z", "J", "L" }
local TETRIS_BACKGROUND_ROOT = "Interface\\AddOns\\CreshGames\\Media\\Games\\Tetris\\Backgrounds\\"

-- Official-style gravity reference points from the common Tetris Worlds /
-- Guideline curve. CreshChat stretches the relative curve across 1,000 game
-- levels and caps the final automatic drop at 0.10 seconds per row so the
-- no-lock-delay WoW implementation remains controllable.
local GUIDELINE_GRAVITY = {
    0.01667, 0.021017, 0.026977, 0.035256, 0.04693,
    0.06361, 0.0879, 0.1236, 0.1775, 0.2598,
    0.388, 0.59, 0.92, 1.46, 2.36,
}
local START_DROP_INTERVAL = 0.90
local FINAL_DROP_INTERVAL = 0.10

local function clamp(value, low, high)
    value = tonumber(value) or low
    return max(low, min(high, value))
end

local function copyColor(color, alpha)
    return { color[1] or 0, color[2] or 0, color[3] or 0, alpha or color[4] or 1 }
end

local function mix(a, b, amount)
    amount = clamp(amount or 0.5, 0, 1)
    return {
        (a[1] or 0) * (1 - amount) + (b[1] or 0) * amount,
        (a[2] or 0) * (1 - amount) + (b[2] or 0) * amount,
        (a[3] or 0) * (1 - amount) + (b[3] or 0) * amount,
        1,
    }
end

local function brighten(color, amount)
    amount = tonumber(amount) or 0.12
    return {
        min(1, (color[1] or 0) + amount),
        min(1, (color[2] or 0) + amount),
        min(1, (color[3] or 0) + amount),
        color[4] or 1,
    }
end

local function darken(color, amount)
    amount = tonumber(amount) or 0.12
    return {
        max(0, (color[1] or 0) - amount),
        max(0, (color[2] or 0) - amount),
        max(0, (color[3] or 0) - amount),
        color[4] or 1,
    }
end

local function addTheme(key, name, source, requirement, a, b, c, background, note)
    key = upper(tostring(key or ""))
    local colors = {
        I = copyColor(a),
        O = copyColor(b),
        T = copyColor(c),
        S = mix(a, b, 0.48),
        Z = mix(c, b, 0.42),
        J = darken(a, 0.12),
        L = brighten(c, 0.13),
    }
    local entry = {
        key = key,
        name = name,
        source = source,
        requirement = requirement,
        colors = colors,
        background = background or { 0.045, 0.050, 0.065, 1 },
        guide = brighten(mix(a, c, 0.50), 0.16),
        highlight = brighten(mix(a, b, 0.50), 0.20),
        note = note or "A collectible Tetris piece palette.",
    }
    Tetris.themes[key] = entry
    Tetris.themeOrder[#Tetris.themeOrder + 1] = key
    return entry
end

local function addBackground(key, name, source, requirement, tint, accent, guide, background, note, texture)
    key = upper(tostring(key or ""))
    local entry = {
        key = key,
        name = name,
        source = source or "BACKGROUND_REVEAL",
        requirement = requirement or 100,
        texture = texture,
        backgroundTexture = texture, -- compatibility alias for older UI helpers
        background = background or { 0.025, 0.030, 0.040, 1 },
        tint = copyColor(tint or { 1, 1, 1, 1 }),
        accent = copyColor(accent or tint or { 0.35, 0.75, 1, 1 }),
        guide = copyColor(guide or accent or { 0.35, 0.75, 1, 1 }),
        note = note or "A collectible Tetris image background.",
    }
    Tetris.backgrounds[key] = entry
    Tetris.backgroundOrder[#Tetris.backgroundOrder + 1] = key
    return entry
end

-- Default and game-level achievement sets. These unlock automatically when the
-- character reaches the listed Tetris game level.
addTheme("CLASSIC_BLOCKS", "Classic Blocks", "DEFAULT", 1,
    {0.15,0.75,0.90,1}, {0.95,0.78,0.18,1}, {0.62,0.32,0.90,1}, {0.055,0.062,0.078,1},
    "The original seven-colour arcade set.")
addTheme("CRESH_BLUE", "Cresh Blue", "GAME_LEVEL", 2,
    {0.10,0.72,1.00,1}, {0.34,0.90,1.00,1}, {0.04,0.42,0.88,1}, {0.025,0.045,0.075,1},
    "Clean blue blocks matching the CreshChat console.")
addTheme("HORDE_IRON", "Horde Iron", "GAME_LEVEL", 4,
    {0.76,0.08,0.06,1}, {0.96,0.34,0.08,1}, {0.33,0.04,0.03,1}, {0.055,0.018,0.015,1},
    "Crimson banners, dark iron and ember edges.")
addTheme("ALLIANCE_VANGUARD", "Alliance Vanguard", "GAME_LEVEL", 6,
    {0.10,0.38,0.94,1}, {1.00,0.74,0.16,1}, {0.30,0.62,1.00,1}, {0.018,0.035,0.080,1},
    "Royal blue blocks with lion-gold highlights.")
addTheme("FORSAKEN_PLAGUE", "Forsaken Plague", "GAME_LEVEL", 8,
    {0.46,0.22,0.66,1}, {0.45,0.82,0.18,1}, {0.20,0.08,0.28,1}, {0.032,0.018,0.040,1},
    "Undercity violet and plague-green stonework.")
addTheme("DRAENEI_CRYSTAL", "Draenei Crystal", "GAME_LEVEL", 10,
    {0.18,0.78,1.00,1}, {0.82,0.42,1.00,1}, {0.38,0.24,0.96,1}, {0.020,0.030,0.075,1},
    "Luminous draenic crystals and arcane blue.")
addTheme("BLOOD_ELF_SUN", "Blood Elf Sun", "GAME_LEVEL", 12,
    {0.82,0.08,0.12,1}, {1.00,0.73,0.20,1}, {0.94,0.28,0.12,1}, {0.060,0.012,0.020,1},
    "Sun-gold trim over Blood Elf crimson.")
addTheme("NAGRAND_SKY", "Nagrand Sky", "GAME_LEVEL", 15,
    {0.22,0.70,1.00,1}, {0.54,0.88,0.22,1}, {0.48,0.36,0.22,1}, {0.020,0.055,0.070,1},
    "Open skies, grasslands and floating-island stone.")
addTheme("ZANGARMARSH_GLOW", "Zangarmarsh Glow", "GAME_LEVEL", 18,
    {0.10,0.88,0.82,1}, {0.64,0.30,0.92,1}, {0.12,0.46,0.58,1}, {0.010,0.055,0.060,1},
    "Bioluminescent spores and deep marsh water.")
addTheme("HELLFIRE_EMBER", "Hellfire Ember", "GAME_LEVEL", 22,
    {0.94,0.20,0.06,1}, {0.95,0.53,0.10,1}, {0.44,0.08,0.03,1}, {0.060,0.018,0.010,1},
    "Cracked red earth and fel-scorched embers.")
addTheme("BLACK_TEMPLE_STONE", "Black Temple Stone", "GAME_LEVEL", 26,
    {0.34,0.18,0.52,1}, {0.28,0.88,0.24,1}, {0.10,0.08,0.14,1}, {0.012,0.012,0.018,1},
    "Illidari violet, fel green and temple shadow.")
addTheme("FROSTMOURNE", "Frostmourne", "GAME_LEVEL", 30,
    {0.60,0.92,1.00,1}, {0.82,0.95,1.00,1}, {0.18,0.48,0.78,1}, {0.018,0.040,0.060,1},
    "Frozen steel and cold runic light.")
addTheme("EMERALD_DREAM", "Emerald Dream", "GAME_LEVEL", 40,
    {0.15,0.82,0.42,1}, {0.72,0.96,0.24,1}, {0.12,0.46,0.28,1}, {0.012,0.050,0.032,1},
    "Dreaming greens with bright natural magic.")
addTheme("MOLTEN_CORE", "Molten Core", "GAME_LEVEL", 50,
    {1.00,0.26,0.05,1}, {1.00,0.72,0.08,1}, {0.62,0.06,0.02,1}, {0.070,0.018,0.006,1},
    "Lava orange, sulphur gold and core-fire red.")
addTheme("VOID_STORM", "Void Storm", "GAME_LEVEL", 75,
    {0.44,0.20,1.00,1}, {0.08,0.80,1.00,1}, {0.82,0.16,0.92,1}, {0.022,0.010,0.060,1},
    "A high-level set of void purple and storm energy.")

-- Twenty themes are earned through the dedicated 100-level Tetris Pass.
local miniThemes = {
    {10, "PIXEL_CANDY", "Pixel Candy", {1.00,0.28,0.66,1}, {0.30,0.90,1.00,1}, {0.78,0.42,1.00,1}, {0.060,0.020,0.060,1}, "Bright arcade sweets and neon sugar."},
    {20, "ARCANE_RUNES", "Arcane Runes", {0.30,0.52,1.00,1}, {0.84,0.42,1.00,1}, {0.18,0.90,0.94,1}, {0.018,0.026,0.070,1}, "Blue-violet runes with a charged glow."},
    {30, "GOLDEN_CACHE", "Golden Cache", {1.00,0.68,0.08,1}, {1.00,0.90,0.38,1}, {0.68,0.34,0.04,1}, {0.055,0.035,0.008,1}, "Treasure-vault gold and polished bronze."},
    {40, "MURLOC_SPLASH", "Murloc Splash", {0.10,0.82,0.88,1}, {0.66,0.90,0.18,1}, {0.16,0.46,0.70,1}, {0.010,0.050,0.060,1}, "Coastal teal, fin green and wet stone."},
    {50, "GOBLIN_TECH", "Goblin Tech", {0.34,0.92,0.12,1}, {1.00,0.58,0.06,1}, {0.30,0.34,0.24,1}, {0.026,0.045,0.016,1}, "Volatile green engineering with copper sparks."},
    {60, "MOONWELL", "Moonwell", {0.38,0.62,1.00,1}, {0.76,0.84,1.00,1}, {0.44,0.28,0.86,1}, {0.020,0.025,0.060,1}, "Moonlit silver-blue and kaldorei violet."},
    {70, "NETHERSTORM_GRID", "Netherstorm Grid", {0.72,0.20,1.00,1}, {0.20,0.72,1.00,1}, {0.96,0.28,0.72,1}, {0.040,0.012,0.070,1}, "Fractured arcane currents over a dark grid."},
    {80, "SUNWELL_RADIANCE", "Sunwell Radiance", {1.00,0.76,0.20,1}, {1.00,0.96,0.62,1}, {1.00,0.34,0.18,1}, {0.070,0.040,0.012,1}, "High-elven light, phoenix red and radiant gold."},
    {90, "TITAN_FORGE", "Titan Forge", {0.28,0.72,1.00,1}, {1.00,0.76,0.24,1}, {0.44,0.48,0.54,1}, {0.025,0.030,0.038,1}, "Titan steel, keeper blue and ancient gold."},
    {100, "CRESH_IMMORTAL", "Cresh Immortal", {0.04,0.78,1.00,1}, {1.00,0.84,0.20,1}, {0.82,0.18,1.00,1}, {0.008,0.018,0.038,1}, "The final Tetris Pass set with animated-looking contrast."},
}
for _, row in ipairs(miniThemes) do
    Tetris.miniPassThemeRewards[row[1]] = row[2]
    addTheme(row[2], row[3], "TETRIS_PASS", row[1], row[4], row[5], row[6], row[7], row[8])
end

-- Five premium sets are attached to selected levels of the main Cresh Battle Pass.
addTheme("QUAKE_ARENA", "Quake Arena", "MAIN_PASS", 15,
    {0.96,0.17,0.03,1}, {1.00,0.52,0.06,1}, {0.24,0.26,0.28,1}, {0.012,0.014,0.018,1},
    "Arena black, industrial steel and rocket-orange glow.")
addTheme("DARK_PORTAL_BLOCKS", "Dark Portal Blocks", "MAIN_PASS", 35,
    {0.56,0.18,0.90,1}, {0.30,0.92,0.22,1}, {0.14,0.05,0.24,1}, {0.018,0.008,0.028,1},
    "Portal violet, fel green and ancient black stone.")
addTheme("ASHBRINGER_LIGHT", "Ashbringer Light", "MAIN_PASS", 55,
    {1.00,0.62,0.10,1}, {1.00,0.94,0.54,1}, {0.86,0.18,0.08,1}, {0.060,0.025,0.008,1},
    "Holy fire, polished gold and scarlet flame.")
addTheme("ILLIDARI_FEL", "Illidari Fel", "MAIN_PASS", 75,
    {0.38,0.96,0.16,1}, {0.70,0.22,0.96,1}, {0.10,0.18,0.08,1}, {0.010,0.022,0.010,1},
    "Premium demon-hunter green and Illidari violet.")
addTheme("COSMIC_GRANDMASTER", "Cosmic Grandmaster", "MAIN_PASS", 95,
    {0.10,0.76,1.00,1}, {1.00,0.42,0.82,1}, {0.60,0.30,1.00,1}, {0.008,0.010,0.034,1},
    "A rare cosmic set reserved for late Battle Pass progression.")

-- Twenty additional block palettes. These are colour/highlight themes only;
-- image backgrounds are registered separately below.
local extraThemes = {
    { "KARAZHAN_CHECKER", "Karazhan Checker", "GAME_LEVEL", 3, {0.58,0.38,0.74,1}, {0.94,0.78,0.28,1}, {0.20,0.13,0.30,1}, {0.045,0.035,0.065,1}, "Arcane chessboard stone and ballroom gold." },
    { "SHATTRATH_TERRACE", "Shattrath Terrace", "GAME_LEVEL", 5, {0.24,0.72,1.00,1}, {0.92,0.78,0.34,1}, {0.42,0.36,0.72,1}, {0.025,0.045,0.075,1}, "Naaru blue, terrace stone and warm city light." },
    { "BLADES_EDGE_SPIRES", "Blade's Edge Spires", "GAME_LEVEL", 7, {0.74,0.24,0.18,1}, {0.92,0.56,0.20,1}, {0.34,0.18,0.16,1}, {0.055,0.024,0.020,1}, "Razor ridges, scorched rock and ember metal." },
    { "TEROKKAR_TWILIGHT", "Terokkar Twilight", "GAME_LEVEL", 9, {0.42,0.36,0.76,1}, {0.28,0.70,0.74,1}, {0.72,0.46,0.86,1}, {0.032,0.030,0.060,1}, "Twilight forest violet with ghostly blue light." },
    { "SHADOWMOON_FELSTORM", "Shadowmoon Felstorm", "GAME_LEVEL", 14, {0.26,0.86,0.22,1}, {0.62,0.18,0.86,1}, {0.10,0.28,0.14,1}, {0.015,0.035,0.020,1}, "Fel lightning over fractured Shadowmoon ground." },
    { "TEMPEST_KEEP", "Tempest Keep", "GAME_LEVEL", 20, {0.76,0.28,1.00,1}, {0.28,0.76,1.00,1}, {0.96,0.42,0.74,1}, {0.035,0.020,0.070,1}, "Arcane conduits and floating fortress energy." },
    { "SUNWELL_PLATEAU", "Sunwell Plateau", "GAME_LEVEL", 28, {1.00,0.72,0.18,1}, {1.00,0.94,0.58,1}, {0.92,0.28,0.18,1}, {0.070,0.040,0.015,1}, "Radiant gold, phoenix red and sunlit stone." },
    { "ZULAMAN_TOTEM", "Zul'Aman Totem", "GAME_LEVEL", 35, {0.72,0.52,0.12,1}, {0.20,0.70,0.30,1}, {0.42,0.22,0.08,1}, {0.045,0.035,0.014,1}, "Ancient totems, jungle green and weathered gold." },
    { "BLACKROCK_FORGE", "Blackrock Forge", "GAME_LEVEL", 60, {0.92,0.26,0.08,1}, {0.48,0.48,0.50,1}, {0.30,0.08,0.04,1}, {0.052,0.020,0.012,1}, "Black iron plates with molten forge seams." },
    { "SCARLET_CRUSADE", "Scarlet Crusade", "GAME_LEVEL", 90, {0.92,0.10,0.16,1}, {0.96,0.78,0.44,1}, {0.42,0.04,0.08,1}, {0.065,0.015,0.022,1}, "Scarlet banners, cathedral gold and dark steel." },

    { "ICECROWN_RIME", "Icecrown Rime", "TETRIS_PASS", 5, {0.52,0.86,1.00,1}, {0.86,0.96,1.00,1}, {0.16,0.38,0.68,1}, {0.018,0.035,0.060,1}, "Frozen battlements and cold runic steel." },
    { "ULDUAR_CONSTELLATION", "Ulduar Constellation", "TETRIS_PASS", 15, {0.30,0.68,1.00,1}, {0.96,0.76,0.26,1}, {0.32,0.42,0.58,1}, {0.018,0.035,0.055,1}, "Titan constellations across keeper-blue stone." },
    { "DEEPHOLM_CRYSTAL", "Deepholm Crystal", "TETRIS_PASS", 25, {0.62,0.30,0.90,1}, {0.30,0.74,0.92,1}, {0.38,0.18,0.58,1}, {0.040,0.025,0.060,1}, "Cavern crystal violet and elemental blue." },
    { "JADE_FOREST", "Jade Forest", "TETRIS_PASS", 35, {0.16,0.74,0.48,1}, {0.72,0.92,0.30,1}, {0.10,0.42,0.34,1}, {0.018,0.050,0.040,1}, "Jade green, bamboo shadow and misty gold." },
    { "IRON_HORDE", "Iron Horde", "TETRIS_PASS", 45, {0.78,0.28,0.12,1}, {0.48,0.48,0.46,1}, {0.28,0.12,0.08,1}, {0.050,0.028,0.018,1}, "Riveted iron, furnace red and war-machine bronze." },
    { "ARGUS_VOID", "Argus Void", "TETRIS_PASS", 55, {0.72,0.20,0.92,1}, {0.20,0.82,0.72,1}, {0.30,0.08,0.44,1}, {0.035,0.012,0.055,1}, "Fractured void arcs over alien worldstone." },
    { "Q3A_RED_ARENA", "Q3A Red Arena", "TETRIS_PASS", 65, {0.96,0.16,0.06,1}, {0.92,0.50,0.08,1}, {0.28,0.28,0.30,1}, {0.035,0.012,0.010,1}, "Industrial red arena plating and rocket glow." },
    { "Q3A_BLUE_ARENA", "Q3A Blue Arena", "TETRIS_PASS", 75, {0.12,0.52,1.00,1}, {0.30,0.84,1.00,1}, {0.24,0.24,0.30,1}, {0.010,0.024,0.045,1}, "Cold blue arena steel and rail-energy light." },
    { "ZERO_WING_CIRCUIT", "Zero Wing Circuit", "TETRIS_PASS", 85, {0.48,0.26,0.86,1}, {0.18,0.70,0.94,1}, {0.10,0.16,0.30,1}, {0.015,0.024,0.040,1}, "Retro circuit paths and deep-space violet." },
    { "CRESH_NEON_GRID", "Cresh Neon Grid", "TETRIS_PASS", 95, {0.02,0.76,1.00,1}, {1.00,0.82,0.18,1}, {0.72,0.20,1.00,1}, {0.005,0.025,0.045,1}, "A premium CreshChat neon grid and arcade glow." },
}
for _, row in ipairs(extraThemes) do
    if row[3] == "TETRIS_PASS" then Tetris.miniPassThemeRewards[row[4]] = row[1] end
    addTheme(row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9])
end

-- Fifty original pixel-art zone backgrounds. Each image is revealed in ten
-- ten-line sections in every solo, CPU and multiplayer Tetris format.
local zoneRevealThemes = {
    { "ZONE_ELWYNN_FOREST", "Elwynn Forest", {0.384,0.671,0.298,1}, {0.910,0.773,0.373,1}, {0.192,0.443,0.306,1}, {0.026,0.058,0.029,1}, "Elwynn Forest zone reveal background." },
    { "ZONE_WESTFALL", "Westfall", {0.906,0.761,0.298,1}, {0.494,0.290,0.153,1}, {0.341,0.545,0.231,1}, {0.106,0.082,0.033,1}, "Westfall zone reveal background." },
    { "ZONE_REDRIDGE_MOUNTAINS", "Redridge Mountains", {0.784,0.333,0.188,1}, {0.914,0.678,0.306,1}, {0.294,0.443,0.282,1}, {0.075,0.034,0.024,1}, "Redridge Mountains zone reveal background." },
    { "ZONE_DUSKWOOD", "Duskwood", {0.396,0.286,0.510,1}, {0.294,0.502,0.357,1}, {0.718,0.643,0.439,1}, {0.016,0.024,0.020,1}, "Duskwood zone reveal background." },
    { "ZONE_STRANGLETHORN_VALE", "Stranglethorn Vale", {0.196,0.604,0.341,1}, {0.902,0.733,0.267,1}, {0.125,0.424,0.455,1}, {0.016,0.051,0.031,1}, "Stranglethorn Vale zone reveal background." },
    { "ZONE_DEADWIND_PASS", "Deadwind Pass", {0.486,0.357,0.506,1}, {0.757,0.573,0.365,1}, {0.267,0.255,0.306,1}, {0.030,0.025,0.031,1}, "Deadwind Pass zone reveal background." },
    { "ZONE_SWAMP_OF_SORROWS", "Swamp of Sorrows", {0.314,0.596,0.349,1}, {0.373,0.718,0.647,1}, {0.580,0.463,0.282,1}, {0.021,0.043,0.034,1}, "Swamp of Sorrows zone reveal background." },
    { "ZONE_BLASTED_LANDS", "Blasted Lands", {0.792,0.286,0.192,1}, {0.878,0.573,0.247,1}, {0.404,0.208,0.337,1}, {0.059,0.029,0.023,1}, "Blasted Lands zone reveal background." },
    { "ZONE_DUN_MOROGH", "Dun Morogh", {0.875,0.949,0.965,1}, {0.369,0.592,0.706,1}, {0.294,0.365,0.427,1}, {0.072,0.091,0.099,1}, "Dun Morogh zone reveal background." },
    { "ZONE_LOCH_MODAN", "Loch Modan", {0.278,0.592,0.690,1}, {0.792,0.667,0.294,1}, {0.325,0.459,0.286,1}, {0.041,0.063,0.042,1}, "Loch Modan zone reveal background." },
    { "ZONE_WETLANDS", "Wetlands", {0.294,0.518,0.455,1}, {0.533,0.671,0.561,1}, {0.686,0.475,0.263,1}, {0.037,0.046,0.038,1}, "Wetlands zone reveal background." },
    { "ZONE_ARATHI_HIGHLANDS", "Arathi Highlands", {0.439,0.639,0.298,1}, {0.827,0.710,0.325,1}, {0.357,0.302,0.231,1}, {0.049,0.071,0.038,1}, "Arathi Highlands zone reveal background." },
    { "ZONE_HILLSBRAD_FOOTHILLS", "Hillsbrad Foothills", {0.424,0.706,0.337,1}, {0.890,0.792,0.420,1}, {0.259,0.392,0.278,1}, {0.039,0.080,0.042,1}, "Hillsbrad Foothills zone reveal background." },
    { "ZONE_ALTERAC_MOUNTAINS", "Alterac Mountains", {0.827,0.886,0.918,1}, {0.365,0.498,0.592,1}, {0.286,0.298,0.357,1}, {0.058,0.065,0.073,1}, "Alterac Mountains zone reveal background." },
    { "ZONE_SILVERPINE_FOREST", "Silverpine Forest", {0.365,0.459,0.576,1}, {0.588,0.635,0.694,1}, {0.267,0.396,0.329,1}, {0.017,0.032,0.035,1}, "Silverpine Forest zone reveal background." },
    { "ZONE_TIRISFAL_GLADES", "Tirisfal Glades", {0.435,0.553,0.294,1}, {0.471,0.357,0.553,1}, {0.757,0.682,0.416,1}, {0.029,0.038,0.030,1}, "Tirisfal Glades zone reveal background." },
    { "ZONE_EASTERN_PLAGUELANDS", "Eastern Plaguelands", {0.635,0.592,0.239,1}, {0.776,0.490,0.224,1}, {0.376,0.443,0.247,1}, {0.059,0.045,0.028,1}, "Eastern Plaguelands zone reveal background." },
    { "ZONE_WESTERN_PLAGUELANDS", "Western Plaguelands", {0.608,0.573,0.271,1}, {0.678,0.400,0.212,1}, {0.345,0.420,0.267,1}, {0.053,0.047,0.029,1}, "Western Plaguelands zone reveal background." },
    { "ZONE_THE_HINTERLANDS", "The Hinterlands", {0.290,0.569,0.306,1}, {0.824,0.698,0.294,1}, {0.235,0.412,0.408,1}, {0.026,0.058,0.035,1}, "The Hinterlands zone reveal background." },
    { "ZONE_SEARING_GORGE", "Searing Gorge", {0.910,0.325,0.110,1}, {0.961,0.600,0.176,1}, {0.349,0.290,0.267,1}, {0.037,0.026,0.024,1}, "Searing Gorge zone reveal background." },
    { "ZONE_BURNING_STEPPES", "Burning Steppes", {0.922,0.216,0.098,1}, {0.961,0.514,0.137,1}, {0.369,0.220,0.196,1}, {0.033,0.023,0.021,1}, "Burning Steppes zone reveal background." },
    { "ZONE_BADLANDS", "Badlands", {0.804,0.478,0.224,1}, {0.898,0.694,0.310,1}, {0.408,0.278,0.208,1}, {0.088,0.051,0.028,1}, "Badlands zone reveal background." },
    { "ZONE_TANARIS", "Tanaris", {0.949,0.784,0.357,1}, {0.498,0.361,0.227,1}, {0.298,0.561,0.608,1}, {0.127,0.095,0.043,1}, "Tanaris zone reveal background." },
    { "ZONE_UNGORO_CRATER", "Un'Goro Crater", {0.208,0.694,0.325,1}, {0.925,0.804,0.286,1}, {0.176,0.455,0.463,1}, {0.018,0.064,0.033,1}, "Un'Goro Crater zone reveal background." },
    { "ZONE_SILITHUS", "Silithus", {0.753,0.357,0.745,1}, {0.878,0.694,0.314,1}, {0.325,0.306,0.486,1}, {0.109,0.079,0.039,1}, "Silithus zone reveal background." },
    { "ZONE_FERALAS", "Feralas", {0.216,0.569,0.369,1}, {0.671,0.600,0.404,1}, {0.294,0.435,0.467,1}, {0.017,0.052,0.035,1}, "Feralas zone reveal background." },
    { "ZONE_DESOLACE", "Desolace", {0.549,0.357,0.557,1}, {0.765,0.510,0.357,1}, {0.306,0.376,0.349,1}, {0.066,0.047,0.048,1}, "Desolace zone reveal background." },
    { "ZONE_STONETALON_MOUNTAINS", "Stonetalon Mountains", {0.584,0.357,0.243,1}, {0.733,0.592,0.314,1}, {0.247,0.427,0.314,1}, {0.056,0.046,0.039,1}, "Stonetalon Mountains zone reveal background." },
    { "ZONE_ASHENVALE", "Ashenvale", {0.318,0.475,0.557,1}, {0.616,0.545,0.745,1}, {0.263,0.498,0.318,1}, {0.015,0.045,0.036,1}, "Ashenvale zone reveal background." },
    { "ZONE_DARKSHORE", "Darkshore", {0.298,0.482,0.580,1}, {0.592,0.604,0.663,1}, {0.255,0.361,0.290,1}, {0.025,0.043,0.045,1}, "Darkshore zone reveal background." },
    { "ZONE_MOONGLADE", "Moonglade", {0.365,0.643,0.600,1}, {0.702,0.729,0.890,1}, {0.373,0.475,0.663,1}, {0.019,0.055,0.042,1}, "Moonglade zone reveal background." },
    { "ZONE_WINTERSPRING", "Winterspring", {0.863,0.941,0.969,1}, {0.439,0.675,0.769,1}, {0.302,0.435,0.494,1}, {0.073,0.092,0.102,1}, "Winterspring zone reveal background." },
    { "ZONE_FELWOOD", "Felwood", {0.369,0.671,0.267,1}, {0.447,0.294,0.553,1}, {0.659,0.518,0.275,1}, {0.020,0.038,0.028,1}, "Felwood zone reveal background." },
    { "ZONE_AZSHARA", "Azshara", {0.796,0.506,0.196,1}, {0.859,0.694,0.302,1}, {0.275,0.502,0.557,1}, {0.058,0.051,0.034,1}, "Azshara zone reveal background." },
    { "ZONE_THE_BARRENS", "The Barrens", {0.871,0.596,0.239,1}, {0.404,0.482,0.239,1}, {0.439,0.282,0.192,1}, {0.104,0.066,0.031,1}, "The Barrens zone reveal background." },
    { "ZONE_THOUSAND_NEEDLES", "Thousand Needles", {0.800,0.478,0.243,1}, {0.902,0.686,0.322,1}, {0.353,0.278,0.231,1}, {0.091,0.051,0.031,1}, "Thousand Needles zone reveal background." },
    { "ZONE_MULGORE", "Mulgore", {0.416,0.718,0.333,1}, {0.878,0.753,0.353,1}, {0.400,0.314,0.212,1}, {0.039,0.080,0.040,1}, "Mulgore zone reveal background." },
    { "ZONE_DUROTAR", "Durotar", {0.824,0.337,0.173,1}, {0.906,0.588,0.259,1}, {0.337,0.278,0.220,1}, {0.095,0.041,0.024,1}, "Durotar zone reveal background." },
    { "ZONE_HELLFIRE_PENINSULA", "Hellfire Peninsula", {0.906,0.275,0.133,1}, {0.424,0.706,0.224,1}, {0.706,0.478,0.200,1}, {0.067,0.031,0.024,1}, "Hellfire Peninsula zone reveal background." },
    { "ZONE_ZANGARMARSH", "Zangarmarsh", {0.318,0.757,0.671,1}, {0.592,0.341,0.761,1}, {0.322,0.514,0.690,1}, {0.016,0.046,0.044,1}, "Zangarmarsh zone reveal background." },
    { "ZONE_TEROKKAR_FOREST", "Terokkar Forest", {0.408,0.576,0.510,1}, {0.592,0.475,0.706,1}, {0.365,0.541,0.639,1}, {0.027,0.051,0.044,1}, "Terokkar Forest zone reveal background." },
    { "ZONE_NAGRAND", "Nagrand", {0.439,0.780,0.333,1}, {0.886,0.804,0.369,1}, {0.369,0.341,0.259,1}, {0.042,0.092,0.043,1}, "Nagrand zone reveal background." },
    { "ZONE_BLADES_EDGE_MOUNTAINS", "Blade's Edge Mountains", {0.745,0.325,0.212,1}, {0.827,0.557,0.263,1}, {0.349,0.278,0.337,1}, {0.058,0.033,0.029,1}, "Blade's Edge Mountains zone reveal background." },
    { "ZONE_NETHERSTORM", "Netherstorm", {0.631,0.286,0.835,1}, {0.255,0.690,0.863,1}, {0.871,0.408,0.737,1}, {0.026,0.018,0.044,1}, "Netherstorm zone reveal background." },
    { "ZONE_SHADOWMOON_VALLEY", "Shadowmoon Valley", {0.357,0.792,0.231,1}, {0.525,0.282,0.678,1}, {0.243,0.490,0.478,1}, {0.019,0.025,0.029,1}, "Shadowmoon Valley zone reveal background." },
    { "ZONE_EVERSONG_WOODS", "Eversong Woods", {0.863,0.561,0.188,1}, {0.808,0.255,0.208,1}, {0.914,0.773,0.369,1}, {0.067,0.049,0.029,1}, "Eversong Woods zone reveal background." },
    { "ZONE_GHOSTLANDS", "Ghostlands", {0.702,0.325,0.259,1}, {0.502,0.286,0.557,1}, {0.796,0.616,0.298,1}, {0.048,0.035,0.031,1}, "Ghostlands zone reveal background." },
    { "ZONE_AZUREMYST_ISLE", "Azuremyst Isle", {0.353,0.663,0.792,1}, {0.545,0.392,0.847,1}, {0.820,0.749,0.400,1}, {0.033,0.065,0.061,1}, "Azuremyst Isle zone reveal background." },
    { "ZONE_BLOODMYST_ISLE", "Bloodmyst Isle", {0.773,0.263,0.298,1}, {0.506,0.302,0.686,1}, {0.804,0.533,0.278,1}, {0.059,0.031,0.036,1}, "Bloodmyst Isle zone reveal background." },
    { "ZONE_ISLE_OF_QUELDANAS", "Isle of Quel'Danas", {0.965,0.784,0.298,1}, {0.875,0.365,0.192,1}, {0.435,0.667,0.725,1}, {0.073,0.065,0.045,1}, "Isle of Quel'Danas zone reveal background." },
}
for _, row in ipairs(zoneRevealThemes) do
    addBackground(row[1], row[2], "BACKGROUND_REVEAL", 100, row[3], row[4], row[5], row[6], row[7], TETRIS_BACKGROUND_ROOT .. row[1] .. ".tga")
end

function Tetris:GetTheme(key)
    return self.themes[upper(tostring(key or "CLASSIC_BLOCKS"))] or self.themes.CLASSIC_BLOCKS
end

function Tetris:GetBackground(key)
    key = upper(tostring(key or ""))
    return self.backgrounds[key]
end

function Tetris:GetThemeCount()
    return #self.themeOrder
end

function Tetris:GetBackgroundThemeCount()
    return #self.backgroundOrder
end

function Tetris:GetUnlockedBackgroundCount()
    local save = self:Ensure()
    local count = 0
    for _, key in ipairs(self.backgroundOrder) do
        if save and save.unlockedBackgrounds[key] then count = count + 1 end
    end
    return count
end

function Tetris:GetBackgroundCatalog(filter)
    filter = upper(tostring(filter or "ALL"))
    if filter ~= "UNLOCKED" and filter ~= "LOCKED" then filter = "ALL" end
    local save = self:Ensure()
    local output = {}
    for _, key in ipairs(self.backgroundOrder) do
        local background = self.backgrounds[key]
        local unlocked = save and save.unlockedBackgrounds[key] == true or false
        if background and (filter == "ALL" or (filter == "UNLOCKED" and unlocked) or (filter == "LOCKED" and not unlocked)) then
            output[#output + 1] = background
        end
    end
    return output
end

function Tetris:GetGameLevel(lines)
    lines = floor(max(0, tonumber(lines) or 0))
    return min(self.maxGameLevel or 1000, 1 + floor(lines / max(1, self.linesPerGameLevel or 10)))
end

function Tetris:GetDropInterval(lines)
    local level = self:GetGameLevel(lines)
    local maxLevel = max(2, self.maxGameLevel or 1000)
    local progress = clamp((level - 1) / (maxLevel - 1), 0, 1)
    local reference = 1 + progress * (#GUIDELINE_GRAVITY - 1)
    local lower = floor(reference)
    local upperIndex = min(#GUIDELINE_GRAVITY, lower + 1)
    local blendAmount = reference - lower
    lower = max(1, min(#GUIDELINE_GRAVITY, lower))
    local lowGravity = GUIDELINE_GRAVITY[lower]
    local highGravity = GUIDELINE_GRAVITY[upperIndex]
    local gravity = math.exp(math.log(lowGravity) * (1 - blendAmount) + math.log(highGravity) * blendAmount)
    local normalized = clamp((math.log(gravity) - math.log(GUIDELINE_GRAVITY[1])) /
        (math.log(GUIDELINE_GRAVITY[#GUIDELINE_GRAVITY]) - math.log(GUIDELINE_GRAVITY[1])), 0, 1)
    return START_DROP_INTERVAL * ((FINAL_DROP_INTERVAL / START_DROP_INTERVAL) ^ normalized), level
end

function Tetris:GetPassNextCost(level)
    level = floor(clamp(level, 1, self.maxPassLevel))
    return 35 + floor((level - 1) * 2.5)
end

function Tetris:GetPassCumulativeXP(level)
    level = floor(clamp(level, 1, self.maxPassLevel))
    local total = 0
    for current = 1, level - 1 do total = total + self:GetPassNextCost(current) end
    return total
end

function Tetris:GetPassLevelFromXP(xp)
    xp = floor(max(0, tonumber(xp) or 0))
    local level = 1
    while level < self.maxPassLevel and xp >= self:GetPassCumulativeXP(level + 1) do level = level + 1 end
    return level
end

function Tetris:GetPassProgress()
    local save = self:Ensure()
    if not save then return 1, 0, 35, 0 end
    local level = self:GetPassLevelFromXP(save.passXP)
    if level >= self.maxPassLevel then return level, 1, 1, 1 end
    local base = self:GetPassCumulativeXP(level)
    local required = self:GetPassNextCost(level)
    local current = max(0, save.passXP - base)
    return level, current, required, clamp(current / max(1, required), 0, 1)
end

function Tetris:GetPassReward(level)
    level = floor(clamp(level, 1, self.maxPassLevel))
    local coins
    if level == 100 then coins = 200
    elseif level % 10 == 0 then coins = 50 + level
    elseif level % 5 == 0 then coins = 25 + floor(level / 2)
    else coins = 8 + floor((level - 1) / 10) * 2 end
    local themeKey = self.miniPassThemeRewards[level]
    local theme = themeKey and self.themes[themeKey] or nil
    return {
        level = level,
        coins = coins,
        themeKey = themeKey,
        themeName = theme and theme.name or nil,
        title = level == 100 and "Tetris Grandmaster" or (theme and "Theme Cache" or "Block Cache"),
    }
end

function Tetris:Ensure()
    if not CC.db then return nil end
    CC.db.soloGames = type(CC.db.soloGames) == "table" and CC.db.soloGames or {}
    CC.db.soloGames.tetris = type(CC.db.soloGames.tetris) == "table" and CC.db.soloGames.tetris or {}
    local save = CC.db.soloGames.tetris
    save.wins = floor(max(0, tonumber(save.wins) or 0))
    save.losses = floor(max(0, tonumber(save.losses) or 0))
    save.games = floor(max(save.wins + save.losses, tonumber(save.games) or 0))
    save.highScore = floor(max(0, tonumber(save.highScore) or 0))
    save.bestLines = floor(max(0, tonumber(save.bestLines) or 0))
    save.totalLines = floor(max(save.bestLines, tonumber(save.totalLines) or 0))
    save.vsWins = floor(max(0, tonumber(save.vsWins) or 0))
    save.vsLosses = floor(max(0, tonumber(save.vsLosses) or 0))
    save.endlessRuns = floor(max(0, tonumber(save.endlessRuns) or 0))
    save.cpuLevel = floor(clamp(save.cpuLevel or 3, 1, 5))
    save.cpuVersusMode = upper(tostring(save.cpuVersusMode or "ENDLESS"))
    if save.cpuVersusMode ~= "ATTACK" then save.cpuVersusMode = "ENDLESS" end
    save.multiplayerMode = upper(tostring(save.multiplayerMode or "ENDLESS"))
    if save.multiplayerMode ~= "ATTACK" then save.multiplayerMode = "ENDLESS" end
    local allowedDuration = { [5]=true, [10]=true, [15]=true, [30]=true, [45]=true, [60]=true }
    save.multiplayerDuration = floor(clamp(save.multiplayerDuration or 10, 5, 60))
    if not allowedDuration[save.multiplayerDuration] then save.multiplayerDuration = 10 end
    save.soloDuration = floor(clamp(save.soloDuration or 10, 5, 60))
    if not allowedDuration[save.soloDuration] then save.soloDuration = 10 end
    save.mode = upper(tostring(save.mode or "ENDLESS"))
    if save.mode ~= "CPU" and save.mode ~= "ENDLESS" then save.mode = "ENDLESS" end

    save.revealLines = floor(clamp(save.revealLines or 0, 0, 100))
    save.revealCompleted = floor(max(0, tonumber(save.revealCompleted) or 0))
    save.passXP = floor(max(0, tonumber(save.passXP) or 0))
    save.passClaimed = type(save.passClaimed) == "table" and save.passClaimed or {}

    save.unlockedThemes = type(save.unlockedThemes) == "table" and save.unlockedThemes or {}
    save.themeUnlockSources = type(save.themeUnlockSources) == "table" and save.themeUnlockSources or {}
    save.unlockedBackgrounds = type(save.unlockedBackgrounds) == "table" and save.unlockedBackgrounds or {}
    save.backgroundUnlockSources = type(save.backgroundUnlockSources) == "table" and save.backgroundUnlockSources or {}

    -- v0.3.68 migration: older builds stored image backgrounds inside the
    -- block-theme registry. Move those keys into the independent background save.
    for _, key in ipairs(self.backgroundOrder) do
        if save.unlockedThemes[key] then
            save.unlockedBackgrounds[key] = true
            save.backgroundUnlockSources[key] = save.backgroundUnlockSources[key] or save.themeUnlockSources[key] or "MIGRATED"
        end
    end

    save.selectedTheme = upper(tostring(save.selectedTheme or "CLASSIC_BLOCKS"))
    if self.backgrounds[save.selectedTheme] then
        save.selectedBackground = save.selectedBackground or save.selectedTheme
        save.selectedTheme = "CLASSIC_BLOCKS"
    end
    save.selectedBackground = upper(tostring(save.selectedBackground or ""))
    save.revealBackgroundKey = upper(tostring(save.revealBackgroundKey or save.revealThemeKey or ""))
    save.revealThemeKey = save.revealBackgroundKey -- compatibility for older releases

    save.unlockedThemes.CLASSIC_BLOCKS = true
    save.themeUnlockSources.CLASSIC_BLOCKS = save.themeUnlockSources.CLASSIC_BLOCKS or "DEFAULT"
    self:SyncUnlocks(false)

    if not save.unlockedThemes[save.selectedTheme] or not self.themes[save.selectedTheme] then save.selectedTheme = "CLASSIC_BLOCKS" end
    if save.selectedBackground ~= "" and (not self.backgrounds[save.selectedBackground] or not save.unlockedBackgrounds[save.selectedBackground]) then
        save.selectedBackground = ""
    end
    if save.selectedBackground == "" then
        for _, key in ipairs(self.backgroundOrder) do
            if save.unlockedBackgrounds[key] then save.selectedBackground = key; break end
        end
    end
    return save
end

function Tetris:UnlockTheme(key, source, showToast, suppressRefresh)
    key = upper(tostring(key or ""))
    local theme = self.themes[key]
    if not theme or not CC.db then return false end
    CC.db.soloGames = type(CC.db.soloGames) == "table" and CC.db.soloGames or {}
    CC.db.soloGames.tetris = type(CC.db.soloGames.tetris) == "table" and CC.db.soloGames.tetris or {}
    local save = CC.db.soloGames.tetris
    save.unlockedThemes = type(save.unlockedThemes) == "table" and save.unlockedThemes or {}
    save.themeUnlockSources = type(save.themeUnlockSources) == "table" and save.themeUnlockSources or {}
    if save.unlockedThemes[key] then return false end
    save.unlockedThemes[key] = true
    save.themeUnlockSources[key] = tostring(source or theme.source or "UNLOCK")
    if showToast and CC.UI and CC.UI.ShowGameToast then
        CC.UI:ShowGameToast("Tetris Block Theme Unlocked", theme.name .. " · open Tetris > Block Themes to equip", "SUCCESS", "TETRIS:THEME:" .. tostring(key))
    end
    if not suppressRefresh and CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels() end
    return true
end

function Tetris:SyncUnlocks(showToast)
    if not CC.db or not CC.db.soloGames or not CC.db.soloGames.tetris then return 0 end
    local save = CC.db.soloGames.tetris
    save.unlockedThemes = type(save.unlockedThemes) == "table" and save.unlockedThemes or {}
    save.themeUnlockSources = type(save.themeUnlockSources) == "table" and save.themeUnlockSources or {}
    save.passClaimed = type(save.passClaimed) == "table" and save.passClaimed or {}
    local unlocked = 0
    local gameLevel = 1
    if CC.GameProgression and CC.GameProgression.GetProgress then gameLevel = select(1, CC.GameProgression:GetProgress("TETRIS")) or 1 end
    for _, key in ipairs(self.themeOrder) do
        local theme = self.themes[key]
        if theme.source == "GAME_LEVEL" and gameLevel >= (theme.requirement or 1) then
            if self:UnlockTheme(key, "TETRIS_LEVEL:" .. tostring(theme.requirement), showToast, true) then unlocked = unlocked + 1 end
        end
    end
    for level, key in pairs(self.miniPassThemeRewards) do
        if save.passClaimed[tostring(level)] then
            if self:UnlockTheme(key, "TETRIS_PASS:" .. tostring(level), false, true) then unlocked = unlocked + 1 end
        end
    end
    local mainClaimed = CC.db.arcadeRewards and CC.db.arcadeRewards.claimed or {}
    for level, key in pairs(self.mainPassThemeRewards) do
        if mainClaimed[tostring(level)] then
            if self:UnlockTheme(key, "MAIN_PASS:" .. tostring(level), false, true) then unlocked = unlocked + 1 end
        end
    end
    if unlocked > 0 and CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels() end
    return unlocked
end

function Tetris:IsThemeUnlocked(key)
    local save = self:Ensure()
    key = upper(tostring(key or ""))
    return save and save.unlockedThemes[key] == true or false
end

function Tetris:GetSelectedTheme()
    local save = self:Ensure()
    return self:GetTheme(save and save.selectedTheme or "CLASSIC_BLOCKS")
end

function Tetris:SelectTheme(key)
    local save = self:Ensure()
    key = upper(tostring(key or ""))
    if not save or not self.themes[key] or not save.unlockedThemes[key] then return false end
    save.selectedTheme = key
    if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
    if CC.Games and CC.Games.gameViews and CC.Games.gameViews.TETRIS and CC.Games.gameViews.TETRIS.Refresh then CC.Games.gameViews.TETRIS:Refresh() end
    return true
end

function Tetris:GetThemeRequirementText(key)
    local theme = self:GetTheme(key)
    if theme.source == "DEFAULT" then return "Included"
    elseif theme.source == "GAME_LEVEL" then return "Tetris game level " .. tostring(theme.requirement)
    elseif theme.source == "TETRIS_PASS" then return "Tetris Pass level " .. tostring(theme.requirement)
    elseif theme.source == "MAIN_PASS" then return "Main Battle Pass level " .. tostring(theme.requirement) end
    return "Locked"
end

function Tetris:UnlockBackground(key, source, showToast, suppressRefresh)
    key = upper(tostring(key or ""))
    local background = self.backgrounds[key]
    if not background or not CC.db then return false end
    local save = self:Ensure()
    if not save or save.unlockedBackgrounds[key] then return false end
    save.unlockedBackgrounds[key] = true
    save.backgroundUnlockSources[key] = tostring(source or background.source or "BACKGROUND_REVEAL")
    if save.selectedBackground == "" then save.selectedBackground = key end
    if showToast and CC.UI and CC.UI.ShowGameToast then
        CC.UI:ShowGameToast("Tetris Image Unlocked", background.name .. " · open Tetris > Backgrounds to preview", "SUCCESS", "TETRIS:IMAGE:" .. tostring(key))
    end
    if not suppressRefresh and CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
    return true
end

function Tetris:IsBackgroundUnlocked(key)
    local save = self:Ensure()
    key = upper(tostring(key or ""))
    return save and save.unlockedBackgrounds[key] == true or false
end

function Tetris:GetSelectedBackground()
    local save = self:Ensure()
    if not save then return nil end
    local selected = self.backgrounds[save.selectedBackground or ""]
    if selected and save.unlockedBackgrounds[selected.key] then return selected end
    for _, key in ipairs(self.backgroundOrder) do
        if save.unlockedBackgrounds[key] then return self.backgrounds[key] end
    end
    return nil
end

function Tetris:SelectBackground(key)
    local save = self:Ensure()
    key = upper(tostring(key or ""))
    if not save or not self.backgrounds[key] or not save.unlockedBackgrounds[key] then return false end
    save.selectedBackground = key
    if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
    if CC.Games and CC.Games.gameViews and CC.Games.gameViews.TETRIS and CC.Games.gameViews.TETRIS.Refresh then CC.Games.gameViews.TETRIS:Refresh() end
    return true
end

function Tetris:GetBackgroundRequirementText(key)
    local background = self:GetBackground(key)
    if not background then return "Unavailable" end
    return "Reveal in any Tetris mode · 100 cumulative lines"
end

function Tetris:GetRevealBackground()
    local save = self:Ensure()
    if not save then return nil, 0, 0, false end
    local carriedLines = floor(clamp(save.revealLines or 0, 0, 99))
    local current = self.backgrounds[save.revealBackgroundKey or ""]
    if not current or save.unlockedBackgrounds[current.key] then
        current = nil
        for _, key in ipairs(self.backgroundOrder) do
            if not save.unlockedBackgrounds[key] then current = self.backgrounds[key]; break end
        end
        if current then
            save.revealBackgroundKey = current.key
            save.revealThemeKey = current.key
            -- Preserve partial progress when migrating from a retired block-texture
            -- background. Normal completions already set revealLines to zero.
            save.revealLines = carriedLines
        else
            current = self:GetSelectedBackground()
            save.revealBackgroundKey = current and current.key or ""
            save.revealThemeKey = save.revealBackgroundKey
            return current, current and 100 or 0, current and 1 or 0, false
        end
    end
    local lines = floor(max(0, tonumber(save.revealLines) or 0))
    return current, lines, clamp(lines / 100, 0, 1), current and not save.unlockedBackgrounds[current.key]
end

-- Compatibility name retained for multiplayer messages from v0.3.64-v0.3.67.
function Tetris:GetRevealTheme()
    return self:GetRevealBackground()
end

function Tetris:AddRevealLines(amount)
    local save = self:Ensure()
    amount = floor(max(0, tonumber(amount) or 0))
    if not save or amount <= 0 then return false, nil, 0 end
    local background = self:GetRevealBackground()
    if not background or save.unlockedBackgrounds[background.key] then return false, background, 0 end
    local oldStage = floor((save.revealLines or 0) / 10)
    save.revealLines = min(100, (save.revealLines or 0) + amount)
    local newStage = floor((save.revealLines or 0) / 10)
    local completed = save.revealLines >= 100
    if completed then
        self:UnlockBackground(background.key, "BACKGROUND_REVEAL:100", true, true)
        save.revealCompleted = (save.revealCompleted or 0) + 1
        save.revealBackgroundKey = ""
        save.revealThemeKey = ""
        save.revealLines = 0
        if CC.GameAudio and CC.GameAudio.PlayEffect then CC.GameAudio:PlayEffect("REVEAL") end
        if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
        return true, background, 10
    end
    if newStage > oldStage and CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
    return false, background, newStage
end

function Tetris:GetRevealProgress()
    local background, lines, fraction, revealing = self:GetRevealBackground()
    lines = floor(clamp(lines or 0, 0, 100))
    local stage = floor(lines / 10)
    local nextPart = revealing and (stage >= 10 and 0 or (10 - (lines % 10))) or 0
    local toUnlock = revealing and max(0, 100 - lines) or 0
    return background, lines, stage, nextPart, toUnlock, fraction, revealing
end

function Tetris:GetRevealOpacity()
    local _, _, stage = self:GetRevealProgress()
    return min(0.72, 0.50 + stage * 0.022), stage
end

function Tetris:GetUnlockedCount()
    local save = self:Ensure()
    local count = 0
    for _, key in ipairs(self.themeOrder) do if save and save.unlockedThemes[key] then count = count + 1 end end
    return count
end

function Tetris:GetPieceColor(piece)
    local theme = self:GetSelectedTheme()
    return theme.colors[upper(tostring(piece or "I"))] or theme.colors.I
end

function Tetris:GetGuideColor()
    return self:GetSelectedTheme().guide
end

function Tetris:GetBackgroundColor()
    return self:GetSelectedTheme().background
end

function Tetris:GetHighlightColor()
    return self:GetSelectedTheme().highlight
end

function Tetris:IsPassLevelReached(level)
    local save = self:Ensure()
    return save and save.passXP >= self:GetPassCumulativeXP(level) or false
end

function Tetris:IsPassRewardClaimed(level)
    local save = self:Ensure()
    return save and save.passClaimed[tostring(level)] == true or false
end

function Tetris:AddPassXP(amount, source)
    local save = self:Ensure()
    amount = floor(max(0, tonumber(amount) or 0))
    if not save or amount <= 0 then return 0 end
    local oldLevel = self:GetPassLevelFromXP(save.passXP)
    save.passXP = save.passXP + amount
    local newLevel = self:GetPassLevelFromXP(save.passXP)
    if newLevel > oldLevel and CC.UI and CC.UI.ShowGameToast then
        CC.UI:ShowGameToast("Tetris Pass Level " .. tostring(newLevel), "+" .. tostring(amount) .. " Tetris XP · reward ready", "SUCCESS", "TETRIS:PASSLEVEL:" .. tostring(newLevel))
    end
    if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels() end
    return amount, oldLevel, newLevel
end

function Tetris:ClaimPassReward(level, silent)
    local save = self:Ensure()
    level = floor(clamp(level, 1, self.maxPassLevel))
    if not save or not self:IsPassLevelReached(level) or save.passClaimed[tostring(level)] then return false end
    local reward = self:GetPassReward(level)
    save.passClaimed[tostring(level)] = true
    if CC.BattlePass and CC.BattlePass.AddCoins then CC.BattlePass:AddCoins(reward.coins, "GAME") end
    if reward.themeKey then self:UnlockTheme(reward.themeKey, "TETRIS_PASS:" .. tostring(level), not silent, true) end
    if not silent and CC.UI and CC.UI.ShowGameToast then
        local extra = reward.themeName and (" · " .. reward.themeName) or ""
        CC.UI:ShowGameToast("Tetris Pass Reward", "Level " .. level .. " · +" .. reward.coins .. " Cresh Coins" .. extra, "SUCCESS", "TETRIS:PASSREWARD:" .. tostring(level))
    end
    if not silent and CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
    return true
end

function Tetris:ClaimAllPassRewards()
    local claimed, coins = 0, 0
    for level = 1, self.maxPassLevel do
        if self:IsPassLevelReached(level) and not self:IsPassRewardClaimed(level) then
            local reward = self:GetPassReward(level)
            if self:ClaimPassReward(level, true) then claimed = claimed + 1; coins = coins + reward.coins end
        end
    end
    if claimed > 0 and CC.UI and CC.UI.ShowGameToast then
        CC.UI:ShowGameToast("Tetris Pass", tostring(claimed) .. " rewards · +" .. tostring(coins) .. " Cresh Coins", "SUCCESS", "TETRIS:CLAIMALL:" .. tostring(time()))
    elseif claimed == 0 and CC.Print then
        CC:Print("No Tetris Pass rewards are ready to claim.")
    end
    if CC.SoloGames and CC.SoloGames.RefreshTetrisPanels then CC.SoloGames:RefreshTetrisPanels(true) end
    return claimed, coins
end

function Tetris:AwardRun(result, mode, score, lines)
    result = upper(tostring(result or "RUN"))
    mode = upper(tostring(mode or "CLASSIC"))
    score = floor(max(0, tonumber(score) or 0))
    lines = floor(max(0, tonumber(lines) or 0))
    local xp = 12 + min(40, lines * 3) + min(25, floor(score / 400))
    if result == "WIN" then xp = xp + 22 elseif result == "LOSS" then xp = xp + 8 else xp = xp + 12 end
    if mode == "CPU" then xp = floor(xp * 1.35) elseif mode == "ENDLESS" then xp = xp + min(25, lines) end
    return self:AddPassXP(xp, "TETRIS RUN")
end

function Tetris:GetCatalog()
    local output = {}
    for _, key in ipairs(self.themeOrder) do output[#output + 1] = self.themes[key] end
    return output
end
