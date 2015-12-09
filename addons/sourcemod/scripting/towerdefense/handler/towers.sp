#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Called when a buy-tower button is being shot.
 *
 * @param iTowerId		The tower id.
 * @param iButton		The button entity.
 * @param iActivator	The activator entity.
 * @noreturn
 */

stock void Tower_OnButtonBuy(TDTowerId iTowerId, int iButton, int iActivator) {
	if (!g_bEnabled) {
		return;
	}
	
	if (!IsDefender(iActivator)) {
		return;
	}
	
	if (!g_bTowerBought[view_as<int>(iTowerId)]) {
		int iPrice = Tower_GetPrice(iTowerId);
		char sName[MAX_NAME_LENGTH];
		Tower_GetName(iTowerId, sName, sizeof(sName));
		
		PrintToChatAll("\x01Buying \x04%s\x01 (Total price: \x04%d metal\x01)", sName, iPrice);
		
		int iClients = GetRealClientCount(true);
		
		if (iClients <= 0) {
			iClients = 1;
		}
		
		iPrice /= iClients;
		
		if (CanAfford(iPrice)) {
			Tower_Spawn(iTowerId);
			
			for (int iClient = 1; iClient <= MaxClients; iClient++) {
				if (IsDefender(iClient)) {
					AddClientMetal(iClient, -iPrice);
					
					Player_CAddValue(iClient, PLAYER_TOWERS_BOUGHT, 1);
				}
			}
			
			PrintToChatAll("\x01%N bought \x04%s", iActivator, sName);
			
			g_bTowerBought[view_as<int>(iTowerId)] = true;
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

stock void Tower_OnButtonTeleport(TDTowerId iTowerId, int iButton, int iActivator) {
	if (!g_bEnabled) {
		return;
	}
	
	int iTower = GetTower(iTowerId);
	
	if (!IsTower(iTower)) {
		return;
	}
	
	if (!IsTowerAttached(iTower)) {
		Tower_TeleportToSpawn(iTower);
	}
}

/**
 * Called when a tower spawned.
 *
 * @param iTower		The tower.
 * @param iTowerId		The tower id.
 * @noreturn
 */

stock void Tower_OnSpawn(int iTower, TDTowerId iTowerId) {
	if (!g_bEnabled) {
		return;
	}
	
	g_iUpgradeMetal[iTower] = 0;
	g_iUpgradeLevel[iTower] = 1;
	g_iLastMover[iTower] = 0;
	
	SetEntProp(iTower, Prop_Data, "m_bloodColor", view_as<int>(TDBlood_None));
	SetRobotModel(iTower);
	
	// Change weapon
	Tower_ChangeWeapon(iTower, Tower_GetWeapon(iTowerId));
	
	// Teleport
	Tower_TeleportToSpawn(iTower);
	
	//Check for AoE
	Tower_AoeSetup(iTower, iTowerId);
}

/**
 * Check if Tower is AoE and execute timer if this is true
 *
 * @param iTower		The tower.
 * @param iTowerId		The tower id.
 * @noreturn
 */

stock void Tower_AoeSetup(int iTower, TDTowerId iTowerId) {	 
	if (!IsTower(iTower)) {
		return;
	}
	char sDamagetype[20];
	if(Tower_GetDamagetype(iTowerId, sDamagetype, sizeof(sDamagetype)))
	{
		if(StrEqual(sDamagetype, "AoE")) {
			if(hAoETimer == null)
				hAoETimer = CreateTimer(0.2, Timer_ClientNearAoETower, _, TIMER_REPEAT);
		}
	}
}

/**
 * Called when a tower touches a func_nobuild brush.
 *
 * @param iTower		The tower.
 * @param iTowerId		The tower id.
 * @noreturn
 */

stock void Tower_OnTouchNobuild(int iTower) {
	if (!g_bEnabled) {
		return;
	}
	
	Forbid(g_iLastMover[iTower], true, "Can't place a tower there.");
	Tower_TeleportToSpawn(iTower);
}

/**
 * Called when a tower is upgraded by a client.
 *
 * @param iTower		The tower.
 * @param iClient		The client upgrading.
 * @noreturn
 */

stock void Tower_OnUpgrade(int iTower, int iClient) {
	if (!g_bEnabled) {
		return;
	}
	
	TDTowerId iTowerId = GetTowerId(iTower);
	int iMaxLevel = Tower_GetMaxLevel(iTowerId);
	
	if (g_iUpgradeLevel[iTower] < iMaxLevel) {
		if (!AddClientMetal(iClient, -50)) {
			return;
		}
		
		g_iUpgradeMetal[iTower] += 50;
		
		if (g_iUpgradeMetal[iTower] >= Tower_GetMetal(iTowerId)) {
			
			int iWeapon = Tower_GetWeapon(iTowerId);
			g_iUpgradeMetal[iTower] = 0;
			g_iUpgradeLevel[iTower]++;
			
			if (iWeapon != Tower_GetWeapon(iTowerId)) {
				Tower_ChangeWeapon(iTower, Tower_GetWeapon(iTowerId));
			} else {
				Tower_SetLevelAttributes(iTower, iTowerId);
			}
			
			PrintToChatAll("\x04%N\x01 reached level \x04%d", iTower, g_iUpgradeLevel[iTower]);
			
			float fDamageScale = Tower_GetDamageScale(iTowerId);
			if (fDamageScale > 1.0) {
				PrintToChatAll("\x04%N\x01 gained \x04%d%% damage bonus", iTower, RoundFloat(fDamageScale * 100 - 100));
			} else if(fDamageScale < 1.0) {
				PrintToChatAll("\x04%N\x01 gained \x04%d%% attackspeed", iTower, RoundFloat(fDamageScale * 100));
			}
			
			float fAttackspeedScale = Tower_GetAttackspeedScale(iTowerId);
			if (fAttackspeedScale > 1.0) {
				PrintToChatAll("\x04%N\x01 gained \x04%d%% attackspeed", iTower, RoundFloat(fAttackspeedScale * 100 - 100));
			} else if(fAttackspeedScale < 1.0) {
				PrintToChatAll("\x04%N\x01 gained \x04%d%% attackspeed", iTower, RoundFloat(fAttackspeedScale * 100));
			}
			if (Tower_GetRotate(iTowerId)) {
				PrintToChatAll("\x04%N\x01 can now rotate", iTower);
			}
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
 * Called when a tower changes weapons.
 *
 * @param iTower					The tower.
 * @param iTowerId					The tower id.
 * @param iItemDefinitionIndex		The items index.
 * @param iSlot						The weapons slot.
 * @param iWeapon					The weapon entity.
 * @noreturn
 */

stock void Tower_OnWeaponChanged(int iTower, TDTowerId iTowerId, int iItemDefinitionIndex, int iSlot, int iWeapon) {
	SetEntPropEnt(iTower, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(iTower, iSlot));
	
	Tower_SetLevelAttributes(iTower, iTowerId);
}

/**
 * Called when a carrier of a tower disconnects or has a timeout.
 *
 * @param iTower		The tower.
 * @param iCarrier		The carrier.
 * @noreturn
 */

stock void Tower_OnCarrierDisconnected(int iTower, int iCarrier) {
	SetEntityMoveType(iTower, MOVETYPE_WALK);
	HideAnnotation(iCarrier);
	
	g_iLastMover[iTower] = iCarrier;
	g_bCarryingObject[iCarrier] = false;
	g_iAttachedTower[iCarrier] = 0;
	
	Log(TDLogLevel_Debug, "%N dropped tower (%N)", iCarrier, iTower);
	
	Tower_TeleportToSpawn(iTower);
}

/**
 * Called when a carrier of a tower dies.
 *
 * @param iTower		The tower.
 * @param iCarrier		The carrier.
 * @noreturn
 */

stock void Tower_OnCarrierDeath(int iTower, int iCarrier) {
	SetEntityMoveType(iTower, MOVETYPE_WALK);
	HideAnnotation(iCarrier);
	
	g_iLastMover[iTower] = iCarrier;
	g_bCarryingObject[iCarrier] = false;
	g_iAttachedTower[iCarrier] = 0;
	
	Log(TDLogLevel_Debug, "%N dropped tower (%N)", iCarrier, iTower);
	
	Tower_TeleportToSpawn(iTower);
}

/**
 * Spawns a tower.
 *
 * @param iTowerId		The towers id.
 * @return				True on success, false otherwise.
 */

stock bool Tower_Spawn(TDTowerId iTowerId) {
	if (!g_bEnabled) {
		return false;
	}
	
	char sName[MAX_NAME_LENGTH], sClass[32];
	
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
 * @return				True on success, false otherwise.
 */

stock bool Tower_TeleportToSpawn(int iTower) {
	if (!g_bEnabled) {
		return false;
	}
	
	TDTowerId iTowerId = GetTowerId(iTower);
	
	if (iTowerId == TDTower_Invalid) {
		return false;
	}
	
	float fLocation[3], fAngles[3];
	
	if (Tower_GetLocation(iTowerId, fLocation)) {
		if (Tower_GetAngles(iTowerId, fAngles)) {
			TeleportEntity(iTower, fLocation, fAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
			
			char sName[MAX_NAME_LENGTH];
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
 * @return				True on success, false otherwise.
 */

stock bool Tower_ChangeWeapon(int iTower, int iWeaponId) {
	if (!g_bEnabled) {
		return false;
	}
	
	if (IsTower(iTower)) {
		int iIndex = -1;
		if ((iIndex = Weapon_GetIndex(iWeaponId)) != -1) {
			int iSlot = -1;
			if ((iSlot = Weapon_GetSlot(iWeaponId)) != -1) {
				int iLevel = -1;
				if ((iLevel = Weapon_GetLevel(iWeaponId)) != -1) {
					int iQuality = -1;
					if ((iQuality = Weapon_GetQuality(iWeaponId)) != -1) {
						char sClassname[64];
						if (Weapon_GetClassname(iWeaponId, sClassname, sizeof(sClassname))) {
							bool bPreserveAttributes = Weapon_GetPreserveAttributes(iWeaponId);
							
							for (int i = 0; i < 3; i++) {
								if (i != iSlot) {
									TF2_RemoveWeaponSlot(iTower, i);
								}
							}
							
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
 * Sets a towers level attributes.
 *
 * @param iTower		The tower.
 * @param iTowerId		The towers id.
 * @noreturn
 */

stock void Tower_SetLevelAttributes(int iTower, TDTowerId iTowerId) {
	int iWeapon = GetEntPropEnt(iTower, Prop_Send, "m_hActiveWeapon");
	
	if (TF2Attrib_SetByDefIndex(iWeapon, 2, Tower_GetDamageScale(iTowerId))) {
		Log(TDLogLevel_Trace, "Successfully set attribute %d on %N to %f", 2, iTower, Tower_GetDamageScale(iTowerId));
	}
	
	if (TF2Attrib_SetByDefIndex(iTower, 6, 1.0 / Tower_GetAttackspeedScale(iTowerId))) {
		Log(TDLogLevel_Trace, "Successfully set attribute %d on %N to %f", 6, iTower, 1.0 / Tower_GetAttackspeedScale(iTowerId));
	}
}

/**
 * Attaches a tower to a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock void Tower_Pickup(int iClient) {
	if (!g_bEnabled) {
		return;
	}
	
	int iTower = GetAimTarget(iClient);
	
	if (IsTower(iTower)) {
		if (IsTowerAttached(iTower)) {
			Forbid(iClient, true, "%N is already being moved by someone!", iTower);
			return;
		}
	
		if(g_bTowersLocked){
			Forbid(iClient, true, "You can't move towers mid wave!");
			return;
		}
		
		TF2Attrib_SetByName(iClient, "cannot pick up buildings", 1.0);
		
		SetEntityMoveType(iTower, MOVETYPE_NOCLIP);
		
		TeleportEntity(iTower, view_as<float>( { 0.0, 0.0, -8192.0 } ), NULL_VECTOR, NULL_VECTOR); // Teleport out of the map
		
		HideAnnotation(iTower);
		AttachAnnotation(iClient, 86400.0, "Moving: %N", iTower);
		
		g_bCarryingObject[iClient] = true;
		g_iAttachedTower[iClient] = iTower;
		
		PrintToChat(iClient, "\x01You picked up \x04%N", iTower);
		Log(TDLogLevel_Debug, "%N picked up tower (%N)", iClient, iTower);
	}
}

/**
 * Detaches a tower from a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock void Tower_Drop(int iClient) {
	if (!g_bEnabled) {
		return;
	}
	
	if (g_bInsideNobuild[iClient]) {
		Forbid(iClient, true, "Towers aren't meant to be placed on the path!");
		return;
	}
	
	if(g_bTowersLocked){
			Forbid(iClient, true, "You can't place towers mid wave!");
			return;
		}
	
	int iTower = g_iAttachedTower[iClient];
	float fLocation[3], fAngles[3];
	
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

stock void Tower_ShowInfo(int iClient) {
	if (!g_bEnabled) {
		return;
	}
	
	int iTower = GetAimTarget(iClient);
	
	if (IsTower(iTower)) {
		TDTowerId iTowerId = GetTowerId(iTower);
		
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

stock int GetVisibilityBitfield(int iClient) {
	if (!IsDefender(iClient)) {
		return 1;
	}
	
	int iBitField = 1;
	iBitField |= RoundFloat(Pow(2.0, float(iClient)));
	return iBitField;
}

/**
 * Checks if a tower is attached to a client.
 *
 * @param iTower		The tower.
 * @return				True if tower is attached, false otherwise.
 */

stock bool IsTowerAttached(int iTower) {
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
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

stock int GetTower(TDTowerId iTowerId) {
	char sName[MAX_NAME_LENGTH], sName2[MAX_NAME_LENGTH];
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
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

stock TDTowerId GetTowerId(int iTower) {
	if (IsValidClient(iTower)) {
		char sName[MAX_NAME_LENGTH], sName2[MAX_NAME_LENGTH];
		GetClientName(iTower, sName, sizeof(sName));
		
		int iClient, iTowerId;
		
		for (iClient = 1; iClient <= MaxClients; iClient++) {
			if (IsClientInGame(iClient)) {
				for (iTowerId = 0; iTowerId < view_as<int>(TDTower_Quantity); iTowerId++) {
					Tower_GetName(view_as<TDTowerId>(iTowerId), sName2, sizeof(sName2));
					
					if (StrEqual(sName, sName2)) {
						return view_as<TDTowerId>(iTowerId);
					}
				}
			}
		}
	}
	
	return TDTower_Invalid;
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

stock bool Tower_GetName(TDTowerId iTowerId, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_name", view_as<int>(iTowerId));
	
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

stock bool Tower_GetClassString(TDTowerId iTowerId, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", view_as<int>(iTowerId));
	
	return GetTrieString(g_hMapTowers, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the class of a tower.
 *
 * @param iTowerId 		The towers id.
 * @return				The towers class type, or TFClass_Unknown on error.
 */

stock TFClassType Tower_GetClass(TDTowerId iTowerId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_class", view_as<int>(iTowerId));
	
	char sClass[32];
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

stock int Tower_GetPrice(TDTowerId iTowerId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_price", view_as<int>(iTowerId));
	
	int iPrice = 0;
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

stock bool Tower_GetLocation(TDTowerId iTowerId, float fLocation[3]) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", view_as<int>(iTowerId));
	
	char sLocation[64];
	if (GetTrieString(g_hMapTowers, sKey, sLocation, sizeof(sLocation))) {
		char sLocationParts[6][16];
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

stock bool Tower_GetAngles(TDTowerId iTowerId, float fAngles[3]) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_location", view_as<int>(iTowerId));
	
	char sAngles[64];
	if (GetTrieString(g_hMapTowers, sKey, sAngles, sizeof(sAngles))) {
		char sAnglesParts[6][16];
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

stock int Tower_GetMetal(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_metal", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		int iMetal = 0;
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

stock int Tower_GetWeapon(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_weapon", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		int iWeapon = 0;
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

stock bool Tower_GetAttackPrimary(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_attack", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		char sAttackMode[64];
		if (!GetTrieString(g_hMapTowers, sKey, sAttackMode, sizeof(sAttackMode))) {
			return false;
		}
		
		return StrEqual(sAttackMode, "Primary");
	}
	
	return false;
}

/**
 * Checks if a tower should do secondary attacks.
 *
 * @param iTowerId 		The towers id.
 * @return				True if should attack, false otherwise.
 */

stock bool Tower_GetAttackSecondary(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_attack", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		char sAttackMode[64];
		if (!GetTrieString(g_hMapTowers, sKey, sAttackMode, sizeof(sAttackMode))) {
			return false;
		}
		
		return StrEqual(sAttackMode, "Secondary");
	}
	
	return false;
}

/**
 * Checks if a tower should rotate towards enemies.
 *
 * @param iTowerId 		The towers id.
 * @return				True if should rotate, false otherwise.
 */

stock bool Tower_GetRotate(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_rotate", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		int iRotate = 0;
		if (!GetTrieValue(g_hMapTowers, sKey, iRotate)) {
			return false;
		}
		if(iRotate != 0)
			return true;
	}
	
	return false;
}

/**
 * Gets the towers pitch.
 *
 * @param iTowerId 		The towers id.
 * @return				The pitch, or 10.0 on failure.
 */

stock float Tower_GetPitch(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_pitch", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		int iPitch = 0;
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

stock float Tower_GetDamageScale(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_damage", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		float fDamage = 1.0;
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

stock float Tower_GetAttackspeedScale(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_attackspeed", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		float fAttackspeed = 1.0;
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

stock float Tower_GetAreaScale(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_%d_area", view_as<int>(iTowerId), g_iUpgradeLevel[iTower]);
		
		float fArea = 1.0;
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

stock int Tower_GetMaxLevel(TDTowerId iTowerId) {
	int iTower = GetTower(iTowerId);
	
	if (IsTower(iTower)) {
		char sKey[32];
		Format(sKey, sizeof(sKey), "%d_1_metal", view_as<int>(iTowerId));
		
		int iLevel = 1, iMetal = 0;
		while (GetTrieValue(g_hMapTowers, sKey, iMetal)) {
			iLevel++;
			Format(sKey, sizeof(sKey), "%d_%d_metal", view_as<int>(iTowerId), iLevel);
		}
		
		return iLevel - 1;
	}
	
	return 1;
}

/**
 * Gets the description of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if tower was not found.
 */

stock bool Tower_GetDescription(TDTowerId iTowerId, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_description", view_as<int>(iTowerId));
	
	return GetTrieString(g_hMapTowers, sKey, sBuffer, iMaxLength);
}

/**
 * Gets the damagetype of a tower.
 *
 * @param iTowerId 		The towers id.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false if tower was not found.
 */

stock bool Tower_GetDamagetype(TDTowerId iTowerId, char[] sBuffer, int iMaxLength) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_damagetype", view_as<int>(iTowerId));
	
	return GetTrieString(g_hMapTowers, sKey, sBuffer, iMaxLength);
} 