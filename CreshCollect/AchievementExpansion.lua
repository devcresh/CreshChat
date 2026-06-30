local _, CC = ...
if not CC or not CC.Achievements then return end
local A = CC.Achievements
local Expansion = { version = CC.version, count = 300 }
CC.AchievementExpansion = Expansion
if CC.RegisterModule then CC:RegisterModule("AchievementExpansion", Expansion) end
local floor, max, min = math.floor, math.max, math.min
local lower, upper = string.lower, string.upper
local tinsert = table.insert

local EXPANSION = {
    { key="EXP_001", category="QUESTS", title="Getting Started", description="Complete 10 unique quests across the account.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_TOTAL", subject="", goal=10 },
    { key="EXP_002", category="QUESTS", title="Helping Hand", description="Complete 25 unique quests across the account.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_TOTAL", subject="", goal=25 },
    { key="EXP_003", category="QUESTS", title="Questing Habit", description="Complete 50 unique quests across the account.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_TOTAL", subject="", goal=50 },
    { key="EXP_004", category="QUESTS", title="Hundred Deeds", description="Complete 100 unique quests across the account.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_TOTAL", subject="", goal=100 },
    { key="EXP_005", category="QUESTS", title="Seasoned Adventurer", description="Complete 250 unique quests across the account.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_TOTAL", subject="", goal=250 },
    { key="EXP_006", category="QUESTS", title="Five Hundred Favors", description="Complete 500 unique quests across the account.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_TOTAL", subject="", goal=500 },
    { key="EXP_007", category="QUESTS", title="Quest Veteran", description="Complete 750 unique quests across the account.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_TOTAL", subject="", goal=750 },
    { key="EXP_008", category="QUESTS", title="Thousand Tales", description="Complete 1,000 unique quests across the account.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_TOTAL", subject="", goal=1000 },
    { key="EXP_009", category="QUESTS", title="Azeroth Chronicler", description="Complete 1,500 unique quests across the account.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_TOTAL", subject="", goal=1500 },
    { key="EXP_010", category="QUESTS", title="Endless Errands", description="Complete 2,000 unique quests across the account.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_TOTAL", subject="", goal=2000 },
    { key="EXP_011", category="QUESTS", title="Through the Portal", description="Complete 10 unique quests in Outland.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_OUTLAND", subject="", goal=10 },
    { key="EXP_012", category="QUESTS", title="Outland Helper", description="Complete 25 unique quests in Outland.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_OUTLAND", subject="", goal=25 },
    { key="EXP_013", category="QUESTS", title="Shattered World", description="Complete 50 unique quests in Outland.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_OUTLAND", subject="", goal=50 },
    { key="EXP_014", category="QUESTS", title="Outland Regular", description="Complete 100 unique quests in Outland.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_OUTLAND", subject="", goal=100 },
    { key="EXP_015", category="QUESTS", title="Outland Veteran", description="Complete 200 unique quests in Outland.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_OUTLAND", subject="", goal=200 },
    { key="EXP_016", category="QUESTS", title="Broken World Chronicler", description="Complete 300 unique quests in Outland.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_OUTLAND", subject="", goal=300 },
    { key="EXP_017", category="QUESTS", title="Outland Loremaster", description="Complete 400 unique quests in Outland.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_OUTLAND", subject="", goal=400 },
    { key="EXP_018", category="QUESTS", title="Every Corner of Outland", description="Complete 500 unique quests in Outland.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_OUTLAND", subject="", goal=500 },
    { key="EXP_019", category="QUESTS", title="Hellfire Arrival", description="Complete 5 unique quests in Hellfire Peninsula.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Hellfire Peninsula", goal=5 },
    { key="EXP_020", category="QUESTS", title="Honor and Survival", description="Complete 15 unique quests in Hellfire Peninsula.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Hellfire Peninsula", goal=15 },
    { key="EXP_021", category="QUESTS", title="Citadel's Shadow", description="Complete 30 unique quests in Hellfire Peninsula.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Hellfire Peninsula", goal=30 },
    { key="EXP_022", category="QUESTS", title="Peninsula Veteran", description="Complete 50 unique quests in Hellfire Peninsula.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Hellfire Peninsula", goal=50 },
    { key="EXP_023", category="QUESTS", title="Hellfire Complete", description="Complete 75 unique quests in Hellfire Peninsula.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Hellfire Peninsula", goal=75 },
    { key="EXP_024", category="QUESTS", title="Into the Marsh", description="Complete 5 unique quests in Zangarmarsh.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Zangarmarsh", goal=5 },
    { key="EXP_025", category="QUESTS", title="Spore and Steam", description="Complete 15 unique quests in Zangarmarsh.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Zangarmarsh", goal=15 },
    { key="EXP_026", category="QUESTS", title="Waters of Zangarmarsh", description="Complete 30 unique quests in Zangarmarsh.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Zangarmarsh", goal=30 },
    { key="EXP_027", category="QUESTS", title="Marsh Veteran", description="Complete 50 unique quests in Zangarmarsh.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Zangarmarsh", goal=50 },
    { key="EXP_028", category="QUESTS", title="Zangarmarsh Complete", description="Complete 75 unique quests in Zangarmarsh.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Zangarmarsh", goal=75 },
    { key="EXP_029", category="QUESTS", title="Into Terokkar", description="Complete 5 unique quests in Terokkar Forest.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Terokkar Forest", goal=5 },
    { key="EXP_030", category="QUESTS", title="Bones and Feathers", description="Complete 15 unique quests in Terokkar Forest.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Terokkar Forest", goal=15 },
    { key="EXP_031", category="QUESTS", title="Auchindoun's Reach", description="Complete 30 unique quests in Terokkar Forest.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Terokkar Forest", goal=30 },
    { key="EXP_032", category="QUESTS", title="Forest Veteran", description="Complete 50 unique quests in Terokkar Forest.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Terokkar Forest", goal=50 },
    { key="EXP_033", category="QUESTS", title="Terokkar Complete", description="Complete 75 unique quests in Terokkar Forest.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Terokkar Forest", goal=75 },
    { key="EXP_034", category="QUESTS", title="Into Nagrand", description="Complete 5 unique quests in Nagrand.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Nagrand", goal=5 },
    { key="EXP_035", category="QUESTS", title="Green Fields", description="Complete 15 unique quests in Nagrand.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Nagrand", goal=15 },
    { key="EXP_036", category="QUESTS", title="Clan and Consortium", description="Complete 30 unique quests in Nagrand.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Nagrand", goal=30 },
    { key="EXP_037", category="QUESTS", title="Nagrand Veteran", description="Complete 50 unique quests in Nagrand.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Nagrand", goal=50 },
    { key="EXP_038", category="QUESTS", title="Nagrand Complete", description="Complete 75 unique quests in Nagrand.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Nagrand", goal=75 },
    { key="EXP_039", category="QUESTS", title="Into the Blades", description="Complete 5 unique quests in Blade's Edge Mountains.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Blade's Edge Mountains", goal=5 },
    { key="EXP_040", category="QUESTS", title="Ogres and Dragons", description="Complete 15 unique quests in Blade's Edge Mountains.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Blade's Edge Mountains", goal=15 },
    { key="EXP_041", category="QUESTS", title="Highland Campaign", description="Complete 30 unique quests in Blade's Edge Mountains.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Blade's Edge Mountains", goal=30 },
    { key="EXP_042", category="QUESTS", title="Blade's Edge Veteran", description="Complete 50 unique quests in Blade's Edge Mountains.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Blade's Edge Mountains", goal=50 },
    { key="EXP_043", category="QUESTS", title="Blade's Edge Complete", description="Complete 75 unique quests in Blade's Edge Mountains.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Blade's Edge Mountains", goal=75 },
    { key="EXP_044", category="QUESTS", title="Into Netherstorm", description="Complete 5 unique quests in Netherstorm.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Netherstorm", goal=5 },
    { key="EXP_045", category="QUESTS", title="Mana and Machines", description="Complete 15 unique quests in Netherstorm.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Netherstorm", goal=15 },
    { key="EXP_046", category="QUESTS", title="Storm Campaign", description="Complete 30 unique quests in Netherstorm.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Netherstorm", goal=30 },
    { key="EXP_047", category="QUESTS", title="Netherstorm Veteran", description="Complete 50 unique quests in Netherstorm.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Netherstorm", goal=50 },
    { key="EXP_048", category="QUESTS", title="Netherstorm Complete", description="Complete 75 unique quests in Netherstorm.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Netherstorm", goal=75 },
    { key="EXP_049", category="QUESTS", title="Into Shadowmoon", description="Complete 5 unique quests in Shadowmoon Valley.", tier=1, tierName="Bronze", coins=5, xp=5, metric="QUESTS_ZONE", subject="Shadowmoon Valley", goal=5 },
    { key="EXP_050", category="QUESTS", title="Fel and Flame", description="Complete 15 unique quests in Shadowmoon Valley.", tier=2, tierName="Silver", coins=10, xp=10, metric="QUESTS_ZONE", subject="Shadowmoon Valley", goal=15 },
    { key="EXP_051", category="QUESTS", title="Valley Campaign", description="Complete 30 unique quests in Shadowmoon Valley.", tier=3, tierName="Gold", coins=20, xp=18, metric="QUESTS_ZONE", subject="Shadowmoon Valley", goal=30 },
    { key="EXP_052", category="QUESTS", title="Shadowmoon Veteran", description="Complete 50 unique quests in Shadowmoon Valley.", tier=4, tierName="Epic", coins=35, xp=30, metric="QUESTS_ZONE", subject="Shadowmoon Valley", goal=50 },
    { key="EXP_053", category="QUESTS", title="Shadowmoon Complete", description="Complete 75 unique quests in Shadowmoon Valley.", tier=5, tierName="Legendary", coins=60, xp=50, metric="QUESTS_ZONE", subject="Shadowmoon Valley", goal=75 },
    { key="EXP_054", category="QUESTS", title="First Daily", description="Complete 1 daily quests.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DAILY_QUESTS", subject="", goal=1 },
    { key="EXP_055", category="QUESTS", title="Daily Routine", description="Complete 5 daily quests.", tier=2, tierName="Silver", coins=10, xp=10, metric="DAILY_QUESTS", subject="", goal=5 },
    { key="EXP_056", category="QUESTS", title="Ten-Day Effort", description="Complete 10 daily quests.", tier=3, tierName="Gold", coins=20, xp=18, metric="DAILY_QUESTS", subject="", goal=10 },
    { key="EXP_057", category="QUESTS", title="Reliable Regular", description="Complete 25 daily quests.", tier=4, tierName="Epic", coins=35, xp=30, metric="DAILY_QUESTS", subject="", goal=25 },
    { key="EXP_058", category="QUESTS", title="Daily Veteran", description="Complete 50 daily quests.", tier=5, tierName="Legendary", coins=60, xp=50, metric="DAILY_QUESTS", subject="", goal=50 },
    { key="EXP_059", category="QUESTS", title="Hundred Dailies", description="Complete 100 daily quests.", tier=5, tierName="Legendary", coins=60, xp=50, metric="DAILY_QUESTS", subject="", goal=100 },
    { key="EXP_060", category="QUESTS", title="Outland's Daily Champion", description="Complete 250 daily quests.", tier=5, tierName="Legendary", coins=60, xp=50, metric="DAILY_QUESTS", subject="", goal=250 },
    { key="EXP_061", category="EXPLORATION", title="Seven Lands Beyond", description="Visit all seven major Outland zones.", tier=3, tierName="Gold", coins=20, xp=18, metric="OUTLAND_ZONES_VISITED", subject="", goal=7 },
    { key="EXP_062", category="EXPLORATION", title="Hellfire Peninsula Explorer", description="Discover 10 different sub-areas in Hellfire Peninsula.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Hellfire Peninsula", goal=10 },
    { key="EXP_063", category="EXPLORATION", title="Zangarmarsh Explorer", description="Discover 10 different sub-areas in Zangarmarsh.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Zangarmarsh", goal=10 },
    { key="EXP_064", category="EXPLORATION", title="Terokkar Forest Explorer", description="Discover 10 different sub-areas in Terokkar Forest.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Terokkar Forest", goal=10 },
    { key="EXP_065", category="EXPLORATION", title="Nagrand Explorer", description="Discover 8 different sub-areas in Nagrand.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Nagrand", goal=8 },
    { key="EXP_066", category="EXPLORATION", title="Blade's Edge Mountains Explorer", description="Discover 10 different sub-areas in Blade's Edge Mountains.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Blade's Edge Mountains", goal=10 },
    { key="EXP_067", category="EXPLORATION", title="Netherstorm Explorer", description="Discover 10 different sub-areas in Netherstorm.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Netherstorm", goal=10 },
    { key="EXP_068", category="EXPLORATION", title="Shadowmoon Valley Explorer", description="Discover 10 different sub-areas in Shadowmoon Valley.", tier=3, tierName="Gold", coins=20, xp=18, metric="ZONE_AREAS", subject="Shadowmoon Valley", goal=10 },
    { key="EXP_069", category="EXPLORATION", title="Hellfire Peninsula Flight Network", description="Discover 2 flight points associated with Hellfire Peninsula.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Hellfire Peninsula", goal=2 },
    { key="EXP_070", category="EXPLORATION", title="Zangarmarsh Flight Network", description="Discover 2 flight points associated with Zangarmarsh.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Zangarmarsh", goal=2 },
    { key="EXP_071", category="EXPLORATION", title="Terokkar Forest Flight Network", description="Discover 2 flight points associated with Terokkar Forest.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Terokkar Forest", goal=2 },
    { key="EXP_072", category="EXPLORATION", title="Nagrand Flight Network", description="Discover 2 flight points associated with Nagrand.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Nagrand", goal=2 },
    { key="EXP_073", category="EXPLORATION", title="Blade's Edge Mountains Flight Network", description="Discover 3 flight points associated with Blade's Edge Mountains.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Blade's Edge Mountains", goal=3 },
    { key="EXP_074", category="EXPLORATION", title="Netherstorm Flight Network", description="Discover 3 flight points associated with Netherstorm.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Netherstorm", goal=3 },
    { key="EXP_075", category="EXPLORATION", title="Shadowmoon Valley Flight Network", description="Discover 3 flight points associated with Shadowmoon Valley.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLIGHT_POINTS_ZONE", subject="Shadowmoon Valley", goal=3 },
    { key="EXP_076", category="EXPLORATION", title="Dark Portal Pilgrim", description="Cross the Dark Portal 1 time.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DARK_PORTAL_CROSSINGS", subject="", goal=1 },
    { key="EXP_077", category="EXPLORATION", title="Portal Commuter", description="Cross the Dark Portal 10 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="DARK_PORTAL_CROSSINGS", subject="", goal=10 },
    { key="EXP_078", category="EXPLORATION", title="Between Two Worlds", description="Cross the Dark Portal 50 times.", tier=4, tierName="Epic", coins=35, xp=30, metric="DARK_PORTAL_CROSSINGS", subject="", goal=50 },
    { key="EXP_079", category="EXPLORATION", title="Learning to Fly", description="Travel 10,000 estimated yards while flying in Outland.", tier=1, tierName="Bronze", coins=5, xp=5, metric="FLYING_DISTANCE", subject="", goal=10000 },
    { key="EXP_080", category="EXPLORATION", title="Outland Air Miles", description="Travel 100,000 estimated yards while flying in Outland.", tier=3, tierName="Gold", coins=20, xp=18, metric="FLYING_DISTANCE", subject="", goal=100000 },
    { key="EXP_081", category="EXPLORATION", title="Master of the Open Sky", description="Travel 500,000 estimated yards while flying in Outland.", tier=5, tierName="Legendary", coins=60, xp=50, metric="FLYING_DISTANCE", subject="", goal=500000 },
    { key="EXP_082", category="EXPLORATION", title="Homeward Bound", description="Use a Hearthstone 10 times.", tier=1, tierName="Bronze", coins=5, xp=5, metric="HEARTH_USES", subject="", goal=10 },
    { key="EXP_083", category="EXPLORATION", title="Hearthstone Regular", description="Use a Hearthstone 50 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="HEARTH_USES", subject="", goal=50 },
    { key="EXP_084", category="EXPLORATION", title="A Familiar Inn", description="Use a Hearthstone 250 times.", tier=4, tierName="Epic", coins=35, xp=30, metric="HEARTH_USES", subject="", goal=250 },
    { key="EXP_085", category="EXPLORATION", title="A Bed in Every Land", description="Bind your Hearthstone at 10 different inns.", tier=3, tierName="Gold", coins=20, xp=18, metric="INNS_BOUND", subject="", goal=10 },
    { key="EXP_086", category="DUNGEONS", title="Hellfire Ramparts: First Expedition", description="Complete Hellfire Ramparts once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="Hellfire Ramparts", goal=1 },
    { key="EXP_087", category="DUNGEONS", title="Hellfire Ramparts: Regular", description="Complete Hellfire Ramparts 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="Hellfire Ramparts", goal=10 },
    { key="EXP_088", category="DUNGEONS", title="Nazan and Vazruden: Repeated Defeat", description="Defeat Nazan and Vazruden 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Nazan and Vazruden", goal=5 },
    { key="EXP_089", category="DUNGEONS", title="Hellfire Ramparts: Heroic Victory", description="Complete Hellfire Ramparts on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="Hellfire Ramparts", goal=1 },
    { key="EXP_090", category="DUNGEONS", title="Blood Furnace: First Expedition", description="Complete The Blood Furnace once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Blood Furnace", goal=1 },
    { key="EXP_091", category="DUNGEONS", title="Blood Furnace: Regular", description="Complete The Blood Furnace 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Blood Furnace", goal=10 },
    { key="EXP_092", category="DUNGEONS", title="Keli'dan the Breaker: Repeated Defeat", description="Defeat Keli'dan the Breaker 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Keli'dan the Breaker", goal=5 },
    { key="EXP_093", category="DUNGEONS", title="Blood Furnace: Heroic Victory", description="Complete The Blood Furnace on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Blood Furnace", goal=1 },
    { key="EXP_094", category="DUNGEONS", title="Shattered Halls: First Expedition", description="Complete The Shattered Halls once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Shattered Halls", goal=1 },
    { key="EXP_095", category="DUNGEONS", title="Shattered Halls: Regular", description="Complete The Shattered Halls 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Shattered Halls", goal=10 },
    { key="EXP_096", category="DUNGEONS", title="Kargath Bladefist: Repeated Defeat", description="Defeat Kargath Bladefist 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Kargath Bladefist", goal=5 },
    { key="EXP_097", category="DUNGEONS", title="Shattered Halls: Heroic Victory", description="Complete The Shattered Halls on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Shattered Halls", goal=1 },
    { key="EXP_098", category="DUNGEONS", title="Slave Pens: First Expedition", description="Complete The Slave Pens once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Slave Pens", goal=1 },
    { key="EXP_099", category="DUNGEONS", title="Slave Pens: Regular", description="Complete The Slave Pens 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Slave Pens", goal=10 },
    { key="EXP_100", category="DUNGEONS", title="Quagmirran: Repeated Defeat", description="Defeat Quagmirran 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Quagmirran", goal=5 },
    { key="EXP_101", category="DUNGEONS", title="Slave Pens: Heroic Victory", description="Complete The Slave Pens on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Slave Pens", goal=1 },
    { key="EXP_102", category="DUNGEONS", title="Underbog: First Expedition", description="Complete The Underbog once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Underbog", goal=1 },
    { key="EXP_103", category="DUNGEONS", title="Underbog: Regular", description="Complete The Underbog 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Underbog", goal=10 },
    { key="EXP_104", category="DUNGEONS", title="The Black Stalker: Repeated Defeat", description="Defeat The Black Stalker 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="The Black Stalker", goal=5 },
    { key="EXP_105", category="DUNGEONS", title="Underbog: Heroic Victory", description="Complete The Underbog on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Underbog", goal=1 },
    { key="EXP_106", category="DUNGEONS", title="Steamvault: First Expedition", description="Complete The Steamvault once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Steamvault", goal=1 },
    { key="EXP_107", category="DUNGEONS", title="Steamvault: Regular", description="Complete The Steamvault 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Steamvault", goal=10 },
    { key="EXP_108", category="DUNGEONS", title="Warlord Kalithresh: Repeated Defeat", description="Defeat Warlord Kalithresh 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Warlord Kalithresh", goal=5 },
    { key="EXP_109", category="DUNGEONS", title="Steamvault: Heroic Victory", description="Complete The Steamvault on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Steamvault", goal=1 },
    { key="EXP_110", category="DUNGEONS", title="Mana-Tombs: First Expedition", description="Complete Mana-Tombs once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="Mana-Tombs", goal=1 },
    { key="EXP_111", category="DUNGEONS", title="Mana-Tombs: Regular", description="Complete Mana-Tombs 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="Mana-Tombs", goal=10 },
    { key="EXP_112", category="DUNGEONS", title="Nexus-Prince Shaffar: Repeated Defeat", description="Defeat Nexus-Prince Shaffar 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Nexus-Prince Shaffar", goal=5 },
    { key="EXP_113", category="DUNGEONS", title="Mana-Tombs: Heroic Victory", description="Complete Mana-Tombs on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="Mana-Tombs", goal=1 },
    { key="EXP_114", category="DUNGEONS", title="Auchenai Crypts: First Expedition", description="Complete Auchenai Crypts once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="Auchenai Crypts", goal=1 },
    { key="EXP_115", category="DUNGEONS", title="Auchenai Crypts: Regular", description="Complete Auchenai Crypts 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="Auchenai Crypts", goal=10 },
    { key="EXP_116", category="DUNGEONS", title="Exarch Maladaar: Repeated Defeat", description="Defeat Exarch Maladaar 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Exarch Maladaar", goal=5 },
    { key="EXP_117", category="DUNGEONS", title="Auchenai Crypts: Heroic Victory", description="Complete Auchenai Crypts on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="Auchenai Crypts", goal=1 },
    { key="EXP_118", category="DUNGEONS", title="Sethekk Halls: First Expedition", description="Complete Sethekk Halls once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="Sethekk Halls", goal=1 },
    { key="EXP_119", category="DUNGEONS", title="Sethekk Halls: Regular", description="Complete Sethekk Halls 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="Sethekk Halls", goal=10 },
    { key="EXP_120", category="DUNGEONS", title="Talon King Ikiss: Repeated Defeat", description="Defeat Talon King Ikiss 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Talon King Ikiss", goal=5 },
    { key="EXP_121", category="DUNGEONS", title="Sethekk Halls: Heroic Victory", description="Complete Sethekk Halls on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="Sethekk Halls", goal=1 },
    { key="EXP_122", category="DUNGEONS", title="Shadow Labyrinth: First Expedition", description="Complete Shadow Labyrinth once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="Shadow Labyrinth", goal=1 },
    { key="EXP_123", category="DUNGEONS", title="Shadow Labyrinth: Regular", description="Complete Shadow Labyrinth 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="Shadow Labyrinth", goal=10 },
    { key="EXP_124", category="DUNGEONS", title="Murmur: Repeated Defeat", description="Defeat Murmur 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Murmur", goal=5 },
    { key="EXP_125", category="DUNGEONS", title="Shadow Labyrinth: Heroic Victory", description="Complete Shadow Labyrinth on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="Shadow Labyrinth", goal=1 },
    { key="EXP_126", category="DUNGEONS", title="Old Hillsbrad Foothills: First Expedition", description="Complete Old Hillsbrad Foothills once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="Old Hillsbrad Foothills", goal=1 },
    { key="EXP_127", category="DUNGEONS", title="Old Hillsbrad Foothills: Regular", description="Complete Old Hillsbrad Foothills 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="Old Hillsbrad Foothills", goal=10 },
    { key="EXP_128", category="DUNGEONS", title="Epoch Hunter: Repeated Defeat", description="Defeat Epoch Hunter 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Epoch Hunter", goal=5 },
    { key="EXP_129", category="DUNGEONS", title="Old Hillsbrad Foothills: Heroic Victory", description="Complete Old Hillsbrad Foothills on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="Old Hillsbrad Foothills", goal=1 },
    { key="EXP_130", category="DUNGEONS", title="Black Morass: First Expedition", description="Complete The Black Morass once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Black Morass", goal=1 },
    { key="EXP_131", category="DUNGEONS", title="Black Morass: Regular", description="Complete The Black Morass 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Black Morass", goal=10 },
    { key="EXP_132", category="DUNGEONS", title="Aeonus: Repeated Defeat", description="Defeat Aeonus 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Aeonus", goal=5 },
    { key="EXP_133", category="DUNGEONS", title="Black Morass: Heroic Victory", description="Complete The Black Morass on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Black Morass", goal=1 },
    { key="EXP_134", category="DUNGEONS", title="Mechanar: First Expedition", description="Complete The Mechanar once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Mechanar", goal=1 },
    { key="EXP_135", category="DUNGEONS", title="Mechanar: Regular", description="Complete The Mechanar 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Mechanar", goal=10 },
    { key="EXP_136", category="DUNGEONS", title="Pathaleon the Calculator: Repeated Defeat", description="Defeat Pathaleon the Calculator 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Pathaleon the Calculator", goal=5 },
    { key="EXP_137", category="DUNGEONS", title="Mechanar: Heroic Victory", description="Complete The Mechanar on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Mechanar", goal=1 },
    { key="EXP_138", category="DUNGEONS", title="Botanica: First Expedition", description="Complete The Botanica once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Botanica", goal=1 },
    { key="EXP_139", category="DUNGEONS", title="Botanica: Regular", description="Complete The Botanica 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Botanica", goal=10 },
    { key="EXP_140", category="DUNGEONS", title="Warp Splinter: Repeated Defeat", description="Defeat Warp Splinter 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Warp Splinter", goal=5 },
    { key="EXP_141", category="DUNGEONS", title="Botanica: Heroic Victory", description="Complete The Botanica on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Botanica", goal=1 },
    { key="EXP_142", category="DUNGEONS", title="Arcatraz: First Expedition", description="Complete The Arcatraz once on Normal or Heroic.", tier=1, tierName="Bronze", coins=5, xp=5, metric="DUNGEON_COMPLETES", subject="The Arcatraz", goal=1 },
    { key="EXP_143", category="DUNGEONS", title="Arcatraz: Regular", description="Complete The Arcatraz 10 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="DUNGEON_COMPLETES", subject="The Arcatraz", goal=10 },
    { key="EXP_144", category="DUNGEONS", title="Harbinger Skyriss: Repeated Defeat", description="Defeat Harbinger Skyriss 5 times.", tier=2, tierName="Silver", coins=10, xp=10, metric="BOSS_KILLS", subject="Harbinger Skyriss", goal=5 },
    { key="EXP_145", category="DUNGEONS", title="Arcatraz: Heroic Victory", description="Complete The Arcatraz on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="DUNGEON_HEROIC_COMPLETES", subject="The Arcatraz", goal=1 },
    { key="EXP_146", category="DUNGEONS", title="Dungeon Sweeper I", description="Defeat 100 enemies inside five-player dungeons.", tier=1, tierName="Bronze", coins=5, xp=5, metric="WOW_DUNGEON_MOBS", subject="", goal=100 },
    { key="EXP_147", category="DUNGEONS", title="Dungeon Sweeper II", description="Defeat 500 enemies inside five-player dungeons.", tier=2, tierName="Silver", coins=10, xp=10, metric="WOW_DUNGEON_MOBS", subject="", goal=500 },
    { key="EXP_148", category="DUNGEONS", title="Dungeon Sweeper III", description="Defeat 1,000 enemies inside five-player dungeons.", tier=3, tierName="Gold", coins=20, xp=18, metric="WOW_DUNGEON_MOBS", subject="", goal=1000 },
    { key="EXP_149", category="DUNGEONS", title="Dungeon Sweeper IV", description="Defeat 2,500 enemies inside five-player dungeons.", tier=4, tierName="Epic", coins=35, xp=30, metric="WOW_DUNGEON_MOBS", subject="", goal=2500 },
    { key="EXP_150", category="DUNGEONS", title="Dungeon Sweeper V", description="Defeat 5,000 enemies inside five-player dungeons.", tier=4, tierName="Epic", coins=35, xp=30, metric="WOW_DUNGEON_MOBS", subject="", goal=5000 },
    { key="EXP_151", category="DUNGEONS", title="Dungeon Sweeper VI", description="Defeat 10,000 enemies inside five-player dungeons.", tier=5, tierName="Legendary", coins=60, xp=50, metric="WOW_DUNGEON_MOBS", subject="", goal=10000 },
    { key="EXP_152", category="DUNGEONS", title="Heroic Mob Breaker I", description="Defeat 50 enemies inside Heroic dungeons.", tier=1, tierName="Bronze", coins=5, xp=5, metric="HEROIC_DUNGEON_MOBS", subject="", goal=50 },
    { key="EXP_153", category="DUNGEONS", title="Heroic Mob Breaker II", description="Defeat 250 enemies inside Heroic dungeons.", tier=2, tierName="Silver", coins=10, xp=10, metric="HEROIC_DUNGEON_MOBS", subject="", goal=250 },
    { key="EXP_154", category="DUNGEONS", title="Heroic Mob Breaker III", description="Defeat 500 enemies inside Heroic dungeons.", tier=3, tierName="Gold", coins=20, xp=18, metric="HEROIC_DUNGEON_MOBS", subject="", goal=500 },
    { key="EXP_155", category="DUNGEONS", title="Heroic Mob Breaker IV", description="Defeat 1,000 enemies inside Heroic dungeons.", tier=4, tierName="Epic", coins=35, xp=30, metric="HEROIC_DUNGEON_MOBS", subject="", goal=1000 },
    { key="EXP_156", category="DUNGEONS", title="Heroic Mob Breaker V", description="Defeat 2,500 enemies inside Heroic dungeons.", tier=5, tierName="Legendary", coins=60, xp=50, metric="HEROIC_DUNGEON_MOBS", subject="", goal=2500 },
    { key="EXP_157", category="DUNGEONS", title="Dungeon Boss Hunter I", description="Defeat 10 five-player dungeon bosses.", tier=1, tierName="Bronze", coins=5, xp=5, metric="WOW_DUNGEON_BOSSES", subject="", goal=10 },
    { key="EXP_158", category="DUNGEONS", title="Dungeon Boss Hunter II", description="Defeat 25 five-player dungeon bosses.", tier=2, tierName="Silver", coins=10, xp=10, metric="WOW_DUNGEON_BOSSES", subject="", goal=25 },
    { key="EXP_159", category="DUNGEONS", title="Dungeon Boss Hunter III", description="Defeat 50 five-player dungeon bosses.", tier=3, tierName="Gold", coins=20, xp=18, metric="WOW_DUNGEON_BOSSES", subject="", goal=50 },
    { key="EXP_160", category="DUNGEONS", title="Dungeon Boss Hunter IV", description="Defeat 100 five-player dungeon bosses.", tier=4, tierName="Epic", coins=35, xp=30, metric="WOW_DUNGEON_BOSSES", subject="", goal=100 },
    { key="EXP_161", category="DUNGEONS", title="Dungeon Boss Hunter V", description="Defeat 250 five-player dungeon bosses.", tier=5, tierName="Legendary", coins=60, xp=50, metric="WOW_DUNGEON_BOSSES", subject="", goal=250 },
    { key="EXP_162", category="DUNGEONS", title="Heroic Boss Hunter I", description="Defeat 5 bosses on Heroic difficulty.", tier=1, tierName="Bronze", coins=5, xp=5, metric="HEROIC_DUNGEON_BOSSES", subject="", goal=5 },
    { key="EXP_163", category="DUNGEONS", title="Heroic Boss Hunter II", description="Defeat 10 bosses on Heroic difficulty.", tier=2, tierName="Silver", coins=10, xp=10, metric="HEROIC_DUNGEON_BOSSES", subject="", goal=10 },
    { key="EXP_164", category="DUNGEONS", title="Heroic Boss Hunter III", description="Defeat 25 bosses on Heroic difficulty.", tier=3, tierName="Gold", coins=20, xp=18, metric="HEROIC_DUNGEON_BOSSES", subject="", goal=25 },
    { key="EXP_165", category="DUNGEONS", title="Heroic Boss Hunter IV", description="Defeat 50 bosses on Heroic difficulty.", tier=4, tierName="Epic", coins=35, xp=30, metric="HEROIC_DUNGEON_BOSSES", subject="", goal=50 },
    { key="EXP_166", category="DUNGEONS", title="Heroic Boss Hunter V", description="Defeat 100 bosses on Heroic difficulty.", tier=5, tierName="Legendary", coins=60, xp=50, metric="HEROIC_DUNGEON_BOSSES", subject="", goal=100 },
    { key="EXP_167", category="DUNGEONS", title="Final Boss Collector I", description="Defeat 5 different five-player final bosses.", tier=1, tierName="Bronze", coins=5, xp=5, metric="UNIQUE_DUNGEON_FINAL_BOSSES", subject="", goal=5 },
    { key="EXP_168", category="DUNGEONS", title="Final Boss Collector II", description="Defeat 10 different five-player final bosses.", tier=2, tierName="Silver", coins=10, xp=10, metric="UNIQUE_DUNGEON_FINAL_BOSSES", subject="", goal=10 },
    { key="EXP_169", category="DUNGEONS", title="Every Final Boss", description="Defeat 15 different five-player final bosses.", tier=3, tierName="Gold", coins=20, xp=18, metric="UNIQUE_DUNGEON_FINAL_BOSSES", subject="", goal=15 },
    { key="EXP_170", category="DUNGEONS", title="Every Heroic Final Boss", description="Defeat 15 different five-player final bosses on Heroic difficulty.", tier=5, tierName="Legendary", coins=60, xp=50, metric="UNIQUE_HEROIC_FINAL_BOSSES", subject="", goal=15 },
    { key="EXP_171", category="DUNGEONS", title="Flawless Dungeon", description="Complete 1 dungeon run without your character dying.", tier=2, tierName="Silver", coins=10, xp=10, metric="FLAWLESS_DUNGEON_RUNS", subject="", goal=1 },
    { key="EXP_172", category="DUNGEONS", title="Flawless Regular", description="Complete 10 dungeon runs without your character dying.", tier=3, tierName="Gold", coins=20, xp=18, metric="FLAWLESS_DUNGEON_RUNS", subject="", goal=10 },
    { key="EXP_173", category="DUNGEONS", title="Untouchable Delver", description="Complete 50 dungeon runs without your character dying.", tier=5, tierName="Legendary", coins=60, xp=50, metric="FLAWLESS_DUNGEON_RUNS", subject="", goal=50 },
    { key="EXP_174", category="DUNGEONS", title="Everyone Made It", description="Defeat a dungeon final boss 1 time with the full party alive.", tier=3, tierName="Gold", coins=20, xp=18, metric="FULL_PARTY_ALIVE_RUNS", subject="", goal=1 },
    { key="EXP_175", category="DUNGEONS", title="No One Left Behind", description="Defeat a dungeon final boss 25 times with the full party alive.", tier=5, tierName="Legendary", coins=60, xp=50, metric="FULL_PARTY_ALIVE_RUNS", subject="", goal=25 },
    { key="EXP_176", category="RAIDS", title="Karazhan: First Entry", description="Enter Karazhan with a raid group.", tier=1, tierName="Bronze", coins=5, xp=5, metric="RAID_ENTRIES", subject="Karazhan", goal=1 },
    { key="EXP_177", category="RAIDS", title="Clear Karazhan", description="Defeat Prince Malchezaar in Karazhan.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Prince Malchezaar", goal=1 },
    { key="EXP_178", category="RAIDS", title="Gruul's Lair: First Entry", description="Enter Gruul's Lair with a raid group.", tier=1, tierName="Bronze", coins=5, xp=5, metric="RAID_ENTRIES", subject="Gruul's Lair", goal=1 },
    { key="EXP_179", category="RAIDS", title="Clear Gruul's Lair", description="Defeat Gruul the Dragonkiller in Gruul's Lair.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Gruul the Dragonkiller", goal=1 },
    { key="EXP_180", category="RAIDS", title="Magtheridon's Lair: First Entry", description="Enter Magtheridon's Lair with a raid group.", tier=1, tierName="Bronze", coins=5, xp=5, metric="RAID_ENTRIES", subject="Magtheridon's Lair", goal=1 },
    { key="EXP_181", category="RAIDS", title="Clear Magtheridon's Lair", description="Defeat Magtheridon in Magtheridon's Lair.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Magtheridon", goal=1 },
    { key="EXP_182", category="RAIDS", title="Serpentshrine Cavern: First Entry", description="Enter Serpentshrine Cavern with a raid group.", tier=1, tierName="Bronze", coins=5, xp=5, metric="RAID_ENTRIES", subject="Serpentshrine Cavern", goal=1 },
    { key="EXP_183", category="RAIDS", title="Clear Serpentshrine Cavern", description="Defeat Lady Vashj in Serpentshrine Cavern.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Lady Vashj", goal=1 },
    { key="EXP_184", category="RAIDS", title="Tempest Keep: The Eye: First Entry", description="Enter Tempest Keep: The Eye with a raid group.", tier=1, tierName="Bronze", coins=5, xp=5, metric="RAID_ENTRIES", subject="Tempest Keep: The Eye", goal=1 },
    { key="EXP_185", category="RAIDS", title="Clear The Eye", description="Defeat Kael'thas Sunstrider in Tempest Keep: The Eye.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Kael'thas Sunstrider", goal=1 },
    { key="EXP_186", category="RAIDS", title="Defeat Attumen the Huntsman", description="Defeat Attumen the Huntsman in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Attumen the Huntsman", goal=1 },
    { key="EXP_187", category="RAIDS", title="Defeat Moroes", description="Defeat Moroes in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Moroes", goal=1 },
    { key="EXP_188", category="RAIDS", title="Defeat Maiden of Virtue", description="Defeat Maiden of Virtue in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Maiden of Virtue", goal=1 },
    { key="EXP_189", category="RAIDS", title="Defeat The Opera Event", description="Defeat The Opera Event in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="The Opera Event", goal=1 },
    { key="EXP_190", category="RAIDS", title="Defeat The Curator", description="Defeat The Curator in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="The Curator", goal=1 },
    { key="EXP_191", category="RAIDS", title="Defeat Terestian Illhoof", description="Defeat Terestian Illhoof in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Terestian Illhoof", goal=1 },
    { key="EXP_192", category="RAIDS", title="Defeat Shade of Aran", description="Defeat Shade of Aran in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Shade of Aran", goal=1 },
    { key="EXP_193", category="RAIDS", title="Defeat Netherspite", description="Defeat Netherspite in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Netherspite", goal=1 },
    { key="EXP_194", category="RAIDS", title="Defeat The Chess Event", description="Defeat The Chess Event in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="The Chess Event", goal=1 },
    { key="EXP_195", category="RAIDS", title="Defeat Prince Malchezaar", description="Defeat Prince Malchezaar in Karazhan.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Prince Malchezaar", goal=1 },
    { key="EXP_196", category="RAIDS", title="Defeat Nightbane", description="Defeat Nightbane in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Nightbane", goal=1 },
    { key="EXP_197", category="RAIDS", title="Defeat Servant Quarters", description="Defeat Servant Quarters in Karazhan.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Servant Quarters", goal=1 },
    { key="EXP_198", category="RAIDS", title="Defeat High King Maulgar", description="Defeat High King Maulgar in Gruul's Lair.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="High King Maulgar", goal=1 },
    { key="EXP_199", category="RAIDS", title="Defeat Gruul the Dragonkiller", description="Defeat Gruul the Dragonkiller in Gruul's Lair.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Gruul the Dragonkiller", goal=1 },
    { key="EXP_200", category="RAIDS", title="Defeat Magtheridon", description="Defeat Magtheridon in Magtheridon's Lair.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Magtheridon", goal=1 },
    { key="EXP_201", category="RAIDS", title="Defeat Hydross the Unstable", description="Defeat Hydross the Unstable in Serpentshrine Cavern.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Hydross the Unstable", goal=1 },
    { key="EXP_202", category="RAIDS", title="Defeat The Lurker Below", description="Defeat The Lurker Below in Serpentshrine Cavern.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="The Lurker Below", goal=1 },
    { key="EXP_203", category="RAIDS", title="Defeat Leotheras the Blind", description="Defeat Leotheras the Blind in Serpentshrine Cavern.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Leotheras the Blind", goal=1 },
    { key="EXP_204", category="RAIDS", title="Defeat Fathom-Lord Karathress", description="Defeat Fathom-Lord Karathress in Serpentshrine Cavern.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Fathom-Lord Karathress", goal=1 },
    { key="EXP_205", category="RAIDS", title="Defeat Morogrim Tidewalker", description="Defeat Morogrim Tidewalker in Serpentshrine Cavern.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Morogrim Tidewalker", goal=1 },
    { key="EXP_206", category="RAIDS", title="Defeat Lady Vashj", description="Defeat Lady Vashj in Serpentshrine Cavern.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Lady Vashj", goal=1 },
    { key="EXP_207", category="RAIDS", title="Defeat Al'ar", description="Defeat Al'ar in Tempest Keep: The Eye.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Al'ar", goal=1 },
    { key="EXP_208", category="RAIDS", title="Defeat Void Reaver", description="Defeat Void Reaver in Tempest Keep: The Eye.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="Void Reaver", goal=1 },
    { key="EXP_209", category="RAIDS", title="Defeat High Astromancer Solarian", description="Defeat High Astromancer Solarian in Tempest Keep: The Eye.", tier=3, tierName="Gold", coins=20, xp=18, metric="RAID_BOSS_KILLS", subject="High Astromancer Solarian", goal=1 },
    { key="EXP_210", category="RAIDS", title="Defeat Kael'thas Sunstrider", description="Defeat Kael'thas Sunstrider in Tempest Keep: The Eye.", tier=4, tierName="Epic", coins=35, xp=30, metric="RAID_BOSS_KILLS", subject="Kael'thas Sunstrider", goal=1 },
    { key="EXP_211", category="COMBAT", title="Elite Hunter I", description="Defeat 25 elite enemies.", tier=1, tierName="Bronze", coins=5, xp=5, metric="ELITE_KILLS", subject="", goal=25 },
    { key="EXP_212", category="COMBAT", title="Elite Hunter II", description="Defeat 100 elite enemies.", tier=2, tierName="Silver", coins=10, xp=10, metric="ELITE_KILLS", subject="", goal=100 },
    { key="EXP_213", category="COMBAT", title="Elite Hunter III", description="Defeat 250 elite enemies.", tier=3, tierName="Gold", coins=20, xp=18, metric="ELITE_KILLS", subject="", goal=250 },
    { key="EXP_214", category="COMBAT", title="Elite Hunter IV", description="Defeat 1,000 elite enemies.", tier=4, tierName="Epic", coins=35, xp=30, metric="ELITE_KILLS", subject="", goal=1000 },
    { key="EXP_215", category="COMBAT", title="Elite Hunter V", description="Defeat 2,500 elite enemies.", tier=5, tierName="Legendary", coins=60, xp=50, metric="ELITE_KILLS", subject="", goal=2500 },
    { key="EXP_216", category="COMBAT", title="Demon Slayer I", description="Defeat 100 demon enemies.", tier=1, tierName="Bronze", coins=5, xp=5, metric="CREATURE_KILLS", subject="Demon", goal=100 },
    { key="EXP_217", category="COMBAT", title="Demon Slayer II", description="Defeat 500 demon enemies.", tier=3, tierName="Gold", coins=20, xp=18, metric="CREATURE_KILLS", subject="Demon", goal=500 },
    { key="EXP_218", category="COMBAT", title="Demon Slayer III", description="Defeat 2,000 demon enemies.", tier=5, tierName="Legendary", coins=60, xp=50, metric="CREATURE_KILLS", subject="Demon", goal=2000 },
    { key="EXP_219", category="COMBAT", title="Humanoid Hunter I", description="Defeat 250 humanoid enemies.", tier=1, tierName="Bronze", coins=5, xp=5, metric="CREATURE_KILLS", subject="Humanoid", goal=250 },
    { key="EXP_220", category="COMBAT", title="Humanoid Hunter II", description="Defeat 1,000 humanoid enemies.", tier=3, tierName="Gold", coins=20, xp=18, metric="CREATURE_KILLS", subject="Humanoid", goal=1000 },
    { key="EXP_221", category="COMBAT", title="Humanoid Hunter III", description="Defeat 5,000 humanoid enemies.", tier=5, tierName="Legendary", coins=60, xp=50, metric="CREATURE_KILLS", subject="Humanoid", goal=5000 },
    { key="EXP_222", category="COMBAT", title="Beast Hunter I", description="Defeat 250 beast enemies.", tier=1, tierName="Bronze", coins=5, xp=5, metric="CREATURE_KILLS", subject="Beast", goal=250 },
    { key="EXP_223", category="COMBAT", title="Beast Hunter II", description="Defeat 1,000 beast enemies.", tier=3, tierName="Gold", coins=20, xp=18, metric="CREATURE_KILLS", subject="Beast", goal=1000 },
    { key="EXP_224", category="COMBAT", title="Beast Hunter III", description="Defeat 5,000 beast enemies.", tier=5, tierName="Legendary", coins=60, xp=50, metric="CREATURE_KILLS", subject="Beast", goal=5000 },
    { key="EXP_225", category="COMBAT", title="Elemental Breaker I", description="Defeat 100 elemental enemies.", tier=2, tierName="Silver", coins=10, xp=10, metric="CREATURE_KILLS", subject="Elemental", goal=100 },
    { key="EXP_226", category="COMBAT", title="Elemental Breaker II", description="Defeat 1,000 elemental enemies.", tier=4, tierName="Epic", coins=35, xp=30, metric="CREATURE_KILLS", subject="Elemental", goal=1000 },
    { key="EXP_227", category="COMBAT", title="Undead Breaker I", description="Defeat 100 undead enemies.", tier=2, tierName="Silver", coins=10, xp=10, metric="CREATURE_KILLS", subject="Undead", goal=100 },
    { key="EXP_228", category="COMBAT", title="Undead Breaker II", description="Defeat 1,000 undead enemies.", tier=4, tierName="Epic", coins=35, xp=30, metric="CREATURE_KILLS", subject="Undead", goal=1000 },
    { key="EXP_229", category="COMBAT", title="Well-Timed Interrupt", description="Successfully interrupt 100 enemy casts.", tier=3, tierName="Gold", coins=20, xp=18, metric="INTERRUPTS", subject="", goal=100 },
    { key="EXP_230", category="COMBAT", title="Bring Them Back", description="Successfully resurrect other players 50 times.", tier=3, tierName="Gold", coins=20, xp=18, metric="RESURRECTIONS", subject="", goal=50 },
    { key="EXP_231", category="PROFESSIONS", title="Alchemy Apprentice", description="Reach 75 skill in Alchemy.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Alchemy", goal=75 },
    { key="EXP_232", category="PROFESSIONS", title="Alchemy Master", description="Reach 300 skill in Alchemy.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Alchemy", goal=300 },
    { key="EXP_233", category="PROFESSIONS", title="Blacksmithing Apprentice", description="Reach 75 skill in Blacksmithing.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Blacksmithing", goal=75 },
    { key="EXP_234", category="PROFESSIONS", title="Blacksmithing Master", description="Reach 300 skill in Blacksmithing.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Blacksmithing", goal=300 },
    { key="EXP_235", category="PROFESSIONS", title="Enchanting Apprentice", description="Reach 75 skill in Enchanting.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Enchanting", goal=75 },
    { key="EXP_236", category="PROFESSIONS", title="Enchanting Master", description="Reach 300 skill in Enchanting.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Enchanting", goal=300 },
    { key="EXP_237", category="PROFESSIONS", title="Engineering Apprentice", description="Reach 75 skill in Engineering.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Engineering", goal=75 },
    { key="EXP_238", category="PROFESSIONS", title="Engineering Master", description="Reach 300 skill in Engineering.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Engineering", goal=300 },
    { key="EXP_239", category="PROFESSIONS", title="Herbalism Apprentice", description="Reach 75 skill in Herbalism.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Herbalism", goal=75 },
    { key="EXP_240", category="PROFESSIONS", title="Herbalism Master", description="Reach 300 skill in Herbalism.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Herbalism", goal=300 },
    { key="EXP_241", category="PROFESSIONS", title="Jewelcrafting Apprentice", description="Reach 75 skill in Jewelcrafting.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Jewelcrafting", goal=75 },
    { key="EXP_242", category="PROFESSIONS", title="Jewelcrafting Master", description="Reach 300 skill in Jewelcrafting.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Jewelcrafting", goal=300 },
    { key="EXP_243", category="PROFESSIONS", title="Leatherworking Apprentice", description="Reach 75 skill in Leatherworking.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Leatherworking", goal=75 },
    { key="EXP_244", category="PROFESSIONS", title="Leatherworking Master", description="Reach 300 skill in Leatherworking.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Leatherworking", goal=300 },
    { key="EXP_245", category="PROFESSIONS", title="Mining Apprentice", description="Reach 75 skill in Mining.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Mining", goal=75 },
    { key="EXP_246", category="PROFESSIONS", title="Mining Master", description="Reach 300 skill in Mining.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Mining", goal=300 },
    { key="EXP_247", category="PROFESSIONS", title="Skinning Apprentice", description="Reach 75 skill in Skinning.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Skinning", goal=75 },
    { key="EXP_248", category="PROFESSIONS", title="Skinning Master", description="Reach 300 skill in Skinning.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Skinning", goal=300 },
    { key="EXP_249", category="PROFESSIONS", title="Tailoring Apprentice", description="Reach 75 skill in Tailoring.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Tailoring", goal=75 },
    { key="EXP_250", category="PROFESSIONS", title="Tailoring Master", description="Reach 300 skill in Tailoring.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Tailoring", goal=300 },
    { key="EXP_251", category="PROFESSIONS", title="Cooking Apprentice", description="Reach 75 skill in Cooking.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Cooking", goal=75 },
    { key="EXP_252", category="PROFESSIONS", title="Cooking Master", description="Reach 300 skill in Cooking.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Cooking", goal=300 },
    { key="EXP_253", category="PROFESSIONS", title="Fishing Apprentice", description="Reach 75 skill in Fishing.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="Fishing", goal=75 },
    { key="EXP_254", category="PROFESSIONS", title="Fishing Master", description="Reach 300 skill in Fishing.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="Fishing", goal=300 },
    { key="EXP_255", category="PROFESSIONS", title="First Aid Apprentice", description="Reach 75 skill in First Aid.", tier=1, tierName="Bronze", coins=5, xp=5, metric="PROF_RANK", subject="First Aid", goal=75 },
    { key="EXP_256", category="PROFESSIONS", title="First Aid Master", description="Reach 300 skill in First Aid.", tier=4, tierName="Epic", coins=35, xp=30, metric="PROF_RANK", subject="First Aid", goal=300 },
    { key="EXP_257", category="PROFESSIONS", title="Crafting Hands I", description="Craft 10 profession items.", tier=1, tierName="Bronze", coins=5, xp=5, metric="CRAFTS_TOTAL", subject="", goal=10 },
    { key="EXP_258", category="PROFESSIONS", title="Crafting Hands II", description="Craft 100 profession items.", tier=2, tierName="Silver", coins=10, xp=10, metric="CRAFTS_TOTAL", subject="", goal=100 },
    { key="EXP_259", category="PROFESSIONS", title="Crafting Hands III", description="Craft 500 profession items.", tier=3, tierName="Gold", coins=20, xp=18, metric="CRAFTS_TOTAL", subject="", goal=500 },
    { key="EXP_260", category="PROFESSIONS", title="Crafting Hands IV", description="Craft 1,000 profession items.", tier=5, tierName="Legendary", coins=60, xp=50, metric="CRAFTS_TOTAL", subject="", goal=1000 },
    { key="EXP_261", category="PROFESSIONS", title="Gatherer I", description="Gather from 50 herb, mining, or skinning sources.", tier=1, tierName="Bronze", coins=5, xp=5, metric="GATHERS_TOTAL", subject="", goal=50 },
    { key="EXP_262", category="PROFESSIONS", title="Gatherer II", description="Gather from 250 herb, mining, or skinning sources.", tier=3, tierName="Gold", coins=20, xp=18, metric="GATHERS_TOTAL", subject="", goal=250 },
    { key="EXP_263", category="PROFESSIONS", title="Gatherer III", description="Gather from 1,000 herb, mining, or skinning sources.", tier=5, tierName="Legendary", coins=60, xp=50, metric="GATHERS_TOTAL", subject="", goal=1000 },
    { key="EXP_264", category="PROFESSIONS", title="Enchanter for Hire", description="Complete 100 successful enchants on equipment.", tier=3, tierName="Gold", coins=20, xp=18, metric="ENCHANTS_TOTAL", subject="", goal=100 },
    { key="EXP_265", category="PROFESSIONS", title="Gem Cutter for Hire", description="Cut 100 gems with Jewelcrafting.", tier=3, tierName="Gold", coins=20, xp=18, metric="GEMS_CUT_TOTAL", subject="", goal=100 },
    { key="EXP_266", category="REPUTATION", title="Outland Vanguard: Honored", description="Reach Honored with Honor Hold or Thrallmar.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Honor Hold;Thrallmar", goal=5 },
    { key="EXP_267", category="REPUTATION", title="Outland Vanguard: Exalted", description="Reach Exalted with Honor Hold or Thrallmar.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Honor Hold;Thrallmar", goal=8 },
    { key="EXP_268", category="REPUTATION", title="Cenarion Ally: Honored", description="Reach Honored with Cenarion Expedition.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Cenarion Expedition", goal=5 },
    { key="EXP_269", category="REPUTATION", title="Cenarion Ally: Exalted", description="Reach Exalted with Cenarion Expedition.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Cenarion Expedition", goal=8 },
    { key="EXP_270", category="REPUTATION", title="Lower City Ally: Honored", description="Reach Honored with Lower City.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Lower City", goal=5 },
    { key="EXP_271", category="REPUTATION", title="Lower City Ally: Exalted", description="Reach Exalted with Lower City.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Lower City", goal=8 },
    { key="EXP_272", category="REPUTATION", title="Sha'tar Ally: Honored", description="Reach Honored with The Sha'tar.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="The Sha'tar", goal=5 },
    { key="EXP_273", category="REPUTATION", title="Sha'tar Ally: Exalted", description="Reach Exalted with The Sha'tar.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="The Sha'tar", goal=8 },
    { key="EXP_274", category="REPUTATION", title="Keeper of Time: Honored", description="Reach Honored with Keepers of Time.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Keepers of Time", goal=5 },
    { key="EXP_275", category="REPUTATION", title="Keeper of Time: Exalted", description="Reach Exalted with Keepers of Time.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Keepers of Time", goal=8 },
    { key="EXP_276", category="REPUTATION", title="Consortium Partner: Honored", description="Reach Honored with The Consortium.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="The Consortium", goal=5 },
    { key="EXP_277", category="REPUTATION", title="Consortium Partner: Exalted", description="Reach Exalted with The Consortium.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="The Consortium", goal=8 },
    { key="EXP_278", category="REPUTATION", title="Shattrath Allegiance: Honored", description="Reach Honored with The Aldor or The Scryers.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="The Aldor;The Scryers", goal=5 },
    { key="EXP_279", category="REPUTATION", title="Shattrath Allegiance: Exalted", description="Reach Exalted with The Aldor or The Scryers.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="The Aldor;The Scryers", goal=8 },
    { key="EXP_280", category="REPUTATION", title="Nagrand Ally: Honored", description="Reach Honored with Kurenai or The Mag'har.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Kurenai;The Mag'har", goal=5 },
    { key="EXP_281", category="REPUTATION", title="Nagrand Ally: Exalted", description="Reach Exalted with Kurenai or The Mag'har.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Kurenai;The Mag'har", goal=8 },
    { key="EXP_282", category="REPUTATION", title="Ogri'la Ally: Honored", description="Reach Honored with Ogri'la.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Ogri'la", goal=5 },
    { key="EXP_283", category="REPUTATION", title="Ogri'la Ally: Exalted", description="Reach Exalted with Ogri'la.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Ogri'la", goal=8 },
    { key="EXP_284", category="REPUTATION", title="Skyguard Ally: Honored", description="Reach Honored with Sha'tari Skyguard.", tier=2, tierName="Silver", coins=10, xp=10, metric="REPUTATION", subject="Sha'tari Skyguard", goal=5 },
    { key="EXP_285", category="REPUTATION", title="Skyguard Ally: Exalted", description="Reach Exalted with Sha'tari Skyguard.", tier=5, tierName="Legendary", coins=60, xp=50, metric="REPUTATION", subject="Sha'tari Skyguard", goal=8 },
    { key="EXP_286", category="PVP", title="First Blood", description="Earn 10 honorable kills.", tier=1, tierName="Bronze", coins=5, xp=5, metric="HONORABLE_KILLS", subject="", goal=10 },
    { key="EXP_287", category="PVP", title="Veteran Combatant", description="Earn 100 honorable kills.", tier=2, tierName="Silver", coins=10, xp=10, metric="HONORABLE_KILLS", subject="", goal=100 },
    { key="EXP_288", category="PVP", title="Battlefield Menace", description="Earn 1,000 honorable kills.", tier=4, tierName="Epic", coins=35, xp=30, metric="HONORABLE_KILLS", subject="", goal=1000 },
    { key="EXP_289", category="PVP", title="Five Thousand Enemies", description="Earn 5,000 honorable kills.", tier=5, tierName="Legendary", coins=60, xp=50, metric="HONORABLE_KILLS", subject="", goal=5000 },
    { key="EXP_290", category="PVP", title="First Battleground Win", description="Win 1 battleground.", tier=1, tierName="Bronze", coins=5, xp=5, metric="BATTLEGROUND_WINS", subject="", goal=1 },
    { key="EXP_291", category="PVP", title="Battleground Regular", description="Win 25 battlegrounds.", tier=3, tierName="Gold", coins=20, xp=18, metric="BATTLEGROUND_WINS", subject="", goal=25 },
    { key="EXP_292", category="PVP", title="Battleground Veteran", description="Win 100 battlegrounds.", tier=5, tierName="Legendary", coins=60, xp=50, metric="BATTLEGROUND_WINS", subject="", goal=100 },
    { key="EXP_293", category="PVP", title="First Arena Win", description="Win 1 rated arena match.", tier=1, tierName="Bronze", coins=5, xp=5, metric="ARENA_WINS", subject="", goal=1 },
    { key="EXP_294", category="PVP", title="Arena Regular", description="Win 25 rated arena matches.", tier=3, tierName="Gold", coins=20, xp=18, metric="ARENA_WINS", subject="", goal=25 },
    { key="EXP_295", category="PVP", title="Arena Veteran", description="Win 100 rated arena matches.", tier=5, tierName="Legendary", coins=60, xp=50, metric="ARENA_WINS", subject="", goal=100 },
    { key="EXP_296", category="COMMUNITY", title="Guilded", description="Join a guild.", tier=1, tierName="Bronze", coins=5, xp=5, metric="GUILDED", subject="", goal=1 },
    { key="EXP_297", category="COMMUNITY", title="Many Companions", description="Group with 25 different players.", tier=2, tierName="Silver", coins=10, xp=10, metric="UNIQUE_GROUP_PLAYERS", subject="", goal=25 },
    { key="EXP_298", category="COMMUNITY", title="Guild Dungeon Night", description="Complete 10 dungeons with at least three guild members in the party.", tier=3, tierName="Gold", coins=20, xp=18, metric="GUILD_DUNGEON_COMPLETES", subject="", goal=10 },
    { key="EXP_299", category="COMMUNITY", title="Friend of Azeroth", description="Have 10 characters on your in-game friends list.", tier=2, tierName="Silver", coins=10, xp=10, metric="GAME_FRIEND_COUNT", subject="", goal=10 },
    { key="EXP_300", category="COMMUNITY", title="Keeping in Touch", description="Send 100 whispers through CreshChat.", tier=3, tierName="Gold", coins=20, xp=18, metric="WHISPERS_SENT", subject="", goal=100 },
}
A.expansionCatalog = EXPANSION


local function now()
    if type(_G.GetServerTime) == "function" then return _G.GetServerTime() end
    if type(_G.time) == "function" then return _G.time() end
    if type(_G.GetTime) == "function" then return floor(_G.GetTime()) end
    return 0
end

local function trim(value)
    local text = tostring(value or "")
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalise(value)
    return lower(trim(value)):gsub("[%p%c]", " "):gsub("%s+", " ")
end

local function formatNumber(value)
    local text = tostring(floor(max(0, tonumber(value) or 0)))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if grouped:sub(1, 1) == "," then grouped = grouped:sub(2) end
    return grouped
end

local function countMap(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function safeCall(func, ...)
    if type(func) ~= "function" then return nil end
    local values = { pcall(func, ...) }
    if not values[1] then return nil end
    table.remove(values, 1)
    return (_G.unpack or table.unpack)(values)
end

local OUTLAND_ZONES = {
    [normalise("Hellfire Peninsula")] = "Hellfire Peninsula",
    [normalise("Zangarmarsh")] = "Zangarmarsh",
    [normalise("Terokkar Forest")] = "Terokkar Forest",
    [normalise("Nagrand")] = "Nagrand",
    [normalise("Blade's Edge Mountains")] = "Blade's Edge Mountains",
    [normalise("Netherstorm")] = "Netherstorm",
    [normalise("Shadowmoon Valley")] = "Shadowmoon Valley",
}

local DUNGEON_FINALS = {
    [normalise("Nazan and Vazruden")] = "Hellfire Ramparts",
    [normalise("Vazruden the Herald")] = "Hellfire Ramparts",
    [normalise("Keli'dan the Breaker")] = "The Blood Furnace",
    [normalise("Kargath Bladefist")] = "The Shattered Halls",
    [normalise("Quagmirran")] = "The Slave Pens",
    [normalise("The Black Stalker")] = "The Underbog",
    [normalise("Warlord Kalithresh")] = "The Steamvault",
    [normalise("Nexus-Prince Shaffar")] = "Mana-Tombs",
    [normalise("Exarch Maladaar")] = "Auchenai Crypts",
    [normalise("Talon King Ikiss")] = "Sethekk Halls",
    [normalise("Murmur")] = "Shadow Labyrinth",
    [normalise("Epoch Hunter")] = "Old Hillsbrad Foothills",
    [normalise("Aeonus")] = "The Black Morass",
    [normalise("Pathaleon the Calculator")] = "The Mechanar",
    [normalise("Warp Splinter")] = "The Botanica",
    [normalise("Harbinger Skyriss")] = "The Arcatraz",
}

local RAID_BOSSES = {
    [normalise("Attumen the Huntsman")] = "Karazhan", [normalise("Moroes")] = "Karazhan",
    [normalise("Maiden of Virtue")] = "Karazhan", [normalise("The Opera Event")] = "Karazhan",
    [normalise("The Curator")] = "Karazhan", [normalise("Terestian Illhoof")] = "Karazhan",
    [normalise("Shade of Aran")] = "Karazhan", [normalise("Netherspite")] = "Karazhan",
    [normalise("The Chess Event")] = "Karazhan", [normalise("Prince Malchezaar")] = "Karazhan",
    [normalise("Nightbane")] = "Karazhan", [normalise("Servant Quarters")] = "Karazhan",
    [normalise("High King Maulgar")] = "Gruul's Lair", [normalise("Gruul the Dragonkiller")] = "Gruul's Lair",
    [normalise("Magtheridon")] = "Magtheridon's Lair",
    [normalise("Hydross the Unstable")] = "Serpentshrine Cavern", [normalise("The Lurker Below")] = "Serpentshrine Cavern",
    [normalise("Leotheras the Blind")] = "Serpentshrine Cavern", [normalise("Fathom-Lord Karathress")] = "Serpentshrine Cavern",
    [normalise("Morogrim Tidewalker")] = "Serpentshrine Cavern", [normalise("Lady Vashj")] = "Serpentshrine Cavern",
    [normalise("Al'ar")] = "Tempest Keep: The Eye", [normalise("Void Reaver")] = "Tempest Keep: The Eye",
    [normalise("High Astromancer Solarian")] = "Tempest Keep: The Eye", [normalise("Kael'thas Sunstrider")] = "Tempest Keep: The Eye",
}

local BOSS_ALIASES = {
    [normalise("Romulo and Julianne")] = normalise("The Opera Event"),
    [normalise("The Big Bad Wolf")] = normalise("The Opera Event"),
    [normalise("The Crone")] = normalise("The Opera Event"),
    [normalise("Chess Event")] = normalise("The Chess Event"),
    [normalise("Rokad the Ravager")] = normalise("Servant Quarters"),
    [normalise("Shadikith the Glider")] = normalise("Servant Quarters"),
    [normalise("Hyakiss the Lurker")] = normalise("Servant Quarters"),
    [normalise("Vazruden the Herald")] = normalise("Nazan and Vazruden"),
    [normalise("Nazan")] = normalise("Nazan and Vazruden"),
}

local function expansionSave()
    local save = A:Ensure()
    if not save then return nil end
    save.expansion = type(save.expansion) == "table" and save.expansion or {}
    local e = save.expansion
    e.stats = type(e.stats) == "table" and e.stats or {}
    e.completedQuestIDs = type(e.completedQuestIDs) == "table" and e.completedQuestIDs or {}
    e.zoneQuestCounts = type(e.zoneQuestCounts) == "table" and e.zoneQuestCounts or {}
    e.zoneAreas = type(e.zoneAreas) == "table" and e.zoneAreas or {}
    e.flightPoints = type(e.flightPoints) == "table" and e.flightPoints or {}
    e.inns = type(e.inns) == "table" and e.inns or {}
    e.dungeonCompletes = type(e.dungeonCompletes) == "table" and e.dungeonCompletes or {}
    e.heroicDungeonCompletes = type(e.heroicDungeonCompletes) == "table" and e.heroicDungeonCompletes or {}
    e.bossKills = type(e.bossKills) == "table" and e.bossKills or {}
    e.raidEntries = type(e.raidEntries) == "table" and e.raidEntries or {}
    e.raidBossKills = type(e.raidBossKills) == "table" and e.raidBossKills or {}
    e.uniqueDungeonFinalBosses = type(e.uniqueDungeonFinalBosses) == "table" and e.uniqueDungeonFinalBosses or {}
    e.uniqueHeroicFinalBosses = type(e.uniqueHeroicFinalBosses) == "table" and e.uniqueHeroicFinalBosses or {}
    e.creatureKills = type(e.creatureKills) == "table" and e.creatureKills or {}
    e.reputation = type(e.reputation) == "table" and e.reputation or {}
    e.groupedPlayers = type(e.groupedPlayers) == "table" and e.groupedPlayers or {}
    e.questCache = type(e.questCache) == "table" and e.questCache or {}
    return e
end

local oldBuildCatalog = A.BuildCatalog
function A:BuildCatalog()
    oldBuildCatalog(self)
    if self.expansionBuilt then return end
    self.expansionBuilt = true
    self.categoryOrder = { "QUESTS", "EXPLORATION", "DUNGEONS", "RAIDS", "COMBAT", "PROFESSIONS", "REPUTATION", "PVP", "COMMUNITY", "CLASSES", "GAMES" }
    self.categoryNames.QUESTS = "Questing & Zones"
    self.categoryNames.EXPLORATION = "Exploration & Travel"
    self.categoryNames.RAIDS = "Raids"
    self.categoryNames.REPUTATION = "Reputation"
    self.categoryNames.PVP = "PvP"
    self.categoryNames.COMMUNITY = "Community"
    self.categoryNames.CLASSES = "Class Mastery"
    for _, item in ipairs(EXPANSION) do
        local achievement = {
            key = item.key, category = item.category,
            stat = "EXP|" .. item.metric .. "|" .. tostring(item.subject or ""),
            goal = item.goal, title = item.title, description = item.description,
            coins = item.coins, xp = item.xp, tier = item.tier, tierName = item.tierName,
            expansion = true,
        }
        self.catalog[#self.catalog + 1] = achievement
        self.byKey[achievement.key] = achievement
    end
end

local oldEnsure = A.Ensure
function A:Ensure()
    local save = oldEnsure(self)
    if not save then return nil end
    save.expansion = type(save.expansion) == "table" and save.expansion or {}
    return save
end

local function scalar(e, key)
    return floor(max(0, tonumber(e.stats[key]) or 0))
end

local function mapValue(tbl, subject)
    return floor(max(0, tonumber((tbl or {})[normalise(subject)]) or 0))
end

local oldGetStat = A.GetStat
function A:GetStat(stat)
    stat = tostring(stat or "")
    if stat:sub(1, 4) ~= "EXP|" then return oldGetStat(self, stat) end
    local metric, subject = stat:match("^EXP|([^|]+)|?(.*)$")
    local e = expansionSave()
    if not e then return 0 end
    if metric == "QUESTS_TOTAL" or metric == "QUESTS_OUTLAND" or metric == "DAILY_QUESTS" or
       metric == "DARK_PORTAL_CROSSINGS" or metric == "FLYING_DISTANCE" or metric == "HEARTH_USES" or
       metric == "WOW_DUNGEON_MOBS" or metric == "HEROIC_DUNGEON_MOBS" or metric == "WOW_DUNGEON_BOSSES" or
       metric == "HEROIC_DUNGEON_BOSSES" or metric == "FLAWLESS_DUNGEON_RUNS" or metric == "FULL_PARTY_ALIVE_RUNS" or
       metric == "ELITE_KILLS" or metric == "INTERRUPTS" or metric == "RESURRECTIONS" or metric == "CRAFTS_TOTAL" or
       metric == "GATHERS_TOTAL" or metric == "ENCHANTS_TOTAL" or metric == "GEMS_CUT_TOTAL" or
       metric == "HONORABLE_KILLS" or metric == "BATTLEGROUND_WINS" or metric == "ARENA_WINS" or
       metric == "GUILD_DUNGEON_COMPLETES" or metric == "WHISPERS_SENT" then
        return scalar(e, metric)
    end
    if metric == "QUESTS_ZONE" then return mapValue(e.zoneQuestCounts, subject) end
    if metric == "OUTLAND_ZONES_VISITED" then
        local count = 0
        for key in pairs(OUTLAND_ZONES) do if e.zoneAreas[key] then count = count + 1 end end
        return count
    end
    if metric == "ZONE_AREAS" then return countMap(e.zoneAreas[normalise(subject)]) end
    if metric == "FLIGHT_POINTS_ZONE" then return countMap(e.flightPoints[normalise(subject)]) end
    if metric == "INNS_BOUND" then return countMap(e.inns) end
    if metric == "WOW_DUNGEON_COMPLETES_TOTAL" then
        local total = 0
        for _, value in pairs(e.dungeonCompletes or {}) do total = total + floor(max(0, tonumber(value) or 0)) end
        return total
    end
    if metric == "DUNGEON_COMPLETES" then return mapValue(e.dungeonCompletes, subject) end
    if metric == "DUNGEON_HEROIC_COMPLETES" then return mapValue(e.heroicDungeonCompletes, subject) end
    if metric == "BOSS_KILLS" then return mapValue(e.bossKills, subject) end
    if metric == "UNIQUE_DUNGEON_FINAL_BOSSES" then return countMap(e.uniqueDungeonFinalBosses) end
    if metric == "UNIQUE_HEROIC_FINAL_BOSSES" then return countMap(e.uniqueHeroicFinalBosses) end
    if metric == "RAID_ENTRIES" then return mapValue(e.raidEntries, subject) end
    if metric == "RAID_BOSS_KILLS" then return mapValue(e.raidBossKills, subject) end
    if metric == "CREATURE_KILLS" then return mapValue(e.creatureKills, subject) end
    if metric == "PROF_RANK" then
        local save = oldEnsure(self)
        return floor(max(0, tonumber(save and save.professionRanks and save.professionRanks[subject]) or 0))
    end
    if metric == "REPUTATION" then
        local best = 0
        for faction in tostring(subject or ""):gmatch("[^;]+") do best = max(best, tonumber(e.reputation[normalise(faction)]) or 0) end
        return floor(best)
    end
    if metric == "GUILDED" then return type(_G.IsInGuild) == "function" and _G.IsInGuild() and 1 or scalar(e, "GUILDED") end
    if metric == "UNIQUE_GROUP_PLAYERS" then return countMap(e.groupedPlayers) end
    if metric == "GAME_FRIEND_COUNT" then
        local count = 0
        if _G.C_FriendList and type(_G.C_FriendList.GetNumFriends) == "function" then count = tonumber(safeCall(_G.C_FriendList.GetNumFriends)) or 0 end
        if type(_G.GetNumFriends) == "function" then count = max(count, tonumber(safeCall(_G.GetNumFriends)) or 0) end
        e.stats.GAME_FRIEND_COUNT = max(tonumber(e.stats.GAME_FRIEND_COUNT) or 0, count)
        return floor(e.stats.GAME_FRIEND_COUNT or 0)
    end
    return scalar(e, metric)
end

function A:RecordArea(zoneName, areaName)
    local e = expansionSave(); if not e then return end
    local zoneKey, areaKey = normalise(zoneName), normalise(areaName)
    if zoneKey == "" then return end
    e.zoneAreas[zoneKey] = type(e.zoneAreas[zoneKey]) == "table" and e.zoneAreas[zoneKey] or {}
    if areaKey ~= "" then e.zoneAreas[zoneKey][areaKey] = true end
    self:EvaluateAll(false)
end

function A:RecordTravelDistance(distance, flying)
    local e = expansionSave(); if not e then return end
    if flying then e.stats.FLYING_DISTANCE = (tonumber(e.stats.FLYING_DISTANCE) or 0) + max(0, tonumber(distance) or 0) end
end

function A:CacheQuestLog()
    local e = expansionSave(); if not e or type(_G.GetNumQuestLogEntries) ~= "function" or type(_G.GetQuestLogTitle) ~= "function" then return end
    local zone = trim((type(_G.GetRealZoneText) == "function" and _G.GetRealZoneText()) or (type(_G.GetZoneText) == "function" and _G.GetZoneText()) or "")
    local numEntries = safeCall(_G.GetNumQuestLogEntries)
    for index = 1, tonumber(numEntries) or 0 do
        local title, _, _, isHeader, _, _, frequency, questID = safeCall(_G.GetQuestLogTitle, index)
        if not isHeader and questID then
            e.questCache[tostring(questID)] = { title = tostring(title or "Quest"), zone = zone, daily = tonumber(frequency) == (tonumber(_G.LE_QUEST_FREQUENCY_DAILY) or 1) }
        end
    end
end

function A:RecordQuestTurnIn(questID, sourceGame)
    if sourceGame ~= nil and sourceGame ~= "WOW" then return end
    local e = expansionSave(); if not e then return end
    local key = tostring(questID or "")
    self.recentQuestTurnins = self.recentQuestTurnins or {}
    local stamp = now()
    if key ~= "" and stamp - (self.recentQuestTurnins[key] or 0) < 4 then return end
    if key ~= "" then self.recentQuestTurnins[key] = stamp end
    local cached = e.questCache[key] or {}
    local zone = trim(cached.zone or ((type(_G.GetRealZoneText) == "function" and _G.GetRealZoneText()) or (type(_G.GetZoneText) == "function" and _G.GetZoneText()) or ""))
    local zoneKey = normalise(zone)
    if cached.daily then e.stats.DAILY_QUESTS = scalar(e, "DAILY_QUESTS") + 1 end
    if key ~= "" and not e.completedQuestIDs[key] then
        e.completedQuestIDs[key] = { at = now(), zone = zone }
        e.stats.QUESTS_TOTAL = scalar(e, "QUESTS_TOTAL") + 1
        if OUTLAND_ZONES[zoneKey] then
            e.stats.QUESTS_OUTLAND = scalar(e, "QUESTS_OUTLAND") + 1
            e.zoneQuestCounts[zoneKey] = mapValue(e.zoneQuestCounts, zone) + 1
        end
    end
    -- Cross-addon call (wire 2/3) — Docs/INTEGRATION-CONTRACT.md Phase 7.
    if _G.CreshGamesAPI and _G.CreshGamesAPI.AddMainPassXP then _G.CreshGamesAPI.AddMainPassXP(5, "WoW quest") end
    self:EvaluateAll(false)
end

function A:ScanTaxiNodes()
    if type(_G.NumTaxiNodes) ~= "function" or type(_G.TaxiNodeName) ~= "function" or type(_G.TaxiNodeGetType) ~= "function" then return end
    local e = expansionSave(); if not e then return end
    local zone = trim((type(_G.GetRealZoneText) == "function" and _G.GetRealZoneText()) or (type(_G.GetZoneText) == "function" and _G.GetZoneText()) or "")
    local zoneKey = normalise(zone)
    if zoneKey == "" then return end
    e.flightPoints[zoneKey] = type(e.flightPoints[zoneKey]) == "table" and e.flightPoints[zoneKey] or {}
    for index = 1, tonumber(safeCall(_G.NumTaxiNodes)) or 0 do
        local nodeType = tostring(safeCall(_G.TaxiNodeGetType, index) or "")
        if nodeType == "CURRENT" or nodeType == "REACHABLE" then
            local name = trim(safeCall(_G.TaxiNodeName, index))
            if name ~= "" then e.flightPoints[zoneKey][normalise(name)] = true end
        end
    end
    self:EvaluateAll(false)
end

function A:RecordHearthUse()
    local e = expansionSave(); if not e then return end
    local stamp = now()
    if stamp - (self.lastHearthUse or 0) < 3 then return end
    self.lastHearthUse = stamp
    e.stats.HEARTH_USES = scalar(e, "HEARTH_USES") + 1
    self:EvaluateAll(false)
end

function A:RecordInnBind()
    local e = expansionSave(); if not e then return end
    local location = trim(type(_G.GetBindLocation) == "function" and safeCall(_G.GetBindLocation) or "Unknown Inn")
    if location == "" then location = "Unknown Inn" end
    e.inns[normalise(location)] = { name = location, at = now() }
    self:EvaluateAll(false)
end

function A:CheckPortalCrossing()
    local e = expansionSave(); if not e then return end
    local zone = trim((type(_G.GetRealZoneText) == "function" and _G.GetRealZoneText()) or (type(_G.GetZoneText) == "function" and _G.GetZoneText()) or "")
    local previous = self.lastExpansionZone
    self.lastExpansionZone = zone
    if not previous or previous == zone then return end
    local a, b = normalise(previous), normalise(zone)
    if (a == normalise("Blasted Lands") and b == normalise("Hellfire Peninsula")) or (b == normalise("Blasted Lands") and a == normalise("Hellfire Peninsula")) then
        e.stats.DARK_PORTAL_CROSSINGS = scalar(e, "DARK_PORTAL_CROSSINGS") + 1
        self:EvaluateAll(false)
    end
end

local oldRecordDeath = A.RecordDeath
function A:RecordDeath()
    oldRecordDeath(self)
    if self.currentRun then self.currentRun.deaths = (self.currentRun.deaths or 0) + 1 end
end

local function currentInstanceInfo()
    if type(_G.GetInstanceInfo) ~= "function" then return "", "none", 0, false end
    local name, instanceType, difficultyID, difficultyName = safeCall(_G.GetInstanceInfo)
    local heroic = tonumber(difficultyID) == 2 or lower(tostring(difficultyName or "")):find("heroic", 1, true) ~= nil
    return trim(name), tostring(instanceType or "none"), tonumber(difficultyID) or 0, heroic
end

local oldProcessInstanceState = A.ProcessInstanceState
function A:ProcessInstanceState(initial)
    oldProcessInstanceState(self, initial)
    local name, instanceType, _, heroic = currentInstanceInfo()
    local inside = instanceType == "party" or instanceType == "raid"
    if inside and (not self.currentRun or self.currentRun.name ~= name or self.currentRun.instanceType ~= instanceType) then
        self.currentRun = { name = name, instanceType = instanceType, heroic = heroic, deaths = 0, started = now() }
        local e = expansionSave()
        if e and instanceType == "raid" and name ~= "" then
            local key = normalise(name)
            e.raidEntries[key] = (tonumber(e.raidEntries[key]) or 0) + 1
            self:EvaluateAll(false)
        end
    elseif not inside then
        self.currentRun = nil
    end
end

local function allPartyAlive()
    if type(_G.UnitIsDeadOrGhost) ~= "function" then return false end
    if _G.UnitIsDeadOrGhost("player") then return false end
    for index = 1, 4 do
        local unit = "party" .. index
        if type(_G.UnitExists) == "function" and _G.UnitExists(unit) and _G.UnitIsDeadOrGhost(unit) then return false end
    end
    return true
end

local function guildGroupCount()
    local count = 0
    for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
        if type(_G.UnitExists) ~= "function" or _G.UnitExists(unit) then
            if type(_G.UnitIsInMyGuild) == "function" and _G.UnitIsInMyGuild(unit) then count = count + 1 end
        end
    end
    return count
end

local oldRecordBoss = A.RecordBoss
function A:RecordBoss(key, name, sourceGame)
    if sourceGame ~= nil and sourceGame ~= "WOW" then return end
    local base = oldEnsure(self)
    local before = base and tonumber(base.stats and base.stats.bosses) or 0
    oldRecordBoss(self, key, name)
    local after = base and tonumber(base.stats and base.stats.bosses) or 0
    if after <= before then return end
    local e = expansionSave(); if not e then return end
    local rawBossKey = normalise(name or key)
    local bossKey = BOSS_ALIASES[rawBossKey] or rawBossKey
    e.bossKills[bossKey] = (tonumber(e.bossKills[bossKey]) or 0) + 1
    local run = self.currentRun
    if not run then
        local instanceName, instanceType, _, heroic = currentInstanceInfo()
        if instanceType == "party" or instanceType == "raid" then
            run = { name = instanceName, instanceType = instanceType, heroic = heroic, deaths = 0, started = now() }
            self.currentRun = run
        end
    end
    if run and run.instanceType == "party" then
        e.stats.WOW_DUNGEON_BOSSES = scalar(e, "WOW_DUNGEON_BOSSES") + 1
        if run.heroic then e.stats.HEROIC_DUNGEON_BOSSES = scalar(e, "HEROIC_DUNGEON_BOSSES") + 1 end
        local dungeon = DUNGEON_FINALS[bossKey]
        if dungeon then
            local dungeonKey = normalise(dungeon)
            e.dungeonCompletes[dungeonKey] = (tonumber(e.dungeonCompletes[dungeonKey]) or 0) + 1
            e.uniqueDungeonFinalBosses[bossKey] = true
            if run.heroic then
                e.heroicDungeonCompletes[dungeonKey] = (tonumber(e.heroicDungeonCompletes[dungeonKey]) or 0) + 1
                e.uniqueHeroicFinalBosses[bossKey] = true
            end
            if (run.deaths or 0) == 0 then e.stats.FLAWLESS_DUNGEON_RUNS = scalar(e, "FLAWLESS_DUNGEON_RUNS") + 1 end
            if allPartyAlive() then e.stats.FULL_PARTY_ALIVE_RUNS = scalar(e, "FULL_PARTY_ALIVE_RUNS") + 1 end
            if guildGroupCount() >= 3 then e.stats.GUILD_DUNGEON_COMPLETES = scalar(e, "GUILD_DUNGEON_COMPLETES") + 1 end
            run.completed = true
        end
    elseif run and run.instanceType == "raid" then
        e.raidBossKills[bossKey] = (tonumber(e.raidBossKills[bossKey]) or 0) + 1
    elseif RAID_BOSSES[bossKey] then
        e.raidBossKills[bossKey] = (tonumber(e.raidBossKills[bossKey]) or 0) + 1
    end
    self:EvaluateAll(false)
end

function A:CaptureUnitMetadata(unit)
    if not unit or type(_G.UnitGUID) ~= "function" then return end
    local guid = _G.UnitGUID(unit); if not guid then return end
    self.unitMetadata = self.unitMetadata or {}
    local creatureType = type(_G.UnitCreatureType) == "function" and _G.UnitCreatureType(unit) or nil
    local classification = type(_G.UnitClassification) == "function" and _G.UnitClassification(unit) or nil
    self.unitMetadata[guid] = { creatureType = creatureType, classification = classification, at = now() }
end

local oldRecordWorldKill = A.RecordWorldKill
function A:RecordWorldKill(destGUID, destName)
    local e = expansionSave()
    if e then
        local meta = self.unitMetadata and self.unitMetadata[destGUID]
        if meta then
            local c = normalise(meta.creatureType)
            if c ~= "" then e.creatureKills[c] = (tonumber(e.creatureKills[c]) or 0) + 1 end
            if meta.classification == "elite" or meta.classification == "rareelite" or meta.classification == "worldboss" then
                e.stats.ELITE_KILLS = scalar(e, "ELITE_KILLS") + 1
            end
        end
        local _, instanceType, _, heroic = currentInstanceInfo()
        if instanceType == "party" then
            e.stats.WOW_DUNGEON_MOBS = scalar(e, "WOW_DUNGEON_MOBS") + 1
            if heroic then e.stats.HEROIC_DUNGEON_MOBS = scalar(e, "HEROIC_DUNGEON_MOBS") + 1 end
        end
    end
    local result = oldRecordWorldKill(self, destGUID, destName)
    if e then self:EvaluateAll(false) end
    return result
end

local oldScanProfessions = A.ScanProfessions
function A:ScanProfessions(silent)
    oldScanProfessions(self, silent)
    self:ScanReputation(silent)
end

function A:RecordTradeSkillSuccess(spellName)
    local e = expansionSave(); if not e then return end
    local profession = ""
    if type(_G.GetTradeSkillLine) == "function" then profession = trim(safeCall(_G.GetTradeSkillLine)) end
    local name = lower(tostring(spellName or ""))
    if profession ~= "" and profession ~= "UNKNOWN" then
        e.stats.CRAFTS_TOTAL = scalar(e, "CRAFTS_TOTAL") + 1
        if normalise(profession) == normalise("Enchanting") then e.stats.ENCHANTS_TOTAL = scalar(e, "ENCHANTS_TOTAL") + 1 end
        if normalise(profession) == normalise("Jewelcrafting") then e.stats.GEMS_CUT_TOTAL = scalar(e, "GEMS_CUT_TOTAL") + 1 end
    elseif name:find("herb", 1, true) or name:find("mining", 1, true) or name:find("skin", 1, true) then
        e.stats.GATHERS_TOTAL = scalar(e, "GATHERS_TOTAL") + 1
    end
    self:EvaluateAll(false)
end

function A:ScanReputation(silent)
    local e = expansionSave(); if not e or type(_G.GetNumFactions) ~= "function" or type(_G.GetFactionInfo) ~= "function" then return end
    local changed = false
    for index = 1, tonumber(safeCall(_G.GetNumFactions)) or 0 do
        local name, _, standingID = safeCall(_G.GetFactionInfo, index)
        name = trim(name)
        if name ~= "" then
            local key = normalise(name)
            local old = tonumber(e.reputation[key]) or 0
            if tonumber(standingID) and tonumber(standingID) > old then e.reputation[key] = tonumber(standingID); changed = true end
        end
    end
    if changed then self:EvaluateAll(silent == true) end
end

function A:ScanHonor()
    local e = expansionSave(); if not e then return end
    local kills = 0
    if type(_G.GetPVPLifetimeStats) == "function" then kills = tonumber((safeCall(_G.GetPVPLifetimeStats))) or 0 end
    if kills > scalar(e, "HONORABLE_KILLS") then e.stats.HONORABLE_KILLS = kills; self:EvaluateAll(false) end
end

function A:ScanGroupPlayers()
    local e = expansionSave(); if not e then return end
    local units = { "party1", "party2", "party3", "party4" }
    if type(_G.IsInRaid) == "function" and _G.IsInRaid() then
        units = {}
        local count = type(_G.GetNumGroupMembers) == "function" and tonumber(_G.GetNumGroupMembers()) or 40
        for index = 1, count do units[#units + 1] = "raid" .. index end
    end
    for _, unit in ipairs(units) do
        if type(_G.UnitExists) ~= "function" or _G.UnitExists(unit) then
            local guid = type(_G.UnitGUID) == "function" and _G.UnitGUID(unit) or nil
            local name = type(_G.GetUnitName) == "function" and _G.GetUnitName(unit, true) or (type(_G.UnitName) == "function" and _G.UnitName(unit))
            if guid or trim(name) ~= "" then e.groupedPlayers[tostring(guid or normalise(name))] = { name = name, at = now() } end
        end
    end
    self:EvaluateAll(false)
end

function A:RecordWhisperSent()
    local e = expansionSave(); if not e then return end
    e.stats.WHISPERS_SENT = scalar(e, "WHISPERS_SENT") + 1
    self:EvaluateAll(false)
end

function A:RecordInterrupt()
    local e = expansionSave(); if not e then return end
    e.stats.INTERRUPTS = scalar(e, "INTERRUPTS") + 1
    self:EvaluateAll(false)
end

function A:RecordResurrection()
    local e = expansionSave(); if not e then return end
    e.stats.RESURRECTIONS = scalar(e, "RESURRECTIONS") + 1
    self:EvaluateAll(false)
end

function A:RecordPvPWin(isArena)
    local e = expansionSave(); if not e then return end
    local key = isArena and "ARENA_WINS" or "BATTLEGROUND_WINS"
    local stamp = now()
    if stamp - (self.lastPvPWin or 0) < 20 then return end
    self.lastPvPWin = stamp
    e.stats[key] = scalar(e, key) + 1
    self:EvaluateAll(false)
end

-- Achievement browser: category + completion filters.
function A:GetPanelHeight(filter, category, status)
    self:BuildCatalog()
    local save = self:Ensure()
    local count = 0
    filter = lower(tostring(filter or "")); status = status or "ALL"
    for _, achievement in ipairs(self.catalog) do
        local complete = save and save.unlocked[achievement.key] ~= nil
        local categoryMatch = not category or category == "ALL" or achievement.category == category
        local statusMatch = status == "ALL" or (status == "COMPLETED" and complete) or (status == "INCOMPLETE" and not complete)
        local haystack = lower(table.concat({ achievement.title, achievement.description, self.categoryNames[achievement.category] or achievement.category }, " "))
        if categoryMatch and statusMatch and (filter == "" or string.find(haystack, filter, 1, true)) then count = count + 1 end
    end
    return 246 + (count * 62)
end

function A:BuildDrawerPanel(drawer, helpers)
    if drawer.achievementPanel then return drawer.achievementPanel end
    self:BuildCatalog()
    local createButton, createFont = helpers.createButton, helpers.createFont
    local applyBackdrop, colors, templateName = helpers.applyBackdrop, helpers.colors, helpers.templateName
    local panel = CreateFrame("Frame", nil, drawer.content)
    panel:SetPoint("TOPLEFT", drawer.content, "TOPLEFT", 0, 0)
    panel:SetPoint("TOPRIGHT", drawer.content, "TOPRIGHT", 0, 0)
    panel:SetHeight(self:GetPanelHeight())
    panel.searchText, panel.category, panel.status, panel.classFilter = "", "ALL", "ALL", "ALL"
    drawer.achievementPanel = panel

    panel.hero = CreateFrame("Frame", nil, panel, templateName())
    panel.hero:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0); panel.hero:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0); panel.hero:SetHeight(72)
    applyBackdrop(panel.hero, colors.panelSoft, colors.quest)
    panel.title = createFont(panel.hero, 14, colors.text, "LEFT"); panel.title:SetPoint("TOPLEFT", panel.hero, "TOPLEFT", 10, -9); panel.title:SetText("ACCOUNT ACHIEVEMENTS")
    panel.summary = createFont(panel.hero, 9, colors.muted, "LEFT"); panel.summary:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -5); panel.summary:SetPoint("RIGHT", panel.hero, "RIGHT", -10, 0)

    panel.searchFrame = CreateFrame("Frame", nil, panel, templateName())
    panel.searchFrame:SetPoint("TOPLEFT", panel.hero, "BOTTOMLEFT", 0, -7); panel.searchFrame:SetPoint("TOPRIGHT", panel.hero, "BOTTOMRIGHT", 0, -7); panel.searchFrame:SetHeight(30)
    applyBackdrop(panel.searchFrame, colors.panelRaised, colors.border)
    panel.search = CreateFrame("EditBox", nil, panel.searchFrame, templateName())
    panel.search:SetPoint("TOPLEFT", panel.searchFrame, "TOPLEFT", 8, -4); panel.search:SetPoint("BOTTOMRIGHT", panel.searchFrame, "BOTTOMRIGHT", -8, 4)
    panel.search:SetAutoFocus(false); panel.search:SetFontObject(_G.GameFontNormalSmall or _G.GameFontHighlightSmall); panel.search:SetTextInsets(2,2,0,0); panel.search:SetMaxLetters(50)
    panel.search:SetScript("OnEscapePressed", function(box) box:ClearFocus() end); panel.search:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    panel.search:SetScript("OnTextChanged", function(box) panel.searchText = tostring(box:GetText() or ""); A:RefreshDrawerPanel(drawer, helpers, true) end)
    panel.searchHint = createFont(panel.searchFrame, 8, colors.muted, "LEFT"); panel.searchHint:SetPoint("LEFT", panel.searchFrame, "LEFT", 10, 0); panel.searchHint:SetText("Search achievements, zones, bosses or types...")
    panel.search:SetScript("OnEditFocusGained", function() panel.searchHint:Hide() end); panel.search:SetScript("OnEditFocusLost", function(box) panel.searchHint:SetShown((box:GetText() or "") == "") end)

    panel.filters = CreateFrame("Frame", nil, panel)
    panel.filters:SetPoint("TOPLEFT", panel.searchFrame, "BOTTOMLEFT", 0, -6); panel.filters:SetPoint("TOPRIGHT", panel.searchFrame, "BOTTOMRIGHT", 0, -6); panel.filters:SetHeight(124)
    panel.statusButtons, panel.filterButtons = {}, {}
    local statusDefs = { {"ALL","ALL",58}, {"INCOMPLETE","IN PROGRESS",92}, {"COMPLETED","COMPLETED",82} }
    local previous
    for _, item in ipairs(statusDefs) do
        local key,label,width = item[1],item[2],item[3]
        local button = createButton(panel.filters, label, width, 24, function() panel.status = key; A:RefreshDrawerPanel(drawer, helpers, true) end)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 4, 0) else button:SetPoint("TOPLEFT", panel.filters, "TOPLEFT", 0, 0) end
        panel.statusButtons[key] = button; previous = button
    end
    local categoryDefs = {
        {"ALL","ALL",42},{"QUESTS","QUESTS",58},{"EXPLORATION","EXPLORE",62},{"DUNGEONS","DUNGEON",62},{"RAIDS","RAIDS",50},
        {"COMBAT","COMBAT",54},{"PROFESSIONS","PROF",46},{"REPUTATION","REP",42},{"PVP","PVP",40},{"COMMUNITY","SOCIAL",52},{"CLASSES","CLASSES",58},{"GAMES","GAMES",48},
    }
    previous = nil
    for index,item in ipairs(categoryDefs) do
        local key,label,width = item[1],item[2],item[3]
        local button = createButton(panel.filters, label, width, 24, function() panel.category = key; A:RefreshDrawerPanel(drawer, helpers, true) end)
        if index == 1 then button:SetPoint("TOPLEFT", panel.filters, "TOPLEFT", 0, -34)
        elseif index == 7 then button:SetPoint("TOPLEFT", panel.filters, "TOPLEFT", 0, -64)
        else button:SetPoint("LEFT", previous, "RIGHT", 3, 0) end
        panel.filterButtons[key] = button; previous = button
    end

    panel.classButtons = {}
    local classDefs = {
        {"ALL","ALL CLS",50},{"DRUID","DRU",38},{"HUNTER","HUN",38},{"MAGE","MAG",38},{"PALADIN","PAL",38},
        {"PRIEST","PRI",38},{"ROGUE","ROG",38},{"SHAMAN","SHA",38},{"WARLOCK","WLK",38},{"WARRIOR","WAR",38},
    }
    previous = nil
    for index,item in ipairs(classDefs) do
        local key,label,width = item[1],item[2],item[3]
        local button = createButton(panel.filters, label, width, 22, function() panel.classFilter = key; A:RefreshDrawerPanel(drawer, helpers, true) end)
        if index == 1 then button:SetPoint("TOPLEFT", panel.filters, "TOPLEFT", 0, -94) else button:SetPoint("LEFT", previous, "RIGHT", 3, 0) end
        panel.classButtons[key] = button; previous = button
    end

    panel.rows = {}
    for index, achievement in ipairs(self.catalog) do
        local row = CreateFrame("Frame", nil, panel, templateName())
        row:SetPoint("TOPLEFT", panel.filters, "BOTTOMLEFT", 0, -8); row:SetPoint("TOPRIGHT", panel.filters, "BOTTOMRIGHT", 0, -8); row:SetHeight(56)
        applyBackdrop(row, colors.panelSoft, colors.border)
        row.title = createFont(row, 10, colors.text, "LEFT"); row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 9, -7); row.title:SetPoint("RIGHT", row, "RIGHT", -88, 0)
        row.detail = createFont(row, 8, colors.muted, "LEFT"); row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4); row.detail:SetPoint("RIGHT", row, "RIGHT", -88, 0)
        row.progress = createFont(row, 8, colors.muted, "RIGHT"); row.progress:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -7)
        row.reward = createFont(row, 8, colors.quest, "RIGHT"); row.reward:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 7)
        row.achievement = achievement; panel.rows[index] = row
    end
    self:RefreshDrawerPanel(drawer, helpers, false)
    return panel
end

function A:RefreshDrawerPanel(drawer, helpers, resetScroll)
    local panel = drawer and drawer.achievementPanel; if not panel then return end
    local applyBackdrop, darken, colors = helpers.applyBackdrop, helpers.darken, helpers.colors
    self:EvaluateAll(true)
    local save = self:Ensure(); local unlocked,total = self:GetCounts(); local points = self:GetPoints()
    panel.summary:SetText(string.format("%d / %d unlocked · %s achievement points · TBC, class and game goals · account-wide rewards", unlocked,total,formatNumber(points)))
    if panel.searchHint then panel.searchHint:SetShown((panel.search:GetText() or "") == "" and not panel.search:HasFocus()) end
    for key,button in pairs(panel.statusButtons or {}) do
        local active = panel.status == key
        if helpers.setAccent then helpers.setAccent(button, active and colors.quest or colors.border, active) end
    end
    for key,button in pairs(panel.filterButtons or {}) do
        local active = panel.category == key
        if helpers.setAccent then helpers.setAccent(button, active and colors.quest or colors.border, active) end
    end
    local showClassFilters = panel.category == "CLASSES"
    panel.filters:SetHeight(showClassFilters and 124 or 94)
    for key,button in pairs(panel.classButtons or {}) do
        button:SetShown(showClassFilters)
        local active = panel.classFilter == key
        if helpers.setAccent then helpers.setAccent(button, active and colors.quest or colors.border, active) end
    end
    local filter = lower(tostring(panel.searchText or "")); local y = 0
    for _,row in ipairs(panel.rows or {}) do
        local ach = row.achievement; local complete = save.unlocked[ach.key] ~= nil
        local categoryMatch = panel.category == "ALL" or panel.category == ach.category
        local classMatch = panel.category ~= "CLASSES" or panel.classFilter == "ALL" or ach.classToken == panel.classFilter
        local statusMatch = panel.status == "ALL" or (panel.status == "COMPLETED" and complete) or (panel.status == "INCOMPLETE" and not complete)
        local haystack = lower(table.concat({ ach.title,ach.description,self.categoryNames[ach.category] or ach.category,ach.classToken or "" }," "))
        local searchMatch = filter == "" or string.find(haystack,filter,1,true)
        if categoryMatch and classMatch and statusMatch and searchMatch then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", panel.filters, "BOTTOMLEFT", 0, -8-y); row:SetPoint("TOPRIGHT", panel.filters, "BOTTOMRIGHT", 0, -8-y); y=y+62
            local value = self:GetStat(ach.stat)
            local tierText = ach.tierName or ("Tier " .. tostring(ach.tier))
            local categoryLabel = self.categoryNames[ach.category] or ach.category
            if ach.classToken then categoryLabel = categoryLabel .. " · " .. ach.classToken end
            row.title:SetText((complete and "✓ " or "") .. ach.title .. "  ·  " .. upper(tierText) .. "  ·  " .. categoryLabel)
            row.detail:SetText(ach.description)
            row.progress:SetText(complete and "COMPLETED" or (formatNumber(min(value,ach.goal)) .. "/" .. formatNumber(ach.goal)))
            row.reward:SetText("+" .. ach.coins .. " coins · +" .. ach.xp .. " XP")
            applyBackdrop(row, complete and darken(colors.green,0.58) or colors.panelSoft, complete and colors.green or colors.border)
            row:Show()
        else row:Hide() end
    end
    local height = (showClassFilters and 246 or 216)+y; panel:SetHeight(height)
    if drawer.mode == "ACHIEVEMENTS" then drawer.content:SetHeight(max(240,height)); if resetScroll and CC.UI and CC.UI.SetGameDrawerScroll then CC.UI:SetGameDrawerScroll(0) end end
    if drawer.achievementMode and drawer.achievementMode.label then drawer.achievementMode.label:SetText("ACH "..tostring(unlocked).."/"..tostring(total)) end
end

local frame = CreateFrame("Frame")
local function register(event) if frame and frame.RegisterEvent then pcall(frame.RegisterEvent, frame, event) end end
for _,event in ipairs({
    "PLAYER_LOGIN","PLAYER_ENTERING_WORLD","QUEST_ACCEPTED","QUEST_LOG_UPDATE","QUEST_COMPLETE","QUEST_FINISHED","QUEST_TURNED_IN","TAXIMAP_OPENED","HEARTHSTONE_BOUND",
    "ZONE_CHANGED_NEW_AREA","GROUP_ROSTER_UPDATE","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED",
    "COMBAT_LOG_EVENT_UNFILTERED","UNIT_SPELLCAST_SUCCEEDED","UPDATE_FACTION","PLAYER_PVP_KILLS_CHANGED",
    "CHAT_MSG_WHISPER_INFORM","CHAT_MSG_BN_WHISPER_INFORM","CHAT_MSG_BG_SYSTEM_ALLIANCE","CHAT_MSG_BG_SYSTEM_HORDE","CHAT_MSG_BG_SYSTEM_NEUTRAL",
}) do register(event) end

frame:SetScript("OnEvent", function(_, event, ...)
    if not CC:IsFeatureEnabled("worldProgression") then return end
    if event == "PLAYER_LOGIN" then
        A:BuildCatalog(); expansionSave(); A:CacheQuestLog(); A:ScanReputation(true); A:ScanHonor(); A:ScanGroupPlayers(); A:CheckPortalCrossing(); A:EvaluateAll(true)
    elseif event == "PLAYER_ENTERING_WORLD" then
        A:ProcessInstanceState(true); A:CheckPortalCrossing(); A:ScanGroupPlayers()
    elseif event == "QUEST_ACCEPTED" or event == "QUEST_LOG_UPDATE" then
        A:CacheQuestLog()
    elseif event == "QUEST_COMPLETE" then
        local questID = type(_G.GetQuestID) == "function" and _G.GetQuestID() or nil
        if not questID and type(_G.GetQuestLogSelection) == "function" and type(_G.GetQuestLogTitle) == "function" then
            local index = _G.GetQuestLogSelection()
            local _, _, _, _, _, _, _, selectedID = safeCall(_G.GetQuestLogTitle, index)
            questID = selectedID
        end
        A.pendingQuestTurnIn = questID
    elseif event == "QUEST_FINISHED" then
        if A.pendingQuestTurnIn then A:RecordQuestTurnIn(A.pendingQuestTurnIn); A.pendingQuestTurnIn = nil end
        A:CacheQuestLog()
    elseif event == "QUEST_TURNED_IN" then
        A:RecordQuestTurnIn(select(1, ...)); A.pendingQuestTurnIn = nil; A:CacheQuestLog()
    elseif event == "TAXIMAP_OPENED" then A:ScanTaxiNodes()
    elseif event == "HEARTHSTONE_BOUND" then A:RecordInnBind()
    elseif event == "ZONE_CHANGED_NEW_AREA" then A:CheckPortalCrossing()
    elseif event == "GROUP_ROSTER_UPDATE" then A:ScanGroupPlayers()
    elseif event == "PLAYER_TARGET_CHANGED" then A:CaptureUnitMetadata("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then A:CaptureUnitMetadata("mouseover")
    elseif event == "NAME_PLATE_UNIT_ADDED" then A:CaptureUnitMetadata(select(1,...))
    elseif event == "UPDATE_FACTION" then A:ScanReputation(false)
    elseif event == "PLAYER_PVP_KILLS_CHANGED" then A:ScanHonor()
    elseif event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_BN_WHISPER_INFORM" then A:RecordWhisperSent()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" then
            local spellName = type(_G.GetSpellInfo) == "function" and _G.GetSpellInfo(spellID) or nil
            if tonumber(spellID) == 8690 or lower(tostring(spellName or "")):find("hearthstone",1,true) then A:RecordHearthUse() end
            local tradeVisible = _G.TradeSkillFrame and _G.TradeSkillFrame.IsShown and _G.TradeSkillFrame:IsShown()
            if tradeVisible or lower(tostring(spellName or "")):find("mining",1,true) or lower(tostring(spellName or "")):find("skin",1,true) or lower(tostring(spellName or "")):find("herb",1,true) then A:RecordTradeSkillSuccess(spellName) end
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and type(_G.CombatLogGetCurrentEventInfo) == "function" then
        local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID, spellName = _G.CombatLogGetCurrentEventInfo()
        local playerGUID = type(_G.UnitGUID) == "function" and _G.UnitGUID("player") or nil
        if sourceGUID and playerGUID and sourceGUID == playerGUID then
            if subevent == "SPELL_INTERRUPT" then A:RecordInterrupt()
            elseif subevent == "SPELL_RESURRECT" then A:RecordResurrection()
            elseif subevent == "SPELL_CAST_SUCCESS" and (tonumber(spellID) == 8690 or lower(tostring(spellName or "")):find("hearthstone",1,true)) then A:RecordHearthUse() end
        end
    elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or event == "CHAT_MSG_BG_SYSTEM_HORDE" or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        local text = lower(tostring(select(1,...) or ""))
        if text:find("wins",1,true) or text:find("victory",1,true) then
            local _, instanceType = currentInstanceInfo()
            local faction = lower(tostring(type(_G.UnitFactionGroup)=="function" and _G.UnitFactionGroup("player") or ""))
            if instanceType == "arena" then
                local winner = type(_G.GetBattlefieldWinner) == "function" and tonumber(_G.GetBattlefieldWinner()) or nil
                local team = type(_G.GetBattlefieldArenaFaction) == "function" and tonumber(_G.GetBattlefieldArenaFaction()) or nil
                if winner ~= nil and team ~= nil and winner == team then A:RecordPvPWin(true) end
            elseif (event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" and faction == "alliance") or (event == "CHAT_MSG_BG_SYSTEM_HORDE" and faction == "horde") then A:RecordPvPWin(false) end
        end
    end
end)
