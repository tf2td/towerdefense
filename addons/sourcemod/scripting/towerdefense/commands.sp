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
	
	//Button Commands
	RegAdminCmd("sm_increase_enabled_sentries", Command_IncreaseSentry, ADMFLAG_ROOT);
	RegAdminCmd("sm_increase_enabled_dispensers", Command_IncreaseDispenser, ADMFLAG_ROOT);
	RegAdminCmd("sm_bonus_metal", Command_BonusMetal, ADMFLAG_ROOT);
	RegAdminCmd("sm_explosiondamage", Command_Multiplier, ADMFLAG_ROOT);
	RegAdminCmd("sm_firedamage", Command_Multiplier, ADMFLAG_ROOT);
	RegAdminCmd("sm_bulletdamage", Command_Multiplier, ADMFLAG_ROOT);
	RegAdminCmd("sm_sentrydamage", Command_Multiplier, ADMFLAG_ROOT);
	RegAdminCmd("sm_critchance", Command_Multiplier, ADMFLAG_ROOT);
	
	// Command Listeners
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_ClosedMotd, "closed_htmlpage");
	AddCommandListener(CommandListener_Exec, "exec");
	AddCommandListener(CommandListener_Kill, "kill");
	AddCommandListener(CommandListener_Kill, "explode");
	//Multipliers
	AddCommandListener(CommandListener_Multiplier, "sm_explosiondamage");
	AddCommandListener(CommandListener_Multiplier, "sm_firedamage");
	AddCommandListener(CommandListener_Multiplier, "sm_bulletdamage");
	AddCommandListener(CommandListener_Multiplier, "sm_sentrydamage");
	AddCommandListener(CommandListener_Multiplier, "sm_critchance");
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

/*=====================================
=            Button Commands          =
=====================================*/

public Action Command_IncreaseSentry(int iClient, any iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	g_iBuildingLimit[TDBuilding_Sentry] += 1;
	
	PrintToChatAll("\x04[\x03TD\x04]\x03 Your sentry limit has been changed to:\x04 %i",g_iBuildingLimit[TDBuilding_Sentry]);
	PrintToChatAll("\x04[\x03TD\x04]\x03 You can build additional sentries with the command \x04/s");
	return Plugin_Continue;
}

public Action Command_IncreaseDispenser(int iClient, any iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	g_iBuildingLimit[TDBuilding_Dispenser] += 1;
	
	PrintToChatAll("\x04[\x03TD\x04]\x03 Your dispenser limit has been changed to:\x04 %i",g_iBuildingLimit[TDBuilding_Dispenser]);
	PrintToChatAll("\x04[\x03TD\x04]\x03 You can build dispensers via your PDA");
	return Plugin_Continue;
}

public Action Command_BonusMetal(int iClient, any iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	SpawnMetalPacksNumber(TDMetalPack_Start, 4);
	
	return Plugin_Continue;
}

