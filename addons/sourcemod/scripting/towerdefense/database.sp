#pragma semicolon 1

#include <sourcemod>

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

	if (g_hDatabase == INVALID_HANDLE) {
		decl String:sPassword[128];
		MD5String(DATABASE_PASS, sPassword, sizeof(sPassword));

		new Handle:hKeyValues = CreateKeyValues("");
		KvSetString(hKeyValues, "host", DATABASE_HOST);
		KvSetString(hKeyValues, "database", DATABASE_NAME);
		KvSetString(hKeyValues, "user", DATABASE_USER);
		KvSetString(hKeyValues, "pass", sPassword);

		new String:sError[512];
		g_hDatabase = SQL_ConnectCustom(hKeyValues, sError, sizeof(sError), true);
		CloseHandle(hKeyValues);

		if (g_hDatabase == INVALID_HANDLE) {
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

/*========================================
=            Server Functions            =
========================================*/

/**
 * Checks if a server does already exist.
 *
 * @noreturn
 */

stock Database_CheckServer() {
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "CALL GetServerInfo('%s', %d)", m_sServerIp, m_iServerPort);

	SQL_TQuery(g_hDatabase, Database_OnCheckServer, sQuery);
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
	decl String:sQuery[512];

	Format(sQuery, sizeof(sQuery), "CALL AddServer('%s', %d, '%s')", m_sServerIp, m_iServerPort, PLUGIN_HOST);

	SQL_TQuery(g_hDatabase, Database_OnAddServer, sQuery);
}

public Database_OnAddServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_AddServer > Error: %s", sError);
	} else {
		Log(TDLogLevel_Info, "Added server to database (%s:%d)", m_sServerIp, m_iServerPort);
		
		SQL_FetchRow(hResult);
		m_iServerId = SQL_FetchInt(hResult, 0);

		Database_UpdateServer();
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

	Format(sQuery, sizeof(sQuery), "CALL UpdateServer(%d, '%s', '%s', '%s', %d)", m_iServerId, sServerNameSave, PLUGIN_VERSION, sPasswordSave, GetRealClientCount());

	SQL_TQuery(g_hDatabase, Database_OnUpdateServer, sQuery, 0);
}

public Database_OnUpdateServer(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_UpdateServer > Error: %s", sError);
	} else {
		decl String:sQuery[128];
		decl String:sCurrentMap[PLATFORM_MAX_PATH];
		GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

		if (iData == 0) {
			Format(sQuery, sizeof(sQuery), "CALL GetMapInfo('%s')", sCurrentMap);

			SQL_TQuery(g_hDatabase, Database_OnUpdateServer, sQuery, 1);
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

			Format(sQuery, sizeof(sQuery), "CALL UpdateServerMap(%d, %d)", m_iServerId, m_iServerMap);

			SQL_TQuery(g_hDatabase, Database_OnUpdateServer, sQuery, 2);
		} else if (iData == 2) {
			Log(TDLogLevel_Info, "Updated server in database (%s:%d)", m_sServerIp, m_iServerPort);

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

	Format(sQuery, sizeof(sQuery), "CALL GetServerDelete(%d)", m_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckForDelete, sQuery);
}

public Database_OnCheckForDelete(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckForDelete > Error: %s", sError);
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
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "CALL GetServerVerified(%d)", m_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckServerVerified, sQuery);
}

