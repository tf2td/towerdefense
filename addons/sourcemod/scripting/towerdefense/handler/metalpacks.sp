#pragma semicolon 1

#include <sourcemod>

/**
 * Spawns all metalpacks (except the boss metalpack).
 *
 * @param iMetalPackType	The metal pack type.
 * @return					True on success, false ontherwise.
 */

stock bool:SpawnMetalPacks(TDMetalPackType:iMetalPackType) {
	new iNumPacks = 0;
	if (!GetTrieValue(g_hMapMetalpacks, "quantity", iNumPacks)) {
		return false;
	}

	if (iNumPacks <= 0) {
		return true;
	}

	new iMetal = 0, iEntity, Float:fLocation[3];
	decl String:sKey[32], String:sLocation[64], String:sLocationParts[6][16];

	for (new iMetalPackId = 0; iMetalPackId < iNumPacks; iMetalPackId++) {
		if (Metalpack_GetType(iMetalPackId) != iMetalPackType) {
			continue;
		}

		Format(sKey, sizeof(sKey), "%d_metal", iMetalPackId);

		if (!GetTrieValue(g_hMapMetalpacks, sKey, iMetal)) {
			continue;
		}

		Format(sKey, sizeof(sKey), "%d_location", iMetalPackId);

		if (!GetTrieString(g_hMapMetalpacks, sKey, sLocation, sizeof(sLocation))) {
			continue;
		}

		ExplodeString(sLocation, " ", sLocationParts, sizeof(sLocationParts), sizeof(sLocationParts[]));

		fLocation[0] = StringToFloat(sLocationParts[0]);
		fLocation[1] = StringToFloat(sLocationParts[1]);
		fLocation[2] = StringToFloat(sLocationParts[2]);

		SpawnMetalPack2(TDMetalPack_Large, fLocation, iMetal, iEntity);

		if (Metalpack_GetType(iMetalPackId) == TDMetalPack_Boss) {
			ShowAnnotation(EntRefToEntIndex(iEntity), fLocation, 64.0, 60.0, "A reward spawned!");
		}
	}

	return false;
}

/*======================================
=            Data Functions            =
======================================*/

/**
 * Gets a metalpacks type.
 *
 * @param iMetalpackId		The metalpacks id.
 * @return					A TDMetalPackType value.
 */

stock TDMetalPackType:Metalpack_GetType(iMetalpackId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_type", iMetalpackId);

	decl String:sType[64];
	GetTrieString(g_hMapMetalpacks, sKey, sType, sizeof(sType));

	if (StrEqual(sType, "start")) {
		return TDMetalPack_Start;
	} else if (StrEqual(sType, "boss")) {
		return TDMetalPack_Boss;
	}

	return TDMetalPack_Invalid;
}