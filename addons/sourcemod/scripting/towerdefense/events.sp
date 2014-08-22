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

public Event_PlayerChangeClass(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	if (!g_bEnabled) {
		return;
	}

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		TF2_SetPlayerClass(iClient, TFClass_Engineer, false, true);
	}
}

public Action:Event_PlayerChangeTeam(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	SetEventBroadcast(hEvent, true); // Block the chat output (Player ... joined team BLU)
	
	if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
		PrintToChatAll("Player %N joined the Defenders.", iClient);
	}

	return Plugin_Continue;
}

public Action:Event_PlayerConnect(Handle:hEvent, const String:sName[], bool:bDontBroadcast) {
	if (!g_bEnabled) {
		return Plugin_Continue;
	}

	SetEventBroadcast(hEvent, true); // Block the original chat output (Player ... has joined the game)
	
	return Plugin_Continue;
}

/*=======================================
=            TF2Items Events            =
=======================================*/

/**
 * Called when an item was given to a client.
 *
 * @noreturn
 */

public TF2Items_OnGiveNamedItem_Post(iClient, String:sClassname[], iItemDefinitionIndex, iItemLevel, iItemQuality, iEntityIndex) {
	if (!g_bEnabled) {
		return;
	}

	if (!IsDefender(iClient)) {
		return;
	}

	switch (iItemDefinitionIndex) {
		case 141, 527, 588, 997, 1004 : {
			// Engineers primaries => Engineer's Shotgun

			TF2Items_GiveWeapon(iClient, 9, TFWeaponSlot_Primary, 5, 1, false, "tf_weapon_shotgun_primary", "");
		}
		case 140, 528, 1086 : {
			// Engineers secondaries => Engineer's Pistol 

			TF2Items_GiveWeapon(iClient, 22, TFWeaponSlot_Secondary, 5, 1, false, "tf_weapon_pistol", "");
		}
	}
}