public Action Command_Multiplier(int iClient, any iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

/**
 * Gets multiplier base price
 *
 * @param iMultiplierId 	The multipliers id.
 * @return					return 1000 on failure.
 */

stock int Multiplier_GetPrice(int iMultiplierId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_price", iMultiplierId);
		
	int iPrice = 0;
	if (!GetTrieValue(g_hMultiplier, sKey, iPrice)) {
		return 1000;
	}	
	return iPrice;
}

/**
 * Gets multiplier increase
 *
 * @param iMultiplierId 	The multipliers id.
 * @return					return 1000 on failure.
 */

stock int Multiplier_GetIncrease(int iMultiplierId) {
	
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_increase", iMultiplierId);
		
	int iIncrease = 0;
	if (!GetTrieValue(g_hMultiplier, sKey, iIncrease)) {
		return 1000;
	}
	return iIncrease;
}

stock int Multiplier_GetInt(const char[] sDamageType) {
	char sKey[32], sMultiplier[32];
	
	for (int i = 0; i <= iMaxMultiplierTypes; i++) {
		Format(sKey, sizeof(sKey), "%d_type", i);
		if (GetTrieString(g_hMultiplierType, sKey, sMultiplier, sizeof(sMultiplier))) {
			if(StrContains(sMultiplier, sDamageType) != -1) {
				return i;
			}
		}
	}
	return 1;
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

public Action CommandListener_Kill(int iClient, const char[] sCommand, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(iClient)) {
		return Plugin_Continue;
	}
	
	if(iArgs > 0) {
		return Plugin_Continue;
	}
	
	if (IsDefender(iClient)) {
		int iMetal = GetClientMetal(iClient) / 2;
		
		if (iMetal > 0) {
			float fLocation[3];
			
			GetClientEyePosition(iClient, fLocation);
			fLocation[2] = fLocation[2] - GetDistanceToGround(fLocation) + 10.0;
			
			SpawnMetalPack(TDMetalPack_Medium, fLocation, iMetal);
		}
	}
	
	return Plugin_Continue;
} 

public Action CommandListener_Multiplier(int iClient, const char[] sCommand, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	for (int i = 1; i <= iMaxMultiplierTypes; i++) {
		char sKey[32], sMultiplier[32];
		Format(sKey, sizeof(sKey), "%d_type", i);

		if (GetTrieString(g_hMultiplierType, sKey, sMultiplier, sizeof(sMultiplier))) {
			if(StrContains(sMultiplier, "crit") != -1) {
				//Check if already has 100% crits
				if(fMultiplier[i] >= 20.0) {
					PrintToChatAll("\x04[\x03TD\x04]\x03 You can't increase crit chance anymore.");
					return Plugin_Continue;
				}
				
				int iPriceToPay = Multiplier_GetPrice(i) + Multiplier_GetIncrease(i) * RoundToZero(fMultiplier[i]);
	
				int iClients = GetRealClientCount(true);
		
				if (iClients <= 0) {
					iClients = 1;
				}
	
				if(CanAfford(iPriceToPay)) {
	
					for (int iLoopClient = 1; iLoopClient <= MaxClients; iLoopClient++) {
						if (IsDefender(iLoopClient)) {
							AddClientMetal(iLoopClient, -iPriceToPay);
						}
					}
					fMultiplier[i] += 1.0;
					PrintToChatAll("\x04[\x03TD\x04]\x03 Crit Chance set to:\x04 %i%",RoundToZero(fMultiplier[i] * 5.0));
		
					if(fMultiplier[i] >= 20.0) {
						PrintToChatAll("\x04[\x03TD\x04]\x03 You can't increase crit chance anymore.");
					} else {
					
						int iNextPrice = iPriceToPay + Multiplier_GetIncrease(i);
						PrintToChatAll("\x04[\x03TD\x04]\x03 Next Upgrade will cost:\x04 %i\x03 metal per Player",iNextPrice);
					}
					
					
					return Plugin_Continue;
				}
			} 
			else if(StrContains(sCommand, sMultiplier) != -1) {
				int iPriceToPay = Multiplier_GetPrice(i) + Multiplier_GetIncrease(i) * RoundToZero(fMultiplier[i]);
	
				int iClients = GetRealClientCount(true);
		
				if (iClients <= 0) {
					iClients = 1;
				}
		
				iPriceToPay /= iClients;
	
				if(CanAfford(iPriceToPay)) {
	
					for (int iLoopClient = 1; iLoopClient <= MaxClients; iLoopClient++) {
						if (IsDefender(iLoopClient)) {
							AddClientMetal(iLoopClient, -iPriceToPay);
						}
					}
					fMultiplier[i] += 1.0;
					PrintToChatAll("\x04[\x03TD\x04]\x03 Multiplier set to:\x04 %i.0",RoundToZero(fMultiplier[i] + 1.0));
		
					int iNextPrice = iPriceToPay + Multiplier_GetIncrease(i);
					PrintToChatAll("\x04[\x03TD\x04]\x03 Next Upgrade will cost:\x04 %i\x03 metal per Player",iNextPrice);
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
} 