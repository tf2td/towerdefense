#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "info/constants.sp"
	#include "info/enums.sp"
	#include "info/variables.sp"
#endif

public Action Timer_Hints(Handle hTimer) {
	int iRandom = GetRandomInt(1, 6);
	if(iRandom  == 1)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "hintBuildInfo");
	else if(iRandom  == 2)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "hintDropMetal");
	else if(iRandom  == 3)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "hintMetalStatus");
	else if(iRandom  == 4)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "hintMetalTransfer");
	else if(iRandom  == 5)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "hintCheckWave");
	else if(iRandom  == 6)
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "hintDeath");
	return Plugin_Continue;
}

public Action Timer_Reset(Handle hTimer) {
	SetPassword("", true, true);
	return Plugin_Continue;
}

public Action RespawnPlayer(Handle hTimer, any iClient) {
	if (IsValidClient(iClient)) {
		TF2_RespawnPlayer(iClient);
	}
	return Plugin_Continue;
}

public Action Timer_EnableUnlockButton(Handle hTimer) {
	g_bCanGetUnlocks = true;
	return Plugin_Continue;
}