#pragma semicolon 1

#include <sourcemod>

/**
 * Checks if an entity is a corner.
 *
 * @param iCorner		The corner.
 * @return				True if valid, false otherwise.
 */

stock bool:Corner_IsValid(iCorner) {
	if (!IsValidEntity(iCorner)) {
		return false;
	}

	decl String:sBuffer[64];
	GetEntityClassname(iCorner, sBuffer, sizeof(sBuffer));

	if (StrEqual(sBuffer, "trigger_multiple")) {
		GetEntPropString(iCorner, Prop_Data, "m_iName", sBuffer, sizeof(sBuffer));

		return (StrContains(sBuffer, "corner_") != -1);
	}

	return false;
}

/**
 * Finds a corner by name.
 *
 * @param sName			The corners name.
 * @return				The corners entity index, or -1 on failure.
 */

stock Corner_FindByName(const String:sName[]) {
	new iCorner = -1;
	decl String:sCornerName[64];

	while ((iCorner = FindEntityByClassname(iCorner, "trigger_multiple")) != -1) {
		Corner_GetName(iCorner, sCornerName, sizeof(sCornerName));

		if (StrEqual(sCornerName, sName)) {
			return iCorner;
		}
	}

	return -1;
}

/**
 * Finds a corner by it's next corners name.
 *
 * @param sName			The next corners name.
 * @return				The corners entity index, or -1 on failure.
 */

stock Corner_FindByNextName(const String:sName[]) {
	new iCorner = -1;
	decl String:sCornerName[64];

	while ((iCorner = FindEntityByClassname(iCorner, "trigger_multiple")) != -1) {
		Corner_GetNextName(iCorner, sCornerName, sizeof(sCornerName));

		if (StrEqual(sCornerName, sName)) {
			return iCorner;
		}
	}

	return -1;
}

/**
 * Gets a corners name.
 *
 * @param iCorner 		The corner.
 * @param bValidate		Validate the corner.
 * @return				The corner number, or -1 on failure.
 */

stock Corner_GetNumber(iCorner, bool:bValidate = true) {
	if (!bValidate) {
		decl String:sName[64];
		Corner_GetName(iCorner, sName, sizeof(sName), false);

		if (!StrEqual(sName, "corner_final")) {
			decl String:sNameParts[2][32];
			ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

			return StringToInt(sNameParts[1]);
		}
	} else if (Corner_IsValid(iCorner)) {
		decl String:sName[64];
		Corner_GetName(iCorner, sName, sizeof(sName), false);

		if (!StrEqual(sName, "corner_final")) {
			decl String:sNameParts[2][32];
			ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

			return StringToInt(sNameParts[1]);
		}
	}

	return -1;
}

/**
 * Gets a corners name.
 *
 * @param iCorner 		The corner.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @param bValidate		Validate the corner.
 * @return				True on success, false if corner was not found.
 */

stock bool:Corner_GetName(iCorner, String:sBuffer[], iMaxLength, bool:bValidate = true) {
	if (!bValidate) {
		GetEntPropString(iCorner, Prop_Data, "m_iName", sBuffer, iMaxLength);
		return true;
	} else if (Corner_IsValid(iCorner)) {
		GetEntPropString(iCorner, Prop_Data, "m_iName", sBuffer, iMaxLength);
		return true;
	}

	return false;
}

/**
 * Gets a corners next corner name.
 *
 * @param iCorner 		The corner.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @param bValidate		Validate the corner.
 * @return				True on success, false if corner was not found.
 */

stock bool:Corner_GetNextName(iCorner, String:sBuffer[], iMaxLength, bool:bValidate = true) {
	if (!bValidate) {
		GetEntPropString(iCorner, Prop_Data, "m_iParent", sBuffer, iMaxLength);
		return true;
	} else if (Corner_IsValid(iCorner)) {
		GetEntPropString(iCorner, Prop_Data, "m_iParent", sBuffer, iMaxLength);
		return true;
	}

	return false;
}

/**
 * Gets a corners location.
 *
 * @param iCorner 		The corner.
 * @param fLocation		The location vector.
 * @param bValidate		Validate the corner.
 * @return				True on success, false if corner was not found.
 */

