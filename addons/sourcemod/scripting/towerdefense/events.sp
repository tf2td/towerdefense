#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "info/constants.sp"
	#include "info/enums.sp"
	#include "info/variables.sp"
#endif

/**
 * Hooks all necessary events.
 * Some events may be hooked with EventHookMode_Pre or EventHookMode_Post.
 *
 * @noreturn
 */

stock void HookEvents() {
	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("player_carryobject", Event_PlayerCarryObject);
	HookEvent("player_changeclass", Event_PlayerChangeClass);
	HookEvent("player_team", Event_PlayerChangeTeamPre, EventHookMode_Pre);
	HookEvent("player_connect_client", Event_PlayerConnectPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnectPre, EventHookMode_Pre);
	HookEvent("player_dropobject", Event_PlayerDropObject);
	HookEvent("post_inventory_application", Event_PostInventoryApplication, EventHookMode_Post);
	HookEvent("teamplay_round_win", Event_RoundWin);
	
	// User Messages
	HookUserMessage(GetUserMessageId("VGUIMenu"), Event_PlayerVGUIMenu, true);
	
	AddNormalSoundHook(Event_Sound);
}

public void Event_PlayerActivate(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	int iUserId = GetEventInt(hEvent, "userid");
	int iClient = GetClientOfUserId(iUserId);
	
	char sSteamId[32];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamId, sizeof(sSteamId));
	
	if (!StrEqual(sSteamId, "BOT")) {
		Player_Loaded(iUserId, iClient);
	}
}

public void Event_PlayerCarryObject(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return;
	}
	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsDefender(iClient)) {
		g_bCarryingObject[iClient] = true;
	}
}

public void Event_PlayerChangeClass(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return;
	}
	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);
	}
}

public Action Event_PlayerChangeTeamPre(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if (GetEventBool(hEvent, "disconnect")) {
		return Plugin_Continue;
	}
	
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	SetEventBroadcast(hEvent, true); // Block the chat output (Player ... joined team BLU)
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		PrintToChatAll("Player %N joined the Defenders.", iClient);
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerConnectPre(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	SetEventBroadcast(hEvent, true); // Block the original chat output (Player ... has joined the game)
	Database_UpdateServerPlayerCount();
	return Plugin_Continue;
}

public void Event_PlayerDeath(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return;
	}
	
	int iUserId = GetEventInt(hEvent, "userid");
	int iClient = GetClientOfUserId(iUserId);
	int iAttackerId = GetEventInt(hEvent, "attacker");
	//Check if attacker is a Defender
	if(IsValidClient(GetClientOfUserId(iAttackerId)) && IsDefender(GetClientOfUserId(iAttackerId))) {
		int iAttacker = GetClientOfUserId(iAttackerId);
		Player_CAddValue(iAttacker, PLAYER_KILLS, 1);
	}
	//Check if assister is a Defender
	int iAssisterId = GetEventInt(hEvent, "assister");
	if(IsValidClient(GetClientOfUserId(iAssisterId)) && IsDefender(GetClientOfUserId(iAssisterId))) {
		int iAssister = GetClientOfUserId(iAssisterId);
		Player_CAddValue(iAssister, PLAYER_ASSISTS, 1);
	}
	
	if (IsDefender(iClient)) {
		Player_OnDeath(iUserId, iClient);
	} else if (IsAttacker(iClient)) {
		int entity = GetEventInt(hEvent, "victim_entindex");
		
		float position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
		
		Wave_OnDeath(iClient, position);
	}
}

public Action Event_PlayerDisconnectPre(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	int iUserId = GetEventInt(hEvent, "userid");
	int iClient = GetClientOfUserId(iUserId);
	
	if (IsDefender(iClient)) {
		Player_OnDisconnectPre(iUserId, iClient);
		Database_UpdateServerPlayerCount();
	} else {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Event_PlayerDropObject(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return;
	}
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsDefender(iClient)) {
		g_bCarryingObject[iClient] = false;
	}
}

