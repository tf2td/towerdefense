#pragma semicolon 1

#include <sourcemod>

stock SetUserId(Handle:hPlayerData, iUserId) {
	SetTrieValue(hPlayerData, "player_user_id", iUserId);
}

stock GetUserId(Handle:hPlayerData) {
	new iUserId;
	GetTrieValue(hPlayerData, "player_user_id", iUserId);
	return iUserId;
}

stock SetDatabaseId(Handle:hPlayerData, iDatabaseId) {
	SetTrieValue(hPlayerData, "player_database_id", iDatabaseId);
}

stock GetDatabaseId(Handle:hPlayerData) {
	new iDatabaseId;
	GetTrieValue(hPlayerData, "player_database_id", iDatabaseId);
	return iDatabaseId;
}

stock SetSteamId(Handle:hPlayerData, const String:sSteamId[]) {
	SetTrieString(hPlayerData, "player_steam_id", sSteamId);
}

stock GetSteamId(Handle:hPlayerData, String:sSteamId[], iMaxLength) {
	GetTrieString(hPlayerData, "player_steam_id", sSteamId, iMaxLength);
}

/**
 * Checks if a player already exists.
 *
 * @param iClient			The client.
 * @param sSteamId			The players 64-bit steam id (community id).
 * @noreturn
 */

stock Database_CheckPlayer(iClient, const String:sSteamId[]) {
	if (!IsDefender(iClient)) {
		return;
	}

	decl String:sQuery[192];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `player_id` \
		FROM `player` \
		WHERE `player`.`steamid64` = '%s' \
		LIMIT 1 \
	", sSteamId);

	new Handle:hPlayerData;
	CreateDataMap(hPlayerData);

	SetUserId(hPlayerData, GetClientUserId(iClient));
	SetDatabaseId(hPlayerData, 0);
	SetSteamId(hPlayerData, sSteamId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayer, sQuery, hPlayerData);
}

