#pragma semicolon 1

#include <sourcemod>

stock RegisterCommands() {
	// Commands for testing purposes
	RegAdminCmd("sm_gm", Command_GiveMetal, ADMFLAG_ROOT);

	// Client Commands
	RegConsoleCmd("sm_d", Command_Drop);
	RegConsoleCmd("sm_drop", Command_Drop);
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

public Action:Command_Drop(iClient, iArgs) {
	decl String:sCommandName[32];
	GetCmdArg(0, sCommandName, sizeof(sCommandName));

	if (iArgs != 1) {
		PrintToChat(iClient, "\x04Usage: !%s <amount>", sCommandName);
		
		return Plugin_Handled;
	}
	
	decl String:sMetal[32];
	GetCmdArg(1, sMetal, sizeof(sMetal));

	new iMetal;

	if (!IsStringNumeric(sMetal)) {
		PrintToChat(iClient, "\x07FF0000Drop letters? Ahhh... nope.");
		return Plugin_Handled;
	} else {
		iMetal = StringToInt(sMetal);
	}

	if (iMetal <= 0) {
		PrintToChat(iClient, "\x07FF0000Drop at least 1 metal, ok?");
		return Plugin_Handled;
	}

	if (iMetal > GetClientMetal(iClient)) {
		PrintToChat(iClient, "\x07FF0000You can't drop more metal than you have!");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		PrintToChat(iClient, "\x07FF0000You're dead, you can't drop anything now!");
		return Plugin_Handled;
	}

	if (!(GetEntityFlags(iClient) & FL_ONGROUND)) {
		PrintToChat(iClient, "\x07FF0000Drop something in midair? Nope.");
		return Plugin_Handled;
	}

	new Float:fLocation[3], Float:fAngles[3];

	GetClientEyePosition(iClient, fLocation);
	GetClientEyeAngles(iClient, fAngles);
		
	fLocation[0] = fLocation[0] + 100 * Cosine(DegToRad(fAngles[1]));
	fLocation[1] = fLocation[1] + 100 * Sine(DegToRad(fAngles[1]));
	fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;

	switch (SpawnMetalPack(TDMetalPack_Small, fLocation, iMetal)) {
		case TDMetalPack_InvalidMetal: {
			PrintToChat(iClient, "\x07FF0000Drop at least 1 metal, ok?");
		}
		case TDMetalPack_LimitReached: {
			PrintToChat(iClient, "\x07FF0000Metalpack limit reached, pick some metalpacks up!");
		}
		case TDMetalPack_InvalidType: {
			PrintToChat(iClient, "\x07FF0000Couldn't drop metal.");
		}
		case TDMetalPack_SpawnedPack: {
			AddClientMetal(iClient, -iMetal);
		}
	}
	
	return Plugin_Handled;
}