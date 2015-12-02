/**
 * Checks for clients near AoE Towers
 *
 * @param hTimer 		Timer Handle 
 * @param iTower 		The tower
 * @noreturn
 */
public Action Timer_ClientNearAoETower(Handle hTimer, any iTower) {
	if (!IsTower(iTower)) {
		return;
	}
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && IsPlayerAlive(iClient)) {
			if (iClient == iTower)
				continue;
			if(IsTower(iClient))
				return;
			char sName[50];
			Tower_GetName(GetTowerId(iTower), sName, sizeof(sName));
			if(StrEqual(sName,"AoEEngineerTower")) {
				CreateBeamBoxAroundClient(iTower, 80.0, true, 0.7, {255, 0, 0, 25});
			} else if(StrEqual(sName,"MedicTower")) {
				CreateBeamBoxAroundClient(iTower, 160.0, true, 0.6, {0, 255, 0, 25});
			}
					
			if (IsClientInZone(iClient, g_fBeamPoints[iTower])) {
				Tower_ObjectNearAoEMedic(iTower, iClient);
			} else {
				Tower_ObjectNotNearAoEMedic(iClient);
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
public void Tower_ObjectNearAoEMedic(int iTower, int iClient) {
	Player_AddHealth(iClient, 5);
	
	//Check if there is no Beam
	if(g_iHealBeamIndex[iClient][0] == 0 && g_iHealBeamIndex[iClient][1] == 0) {
		AttachHealBeam(iTower, iClient);
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
		RemoveEdict(g_iHealBeamIndex[iClient][0]);
		g_iHealBeamIndex[iClient][0] = 0;
	}
			
	if (g_iHealBeamIndex[iClient][1] != 0) {
		RemoveEdict(g_iHealBeamIndex[iClient][1]);
		g_iHealBeamIndex[iClient][1] = 0;
	}
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