public Database_OnCheckPlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No player found, add it

		Database_AddPlayer(hPlayerData);
	} else {
		SQL_FetchRow(hResult);

		SetDatabaseId(hPlayerData, SQL_FetchInt(hResult, 0));

		Database_UpdatePlayer(hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Adds a player.
 *
 * @param hPlayerData 			The datamap (trie) handle containing the player info.
 * @noreturn
 */

stock Database_AddPlayer(Handle:hPlayerData) {
	decl String:sQuery[128];
	decl String:sSteamId[32];

	GetSteamId(hPlayerData, sSteamId, sizeof(sSteamId));

	Format(sQuery, sizeof(sQuery), "\
		INSERT INTO `player` (`steamid64`, `first_server`) \
		VALUES ('%s', %d) \
	", sSteamId, g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnAddPlayer_1, sQuery, hPlayerData);
}

public Database_OnAddPlayer_1(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else {
		decl String:sQuery[32];
		Format(sQuery, sizeof(sQuery), "SELECT LAST_INSERT_ID()");

		SQL_TQuery(g_hDatabase, Database_OnAddPlayer_2, sQuery, hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnAddPlayer_2(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		decl String:sSteamId[32];
		GetSteamId(hPlayerData, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Added player %N to database (%s)", GetClientOfUserId(GetUserId(hPlayerData)), sSteamId);

		SQL_FetchRow(hResult);
		
		SetDatabaseId(hPlayerData, SQL_FetchInt(hResult, 0));

		Database_UpdatePlayer(hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Updates a servers info.
 *
 * @param hPlayerData 			The datamap (trie) handle containing the player info.
 * @noreturn
 */

stock Database_UpdatePlayer(Handle:hPlayerData) {
	decl String:sQuery[512];

	decl String:sPlayerName[MAX_NAME_LENGTH + 1];
	decl String:sPlayerNameSave[MAX_NAME_LENGTH * 2 + 1];

	new iClient = GetClientOfUserId(GetUserId(hPlayerData));

	GetClientName(iClient, sPlayerName, sizeof(sPlayerName));
	SQL_EscapeString(g_hDatabase, sPlayerName, sPlayerNameSave, sizeof(sPlayerNameSave));

	decl String:sPlayerIp[16];
	decl String:sPlayerIpSave[33];

	GetClientIP(iClient, sPlayerIp, sizeof(sPlayerIp));
	SQL_EscapeString(g_hDatabase, sPlayerIp, sPlayerIpSave, sizeof(sPlayerIpSave));

	new iPlayerId = GetDatabaseId(hPlayerData);

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player` \
		SET `name` = '%s', \
			`ip` = '%s', \
			`last_server` = %d, \
			`current_server` = %d \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", sPlayerNameSave, sPlayerIpSave, g_iServerId, g_iServerId, iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_1, sQuery, hPlayerData);
}

public Database_OnUpdatePlayer_1(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		decl String:sQuery[512];

		new iPlayerId = GetDatabaseId(hPlayerData);

		Format(sQuery, sizeof(sQuery), "\
			INSERT IGNORE INTO `player_stats` (`player_id`, `map_id`, `first_connect`, `last_connect`, `last_disconnect`) \
			VALUES (%d, \
					(SELECT `map_id` \
					 FROM `server` \
					 WHERE `server_id` = %d \
					 LIMIT 1), \
					UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP()) \
		", iPlayerId, g_iServerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_2, sQuery, hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayer_2(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		decl String:sQuery[128];

		new iPlayerId = GetDatabaseId(hPlayerData);

		Format(sQuery, sizeof(sQuery), "\
			SELECT `steamid64` \
			FROM `player` \
			WHERE `player_id` = %d \
			LIMIT 1 \
		", iPlayerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_3, sQuery, hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayer_3(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		decl String:sSteamId[32];
		SQL_FetchString(hResult, 0, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Updated player %N in database (%s)", GetClientOfUserId(GetUserId(hPlayerData)), sSteamId);

		Database_CheckPlayerBanned(hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks if a player's banned.
 *
 * @param hPlayerData 			The datamap (trie) handle containing the player info.
 * @noreturn
 */

stock Database_CheckPlayerBanned(Handle:hPlayerData) {
	decl String:sQuery[128];

	new iPlayerId = GetDatabaseId(hPlayerData);

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player_ban` \
		SET `active` = 'not active' \
		WHERE `player_id` = %d AND `expire` <= UTC_TIMESTAMP() \
	", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerBanned_1, sQuery, hPlayerData);
}

public Database_OnCheckPlayerBanned_1(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		decl String:sQuery[512];

		new iPlayerId = GetDatabaseId(hPlayerData);

		Format(sQuery, sizeof(sQuery), "\
			SELECT `reason`, CONCAT(`expire`, ' ', 'UTC') \
			FROM `player_ban` \
			WHERE `player_id` = %d AND `active` = 'active' AND `expire` IN (SELECT MAX(`expire`) \
																			FROM `player_ban` \
																			WHERE `player_id` = %d) \
			LIMIT 1 \
		", iPlayerId, iPlayerId);

		SQL_TQuery(g_hDatabase, Database_OnCheckPlayerBanned_2, sQuery, hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnCheckPlayerBanned_2(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new bool:bDontProceed = false;

		new iClient = GetClientOfUserId(GetUserId(hPlayerData));

		SQL_FetchRow(hResult);

		decl String:sReason[256], String:sExpire[32];

		SQL_FetchString(hResult, 0, sReason, sizeof(sReason));
		SQL_FetchString(hResult, 1, sExpire, sizeof(sExpire));

		if (strlen(sReason) > 0) {
			KickClient(iClient, "You have been banned from TF2 Tower Defense until %s! Reason: %s", sExpire, sReason);
			bDontProceed = true;
		} else {
			KickClient(iClient, "You have been banned from TF2 Tower Defense until %s!", sExpire);
			bDontProceed = true;
		}

		if (!bDontProceed) {
			Database_CheckPlayerImmunity(hPlayerData);
		}
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks a players immunity level.
 *
 * @param hPlayerData 			The datamap (trie) handle containing the player info.
 * @noreturn
 */

stock Database_CheckPlayerImmunity(Handle:hPlayerData) {
	decl String:sQuery[512];

	new iPlayerId = GetDatabaseId(hPlayerData);

	Format(sQuery, sizeof(sQuery), "\
		SELECT `immunity` \
		FROM `player_immunity` \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerImmunity, sQuery, hPlayerData);
}

public Database_OnCheckPlayerImmunity(Handle:hDriver, Handle:hResult, const String:sError[], any:hPlayerData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerImmunity > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new iClient = GetClientOfUserId(GetUserId(hPlayerData));

		SQL_FetchRow(hResult);
		new iImmunity = SQL_FetchInt(hResult, 0);

		if (iImmunity >= 99 && GetUserAdmin(iClient) == INVALID_ADMIN_ID) {
			new AdminId:iAdmin = CreateAdmin("Admin");

			SetAdminFlag(iAdmin, Admin_Root, true);
			SetUserAdmin(iClient, iAdmin);
		}

		CloseHandle(hPlayerData);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}