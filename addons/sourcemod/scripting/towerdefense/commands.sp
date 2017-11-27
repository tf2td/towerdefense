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
	RegAdminCmd("sm_sw", Command_SetWave, ADMFLAG_ROOT);
	RegAdminCmd("sm_bt", Command_BuyTower, ADMFLAG_ROOT);
	
	// Temporary commands
	RegAdminCmd("sm_pregame", Command_PreGame, ADMFLAG_ROOT);
	RegAdminCmd("sm_password", Command_Password, ADMFLAG_ROOT);
	
	// Client Commands
	RegConsoleCmd("sm_p", Command_GetPassword);
	RegConsoleCmd("sm_s", Command_BuildSentry);
	RegConsoleCmd("sm_sentry", Command_BuildSentry);
	RegConsoleCmd("sm_d", Command_DropMetal);
	RegConsoleCmd("sm_drop", Command_DropMetal);
	RegConsoleCmd("sm_m", Command_ShowMetal);
	RegConsoleCmd("sm_metal", Command_ShowMetal);
	RegConsoleCmd("sm_w", Command_ShowWave);
	RegConsoleCmd("sm_wave", Command_ShowWave);
	RegConsoleCmd("sm_t", Command_TransferMetal);
	RegConsoleCmd("sm_transfer", Command_TransferMetal);
	RegConsoleCmd("sm_givemetal", Command_TransferMetal);
	
	// Command Listeners
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_ClosedMotd, "closed_htmlpage");
	AddCommandListener(CommandListener_Exec, "exec");
}

/*=====================================
=            Test Commands            =
=====================================*/

public Action Command_GiveMetal(int iClient, any iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	char sMetal[16], arg[65], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if (iArgs < 1) {
		ReplyToCommand(iClient, "[SM] Usage: sm_gm <#userid|name> <metal>");
		return Plugin_Handled;
	}
	else if (iArgs == 1) {
		GetCmdArg(1, sMetal, sizeof(sMetal));
		AddClientMetal(iClient, StringToInt(sMetal));
	}
	else if (iArgs >= 2) {
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, sMetal, sizeof(sMetal));
		
		if ((target_count = ProcessTargetString(
					arg, 
					iClient, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_CONNECTED, 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) {
			ReplyToCommand(iClient, "[SM] Player not found");
			return Plugin_Handled;
		}
		
		for (int i = 0; i < target_count; i++) {
			AddClientMetal(target_list[i], StringToInt(sMetal));
		}
	}
	
	return Plugin_Handled;
}

public Action Command_ReloadMap(int iClient, int iArgs) {
	ReloadMap();
	
	return Plugin_Handled;
}

public Action Command_SetWave(int iClient, int iArgs) {
	if (iArgs != 1) {
		PrintToChat(iClient, "Usage: !sw <wave>");
		return Plugin_Handled;
	}

	char sWave[6];
	GetCmdArg(1, sWave, sizeof(sWave));
	if(StringToInt(sWave) - 1 >= iMaxWaves)
		PrintToChat(iClient, "[SM] The highest wave is %i. Please choose a lower value than that!", iMaxWaves);
	else {
	g_iCurrentWave = StringToInt(sWave) - 1;
	PrintToChat(iClient, "[SM] Wave set to %i.", g_iCurrentWave + 1);
	}

	return Plugin_Handled;
}

public Action Command_BuyTower(int iClient, int iArgs) {
	if (iArgs != 1) {
		return Plugin_Handled;
	}
	
	char sTower[6];
	GetCmdArg(1, sTower, sizeof(sTower));
	TDTowerId iTowerId = view_as<TDTowerId>(StringToInt(sTower));
	
	if (!g_bTowerBought[view_as<int>(iTowerId)]) {
		char sName[MAX_NAME_LENGTH];
		Tower_GetName(iTowerId, sName, sizeof(sName));
		
		Tower_Spawn(iTowerId);
			
		PrintToChatAll("\x01%N bought \x04%s", iClient, sName);
			
		g_bTowerBought[view_as<int>(iTowerId)] = true;
	}
	
	return Plugin_Handled;
}


/*===================================
=            Start Round            =
===================================*/

public Action Command_PreGame(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	SetPregameConVars();
	
	SpawnMetalPacks(TDMetalPack_Start);
	
	PrintToChatAll("\x04Have fun playing!");
	PrintToChatAll("\x04Don't forget to pick up dropped metal packs!");
	
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
		
		for (int i = 0; i < 4; i++) {
			switch (GetRandomInt(0, 2)) {
				case 0: {
					g_sPassword[i] = GetRandomInt('1', '9');
				}
				
				case 1, 2: {
					g_sPassword[i] = GetRandomInt('a', 'z');
				}
			}
		}
		
		g_sPassword[4] = '\0';
		
		PrintToChatAll("\x01Set the server password to \x04%s", g_sPassword);
		PrintToChatAll("\x01If you want your friends to join, tell them the password.");
		PrintToChatAll("\x01Write \x04!p\x01 to see the password again.");
		
		SetPassword(g_sPassword);
	} else {
		PrintToChatAll("This server can't be locked!");
	}
	
	return Plugin_Handled;
}

