#pragma semicolon 1

#include <sourcemod>

static Handle:m_hDatabase;

static String:m_sServerIp[16];
static m_iServerPort;

static m_iServerId;
static m_iServerMap;

/**
 * Connects to the database.
 *
 * @noreturn
 */

stock Database_Connect() {
	if (!g_bEnabled) {
		return;
	}

	if (m_hDatabase != INVALID_HANDLE) {
		CloseHandle(m_hDatabase);
		m_hDatabase = INVALID_HANDLE;
	}

	if (m_hDatabase == INVALID_HANDLE) {
		//decl String:sDrowssap[128];
		//MD5String("1NGIwZDk2Y", sDrowssap, sizeof(sDrowssap));

		new Handle:hKeyValues = CreateKeyValues("");
		KvSetString(hKeyValues, "host", "46.38.241.137");
		KvSetString(hKeyValues, "database", "tf2tdsql5");
		KvSetString(hKeyValues, "user", "tf2tdsql5");
		KvSetString(hKeyValues, "pass", "1NGIwZDk2Y");

		new String:sError[512];
		m_hDatabase = SQL_ConnectCustom(hKeyValues, sError, sizeof(sError), true);
		CloseHandle(hKeyValues);

		if (m_hDatabase == INVALID_HANDLE) {
			LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to connect to the database! Error: %s", sError);
		} else {
			Log(TDLogLevel_Info, "Successfully connected to the database");

			new iServerIp[4];
			Steam_GetPublicIP(iServerIp);
			Format(m_sServerIp, sizeof(m_sServerIp), "%d.%d.%d.%d", iServerIp[0], iServerIp[1], iServerIp[2], iServerIp[3]);

			decl String:sServerPort[6];
			GetConVarString(FindConVar("hostport"), sServerPort, sizeof(sServerPort));
			m_iServerPort = StringToInt(sServerPort);

			if (StrEqual(m_sServerIp, "0.0.0.0")) {
				Log(TDLogLevel_Info, "Server has been restarted completely, reloading map for initializing");
				ReloadMap();
			} else {
				Database_CheckServer();
			}
		}
	} else {
		Database_CheckServer();
	}
}

/**
 * Checks if a server does already exist.
 *
 * @noreturn
 */

stock Database_CheckServer() {
	decl String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `server_id` \
		FROM `server` \
		WHERE `ip` = '%s' AND `port` = %d",
	m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnCheckServer, sQuery);
}

public Database_OnCheckServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckServer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No server found, add it

		Database_AddServer();
	} else {
		SQL_FetchRow(hResult);

		m_iServerId = SQL_FetchInt(hResult, 0);

		Database_RefreshServer();
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Adds a server.
 *
 * @noreturn
 */

stock Database_AddServer() {
	decl String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "\
		INSERT INTO `server` (`ip`, `port`) \
		VALUES ('%s', %d)",
	m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnAddServer, sQuery, 0);
}

