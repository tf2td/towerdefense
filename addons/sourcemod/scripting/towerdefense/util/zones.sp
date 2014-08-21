#pragma semicolon 1

#include <sourcemod>

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

stock CreateBeamLine(iClient, Float:fStart[3], Float:fEnd[3], Float:fDuration=5.0, const iColors[]={255, 0, 0, 255}) {
	new iColors2[4];
	iColors2[0] = iColors[0];
	iColors2[1] = iColors[1];
	iColors2[2] = iColors[2];
	iColors2[3] = iColors[3];
	
	TE_SetupBeamPoints(fStart, fEnd, g_iLaserMaterial, g_iHaloMaterial, 0, 0, fDuration + 0.1, 1.0, 1.0, 1, 0.0, iColors2, 0);

	if (fDuration == 0.0) {
		new Handle:hPack = CreateDataPack();

		CreateDataTimer(fDuration, Timer_CreateBeam, hPack);

		WritePackCell(hPack, iClient);
		WritePackFloat(hPack, fDuration);
		WritePackFloat(hPack, fStart[0]);
		WritePackFloat(hPack, fStart[1]);
		WritePackFloat(hPack, fStart[2]);
		WritePackFloat(hPack, fEnd[0]);
		WritePackFloat(hPack, fEnd[1]);
		WritePackFloat(hPack, fEnd[2]);
		WritePackCell(hPack, iColors[0]);
		WritePackCell(hPack, iColors[1]);
		WritePackCell(hPack, iColors[2]);
		WritePackCell(hPack, iColors[3]);
	}

	TE_SendToAll();
}

public Action:Timer_CreateBeam(Handle:hTimer, Handle:hPack) {
	new iClient, Float:fDuration, Float:fStart[3], Float:fEnd[3], iColors[4];
	
	ResetPack(hPack);
	iClient = ReadPackCell(hPack);
	fDuration = ReadPackFloat(hPack);
	fStart[0] = ReadPackFloat(hPack);
	fStart[1] = ReadPackFloat(hPack);
	fStart[2] = ReadPackFloat(hPack);
	fEnd[0] = ReadPackFloat(hPack);
	fEnd[1] = ReadPackFloat(hPack);
	fEnd[2] = ReadPackFloat(hPack);
	iColors[0] = ReadPackCell(hPack);
	iColors[1] = ReadPackCell(hPack);
	iColors[2] = ReadPackCell(hPack);
	iColors[3] = ReadPackCell(hPack);
	
	CreateBeamLine(iClient, fStart, fEnd, fDuration, iColors);

	return Plugin_Stop;
}

/**
 * Creates a beam line.
 *
 * @param iClient		The client.
 * @param fStart		The start point.
 * @param fEnd			The end point.
 * @param iColors		The colors.
 * @noreturn
 */

stock CreateBeamLine2(iClient, iIndex, Float:fStart[3], Float:fEnd[3], const iColors[]={255, 0, 0, 255}) {
	new iColors2[4];
	iColors2[0] = iColors[0];
	iColors2[1] = iColors[1];
	iColors2[2] = iColors[2];
	iColors2[3] = iColors[3];
	
	TE_SetupBeamPoints(fStart, fEnd, g_iLaserMaterial, g_iHaloMaterial, 0, 0, 0.6, 1.0, 1.0, 1, 0.0, iColors2, 0);

	if (g_bMetalPackID[iIndex]) {
		new Handle:hPack = CreateDataPack();

		CreateDataTimer(0.5, Timer_CreateBeam2, hPack);

		WritePackCell(hPack, iClient);
		WritePackCell(hPack, iIndex);
		WritePackFloat(hPack, fStart[0]);
		WritePackFloat(hPack, fStart[1]);
		WritePackFloat(hPack, fStart[2]);
		WritePackFloat(hPack, fEnd[0]);
		WritePackFloat(hPack, fEnd[1]);
		WritePackFloat(hPack, fEnd[2]);
		WritePackCell(hPack, iColors[0]);
		WritePackCell(hPack, iColors[1]);
		WritePackCell(hPack, iColors[2]);
		WritePackCell(hPack, iColors[3]);
	}

	TE_SendToAll();
}

