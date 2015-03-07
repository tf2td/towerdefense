#pragma semicolon 1

#include <sourcemod>

#define PLAYER_USER_ID 		 0
#define PLAYER_DATABASE_ID 	 8
#define PLAYER_STEAM_ID 	16

new Handle:m_hPlayerData[MAXPLAYERS + 1];

/**
 * Called multiple times during server initialization.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock Player_ServerInitializing(iClient) {
	if (!TF2_IsPlayerInCondition(iClient, TFCond_RestrictToMelee)) {
		TF2_AddCondition(iClient, TFCond_RestrictToMelee);
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));
	}
	
	SetEntityMoveType(iClient, MOVETYPE_NONE);

	PrintToHud(iClient, "INITIALIZING GAME, PLEASE WAIT A MOMENT ...");
}

/**
 * Called once the server is initialized.
 *
 * @param iClient			The client.
 * @noreturn
 */

stock Player_ServerInitialized(iClient) {
	decl String:sCommunityId[32];

	if (!GetClientCommunityId(iClient, sCommunityId, sizeof(sCommunityId))) {
		Player_ConnectionError(iClient, "Could not get Steam identification number");
		return;
	}

	m_hPlayerData[iClient] = CreateDataPack();

	Player_SetUserId(iClient, GetClientUserId(iClient));
	Player_SetDatabaseId(iClient, 0);
	Player_SetSteamId(iClient, sCommunityId);

	TF2_RemoveCondition(iClient, TFCond_RestrictToMelee);
	SetEntityMoveType(iClient, MOVETYPE_WALK);

	Player_SyncDatabase(iClient, sCommunityId);

	Log(TDLogLevel_Debug, "Successfully initialized player %N (%s)", iClient, sCommunityId);
}

stock Player_SyncDatabase(iClient, const String:sCommunityId[]) {
	Database_CheckPlayer(iClient, sCommunityId);
}

stock Player_ConnectionError(iClient, const String:sError[]) {
	// Kick from server
}

/**
 * Called once the client is connected.
 *
 * @param iUserId			The user id on server (unique on server). 
 * @param iClient			The client.
 * @param sName				The clients name.
 * @param sCommunityId		The clients 32-bit steam id.
 * @param sCommunityId		The clients 64-bit steam id (community id).
 * @param sIp				The clients network address (ip).
 * @noreturn
 */

stock Player_Connected(iUserId, iClient, const String:sName[], const String:sSteamId[], const String:sCommunityId[], const String:sIp[]) {
	Log(TDLogLevel_Trace, "Player connected (UserId=%d, Client=%d, Name=%s, SteamId=%s, CommunityId=%s, Address=%s)", iUserId, iClient, sName, sSteamId, sCommunityId, sIp);

	if (!StrEqual(sSteamId, "BOT")) {
		if (GetRealClientCount() > PLAYER_LIMIT) {
			KickClient(iClient, "Maximum number of players has been reached (%d/%d)", GetRealClientCount() - 1, PLAYER_LIMIT);
			Log(TDLogLevel_Info, "Kicked player (%N, %s) (Maximum players reached: %d/%d)", iClient, sSteamId, GetRealClientCount() - 1, PLAYER_LIMIT);
			return;
		}

		Log(TDLogLevel_Info, "Connected clients: %d/%d", GetRealClientCount(), PLAYER_LIMIT);

		SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(iClient, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

		g_bCarryingObject[iClient] = false;
		g_bReplaceWeapon[iClient][TFWeaponSlot_Primary] = false;
		g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = false;
		g_bReplaceWeapon[iClient][TFWeaponSlot_Melee] = false;

		g_iAttachedTower[iClient] = 0;

		ChangeClientTeam(iClient, TEAM_DEFENDER);
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);

		Log(TDLogLevel_Debug, "Moved player %N to the Defenders team as Engineer", iClient);
	}
}

/**
 * Called once the client has entered the game (connected and loaded)
 *
 * @param iClient			The client.
 * @noreturn
 */

stock Player_Active(iClient) {
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		CreateTimer(1.0, InitInfoTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:InitInfoTimer(Handle:hTimer, any:iClient) {
	if (g_bServerInitialized) {
		Player_ServerInitialized(iClient);
		return Plugin_Stop;
	}

	Player_ServerInitializing(iClient);

	CreateTimer(1.0, InitInfoTimer, iClient, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

stock Player_SetUserId(iClient, iUserId) {
	SetPackPosition(m_hPlayerData[iClient], PLAYER_USER_ID);
	WritePackCell(m_hPlayerData[iClient], iUserId);
}

stock Player_GetUserId(iClient) {
	SetPackPosition(m_hPlayerData[iClient], PLAYER_USER_ID)
	return ReadPackCell(m_hPlayerData[iClient]);
}

stock Player_SetDatabaseId(iClient, iDatabaseId) {
	SetPackPosition(m_hPlayerData[iClient], PLAYER_DATABASE_ID);
	WritePackCell(m_hPlayerData[iClient], iDatabaseId);
}

stock Player_GetDatabaseId(iClient) {
	SetPackPosition(m_hPlayerData[iClient], PLAYER_DATABASE_ID)
	return ReadPackCell(m_hPlayerData[iClient]);
}

stock Player_SetSteamId(iClient, const String:sSteamId[]) {
	SetPackPosition(m_hPlayerData[iClient], PLAYER_STEAM_ID);
	WritePackString(m_hPlayerData[iClient], sSteamId);
}

stock Player_GetSteamId(iClient, String:sSteamId[], iMaxLength) {
	SetPackPosition(m_hPlayerData[iClient], PLAYER_STEAM_ID);
	ReadPackString(m_hPlayerData[iClient], sSteamId, iMaxLength);
}