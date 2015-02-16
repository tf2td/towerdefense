#pragma semicolon 1

#include <sourcemod>

/**
 * Initializes the server.
 *
 * @noreturn
 */

stock InitializeServer() {
	Log(TDLogLevel_Debug, "Initializing server");

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
	SetConVars();

	g_bDatabase = Database_Connect();

	if (g_bDatabase) {
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
			Database_CheckServer();
		}

		Log(TDLogLevel_Debug, "Initializing connected clients");

		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsDefender(iClient)) {
				InitializeClient(iClient);
			}
		}
	}

	g_bServerInitialized = true;
}

/**
 * Resets the server.
 *
 * @noreturn
 */

stock ResetServer() {
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