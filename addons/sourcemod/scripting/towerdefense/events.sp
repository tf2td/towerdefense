#pragma semicolon 1

#include <sourcemod>

/**
 * Hooks all necessary events.
 * Some events may be hooked with EventHookMode_Pre or EventHookMode_Post.
 *
 * @noreturn
 */

stock HookEvents() {
	HookEvent("player_changeclass", Event_PlayerChangeClass);
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
}

public Action:Event_PlayerChangeClass(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerChangeTeam(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	SetEventBroadcast(hEvent, true); // Block the chat output (Player ... joined team BLU)
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		PrintToChatAll("Player %N joined the Defenders.", iClient);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerConnect(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	SetEventBroadcast(hEvent, true); // Block the original chat output (Player ... has joined the game)
	
	return Plugin_Continue;
}