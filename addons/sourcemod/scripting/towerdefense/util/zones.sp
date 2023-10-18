#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Creates a beam line.
 *
 * @param iClient		The client.
 * @param fStart		The start point.
 * @param fEnd			The end point.
 * @param fDuration		The duration it should appear (in seconds).
 * @param iColors		The colors.
 * @noreturn
 */

stock void CreateBeamLine(int iClient, float fStart[3], float fEnd[3], float fDuration = 5.0, const int[] iColors =  { 255, 0, 0, 255 } ) {
	int iColors2[4];
	iColors2[0] = iColors[0];
	iColors2[1] = iColors[1];
	iColors2[2] = iColors[2];
	iColors2[3] = iColors[3];
	
	TE_SetupBeamPoints(fStart, fEnd, g_iLaserMaterial, g_iHaloMaterial, 0, 0, fDuration + 0.1, 1.0, 1.0, 1, 0.0, iColors2, 0);
	
	if (fDuration == 0.0) {
		DataPack hPack = new DataPack();
		
		CreateDataTimer(fDuration, Timer_CreateBeam, hPack);
		
		hPack.WriteCell(iClient);
		hPack.WriteFloat(fDuration);
		hPack.WriteFloat(fStart[0]);
		hPack.WriteFloat(fStart[1]);
		hPack.WriteFloat(fStart[2]);
		hPack.WriteFloat(fEnd[0]);
		hPack.WriteFloat(fEnd[1]);
		hPack.WriteFloat(fEnd[2]);
		hPack.WriteCell(iColors[0]);
		hPack.WriteCell(iColors[1]);
		hPack.WriteCell(iColors[2]);
		hPack.WriteCell(iColors[3]);
	}
	
	TE_SendToAll();
}

public Action Timer_CreateBeam(Handle hTimer, DataPack hPack) {
	int iClient, iColors[4];
	float fDuration, fStart[3], fEnd[3];
	
	hPack.Reset();
	iClient = hPack.ReadCell();
	fDuration = hPack.ReadFloat();
	fStart[0] = hPack.ReadFloat();
	fStart[1] = hPack.ReadFloat();
	fStart[2] = hPack.ReadFloat();
	fEnd[0] = hPack.ReadFloat();
	fEnd[1] = hPack.ReadFloat();
	fEnd[2] = hPack.ReadFloat();
	iColors[0] = hPack.ReadCell();
	iColors[1] = hPack.ReadCell();
	iColors[2] = hPack.ReadCell();
	iColors[3] = hPack.ReadCell();
	
	CreateBeamLine(iClient, fStart, fEnd, fDuration, iColors);
	
	return Plugin_Stop;
}

/**
 * Creates a beam box.
 *
 * @param iClient		The client.
 * @param fStart		The start point.
 * @param fEnd			The end point.
 * @param fDuration		The duration it should appear (in seconds).
 * @param iColors		The colors.
 * @noreturn
 */

stock void CreateBeamBox(int iClient, float fStart[3], float fEnd[3], float fDuration = 5.0, const int[] iColors =  { 255, 0, 0, 255 } ) {
	float fPoint[8][3];
	
	CopyVector(fStart, fPoint[0]);
	CopyVector(fEnd, fPoint[7]);
	
	CreateZonePoints(fPoint);
	
	for (int i = 0, i2 = 3; i2 >= 0; i += i2--) {
		for (int j = 1; j <= 7; j += (j / 2) + 1) {
			if (j != 7 - i) {
				CreateBeamLine(iClient, fPoint[i], fPoint[j], fDuration, iColors);
			}
		}
	}
}

/**
 * Creates all 8 zone points by using start and end point.
 *
 * @param fPoint		The array to store the points in.
 * @noreturn
 */

stock void CreateZonePoints(float fPoint[8][3]) {
	for (int i = 1; i < 7; i++) {
		for (int j = 0; j < 3; j++) {
			fPoint[i][j] = fPoint[((i >> (2 - j)) & 1) * 7][j];
		}
	}
}

/**
 * Creates all an beam box around a client.
 *
 * @param iClient		The client.
 * @param fStart		The start point.
 * @param fEnd			The end point.
 * @param fDuration		The duration it should appear (in seconds).
 * @param iColors		The colors.
 * @noreturn
 */

