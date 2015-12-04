#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Checks if a player already exists.
 *
 * @param iUserId			The user id on server (unique on server).
 * @param iClient			The client.
 * @param sCommunityId		The clients 64-bit steam id (community id).
 * @noreturn
 */

stock void Database_CheckPlayer(int iUserId, int iClient, const char[] sCommunityId) {
	if (!IsDefender(iClient)) {
		return;
	}
	
	char sQuery[192];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `player_id` \
		FROM `player` \
		WHERE `player`.`steamid64` = '%s' \
		LIMIT 1 \
	", sCommunityId);
	
	SQL_TQuery(g_hDatabase, Database_OnCheckPlayer, sQuery, iUserId);
}

public void Database_OnCheckPlayer(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
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

stock void Database_AddPlayer(int iUserId) {
	char sQuery[128];
	char sSteamId[32];
	
	Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sSteamId, sizeof(sSteamId));
	
	Format(sQuery, sizeof(sQuery), "\
		INSERT INTO `player` (`steamid64`, `first_server`) \
		VALUES ('%s', %d) \
	", sSteamId, g_iServerId);
	
	SQL_TQuery(g_hDatabase, Database_OnAddPlayer_1, sQuery, iUserId);
}

public void Database_OnAddPlayer_1(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else {
		char sQuery[32];
		Format(sQuery, sizeof(sQuery), "SELECT LAST_INSERT_ID()");
		
		SQL_TQuery(g_hDatabase, Database_OnAddPlayer_2, sQuery, iUserId);
	}
	
	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public void Database_OnAddPlayer_2(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		char sSteamId[32];
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

stock void Database_UpdatePlayer(int iUserId) {
	char sQuery[512];
	
	char sPlayerName[MAX_NAME_LENGTH + 1];
	char sPlayerNameSave[MAX_NAME_LENGTH * 2 + 1];
	
	int iClient = GetClientOfUserId(iUserId);
	
	GetClientName(iClient, sPlayerName, sizeof(sPlayerName));
	SQL_EscapeString(g_hDatabase, sPlayerName, sPlayerNameSave, sizeof(sPlayerNameSave));
	
	char sPlayerIp[16];
	char sPlayerIpSave[33];
	
	Player_UGetString(iUserId, PLAYER_IP_ADDRESS, sPlayerIp, sizeof(sPlayerIp));
	SQL_EscapeString(g_hDatabase, sPlayerIp, sPlayerIpSave, sizeof(sPlayerIpSave));
	
	int iPlayerId;
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

public void Database_OnUpdatePlayer_1(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		char sQuery[512];
		
		int iPlayerId;
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

public void Database_OnUpdatePlayer_2(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else {
		char sQuery[128];
		
		int iPlayerId;
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

public void Database_OnUpdatePlayer_3(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		char sQuery[128];
		
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

public void Database_OnUpdatePlayer_4(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);
		
		char sSteamId[32];
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

stock void Database_CheckPlayerBanned(int iUserId) {
	char sQuery[128];
	
	int iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);
	
	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player_ban` \
		SET `active` = 'not active' \
		WHERE `player_id` = %d AND `expire` <= UTC_TIMESTAMP() \
	", iPlayerId);
	
	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerBanned_1, sQuery, iUserId);
}

public void Database_OnCheckPlayerBanned_1(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else {
		char sQuery[512];
		
		int iPlayerId;
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

public void Database_OnCheckPlayerBanned_2(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		bool bDontProceed = false;
		
		int iClient = GetClientOfUserId(iUserId);
		
		SQL_FetchRow(hResult);
		
		char sReason[256], sExpire[32];
		
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

stock void Database_CheckPlayerImmunity(int iUserId) {
	char sQuery[512];
	
	int iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `immunity` \
		FROM `player_immunity` \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", iPlayerId);
	
	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerImmunity, sQuery, iUserId);
}

public void Database_OnCheckPlayerImmunity(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerImmunity > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		int iClient = GetClientOfUserId(iUserId);
		
		SQL_FetchRow(hResult);
		int iImmunity = SQL_FetchInt(hResult, 0);
		
		if (iImmunity >= 99 && GetUserAdmin(iClient) == INVALID_ADMIN_ID) {
			AdminId iAdmin = CreateAdmin("Admin");
			
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

stock void Database_UpdatePlayerDisconnect(int iUserId) {
	char sQuery[128];
	
	int iPlayerId;
	Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);
	
	Format(sQuery, sizeof(sQuery), "\
		UPDATE `player` \
		SET `current_server` = NULL \
		WHERE `player_id` = %d \
		LIMIT 1 \
	", iPlayerId);
	
	SQL_TQuery(g_hDatabase, Database_OnUpdatePlayerDisconnect_1, sQuery, iUserId);
}

public void Database_OnUpdatePlayerDisconnect_1(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		char sQuery[128];
		
		int iPlayerId;
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

public void Database_OnUpdatePlayerDisconnect_2(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		char sQuery[128];
		
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

public void Database_OnUpdatePlayerDisconnect_3(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		char sSteamId[32];
		Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sSteamId, sizeof(sSteamId));
		
		Log(TDLogLevel_Info, "Updated disconnected player in database (%s)", sSteamId);
		
		int iPlayerId;
		Player_UGetValue(iUserId, PLAYER_DATABASE_ID, iPlayerId);
		
		//Get Saved Player Info
		int iKills, iAssists, iDeaths, iDamage, iObjects_Built, iTowers_Bought, iMetal_Pick, iMetal_Drop, iWaves_Played, iRounds_Won, iPlayTime;
		Player_UGetValue(iUserId, PLAYER_KILLS, iKills);
		Player_UGetValue(iUserId, PLAYER_ASSISTS, iAssists);
		Player_UGetValue(iUserId, PLAYER_DEATHS, iDeaths);
		Player_UGetValue(iUserId, PLAYER_DAMAGE, iDamage);
		Player_UGetValue(iUserId, PLAYER_OBJECTS_BUILT, iObjects_Built);
		Player_UGetValue(iUserId, PLAYER_TOWERS_BOUGHT, iTowers_Bought);
		Player_UGetValue(iUserId, PLAYER_METAL_PICK, iMetal_Pick);
		Player_UGetValue(iUserId, PLAYER_METAL_DROP, iMetal_Drop);
		Player_UGetValue(iUserId, PLAYER_WAVES_PLAYED, iWaves_Played);
		Player_UGetValue(iUserId, PLAYER_ROUNDS_WON, iRounds_Won);
		if(iKills == -1)
			iKills = 0;
		if(iAssists == -1)
			iAssists = 0;
		if(iDeaths == -1)
			iDeaths = 0;
		if(iDamage == -1)
			iDamage = 0;
		if(iObjects_Built == -1)
			iObjects_Built = 0;
		if(iTowers_Bought == -1)
			iTowers_Bought = 0;
		if(iMetal_Pick == -1)
			iMetal_Pick = 0;
		if(iMetal_Drop == -1)
			iMetal_Drop = 0;
		if(iWaves_Played == -1)
			iWaves_Played = 0;
		if(iRounds_Won == -1)
			iRounds_Won = 0;
			
		//Update Player info based on saved info	
		char sQuery[255];
		Format(sQuery, sizeof(sQuery), "\
			UPDATE `player_stats` \
			SET `kills` = kills + %d, `assists` = assists + %d, `deaths` = deaths + %d, `damage` = damage + %d, \
			`objects_built` = objects_built + %d, `towers_bought` = towers_bought + %d, `metal_pick` = metal_pick + %d, \
			`metal_drop` = metal_drop + %d, `waves_played` = waves_played + %d, `rounds_won` = rounds_won + %d, `playtime` = playtime + %d  \
			WHERE `player_id` = %d AND map_id = %d \
		", iKills, iAssists, iDeaths, iDamage, iObjects_Built, iTowers_Bought, iMetal_Pick, iMetal_Drop, iWaves_Played, iRounds_Won, iPlayTime, iPlayerId, g_iServerMap);
		
		SQL_TQuery(g_hDatabase, Database_OnUpdatePlayerDisconnect_4, sQuery, iUserId);
	}
	
	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

public void Database_OnUpdatePlayerDisconnect_4(Handle hDriver, Handle hResult, const char[] sError, any iUserId) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayerDisconnect > Error: %s", sError);
	} else {
		char sSteamId[32];
		Player_UGetString(iUserId, PLAYER_COMMUNITY_ID, sSteamId, sizeof(sSteamId));
		
		Log(TDLogLevel_Info, "Updated disconnected player in database (%s)", sSteamId);
	}
	
	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
} 