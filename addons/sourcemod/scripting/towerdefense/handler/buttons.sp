#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Hooks buttons.
 *
 * @noreturn
 */

stock void HookButtons() {
	HookEntityOutput("func_breakable", "OnHealthChanged", OnButtonShot);
}

public void OnButtonShot(const char[] sOutput, int iCaller, int iActivator, float fDelay) {
	char sName[64];
	GetEntPropString(iCaller, Prop_Data, "m_iName", sName, sizeof(sName));

	if (StrContains(sName, "break_tower_tp_") != -1) {
		// Tower teleport

		char sNameParts[4][32];
		ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

		TDTowerId iTowerId = view_as<TDTowerId>(StringToInt(sNameParts[3]));
		Tower_OnButtonTeleport(iTowerId, iCaller, iActivator);
	} else if (StrContains(sName, "break_tower_") != -1) {
		// Tower buy

		if (!g_bCanGetUnlocks) {
			return;
		}

		g_bCanGetUnlocks = false;
		CreateTimer(0.5, Timer_EnableUnlockButton);

		char sNameParts[3][32];
		ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

		TDTowerId iTowerId = view_as<TDTowerId>(StringToInt(sNameParts[2]));
		Tower_OnButtonBuy(iTowerId, iCaller, iActivator);
	} else if (StrEqual(sName, "break_pregame")) {
		// Pregame button

		if (hHintTimer == null) {
			hHintTimer = CreateTimer(60.0, Timer_Hints, _, TIMER_REPEAT);
		}
	} else if (StrContains(sName, "wave_start") != -1) {
		// Wave start

		if (StrEqual(sName, "wave_start")) {
			Wave_OnButtonStart(g_iCurrentWave, iCaller, iActivator);
		} else {
			char sNameParts[3][32];
			ExplodeString(sName, "_", sNameParts, sizeof(sNameParts), sizeof(sNameParts[]));

			Wave_OnButtonStart(StringToInt(sNameParts[2]), iCaller, iActivator);
		}
	} else if (StrContains(sName, "enable_sentry") != -1) {
		// Allow another sentry

		if (!g_bCanGetUnlocks) {
			return;
		}

		g_bCanGetUnlocks = false;
		CreateTimer(0.5, Timer_EnableUnlockButton);

		g_iBuildingLimit[TDBuilding_Sentry] += 1;
		
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "sentryLimitChanged", g_iBuildingLimit[TDBuilding_Sentry]);
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "sentryLimitBuildInfo");

		//PrintToChatAll("\x04[\x03TD\x04]\x03 Your sentry limit has been changed to:\x04 %i",g_iBuildingLimit[TDBuilding_Sentry]);
		//PrintToChatAll("\x04[\x03TD\x04]\x03 You can build additional sentries with the command \x04/s");
		
		AcceptEntityInput(iCaller, "Break");
	} else if (StrContains(sName, "enable_dispenser") != -1) {
		// Enable dispenser

		if (!g_bCanGetUnlocks) {
			return;
		}

		g_bCanGetUnlocks = false;
		CreateTimer(0.5, Timer_EnableUnlockButton);

		g_iBuildingLimit[TDBuilding_Dispenser] += 1;
		
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "dispenserLimitChanged", g_iBuildingLimit[TDBuilding_Dispenser]);
		CPrintToChatAll("%s %t", PLUGIN_PREFIX, "dispenserLimitBuildInfo");

		//PrintToChatAll("\x04[\x03TD\x04]\x03 Your dispenser limit has been changed to:\x04 %i",g_iBuildingLimit[TDBuilding_Dispenser]);
		//PrintToChatAll("\x04[\x03TD\x04]\x03 You can build dispensers via your PDA");
		
		AcceptEntityInput(iCaller, "Break");
	} else if (StrContains(sName, "bonus_metal") != -1) {
		// Metal bonus reward

		if (!g_bCanGetUnlocks) {
			return;
		}

		g_bCanGetUnlocks = false;
		CreateTimer(0.5, Timer_EnableUnlockButton);

		SpawnMetalPacksNumber(TDMetalPack_Start, 4);

		AcceptEntityInput(iCaller, "Break");
	} else if (StrContains(sName, "multiplier") != -1) {
		// Damage multipliers

		if (!g_bCanGetUnlocks) {
			return;
		}

		g_bCanGetUnlocks = false;
		CreateTimer(0.5, Timer_EnableUnlockButton);

		for (int i = 1; i <= iMaxMultiplierTypes; i++) {
			char sKey[32], sMultiplier[32];
			Format(sKey, sizeof(sKey), "%d_type", i);

			if (GetTrieString(g_hMultiplierType, sKey, sMultiplier, sizeof(sMultiplier))) {
				if (StrContains(sMultiplier, "crit") != -1 && StrContains(sName, "crit") != -1) {
					// Crit chance
					
					//Check if already has 100% crits
					if(fMultiplier[i] >= 20.0) {
						CPrintToChatAll("%s %t", PLUGIN_PREFIX, "critChanceLimitReached");
						//PrintToChatAll("\x04[\x03TD\x04]\x03 You can't increase crit chance anymore.");
						return;
					}

					int iPriceToPay = Multiplier_GetPrice(i) + Multiplier_GetIncrease(i) * RoundToZero(fMultiplier[i]);
					int iClients	= GetRealClientCount(true);

					if (iClients <= 0) {
						iClients = 1;
					}
		
					if(CanAfford(iPriceToPay, false)) {
						
						for (int iLoopClient = 1; iLoopClient <= MaxClients; iLoopClient++) {
							if (IsDefender(iLoopClient)) {
								AddClientMetal(iLoopClient, -iPriceToPay);
							}
						}
						fMultiplier[i] += 1.0;
						CPrintToChatAll("%s %t", PLUGIN_PREFIX, "critChanceSet", RoundToZero(fMultiplier[i] * 5.0));
						//PrintToChatAll("\x04[\x03TD\x04]\x03 Crit Chance set to:\x04 %i%", RoundToZero(fMultiplier[i] * 5.0));
						
						if(fMultiplier[i] >= 20.0) {
							CPrintToChatAll("%s %t", PLUGIN_PREFIX, "critChanceLimitReached");
							//PrintToChatAll("\x04[\x03TD\x04]\x03 You can't increase crit chance anymore.");
						} else {
							int iNextPrice = iPriceToPay + Multiplier_GetIncrease(i);
							CPrintToChatAll("%s %t", PLUGIN_PREFIX, "nextUpgradeCost", iNextPrice);
							//PrintToChatAll("\x04[\x03TD\x04]\x03 Next Upgrade will cost:\x04 %i\x03 metal per Player",iNextPrice);
						}
					}
				} else if (StrContains(sName, sMultiplier) != -1) {
					// Damage modifiers

					int iPriceToPay = Multiplier_GetPrice(i) + Multiplier_GetIncrease(i) * RoundToZero(fMultiplier[i]);
					int iClients	= GetRealClientCount(true);

					if (iClients <= 0) {
						iClients = 1;
					}

					iPriceToPay /= iClients;
		
					if(CanAfford(iPriceToPay, false)) {
		
						for (int iLoopClient = 1; iLoopClient <= MaxClients; iLoopClient++) {
							if (IsDefender(iLoopClient)) {
								AddClientMetal(iLoopClient, -iPriceToPay);
							}
						}
						fMultiplier[i] += 1.0;
						CPrintToChatAll("%s %t", PLUGIN_PREFIX, "dmgMultiplierSet", RoundToZero(fMultiplier[i] * 5.0));
						//PrintToChatAll("\x04[\x03TD\x04]\x03 Multiplier set to:\x04 %i.0",RoundToZero(fMultiplier[i] + 1.0));
			
						int iNextPrice = iPriceToPay + Multiplier_GetIncrease(i);
						CPrintToChatAll("%s %t", PLUGIN_PREFIX, "nextUpgradeCost", iNextPrice);
						//PrintToChatAll("\x04[\x03TD\x04]\x03 Next Upgrade will cost:\x04 %i\x03 metal per Player",iNextPrice);
					}
				}
			}
		}
	}
}

