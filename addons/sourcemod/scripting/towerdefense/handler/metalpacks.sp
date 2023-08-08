#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Spawns all metalpacks (except the boss and reward metalpack).
 *
 * @param iMetalPackType	The metal pack type.
 * @return					True on success, false otherwiseherwise.
 */

stock bool SpawnMetalPacks(TDMetalPackType iMetalPackType) {
	int iNumPacks = 0;
	if (!GetTrieValue(g_hMapMetalpacks, "quantity", iNumPacks)) {
		return false;
	}
	
	if (iNumPacks <= 0) {
		return true;
	}
	
	int iMetal = 0, iEntity;
	float fLocation[3];
	char sKey[32], sLocation[64], sLocationParts[6][16];
	
	for (int iMetalPackId = 0; iMetalPackId < iNumPacks; iMetalPackId++) {
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

/**
 * Spawns certain amount of metalpacks.
 *
 * @param iMetalPackType	The metal pack type.
 * @param iNumPacks			Amount of metalpacks
 * @return					True on success, false otherwiseherwise.
 */

stock void SpawnMetalPacksNumber(TDMetalPackType iMetalPackType, int iNumPacks) {
	
	int iMetal = 0, iEntity;
	float fLocation[3];
	char sKey[32], sLocation[64], sLocationParts[6][16];
	
	for (int iMetalPackId = 0; iMetalPackId < iNumPacks; iMetalPackId++) {
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
		ShowAnnotation(EntRefToEntIndex(iEntity), fLocation, 64.0, 5.0, "A Metalpack spawned!");
	}
}

/**
 * Spawns reward metal pack.
 *
 * @param iMetalPackType	The type of metal pack.
 * @param fLocation			The location to place the metal pack.
 * @param iMetal			The ammount of metal to spawn.
 * @noreturn
 */

stock void SpawnRewardPack(TDMetalPackSpawnType iMetalPackType, float fLocation[3], int iMetal) {
	int iEntity;
	SpawnMetalPack2(iMetalPackType, fLocation, iMetal, iEntity);
	
	// Dirty hack to add outlines to the ammo packs
	int PackRef = EntRefToEntIndex(iEntity);
	int dispenser = CreateEntityByName("obj_dispenser");
			
	DispatchKeyValue(dispenser, "spawnflags", "2");
	DispatchKeyValue(dispenser, "solid", "0");
	DispatchKeyValue(dispenser, "teamnum", "3");
	
	SetEntProp(dispenser, Prop_Send, "m_usSolidFlags", 12); // FSOLID_TRIGGER|FSOLID_NOT_SOLID
	SetEntProp(dispenser, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
	SetEntProp(dispenser, Prop_Data, "m_CollisionGroup", 1); //COLLISION_GROUP_DEBRIS 
	
	char model[PLATFORM_MAX_PATH];
	float pos[3], ang[3];
	
	GetEntPropString(PackRef, Prop_Data, "m_ModelName", model, sizeof(model));
	GetEntPropVector(PackRef, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(PackRef, Prop_Send, "m_angRotation", ang);
	SetEntProp(dispenser, Prop_Send, "m_bGlowEnabled", 1);
	
	TeleportEntity(dispenser, pos, ang, NULL_VECTOR);
	DispatchSpawn(dispenser);
	SetEntityModel(dispenser, model);
	SetVariantString("!activator");
	AcceptEntityInput(dispenser, "SetParent", PackRef);
	
	SDKHook(dispenser, SDKHook_OnTakeDamage, OnTakeDamage_Dispenser);
}

public Action OnTakeDamage_Dispenser(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	return Plugin_Stop;
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

stock TDMetalPackType Metalpack_GetType(int iMetalpackId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_type", iMetalpackId);
	
	char sType[64];
	GetTrieString(g_hMapMetalpacks, sKey, sType, sizeof(sType));
	
	if (StrEqual(sType, "start")) {
		return TDMetalPack_Start;
	} else if (StrEqual(sType, "boss")) {
		return TDMetalPack_Boss;
	}
	
	return TDMetalPack_Invalid;
} 