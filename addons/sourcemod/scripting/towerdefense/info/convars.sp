#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

stock void CreateConVars() {
	CreateConVar("td_version", PLUGIN_VERSION, "Tower Defense Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("td_enabled", "1", "Enables/disables Tower Defense", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_hMaxBotsOnField = CreateConVar("td_max_bots_on_field", "8", "Max bots simultaneously on field. Might be actually lower than set due to maxplayer limit");
}

stock void LoadConVars() {
	g_hEnabled.AddChangeHook(OnConVarChanged);
	g_hTfBotQuota = FindConVar("tf_bot_quota");
	g_hTfBotQuota.AddChangeHook(OnConVarChanged);
}

stock void SetConVars() {
	g_hTfBotQuota.IntValue = 0;
}

stock void SetPregameConVars() {
	FindConVar("sv_cheats").SetInt(1, true, false);
}

/**
 * Called when a console variable's value is changed.
 *
 * @param hConVar		Handle to the convar that was changed.
 * @param sOldValue		String containing the value of the convar before it was changed.
 * @param sNewValue		String containing the new value of the convar.
 * @noreturn
 */

public void OnConVarChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue) {
	if (hConVar == g_hEnabled) {
		if (!g_bMapRunning) {
			return;
		}
		
		if (g_hEnabled.BoolValue) {
			if (!g_bEnabled) {
				bool bEnabled = IsTowerDefenseMap();

				if (bEnabled) {
					// Basically do the same as in OnConfigsExecuted().

					g_bEnabled = true;
					UpdateGameDescription();
				}
			}
		} else {
			if (g_bEnabled) {
				// Basically do the same as in OnMapEnd().

				g_bEnabled = false;
				UpdateGameDescription();
			}
		}
	} else if (hConVar == g_hTfBotQuota) {
		if (StringToInt(sNewValue) > 0) {
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "ConVar 'tf_bot_quota' can't be above 0 - Current Value: %d - New Value: %d", StringToInt(sOldValue), StringToInt(sNewValue));
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Setting ConVar 'tf_bot_quota' to default");
			ResetConVar(g_hTfBotQuota, true, false);
		}
	}
}