/**
 * Gets multiplier base price
 *
 * @param iMultiplierId 	The multipliers id.
 * @return					return 1000 on failure.
 */

stock int Multiplier_GetPrice(int iMultiplierId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_price", iMultiplierId);

	int iPrice = 0;
	if (!GetTrieValue(g_hMultiplier, sKey, iPrice)) {
		return 1000;
	}
	return iPrice;
}

/**
 * Gets multiplier increase
 *
 * @param iMultiplierId 	The multipliers id.
 * @return					return 1000 on failure.
 */

stock int Multiplier_GetIncrease(int iMultiplierId) {
	char sKey[32];
	Format(sKey, sizeof(sKey), "%d_increase", iMultiplierId);

	int iIncrease = 0;
	if (!GetTrieValue(g_hMultiplier, sKey, iIncrease)) {
		return 1000;
	}
	return iIncrease;
}

/**
 * Gets multiplier amount
 *
 * @param sDamageType 		The damage type.
 * @return					return 1 on failure.
 */

stock int Multiplier_GetInt(const char[] sDamageType) {
	char sKey[32], sMultiplier[32];

	for (int i = 0; i <= iMaxMultiplierTypes; i++) {
		Format(sKey, sizeof(sKey), "%d_type", i);
		if (GetTrieString(g_hMultiplierType, sKey, sMultiplier, sizeof(sMultiplier))) {
			if (StrContains(sMultiplier, sDamageType) != -1) {
				return i;
			}
		}
	}
	return 1;
}

/**
 * Checks if all clients have enough metal to pay a price.
 *
 * @param iPrice		The price to pay.
 * @return				True if affordable, false otherwise.
 */

stock bool CanAfford(int iPrice, bool silent) {
	bool bResult = true;

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsDefender(iClient)) {
			if (GetClientMetal(iClient) < iPrice) {
				if (!silent) {
					CPrintToChatAll("%s %t", PLUGIN_PREFIX, "towerInsufficientMetal", GetClientNameShort(iClient), iPrice - GetClientMetal(iClient));
				}
				bResult = false;
			}
		}
	}

	return bResult;
}