#pragma semicolon 1

#include <dhooks>
#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

public void InitDhooks() {
	Handle hGameConf = LoadGameConfigFile("tf2.dispenser");
	if(hGameConf == null) {
		SetFailState("tf2.dispenser.txt Not Found");
	}
	
	int DispenseMetalOffset = GameConfGetOffset(hGameConf, "CObjectDispenser::DispenseMetal");
	if(DispenseMetalOffset == -1) {
		SetFailState("Failed To Get Offset For CObjectDispenser::DispenseMetal");
	}
	
	hDispenseMetal = DHookCreate(DispenseMetalOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, DispenseMetal);
	DHookAddParam(hDispenseMetal, HookParamType_CBaseEntity, _, DHookPass_ByRef);
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CObjectDispenser::DispenseMetal");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hDispenseMetalCall = EndPrepSDKCall();
	if(hDispenseMetalCall == null)
		SetFailState("Failed To End SDKCall hDispenseMetalCall");
	
	delete hGameConf;
	
	int ent = -1; 
	while((ent = FindEntityByClassname(ent, "obj_dispenser")) != INVALID_ENT_REFERENCE)
	{
	    if(IsValidEntity(ent)) Dispenser_OnSpawnPost(ent);
	}
}