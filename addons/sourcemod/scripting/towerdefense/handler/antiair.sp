// TODO(floube): Fix this :P

public void AntiAir_ProjectileTick(int iProjectile, int iTower) {
	float fLocation[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecOrigin", fLocation);

	if (fLocation[2] >= g_fAirWaveSpawn[2] && fLocation[2] <= g_fAirWaveSpawn[2] + 80.0) {
		float fAngles[3];
		GetEntPropVector(iProjectile, Prop_Data, "m_angRotation", fAngles);
		
		float fVelocity[3];
		GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", fVelocity);

		float fNewVelocity[3];
		fNewVelocity[0] = fVelocity[0];
		fNewVelocity[1] = fVelocity[1];
		fNewVelocity[2] = -fVelocity[2];

		float fNormal[3];
		fNormal[0] = 0.0; 
		fNormal[1] = 0.0; 
		fNormal[2] = -955.0;

		float fBounceVec[3];
		SubtractVectors(fNewVelocity, fNormal, fBounceVec);

		float fNewAngles[3];
		GetVectorAngles(fBounceVec, fNewAngles);

		// TeleportEntity(iProjectile, NULL_VECTOR, fNewAngles, fBounceVec);

		// PrintToServer("Old: %d: [%.2f, %.2f, %.2f]", iProjectile, fVelocity[0], fVelocity[1], fVelocity[2]);
		// PrintToServer("New: %d: [%.2f, %.2f, %.2f]", iProjectile, fBounceVec[0], fBounceVec[1], fBounceVec[2]);

		// PrintToServer("Rotated %d", iProjectile);
	} else {
		Handle hPack = CreateDataPack(); 

		WritePackCell(hPack, iProjectile);
		WritePackCell(hPack, iTower);

		RequestFrame(AntiAir_ProjectileTick2, hPack);
	}
}

public void AntiAir_ProjectileTick2(any iData) {
	ResetPack(iData);
	AntiAir_ProjectileTick(ReadPackCell(iData), ReadPackCell(iData));
	CloseHandle(iData);
}