#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

stock void LoadConVars() {
	CreateConVar("towerdefense_version", PLUGIN_VERSION, "Tower Defense Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_hEnabled = CreateConVar("td_enabled", "1", "Enables/disables Tower Defense", FCVAR_DONTRECORD);
	
	HookConVarChange(g_hEnabled, OnConVarChanged);
}

stock void SetConVars() {
	
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

public void OnConVarChanged(Handle hConVar, const char[] sOldValue, const char[] sNewValue) {
	if (hConVar == g_hEnabled) {
		if (!g_bMapRunning) {
			return;
		}
		
		if (GetConVarBool(g_hEnabled)) {
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
	}
} 