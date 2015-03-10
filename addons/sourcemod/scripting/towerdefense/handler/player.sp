#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Called multiple times during server initialization.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock Player_ServerInitializing(iUserId, iClient) {
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
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock Player_ServerInitialized(iUserId, iClient) {
	decl String:sCommunityId[32];
	Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sCommunityId, sizeof(sCommunityId));

	TF2_RemoveCondition(iClient, TFCond_RestrictToMelee);
	SetEntityMoveType(iClient, MOVETYPE_WALK);

	Player_SyncDatabase(iUserId, iClient, sCommunityId);

	Log(TDLogLevel_Debug, "Successfully initialized player %N (%s)", iClient, sCommunityId);
}

/**
 * Syncs all initial things of a client with the database.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @param sCommunityId		The clients 64-bit steam id (community id).
 * @noreturn
 */

stock Player_SyncDatabase(iUserId, iClient, const String:sCommunityId[]) {
	Database_CheckPlayer(iUserId, iClient, sCommunityId);
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
	Log(TDLogLevel_Debug, "Player connected (UserId=%d, Client=%d, Name=%s, SteamId=%s, CommunityId=%s, Address=%s)", iUserId, iClient, sName, sSteamId, sCommunityId, sIp);

	if (!StrEqual(sSteamId, "BOT")) {
		if (GetRealClientCount() > PLAYER_LIMIT) {
			KickClient(iClient, "Maximum number of players has been reached (%d/%d)", GetRealClientCount() - 1, PLAYER_LIMIT);
			Log(TDLogLevel_Info, "Kicked player (%N, %s) (Maximum players reached: %d/%d)", iClient, sSteamId, GetRealClientCount() - 1, PLAYER_LIMIT);
			return;
		}

		Log(TDLogLevel_Info, "Connected clients: %d/%d", GetRealClientCount(), PLAYER_LIMIT);

		Player_USetString(iUserId, PLAYER_STEAM_ID, sSteamId);
		Player_USetString(iUserId, PLAYER_COMMUNITY_ID, sCommunityId);
		Player_USetString(iUserId, PLAYER_IP_ADDRESS, sIp);

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
 * Called before the client disconnects.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock Player_OnDisconnectPre(iUserId, iClient) {
	Database_UpdatePlayerDisconnect(iUserId);

	if (GetRealClientCount(true) <= 1) { // the disconnected player is counted (thus 1 not 0)
		SetPassword(SERVER_PASS, true, true);
	}
}

/**
 * Called once the client has entered the game (connected and loaded).
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock Player_Loaded(iUserId, iClient) {
	decl String:sCommunityId[32];
	Player_CGetString(iClient, PLAYER_COMMUNITY_ID, sCommunityId, sizeof(sCommunityId));

	Log(TDLogLevel_Debug, "Player loaded (UserId=%d, Client=%d, CommunityId=%s)", iUserId, iClient, sCommunityId);

	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		CreateTimer(1.0, InitInfoTimer, iUserId, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:InitInfoTimer(Handle:hTimer, any:iUserId) {
	if (g_bServerInitialized) {
		Player_ServerInitialized(iUserId, GetClientOfUserId(iUserId));
		return Plugin_Stop;
	}

	Player_ServerInitializing(iUserId, GetClientOfUserId(iUserId));

	CreateTimer(1.0, InitInfoTimer, iUserId, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

/**
 * Called when a client spawned.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock Player_OnSpawn(iUserId, iClient) {
	ResetClientMetal(iClient);
	SetEntProp(iClient, Prop_Data, "m_bloodColor", _:TDBlood_None);

	if (g_bReplaceWeapon[iClient][TFWeaponSlot_Primary]) {
		TF2Items_GiveWeapon(iClient, 9, TFWeaponSlot_Primary, 5, 1, true, "tf_weapon_shotgun_primary", "");	
		
		g_bReplaceWeapon[iClient][TFWeaponSlot_Primary] = false;
	}

	if (g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary]) {
		TF2Items_GiveWeapon(iClient, 22, TFWeaponSlot_Secondary, 5, 1, true, "tf_weapon_pistol", "");
			
		g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = false;
	}
}

/**
 * Called when a client dies.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock Player_OnDeath(iUserId, iClient) {
	g_bCarryingObject[iClient] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Primary] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Melee] = false;

	if (IsTower(g_iAttachedTower[iClient])) {
		Tower_OnCarrierDeath(g_iAttachedTower[iClient], iClient);
	}
}

/**
 * Called when a client data was set.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @param sKey				The set key.
 * @param iDataType			The datatype of the set data.
 * @param iValue			The value if the set data is an integer, -1 otherwise.
 * @param bValue			The value if the set data is a boolean, false otherwise.
 * @param fValue			The value if the set data is a float, -1.0 otherwise.
 * @param sValue			The value if the set data is a string, empty string ("") otherwise.
 * @noreturn
 */

stock Player_OnDataSet(iUserId, iClient, const String:sKey[], TDDataType:iDataType, iValue, bValue, Float:fValue, const String:sValue[]) {
	switch (iDataType) {
		case TDDataType_Integer: {
			Log(TDLogLevel_Trace, "Player_OnDataSet: iUserId=%d, iClient=%d, sKey=%s, iDataType=TDDataType_Integer, iValue=%d", iUserId, iClient, sKey, iValue);
		}

		case TDDataType_Boolean: {
			Log(TDLogLevel_Trace, "Player_OnDataSet: iUserId=%d, iClient=%d, sKey=%s, iDataType=TDDataType_Boolean, bValue=%s", iUserId, iClient, sKey, (bValue ? "true" : "false"));
		}

		case TDDataType_Float: {
			Log(TDLogLevel_Trace, "Player_OnDataSet: iUserId=%d, iClient=%d, sKey=%s, iDataType=TDDataType_Float, fValue=%f", iUserId, iClient, sKey, fValue);
		}

		case TDDataType_String: {
			Log(TDLogLevel_Trace, "Player_OnDataSet: iUserId=%d, iClient=%d, sKey=%s, iDataType=TDDataType_String, sValue=%s", iUserId, iClient, sKey, sValue);
		}
	}
}

stock CheckClientForUserId(iClient) {
	return (iClient > 0 && iClient <= MaxClients && IsClientConnected(iClient));
}

stock Player_USetValue(iUserId, const String:sKey[], iValue) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, iValue, false, -1.0, "");

	SetTrieValue(g_hPlayerData, sUserIdKey, iValue);
}

