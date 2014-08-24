#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <steamtools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

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
#include "towerdefense/info/enums.sp"
#include "towerdefense/info/variables.sp"
#include "towerdefense/info/convars.sp"

#include "towerdefense/util/log.sp"
#include "towerdefense/util/md5.sp"
#include "towerdefense/util/metal.sp"
#include "towerdefense/util/tf2items.sp"
#include "towerdefense/util/zones.sp"

#include "towerdefense/handler/towers.sp"
#include "towerdefense/handler/waves.sp"

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
	RegisterCommands();

	// Plugin late load, re-load
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient)) {
			OnClientPutInServer(iClient);
		}
	}
}

public OnPluginEnd() {
	if (g_bSteamTools) {
		Steam_SetGameDescription("Team Fortress");
	}
}

public OnMapStart() {
	g_bTowerDefenseMap = IsTowerDefenseMap();

	PrecacheModels();
	PrecacheSounds();
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
	g_bEnabled = GetConVarBool(g_hEnabled) && g_bTowerDefenseMap && g_bSteamTools && g_bTF2Attributes;
	g_bMapRunning = true;

	UpdateGameDescription();

	if (!g_bEnabled) {
		if (!g_bTowerDefenseMap) {
			Log(TDLogLevel_Info, "This map is not a valid map, thus Tower Defense has been temporarily disabled.");
		} else {
			Log(TDLogLevel_Info, "Plugin is disabled.");
		}
	}
}

public OnAllPluginsLoaded() {
	g_bSteamTools = LibraryExists("SteamTools");

	if (g_bSteamTools) {
		UpdateGameDescription();

		Log(TDLogLevel_Info, "Found SteamTools on startup");
	}

	g_bTF2Attributes = LibraryExists("tf2attributes");

	if (g_bTF2Attributes) {
		Log(TDLogLevel_Info, "Found TF2Attributes on startup");
	}
}

public OnLibraryAdded(const String:sName[]) {
	if (StrEqual(sName, "SteamTools", false)) {
		g_bSteamTools = true;
		UpdateGameDescription();

		Log(TDLogLevel_Info, "SteamTools loaded");
	} else if (StrEqual(sName, "tf2attributes", false)) {
		g_bTF2Attributes = true;

		Log(TDLogLevel_Info, "TF2Attributes loaded");
	}
}

public OnLibraryRemoved(const String:sName[]) {
	if (StrEqual(sName, "SteamTools", false)) {
		g_bSteamTools = false;

		Log(TDLogLevel_Info, "SteamTools unloaded");
	} else if (StrEqual(sName, "tf2attributes", false)) {
		g_bTF2Attributes = false;

		Log(TDLogLevel_Info, "TF2Attributes unloaded");
	}
}

public OnClientAuthorized(iClient, const String:sSteamID[]) {
	if (!g_bEnabled) {
		return;
	}

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
	if (!g_bEnabled) {
		return;
	}

	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);

	g_iAttachedTower[iClient] = 0;

	g_iUpgradeMetal[iClient] = 0;
	g_iUpgradeLevel[iClient] = 1;
}

public OnClientPostAdminCheck(iClient) {
	if (!g_bEnabled) {
		return;
	}

	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		ChangeClientTeam(iClient, TEAM_DEFENDER);
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);
	}
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	// Attach/detach tower on right-click
	if (IsButtonReleased(iClient, iButtons, IN_ATTACK2)) { 
		decl String:sActiveWeapon[64];
		GetClientWeapon(iClient, sActiveWeapon, sizeof(sActiveWeapon));
		
		if (StrEqual(sActiveWeapon, "tf_weapon_wrench") || StrEqual(sActiveWeapon, "tf_weapon_robot_arm")) {
			if (IsTower(g_iAttachedTower[iClient])) {
				DetachTower(iClient);
			} else {
				AttachTower(iClient);
			}
		}
	}

	// Show tower info on left-click
	if (IsButtonReleased(iClient, iButtons, IN_ATTACK)) { 
		decl String:sActiveWeapon[64];
		GetClientWeapon(iClient, sActiveWeapon, sizeof(sActiveWeapon));
		
		if (StrEqual(sActiveWeapon, "tf_weapon_wrench") || StrEqual(sActiveWeapon, "tf_weapon_robot_arm")) {
			ShowTowerInfo(iClient);
		}
	}

	g_iLastButtons[iClient] = iButtons;

	return Plugin_Continue;
}

