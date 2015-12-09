/**
 * Checks for clients near AoE Towers
 *
 * @param hTimer 		Timer Handle 
 * @param iTower 		The tower
 * @noreturn
 */
public Action Timer_ClientNearAoETower(Handle hTimer) {
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
			if (IsTower(iClient)){
				int iTower = iClient;
				TDTowerId iTowerId = GetTowerId(iTower);
			
				if(iTowerId == TDTower_AoE_Engineer) {
					float fAreaScale = 80.0 * Tower_GetAreaScale(GetTowerId(iTower));
					CreateBeamBoxAroundClient(iTower, fAreaScale, true, 0.2, {231, 76, 60, 25});
					Tower_ObjectNearAoEEngineer(iTower, iClient);
				}
				if(iTowerId == TDTower_Medic) {
					float fAreaScale = 160.0 * Tower_GetAreaScale(GetTowerId(iTower));
					CreateBeamBoxAroundClient(iTower, fAreaScale, true, 0.2, {46, 204, 113, 25});
					Tower_ObjectNearAoEMedic(iTower);
				}
				if(iTowerId == TDTower_Kritz_Medic) {
					float fAreaScale = 60.0 * Tower_GetAreaScale(GetTowerId(iTower));
					CreateBeamBoxAroundClient(iTower, fAreaScale, true, 0.2, {41, 128, 185, 25});
					Tower_ObjectNearKritzMedic(iTower);
				}	
				if(iTowerId == TDTower_Slow_Spy) {
					float fAreaScale = 100.0 * Tower_GetAreaScale(GetTowerId(iTower));
					CreateBeamBoxAroundClient(iTower, fAreaScale, false, 0.2, {44, 62, 80, 25});
					Tower_ObjectNearAoESpy(iTower);
				}
				
				
			}
		}
	}
}

/**
 * Player is close to AoEMedic
 * 
 * @param iTower 		The tower
 * @param iClient 		The player
 * @noreturn
 */
public void Tower_ObjectNearAoEMedic(int iTower) {
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient) && IsClientInZone(iClient, g_fBeamPoints[iTower])) {
			Player_AddHealth(iClient, 5);
	
			//Check if there is no Beam
			if(g_iHealBeamIndex[iClient][0] == 0 && g_iHealBeamIndex[iClient][1] == 0) {
				AttachHealBeam(iTower, iClient);
			}
			
		} else {
			Tower_ObjectNotNearAoEMedic(iClient);
		}
	}
}



/**
 * Player isn't close to AoEMedic
 * 
 * @param iTower 		The tower
 * @param iClient 		The player
 * @noreturn
 */
public void Tower_ObjectNotNearAoEMedic(int iClient) {
	//Remove Beam if there is one
	if (g_iHealBeamIndex[iClient][0] != 0) {
		if(IsValidEdict(g_iHealBeamIndex[iClient][0])) {
			RemoveEdict(g_iHealBeamIndex[iClient][0]);
			g_iHealBeamIndex[iClient][0] = 0;
		}
	}
			
	if (g_iHealBeamIndex[iClient][1] != 0) {
		if(IsValidEdict(g_iHealBeamIndex[iClient][1])) {
			RemoveEdict(g_iHealBeamIndex[iClient][1]);
			g_iHealBeamIndex[iClient][1] = 0;
		}
	}
}

/**
 * Player is close to AoEEngineer
 * 
 * @param iTower 		The tower
 * @param iClient 		The player
 * @noreturn
 */
