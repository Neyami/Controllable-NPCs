namespace cnpc_islave
{

bool CNPC_USE_COLORMAP				= true; //Use the player's topcolor and bottomcolor to color the beams?
bool CNPC_FIRSTPERSON					= false;

const string CNPC_WEAPONNAME		= "weapon_islave";
const string CNPC_MODEL					= "models/islave.mdl";
const Vector CNPC_SIZEMIN				= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX				= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 80.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the islave itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (55.127274 * CNPC::flModelToGameSpeedModifier) * 0.3;
const float SPEED_RUN					= (151.098679 * CNPC::flModelToGameSpeedModifier) * 0.8;
const float VELOCITY_WALK			= 125.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 2.3;
const float RANGE_DAMAGE				= 11.0;
const int ISLAVE_MAX_BEAMS			= 8;
const float REVIVE_RANGE				= 420.0;
const string ZAP_BEAM_SPRITE		= "sprites/lgtning.spr";
const RGBA CHARGE_COLOR			= RGBA( 96, 128, 16, 0 );
const RGBA ZAP_COLOR					= RGBA( 180, 255, 96, 0 );

const float CD_SECONDARY				= 1.5;
const float MELEE_DAMAGE				= 8.0;
const float MELEE_RANGE				= 70.0;

const array<string> pPainSounds = 
{
	"aslave/slv_pain1.wav",
	"aslave/slv_pain2.wav"
};

const array<string> pDieSounds = 
{
	"aslave/slv_die1.wav",
	"aslave/slv_die2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"debris/zap4.wav",
	"weapons/electro4.wav",
	"hassault/hw_shoot1.wav",
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav"
};

enum sound_e
{
	SND_CHARGE = 1,
	SND_ZAP1,
	SND_ZAP2,
	SND_HIT1,
	SND_HIT2,
	SND_HIT3,
	SND_MISS1,
	SND_MISS2
};

enum anim_e
{
	ANIM_IDLE = 2,
	ANIM_WALK = 4,
	ANIM_RUN = 6,
	ANIM_MELEE = 11,
	ANIM_RANGE,
	ANIM_DEATH1 = 18,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_RANGE,
	STATE_MELEE
};

class weapon_islave : CBaseDriveWeapon
{
	int m_iVoicePitch;

	protected array<EHandle> m_hBeam(ISLAVE_MAX_BEAMS);
	//Thanks Outerbeast :ayaya:
	CBeam@ m_pBeam( uint i )
	{
		return cast<CBeam@>( m_hBeam[i].GetEntity() );
	}

	protected EHandle m_hDead;
	private int m_iBeams;
	private int m_iZapStage; //to prevent fake model events to play more than once
	private bool m_bReviveZap;

	private uint m_iSwing;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_iVoicePitch = Math.RandomLong( 85, 110 );
		m_iSwing = 0;
		m_iZapStage = 0;
		m_bReviveZap = false;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( ZAP_BEAM_SPRITE );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_islave.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_islave.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_islave_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::ISLAVE_SLOT - 1;
		info.iPosition		= CNPC::ISLAVE_POSITION - 1;
		info.iFlags 			= 0;
		info.iWeight			= 0; //-1 ??

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m1.WriteLong( g_ItemRegistry.GetIdForName(CNPC_WEAPONNAME) );
		m1.End();

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
		}

		return self.DefaultDeploy( "", "", 0, "" );
	}

	bool CanHolster()
	{
		return false;
	}

	void Holster( int skipLocal = 0 )
	{
		if( m_pDriveEnt !is null )
			@m_pDriveEnt.pev.owner = null;

		ResetPlayer();
		ClearBeams();

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState == STATE_MELEE or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_iState = STATE_RANGE;
			SetAnim( ANIM_RANGE );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState == STATE_RANGE or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_iState = STATE_MELEE;
			m_iSwing = 0;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			SetAnim( ANIM_MELEE );

			SetThink( ThinkFunction(this.MeleeAttackThink) );
			pev.nextthink = g_Engine.time + 0.3;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CD_SECONDARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_SECONDARY;
	}

	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
		{
			SetThink( null );
			return;
		}

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE, DMG_SLASH );
		if( pHurt !is null )
		{
			if( (pHurt.pev.flags & FL_MONSTER) != 0 or ((pHurt.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
			{
				pHurt.pev.punchangle.z = -18;
				pHurt.pev.punchangle.x = 5;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT3)], VOL_NORM, ATTN_NORM, 0, m_iVoicePitch );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MISS1, SND_MISS2)], VOL_NORM, ATTN_NORM, 0, m_iVoicePitch );

		if( m_iSwing == 0 )
			pev.nextthink = g_Engine.time + 0.3;
		else if( m_iSwing == 1 )
			pev.nextthink = g_Engine.time + 0.4;
		else if( m_iSwing == 2 )
			SetThink( null );

		m_iSwing++;
	}

	void TertiaryAttack()
	{
		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;

		if( m_pDriveEnt is null ) return;

		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			DoFirstPersonView();
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			cnpc_islave@ pDriveEnt = cast<cnpc_islave@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			DoMovementAnimation();
			DoIdleAnimation();
			DoIdleSound();

			DoZapAttack();
			CheckReviveInput();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState >= STATE_RANGE ) return;

		m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				SetAnim( ANIM_WALK );
				m_pDriveEnt.pev.framerate = 1.7; //the walking animation is too slow
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_RANGE and m_pDriveEnt.pev.sequence == ANIM_RANGE and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;
				m_iZapStage = 0;

				SetAnim( ANIM_IDLE );
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void IdleSound()
	{
		if( m_pDriveEnt is null ) return;

		if( Math.RandomLong(0, 2) == 0 )
			g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "SLV_IDLE", 0.85, ATTN_NORM, 0, m_iVoicePitch );
	}

	void DoZapAttack()
	{
		if( m_iState != STATE_RANGE or m_pDriveEnt.pev.sequence != ANIM_RANGE or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		switch( GetFrame(35) )
		{
			case 0: { if( m_iZapStage == 0 ) { CheckForDeadFriends(); ZapPowerUp(); m_iZapStage++; } break; }
			case 4: { if( m_iZapStage == 1 ) { ZapPowerUp(); m_iZapStage++; } break; }
			case 10: { if( m_iZapStage == 2 ) { ZapPowerUp(); m_iZapStage++; } break; }
			case 15: { if( m_iZapStage == 3 ) { ZapPowerUp(); m_iZapStage++; } break; }
			case 24: { if( m_iZapStage == 4 ) { ZapShoot(); m_iZapStage++; } break; }
			case 29: { if( m_iZapStage == 5 ) { ZapDone(); m_iZapStage++; } break; }
		}
	}

	void CheckReviveInput()
	{
		if( m_iState == STATE_RANGE or m_iState == STATE_MELEE or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( self.m_flNextPrimaryAttack > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 )
		{
			m_bReviveZap = true;
			PrimaryAttack();
		}
	}

	void CheckForDeadFriends()
	{
		float flDist = REVIVE_RANGE;
		m_hDead = null;

		CBaseEntity@ pEntity = null;
		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "monster_alien_slave")) !is null )
		{
			TraceResult tr;

			g_Utility.TraceLine( self.EyePosition(), pEntity.EyePosition( ), ignore_monsters, m_pDriveEnt.edict(), tr );

			if( tr.flFraction == 1.0 or tr.pHit is pEntity.edict() )
			{
				if( pEntity.pev.deadflag == DEAD_DEAD )
				{
					float d = (pev.origin - pEntity.pev.origin).Length();
					if( d < flDist )
					{
						m_hDead = EHandle(pEntity);
						flDist = d;
					}
				}
			}
		}
	}

	void ZapPowerUp()
	{
		// speed up attack when on hard, TODO: use??
		//if( g_iSkillLevel == SKILL_HARD )
			//pev.framerate = 1.5;

		Math.MakeAimVectors( m_pDriveEnt.pev.angles ); //player v_angle ??

		if( m_iBeams == 0 )
		{
			Vector vecSrc = m_pDriveEnt.pev.origin + g_Engine.v_forward * 2;

			NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
				m1.WriteByte( TE_DLIGHT );
				m1.WriteCoord( vecSrc.x );
				m1.WriteCoord( vecSrc.y );
				m1.WriteCoord( vecSrc.z );
				m1.WriteByte( 12 ); //radius * 0.1
				m1.WriteByte( 255 ); //rgb
				m1.WriteByte( 180 );
				m1.WriteByte( 96 );
				m1.WriteByte( int(20 / m_pDriveEnt.pev.framerate) ); //life * 10
				m1.WriteByte( 0 ); //decay * 0.1
			m1.End();
		}

		if( m_bReviveZap and m_hDead.IsValid() )
		{
			WackBeam( -1, m_hDead );
			WackBeam( 1, m_hDead );
		}
		else
		{
			ArmBeam( -1 );
			ArmBeam( 1 );
			BeamGlow();
		}

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_CHARGE], VOL_NORM, ATTN_NORM, 0, 100 + m_iBeams * 10 );
		//m_pDriveEnt.pev.skin = m_iBeams / 2; //??
	}

	void ZapShoot()
	{
		ClearBeams();

		if( m_bReviveZap and m_hDead.IsValid() )
		{
			Vector vecDest = m_hDead.GetEntity().pev.origin + Vector( 0, 0, 38 );
			TraceResult trace;
			g_Utility.TraceHull( vecDest, vecDest, dont_ignore_monsters, human_hull, m_pPlayer.edict(), trace );

			if( trace.fStartSolid == 0 )
			{
				CBaseEntity@ pNew = g_EntityFuncs.Create( "monster_alien_slave", m_hDead.GetEntity().pev.origin, m_hDead.GetEntity().pev.angles, false );
				CBaseMonster@ pNewMonster = pNew.MyMonsterPointer();
				pNew.pev.spawnflags |= 1;
				g_EntityFuncs.DispatchKeyValue( pNew.edict(), "is_player_ally", "1" );

				WackBeam( -1, EHandle(pNew) );
				WackBeam( 1, EHandle(pNew) );
				g_EntityFuncs.Remove( m_hDead.GetEntity() );
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ZAP1], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(130, 160) );

				return;
			}
		}

		g_WeaponFuncs.ClearMultiDamage();

		Vector vecAngle = m_pPlayer.pev.v_angle;
		vecAngle.x = -vecAngle.x;
		Math.MakeAimVectors( vecAngle );

		ZapBeam( -1 );
		ZapBeam( 1 );

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ZAP1], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(130, 160) );
		//g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_CHARGE] );
		g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
	}

	void ZapDone()
	{
		ClearBeams();
		m_bReviveZap = false;
	}

	void ArmBeam( int side )
	{
		TraceResult tr;
		float flDist = 1.0;

		if( m_iBeams >= ISLAVE_MAX_BEAMS )
			return;

		Math.MakeAimVectors( m_pDriveEnt.pev.angles );
		Vector vecSrc = pev.origin + g_Engine.v_up * 36 + g_Engine.v_right * side * 16 + g_Engine.v_forward * 32;

		for( int i = 0; i < 3; i++ )
		{
			Vector vecAim = g_Engine.v_right * side * Math.RandomFloat( 0, 1 ) + g_Engine.v_up * Math.RandomFloat( -1, 1 );
			TraceResult tr1;
			g_Utility.TraceLine( vecSrc, vecSrc + vecAim * 512, dont_ignore_monsters, m_pPlayer.edict(), tr1 );

			if( flDist > tr1.flFraction )
			{
				tr = tr1;
				flDist = tr.flFraction;
			}
		}

		// Couldn't find anything close enough
		if( flDist == 1.0 )
			return;

		g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_CROWBAR );

		m_hBeam[m_iBeams] = EHandle( g_EntityFuncs.CreateBeam(ZAP_BEAM_SPRITE, 30) );
		if( !m_hBeam[m_iBeams].IsValid() )
			return;

		m_pBeam(m_iBeams).PointEntInit( tr.vecEndPos, m_pDriveEnt.entindex() );
		m_pBeam(m_iBeams).SetEndAttachment( side < 0 ? 2 : 1 );

		if( !CNPC_USE_COLORMAP )
			m_pBeam(m_iBeams).SetColor( CHARGE_COLOR.r, CHARGE_COLOR.g, CHARGE_COLOR.b );
		else
		{
			RGBA rgbBottomRGB;
			getPlayerColors( m_pPlayer, void, rgbBottomRGB );
			m_pBeam(m_iBeams).SetColor( rgbBottomRGB.r, rgbBottomRGB.g, rgbBottomRGB.b );
		}

		m_pBeam(m_iBeams).SetBrightness( 64 );
		m_pBeam(m_iBeams).SetNoise( 80 );
		m_iBeams++;
	}

	void BeamGlow()
	{
		int b = m_iBeams * 32;

		if( b > 255 )
			b = 255;

		for( int i = 0; i < m_iBeams; i++ )
		{
			if( m_pBeam(i).GetBrightness() != 255 )
				m_pBeam(i).SetBrightness( b );
		}
	}

	void WackBeam( int side, EHandle hEntity )
	{
		CBaseEntity@ pEntity = hEntity.GetEntity();
		
		Vector vecDest;
		float flDist = 1.0;

		if( m_iBeams >= ISLAVE_MAX_BEAMS )
			return;

		if( pEntity is null )
			return;

		m_hBeam[m_iBeams] = EHandle( g_EntityFuncs.CreateBeam(ZAP_BEAM_SPRITE, 30) );
		if( !m_hBeam[m_iBeams].IsValid() )
			return;

		m_pBeam(m_iBeams).PointEntInit( pEntity.Center(), m_pDriveEnt.entindex() );
		m_pBeam(m_iBeams).SetEndAttachment( side < 0 ? 2 : 1 );

		if( !CNPC_USE_COLORMAP )
			m_pBeam(m_iBeams).SetColor( ZAP_COLOR.r, ZAP_COLOR.g, ZAP_COLOR.b );
		else
		{
			RGBA rgbTopRGB;
			getPlayerColors( m_pPlayer, rgbTopRGB, void );
			m_pBeam(m_iBeams).SetColor( rgbTopRGB.r, rgbTopRGB.g, rgbTopRGB.b );
		}

		m_pBeam(m_iBeams).SetBrightness( 255 );
		m_pBeam(m_iBeams).SetNoise( 80 );
		m_iBeams++;
	}

	void ZapBeam( int side )
	{
		Vector vecSrc, vecAim;
		TraceResult tr;
		CBaseEntity@ pEntity;

		if( m_iBeams >= ISLAVE_MAX_BEAMS )
			return;

		vecSrc = pev.origin + g_Engine.v_up * 36;
		vecAim = g_Engine.v_forward;
		float deflection = 0.01;
		vecAim = vecAim + side * g_Engine.v_right * Math.RandomFloat( 0, deflection ) + g_Engine.v_up * Math.RandomFloat( -deflection, deflection );
		g_Utility.TraceLine( vecSrc, vecSrc + vecAim * 1024.0, dont_ignore_monsters, m_pPlayer.edict(), tr );

		m_hBeam[m_iBeams] = EHandle( g_EntityFuncs.CreateBeam(ZAP_BEAM_SPRITE, 50) );

		if( !m_hBeam[m_iBeams].IsValid() )
			return;

		m_pBeam(m_iBeams).PointEntInit( tr.vecEndPos, m_pDriveEnt.entindex() );
		m_pBeam(m_iBeams).SetEndAttachment( side < 0 ? 2 : 1 );

		if( !CNPC_USE_COLORMAP )
			m_pBeam(m_iBeams).SetColor( ZAP_COLOR.r, ZAP_COLOR.g, ZAP_COLOR.b );
		else
		{
			RGBA rgbTopRGB;
			getPlayerColors( m_pPlayer, rgbTopRGB, void );
			m_pBeam(m_iBeams).SetColor( rgbTopRGB.r, rgbTopRGB.g, rgbTopRGB.b );
		}

		m_pBeam(m_iBeams).SetBrightness( 255 );
		m_pBeam(m_iBeams).SetNoise( 20 );
		m_iBeams++;

		@pEntity = g_EntityFuncs.Instance( tr.pHit );
		if( pEntity !is null and pEntity.pev.takedamage != DAMAGE_NO )
			pEntity.TraceAttack( m_pPlayer.pev, RANGE_DAMAGE, vecAim, tr, DMG_SHOCK );

		g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), tr.vecEndPos, arrsCNPCSounds[SND_ZAP2], 0.5, ATTN_NORM, 0, Math.RandomLong(140, 160) ); 
	}

	void ClearBeams()
	{
		for( int i = 0; i < ISLAVE_MAX_BEAMS; i++ )
		{
			if( m_hBeam[i].IsValid() )
				g_EntityFuncs.Remove( m_hBeam[i].GetEntity() );
		}

		m_iBeams = 0;

		g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_CHARGE] );
	}

	void spawnDriveEnt()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		vecOrigin.z -= CNPC_MODEL_OFFSET;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_islave", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		cnpc_islave@ pDriveEnt = cast<cnpc_islave@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt !is null )
			pDriveEnt.m_iVoicePitch = m_iVoicePitch;

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;

		self.m_bExclusiveHold = true;

		if( CNPC_FIRSTPERSON )
		{
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			DoFirstPersonView();
		}
		else
		{
			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_ISLAVE );
	}

	void DoFirstPersonView()
	{
		cnpc_islave@ pDriveEnt = cast<cnpc_islave@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_islave_rend_" + m_pPlayer.entindex();
		m_pDriveEnt.pev.targetname = szDriveEntTargetName;

		dictionary keys;
		keys[ "target" ] = szDriveEntTargetName;
		keys[ "rendermode" ] = "2"; //kRenderTransTexture
		keys[ "renderamt" ] = "0";
		keys[ "spawnflags" ] = "64"; //Affect Activator (ignore netname)

		CBaseEntity@ pRender = g_EntityFuncs.CreateEntity( "env_render_individual", keys );

		if( pRender !is null )
		{
			pRender.Use( m_pPlayer, pRender, USE_ON, 0.0 );
			pDriveEnt.m_hRenderEntity = EHandle( pRender );
		}
	}

	void ResetPlayer()
	{
		m_pPlayer.pev.iuser3 = 0; //enable ducking
		m_pPlayer.pev.fuser4 = 0; //enable jumping
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}

	void getPlayerColors( CBasePlayer@ pPlayer, RGBA &out rgbTop, RGBA &out rgbBottom )
	{
		if( pPlayer is null ) return;

		uint8 uiTop = pPlayer.pev.colormap & 0xFF;
		uint8 uiBottom = (pPlayer.pev.colormap & 0xFF00) >> 8;

		rgbTop = HUEtoRGB( uiTop );
		rgbBottom = HUEtoRGB( uiBottom );
	}

	//from https://github.com/Inseckto/HSV-to-RGB/blob/master/HSV2RGB.c
	RGBA HUEtoRGB( float H )
	{
		float r, g, b;

		float h = H / 255;
		float s = 1.0;
		float v = 1.0;

		int i = int(floor(h * 6));
		float f = h * 6 - i;
		float p = v * (1 - s);
		float q = v * (1 - f * s);
		float t = v * (1 - (1 - f) * s);

		switch( i % 6 )
		{
			case 0: { r = v; g = t; b = p; break; }
			case 1: { r = q; g = v; b = p; break; }
			case 2: { r = p; g = v; b = t; break; }
			case 3: { r = p; g = q; b = v; break; }
			case 4: { r = t; g = p; b = v; break; }
			case 5: { r = v; g = p; b = q; break; }
		}

		RGBA color;
		color.r = int(r * 255);
		color.g = int(g * 255);
		color.b = int(b * 255);

		return color;
	}
}

