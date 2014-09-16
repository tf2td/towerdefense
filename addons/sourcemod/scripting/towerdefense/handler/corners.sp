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

	new bool:bResult = false;

	static iNearBefore;

	new iNear = Corner_GetNearest(iClient);

	// Not working for corners which are before the now-near one...
	if (Corner_GetNumber(iNearBefore) != -1 && Corner_GetNumber(iNear) - 1 > Corner_GetNumber(iNearBefore)) {
		return false;
	}
	
	new iNext = Corner_GetNext(iNear);
	new iPrev = Corner_GetPrevious(iNear);

	new Float:fLocationNear[3], Float:fLocationNext[3], Float:fLocationPrev[3], Float:fLocationClient[3];

	Corner_GetLocation(iNear, fLocationNear, false);
	Corner_GetLocation(iNext, fLocationNext);
	Corner_GetLocation(iPrev, fLocationPrev);
	GetClientAbsOrigin(iClient, fLocationClient);

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

		bResult = true;
	}

	SubtractVectors(fLocationNear, fLocationPrev, fResultA);
	SubtractVectors(fLocationClient, fLocationPrev, fResultB);

	fScale = GetVectorDotProduct(fResultA, fResultB) / GetVectorDotProduct(fResultA, fResultA);
	ScaleVector(fResultA, fScale);

	SubtractVectors(fResultB, fResultA, fResult);

	if (FloatAbs(fResult[0]) <= fEpsilon && FloatAbs(fResult[1]) <= fEpsilon) {
		iCornerA = iPrev;
		iCornerB = iNear;

		bResult = true;
	}

	iNearBefore = iNear;

	return bResult;
}