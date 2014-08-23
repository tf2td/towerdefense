#pragma semicolon 1

#include <sourcemod>

/**
 * Gets a clients current metal amount.
 *
 * @param iClient		The client.
 * @return				The clients current metal.
 */

stock GetClientMetal(iClient) {
	return GetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (3 * 4), 4);
}

/**
 * Sets a clients metal amount.
 *
 * @param iClient		The client.
 * @param iMetal		The metal amount the client should get.
 * @noreturn
 */

stock SetClientMetal(iClient, iMetal) {
	SetEntData(iClient, FindDataMapOffs(iClient, "m_iAmmo") + (3 * 4), iMetal, 4);

	Log(TDLogLevel_Trace, "Set %N's metal to %d", iClient, iMetal);
}

/**
 * Resets a clients metal amount back to zero.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock ResetClientMetal(iClient) {
	CreateTimer(0.0, ResetClientMetalDelayed, iClient, TIMER_FLAG_NO_MAPCHANGE); // Process next frame
}

public Action:ResetClientMetalDelayed(Handle:hTimer, any:iClient) {
	SetClientMetal(iClient, 0);

	return Plugin_Stop;
}

/**
 * Add a amount to the clients metal amount.
 *
 * @param iClient		The client.
 * @param iMetal		The metal amount to add.
 * @return				True if amount could be added, false otherwise.
 */

stock bool:AddClientMetal(iClient, iMetal) {
	if (iMetal < 0) {
		if (GetClientMetal(iClient) + iMetal >= 0) {
			SetClientMetal(iClient, GetClientMetal(iClient) + iMetal);
			return true;
		} else {
			return false;
		}
	}
	
	SetClientMetal(iClient, GetClientMetal(iClient) + iMetal);
	return true;
}

/**
 * Spawns a metal pack.
 *
 * @param iMetalPackType	The metal pack type.
 * @param fLocation			The location it should spawn at.
 * @param iMetal			The amount of metal it should spawn with.
 * @return					A TDMetalPackReturn value.
 */

stock TDMetalPackReturn:SpawnMetalPack(TDMetalPackType:iMetalPackType, Float:fLocation[3], iMetal) {
	if (iMetal <= 0) {
		return TDMetalPack_InvalidMetal;
	}

	if (g_iMetalPackCount >= METALPACK_LIMIT) {
		return TDMetalPack_LimitReached;
	}

	decl String:sModelPath[PLATFORM_MAX_PATH];

	switch (iMetalPackType) {
		case TDMetalPack_Small: {
			strcopy(sModelPath, sizeof(sModelPath), "models/items/ammopack_small.mdl");
		}
		case TDMetalPack_Medium: {
			strcopy(sModelPath, sizeof(sModelPath), "models/items/ammopack_medium.mdl");
		}
		case TDMetalPack_Large: {
			strcopy(sModelPath, sizeof(sModelPath), "models/items/ammopack_large.mdl");
		}
		default: {
			return TDMetalPack_InvalidType;
		}
	}

	new iMetalPack = CreateEntityByName("prop_dynamic");

	DispatchKeyValue(iMetalPack, "model", sModelPath);

	decl String:sMetal[32];
	IntToString(iMetal, sMetal, sizeof(sMetal));

	DispatchKeyValue(iMetalPack, "targetname", sMetal);

	if (DispatchSpawn(iMetalPack)) {
		// Make it not solid, but still "collideable"
		SetEntProp(iMetalPack, Prop_Send, "m_usSolidFlags", 0x0008|0x0010); // FSOLID_TRIGGER|FSOLID_NOT_STANDABLE
		SetEntProp(iMetalPack, Prop_Data, "m_nSolidType", 6); // SOLID_VPHYSICS
		SetEntProp(iMetalPack, Prop_Data, "m_CollisionGroup", 2); // COLLISION_GROUP_DEBRIS_TRIGGER

		SetVariantString("idle");
		AcceptEntityInput(iMetalPack, "SetAnimation");
		
		TeleportEntity(iMetalPack, fLocation, NULL_VECTOR, NULL_VECTOR);

		SDKHook(iMetalPack, SDKHook_Touch, OnMetalPackPickup);

		g_iMetalPackCount++;
	}

	Log(TDLogLevel_Debug, "Spawned metal pack (%d, Metal: %d)", iMetalPack, iMetal);

	return TDMetalPack_SpawnedPack;
}

public OnMetalPackPickup(iMetalPack, iClient) {
	if (!IsDefender(iClient) || !IsValidEntity(iMetalPack)) {
		return;
	}

	decl String:sMetal[32];
	GetEntPropString(iMetalPack, Prop_Data, "m_iName", sMetal, sizeof(sMetal));

	new iMetal = StringToInt(sMetal);

	AddClientMetal(iClient, iMetal);
	EmitSoundToClient(iClient, "items/gunpickup2.wav");

	AcceptEntityInput(iMetalPack, "Kill");

	g_iMetalPackCount--;
}