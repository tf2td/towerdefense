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
	
	if (strncmp(sUrlPrefixed, "https://", 8) == 0) {
		Updater_DownloadEnded(false, "Socket does not support HTTPs.");
		return;
	}
	
	new Handle:hFile = OpenFile(sDestination, "wb");
	
	if (hFile == INVALID_HANDLE){
		Updater_DownloadEnded(false, "Error writing to file.");
		return;
	}
	
	// Format HTTP GET method
	decl String:sHostname[64];
	decl String:sLocation[128];
	decl String:sFilename[64];
	decl String:sRequest[512];

	ParseURL(sUrlPrefixed, sHostname, sizeof(sHostname), sLocation, sizeof(sLocation), sFilename, sizeof(sFilename));
	Format(sRequest, sizeof(sRequest), "GET %s/%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", sLocation, sFilename, sHostname);

	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack, 0);			// 0 - bParsedHeader
	WritePackCell(hPack, 0);			// 8 - iRedirects
	WritePackCell(hPack, _:hFile);		// 16
	WritePackString(hPack, sRequest);	// 24
	
	new Handle:hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketSetArg(hSocket, hPack);
	SocketSetOption(hSocket, ConcatenateCallbacks, 4096);
	SocketConnect(hSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, sHostname, 80);
}

public OnSocketConnected(Handle:hSocket, any:hPack) {
	decl String:sRequest[512];

	SetPackPosition(hPack, 24);
	ReadPackString(hPack, sRequest, sizeof(sRequest));
	
	SocketSend(hSocket, sRequest);
}

public OnSocketReceive(Handle:hSocket, String:sData[], const iSize, any:hPack) {
	new iIndex = 0;
	
	// Check if the HTTP header has already been parsed.
	SetPackPosition(hPack, 0);
	new bool:bParsedHeader = bool:ReadPackCell(hPack);
	new iRedirects = ReadPackCell(hPack);
	
	if (!bParsedHeader) {
		// Parse header data.
		if ((iIndex = StrContains(sData, "\r\n\r\n")) == -1) {
			iIndex = 0;
		} else {
			if (strncmp(sData, "HTTP/", 5) == 0) {
				// Check for location header.
				new iIndex2 = StrContains(sData, "\nLocation: ", false);
				
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

					decl String:sUrl[256];
					decl String:sUrlPrefixed[256];

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
					
					decl String:sHostname[64], String:sLocation[128], String:sFilename[64], String:sRequest[512];
					ParseURL(sUrlPrefixed, sHostname, sizeof(sHostname), sLocation, sizeof(sLocation), sFilename, sizeof(sFilename));
					Format(sRequest, sizeof(sRequest), "GET %s/%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", sLocation, sFilename, sHostname);

					SetPackPosition(hPack, 24); // sRequest
					WritePackString(hPack, sRequest);
					
					new Handle:hNewSocket = SocketCreate(SOCKET_TCP, OnSocketError);
					SocketSetArg(hNewSocket, hPack);
					SocketSetOption(hNewSocket, ConcatenateCallbacks, 4096);
					SocketConnect(hNewSocket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, sHostname, 80);
					
					CloseHandle(hSocket);
					return;
				}

				// Check HTTP status code
				decl String:sStatusCode[64];
				strcopy(sStatusCode, (FindCharInString(sData, '\r') - 8), sData[9]);
				
				if (strncmp(sStatusCode, "200", 3) != 0) {
					CloseSocketHandles(hSocket, hPack);
				
					decl String:sError[256];
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
	new Handle:hFile = Handle:ReadPackCell(hPack);
	
	while (iIndex < iSize) {
		WriteFileCell(hFile, sData[iIndex++], 1);
	}
}

public OnSocketDisconnected(Handle:hSocket, any:hPack) {
	CloseSocketHandles(hSocket, hPack);
	
	Updater_DownloadEnded(true);
}

public OnSocketError(Handle:hSocket, const iErrorType, const iErrorNum, any:hPack) {
	CloseSocketHandles(hSocket, hPack);

	decl String:sError[256];
	Format(sError, sizeof(sError), "Socket error: %d (Error code %d)", hPack, iErrorNum);
	Updater_DownloadEnded(false, sError);
}

stock CloseSocketHandles(Handle:hSocket, Handle:hPack) {
	SetPackPosition(hPack, 16);
	CloseHandle(Handle:ReadPackCell(hPack)); // hFile
	CloseHandle(hPack);
	CloseHandle(hSocket);
}

stock Updater_DownloadEnded(bool:bSuccessful, const String:sError[] = "") {
	if (bSuccessful) {
		Log(TDLogLevel_Info, "Successfully updated the plugin");

		if (Database_UpdatedServer()) {
			decl String:sFile[PLATFORM_MAX_PATH];
			GetPluginFilename(INVALID_HANDLE, sFile, sizeof(sFile));
			ServerCommand("sm plugins reload %s", sFile);
		}
	} else {
		LogType(TDLogLevel_Error, TDLogType_FileAndConsole, "Failed to update: %s", sError);
	}
}

// Split URL into hostname, location, and filename. No trailing slashes.
stock ParseURL(const String:sUrl[], String:sHost[], iMaxLengthHost, String:sLocation[], iMaxLengthLocation, String:sFilename[], iMaxLengthFilename) {
	// Strip url prefix
	new iIndex = StrContains(sUrl, "://");
	iIndex = (iIndex != -1) ? iIndex + 3 : 0;
	
	decl String:sDirs[16][64];
	new iTotalDirs = ExplodeString(sUrl[iIndex], "/", sDirs, sizeof(sDirs), sizeof(sDirs[]));
	
	// Host
	Format(sHost, iMaxLengthHost, "%s", sDirs[0]);
	
	// Location
	sLocation[0] = '\0';
	for (new i = 1; i < iTotalDirs - 1; i++) {
		Format(sLocation, iMaxLengthLocation, "%s/%s", sLocation, sDirs[i]);
	}
	
	// Filename
	Format(sFilename, iMaxLengthFilename, "%s", sDirs[iTotalDirs - 1]);
}