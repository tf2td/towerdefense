enum TDBloodColor
{
	TDBlood_None = -1,
	TDBlood_Color_Red = 0,
	TDBlood_Color_Yellow,
	TDBlood_Color_Green,
	TDBlood_Color_Mech
};

enum TDMetalPackType
{
	TDMetalPack_Small = 0,
	TDMetalPack_Medium,
	TDMetalPack_Large
};

enum TDMetalPackReturn
{
	TDMetalPack_InvalidMetal = 0,
	TDMetalPack_LimitReached,
	TDMetalPack_InvalidType,
	TDMetalPack_SpawnedPack
};

enum TDBuildingType
{
	TDBuilding_Dispenser = 0,
	TDBuilding_TeleporterEntry,
	TDBuilding_Sentry,
	TDBuilding_TeleporterExit
};

enum TDTowerId
{
	TDTower_Invalid				= -1,
	TDTower_Engineer			=  0,
	TDTower_Sniper				=  1,
	TDTower_Medic				=  2,
	TDTower_Grenade				=  3,
	TDTower_Pyro				=  4,
	TDTower_Jarate				=  5,
	TDTower_AnitAir_Rocket		=  6,
	TDTower_AntiAir_Flare		=  7,
	TDTower_Crossbow			=  8,
	TDTower_Flare				=  9,
	TDTower_Heavy				= 10,
	TDTower_Shotgun				= 11,
	TDTower_Knockback			= 12,
	TDTower_Rocket				= 13,
	TDTower_Rapidflare			= 14,
	TDTower_Backburner_Pyro		= 15,
	TDTower_Lochnload_Demoman	= 16,
	TDTower_Machina_Sniper		= 17,
	TDTower_Liberty_Soldier		= 18,
	TDTower_Juggle_Soldier		= 19,
	TDTower_Bushwacka_Sniper	= 20,
	TDTower_Natascha_Heavy		= 21,
	TDTower_Guillotine_Scout	= 22,
	TDTower_Homewrecker_Pyro	= 23,
	TDTower_Airblast_Pyro		= 24,
	TDTower_AoE_Engineer		= 25,
	TDTower_Kritz_Medic			= 26,
	TDTower_Quantity
};

enum TDWaveType
{
	TDWaveType_None = 0,
	TDWaveType_Boss,
	TDWaveType_Rapid,
	TDWaveType_Regen,
	TDWaveType_KnockbackImmune,
	TDWaveType_Air,
	TDWaveType_JarateImmune
};