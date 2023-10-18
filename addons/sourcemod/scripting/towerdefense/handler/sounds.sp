stock void PlaySound(char[] sSoundName, int iClient) {
	if (iClient == 0) {
		if (StrEqual(sSoundName, "Win")) {
			int iRandom = GetRandomInt(1, 2);
			switch (iRandom) {
				case 1: {
					EmitSoundToAll("vo/mvm_mannup_wave_end01.mp3");
				}
				case 2: {
					EmitSoundToAll("vo/mvm_mannup_wave_end02.mp3");
				}
			}
		} else if (StrEqual(sSoundName, "WaveComplete")) {
			int iRandom = GetRandomInt(1, 21);
			switch (iRandom) {
				case 1: {
					EmitSoundToAll("vo/mvm_wave_end01.mp3");
				}
				case 2: {
					EmitSoundToAll("vo/mvm_wave_end02.mp3");
				}
				case 3: {
					EmitSoundToAll("vo/mvm_wave_end03.mp3");
				}
				case 4: {
					EmitSoundToAll("vo/mvm_wave_end04.mp3");
				}
				case 5: {
					EmitSoundToAll("vo/mvm_wave_end05.mp3");
				}
				case 6: {
					EmitSoundToAll("vo/mvm_wave_end06.mp3");
				}
				case 7: {
					EmitSoundToAll("vo/mvm_wave_end07.mp3");
				}
			}
		} else if (StrEqual(sSoundName, "Music")) {
			int iRandom = GetRandomInt(1, 15);
			switch (iRandom) {
				case 1: {
					EmitSoundToAll("music/mvm_start_mid_wave.wav");
				}
				case 2: {
					EmitSoundToAll("music/mvm_start_last_wave.wav");
				}
				case 3: {
					EmitSoundToAll("music/mvm_end_last_wave.wav");
				}
			}
		}
	} else {
		if (StrEqual(sSoundName, "Forbid")) {
			int iRandom = GetRandomInt(1, 3);
			switch (iRandom) {
				case 1: {
					EmitSoundToClient(iClient, "vo/engineer_no01.mp3");
				}
				case 2: {
					EmitSoundToClient(iClient, "vo/engineer_no02.mp3");
				}
				case 3: {
					EmitSoundToClient(iClient, "vo/engineer_no03.mp3");
				}
			}
		}
	}
}