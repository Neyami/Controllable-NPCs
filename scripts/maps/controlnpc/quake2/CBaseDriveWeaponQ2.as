class CBaseDriveWeaponQ2 : ScriptBasePlayerWeaponEntity
{
	int STATE_IDLE = 0;

	int m_iState;
	int m_iAutoDeploy;
	float m_flNextIdleCheck;
	protected uint m_uiAnimationState; //for hacky HandleAnimEvent
	protected float m_flNextThink; //for stuff that shouldn't run every frame
	float m_flCustomHealth;
	int m_iSpawnFlags; //Just in case
	protected int m_iMaxAmmo;
	protected float m_flFireRate;

	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	protected EHandle m_hDriveEnt;
	CBaseAnimating@ m_pDriveEnt
	{
		get const { return cast<CBaseAnimating@>(m_hDriveEnt.GetEntity()); }
		set { m_hDriveEnt = EHandle(@value); }
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "autodeploy" )
		{
			m_iAutoDeploy = atoi( szValue );
			return true;
		}
		else if( szKey == "m_flCustomHealth" )
		{
			m_flCustomHealth = atof( szValue );
			return true;
		}
		else if( szKey == "m_iSpawnFlags" )
		{
			m_iSpawnFlags = atoi( szValue );
			return true;
		}
		else if( szKey == "m_iMaxAmmo" )
		{
			m_iMaxAmmo = atoi( szValue );
			return true;
		}
		else if( szKey == "m_flFireRate" )
		{
			m_flFireRate = atof( szValue );
			return true;
		}
		else if( CustomKeyValue(szKey, szValue) )
			return true;
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	bool CustomKeyValue( const string& in szKey, const string& in szValue ) { return false; }

	void DoIdleSound()
	{
		if( !GetSpawnflags(CNPC::FL_GAG) and GetState(STATE_IDLE) and g_Engine.time > m_flNextIdleCheck )
		{
			if( m_flNextIdleCheck > 0.0 )
			{
				IdleSound();
				m_flNextIdleCheck = g_Engine.time + 15 + Math.RandomFloat(0, 1) * 15;
			}
			else
				m_flNextIdleCheck = g_Engine.time + Math.RandomFloat(0, 1) * 15;
		}
	}

	void IdleSound() {}

	//Prevent weapon from being dropped manually
	CBasePlayerItem@ DropItem() { return null; }

	CBaseEntity@ CheckTraceHullAttack( float flDist, int iDamage, int iDmgType, bool bUseViewAngles = true )
	{
		TraceResult tr;

		if( bUseViewAngles )
			Math.MakeVectors( m_pPlayer.pev.v_angle );
		else
			Math.MakeVectors( m_pDriveEnt.pev.angles );
			//Math.MakeVectors( m_pPlayer.pev.angles );

		Vector vecStart = m_pDriveEnt.pev.origin;
		vecStart.z += m_pDriveEnt.pev.size.z * 0.5;
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

	CBaseEntity@ CheckTraceHullHeal( float flDist, int iDamage, int iDmgType )
	{
		TraceResult tr;

		Math.MakeVectors( m_pDriveEnt.pev.angles );

		Vector vecStart = m_pDriveEnt.pev.origin;
		vecStart.z += m_pDriveEnt.pev.size.z * 0.5;
		Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( pEntity.pev.FlagBitSet(FL_CLIENT|FL_MONSTER) )
			{
				if( m_pPlayer.IRelationship(pEntity) == R_AL and pEntity.IsAlive() and pEntity.edict() !is m_pPlayer.edict() )
				{
					if( pEntity.pev.health >= pEntity.pev.max_health ) return null;

					pEntity.TakeHealth( iDamage, iDmgType ); //DMG_GENERIC

					return pEntity;
				}
			}
		}

		return null;
	}

	void monster_fire_blaster( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "cnpcq2laser", vecStart, vecDir, false, m_pPlayer.edict() ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );
	}

	void monster_fire_rocket( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pRocket = g_EntityFuncs.Create( "cnpcq2rocket", vecStart, vecDir, false, m_pPlayer.edict() ); 
		pRocket.pev.velocity = vecDir * flSpeed;
		pRocket.pev.dmg = flDamage;
		pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );
	}

	void monster_fire_railgun( Vector vecStart, Vector vecDir, float flDamage )
	{
		TraceResult tr;

		Vector vecEnd = vecStart + vecDir * 8192;
		Vector railstart = vecStart;

		edict_t@ ignore = m_pPlayer.edict();

		while( ignore !is null )
		{
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore, tr );

			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit.IsMonster() or pHit.IsPlayer() or tr.pHit.vars.solid == SOLID_BBOX or (tr.pHit.vars.ClassNameIs( "func_breakable" ) and tr.pHit.vars.takedamage != DAMAGE_NO) )
				@ignore = tr.pHit;
			else
				@ignore = null;

			g_WeaponFuncs.ClearMultiDamage();

			if( tr.pHit !is self.edict() and pHit.pev.takedamage != DAMAGE_NO )
				pHit.TraceAttack( self.pev, flDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 

			g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );

			vecStart = tr.vecEndPos;
		}

		CreateRailbeam( railstart, tr.vecEndPos );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null or pHit.IsBSPModel() == true )
			{
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SNIPER );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );

				int r = 155, g = 255, b = 255;

				NetworkMessage railimpact( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
					railimpact.WriteByte( TE_DLIGHT );
					railimpact.WriteCoord( tr.vecEndPos.x );
					railimpact.WriteCoord( tr.vecEndPos.y );
					railimpact.WriteCoord( tr.vecEndPos.z );
					railimpact.WriteByte( 8 );//radius
					railimpact.WriteByte( int(r) );
					railimpact.WriteByte( int(g) );
					railimpact.WriteByte( int(b) );
					railimpact.WriteByte( 48 );//life
					railimpact.WriteByte( 12 );//decay
				railimpact.End();
			}
		}
	}

	void CreateRailbeam( Vector vecStart, Vector vecEnd )
	{
		CBaseEntity@ cbeBeam = g_EntityFuncs.CreateEntity( "cnpcq2railbeam", null, false );
		CNPC::Q2::cnpcq2railbeam@ pBeam = cast<CNPC::Q2::cnpcq2railbeam@>(CastToScriptClass(cbeBeam));
		pBeam.m_vecStart = vecStart;
		pBeam.m_vecEnd = vecEnd;
		g_EntityFuncs.SetOrigin( pBeam.self, vecStart );
		g_EntityFuncs.DispatchSpawn( pBeam.self.edict() );
	}

	bool GetSpawnflags( int iSpawnflags )
	{
		return (m_iSpawnFlags & iSpawnflags) != 0;
	}

	void SetSpeed( int iSpeed )
	{
		m_pPlayer.SetMaxSpeedOverride( iSpeed );
	}

	void SetState( int iState )
	{
		m_iState = iState;
	}

	int GetState()
	{
		return m_iState;
	}

	bool GetState( int iState )
	{
		return m_iState == iState;
	}

	void SetAnim( int iAnim, float flFrameRate = 1.0, float flFrame = 0.0 )
	{
		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.pev.sequence = iAnim;
			m_pDriveEnt.ResetSequenceInfo();
			m_pDriveEnt.pev.frame = flFrame;
			m_pDriveEnt.pev.framerate = flFrameRate;
			m_uiAnimationState = 0;
		}
	}

	int GetAnim()
	{
		return m_pDriveEnt.pev.sequence;
	}

	bool GetAnim( int iAnim )
	{
		if( m_pDriveEnt !is null )
			return m_pDriveEnt.pev.sequence == iAnim;

		return false;
	}

	int GetFrame( int iMaxFrames )
	{
		if( m_pDriveEnt is null ) return 0;

		return int( (m_pDriveEnt.pev.frame/255) * iMaxFrames );
	}

	bool GetFrame( int iMaxFrames, int iTargetFrame )
	{
		if( m_pDriveEnt is null ) return false;

		int iFrame = int( (m_pDriveEnt.pev.frame/255) * iMaxFrames );
		if( IsBetween2(iFrame, Math.clamp(0, iMaxFrames, iTargetFrame-1), iTargetFrame+1) ) return true;
 
		return false;
	}

	float SetFrame( float flFrame, float flMaxFrames )
	{
		if( m_pDriveEnt is null ) return 0;

		return float( (flFrame / flMaxFrames) * 255 );
	}

	void SetYaw( float flYaw )
	{
		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.pev.angles.y = flYaw;
		}
	}

	bool GetButton( int iButtons )
	{
		return (m_pPlayer.pev.button & iButtons) != 0;
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

abstract class CBaseDriveEntityQ2 : ScriptBaseAnimating
{
	int m_iSpawnFlags;
	float m_flCustomHealth;

	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_iSpawnFlags" )
		{
			m_iSpawnFlags = atoi( szValue );
			return true;
		}
		else if( szKey == "m_flCustomHealth" )
		{
			m_flCustomHealth = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	//More true to the original ??
	void ThrowGib( int iCount, const string &in sGibName, float flDamage, int iType = 0, bool bHead = false )
	{
		Vector vecOrigin = pev.origin;

		CGib@ pGib = g_EntityFuncs.CreateGib( pev.origin, g_vecZero );
		pGib.Spawn( sGibName );

		if( bHead )
		{
			pGib.pev.origin.x = pev.origin.x;
			pGib.pev.origin.y = pev.origin.y;
			pGib.pev.origin.z = pev.origin.z + pev.size.z;
		}
		else
		{
			pGib.pev.origin.x = pev.absmin.x + pev.size.x * (Math.RandomFloat(0 , 1));
			pGib.pev.origin.y = pev.absmin.y + pev.size.y * (Math.RandomFloat(0 , 1));
			pGib.pev.origin.z = pev.absmin.z + pev.size.z * (Math.RandomFloat(0 , 1)) + 1;
		}

		pGib.pev.velocity = VelocityForDamage( flDamage );

		pGib.pev.velocity.x += Math.RandomFloat( -0.15, 0.15 );
		pGib.pev.velocity.y += Math.RandomFloat( -0.25, 0.15 );
		pGib.pev.velocity.z += Math.RandomFloat( -0.2, 1.9 );

		pGib.pev.avelocity.x = Math.RandomFloat( 70, 200 );
		pGib.pev.avelocity.y = Math.RandomFloat( 70, 200 );

		pGib.pev.solid = SOLID_NOT;
		g_EntityFuncs.SetSize( pGib.pev, g_vecZero, g_vecZero );

		pGib.LimitVelocity();

		if( iType == BREAK_FLESH )
		{
			pGib.m_bloodColor = BLOOD_COLOR_RED;
			pGib.m_cBloodDecals = 5;
			pGib.m_material = matFlesh;
			g_WeaponFuncs.SpawnBlood( pGib.pev.origin, BLOOD_COLOR_RED, 400 );
		}
		else
			pGib.m_bloodColor = DONT_BLEED;
	}

	/*void ThrowGib( int iCount, const string &in sGibName, float flDamage, int iType, bool bHead = false )
	{
		Vector vecOrigin = pev.origin;
		Vector vecVelocity = VelocityForDamage( flDamage );

		if( bHead)
			vecOrigin.z += pev.size.z;
		else
			vecOrigin.z += pev.size.z * 0.5;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BREAKMODEL );
			m1.WriteCoord( vecOrigin.x ); //position x y z
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteCoord( 1 ); //size x y z
			m1.WriteCoord( 1 );
			m1.WriteCoord( 1 );
			m1.WriteCoord( vecVelocity.x ); //velocity x y z
			m1.WriteCoord( vecVelocity.y );
			m1.WriteCoord( vecVelocity.z );
			m1.WriteByte( 3 ); //random velocity in 10's
			m1.WriteShort( g_EngineFuncs.ModelIndex(sGibName) );
			m1.WriteByte( iCount ); //count
			m1.WriteByte( Math.RandomLong(100, 200) ); //life in 0.1 secs
			m1.WriteByte( iType ); //flags
		m1.End();

		if( iType == BREAK_FLESH )
			g_WeaponFuncs.SpawnBlood( vecOrigin, BLOOD_COLOR_RED, 400 );
	}*/

	Vector VelocityForDamage( float flDamage )
	{
		Vector vec( Math.RandomFloat(-100, 100), Math.RandomFloat(-100, 100), Math.RandomFloat(200, 300) );

		if( flDamage > 50 )
			vec = vec * 0.7;
		else if( flDamage > 200 )
			vec = vec * 2;
		else
			vec = vec * 10;

		return vec;
	}

	bool GetFrame( int iMaxFrames, int iTargetFrame )
	{
		int iFrame = int( (pev.frame/255) * iMaxFrames );
		if( IsBetween2(iFrame, Math.clamp(0, iMaxFrames, iTargetFrame-1), iTargetFrame+1) ) return true;
 
		return false;
	}

	bool IsBetween2( float flValue, float flMin, float flMax )
	{
		return (flValue >= flMin and flValue <= flMax);
	}
}

/* TODO
*/