class cnpc_islave : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players
	int m_iVoicePitch;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 72) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;
		pev.set_controller( 0,  127 );

		if( m_iVoicePitch <= 0 ) m_iVoicePitch = PITCH_NORM;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flNextOriginUpdate = g_Engine.time;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

			return;
		}

		if( m_flNextOriginUpdate < g_Engine.time )
		{
			Vector vecOrigin = m_pOwner.pev.origin;
			vecOrigin.z -= CNPC_MODEL_OFFSET;
			g_EntityFuncs.SetOrigin( self, vecOrigin );
			m_flNextOriginUpdate = g_Engine.time + CNPC_ORIGINUPDATE;
		}

		pev.velocity = m_pOwner.pev.velocity;

		pev.angles.x = 0;

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_WALK) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH4 );
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM, 0, m_iVoicePitch );

		SetThink( ThinkFunction(this.SUB_StartFadeOut) );
		pev.nextthink = g_Engine.time;
	}

	void SUB_StartFadeOut()
	{
		if( pev.rendermode == kRenderNormal )
		{
			pev.renderamt = 255;
			pev.rendermode = kRenderTransTexture;
		}

		pev.solid = SOLID_NOT;
		pev.avelocity = g_vecZero;

		pev.nextthink = g_Engine.time + 0.1;
		SetThink( ThinkFunction(this.SUB_FadeOut) );
	}

	void SUB_FadeOut()
	{
		if( pev.renderamt > 7 )
		{
			pev.renderamt -= 7;
			pev.nextthink = g_Engine.time + 0.1;
		}
		else 
		{
			pev.renderamt = 0;
			pev.nextthink = g_Engine.time + 0.2;
			SetThink( ThinkFunction(this.SUB_Remove) );
		}
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_islave : CNPCSpawnEntity
{
	info_cnpc_islave()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
	}

	void DoSpecificStuff()
	{
		pev.set_controller( 0,  127 );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_islave::info_cnpc_islave", "info_cnpc_islave" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_islave::cnpc_islave", "cnpc_islave" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_islave::weapon_islave", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "cnpc_islave" );
	g_Game.PrecacheOther( "info_cnpc_islave" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_islave END

/* FIXME
*/

/* TODO
*/