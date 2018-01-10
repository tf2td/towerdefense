#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <socket>
#include <steamtools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>

#pragma newdecls required

/*=================================
=            Constants            =
=================================*/

#define PLUGIN_NAME		"TF2 Tower Defense"
#define PLUGIN_AUTHOR	"floube, benedevil, hurpdurp"
#define PLUGIN_DESC		"Stop enemies from crossing a map by buying towers and building up defenses."
#define PLUGIN_VERSION	"2.0.1"
#define PLUGIN_URL		"https://github.com/tf2td/towerdefense"
#define PLUGIN_PREFIX	"[TF2TD]"

/*==========================================
=            Plugin Information            =
==========================================*/

public Plugin myinfo = 
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
#include "towerdefense/util/metal.sp"
#include "towerdefense/util/steamid.sp"
#include "towerdefense/util/tf2items.sp"
#include "towerdefense/util/zones.sp"

#include "towerdefense/handler/antiair.sp"
#include "towerdefense/handler/aoe.sp"
#include "towerdefense/handler/buttons.sp"
#include "towerdefense/handler/corners.sp"
#include "towerdefense/handler/metalpacks.sp"
#include "towerdefense/handler/panels.sp"
#include "towerdefense/handler/player.sp"
#include "towerdefense/handler/server.sp"
#include "towerdefense/handler/sounds.sp"
#include "towerdefense/handler/towers.sp"
#include "towerdefense/handler/waves.sp"
#include "towerdefense/handler/weapons.sp"

#include "towerdefense/database/general.sp"
#include "towerdefense/database/player.sp"
#include "towerdefense/database/server.sp"

#include "towerdefense/commands.sp"
#include "towerdefense/events.sp"
#include "towerdefense/timers.sp"

/*=======================================
=            Public Forwards            =
=======================================*/

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iMaxLength) {
	if (GetEngineVersion() != Engine_TF2) {
		Format(sError, iMaxLength, "This mod can only run under TF2.");
		return APLRes_Failure;
	}
	
	if (SQL_CheckConfig("towerdefense"))
		g_hDatabase = SQL_Connect("towerdefense", true, sError, iMaxLength);
	else {
		Format(sError, iMaxLength, "Unable to read database info from file");
		return APLRes_Failure;
	}
	
	if (g_hDatabase == null)
		return APLRes_Failure;
	
	MarkNativeAsOptional("Steam_SetGameDescription");
	return APLRes_Success;
}

