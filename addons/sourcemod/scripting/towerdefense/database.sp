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
				LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Server has been restarted completely, reloading map for initializing");
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

		// Database_RefreshServer();
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

			// Database_RefreshServer();
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

	decl String:sCurrentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

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
			`players` = %d, \
			`map_id` = ( \
				SELECT `id` \
				FROM `map` \
				WHERE `name` = '%s') \
		WHERE `ip` = '%s' AND `port` = %d", 
	sServerNameSave, PLUGIN_HOST, PLUGIN_VERSION, sPasswordSave, GetRealClientCount(), PLAYER_LIMIT, sCurrentMap, m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnRefreshServer, sQuery);
}

public Database_OnRefreshServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_RefreshServer > Error: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Refreshed server in database (%s:%d)", m_sServerIp, m_iServerPort);

		Database_GetServerMap();
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Gets the servers map.
 *
 * @noreturn
 */

stock Database_GetServerMap() {
	new String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "SELECT `map_id` FROM `server` WHERE `ip` = '%s' AND `port` = %d", m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnGetServerMap, sQuery);
}

public Database_OnGetServerMap(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_GetServerMap > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		m_iServerMap = SQL_FetchInt(hResult, 0);
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
		SELECT `tower`.`tower_id`, `level`, `tower`.`name`, `type`, `price`, `teleport_tower`, `metal`, `weapon_id`, `attack_primary`, `attack_secondary`, `rotate`, `pitch`, `damage`, `attackspeed`, `area` \
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

		// Level Name          Class    Price Location          Metal WeaponId AttackPrimary AttackSecondary Rotate Pitch Damage Attackspeed Area
		// 1     EngineerTower Engineer 500   666 -626 -2 0 0 0 1000  1        1             0               0      45    1.0    1.0         1.0

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
			}
			
			// PrintToServer("Level %d:", iTowerLevel);

			// Save tower level metal
			Format(sKey, sizeof(sKey), "%d_%d_metal", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 6));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 6));

			// Save tower level weapon index
			Format(sKey, sizeof(sKey), "%d_%d_weapon", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 7));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 7));

			// Save tower level attack primary
			Format(sKey, sizeof(sKey), "%d_%d_attack_primary", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 8));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 8));

			// Save tower level attack secondary
			Format(sKey, sizeof(sKey), "%d_%d_attack_secondary", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 9));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 9));

			// Save tower level rotate
			Format(sKey, sizeof(sKey), "%d_%d_rotate", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 10));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 10));

			// Save tower level pitch
			Format(sKey, sizeof(sKey), "%d_%d_pitch", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 11));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 11));

			// Save tower level damage
			Format(sKey, sizeof(sKey), "%d_%d_damage", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 12));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 12));

			// Save tower level attackspeed
			Format(sKey, sizeof(sKey), "%d_%d_attackspeed", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 13));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 13));

			// Save tower level area
			Format(sKey, sizeof(sKey), "%d_%d_area", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 14));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 14));
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}