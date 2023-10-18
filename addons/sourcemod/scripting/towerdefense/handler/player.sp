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

stock void Player_ServerInitializing(int iUserId, int iClient) {
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

stock void Player_ServerInitialized(int iUserId, int iClient) {
	char sCommunityId[32];
	if (IsValidClient(iClient)) {
		Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sCommunityId, sizeof(sCommunityId));

		TF2_RemoveCondition(iClient, TFCond_RestrictToMelee);
		SetEntityMoveType(iClient, MOVETYPE_WALK);

		Player_SyncDatabase(iUserId, iClient, sCommunityId);

		Log(TDLogLevel_Debug, "Successfully initialized player %N (%s)", iClient, sCommunityId);
	}
}

/**
 * Syncs all initial things of a client with the database.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @param sCommunityId		The clients 64-bit steam id (community id).
 * @noreturn
 */

stock void Player_SyncDatabase(int iUserId, int iClient, const char[] sCommunityId) {
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

stock void Player_Connected(int iUserId, int iClient, const char[] sName, const char[] sSteamId, const char[] sCommunityId, const char[] sIp) {
	Log(TDLogLevel_Debug, "Player connected (UserId=%d, Client=%d, Name=%s, SteamId=%s, CommunityId=%s, Address=%s)", iUserId, iClient, sName, sSteamId, sCommunityId, sIp);

	if (!StrEqual(sSteamId, "BOT")) {
		if (GetRealClientCount() > g_iMaxClients) {
			KickClient(iClient, "Maximum number of players has been reached (%d/%d)", GetRealClientCount() - 1, g_iMaxClients);
			Log(TDLogLevel_Info, "Kicked player (%N, %s) (Maximum players reached: %d/%d)", iClient, sSteamId, GetRealClientCount() - 1, g_iMaxClients);
			return;
		}

		Log(TDLogLevel_Info, "Connected clients: %d/%d", GetRealClientCount(), g_iMaxClients);

		Player_USetString(iUserId, PLAYER_STEAM_ID, sSteamId);
		Player_USetString(iUserId, PLAYER_COMMUNITY_ID, sCommunityId);
		Player_USetString(iUserId, PLAYER_IP_ADDRESS, sIp);
		Server_UAddValue(g_iServerId, SERVER_CONNECTIONS, 1);

		g_bCarryingObject[iClient]						  = false;
		g_bReplaceWeapon[iClient][TFWeaponSlot_Primary]	  = false;
		g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = false;
		g_bReplaceWeapon[iClient][TFWeaponSlot_Melee]	  = false;

		g_iAttachedTower[iClient]						  = 0;

		ChangeClientTeam(iClient, TEAM_DEFENDER);
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);

		UpdateGameDescription();

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

stock void Player_OnDisconnectPre(int iUserId, int iClient) {
	Database_UpdatePlayerDisconnect(iUserId);
	int iTime = GetTime() - g_iTime;
	Player_CSetValue(iClient, PLAYER_PLAYTIME, iTime);
	Server_UAddValue(g_iServerId, SERVER_PLAYTIME, iTime);

	if (GetRealClientCount(true) <= 1) {	// the disconnected player is counted (thus 1 not 0)
		Database_ServerStatsUpdate();
		CreateTimer(10.0, Timer_Reset);	   // Give Queries time to send
	}
}

/**
 * Called once the client has entered the game (connected and loaded).
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @noreturn
 */

stock void Player_Loaded(int iUserId, int iClient) {
	char sCommunityId[32];
	Player_CGetString(iClient, PLAYER_COMMUNITY_ID, sCommunityId, sizeof(sCommunityId));

	Log(TDLogLevel_Debug, "Player loaded (UserId=%d, Client=%d, CommunityId=%s)", iUserId, iClient, sCommunityId);
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient) && g_bTowerDefenseMap) {
		CreateTimer(1.0, InitInfoTimer, iUserId, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action InitInfoTimer(Handle hTimer, any iUserId) {
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

stock void Player_OnSpawn(int iUserId, int iClient) {
	ResetClientMetal(iClient);
	SetEntProp(iClient, Prop_Data, "m_bloodColor", view_as<int>(TDBlood_None));

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

stock void Player_OnDeath(int iUserId, int iClient) {
	g_bCarryingObject[iClient]						  = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Primary]	  = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = false;
	g_bReplaceWeapon[iClient][TFWeaponSlot_Melee]	  = false;
	Player_CAddValue(iClient, PLAYER_DEATHS, 1);

	if (IsDefender(iClient) && g_iCurrentWave > 0) {
		int iMetal = GetClientMetal(iClient) / 2;

		if (iMetal > 0) {
			float fLocation[3];

			GetClientEyePosition(iClient, fLocation);
			fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;

			SpawnMetalPack(TDMetalPack_Medium, fLocation, iMetal);
		}
	}

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

stock void Player_OnDataSet(int iUserId, int iClient, const char[] sKey, TDDataType iDataType, int iValue, int bValue, float fValue, const char[] sValue) {
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

stock bool CheckClientForUserId(int iClient) {
	return (iClient > 0 && iClient <= MaxClients && IsClientConnected(iClient));
}

stock void Player_UAddValue(int iUserId, const char[] sKey, int iValue) {
	char sUserIdKey[128];
	int	 iOldValue;
	Player_UGetValue(iUserId, sKey, iOldValue);
	if (iOldValue != -1)
		iValue = iValue + iOldValue;

	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, iValue, false, -1.0, "");

	SetTrieValue(g_hPlayerData, sUserIdKey, iValue);
}

stock void Player_CAddValue(int iClient, const char[] sKey, int iValue) {
	if (CheckClientForUserId(iClient)) {
		Player_UAddValue(GetClientUserId(iClient), sKey, iValue);
	}
}

stock void Player_USetValue(int iUserId, const char[] sKey, int iValue) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, iValue, false, -1.0, "");

	SetTrieValue(g_hPlayerData, sUserIdKey, iValue);
}

stock void Player_CSetValue(int iClient, const char[] sKey, int iValue) {
	if (CheckClientForUserId(iClient)) {
		Player_USetValue(GetClientUserId(iClient), sKey, iValue);
	}
}

stock bool Player_UGetValue(int iUserId, const char[] sKey, int &iValue) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetValue: iUserId=%d, sKey=%s", iUserId, sKey);

	if (!GetTrieValue(g_hPlayerData, sUserIdKey, iValue)) {
		iValue = -1;
		return false;
	}

	return true;
}

stock bool Player_CGetValue(int iClient, const char[] sKey, int &iValue) {
	return CheckClientForUserId(iClient) && Player_UGetValue(GetClientUserId(iClient), sKey, iValue);
}

stock void Player_USetBool(int iUserId, const char[] sKey, bool bValue) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, -1, bValue, -1.0, "");

	SetTrieValue(g_hPlayerData, sUserIdKey, (bValue ? 1 : 0));
}