public void OnPluginStart() {
	PrintToServer("%s Loaded %s %s by %s", PLUGIN_PREFIX, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	Log_Initialize(TDLogLevel_Trace, TDLogType_Console);
	
	CreateDataMap(g_hMapTowers);
	CreateDataMap(g_hMapWeapons);
	CreateDataMap(g_hMapWaves);
	CreateDataMap(g_hMapMetalpacks);
	CreateDataMap(g_hMultiplierType);
	CreateDataMap(g_hMultiplier);
	
	CreateDataMap(g_hServerData);
	CreateDataMap(g_hPlayerData);
	
	HookEvents();
	RegisterCommands();
	LoadConVars();
	SetConVars();
	
	SetPassword("WaitingForServerToInitialize", false);
}

public void OnPluginEnd() {
	if (g_bSteamTools) {
		Steam_SetGameDescription("Team Fortress");
	}
	
	if (g_hDatabase != null) {
		CloseHandle(g_hDatabase);
		g_hDatabase = null;
	}
	
	if (g_hMapTowers != null) {
		CloseHandle(g_hMapTowers);
		g_hMapTowers = null;
	}
	
	if (g_hMapWeapons != null) {
		CloseHandle(g_hMapWeapons);
		g_hMapWeapons = null;
	}
	
	if (g_hMapWaves != null) {
		CloseHandle(g_hMapWaves);
		g_hMapWaves = null;
	}
	
	if (g_hMapMetalpacks != null) {
		CloseHandle(g_hMapMetalpacks);
		g_hMapMetalpacks = null;
	}
	
	if (g_hMultiplierType != null) {
		CloseHandle(g_hMultiplierType);
		g_hMultiplierType = null;
	}
	
	if (g_hMultiplier != null) {
		CloseHandle(g_hMultiplier);
		g_hMultiplier = null;
	}
	
	if (g_hServerData != null) {
		CloseHandle(g_hServerData);
		g_hServerData = null;
	}
	
	if (g_hPlayerData != null) {
		CloseHandle(g_hPlayerData);
		g_hPlayerData = null;
	}

	FindConVar("sv_cheats").SetInt(0, true, false);
}

public void OnMapStart() {
	g_bTowerDefenseMap = IsTowerDefenseMap();
	
	PrecacheModels();
	PrecacheSounds();
	
	g_iHealthBar = GetHealthBar();
	
	g_bConfigsExecuted = false;
}

public void OnMapEnd() {
	g_bMapRunning = false;
	
	bool bWasEnabled = g_bEnabled;
	g_bEnabled = false;
	
	if (bWasEnabled) {
		UpdateGameDescription();
	}
	
	AddConVarFlag("sv_cheats", FCVAR_NOTIFY);
	AddConVarFlag("sv_tags", FCVAR_NOTIFY);
	AddConVarFlag("tf_bot_count", FCVAR_NOTIFY);
	AddConVarFlag("sv_password", FCVAR_NOTIFY);
}

public void OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled) && g_bTowerDefenseMap && g_bSteamTools && g_bTF2Attributes;
	g_bMapRunning = true;
	
	UpdateGameDescription();
	
	if (!g_bEnabled) {
		if (!g_bTowerDefenseMap) {
			char sCurrentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
			
			Log(TDLogLevel_Info, "Map \"%s\" is not supported, Tower Defense has been disabled.", sCurrentMap);
		} else {
			Log(TDLogLevel_Info, "Tower Defense is disabled.");
		}
		
		return;
	}
	
	g_bServerInitialized = false;
	
	CreateTimer(5.0, InitializeDelay, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Action InitializeDelay(Handle hTimer, any iTime) {
	Server_Initialize();
	return Plugin_Stop;
}

public void OnAllPluginsLoaded() {
	g_bSteamTools = LibraryExists("SteamTools");
	
	if (g_bSteamTools) {
		UpdateGameDescription();
		
		Log(TDLogLevel_Debug, "Found SteamTools on startup");
	}
	
	g_bTF2Attributes = LibraryExists("tf2attributes");
	
	if (g_bTF2Attributes) {
		Log(TDLogLevel_Debug, "Found TF2Attributes on startup");
	}
}

public void OnLibraryAdded(const char[] sName) {
	if (StrEqual(sName, "SteamTools", false)) {
		g_bSteamTools = true;
		UpdateGameDescription();
		
		Log(TDLogLevel_Debug, "SteamTools loaded");
	} else if (StrEqual(sName, "tf2attributes", false)) {
		g_bTF2Attributes = true;
		
		Log(TDLogLevel_Debug, "TF2Attributes loaded");
	}
}

public void OnLibraryRemoved(const char[] sName) {
	if (StrEqual(sName, "SteamTools", false)) {
		g_bSteamTools = false;
		
		Log(TDLogLevel_Debug, "SteamTools unloaded");
	} else if (StrEqual(sName, "tf2attributes", false)) {
		g_bTF2Attributes = false;
		
		Log(TDLogLevel_Debug, "TF2Attributes unloaded");
	}
}

public void OnClientPutInServer(int iClient) {
	for (int i = 0; i < sizeof(g_fBeamPoints[]); i++) {
		g_fBeamPoints[iClient][i][0] = -1.0;
		g_fBeamPoints[iClient][i][1] = -1.0;
		g_fBeamPoints[iClient][i][2] = -1.0;
	}
}

public void OnClientPostAdminCheck(int iClient) {
	if (!g_bEnabled) {
		return;
	}
	
	char sSteamId[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamId, sizeof(sSteamId));
	
	if (!StrEqual(sSteamId, "BOT")) {
		char sName[MAX_NAME_LENGTH];
		GetClientName(iClient, sName, sizeof(sName));
		
		char sCommunityId[32];
		GetClientCommunityId(iClient, sCommunityId, sizeof(sCommunityId));
		
		char sIp[32];
		GetClientIP(iClient, sIp, sizeof(sIp));
		
		Player_Connected(GetClientUserId(iClient), iClient, sName, sSteamId, sCommunityId, sIp);
	}
	
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(iClient, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void OnClientDisconnect(int iClient) {
	if (!g_bEnabled) {
		return;
	}
	
	if (IsTower(g_iAttachedTower[iClient])) {
		Tower_OnCarrierDisconnected(g_iAttachedTower[iClient], iClient);
	}
	
	if (IsDefender(iClient)) {
		int iMetal = GetClientMetal(iClient);
		
		if (iMetal > 0) {
			float fLocation[3];
			
			GetClientEyePosition(iClient, fLocation);
			fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;
			
			SpawnMetalPack(TDMetalPack_Medium, fLocation, iMetal);
		}
	}
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	// Force towers to shoot
	if (IsTower(iClient)) {
		TDTowerId iTowerId = GetTowerId(iClient);
	
		// Refill ammo for airblast tower
		if (iTowerId == TDTower_Airblast_Pyro) {
			int iOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			if (GetEntData(iClient, iOffset + 4) <= 0) {
				SetEntData(iClient, iOffset + 4, 100);
			}
		}
		if(iTowerId == TDTower_AoE_Engineer && g_bAoEEngineerAttack) {
			iButtons |= IN_ATTACK;
		}
		
		if (Tower_GetAttackPrimary(iTowerId)) {
			iButtons |= IN_ATTACK;
		}
		
		if (Tower_GetAttackSecondary(iTowerId)) {
			iButtons |= IN_ATTACK2;
		}
		
		if(Tower_GetRotate(iTowerId) && g_bTowersLocked) {
		
			float fClientEyePosition[3];
			GetClientEyePosition(iClient, fClientEyePosition);
			
			int iClosest = GetClosestClient(iClient);
			if(!IsValidClient(iClosest) || !IsClientConnected(iClosest) || !IsClientInGame(iClosest))
				return Plugin_Continue;

			float fClosestLocation[3];
			GetClientAbsOrigin(iClosest, fClosestLocation);

			float fVector[3];
			MakeVectorFromPoints(fClosestLocation, fClientEyePosition, fVector);

			float fAngle[3];
			GetVectorAngles(fVector, fAngle);
			fAngle[0] = (fAngle[0] * -1.0) + 355;
			fAngle[1] += 180.0;

			TeleportEntity(iClient, NULL_VECTOR, fAngle, NULL_VECTOR);
		}
	}
	
	if (IsAttacker(iClient) && g_bBoostWave) {
		fVelocity[0] = 500.0;
	}
	if (IsAttacker(iClient) && g_iSlowAttacker[iClient]) {
		fVelocity[0] = -10000.0;
	}
	
	if (IsDefender(iClient)) {
		// Attach/detach tower on right-click
		if (IsButtonReleased(iClient, iButtons, IN_ATTACK2)) {
			char sActiveWeapon[64];
			GetClientWeapon(iClient, sActiveWeapon, sizeof(sActiveWeapon));
			
			if (StrEqual(sActiveWeapon, "tf_weapon_wrench") || StrEqual(sActiveWeapon, "tf_weapon_robot_arm")) {
				if (IsTower(g_iAttachedTower[iClient])) {
					Tower_Drop(iClient);
				} else {
					Tower_Pickup(iClient);
				}
			}
		}
		
		// Show tower info on left-click
		if (IsButtonReleased(iClient, iButtons, IN_ATTACK)) {
			char sActiveWeapon[64];
			GetClientWeapon(iClient, sActiveWeapon, sizeof(sActiveWeapon));
			
			if (StrEqual(sActiveWeapon, "tf_weapon_wrench") || StrEqual(sActiveWeapon, "tf_weapon_robot_arm")) {
				Tower_ShowInfo(iClient);
			}
		}
		
		float fLocation[3], fViewAngles[3];
		GetClientEyePosition(iClient, fLocation);
		GetClientEyeAngles(iClient, fViewAngles);
		
		TR_TraceRayFilter(fLocation, fViewAngles, MASK_VISIBLE, RayType_Infinite, TraceRayEntities, iClient);
		
		if (TR_DidHit()) {
			int iAimEntity = TR_GetEntityIndex();
			
			if (IsValidEntity(iAimEntity)) {
				char sClassname[64];
				GetEntityClassname(iAimEntity, sClassname, sizeof(sClassname));
				
				if (StrEqual(sClassname, "func_breakable")) {
					char sName[64];
					GetEntPropString(iAimEntity, Prop_Data, "m_iName", sName, sizeof(sName));
					
					if (StrContains(sName, "break_tower_") != -1) {
						float fEntityLocation[3];
						GetEntPropVector(iAimEntity, Prop_Send, "m_vecOrigin", fEntityLocation);
						
						if (GetVectorDistance(fLocation, fEntityLocation) <= 512.0) {
							TDTowerId iTowerId;
							
							if (StrContains(sName, "break_tower_tp_") != -1) {
								char sNameParts[4][32];
								ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));
								
								iTowerId = view_as<TDTowerId>(StringToInt(sNameParts[3]));
								Tower_GetName(iTowerId, sName, sizeof(sName));
							} else {
								char sNameParts[3][32];
								ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));
								
								iTowerId = view_as<TDTowerId>(StringToInt(sNameParts[2]));
								Tower_GetName(iTowerId, sName, sizeof(sName));
							}
							
							char sDescription[1024];
							if (Tower_GetDescription(iTowerId, sDescription, sizeof(sDescription))) {
								char sDamagetype[64];
								if (Tower_GetDamagetype(iTowerId, sDamagetype, sizeof(sDamagetype))) {
									PrintToHud(iClient, "\
										%s \n\
										--------------- \n\
										Price: %d metal (%d metal/player)\n\
										Damagetype: %s \n\
										Number of Levels: %d \n\
										--------------- \n\
										%s", 
										sName, Tower_GetPrice(iTowerId), Tower_GetPrice(iTowerId) / GetRealClientCount(true), sDamagetype, Tower_GetMaxLevel(iTowerId), sDescription);
								}
							}
						}
					}
				}
			}
		}
	}
	
	if (g_bPickupSentry[iClient]) {
		iButtons |= IN_ATTACK2;
		g_bPickupSentry[iClient] = false;
	}
	
	g_iLastButtons[iClient] = iButtons;
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float fDamageForce[3], float fDamagePosition[3]) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	// Block tower taking damage
	if (IsTower(iClient)) {
		return Plugin_Handled;
	}
	
	if (IsClientInGame(iClient)) {   
		char sAttackerObject[128];
		GetEdictClassname(iInflictor, sAttackerObject, sizeof(sAttackerObject));
		
		//Sentry Damage
		if (StrEqual(sAttackerObject, "obj_sentrygun")) {
			fDamage *= fMultiplier[Multiplier_GetInt("sentry")] + 1.0;
			//Register Damage For Stats
			if(IsValidClient(iAttacker) && IsDefender(iAttacker)) {
				Player_CAddValue(iAttacker, PLAYER_DAMAGE, RoundToZero(fDamage));
			}
			return Plugin_Changed;
		}
		
		//Blast Damage
		if(iDamageType & DMG_BLAST) {
			fDamage *= fMultiplier[Multiplier_GetInt("explosion")] + 1.0;
			//Register Damage For Stats
			if(IsValidClient(iAttacker) && IsDefender(iAttacker)) {
				Player_CAddValue(iAttacker, PLAYER_DAMAGE, RoundToZero(fDamage));
			}
			return Plugin_Changed;
		}
		
		//Fire Damage
		if(iDamageType & DMG_BURN) {
			fDamage *= fMultiplier[Multiplier_GetInt("fire")] + 1.0;
			//Register Damage For stats
			if(IsValidClient(iAttacker) && IsDefender(iAttacker)) {
				Player_CAddValue(iAttacker, PLAYER_DAMAGE, RoundToZero(fDamage));
			}
			return Plugin_Changed;
		}
		
		//Bullet Damage
		if(iDamageType & DMG_BULLET) {
			fDamage *= fMultiplier[Multiplier_GetInt("bullet")] + 1.0;
			//Register Damage For Stats
			if(IsValidClient(iAttacker) && IsDefender(iAttacker)) {
				Player_CAddValue(iAttacker, PLAYER_DAMAGE, RoundToZero(fDamage));
			}
			return Plugin_Changed;
		}
	}
	
	if(IsValidClient(iAttacker) && IsDefender(iAttacker)) {
		Player_CAddValue(iAttacker, PLAYER_DAMAGE, RoundToZero(fDamage));
	}
	
	if (IsDefender(iClient)) {
		if (IsValidClient(iAttacker)) {
			if (iClient == iAttacker || GetClientTeam(iClient) != GetClientTeam(iAttacker)) {
				if (fDamage >= GetClientHealth(iClient)) {
					int iMetal = GetClientMetal(iClient) / 2;
					
					if (iMetal > 0) {
						float fLocation[3];
						
						GetClientEyePosition(iClient, fLocation);
						fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;
						
						SpawnMetalPack(TDMetalPack_Medium, fLocation, iMetal);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnTakeDamagePost(int iClient, int iAttacker, int iInflictor, float fDamage, int iDamageType) {
	if (!g_bEnabled) {
		return;
	}
	
	if (IsAttacker(iClient)) {
		Wave_OnTakeDamagePost(iClient, iAttacker, iInflictor, fDamage, iDamageType);
	}
}

public void OnEntityCreated(int iEntity, const char[] sClassname) {
	if (StrEqual(sClassname, "tf_ammo_pack") || StrEqual(sClassname, "tf_dropped_weapon")) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawnKill);
	} else if (StrEqual(sClassname, "func_breakable")) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnButtonSpawned);
	} else if (StrEqual(sClassname, "tf_projectile_rocket") || StrEqual(sClassname, "tf_projectile_flare")) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnAntiAirProjectileSpawned);
	} else if (StrContains(sClassname, "tf_projectile_") != -1) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnProjectileSpawned);
	} else if (StrEqual(sClassname, "trigger_multiple")) {
		SDKHook(iEntity, SDKHook_StartTouchPost, Wave_OnTouchCorner);
	}
}

