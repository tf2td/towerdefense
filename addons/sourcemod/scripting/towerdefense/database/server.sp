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

stock Database_CheckServer() {
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `server_id` \
		FROM `server` \
		WHERE `ip` = '%s' AND `port` = %d \
		LIMIT 1 \
	", g_sServerIp, g_iServerPort);

	SQL_TQuery(g_hDatabase, Database_OnCheckServer, sQuery);
}

public Database_OnCheckServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No server found, add it

		Database_AddServer();
	} else {
		SQL_FetchRow(hResult);

		g_iServerId = SQL_FetchInt(hResult, 0);

		Database_UpdateServer();
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
	decl String:sQuery[256];

	Format(sQuery, sizeof(sQuery), "\
		INSERT INTO `server` (`ip`, `port`, `host_id`, `created`, `updated`) \
		VALUES ('%s', %d, (SELECT `host_id` \
						   FROM `host` \
						   WHERE `name` = '%s' \
						   LIMIT 1), UTC_TIMESTAMP(), UTC_TIMESTAMP()) \
	", g_sServerIp, g_iServerPort, PLUGIN_HOST);

	SQL_TQuery(g_hDatabase, Database_OnAddServer, sQuery, 0);
}

public Database_OnAddServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddServer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		decl String:sQuery[256];

		if (iData == 0) {
			Format(sQuery, sizeof(sQuery), "\
				SELECT `server_id` \
				FROM `server` \
				WHERE `ip` = '%s' AND `port` = %d \
				LIMIT 1 \
			", g_sServerIp, g_iServerPort);

			SQL_TQuery(g_hDatabase, Database_OnAddServer, sQuery, 1);
		} else if (iData == 1) {
			SQL_FetchRow(hResult);
			g_iServerId = SQL_FetchInt(hResult, 0);

			Format(sQuery, sizeof(sQuery), "\
				INSERT INTO `server_stats` (`server_id`) \
				VALUES (%d) \
			", g_iServerId);

			SQL_TQuery(g_hDatabase, Database_OnAddServer, sQuery, 2);
		} else if (iData == 2) {
			Log(TDLogLevel_Info, "Added server to database (%s:%d)", g_sServerIp, g_iServerPort);
		
			Database_UpdateServer();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Updates a servers info.
 *
 * @noreturn
 */

stock Database_UpdateServer() {
	decl String:sQuery[512];

	decl String:sServerName[128], String:sServerNameSave[256];

	GetConVarString(FindConVar("hostname"), sServerName, sizeof(sServerName));
	SQL_EscapeString(g_hDatabase, sServerName, sServerNameSave, sizeof(sServerNameSave));

	decl String:sPassword[32], String:sPasswordSave[64];
	GetConVarString(FindConVar("sv_password"), sPassword, sizeof(sPassword));
	SQL_EscapeString(g_hDatabase, sPassword, sPasswordSave, sizeof(sPasswordSave));

	decl String:sRconPassword[256], String:sRconPasswordSave[512];
	GetRconPassword(sRconPassword, sizeof(sRconPassword));
	SQL_EscapeString(g_hDatabase, sRconPassword, sRconPasswordSave, sizeof(sRconPasswordSave));

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `server` \
		SET `name` = '%s', \
			`version` = '%s', \
			`password` = '%s', \
			`rcon_password` = '%s', \
			`players` = %d, \
			`updated` = UTC_TIMESTAMP() \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", sServerNameSave, PLUGIN_VERSION, sPasswordSave, sRconPasswordSave, GetRealClientCount(), g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnUpdateServer, sQuery, 0);
}

public Database_OnUpdateServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdateServer > Error: %s", sError);
	} else {
		decl String:sQuery[256];
		decl String:sCurrentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		if (iData == 0) {
			Format(sQuery, sizeof(sQuery), "\
				SELECT `map_id`, `respawn_wave_time` \
				FROM `map` \
				WHERE `name` = '%s' \
				LIMIT 1 \
			", sCurrentMap);

			SQL_TQuery(g_hDatabase, Database_OnUpdateServer, sQuery, 1);
		} else if (iData == 1) {
			if (SQL_GetRowCount(hResult) == 0) {
				Log(TDLogLevel_Error, "Map \"%s\" is not supported, thus Tower Defense has been disabled.", sCurrentMap);
				
				g_bEnabled = false;
				UpdateGameDescription();

				if (hResult != INVALID_HANDLE) {
					CloseHandle(hResult);
					hResult = INVALID_HANDLE;
				}

				return;
			}

			SQL_FetchRow(hResult);

			g_iServerMap = SQL_FetchInt(hResult, 0);
			g_iRespawnWaveTime = SQL_FetchInt(hResult, 1);

			Format(sQuery, sizeof(sQuery), "\
				UPDATE `server` \
				SET `map_id` = %d \
				WHERE `server_id` = %d \
				LIMIT 1 \
			", g_iServerMap, g_iServerId);

			SQL_TQuery(g_hDatabase, Database_OnUpdateServer, sQuery, 2);
		} else if (iData == 2) {
			Log(TDLogLevel_Info, "Updated server in database (%s:%d)", g_sServerIp, g_iServerPort);

			g_bConfigsExecuted = true;

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
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `delete` \
		FROM `server` \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckForDelete, sQuery);
}