public Database_OnAddServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_AddServer > Error: %s", sError);
	} else {
		decl String:sQuery[512];

		if (iData == 0) {
			Format(sQuery, sizeof(sQuery), "\
				SELECT `server_id` \
				FROM `server` \
				WHERE `ip` = '%s' AND `port` = %d",
			m_sServerIp, m_iServerPort);

			SQL_TQuery(m_hDatabase, Database_OnAddServer, sQuery, 1);
		} else if (iData == 1) {
			SQL_FetchRow(hResult);

			m_iServerId = SQL_FetchInt(hResult, 0);

			Format(sQuery, sizeof(sQuery), "\
				INSERT INTO `server_stats` (`server_id`) \
				VALUES (%d)",
			m_iServerId);

			SQL_TQuery(m_hDatabase, Database_OnAddServer, sQuery, 2);
		} else if (iData == 2) {
			Format(sQuery, sizeof(sQuery), "\
				INSERT INTO `server_config` (`server_id`) \
				VALUES (%d)",
			m_iServerId);

			SQL_TQuery(m_hDatabase, Database_OnAddServer, sQuery, 3);
		} else if (iData == 3) {
			Log(TDLogLevel_Info, "Added server to database (%s:%d)", m_sServerIp, m_iServerPort);

			Database_RefreshServer();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Refreshs a server.
 *
 * @noreturn
 */

stock Database_RefreshServer() {
	decl String:sQuery[512];

	decl String:sServerName[128], String:sServerNameSave[256];

	GetConVarString(FindConVar("hostname"), sServerName, sizeof(sServerName));
	SQL_EscapeString(m_hDatabase, sServerName, sServerNameSave, sizeof(sServerNameSave));

	decl String:sPassword[32], String:sPasswordSave[64];
	GetConVarString(FindConVar("sv_password"), sPassword, sizeof(sPassword));
	SQL_EscapeString(m_hDatabase, sPassword, sPasswordSave, sizeof(sPasswordSave));

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `server` \
		SET `name` = '%s', \
			`host_id` = ( \
				SELECT `host_id` \
				FROM `host` \
				WHERE `name` = '%s'), \
			`version` = '%s', \
			`password` = '%s', \
			`players` = %d \
		WHERE `ip` = '%s' AND `port` = %d", 
	sServerNameSave, PLUGIN_HOST, PLUGIN_VERSION, sPasswordSave, GetRealClientCount(), m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnRefreshServer, sQuery, 0);
}

public Database_OnRefreshServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_RefreshServer > Error: %s", sError);
	} else {
		decl String:sQuery[512];
		decl String:sCurrentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		if (iData == 0) {
			Format(sQuery, sizeof(sQuery), "\
				SELECT `map_id`, `respawn_wave_time` \
				FROM `map` \
				WHERE `name` = '%s'",
			sCurrentMap);

			SQL_TQuery(m_hDatabase, Database_OnRefreshServer, sQuery, 1);
		} else if (iData == 1) {
			if (SQL_GetRowCount(hResult) == 0) {
				LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Map \"%s\" is not supported, thus Tower Defense has been disabled.", sCurrentMap);
				
				g_bEnabled = false;
				UpdateGameDescription();

				if (hResult != INVALID_HANDLE) {
					CloseHandle(hResult);
					hResult = INVALID_HANDLE;
				}

				return;
			}

			SQL_FetchRow(hResult);

			m_iServerMap = SQL_FetchInt(hResult, 0);
			g_iRespawnWaveTime = SQL_FetchInt(hResult, 1);

			Format(sQuery, sizeof(sQuery), "\
				UPDATE `server` \
				SET `map_id` = %d \
				WHERE `ip` = '%s' AND `port` = %d", 
			m_iServerMap, m_sServerIp, m_iServerPort);

			SQL_TQuery(m_hDatabase, Database_OnRefreshServer, sQuery, 2);
		} else if (iData == 2) {
			Log(TDLogLevel_Info, "Refreshed server in database (%s:%d)", m_sServerIp, m_iServerPort);

			Database_CheckForDelete();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks for plugin delete.
 *
 * @noreturn
 */

stock Database_CheckForDelete() {
	decl String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `delete` \
		FROM `server` \
		WHERE `ip` = '%s' AND `port` = %d", 
	m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnCheckForDelete, sQuery);
}

public Database_OnCheckForDelete(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckForDelete > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		if (SQL_FetchInt(hResult, 0) == 1) {
			decl String:sFile[PLATFORM_MAX_PATH], String:sPath[PLATFORM_MAX_PATH];
			
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
			BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "plugins/%s", sFile);			

			if (FileExists(sPath)) {
				if (DeleteFile(sPath)) {
					ServerCommand("sm plugins unload %s", sFile);
				}
			}
		} else {
			Database_CheckServerVerified();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks if the server is verified.
 *
 * @noreturn
 */

public Database_CheckServerVerified() {
	new String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `verified` \
		FROM `server` \
		WHERE `ip` = '%s' AND `port` = %d", 
	m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnCheckServerVerified, sQuery);
}