public void Tower_ObjectNearAoEEngineer(int iTower, int iClient) {
	
	if(iAoEEngineerTimer < 3 && !IsTowerAttached(iTower)) {
		iAoEEngineerTimer++;
		return;
	} else if(!IsTowerAttached(iTower)) {
		iAoEEngineerTimer = 0;
	}
	int iSentry = -1, iDispenser = -1;
	float fLocation[3];
	
	//Sentries
	while ((iSentry = FindEntityByClassname(iSentry, "obj_sentrygun")) != -1) {
		if (!IsValidEntity(iSentry)) {
			continue;
		}
		
		GetEntPropVector(iSentry, Prop_Send, "m_vecOrigin", fLocation);
		fLocation[2] += 20.0;
	
		if (IsPointInZone(fLocation, g_fBeamPoints[iTower])) {
		
	
			int iShellsMax, iHealthMax, iRocketsMax, iMetalMax;

			if (IsMiniSentry(iSentry)) {
				iShellsMax =   150;
				iHealthMax =   150;
				iRocketsMax =    0;
				iMetalMax =      0;
			} else {
				switch (GetBuildingLevel(iSentry)) {
					case 1: {
						iShellsMax =   150;
						iHealthMax =   150;
						iRocketsMax =    0;
						iMetalMax =    1000;
					}

					case 2: {
						iShellsMax =   200;
						iHealthMax =   180;
						iRocketsMax =    0;
						iMetalMax =    1000;
					}

					case 3: {
						iShellsMax =   200;
						iHealthMax =   216;
						iRocketsMax =   20;
						iMetalMax =      0;
					}
				}
			}
			
			int iState = GetEntProp(iSentry, Prop_Send, "m_iState");

			// If is not building up
			if (iState != 0) {
				int iShells = GetEntProp(iSentry, Prop_Send, "m_iAmmoShells");
				int iHealth = GetEntProp(iSentry, Prop_Send, "m_iHealth");
				int iRockets = GetEntProp(iSentry, Prop_Send, "m_iAmmoRockets");
				int iMetal = GetEntProp(iSentry, Prop_Send, "m_iUpgradeMetal");
			
				if (IsMiniSentry(iSentry)) {
					int iShellsPerHit = 20; 	// Default: 40
					
					if (iShells + iShellsPerHit < iShellsMax) {
						SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShells + iShellsPerHit);
					} else if (iShells < iShellsMax) {
						SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShellsMax);
					}
				} else {
					int iMetalPerHit = 10; 		// Default: 25
					int iHealthPerHit = 50; 	// Default: 105
					int iShellsPerHit = 20; 	// Default: 40
					int iRocketsPerHit = 4; 	// Default: 8

					if (iMetal < iMetalMax) {
						SetEntProp(iSentry, Prop_Send, "m_iUpgradeMetal", iMetal + iMetalPerHit);
					
					// Upgrade to the next level
					} else if (iMetalMax != 0 && !g_bAoEEngineerAttack) { 
					
						float fLocationTower[3];
						GetClientAbsOrigin(iTower, fLocationTower);

						TeleportEntity(iTower, fLocation, NULL_VECTOR, NULL_VECTOR);

						g_bAoEEngineerAttack = true;
				
						DataPack hPack = new DataPack();
						hPack.WriteFloat(float(iTower));
						hPack.WriteFloat(fLocationTower[0]);
						hPack.WriteFloat(fLocationTower[1]);
						hPack.WriteFloat(fLocationTower[2]);

						CreateTimer(0.2, Timer_TeleportAoEEngineerBack, hPack, _);				
					}

					if (iHealth + iHealthPerHit < iHealthMax) {
						SetEntProp(iSentry, Prop_Send, "m_iHealth", iHealth + iHealthPerHit);
					} else if (iHealth < iHealthMax) {
						SetEntProp(iSentry, Prop_Send, "m_iHealth", iHealthMax);
					}
	
					if (iShells + iShellsPerHit < iShellsMax) {
						SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShells + iShellsPerHit);
					} else if (iShells < iShellsMax) {
						SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShellsMax);
					}
					if (iRockets + iRocketsPerHit < iRocketsMax) {
						SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", iRockets + iRocketsPerHit);
					} else if (iRockets < iRocketsMax) {
						SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", iRocketsMax);
					}
				}
			}
		}
	}
	
	//Dispensers
	while ((iDispenser = FindEntityByClassname(iDispenser, "obj_dispenser")) != -1) {
		if (!IsValidEntity(iDispenser)) {
			continue;
		}

		GetEntPropVector(iDispenser, Prop_Send, "m_vecOrigin", fLocation);

		fLocation[2] += 20.0;

		if (IsPointInZone(fLocation, g_fBeamPoints[iTower])) {
			int iHealthMax, iMetalMax;

			switch (GetBuildingLevel(iDispenser)) {
				case 1: {
					iHealthMax = 150;
					iMetalMax =  500;
				}

				case 2: {
					iHealthMax = 180;
					iMetalMax =  500;
				}

				case 3: {
					iHealthMax = 216;
					iMetalMax =    0;
				}
			}

			int iBuildingUp = GetEntProp(iDispenser, Prop_Send, "m_bBuilding");
			if (iBuildingUp != 1) { // Is not building up
				int iHealth = GetEntProp(iDispenser, Prop_Send, "m_iHealth");
				int iMetal = GetEntProp(iDispenser, Prop_Send, "m_iUpgradeMetal");
				int iMetalPerHit = 10; 		// Default: 25
				int iHealthPerHit = 50; 	// Default: 105

				if (iMetal < iMetalMax) {
					SetEntProp(iDispenser, Prop_Send, "m_iUpgradeMetal", iMetal + iMetalPerHit);
				} else if (iMetalMax != 0 && !g_bAoEEngineerAttack) { // Upgrade to the next level
					float fLocationTower[3];
					GetClientAbsOrigin(iTower, fLocationTower);

					TeleportEntity(iTower, fLocation, NULL_VECTOR, NULL_VECTOR);

					g_bAoEEngineerAttack = true;

					DataPack hPack = new DataPack();
					hPack.WriteFloat(float(iTower));
					hPack.WriteFloat(fLocationTower[0]);
					hPack.WriteFloat(fLocationTower[1]);
					hPack.WriteFloat(fLocationTower[2]);

					CreateTimer(0.5, Timer_TeleportAoEEngineerBack, hPack, _);
				}

				if (iHealth + iHealthPerHit < iHealthMax) {
					SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealth + iHealthPerHit);
				} else if (iHealth < iHealthMax) {
					SetEntProp(iDispenser, Prop_Send, "m_iHealth", iHealthMax);
				}
			}
		}
	}
}

