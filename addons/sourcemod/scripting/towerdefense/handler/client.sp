#pragma semicolon 1

#include <sourcemod>

/**
 * Initializes a client.
 *
 * @param iClient		The client.
 * @noreturn
 */

stock InitializeClient(iClient) {
	if (IsDefender(iClient)) {
		decl String:sCommunityId[32];
		
		if (GetClientCommunityId(iClient, sCommunityId, sizeof(sCommunityId))) {
			Log(TDLogLevel_Trace, "Initializing %N (%d, %s)", iClient, iClient, sCommunityId);

			SetEntityMoveType(iClient, MOVETYPE_WALK);

			Database_CheckPlayer(iClient, sCommunityId);
		}
	}
}