public void OnEntitySpawnKill(int iEntity) {
	AcceptEntityInput(iEntity, "Kill");
}

public void OnButtonSpawned(int iEntity) {
	if (!g_bEnabled) {
		return;
	}
	
	char sName[64];
	GetEntPropString(iEntity, Prop_Data, "m_iName", sName, sizeof(sName));
	
	if (StrEqual(sName, "wave_start")) {
		g_iWaveStartButton = iEntity;
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", g_fWaveStartButtonLocation);
	}
}

public void OnAntiAirProjectileSpawned(int iEntity) {
	if (!g_bEnabled) {
		return;
	}
	
	SDKHook(iEntity, SDKHook_ShouldCollide, OnProjectileCollide);
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

	if (IsTower(iOwner)) {
		AntiAir_ProjectileTick(iEntity, iOwner);
	}
}

public void OnProjectileSpawned(int iEntity) {
	if (!g_bEnabled) {
		return;
	}
	
	SDKHook(iEntity, SDKHook_ShouldCollide, OnProjectileCollide);
}

public bool OnProjectileCollide(int iEntity, int iCollisiongroup, int iContentsmask, bool bResult) {
	if (!g_bEnabled) {
		return true;
	}
	
	int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
	
	if (IsValidEntity(iOwner)) {
		int iTeam = GetEntProp(iOwner, Prop_Send, "m_iTeamNum");
		
		float fLocation[3], fAngles[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fLocation);
		GetEntPropVector(iEntity, Prop_Data, "m_angAbsRotation", fAngles);
		
		TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayers);
		
		if (TR_DidHit()) {
			int iTarget = TR_GetEntityIndex();
			
			if (IsValidClient(iTarget)) {
				if (GetClientTeam(iTarget) != iTeam) {
					SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 0);
				} else {
					SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 24);
				}
			}
		}
	}
	
	return true;
}

