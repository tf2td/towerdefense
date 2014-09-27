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

#define PLUGIN_HOST 	"Styria Games"

#define PLUGIN_NAME		"TF2 Tower Defense"
#define PLUGIN_AUTHOR	"floube"
#define PLUGIN_DESC		"Stop enemies from crossing a map by buying towers and building up defenses."
#define PLUGIN_VERSION	"1.0.0"
#define PLUGIN_URL		"http://www.tf2td.net/"
#define PLUGIN_PREFIX	"[TF2TD]"

#define DATABASE_HOST 	"46.38.241.137"
#define DATABASE_NAME 	"tf2tdsql5"
#define DATABASE_USER 	"tf2td_styria"
#define DATABASE_PASS 	"t9J3gTiep8zbvVObSGeom09btg3Ts1Nm"

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
#include "towerdefense/util/steamid.sp"
#include "towerdefense/util/tf2items.sp"
#include "towerdefense/util/zones.sp"

#include "towerdefense/handler/corners.sp"
#include "towerdefense/handler/metalpacks.sp"
#include "towerdefense/handler/towers.sp"
#include "towerdefense/handler/waves.sp"
#include "towerdefense/handler/weapons.sp"

#include "towerdefense/commands.sp"
#include "towerdefense/database.sp"
#include "towerdefense/events.sp"
#include "towerdefense/timers.sp"
#include "towerdefense/updater.sp"

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

	if (g_hMapTowers != INVALID_HANDLE) {
		CloseHandle(g_hMapTowers);
		g_hMapTowers = INVALID_HANDLE;
	}

	g_hMapTowers = CreateTrie();

	if (g_hMapWeapons != INVALID_HANDLE) {
		CloseHandle(g_hMapWeapons);
		g_hMapWeapons = INVALID_HANDLE;
	}

	g_hMapWeapons = CreateTrie();

	if (g_hMapWaves != INVALID_HANDLE) {
		CloseHandle(g_hMapWaves);
		g_hMapWaves = INVALID_HANDLE;
	}

	g_hMapWaves = CreateTrie();

	if (g_hMapMetalpacks != INVALID_HANDLE) {
		CloseHandle(g_hMapMetalpacks);
		g_hMapMetalpacks = INVALID_HANDLE;
	}

	g_hMapMetalpacks = CreateTrie();

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

	if (g_hDatabase != INVALID_HANDLE) {
		CloseHandle(g_hDatabase);
		g_hDatabase = INVALID_HANDLE;
	}

	SetConVarInt(FindConVar("sv_cheats"), 0, true, false);
}

public OnMapStart() {
	g_bTowerDefenseMap = IsTowerDefenseMap();

	PrecacheModels();
	PrecacheSounds();

	new iHealthBar = CreateEntityByName("monster_resource");

	if (DispatchSpawn(iHealthBar)) {
		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
		g_iHealthBar = EntIndexToEntRef(iHealthBar);
	}
}

public OnMapEnd() {
	g_bMapRunning = false;

	new bool:bWasEnabled = g_bEnabled;
	g_bEnabled = false;

	if (bWasEnabled) {
		UpdateGameDescription();
	}

	AddConVarFlag("sv_cheats", FCVAR_NOTIFY);
	AddConVarFlag("sv_tags", FCVAR_NOTIFY);
	AddConVarFlag("tf_bot_count", FCVAR_NOTIFY);
	AddConVarFlag("sv_password", FCVAR_NOTIFY);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled) && g_bTowerDefenseMap && g_bSteamTools && g_bTF2Attributes;
	g_bMapRunning = true;

	UpdateGameDescription();

	if (!g_bEnabled) {
		if (!g_bTowerDefenseMap) {
			decl String:sCurrentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

			Log(TDLogLevel_Info, "Map \"%s\" is not supported, thus Tower Defense has been disabled.", sCurrentMap);
		} else {
			Log(TDLogLevel_Info, "Tower Defense is disabled.");
		}

		return;
	}

	StripConVarFlag("sv_cheats", FCVAR_NOTIFY);
	StripConVarFlag("sv_tags", FCVAR_NOTIFY);
	StripConVarFlag("tf_bot_count", FCVAR_NOTIFY);
	StripConVarFlag("sv_password", FCVAR_NOTIFY);

	HookButtons();

	g_iBuildingLimit[TDBuilding_Sentry] = 1;
	g_iBuildingLimit[TDBuilding_Dispenser] = 0;
	g_iBuildingLimit[TDBuilding_TeleporterEntry] = 1;
	g_iBuildingLimit[TDBuilding_TeleporterExit] = 1;

	g_iMetalPackCount = 0;

	new iHealthBar = EntRefToEntIndex(g_iHealthBar);
	if (IsValidEntity(iHealthBar)) {
		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
	}

	Database_Connect();
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

