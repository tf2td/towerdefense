#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

#define PLAYER_USER_ID 		 0
#define PLAYER_DATABASE_ID 	 8
#define PLAYER_STEAM_ID 	16

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
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult) == 0) {
		// No player found, add it

		SetPackPosition(hPack, PLAYER_STEAM_ID);
		decl String:sSteamId[32];
		ReadPackString(hPack, sSteamId, sizeof(sSteamId));

		Database_AddPlayer(hPack);
	} else {
		SQL_FetchRow(hResult);

		SetPackPosition(hPack, PLAYER_DATABASE_ID);
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

	SetPackPosition(hPack, PLAYER_STEAM_ID);
	ReadPackString(hPack, sSteamId, sizeof(sSteamId));

	Format(sQuery, sizeof(sQuery), "CALL AddPlayer('%s', %d)", sSteamId, g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnAddPlayer, sQuery, hPack);
}

public Database_OnAddPlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_AddPlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SetPackPosition(hPack, PLAYER_STEAM_ID);

		decl String:sSteamId[32];
		ReadPackString(hPack, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Added player to database (%s)", sSteamId);

		SQL_FetchRow(hResult);
		
		SetPackPosition(hPack, PLAYER_DATABASE_ID);
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

	SetPackPosition(hPack, PLAYER_USER_ID);

	new iClient = GetClientOfUserId(ReadPackCell(hPack));

	GetClientName(iClient, sPlayerName, sizeof(sPlayerName));
	SQL_EscapeString(g_hDatabase, sPlayerName, sPlayerNameSave, sizeof(sPlayerNameSave));

	decl String:sPlayerIp[16];
	decl String:sPlayerIpSave[33];

	GetClientIP(iClient, sPlayerIp, sizeof(sPlayerIp));
	SQL_EscapeString(g_hDatabase, sPlayerIp, sPlayerIpSave, sizeof(sPlayerIpSave));

	SetPackPosition(hPack, PLAYER_DATABASE_ID);

	new iPlayerId = ReadPackCell(hPack);

	Format(sQuery, sizeof(sQuery), "CALL UpdatePlayer(%d, '%s', '%s', %d)", iPlayerId, sPlayerNameSave, sPlayerIpSave, g_iServerId);

	SQL_TQuery(g_hDatabase, Database_OnUpdatePlayer, sQuery, hPack);
}

public Database_OnUpdatePlayer(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_UpdatePlayer > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		decl String:sSteamId[32];
		SQL_FetchString(hResult, 0, sSteamId, sizeof(sSteamId));

		Log(TDLogLevel_Info, "Updated player in database (%s)", sSteamId);

		Database_CheckPlayerBanned(hPack);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}

/**
 * Checks if a player's banned.
 *
 * @param hPack 			The datapack handle containing the player info.
 * @noreturn
 */

stock Database_CheckPlayerBanned(Handle:hPack) {
	decl String:sQuery[512];

	SetPackPosition(hPack, PLAYER_DATABASE_ID);
	new iPlayerId = ReadPackCell(hPack);

	Format(sQuery, sizeof(sQuery), "CALL GetPlayerBanned(%d)", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerBanned, sQuery, hPack);
}

public Database_OnCheckPlayerBanned(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerBanned > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		new bool:bDotherwiseProceed = false;

		SetPackPosition(hPack, PLAYER_USER_ID);
		new iClient = GetClientOfUserId(ReadPackCell(hPack));

		SQL_FetchRow(hResult);

		decl String:sReason[256], String:sExpire[32];

		SQL_FetchString(hResult, 0, sReason, sizeof(sReason));
		SQL_FetchString(hResult, 1, sExpire, sizeof(sExpire));

		if (strlen(sReason) > 0) {
			KickClient(iClient, "You have been banned from TF2 Tower Defense until %s! Reason: %s", sExpire, sReason);
			bDotherwiseProceed = true;
		} else {
			KickClient(iClient, "You have been banned from TF2 Tower Defense until %s!", sExpire);
			bDotherwiseProceed = true;
		}

		if (!bDotherwiseProceed) {
			Database_CheckPlayerImmunity(hPack);
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
 * @param hPack 			The datapack handle containing the player info.
 * @noreturn
 */

stock Database_CheckPlayerImmunity(Handle:hPack) {
	decl String:sQuery[512];

	SetPackPosition(hPack, PLAYER_DATABASE_ID);
	new iPlayerId = ReadPackCell(hPack);

	Format(sQuery, sizeof(sQuery), "CALL GetPlayerImmunity(%d)", iPlayerId);

	SQL_TQuery(g_hDatabase, Database_OnCheckPlayerImmunity, sQuery, hPack);
}

public Database_OnCheckPlayerImmunity(Handle:hDriver, Handle:hResult, const String:sError[], any:hPack) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_CheckPlayerImmunity > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SetPackPosition(hPack, PLAYER_USER_ID);
		new iClient = GetClientOfUserId(ReadPackCell(hPack));

		SQL_FetchRow(hResult);
		new iImmunity = SQL_FetchInt(hResult, 0);

		if (iImmunity >= 99 && GetUserAdmin(iClient) == INVALID_ADMIN_ID) {
			new AdminId:iAdmin = CreateAdmin("Admin");

			SetAdminFlag(iAdmin, Admin_Root, true);
			SetUserAdmin(iClient, iAdmin);
		}

		CloseHandle(hPack);
	}

	if (hResult != INVALID_HANDLE) {
		CloseHandle(hResult);
		hResult = INVALID_HANDLE;
	}
}