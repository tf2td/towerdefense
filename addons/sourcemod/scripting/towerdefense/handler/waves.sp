#pragma semicolon 1

#include <sourcemod>

/**
 * Spawns a wave.
 *
 * @noreturn
 */

stock Wave_Spawn() {
	PrintToChatAll("\x04Spawned Wave %d!", g_iCurrentWave + 1);

	decl String:sName[MAX_NAME_LENGTH];
	if (!Wave_GetName(g_iCurrentWave, sName, sizeof(sName))) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to spawn wave %d, could not read name!", g_iCurrentWave);
		return;
	}

	decl String:sClass[32];
	if (!Wave_GetClassString(g_iCurrentWave, sClass, sizeof(sClass))) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to spawn wave %d, could not read class!", g_iCurrentWave);
		return;
	}

	for (new i = 1; i <= Wave_GetQuantity(g_iCurrentWave); i++) {
		ServerCommand("bot -team red -class %s -name %s%d", sClass, sName, i);
	}

	Wave_Teleport();
}

stock Wave_Teleport() {
	Log(TDLogLevel_Info, "Spawned wave %d (%d attackers)", g_iCurrentWave + 1, Wave_GetQuantity(g_iCurrentWave));

	CreateTimer(1.0, TeleportWaveDelay, 1, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TeleportWaveDelay(Handle:hTimer, any:iNumber) {
	if (iNumber > Wave_GetQuantity(g_iCurrentWave)) {
		Log(TDLogLevel_Info, "Teleported wave %d (%d attackers)", g_iCurrentWave + 1, Wave_GetQuantity(g_iCurrentWave));
		return Plugin_Stop;
	}

	decl String:sName[MAX_NAME_LENGTH];
	if (!Wave_GetName(g_iCurrentWave, sName, sizeof(sName))) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to teleport wave %d, could not read name!", g_iCurrentWave);
		return Plugin_Stop;
	}

	Format(sName, sizeof(sName), "%s%d", sName, iNumber);

	new iAttacker = GetClientByNameExact(sName);

	if (IsAttacker(iAttacker)) {
		new Float:fLocation[3];
		if (!Wave_GetLocation(g_iCurrentWave, fLocation)) {
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to teleport wave %d, could not read location!", g_iCurrentWave);
			return Plugin_Stop;
		}

		new Float:fAngles[3];
		if (!Wave_GetAngles(g_iCurrentWave, fAngles)) {
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to teleport wave %d, could not read angles!", g_iCurrentWave);
			return Plugin_Stop;
		}

		TeleportEntity(iAttacker, fLocation, fAngles, Float:{0.0, 0.0, 0.0});

		CreateTimer(1.0, TeleportWaveDelay, iNumber + 1, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

/*======================================
=            Data Functions            =
======================================*/

/**
 * Gets the name of a wave.
 *
 * @param iWave 		The wave.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if wave was not found.
 */

stock Wave_GetName(iWave, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_name", iWave);

	return GetTrieString(g_hMapWaves, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the type of a wave.
 *
 * @param iWave 		The wave.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if wave was not found.
 */

stock Wave_GetTypeString(iWave, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_type", iWave);

	return GetTrieString(g_hMapWaves, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the type of a wave.
 *
 * @param iWave 		The wave.
 * @return				The waves type.
 */

stock TDWaveType:Wave_GetType(iWave) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_type", iWave);

	decl String:sType[32];
	GetTrieString(g_hMapWaves, sKey, sType, sizeof(sType));

	if (StrEqual(sType, "boss")) {
		return TDWaveType_Boss;
	} else if (StrEqual(sType, "rapid")) {
		return TDWaveType_Rapid;
	} else if (StrEqual(sType, "regen")) {
		return TDWaveType_Regen;
	} else if (StrEqual(sType, "knockbackImmune")) {
		return TDWaveType_KnockbackImmune;
	} else if (StrEqual(sType, "air")) {
		return TDWaveType_Air;
	} else if (StrEqual(sType, "jarateImmune")) {
		return TDWaveType_JarateImmune;
	}

	return TDWaveType_None;
}

/**
 * Gets the class of a wave.
 *
 * @param iWave 		The wave.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if wave was not found.
 */

stock bool:Wave_GetClassString(iWave, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", iWave);

	return GetTrieString(g_hMapWaves, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the class of a wave.
 *
 * @param iWave 		The wave.
 * @return				The waves class type, or TFClass_Unknown on error.
 */

stock TFClassType:Wave_GetClass(iWave) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", iWave);

	decl String:sClass[32];
	GetTrieString(g_hMapWaves, sKey, sClass, sizeof(sClass));

	if (StrEqual(sClass, "Scout")) {
		return TFClass_Scout;
	} else if (StrEqual(sClass, "Sniper")) {
		return TFClass_Sniper;
	} else if (StrEqual(sClass, "Soldier")) {
		return TFClass_Soldier;
	} else if (StrEqual(sClass, "Demoman")) {
		return TFClass_DemoMan;
	} else if (StrEqual(sClass, "Medic")) {
		return TFClass_Medic;
	} else if (StrEqual(sClass, "Heavy")) {
		return TFClass_Heavy;
	} else if (StrEqual(sClass, "Pyro")) {
		return TFClass_Pyro;
	} else if (StrEqual(sClass, "Spy")) {
		return TFClass_Spy;
	} else if (StrEqual(sClass, "Spy")) {
		return TFClass_Engineer;
	}

	return TFClass_Unknown;
}

/**
 * Gets the quantity of a wave.
 *
 * @param iWave 		The wave.
 * @return				The waves quantity, or -1 on failure.
 */

stock Wave_GetQuantity(iWave) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_quantity", iWave);
	
	new iQuantity = 0;
	if (!GetTrieValue(g_hMapWaves, sKey, iQuantity)) {
		return -1;
	}

	return iQuantity;
}

/**
 * Gets the health of a wave.
 *
 * @param iWave 		The wave.
 * @return				The waves health, or -1 on failure.
 */

stock Wave_GetHealth(iWave) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_health", iWave);
	
	new iHealth = 0;
	if (!GetTrieValue(g_hMapWaves, sKey, iHealth)) {
		return -1;
	}

	return iHealth;
}

/**
 * Gets the location of a wave.
 *
 * @param iWave 		The wave.
 * @param fLocation 	The location vector.
 * @return				True on success, false if wave was not found.
 */

stock bool:Wave_GetLocation(iWave, Float:fLocation[3]) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", iWave);
	
	decl String:sLocation[64];
	if (GetTrieString(g_hMapWaves, sKey, sLocation, sizeof(sLocation))) {
		decl String:sLocationParts[6][16];
		ExplodeString(sLocation, " ", sLocationParts, sizeof(sLocationParts), sizeof(sLocationParts[]));

		fLocation[0] = StringToFloat(sLocationParts[0]);
		fLocation[1] = StringToFloat(sLocationParts[1]);
		fLocation[2] = StringToFloat(sLocationParts[2]);

		return true;
	}

	return false;
}

/**
 * Gets the angles of a wave.
 *
 * @param iWave 		The wave.
 * @param fAngles 		The angles vector.
 * @return				True on success, false if wave was not found.
 */

stock bool:Wave_GetAngles(iWave, Float:fAngles[3]) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", iWave);
	
	decl String:sAngles[64];
	if (GetTrieString(g_hMapWaves, sKey, sAngles, sizeof(sAngles))) {
		decl String:sAnglesParts[6][16];
		ExplodeString(sAngles, " ", sAnglesParts, sizeof(sAnglesParts), sizeof(sAnglesParts[]));

		fAngles[0] = StringToFloat(sAnglesParts[3]);
		fAngles[1] = StringToFloat(sAnglesParts[4]);
		fAngles[2] = StringToFloat(sAnglesParts[5]);

		return true;
	}

	return false;
}