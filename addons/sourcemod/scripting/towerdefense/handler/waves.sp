#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

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

	if (g_iNextWaveType & TDWaveType_Boss) {
		
	}

	if (g_iNextWaveType & TDWaveType_Rapid) {
		g_bBoostWave[iAttacker] = true;
	}

	if (g_iNextWaveType & TDWaveType_Regen) {
		TF2Attrib_SetByName(iAttacker, "health regen", float(RoundFloat(iWaveHealth * 0.05)));
	}

	if (g_iNextWaveType & TDWaveType_KnockbackImmune) {
		TF2Attrib_SetByName(iAttacker, "damage force reduction", 0.0);
	}

	if (g_iNextWaveType & TDWaveType_Air) {
		TF2Attrib_SetByName(iAttacker, "damage force reduction", 0.0);
	}

	if (g_iNextWaveType & TDWaveType_JarateImmune) {
		
	}
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

	if (g_iNextWaveType & TDWaveType_Boss) {
		SpawnMetalPacks(TDMetalPack_Boss);
	}

	g_bStartWaveEarly = false;

	g_iCurrentWave++;
	g_iNextWaveType = Wave_GetType(g_iCurrentWave);

	TeleportEntity(g_iWaveStartButton, g_fWaveStartButtonLocation, NULL_VECTOR, Float:{0.0, 0.0, 0.0});

	Timer_NextWaveCountdown(INVALID_HANDLE, g_iRespawnWaveTime);

	PrintToChatAll("\x04*** Passed wave %d ***", g_iCurrentWave);
	PrintToChatAll("\x01You have \x04%d seconds\x01 to prepare for the next wave!", g_iRespawnWaveTime);

	Log(TDLogLevel_Info, "Passed wave %d", g_iCurrentWave);

	if (Panel_Remove(g_iCurrentWave)) {
		PrintToChatAll("\x04New bonus (wave %d) available, see buy panel!", g_iCurrentWave);
		Log(TDLogLevel_Debug, "New bonus available (Wave: %d)", g_iCurrentWave);
	}
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
		new iNextCorner = Corner_GetNext(iCorner);

		if (iNextCorner != -1) {
			new Float:fAngles[3];
			Corner_GetAngles(iCorner, iNextCorner, fAngles);
			TeleportEntity(iAttacker, NULL_VECTOR, fAngles, NULL_VECTOR);
		} else {
			g_bBoostWave[iAttacker] = false;
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

	new iWaveQuantity = Wave_GetQuantity(g_iCurrentWave);

	if (iWaveQuantity > 1) {
		for (new i = 1; i <= iWaveQuantity; i++) {
			ServerCommand("bot -team red -class %s -name %s%d", sClass, sName, i);
		}
	} else {
		ServerCommand("bot -team red -class %s -name %s", sClass, sName);
	}

	Wave_TeleportToSpawn(iWaveQuantity);
}

/**
 * Starts to teleport all wave attackers.
 *
 * @param iWaveQuantity			The waves quantiy.
 * @noreturn
 */

stock Wave_TeleportToSpawn(iWaveQuantity) {
	Log(TDLogLevel_Info, "Spawned wave %d (%d attackers)", g_iCurrentWave + 1, iWaveQuantity);

	if (iWaveQuantity > 1) {
		CreateTimer(1.0, TeleportWaveDelay, 1, TIMER_FLAG_NO_MAPCHANGE);
	} else {
		CreateTimer(1.0, TeleportWaveDelay, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
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

	if (iNumber > 0) {
		Format(sName, sizeof(sName), "%s%d", sName, iNumber);
	}

	new iAttacker = GetClientByNameExact(sName, TEAM_ATTACKER);

	Log(TDLogLevel_Trace, "Should teleport attacker %d (%d, %s) of wave %d (%d attackers)", iNumber, iAttacker, sName, g_iCurrentWave + 1, Wave_GetQuantity(g_iCurrentWave));

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

		Log(TDLogLevel_Trace, " -> Teleported attacker");

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
			
			decl String:sType[256];
			strcopy(sType, sizeof(sType), "");

			if (g_iNextWaveType & TDWaveType_Rapid) {
				if (StrEqual(sType, "")) {
					Format(sType, sizeof(sType), "%s", "Rapid");
				} else {
					Format(sType, sizeof(sType), "%s + %s", sType, "Rapid");
				}
			}

			if (g_iNextWaveType & TDWaveType_Regen) {
				if (StrEqual(sType, "")) {
					Format(sType, sizeof(sType), "%s", "Regen");
				} else {
					Format(sType, sizeof(sType), "%s + %s", sType, "Regen");
				}
			}

			if (g_iNextWaveType & TDWaveType_KnockbackImmune) {
				if (StrEqual(sType, "")) {
					Format(sType, sizeof(sType), "%s", "Knockback Immune");
				} else {
					Format(sType, sizeof(sType), "%s + %s", sType, "Knockback Immune");
				}
			}

			if (g_iNextWaveType & TDWaveType_Air) {
				if (StrEqual(sType, "")) {
					Format(sType, sizeof(sType), "%s", "Air");
				} else {
					Format(sType, sizeof(sType), "%s + %s", sType, "Air");
				}
			}

			if (g_iNextWaveType & TDWaveType_JarateImmune) {
				if (StrEqual(sType, "")) {
					Format(sType, sizeof(sType), "%s", "Jarate Immune");
				} else {
					Format(sType, sizeof(sType), "%s + %s", sType, "Jarate Immune");
				}
			}

			if (g_iNextWaveType & TDWaveType_Boss) {
				if (StrEqual(sType, "")) {
					Format(sType, sizeof(sType), "%s", "Boss");
				} else {
					Format(sType, sizeof(sType), "%s %s", sType, "Boss");
				}
			}

			for (new iClient = 1; iClient <= MaxClients; iClient++) {
				if (IsDefender(iClient)) {
					if (StrEqual(sType, "")) {
						ShowHudText(iClient, -1, "Wave (%d) with %d HP incoming!", g_iCurrentWave + 1, iWaveHealth);
					} else {
						ShowHudText(iClient, -1, "%s Wave (%d) with %d HP incoming!", sType, g_iCurrentWave + 1, iWaveHealth);
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
 * @return				The waves type bit field.
 */

stock Wave_GetType(iWave) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_type", iWave);
	
	new iType = 0;
	if (!GetTrieValue(g_hMapWaves, sKey, iType)) {
		return -1;
	}

	return iType;
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