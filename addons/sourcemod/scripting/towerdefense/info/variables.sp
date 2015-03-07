/*======================================
=            Data Variables            =
======================================*/

new Handle:g_hMapTowers;
new Handle:g_hMapWeapons;
new Handle:g_hMapWaves;
new Handle:g_hMapMetalpacks;


/*=========================================
=            Generic Variables            =
=========================================*/

/*==========  Boolean  ==========*/

new bool:g_bConfigsExecuted;
new bool:g_bEnabled;
new bool:g_bLockable;
new bool:g_bMapRunning;
new bool:g_bServerInitialized;
new bool:g_bSteamTools;
new bool:g_bTF2Attributes;
new bool:g_bTowerDefenseMap;

/*==========  Handle  ==========*/

new Handle:g_hEnabled;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iBuildingLimit[TDBuildingType];
new g_iHaloMaterial;
new g_iLaserMaterial;
new g_iMetalPackCount;

/*==========  String  ==========*/



/*==========================================
=            Database Variables            =
==========================================*/

/*==========  Boolean  ==========*/

/*==========  Handle  ==========*/

new Handle:g_hDatabase;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iServerId;
new g_iServerMap;
new g_iServerPort;

/*==========  String  ==========*/

new String:g_sServerIp[16];



/*========================================
=            Client Variables            =
========================================*/

/*==========  Boolean  ==========*/

new bool:g_bCarryingObject[MAXPLAYERS + 1];
new bool:g_bInsideNobuild[MAXPLAYERS + 1];
new bool:g_bPickupSentry[MAXPLAYERS + 1];
new bool:g_bReplaceWeapon[MAXPLAYERS + 1][3];

/*==========  Handle  ==========*/

new Handle:g_hPlayerData;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iAttachedTower[MAXPLAYERS + 1];
new g_iLastButtons[MAXPLAYERS + 1];

/*==========  String  ==========*/



/*=======================================
=            Tower Variables            =
=======================================*/

/*==========  Boolean  ==========*/

new g_bTowerBought[TDTowerId];

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iLastMover[MAXPLAYERS + 1];
new g_iUpgradeLevel[MAXPLAYERS + 1];
new g_iUpgradeMetal[MAXPLAYERS + 1];

/*==========  String  ==========*/


/*======================================
=            Wave Variables            =
======================================*/

/*==========  Boolean  ==========*/

new bool:g_bBoostWave[MAXPLAYERS + 1];
new bool:g_bStartWaveEarly;

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

new Float:g_fWaveStartButtonLocation[3];

/*==========  Integer  ==========*/

new g_iCurrentWave;
new g_iHealthBar;
new g_iNextWaveType;
new g_iRespawnWaveTime;
new g_iWaveStartButton;

/*==========  String  ==========*/