#pragma semicolon 1

#include <sourcemod>

/**
 * Gets a clients current metal amount.
 *
 * @param iClient		The client.
 * @return				The clients current metal.
 */

stock GetClientMetal(iClient) {
	return GetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (3 * 4), 4);
}

/**
 * Sets a clients metal amount.
 *
 * @param iClient		The client.
 * @param iMetal		The metal amount the client should get.
 * @noreturn
 */

stock SetClientMetal(iClient, iMetal) {
	SetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (3 * 4), iMetal, 4);

	Log(TDLogLevel_Trace, "Set %N's metal to %d", iClient, iMetal);
}

/**
 * Resets a clients metal amount back to zero.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock ResetClientMetal(iClient) {
	CreateTimer(0.0, ResetClientMetalDelayed, iClient, TIMER_FLAG_NO_MAPCHANGE); // Process next frame
}

public Action:ResetClientMetalDelayed(Handle:hTimer, any:iClient) {
	SetClientMetal(iClient, 0);

	return Plugin_Stop;
}

/**
 * Add a amount to the clients metal amount.
 *
 * @param iClient		The client.
 * @param iMetal		The metal amount to add.
 * @return				True if amount could be added, false otherwise.
 */

stock bool:AddClientMetal(iClient, iMetal) {
	if (iMetal < 0) {
		if (GetClientMetal(iClient) + iMetal >= 0) {
			SetClientMetal(iClient, GetClientMetal(iClient) + iMetal);
			return true;
		} else {
			return false;
		}
	}
	
	SetClientMetal(iClient, GetClientMetal(iClient) + iMetal);
	return true;
}