public Action Timer_TeleportAoEEngineerBack(Handle hTimer, DataPack hPack) {
	hPack.Reset();
	
	g_bAoEEngineerAttack = false;
	int iTower = RoundToZero(ReadPackFloat(hPack));
	float fLocation[3];
	fLocation[0] = hPack.ReadFloat();
	fLocation[1] = hPack.ReadFloat();
	fLocation[2] = hPack.ReadFloat();
	TeleportEntity(iTower, fLocation, NULL_VECTOR, NULL_VECTOR);
}

/**
 * Player is close to KritzMedic
 * 
 * @param iTower 		The tower
 * @noreturn
 */
public void Tower_ObjectNearKritzMedic(int iTower) {

	//If Kritz Time is up
	if(TF2_GetUberLevel(iTower) <= 0.0)
		g_bKritzMedicCharged = false;
		
	//If Bot is fully charged, charge player	
	if(g_bKritzMedicCharged && TF2_GetUberLevel(iTower) > 0.0) {
		TF2_SetUberLevel(iTower, TF2_GetUberLevel(iTower) - 0.02);
		for (int iClient = 1; iClient <= MaxClients; iClient++) {
			if(IsValidClient(iClient))
				TF2_AddCondition(iClient, TFCond_Kritzkrieged, 0.3);
		}
	//If Bot is fully charged	
	} else if(TF2_GetUberLevel(iTower) >= 1.0) {
		g_bKritzMedicCharged = true;	
	} else if(iAoEKritzMedicTimer < 3 && !IsTowerAttached(iTower)) {
		iAoEKritzMedicTimer++;
		return;
	} else if(!IsTowerAttached(iTower)) {
		iAoEKritzMedicTimer = 0;
	}
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if(IsDefender(iClient) && IsClientInZone(iClient, g_fBeamPoints[iTower])) {
			float fUberLevel = TF2_GetUberLevel(iTower);
			TF2_SetUberLevel(iTower, fUberLevel + 0.01);
		}
	}
}

