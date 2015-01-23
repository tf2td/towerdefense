#pragma semicolon 1

#include <sourcemod>

/**
 * Gets a clients steam community id.
 *
 * @param iClient		The client.
 * @param sBuffer		The destination string buffer.
 * @param iMaxLength	The maximum length of the output string buffer.
 * @return				True on success, false otherwise.
 */

stock bool:GetClientCommunityId(iClient, String:sBuffer[], iMaxLength) {
	if (!IsClientConnected(iClient) || IsFakeClient(iClient)) {
		return false;
	}

	new iSteamAccountId = GetSteamAccountID(iClient);

	if (iSteamAccountId > 0) {
		decl String:sSteamAccountId[32];
		decl String:sBase[] = "76561197960265728";
		decl String:sSteamId[iMaxLength];
		
		IntToString((iSteamAccountId - iSteamAccountId % 2) / 2, sSteamAccountId, sizeof(sSteamAccountId));
		
		new iCurrent, iCarryOver = iSteamAccountId % 2;
		for (new i = (iMaxLength - 2), j = (strlen(sSteamAccountId) - 1), k = (strlen(sBase) - 1); i >= 0; i--, j--, k--) {
			iCurrent = (j >= 0 ? (2 * (sSteamAccountId[j] - '0')) : 0) + iCarryOver + (k >= 0 ? ((sBase[k] - '0') * 1) : 0);
			iCarryOver = iCurrent / 10;
			sSteamId[i] = (iCurrent % 10) + '0';
		}

		sSteamId[iMaxLength - 1] = '\0';

		new iPos = FindCharInString(sSteamId, '7');

		if (iPos > 0 && Substring(sBuffer, iMaxLength, sSteamId, iMaxLength, iPos, strlen(sSteamId))) {
			return true;
		}
	}

	return false;
}