#pragma semicolon 1

#include <sourcemod>

/**
 * Called when a buy-tower button is being shot.
 *
 * @param iTowerId		The tower id.
 * @param iButton		The button entity.
 * @param iActivator	The activator entity.
 * @noreturn
 */

stock Tower_OnButtonBuy(TDTowerId:iTowerId, iButton, iActivator) {
	if (!g_bEnabled) {
		return;
	}

	if (!IsDefender(iActivator)) {
		return;
	}

	if (!g_bTowerBought[_:iTowerId]) {
		new iPrice = Tower_GetPrice(iTowerId);
		decl String:sName[MAX_NAME_LENGTH];
		Tower_GetName(iTowerId, sName, sizeof(sName));

		PrintToChatAll("\x04Buying \x01%s\x04 (Total price: \x01%d metal\x04)", sName, iPrice);

		if (CanAfford(iPrice)) {
			Tower_Spawn(iTowerId);

			PrintToChatAll("\x04%N bought \x01%s", iActivator, sName);

			g_bTowerBought[_:iTowerId] = true;
			AcceptEntityInput(iButton, "Break");
		}
	}
}

/**
 * Called when a teleport-tower button is being shot.
 *
 * @param iTowerId		The tower id.
 * @param iButton		The button entity.
 * @param iActivator	The activator entity.
 * @noreturn
 */

stock Tower_OnButtonTeleport(TDTowerId:iTowerId, iButton, iActivator) {
	if (!g_bEnabled) {
		return;
	}
}

/**
 * Spawns a tower.
 *
 * @param iTowerId		The towers id.
 * @return				True on success, false ontherwise.
 */

stock bool:Tower_Spawn(TDTowerId:iTowerId) {
	if (!g_bEnabled) {
		return false;
	}

	decl String:sName[MAX_NAME_LENGTH], String:sClass[32];

	if (Tower_GetName(iTowerId, sName, sizeof(sName))) {
		if (Tower_GetClassString(iTowerId, sClass, sizeof(sClass))) {
			ServerCommand("bot -team blue -class %s -name %s", sClass, sName);

			Log(TDLogLevel_Info, "Tower (%s) spawned", sName);
			return true;
		}
	}

	return false;
}

/**
 * Attaches a tower to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock AttachTower(iClient) {
	if (!g_bEnabled) {
		return;
	}

	new iTower = GetAimTarget(iClient);

	if (IsTower(iTower)) {
		if (IsTowerAttached(iTower)) {
			Forbid(iClient, true, "%N is already being moved by someone!", iTower);
			return;
		}

		TF2Attrib_SetByName(iClient, "cannot pick up buildings", 1.0);

		SetEntityMoveType(iTower, MOVETYPE_NOCLIP);

		TeleportEntity(iTower, Float:{0.0, 0.0, -8192.0}, NULL_VECTOR, NULL_VECTOR); // Teleport out of the map

		HideAnnotation(iTower);
		AttachAnnotation(iClient, 86400.0, "Moving: %N", iTower);

		g_bCarryingObject[iClient] = true;
		g_iAttachedTower[iClient] = iTower;
		Log(TDLogLevel_Debug, "%N picked up tower (%N)", iClient, iTower);
	}
}

/**
 * Detaches a tower from a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock DetachTower(iClient) {
	if (!g_bEnabled) {
		return;
	}

	if (g_bInsideNobuild[iClient]) {
		Forbid(iClient, true, "Towers aren't meant to be placed on the path!");
		return;
	}

	new iTower = g_iAttachedTower[iClient];
	new Float:fLocation[3], Float:fAngles[3];

	SetEntityMoveType(iTower, MOVETYPE_WALK);

	GetClientAbsOrigin(iClient, fLocation);
	GetClientAbsAngles(iClient, fAngles);

	TeleportEntity(iTower, fLocation, fAngles, NULL_VECTOR);

	HideAnnotation(iClient);

	TF2Attrib_RemoveByName(iClient, "cannot pick up buildings");

	g_iLastMover[iTower] = iClient;
	g_bCarryingObject[iClient] = false;
	g_iAttachedTower[iClient] = 0;
	Log(TDLogLevel_Debug, "%N dropped tower (%N)", iClient, iTower);
}

/**
 * Gets called when a tower is upgraded by a client.
 *
 * @param iTower		The tower.
 * @param iClient		The client upgrading.
 * @noreturn
 */

