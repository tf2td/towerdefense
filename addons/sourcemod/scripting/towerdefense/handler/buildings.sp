#pragma semicolon 1

#include <dhooks>
#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Dhooks functions for dispensers
 * Add metal to global count when a player gets metal from it. 
 * Amount based on dispenser level.
 */

public MRESReturn DispenseMetal(int thisp, Handle hReturn, Handle hParams)
{
	if(hReturn != null)
	{
		int level = GetEntProp(thisp, Prop_Send, "m_iUpgradeLevel");
		int metal = GetEntProp(thisp, Prop_Send, "m_iAmmoMetal");
		int client = DHookGetParam(hParams, 1);
		
		if (IsTower(client)) {
			// Block towers from taking metal from the dispenser
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;	
		}
		
		// TODO(hurp): fix dispeners not draining metal when clients have
		//			   >5000 metal, this hack isn't that great
		if (metal > 0 && GetClientMetal(client) >= 5000) {
			switch (level) {
				case 1: { AddGlobalMetal(10); }
				case 2: { AddGlobalMetal(15); }
				case 3: { AddGlobalMetal(20); }
			}
		}
	}
	return MRES_Ignored;
}

public void Dispenser_OnSpawnPost(int iEntity)
{
    DHookEntity(hDispenseMetal, false, iEntity);
}

