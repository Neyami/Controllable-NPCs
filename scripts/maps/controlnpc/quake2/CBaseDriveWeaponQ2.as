class CBaseDriveWeaponQ2 : ScriptBasePlayerWeaponEntity
{
	int STATE_IDLE = 0;
	int STATE_MOVING = 1;

	int m_iState;
	int m_iAutoDeploy;
	float m_flNextIdleCheck;
	protected uint m_uiAnimationState; //for hacky HandleAnimEvent
	protected float m_flNextThink; //for stuff that shouldn't run every frame
	float m_flCustomHealth;
	int m_iSpawnFlags; //Just in case
	protected int m_iMaxAmmo;
	protected float m_flFireRate;
	int m_iStepLeft; //for alternating right and left footsteps

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

	void DoSearchSound()
	{
		if( !GetSpawnflags(CNPC::FL_GAG) and GetState(STATE_MOVING) and g_Engine.time > m_flNextIdleCheck )
		{
			if( m_flNextIdleCheck > 0.0 )
			{
				SearchSound();
				m_flNextIdleCheck = g_Engine.time + 15 + Math.RandomFloat(0, 1) * 15;
			}
			else
				m_flNextIdleCheck = g_Engine.time + Math.RandomFloat(0, 1) * 15;
		}
	}

	void SearchSound() {}

	void Footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		CNPC::monster_footstep( EHandle(m_pDriveEnt), EHandle(m_pPlayer), m_iStepLeft, iPitch, bSetOrigin, vecSetOrigin );
	}

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

	void MachineGunEffects( Vector vecOrigin, int iScale = 5 )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_SMOKE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z - 10.0 );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/steam1.spr") );
			m1.WriteByte( iScale ); // scale * 10
			m1.WriteByte( 105 ); // framerate
		m1.End();

		NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_DLIGHT );
			m2.WriteCoord( vecOrigin.x );
			m2.WriteCoord( vecOrigin.y );
			m2.WriteCoord( vecOrigin.z );
			m2.WriteByte( 16 ); //radius
			m2.WriteByte( 240 ); //rgb
			m2.WriteByte( 180 );
			m2.WriteByte( 0 );
			m2.WriteByte( 8 ); //lifetime
			m2.WriteByte( 50 ); //decay
		m2.End();
	}

	void monster_muzzleflash( Vector vecOrigin, int iRadius, int iR, int iG, int iB )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteByte( iRadius + Math.RandomLong(0, 6) ); //radius
			m1.WriteByte( iR ); //rgb
			m1.WriteByte( iG );
			m1.WriteByte( iB );
			m1.WriteByte( 10 ); //lifetime
			m1.WriteByte( 35 ); //decay
		m1.End();
	}

	void monster_fire_bullet( Vector vecStart, Vector vecDir, float flDamage, Vector vecSpread )
	{
		self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );
	}

	void monster_fire_shotgun( Vector vecStart, Vector vecDir, float flDamage, Vector vecSpread, int iCount )
	{
		for( int i = 0; i < iCount; i++ )
			self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );

		//too loud
		//self.FireBullets( iCount, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );
	}

	void monster_fire_blaster( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "cnpcq2laser", vecStart, vecDir, false, m_pPlayer.edict() ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );
	}

	void monster_fire_rocket( Vector vecStart, Vector vecDir, float flDamage, int flSpeed, float flScale = 1.0 )
	{
		CBaseEntity@ pRocket = g_EntityFuncs.Create( "cnpcq2rocket", vecStart, vecDir, false, m_pPlayer.edict() );
		pRocket.pev.velocity = vecDir * flSpeed;
		pRocket.pev.dmg = flDamage;
		pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );
		pRocket.pev.scale = flScale;
	}

	/*void monster_fire_grenade( Vector vecStart, Vector vecDir, float flDamage, int flSpeed, float flScale = 1.0 )
	{
		CBaseEntity@ pGrenade = g_EntityFuncs.Create( "cnpcq2grenade", vecStart, vecDir, false, m_pPlayer.edict() );
		pGrenade.pev.velocity = vecDir * flSpeed;
		pGrenade.pev.dmg = flDamage;
		pGrenade.pev.scale = flScale;
	}*/

	void monster_fire_grenade( Vector vecStart, Vector vecVelocity, float flDamage, float flScale = 1.0 )
	{
		CBaseEntity@ pGrenade = g_EntityFuncs.Create( "cnpcq2grenade", vecStart, g_vecZero, false, m_pPlayer.edict() );
		pGrenade.pev.velocity = vecVelocity;
		pGrenade.pev.dmg = flDamage;
		pGrenade.pev.scale = flScale;
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

//void monster_fire_bfg( int damage, int speed, int kick, float damage_radius, int flashtype )
//monster_fire_bfg( 50, 300, 100, 300, MZ2_MAKRON_BFG );
	void monster_fire_bfg( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pBFG = g_EntityFuncs.Create( "cnpcq2bfg", vecStart, vecDir, false, m_pPlayer.edict() );
		pBFG.pev.velocity = vecDir * flSpeed;
		pBFG.pev.dmg = flDamage;
	}

	void WalkMove( float flDist )
	{
		g_EngineFuncs.WalkMove( self.edict(), pev.angles.y, flDist, WALKMOVE_WORLDONLY );
	}

	//from h_ai.cpp
	Vector VecCheckThrow( const Vector& in vecSpot1, Vector vecSpot2, float flSpeed, float flGravityAdj )
	{
		float flGravity = g_EngineFuncs.CVarGetFloat("sv_gravity") * flGravityAdj;

		Vector vecGrenadeVel = (vecSpot2 - vecSpot1);

		float time = vecGrenadeVel.Length() / flSpeed;
		vecGrenadeVel = vecGrenadeVel * (1.0 / time);

		vecGrenadeVel.z += flGravity * time * 0.5;

		Vector vecApex = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
		vecApex.z += 0.5 * flGravity * (time * 0.5) * (time * 0.5);

		/*TraceResult tr;
		g_Utility.TraceLine( vecSpot1, vecApex, dont_ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction != 1.0 )
			return g_vecZero;

		g_Utility.TraceLine( vecSpot2, vecApex, ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction != 1.0 )
			return g_vecZero;*/

		return vecGrenadeVel;
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

	void SetAnim( int iAnim, float flFramerate = 1.0, float flFrame = 0.0 )
	{
		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.pev.sequence = iAnim;
			m_pDriveEnt.ResetSequenceInfo();
			m_pDriveEnt.pev.frame = flFrame;
			m_pDriveEnt.pev.framerate = flFramerate;
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

	float SetFrame( float flMaxFrames, float flFrame )
	{
		if( m_pDriveEnt is null ) return 0;

		return float( (flFrame / flMaxFrames) * 255 );
	}

	void SetFramerate( float flFramerate)
	{
		m_pDriveEnt.pev.framerate = flFramerate;
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

	bool GetPressed( int iButton )
	{
		return(m_pPlayer.m_afButtonPressed & iButton) != 0;
	}

	bool GetPushedDown( int iButton )
	{
		return (m_pPlayer.pev.button & iButton) != 0 and (m_pPlayer.pev.oldbuttons & iButton) == 0;
	}

	bool GetReleased( int iButton )
	{
		return (m_pPlayer.pev.oldbuttons & iButton) != 0 and (m_pPlayer.pev.button & iButton) == 0;
	}

	int GetAmmo( uint uiAmmoType )
	{
		if( uiAmmoType == 2 )
			return m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType );

		return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
	}

	void SetAmmo( uint uiAmmoType, int iAmount )
	{
		if( uiAmmoType == 2 )
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, iAmount );
		else
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmount );
	}

	void IncreaseAmmo( uint uiAmmoType, int iAmount )
	{
		SetAmmo( uiAmmoType, GetAmmo(uiAmmoType) + iAmount );
	}

	void ReduceAmmo( uint uiAmmoType, int iAmount )
	{
		SetAmmo( uiAmmoType, GetAmmo(uiAmmoType) - iAmount );
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
	uint m_uiAnimationState;
	int m_iStepLeft;

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

	void MachineGunEffects( Vector vecOrigin, int iScale = 5 )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_SMOKE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z - 10.0 );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/steam1.spr") );
			m1.WriteByte( iScale ); // scale * 10
			m1.WriteByte( 105 ); // framerate
		m1.End();

		NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_DLIGHT );
			m2.WriteCoord( vecOrigin.x );
			m2.WriteCoord( vecOrigin.y );
			m2.WriteCoord( vecOrigin.z );
			m2.WriteByte( 16 ); //radius
			m2.WriteByte( 240 ); //rgb
			m2.WriteByte( 180 );
			m2.WriteByte( 0 );
			m2.WriteByte( 8 ); //lifetime
			m2.WriteByte( 50 ); //decay
		m2.End();
	}

	void monster_muzzleflash( Vector vecOrigin, int iRadius, int iR, int iG, int iB )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteByte( iRadius + Math.RandomLong(0, 6) ); //radius
			m1.WriteByte( iR ); //rgb
			m1.WriteByte( iG );
			m1.WriteByte( iB );
			m1.WriteByte( 10 ); //lifetime
			m1.WriteByte( 35 ); //decay
		m1.End();
	}

	void monster_fire_bullet( Vector vecStart, Vector vecDir, float flDamage, Vector vecSpread )
	{
		self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage) );
	}

	void monster_fire_shotgun( Vector vecStart, Vector vecDir, float flDamage, Vector vecSpread, int iCount )
	{
		for( int i = 0; i < iCount; i++ )
			self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage) );

		//too loud
		//self.FireBullets( iCount, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );
	}

	void monster_fire_blaster( Vector vecStart, Vector vecDir, float flDamage, int flSpeed )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "cnpcq2laser", vecStart, vecDir, false ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );
	}

	void WalkMove( float flDist )
	{
		g_EngineFuncs.WalkMove( self.edict(), pev.angles.y, flDist, WALKMOVE_WORLDONLY );
	}

	void SetAnim( int iAnim, float flFramerate = 1.0, float flFrame = 0.0 )
	{
			pev.sequence = iAnim;
			self.ResetSequenceInfo();
			pev.frame = flFrame;
			pev.framerate = flFramerate;
			m_uiAnimationState = 0;
	}

	int GetAnim()
	{
		return pev.sequence;
	}

	bool GetAnim( int iAnim )
	{
		return pev.sequence == iAnim;
	}

	int GetFrame( int iMaxFrames )
	{
		return int( (pev.frame/255) * iMaxFrames );
	}

	bool GetFrame( int iMaxFrames, int iTargetFrame )
	{
		int iFrame = int( (pev.frame/255) * iMaxFrames );
		if( IsBetween2(iFrame, Math.clamp(0, iMaxFrames, iTargetFrame-1), iTargetFrame+1) ) return true;
 
		return false;
	}

	float SetFrame( float flMaxFrames, float flFrame )
	{
		return float( (flFrame / flMaxFrames) * 255 );
	}

	bool IsBetween2( float flValue, float flMin, float flMax )
	{
		return (flValue >= flMin and flValue <= flMax);
	}
}