public Action:Timer_CreateBeam2(Handle:hTimer, Handle:hPack) {
	new iClient, iIndex, Float:fStart[3], Float:fEnd[3], iColors[4];
	
	ResetPack(hPack);
	iClient = ReadPackCell(hPack);
	iIndex = ReadPackCell(hPack);
	fStart[0] = ReadPackFloat(hPack);
	fStart[1] = ReadPackFloat(hPack);
	fStart[2] = ReadPackFloat(hPack);
	fEnd[0] = ReadPackFloat(hPack);
	fEnd[1] = ReadPackFloat(hPack);
	fEnd[2] = ReadPackFloat(hPack);
	iColors[0] = ReadPackCell(hPack);
	iColors[1] = ReadPackCell(hPack);
	iColors[2] = ReadPackCell(hPack);
	iColors[3] = ReadPackCell(hPack);
	
	CreateBeamLine2(iClient, iIndex, fStart, fEnd, iColors);

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

stock CreateBeamBox(iClient, Float:fStart[3], Float:fEnd[3], Float:fDuration=5.0, const iColors[]={255, 0, 0, 255}) {
	new Float:fPoint[8][3];

	CopyVector(fStart, fPoint[0]);
	CopyVector(fEnd, fPoint[7]);

	CreateZonePoints(fPoint);

	for (new i = 0, i2 = 3; i2 >= 0; i += i2--) {
		for (new j = 1; j <= 7; j += (j / 2) + 1) {
			if (j != 7 - i) {
				CreateBeamLine(iClient, fPoint[i], fPoint[j], fDuration, iColors);
			}
		}
	}
}

/**
 * Creates a beam box.
 *
 * @param iClient		The client.
 * @param iIndex		The unique id index.
 * @param fStart		The start point.
 * @param fEnd			The end point.
 * @param fDuration		The duration it should appear (in seconds).
 * @param iColors		The colors.
 * @noreturn
 */

/*
stock CreateBeamBox2(iClient, iIndex, Float:fStart[3], Float:fEnd[3], const iColors[]={255, 0, 0, 255}) {
	new Float:fPoint[8][3];

	CopyVector(fStart, fPoint[0]);
	CopyVector(fEnd, fPoint[7]);

	CreateZonePoints(fPoint);

	g_bMetalPackID[iIndex] = true;

	for (new i = 0, i2 = 3; i2 >= 0; i += i2--) {
		for (new j = 1; j <= 7; j += (j / 2) + 1) {
			if (j != 7 - i) {
				CreateBeamLine2(iClient, iIndex, fPoint[i], fPoint[j], iColors);
			}
		}
	}
}
*/

/**
 * Creates all 8 zone points by using start and end point.
 *
 * @param fPoint		The array to store the points in.
 * @noreturn
 */

stock CreateZonePoints(Float:fPoint[8][3]) {
	for (new i = 1; i < 7; i++) {
		for (new j = 0; j < 3; j++) {
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

stock CreateBeamBoxAroundClient(iClient, Float:fDistance, bool:OnlyPlayerHeight=true, Float:fDuration=5.0, const iColors[]={255, 0, 0, 255}) {
	if (!IsValidClient(iClient) || !IsClientConnected(iClient) || !IsClientInGame(iClient) || !IsPlayerAlive(iClient)) {
		return;
	}
	
	new Float:fLocation[3], Float:fStart[3], Float:fEnd[3];

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

	new Float:fPoint[8][3];

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

stock CopyVector(Float:fSource[3], Float:fDestination[3]) {
	for (new i = 0; i < sizeof(fSource); i++) {
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

stock CopyZone(Float:fSource[8][3], Float:fDestination[8][3]) {
	for (new i = 0; i < sizeof(fSource); i++) {
		for (new j = 0; j < sizeof(fSource[]); j++) {
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

stock bool:IsEntityInZone(iEntity, Float:fZone[8][3], Float:fDifferenceZ) {
	new Float:fEntityPosition[3];
	
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

stock bool:IsClientInZone(iClient, Float:fPoint[8][3]) {
	new Float:fPlayerPosition[3], Float:fPlayerPoint[8][3];
	
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
 * Checkes if a client is inside a zone.
 *
 * @param iClient		The client.
 * @param fPoint		The zone array.
 * @param iID			The unique id.
 * @return				True if inside, false otherwise.
 */

stock bool:IsClientInZone2(iClient, Float:fPoint[8][3], iID) {
	new Float:fPlayerPosition[3], Float:fPlayerPoint[8][3];
	
	GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", fPlayerPosition);
	fPlayerPosition[2] += 41.5;

	fPlayerPoint[0][0] = fPlayerPosition[0] - 12.0;
	fPlayerPoint[0][1] = fPlayerPosition[1] - 12.0;
	fPlayerPoint[0][2] = fPlayerPosition[2] - 20.0;
	fPlayerPoint[7][0] = fPlayerPosition[0] + 12.0;
	fPlayerPoint[7][1] = fPlayerPosition[1] + 12.0;
	fPlayerPoint[7][2] = fPlayerPosition[2] + 20.0;

	CreateZonePoints(fPlayerPoint);

	return (Box3DIntersects(fPlayerPoint, fPoint) && g_bMetalPackID[iID]);
}

/**
 * Draws a bounding box around a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock DrawClientBoundingBox(iClient) {
	new Float:fPlayerPosition[3], Float:fPlayerPoint[8][3];
	
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

stock bool:Box3DIntersects(Float:fCheck[8][3], Float:fSource[8][3]) {
	if (fCheck[0][0] > fSource[4][0] || 	// fCheck is right of fSource
		fCheck[4][0] < fSource[0][0] ||		// fCheck is left of fSource
		fCheck[1][2] < fSource[0][2] || 	// fCheck is below fSource
		fCheck[0][2] > fSource[1][2] ||		// fCheck is above fSource
		fCheck[3][1] < fSource[1][1] || 	// fCheck is behind fSource
		fCheck[1][1] > fSource[3][1]) {		// fCheck is in front fSource
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

stock bool:IsPointInZone(Float:fPoint[3], Float:fZone[8][3]) {
	if (fPoint[0] > fZone[4][0] || 		// fPoint is right of fZone
		fPoint[0] < fZone[0][0] ||		// fPoint is left of fZone
		fPoint[2] < fZone[0][2] || 		// fPoint is below fZone
		fPoint[2] > fZone[1][2] ||		// fPoint is above fZone
		fPoint[1] < fZone[1][1] || 		// fPoint is behind fZone
		fPoint[1] > fZone[3][1]) {		// fPoint is in front fZone
		return false;
	}

	return true;
}