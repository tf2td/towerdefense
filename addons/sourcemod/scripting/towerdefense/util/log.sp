#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

enum TDLogLevel
{
	TDLogLevel_None = 0,	// disables all logging
	TDLogLevel_Error = 1,	// is for critical errors, the plugin may no longer work correctly
	TDLogLevel_Warning = 2,	// is for important warnings, the plugin will continue to work correctly
	TDLogLevel_Info = 3,	// is for informative messages, typically used for deployment
	TDLogLevel_Debug = 4,	// is for debug messages, this level is useful during development
	TDLogLevel_Trace = 5	// is for trace messages, this level is usually only needed when debugging a problem
};

enum TDLogType
{
	TDLogType_File = 0,				// logs to SourceMod logs
	TDLogType_Console = 1,			// logs to server console
	TDLogType_FileAndConsole = 2	// logs to SourceMod logs and server console
};

static TDLogLevel m_iLogLevel = TDLogLevel_Info;
static TDLogType m_iLogType = TDLogType_FileAndConsole;

stock void Log_Initialize(TDLogLevel iLogLevel = TDLogLevel_Info, TDLogType iLogType = TDLogType_FileAndConsole) {
	m_iLogLevel = iLogLevel;
	m_iLogType = iLogType;
}

stock void Log(TDLogLevel iLogLevel, const char[] sMessage, any...) {
	if (m_iLogLevel >= iLogLevel) {
		char sFormattedMessage[256];
		VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 3);
		
		switch (m_iLogType) {
			case TDLogType_File: {
				switch (iLogLevel) {
					case TDLogLevel_Error: {
						LogError("[TF2TD > Error] %s", sFormattedMessage);
					}
					case TDLogLevel_Warning: {
						LogError("[TF2TD > Warning] %s", sFormattedMessage);
					}
					case TDLogLevel_Info: {
						LogMessage("[TF2TD > Info] %s", sFormattedMessage);
					}
					case TDLogLevel_Debug: {
						LogMessage("[TF2TD > Debug] %s", sFormattedMessage);
					}
					case TDLogLevel_Trace: {
						LogMessage("[TF2TD > Trace] %s", sFormattedMessage);
					}
				}
			}
			case TDLogType_Console: {
				switch (iLogLevel) {
					case TDLogLevel_Error: {
						PrintToServer("[TF2TD > Error] %s", sFormattedMessage);
					}
					case TDLogLevel_Warning: {
						PrintToServer("[TF2TD > Warning] %s", sFormattedMessage);
					}
					case TDLogLevel_Info: {
						PrintToServer("[TF2TD > Info] %s", sFormattedMessage);
					}
					case TDLogLevel_Debug: {
						PrintToServer("[TF2TD > Debug] %s", sFormattedMessage);
					}
					case TDLogLevel_Trace: {
						PrintToServer("[TF2TD > Trace] %s", sFormattedMessage);
					}
				}
			}
			case TDLogType_FileAndConsole: {
				switch (iLogLevel) {
					case TDLogLevel_Error: {
						LogError("[TF2TD > Error] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Error] %s", sFormattedMessage);
					}
					case TDLogLevel_Warning: {
						LogError("[TF2TD > Warning] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Warning] %s", sFormattedMessage);
					}
					case TDLogLevel_Info: {
						LogMessage("[TF2TD > Info] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Info] %s", sFormattedMessage);
					}
					case TDLogLevel_Debug: {
						LogMessage("[TF2TD > Debug] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Debug] %s", sFormattedMessage);
					}
					case TDLogLevel_Trace: {
						LogMessage("[TF2TD > Trace] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Trace] %s", sFormattedMessage);
					}
				}
			}
		}
	}
}

stock void LogType(TDLogLevel iLogLevel, TDLogType iLogType, const char[] sMessage, any...) {
	if (m_iLogLevel >= iLogLevel) {
		char sFormattedMessage[256];
		VFormat(sFormattedMessage, sizeof(sFormattedMessage), sMessage, 4);
		
		switch (iLogType) {
			case TDLogType_File: {
				switch (iLogLevel) {
					case TDLogLevel_Error: {
						LogError("[TF2TD > Error] %s", sFormattedMessage);
					}
					case TDLogLevel_Warning: {
						LogError("[TF2TD > Warning] %s", sFormattedMessage);
					}
					case TDLogLevel_Info: {
						LogMessage("[TF2TD > Info] %s", sFormattedMessage);
					}
					case TDLogLevel_Debug: {
						LogMessage("[TF2TD > Debug] %s", sFormattedMessage);
					}
					case TDLogLevel_Trace: {
						LogMessage("[TF2TD > Trace] %s", sFormattedMessage);
					}
				}
			}
			case TDLogType_Console: {
				switch (iLogLevel) {
					case TDLogLevel_Error: {
						PrintToServer("[TF2TD > Error] %s", sFormattedMessage);
					}
					case TDLogLevel_Warning: {
						PrintToServer("[TF2TD > Warning] %s", sFormattedMessage);
					}
					case TDLogLevel_Info: {
						PrintToServer("[TF2TD > Info] %s", sFormattedMessage);
					}
					case TDLogLevel_Debug: {
						PrintToServer("[TF2TD > Debug] %s", sFormattedMessage);
					}
					case TDLogLevel_Trace: {
						PrintToServer("[TF2TD > Trace] %s", sFormattedMessage);
					}
				}
			}
			case TDLogType_FileAndConsole: {
				switch (iLogLevel) {
					case TDLogLevel_Error: {
						LogError("[TF2TD > Error] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Error] %s", sFormattedMessage);
					}
					case TDLogLevel_Warning: {
						LogError("[TF2TD > Warning] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Warning] %s", sFormattedMessage);
					}
					case TDLogLevel_Info: {
						LogMessage("[TF2TD > Info] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Info] %s", sFormattedMessage);
					}
					case TDLogLevel_Debug: {
						LogMessage("[TF2TD > Debug] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Debug] %s", sFormattedMessage);
					}
					case TDLogLevel_Trace: {
						LogMessage("[TF2TD > Trace] %s", sFormattedMessage);
						PrintToServer("[TF2TD > Trace] %s", sFormattedMessage);
					}
				}
			}
		}
	}
} 