stock UpgradeTower(iTower, iClient) {
	if (!g_bEnabled) {
		return;
	}

	if (!AddClientMetal(iClient, -25)) {
		return;
	}

	g_iUpgradeMetal[iTower] += 25;

	if (g_iUpgradeMetal[iTower] >= 1000) {
		// Upgrade tower to next level

		g_iUpgradeMetal[iTower] = 0;
		g_iUpgradeLevel[iTower]++;
	}

	HideAnnotation(iTower);
	HideAdvancedAnnotation(iClient, iTower);
	AttachAnnotation(iTower, 2.0, "%N\n\rCurrent Level: %d\n\rUpgrade Progress: %d/1000", iTower, g_iUpgradeLevel[iTower], g_iUpgradeMetal[iTower]);
}

/**
 * Shows tower info to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock ShowTowerInfo(iClient) {
	if (!g_bEnabled) {
		return;
	}

	new iTower = GetAimTarget(iClient);

	if (IsTower(iTower)) {
		AttachAdvancedAnnotation(iClient, iTower, 4.0, "%N\n\rCurrent Level: %d\n\rUpgrade Progress: %d/1000", iTower, g_iUpgradeLevel[iTower], g_iUpgradeMetal[iTower]);
	}
}

/**
 * Teleports a tower to his spawn location.
 *
 * @param iTower		The tower.
 * @return				True on success, false ontherwise.
 */

stock TeleportTower(iTower) {
	if (!g_bEnabled) {
		return false;
	}

	new TDTowerId:iTowerId = GetTowerId(iTower);

	if (iTowerId == TDTower_Invalid) {
		return false;
	}

	new Float:fLocation[3], Float:fAngles[3];

	if (Tower_GetLocation(iTowerId, fLocation)) {
		if (Tower_GetAngles(iTowerId, fAngles)) {
			TeleportEntity(iTower, fLocation, fAngles, Float:{0.0, 0.0, 0.0});

			decl String:sName[MAX_NAME_LENGTH];
			if (!Tower_GetName(iTowerId, sName, sizeof(sName))) {
				Log(TDLogLevel_Debug, "Tower (%N) teleported", sName);
			}
		}
	}
	
	return false;
}

/*=========================================
=            Utility Functions            =
=========================================*/

/**
 * Gets a visibility bitfield which determines if a player should see an annotation.
 *
 * @param iClient		The client who should see it.
 * @return				The bitfield.
 */

stock GetVisibilityBitfield(iClient) {
	if (!IsDefender(iClient)) {
		return 1;
	}

	new iBitField = 1;
	iBitField |= RoundFloat(Pow(2.0, float(iClient)));
	return iBitField;
}

/**
 * Checks if a tower is attached to a client.
 *
 * @param iTower		The tower.
 * @return				True if tower is attached, false ontherwise.
 */

stock bool:IsTowerAttached(iTower) {
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (g_iAttachedTower[iClient] == iTower) {
			return true;
		}
	}

	return false;
}

/**
 * Gets a towers client index.
 *
 * @param iTowerId		The towers id.
 * @return				The towers client index, or -1 on failure.
 */

stock GetTower(TDTowerId:iTowerId) {
	decl String:sName[MAX_NAME_LENGTH], String:sName2[MAX_NAME_LENGTH];
	
	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsTower(iClient)) {
			GetClientName(iClient, sName, sizeof(sName));
			Tower_GetName(iTowerId, sName2, sizeof(sName2));

			if (StrEqual(sName, sName2)) {
				return iClient;
			}
		}
	}
	
	return -1;
}

/**
 * Gets the towers id.
 *
 * @param iTower		The tower.
 * @return				The towers id, or -1 on error.
 */

stock TDTowerId:GetTowerId(iTower) {
	if (IsValidClient(iTower)) {
		decl String:sName[MAX_NAME_LENGTH], String:sName2[MAX_NAME_LENGTH];
		GetClientName(iTower, sName, sizeof(sName));

		new iClient, iTowerId;

		for (iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsClientInGame(iClient)) {
				for (iTowerId = 0; iTowerId < _:TDTower_Quantity; iTowerId++) {
					Tower_GetName(TDTowerId:iTowerId, sName2, sizeof(sName2));

					if (StrEqual(sName, sName2)) {
						return TDTowerId:iTowerId;
					}
				}
			}
		}
	}

	return TDTower_Invalid;
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock AttachAnnotation(iEntity, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity); 
	SetEventInt(hEvent, "id", iEntity); 
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
	SetEventString(hEvent, "text", sFormattedMessage);

	FireEvent(hEvent);
}

/**
 * Attaches a annotation to an entity.
 *
 * @param iClient		The client.
 * @param iEntity		The entity.
 * @param fLifetime		The lifetime of the annotation.
 * @param sMessage		The message to show.
 * @param ...			Message formatting parameters.
 * @noreturn
 */

