#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Initializes hud indicators
 *
 * @noreturn
 */

stock void InitializeHud() {
	g_hMetalHud = CreateHudSynchronizer();
	g_hWaveStartHud = CreateHudSynchronizer();
	g_hWaveCountdownHud = CreateHudSynchronizer();
}

/**
 * Displays metal hud to all defenders.
 *
 * @noreturn
 */
stock void UpdateMetalHud() {
	if (g_hMetalHud == null) {
		Log(TDLogLevel_Error, "Failed to update hud metal indicator");
		return;
	}
	
	SetHudTextParams(0.8, 0.8, 999999.0, 255, 255, 255, 255);
	
	for (int i = 1; i < MaxClients; i++) {
		if (IsDefender(i)) {
			ShowSyncHudText(i, g_hMetalHud, "Team Metal: %d", g_iSharedMetal);
		}
	}
}

/**
 * Hides metal hud to all defenders.
 *
 * @noreturn
 */
stock void HideMetalHud() {
	if (g_hMetalHud == null) {
		Log(TDLogLevel_Error, "Failed to update hud metal indicator");
		return;
	}
	
	for (int i = 1; i < MaxClients; i++) {
		if (IsDefender(i)) {
			ClearSyncHud(i, g_hMetalHud);
		}
	}
}

/**
 * Adds a metal value to g_iSharedMetal and updates the hud
 *
 * @param iMetal			The metal amount to subtract.
 * @noreturn
 */
stock void AddGlobalMetal(int iMetal)
{
	g_iSharedMetal += iMetal;
	UpdateMetalHud();
}

/**
 * Destroys the metal hud element.
 *
 * @param iWave				The panels wave.
 * @return					True on success, false otherwise.
 */

stock void DestroyHud() {
	
	if (g_hMetalHud != null) {
		delete g_hMetalHud;
		g_hMetalHud = null;
	}
	if (g_hWaveStartHud != null) {
		delete g_hWaveStartHud;
		g_hWaveStartHud = null;
	}
	if (g_hWaveCountdownHud != null) {
		delete g_hWaveCountdownHud;
		g_hWaveCountdownHud = null;
	}
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