public Database_OnCheckForDelete(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckForDelete > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		decl String:sDelete[32];
		SQL_FetchString(hResult, 0, sDelete, sizeof(sDelete));

		if (StrEqual(sDelete, "delete")) {
			decl String:sFile[PLATFORM_MAX_PATH], String:sPath[PLATFORM_MAX_PATH];
			
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
			BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "plugins/%s", sFile);			

			if (FileExists(sPath)) {
				if (DeleteFile(sPath)) {
					ServerCommand("sm plugins unload %s", sFile);
				}
			}
		} else {
			Database_CheckServerSettings();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks for the servers settings.
 *
 * @noreturn
 */

stock Database_CheckServerSettings() {
	decl String:sQuery[256];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `lockable`, `loglevel`, `logtype` \
		FROM `server` \
		INNER JOIN `server_settings` \
			ON (`server`.`server_settings_id` = `server_settings`.`server_settings_id`) \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckServerSettings, sQuery);
}

public Database_OnCheckServerSettings(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServerSettings > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		decl String:sLockable[32];
		SQL_FetchString(hResult, 0, sLockable, sizeof(sLockable));

		if (StrEqual(sLockable, "not lockable")) {
			g_bLockable = false;
		} else if (StrEqual(sLockable, "lockable")) {
			g_bLockable = true;
		}

		decl String:sLogLevel[32];
		SQL_FetchString(hResult, 1, sLogLevel, sizeof(sLogLevel));
		
		new TDLogLevel:iLogLevel;

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

		decl String:sLogType[32];
		SQL_FetchString(hResult, 2, sLogType, sizeof(sLogType));

		new TDLogType:iLogType;

		if (StrEqual(sLogType, "File")) {
			iLogType = TDLogType_File;
		} else if (StrEqual(sLogType, "Console")) {
			iLogType = TDLogType_Console;
		} else if (StrEqual(sLogType, "File and console")) {
			iLogType = TDLogType_FileAndConsole;
		}

		Log_Initialize(iLogLevel, iLogType);

		Database_CheckServerVerified();
	} else {
		Database_CheckServerVerified();
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

stock Database_CheckServerVerified() {
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `verified` \
		FROM `server` \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckServerVerified, sQuery);
}

