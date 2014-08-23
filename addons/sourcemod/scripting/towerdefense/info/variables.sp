/*======================================
=            Data Variables            =
======================================*/

new String:g_sTowerData[TDTowerId][TDTowerData][96];



/*=========================================
=            Generic Variables            =
=========================================*/

/*==========  Boolean  ==========*/

new bool:g_bEnabled;
new bool:g_bMapRunning;
new bool:g_bSteamTools;
new bool:g_bTowerDefenseMap;

/*==========  Handle  ==========*/

new Handle:g_hEnabled;

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iHaloMaterial;
new g_iLaserMaterial;

/*==========  String  ==========*/



/*========================================
=            Client Variables            =
========================================*/

/*==========  Boolean  ==========*/

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iAttachedTower[MAXPLAYERS + 1];
new g_iLastButtons[MAXPLAYERS + 1];

/*==========  String  ==========*/



/*=======================================
=            Tower Variables            =
=======================================*/

/*==========  Boolean  ==========*/

/*==========  Handle  ==========*/

/*==========  Float  ==========*/

/*==========  Integer  ==========*/

new g_iUpgradeLevel[MAXPLAYERS + 1];
new g_iUpgradeMetal[MAXPLAYERS + 1];

/*==========  String  ==========*/