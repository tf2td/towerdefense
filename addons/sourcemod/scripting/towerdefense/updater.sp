#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "info/constants.sp"
	#include "info/enums.sp"
	#include "info/variables.sp"
#endif

stock void Updater_Download(const char[] sUrl, const char[] sDestination) {
	char sUrlPrefixed[256];

	// Prefix url
	if (strncmp(sUrl, "http://", 7) != 0 && strncmp(sUrl, "https://", 8) != 0) {
		Format(sUrlPrefixed, sizeof(sUrlPrefixed), "http://%s", sUrl);
	} else {
		strcopy(sUrlPrefixed, sizeof(sUrlPrefixed), sUrl);
	}
	
	if (strncmp(sUrlPrefixed, "https://", 8) == 0) {
		Updater_DownloadEnded(false, "Socket does not support HTTPs.");
		return;
	}
	
	Handle hFile = OpenFile(sDestination, "wb");
	
	if (hFile == INVALID_HANDLE){
		Updater_DownloadEnded(false, "Error writing to file.");
		return;
	}
	
	// Format HTTP GET method
	char sHostname[64];
	char sLocation[128];
	char sFilename[64];
	char sRequest[512];

	ParseURL(sUrlPrefixed, sHostname, sizeof(sHostname), sLocation, sizeof(sLocation), sFilename, sizeof(sFilename));
	Format(sRequest, sizeof(sRequest), "GET %s/%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", sLocation, sFilename, sHostname);

	Handle hPack = CreateDataPack();
	WritePackCell(hPack, 0);						// 0 - bParsedHeader
	WritePackCell(hPack, 0);						// 8 - iRedirects
	WritePackCell(hPack, view_as<int>(hFile));		// 16
	WritePackString(hPack, sRequest);				// 24
	
	Handle hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(hSocket, hPack);
	SocketSetOption(hSocket, ConcatenateCallbacks, 4096);
	SocketConnect(hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, sHostname, 80);
}

public void OnSocketConnected(Handle hSocket, any hPack) {
	char sRequest[512];

	SetPackPosition(hPack, 24);
	ReadPackString(hPack, sRequest, sizeof(sRequest));
	
	SocketSend(hSocket, sRequest);
}