public Action:OnTakeDamage(iClient, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iWeapon, Float:fDamageForce[3], Float:fDamagePosition[3]) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	// Block tower taking damage
	if (IsTower(iClient)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public OnEntityCreated(iEntity, const String:sClassname[]) {
	if (StrEqual(sClassname, "tf_ammo_pack")) {
		SDKHook(iEntity, SDKHook_Touch, OnTouchWeapon);
	}
}

public Action:OnTouchWeapon(iEntity, iClient) {
	if (IsDefender(iClient)) {
		return Plugin_Continue;
	}

	return Plugin_Handled;
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
	PrecacheModel("models/bots/scout/bot_scout.mdl");
	PrecacheModel("models/bots/sniper/bot_sniper.mdl");
	PrecacheModel("models/bots/soldier/bot_soldier.mdl");
	PrecacheModel("models/bots/demo/bot_demo.mdl");
	PrecacheModel("models/bots/medic/bot_medic.mdl");
	PrecacheModel("models/bots/heavy/bot_heavy.mdl");
	PrecacheModel("models/bots/pyro/bot_pyro.mdl");
	PrecacheModel("models/bots/spy/bot_spy.mdl");
	PrecacheModel("models/bots/engineer/bot_engineer.mdl");

	PrecacheModel("models/items/ammopack_large.mdl");
	PrecacheModel("models/items/ammopack_medium.mdl");
	PrecacheModel("models/items/ammopack_small.mdl");
	
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}

/**
 * Precaches needed sounds.
 *
 * @noreturn
 */

stock PrecacheSounds() {
	new String:sRoboPath[64];
	for (new i = 1; i <= 18; i++) {
		Format(sRoboPath, sizeof(sRoboPath), "mvm/player/footsteps/robostep_%s%i.wav", (i < 10) ? "0" : "", i);
		PrecacheSound(sRoboPath);
	}
	
	PrecacheSound("items/gunpickup2.wav");
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

/**
 * Checks if a button is being pressed/was pressed.
 *
 * @param iClient		The client.
 * @param iButtons		The clients current buttons.
 * @param iButton		The button to check for.
 * @return				True if pressed, false ontherwise.
 */

stock bool:IsButtonPressed(iClient, iButtons, iButton) { 
	return ((iButtons & iButton) == iButton && (g_iLastButtons[iClient] & iButton) != iButton); 
}

/**
 * Checks if a button is being released/was released.
 *
 * @param iClient		The client.
 * @param iButtons		The clients current buttons.
 * @param iButton		The button to check for.
 * @return				True if released, false ontherwise.
 */

stock bool:IsButtonReleased(iClient, iButtons, iButton) { 
	return ((g_iLastButtons[iClient] & iButton) == iButton && (iButtons & iButton) != iButton); 
}

/**
 * Get the target a client is aiming at.
 *
 * @param iClient		The client.
 * @return				The targets or -1 if no target is being aimed at.
 */

stock GetAimTarget(iClient) {
	new Float:fLocation[3], Float:fAngles[3];
	GetClientEyePosition(iClient, fLocation);
	GetClientEyeAngles(iClient, fAngles);
		
	TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayers, iClient);
	
	if (TR_DidHit()) {
		new iEntity = TR_GetEntityIndex();
	
		if (IsValidEntity(iEntity) && IsValidClient(iEntity)) {
			return iEntity;
		}
	}

	return -1;
}

public bool:TraceRayPlayers(iEntity, iMask, any:iData) {
	return (iEntity != iData) && IsValidClient(iEntity);
}

/**
 * Get the entity a client is aiming at.
 *
 * @param iClient		The client.
 * @return				The entity or -1 if no entity is being aimed at.
 */

stock GetAimEntity(iClient) {
	new Float:fLocation[3], Float:fAngles[3];
	GetClientEyePosition(iClient, fLocation);
	GetClientEyeAngles(iClient, fAngles);
		
	TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayEntities, iClient);
	
	if (TR_DidHit()) {
		new iEntity = TR_GetEntityIndex();
	
		if (IsValidEntity(iEntity)) {
			return iEntity;
		}
	}

	return -1;
}

public bool:TraceRayEntities(iEntity, iMask, any:iData) {
	return (iEntity != iData) && iEntity > MaxClients && IsValidEntity(iEntity);
}

/**
 * Gets a client by name.
 *
 * @param iClient		The executing clients index.
 * @param sName			The clients name.
 * @return				The clients client index, or -1 on error.
 */

