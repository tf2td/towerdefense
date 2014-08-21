#pragma semicolon 1

#include <sourcemod>

/*=================================
=            Constants            =
=================================*/

#define PLUGIN_NAME		"TF2 Tower Defense"
#define PLUGIN_AUTHOR	"floube"
#define PLUGIN_DESC		"Stop enemies from crossing a map by buying towers and building up defenses."
#define PLUGIN_VERSION	"1.0.0"
#define PLUGIN_URL		"http://www.tf2td.net/"
#define PLUGIN_PREFIX	"[TF2TD]"

/*==========================================
=            Plugin Information            =
==========================================*/

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

/*=======================================
=            Custom Includes            =
=======================================*/

#include "towerdefense/handler/towers.sp"
#include "towerdefense/handler/waves.sp"

#include "towerdefense/info/constants.sp"
#include "towerdefense/info/variables.sp"

#include "towerdefense/util/log.sp"
#include "towerdefense/util/md5.sp"
#include "towerdefense/util/zones.sp"

#include "towerdefense/commands.sp"
#include "towerdefense/database.sp"
#include "towerdefense/events.sp"

/*=======================================
=            Public Forwards            =
=======================================*/

public OnPluginStart() {
	PrintToServer("%s Loaded %s %s by %s", PLUGIN_PREFIX, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	Log_Initialize(TDLogLevel_Debug, TDLogType_Console);
}

public OnMapStart() {
	
}

public OnClientPutInServer(iClient) {
	
}