public Database_OnCheckServerVerified(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckServerVerified > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		if (SQL_FetchInt(hResult, 0) == 0) {
			LogType(TDLogLevel_Warning, TDLogType_FileAndConsole, "Your server is not verified, please contact us at tf2td.net or on Steam");

			decl String:sFile[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
			ServerCommand("sm plugins unload %s", sFile);
		} else {
			Database_CheckForUpdates();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks for plugin updates.
 *
 * @noreturn
 */

stock Database_CheckForUpdates() {
	decl String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `update` \
		FROM `server` \
		WHERE `ip` = '%s' AND `port` = %d", 
	m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnCheckForUpdates, sQuery, 0);
}

public Database_OnCheckForUpdates(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckForUpdates > Error: %s", sError);
	} else {
		if (iData == 0) {
			SQL_FetchRow(hResult);

			if (SQL_FetchInt(hResult, 0) == 1) {
				decl String:sQuery[512];

				Format(sQuery, sizeof(sQuery), "\
					SELECT `update_url` \
					FROM `server` \
					WHERE `ip` = '%s' AND `port` = %d", 
				m_sServerIp, m_iServerPort);

				SQL_TQuery(m_hDatabase, Database_OnCheckForUpdates, sQuery, 1);
			} else {
				Database_LoadTowers();
				Database_LoadWeapons();
				Database_LoadWaves();
				Database_LoadMetalpacks();
			}
		} else if (iData == 1) {
			SQL_FetchRow(hResult);

			if (!SQL_IsFieldNull(hResult, 0)) {
				decl String:sUrl[256];
				SQL_FetchString(hResult, 0, sUrl, sizeof(sUrl));

				Log(TDLogLevel_Info, "Plugin update pending. Updating now ...");

				decl String:sFile[PLATFORM_MAX_PATH];
				GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));

				decl String:sPath[PLATFORM_MAX_PATH];
				Format(sPath, sizeof(sPath), "addons/sourcemod/plugins/%s", sFile);

				PrintToServer("Url: %s", sUrl);
				PrintToServer("Dest: %s", sPath);

				Updater_Download(sUrl, sPath);
			}
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/*======================================
=            Data Functions            =
======================================*/

/**
 * Loads towers to its map.
 *
 * @noreturn
 */

stock Database_LoadTowers() {
	decl String:sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `tower`.`tower_id`, `level`, `tower`.`name`, `type`, `price`, `teleport_tower`, `damagetype`, `description`, `metal`, `weapon_id`, `attack_primary`, `attack_secondary`, `rotate`, `pitch`, `damage`, `attackspeed`, `area` \
		FROM `tower` \
		INNER JOIN `classtype` \
			ON (`tower`.`classtype_id` = `classtype`.`classtype_id`) \
		INNER JOIN `map` \
			ON (`map`.`map_id` = %d) \
		INNER JOIN `towerlevel` \
			ON (`tower`.`tower_id` = `towerlevel`.`tower_id`) \
 		ORDER BY `name` ASC, `level` ASC", 
 	m_iServerMap);
	
	SQL_TQuery(m_hDatabase, Database_OnLoadTowers, sQuery);
}

public Database_OnLoadTowers(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_LoadTowers > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new iTowerId = 0, iTowerLevel = 0;
		decl String:sKey[64], String:sBuffer[128];

		// Level Name          Class    Price Location          Damagetype Description Metal WeaponId AttackPrimary AttackSecondary Rotate Pitch Damage Attackspeed Area
		// 1     EngineerTower Engineer 500   666 -626 -2 0 0 0 Melee      ...         1000  1        1             0               0      45    1.0    1.0         1.0

		while (SQL_FetchRow(hResult)) {
			iTowerId = SQL_FetchInt(hResult, 0) - 1;
			iTowerLevel = SQL_FetchInt(hResult, 1);

			// Save data only once
			if (iTowerLevel == 1) {
				// Save tower name
				Format(sKey, sizeof(sKey), "%d_name", iTowerId);
				SQL_FetchString(hResult, 2, sBuffer, sizeof(sBuffer));
				SetTrieString(g_hMapTowers, sKey, sBuffer);

				// PrintToServer("%s => %s", sKey, sBuffer);

				// Save tower class
				Format(sKey, sizeof(sKey), "%d_class", iTowerId);
				SQL_FetchString(hResult, 3, sBuffer, sizeof(sBuffer));
				SetTrieString(g_hMapTowers, sKey, sBuffer);

				// PrintToServer("%s => %s", sKey, sBuffer);

				// Save tower price
				Format(sKey, sizeof(sKey), "%d_price", iTowerId);
				SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 4));

				// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 4));

				// Save tower location
				Format(sKey, sizeof(sKey), "%d_location", iTowerId);
				SQL_FetchString(hResult, 5, sBuffer, sizeof(sBuffer));
				SetTrieString(g_hMapTowers, sKey, sBuffer);

				// PrintToServer("%s => %s", sKey, sBuffer);

				// Save tower damagetype
				Format(sKey, sizeof(sKey), "%d_damagetype", iTowerId);
				SQL_FetchString(hResult, 6, sBuffer, sizeof(sBuffer));
				SetTrieString(g_hMapTowers, sKey, sBuffer);

				// PrintToServer("%s => %s", sKey, sBuffer);

				// Save tower description
				Format(sKey, sizeof(sKey), "%d_description", iTowerId);
				SQL_FetchString(hResult, 7, sBuffer, sizeof(sBuffer));
				SetTrieString(g_hMapTowers, sKey, sBuffer);

				// PrintToServer("%s => %s", sKey, sBuffer);
			}
			
			// PrintToServer("Level %d:", iTowerLevel);

			// Save tower level metal
			Format(sKey, sizeof(sKey), "%d_%d_metal", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 8));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 8));

			// Save tower level weapon index
			Format(sKey, sizeof(sKey), "%d_%d_weapon", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 9));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 9));

			// Save tower level attack primary
			Format(sKey, sizeof(sKey), "%d_%d_attack_primary", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 10));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 10));

			// Save tower level attack secondary
			Format(sKey, sizeof(sKey), "%d_%d_attack_secondary", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 11));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 11));

			// Save tower level rotate
			Format(sKey, sizeof(sKey), "%d_%d_rotate", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 12));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 12));

			// Save tower level pitch
			Format(sKey, sizeof(sKey), "%d_%d_pitch", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 13));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 13));

			// Save tower level damage
			Format(sKey, sizeof(sKey), "%d_%d_damage", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 14));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 14));

			// Save tower level attackspeed
			Format(sKey, sizeof(sKey), "%d_%d_attackspeed", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 15));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 15));

			// Save tower level area
			Format(sKey, sizeof(sKey), "%d_%d_area", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 16));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 16));
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Loads weapons to its map.
 *
 * @noreturn
 */

