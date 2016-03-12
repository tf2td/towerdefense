#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Initializes the server.
 *
 * @noreturn
 */

stock void Server_Initialize() {
	Log(TDLogLevel_Debug, "Initializing server");

	StripConVarFlag("sv_cheats", FCVAR_NOTIFY);
	StripConVarFlag("sv_tags", FCVAR_NOTIFY);
	StripConVarFlag("tf_bot_count", FCVAR_NOTIFY);
	StripConVarFlag("sv_password", FCVAR_NOTIFY);

	HookButtons();
	Server_Reset();

	int iServerIp[4];
	Steam_GetPublicIP(iServerIp);
	Format(g_sServerIp, sizeof(g_sServerIp), "%d.%d.%d.%d", iServerIp[0], iServerIp[1], iServerIp[2], iServerIp[3]);

	char sServerPort[6];
	GetConVarString(FindConVar("hostport"), sServerPort, sizeof(sServerPort));
	g_iServerPort = StringToInt(sServerPort);

	if (StrEqual(g_sServerIp, "0.0.0.0")) {
		Log(TDLogLevel_Info, "Server has been restarted completely, reloading map for initializing");
		ReloadMap();
	} else {
		Database_CheckServer(); // Calls Database_OnServerChecked() when finished
	}
}

stock void Database_OnServerChecked() {
	Log(TDLogLevel_Trace, "Database_OnServerChecked");

	Database_LoadData(); // Calls Database_OnDataLoaded() when finished
}

stock void Database_OnDataLoaded() {
	Log(TDLogLevel_Debug, "Successfully initialized server");

	PrintToHudAll("WELCOME TO TF2 TOWER DEFENSE");

	g_bServerInitialized = true;
}

/**
 * Resets the server.
 *
 * @noreturn
 */

stock void Server_Reset() {
	g_bEnabled = GetConVarBool(g_hEnabled) && g_bTowerDefenseMap && g_bSteamTools && g_bTF2Attributes;
	g_bMapRunning = true;

	UpdateGameDescription();

	if (!g_bEnabled) {
		if (!g_bTowerDefenseMap) {
			char sCurrentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

			Log(TDLogLevel_Info, "Map \"%s\" is not supported, thus Tower Defense has been disabled.", sCurrentMap);
		} else {
			Log(TDLogLevel_Info, "Tower Defense is disabled.");
		}

		return;
	}

	g_iBuildingLimit[TDBuilding_Sentry] = 1;
	g_iBuildingLimit[TDBuilding_Dispenser] = 0;
	g_iBuildingLimit[TDBuilding_TeleporterEntry] = 1;
	g_iBuildingLimit[TDBuilding_TeleporterExit] = 1;

	//Reset Hint Timer
	if (hHintTimer != null) {
		CloseHandle(hHintTimer);
		hHintTimer = null;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		//Reset carry Towers/Sentry
		if (IsTower(g_iAttachedTower[iClient])) {
			PrintToChatAll("Yes");
			TF2Attrib_RemoveByName(iClient, "cannot pick up buildings");
			g_iLastMover[g_iAttachedTower[iClient]] = 0;
			g_bCarryingObject[iClient] = false;
			g_iAttachedTower[iClient] = 0;
		}
		//Reset bought Towers
		if(IsTower(iClient)) {
			TDTowerId iTowerId = GetTowerId(iClient);
			g_bTowerBought[view_as<int>(iTowerId)] = false;
		}
		if(IsAttacker(iClient) && g_iSlowAttacker[iClient]) {
			g_iSlowAttacker[iClient] = false;
		}
		if(IsDefender(iClient)) {
			g_bCarryingObject[iClient] = false;
			//Remove Beam if there is one
			if (g_iHealBeamIndex[iClient][0] != 0) {
				if(IsValidEdict(g_iHealBeamIndex[iClient][0])) {
					RemoveEdict(g_iHealBeamIndex[iClient][0]);
					g_iHealBeamIndex[iClient][0] = 0;
				}
			}

			if (g_iHealBeamIndex[iClient][1] != 0) {
				if(IsValidEdict(g_iHealBeamIndex[iClient][1])) {
					RemoveEdict(g_iHealBeamIndex[iClient][1]);
					g_iHealBeamIndex[iClient][1] = 0;
				}
			}
		}
	}

	//Reset Multipliers
	for (int i = 1; i <= iMaxMultiplierTypes; i++) {
		fMultiplier[i] = 0.0;
	}
	g_iTime = GetTime();
	g_iMetalPackCount = 0;

	g_bTowersLocked = false;
	g_bAoEEngineerAttack = false;

	g_bStartWaveEarly = false;
	g_iBotsToSpawn = 0;
	g_iTotalBotsLeft = 0;

	g_iCurrentWave = 0;
	g_iNextWaveType = 0;

	iAoEEngineerTimer = 0;
	iAoEKritzMedicTimer = 0;

	g_iHealthBar = GetHealthBar();

	g_bLockable = true;
	g_bCanGetUnlocks = true;

	//Reset AoE Timer
	if (hAoETimer != null) {
		CloseHandle(hAoETimer);
		hAoETimer = null;
	}

	Format(g_sPassword, sizeof(g_sPassword), "");

	SetPassword(g_sPassword, false); //Change upon release
}