public Database_OnCheckServerVerified(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckServerVerified > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		decl String:sVerfied[32];
		SQL_FetchString(hResult, 0, sVerfied, sizeof(sVerfied));

		if (StrEqual(sVerfied, "verified")) {
			Database_CheckForUpdates();
		} else {
			LogType(TDLogLevel_Warning, TDLogType_FileAndConsole, "Your server is not verified, please contact us at tf2td.net or on Steam");

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
 * Checks for plugin updates.
 *
 * @noreturn
 */

stock Database_CheckForUpdates() {
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "CALL GetServerUpdate(%d)", m_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckForUpdates, sQuery);
}

public Database_OnCheckForUpdates(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckForUpdates > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		decl String:sUrl[256];
		SQL_FetchString(hResult, 0, sUrl, sizeof(sUrl));

		if (StrEqual(sUrl, "")) {
			Database_LoadTowers();
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

stock bool:Database_UpdatedServer() {
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "CALL UpdatedServer(%d)", m_iServerId);
	 
	SQL_LockDatabase(g_hDatabase);
		
	new Handle:hQuery = SQL_Query(g_hDatabase, sQuery);

	if (hQuery == INVALID_HANDLE) {
		decl String:sError[256];
		SQL_GetError(g_hDatabase, sError, sizeof(sError));
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_UpdatedServer > Error: %s", sError);

		SQL_UnlockDatabase(g_hDatabase);
		return false;
	}

	new bool:bResult = (SQL_FetchRow(hQuery) && SQL_FetchInt(hQuery, 0) == 0);

	SQL_UnlockDatabase(g_hDatabase);
	CloseHandle(hQuery);

	return bResult;
}

/*========================================
=            Player Functions            =
========================================*/

/**
 * Checks if a player already exists.
 *
 * @param iClient			The client.
 * @param sSteamId			The players 64-bit steam id (community id).
 * @noreturn
 */

stock Database_CheckPlayer(iClient, const String:sSteamId[]) {
	decl String:sQuery[128];

	Format(sQuery, sizeof(sQuery), "CALL GetPlayerInfo('%s')", sSteamId);

	new Handle:hPack = CreateDataPack();

	WritePackCell(hPack, GetClientUserId(iClient));		//  0 - user id
	WritePackCell(hPack, 0);							//  8 - database id
	WritePackString(hPack, sSteamId);					// 16 - steam id

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayer, sQuery, hPack);
}

public Database_OnCheckPlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No player found, add it

		SetPackPosition(hPack, 16);
		decl String:sSteamId[32];
		ReadPackString(hPack, sSteamId, sizeof(sSteamId));

		Database_AddPlayer(hPack);
	} else {
		SQL_FetchRow(hResult);

		SetPackPosition(hPack, 8);
		WritePackCell(hPack, SQL_FetchInt(hResult, 0));

		Database_UpdatePlayer(hPack);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Adds a player.
 *
 * @param hPack 			The datapack handle containing the player info.
 * @noreturn
 */

stock Database_AddPlayer(Handle:hPack) {
	decl String:sQuery[512];
	decl String:sSteamId[32];

	SetPackPosition(hPack, 16);
	ReadPackString(hPack, sSteamId, sizeof(sSteamId));

	Format(sQuery, sizeof(sQuery), "CALL AddPlayer('%s', %d)", sSteamId, m_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnAddPlayer, sQuery, hPack);
}

public Database_OnAddPlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else {
		SetPackPosition(hPack, 16);

		decl String:sSteamId[32];
		ReadPackString(hPack, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Added player to database (%s)", sSteamId);

		SQL_FetchRow(hResult);
		
		SetPackPosition(hPack, 8);
		WritePackCell(hPack, SQL_FetchInt(hResult, 0));

		Database_UpdatePlayer(hPack);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Updates a servers info.
 *
 * @param hPack 			The datapack handle containing the player info.
 * @noreturn
 */

stock Database_UpdatePlayer(Handle:hPack) {
	decl String:sQuery[512];

	decl String:sPlayerName[MAX_NAME_LENGTH + 1];
	decl String:sPlayerNameSave[MAX_NAME_LENGTH * 2 + 1];

	SetPackPosition(hPack, 0);

	new iClient = GetClientOfUserId(ReadPackCell(hPack));

	GetClientName(iClient, sPlayerName, sizeof(sPlayerName));
	SQL_EscapeString(g_hDatabase, sPlayerName, sPlayerNameSave, sizeof(sPlayerNameSave));

	decl String:sPlayerIp[16];
	decl String:sPlayerIpSave[33];

	GetClientIP(iClient, sPlayerIp, sizeof(sPlayerIp));
	SQL_EscapeString(g_hDatabase, sPlayerIp, sPlayerIpSave, sizeof(sPlayerIpSave));

	SetPackPosition(hPack, 8);

	new iPlayerId = ReadPackCell(hPack);

	Format(sQuery, sizeof(sQuery), "CALL UpdatePlayer(%d, '%s', '%s', %d)", iPlayerId, sPlayerNameSave, sPlayerIpSave, m_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer, sQuery, hPack);
}

public Database_OnUpdatePlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		SQL_FetchRow(hResult);

		decl String:sSteamId[32];
		SQL_FetchString(hResult, 0, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Updated player in database (%s)", sSteamId);

		Database_CheckPlayerImmunity(hPack);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks a players immunity level.
 *
 * @param hPack 			The datapack handle containing the player info.
 * @noreturn
 */

stock Database_CheckPlayerImmunity(Handle:hPack) {
	decl String:sQuery[512];

	SetPackPosition(hPack, 8);
	new iPlayerId = ReadPackCell(hPack);

	Format(sQuery, sizeof(sQuery), "CALL GetPlayerImmunity(%d)", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerImmunity, sQuery, hPack);
}

public Database_OnCheckPlayerImmunity(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Query failed at Database_CheckPlayerImmunity > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SetPackPosition(hPack, 0);
		new iClient = GetClientOfUserId(ReadPackCell(hPack));

		SQL_FetchRow(hResult);
		new iImmunity = SQL_FetchInt(hResult, 0);

		if (iImmunity >= 99 && GetUserAdmin(iClient) == INVALID_ADMIN_ID) {
			new AdminId:iAdmin = CreateAdmin("Admin");

			SetAdminFlag(iAdmin, Admin_Root, true);
			SetUserAdmin(iClient, iAdmin);
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
	decl String:sQuery[128];
	
	Format(sQuery, sizeof(sQuery), "CALL GetTowers(%d)", m_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadTowers, sQuery);
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

	Database_LoadWeapons();
}

/**
 * Loads weapons to its map.
 *
 * @noreturn
 */

stock Database_LoadWeapons() {
	decl String:sQuery[128];
	
	Format(sQuery, sizeof(sQuery), "CALL GetWeapons()");
	
	SQL_TQuery(g_hDatabase, Database_OnLoadWeapons, sQuery);
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

	Database_LoadWaves();
}

/**
 * Loads waves to its map.
 *
 * @noreturn
 */

stock Database_LoadWaves() {
	decl String:sQuery[128];
	
	Format(sQuery, sizeof(sQuery), "CALL GetWaves(%d)", m_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadWaves, sQuery);
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

	Database_LoadMetalpacks();
}

/**
 * Loads metalpacks to its map.
 *
 * @noreturn
 */

stock Database_LoadMetalpacks() {
	decl String:sQuery[128];
	
	Format(sQuery, sizeof(sQuery), "CALL GetMetalpacks(%d)", m_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadMetalpacks, sQuery);
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