stock Database_LoadWeapons() {
	decl String:sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `name`, `index`, `slot`, `level`, `quality`, `classname`, `attributes`, `preserve_attributes` \
		FROM `weapon` \
 		ORDER BY `weapon_id` ASC"
 	);
	
	SQL_TQuery(m_hDatabase, Database_OnLoadWeapons, sQuery);
}

public Database_OnLoadWeapons(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_LoadWeapons > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new iWeaponId = 1;
		decl String:sKey[64], String:sBuffer[128];

		// Name   Index Slot Level Quality Classname        Attributes Preserve
		// Wrench 7     2    1     0       tf_weapon_wrench            1

		while (SQL_FetchRow(hResult)) {
			// Save weapon name
			Format(sKey, sizeof(sKey), "%d_name", iWeaponId);
			SQL_FetchString(hResult, 0, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapWeapons, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save weapon index
			Format(sKey, sizeof(sKey), "%d_index", iWeaponId);
			SetTrieValue(g_hMapWeapons, sKey, SQL_FetchInt(hResult, 1));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 1));

			// Save weapon slot
			Format(sKey, sizeof(sKey), "%d_slot", iWeaponId);
			SetTrieValue(g_hMapWeapons, sKey, SQL_FetchInt(hResult, 2));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 2));

			// Save weapon level
			Format(sKey, sizeof(sKey), "%d_level", iWeaponId);
			SetTrieValue(g_hMapWeapons, sKey, SQL_FetchInt(hResult, 3));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 3));

			// Save weapon quality
			Format(sKey, sizeof(sKey), "%d_quality", iWeaponId);
			SetTrieValue(g_hMapWeapons, sKey, SQL_FetchInt(hResult, 4));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 4));

			// Save weapon classname
			Format(sKey, sizeof(sKey), "%d_classname", iWeaponId);
			SQL_FetchString(hResult, 5, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapWeapons, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save weapon attributes
			Format(sKey, sizeof(sKey), "%d_attributes", iWeaponId);
			SQL_FetchString(hResult, 6, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapWeapons, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save weapon preserve attributes
			Format(sKey, sizeof(sKey), "%d_preserve_attributes", iWeaponId);
			SetTrieValue(g_hMapWeapons, sKey, SQL_FetchInt(hResult, 7));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 7));

			iWeaponId++;
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Loads waves to its map.
 *
 * @noreturn
 */

