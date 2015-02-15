#pragma semicolon 1

#include <sourcemod>

/**
 * Initializes the server.
 *
 * @noreturn
 */

stock InitializeServer() {
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

	SetPassword(SERVER_PASS, false);
	SetConVars();

	Database_Connect();
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

	new iHealthBar = EntRefToEntIndex(g_iHealthBar);
	if (IsValidEntity(iHealthBar)) {
		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 0);
	}

	SetPassword(SERVER_PASS, false);
}