stock void CreateBeamBoxAroundClient(int iClient, float fDistance, bool OnlyPlayerHeight = true, float fDuration = 5.0, const int[] iColors =  { 255, 0, 0, 255 } ) {
	if (!IsValidClient(iClient) || !IsClientConnected(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return;
	}
	
	float fLocation[3], fStart[3], fEnd[3];
	
	GetClientAbsOrigin(iClient, fLocation);
	
	if (OnlyPlayerHeight) {
		fStart[0] = fLocation[0] - fDistance;
		fStart[1] = fLocation[1] - fDistance;
		fStart[2] = fLocation[2];
		
		fEnd[0] = fLocation[0] + fDistance;
		fEnd[1] = fLocation[1] + fDistance;
		fEnd[2] = fLocation[2] + 83;
	} else {
		fStart[0] = fLocation[0] - fDistance;
		fStart[1] = fLocation[1] - fDistance;
		fStart[2] = fLocation[2] - fDistance;
		
		fEnd[0] = fLocation[0] + fDistance;
		fEnd[1] = fLocation[1] + fDistance;
		fEnd[2] = fLocation[2] + 83 + fDistance;
	}
	
	CreateBeamBox(iClient, fStart, fEnd, fDuration, iColors);
	
	float fPoint[8][3];
	
	CopyVector(fStart, fPoint[0]);
	CopyVector(fEnd, fPoint[7]);
	
	CreateZonePoints(fPoint);
	
	CopyZone(fPoint, g_fBeamPoints[iClient]);
}

/**
 * Copies one float vector onto another one.
 *
 * @param fSource			The vector to copy.
 * @param fDestination		The destination vector.
 * @noreturn
 */

stock void CopyVector(float fSource[3], float fDestination[3]) {
	for (int i = 0; i < sizeof(fSource); i++) {
		fDestination[i] = fSource[i];
	}
}

/**
 * Copies one zone array onto another one.
 *
 * @param fSource			The array to copy.
 * @param fDestination		The destination array.
 * @noreturn
 */

stock void CopyZone(float fSource[8][3], float fDestination[8][3]) {
	for (int i = 0; i < sizeof(fSource); i++) {
		for (int j = 0; j < sizeof(fSource[]); j++) {
			fDestination[i][j] = fSource[i][j];
		}
	}
}

/**
 * Checkes if an entity is inside a zone.
 *
 * @param iClient		The entity.
 * @param fZone			The zone array.
 * @return				True if inside, false otherwise.
 */

stock bool IsEntityInZone(int iEntity, float fZone[8][3], float fDifferenceZ) {
	float fEntityPosition[3];
	
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPosition);
	fEntityPosition[2] += fDifferenceZ;
	
	return IsPointInZone(fEntityPosition, fZone);
}

/**
 * Checkes if a client is inside a zone.
 *
 * @param iClient		The client.
 * @param fPoint		The zone array.
 * @return				True if inside, false otherwise.
 */

stock bool IsClientInZone(int iClient, float fPoint[8][3]) {
	float fPlayerPosition[3], fPlayerPoint[8][3];
	
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPlayerPosition);
	fPlayerPosition[2] += 41.5;
	
	fPlayerPoint[0][0] = fPlayerPosition[0] - 12.0;
	fPlayerPoint[0][1] = fPlayerPosition[1] - 12.0;
	fPlayerPoint[0][2] = fPlayerPosition[2] - 20.0;
	fPlayerPoint[7][0] = fPlayerPosition[0] + 12.0;
	fPlayerPoint[7][1] = fPlayerPosition[1] + 12.0;
	fPlayerPoint[7][2] = fPlayerPosition[2] + 20.0;
	
	CreateZonePoints(fPlayerPoint);
	
	return Box3DIntersects(fPlayerPoint, fPoint);
}

/**
 * Draws a bounding box around a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock void DrawClientBoundingBox(int iClient) {
	float fPlayerPosition[3], fPlayerPoint[8][3];
	
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPlayerPosition);
	fPlayerPosition[2] += 41.5;
	
	fPlayerPoint[0][0] = fPlayerPosition[0] - 12.0;
	fPlayerPoint[0][1] = fPlayerPosition[1] - 12.0;
	fPlayerPoint[0][2] = fPlayerPosition[2] - 20.0;
	fPlayerPoint[7][0] = fPlayerPosition[0] + 12.0;
	fPlayerPoint[7][1] = fPlayerPosition[1] + 12.0;
	fPlayerPoint[7][2] = fPlayerPosition[2] + 20.0;
	
	CreateZonePoints(fPlayerPoint);
	
	CreateBeamBox(iClient, fPlayerPoint[0], fPlayerPoint[7]);
}

/**
 * Checkes if a zone intersects with another zone.
 *
 * @param fCheck		The 1st zone array.
 * @param fSource		The 2nd zone array.
 * @return				True if intersects, false otherwise.
 */

stock bool Box3DIntersects(float fCheck[8][3], float fSource[8][3]) {
	if (fCheck[0][0] > fSource[4][0] ||  // fCheck is right of fSource
		fCheck[4][0] < fSource[0][0] ||  // fCheck is left of fSource
		fCheck[1][2] < fSource[0][2] ||  // fCheck is below fSource
		fCheck[0][2] > fSource[1][2] ||  // fCheck is above fSource
		fCheck[3][1] < fSource[1][1] ||  // fCheck is behind fSource
		fCheck[1][1] > fSource[3][1]) {  // fCheck is in front fSource
		return false;
	}
	
	return true;
}

/**
 * Checkes if a point is inside a zone.
 *
 * @param fPoint		The point vector.
 * @param fZone			The zone array.
 * @return				True if inside, false otherwise.
 */

stock bool IsPointInZone(float fPoint[3], float fZone[8][3]) {
	if (fPoint[0] > fZone[4][0] ||  // fPoint is right of fZone
		fPoint[0] < fZone[0][0] ||  // fPoint is left of fZone
		fPoint[2] < fZone[0][2] ||  // fPoint is below fZone
		fPoint[2] > fZone[1][2] ||  // fPoint is above fZone
		fPoint[1] < fZone[1][1] ||  // fPoint is behind fZone
		fPoint[1] > fZone[3][1]) {  // fPoint is in front fZone
		return false;
	}
	
	return true;
} 