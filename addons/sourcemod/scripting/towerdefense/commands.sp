#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "info/constants.sp"
	#include "info/enums.sp"
	#include "info/variables.sp"
#endif

stock void RegisterCommands() {
	// Commands for testing purposes
	RegAdminCmd("sm_gm", Command_GiveMetal, ADMFLAG_ROOT);
	RegAdminCmd("sm_r", Command_ReloadMap, ADMFLAG_ROOT);
	
	// Temporary commands
	RegAdminCmd("sm_pregame", Command_PreGame, ADMFLAG_ROOT);
	RegAdminCmd("sm_password", Command_Password, ADMFLAG_ROOT);
	
	// Client Commands
	RegConsoleCmd("sm_s", Command_BuildSentry);
	RegConsoleCmd("sm_sentry", Command_BuildSentry);
	RegConsoleCmd("sm_d", Command_DropMetal);
	RegConsoleCmd("sm_drop", Command_DropMetal);
	RegConsoleCmd("sm_m", Command_ShowMetal);
	RegConsoleCmd("sm_metal", Command_ShowMetal);
	
	// Command Listeners
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_ClosedMotd, "closed_htmlpage");
	AddCommandListener(CommandListener_Exec, "exec");
	AddCommandListener(CommandListener_Kill, "kill");
	AddCommandListener(CommandListener_Kill, "explode");
}

/*=====================================
=            Test Commands            =
=====================================*/

public Action Command_GiveMetal(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	char sTarget[MAX_NAME_LENGTH], sMetal[16];
	
	if (iArgs != 2) {
		PrintToChat(iClient, "Usage: !gm <player|@me|@all> <metal>");
		
		return Plugin_Handled;
	}
	
	GetCmdArg(1, sTarget, sizeof(sTarget));
	GetCmdArg(2, sMetal, sizeof(sMetal));
	
	if (StrEqual(sTarget, "@me")) {
		AddClientMetal(iClient, StringToInt(sMetal));
	} else if (StrEqual(sTarget, "@all")) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				AddClientMetal(i, StringToInt(sMetal));
			}
		}
	} else {
		if (IsValidClient(GetClientByName(iClient, sTarget)) && IsClientInGame(GetClientByName(iClient, sTarget))) {
			int iTarget = GetClientByName(iClient, sTarget);
			
			AddClientMetal(iTarget, StringToInt(sMetal));
		}
	}
	
	return Plugin_Handled;
}

public Action Command_ReloadMap(int iClient, int iArgs) {
	ReloadMap();
	
	return Plugin_Handled;
}

/*===================================
=            Start Round            =
===================================*/

public Action Command_PreGame(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	SpawnMetalPacks(TDMetalPack_Start);
	
	PrintToChatAll("\x04Have fun playing!");
	PrintToChatAll("\x04Don't forget to pick up dropped weapons!");
	
	// Hook func_nobuild events
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "func_nobuild")) != -1) {
		SDKHook(iEntity, SDKHook_StartTouch, OnNobuildEnter);
		SDKHook(iEntity, SDKHook_EndTouch, OnNobuildExit);
	}
	
	return Plugin_Handled;
}

public Action Command_Password(int iClient, int iArgs) {
	if (g_bLockable) {
		char sPassword[8];
		
		for (int i = 0; i < 4; i++) {
			switch (GetRandomInt(0, 2)) {
				case 0: {
					sPassword[i] = GetRandomInt('1', '9');
				}
				
				case 1, 2: {
					sPassword[i] = GetRandomInt('a', 'z');
				}
			}
		}
		
		sPassword[4] = '\0';
		
		PrintToChatAll("\x01Set the server password to \x04%s", sPassword);
		PrintToChatAll("\x01If you want your friends to join, tell them the password.");
		PrintToChatAll("\x01Write \x04!p\x01 to see the password again.");
		
		SetPassword(sPassword);
	} else {
		PrintToChatAll("This server can't be locked!");
	}
	
	return Plugin_Handled;
}

