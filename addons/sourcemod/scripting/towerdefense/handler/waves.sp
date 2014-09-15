#pragma semicolon 1

#include <sourcemod>

/**
 * Called when the start button is being shot.
 *
 * @param iWave			The incoming wave.
 * @param iButton		The button entity.
 * @param iActivator	The activator entity.
 * @noreturn
 */

stock Wave_OnButtonStart(iWave, iButton, iActivator) {
	if (!g_bEnabled) {
		return;
	}

	if (!IsDefender(iActivator)) {
		return;
	}

	decl String:sName[64];
	Format(sName, sizeof(sName), "wave_start_%d", iWave + 1);
	DispatchKeyValue(iButton, "targetname", sName);

	TeleportEntity(iButton, Float:{0.0, 0.0, -9192.0}, NULL_VECTOR, Float:{0.0, 0.0, 0.0});

	PrintToChatAll("%N started \x04Wave %d", iActivator, iWave + 1);

	if (iWave == 0) {
		Timer_NextWaveCountdown(INVALID_HANDLE, 5);
	} else {
		g_bStartWaveEarly = true;
		Wave_Spawn();
	}
}

/**
 * Called when an attacker spawned.
 *
 * @param iAttacker		The attacker.
 * @noreturn
 */

stock Wave_OnSpawn(iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	SetRobotModel(iAttacker);
}

/**
 * Called the frame after an attacker spawned.
 *
 * @param iAttacker		The attacker.
 * @noreturn
 */

public Wave_OnSpawnPost(any:iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	new iMaxHealth = GetEntProp(iAttacker, Prop_Data, "m_iMaxHealth");
	new iWaveHealth = Wave_GetHealth(g_iCurrentWave);

	TF2Attrib_SetByName(iAttacker, "max health additive bonus", float(iWaveHealth - iMaxHealth));
	SetEntityHealth(iAttacker, iWaveHealth);
}

/**
 * Called the frame after an attacker gets damaged.
 *
 * @param iVictim		The victim.
 * @param iAttacker		The attacker.
 * @param iInflictor	The inflictor.
 * @param fDamage		The damage.
 * @param iDamageType	The damage type.
 * @noreturn
 */

stock Wave_OnTakeDamagePost(iVictim, iAttacker, iInflictor, Float:fDamage, iDamageType) {
	if (!g_bEnabled) {
		return;
	}

	new iHealthBar = EntRefToEntIndex(g_iHealthBar);
	if (IsValidEntity(iHealthBar)) {
		new iTotalHealth = 0;

		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsAttacker(iClient)) {
				iTotalHealth += GetEntProp(iClient, Prop_Data, "m_iHealth");
			}
		}

		new iTotalHealthMax = Wave_GetHealth(g_iCurrentWave) * Wave_GetQuantity(g_iCurrentWave);
		new Float:fPercentage = float(iTotalHealth) / float(iTotalHealthMax);

		SetEntProp(iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", RoundToFloor(fPercentage * 255));
	}
}

/**
 * Called when an attacker dies.
 *
 * @param iAttacker		The attacker.
 * @noreturn
 */

stock Wave_OnDeath(iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	CreateTimer(1.0, Delay_KickAttacker, iAttacker, TIMER_FLAG_NO_MAPCHANGE);

	if (GetAliveAttackerCount() <= 1) {
		Wave_OnDeathAll();
	}
}

/**
 * Called when all attackers died.
 *
 * @noreturn
 */

stock Wave_OnDeathAll() {
	if (!g_bEnabled) {
		return;
	}

	g_bStartWaveEarly = false;

	g_iCurrentWave++;

	TeleportEntity(g_iWaveStartButton, g_fWaveStartButtonLocation, NULL_VECTOR, Float:{0.0, 0.0, 0.0});

	Timer_NextWaveCountdown(INVALID_HANDLE, g_iRespawnWaveTime);

	PrintToChatAll("\x04*** Passed wave %d ***", g_iCurrentWave);
	PrintToChatAll("\x01You have \x04%d seconds\x01 to prepare for the next wave!", g_iRespawnWaveTime);

	Log(TDLogLevel_Info, "Passed wave %d", g_iCurrentWave);
}

/**
 * Called when an attacker touches a corner.
 *
 * @param iCorner		The corner trigger entity.
 * @param iAttacker		The attacker.
 * @noreturn
 */

