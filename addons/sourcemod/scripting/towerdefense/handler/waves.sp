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

stock void Wave_OnButtonStart(int iWave, int iButton, int iActivator) {
	if (!g_bEnabled) {
		return;
	}

	if (!IsDefender(iActivator)) {
		return;
	}

	char sName[64];
	Format(sName, sizeof(sName), "wave_start_%d", iWave + 1);
	DispatchKeyValue(iButton, "targetname", sName);

	TeleportEntity(iButton, view_as<float>({ 0.0, 0.0, -9192.0 }), NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));

	/*Translation Example
	* Format: %s	  			%t
	* Values: PLUGIN_PREFIX		"waveStart" GetClientNameShort(iActivator) (g_iCurrentWave + 1)
	* Output: [TF2TD] 			[PrWh] Dragonisser started Wave 1
	*/
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "waveStart", GetClientNameShort(iActivator), g_iCurrentWave + 1);
	
	//Wave Health
	int iWaveHealth;
	int iPlayerCount = GetRealClientCount();
	if (iPlayerCount > 1)
		iWaveHealth = RoundToZero(float(Wave_GetHealth(g_iCurrentWave)) * (float(iPlayerCount) * 0.125 + 1.0));
	else
		iWaveHealth = Wave_GetHealth(g_iCurrentWave);

	SetHudTextParams(-1.0, 0.6, 3.1, 255, 255, 255, 255, 1, 2.0);
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient)) {
			if(Wave_GetType(g_iCurrentWave) == 0) {
				ShowHudText(iClient, -1, "%t", "waveIncommingWithHealth", g_iCurrentWave + 1, iWaveHealth);
			}
		}
	}

	if (iWave == 0) {
		Timer_NextWaveCountdown(null, 5);
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

stock void Wave_OnSpawn(int iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	g_bBoostWave = false;

	SetRobotModel(iAttacker);
}

/**
 * Called the frame after an attacker spawned.
 *
 * @param iAttacker		The attacker.
 * @noreturn
 */
public void Wave_OnSpawnPost(any iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	int iMaxHealth = GetEntProp(iAttacker, Prop_Data, "m_iMaxHealth");
	int iWaveHealth;
	int iPlayerCount = GetRealClientCount();
	if (iPlayerCount > 1)
		iWaveHealth = RoundToZero(float(Wave_GetHealth(g_iCurrentWave)) * (float(iPlayerCount) * 0.125 + 1.0));
	else
		iWaveHealth = Wave_GetHealth(g_iCurrentWave);

	TF2Attrib_SetByName(iAttacker, "max health additive bonus", float(iWaveHealth - iMaxHealth));
	SetEntityHealth(iAttacker, iWaveHealth);

	if (g_iNextWaveType & TDWaveType_Boss) {
		// TODO(?)
	}

	if (g_iNextWaveType & TDWaveType_Rapid) {
		g_bBoostWave = true;
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
}

public void TF2_OnConditionAdded(int iClient, TFCond Condition) {
	if (Condition == TFCond_Jarated && g_iNextWaveType & TDWaveType_JarateImmune)
		TF2_RemoveCondition(iClient, TFCond_Jarated);
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

stock void Wave_OnTakeDamagePost(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType) {
	if (!g_bEnabled) {
		return;
	}

	if (IsValidEntity(g_iHealthBar)) {
		int iWaveHealth;
		int iPlayerCount = GetRealClientCount();
		if (iPlayerCount > 1)
			iWaveHealth = RoundToZero(float(Wave_GetHealth(g_iCurrentWave)) * (float(iPlayerCount) * 0.125 + 1.0));
		else
			iWaveHealth = Wave_GetHealth(g_iCurrentWave);
		int iTotalHealth = iWaveHealth * g_iBotsToSpawn;
		for (int iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsAttacker(iClient)) {
				iTotalHealth += GetClientHealth(iClient);
			}
		}

		int	  iTotalHealthMax = iWaveHealth * Wave_GetQuantity(g_iCurrentWave);
		float fPercentage	  = float(iTotalHealth) / float(iTotalHealthMax);

		SetEntProp(g_iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", RoundToFloor(fPercentage * 255));
	}
}

/**
 * Called when an attacker dies.
 *
 * @param iAttacker		The attacker.
 * @noreturn
 */

stock void Wave_OnDeath(int iAttacker, float fPosition[3]) {
	if (!g_bEnabled) {
		return;
	}

	// TODO(hurp): Find a better way to make the ammo from air waves spawn on the ground,
	//             This method probably wont work for all maps
	if (Wave_GetType(g_iCurrentWave) == TDWaveType_Air) {
		fPosition[2] = fPosition[2] - 10.0;
	}

	// TODO(hurp): Customize metal ammount based off the wave in config files
	fPosition[2] = fPosition[2] - GetDistanceToGround(fPosition) + 10.0;
	SpawnRewardPack(TDMetalPack_Small, fPosition, 100);

	CreateTimer(1.0, Delay_KickAttacker, iAttacker, TIMER_FLAG_NO_MAPCHANGE);
	if (g_iBotsToSpawn >= 1) {
		Wave_SpawnBots();
	} else if (GetAliveAttackerCount() <= 1 && g_iBotsToSpawn <= 0) {
		Wave_OnDeathAll();
		for (int iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsDefender(iClient)) {
				Player_CAddValue(iClient, PLAYER_WAVES_PLAYED, g_iCurrentWave);
				Player_CSetValue(iClient, PLAYER_WAVE_REACHED, g_iCurrentWave);
			}
		}
	}
}

/**
 * Called when all attackers died.
 *
 * @noreturn
 */

stock void Wave_OnDeathAll() {
	if (!g_bEnabled) {
		return;
	}
	if (g_iNextWaveType & TDWaveType_Boss) {
		SpawnMetalPacks(TDMetalPack_Boss);
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient))
			Player_CAddValue(iClient, PLAYER_WAVES_PLAYED, 1);
	}

	if (g_iCurrentWave + 1 >= iMaxWaves) {
		PrintToServer("[TF2TD] Round won (Wave: %d)", g_iCurrentWave + 1);
		Server_UAddValue(g_iServerId, SERVER_ROUNDS_WON, 1);
		for (int iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsDefender(iClient)) {
				Player_CSetValue(iClient, PLAYER_ROUNDS_WON, 1);
			}
		}
		PlaySound("Win", 0);
		Wave_Win(TEAM_DEFENDER);
		return;
	} else {
		PlaySound("WaveComplete", 0);
	}

	g_iTotalBotsLeft  = 0;

	g_bStartWaveEarly = false;

	g_iCurrentWave++;

	g_iNextWaveType = Wave_GetType(g_iCurrentWave);

	TeleportEntity(g_iWaveStartButton, g_fWaveStartButtonLocation, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));

	Timer_NextWaveCountdown(null, g_iRespawnWaveTime);
	
	
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "wavePassed", g_iCurrentWave);
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "wavePrepareTime", g_iRespawnWaveTime);
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "waveTowersUnlocked");
	
	g_bTowersLocked = false;

	Log(TDLogLevel_Info, "Wave %d passed", g_iCurrentWave);

	if (Panel_Remove(g_iCurrentWave)) {
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "waveBonusAvailable", g_iCurrentWave);
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
public void Wave_OnTouchCorner(int iCorner, int iAttacker) {
	if (!g_bEnabled) {
		return;
	}

	if (IsAttacker(iAttacker)) {
		int iNextCorner = Corner_GetNext(iCorner);

		if (iNextCorner != -1) {
			float fAngles[3];
			Corner_GetAngles(iCorner, iNextCorner, fAngles);
			TeleportEntity(iAttacker, NULL_VECTOR, fAngles, NULL_VECTOR);
		} else {
			g_bBoostWave = false;
		}
	}
}