/*=======================================
=            Client Commands            =
=======================================*/

public Action Command_BuildSentry(int iClient, int iArgs) {
	if (!CanClientBuild(iClient, TDBuilding_Sentry)) {
		return Plugin_Handled;
	}
	
	if (IsInsideClient(iClient)) {
		Forbid(iClient, true, "You can not build while standing inside a other player!");
		return Plugin_Handled;
	}
	
	int iSentry = CreateEntityByName("obj_sentrygun");
	
	if (DispatchSpawn(iSentry)) {
		AcceptEntityInput(iSentry, "SetBuilder", iClient);
		
		SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", 150);
		SetEntProp(iSentry, Prop_Send, "m_iHealth", 150);
		
		DispatchKeyValue(iSentry, "angles", "0 0 0");
		DispatchKeyValue(iSentry, "defaultupgrade", "0");
		DispatchKeyValue(iSentry, "TeamNum", "3");
		DispatchKeyValue(iSentry, "spawnflags", "0");
		
		float fLocation[3], fAngles[3];
		
		GetClientAbsOrigin(iClient, fLocation);
		GetClientEyeAngles(iClient, fAngles);
		
		fLocation[2] += 30;
		
		fAngles[0] = 0.0;
		fAngles[2] = 0.0;
		
		TeleportEntity(iSentry, fLocation, fAngles, NULL_VECTOR);
		
		AddClientMetal(iClient, -130);
		
		g_bPickupSentry[iClient] = true;
		
		PrintToChat(iClient, "\x01Sentries need \x041000 metal\x01 to upgrade!");
	}
	
	return Plugin_Handled;
}

public Action Command_DropMetal(int iClient, int iArgs) {
	char sPassword[256];
	GetRconPassword(sPassword, sizeof(sPassword));
	
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	if (iArgs != 1) {
		PrintToChat(iClient, "\x01Usage: !d <amount>");
		
		return Plugin_Handled;
	}
	
	char sMetal[32];
	GetCmdArg(1, sMetal, sizeof(sMetal));
	
	int iMetal;
	
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
	
	float fLocation[3], fAngles[3];
	
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

public Action Command_ShowMetal(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	PrintToChatAll("\x01Metal stats:");
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsDefender(i)) {
			PrintToChatAll("\x04%N - %d metal", i, GetClientMetal(i));
		}
	}
	
	return Plugin_Handled;
}

/*=========================================
=            Command Listeners            =
=========================================*/

public Action CommandListener_Build(int iClient, const char[] sCommand, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	char sBuildingType[4];
	GetCmdArg(1, sBuildingType, sizeof(sBuildingType));
	TDBuildingType iBuildingType = view_as<TDBuildingType>(StringToInt(sBuildingType));
	
	switch (iBuildingType) {
		case TDBuilding_Sentry: {
			//PrintToChat(iClient, "\x01Use \x04!s \x01or \x04!sentry \x01to build a Sentry!");
			Command_BuildSentry(iClient, iArgs);
			
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

public Action CommandListener_ClosedMotd(int iClient, const char[] sCommand, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if (GetClientMetal(iClient) <= 0) {
		SetClientMetal(iClient, 1); // for resetting HUD
		ResetClientMetal(iClient);
	}
	
	return Plugin_Continue;
}

public Action CommandListener_Exec(int iClient, const char[] sCommand, int iArgs) {
	if (g_bConfigsExecuted && iClient == 0) {
		Database_UpdateServer();
	}
	
	return Plugin_Continue;
}

public Action CommandListener_Kill(int iClient, const char[] sCommand, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if (IsDefender(iClient)) {
		int iMetal = GetClientMetal(iClient);
		
		if (iMetal > 0) {
			float fLocation[3];
			
			GetClientEyePosition(iClient, fLocation);
			fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;
			
			SpawnMetalPack(TDMetalPack_Small, fLocation, iMetal);
		}
	}
	
	return Plugin_Continue;
} 