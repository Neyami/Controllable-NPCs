class CBaseDriveWeapon : ScriptBasePlayerWeaponEntity
{
	int m_iState;

	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	protected EHandle m_hDriveEnt;
	protected CBaseAnimating@ m_pDriveEnt
	{
		get const { return cast<CBaseAnimating@>(m_hDriveEnt.GetEntity()); }
		set { m_hDriveEnt = EHandle(@value); }
	}

	//Prevent weapon from being dropped manually
	CBasePlayerItem@ DropItem() { return null; }

	CBaseEntity@ CheckTraceHullAttack( float flDist, int iDamage, int iDmgType )
	{
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		Vector vecStart = self.pev.origin;
		vecStart.z += self.pev.size.z * 0.5;
		Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( iDamage > 0 )
				pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, iDamage, iDmgType );

			return pEntity;
		}

		return null;
	}

	void SetAnim( int iAnim, float flFrame = 0.0, float flFrameRate = 1.0 )
	{
		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.pev.sequence = iAnim;
			m_pDriveEnt.pev.frame = flFrame;
			m_pDriveEnt.pev.framerate = flFrameRate;

			m_pDriveEnt.ResetSequenceInfo();
		}
	}

	int GetFrame( int iMaxFrames )
	{
		if( m_pDriveEnt is null ) return 0;

		return int( (m_pDriveEnt.pev.frame/255) * iMaxFrames );
	}

	float SetFrame( float flFrame, float flMaxFrames )
	{
		if( m_pDriveEnt is null ) return 0;

		return float( (flFrame / flMaxFrames) * 255 );
	}

	bool IsBetween( float flValue, float flMin, float flMax )
	{
		return (flValue > flMin and flValue < flMax);
	}

	bool IsBetween( int iValue, int iMin, int iMax )
	{
		return (iValue > iMin and iValue < iMax);
	}

	bool IsBetween2( float flValue, float flMin, float flMax )
	{
		return (flValue >= flMin and flValue <= flMax);
	}

	bool IsBetween2( int iValue, int iMin, int iMax )
	{
		return (iValue >= iMin and iValue <= iMax);
	}
}
