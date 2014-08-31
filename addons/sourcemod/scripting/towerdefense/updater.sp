#pragma semicolon 1

#include <sourcemod>

stock Updater_Download(const String:sUrl[], const String:sDestination[]) {
	decl String:sUrlPrefixed[256];

	// Prefix url
	if (strncmp(sUrl, "http://", 7) != 0 && strncmp(sUrl, "https://", 8) != 0) {
		Format(sUrlPrefixed, sizeof(sUrlPrefixed), "http://%s", sUrl);
	} else {
		strcopy(sUrlPrefixed, sizeof(sUrlPrefixed), sUrl);
	}

	new Handle:hPack = CreateDataPack();
	WritePackString(hPack, sDestination);

	new HTTPRequestHandle:hRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, sUrlPrefixed);
	Steam_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
	Steam_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");
	Steam_SendHTTPRequest(hRequest, OnSteamHTTPComplete, hPack);
}

public OnSteamHTTPComplete(HTTPRequestHandle:HTTPRequest, bool:bRequestSuccessful, HTTPStatusCode:iStatusCode, any:hPack) {
	ResetPack(hPack);

	decl String:sDestination[PLATFORM_MAX_PATH];
	ReadPackString(hPack, sDestination, sizeof(sDestination));

	if (hPack != INVALID_HANDLE) {
		CloseHandle(hPack);
		hPack = INVALID_HANDLE;
	}
	
	if (bRequestSuccessful && iStatusCode == HTTPStatusCode_OK) {
		Steam_WriteHTTPResponseBody(HTTPRequest, sDestination);
		Updater_DownloadEnded(true);
	} else {
		decl String:sError[256];
		Format(sError, sizeof(sError), "SteamTools error (status code %i). Request successful: %s", _:iStatusCode, bRequestSuccessful ? "true" : "false");
		Updater_DownloadEnded(false, sError);
	}
	
	Steam_ReleaseHTTPRequest(HTTPRequest);
}

stock Updater_DownloadEnded(bool:bSuccessful, const String:sError[] = "") {
	if (bSuccessful) {
		Log(TDLogLevel_Info, "Successfully updated plugin");

		decl String:sFile[PLATFORM_MAX_PATH];
		GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
		ServerCommand("sm plugins reload %s", sFile);
	} else {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to update: %s", sError);
	}
}