#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "info/constants.sp"
	#include "info/enums.sp"
	#include "info/variables.sp"
#endif

public Action Timer_Hints(Handle hTimer) {
	
	int iRandom = GetRandomInt(1, 3);
	if(iRandom  == 1)
	PrintToChatAll("\x04[\x03TD\x04]\x03 You build sentries via your PDA or with the command \x04/s");
	else if(iRandom  == 2)
	PrintToChatAll("\x04[\x03TD\x04]\x04 /d <amount> \x03to drop metal for other players.");
	else if(iRandom  == 3)
	PrintToChatAll("\x04[\x03TD\x04]\x03 Check everyones metal status with \x04/m ");
	
	
}