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

stock bool:Weapon_GetName(iWeaponId, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_name", iWeaponId);

	return GetTrieString(g_hMapWeapons, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the index of a weapon.
 *
 * @param iWeaponId 	The weapons id.
 * @return				The weapons index, or -1 on failure.
 */

stock Weapon_GetIndex(iWeaponId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_index", iWeaponId);
	
	new iIndex = 0;
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

stock Weapon_GetSlot(iWeaponId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_slot", iWeaponId);
	
	new iSlot = 0;
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

stock Weapon_GetLevel(iWeaponId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_level", iWeaponId);
	
	new iLevel = 0;
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

stock Weapon_GetQuality(iWeaponId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_quality", iWeaponId);
	
	new iQuality = 0;
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

stock bool:Weapon_GetClassname(iWeaponId, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
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

stock Weapon_GetAttributes(iWeaponId, iAttributes[16], Float:iValues[16]) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_attributes", iWeaponId);

	decl String:sAttributes[256];
	if (GetTrieString(g_hMapWeapons, sKey, sAttributes, sizeof(sAttributes))) {
		decl String:sAttributeParts[32][6];
		new iCount = ExplodeString(sAttributes, ";", sAttributeParts, sizeof(sAttributeParts), sizeof(sAttributeParts[]));

		if (iCount % 2 != 0) {
			Log(TDLogLevel_Error, "Failed to parse weapon attributes for weapon id %d (some attribute has no value)", iWeaponId);
			return 0;
		}

		new iAttributeCount = 0;

		for (new i = 0; i < iCount && iAttributeCount < 16; i += 2){
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

stock bool:Weapon_GetPreserveAttributes(iWeaponId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_preserve_attributes", iWeaponId);

	new iPreserve = 0;
	if (!GetTrieValue(g_hMapWeapons, sKey, iPreserve)) {
		return false;
	}

	return (iPreserve != 0);
}