stock bool:Corner_GetLocation(iCorner, Float:fLocation[3], bool:bValidate = true) {
	if (!bValidate) {
		GetEntPropVector(iCorner, Prop_Data, "m_vecAbsOrigin", fLocation);
		return true;
	} else if (Corner_IsValid(iCorner)) {
		GetEntPropVector(iCorner, Prop_Data, "m_vecAbsOrigin", fLocation);
		return true;
	}

	return false;
}

/**
 * Gets the angle between two corners.
 *
 * @param iCornerA 		The first corner.
 * @param iCornerB 		The second corner.
 * @param fAngles		The angles vector.
 * @param bValidate		Validate the corner.
 * @return				True on success, false if corner was not found.
 */

stock bool:Corner_GetAngles(iCornerA, iCornerB, Float:fAngles[3], bool:bValidate = true) {
	new Float:fLocationCornerA[3], Float:fLocationCornerB[3], Float:fVector[3];

	if (!bValidate) {
		Corner_GetLocation(iCornerA, fLocationCornerA, false);
		Corner_GetLocation(iCornerB, fLocationCornerB, false);

		MakeVectorFromPoints(fLocationCornerA, fLocationCornerB, fVector);
		GetVectorAngles(fVector, fAngles);
	} else if (Corner_IsValid(iCornerA) && Corner_IsValid(iCornerB)) {
		Corner_GetLocation(iCornerA, fLocationCornerA, false);
		Corner_GetLocation(iCornerB, fLocationCornerB, false);

		MakeVectorFromPoints(fLocationCornerA, fLocationCornerB, fVector);
		GetVectorAngles(fVector, fAngles);
	}

	return false;
}

/**
 * Gets the next corner.
 *
 * @param iCorner		The current corner.
 * @param sName			The current corners name (optional).
 * @return				The next corners entity index, or -1 on failure.
 */

stock Corner_GetNext(iCorner = -1, const String:sName[] = "") {
	decl String:sCornerName[64];

	if (StrEqual(sName, "") && Corner_IsValid(iCorner)) {
		Corner_GetName(iCorner, sCornerName, sizeof(sCornerName));
	} else if (!StrEqual(sName, "") && !Corner_IsValid(iCorner)) {
		strcopy(sCornerName, sizeof(sCornerName), sName);
		iCorner = Corner_FindByName(sCornerName);
	} else {
		return -1;
	}

	if (StrContains(sCornerName, "corner_") != -1 && !StrEqual(sCornerName, "corner_final")) {
		decl String:sNextName[64];
		Corner_GetNextName(iCorner, sNextName, sizeof(sNextName));

		return Corner_FindByName(sNextName);
	}

	return -1;
}

/**
 * Gets the previous corner.
 *
 * @param iCorner		The current corner.
 * @param sName			The current corners name (optional).
 * @return				The previous corners entity index, or -1 on failure.
 */

stock Corner_GetPrevious(iCorner = -1, const String:sName[] = "") {
	decl String:sCornerName[64];

	if (StrEqual(sName, "") && Corner_IsValid(iCorner)) {
		Corner_GetName(iCorner, sCornerName, sizeof(sCornerName));
	} else if (!StrEqual(sName, "") && !Corner_IsValid(iCorner)) {
		strcopy(sCornerName, sizeof(sCornerName), sName);
		iCorner = Corner_FindByName(sCornerName);
	} else {
		return -1;
	}

	if (StrContains(sCornerName, "corner_") != -1) {
		return Corner_FindByNextName(sCornerName);
	}

	return -1;
}

/**
 * Gets the nearest corner to a client.
 *
 * @param iClient		The client.
 * @return				The corners entity index, or -1 on failure.
 */