public void Event_PostInventoryApplication(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	if (!g_bEnabled) {
		return;
	}
	
	int iUserId = GetEventInt(hEvent, "userid");
	int iClient = GetClientOfUserId(iUserId);
	
	if(IsValidClient(iClient) && IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && GetClientTeam(iClient) == TEAM_ATTACKER) {
		ChangeClientTeam(iClient, TEAM_DEFENDER);
		CreateTimer(0.5, RespawnPlayer, iClient);
	} else if (IsDefender(iClient)) {
		Player_OnSpawn(iUserId, iClient);
	} else if (IsTower(iClient)) {
		Tower_OnSpawn(iClient, GetTowerId(iClient));
	} else if (IsAttacker(iClient)) {
		Wave_OnSpawn(iClient);
		RequestFrame(Wave_OnSpawnPost, iClient);
	}
	
	SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 13); // COLLISION_GROUP_PROJECTILE
}

public Action Event_RoundWin(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	int iTeam = GetEventInt(hEvent, "team");
	Server_UAddValue(g_iServerId, SERVER_ROUNDS_PLAYED, 1);
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
			if(IsDefender(iClient)) {
				int iUserId = GetClientUserId(iClient);
				int iTime = GetTime() - g_iTime;
				Player_CSetValue(iClient, PLAYER_PLAYTIME, iTime);
				Server_UAddValue(g_iServerId, SERVER_PLAYTIME, iTime);
				Player_CSetValue(iClient, PLAYER_ROUNDS_PLAYED, 1);
				Database_UpdatePlayerDisconnect(iUserId);
			}
		}
		
	Database_ServerStatsUpdate();
	
	ServerCommand("bot_kick all");
	ServerCommand("mp_autoteambalance 0");
	
	if (iTeam == TEAM_ATTACKER) {
		PrintToChatAll("\x07FF0000Game over! Resetting the map...");
	}
	Server_Reset();
	
	return Plugin_Handled;
}

