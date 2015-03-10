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

stock Server_Initialize() {
	Log(TDLogLevel_Debug, "Initializing server");

	decl String:sError[512];
	if (Database_Connect(sError, sizeof(sError)) == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Failed to connect to the database: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Successfully connected to the database");

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

		SetPassword(SERVER_PASS, false);

		new iServerIp[4];
		Steam_GetPublicIP(iServerIp);
		Format(g_sServerIp, sizeof(g_sServerIp), "%d.%d.%d.%d", iServerIp[0], iServerIp[1], iServerIp[2], iServerIp[3]);

		decl String:sServerPort[6];
		GetConVarString(FindConVar("hostport"), sServerPort, sizeof(sServerPort));
		g_iServerPort = StringToInt(sServerPort);

		if (StrEqual(g_sServerIp, "0.0.0.0")) {
			Log(TDLogLevel_Info, "Server has been restarted completely, reloading map for initializing");
			ReloadMap();
		} else {
			Database_CheckServer(); // Calls Database_OnServerChecked() when finished
		}
	}
}

stock Database_OnServerChecked() {
	Log(TDLogLevel_Trace, "Database_OnServerChecked");

	Database_LoadData(); // Calls Database_OnDataLoaded() when finished
}

stock Database_OnDataLoaded() {
	Log(TDLogLevel_Debug, "Successfully initialized server");

	PrintToHudAll("WELCOME TO TF2 TOWER DEFENSE");

	g_bServerInitialized = true;
}

/**
 * Resets the server.
 *
 * @noreturn
 */

stock Server_Reset() {
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

	g_iBuildingLimit[TDBuilding_Sentry] = 1;
	g_iBuildingLimit[TDBuilding_Dispenser] = 0;
	g_iBuildingLimit[TDBuilding_TeleporterEntry] = 1;
	g_iBuildingLimit[TDBuilding_TeleporterExit] = 1;

	g_iMetalPackCount = 0;

	g_bStartWaveEarly = false;

	g_iCurrentWave = 0;

	new iHealthBar = EntRefToEntIndex(g_iHealthBar);
	if (IsValidEntity(iHealthBar)) {
		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
	}

	SetPassword(SERVER_PASS, false);
}