class CBaseDriveWeapon : ScriptBasePlayerWeaponEntity
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
	protected CBaseAnimating@ m_pDriveEnt
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
		if( (m_iSpawnFlags & CNPC::FL_GAG) != 0 ) return;
		if( m_flNextIdleCheck > g_Engine.time ) return;
		if( m_iState != STATE_IDLE ) return;

		if( Math.RandomLong(0, 99) == 0 )
			IdleSound();

		m_flNextIdleCheck = g_Engine.time + 0.1;
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

	CBaseEntity@ FindNearestFriend( bool bIncludePlayers = true )
	{
		CBaseEntity@ pFriend = null;
		CBaseEntity@ pNearest = null;
		float range = 10000000.0;
		TraceResult tr;
		Vector vecStart = m_pPlayer.pev.origin;
		Vector vecCheck;
		string sFriend;

		array<string> arrsFriends = 
		{
			"cnpc_scientist",
			"cnpc_barney",
			"cnpc_otis",
			"player"/*,
			"monster_scientist",
			"monster_sitting_scientist",
			"monster_barney"*/ //TODO
		};

		vecStart.z = m_pPlayer.pev.absmax.z;

		// for each type of friend...
		for( uint i = 0; i < arrsFriends.length(); i++ )
		{
			sFriend = arrsFriends[i];

			// for each friend in this bsp...
			while( (@pFriend = g_EntityFuncs.FindEntityByClassname(pFriend, sFriend)) !is null )
			{
				if( !pFriend.pev.FlagBitSet(FL_CLIENT) )
				{
					if( pFriend.pev.owner is null or pFriend.pev.owner is m_pPlayer.edict() or pFriend.pev.deadflag > DEAD_NO )
						continue;
				}

				if( pFriend.pev.FlagBitSet(FL_CLIENT) and pFriend.edict() is m_pPlayer.edict() ) continue;

				if( !pFriend.pev.FlagBitSet(FL_CLIENT) )
				{
					CBaseEntity@ cbeFriendController = GetFriendController(pFriend);
					if( cbeFriendController is null ) continue;

					if( cbeFriendController.GetClassname() == "weapon_scientist" )
					{
						cnpc_scientist::weapon_scientist@ pFriendController = cast<cnpc_scientist::weapon_scientist@>(CastToScriptClass(cbeFriendController));
						if( pFriendController is null or pFriendController.m_iState != STATE_IDLE ) continue;
					}
					else if( cbeFriendController.GetClassname() == "weapon_barney" )
					{
						cnpc_barney::weapon_barney@ pFriendController = cast<cnpc_barney::weapon_barney@>(CastToScriptClass(cbeFriendController));
						if( pFriendController is null or pFriendController.m_iState != STATE_IDLE ) continue;
					}
					else if( cbeFriendController.GetClassname() == "weapon_otis" )
					{
						cnpc_otis::weapon_otis@ pFriendController = cast<cnpc_otis::weapon_otis@>(CastToScriptClass(cbeFriendController));
						if( pFriendController is null or pFriendController.m_iState != STATE_IDLE ) continue;
					}
				}

				if( !bIncludePlayers and pFriend.pev.FlagBitSet(FL_CLIENT) ) continue;

				//pFriendController.m_bAnswerQuestion = true;

				vecCheck = pFriend.pev.origin;
				vecCheck.z = pFriend.pev.absmax.z;

				// if closer than previous friend, and in range, see if he's visible

				if( range > (vecStart - vecCheck).Length() )
				{
					g_Utility.TraceLine( vecStart, vecCheck, ignore_monsters, m_pPlayer.edict(), tr ); //m_pDriveEnt ??

					if( tr.flFraction == 1.0 )
					{
						// visible and in range, this is the new nearest scientist
						if( (vecStart - vecCheck).Length() < 500.0 ) //TALKRANGE_MIN
						{
							@pNearest = pFriend;
							range = (vecStart - vecCheck).Length();
						}
					}
				}
			}
		}

		/*if( pNearest !is null )
			g_Game.AlertMessage( at_notice, "pNearest: %1\n", pNearest.GetClassname() );
		else
			g_Game.AlertMessage( at_notice, "pNearest is null!\n" );*/

		return pNearest;
	}

	CBaseEntity@ GetFriendController( CBaseEntity@ pFriend )
	{
		CBasePlayer@ pFriendOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pFriend.pev.owner) );

		if( pFriendOwner is null or !pFriendOwner.IsConnected() ) return null;
		if( pFriendOwner.m_hActiveItem.GetEntity() is null ) return null;

		//g_Game.AlertMessage( at_notice, "Friend controller found!\n" );
		return pFriendOwner.m_hActiveItem.GetEntity();
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


abstract class CBaseDriveEntity : ScriptBaseAnimating
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
}

abstract class CBaseDriveEntityHitbox : ScriptBaseMonsterEntity
{
	Vector m_vecExitOrigin, m_vecExitAngles; //for noplayerdeath

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

	int Classify()
	{
		if( CNPC::PVP )
		{
			if( m_pOwner !is null and m_pOwner.IsConnected() )
			{
				if( m_pOwner.Classify() == CLASS_PLAYER )
					return CLASS_PLAYER_ALLY;
				else
					return m_pOwner.Classify();
			}
		}

		return CLASS_PLAYER_ALLY;
	}
}