public Action Event_Sound(int iClients[64], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}
	
	if (IsValidEntity(iEntity) && IsTower(iEntity)) {
		// Allow engineer hitting building sounds
		if (StrContains(sSample, "wrench_hit_build_") != -1 || StrContains(sSample, "wrench_swing") != -1) {
			return Plugin_Continue;
		}
		
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/*====================================
=            Usermessages            =
====================================*/

public Action Event_PlayerVGUIMenu(UserMsg iMessageId, Handle hBitBuffer, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit) {
	char sBuffer1[64];
	char sBuffer2[256];
	
	// check menu name
	BfReadString(hBitBuffer, sBuffer1, sizeof(sBuffer1));
	if (strcmp(sBuffer1, "info") != 0) {
		return Plugin_Continue;
	}
	
	// Skip hidden motd
	if (BfReadByte(hBitBuffer) != 1) {
		return Plugin_Continue;
	}
	
	int iCount = BfReadByte(hBitBuffer);
	
	if (iCount == 0) {
		return Plugin_Continue;
	}
	
	Handle hKeyValues = CreateKeyValues("data");
	
	for (int i = 0; i < iCount; i++) {
		BfReadString(hBitBuffer, sBuffer1, sizeof(sBuffer1));
		BfReadString(hBitBuffer, sBuffer2, sizeof(sBuffer2));
		
		if (StrEqual(sBuffer1, "customsvr") || (StrEqual(sBuffer1, "msg") && !StrEqual(sBuffer2, "motd"))) {
			delete hKeyValues;
			return Plugin_Continue;
		}
		
		KvSetString(hKeyValues, sBuffer1, sBuffer2);
	}
	
	Handle hPack;
	
	CreateDataTimer(0.0, ShowMotd, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	WritePackCell(hPack, GetClientUserId(iPlayers[0]));
	WritePackCell(hPack, view_as<int>(hKeyValues));
	
	return Plugin_Handled;
}

public Action ShowMotd(Handle hTimer, Handle hPack) {
	ResetPack(hPack);
	
	int iClient = GetClientOfUserId(ReadPackCell(hPack));
	Handle hKeyValues = view_as<Handle>(ReadPackCell(hPack));
	
	if (!IsValidClient(iClient)) {
		CloseHandle(hKeyValues);
		return Plugin_Stop;
	}
	
	KvSetNum(hKeyValues, "customsvr", 1);
	KvSetNum(hKeyValues, "cmd", 5); // closed_htmlpage
	KvSetNum(hKeyValues, "type", MOTDPANEL_TYPE_URL);
	
	KvSetString(hKeyValues, "title", "Welcome to TF2 Tower Defense!");
	KvSetString(hKeyValues, "msg", "http://www.tf2td.net/");
	
	ShowVGUIPanel(iClient, "info", hKeyValues, true);
	
	CloseHandle(hKeyValues);
	
	return Plugin_Stop;
}

/*==================================
=            TF2 Events            =
==================================*/

/**
 * Called on weapon fire to decide if the current shot should be critical.
 *
 * @noreturn
 */

public Action TF2_CalcIsAttackCritical(int iClient, int iWeapon, char[] sClassname, bool &bResult) {
	if (!g_bEnabled) {
		return Plugin_Handled;
	}
	//If hitting with Wrench
	if (StrEqual(sClassname, "tf_weapon_wrench") || StrEqual(sClassname, "tf_weapon_robot_arm")) {
		float fLocation[3], fAngles[3];
		
		GetClientEyePosition(iClient, fLocation);
		GetClientEyeAngles(iClient, fAngles);
		
		TR_TraceRayFilter(fLocation, fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayPlayers, iClient);
		
		if (TR_DidHit()) {
			int iTower = TR_GetEntityIndex();
			
			if (IsTower(iTower)) {
				float fHitLocation[3];
				TR_GetEndPosition(fHitLocation);
				
				if (GetVectorDistance(fLocation, fHitLocation) <= 70.0) {
					Tower_OnUpgrade(iTower, iClient);
				}
			}
		}
	}
	
	// Unlimited ammo/metal for towers
	if (IsTower(iClient)) {
		SetEntData(iWeapon, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 100, _, true);
		SetEntData(iClient, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 100);
		SetEntData(iClient, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 100);
		SetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (3 * 4), 100);
	}
	
	//Calculate crit chances
	if (fMultiplier[Multiplier_GetInt("crit")] == 0.0) {
		bResult = false;
	}

	if (fMultiplier[Multiplier_GetInt("crit")] * 0.05 * 100 >= GetRandomInt(0, 100)) {
		bResult = true;		
	}
	
	
	return Plugin_Handled;
}

/*=======================================
=            TF2Items Events            =
=======================================*/

/**
 * Called when an item was given to a client.
 *
 * @noreturn
 */

public int TF2Items_OnGiveNamedItem_Post(int iClient, char[] sClassname, int iItemDefinitionIndex, int iItemLevel, int iItemQuality, int iEntityIndex) {
	if (!g_bEnabled) {
		return;
	}
	
	if (!IsDefender(iClient)) {
		return;
	}
	
	if (iItemDefinitionIndex != 9 || iItemDefinitionIndex != 199) {
		// Engineers primaries => Engineer's Shotgun
		
		g_bReplaceWeapon[iClient][TFWeaponSlot_Primary] = true;
	}
	
	if (iItemDefinitionIndex != 22 || iItemDefinitionIndex != 209 || iItemDefinitionIndex != 160 || iItemDefinitionIndex != 294) {
		// Engineers secondaries => Engineer's Pistol 
		
		g_bReplaceWeapon[iClient][TFWeaponSlot_Secondary] = true;
	}
} 