#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Connects to the database.
 *
 * @return				True if connected successfully, false otherwise.
 */

stock bool:Database_Connect() {
	if (!g_bEnabled) {
		return false;
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
			Log(TDLogLevel_Error, "Failed to connect to the database! Error: %s", sError);

			return false;
		} else {
			Log(TDLogLevel_Info, "Successfully connected to the database");

			return true;
		}
	}

	return false;
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
	
	Format(sQuery, sizeof(sQuery), "CALL GetTowers(%d)", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadTowers, sQuery);
}

public Database_OnLoadTowers(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadTowers > Error: %s", sError);
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

			// Save tower level attack mode
			Format(sKey, sizeof(sKey), "%d_%d_attack", iTowerId, iTowerLevel);
			SQL_FetchString(hResult, 10, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMapTowers, sKey, sBuffer);

			// PrintToServer("%s => %s", sKey, sBuffer);

			// Save tower level rotate
			Format(sKey, sizeof(sKey), "%d_%d_rotate", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 11));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 11));

			// Save tower level pitch
			Format(sKey, sizeof(sKey), "%d_%d_pitch", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchInt(hResult, 12));

			// PrintToServer("%s => %d", sKey, SQL_FetchInt(hResult, 12));

			// Save tower level damage
			Format(sKey, sizeof(sKey), "%d_%d_damage", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 13));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 13));

			// Save tower level attackspeed
			Format(sKey, sizeof(sKey), "%d_%d_attackspeed", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 14));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 14));

			// Save tower level area
			Format(sKey, sizeof(sKey), "%d_%d_area", iTowerId, iTowerLevel);
			SetTrieValue(g_hMapTowers, sKey, SQL_FetchFloat(hResult, 15));

			// PrintToServer("%s => %f", sKey, SQL_FetchFloat(hResult, 15));
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
		Log(TDLogLevel_Error, "Query failed at Database_LoadWeapons > Error: %s", sError);
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
	Database_LoadMaxWaves();
}

stock Database_LoadWaves() {
	decl String:sQuery[128];
	
	Format(sQuery, sizeof(sQuery), "CALL GetWaves(%d)", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadMaxWaves, sQuery);
}

/**
 * Loads waves to its map.
 *
 * @noreturn
 */

stock Database_LoadWaves() {
	decl String:sQuery[128];
	
	Format(sQuery, sizeof(sQuery), "CALL GetWaves(%d)", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadWaves, sQuery);
}

public Database_OnLoadWaves(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadWaves > Error: %s", sError);
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
	
	Format(sQuery, sizeof(sQuery), "CALL GetMetalpacks(%d)", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadMetalpacks, sQuery);
}

public Database_OnLoadMetalpacks(Handle:hDriver, Handle:hResult, const String:sError[], any:iData) {
	if (hResult == INVALID_HANDLE) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadMetalpacks > Error: %s", sError);
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