/**
 * Called when a servers data was set.
 *
 * @param iServerId		The server id (unique for every server).
 * @param sKey				The set key.
 * @param iDataType			The datatype of the set data.
 * @param iValue			The value if the set data is an integer, -1 otherwise.
 * @param bValue			The value if the set data is a boolean, false otherwise.
 * @param fValue			The value if the set data is a float, -1.0 otherwise.
 * @param sValue			The value if the set data is a string, empty string ("") otherwise.
 * @noreturn
 */

stock void Server_OnDataSet(int iServerId, const char[] sKey, TDDataType iDataType, int iValue, int bValue, float fValue, const char[] sValue) {
	switch (iDataType) {
		case TDDataType_Integer: {
			Log(TDLogLevel_Trace, "Server_OnDataSet: iServerId=%d, sKey=%s, iDataType=TDDataType_Integer, iValue=%d", iServerId, sKey, iValue);
		}

		case TDDataType_Boolean: {
			Log(TDLogLevel_Trace, "Server_OnDataSet: iServerId=%d, sKey=%s, iDataType=TDDataType_Boolean, bValue=%s", iServerId, sKey, (bValue ? "true" : "false"));
		}

		case TDDataType_Float: {
			Log(TDLogLevel_Trace, "Server_OnDataSet: iServerId=%d, sKey=%s, iDataType=TDDataType_Float, fValue=%f", iServerId, sKey, fValue);
		}

		case TDDataType_String: {
			Log(TDLogLevel_Trace, "Server_OnDataSet: iServerId=%d, sKey=%s, iDataType=TDDataType_String, sValue=%s", iServerId, sKey, sValue);
		}
	}
}

stock void Server_UAddValue(int iServerId, const char[] sKey, int iValue) {
	char sServerIdKey[128];
	int iOldValue;
	Server_UGetValue(iServerId, sKey, iOldValue);
	if(iOldValue != -1)
		iValue = iValue + iOldValue;

	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Server_OnDataSet(iServerId, sKey, TDDataType_Integer, iValue, false, -1.0, "");

	SetTrieValue(g_hServerData, sServerIdKey, iValue);
}

stock void Server_USetValue(int iServerId, const char[] sKey, int iValue) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Server_OnDataSet(iServerId, sKey, TDDataType_Integer, iValue, false, -1.0, "");

	SetTrieValue(g_hServerData, sServerIdKey, iValue);
}

stock bool Server_UGetValue(int iServerId, const char[] sKey, int &iValue) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Log(TDLogLevel_Trace, "Server_UGetValue: iServerId=%d, sKey=%s", iServerId, sKey);

	if (!GetTrieValue(g_hServerData, sServerIdKey, iValue)) {
		iValue = -1;
		return false;
	}

	return true;
}

stock void Server_USetBool(int iServerId, const char[] sKey, bool bValue) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Server_OnDataSet(iServerId, sKey, TDDataType_Integer, -1, bValue, -1.0, "");

	SetTrieValue(g_hServerData, sServerIdKey, (bValue ? 1 : 0));
}

stock bool Server_UGetBool(int iServerId, const char[] sKey) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Log(TDLogLevel_Trace, "Server_UGetBool: iServerId=%d, sKey=%s", iServerId, sKey);

	int iValue = 0;
	GetTrieValue(g_hServerData, sServerIdKey, iValue);

	return (iValue != 0);
}

stock void Server_USetFloat(int iServerId, const char[] sKey, float fValue) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	char sValue[64];
	FloatToString(fValue, sValue, sizeof(sValue))

	Server_OnDataSet(iServerId, sKey, TDDataType_Integer, -1, false, fValue, "");

	SetTrieString(g_hServerData, sServerIdKey, sValue);
}

stock bool Server_UGetFloat(int iServerId, const char[] sKey, float &fValue) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Log(TDLogLevel_Trace, "Server_UGetFloat: iServerId=%d, sKey=%s", iServerId, sKey);

	char sValue[64];
	if (!GetTrieString(g_hServerData, sServerIdKey, sValue, sizeof(sValue))) {
		fValue = -1.0;
		return false;
	}

	fValue = StringToFloat(sValue);
	return true;
}

stock bool Server_USetString(int iServerId, const char[] sKey, const char[] sValue, any...) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	char sFormattedValue[256];
	VFormat(sFormattedValue, sizeof(sFormattedValue), sValue, 4);

	Server_OnDataSet(iServerId, sKey, TDDataType_String, -1, false, -1.0, sValue);

	SetTrieString(g_hServerData, sServerIdKey, sFormattedValue);
}

stock bool Server_UGetString(int iServerId, const char[] sKey, char[] sValue, int iMaxLength) {
	char sServerIdKey[128];
	Format(sServerIdKey, sizeof(sServerIdKey), "%d_%s", iServerId, sKey);

	Log(TDLogLevel_Trace, "Server_UGetString: iServerId=%d, sKey=%s, iMaxLength=%d", iServerId, sKey, iMaxLength);

	if (!GetTrieString(g_hServerData, sServerIdKey, sValue, iMaxLength)) {
		Format(sValue, iMaxLength, "");
		return false;
	}

	return true;
}