public OnClientAuthorized(iClient, const String:sSteamId[]) {
	if (!g_bEnabled) {
		return;
	}

	if (IsValidClient(iClient) && !StrEqual(sSteamId, "BOT")) {
		if (GetRealClientCount() > PLAYER_LIMIT) {
			KickClient(iClient, "Maximum number of players has been reached (%d/%d)", GetRealClientCount() - 1, PLAYER_LIMIT);
			Log(TDLogLevel_Info, "Kicked player (%N, %s) (Maximum players reached: %d/%d)", iClient, sSteamId, GetRealClientCount() - 1, PLAYER_LIMIT);
			return;
		}

		Log(TDLogLevel_Info, "Connected clients: %d/%d", GetRealClientCount(), PLAYER_LIMIT);
	}

	decl String:sCommunityId[32];
	if (GetClientCommunityId(iClient, sCommunityId, sizeof(sCommunityId))) {
		PrintToServer("%N = %s", iClient, sCommunityId);
	}
}

public OnClientPutInServer(iClient) {
	if (!g_bEnabled) {
		return;
	}

	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(iClient, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	g_bCarryingObject[iClient] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Primary] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Melee] = false;

	g_iAttachedTower[iClient] = 0;
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

public OnClientDisconnect(iClient) {
	if (!g_bEnabled) {
		return;
	}

	if (IsTower(g_iAttachedTower[iClient])) {
		Tower_OnCarrierDisconnected(g_iAttachedTower[iClient], iClient);
	}

	new iMetal = GetClientMetal(iClient);

	if (iMetal > 0) {
		new Float:fLocation[3];

		GetClientEyePosition(iClient, fLocation);
		fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;

		SpawnMetalPack(TDMetalPack_Small, fLocation, iMetal);
	}
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	// Force towers to shoot
	if (IsTower(iClient)) {
		new TDTowerId:iTowerId = GetTowerId(iClient);

		// Refill ammo for airblast tower
		if (iTowerId == TDTower_Airblast_Pyro) {
			new iOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			if (GetEntData(iClient, iOffset + 4) <= 0) {
				SetEntData(iClient, iOffset + 4, 100);
			}
		}

		if (Tower_GetAttackPrimary(iTowerId)) {
			iButtons |= IN_ATTACK;
		}

		if (Tower_GetAttackSecondary(iTowerId)) {
			iButtons |= IN_ATTACK2;
		}
	}

	if (IsAttacker(iClient) && g_bBoostWave[iClient]) {
		if (g_iNextWaveType & TDWaveType_Rapid) {
			fVelocity[0] = 500.0;
		}
	}

	if (IsDefender(iClient)) {
		// Attach/detach tower on right-click
		if (IsButtonReleased(iClient, iButtons, IN_ATTACK2)) { 
			decl String:sActiveWeapon[64];
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
			decl String:sActiveWeapon[64];
			GetClientWeapon(iClient, sActiveWeapon, sizeof(sActiveWeapon));
			
			if (StrEqual(sActiveWeapon, "tf_weapon_wrench") || StrEqual(sActiveWeapon, "tf_weapon_robot_arm")) {
				Tower_ShowInfo(iClient);
			}
		}

		new Float:fLocation[3], Float:fViewAngles[3];
		GetClientEyePosition(iClient, fLocation);
		GetClientEyeAngles(iClient, fViewAngles);
			
		TR_TraceRayFilter(fLocation, fViewAngles, MASK_VISIBLE, RayType_Infinite, TraceRayEntities, iClient);
		
		if (TR_DidHit()) {
			new iAimEntity = TR_GetEntityIndex();
		
			if (IsValidEntity(iAimEntity)) {
				decl String:sClassname[64];
				GetEntityClassname(iAimEntity, sClassname, sizeof(sClassname));

				if (StrEqual(sClassname, "func_breakable")) {
					decl String:sName[64];
					GetEntPropString(iAimEntity, Prop_Data, "m_iName", sName, sizeof(sName));

					if (StrContains(sName, "break_tower_") != -1) {
						new Float:fEntityLocation[3];
						GetEntPropVector(iAimEntity, Prop_Send, "m_vecOrigin", fEntityLocation);

						if (GetVectorDistance(fLocation, fEntityLocation) <= 512.0) {
							new TDTowerId:iTowerId;

							if (StrContains(sName, "break_tower_tp_") != -1) {
								decl String:sNameParts[4][32];
								ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

								iTowerId = TDTowerId:StringToInt(sNameParts[3]);
								Tower_GetName(iTowerId, sName, sizeof(sName));
							} else {
								decl String:sNameParts[3][32];
								ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

								iTowerId = TDTowerId:StringToInt(sNameParts[2]);
								Tower_GetName(iTowerId, sName, sizeof(sName));
							}

							decl String:sDescription[1024];
							if (Tower_GetDescription(iTowerId, sDescription, sizeof(sDescription))) {
								decl String:sDamagetype[64];
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

public Action:OnTakeDamage(iClient, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType, &iWeapon, Float:fDamageForce[3], Float:fDamagePosition[3]) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	// Block tower taking damage
	if (IsTower(iClient)) {
		return Plugin_Handled;
	}

	if (IsDefender(iClient)) {
		if (fDamage >= GetClientHealth(iClient)) {
			new iMetal = GetClientMetal(iClient);

			if (iMetal > 0) {
				new Float:fLocation[3];

				GetClientEyePosition(iClient, fLocation);
				fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;

				SpawnMetalPack(TDMetalPack_Small, fLocation, iMetal);
			}
		}
	}

	return Plugin_Continue;
}

public OnTakeDamagePost(iClient, iAttacker, iInflictor, Float:fDamage, iDamageType) {
	if (!g_bEnabled) {
		return;
	}

	if (IsAttacker(iClient)) {
		Wave_OnTakeDamagePost(iClient, iAttacker, iInflictor, fDamage, iDamageType);
	}
}

public OnEntityCreated(iEntity, const String:sClassname[]) {
	if (StrEqual(sClassname, "tf_ammo_pack")) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnWeaponSpawned);
	} else if (StrEqual(sClassname, "func_breakable")) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnButtonSpawned);
	} else if (StrContains(sClassname, "tf_projectile_") != -1) {
		SDKHook(iEntity, SDKHook_SpawnPost, OnProjectileSpawned);
	} else if (StrEqual(sClassname, "trigger_multiple")) {
		SDKHook(iEntity, SDKHook_StartTouchPost, Wave_OnTouchCorner);
	}
}

public OnWeaponSpawned(iEntity) {
	new iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

	if (IsDefender(iOwner)) {
		AcceptEntityInput(iEntity, "Kill");
	}

	decl String:sName[64];
	IntToString(iOwner, sName, sizeof(sName));
	DispatchKeyValue(iEntity, "targetname", sName);

	SDKHook(iEntity, SDKHook_Touch, OnTouchWeapon);
}

public Action:OnTouchWeapon(iEntity, iClient) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	if (IsDefender(iClient)) {
		decl String:sName[64];
		GetEntPropString(iEntity, Prop_Data, "m_iName", sName, sizeof(sName));

		new iOwner = StringToInt(sName);

		if (IsValidClient(iOwner)) {
			// Picking up weapon

			AcceptEntityInput(iEntity, "Kill");
			AddClientMetal(iClient, 100);
			ResupplyClient(iClient, true, 0.25);
			EmitSoundToAll("items/ammo_pickup.wav", iClient);
		} else {
			AcceptEntityInput(iEntity, "Kill");
			AddClientMetal(iClient, 15);
			EmitSoundToAll("items/ammo_pickup.wav", iClient);
		}
	}

	return Plugin_Handled;
}

public OnButtonSpawned(iEntity) {
	if (!g_bEnabled) {
		return;
	}

	decl String:sName[64];
	GetEntPropString(iEntity, Prop_Data, "m_iName", sName, sizeof(sName));

	if (StrEqual(sName, "wave_start")) {
		g_iWaveStartButton = iEntity;
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", g_fWaveStartButtonLocation);
	}
}

public OnProjectileSpawned(iEntity) {
	if (!g_bEnabled) {
		return;
	}

	SDKHook(iEntity, SDKHook_ShouldCollide, OnProjectileCollide);
}

public bool:OnProjectileCollide(iEntity, iCollisiongroup, iContentsmask, bool:bResult) {
	if (!g_bEnabled) {
		return true;
	}

	new iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

	if (IsValidClient(iOwner)) {
		new Float:fLocation[3], Float:fAngles[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fLocation);
		GetEntPropVector(iEntity, Prop_Data, "m_angAbsRotation", fAngles);

		TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayers, iOwner);

		if (TR_DidHit()) {
			new iTarget = TR_GetEntityIndex();

			if (IsValidClient(iTarget)) {
				if (GetClientTeam(iOwner) != GetClientTeam(iTarget)) {
					SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 0);
				} else {
					SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 24);
				}
			}
		}
	}

	return true;
}