abstract class CBaseDriveEntityHitboxQ2 : ScriptBaseMonsterEntity
{
	int m_iSpawnFlags;
	float m_flCustomHealth;
	uint m_uiAnimationState;

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

	/*void ThrowGib( int iCount, const string &in sGibName, float flDamage, int iType = 0, bool bHead = false, int iSkin = 0 )
	{
		Vector vecOrigin = pev.origin;

		CGib@ pGib = g_EntityFuncs.CreateGib( pev.origin, g_vecZero );
		pGib.Spawn( sGibName );
		pGib.pev.skin = iSkin;

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
	}*/

	Vector VelocityForDamage( float flDamage )
	{
		Vector vec( Math.RandomFloat(-200, 200), Math.RandomFloat(-200, 200), Math.RandomFloat(300, 400) );

		if( flDamage > 50 )
			vec = vec * 0.7;
		else if( flDamage > 200 )
			vec = vec * 2;
		else
			vec = vec * 10;

		return vec;
	}

	int GetAnim()
	{
		return pev.sequence;
	}

	bool GetAnim( int iAnim )
	{
		return pev.sequence == iAnim;
	}

	int GetFrame( int iMaxFrames )
	{
		return int( (pev.frame/255) * iMaxFrames );
	}

	bool GetFrame( int iMaxFrames, int iTargetFrame )
	{
		int iFrame = int( (pev.frame/255) * iMaxFrames );
		if( IsBetween2(iFrame, Math.clamp(0, iMaxFrames, iTargetFrame-1), iTargetFrame+1) ) return true;
 
		return false;
	}

	float SetFrame( float flMaxFrames, float flFrame )
	{
		return float( (flFrame / flMaxFrames) * 255 );
	}

	bool IsBetween2( float flValue, float flMin, float flMax )
	{
		return (flValue >= flMin and flValue <= flMax);
	}
}

/* TODO
*/