#pragma semicolon 1

#include <sourcemod>

stock RegisterCommands() {
	// Commands for testing purposes
	RegAdminCmd("sm_gm", Command_GiveMetal, ADMFLAG_ROOT);
}

public Action:Command_GiveMetal(iClient, iArgs) {
	new String:sTarget[MAX_NAME_LENGTH], String:sMetal[16];
	
	if (iArgs != 2) {
		PrintToChat(iClient, "Usage: !gm <player|@me|@all> <metal>");
		
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sMetal, sizeof(sMetal));

	if (StrEqual(sTarget, "@me")) {
		AddClientMetal(iClient, StringToInt(sMetal));
	} else if (StrEqual(sTarget, "@all")) {
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				AddClientMetal(i, StringToInt(sMetal));
			}
		}
	} else {
		if (IsValidClient(GetClientByName(iClient, sTarget)) && IsClientInGame(GetClientByName(iClient, sTarget))) {
			new iTarget = GetClientByName(iClient, sTarget);

			AddClientMetal(iTarget, StringToInt(sMetal));
		}
	}

	return Plugin_Handled;
}