public void OnSocketReceive(Handle hSocket, char[] sData, const int iSize, any hPack) {
	int iIndex = 0;
	
	// Check if the HTTP header has already been parsed.
	SetPackPosition(hPack, 0);
	bool bParsedHeader = view_as<bool>(ReadPackCell(hPack));
	int iRedirects = ReadPackCell(hPack);
	
	if (!bParsedHeader) {
		// Parse header data.
		if ((iIndex = StrContains(sData, "\r\n\r\n")) == -1) {
			iIndex = 0;
		} else {
			if (strncmp(sData, "HTTP/", 5) == 0) {
				// Check for location header.
				int iIndex2 = StrContains(sData, "\nLocation: ", false);
				
				if (iIndex2 > -1 && iIndex2 < iIndex) {
					if (++iRedirects > 5) {
						CloseSocketHandles(hSocket, hPack);
						Updater_DownloadEnded(false, "Socket error: Too many redirects.");
						return;
					} else {
						SetPackPosition(hPack, 8);
						WritePackCell(hPack, iRedirects);
					}
				
					// Skip to url
					iIndex2 += 11;

					char sUrl[256];
					char sUrlPrefixed[256];

					strcopy(sUrl, (FindCharInString(sData[iIndex2], '\r') + 1), sData[iIndex2]);

					// Prefix url
					if (strncmp(sUrl, "http://", 7) != 0 && strncmp(sUrl, "https://", 8) != 0) {
						Format(sUrlPrefixed, sizeof(sUrlPrefixed), "http://%s", sUrl);
					} else {
						strcopy(sUrlPrefixed, sizeof(sUrlPrefixed), sUrl);
					}

					if (strncmp(sUrlPrefixed, "https://", 8) == 0) {
						CloseSocketHandles(hSocket, hPack);
						Updater_DownloadEnded(false, "Socket does not support HTTPs.");
						return;
					}
					
					char sHostname[64], sLocation[128], sFilename[64], sRequest[512];
					ParseURL(sUrlPrefixed, sHostname, sizeof(sHostname), sLocation, sizeof(sLocation), sFilename, sizeof(sFilename));
					Format(sRequest, sizeof(sRequest), "GET %s/%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", sLocation, sFilename, sHostname);

					SetPackPosition(hPack, 24); // sRequest
					WritePackString(hPack, sRequest);
					
					Handle hNewSocket = SocketCreate(SOCKET_TCP, OnSocketError);
					SocketSetArg(hNewSocket, hPack);
					SocketSetOption(hNewSocket, ConcatenateCallbacks, 4096);
					SocketConnect(hNewSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, sHostname, 80);
					
					CloseHandle(hSocket);
					return;
				}

				// Check HTTP status code
				char sStatusCode[64];
				strcopy(sStatusCode, (FindCharInString(sData, '\r') - 8), sData[9]);
				
				if (strncmp(sStatusCode, "200", 3) != 0) {
					CloseSocketHandles(hSocket, hPack);
				
					char sError[256];
					Format(sError, sizeof(sError), "Socket error: %s", sStatusCode);
					Updater_DownloadEnded(false, sError);
					return;
				}
			}
			
			iIndex += 4;
		}
		
		SetPackPosition(hPack, 0);
		WritePackCell(hPack, 1); // bParsedHeader
	}
	
	// Write data to file.
	SetPackPosition(hPack, 16);
	Handle hFile = view_as<Handle>(ReadPackCell(hPack));
	
	while (iIndex < iSize) {
		WriteFileCell(hFile, sData[iIndex++], 1);
	}
}

public void OnSocketDisconnected(Handle hSocket, any hPack) {
	CloseSocketHandles(hSocket, hPack);
	
	Updater_DownloadEnded(true);
}

public void OnSocketError(Handle hSocket, const int iErrorType, const int iErrorNum, any hPack) {
	CloseSocketHandles(hSocket, hPack);

	char sError[256];
	Format(sError, sizeof(sError), "Socket error: %d (Error code %d)", hPack, iErrorNum);
	Updater_DownloadEnded(false, sError);
}

stock void CloseSocketHandles(Handle hSocket, Handle hPack) {
	SetPackPosition(hPack, 16);
	CloseHandle(view_as<Handle>(ReadPackCell(hPack))); // hFile
	CloseHandle(hPack);
	CloseHandle(hSocket);
}

stock void Updater_DownloadEnded(bool bSuccessful, const char sError[] = "") {
	if (bSuccessful) {
		Log(TDLogLevel_Info, "Successfully updated the plugin");

		if (Database_UpdatedServer()) {
			char sFile[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
			ServerCommand("sm plugins reload %s", sFile);
		}
	} else {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to update: %s", sError);
	}
}

// Split URL into hostname, location, and filename. No trailing slashes.
stock void ParseURL(const char[] sUrl, char[] sHost, int iMaxLengthHost, char[] sLocation, int iMaxLengthLocation, char[] sFilename, int iMaxLengthFilename) {
	// Strip url prefix
	int iIndex = StrContains(sUrl, "://");
	iIndex = (iIndex != -1) ? iIndex + 3 : 0;
	
	char sDirs[16][64];
	int iTotalDirs = ExplodeString(sUrl[iIndex], "/", sDirs, sizeof(sDirs), sizeof(sDirs[]));
	
	// Host
	Format(sHost, iMaxLengthHost, "%s", sDirs[0]);
	
	// Location
	sLocation[0] = '\0';
	for (int i = 1; i < iTotalDirs - 1; i++) {
		Format(sLocation, iMaxLengthLocation, "%s/%s", sLocation, sDirs[i]);
	}
	
	// Filename
	Format(sFilename, iMaxLengthFilename, "%s", sDirs[iTotalDirs - 1]);
}