stock Player_CSetValue(iClient, const String:sKey[], iValue) {
	if (CheckClientForUserId(iClient)) {
		Player_USetValue(GetClientUserId(iClient), sKey, iValue);
	}
}

stock bool:Player_UGetValue(iUserId, const String:sKey[], &iValue) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetValue: iUserId=%d, sKey=%s", iUserId, sKey);
	
	if (!GetTrieValue(g_hPlayerData, sUserIdKey, iValue)) {
		iValue = -1;
		return false;
	}

	return true;
}

stock bool:Player_CGetValue(iClient, const String:sKey[], &iValue) {
	return CheckClientForUserId(iClient) && Player_UGetValue(GetClientUserId(iClient), sKey, iValue);
}

stock Player_USetBool(iUserId, const String:sKey[], bool:bValue) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, -1, bValue, -1.0, "");

	SetTrieValue(g_hPlayerData, sUserIdKey, (bValue ? 1 : 0));
}

stock Player_CSetBool(iClient, const String:sKey[], bool:bValue) {
	if (CheckClientForUserId(iClient)) {
		Player_USetBool(GetClientUserId(iClient), sKey, bValue);
	}
}

stock bool:Player_UGetBool(iUserId, const String:sKey[]) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetBool: iUserId=%d, sKey=%s", iUserId, sKey);
	
	new iValue = 0;
	GetTrieValue(g_hPlayerData, sUserIdKey, iValue);

	return (iValue != 0);
}

stock bool:Player_CGetBool(iClient, const String:sKey[]) {
	return CheckClientForUserId(iClient) && Player_UGetBool(GetClientUserId(iClient), sKey);
}

stock Player_USetFloat(iUserId, const String:sKey[], Float:fValue) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	decl String:sValue[64];
	FloatToString(fValue, sValue, sizeof(sValue))

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, -1, false, fValue, "");

	SetTrieString(g_hPlayerData, sUserIdKey, sValue);
}

stock Player_CSetFloat(iClient, const String:sKey[], Float:fValue) {
	if (CheckClientForUserId(iClient)) {
		Player_USetFloat(GetClientUserId(iClient), sKey, fValue);
	}
}

stock bool:Player_UGetFloat(iUserId, const String:sKey[], &Float:fValue) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetFloat: iUserId=%d, sKey=%s", iUserId, sKey);

	decl String:sValue[64];
	if (!GetTrieString(g_hPlayerData, sUserIdKey, sValue, sizeof(sValue))) {
		fValue = -1.0;
		return false;
	}

	fValue = StringToFloat(sValue);
	return true;
}

