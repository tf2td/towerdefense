#pragma semicolon 1

#include <sourcemod>

/**
 * Checks if a player already exists.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @param sCommunityId		The clients 64-bit steam id (community id).
 * @noreturn
 */

stock Database_CheckPlayer(iUserId, iClient, const String:sCommunityId[]) {
	if (!IsDefender(iClient)) {
		return;
	}

	decl String:sQuery[192];

	Format(sQuery, sizeof(sQuery), "\
		SELECT `player_id` \
		FROM `player` \
		WHERE `player`.`steamid64` = '%s' \
		LIMIT 1 \
	", sCommunityId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayer, sQuery, iUserId);
}

public Database_OnCheckPlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No player found, add it

		Database_AddPlayer(iUserId);
	} else {
		SQL_FetchRow(hResult);

		Player_USetValue(iUserId, PLAYER_DATABASE_ID, SQL_FetchInt(hResult, 0));

		Database_UpdatePlayer(iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Adds a player.
 *
 * @param iUserId			The user id on server (unique on server).
 * @noreturn
 */

stock Database_AddPlayer(iUserId) {
	decl String:sQuery[128];
	decl String:sSteamId[32];

	Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sSteamId, sizeof(sSteamId));

	Format(sQuery, sizeof(sQuery), "\
		INSERT INTO `player` (`steamid64`, `first_server`) \
		VALUES ('%s', %d) \
	", sSteamId, g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnAddPlayer_1, sQuery, iUserId);
}

public Database_OnAddPlayer_1(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else {
		decl String:sQuery[32];
		Format(sQuery, sizeof(sQuery), "SELECT LAST_INSERT_ID()");

		SQL_TQuery(g_hDatabase, Database_OnAddPlayer_2, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnAddPlayer_2(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		decl String:sSteamId[32];
		Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Added player %N to database (%s)", GetClientOfUserId(iUserId), sSteamId);

		SQL_FetchRow(hResult);
		
		Player_USetValue(iUserId, PLAYER_DATABASE_ID, SQL_FetchInt(hResult, 0));

		Database_UpdatePlayer(iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Updates a servers info.
 *
 * @param iUserId			The user id on server (unique on server).
 * @noreturn
 */

stock Database_UpdatePlayer(iUserId) {
	decl String:sQuery[512];

	decl String:sPlayerName[MAX_NAME_LENGTH + 1];
	decl String:sPlayerNameSave[MAX_NAME_LENGTH * 2 + 1];

	new iClient = GetClientOfUserId(iUserId);

	GetClientName(iClient, sPlayerName, sizeof(sPlayerName));
	SQL_EscapeString(g_hDatabase, sPlayerName, sPlayerNameSave, sizeof(sPlayerNameSave));

	decl String:sPlayerIp[16];
	decl String:sPlayerIpSave[33];

	Player_UGetString(iUserId, PLAYER_IP_ADDRESS, sPlayerIp, sizeof(sPlayerIp));
	SQL_EscapeString(g_hDatabase, sPlayerIp, sPlayerIpSave, sizeof(sPlayerIpSave));

	new iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player` \
		SET `name` = '%s', \
			`ip` = '%s', \
			`last_server` = %d, \
			`current_server` = %d \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", sPlayerNameSave, sPlayerIpSave, g_iServerId, g_iServerId, iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_1, sQuery, iUserId);
}

public Database_OnUpdatePlayer_1(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		decl String:sQuery[512];

		new iPlayerId;
		Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

		Format(sQuery, sizeof(sQuery), "\
			INSERT IGNORE INTO `player_stats` (`player_id`, `map_id`, `first_connect`, `last_connect`, `last_disconnect`) \
			VALUES (%d, \
					(SELECT `map_id` \
					 FROM `server` \
					 WHERE `server_id` = %d \
					 LIMIT 1), \
					UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP()) \
		", iPlayerId, g_iServerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_2, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayer_2(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		decl String:sQuery[128];

		new iPlayerId;
		Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

		Format(sQuery, sizeof(sQuery), "\
			SELECT `steamid64` \
			FROM `player` \
			WHERE `player_id` = %d \
			LIMIT 1 \
		", iPlayerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_3, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayer_3(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		decl String:sQuery[128];

		Format(sQuery, sizeof(sQuery), "\
			UPDATE `server` \
			SET `players` = `players` + 1 \
			WHERE `server_id` = %d \
			LIMIT 1 \
		", g_iServerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer_4, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayer_4(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		decl String:sSteamId[32];
		SQL_FetchString(hResult, 0, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Updated player %N in database (%s)", GetClientOfUserId(iUserId), sSteamId);

		Database_CheckPlayerBanned(iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks if a player's banned.
 *
 * @param iUserId			The user id on server (unique on server).
 * @noreturn
 */

stock Database_CheckPlayerBanned(iUserId) {
	decl String:sQuery[128];

	new iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player_ban` \
		SET `active` = 'not active' \
		WHERE `player_id` = %d AND `expire` <= UTC_TIMESTAMP() \
	", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerBanned_1, sQuery, iUserId);
}

public Database_OnCheckPlayerBanned_1(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else {
		decl String:sQuery[512];

		new iPlayerId;
		Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

		Format(sQuery, sizeof(sQuery), "\
			SELECT `reason`, CONCAT(`expire`, ' ', 'UTC') \
			FROM `player_ban` \
			WHERE `player_id` = %d AND `active` = 'active' AND `expire` IN (SELECT MAX(`expire`) \
																			FROM `player_ban` \
																			WHERE `player_id` = %d) \
			LIMIT 1 \
		", iPlayerId, iPlayerId);

		SQL_TQuery(g_hDatabase, Database_OnCheckPlayerBanned_2, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnCheckPlayerBanned_2(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new bool:bDontProceed = false;

		new iClient = GetClientOfUserId(iUserId);

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
			Database_CheckPlayerImmunity(iUserId);
		}
	} else {
		Database_CheckPlayerImmunity(iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks a players immunity level.
 *
 * @param iUserId			The user id on server (unique on server).
 * @noreturn
 */

stock Database_CheckPlayerImmunity(iUserId) {
	decl String:sQuery[512];

	new iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

	Format(sQuery, sizeof(sQuery), "\
		SELECT `immunity` \
		FROM `player_immunity` \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerImmunity, sQuery, iUserId);
}

public Database_OnCheckPlayerImmunity(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerImmunity > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new iClient = GetClientOfUserId(iUserId);

		SQL_FetchRow(hResult);
		new iImmunity = SQL_FetchInt(hResult, 0);

		if (iImmunity >= 99 && GetUserAdmin(iClient) == INVALID_ADMIN_ID) {
			new AdminId:iAdmin = CreateAdmin("Admin");

			SetAdminFlag(iAdmin, Admin_Root, true);
			SetUserAdmin(iClient, iAdmin);
		}

		Player_USetValue(iUserId, PLAYER_IMMUNITY, iImmunity);
	} else {
		Player_USetValue(iUserId, PLAYER_IMMUNITY, 0);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Updates a disconnect client things.
 *
 * @param iUserId			The user id on server (unique on server).
 * @noreturn
 */

stock Database_UpdatePlayerDisconnect(iUserId) {
	decl String:sQuery[128];

	new iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player` \
		SET `current_server` = NULL \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnUpdatePlayerDisconnect_1, sQuery, iUserId);
}

public Database_OnUpdatePlayerDisconnect_1(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		decl String:sQuery[128];

		new iPlayerId;
		Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);

		Format(sQuery, sizeof(sQuery), "\
			UPDATE `player_stats` \
			SET `last_disconnect` = UTC_TIMESTAMP() \
			WHERE `player_id` = %d \
			LIMIT 1 \
		", iPlayerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayerDisconnect_2, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayerDisconnect_2(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		decl String:sQuery[128];

		Format(sQuery, sizeof(sQuery), "\
			UPDATE `server` \
			SET `players` = `players` - 1 \
			WHERE `server_id` = %d \
			LIMIT 1 \
		", g_iServerId);

		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayerDisconnect_3, sQuery, iUserId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public Database_OnUpdatePlayerDisconnect_3(Handle:hDriver, Handle:hResult, const String:sError[], any:iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		decl String:sSteamId[32];
		Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Updated disconnected player in database (%s)", sSteamId);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}