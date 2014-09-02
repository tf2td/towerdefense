#pragma semicolon 1

#include <sourcemod>

stock RegisterCommands() {
	// Commands for testing purposes
	RegAdminCmd("sm_gm", Command_GiveMetal, ADMFLAG_ROOT);
	RegAdminCmd("sm_r", Command_ReloadMap, ADMFLAG_ROOT);

	// Start Round
	RegAdminCmd("sm_pregame", Command_PreGame, ADMFLAG_ROOT);

	// Client Commands
	RegConsoleCmd("sm_d", Command_Drop);
	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_m", Command_ShowMetal);
	RegConsoleCmd("sm_metal", Command_ShowMetal);

	// Command Listeners
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_ClosedMotd, "closed_htmlpage");
}

/*=====================================
=            Test Commands            =
=====================================*/

public Action:Command_GiveMetal(iClient, iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

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

public Action:Command_ReloadMap(iClient, iArgs) {
	ReloadMap();

	return Plugin_Handled;
}

/*===================================
=            Start Round            =
===================================*/

public Action:Command_PreGame(iClient, iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	PrintToChatAll("\x0704B404Have fun playing!");
	PrintToChatAll("\x0704B404Don't forget to pick up dropped weapons!");

	// Hook func_nobuild events
	new iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "func_nobuild")) != -1) {
		SDKHook(iEntity, SDKHook_StartTouch, OnNobuildEnter);
		SDKHook(iEntity, SDKHook_EndTouch, OnNobuildExit);
	}
	
	return Plugin_Handled;
}

/*=======================================
=            Client Commands            =
=======================================*/

public Action:Command_Drop(iClient, iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	if (iArgs != 1) {
		PrintToChat(iClient, "\x0704B404Usage: !d <amount>");
		
		return Plugin_Handled;
	}
	
	decl String:sMetal[32];
	GetCmdArg(1, sMetal, sizeof(sMetal));

	new iMetal;

	if (!IsStringNumeric(sMetal)) {
		Forbid(iClient, true, "Drop letters? Ahhh... nope.");
		return Plugin_Handled;
	} else {
		iMetal = StringToInt(sMetal);
	}

	if (iMetal <= 0) {
		Forbid(iClient, true, "Drop at least 1 metal, ok?");
		return Plugin_Handled;
	}

	if (iMetal > GetClientMetal(iClient)) {
		Forbid(iClient, true, "You can't drop more metal than you have!");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		Forbid(iClient, true, "You're dead, you can't drop anything now!");
		return Plugin_Handled;
	}

	if (!(GetEntityFlags(iClient) & FL_ONGROUND)) {
		Forbid(iClient, true, "Drop something in midair? Nope.");
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
			Forbid(iClient, true, "Drop at least 1 metal, ok?");
		}
		case TDMetalPack_LimitReached: {
			Forbid(iClient, true, "Metalpack limit reached, pick some metalpacks up!");
		}
		case TDMetalPack_InvalidType: {
			Forbid(iClient, true, "Couldn't drop metal.");
		}
		case TDMetalPack_SpawnedPack: {
			AddClientMetal(iClient, -iMetal);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_ShowMetal(iClient, iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	PrintToChatAll("\x0704B404Metal stats:");
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsDefender(i)) {
			PrintToChatAll("\x04%N - %d metal", i, GetClientMetal(i));
		}
	}
	
	return Plugin_Handled;
}

/*=========================================
=            Command Listeners            =
=========================================*/

public Action:CommandListener_Build(iClient, const String:sCommand[], iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	decl String:sBuildingType[4];
	GetCmdArg(1, sBuildingType, sizeof(sBuildingType));
	new TDBuildingType:iBuildingType = TDBuildingType:StringToInt(sBuildingType);

	switch (iBuildingType) {
		case TDBuilding_Sentry: {
			PrintToChat(iClient, "\x0704B404Use \x04!s \x0704B404or \x04!sentry \x0704B404to build a Sentry!");

			return Plugin_Handled;
		}
		case TDBuilding_Dispenser: {
			if (!CanClientBuild(iClient, TDBuilding_Dispenser)) {
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action:CommandListener_ClosedMotd(iClient, const String:sCommand[], iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	if (GetClientMetal(iClient) <= 0) {
		SetClientMetal(iClient, 1); // for resetting HUD
		ResetClientMetal(iClient);
	}

	return Plugin_Continue;
}