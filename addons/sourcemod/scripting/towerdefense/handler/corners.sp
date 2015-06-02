#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Checks if an entity is a corner.
 *
 * @param iCorner		The corner.
 * @return				True if valid, false otherwise.
 */

stock bool Corner_IsValid(int iCorner) {
	if (!IsValidEntity(iCorner)) {
		return false;
	}
	
	char sBuffer[64];
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

stock int Corner_FindByName(const char[] sName) {
	int iCorner = -1;
	char sCornerName[64];
	
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

stock int Corner_FindByNextName(const char[] sName) {
	int iCorner = -1;
	char sCornerName[64];
	
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

stock int Corner_GetNumber(int iCorner, bool bValidate = true) {
	if (!bValidate) {
		char sName[64];
		Corner_GetName(iCorner, sName, sizeof(sName), false);
		
		if (!StrEqual(sName, "corner_final")) {
			char sNameParts[2][32];
			ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));
			
			return StringToInt(sNameParts[1]);
		}
	} else if (Corner_IsValid(iCorner)) {
		char sName[64];
		Corner_GetName(iCorner, sName, sizeof(sName), false);
		
		if (!StrEqual(sName, "corner_final")) {
			char sNameParts[2][32];
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

stock bool Corner_GetName(int iCorner, char[] sBuffer, int iMaxLength, bool bValidate = true) {
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

stock bool Corner_GetNextName(int iCorner, char[] sBuffer, int iMaxLength, bool bValidate = true) {
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

stock bool Corner_GetLocation(int iCorner, float fLocation[3], bool bValidate = true) {
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

stock bool Corner_GetAngles(int iCornerA, int iCornerB, float fAngles[3], bool bValidate = true) {
	float fLocationCornerA[3], fLocationCornerB[3], fVector[3];
	
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

stock int Corner_GetNext(int iCorner = -1, const char sName[] = "") {
	char sCornerName[64];
	
	if (StrEqual(sName, "") && Corner_IsValid(iCorner)) {
		Corner_GetName(iCorner, sCornerName, sizeof(sCornerName));
	} else if (!StrEqual(sName, "") && !Corner_IsValid(iCorner)) {
		strcopy(sCornerName, sizeof(sCornerName), sName);
		iCorner = Corner_FindByName(sCornerName);
	} else {
		return -1;
	}
	
	if (StrContains(sCornerName, "corner_") != -1 && !StrEqual(sCornerName, "corner_final")) {
		char sNextName[64];
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

stock void Corner_GetPrevious(int iCorner = -1, const char sName[] = "") {
	char sCornerName[64];
	
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

stock int Corner_GetNearest(int iClient) {
	if (!IsValidClient(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return -1;
	}
	
	float fCornerLocation[3], fClientLocation[3];
	GetClientAbsOrigin(iClient, fClientLocation);
	
	int iCorner = -1, iNearestCorner = -1;
	float fNearestDistance = 2147483647.0, fDistance;
	
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

stock bool Corner_GetBetween(int iClient, int &iCornerA, int &iCornerB, float fEpsilon = 15.0) {
	if (!IsValidClient(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return false;
	}
	
	static int iNearBefore[MAXPLAYERS + 1];
	
	int iNear = Corner_GetNearest(iClient);
	
	float fLocationNear[3], fLocationClient[3];
	Corner_GetLocation(iNear, fLocationNear, false);
	GetClientAbsOrigin(iClient, fLocationClient);
	
	float fVector[3], fAngles[3], fAnglesClient[3];
	MakeVectorFromPoints(fLocationNear, fLocationClient, fVector);
	GetVectorAngles(fVector, fAngles);
	GetClientEyeAngles(iClient, fAnglesClient);
	
	float fAnglesDiff = FloatAbs(fAngles[1] - fAnglesClient[1]);
	
	if (fAnglesDiff != 0.0 && fAnglesDiff != 45.0 && fAnglesDiff != 90.0 && fAnglesDiff != 135.0 && fAnglesDiff != 180.0 && 
		fAnglesDiff != 225.0 && fAnglesDiff != 270.0 && fAnglesDiff != 315.0 && fAnglesDiff != 360.0 && fAnglesDiff > 5.0) {
		
		return false;
	}
	
	int iNumberNearBefore = Corner_GetNumber(iNearBefore[iClient]);
	
	if (iNumberNearBefore != -1 && IsValidEntity(iNear)) {
		int iNumberNear = Corner_GetNumber(iNear);
		
		if (iNumberNear != -1) {
			if (Abs(iNumberNearBefore - iNumberNear) > 1) {
				iNearBefore[iClient] = iNear;
				return false;
			}
		}
	}
	
	int iNext = Corner_GetNext(iNear);
	
	float fLocationNext[3];
	Corner_GetLocation(iNext, fLocationNext);
	
	float fResultA[3], fResultB[3];
	SubtractVectors(fLocationNear, fLocationNext, fResultA);
	SubtractVectors(fLocationClient, fLocationNext, fResultB);
	
	float fScale = GetVectorDotProduct(fResultA, fResultB) / GetVectorDotProduct(fResultA, fResultA);
	ScaleVector(fResultA, fScale);
	
	float fResult[3];
	SubtractVectors(fResultB, fResultA, fResult);
	
	if (FloatAbs(fResult[0]) <= fEpsilon && FloatAbs(fResult[1]) <= fEpsilon) {
		iCornerA = iNear;
		iCornerB = iNext;
		
		iNearBefore[iClient] = iNear;
		return true;
	}
	
	int iPrev = Corner_GetPrevious(iNear);
	
	float fLocationPrev[3];
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