public Action:OnNobuildEnter(iEntity, iClient) {
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

public Action:OnNobuildExit(iEntity, iClient) {
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
	
	PrecacheSound("items/ammo_pickup.wav");
	PrecacheSound("items/gunpickup2.wav");
	PrecacheSound("vo/announcer_begins_5sec.wav");
	PrecacheSound("vo/announcer_begins_4sec.wav");
	PrecacheSound("vo/announcer_begins_3sec.wav");
	PrecacheSound("vo/announcer_begins_2sec.wav");
	PrecacheSound("vo/announcer_begins_1sec.wav");
	PrecacheSound("vo/engineer_no03.wav");
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

/**
 * Check if a client is allowed to build an object.
 *
 * @param iClient 		The client.
 * @param iType			The building type.
 * @return				True if allowed, false otherwise.
 */

public bool:CanClientBuild(iClient, TDBuildingType:iType) {
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

			new iEntity = -1, iCount = 0, iOwner = -1;

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

			new iEntity = -1, iCount = 0, iOwner = -1;

			while ((iEntity = FindEntityByClassname(iEntity, "obj_dispenser")) != -1) {
				iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder");

				if (iOwner == iClient) {
					iCount++;
				}

				if (iCount > g_iBuildingLimit[TDBuilding_Dispenser]) {
					AcceptEntityInput(iEntity, "Kill");
				}
			}

			// Client can build Sentry
			if (iCount < g_iBuildingLimit[TDBuilding_Dispenser]) {
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

stock Forbid(iClient, bool:bPlaySound, const String:sMessage[], any:...) {
	decl String:sFormattedMessage[512];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);

	PrintToChat(iClient, "\x07FF0000%s", sFormattedMessage);

	if (bPlaySound) {
		EmitSoundToClient(iClient, "vo/engineer_no03.wav");
	}
}

/**
 * Reloads the current map.
 *
 * @noreturn
 */

stock ReloadMap() {
	new String:sCurrentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	ServerCommand("changelevel %s", sCurrentMap);
}

/**
 * Hooks buttons.
 *
 * @noreturn
 */

stock HookButtons() {
	HookEntityOutput("func_breakable", "OnHealthChanged", OnButtonShot);
}

public OnButtonShot(const String:sOutput[], iCaller, iActivator, Float:fDelay) {
	decl String:sName[64];
	GetEntPropString(iCaller, Prop_Data, "m_iName", sName, sizeof(sName));

	if (StrContains(sName, "break_tower_tp_") != -1) {
		// Tower teleport

		decl String:sNameParts[4][32];
		ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

		new TDTowerId:iTowerId = TDTowerId:StringToInt(sNameParts[3]);
		Tower_OnButtonTeleport(iTowerId, iCaller, iActivator);
	} else if (StrContains(sName, "break_tower_") != -1) {
		// Tower buy

		decl String:sNameParts[3][32];
		ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

		new TDTowerId:iTowerId = TDTowerId:StringToInt(sNameParts[2]);
		Tower_OnButtonBuy(iTowerId, iCaller, iActivator);
	} else if (StrContains(sName, "wave_start") != -1) {
		// Wave start

		if (StrEqual(sName, "wave_start")) {
			Wave_OnButtonStart(0, iCaller, iActivator);
		} else {
			decl String:sNameParts[3][32];
			ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

			Wave_OnButtonStart(StringToInt(sNameParts[2]), iCaller, iActivator);
		}
	}
}

/**
 * Checks if all clients have enough metal to pay a price.
 *
 * @param iPrice		The price to pay.
 * @return				True if affordable, false ontherwise.
 */

stock bool:CanAfford(iPrice) {
	new bool:bResult = true;

	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient)) {
			if (GetClientMetal(iClient) < iPrice) {
				PrintToChatAll("\x07FF0000%N needs %d metal", iClient, iPrice - GetClientMetal(iClient));
				
				bResult = false;
			}
		}
	}

	return bResult;
}

