

public void AntiAir_ProjectileTick(int iProjectile, int iTower) {
	if (IsValidEntity(iProjectile)) {
		float fLocation[3];
		GetEntPropVector(iProjectile, Prop_Data, "m_vecOrigin", fLocation);
		char sEntityName[50];
		GetEntPropString(iProjectile, Prop_Data, "m_iName", sEntityName, sizeof(sEntityName));

		if (fLocation[2] >= g_fAirWaveSpawn[2] && fLocation[2] <= g_fAirWaveSpawn[2] + 95.0) {
			float fAngles[3];
			GetEntPropVector(iProjectile, Prop_Data, "m_angRotation", fAngles);

			float fVelocity[3];
			GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", fVelocity);

			float fNewVelocity[3];
			fNewVelocity[0] = fVelocity[0];
			fNewVelocity[1] = fVelocity[1];
			fNewVelocity[2] = -fVelocity[2];

			float fBounceVec[3];
			SubtractVectors(fNewVelocity, NULL_VECTOR, fBounceVec);
			fBounceVec[2] = 0.0;

			float fNewAngles[3];
			GetVectorAngles(fBounceVec, fNewAngles);

			TeleportEntity(iProjectile, NULL_VECTOR, fNewAngles, fBounceVec);
		} else {
			DataPack hPack = new DataPack();

			hPack.WriteCell(iProjectile);
			hPack.WriteCell(iTower);

			RequestFrame(AntiAir_ProjectileTick2, hPack);
		}
	}
}

public void AntiAir_ProjectileTick2(DataPack iData) {
	iData.Reset();
	AntiAir_ProjectileTick(iData.ReadCell(), iData.ReadCell());
	delete iData;
}