public Action OnNobuildEnter(int iEntity, int iClient) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if (IsDefender(iClient)) {
		g_bInsideNobuild[iClient] = true;
	} else if (IsTower(iClient)) {
		if (IsDefender(g_iLastMover[iClient])) {
			Tower_OnTouchNobuild(iClient);
		}
	}
	
	return Plugin_Continue;
}

public Action OnNobuildExit(int iEntity, int iClient) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if (IsDefender(iClient)) {
		g_bInsideNobuild[iClient] = false;
	}
	
	return Plugin_Continue;
}

/*=========================================
=            Utility Functions            =
=========================================*/

/**
 * Checks if a client is a valid client.
 *
 * @param iClient		The clients index.
 * @return				True on success, false otherwise.
 */

stock bool IsValidClient(int iClient) {
	return (iClient > 0 && iClient <= MaxClients);
}

/**
 * Checks if a client is a defender.
 *
 * @param iClient		The client.
 * @return				True on success, false otherwise.
 */

stock bool IsDefender(int iClient) {
	return (IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_DEFENDER);
}

/**
 * Checks if a client is a tower.
 *
 * @param iClient		The client.
 * @return				True on success, false otherwise.
 */

stock bool IsTower(int iClient) {
	return (IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_DEFENDER);
}

/**
 * Checks if a client is an attacker.
 *
 * @param iClient		The client.
 * @return				True on success, false otherwise.
 */