/**
 * Removes a flag from a cvar.
 *
 * @param sCvar		The cvar which is affected.
 * @param iFlag		The flag to remove.
 * @noreturn
 */

stock StripConVarFlag(String:sCvar[], iFlag) {
	new Handle:hCvar, iFlags;

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

stock AddConVarFlag(String:sCvar[], iFlag) {
	new Handle:hCvar, iFlags;

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

stock bool:IsInsideClient(iClient) {
	new Float:fMinBounds[3], Float:fMaxBounds[3], Float:fLocation[3];

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

stock PrintToHud(iClient, const String:sMessage[], any:...) {
	if (!IsValidClient(iClient) || !IsClientInGame(iClient)) {
		return;
	}
	
	/*
	decl String:sBuffer[256];
	
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

	decl String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 3);

	new Handle:hBuffer = StartMessageOne("KeyHintText", iClient);

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

stock PrintToHudAll(const String:sMessage[], any:...) {
	decl String:sFormattedMessage[256];
	
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && !IsFakeClient(iClient)) {
			VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 2);
			PrintToHud(iClient, sBuffer);
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

stock GetClientByNameExact(String:sName[], iTeam = -1) {
	new String:sClientName[MAX_NAME_LENGTH];
	
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
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

stock AttachAnnotation(iEntity, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity); 
	SetEventInt(hEvent, "id", iEntity); 
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
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

stock HideAnnotation(iEntity) {
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
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

stock AttachAdvancedAnnotation(iClient, iEntity, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iClient * iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
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

stock HideAdvancedAnnotation(iClient, iEntity) {
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
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

stock ShowAnnotation(iId, Float:fLocation[3], Float:fOffsetZ, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventFloat(hEvent, "worldPosX", fLocation[0]);
	SetEventFloat(hEvent, "worldPosY", fLocation[1]);
	SetEventFloat(hEvent, "worldPosZ", fLocation[2] + fOffsetZ);
	SetEventInt(hEvent, "id", iId);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);

	FireEvent(hEvent);
}

stock Abs(iValue) {
	if (iValue < 0) {
		return iValue * (-1);
	}

	return iValue;
}