/**
 * Player is close to AoESpy
 * 
 * @param iTower 		The tower
 * @param iClient 		The player
 * @noreturn
 */
public void Tower_ObjectNearAoESpy(int iTower) {
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsAttacker(iClient) && IsClientInZone(iClient, g_fBeamPoints[iTower]) && !g_iSlowAttacker[iClient])
			g_iSlowAttacker[iClient] = true;
		else if(g_iSlowAttacker[iClient] && IsClientInZone(iClient, g_fBeamPoints[iTower]))
			TF2_AddCondition(iClient, TFCond_TeleportedGlow, 1.0);
		else if (g_iSlowAttacker[iClient])
			g_iSlowAttacker[iClient] = false;
	}
}

/**
 * Gets the level of an building.
 *
 * @param iEntity		The buildings entity index.
 * @return				The buildings level.
 */

public int GetBuildingLevel(int iEntity) {
	return GetEntProp(iEntity, Prop_Send, "m_iUpgradeLevel");	
}

/**
 * Checks wheter a sentry is a Mini-Sentry or not.
 *
 * @param iSentry		The sentries entity index.
 * @return				True if mini, false otherwise.
 */

public bool IsMiniSentry(int iSentry) {
	return ((GetEntProp(iSentry, Prop_Send, "m_bMiniBuilding") == 0) ? false : true);	
}

/**
 * Attach a beam between two entities
 * 
 * @param iEntity 		The start point
 * @param iTarget		The target
 * @noreturn
 */
stock void AttachHealBeam(int iEntity, int iTarget) {
	int iParticleIndex1  = CreateEntityByName("info_particle_system");
	int iParticleIndex2 = CreateEntityByName("info_particle_system");

	if (IsValidEdict(iParticleIndex1)) { 
		char sEntityName[128];
		Format(sEntityName, sizeof(sEntityName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", sEntityName);
 
		char sTargetName1[128];
		Format(sTargetName1, sizeof(sTargetName1), "target%i", iTarget);
		DispatchKeyValue(iTarget, "targetname", sTargetName1);

		char sTargetName2[128];
		Format(sTargetName2, sizeof(sTargetName2), "tf2particle%i", iTarget);
 
		DispatchKeyValue(iParticleIndex2, "targetname", sTargetName2);
		DispatchKeyValue(iParticleIndex2, "parentname", sTargetName1);
 
		SetVariantString(sTargetName1);
		AcceptEntityInput(iParticleIndex2, "SetParent");
 
		SetVariantString("flag");
		AcceptEntityInput(iParticleIndex2, "SetParentAttachment");
 
		DispatchKeyValue(iParticleIndex1, "targetname", "tf2particle");
		DispatchKeyValue(iParticleIndex1, "parentname", sEntityName);
		DispatchKeyValue(iParticleIndex1, "effect_name", "dispenser_heal_blue");
		DispatchKeyValue(iParticleIndex1, "cpoint1", sTargetName2);
 
		DispatchSpawn(iParticleIndex1);
 
		SetVariantString(sEntityName);
		AcceptEntityInput(iParticleIndex1, "SetParent");
 
		SetVariantString("flag");
		AcceptEntityInput(iParticleIndex1, "SetParentAttachment");

		ActivateEntity(iParticleIndex1);
		AcceptEntityInput(iParticleIndex1, "start");

		g_iHealBeamIndex[iTarget][0] = iParticleIndex1;
		g_iHealBeamIndex[iTarget][1] = iParticleIndex2;
 	}
}

stock float TF2_GetUberLevel(int iClient)
{
	int iIndex = GetPlayerWeaponSlot(iClient, 1);
	if (iIndex > 0)
		return GetEntPropFloat(iIndex, Prop_Send, "m_flChargeLevel");
	else
		return 0.0;
}

stock void TF2_SetUberLevel(int iClient, float fUberLevel)
{
	int iIndex = GetPlayerWeaponSlot(iClient, 1);
	if (iIndex > 0)
		SetEntPropFloat(iIndex, Prop_Send, "m_flChargeLevel", fUberLevel);
    }