/*=======================================
=            Client Commands            =
=======================================*/

public Action Command_GetPassword(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	if(!StrEqual(g_sPassword, ""))
		PrintToChatAll("\x01The server password is \x04%s", g_sPassword);
	else
		Forbid(iClient, true, "There is no password set!");
		
	return Plugin_Continue;
}


public Action Command_BuildSentry(int iClient, int iArgs) {
	if (!CanClientBuild(iClient, TDBuilding_Sentry)) {
		return Plugin_Handled;
	}
	
	if (IsInsideClient(iClient)) {
		Forbid(iClient, true, "You can not build while standing inside a other player!");
		return Plugin_Handled;
	}
	
	int iSentry = CreateEntityByName("obj_sentrygun");
	
	if (DispatchSpawn(iSentry) && IsValidEntity(iSentry)) {
		Player_CAddValue(iClient, PLAYER_OBJECTS_BUILT, 1);
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
		Forbid(iClient, true, "Invalid input");
		return Plugin_Handled;
	} else {
		iMetal = StringToInt(sMetal);
	}
	
	if (iMetal <= 0) {
		Forbid(iClient, true, "You must drop at least 1 metal");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(iClient)) {
		Forbid(iClient, true, "Cannot drop metal while dead");
		return Plugin_Handled;
	}
	
	if (!(GetEntityFlags(iClient) & FL_ONGROUND)) {
		Forbid(iClient, true, "Cannot drop metal while in the air");
		return Plugin_Handled;
	}
	
	if (iMetal > GetClientMetal(iClient)) {
		iMetal = GetClientMetal(iClient);
	}
	
	float fLocation[3], fAngles[3];
	
	GetClientEyePosition(iClient, fLocation);
	GetClientEyeAngles(iClient, fAngles);
	
	fLocation[0] = fLocation[0] + 100 * Cosine(DegToRad(fAngles[1]));
	fLocation[1] = fLocation[1] + 100 * Sine(DegToRad(fAngles[1]));
	fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;
	
	switch (SpawnMetalPack(TDMetalPack_Medium, fLocation, iMetal)) {
		case TDMetalPack_InvalidMetal: {
			Forbid(iClient, true, "You must drop at least 1 metal");
		}
		case TDMetalPack_LimitReached: {
			Forbid(iClient, true, "Metalpack limit reached, pick some metalpacks up!");
		}
		case TDMetalPack_InvalidType: {
			Forbid(iClient, true, "Unable to drop metal");
		}
		case TDMetalPack_SpawnedPack: {
			AddClientMetal(iClient, -iMetal);
			Player_CAddValue(iClient, PLAYER_METAL_DROP, iMetal);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_ShowMetal(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	PrintToChatAll("\x04[\x03TD\x04]\x03 Metal stats:");
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsDefender(i)) {
			PrintToChatAll("\x04%N - %d metal", i, GetClientMetal(i));
		}
	}
	
	return Plugin_Handled;
}

public Action Command_ShowWave(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	PrintToChatAll("\x04[\x03TD\x04]\x03 Currently on Wave %i out of %i", g_iCurrentWave + 1, iMaxWaves);
	
	return Plugin_Handled;
}

public Action Command_TransferMetal(int iClient, int iArgs) {
	
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	
	if (iArgs != 2) {
		PrintToChat(iClient, "\x01Usage: !t <target> <amount>");
		
		return Plugin_Handled;
	}
	
	char sTarget[64];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	char sMetal[32];
	GetCmdArg(2, sMetal, sizeof(sMetal));
	
	int iMetal;
	int iTarget = GetClientByName(iClient, sTarget);
	
	if (!IsStringNumeric(sMetal)) {
		Forbid(iClient, true, "Invalid input");
		return Plugin_Handled;
	} else {
		iMetal = StringToInt(sMetal);
	}

	if (iMetal > GetClientMetal(iClient) || GetClientMetal(iClient) <= 0) {
		Forbid(iClient, true, "You can't transfer more metal then you have!");
		return Plugin_Handled;
	}

	if (iMetal < 0) {
		Forbid(iClient, true, "Can't transfer negative amounts!");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		Forbid(iClient, true, "Can't transfer while dead!");
		return Plugin_Handled;
	}

	if (IsDefender(iTarget) && IsPlayerAlive(iTarget)) {
		AddClientMetal(iTarget, iMetal);
		AddClientMetal(iClient, -iMetal);

		PrintToChat(iTarget, "\x04You received \x01%d metal \x04from \x01%N\x04.", iMetal, iClient);
		PrintToChat(iClient, "\x01%N \x04received \x01%d metal \x04from you.", iTarget, iMetal);
	}
	
	return Plugin_Continue;
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
		AddClientMetal(iClient, 1); // for resetting HUD
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