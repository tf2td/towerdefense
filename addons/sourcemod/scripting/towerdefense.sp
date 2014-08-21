#pragma semicolon 1

#include <sourcemod>

/*=================================
=            Constants            =
=================================*/

#define PLUGIN_NAME     "TF2 Tower Defense"
#define PLUGIN_AUTHOR   "floube"
#define PLUGIN_DESC     "Stop enemies from crossing a map by buying towers and building up defenses."
#define PLUGIN_VERSION  "1.0.0.0"
#define PLUGIN_URL      "http://www.tf2td.net/"

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
=            Public Forwards            =
=======================================*/

public OnPluginStart() {
	
}

public OnMapStart() {
	
}

public OnClientPutInServer(iClient) {
	
}