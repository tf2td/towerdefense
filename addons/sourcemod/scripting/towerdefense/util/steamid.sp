#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

/**
 * Gets a clients steam community id.
 *
 * @param iClient		The client.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false otherwise.
 */

stock bool GetClientCommunityId(int iClient, char[] sBuffer, int iMaxLength) {
	if (!IsClientConnected(iClient) || IsFakeClient(iClient)) {
		return false;
	}
	
	int iSteamAccountId = GetSteamAccountID(iClient);
	
	if (iSteamAccountId > 0) {
		char sSteamAccountId[32];
		char[] sBase = "76561197960265728";
		// char[] sBase = { "7", "6", "5", "6", "1", "1", "9", "7", "9", "6", "0", "2", "6", "5", "7", "2", "8" };
		char[] sSteamId = new char[iMaxLength];
		
		IntToString((iSteamAccountId - iSteamAccountId % 2) / 2, sSteamAccountId, sizeof(sSteamAccountId));
		
		int iCurrent, iCarryOver = iSteamAccountId % 2;
		for (int i = (iMaxLength - 2), j = (strlen(sSteamAccountId) - 1), k = (strlen(sBase) - 1); i >= 0; i--, j--, k--) {
			iCurrent = (j >= 0 ? (2 * (sSteamAccountId[j]-'0')) : 0) + iCarryOver + (k >= 0 ? ((sBase[k]-'0') * 1) : 0);
			iCarryOver = iCurrent / 10;
			sSteamId[i] = (iCurrent % 10) + '0';
		}
		
		sSteamId[iMaxLength - 1] = '\0';
		
		int iPos = FindCharInString(sSteamId, '7');
		
		if (iPos > 0 && Substring(sBuffer, iMaxLength, sSteamId, iMaxLength, iPos, strlen(sSteamId))) {
			return true;
		}
	}
	
	return false;
} 