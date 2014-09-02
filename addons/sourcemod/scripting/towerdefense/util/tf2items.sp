#pragma semicolon 1

#include <sourcemod>

/**
 * Gives a weapon to a client.
 * See https://wiki.alliedmods.net/Team_fortress_2_item_definition_indexes for item indexes and classnames.
 *
 * @param iClient					The client who should get the weapon.
 * @param iItemDefinitionIndex		The weapons items index.
 * @param iSlot						The weapons slot.
 * @param iLevel					The weapons level. (must be between 0 an 100)
 * @param iQuality					The weapons quality. (must be between 0 an 10)
 * @param bPreserveAttributes		Should attributes be preserved?
 * @param sClassname				The weapons classname.
 * @param sAttributes				The attributes to apply tp the weapon. (Format: "<AttributeId1>=<Value1>;<AttributeId2>=<Value2>;...")
 * @noreturn
 */

stock TF2Items_GiveWeapon(iClient, iItemDefinitionIndex, iSlot, iLevel, iQuality, bool:bPreserveAttributes, String:sClassname[], String:sAttributes[]) {
	Log(TDLogLevel_Trace, "%d, %d, %d, %d, %d, %s, \"%s\", \"%s\"", iClient, iItemDefinitionIndex, iSlot, iLevel, iQuality, (bPreserveAttributes ? "true" : "false"), sClassname, sAttributes);

	new Handle:hItem = TF2Items_CreateItem(OVERRIDE_ALL);
	new iFlags = 0;

	TF2Items_SetItemIndex(hItem, iItemDefinitionIndex);

	if (iLevel >= 0 && iLevel <= 100) {
		TF2Items_SetLevel(hItem, iLevel);
		iFlags |= OVERRIDE_ITEM_LEVEL;
	}

	if (iQuality >= 0 && iQuality <= 10) {
		TF2Items_SetQuality(hItem, iQuality);
		iFlags |= OVERRIDE_ITEM_QUALITY;
	}

	if (bPreserveAttributes) {
		iFlags |= PRESERVE_ATTRIBUTES;
	}

	new String:sAttributeList[15][16], String:sAttribute[2][16];
	new iAttributeIndex, Float:fAttributeValue;
	new iNumAttributes = 0;

	// More than 1 attribute
	if (FindCharInString(sAttributes, ';') != -1) {
		ExplodeString(sAttributes, ";", sAttributeList, sizeof(sAttributeList), sizeof(sAttributeList[]));

		for (new i = 0; i < sizeof(sAttributeList); i++) {
			if (!StrEqual(sAttributeList[i], "")) {
				ExplodeString(sAttributeList[i], "=", sAttribute, sizeof(sAttribute), sizeof(sAttribute[]));

				iAttributeIndex = StringToInt(sAttribute[0]);
				fAttributeValue = StringToFloat(sAttribute[1]);

				PrintToServer("Attribute: %d, Value: %f", iAttributeIndex, fAttributeValue);

				TF2Items_SetAttribute(hItem, i, iAttributeIndex, fAttributeValue);

				iNumAttributes++;
			}
		}
	} else {
		// Exactly 1 attribute
		if (!StrEqual(sAttributes, "")) {
			ExplodeString(sAttributes, "=", sAttribute, sizeof(sAttribute), sizeof(sAttribute[]));

			iAttributeIndex = StringToInt(sAttribute[0]);
			fAttributeValue = StringToFloat(sAttribute[1]);

			PrintToServer("Attribute: %d, Value: %f", iAttributeIndex, fAttributeValue);

			TF2Items_SetAttribute(hItem, 0, iAttributeIndex, fAttributeValue);

			iNumAttributes++;
		}
	}
	
	if (iNumAttributes != 0 && iNumAttributes <= 15) {
		TF2Items_SetNumAttributes(hItem, iNumAttributes);
		iFlags |= OVERRIDE_ATTRIBUTES;
	}

	TF2Items_SetFlags(hItem, iFlags);

	TF2Items_SetClassname(hItem, sClassname);

	TF2_RemoveWeaponSlot(iClient, iSlot);
	new iWeapon = TF2Items_GiveNamedItem(iClient, hItem);
			
	if (IsValidEntity(iWeapon)) {
		EquipPlayerWeapon(iClient, iWeapon);

		Log(TDLogLevel_Debug, "Gave weapon (%d) to %N", iItemDefinitionIndex, iClient);
	}

	if (IsTower(iClient)) {
		new TDTowerId:iTowerId = GetTowerId(iClient);
		Tower_OnWeaponChanged(iClient, iTowerId, iItemDefinitionIndex, iSlot, iWeapon);
	}

	CloseHandle(hItem);
}