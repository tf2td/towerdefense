#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Attaches a annotation to an entity.
 *
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void AttachAnnotation(int iEntity, float fLifetime, char[] sMessage, any...) {
	Handle hEvent = CreateEvent("show_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The entity.
 * @noreturn
 */

stock void HideAnnotation(int iEntity) {
	Handle hEvent = CreateEvent("hide_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "id", iEntity);
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

stock void AttachAdvancedAnnotation(int iClient, int iEntity, float fLifetime, char[] sMessage, any...) {
	Handle hEvent = CreateEvent("show_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iClient * iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 5);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	SetEventInt(hEvent, "visibilityBitfield", GetVisibilityBitfield(iClient));
	
	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The client.
 * @param iEntity		The entity.
 * @noreturn
 */

stock void HideAdvancedAnnotation(int iClient, int iEntity) {
	Handle hEvent = CreateEvent("hide_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventInt(hEvent, "id", iClient * iEntity);
	FireEvent(hEvent);
}

/**
 * Shows an annotation at a given location.
 *
 * @param iId			The id (use this to hide).
 * @param fLocation		The location vector.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock void ShowAnnotation(int iId, float fLocation[3], float fOffsetZ, float fLifetime, char[] sMessage, any...) {
	Handle hEvent = CreateEvent("show_annotation");
	
	if (hEvent == null) {
		return;
	}
	
	SetEventFloat(hEvent, "worldPosX", fLocation[0]);
	SetEventFloat(hEvent, "worldPosY", fLocation[1]);
	SetEventFloat(hEvent, "worldPosZ", fLocation[2] + fOffsetZ);
	SetEventInt(hEvent, "id", iId);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");
	
	char sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	FireEvent(hEvent);
}