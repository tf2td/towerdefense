/*======================================
=            Data Variables            =
======================================*/

Handle g_hMapTowers;
Handle g_hMapWeapons;
Handle g_hMapWaves;
Handle g_hMapMetalpacks;
Handle g_hMultiplierType;
Handle g_hMultiplier;
Handle g_hServerData;

int g_iTime;

/*=========================================
=            Generic Variables            =
=========================================*/

/*==========  Boolean  ==========*/

bool g_bConfigsExecuted;
bool g_bEnabled;
bool g_bLockable;
bool g_bMapRunning;
bool g_bServerInitialized;
bool g_bSteamWorks;
bool g_bTF2Attributes;
bool g_bTowerDefenseMap;
bool g_bCanGetUnlocks;

/*==========  ConVar  ==========*/

ConVar g_hEnabled;
ConVar g_hTfBotQuota;
ConVar g_hMaxBotsOnField;

/*==========  Handle  ==========*/

Handle hHintTimer;

/*==========  Float  ==========*/

float fMultiplier[50];

/*==========  Integer  ==========*/

int g_iBuildingLimit[TDBuildingType];
int g_iHaloMaterial;
int g_iLaserMaterial;
int g_iMetalPackCount;
int iMaxWaves;
int iMaxMultiplierTypes;
int g_iBotsToSpawn;
int g_iTotalBotsLeft;
int g_iMaxClients;

/*==========  String  ==========*/

char g_sPassword[8];

/*==========================================
=            Database Variables            =
==========================================*/

/*==========  Boolean  ==========*/

/*==========  Handle  ==========*/

Database g_hDatabase;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

int g_iServerId;
int g_iServerMap;
int g_iServerPort;

/*==========  String  ==========*/

char g_sServerIp[16];



/*========================================
=            Client Variables            =
========================================*/

/*==========  Boolean  ==========*/

bool g_bCarryingObject[MAXPLAYERS + 1];
bool g_bInsideNobuild[MAXPLAYERS + 1];
bool g_bPickupSentry[MAXPLAYERS + 1];
bool g_bReplaceWeapon[MAXPLAYERS + 1][3];

/*==========  Handle  ==========*/

Handle g_hPlayerData;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

int g_iAttachedTower[MAXPLAYERS + 1];
int g_iLastButtons[MAXPLAYERS + 1];
int g_iHealBeamIndex[MAXPLAYERS + 1][2];

/*==========  String  ==========*/



/*=======================================
=            Tower Variables            =
=======================================*/

/*==========  Boolean  ==========*/

int g_bTowerBought[TDTowerId];
bool g_bTowersLocked;
bool g_bAoEEngineerAttack;
bool g_bKritzMedicCharged;

/*==========  Handle  ==========*/

Handle hAoETimer;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

int g_iLastMover[MAXPLAYERS + 1];
int g_iUpgradeLevel[MAXPLAYERS + 1];
int g_iUpgradeMetal[MAXPLAYERS + 1];
int iAoEEngineerTimer;
int iAoEKritzMedicTimer;

/*==========  String  ==========*/


/*======================================
=            Wave Variables            =
======================================*/

/*==========  Boolean  ==========*/

bool g_bBoostWave;
bool g_bStartWaveEarly;
bool g_iSlowAttacker[MAXPLAYERS + 1];

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

float g_fAirWaveSpawn[3];
float g_fWaveStartButtonLocation[3];
float g_fBeamPoints[MAXPLAYERS + 1][8][3];

/*==========  Integer  ==========*/

int g_iCurrentWave;
int g_iHealthBar;
int g_iNextWaveType;
int g_iRespawnWaveTime;
int g_iWaveStartButton;

/*==========  String  ==========*/

char g_sAirWaveSpawn[64];