public Wave_OnTouchCorner(iCorner, iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	if (IsAttacker(iAttacker)) {
		decl String:sCornerName[64];
		GetEntPropString(iCorner, Prop_Data, "m_iName", sCornerName, sizeof(sCornerName));

		if (StrContains(sCornerName, "corner_") != -1 && !StrEqual(sCornerName, "corner_final")) {
			decl String:sCornerParentName[64];
			GetEntPropString(iCorner, Prop_Data, "m_iParent", sCornerParentName, sizeof(sCornerParentName));

			new iNextCorner = -1;
			decl String:sNextCornerName[64];

			while ((iNextCorner = FindEntityByClassname(iNextCorner, "trigger_multiple")) != -1) {
				GetEntPropString(iNextCorner, Prop_Data, "m_iName", sNextCornerName, sizeof(sNextCornerName));

				if (StrEqual(sCornerParentName, sNextCornerName)) {
					break;
				}
			}

			if (IsValidEntity(iNextCorner)) {
				new Float:fLocation[3], Float:fNextLocation[3];

				GetEntPropVector(iCorner, Prop_Data, "m_vecAbsOrigin", fLocation);
				GetEntPropVector(iNextCorner, Prop_Data, "m_vecAbsOrigin", fNextLocation);
				
				new Float:fVector[3], Float:fAngles[3];
				MakeVectorFromPoints(fLocation, fNextLocation, fVector);
				GetVectorAngles(fVector, fAngles);

				TeleportEntity(iAttacker, NULL_VECTOR, fAngles, NULL_VECTOR);
			}
		}
	}
}

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

	Wave_TeleportToSpawn();
}

/**
 * Starts to teleport all wave attackers.
 *
 * @noreturn
 */

stock Wave_TeleportToSpawn() {
	Log(TDLogLevel_Info, "Spawned wave %d (%d attackers)", g_iCurrentWave + 1, Wave_GetQuantity(g_iCurrentWave));

	CreateTimer(1.0, TeleportWaveDelay, 1, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TeleportWaveDelay(Handle:hTimer, any:iNumber) {
	if (iNumber > Wave_GetQuantity(g_iCurrentWave)) {
		Log(TDLogLevel_Debug, "Teleported wave %d (%d attackers)", g_iCurrentWave + 1, Wave_GetQuantity(g_iCurrentWave));
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

/*=========================================
=            Utility Functions            =
=========================================*/

public Action:Delay_KickAttacker(Handle:hTimer, any:iAttacker) {
	if (IsAttacker(iAttacker)) {
		KickClient(iAttacker);
	}

	return Plugin_Stop;
}

public Action:Timer_NextWaveCountdown(Handle:hTimer, any:iTime) {
	if (g_bStartWaveEarly) {
		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsDefender(iClient)) {
				PrintToChat(iClient, "\x04All of you received %d metal for starting %d seconds earlier!", (iTime + 1) * 10, iTime + 1);
				AddClientMetal(iClient, (iTime + 1) * 10);
			}
		}

		return Plugin_Stop;
	}

	switch (iTime) {
		case 5: {
			SetHudTextParams(-1.0, 0.6, 5.1, 255, 255, 255, 255, 2, 2.0);

			new iWaveHealth = Wave_GetHealth(g_iCurrentWave);
			g_iNextWaveType = Wave_GetType(g_iCurrentWave);

			for (new iClient = 1; iClient <= MaxClients; iClient++) {
				if (IsDefender(iClient)) {
					switch (g_iNextWaveType) {
						case TDWaveType_Boss: {
							ShowHudText(iClient, -1, "Boss with %d HP incoming!", iWaveHealth);
						}
						case TDWaveType_Rapid: {
							ShowHudText(iClient, -1, "Rapid Wave with %d HP incoming!", iWaveHealth);
						}
						case TDWaveType_Regen: {
							ShowHudText(iClient, -1, "Regen Wave with %d HP incoming!", iWaveHealth);
						}
						case TDWaveType_KnockbackImmune: {
							ShowHudText(iClient, -1, "Knockback Immune Wave with %d HP incoming!", iWaveHealth);
						}
						case TDWaveType_Air: {
							ShowHudText(iClient, -1, "Air Wave with %d HP incoming!", iWaveHealth);
						}
						case TDWaveType_JarateImmune: {
							ShowHudText(iClient, -1, "Jarate Immune Wave with %d HP incoming!", iWaveHealth);
						}
						default: {
							ShowHudText(iClient, -1, "Wave %d with %d HP incoming!", g_iCurrentWave + 1, iWaveHealth);
						}
					}
					
				}
			}

			EmitSoundToAll("vo/announcer_begins_5sec.wav");
		}
		case 4: {
			EmitSoundToAll("vo/announcer_begins_4sec.wav");
		}
		case 3: {
			EmitSoundToAll("vo/announcer_begins_3sec.wav");
		}
		case 2: {
			EmitSoundToAll("vo/announcer_begins_2sec.wav");
		}
		case 1: {
			EmitSoundToAll("vo/announcer_begins_1sec.wav");

			TeleportEntity(g_iWaveStartButton, Float:{0.0, 0.0, -9192.0}, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		}
		case 0: {
			Wave_Spawn();

			return Plugin_Stop;
		}
	}

	SetHudTextParams(-1.0, 0.85, 1.1, 255, 255, 255, 255);

	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient)) {
			ShowHudText(iClient, -1, "Next wave in: %02d", iTime);
		}
	}

	CreateTimer(1.0, Timer_NextWaveCountdown, iTime - 1, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Stop;
}

/**
 * Gets the count of alive attackers.
 *
 * @return				Count of alive attackers.
 */

stock GetAliveAttackerCount() {
	new iAttackers = 0;

	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsAttacker(iClient) && IsPlayerAlive(iClient)) {
			iAttackers++;
		}
	}

	return iAttackers;
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