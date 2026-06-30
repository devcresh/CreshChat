local _, CC = ...

-- Dungeon Crawler content library.
-- Texture pack v4.0 is live for expansion enemies, active-class armour, milestone chests and reward icons.
-- All milestone bosses now use integrated art; reserved future Druid/Shaman armour keeps stable placeholder paths until supplied.

local ROOT = "Interface\\AddOns\\CreshGames\\Media\\Games\\DungeonDwellers"

local Content = {
    version = CC and CC.version or "0.3.63-account-friends",
    placeholderArt = true, -- reserved future Druid/Shaman armour placeholders remain
    assetPack = {
        name = "DungeonCrawler Enemies, Class Armor, Chests & Rewards",
        version = "4.0",
        liveEnemyCount = 20,
        liveArmourCount = 40,
        liveMilestoneChestCount = 5,
        liveRewardIconCount = 5,
    },
    enemyBalance = {
        version = 2,
        health = {
            base = 5,
            linearNumerator = 3,
            linearDivisor = 2,
            quadraticDivisor = 70,
            overLevel = 100,
            overQuadraticDivisor = 180,
            variancePercent = 8,
        },
        attack = {
            base = 1,
            linearDivisor = 6,
            quadraticDivisor = 650,
            overLevel = 120,
            overLinearDivisor = 10,
            variancePercent = 7,
        },
        boss = {
            healthMultiplier = 2,
            flatHealth = 5,
            healthPerFiveLevels = 2,
            flatAttack = 1,
            attackTierDivisor = 3,
        },
    },
    enemyOrder = {
        "KOBOLD_MINER",
        "GNOLL_BRUTE",
        "MURLOC_TIDECALLER",
        "NAGA_SIREN",
        "TROGG_EARTHSHAKER",
        "HARPY_STORMTALON",
        "SATYR_FELWHISPER",
        "NERUBIAN_WEBWARDEN",
        "FROST_REVENANT",
        "DARK_IRON_BOMBARDIER",
        "ETHEREAL_PHASEBLADE",
        "ARAKKOA_WINDSEER",
        "BROKEN_SOULBINDER",
        "BLOOD_ELF_SPELLBREAKER",
        "FEL_ORC_BERSERKER",
        "BOG_BEAST",
        "MANA_WYRM",
        "CLOCKWORK_REAVER",
        "ARENA_GLADIATOR",
        "ZERO_WING_DRONE",
    },
    enemies = {
        KOBOLD_MINER = {
            key = "KOBOLD_MINER", assetKey = "KoboldMiner", type = "Kobold Miner", name = "Candlewick Tunnel Rat",
            minLevel = 1, maxLevel = 39, weight = 10, hpMultiplier = 0.90, attackBonus = 0,
            abilityKey = "CANDLE_SNATCH", abilityName = "Candle Snatch", abilityDescription = "Steals one upgrade point unless defeated quickly.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_KoboldMiner_CandlewickTunnelRat.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_KoboldMiner_CandlewickTunnelRat.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        GNOLL_BRUTE = {
            key = "GNOLL_BRUTE", assetKey = "GnollBrute", type = "Gnoll Brute", name = "Redtooth Mauler",
            minLevel = 1, maxLevel = 39, weight = 10, hpMultiplier = 1.25, attackBonus = 1,
            abilityKey = "HEAVY_SWING", abilityName = "Heavy Swing", abilityDescription = "Prepares a heavy attack every third enemy turn.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_GnollBrute_RedtoothMauler.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_GnollBrute_RedtoothMauler.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        MURLOC_TIDECALLER = {
            key = "MURLOC_TIDECALLER", assetKey = "MurlocTidecaller", type = "Murloc Tidecaller", name = "Glubfin the Loud",
            minLevel = 1, maxLevel = 39, weight = 9, hpMultiplier = 0.95, attackBonus = 0,
            abilityKey = "TIDAL_MENDING", abilityName = "Tidal Mending", abilityDescription = "Can heal another living enemy.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_MurlocTidecaller_GlubfintheLoud.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_MurlocTidecaller_GlubfintheLoud.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        NAGA_SIREN = {
            key = "NAGA_SIREN", assetKey = "NagaSiren", type = "Naga Siren", name = "Coilscale Enchantress",
            minLevel = 1, maxLevel = 39, weight = 8, hpMultiplier = 1.00, attackBonus = 0,
            abilityKey = "SIREN_SONG", abilityName = "Siren Song", abilityDescription = "Reduces the player's next attack roll.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_NagaSiren_CoilscaleEnchantress.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_NagaSiren_CoilscaleEnchantress.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        TROGG_EARTHSHAKER = {
            key = "TROGG_EARTHSHAKER", assetKey = "TroggEarthshaker", type = "Trogg Earthshaker", name = "Grumblefist",
            minLevel = 1, maxLevel = 39, weight = 8, hpMultiplier = 1.30, attackBonus = 1,
            abilityKey = "EARTHSHAKE", abilityName = "Earthshake", abilityDescription = "Damages the hero and recruited minions.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_TroggEarthshaker_Grumblefist.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_TroggEarthshaker_Grumblefist.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        HARPY_STORMTALON = {
            key = "HARPY_STORMTALON", assetKey = "HarpyStormtalon", type = "Harpy Stormtalon", name = "Screechwing Tempest",
            minLevel = 40, maxLevel = 79, weight = 10, hpMultiplier = 0.90, attackBonus = 0,
            abilityKey = "WIND_EVASION", abilityName = "Wind Evasion", abilityDescription = "Has a chance to evade incoming attacks.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_HarpyStormtalon_ScreechwingTempest.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_HarpyStormtalon_ScreechwingTempest.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        SATYR_FELWHISPER = {
            key = "SATYR_FELWHISPER", assetKey = "SatyrFelwhisper", type = "Satyr Felwhisper", name = "Xavros the Twisted",
            minLevel = 40, maxLevel = 79, weight = 9, hpMultiplier = 1.00, attackBonus = 1,
            abilityKey = "FEL_DRAIN", abilityName = "Fel Drain", abilityDescription = "Drains hero health and restores its own.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_SatyrFelwhisper_XavrostheTwisted.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_SatyrFelwhisper_XavrostheTwisted.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        NERUBIAN_WEBWARDEN = {
            key = "NERUBIAN_WEBWARDEN", assetKey = "NerubianWebwarden", type = "Nerubian Webwarden", name = "Cryptweb Binder",
            minLevel = 40, maxLevel = 79, weight = 9, hpMultiplier = 1.15, attackBonus = 0,
            abilityKey = "WEB_BIND", abilityName = "Web Bind", abilityDescription = "Prevents one minion from attacking for a turn.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_NerubianWebwarden_CryptwebBinder.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_NerubianWebwarden_CryptwebBinder.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        FROST_REVENANT = {
            key = "FROST_REVENANT", assetKey = "FrostRevenant", type = "Frost Revenant", name = "Coldgrave Watcher",
            minLevel = 40, maxLevel = 79, weight = 8, hpMultiplier = 1.10, attackBonus = 1,
            abilityKey = "CHILLING_TOUCH", abilityName = "Chilling Touch", abilityDescription = "Slows the hero and lowers the next roll.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_FrostRevenant_ColdgraveWatcher.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_FrostRevenant_ColdgraveWatcher.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        DARK_IRON_BOMBARDIER = {
            key = "DARK_IRON_BOMBARDIER", assetKey = "DarkIronBombardier", type = "Dark Iron Bombardier", name = "Fusebeard Demolitionist",
            minLevel = 40, maxLevel = 79, weight = 8, hpMultiplier = 1.00, attackBonus = 1,
            abilityKey = "TIMED_BOMB", abilityName = "Timed Bomb", abilityDescription = "Places a bomb that explodes after two turns.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_DarkIronBombardier_FusebeardDemolitionist.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_DarkIronBombardier_FusebeardDemolitionist.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        ETHEREAL_PHASEBLADE = {
            key = "ETHEREAL_PHASEBLADE", assetKey = "EtherealPhaseblade", type = "Ethereal Phaseblade", name = "Nexus Cutthroat",
            minLevel = 80, maxLevel = 119, weight = 10, hpMultiplier = 0.95, attackBonus = 1,
            abilityKey = "PHASE_SHIFT", abilityName = "Phase Shift", abilityDescription = "Temporarily phases out and cannot be targeted.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_EtherealPhaseblade_NexusCutthroat.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_EtherealPhaseblade_NexusCutthroat.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        ARAKKOA_WINDSEER = {
            key = "ARAKKOA_WINDSEER", assetKey = "ArakkoaWindseer", type = "Arakkoa Windseer", name = "Skyrend Prophet",
            minLevel = 80, maxLevel = 119, weight = 9, hpMultiplier = 1.00, attackBonus = 0,
            abilityKey = "WAR_WINDS", abilityName = "War Winds", abilityDescription = "Raises the attack of every living enemy.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_ArakkoaWindseer_SkyrendProphet.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_ArakkoaWindseer_SkyrendProphet.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        BROKEN_SOULBINDER = {
            key = "BROKEN_SOULBINDER", assetKey = "BrokenSoulbinder", type = "Broken Soulbinder", name = "Akoru the Forsaken",
            minLevel = 80, maxLevel = 119, weight = 8, hpMultiplier = 1.10, attackBonus = 0,
            abilityKey = "SOUL_RECALL", abilityName = "Soul Recall", abilityDescription = "Revives one defeated normal enemy.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_BrokenSoulbinder_AkorutheForsaken.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_BrokenSoulbinder_AkorutheForsaken.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        BLOOD_ELF_SPELLBREAKER = {
            key = "BLOOD_ELF_SPELLBREAKER", assetKey = "BloodElfSpellbreaker", type = "Blood Elf Spellbreaker", name = "Sunblade Disruptor",
            minLevel = 80, maxLevel = 119, weight = 9, hpMultiplier = 1.05, attackBonus = 1,
            abilityKey = "DISRUPT_MAGIC", abilityName = "Disrupt Magic", abilityDescription = "Removes one temporary hero bonus.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_BloodElfSpellbreaker_SunbladeDisruptor.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_BloodElfSpellbreaker_SunbladeDisruptor.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        FEL_ORC_BERSERKER = {
            key = "FEL_ORC_BERSERKER", assetKey = "FelOrcBerserker", type = "Fel Orc Berserker", name = "Maghar Bloodhowler",
            minLevel = 80, maxLevel = 119, weight = 8, hpMultiplier = 1.35, attackBonus = 1,
            abilityKey = "BLOOD_FRENZY", abilityName = "Blood Frenzy", abilityDescription = "Gains attack whenever another enemy dies.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_FelOrcBerserker_HellfireBloodhowler.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_FelOrcBerserker_HellfireBloodhowler.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        BOG_BEAST = {
            key = "BOG_BEAST", assetKey = "BogBeast", type = "Bog Beast", name = "Marshroot Ancient",
            minLevel = 120, maxLevel = 0, weight = 10, hpMultiplier = 1.45, attackBonus = 0,
            abilityKey = "BARK_ARMOUR", abilityName = "Bark Armour", abilityDescription = "Starts with armour that must be broken first.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_BogBeast_MarshrootAncient.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_BogBeast_MarshrootAncient.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        MANA_WYRM = {
            key = "MANA_WYRM", assetKey = "ManaWyrm", type = "Mana Wyrm", name = "Arcane Glimmermaw",
            minLevel = 120, maxLevel = 0, weight = 9, hpMultiplier = 0.90, attackBonus = 1,
            abilityKey = "ARCANE_FEED", abilityName = "Arcane Feed", abilityDescription = "Becomes stronger whenever the hero rolls high.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_ManaWyrm_ArcaneGlimmermaw.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_ManaWyrm_ArcaneGlimmermaw.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        CLOCKWORK_REAVER = {
            key = "CLOCKWORK_REAVER", assetKey = "ClockworkReaver", type = "Clockwork Reaver", name = "Geargrind Prototype",
            minLevel = 120, maxLevel = 0, weight = 9, hpMultiplier = 1.25, attackBonus = 1,
            abilityKey = "MODE_SHIFT", abilityName = "Mode Shift", abilityDescription = "Alternates between defensive and attack modes.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_ClockworkReaver_GeargrindPrototype.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_ClockworkReaver_GeargrindPrototype.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        ARENA_GLADIATOR = {
            key = "ARENA_GLADIATOR", assetKey = "ArenaGladiator", type = "Arena Gladiator", name = "ZLR Blood Champion",
            minLevel = 120, maxLevel = 0, weight = 7, hpMultiplier = 1.30, attackBonus = 2,
            abilityKey = "PERFECT_COMBO", abilityName = "Perfect Combo", abilityDescription = "Attacks twice after a perfect enemy roll.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_ArenaGladiator_ZLRBloodChampion.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_ArenaGladiator_ZLRBloodChampion.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        ZERO_WING_DRONE = {
            key = "ZERO_WING_DRONE", assetKey = "ZeroWingDrone", type = "Zero Wing Drone", name = "CATS Assault Unit",
            minLevel = 120, maxLevel = 0, weight = 6, hpMultiplier = 1.40, attackBonus = 2,
            abilityKey = "BASE_LASER", abilityName = "Base Laser", abilityDescription = "Charges a powerful laser with a visible warning.",
            abilityImplemented = false,
            icon = ROOT .. "\\Sets\\08_Enemy_Icons_Expansion_01\\Icons\\Enemy_ZeroWingDrone_CATSAssaultUnit.tga",
            fullBody = ROOT .. "\\Sets\\09_Enemy_FullBody_Expansion_01\\FullBody\\Enemy_ZeroWingDrone_CATSAssaultUnit.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
    },
    classOrder = { "PALADIN", "WARRIOR", "ROGUE", "RANGER", "MAGE", "PRIEST", "WARLOCK", "DEFENDER", "DRUID", "SHAMAN" },
    bossPlaceholderArt = true,
    bossMilestone = 10,
    bossOrder = {
        "KING_CANDLEWICK",
        "GNARLFANG_PACKLORD",
        "MURKFIN_TIDE_KING",
        "ZARISS_COIL_QUEEN",
        "GRUMBAR_EARTHBREAKER",
        "STORMTALON_MATRIARCH",
        "XAVROS_FELWHISPER",
        "AZARAK_WEB_TYRANT",
        "LORD_COLDGRAVE",
        "EMPEROR_BLACKFUSE",
        "NEXUS_LORD_VAELRIX",
        "HIGH_SEER_SKYREND",
        "AKORU_SOULKEEPER",
        "SUNBLADE_GRAND_MAGISTER",
        "GORVAK_UNCHAINED",
        "DROWNED_ANCIENT",
        "ASTRALAX_DEVOURER",
        "OMEGA_REAVER",
        "ZLR_ARENA_OVERLORD",
        "CATS_MASTER_BASE",
    },
    bosses = {
        KING_CANDLEWICK = {
            key = "KING_CANDLEWICK", assetKey = "KingCandlewick", name = "King Candlewick", level = 10, family = "Kobold",
            mechanic = "CANDLE", abilityName = "Candle Barrier", abilityDescription = "The lit candle empowers the king until a high attack roll extinguishes it.", abilityImplemented = true,
            hpMultiplier = 2.20, attackBonus = 2, coinMin = 10, coinMax = 25, armourChance = 2, armourTierMax = 1,
            crateWeights = { ADVENTURER = 70, WARBOUND = 20, ROYAL = 9, VOID = 1 },
            firstKill = { type = "DAMAGE", value = 1, label = "+1 permanent Dungeon damage" },
            icon = ROOT .. "\\Bosses\\Icons\\KingCandlewick.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\KingCandlewick.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        GNARLFANG_PACKLORD = {
            key = "GNARLFANG_PACKLORD", assetKey = "GnarlfangPacklord", name = "Gnarlfang the Packlord", level = 20, family = "Gnoll",
            mechanic = "PACK", abilityName = "Call the Pack", abilityDescription = "Summons packlings during the fight.", abilityImplemented = true,
            hpMultiplier = 2.35, attackBonus = 2, coinMin = 15, coinMax = 30, armourChance = 10, armourTierMax = 1,
            crateWeights = { ADVENTURER = 70, WARBOUND = 20, ROYAL = 9, VOID = 1 },
            firstKill = { type = "CRATE", value = "ADVENTURER", label = "Adventurer’s Cache" },
            icon = ROOT .. "\\Bosses\\Icons\\GnarlfangPacklord.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\GnarlfangPacklord.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        MURKFIN_TIDE_KING = {
            key = "MURKFIN_TIDE_KING", assetKey = "MurkfinTideKing", name = "Murkfin Tide King", level = 30, family = "Murloc",
            mechanic = "TIDE", abilityName = "Tidal Totem", abilityDescription = "Heals through a tide totem unless interrupted by a strong attack.", abilityImplemented = true,
            hpMultiplier = 2.45, attackBonus = 2, coinMin = 20, coinMax = 40, armourChance = 4, armourTierMax = 1,
            crateWeights = { ADVENTURER = 70, WARBOUND = 20, ROYAL = 9, VOID = 1 },
            firstKill = { type = "COINS", value = 30, label = "30 Cresh Coins" },
            icon = ROOT .. "\\Bosses\\Icons\\MurkfinTideKing.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\MurkfinTideKing.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        ZARISS_COIL_QUEEN = {
            key = "ZARISS_COIL_QUEEN", assetKey = "ZarissCoilQueen", name = "Zariss the Coil Queen", level = 40, family = "Naga",
            mechanic = "COIL", abilityName = "Coilguard Stance", abilityDescription = "Alternates between a damage shield and an empowered assault stance.", abilityImplemented = true,
            hpMultiplier = 2.55, attackBonus = 3, coinMin = 25, coinMax = 50, armourChance = 12, armourTierMax = 2,
            crateWeights = { ADVENTURER = 70, WARBOUND = 20, ROYAL = 9, VOID = 1 },
            firstKill = { type = "ARMOUR", value = 2, label = "Tier 2 class armour" },
            icon = ROOT .. "\\Bosses\\Icons\\ZarissCoilQueen.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\ZarissCoilQueen.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        GRUMBAR_EARTHBREAKER = {
            key = "GRUMBAR_EARTHBREAKER", assetKey = "GrumbarEarthbreaker", name = "Grumbar Earthbreaker", level = 50, family = "Trogg",
            mechanic = "QUAKE", abilityName = "Earthbreaker", abilityDescription = "Warns before unleashing a heavy earthquake.", abilityImplemented = true,
            hpMultiplier = 2.70, attackBonus = 3, coinMin = 30, coinMax = 60, armourChance = 6, armourTierMax = 2,
            crateWeights = { ADVENTURER = 50, WARBOUND = 27, ROYAL = 18, VOID = 5 },
            firstKill = { type = "PORTRAIT_TOKEN", value = 1, label = "Boss portrait token" },
            icon = ROOT .. "\\Bosses\\Icons\\GrumbarEarthbreaker.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\GrumbarEarthbreaker.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        STORMTALON_MATRIARCH = {
            key = "STORMTALON_MATRIARCH", assetKey = "StormtalonMatriarch", name = "Stormtalon Matriarch", level = 60, family = "Harpy",
            mechanic = "AIRBORNE", abilityName = "Storm Dive", abilityDescription = "Takes flight to evade a strike, then dives for extra damage.", abilityImplemented = true,
            hpMultiplier = 2.75, attackBonus = 3, coinMin = 40, coinMax = 75, armourChance = 14, armourTierMax = 3,
            crateWeights = { ADVENTURER = 50, WARBOUND = 27, ROYAL = 18, VOID = 5 },
            firstKill = { type = "DAMAGE", value = 2, label = "+2 permanent Dungeon damage" },
            icon = ROOT .. "\\Bosses\\Icons\\StormtalonMatriarch.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\StormtalonMatriarch.tga",
            artStatus = "PLACEHOLDER",
        },
        XAVROS_FELWHISPER = {
            key = "XAVROS_FELWHISPER", assetKey = "XavrosFelwhisper", name = "Xavros Felwhisper", level = 70, family = "Satyr",
            mechanic = "DRAIN", abilityName = "Fel Drain", abilityDescription = "Periodically drains health and restores his own.", abilityImplemented = true,
            hpMultiplier = 2.85, attackBonus = 4, coinMin = 50, coinMax = 90, armourChance = 7, armourTierMax = 3,
            crateWeights = { ADVENTURER = 50, WARBOUND = 27, ROYAL = 18, VOID = 5 },
            firstKill = { type = "CRATE", value = "ROYAL", label = "Royal Vanguard Chest" },
            icon = ROOT .. "\\Bosses\\Icons\\XavrosFelwhisper.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\XavrosFelwhisper.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        AZARAK_WEB_TYRANT = {
            key = "AZARAK_WEB_TYRANT", assetKey = "AzarakWebTyrant", name = "Azarak the Web Tyrant", level = 80, family = "Nerubian",
            mechanic = "WEB", abilityName = "Royal Webbing", abilityDescription = "Binds a minion or weakens the hero’s next attack.", abilityImplemented = true,
            hpMultiplier = 3.00, attackBonus = 4, coinMin = 60, coinMax = 105, armourChance = 16, armourTierMax = 4,
            crateWeights = { ADVENTURER = 50, WARBOUND = 27, ROYAL = 18, VOID = 5 },
            firstKill = { type = "ARMOUR", value = 4, label = "Tier 4 class armour" },
            icon = ROOT .. "\\Bosses\\Icons\\AzarakWebTyrant.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\AzarakWebTyrant.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        LORD_COLDGRAVE = {
            key = "LORD_COLDGRAVE", assetKey = "LordColdgrave", name = "Lord Coldgrave", level = 90, family = "Frost Revenant",
            mechanic = "FROST", abilityName = "Coldgrave Curse", abilityDescription = "Freezes the hero and reduces the next attack.", abilityImplemented = true,
            hpMultiplier = 3.10, attackBonus = 4, coinMin = 70, coinMax = 120, armourChance = 8, armourTierMax = 4,
            crateWeights = { ADVENTURER = 50, WARBOUND = 27, ROYAL = 18, VOID = 5 },
            firstKill = { type = "FULLBODY_TOKEN", value = 1, label = "Full-body profile token" },
            icon = ROOT .. "\\Bosses\\Icons\\LordColdgrave.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\LordColdgrave.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        EMPEROR_BLACKFUSE = {
            key = "EMPEROR_BLACKFUSE", assetKey = "EmperorBlackfuse", name = "Emperor Blackfuse", level = 100, family = "Dark Iron",
            mechanic = "BOMB", abilityName = "Blackfuse Bomb", abilityDescription = "Plants timed explosives that detonate two turns later.", abilityImplemented = true,
            hpMultiplier = 3.25, attackBonus = 5, coinMin = 85, coinMax = 140, armourChance = 20, armourTierMax = 5,
            crateWeights = { ADVENTURER = 35, WARBOUND = 30, ROYAL = 27, VOID = 8 },
            firstKill = { type = "ARMOUR", value = 5, label = "Tier 5 class armour" },
            icon = ROOT .. "\\Bosses\\Icons\\EmperorBlackfuse.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\EmperorBlackfuse.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        NEXUS_LORD_VAELRIX = {
            key = "NEXUS_LORD_VAELRIX", assetKey = "NexusLordVaelrix", name = "Nexus Lord Vaelrix", level = 110, family = "Ethereal",
            mechanic = "PHASE", abilityName = "Nexus Phase", abilityDescription = "Phases out to avoid a strike, then returns with an ambush.", abilityImplemented = true,
            hpMultiplier = 3.30, attackBonus = 5, coinMin = 95, coinMax = 155, armourChance = 12, armourTierMax = 5,
            crateWeights = { ADVENTURER = 35, WARBOUND = 30, ROYAL = 27, VOID = 8 },
            firstKill = { type = "COINS", value = 150, label = "150 Cresh Coins" },
            icon = ROOT .. "\\Bosses\\Icons\\NexusLordVaelrix.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\NexusLordVaelrix.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        HIGH_SEER_SKYREND = {
            key = "HIGH_SEER_SKYREND", assetKey = "HighSeerSkyrend", name = "High Seer Skyrend", level = 120, family = "Arakkoa",
            mechanic = "WINDS", abilityName = "War Winds", abilityDescription = "Calls war winds that permanently raise boss attack during the battle.", abilityImplemented = true,
            hpMultiplier = 3.40, attackBonus = 5, coinMin = 105, coinMax = 170, armourChance = 18, armourTierMax = 5,
            crateWeights = { ADVENTURER = 35, WARBOUND = 30, ROYAL = 27, VOID = 8 },
            firstKill = { type = "SHARDS", value = 4, label = "4 Armour Shards" },
            icon = ROOT .. "\\Bosses\\Icons\\HighSeerSkyrend.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\HighSeerSkyrend.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        AKORU_SOULKEEPER = {
            key = "AKORU_SOULKEEPER", assetKey = "AkoruSoulkeeper", name = "Akoru the Soulkeeper", level = 130, family = "Broken",
            mechanic = "SOUL", abilityName = "Soul Recall", abilityDescription = "Summons soul echoes to fight beside him.", abilityImplemented = true,
            hpMultiplier = 3.50, attackBonus = 5, coinMin = 115, coinMax = 185, armourChance = 14, armourTierMax = 5,
            crateWeights = { ADVENTURER = 35, WARBOUND = 30, ROYAL = 27, VOID = 8 },
            firstKill = { type = "CRATE", value = "ROYAL", label = "Royal Vanguard Chest" },
            icon = ROOT .. "\\Bosses\\Icons\\AkoruSoulkeeper.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\AkoruSoulkeeper.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        SUNBLADE_GRAND_MAGISTER = {
            key = "SUNBLADE_GRAND_MAGISTER", assetKey = "SunbladeGrandMagister", name = "Sunblade Grand Magister", level = 140, family = "Blood Elf",
            mechanic = "STEAL", abilityName = "Spell Theft", abilityDescription = "Steals a point of attack and converts it into boss power.", abilityImplemented = true,
            hpMultiplier = 3.55, attackBonus = 6, coinMin = 125, coinMax = 200, armourChance = 20, armourTierMax = 5,
            crateWeights = { ADVENTURER = 35, WARBOUND = 30, ROYAL = 27, VOID = 8 },
            firstKill = { type = "DAMAGE", value = 2, label = "+2 permanent Dungeon damage" },
            icon = ROOT .. "\\Bosses\\Icons\\SunbladeGrandMagister.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\SunbladeGrandMagister.tga",
            artStatus = "PLACEHOLDER",
        },
        GORVAK_UNCHAINED = {
            key = "GORVAK_UNCHAINED", assetKey = "GorvakUnchained", name = "Gorvak the Unchained", level = 150, family = "Fel Orc",
            mechanic = "RAGE", abilityName = "Unchained Rage", abilityDescription = "Gains attack at 75%, 50% and 25% health.", abilityImplemented = true,
            hpMultiplier = 3.65, attackBonus = 6, coinMin = 140, coinMax = 220, armourChance = 16, armourTierMax = 5,
            crateWeights = { ADVENTURER = 20, WARBOUND = 30, ROYAL = 38, VOID = 12 },
            firstKill = { type = "CRATE", value = "VOID", label = "Voidlord Reliquary" },
            icon = ROOT .. "\\Bosses\\Icons\\GorvakUnchained.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\GorvakUnchained.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        DROWNED_ANCIENT = {
            key = "DROWNED_ANCIENT", assetKey = "DrownedAncient", name = "The Drowned Ancient", level = 160, family = "Bog Beast",
            mechanic = "BARK", abilityName = "Ancient Bark", abilityDescription = "Begins with bark armour and periodically regenerates it.", abilityImplemented = true,
            hpMultiplier = 3.75, attackBonus = 6, coinMin = 155, coinMax = 240, armourChance = 22, armourTierMax = 5,
            crateWeights = { ADVENTURER = 20, WARBOUND = 30, ROYAL = 38, VOID = 12 },
            firstKill = { type = "SHARDS", value = 5, label = "5 Armour Shards" },
            icon = ROOT .. "\\Bosses\\Icons\\DrownedAncient.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\DrownedAncient.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        ASTRALAX_DEVOURER = {
            key = "ASTRALAX_DEVOURER", assetKey = "AstralaxDevourer", name = "Astralax the Devourer", level = 170, family = "Mana Wyrm",
            mechanic = "MANA", abilityName = "Arcane Consumption", abilityDescription = "Absorbs powerful rolls and discharges stored arcane energy.", abilityImplemented = true,
            hpMultiplier = 3.80, attackBonus = 7, coinMin = 170, coinMax = 260, armourChance = 18, armourTierMax = 5,
            crateWeights = { ADVENTURER = 20, WARBOUND = 30, ROYAL = 38, VOID = 12 },
            firstKill = { type = "PORTRAIT_TOKEN", value = 2, label = "2 Boss portrait tokens" },
            icon = ROOT .. "\\Bosses\\Icons\\AstralaxDevourer.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\AstralaxDevourer.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        OMEGA_REAVER = {
            key = "OMEGA_REAVER", assetKey = "OmegaReaver", name = "Prototype Omega-Reaver", level = 180, family = "Clockwork",
            mechanic = "MODES", abilityName = "Omega Configuration", abilityDescription = "Cycles through armour, assault and repair configurations.", abilityImplemented = true,
            hpMultiplier = 3.90, attackBonus = 7, coinMin = 185, coinMax = 280, armourChance = 24, armourTierMax = 5,
            crateWeights = { ADVENTURER = 20, WARBOUND = 30, ROYAL = 38, VOID = 12 },
            firstKill = { type = "DAMAGE", value = 3, label = "+3 permanent Dungeon damage" },
            icon = ROOT .. "\\Bosses\\Icons\\OmegaReaver.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\OmegaReaver.tga",
            artStatus = "LIVE_BOSS_ART",
        },
        ZLR_ARENA_OVERLORD = {
            key = "ZLR_ARENA_OVERLORD", assetKey = "ZLRArenaOverlord", name = "ZLR Arena Overlord", level = 190, family = "Arena Gladiator",
            mechanic = "ARENA", abilityName = "Arena Double Tap", abilityDescription = "Unleashes a second strike on scheduled attack turns.", abilityImplemented = true,
            hpMultiplier = 4.00, attackBonus = 7, coinMin = 200, coinMax = 300, armourChance = 20, armourTierMax = 5,
            crateWeights = { ADVENTURER = 20, WARBOUND = 30, ROYAL = 38, VOID = 12 },
            firstKill = { type = "FULLBODY_TOKEN", value = 2, label = "2 Full-body profile tokens" },
            icon = ROOT .. "\\Bosses\\Icons\\ZLRArenaOverlord.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\ZLRArenaOverlord.tga",
            artStatus = "PLACEHOLDER",
        },
        CATS_MASTER_BASE = {
            key = "CATS_MASTER_BASE", assetKey = "CATSMasterBase", name = "CATS, Master of the Base", level = 200, family = "Zero Wing",
            mechanic = "CATS", abilityName = "All Your Base", abilityDescription = "A multi-stage encounter with drones and a charged laser.", abilityImplemented = true,
            hpMultiplier = 4.25, attackBonus = 8, coinMin = 300, coinMax = 400, armourChance = 30, armourTierMax = 5,
            crateWeights = { ADVENTURER = 10, WARBOUND = 25, ROYAL = 45, VOID = 20 },
            firstKill = { type = "CRATE", value = "VOID", label = "Voidlord Reliquary" },
            icon = ROOT .. "\\Bosses\\Icons\\CATSMasterBase.tga",
            fullBody = ROOT .. "\\Bosses\\FullBody\\CATSMasterBase.tga",
            artStatus = "LIVE_BOSS_ART",
        },
    },
    crateOrder = { "ADVENTURER", "WARBOUND", "ROYAL", "VOID" },
    crates = {
        ADVENTURER = {
            key = "ADVENTURER", assetKey = "AdventurersCache", name = "Adventurer's Cache", rarity = "COMMON",
            coinMin = 8, coinMax = 18, damageChance = 20, portraitChance = 1, fullBodyChance = 0, armourChance = 2,
            description = "Reliable coins with a small chance at a permanent damage relic.",
            icon = ROOT .. "\\Crates\\AdventurersCache.tga", artStatus = "GAME_ART",
        },
        WARBOUND = {
            key = "WARBOUND", assetKey = "WarboundStrongbox", name = "Warbound Strongbox", rarity = "UNCOMMON",
            coinMin = 15, coinMax = 35, damageChance = 35, portraitChance = 3, fullBodyChance = 1, armourChance = 5,
            description = "Combat-focused rewards with improved relic and armour chances.",
            icon = ROOT .. "\\Crates\\WarboundStrongbox.tga", artStatus = "GAME_ART",
        },
        ROYAL = {
            key = "ROYAL", assetKey = "RoyalVanguardChest", name = "Royal Vanguard Chest", rarity = "RARE",
            coinMin = 30, coinMax = 60, damageChance = 45, portraitChance = 10, fullBodyChance = 5, armourChance = 15,
            description = "High-value coins, class armour and profile cosmetic tokens.",
            icon = ROOT .. "\\Crates\\RoyalVanguardChest.tga", artStatus = "GAME_ART",
        },
        VOID = {
            key = "VOID", assetKey = "VoidlordReliquary", name = "Voidlord Reliquary", rarity = "EPIC",
            coinMin = 50, coinMax = 100, damageChance = 60, portraitChance = 20, fullBodyChance = 12, armourChance = 30,
            description = "Premium boss cache with the strongest cosmetic and armour odds.",
            icon = ROOT .. "\\Crates\\VoidlordReliquary.tga", artStatus = "GAME_ART",
        },
    },
    milestoneChestOrder = { 20, 40, 60, 80, 100 },
    milestoneChests = {
        [20] = {
            level = 20, name = "Level 20 Milestone Chest",
            icon = ROOT .. "\\Chests\\Icons\\Chest_L20_Level20MilestoneChest.tga",
            display = ROOT .. "\\Chests\\Display\\Chest_L20_Level20MilestoneChest.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        [40] = {
            level = 40, name = "Level 40 Milestone Chest",
            icon = ROOT .. "\\Chests\\Icons\\Chest_L40_Level40MilestoneChest.tga",
            display = ROOT .. "\\Chests\\Display\\Chest_L40_Level40MilestoneChest.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        [60] = {
            level = 60, name = "Level 60 Milestone Chest",
            icon = ROOT .. "\\Chests\\Icons\\Chest_L60_Level60MilestoneChest.tga",
            display = ROOT .. "\\Chests\\Display\\Chest_L60_Level60MilestoneChest.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        [80] = {
            level = 80, name = "Level 80 Milestone Chest",
            icon = ROOT .. "\\Chests\\Icons\\Chest_L80_Level80MilestoneChest.tga",
            display = ROOT .. "\\Chests\\Display\\Chest_L80_Level80MilestoneChest.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
        [100] = {
            level = 100, name = "Level 100 Milestone Chest",
            icon = ROOT .. "\\Chests\\Icons\\Chest_L100_Level100MilestoneChest.tga",
            display = ROOT .. "\\Chests\\Display\\Chest_L100_Level100MilestoneChest.tga",
            artStatus = "LIVE_TEXTURE_PACK_V4",
        },
    },
    rewardIcons = {
        COINS = { name = "Cresh Coin Cache", icon = ROOT .. "\\RewardIcons\\Icons\\RewardIcon_CreshCoinCache.tga" },
        DAMAGE = { name = "Damage Relic", icon = ROOT .. "\\RewardIcons\\Icons\\RewardIcon_DamageRelic.tga" },
        PORTRAIT = { name = "Portrait Token", icon = ROOT .. "\\RewardIcons\\Icons\\RewardIcon_PortraitToken.tga" },
        FULLBODY = { name = "Full-Body Token", icon = ROOT .. "\\RewardIcons\\Icons\\RewardIcon_FullBodyToken.tga" },
        SHARDS = { name = "Armour Choice Token", icon = ROOT .. "\\RewardIcons\\Icons\\RewardIcon_ArmourChoiceToken.tga" },
        ARMOUR = { name = "Armour Choice Token", icon = ROOT .. "\\RewardIcons\\Icons\\RewardIcon_ArmourChoiceToken.tga" },
    },
    pity = { armourBosses = 5, voidCrates = 10, shardsForArmour = 10, duplicateArmourShards = 2 },
    armourSets = {
        PALADIN = {
            {
                key = "PALADIN_T20_DAWNWATCHPLATE", classKey = "PALADIN", className = "Paladin", tier = 1, unlockLevel = 20,
                name = "Dawnwatch Plate", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Paladin\\ClassArmor_Paladin_L20_DawnwatchPlate.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Paladin\\ClassArmor_Paladin_L20_DawnwatchPlate.tga",
            },
            {
                key = "PALADIN_T40_LIONGUARDREGALIA", classKey = "PALADIN", className = "Paladin", tier = 2, unlockLevel = 40,
                name = "Lionguard Regalia", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Paladin\\ClassArmor_Paladin_L40_LionguardRegalia.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Paladin\\ClassArmor_Paladin_L40_LionguardRegalia.tga",
            },
            {
                key = "PALADIN_T60_SHATTRATHSUNFORGED", classKey = "PALADIN", className = "Paladin", tier = 3, unlockLevel = 60,
                name = "Shattrath Sunforged", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Paladin\\ClassArmor_Paladin_L60_ShattrathSunforged.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Paladin\\ClassArmor_Paladin_L60_ShattrathSunforged.tga",
            },
            {
                key = "PALADIN_T80_DARKPORTALCRUSADER", classKey = "PALADIN", className = "Paladin", tier = 4, unlockLevel = 80,
                name = "Dark Portal Crusader", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Paladin\\ClassArmor_Paladin_L80_DarkPortalCrusader.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Paladin\\ClassArmor_Paladin_L80_DarkPortalCrusader.tga",
            },
            {
                key = "PALADIN_T100_ASHBRINGERASCENDANT", classKey = "PALADIN", className = "Paladin", tier = 5, unlockLevel = 100,
                name = "Ashbringer Ascendant", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Paladin\\ClassArmor_Paladin_L100_AshbringerAscendant.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Paladin\\ClassArmor_Paladin_L100_AshbringerAscendant.tga",
            },
        },
        WARRIOR = {
            {
                key = "WARRIOR_T20_IRONHIDEBATTLEGEAR", classKey = "WARRIOR", className = "Warrior", tier = 1, unlockLevel = 20,
                name = "Ironhide Battlegear", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warrior\\ClassArmor_Warrior_L20_IronhideBattlegear.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warrior\\ClassArmor_Warrior_L20_IronhideBattlegear.tga",
            },
            {
                key = "WARRIOR_T40_WARSONGVANGUARD", classKey = "WARRIOR", className = "Warrior", tier = 2, unlockLevel = 40,
                name = "Warsong Vanguard", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warrior\\ClassArmor_Warrior_L40_WarsongVanguard.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warrior\\ClassArmor_Warrior_L40_WarsongVanguard.tga",
            },
            {
                key = "WARRIOR_T60_HELLFIREJUGGERNAUT", classKey = "WARRIOR", className = "Warrior", tier = 3, unlockLevel = 60,
                name = "Hellfire Juggernaut", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warrior\\ClassArmor_Warrior_L60_HellfireJuggernaut.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warrior\\ClassArmor_Warrior_L60_HellfireJuggernaut.tga",
            },
            {
                key = "WARRIOR_T80_Q3ABLOODSTEEL", classKey = "WARRIOR", className = "Warrior", tier = 4, unlockLevel = 80,
                name = "Q3A Bloodsteel", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warrior\\ClassArmor_Warrior_L80_Q3ABloodsteel.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warrior\\ClassArmor_Warrior_L80_Q3ABloodsteel.tga",
            },
            {
                key = "WARRIOR_T100_WARLORDOFTHEBLACKTEMPLE", classKey = "WARRIOR", className = "Warrior", tier = 5, unlockLevel = 100,
                name = "Warlord of the Black Temple", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warrior\\ClassArmor_Warrior_L100_WarlordoftheBlackTemple.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warrior\\ClassArmor_Warrior_L100_WarlordoftheBlackTemple.tga",
            },
        },
        ROGUE = {
            {
                key = "ROGUE_T20_GLOOMSTEPLEATHERS", classKey = "ROGUE", className = "Rogue", tier = 1, unlockLevel = 20,
                name = "Gloomstep Leathers", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Rogue\\ClassArmor_Rogue_L20_GloomstepLeathers.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Rogue\\ClassArmor_Rogue_L20_GloomstepLeathers.tga",
            },
            {
                key = "ROGUE_T40_NIGHTBLADEDISGUISE", classKey = "ROGUE", className = "Rogue", tier = 2, unlockLevel = 40,
                name = "Nightblade Disguise", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Rogue\\ClassArmor_Rogue_L40_NightbladeDisguise.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Rogue\\ClassArmor_Rogue_L40_NightbladeDisguise.tga",
            },
            {
                key = "ROGUE_T60_NETHERKNIFEHARNESS", classKey = "ROGUE", className = "Rogue", tier = 3, unlockLevel = 60,
                name = "Netherknife Harness", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Rogue\\ClassArmor_Rogue_L60_NetherknifeHarness.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Rogue\\ClassArmor_Rogue_L60_NetherknifeHarness.tga",
            },
            {
                key = "ROGUE_T80_ZLRARENAASSASSIN", classKey = "ROGUE", className = "Rogue", tier = 4, unlockLevel = 80,
                name = "ZLR Arena Assassin", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Rogue\\ClassArmor_Rogue_L80_ZLRArenaAssassin.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Rogue\\ClassArmor_Rogue_L80_ZLRArenaAssassin.tga",
            },
            {
                key = "ROGUE_T100_SHADOWOFKARAZHAN", classKey = "ROGUE", className = "Rogue", tier = 5, unlockLevel = 100,
                name = "Shadow of Karazhan", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Rogue\\ClassArmor_Rogue_L100_ShadowofKarazhan.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Rogue\\ClassArmor_Rogue_L100_ShadowofKarazhan.tga",
            },
        },
        RANGER = {
            {
                key = "RANGER_T20_WILDWOODTRACKER", classKey = "RANGER", className = "Ranger", tier = 1, unlockLevel = 20,
                name = "Wildwood Tracker", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Ranger\\ClassArmor_Ranger_L20_WildwoodTracker.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Ranger\\ClassArmor_Ranger_L20_WildwoodTracker.tga",
            },
            {
                key = "RANGER_T40_FARSTRIDERBATTLEGEAR", classKey = "RANGER", className = "Ranger", tier = 2, unlockLevel = 40,
                name = "Farstrider Battlegear", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Ranger\\ClassArmor_Ranger_L40_FarstriderBattlegear.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Ranger\\ClassArmor_Ranger_L40_FarstriderBattlegear.tga",
            },
            {
                key = "RANGER_T60_ZANGARMARSHSTALKER", classKey = "RANGER", className = "Ranger", tier = 3, unlockLevel = 60,
                name = "Zangarmarsh Stalker", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Ranger\\ClassArmor_Ranger_L60_ZangarmarshStalker.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Ranger\\ClassArmor_Ranger_L60_ZangarmarshStalker.tga",
            },
            {
                key = "RANGER_T80_FROSTWOLFHUNTMASTER", classKey = "RANGER", className = "Ranger", tier = 4, unlockLevel = 80,
                name = "Frostwolf Huntmaster", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Ranger\\ClassArmor_Ranger_L80_FrostwolfHuntmaster.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Ranger\\ClassArmor_Ranger_L80_FrostwolfHuntmaster.tga",
            },
            {
                key = "RANGER_T100_BEASTLORDOFOUTLAND", classKey = "RANGER", className = "Ranger", tier = 5, unlockLevel = 100,
                name = "Beastlord of Outland", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Ranger\\ClassArmor_Ranger_L100_BeastlordofOutland.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Ranger\\ClassArmor_Ranger_L100_BeastlordofOutland.tga",
            },
        },
        MAGE = {
            {
                key = "MAGE_T20_EMBERWEAVEROBES", classKey = "MAGE", className = "Mage", tier = 1, unlockLevel = 20,
                name = "Emberweave Robes", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Mage\\ClassArmor_Mage_L20_EmberweaveRobes.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Mage\\ClassArmor_Mage_L20_EmberweaveRobes.tga",
            },
            {
                key = "MAGE_T40_ARCANECONSERVATOR", classKey = "MAGE", className = "Mage", tier = 2, unlockLevel = 40,
                name = "Arcane Conservator", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Mage\\ClassArmor_Mage_L40_ArcaneConservator.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Mage\\ClassArmor_Mage_L40_ArcaneConservator.tga",
            },
            {
                key = "MAGE_T60_NETHERSTORMMAGISTER", classKey = "MAGE", className = "Mage", tier = 3, unlockLevel = 60,
                name = "Netherstorm Magister", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Mage\\ClassArmor_Mage_L60_NetherstormMagister.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Mage\\ClassArmor_Mage_L60_NetherstormMagister.tga",
            },
            {
                key = "MAGE_T80_ZEROWINGSTARCASTER", classKey = "MAGE", className = "Mage", tier = 4, unlockLevel = 80,
                name = "Zero Wing Starcaster", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Mage\\ClassArmor_Mage_L80_ZeroWingStarcaster.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Mage\\ClassArmor_Mage_L80_ZeroWingStarcaster.tga",
            },
            {
                key = "MAGE_T100_TEMPESTKEEPARCHMAGE", classKey = "MAGE", className = "Mage", tier = 5, unlockLevel = 100,
                name = "Tempest Keep Archmage", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Mage\\ClassArmor_Mage_L100_TempestKeepArchmage.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Mage\\ClassArmor_Mage_L100_TempestKeepArchmage.tga",
            },
        },
        PRIEST = {
            {
                key = "PRIEST_T20_CANDLELIGHTVESTMENTS", classKey = "PRIEST", className = "Priest", tier = 1, unlockLevel = 20,
                name = "Candlelight Vestments", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Priest\\ClassArmor_Priest_L20_CandlelightVestments.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Priest\\ClassArmor_Priest_L20_CandlelightVestments.tga",
            },
            {
                key = "PRIEST_T40_ANCHORITESGRACE", classKey = "PRIEST", className = "Priest", tier = 2, unlockLevel = 40,
                name = "Anchorite's Grace", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Priest\\ClassArmor_Priest_L40_AnchoritesGrace.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Priest\\ClassArmor_Priest_L40_AnchoritesGrace.tga",
            },
            {
                key = "PRIEST_T60_SHATTRATHLIGHTWEAVER", classKey = "PRIEST", className = "Priest", tier = 3, unlockLevel = 60,
                name = "Shattrath Lightweaver", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Priest\\ClassArmor_Priest_L60_ShattrathLightweaver.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Priest\\ClassArmor_Priest_L60_ShattrathLightweaver.tga",
            },
            {
                key = "PRIEST_T80_VOIDBOUNDCONFESSOR", classKey = "PRIEST", className = "Priest", tier = 4, unlockLevel = 80,
                name = "Voidbound Confessor", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Priest\\ClassArmor_Priest_L80_VoidboundConfessor.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Priest\\ClassArmor_Priest_L80_VoidboundConfessor.tga",
            },
            {
                key = "PRIEST_T100_PROPHETOFTHENAARU", classKey = "PRIEST", className = "Priest", tier = 5, unlockLevel = 100,
                name = "Prophet of the Naaru", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Priest\\ClassArmor_Priest_L100_ProphetoftheNaaru.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Priest\\ClassArmor_Priest_L100_ProphetoftheNaaru.tga",
            },
        },
        WARLOCK = {
            {
                key = "WARLOCK_T20_SOOTBOUNDRAIMENT", classKey = "WARLOCK", className = "Warlock", tier = 1, unlockLevel = 20,
                name = "Sootbound Raiment", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warlock\\ClassArmor_Warlock_L20_SootboundRaiment.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warlock\\ClassArmor_Warlock_L20_SootboundRaiment.tga",
            },
            {
                key = "WARLOCK_T40_SHADOWCOUNCILVESTMENTS", classKey = "WARLOCK", className = "Warlock", tier = 2, unlockLevel = 40,
                name = "Shadow Council Vestments", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warlock\\ClassArmor_Warlock_L40_ShadowCouncilVestments.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warlock\\ClassArmor_Warlock_L40_ShadowCouncilVestments.tga",
            },
            {
                key = "WARLOCK_T60_FELHEARTREBORN", classKey = "WARLOCK", className = "Warlock", tier = 3, unlockLevel = 60,
                name = "Felheart Reborn", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warlock\\ClassArmor_Warlock_L60_FelheartReborn.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warlock\\ClassArmor_Warlock_L60_FelheartReborn.tga",
            },
            {
                key = "WARLOCK_T80_DARKPORTALSOULBINDER", classKey = "WARLOCK", className = "Warlock", tier = 4, unlockLevel = 80,
                name = "Dark Portal Soulbinder", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warlock\\ClassArmor_Warlock_L80_DarkPortalSoulbinder.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warlock\\ClassArmor_Warlock_L80_DarkPortalSoulbinder.tga",
            },
            {
                key = "WARLOCK_T100_LORDOFTHEBURNINGRIFT", classKey = "WARLOCK", className = "Warlock", tier = 5, unlockLevel = 100,
                name = "Lord of the Burning Rift", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Warlock\\ClassArmor_Warlock_L100_LordoftheBurningRift.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Warlock\\ClassArmor_Warlock_L100_LordoftheBurningRift.tga",
            },
        },
        DEFENDER = {
            {
                key = "DEFENDER_T20_DEEPFORGEBULWARK", classKey = "DEFENDER", className = "Defender", tier = 1, unlockLevel = 20,
                name = "Deepforge Bulwark", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Defender\\ClassArmor_Defender_L20_DeepforgeBulwark.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Defender\\ClassArmor_Defender_L20_DeepforgeBulwark.tga",
            },
            {
                key = "DEFENDER_T40_IRONFORGEKINGSGUARD", classKey = "DEFENDER", className = "Defender", tier = 2, unlockLevel = 40,
                name = "Ironforge Kingsguard", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Defender\\ClassArmor_Defender_L40_IronforgeKingsguard.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Defender\\ClassArmor_Defender_L40_IronforgeKingsguard.tga",
            },
            {
                key = "DEFENDER_T60_GRUULBREAKERPLATE", classKey = "DEFENDER", className = "Defender", tier = 3, unlockLevel = 60,
                name = "Gruulbreaker Plate", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Defender\\ClassArmor_Defender_L60_GruulbreakerPlate.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Defender\\ClassArmor_Defender_L60_GruulbreakerPlate.tga",
            },
            {
                key = "DEFENDER_T80_CHESSKINGCITADEL", classKey = "DEFENDER", className = "Defender", tier = 4, unlockLevel = 80,
                name = "Chess King Citadel", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Defender\\ClassArmor_Defender_L80_ChessKingCitadel.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Defender\\ClassArmor_Defender_L80_ChessKingCitadel.tga",
            },
            {
                key = "DEFENDER_T100_TITANWALLETERNAL", classKey = "DEFENDER", className = "Defender", tier = 5, unlockLevel = 100,
                name = "Titanwall Eternal", reservedClass = false, artStatus = "LIVE_TEXTURE_PACK_V4",
                icon = ROOT .. "\\ClassArmor\\Icons\\Defender\\ClassArmor_Defender_L100_TitanwallEternal.tga",
                fullBody = ROOT .. "\\ClassArmor\\FullBody\\Defender\\ClassArmor_Defender_L100_TitanwallEternal.tga",
            },
        },
        DRUID = {
            {
                key = "DRUID_T20_MOONBARKRAIMENT", classKey = "DRUID", className = "Druid", tier = 1, unlockLevel = 20,
                name = "Moonbark Raiment", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\DRUID\\T20_MoonbarkRaiment\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\DRUID\\T20_MoonbarkRaiment\\FullBody.tga",
            },
            {
                key = "DRUID_T40_CENARIONWILDGUARD", classKey = "DRUID", className = "Druid", tier = 2, unlockLevel = 40,
                name = "Cenarion Wildguard", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\DRUID\\T40_CenarionWildguard\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\DRUID\\T40_CenarionWildguard\\FullBody.tga",
            },
            {
                key = "DRUID_T60_ZANGARMARSHDREAMER", classKey = "DRUID", className = "Druid", tier = 3, unlockLevel = 60,
                name = "Zangarmarsh Dreamer", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\DRUID\\T60_ZangarmarshDreamer\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\DRUID\\T60_ZangarmarshDreamer\\FullBody.tga",
            },
            {
                key = "DRUID_T80_EMERALDSHAPEWARDEN", classKey = "DRUID", className = "Druid", tier = 4, unlockLevel = 80,
                name = "Emerald Shapewarden", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\DRUID\\T80_EmeraldShapewarden\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\DRUID\\T80_EmeraldShapewarden\\FullBody.tga",
            },
            {
                key = "DRUID_T100_ARCHDRUIDOFTHETWISTINGNETHER", classKey = "DRUID", className = "Druid", tier = 5, unlockLevel = 100,
                name = "Archdruid of the Twisting Nether", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\DRUID\\T100_ArchdruidoftheTwistingNether\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\DRUID\\T100_ArchdruidoftheTwistingNether\\FullBody.tga",
            },
        },
        SHAMAN = {
            {
                key = "SHAMAN_T20_STONECALLERMAIL", classKey = "SHAMAN", className = "Shaman", tier = 1, unlockLevel = 20,
                name = "Stonecaller Mail", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\SHAMAN\\T20_StonecallerMail\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\SHAMAN\\T20_StonecallerMail\\FullBody.tga",
            },
            {
                key = "SHAMAN_T40_EARTHENRINGREGALIA", classKey = "SHAMAN", className = "Shaman", tier = 2, unlockLevel = 40,
                name = "Earthen Ring Regalia", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\SHAMAN\\T40_EarthenRingRegalia\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\SHAMAN\\T40_EarthenRingRegalia\\FullBody.tga",
            },
            {
                key = "SHAMAN_T60_STORMFORGEDELEMENTS", classKey = "SHAMAN", className = "Shaman", tier = 3, unlockLevel = 60,
                name = "Stormforged Elements", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\SHAMAN\\T60_StormforgedElements\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\SHAMAN\\T60_StormforgedElements\\FullBody.tga",
            },
            {
                key = "SHAMAN_T80_ELEMENTALARENACHAMPION", classKey = "SHAMAN", className = "Shaman", tier = 4, unlockLevel = 80,
                name = "Elemental Arena Champion", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\SHAMAN\\T80_ElementalArenaChampion\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\SHAMAN\\T80_ElementalArenaChampion\\FullBody.tga",
            },
            {
                key = "SHAMAN_T100_FARSEEROFTHEBROKENWORLD", classKey = "SHAMAN", className = "Shaman", tier = 5, unlockLevel = 100,
                name = "Farseer of the Broken World", reservedClass = true, artStatus = "PLACEHOLDER",
                icon = ROOT .. "\\ArmourSets\\SHAMAN\\T100_FarseeroftheBrokenWorld\\Icon.tga",
                fullBody = ROOT .. "\\ArmourSets\\SHAMAN\\T100_FarseeroftheBrokenWorld\\FullBody.tga",
            },
        },
    },
}

-- Armour sets are gameplay loadouts as well as cosmetic skins.  The compact
-- stat tables below are attached after the content table is created so final
-- artwork can replace the placeholder files without changing combat data.
local ARMOUR_STAT_PROFILES = {
    PALADIN_T20_DAWNWATCHPLATE = { maxHP = 2, regenRoom = 1 },
    PALADIN_T40_LIONGUARDREGALIA = { maxHP = 3, blockChance = 10, blockAmount = 1 },
    PALADIN_T60_SHATTRATHSUNFORGED = { attack = 1, regenTurn = 1 },
    PALADIN_T80_DARKPORTALCRUSADER = { maxHP = 5, doubleDamageChance = 8 },
    PALADIN_T100_ASHBRINGERASCENDANT = { maxHP = 6, attack = 2, regenTurn = 1, doubleDamageChance = 12 },

    WARRIOR_T20_IRONHIDEBATTLEGEAR = { maxHP = 1, attack = 1 },
    WARRIOR_T40_WARSONGVANGUARD = { attack = 1, doubleDamageChance = 8 },
    WARRIOR_T60_HELLFIREJUGGERNAUT = { maxHP = 4, flatBlock = 1, blockChance = 5 },
    WARRIOR_T80_Q3ABLOODSTEEL = { extraDice = 1, extraDiePower = 65 },
    WARRIOR_T100_WARLORDOFTHEBLACKTEMPLE = { attack = 2, doubleDamageChance = 18, bleedChance = 20, bleedDamage = 2, bleedTurns = 2 },

    ROGUE_T20_GLOOMSTEPLEATHERS = { evadeChance = 8, bleedChance = 12, bleedDamage = 1, bleedTurns = 2 },
    ROGUE_T40_NIGHTBLADEDISGUISE = { extraDieChance = 20, extraDiePower = 60, evadeChance = 8 },
    ROGUE_T60_NETHERKNIFEHARNESS = { doubleDamageChance = 12, evadeChance = 10 },
    ROGUE_T80_ZLRARENAASSASSIN = { extraDice = 1, extraDiePower = 60, evadeChance = 5, bleedChance = 18, bleedDamage = 2, bleedTurns = 2 },
    ROGUE_T100_SHADOWOFKARAZHAN = { extraDice = 1, extraDiePower = 70, doubleDamageChance = 18, bleedChance = 30, bleedDamage = 3, bleedTurns = 2 },

    RANGER_T20_WILDWOODTRACKER = { extraDieChance = 15, extraDiePower = 60 },
    RANGER_T40_FARSTRIDERBATTLEGEAR = { bleedChance = 18, bleedDamage = 1, bleedTurns = 3 },
    RANGER_T60_ZANGARMARSHSTALKER = { extraDice = 1, extraDiePower = 55 },
    RANGER_T80_FROSTWOLFHUNTMASTER = { minionBonus = 1, extraDieChance = 25, extraDiePower = 65 },
    RANGER_T100_BEASTLORDOFOUTLAND = { extraDice = 1, extraDieChance = 25, extraDiePower = 70, bossDamage = 2, minionBonus = 1 },

    MAGE_T20_EMBERWEAVEROBES = { attack = 1, doubleDamageChance = 5 },
    MAGE_T40_ARCANECONSERVATOR = { extraDieChance = 20, extraDiePower = 65, maxHP = 1 },
    MAGE_T60_NETHERSTORMMAGISTER = { extraDice = 1, extraDiePower = 60, doubleDamageChance = 8 },
    MAGE_T80_ZEROWINGSTARCASTER = { extraDice = 1, extraDiePower = 70, doubleDamageChance = 12 },
    MAGE_T100_TEMPESTKEEPARCHMAGE = { extraDice = 2, extraDiePower = 60, doubleDamageChance = 15, attack = 1 },

    PRIEST_T20_CANDLELIGHTVESTMENTS = { maxHP = 2, regenRoom = 2 },
    PRIEST_T40_ANCHORITESGRACE = { maxHP = 3, regenTurn = 1 },
    PRIEST_T60_SHATTRATHLIGHTWEAVER = { regenTurn = 1, regenRoom = 2, doubleDamageChance = 6 },
    PRIEST_T80_VOIDBOUNDCONFESSOR = { maxHP = 4, bleedChance = 18, bleedDamage = 2, bleedTurns = 2 },
    PRIEST_T100_PROPHETOFTHENAARU = { maxHP = 6, regenTurn = 2, regenRoom = 3, doubleDamageChance = 10 },

    WARLOCK_T20_SOOTBOUNDRAIMENT = { bleedChance = 15, bleedDamage = 1, bleedTurns = 2 },
    WARLOCK_T40_SHADOWCOUNCILVESTMENTS = { minionBonus = 1, maxHP = 2 },
    WARLOCK_T60_FELHEARTREBORN = { bleedChance = 22, bleedDamage = 2, bleedTurns = 2, regenTurn = 1 },
    WARLOCK_T80_DARKPORTALSOULBINDER = { extraDice = 1, extraDiePower = 55, minionBonus = 2 },
    WARLOCK_T100_LORDOFTHEBURNINGRIFT = { doubleDamageChance = 15, bleedChance = 28, bleedDamage = 3, bleedTurns = 2, minionBonus = 2 },

    DEFENDER_T20_DEEPFORGEBULWARK = { maxHP = 4, flatBlock = 1 },
    DEFENDER_T40_IRONFORGEKINGSGUARD = { maxHP = 5, blockChance = 12, blockAmount = 1 },
    DEFENDER_T60_GRUULBREAKERPLATE = { maxHP = 7, flatBlock = 1, bossDamage = 1 },
    DEFENDER_T80_CHESSKINGCITADEL = { maxHP = 8, blockChance = 20, blockAmount = 2, regenRoom = 1 },
    DEFENDER_T100_TITANWALLETERNAL = { maxHP = 10, flatBlock = 2, blockChance = 25, blockAmount = 2, regenTurn = 1 },

    DRUID_T20_MOONBARKRAIMENT = { maxHP = 2, regenRoom = 2, evadeChance = 4 },
    DRUID_T40_CENARIONWILDGUARD = { regenTurn = 1, evadeChance = 6 },
    DRUID_T60_ZANGARMARSHDREAMER = { extraDieChance = 20, extraDiePower = 60, regenRoom = 2 },
    DRUID_T80_EMERALDSHAPEWARDEN = { extraDice = 1, extraDiePower = 60, bleedChance = 18, bleedDamage = 2, bleedTurns = 2 },
    DRUID_T100_ARCHDRUIDOFTHETWISTINGNETHER = { extraDice = 1, extraDiePower = 70, regenTurn = 2, bleedChance = 25, bleedDamage = 3, bleedTurns = 2 },

    SHAMAN_T20_STONECALLERMAIL = { maxHP = 2, flatBlock = 1 },
    SHAMAN_T40_EARTHENRINGREGALIA = { regenTurn = 1, attack = 1, bossDamage = 1 },
    SHAMAN_T60_STORMFORGEDELEMENTS = { extraDieChance = 25, extraDiePower = 65, doubleDamageChance = 8 },
    SHAMAN_T80_ELEMENTALARENACHAMPION = { extraDice = 1, extraDiePower = 65, doubleDamageChance = 12 },
    SHAMAN_T100_FARSEEROFTHEBROKENWORLD = { extraDice = 1, extraDieChance = 30, extraDiePower = 75, doubleDamageChance = 15, regenTurn = 1 },
}

for _, sets in pairs(Content.armourSets or {}) do
    for _, set in ipairs(sets) do
        set.stats = ARMOUR_STAT_PROFILES[set.key] or {}
        set.gameplayEnabled = not set.reservedClass
    end
end

local function scaledVariance(value, percent, rng)
    value = math.max(1, math.floor(tonumber(value) or 1))
    percent = math.max(0, tonumber(percent) or 0)
    if not rng or type(rng.Next) ~= "function" or percent <= 0 then return value end
    local spread = math.max(1, math.floor((value * percent) / 100))
    return math.max(1, value + rng:Next((spread * 2) + 1) - spread - 1)
end

function Content:GetScaledEnemyStats(level, boss, rng)
    level = math.max(1, math.floor(tonumber(level) or 1))
    local balance = self.enemyBalance or {}
    local health = balance.health or {}
    local attack = balance.attack or {}
    local overHealth = math.max(0, level - (health.overLevel or 100))
    local overAttack = math.max(0, level - (attack.overLevel or 120))

    local hp = (health.base or 5)
        + math.floor((level * (health.linearNumerator or 3)) / math.max(1, health.linearDivisor or 2))
        + math.floor((level * level) / math.max(1, health.quadraticDivisor or 70))
        + math.floor((overHealth * overHealth) / math.max(1, health.overQuadraticDivisor or 180))
    local power = (attack.base or 1)
        + math.floor(level / math.max(1, attack.linearDivisor or 6))
        + math.floor((level * level) / math.max(1, attack.quadraticDivisor or 650))
        + math.floor(overAttack / math.max(1, attack.overLinearDivisor or 10))

    hp = scaledVariance(hp, health.variancePercent or 0, rng)
    power = scaledVariance(power, attack.variancePercent or 0, rng)

    if boss then
        local bossBalance = balance.boss or {}
        local fiveLevelTier = math.floor((level - 1) / 5)
        hp = (hp * (bossBalance.healthMultiplier or 2))
            + (bossBalance.flatHealth or 5)
            + (fiveLevelTier * (bossBalance.healthPerFiveLevels or 2))
        power = power
            + (bossBalance.flatAttack or 1)
            + math.floor(fiveLevelTier / math.max(1, bossBalance.attackTierDivisor or 3))
    end

    return math.max(1, math.floor(hp)), math.max(1, math.floor(power))
end

function Content:GetEnemy(key)
    return self.enemies[string.upper(tostring(key or ""))]
end

function Content:GetEnemyPool(level)
    level = math.max(1, math.floor(tonumber(level) or 1))
    local pool = {}
    for _, key in ipairs(self.enemyOrder) do
        local enemy = self.enemies[key]
        if enemy and level >= (enemy.minLevel or 1) and ((enemy.maxLevel or 0) <= 0 or level <= enemy.maxLevel) then
            local weight = math.max(1, math.floor(tonumber(enemy.weight) or 1))
            for _ = 1, weight do pool[#pool + 1] = enemy end
        end
    end
    return pool
end


function Content:GetBoss(key)
    return self.bosses[string.upper(tostring(key or ""))]
end

function Content:IsBossLevel(level)
    level = math.max(1, math.floor(tonumber(level) or 1))
    return level % (self.bossMilestone or 10) == 0
end

function Content:GetBossForLevel(level)
    level = math.max(1, math.floor(tonumber(level) or 1))
    local exact
    for _, key in ipairs(self.bossOrder or {}) do
        local boss = self.bosses[key]
        if boss and boss.level == level then exact = boss break end
    end
    if exact then return exact end
    if not self:IsBossLevel(level) then return nil end
    local index = math.max(1, math.floor(level / (self.bossMilestone or 10)))
    local ordered = self.bossOrder or {}
    if #ordered == 0 then return nil end
    return self.bosses[ordered[((index - 1) % #ordered) + 1]]
end

function Content:GetCrate(key)
    return self.crates[string.upper(tostring(key or ""))]
end

function Content:GetMilestoneChest(level)
    level = math.max(1, math.floor(tonumber(level) or 1))
    for _, threshold in ipairs(self.milestoneChestOrder or {}) do
        if level <= threshold then return self.milestoneChests[threshold] end
    end
    local order = self.milestoneChestOrder or {}
    local last = order[#order]
    return last and self.milestoneChests[last] or nil
end

function Content:GetRewardIcon(rewardType)
    return self.rewardIcons[string.upper(tostring(rewardType or ""))]
end

function Content:GetArmourByTier(classKey, tier)
    tier = math.max(1, math.floor(tonumber(tier) or 1))
    for _, set in ipairs(self:GetArmourSets(classKey)) do
        if tonumber(set.tier) == tier then return set end
    end
    return nil
end

function Content:GetEligibleArmour(classKey, maxTier)
    maxTier = math.max(1, math.floor(tonumber(maxTier) or 1))
    local eligible = {}
    for _, set in ipairs(self:GetArmourSets(classKey)) do
        if not set.reservedClass and (tonumber(set.tier) or 0) <= maxTier then eligible[#eligible + 1] = set end
    end
    return eligible
end

function Content:GetArmourSets(classKey)
    return self.armourSets[string.upper(tostring(classKey or ""))] or {}
end

function Content:GetArmourSet(classKey, setKey)
    setKey = string.upper(tostring(setKey or ""))
    for _, set in ipairs(self:GetArmourSets(classKey)) do
        if string.upper(tostring(set.key or "")) == setKey then return set end
    end
    return nil
end

function Content:GetArmourForLevel(classKey, level)
    level = math.max(0, math.floor(tonumber(level) or 0))
    local selected
    for _, set in ipairs(self:GetArmourSets(classKey)) do
        if level >= (set.unlockLevel or 0) then selected = set end
    end
    return selected
end

_G.CreshGamesDungeonCrawlerContent = Content
if CC then
    CC.DungeonCrawlerContent = Content
    CC.Assets = CC.Assets or {}
    CC.Assets.DungeonCrawlerContent = Content
    if CC.RegisterModule then CC:RegisterModule("DungeonContent", Content) end
end
