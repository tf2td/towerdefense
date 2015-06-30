#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "info/constants.sp"
	#include "info/enums.sp"
	#include "info/variables.sp"
#endif

public Action Timer_Hints(Handle hTimer) {
	
	if(iHint == 1)
	PrintToChatAll("\x04[\x03TD\x04]\x03 You build sentries via your PDA or with the command \x02/s");
	else if(iHint == 2)
	PrintToChatAll("\x04[\x03TD\x04]\x02 /d <amount> \x03to drop metal for other players.");
	else if(iHint == 3)
	PrintToChatAll("\x04[\x03TD\x04]\x03 Check everyones metal status with \x02/m ");
	else
		iHint = 0;
		
	iHint++;
	
	
}