public Database_OnCheckServerVerified(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServerVerified > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		decl String:sVerfied[32];
		SQL_FetchString(hResult, 0, sVerfied, sizeof(sVerfied));

		if (StrEqual(sVerfied, "verified")) {
			Database_CheckServerConfig();
		} else {
			Log(TDLogLevel_Warning, "Your server is not verified, please contact us at tf2td.net or on Steam");

			decl String:sFile[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
			ServerCommand("sm plugins unload %s", sFile);
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks for the servers config.
 *
 * @noreturn
 */

stock Database_CheckServerConfig() {
	decl String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "\
		SELECT CONCAT(`variable`, ' \"', `value`, '\"') \
		FROM `config` \
		INNER JOIN `server` \
			ON (`server_id` = %d) \
		INNER JOIN `server_settings` \
			ON (`server`.`server_settings_id` = `server_settings`.`server_settings_id`) \
		WHERE `config_id` >= `config_start` AND `config_id` <= `config_end` \
		ORDER BY `config_id` ASC \
	", g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckServerConfig, sQuery);
}

public Database_OnCheckServerConfig(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckServerConfig > Error: %s", sError);
	} else {
		decl String:sCommand[260];

		while (SQL_FetchRow(hResult)) {
			SQL_FetchString(hResult, 0, sCommand, sizeof(sCommand));

			ServerCommand("%s", sCommand);
		}
		
		Database_CheckForUpdates();
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
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "\
		SELECT IF(`update` = 'update', '', `update_url`) \
		FROM `server` \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckForUpdates, sQuery);
}

public Database_OnCheckForUpdates(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckForUpdates > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		decl String:sUrl[256];
		SQL_FetchString(hResult, 0, sUrl, sizeof(sUrl));

		if (StrEqual(sUrl, "")) {
			Database_OnServerChecked();
		} else {
			Log(TDLogLevel_Info, "Plugin update pending. Updating now ...");

			decl String:sFile[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));

			decl String:sPath[PLATFORM_MAX_PATH];
			Format(sPath, sizeof(sPath), "addons/sourcemod/plugins/%s", sFile);

			Updater_Download(sUrl, sPath);
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Tells the database that the servers plugin got updated.
 *
 * @return				True on success, false otherwise.
 */

stock bool:Database_UpdatedServer() {
	decl String:sQuery[128];
	new Handle:hQuery = INVALID_HANDLE;

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `server` \
		SET `update` = 0 \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", g_iServerId);
	 
	SQL_LockDatabase(g_hDatabase);
		
	hQuery = SQL_Query(g_hDatabase, sQuery);

	if (hQuery == INVALID_HANDLE) {
		decl String:sError[256];
		SQL_GetError(g_hDatabase, sError, sizeof(sError));
		Log(TDLogLevel_Error, "Query failed at Database_UpdatedServer > Error: %s", sError);

		SQL_UnlockDatabase(g_hDatabase);
		return false;
	}

	Format(sQuery, sizeof(sQuery), "\
		SELECT `update` \
		FROM `server` \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", g_iServerId);
	 
	SQL_LockDatabase(g_hDatabase);
		
	hQuery = SQL_Query(g_hDatabase, sQuery);

	if (hQuery == INVALID_HANDLE) {
		decl String:sError[256];
		SQL_GetError(g_hDatabase, sError, sizeof(sError));
		Log(TDLogLevel_Error, "Query failed at Database_UpdatedServer > Error: %s", sError);

		SQL_UnlockDatabase(g_hDatabase);
		return false;
	}

	new bool:bResult = (SQL_FetchRow(hQuery) && SQL_FetchInt(hQuery, 0) == 0);

	SQL_UnlockDatabase(g_hDatabase);
	CloseHandle(hQuery);

	return bResult;
}

/**
 * Sets the servers password in the database.
 *
 * @param sPassword 	The password to set.
 * @param bReloadMap 	Reload map afterwards.
 * @noreturn
 */

stock Database_SetServerPassword(const String:sPassword[], bool:bReloadMap) {
	decl String:sQuery[128];

	decl String:sPasswordSave[64];
	SQL_EscapeString(g_hDatabase, sPassword, sPasswordSave, sizeof(sPasswordSave));

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `server` \
		SET `password` = '%s' \
		WHERE `server_id` = %d \
		LIMIT 1 \
	", sPasswordSave, g_iServerId);

	new Handle:hPack = CreateDataPack();

	WritePackCell(hPack, bReloadMap ? 1 : 0);
	WritePackString(hPack, sPassword);

	SQL_TQuery(g_hDatabase, Database_OnSetServerPassword, sQuery, hPack);
}

public Database_OnSetServerPassword(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_SetServerPassword > Error: %s", sError);
	} else {
		ResetPack(hPack);

		new bool:bReloadMap = (ReadPackCell(hPack) == 0 ? false : true);

		decl String:sPassword[32];
		ReadPackString(hPack, sPassword, sizeof(sPassword));

		Log(TDLogLevel_Debug, "Set server password to \"%s\"", sPassword);

		if (bReloadMap) {
			ReloadMap();
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}