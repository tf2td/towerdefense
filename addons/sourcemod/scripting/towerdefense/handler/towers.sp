#pragma semicolon 1

#include <sourcemod>

/**
 * Attaches a tower to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock AttachTower(iClient) {
	new iTower = GetAimTarget(iClient);

	if (IsTower(iTower)) {
		if (IsTowerAttached(iTower)) {
			PrintToChat(iClient, "\x07FF0000%N is already being moved by someone!", iTower);
			return;
		}

		SetEntityMoveType(iTower, MOVETYPE_NOCLIP);

		TeleportEntity(iTower, Float:{0.0, 0.0, -8192.0}, NULL_VECTOR, NULL_VECTOR); // Teleport out of the map

		AttachAnnotation(iClient, "Moving: %N", iTower);

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
	new iTower = g_iAttachedTower[iClient];
	new Float:fLocation[3], Float:fAngles[3];

	SetEntityMoveType(iTower, MOVETYPE_WALK);

	GetClientAbsOrigin(iClient, fLocation);
	GetClientAbsAngles(iClient, fAngles);

	TeleportEntity(iTower, fLocation, fAngles, NULL_VECTOR);

	HideAnnotation(iClient);

	g_iAttachedTower[iClient] = 0;
	Log(TDLogLevel_Debug, "%N dropped tower (%N)", iClient, iTower);
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iEntity		The entity.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock AttachAnnotation(iEntity, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity); 
	SetEventInt(hEvent, "id", iEntity); 
	SetEventFloat(hEvent, "lifetime", 86400.0);

	new String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 3);
	SetEventString(hEvent, "text", sFormattedMessage); 

	FireEvent(hEvent); 
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The entity.
 * @noreturn
 */

stock HideAnnotation(iEntity)  { 
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
		return;
	}

	SetEventInt(hEvent, "id", iEntity); 
	FireEvent(hEvent); 
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