#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/*======================================
=            Data Functions            =
======================================*/

/**
 * Starts to load all data from the database, calls Database_OnDataLoaded() when finished.
 *
 * @noreturn
 */

stock void Database_LoadData() {
	Database_LoadTowers();
}

/**
 * Loads towers to its map.
 *
 * @noreturn
 */

stock void Database_LoadTowers() {
	char sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `tower`.`tower_id`, `level`, `tower`.`name`, `class`, `price`, `teleport_tower`, `damagetype`, `description`, `metal`, `weapon_id`, `attack`, `rotate`, `pitch`, `damage`, `attackspeed`, `area` \
		FROM `tower` \
		INNER JOIN `map` \
			ON (`map`.`map_id` = %d) \
		INNER JOIN `towerlevel` \
			ON (`tower`.`tower_id` = `towerlevel`.`tower_id`) \
		ORDER BY `tower`.`name` ASC, `level` ASC \
	", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadTowers, sQuery);
}

public void Database_OnLoadTowers(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadTowers > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		int iTowerId = 0, iTowerLevel = 0;
		char sKey[64], sBuffer[128];
		
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
	
	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
	
	Database_LoadWeapons();
}

/**
 * Loads weapons to its map.
 *
 * @noreturn
 */

stock void Database_LoadWeapons() {
	char sQuery[256];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `name`, `index`, (`slot` - 1), `level`, (`quality` - 1), `classname`, `attributes`, (`preserve_attributes` - 1) \
		FROM `weapon` \
		ORDER BY `weapon_id` ASC \
	");
	
	SQL_TQuery(g_hDatabase, Database_OnLoadWeapons, sQuery);
}

public void Database_OnLoadWeapons(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadWeapons > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		int iWeaponId = 1;
		char sKey[64], sBuffer[128];
		
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
	
	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
	
	Database_LoadWaves();
}

/**
 * Loads waves to its map.
 *
 * @noreturn
 */

stock void Database_LoadWaves() {
	char sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `wavetype`, `wave`.`name`, `class`, `quantity`, `health`, IF(`wavetype` & (SELECT `bit_value` FROM `wavetype` WHERE `wavetype`.`type` = 'air'), `teleport_air`, `teleport_ground`) \
		FROM `wave` \
		INNER JOIN `map` \
			ON (`map`.`map_id` = %d) \
		WHERE `wave_id` >= `wave_start` AND `wave_id` <= `wave_end` \
		ORDER BY `wave_id` ASC \
	", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadWaves, sQuery);
}

public void Database_OnLoadWaves(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadWaves > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		int iWaveId = 0;
		char sKey[64], sBuffer[128];
		
		iMaxWaves = 0;
		
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
			iMaxWaves++;
		}
	}
	
	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
	
	Database_LoadAirWaveSpawn();
}

/**
 * Loads the spawn location of air waves (for anti-air towers).
 *
 * @noreturn
 */

stock void Database_LoadAirWaveSpawn() {
	char sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `teleport_air` \
		FROM `map` \
		WHERE (`map_id` = %d) \
	", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadAirWaveSpawn, sQuery);
}

public void Database_OnLoadAirWaveSpawn(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadAirWaveSpawn > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		SQL_FetchRow(hResult);

		SQL_FetchString(hResult, 0, g_sAirWaveSpawn, sizeof(g_sAirWaveSpawn));

		char sLocationParts[6][16];
		ExplodeString(g_sAirWaveSpawn, " ", sLocationParts, sizeof(sLocationParts), sizeof(sLocationParts[]));

		g_fAirWaveSpawn[0] = StringToFloat(sLocationParts[0]);
		g_fAirWaveSpawn[1] = StringToFloat(sLocationParts[1]);
		g_fAirWaveSpawn[2] = StringToFloat(sLocationParts[2]);
	}
	
	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}
	
	Database_LoadMetalpacks();
}

/**
 * Loads metalpacks to its map.
 *
 * @noreturn
 */

stock void Database_LoadMetalpacks() {
	char sQuery[256];
	
	Format(sQuery, sizeof(sQuery), "\
		SELECT `type`, `metal`, `location` \
		FROM `metalpack` \
		INNER JOIN `metalpacktype` \
			ON (`metalpack`.`metalpacktype_id` = `metalpacktype`.`metalpacktype_id`) \
		WHERE `map_id` = %d \
		ORDER BY `metalpack_id` ASC \
	", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadMetalpacks, sQuery);
}

public void Database_OnLoadMetalpacks(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadMetalpacks > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		int iMetalpackId = 0;
		char sKey[64], sBuffer[128];
		
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
	
	if (hResult != null) {
		CloseHandle(hResult);
		hResult = null;
	}

	Database_LoadMultipliersTypes();
	
} 

stock void Database_LoadMultipliersTypes() {
	char sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "SELECT type FROM multipliertype ORDER BY `multipliertype_id` ASC", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadMultipliersTypes, sQuery);
}

/**
 * Load Multiplier Types
 *
 * @noreturn
 */
 
 public void Database_OnLoadMultipliersTypes(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadMaxWaves > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		// type	
		// bullet
		int iMultiplierTypeId = 1;
		while (SQL_FetchRow(hResult)) {
			char sKey[64], sBuffer[128];
			
			// Save type
			Format(sKey, sizeof(sKey), "%d_type", iMultiplierTypeId);
			SQL_FetchString(hResult, 0, sBuffer, sizeof(sBuffer));
			SetTrieString(g_hMultiplierType, sKey, sBuffer);
			
			iMultiplierTypeId++;
		}
	}
	
	Database_LoadMultipliers();
}

stock void Database_LoadMultipliers() {
	char sQuery[512];
	
	Format(sQuery, sizeof(sQuery), "SELECT price,increase FROM `multiplier` WHERE map_id=%d ORDER BY `multipliertype_id` ASC", g_iServerMap);
	
	SQL_TQuery(g_hDatabase, Database_OnLoadMultipliers, sQuery);
}

/**
 * Load Multipliers
 *
 * @noreturn
 */
 
 public void Database_OnLoadMultipliers(Handle hDriver, Handle hResult, const char[] sError, any iData) {
	if (hResult == null) {
		Log(TDLogLevel_Error, "Query failed at Database_LoadMaxWaves > Error: %s", sError);
	} else if (SQL_GetRowCount(hResult)) {
		// multipliertype_id	price	increase 
		// 1					1000	1000
		
		iMaxMultiplierTypes = 0;
		int iMultiplierTypeId = 1;
		
		while (SQL_FetchRow(hResult)) {
			char sKey[64];
			
			// Save price
			Format(sKey, sizeof(sKey), "%d_price", iMultiplierTypeId);
			SetTrieValue(g_hMultiplier, sKey, SQL_FetchInt(hResult, 0));
			
			// Save increase
			Format(sKey, sizeof(sKey), "%d_increase", iMultiplierTypeId);
			SetTrieValue(g_hMultiplier, sKey, SQL_FetchInt(hResult, 1));
			
			iMultiplierTypeId++;
			iMaxMultiplierTypes++;
		}
	}
	
	Database_OnDataLoaded();
}