stock GetClientByName(iClient, String:sName[]) {
	new String:sNameOfIndex[MAX_NAME_LENGTH + 1];
	new iLen = strlen(sName);
	
	new iResults = 0;
	new iTarget = 0;

	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			GetClientName(i, sNameOfIndex, sizeof(sNameOfIndex));
			Substring(sNameOfIndex, sizeof(sNameOfIndex), sNameOfIndex, sizeof(sNameOfIndex), 0, iLen);
			
			if (StrEqual(sName, sNameOfIndex)) {
				iResults++;
				iTarget = i;
			}
		}
	}

	if (iResults == 1) {
		return iTarget;
	} else if (iResults == 0) {
		if (IsDefender(iClient)) {
			PrintToChat(iClient, "Couldn't find player %s.", sName);
		}
	} else {
		if (IsDefender(iClient)) {
			PrintToChat(iClient, "Be more specific.", sName);
		}
	}
	
	return -1;
}

/**
 * Gets a substring of an string.
 *
 * @param sDest				The string to copy to.
 * @param iDestLength		The length of the destination string.
 * @param sSource			The string to copy from.
 * @param iSourceLength		The length of the source string.
 * @param iStart			The positon to start the copy from.
 * @param iEnd				The postion to end the copy.
 * @return					True on success, false ontherwise.
 */

stock bool:Substring(String:sDest[], iDestLength, String:sSource[], iSourceLength, iStart, iEnd) {
	if (iEnd < iStart || iEnd > (iSourceLength - 1)) {
		strcopy(sDest, iDestLength, NULL_STRING);
		return false;
	} else {
		strcopy(sDest, (iEnd - iStart + 1), sSource[iStart]);
		return true;
	}
}

/**
 * Checks if a string is numeric.
 *
 * @param sText			The string which should be checked.
 * @return				True if number, false ontherwise.
 */

stock bool:IsStringNumeric(String:sText[]) {
	for (new iChar = 0; iChar < strlen(sText); iChar++) {
		if (!IsCharNumeric(sText[iChar])) {
			return false;
		}
	}

	return true;
}

/**
 * Gets the distance between a location and the ground.
 *
 * @param fLocation		The location vector.
 * @return				Distance to the ground.
 */

stock Float:GetDistanceToGround(Float:fLocation[3]) {	
	new Float:fGround[3];

	TR_TraceRayFilter(fLocation, Float:{90.0, 0.0, 0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, 0);
	
	if (TR_DidHit()) {
		TR_GetEndPosition(fGround);

		return GetVectorDistance(fLocation, fGround);
	}

	return 0.0;
}

public bool:TraceRayNoPlayers(iEntity, iMask, any:iData) {
	return !(iEntity == iData || IsValidClient(iEntity));
}

/**
 * Sets the model of a client to the robot model.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock SetRobotModel(iClient) {
	decl String:sClass[16], String:sModelPath[PLATFORM_MAX_PATH];

	GetClientClassName(iClient, sClass, sizeof(sClass));
	Format(sModelPath, sizeof(sModelPath), "models/bots/%s/bot_%s.mdl", sClass, sClass);
	SetVariantString(sModelPath);
	AcceptEntityInput(iClient, "SetCustomModel");
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1);
}

/**
 * Gets the name of the class a client is playing.
 *
 * @param iClient 		The client.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @noreturn
 */

stock GetClientClassName(iClient, String:sBuffer[], iMaxLength) {
	switch (TF2_GetPlayerClass(iClient)) {
		case TFClass_Scout: {
			strcopy(sBuffer, iMaxLength, "scout");
		} case TFClass_Sniper: {
			strcopy(sBuffer, iMaxLength, "sniper");
		} case TFClass_Soldier: {
			strcopy(sBuffer, iMaxLength, "soldier");
		} case TFClass_DemoMan: {
			strcopy(sBuffer, iMaxLength, "demo");
		} case TFClass_Medic: {
			strcopy(sBuffer, iMaxLength, "medic");
		} case TFClass_Heavy: {
			strcopy(sBuffer, iMaxLength, "heavy");
		} case TFClass_Pyro: {
			strcopy(sBuffer, iMaxLength, "pyro");
		} case TFClass_Spy: {
			strcopy(sBuffer, iMaxLength, "spy");
		} case TFClass_Engineer: {
			strcopy(sBuffer, iMaxLength, "engineer");
		}
	}
}