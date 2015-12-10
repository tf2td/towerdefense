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
		PrintToChatAll("\x04[\x03TD\x04]\x03 You can build sentries via your PDA or with the command \x04/s");
	else if(iRandom  == 2)
		PrintToChatAll("\x04[\x03TD\x04]\x04 /d <amount> \x03to drop metal for other players.");
	else if(iRandom  == 3)
		PrintToChatAll("\x04[\x03TD\x04]\x03 Check everyone's metal status with \x04/m ");
	else if(iRandom  == 4)
		PrintToChatAll("\x04[\x03TD\x04]\x03 Transfer metal between your comrades \x04/t <target> <amount> ");
	else if(iRandom  == 5)
		PrintToChatAll("\x04[\x03TD\x04]\x03 Check on what wave you're on with \x04/w ");
	else if(iRandom  == 6)
		PrintToChatAll("\x04[\x03TD\x04]\x03 Dying will make you lose half your metal! ");
}
public Action Timer_Reset(Handle hTimer) {
	SetPassword("", true, true);
}

public Action RespawnPlayer(Handle hTimer, any iClient) {
	if(IsValidClient(iClient))
		TF2_RespawnPlayer(iClient);
}

public Action Timer_EnableUnlockButton(Handle hTimer) {
	g_bCanGetUnlocks = true;
}