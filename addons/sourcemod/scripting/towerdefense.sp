#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <steamtools>
#include <tf2_stocks>
#include <tf2items>

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

#include "towerdefense/info/constants.sp"
#include "towerdefense/info/variables.sp"
#include "towerdefense/info/convars.sp"

#include "towerdefense/handler/towers.sp"
#include "towerdefense/handler/waves.sp"

#include "towerdefense/util/log.sp"
#include "towerdefense/util/md5.sp"
#include "towerdefense/util/tf2items.sp"
#include "towerdefense/util/zones.sp"

#include "towerdefense/commands.sp"
#include "towerdefense/database.sp"
#include "towerdefense/events.sp"
#include "towerdefense/timers.sp"

/*=======================================
=            Public Forwards            =
=======================================*/

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:sError[], iMaxLength) {
	if (GetEngineVersion() != Engine_TF2) {
		Format(sError, iMaxLength, "Cannot run on other mods than TF2.");
		return APLRes_Failure;
	}

	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}

public OnPluginStart() {
	PrintToServer("%s Loaded %s %s by %s", PLUGIN_PREFIX, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	Log_Initialize(TDLogLevel_Debug, TDLogType_Console);

	LoadConVars();
	HookEvents();
}

public OnPluginEnd() {
	if (g_bSteamTools) {
		Steam_SetGameDescription("Team Fortress");
	}
}

public OnMapStart() {
	g_bTowerDefenseMap = IsTowerDefenseMap();

	PrecacheModels();
}

public OnMapEnd() {
	g_bMapRunning = false;

	new bool:bWasEnabled = g_bEnabled;
	g_bEnabled = false;

	if (bWasEnabled) {
		UpdateGameDescription();
	}
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled) && g_bTowerDefenseMap;
	g_bMapRunning = true;

	UpdateGameDescription();
}

public OnAllPluginsLoaded() {
	g_bSteamTools = LibraryExists("SteamTools");

	if (g_bSteamTools) {
		UpdateGameDescription();

		Log(TDLogLevel_Info, "Found SteamTools on startup");
	}
}

public OnLibraryAdded(const String:sName[]) {
	if (StrEqual(sName, "SteamTools", false)) {
		g_bSteamTools = true;
		UpdateGameDescription();

		Log(TDLogLevel_Info, "SteamTools loaded");
	}
}

public OnLibraryRemoved(const String:sName[]) {
	if (StrEqual(sName, "SteamTools", false)) {
		g_bSteamTools = false;

		Log(TDLogLevel_Info, "SteamTools unloaded");
	}
}

public OnClientAuthorized(iClient, const String:sSteamID[]) {
	if (IsValidClient(iClient) && !StrEqual(sSteamID, "BOT")) {
		if (GetRealClientCount() > PLAYER_LIMIT) {
			KickClient(iClient, "Maximum number of players has been reached (%d/%d)", GetRealClientCount() - 1, PLAYER_LIMIT);
			Log(TDLogLevel_Info, "Kicked player (%N, %s) (Maximum players reached: %d/%d)", iClient, sSteamID, GetRealClientCount() - 1, PLAYER_LIMIT);
			return;
		}

		Log(TDLogLevel_Info, "Connected clients: %d/%d", GetRealClientCount(), PLAYER_LIMIT);
	}
}

public OnClientPutInServer(iClient) {
	
}

public OnClientPostAdminCheck(iClient) {
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		ChangeClientTeam(iClient, TEAM_DEFENDER);
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);
	}
}

/*=========================================
=            Utility Functions            =
=========================================*/

/**
 * Checks if a client is a valid client.
 *
 * @param iClient		The clients index.
 * @return				True on success, false ontherwise.
 */

stock bool:IsValidClient(iClient) {
	return (iClient > 0 && iClient <= MaxClients);
}

/**
 * Checks if a client is a defender.
 *
 * @param iClient		The client.
 * @return				True on success, false ontherwise.
 */

stock bool:IsDefender(iClient) {
	return (IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_DEFENDER);
}

/**
 * Checks if a client is a tower.
 *
 * @param iClient		The client.
 * @return				True on success, false ontherwise.
 */

stock bool:IsTower(iClient) {
	return (IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_DEFENDER);
}

/**
 * Checks if a client is an attacker.
 *
 * @param iClient		The client.
 * @return				True on success, false ontherwise.
 */

stock bool:IsAttacker(iClient) {
	return (IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_ATTACKER);
}

/**
 * Checks if the current map is a Tower Defense map, 
 * which can either start with td_ or tf2td_.
 *
 * @return		True if the current map is a Tower Defense map, false ontherwise.
 */

stock bool:IsTowerDefenseMap() {
	new String:sCurrentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	return (strncmp(sCurrentMap, "td_", 3) == 0 || strncmp(sCurrentMap, "tf2td_", 6) == 0);
}

/**
 * Changes the 'Game' tab in the server browser, according to the plugins state.
 *
 * @noreturn
 */

stock UpdateGameDescription() {
	if (!g_bSteamTools) {
		return;
	}

	decl String:sGamemode[64];

	if (g_bEnabled) {
		Format(sGamemode, sizeof(sGamemode), "%s (%s)", GAME_DESCRIPTION, PLUGIN_VERSION);
	} else {
		strcopy(sGamemode, sizeof(sGamemode), "Team Fortress");
	}

	Steam_SetGameDescription(sGamemode);
}

/**
 * Precaches needed models.
 *
 * @noreturn
 */

stock PrecacheModels() {
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}

/**
 * Counts non-fake clients connected to the game.
 *
 * @param bInGameOnly	Only count clients which are in-game.
 * @return				The client count.
 */

stock GetRealClientCount(bool:bInGameOnly = false) {
	new iClients = 0;

	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (((bInGameOnly) ? IsClientInGame(iClient) : IsClientConnected(iClient)) && !IsFakeClient(iClient)) {
			iClients++;
		}
	}

	return iClients;
}