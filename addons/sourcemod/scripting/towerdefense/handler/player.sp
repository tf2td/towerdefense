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