stock AttachAdvancedAnnotation(iClient, iEntity, Float:fLifetime, String:sMessage[], any:...) {
	new Handle:hEvent = CreateEvent("show_annotation");

	if (hEvent == INVALID_HANDLE) {
		return;
	}
	
	SetEventInt(hEvent, "follow_entindex", iEntity);
	SetEventInt(hEvent, "id", iClient * iEntity);
	SetEventFloat(hEvent, "lifetime", fLifetime);
	SetEventString(hEvent, "play_sound", "misc/null.wav");

	decl String:sFormattedMessage[256];
	VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 5);
	SetEventString(hEvent, "text", sFormattedMessage);
	
	SetEventInt(hEvent, "visibilityBitfield", GetVisibilityBitfield(iClient));

	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The entity.
 * @noreturn
 */

stock HideAnnotation(iEntity) {
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
		return;
	}

	SetEventInt(hEvent, "id", iEntity); 
	FireEvent(hEvent);
}

/**
 * Hides the annotation which is attached to an entity.
 *
 * @param iEntity		The client.
 * @param iEntity		The entity.
 * @noreturn
 */

stock HideAdvancedAnnotation(iClient, iEntity) {
	new Handle:hEvent = CreateEvent("hide_annotation"); 

	if (hEvent == INVALID_HANDLE) {
		return;
	}

	SetEventInt(hEvent, "id", iClient * iEntity); 
	FireEvent(hEvent);
}

/*======================================
=            Data Functions            =
======================================*/

/**
 * Gets the name of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if tower was not found.
 */

stock bool:Tower_GetName(TDTowerId:iTowerId, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_name", _:iTowerId);

	return GetTrieString(g_hMapTowers, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the class of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if tower was not found.
 */

stock bool:Tower_GetClassString(TDTowerId:iTowerId, String:sBuffer[], iMaxLength) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", _:iTowerId);

	return GetTrieString(g_hMapTowers, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the class of a tower.
 *
 * @param iTowerId 		The towers id.
 * @return				The towers class type, or TFClass_Unknown on error.
 */

stock TFClassType:Tower_GetClass(TDTowerId:iTowerId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", _:iTowerId);

	decl String:sClass[32];
	GetTrieString(g_hMapTowers, sKey, sClass, sizeof(sClass));

	if (StrEqual(sClass, "Scout")) {
		return TFClass_Scout;
	} else if (StrEqual(sClass, "Sniper")) {
		return TFClass_Sniper;
	} else if (StrEqual(sClass, "Soldier")) {
		return TFClass_Soldier;
	} else if (StrEqual(sClass, "Demoman")) {
		return TFClass_DemoMan;
	} else if (StrEqual(sClass, "Medic")) {
		return TFClass_Medic;
	} else if (StrEqual(sClass, "Heavy")) {
		return TFClass_Heavy;
	} else if (StrEqual(sClass, "Pyro")) {
		return TFClass_Pyro;
	} else if (StrEqual(sClass, "Spy")) {
		return TFClass_Spy;
	} else if (StrEqual(sClass, "Spy")) {
		return TFClass_Engineer;
	}

	return TFClass_Unknown;
}

/**
 * Gets the price of a tower.
 *
 * @param iTowerId 		The towers id.
 * @return				The towers price, or -1 on failure.
 */

stock Tower_GetPrice(TDTowerId:iTowerId) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_price", _:iTowerId);
	
	new iPrice = 0;
	if (!GetTrieValue(g_hMapTowers, sKey, iPrice)) {
		return -1;
	}

	return iPrice;
}

/**
 * Gets the location of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param fLocation 	The location vector.
 * @return				True on success, false if tower was not found.
 */

stock bool:Tower_GetLocation(TDTowerId:iTowerId, Float:fLocation[3]) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", _:iTowerId);
	
	decl String:sLocation[64];
	if (GetTrieString(g_hMapTowers, sKey, sLocation, sizeof(sLocation))) {
		decl String:sLocationParts[6][16];
		ExplodeString(sLocation, " ", sLocationParts, sizeof(sLocationParts), sizeof(sLocationParts[]));

		fLocation[0] = StringToFloat(sLocationParts[0]);
		fLocation[1] = StringToFloat(sLocationParts[1]);
		fLocation[2] = StringToFloat(sLocationParts[2]);

		return true;
	}

	return false;
}

/**
 * Gets the angles of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param iTowerLevel 	The towers level.
 * @param fAngles 		The angles vector.
 * @return				True on success, false if tower was not found.
 */

stock bool:Tower_GetAngles(TDTowerId:iTowerId, Float:fAngles[3]) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", _:iTowerId);
	
	decl String:sAngles[64];
	if (GetTrieString(g_hMapTowers, sKey, sAngles, sizeof(sAngles))) {
		new iTower = GetTower(iTowerId);

		if (IsTower(iTower)) {
			Format(sKey, sizeof(sKey), "%d_%d_pitch", _:iTowerId, g_iUpgradeLevel[iTower]);

			new iPitch = 0;
			if (GetTrieValue(g_hMapTowers, sKey, iPitch)) {
				decl String:sAnglesParts[6][16];
				ExplodeString(sAngles, " ", sAnglesParts, sizeof(sAnglesParts), sizeof(sAnglesParts[]));

				fAngles[0] = float(iPitch);
				fAngles[1] = StringToFloat(sAnglesParts[4]);
				fAngles[2] = StringToFloat(sAnglesParts[5]);

				return true;
			}
		}
	}

	return false;
}

