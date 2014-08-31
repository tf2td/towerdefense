#pragma semicolon 1

#include <sourcemod>

stock LoadConVars() {
	CreateConVar("towerdefense_version", PLUGIN_VERSION, "Tower Defense Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("td_enabled", "1", "Enables/disables Tower Defense", FCVAR_PLUGIN|FCVAR_DONTRECORD);

	HookConVarChange(g_hEnabled, OnConVarChanged);

	SetConVarInt(FindConVar("sv_cheats"), 1, true, false);
}

/**
 * Called when a console variable's value is changed.
 *
 * @param hConVar		Handle to the convar that was changed.
 * @param sOldValue		String containing the value of the convar before it was changed.
 * @param sNewValue		String containing the new value of the convar.
 * @noreturn
 */

public OnConVarChanged(Handle:hConVar, const String:sOldValue[], const String:sNewValue[]) {
	if (hConVar == g_hEnabled) {
		if (!g_bMapRunning) {
			return;
		}
		
		if (GetConVarBool(g_hEnabled)) {
			if (!g_bEnabled) {
				new bool:bEnabled = IsTowerDefenseMap();

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
	}
}