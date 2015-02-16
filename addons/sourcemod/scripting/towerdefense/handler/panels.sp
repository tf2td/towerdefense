#pragma semicolon 1

#include <sourcemod>

/**
 * Removes a panel.
 *
 * @param iWave				The panels wave.
 * @return					True on success, false otherwise.
 */

stock bool:Panel_Remove(iWave) {
	new iEntity = -1, bool:bResult = false;
	decl String:sName[64], String:sPanelName[64], String:sPanelTextName[64];

	Format(sPanelName, sizeof(sPanelName), "wavePanel%d", iWave); // TODO: Rename to panel_%d
	Format(sPanelTextName, sizeof(sPanelTextName), "wavePanelText%d", iWave); // TODO: Rename to panel_text_%d

	while ((iEntity = FindEntityByClassname(iEntity, "func_movelinear")) != -1) {
		GetEntPropString(iEntity, Prop_Data, "m_iName", sName, sizeof(sName));
		
		if (StrEqual(sName, sPanelName) || StrEqual(sName, sPanelTextName)) {
			AcceptEntityInput(iEntity, "Kill");
			bResult = true;
		}
	}

	return bResult;
}