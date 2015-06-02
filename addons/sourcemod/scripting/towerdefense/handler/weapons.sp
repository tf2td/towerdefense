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
 * Gets the name of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if weapon was not found.
 */

stock bool Weapon_GetName(int iWeaponId, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_name", iWeaponId);
	
	return GetTrieString(g_hMapWeapons, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the index of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @return				The weapons index, or -1 on failure.
 */

stock int Weapon_GetIndex(int iWeaponId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_index", iWeaponId);
	
	int iIndex = 0;
	if (!GetTrieValue(g_hMapWeapons, sKey, iIndex)) {
		return -1;
	}
	
	return iIndex;
}

/**
 * Gets the slot of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @return				The weapons slot, or -1 on failure.
 */

stock int Weapon_GetSlot(int iWeaponId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_slot", iWeaponId);
	
	int iSlot = 0;
	if (!GetTrieValue(g_hMapWeapons, sKey, iSlot)) {
		return -1;
	}
	
	return iSlot;
}

/**
 * Gets the level of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @return				The weapons level, or -1 on failure.
 */

stock int Weapon_GetLevel(int iWeaponId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_level", iWeaponId);
	
	int iLevel = 0;
	if (!GetTrieValue(g_hMapWeapons, sKey, iLevel)) {
		return -1;
	}
	
	return iLevel;
}

/**
 * Gets the quality of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @return				The weapons quality, or -1 on failure.
 */

stock int Weapon_GetQuality(int iWeaponId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_quality", iWeaponId);
	
	int iQuality = 0;
	if (!GetTrieValue(g_hMapWeapons, sKey, iQuality)) {
		return -1;
	}
	
	return iQuality;
}

/**
 * Gets the classname of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if weapon was not found.
 */

stock bool Weapon_GetClassname(int iWeaponId, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_classname", iWeaponId);
	
	return GetTrieString(g_hMapWeapons, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the attributes of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @param iAttributes 	The attribute id array.
 * @param iWeaponId 	The attribute value array.
 * @return				The attribute count.
 */

stock int Weapon_GetAttributes(int iWeaponId, int iAttributes[16], float iValues[16]) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_attributes", iWeaponId);
	
	char sAttributes[256];
	if (GetTrieString(g_hMapWeapons, sKey, sAttributes, sizeof(sAttributes))) {
		char sAttributeParts[32][6];
		int iCount = ExplodeString(sAttributes, ";", sAttributeParts, sizeof(sAttributeParts), sizeof(sAttributeParts[]));
		
		if (iCount % 2 != 0) {
			Log(TDLogLevel_Error, "Failed to parse weapon attributes for weapon id %d (some attribute has no value)", iWeaponId);
			return 0;
		}
		
		int iAttributeCount = 0;
		
		for (int i = 0; i < iCount && iAttributeCount < 16; i += 2) {
			iAttributes[iAttributeCount] = StringToInt(sAttributeParts[i]);
			iValues[iAttributeCount] = StringToFloat(sAttributeParts[i + 1]);
			
			iAttributeCount++;
		}
		
		return iAttributeCount;
	}
	
	return 0;
}

/**
 * Checks if a weapon should preserve its attributes.
 *
 * @param iWeaponId 	The weapons id.
 * @return				True if should preserve, false otherwise.
 */

stock bool Weapon_GetPreserveAttributes(int iWeaponId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_preserve_attributes", iWeaponId);
	
	int iPreserve = 0;
	if (!GetTrieValue(g_hMapWeapons, sKey, iPreserve)) {
		return false;
	}
	
	return (iPreserve != 0);
} 