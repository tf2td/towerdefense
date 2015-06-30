/*======================================
=            Data Variables            =
======================================*/

Handle g_hMapTowers;
Handle g_hMapWeapons;
Handle g_hMapWaves;
Handle g_hMapMetalpacks;


/*=========================================
=            Generic Variables            =
=========================================*/

/*==========  Boolean  ==========*/

bool g_bConfigsExecuted;
bool g_bEnabled;
bool g_bLockable;
bool g_bMapRunning;
bool g_bServerInitialized;
bool g_bSteamTools;
bool g_bTF2Attributes;
bool g_bTowerDefenseMap;

/*==========  Handle  ==========*/

Handle g_hEnabled;
Handle hHintTimer;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

int g_iBuildingLimit[TDBuildingType];
int g_iHaloMaterial;
int g_iLaserMaterial;
int g_iMetalPackCount;
int iHint = 1;

/*==========  String  ==========*/
char PasswordListOfChar[] = "aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ0123456789";


/*==========================================
=            Database Variables            =
==========================================*/

/*==========  Boolean  ==========*/

/*==========  Handle  ==========*/

Handle g_hDatabase;

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

/*==========  String  ==========*/



/*=======================================
=            Tower Variables            =
=======================================*/

/*==========  Boolean  ==========*/

int g_bTowerBought[TDTowerId];

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

int g_iLastMover[MAXPLAYERS + 1];
int g_iUpgradeLevel[MAXPLAYERS + 1];
int g_iUpgradeMetal[MAXPLAYERS + 1];

/*==========  String  ==========*/


/*======================================
=            Wave Variables            =
======================================*/

/*==========  Boolean  ==========*/

bool g_bBoostWave;
bool g_bStartWaveEarly;

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

float g_fWaveStartButtonLocation[3];

/*==========  Integer  ==========*/

int g_iCurrentWave;
int g_iHealthBar;
int g_iNextWaveType;
int g_iRespawnWaveTime;
int g_iWaveStartButton;

/*==========  String  ==========*/