stock Corner_GetNearest(iClient) {
	if (!IsValidClient(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return -1;
	}

	new Float:fCornerLocation[3], Float:fClientLocation[3];
	GetClientAbsOrigin(iClient, fClientLocation);

	new iCorner = -1, iNearestCorner = -1;
	new Float:fNearestDistance = 2147483647.0, Float:fDistance;

	while ((iCorner = FindEntityByClassname(iCorner, "trigger_multiple")) != -1) {
		if (Corner_IsValid(iCorner)) {
			Corner_GetLocation(iCorner, fCornerLocation, false);

			fDistance = GetVectorDistance(fCornerLocation, fClientLocation);

			if (fDistance < fNearestDistance) {
				iNearestCorner = iCorner;
				fNearestDistance = fDistance;
			}
		}
	}

	return iNearestCorner;
}

/**
 * Gets the two corners a client is in between.
 *
 * @param iClient		The client.
 * @param iCornerA		The first corner.
 * @param iCornerB		The second corner.
 * @param fEpsilon		The possible deviation.
 * @return				False if not between any corners, true otherwise.
 */

stock bool:Corner_GetBetween(iClient, &iCornerA, &iCornerB, Float:fEpsilon = 15.0) {
	if (!IsValidClient(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return false;
	}

	static iNearBefore[MAXPLAYERS + 1];

	new iNear = Corner_GetNearest(iClient);
	
	new Float:fLocationNear[3], Float:fLocationClient[3];
	Corner_GetLocation(iNear, fLocationNear, false);
	GetClientAbsOrigin(iClient, fLocationClient);

	new Float:fVector[3], Float:fAngles[3], Float:fAnglesClient[3];
	MakeVectorFromPoints(fLocationNear, fLocationClient, fVector);
	GetVectorAngles(fVector, fAngles);
	GetClientEyeAngles(iClient, fAnglesClient);

	PrintToChatAll("%N: LOOKING: %.2f NEXT: %.2f DIFF: %.2f", iClient, fAnglesClient[1], fAngles[1], FloatAbs(fAngles[1] - fAnglesClient[1]));

	new Float:fAnglesDiff = FloatAbs(fAngles[1] - fAnglesClient[1]);

	if (fAnglesDiff != 0.0 && fAnglesDiff != 45.0 && fAnglesDiff != 90.0 && fAnglesDiff != 135.0 && fAnglesDiff != 180.0 && 
		fAnglesDiff != 225.0 && fAnglesDiff != 270.0 && fAnglesDiff != 315.0 && fAnglesDiff != 360.0 && fAnglesDiff > 5.0) {

		return false;
	}

	new iNumberNearBefore = Corner_GetNumber(iNearBefore[iClient]);

	if (iNumberNearBefore != -1 && IsValidEntity(iNear)) {
		new iNumberNear = Corner_GetNumber(iNear);

		if (iNumberNear != -1) {
			if (Abs(iNumberNearBefore - iNumberNear) > 1) {
				iNearBefore[iClient] = iNear;
				return false;
			}
		}
	}
	
	new iNext = Corner_GetNext(iNear);

	new Float:fLocationNext[3];
	Corner_GetLocation(iNext, fLocationNext);
	
	new Float:fResultA[3], Float:fResultB[3];
	SubtractVectors(fLocationNear, fLocationNext, fResultA);
	SubtractVectors(fLocationClient, fLocationNext, fResultB);

	new Float:fScale = GetVectorDotProduct(fResultA, fResultB) / GetVectorDotProduct(fResultA, fResultA);
	ScaleVector(fResultA, fScale);

	new Float:fResult[3];
	SubtractVectors(fResultB, fResultA, fResult);

	if (FloatAbs(fResult[0]) <= fEpsilon && FloatAbs(fResult[1]) <= fEpsilon) {
		iCornerA = iNear;
		iCornerB = iNext;

		iNearBefore[iClient] = iNear;
		return true;
	}

	new iPrev = Corner_GetPrevious(iNear);

	new Float:fLocationPrev[3];
	Corner_GetLocation(iPrev, fLocationPrev);

	SubtractVectors(fLocationNear, fLocationPrev, fResultA);
	SubtractVectors(fLocationClient, fLocationPrev, fResultB);

	fScale = GetVectorDotProduct(fResultA, fResultB) / GetVectorDotProduct(fResultA, fResultA);
	ScaleVector(fResultA, fScale);

	SubtractVectors(fResultB, fResultA, fResult);

	if (FloatAbs(fResult[0]) <= fEpsilon && FloatAbs(fResult[1]) <= fEpsilon) {
		iCornerA = iPrev;
		iCornerB = iNear;

		iNearBefore[iClient] = iNear;
		return true;
	}

	return false;
}