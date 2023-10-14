#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Checks if a server does already exist.
 *
 * @noreturn
 */

stock void Database_CheckServer() {
	char sQuery[128];

	g_hDatabase.Format(sQuery, sizeof(sQuery),
		"SELECT `server_id` " ...
		"FROM `server` " ...
		"WHERE `ip` = '%s' AND `port` = %d " ...
		"LIMIT 1",
		g_sServerIp, g_iServerPort);

	g_hDatabase.Query(Database_OnCheckServer, sQuery);
}

public void Database_OnCheckServer(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No server found, add it

		Database_AddServer();
	} else {
		SQL_FetchRow(hResult);

		g_iServerId = SQL_FetchInt(hResult, 0);

		Database_UpdateServer();
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

/**
 * Adds a server.
 *
 * @noreturn
 */

stock void Database_AddServer() {
	char sQuery[256];

	g_hDatabase.Format(sQuery, sizeof(sQuery),
		"INSERT INTO `server` (`ip`, `port`, `created`, `updated`) " ...
		"VALUES ('%s', %d, UTC_TIMESTAMP(), UTC_TIMESTAMP())",
		g_sServerIp, g_iServerPort);

	g_hDatabase.Query(Database_OnAddServer, sQuery, 0);
}

public void Database_OnAddServer(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_AddServer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		char sQuery[256];

		if (iData == 0) {
			g_hDatabase.Format(sQuery, sizeof(sQuery), 
				"SELECT `server_id` " ...
				"FROM `server` " ...
				"WHERE `ip` = '%s' AND `port` = %d " ...
				"LIMIT 1",
				g_sServerIp, g_iServerPort);

			g_hDatabase.Query(Database_OnAddServer, sQuery, 1);
		} else if (iData == 1) {
			SQL_FetchRow(hResult);
			g_iServerId = SQL_FetchInt(hResult, 0);

			g_hDatabase.Format(sQuery, sizeof(sQuery), 
				"INSERT INTO `server_stats` (`server_id`) " ...
				"VALUES (%d)",
				g_iServerId);

			g_hDatabase.Query(Database_OnAddServer, sQuery, 2);
		} else if (iData == 2) {
			Log(TDLogLevel_Info, "Added server to database (%s:%d)", g_sServerIp, g_iServerPort);

			Database_UpdateServer();
		}
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

stock void Database_UpdateServerPlayerCount() {
	char sQuery[512];

	g_hDatabase.Format(sQuery, sizeof(sQuery), 
		"UPDATE `server` " ...
		"SET `players` = %d " ...
		"WHERE `server_id` = %d " ...
		"LIMIT 1",
		GetRealClientCount(), g_iServerId);

	g_hDatabase.Query(Database_OnUpdateServerPlayerCount, sQuery, 0);
}

public void Database_OnUpdateServerPlayerCount(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdateServer > Error: %s", sError);
	}
}

/**
 * Updates a servers info.
 *
 * @noreturn
 */

stock void Database_UpdateServer() {
	char sQuery[512];

	char sServerName[128], sServerNameSave[256];

	GetConVarString(FindConVar("hostname"), sServerName, sizeof(sServerName));
	SQL_EscapeString(g_hDatabase, sServerName, sServerNameSave, sizeof(sServerNameSave));

	char sPassword[32], sPasswordSave[64];
	GetConVarString(FindConVar("sv_password"), sPassword, sizeof(sPassword));
	SQL_EscapeString(g_hDatabase, sPassword, sPasswordSave, sizeof(sPasswordSave));

	g_hDatabase.Format(sQuery, sizeof(sQuery),
		"UPDATE `server` " ...
		"SET `name` = '%s', " ...
			"`version` = '%s', " ...
			"`password` = '%s', " ...
			"`players` = %d, " ...
			"`updated` = UTC_TIMESTAMP() " ...
		"WHERE `server_id` = %d  " ...
		"LIMIT 1",
		sServerNameSave, PLUGIN_VERSION, sPasswordSave, GetRealClientCount(), g_iServerId);

	g_hDatabase.Query(Database_OnUpdateServer, sQuery, 0);
}

public void Database_OnUpdateServer(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdateServer > Error: %s", sError);
	} else {
		char sQuery[256];
		char sCurrentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		if (iData == 0) {
			g_hDatabase.Format(sQuery, sizeof(sQuery),
				"SELECT `map_id`, `respawn_wave_time` " ...
				"FROM `map` " ...
				"WHERE `name` = '%s'  " ...
				"LIMIT 1",
				sCurrentMap);

			g_hDatabase.Query(Database_OnUpdateServer, sQuery, 1);
		} else if (iData == 1) {
			if (SQL_GetRowCount(hResult) == 0) {
				Log(TDLogLevel_Error, "Map \"%s\" is not supported, thus Tower Defense has been disabled.", sCurrentMap);

				g_bEnabled = false;
				UpdateGameDescription();

				if (hResult != null) {
					CloseHandle(hResult);
					hResult = null;
				}

				return;
			}

			SQL_FetchRow(hResult);

			g_iServerMap	   = SQL_FetchInt(hResult, 0);
			g_iRespawnWaveTime = SQL_FetchInt(hResult, 1);

			g_hDatabase.Format(sQuery, sizeof(sQuery), 
				"UPDATE `server` " ...
				"SET `map_id` = %d " ...
				"WHERE `server_id` = %d " ...
				"LIMIT 1",
				g_iServerMap, g_iServerId);

			g_hDatabase.Query(Database_OnUpdateServer, sQuery, 2);
		} else if (iData == 2) {
			Log(TDLogLevel_Info, "Updated server in database (%s:%d)", g_sServerIp, g_iServerPort);

			g_bConfigsExecuted = true;

			Database_CheckServerSettings();
		}
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

/**
 * Checks for the servers settings.
 *
 * @noreturn
 */

stock void Database_CheckServerSettings() {
	char sQuery[256];

	g_hDatabase.Format(sQuery, sizeof(sQuery),
		"SELECT `lockable`, `loglevel`, `logtype` " ...
		"FROM `server` " ...
		"INNER JOIN `server_settings` " ...
			"ON (`server`.`server_settings_id` = `server_settings`.`server_settings_id`) " ...
		"WHERE `server_id` = %d " ...
		"LIMIT 1",
		g_iServerId);

	g_hDatabase.Query(Database_OnCheckServerSettings, sQuery);
}

public void Database_OnCheckServerSettings(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServerSettings > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		char sLockable[32];
		SQL_FetchString(hResult, 0, sLockable, sizeof(sLockable));

		if (StrEqual(sLockable, "not lockable")) {
			g_bLockable = false;
		} else if (StrEqual(sLockable, "lockable")) {
			g_bLockable = true;
		}

		char sLogLevel[32];
		SQL_FetchString(hResult, 1, sLogLevel, sizeof(sLogLevel));

		TDLogLevel iLogLevel;

		if (StrEqual(sLogLevel, "None")) {
			iLogLevel = TDLogLevel_None;
		} else if (StrEqual(sLogLevel, "Error")) {
			iLogLevel = TDLogLevel_Error;
		} else if (StrEqual(sLogLevel, "Warning")) {
			iLogLevel = TDLogLevel_Warning;
		} else if (StrEqual(sLogLevel, "Info")) {
			iLogLevel = TDLogLevel_Info;
		} else if (StrEqual(sLogLevel, "Debug")) {
			iLogLevel = TDLogLevel_Debug;
		} else if (StrEqual(sLogLevel, "Trace")) {
			iLogLevel = TDLogLevel_Trace;
		}

		char sLogType[32];
		SQL_FetchString(hResult, 2, sLogType, sizeof(sLogType));

		TDLogType iLogType;

		if (StrEqual(sLogType, "File")) {
			iLogType = TDLogType_File;
		} else if (StrEqual(sLogType, "Console")) {
			iLogType = TDLogType_Console;
		} else if (StrEqual(sLogType, "File and console")) {
			iLogType = TDLogType_FileAndConsole;
		}

		Log_Initialize(iLogLevel, iLogType);

		Database_CheckServerConfig();
		Database_CheckServerStats();
	} else {
		Database_CheckServerConfig();
		Database_CheckServerStats();
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

/**
 * Checks for the servers config.
 *
 * @noreturn
 */

stock void Database_CheckServerConfig() {
	char sQuery[512];

	g_hDatabase.Format(sQuery, sizeof(sQuery),
		"SELECT CONCAT(`variable`, ' \"', `value`, '\"') " ...
		"FROM `config` " ...
		"INNER JOIN `server` " ...
			"ON (`server_id` = %d) " ...
		"INNER JOIN `server_settings` " ...
			"ON (`server`.`server_settings_id` = `server_settings`.`server_settings_id`) " ...
		"WHERE `config_id` >= `config_start` AND `config_id` <= `config_end` " ...
		"ORDER BY `config_id` ASC",
		g_iServerId);

	g_hDatabase.Query(Database_OnCheckServerConfig, sQuery);
}

public void Database_OnCheckServerConfig(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServerConfig > Error: %s", sError);
	} else {
		char sCommand[260];

		while (SQL_FetchRow(hResult)) {
			SQL_FetchString(hResult, 0, sCommand, sizeof(sCommand));

			ServerCommand("%s", sCommand);
		}

		Database_OnServerChecked();
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

/**
 * Sets the servers password in the database.
 *
 * @param sPassword 	The password to set.
 * @param bReloadMap 	Reload map afterwards.
 * @noreturn
 */

stock void Database_SetServerPassword(const char[] sPassword, bool bReloadMap) {
	char sQuery[128];

	char sPasswordSave[64];
	SQL_EscapeString(g_hDatabase, sPassword, sPasswordSave, sizeof(sPasswordSave));

	g_hDatabase.Format(sQuery, sizeof(sQuery), 
		"UPDATE `server` " ...
		"SET `password` = '%s' " ...
		"WHERE `server_id` = %d " ...
		"LIMIT 1",
		sPasswordSave, g_iServerId);

	DataPack hPack = new DataPack();

	hPack.WriteCell(bReloadMap ? 1 : 0);
	hPack.WriteString(sPassword);

	g_hDatabase.Query(Database_OnSetServerPassword, sQuery, hPack);
}

public void Database_OnSetServerPassword(Handle hDriver, Handle hResult, const char[] sError, DataPack hPack) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_SetServerPassword > Error: %s", sError);
	} else {
		ResetPack(hPack);

		bool bReloadMap = (hPack.ReadCell() == 0 ? false : true);

		char sPassword[32];
		hPack.ReadString(sPassword, sizeof(sPassword));

		Log(TDLogLevel_Debug, "Set server password to \"%s\"", sPassword);

		if (bReloadMap) {
			ReloadMap();
		}
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

/**
 * Checks if server stats does already exist.
 *
 * @noreturn
 */

stock void Database_CheckServerStats() {
	char sQuery[128];

	g_hDatabase.Format(sQuery, sizeof(sQuery), 
		"SELECT `playtime` " ...
		"FROM `server_stats` " ...
		"WHERE `server_id` = %d " ...
		"LIMIT 1",
		g_iServerId);

	g_hDatabase.Query(Database_OnCheckServerStats, sQuery);
}

public void Database_OnCheckServerStats(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServerStats > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No server found, add it

		Database_AddServerStats();
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

stock void Database_AddServerStats() {
	char sQuery[256];

	g_hDatabase.Format(sQuery, sizeof(sQuery), 
		"INSERT INTO `server_stats` (`server_id`) " ...
		"VALUES (%d)",
		g_iServerId);

	g_hDatabase.Query(Database_OnAddServerStats, sQuery);
}

public void Database_OnAddServerStats(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_AddServerStats > Error: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Added server stats (%i)", g_iServerId);
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}

stock void Database_ServerStatsUpdate() {
	char sQuery[1024];

	int	 iConnections, iRounds_Played, iRounds_Won, iPlaytime;

	if (!Server_UGetValue(g_iServerId, SERVER_CONNECTIONS, iConnections))
		iConnections = 0;
	if (!Server_UGetValue(g_iServerId, SERVER_ROUNDS_PLAYED, iRounds_Played))
		iRounds_Played = 0;
	if (!Server_UGetValue(g_iServerId, SERVER_ROUNDS_WON, iRounds_Won))
		iRounds_Won = 0;
	if (!Server_UGetValue(g_iServerId, SERVER_PLAYTIME, iPlaytime))
		iRounds_Won = 0;

	g_hDatabase.Format(sQuery, sizeof(sQuery), 
			"UPDATE `server_stats` " ...
			"SET `connections` = connections + %d, `rounds_played` = rounds_played + %d, `rounds_won` = rounds_won + %d, `playtime` = playtime + %d " ...
			"WHERE `server_id` = %d",
			iConnections, iRounds_Played, iRounds_Won, iPlaytime, g_iServerId);

	Server_USetValue(g_iServerId, SERVER_CONNECTIONS, 0);
	Server_USetValue(g_iServerId, SERVER_ROUNDS_PLAYED, 0);
	Server_USetValue(g_iServerId, SERVER_ROUNDS_WON, 0);
	Server_USetValue(g_iServerId, SERVER_PLAYTIME, 0);

	g_hDatabase.Query(Database_OnServerStatsUpdate, sQuery);
}

public void Database_OnServerStatsUpdate(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_ServerStatsUpdate > Error: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Updated server stats in database (%i)", g_iServerId);
	}

	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
}