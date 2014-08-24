#pragma semicolon 1

#include <sourcemod>

/**
 * Attaches a tower to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock AttachTower(iClient) {
	if (!g_bEnabled) {
		return;
	}

	new iTower = GetAimTarget(iClient);

	if (IsTower(iTower)) {
		if (IsTowerAttached(iTower)) {
			PrintToChat(iClient, "\x07FF0000%N is already being moved by someone!", iTower);
			return;
		}

		TF2Attrib_SetByName(iClient, "cannot pick up buildings", 1.0);

		SetEntityMoveType(iTower, MOVETYPE_NOCLIP);

		TeleportEntity(iTower, Float:{0.0, 0.0, -8192.0}, NULL_VECTOR, NULL_VECTOR); // Teleport out of the map

		HideAnnotation(iTower);
		AttachAnnotation(iClient, 86400.0, "Moving: %N", iTower);

		g_bCarryingObject[iClient] = true;
		g_iAttachedTower[iClient] = iTower;
		Log(TDLogLevel_Debug, "%N picked up tower (%N)", iClient, iTower);
	}
}

/**
 * Detaches a tower from a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock DetachTower(iClient) {
	if (!g_bEnabled) {
		return;
	}

	new iTower = g_iAttachedTower[iClient];
	new Float:fLocation[3], Float:fAngles[3];

	SetEntityMoveType(iTower, MOVETYPE_WALK);

	GetClientAbsOrigin(iClient, fLocation);
	GetClientAbsAngles(iClient, fAngles);

	TeleportEntity(iTower, fLocation, fAngles, NULL_VECTOR);

	HideAnnotation(iClient);

	TF2Attrib_RemoveByName(iClient, "cannot pick up buildings");

	g_bCarryingObject[iClient] = false;
	g_iAttachedTower[iClient] = 0;
	Log(TDLogLevel_Debug, "%N dropped tower (%N)", iClient, iTower);
}

/**
 * Gets called when a tower is upgraded by a client.
 *
 * @param iTower		The tower.
 * @param iClient		The client upgrading.
 * @noreturn
 */

stock UpgradeTower(iTower, iClient) {
	if (!g_bEnabled) {
		return;
	}

	if (!AddClientMetal(iClient, -25)) {
		return;
	}

	g_iUpgradeMetal[iTower] += 25;

	if (g_iUpgradeMetal[iTower] >= 1000) {
		// Upgrade tower to next level

		g_iUpgradeMetal[iTower] = 0;
		g_iUpgradeLevel[iTower]++;
	}

	HideAnnotation(iTower);
	HideAdvancedAnnotation(iClient, iTower);
	AttachAnnotation(iTower, 2.0, "%N\n\rCurrent Level: %d\n\rUpgrade Progress: %d/1000", iTower, g_iUpgradeLevel[iTower], g_iUpgradeMetal[iTower]);
}

/**
 * Shows tower info to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock ShowTowerInfo(iClient) {
	if (!g_bEnabled) {
		return;
	}

	new iTower = GetAimTarget(iClient);

	if (IsTower(iTower)) {
		AttachAdvancedAnnotation(iClient, iTower, 4.0, "%N\n\rCurrent Level: %d\n\rUpgrade Progress: %d/1000", iTower, g_iUpgradeLevel[iTower], g_iUpgradeMetal[iTower]);
	}
}

/**
 * Spawns a tower.
 *
 * @param iTowerID		The towers id.
 * @return				True on success, false ontherwise.
 */

stock bool:SpawnTower(iTowerId) {
	if (!g_bEnabled) {
		return false;
	}

	if (IsTower(GetTower(iTowerId))) { // Tower already spawned
		return false;
	}

	// Remove sv_cheats flags from bot command
	new iFlags;
	iFlags = GetCommandFlags("bot");
	iFlags &= ~FCVAR_CHEAT;
	iFlags &= ~FCVAR_SPONLY;
	SetCommandFlags("bot", iFlags);

	ServerCommand("bot -team blue -class %s -name %s", g_sTowerData[iTowerId][TOWER_DATA_CLASS], g_sTowerData[iTowerId][TOWER_DATA_NAME]);

	// Re-add sv_cheats flags to bot command
	iFlags &= FCVAR_CHEAT;
	iFlags &= FCVAR_SPONLY;
	SetCommandFlags("bot", iFlags);

	Log(TDLogLevel_Info, "Tower (%N) spawned", g_sTowerData[iTowerId][TOWER_DATA_NAME]);
	return true;
}

/*=========================================
=            Utility Functions            =
=========================================*/

/**
 * Gets a visibility bitfield which determines if a player should see an annotation.
 *
 * @param iClient		The client who should see it.
 * @return				The bitfield.
 */

stock GetVisibilityBitfield(iClient) {
	if (!IsDefender(iClient)) {
		return 1;
	}

	new iBitField = 1;
	iBitField |= RoundFloat(Pow(2.0, float(iClient)));
	return iBitField;
}

/**
 * Checks if a tower is attached to a client.
 *
 * @param iTower		The tower.
 * @return				True if tower is attached, false ontherwise.
 */

stock bool:IsTowerAttached(iTower) {
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (g_iAttachedTower[iClient] == iTower) {
			return true;
		}
	}

	return false;
}

/**
 * Gets a towers client index.
 *
 * @param iTowerId		The towers id.
 * @return				The towers client index, or -1 on failure.
 */

stock GetTower(iTowerId) {
	decl String:sName[MAX_NAME_LENGTH];
	
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsTower(iClient)) {
			GetClientName(iClient, sName, sizeof(sName));
			
			if (StrEqual(sName, g_sTowerData[iTowerId][TOWER_DATA_NAME])) {
				return iClient;
			}
		}
	}
	
	return -1;
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock AttachAnnotation(iEntity, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity); 
	SetEventInt(hEvent, "id", iEntity); 
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);

	FireEvent(hEvent);
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iClient		The client.
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock AttachAdvancedAnnotation(iClient, iEntity, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iClient * iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 5);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	SetEventInt(hEvent, "visibilityBitfield", GetVisibilityBitfield(iClient));

	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The entity.
 * @noreturn
 */

stock HideAnnotation(iEntity) {
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
		return;
	}

	SetEventInt(hEvent, "id", iEntity); 
	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The client.
 * @param iEntity		The entity.
 * @noreturn
 */

stock HideAdvancedAnnotation(iClient, iEntity) {
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
		return;
	}

	SetEventInt(hEvent, "id", iClient * iEntity); 
	FireEvent(hEvent);
}