stock bool:Player_CGetFloat(iClient, const String:sKey[], &Float:fValue) {
	return CheckClientForUserId(iClient) && Player_UGetFloat(GetClientUserId(iClient), sKey, fValue);
}

stock Player_USetString(iUserId, const String:sKey[], const String:sValue[], any:...) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	decl String:sFormattedValue[256];
	VFormat(sFormattedValue, sizeof(sFormattedValue), sValue, 4);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_String, -1, false, -1.0, sValue);

	SetTrieString(g_hPlayerData, sUserIdKey, sFormattedValue);
}

stock Player_CSetString(iClient, const String:sKey[], const String:sValue[], any:...) {
	if (CheckClientForUserId(iClient)) {
		decl String:sFormattedValue[256];
		VFormat(sFormattedValue, sizeof(sFormattedValue), sValue, 4);

		Player_USetString(GetClientUserId(iClient), sKey, sFormattedValue);
	}
}

stock bool:Player_UGetString(iUserId, const String:sKey[], String:sValue[], iMaxLength) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetString: iUserId=%d, sKey=%s, iMaxLength=%d", iUserId, sKey, iMaxLength);

	if (!GetTrieString(g_hPlayerData, sUserIdKey, sValue, iMaxLength)) {
		Format(sValue, iMaxLength, "");
		return false;
	}

	return true;
}

stock bool:Player_CGetString(iClient, const String:sKey[], String:sValue[], iMaxLength) {
	return CheckClientForUserId(iClient) && Player_UGetString(GetClientUserId(iClient), sKey, sValue, iMaxLength);
}

/*==========  May not be of use  ==========*/
/*
stock Player_USetArray(iUserId, const String:sKey[], const any:aArray[], iNumItems) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_USetArray: iUserId=%d, sKey=%s, iNumItems=%d", iUserId, sKey, iNumItems);

	SetTrieArray(g_hPlayerData, sUserIdKey, aArray, iNumItems);
}

stock Player_CSetArray(iClient, const String:sKey[], const any:aArray[], iNumItems) {
	if (CheckClientForUserId(iClient)) {
		Player_USetArray(GetClientUserId(iClient), sKey, aArray, iNumItems);
	}
}

stock bool:Player_UGetArray(iUserId, const String:sKey[], any:aArray[], iMaxSize) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetArray: iUserId=%d, sKey=%s, iMaxSize=%d", iUserId, sKey, iMaxSize);

	new bool:bResult = GetTrieArray(g_hPlayerData, sUserIdKey, aArray, iMaxSize);

	if (!bResult) {
		bResult = GetTrieValue(g_hPlayerData, sUserIdKey, aArray[0]);
	}

	return bResult;
}

stock bool:Player_CGetArray(iClient, const String:sKey[], any:aArray[], iMaxSize) {
	return CheckClientForUserId(iClient) && Player_UGetArray(GetClientUserId(iClient), sKey, aArray, iMaxSize);
}

stock Player_USetArrayValue(iUserId, const String:sKey[], iIndex, any:aValue, const iNumItems) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_USetArrayValue: iUserId=%d, sKey=%s, iIndex=%d, iNumItems=%d", iUserId, sKey, iIndex, iNumItems);

	new any:aArray[iNumItems];
	GetTrieArray(g_hPlayerData, sUserIdKey, aArray, iNumItems);

	aArray[iIndex] = aValue;

	SetTrieArray(g_hPlayerData, sUserIdKey, aArray, iNumItems);
}

stock Player_CSetArrayValue(iClient, const String:sKey[], iIndex, any:aValue, const iNumItems) {
	if (CheckClientForUserId(iClient)) {
		Player_USetArrayValue(GetClientUserId(iClient), sKey, iIndex, aValue, iNumItems);
	}
}

stock bool:Player_UGetArrayValue(iUserId, const String:sKey[], iIndex, &any:aValue, const iNumItems) {
	decl String:sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_USetArrayValue: iUserId=%d, sKey=%s, iIndex=%d, iNumItems=%d", iUserId, sKey, iIndex, iNumItems);

	new any:aArray[iNumItems];
	new bool:bResult = GetTrieArray(g_hPlayerData, sUserIdKey, aArray, iNumItems);

	if (bResult) {
		aValue = aArray[iIndex];
	} else {
		bResult = GetTrieValue(g_hPlayerData, sUserIdKey, aValue);
	}

	return bResult;
}

stock bool:Player_CGetArrayValue(iClient, const String:sKey[], iIndex, &any:aValue, const iNumItems) {
	return CheckClientForUserId(iClient) && Player_UGetArrayValue(GetClientUserId(iClient), sKey, iIndex, aValue, iNumItems);
}
*/