stock void Player_CSetBool(int iClient, const char[] sKey, bool bValue) {
	if (CheckClientForUserId(iClient)) {
		Player_USetBool(GetClientUserId(iClient), sKey, bValue);
	}
}

stock bool Player_UGetBool(int iUserId, const char[] sKey) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetBool: iUserId=%d, sKey=%s", iUserId, sKey);

	int iValue = 0;
	GetTrieValue(g_hPlayerData, sUserIdKey, iValue);

	return (iValue != 0);
}

stock bool Player_CGetBool(int iClient, const char[] sKey) {
	return CheckClientForUserId(iClient) && Player_UGetBool(GetClientUserId(iClient), sKey);
}

stock void Player_USetFloat(int iUserId, const char[] sKey, float fValue) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	char sValue[64];
	FloatToString(fValue, sValue, sizeof(sValue));

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_Integer, -1, false, fValue, "");

	SetTrieString(g_hPlayerData, sUserIdKey, sValue);
}

stock void Player_CSetFloat(int iClient, const char[] sKey, float fValue) {
	if (CheckClientForUserId(iClient)) {
		Player_USetFloat(GetClientUserId(iClient), sKey, fValue);
	}
}

stock bool Player_UGetFloat(int iUserId, const char[] sKey, float &fValue) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetFloat: iUserId=%d, sKey=%s", iUserId, sKey);

	char sValue[64];
	if (!GetTrieString(g_hPlayerData, sUserIdKey, sValue, sizeof(sValue))) {
		fValue = -1.0;
		return false;
	}

	fValue = StringToFloat(sValue);
	return true;
}

stock bool Player_CGetFloat(int iClient, const char[] sKey, float &fValue) {
	return CheckClientForUserId(iClient) && Player_UGetFloat(GetClientUserId(iClient), sKey, fValue);
}

stock void Player_USetString(int iUserId, const char[] sKey, const char[] sValue, any...) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	char sFormattedValue[256];
	VFormat(sFormattedValue, sizeof(sFormattedValue), sValue, 4);

	Player_OnDataSet(iUserId, GetClientOfUserId(iUserId), sKey, TDDataType_String, -1, false, -1.0, sValue);

	SetTrieString(g_hPlayerData, sUserIdKey, sFormattedValue);
}

stock void Player_CSetString(int iClient, const char[] sKey, const char[] sValue, any...) {
	if (CheckClientForUserId(iClient)) {
		char sFormattedValue[256];
		VFormat(sFormattedValue, sizeof(sFormattedValue), sValue, 4);

		Player_USetString(GetClientUserId(iClient), sKey, sFormattedValue);
	}
}

stock bool Player_UGetString(int iUserId, const char[] sKey, char[] sValue, int iMaxLength) {
	char sUserIdKey[128];
	Format(sUserIdKey, sizeof(sUserIdKey), "%d_%s", iUserId, sKey);

	Log(TDLogLevel_Trace, "Player_UGetString: iUserId=%d, sKey=%s, iMaxLength=%d", iUserId, sKey, iMaxLength);

	if (!GetTrieString(g_hPlayerData, sUserIdKey, sValue, iMaxLength)) {
		Format(sValue, iMaxLength, "");
		return false;
	}

	return true;
}

stock bool Player_CGetString(int iClient, const char[] sKey, char[] sValue, int iMaxLength) {
	return CheckClientForUserId(iClient) && Player_UGetString(GetClientUserId(iClient), sKey, sValue, iMaxLength);
}

stock void Player_AddHealth(int iClient, int iHealth, bool ignoreMax = false) {
	if (ignoreMax) {
		SetEntityHealth(iClient, GetClientHealth(iClient) + iHealth);
	} else {
		int iCurrentHealth = GetEntProp(iClient, Prop_Send, "m_iHealth");
		int iMaxHealth	   = GetEntData(iClient, FindDataMapInfo(iClient, "m_iMaxHealth"));
		if (iCurrentHealth < iMaxHealth) {
			SetEntityHealth(iClient, GetClientHealth(iClient) + iHealth);
		}
	}
}