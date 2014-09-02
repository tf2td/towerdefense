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

		new iClients = GetRealClientCount(true);

		if (iClients <= 0) {
			iClients = 1;
		}

		iPrice /= iClients;

		if (CanAfford(iPrice)) {
			Tower_Spawn(iTowerId);

			for (new iClient = 1; iClient <= MaxClients; iClient++) {
				if (IsDefender(iClient)) {
					AddClientMetal(iClient, -iPrice);

					// tdSQL_RefreshPlayerStats_TowersBought(iClient);
				}
			}

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
 * Called when a tower spawned.
 *
 * @param iTower		The tower.
 * @param iTowerId		The tower id.
 * @noreturn
 */

stock Tower_OnSpawn(iTower, TDTowerId:iTowerId) {
	if (!g_bEnabled) {
		return;
	}

	g_iUpgradeMetal[iTower] = 0;
	g_iUpgradeLevel[iTower] = 1;
	g_iLastMover[iTower] = 0;

	SetEntProp(iTower, Prop_Data, "m_bloodColor", _:TDBlood_None);
	SetRobotModel(iTower);

	// Set level attributes
	TF2Attrib_SetByDefIndex(iTower, 2, Tower_GetDamageScale(iTowerId));
	TF2Attrib_SetByDefIndex(iTower, 6, 1.0 / Tower_GetAttackspeedScale(iTowerId));

	// Change weapon
	Tower_ChangeWeapon(iTower, Tower_GetWeapon(iTowerId));

	// Teleport
	Tower_TeleportToSpawn(iTower);
}

/**
 * Called when a tower touches a func_nobuild brush.
 *
 * @param iTower		The tower.
 * @param iTowerId		The tower id.
 * @noreturn
 */

stock Tower_OnTouchNobuild(iTower) {
	if (!g_bEnabled) {
		return;
	}

	Forbid(g_iLastMover[iTower], true, "Don't you dare to place towers on the path again! Did you think you can trick me?");
	Tower_TeleportToSpawn(iTower);
}

/**
 * Called when a tower is upgraded by a client.
 *
 * @param iTower		The tower.
 * @param iClient		The client upgrading.
 * @noreturn
 */

stock Tower_OnUpgrade(iTower, iClient) {
	if (!g_bEnabled) {
		return;
	}

	new TDTowerId:iTowerId = GetTowerId(iTower);
	new iMaxLevel = Tower_GetMaxLevel(iTowerId);

	if (g_iUpgradeLevel[iTower] < iMaxLevel) {
		if (!AddClientMetal(iClient, -50)) {
			return;
		}

		g_iUpgradeMetal[iTower] += 50;

		if (g_iUpgradeMetal[iTower] >= Tower_GetMetal(iTowerId)) {
			g_iUpgradeMetal[iTower] = 0;
			g_iUpgradeLevel[iTower]++;

			// Upgrade tower to next level
			TF2Attrib_SetByDefIndex(iTower, 2, Tower_GetDamageScale(iTowerId));
			TF2Attrib_SetByDefIndex(iTower, 6, 1.0 / Tower_GetAttackspeedScale(iTowerId));
		}
	}

	HideAnnotation(iTower);
	HideAdvancedAnnotation(iClient, iTower);

	if (g_iUpgradeLevel[iTower] == iMaxLevel) {
		AttachAnnotation(iTower, 2.0, "%N\nCurrent Level: %d\nMax. Level Reached", iTower, g_iUpgradeLevel[iTower]);
	} else {
		AttachAnnotation(iTower, 2.0, "%N\nCurrent Level: %d\nUpgrade Progress: %d/%d", iTower, g_iUpgradeLevel[iTower], g_iUpgradeMetal[iTower], Tower_GetMetal(iTowerId));
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
 * Teleports a tower to his spawn location.
 *
 * @param iTower		The tower.
 * @return				True on success, false ontherwise.
 */

stock bool:Tower_TeleportToSpawn(iTower) {
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
			if (Tower_GetName(iTowerId, sName, sizeof(sName))) {
				Log(TDLogLevel_Debug, "Tower (%s) teleported", sName);
			}

			return true;
		}
	}
	
	return false;
}

/**
 * Changes a towers weapon.
 *
 * @param iTower		The tower.
 * @param iWeaponId		The weapons id.
 * @return				True on success, false ontherwise.
 */

stock bool:Tower_ChangeWeapon(iTower, iWeaponId) {
	if (!g_bEnabled) {
		return false;
	}

	if (IsTower(iTower)) {
		new iIndex = -1;
		if ((iIndex = Weapon_GetIndex(iWeaponId)) != -1) {
			new iSlot = -1;
			if ((iSlot = Weapon_GetSlot(iWeaponId)) != -1) {
				new iLevel = -1;
				if ((iLevel = Weapon_GetLevel(iWeaponId)) != -1) {
					new iQuality = -1;
					if ((iQuality = Weapon_GetQuality(iWeaponId)) != -1) {
						decl String:sClassname[64];
						if (Weapon_GetClassname(iWeaponId, sClassname, sizeof(sClassname))) {
							new bool:bPreserveAttributes = Weapon_GetPreserveAttributes(iWeaponId);

							TF2_RemoveAllWeapons(iTower);
							TF2Items_GiveWeapon(iTower, iIndex, iSlot, iLevel, iQuality, bPreserveAttributes, sClassname, "");

							return true;
						}
					}
				}
			}
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

stock Tower_Pickup(iClient) {
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

stock Tower_Drop(iClient) {
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

	fAngles[0] = Tower_GetPitch(GetTowerId(iTower));

	TeleportEntity(iTower, fLocation, fAngles, NULL_VECTOR);

	HideAnnotation(iClient);

	TF2Attrib_RemoveByName(iClient, "cannot pick up buildings");

	g_iLastMover[iTower] = iClient;
	g_bCarryingObject[iClient] = false;
	g_iAttachedTower[iClient] = 0;
	Log(TDLogLevel_Debug, "%N dropped tower (%N)", iClient, iTower);
}

/**
 * Shows tower info to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock Tower_ShowInfo(iClient) {
	if (!g_bEnabled) {
		return;
	}

	new iTower = GetAimTarget(iClient);

	if (IsTower(iTower)) {
		new TDTowerId:iTowerId = GetTowerId(iTower);

		if (g_iUpgradeLevel[iTower] == Tower_GetMaxLevel(iTowerId)) {
			AttachAdvancedAnnotation(iClient, iTower, 4.0, "%N\nCurrent Level: %d\nMax. Level Reached", iTower, g_iUpgradeLevel[iTower]);
		} else {
			AttachAdvancedAnnotation(iClient, iTower, 4.0, "%N\nCurrent Level: %d\nUpgrade Progress: %d/%d", iTower, g_iUpgradeLevel[iTower], g_iUpgradeMetal[iTower], Tower_GetMetal(iTowerId));
		}
	}
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
		decl String:sAnglesParts[6][16];
		ExplodeString(sAngles, " ", sAnglesParts, sizeof(sAnglesParts), sizeof(sAnglesParts[]));

		fAngles[0] = Tower_GetPitch(iTowerId);
		fAngles[1] = StringToFloat(sAnglesParts[4]);
		fAngles[2] = StringToFloat(sAnglesParts[5]);

		return true;
	}

	return false;
}

/**
 * Gets the metal to upgrade the tower to the next level.
 *
 * @param iTowerId 		The towers id.
 * @return				The towers upgrade metal, or -1 on failure.
 */

stock Tower_GetMetal(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_metal", _:iTowerId, g_iUpgradeLevel[iTower]);

		new iMetal = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iMetal)) {
			return -1;
		}

		return iMetal;
	}

	return -1;
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
 * Checks if a tower should do primary attacks.
 *
 * @param iTowerId 		The towers id.
 * @return				True if should attack, false otherwise.
 */

stock bool:Tower_GetAttackPrimary(TDTowerId:iTowerId) {
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

stock bool:Tower_GetAttackSecondary(TDTowerId:iTowerId) {
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

stock bool:Tower_GetRotate(TDTowerId:iTowerId) {
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
 * Gets the towers pitch.
 *
 * @param iTowerId 		The towers id.
 * @return				The pitch, or 10.0 on failure.
 */

stock Float:Tower_GetPitch(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_pitch", _:iTowerId, g_iUpgradeLevel[iTower]);

		new iPitch = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iPitch)) {
			return 0.0;
		}

		return float(iPitch);
	}

	return 0.0;
}

/**
 * Gets the towers damage scale.
 *
 * @param iTowerId 		The towers id.
 * @return				The damage scale, or 1.0 on failure.
 */

stock Float:Tower_GetDamageScale(TDTowerId:iTowerId) {
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

stock Float:Tower_GetAttackspeedScale(TDTowerId:iTowerId) {
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

stock Float:Tower_GetAreaScale(TDTowerId:iTowerId) {
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

/**
 * Gets the towers max level.
 *
 * @param iTowerId 		The towers id.
 * @return				The max level, or 1 on failure.
 */

stock Tower_GetMaxLevel(TDTowerId:iTowerId) {
	new iTower = GetTower(iTowerId);

	if (IsTower(iTower)) {
		decl String:sKey[32];
		Format(sKey, sizeof(sKey), "%d_1_metal", _:iTowerId);

		new iLevel = 1, iMetal = 0;
		while (GetTrieValue(g_hMapTowers, sKey, iMetal)) {
			iLevel++;
			Format(sKey, sizeof(sKey), "%d_%d_metal", _:iTowerId, iLevel);
		}

		return iLevel - 1;
	}

	return 1;
}