stock Database_LoadWaves() {
	decl String:sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `wavetype`, `wave`.`name`, `classtype`.`type`, `quantity`, `health`, IF(`wavetype` & (SELECT `bit_value` FROM `wavetype` WHERE `wavetype`.`type` = 'air'), `teleport_air`, `teleport_ground`) \
		FROM `wave` \
		INNER JOIN `classtype` \
			ON (`wave`.`classtype_id` = `classtype`.`classtype_id`) \
		INNER JOIN `map` \
			ON (`map`.`map_id` = %d) \
 		WHERE `wave_id` >= `wave_start` AND `wave_id` <= `wave_end` \
 		ORDER BY `wave_id` ASC",
 	m_iServerMap);
	
	SQL_TQuery(m_hDatabase, Database_OnLoadWaves, sQuery);
}

public Database_OnLoadWaves(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_LoadWaves > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new iWaveId = 0;
		decl String:sKey[64], String:sBuffer[128];

		// Type Name      Class Quantiy Health Location
		// 0    WeakScout Scout 4       125    560 -1795 -78 0 90 0

		while (SQL_FetchRow(hResult)) {
			// Save wave type
			Format(sKey, sizeof(sKey), "%d_type", iWaveId);
			SetTrieValue(g_hMapWaves, sKey, SQL_FetchInt(hResult, 0));

			if (iWaveId == 0) {
				g_iNextWaveType = SQL_FetchInt(hResult, 0);
			}

			// Save wave name
			Format(sKey, sizeof(sKey), "%d_name", iWaveId);
			SQL_FetchString(hResult, 1, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapWaves, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save wave class
			Format(sKey, sizeof(sKey), "%d_class", iWaveId);
			SQL_FetchString(hResult, 2, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapWaves, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save wave quantity
			Format(sKey, sizeof(sKey), "%d_quantity", iWaveId);
			SetTrieValue(g_hMapWaves, sKey, SQL_FetchInt(hResult, 3));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 3));

			// Save wave health
			Format(sKey, sizeof(sKey), "%d_health", iWaveId);
			SetTrieValue(g_hMapWaves, sKey, SQL_FetchInt(hResult, 4));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 4));

			// Save wave location
			Format(sKey, sizeof(sKey), "%d_location", iWaveId);
			SQL_FetchString(hResult, 5, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapWaves, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			iWaveId++;
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Loads metalpacks to its map.
 *
 * @noreturn
 */

stock Database_LoadMetalpacks() {
	decl String:sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `type`, `metal`, `location` \
		FROM `metalpack` \
		INNER JOIN `metalpacktype` \
			ON (`metalpack`.`metalpacktype_id` = `metalpacktype`.`metalpacktype_id`) \
 		WHERE `map_id` = %d \
 		ORDER BY `metalpack_id` ASC",
 	m_iServerMap);
	
	SQL_TQuery(m_hDatabase, Database_OnLoadMetalpacks, sQuery);
}

public Database_OnLoadMetalpacks(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_LoadMetalpacks > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new iMetalpackId = 0;
		decl String:sKey[64], String:sBuffer[128];

		// Type  Metal Location
		// start 400   1100 -1200 -90

		while (SQL_FetchRow(hResult)) {
			// Save metalpack type
			Format(sKey, sizeof(sKey), "%d_type", iMetalpackId);
			SQL_FetchString(hResult, 0, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapMetalpacks, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save metalpack metal
			Format(sKey, sizeof(sKey), "%d_metal", iMetalpackId);
			SetTrieValue(g_hMapMetalpacks, sKey, SQL_FetchInt(hResult, 1));

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save metalpack location
			Format(sKey, sizeof(sKey), "%d_location", iMetalpackId);
			SQL_FetchString(hResult, 2, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapMetalpacks, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			iMetalpackId++;
		}

		// Save metalpack quantity
		SetTrieValue(g_hMapMetalpacks, "quantity", iMetalpackId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}