/**
 * Spawns a wave.
 *
 * @noreturn
 */

stock void Wave_Spawn() {
	// Delete ammo packs loot that have not been picked up
	char buffer[64];
	int	 entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE) {
		GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));

		if (StrEqual(buffer, "models/items/ammopack_small.mdl")) {
			AcceptEntityInput(entity, "Kill");
			g_iMetalPackCount--;
		}
	}

	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "waveIncomming", g_iCurrentWave + 1);
	CPrintToChatAll("%s %t", PLUGIN_PREFIX, "waveTowersLocked");
	g_bTowersLocked = true;

	g_iBotsToSpawn	= Wave_GetQuantity(g_iCurrentWave);

	SetEntProp(g_iHealthBar, Prop_Send, "m_iBossHealthPercentageByte", 255);
	g_iTotalBotsLeft = Wave_GetQuantity(g_iCurrentWave);
	Wave_SpawnBots();
}

stock void Wave_SpawnBots() {
	if (g_iBotsToSpawn <= 0) {
		return;
	}
	char sName[MAX_NAME_LENGTH];
	if (!Wave_GetName(g_iCurrentWave, sName, sizeof(sName))) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to spawn wave %d, could not read name!", g_iCurrentWave);
		return;
	}

	char sClass[32];
	if (!Wave_GetClassString(g_iCurrentWave, sClass, sizeof(sClass))) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to spawn wave %d, could not read class!", g_iCurrentWave);
		return;
	}

	int iTotalBots = Wave_GetQuantity(g_iCurrentWave);
	int iAliveBots = GetAliveAttackerCount();

	// If only less than g_iMaxBotsOnField bots in total
	if (iTotalBots <= g_hMaxBotsOnField.IntValue) {
		if (iTotalBots > 1) {
			for (int i = 1; i <= iTotalBots; i++) {
				ServerCommand("bot -team red -class %s -name %s%d", sClass, sName, i);
				g_iBotsToSpawn--;
			}
			// If only 1 bot
		} else {
			ServerCommand("bot -team red -class %s -name %s", sClass, sName);
			g_iBotsToSpawn = 0;
		}
		CreateTimer(1.0, TeleportWaveDelay, iTotalBots, TIMER_FLAG_NO_MAPCHANGE);
		// Else more than g_iMaxBotsOnField bots
	} else {
		// If no bot alive
		if (iAliveBots <= 0) {
			for (int i = 1; i <= g_hMaxBotsOnField.IntValue; i++) {
				g_iBotsToSpawn--;
				ServerCommand("bot -team red -class %s -name %s%d", sClass, sName, -(g_iBotsToSpawn - iTotalBots));
			}
			CreateTimer(1.0, TeleportWaveDelay, g_hMaxBotsOnField.IntValue, TIMER_FLAG_NO_MAPCHANGE);
			// If bots alive
		} else {
			int iBotsToSpawn = g_hMaxBotsOnField.IntValue - iAliveBots;
			for (int i = 1; i <= iBotsToSpawn; i++) {
				g_iBotsToSpawn--;
				ServerCommand("bot -team red -class %s -name %s%d", sClass, sName, -(g_iBotsToSpawn - iTotalBots));
			}
			CreateTimer(1.0, TeleportWaveDelay, iBotsToSpawn, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action TeleportWaveDelay(Handle hTimer, any iNumber) {
	if (iNumber <= 0) {
		return Plugin_Stop;
	}
	int	 iTotalBots = Wave_GetQuantity(g_iCurrentWave);
	char sName[MAX_NAME_LENGTH];
	if (!Wave_GetName(g_iCurrentWave, sName, sizeof(sName))) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to teleport wave %d, could not read name!", g_iCurrentWave);
		return Plugin_Stop;
	}
	if (iTotalBots <= 1) {
		Format(sName, sizeof(sName), "%s", sName);
	} else if (iTotalBots > g_hMaxBotsOnField.IntValue) {
		g_iTotalBotsLeft--;
		Format(sName, sizeof(sName), "%s%d", sName, -(g_iTotalBotsLeft - iTotalBots));
	} else if (iNumber > 0) {
		Format(sName, sizeof(sName), "%s%d", sName, iNumber);
	}

	int iAttacker = GetClientByNameExact(sName, TEAM_ATTACKER);

	Log(TDLogLevel_Trace, "Should teleport attacker %d (%d, %s) of wave %d (%d attackers)", iNumber, iAttacker, sName, g_iCurrentWave + 1, Wave_GetQuantity(g_iCurrentWave));

	if (IsAttacker(iAttacker)) {
		float fLocation[3];
		if (!Wave_GetLocation(g_iCurrentWave, fLocation)) {
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to teleport wave %d, could not read location!", g_iCurrentWave);
			return Plugin_Stop;
		}

		float fAngles[3];
		if (!Wave_GetAngles(g_iCurrentWave, fAngles)) {
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to teleport wave %d, could not read angles!", g_iCurrentWave);
			return Plugin_Stop;
		}

		TeleportEntity(iAttacker, fLocation, fAngles, view_as<float>({ 0.0, 0.0, 0.0 }));

		Log(TDLogLevel_Trace, " -> Teleported attacker");
		CreateTimer(1.0, TeleportWaveDelay, iNumber - 1, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

public void Wave_Win(int iTeam) {
	int iEntity = -1;

	iEntity		= FindEntityByClassname2(iEntity, "team_control_point_master");

	if (iEntity == -1 || !IsValidEntity(iEntity)) {
		// No team_control_point_master either... lets create one.
		iEntity = CreateEntityByName("team_control_point_master");
		DispatchKeyValue(iEntity, "targetname", "master_control_point");
		DispatchKeyValue(iEntity, "StartDisabled", "0");
		DispatchSpawn(iEntity);
	}
	SetVariantInt(iTeam);
	AcceptEntityInput(iEntity, "SetWinner");
}

/*=========================================
=            Utility Functions            =
=========================================*/
public Action Delay_KickAttacker(Handle hTimer, any iAttacker) {
	if (IsAttacker(iAttacker)) {
		KickClient(iAttacker);
	}

	return Plugin_Stop;
}

public Action Timer_NextWaveCountdown(Handle hTimer, any iTime) {
	if (g_bStartWaveEarly) {
		for (int iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsDefender(iClient)) {
				CPrintToChat(iClient, "%s %t", PLUGIN_PREFIX, "waveStartedEarly", (iTime + 1) * 10, iTime + 1);
				AddClientMetal(iClient, (iTime + 1) * 10);
			}
		}

		return Plugin_Stop;
	}

	switch (iTime) {
		case 5: {
			SetHudTextParams(-1.0, 0.6, 5.1, 255, 255, 255, 255, 2, 2.0);

			// Wave Health
			int iWaveHealth;
			int iPlayerCount = GetRealClientCount();
			if (iPlayerCount > 1)
				iWaveHealth = RoundToZero(float(Wave_GetHealth(g_iCurrentWave)) * (float(iPlayerCount) * 0.125 + 1.0));
			else
				iWaveHealth = Wave_GetHealth(g_iCurrentWave);

			for (int iClient = 1; iClient <= MaxClients; iClient++) {
				if (IsDefender(iClient)) {
					char sType[256];
					strcopy(sType, sizeof(sType), "");

					if (g_iNextWaveType & TDWaveType_Rapid) {
						if (StrEqual(sType, "")) {
							Format(sType, sizeof(sType), "%T", "waveTypeRapid", iClient);
						} else {
							Format(sType, sizeof(sType), "%s + %T", sType, "waveTypeRapid", iClient);
						}
					}

					if (g_iNextWaveType & TDWaveType_Regen) {
						if (StrEqual(sType, "")) {
							Format(sType, sizeof(sType), "%T", "waveTypeRegen", iClient);
						} else {
							Format(sType, sizeof(sType), "%s + %T", sType, "waveTypeRegen", iClient);
						}
					}

					if (g_iNextWaveType & TDWaveType_KnockbackImmune) {
						if (StrEqual(sType, "")) {
							Format(sType, sizeof(sType), "%T", "waveTypeKnockbackImmune", iClient);
						} else {
							Format(sType, sizeof(sType), "%s + %T", sType, "waveTypeKnockbackImmune", iClient);
						}
					}

					if (g_iNextWaveType & TDWaveType_Air) {
						if (StrEqual(sType, "")) {
							Format(sType, sizeof(sType), "%T", "waveTypeAir", iClient);
						} else {
							Format(sType, sizeof(sType), "%s + %T", sType, "waveTypeAir", iClient);
						}
					}

					if (g_iNextWaveType & TDWaveType_JarateImmune) {
						if (StrEqual(sType, "")) {
							Format(sType, sizeof(sType), "%T", "waveTypeJarateImmune", iClient);
						} else {
							Format(sType, sizeof(sType), "%s + %T", sType, "waveTypeJarateImmune", iClient);
						}
					}

					if (g_iNextWaveType & TDWaveType_Boss) {
						if (StrEqual(sType, "")) {
							Format(sType, sizeof(sType), "%T", "waveTypeBoss", iClient);
						} else {
							Format(sType, sizeof(sType), "%s %T", sType, "waveTypeBoss", iClient);
						}
					}

					if (StrEqual(sType, "")) {
						ShowHudText(iClient, -1, "%t", "waveIncommingWithHealth", g_iCurrentWave + 1, iWaveHealth);
					} else {
						ShowHudText(iClient, -1, "%t", "waveIncommingWithHealthAndType", sType, g_iCurrentWave + 1, iWaveHealth);
					}
				}
			}

			EmitSoundToAll("vo/announcer_begins_5sec.mp3");
		}
		case 4: {
			EmitSoundToAll("vo/announcer_begins_4sec.mp3");
		}
		case 3: {
			EmitSoundToAll("vo/announcer_begins_3sec.mp3");
		}
		case 2: {
			EmitSoundToAll("vo/announcer_begins_2sec.mp3");
		}
		case 1: {
			EmitSoundToAll("vo/announcer_begins_1sec.mp3");

			TeleportEntity(g_iWaveStartButton, view_as<float>({ 0.0, 0.0, -9192.0 }), NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
		}
		case 0: {
			PlaySound("Music", 0);
			Wave_Spawn();

			return Plugin_Stop;
		}
	}

	SetHudTextParams(-1.0, 0.85, 1.1, 255, 255, 255, 255);

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient)) {
			ShowHudText(iClient, -1, "%t", "waveArrivingIn", iTime);
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

stock int GetAliveAttackerCount() {
	int iAttackers = 0;

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
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

stock bool Wave_GetName(int iWave, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_name", iWave);

	return GetTrieString(g_hMapWaves, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the type of a wave.
 *
 * @param iWave 		The wave.
 * @return				The waves type bit field.
 */

stock int Wave_GetType(int iWave) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_type", iWave);

	int iType = 0;
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

stock bool Wave_GetClassString(int iWave, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", iWave);

	return GetTrieString(g_hMapWaves, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the class of a wave.
 *
 * @param iWave 		The wave.
 * @return				The waves class type, or TFClass_Unknown on error.
 */

stock TFClassType Wave_GetClass(int iWave) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", iWave);

	char sClass[32];
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

stock int Wave_GetQuantity(int iWave) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_quantity", iWave);

	int iQuantity = 0;
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

stock int Wave_GetHealth(int iWave) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_health", iWave);

	int iHealth = 0;
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

stock bool Wave_GetLocation(int iWave, float fLocation[3]) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", iWave);

	char sLocation[64];
	if (GetTrieString(g_hMapWaves, sKey, sLocation, sizeof(sLocation))) {
		char sLocationParts[6][16];
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

stock bool Wave_GetAngles(int iWave, float fAngles[3]) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", iWave);

	char sAngles[64];
	if (GetTrieString(g_hMapWaves, sKey, sAngles, sizeof(sAngles))) {
		char sAnglesParts[6][16];
		ExplodeString(sAngles, " ", sAnglesParts, sizeof(sAnglesParts), sizeof(sAnglesParts[]));

		fAngles[0] = StringToFloat(sAnglesParts[3]);
		fAngles[1] = StringToFloat(sAnglesParts[4]);
		fAngles[2] = StringToFloat(sAnglesParts[5]);

		return true;
	}

	return false;
}

/**
 * Finds an entity by using its classname.
 *
 * @param iStartEnt 	The start entity entity index.
 * @param sClassname 	The entity classname to look for.
 * @return				The entitys entity index, or -1 on failure.
 */
public int FindEntityByClassname2(int iStartEnt, const char[] sClassname) {
	/* If iStartEnt isn't valid shifting it back to the nearest valid one */
	while (iStartEnt > -1 && !IsValidEntity(iStartEnt))
		iStartEnt--;
	return FindEntityByClassname(iStartEnt, sClassname);
}