/**
 * Gets the weapon of a tower.
 *
 * @param iTowerId 		The towers id.
 * @return				The towers weapon id, or -1 on failure.
 */

stock Tower_GetWeapon(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_weapon", _:iTowerId, g_iUpgradeLevel[iTower]);

		new iWeapon = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iWeapon)) {
			return -1;
		}

		return iWeapon;
	}

	return -1;
}

/**
 * Gets the weapon attributes of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param iAttributes 	The attribute id array.
 * @param iTowerId 		The attribute value array.
 * @return				The attribute count.
 */

stock Tower_GetWeaponAttributes(TDTowerId:iTowerId, iAttributes[16], Float:iValues[16]) {
	decl String:sKey[32];
	Format(sKey, sizeof(sKey), "%d_weapon_attributes", _:iTowerId);

	decl String:sAttributes[256];
	if (GetTrieString(g_hMapTowers, sKey, sAttributes, sizeof(sAttributes))) {
		decl String:sAttributeParts[32][6];
		new iCount = ExplodeString(sAttributes, ";", sAttributeParts, sizeof(sAttributeParts), sizeof(sAttributeParts[]));

		if (iCount % 2 != 0) {
			Log(TDLogLevel_Error, "Failed to parse weapon attributes for tower id %d (some attribute has no value)", _:iTowerId);
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
 * Checks if a tower should do primary attacks.
 *
 * @param iTowerId 		The towers id.
 * @return				True if should attack, false otherwise.
 */

stock bool:Tower_AttackPrimary(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_attack_primary", _:iTowerId, g_iUpgradeLevel[iTower]);

		new iAttack = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iAttack)) {
			return false;
		}

		return (iAttack != 0);
	}

	return false;
}

/**
 * Checks if a tower should do secondary attacks.
 *
 * @param iTowerId 		The towers id.
 * @return				True if should attack, false otherwise.
 */

stock bool:Tower_AttackSecondary(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_attack_secondary", _:iTowerId, g_iUpgradeLevel[iTower]);

		new iAttack = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iAttack)) {
			return false;
		}

		return (iAttack != 0);
	}

	return false;
}

/**
 * Checks if a tower should rotate towards enemies.
 *
 * @param iTowerId 		The towers id.
 * @return				True if should rotate, false otherwise.
 */

stock bool:Tower_Rotate(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_rotate", _:iTowerId, g_iUpgradeLevel[iTower]);

		new iRotate = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iRotate)) {
			return false;
		}

		return (iRotate != 0);
	}

	return false;
}

/**
 * Gets the towers damage scale.
 *
 * @param iTowerId 		The towers id.
 * @return				The damage scale, or 1.0 on failure.
 */

stock Float:Tower_DamageScale(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_damage", _:iTowerId, g_iUpgradeLevel[iTower]);

		new Float:fDamage = 1.0;
		if (!GetTrieValue(g_hMapTowers, sKey, fDamage)) {
			return 1.0;
		}

		return fDamage;
	}

	return 1.0;
}

/**
 * Gets the towers attackspeed scale.
 *
 * @param iTowerId 		The towers id.
 * @return				The attackspeed scale, or 1.0 on failure.
 */

stock Float:Tower_AttackspeedScale(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_attackspeed", _:iTowerId, g_iUpgradeLevel[iTower]);

		new Float:fAttackspeed = 1.0;
		if (!GetTrieValue(g_hMapTowers, sKey, fAttackspeed)) {
			return 1.0;
		}

		return fAttackspeed;
	}

	return 1.0;
}

/**
 * Gets the towers area scale.
 *
 * @param iTowerId 		The towers id.
 * @return				The area scale, or 1.0 on failure.
 */

stock Float:Tower_AreaScale(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_area", _:iTowerId, g_iUpgradeLevel[iTower]);

		new Float:fArea = 1.0;
		if (!GetTrieValue(g_hMapTowers, sKey, fArea)) {
			return 1.0;
		}

		return fArea;
	}

	return 1.0;
}