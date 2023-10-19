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
	int	 target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if (iArgs < 1) {
		ReplyToCommand(iClient, "[SM] Usage: sm_gm <#userid|name> <metal>");
		return Plugin_Handled;
	} else if (iArgs == 1) {
		GetCmdArg(1, sMetal, sizeof(sMetal));
		AddClientMetal(iClient, StringToInt(sMetal));
	} else if (iArgs >= 2) {
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
				 tn_is_ml))
			<= 0) {
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
		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdSetWaveUsage");
		return Plugin_Handled;
	}

	if (g_bTowersLocked) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidSetWaveMidWave");
		return Plugin_Handled;
	}

	char sWave[6];
	GetCmdArg(1, sWave, sizeof(sWave));
	if (StringToInt(sWave) - 1 >= iMaxWaves)
		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdSetWaveOOB", iMaxWaves);
	else {
		g_iCurrentWave = StringToInt(sWave) - 1;
		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdSetWave", g_iCurrentWave + 1);
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

		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdBuyTower", iClient, sName);

		g_bTowerBought[view_as<int>(iTowerId)] = true;
		UpdateMaxBotsOnField();
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

	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdPreGameInfo1");
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdPreGameInfo2");

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

		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdSetPasswordInfo1", g_sPassword);
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdSetPasswordInfo2");
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdSetPasswordInfo3");

		SetPassword(g_sPassword);
	} else {
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdServerNotLockable");
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
	if (!StrEqual(g_sPassword, "")) {
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdPassword", g_sPassword);
	} else {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidNoPasswordSet");
	}
	return Plugin_Continue;
}

public Action Command_BuildSentry(int iClient, int iArgs) {
	if (!CanClientBuild(iClient, TDBuilding_Sentry)) {
		return Plugin_Handled;
	}

	if (IsInsideClient(iClient)) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidCantBuildInsideAPlayer");
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

		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdBuildSentryInfo");
	}

	return Plugin_Handled;
}

public Action Command_DropMetal(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	if (iArgs != 1) {
		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdDropMetalUsage");
		return Plugin_Handled;
	}

	char sMetal[32];
	GetCmdArg(1, sMetal, sizeof(sMetal));

	int iMetal;

	if (!IsStringNumeric(sMetal)) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidInvalidInput");
		return Plugin_Handled;
	} else {
		iMetal = StringToInt(sMetal);
	}

	if (iMetal <= 0) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidDropMinMetal");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidDeadCantDropMetal");
		return Plugin_Handled;
	}

	if (!(GetEntityFlags(iClient) & FL_ONGROUND)) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidInAirCantDropMetal");
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
			Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidDropMinMetal");
		}
		case TDMetalPack_LimitReached: {
			Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidDropMetalLimit");
		}
		case TDMetalPack_InvalidType: {
			Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidUnableDropMetal");
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

	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdMetalStats");

	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if (IsDefender(iPlayer)) {
			CPrintToChatAll("%t", "cmdMetalStatsPlayer", iPlayer, GetClientMetal(iPlayer));
		}
	}

	return Plugin_Handled;
}

public Action Command_ShowWave(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "cmdCurrentWave", g_iCurrentWave + 1, iMaxWaves);

	return Plugin_Handled;
}

public Action Command_TransferMetal(int iClient, int iArgs) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}

	if (iArgs != 2) {
		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdTransferMetalUsage");
		return Plugin_Handled;
	}

	char sTarget[64];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	char sMetal[32];
	GetCmdArg(2, sMetal, sizeof(sMetal));

	int iMetal;
	int iTarget = GetClientByName(iClient, sTarget);

	if (!IsStringNumeric(sMetal)) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidInvalidInput");
		return Plugin_Handled;
	} else {
		iMetal = StringToInt(sMetal);
	}

	if (iMetal > GetClientMetal(iClient) || GetClientMetal(iClient) <= 0) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidTransferNotEnough");
		return Plugin_Handled;
	}

	if (iMetal < 0) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidTransferNegative");
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(iClient)) {
		Forbid(iClient, true, "%s %t", PLUGIN_PREFIX, "forbidTransferDead");
		return Plugin_Handled;
	}

	if (IsDefender(iTarget) && IsPlayerAlive(iTarget)) {
		AddClientMetal(iTarget, iMetal);
		AddClientMetal(iClient, -iMetal);

		CPrintToChat(iTarget, "%s %t", PLUGIN_PREFIX, "cmdTransferMetalReceived", iMetal, iClient);
		CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "cmdTransferMetalSent", iTarget, iMetal);
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
		AddClientMetal(iClient, 1);	   // for resetting HUD
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