stock bool IsAttacker(int iClient) {
	return (IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_ATTACKER);
}

/**
 * Checks if the current map is a Tower Defense map, 
 * which can either start with td_ or tf2td_.
 *
 * @return		True if the current map is a Tower Defense map, false otherwise.
 */

stock bool IsTowerDefenseMap() {
	char sCurrentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	
	return (strncmp(sCurrentMap, "td_", 3) == 0 || strncmp(sCurrentMap, "tf2td_", 6) == 0);
}

/**
 * Changes the 'Game' tab in the server browser, according to the plugins state.
 *
 * @noreturn
 */

stock void UpdateGameDescription() {
	if (!g_bSteamTools) {
		return;
	}
	
	char sGamemode[64];
	
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

stock void PrecacheModels() {
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

stock void PrecacheSounds() {
	char sRoboPath[64];
	for (int i = 1; i <= 18; i++) {
		Format(sRoboPath, sizeof(sRoboPath), "mvm/player/footsteps/robostep_%s%i.mp3", (i < 10) ? "0" : "", i);
		PrecacheSound(sRoboPath);
	}
	
	PrecacheSound("items/ammo_pickup.wav");
	PrecacheSound("items/gunpickup2.wav");
	PrecacheSound("vo/announcer_begins_5sec.mp3");
	PrecacheSound("vo/announcer_begins_4sec.mp3");
	PrecacheSound("vo/announcer_begins_3sec.mp3");
	PrecacheSound("vo/announcer_begins_2sec.mp3");
	PrecacheSound("vo/announcer_begins_1sec.mp3");
	PrecacheSound("vo/mvm_mannup_wave_end01.mp3");
	PrecacheSound("vo/mvm_mannup_wave_end02.mp3");
	PrecacheSound("vo/mvm_wave_end01.mp3");
	PrecacheSound("vo/mvm_wave_end02.mp3");
	PrecacheSound("vo/mvm_wave_end03.mp3");
	PrecacheSound("vo/mvm_wave_end04.mp3");
	PrecacheSound("vo/mvm_wave_end05.mp3");
	PrecacheSound("vo/mvm_wave_end06.mp3");
	PrecacheSound("vo/mvm_wave_end07.mp3");
	PrecacheSound("vo/engineer_no01.mp3");
	PrecacheSound("vo/engineer_no02.mp3");
	PrecacheSound("vo/engineer_no03.mp3");
	PrecacheSound("music/mvm_start_mid_wave.wav");
	PrecacheSound("music/mvm_start_last_wave.wav");
	PrecacheSound("music/mvm_end_last_wave.wav");
	}

/**
 * Counts non-fake clients connected to the game.
 *
 * @param bInGameOnly	Only count clients which are in-game.
 * @return				The client count.
 */

stock int GetRealClientCount(bool bInGameOnly = false) {
	int iClients = 0;
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
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
 * @return				True if pressed, false otherwise.
 */

stock bool IsButtonPressed(int iClient, int iButtons, int iButton) {
	return ((iButtons & iButton) == iButton && (g_iLastButtons[iClient] & iButton) != iButton);
}

/**
 * Checks if a button is being released/was released.
 *
 * @param iClient		The client.
 * @param iButtons		The clients current buttons.
 * @param iButton		The button to check for.
 * @return				True if released, false otherwise.
 */

stock bool IsButtonReleased(int iClient, int iButtons, int iButton) {
	return ((g_iLastButtons[iClient] & iButton) == iButton && (iButtons & iButton) != iButton);
}

/**
 * Get the target a client is aiming at.
 *
 * @param iClient		The client.
 * @return				The targets or -1 if no target is being aimed at.
 */

stock int GetAimTarget(int iClient) {
	float fLocation[3], fAngles[3];
	GetClientEyePosition(iClient, fLocation);
	GetClientEyeAngles(iClient, fAngles);
	
	TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayers, iClient);
	
	if (TR_DidHit()) {
		int iEntity = TR_GetEntityIndex();
		
		if (IsValidEntity(iEntity) && IsValidClient(iEntity)) {
			return iEntity;
		}
	}
	
	return -1;
}

public bool TraceRayPlayers(int iEntity, int iMask, any iData) {
	return (iEntity != iData) && IsValidClient(iEntity);
}

/**
 * Get the entity a client is aiming at.
 *
 * @param iClient		The client.
 * @return				The entity or -1 if no entity is being aimed at.
 */

stock int GetAimEntity(int iClient) {
	float fLocation[3], fAngles[3];
	GetClientEyePosition(iClient, fLocation);
	GetClientEyeAngles(iClient, fAngles);
	
	TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayEntities, iClient);
	
	if (TR_DidHit()) {
		int iEntity = TR_GetEntityIndex();
		
		if (IsValidEntity(iEntity)) {
			return iEntity;
		}
	}
	
	return -1;
}

public bool TraceRayEntities(int iEntity, int iMask, any iData) {
	return (iEntity != iData) && iEntity > MaxClients && IsValidEntity(iEntity);
}

/**
 * Gets a client by name.
 *
 * @param iClient		The executing clients index.
 * @param sName			The clients name.
 * @return				The clients client index, or -1 on error.
 */

stock int GetClientByName(int iClient, char[] sName) {
	char sNameOfIndex[MAX_NAME_LENGTH + 1];
	int iLen = strlen(sName);
	
	int iResults = 0;
	int iTarget = 0;
	
	for (int i = 1; i <= MaxClients; i++) {
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
			Forbid(iClient, true, "Couldn't find player %s.", sName);
		}
	} else {
		if (IsDefender(iClient)) {
			Forbid(iClient, true, "Be more specific.", sName);
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
 * @return					True on success, false otherwise.
 */

stock bool Substring(char[] sDest, int iDestLength, char[] sSource, int iSourceLength, int iStart, int iEnd) {
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
 * @return				True if number, false otherwise.
 */

stock bool IsStringNumeric(char[] sText) {
	for (int iChar = 0; iChar < strlen(sText); iChar++) {
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

stock float GetDistanceToGround(float fLocation[3]) {
	float fGround[3];
	
	TR_TraceRayFilter(fLocation, view_as<float>( { 90.0, 0.0, 0.0 } ), MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, 0);
	
	if (TR_DidHit()) {
		TR_GetEndPosition(fGround);
		
		return GetVectorDistance(fLocation, fGround);
	}
	
	return 0.0;
}

public bool TraceRayNoPlayers(int iEntity, int iMask, any iData) {
	return !(iEntity == iData || IsValidClient(iEntity));
}

/**
 * Sets the model of a client to the robot model.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock void SetRobotModel(int iClient) {
	char sClass[16], sModelPath[PLATFORM_MAX_PATH];
	
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

stock void GetClientClassName(int iClient, char[] sBuffer, int iMaxLength) {
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

/**
 * Check if a client is allowed to build an object.
 *
 * @param iClient 		The client.
 * @param iType			The building type.
 * @return				True if allowed, false otherwise.
 */

public bool CanClientBuild(int iClient, TDBuildingType iType) {
	if (!IsValidClient(iClient)) {
		return false;
	}
	
	if (TF2_IsPlayerInCondition(iClient, TFCond_Taunting)) {
		Forbid(iClient, true, "You can't build while taunting!");
		return false;
	}
	
	if (g_bCarryingObject[iClient]) {
		Forbid(iClient, true, "You can not build while carrying another building or a tower!");
		return false;
	}
	
	switch (iType) {
		case TDBuilding_Sentry: {
			if (GetClientMetal(iClient) < 130) {
				Forbid(iClient, true, "You need at least 130 metal!");
				return false;
			}
			
			int iEntity = -1, iCount = 0, iOwner = -1;
			
			while ((iEntity = FindEntityByClassname(iEntity, "obj_sentrygun")) != -1) {
				iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder");
				
				if (iOwner == iClient) {
					iCount++;
				}
				
				if (iCount > g_iBuildingLimit[TDBuilding_Sentry]) {
					AcceptEntityInput(iEntity, "Kill");
				}
			}
			
			// Client can build Sentry
			if (iCount < g_iBuildingLimit[TDBuilding_Sentry]) {
				return true;
			} else {
				Forbid(iClient, true, "Sentry limit reached! (Limit: %d)", g_iBuildingLimit[TDBuilding_Sentry]);
				return false;
			}
		}
		case TDBuilding_Dispenser: {
			if (GetClientMetal(iClient) < 100) {
				Forbid(iClient, true, "You need at least 100 metal!");
				return false;
			}
			
			int iEntity = -1, iCount = 0, iOwner = -1;
			
			while ((iEntity = FindEntityByClassname(iEntity, "obj_dispenser")) != -1) {
				iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder");
				
				if (iOwner == iClient) {
					iCount++;
				}
				
				if (iCount > g_iBuildingLimit[TDBuilding_Dispenser]) {
					AcceptEntityInput(iEntity, "Kill");
				}
			}
			
			// Client can build Dispenser
			if (iCount < g_iBuildingLimit[TDBuilding_Dispenser]) {
				Player_CAddValue(iClient, PLAYER_OBJECTS_BUILT, 1);
				return true;
			} else {
				Forbid(iClient, true, "Dispenser limit reached! (Limit: %d)", g_iBuildingLimit[TDBuilding_Dispenser]);
				return false;
			}
		}
	}
	
	return false;
}

/**
 * Prints a red forbid message to a client and plays a sound.
 *
 * @param iClient 		The client.
 * @param bPlaySound	Play the sound or not.
 * @param sMessage		The message.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void Forbid(int iClient, bool bPlaySound, const char[] sMessage, any...) {
	char sFormattedMessage[512];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	
	PrintToChat(iClient, "\x07FF0000%s", sFormattedMessage);
	
	if (bPlaySound) {
		PlaySound("Forbid", iClient);
	}
}

/**
 * Reloads the current map.
 *
 * @noreturn
 */

stock void ReloadMap() {
	char sCurrentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	
	ServerCommand("changelevel %s", sCurrentMap);
}

/**
 * Removes a flag from a cvar.
 *
 * @param sCvar		The cvar which is affected.
 * @param iFlag		The flag to remove.
 * @noreturn
 */

stock void StripConVarFlag(char[] sCvar, int iFlag) {
	Handle hCvar;
	int iFlags;
	
	hCvar = FindConVar(sCvar);
	iFlags = GetConVarFlags(hCvar);
	iFlags &= ~iFlag;
	SetConVarFlags(hCvar, iFlags);
}

/**
 * Adds a flag to a cvar.
 *
 * @param sCvar		The cvar which is affected.
 * @param iFlag		The flag to add.
 * @noreturn
 */

stock void AddConVarFlag(char[] sCvar, int iFlag) {
	Handle hCvar;
	int iFlags;
	
	hCvar = FindConVar(sCvar);
	iFlags = GetConVarFlags(hCvar);
	iFlags &= iFlag;
	SetConVarFlags(hCvar, iFlags);
}

/**
 * Checks if a client inside another client.
 *
 * @param iClient		The client to check.
 * @return				True if inside, false otherwise.
 */

stock bool IsInsideClient(int iClient) {
	float fMinBounds[3], fMaxBounds[3], fLocation[3];
	
	GetClientMins(iClient, fMinBounds);
	GetClientMaxs(iClient, fMaxBounds);
	
	GetClientAbsOrigin(iClient, fLocation);
	
	TR_TraceHullFilter(fLocation, fLocation, fMinBounds, fMaxBounds, MASK_SOLID, TraceRayPlayers, iClient);
	
	return TR_DidHit();
}

/**
 * Shows a custom HUD message to a client.
 *
 * @param iClient		The client.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void PrintToHud(int iClient, const char[] sMessage, any...) {
	if (!IsValidClient(iClient) || !IsClientInGame(iClient)) {
		return;
	}
	
	/*
	char sBuffer[256];
	
	SetGlobalTransTarget(iClient);
	VFormat(sBuffer, sizeof(sBuffer), sMessage, 3);
	ReplaceString(sBuffer, sizeof(sBuffer), "\"", "“");
	
	decl iParams[] = {0x76, 0x6F, 0x69, 0x63, 0x65, 0x5F, 0x73, 0x65, 0x6C, 0x66, 0x00, 0x00};
	new Handle:hMessage = StartMessageOne("HudNotifyCustom", iClient);
	BfWriteString(hMessage, sBuffer);
	
	for (new i = 0; i < sizeof(iParams); i++) {
		BfWriteByte(hMessage, iParams[i]);
	}
	
	EndMessage();
	*/
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 3);
	
	Handle hBuffer = StartMessageOne("KeyHintText", iClient);
	
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, sFormattedMessage);
	EndMessage();
}

/**
 * Shows a custom HUD message to all clients.
 *
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void PrintToHudAll(const char[] sMessage, any...) {
	char sFormattedMessage[256];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && !IsFakeClient(iClient)) {
			VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 2);
			PrintToHud(iClient, sFormattedMessage);
		}
	}
}

/**
 * Gets a client by name.
 *
 * @param sName			The clients name.
 * @param iTeam			The clients team, -1 for both teams.
 * @return				The client, or -1 on error.
 */

stock int GetClientByNameExact(char[] sName, int iTeam = -1) {
	char sClientName[MAX_NAME_LENGTH];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient)) {
			if (iTeam == -1) {
				GetClientName(iClient, sClientName, sizeof(sClientName));
				
				if (StrEqual(sName, sClientName)) {
					return iClient;
				}
			} else if (GetClientTeam(iClient) == iTeam) {
				GetClientName(iClient, sClientName, sizeof(sClientName));
				
				if (StrEqual(sName, sClientName)) {
					return iClient;
				}
			}
		}
	}
	
	return -1;
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void AttachAnnotation(int iEntity, float fLifetime, char[] sMessage, any...) {
	Handle hEvent = CreateEvent("show_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The entity.
 * @noreturn
 */

stock void HideAnnotation(int iEntity) {
	Handle hEvent = CreateEvent("hide_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "id", iEntity);
	FireEvent(hEvent);
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iClient		The client.
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void AttachAdvancedAnnotation(int iClient, int iEntity, float fLifetime, char[] sMessage, any...) {
	Handle hEvent = CreateEvent("show_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iClient * iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 5);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	SetEventInt(hEvent, "visibilityBitfield", GetVisibilityBitfield(iClient));
	
	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The client.
 * @param iEntity		The entity.
 * @noreturn
 */

stock void HideAdvancedAnnotation(int iClient, int iEntity) {
	Handle hEvent = CreateEvent("hide_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "id", iClient * iEntity);
	FireEvent(hEvent);
}

/**
 * Shows an annotation at a given location.
 *
 * @param iId			The id (use this to hide).
 * @param fLocation		The location vector.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void ShowAnnotation(int iId, float fLocation[3], float fOffsetZ, float fLifetime, char[] sMessage, any...) {
	Handle hEvent = CreateEvent("show_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventFloat(hEvent, "worldPosX", fLocation[0]);
	SetEventFloat(hEvent, "worldPosY", fLocation[1]);
	SetEventFloat(hEvent, "worldPosZ", fLocation[2] + fOffsetZ);
	SetEventInt(hEvent, "id", iId);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	FireEvent(hEvent);
}

/**
 * Converts an integer value to its absolute value.
 *
 * @param iValue		The value.
 * @return				The absolute value.
 */

stock int Abs(int iValue) {
	return (iValue < 0 ? -iValue : iValue);
}

/**
 * Sets the servers password.
 *
 * @param sPassword 	The password to set.
 * @param bDatabase 	Save the password in the database.
 * @param bReloadMap 	Reload map afterwards.
 * @noreturn
 */

stock void SetPassword(const char[] sPassword, bool bDatabase = true, bool bReloadMap = false) {
	ServerCommand("sv_password \"%s\"", sPassword);
	
	if (bDatabase) {
		Database_SetServerPassword(sPassword, bReloadMap);
	} else {
		Log(TDLogLevel_Debug, "Set server password to \"%s\"", sPassword);
	}
}

/**
 * Initializes a map (trie) handle.
 *
 * @param hMapHandle	The map handle to initialize.
 * @noreturn
 */

stock void CreateDataMap(Handle &hMapHandle) {
	if (hMapHandle != null) {
		CloseHandle(hMapHandle);
		hMapHandle = null;
	}
	
	hMapHandle = CreateTrie();
}

/**
 * Gets the entity index of the health bar.
 *
 * @return				The entity index of the health bar.
 */

stock int GetHealthBar() {
	int iHealthBar = FindEntityByClassname(-1, "monster_resource");
	
	if (!IsValidEntity(iHealthBar)) {
		iHealthBar = CreateEntityByName("monster_resource");
		
		if (IsValidEntity(iHealthBar)) {
			DispatchSpawn(iHealthBar);
		}
	}
	
	SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
	
	return iHealthBar;
} 

stock int GetClosestClient(int iClient)
{
	float fClientLocation[3];
	GetClientAbsOrigin(iClient, fClientLocation);
	float fEntityOrigin[3];

	int iClosestEntity = -1;
	float fClosestDistance = -1.0;
	for(int i = 1; i < MaxClients; i++) if(IsValidClient(i)) {
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) != GetClientTeam(iClient) && i > 0) {
			GetClientAbsOrigin(i, fEntityOrigin);
			float fEntityDistance = GetVectorDistance(fClientLocation, fEntityOrigin);
			if((fEntityDistance < fClosestDistance) || fClosestDistance == -1.0) {
				fClosestDistance = fEntityDistance;
				iClosestEntity = i;
			}
		}
	}
	return iClosestEntity;
}