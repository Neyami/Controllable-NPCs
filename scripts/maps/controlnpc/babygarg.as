namespace cnpc_babygarg
{

bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_babygarg";
const string CNPC_MODEL				= "models/babygarg.mdl";
const Vector CNPC_SIZEMIN			= Vector( -24, -24, 0 );
const Vector CNPC_SIZEMAX			= Vector( 24, 24, 72 );

const float CNPC_HEALTH				= 600.0;
const float CNPC_VIEWOFS_FPV		= 42.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 64.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the babygarg itself
const float CNPC_MODEL_OFFSET	= 32.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (66.093971 * CNPC::flModelToGameSpeedModifier) * 0.2;
const float SPEED_RUN					= -1;//(341.657471 * CNPC::flModelToGameSpeedModifier) * 0.5;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const string GARG_EYE_SPRITE		= "sprites/gargeye1.spr";

const float CD_PRIMARY					= 1.0;
const float FLAME_DAMAGE			= 2.0;
const int FLAME_LENGTH				= 180;
const int AMMO_FLAME_MAX			= 100;
const string FLAME_SPRITE				= "sprites/xbeam3.spr";
const float AMMO_REGEN_RATE		= 0.1; //+1 per AMMO_REGEN_RATE seconds

const float CD_SECONDARY			= 1.5; //melee
const float MELEE_RANGE				= 75.0;
const float MELEE_DAMAGE			= 25.0;

const float KICK_RANGE					= 75.0;
const float KICK_DAMAGE				= 25.0;

const float CD_STOMP					= 1.0;
const float STOMP_SPEED				= 250.0;
const float STOMP_DAMAGE			= 50.0;

const array<string> pPainSounds = 
{
	"babygarg/gar_pain1.wav",
	"babygarg/gar_pain2.wav",
	"babygarg/gar_pain3.wav"
};

const array<string> pDieSounds = 
{
	"babygarg/gar_die1.wav",
	"babygarg/gar_die2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"babygarg/gar_attack1.wav",
	"babygarg/gar_breathe1.wav",
	"babygarg/gar_breathe2.wav",
	"babygarg/gar_breathe3.wav",
	"babygarg/gar_step1.wav",
	"babygarg/gar_step2.wav",
	"babygarg/gar_flameoff1.wav",
	"babygarg/gar_flameon1.wav",
	"babygarg/gar_flamerun1.wav",
	"babygarg/gar_attack1.wav",
	"babygarg/gar_attack2.wav",
	"babygarg/gar_attack3.wav",
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav",
	"babygarg/gar_stomp1.wav",
	"weapons/mine_charge.wav"
};

enum sound_e
{
	SND_IDLE = 1,
	SND_BREATHE1,
	SND_BREATHE2,
	SND_BREATHE3,
	SND_STEP1,
	SND_STEP2,
	SND_FLAME_OFF,
	SND_FLAME_ON,
	SND_FLAME_LOOP,
	SND_ATTACK1,
	SND_ATTACK2,
	SND_ATTACK3,
	SND_MELEE_HIT1,
	SND_MELEE_HIT2,
	SND_MELEE_HIT3,
	SND_MELEE_MISS1,
	SND_MELEE_MISS2,
	SND_STOMP
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK = 4,
	ANIM_RUN,
	ANIM_RANGE_LOOP = 7,
	ANIM_MELEE,
	ANIM_STOMP,
	ANIM_DEATH = 14,
	ANIM_KICK = 19
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_FLAME,
	STATE_MELEE,
	STATE_STOMP,
	STATE_KICK
};

class weapon_babygarg : CBaseDriveWeapon
{
	private EHandle m_hEyeGlow;
	private CSprite@ m_pEyeGlow
	{
		get const { return cast<CSprite@>(m_hEyeGlow.GetEntity()); }
		set { m_hEyeGlow = EHandle(@value); }
	}

	private array<EHandle> m_hFlame(4);
	//Thanks Outerbeast :ayaya:
	CBeam@ m_pFlame( uint i )
	{
		return cast<CBeam@>( m_hFlame[i].GetEntity() );
	}

	private Vector m_vecAim;
	private float m_flFlameX;
	private float m_flFlameY;
	private float m_flStreakTime;
	private float m_flNextAmmoUse;
	private float m_flNextAmmoRegen;

	private int m_iEyeBrightness;

	void Spawn()
	{
		Precache();

		self.m_iDefaultAmmo = AMMO_FLAME_MAX;
		m_iState = STATE_IDLE;
		m_uiAnimationState = 0;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( FLAME_SPRITE );
		g_Game.PrecacheModel( GARG_EYE_SPRITE );
		g_Game.PrecacheModel( "sprites/zerogxplode.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_babygarg.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_babygarg.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_babygarg_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= AMMO_FLAME_MAX;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::BABYGARG_SLOT - 1;
		info.iPosition			= CNPC::BABYGARG_POSITION - 1;
		info.iFlags 				= 0;
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

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, AMMO_FLAME_MAX );

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
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

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState >= STATE_FLAME or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 ) return;

			m_iState = STATE_FLAME;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			SetAnim( ANIM_RANGE_LOOP );

			if( Math.RandomLong(0, 100) < 30 )
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_ATTACK1, SND_ATTACK3)], VOL_NORM, ATTN_NORM );

			FlameCreate();
			m_flFlameX = 0;
			m_flFlameY = 0;
			m_pDriveEnt.pev.angles.y = m_pPlayer.pev.v_angle.y;
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt is null or m_iState >= STATE_FLAME or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		m_iState = STATE_MELEE;
		m_pPlayer.SetMaxSpeedOverride( 0 );
		SetAnim( ANIM_MELEE );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
	}

	void TertiaryAttack()
	{
		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			SetRender( 1 ); //if it's 0 the flames start at the gargs feet
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			SetRender( 255 );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}

		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			DoMovementAnimation();
			DoIdleAnimation();

			DoEyeGlow();
			DoFlame();
			DoAmmoRegen();
			MeleeAE();
			CheckKickInput();
			KickAE();
			CheckStompInput();
			StompAE();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState >= STATE_FLAME ) return;

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
				m_pDriveEnt.pev.framerate = 1.5; //the animation is too slow
			}
			else
			{
				if( IsBetween2(GetFrame(34), 0, 2) and m_uiAnimationState == 0 ) { FootStep(); m_uiAnimationState++; }
				else if( IsBetween2(GetFrame(34), 6, 8) and m_uiAnimationState == 1 ) { Breathe(); m_uiAnimationState++; }
				else if( IsBetween2(GetFrame(34), 17, 19) and m_uiAnimationState == 2 ) { FootStep(); m_uiAnimationState = 0; }
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
				m_pDriveEnt.pev.framerate = 1.5; //the animation is too slow
			}
			else
			{
				if( IsBetween2(GetFrame(21), 8, 10) and m_uiAnimationState == 0 ) { FootStep(); m_uiAnimationState++; }
				else if( IsBetween2(GetFrame(21), 18, 20) and m_uiAnimationState == 1 ) { FootStep(); m_uiAnimationState = 0; }

				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
			}
		}
	}

	void FootStep()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_STEP1, SND_STEP2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-10, 10) );
	}

	void Breathe()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_BREATHE1, SND_BREATHE3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-10, 10) );
	}

	void DoIdleAnimation( bool bOverrideState = false )
	{
		if( !bOverrideState )
		{
			if( m_iState == STATE_FLAME and (m_pPlayer.pev.button & IN_ATTACK != 0) ) return;
			if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_KICK and m_pDriveEnt.pev.sequence == ANIM_KICK and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_STOMP and m_pDriveEnt.pev.sequence == ANIM_STOMP and !m_pDriveEnt.m_fSequenceFinished ) return;
		}

		if( m_iState == STATE_FLAME and (m_pPlayer.pev.button & IN_ATTACK) == 0 )
			StopFlame();

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;
				SetAnim( ANIM_IDLE );
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}

			if( m_iState == STATE_IDLE )
			{
				if( m_pDriveEnt.pev.sequence == ANIM_IDLE )
				{
					if( IsBetween2(GetFrame(31), 7, 9) and m_uiAnimationState == 0 ) { Breathe(); m_uiAnimationState++; }
					else if( GetFrame(31) >= 18 and m_uiAnimationState >= 1 ) { m_uiAnimationState = 0; }
				}
				else if( m_pDriveEnt.pev.sequence == ANIM_IDLE_FIDGET )
				{
					if( IsBetween2(GetFrame(66), 6, 8) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
					else if( GetFrame(66) >=17 and m_uiAnimationState >= 1 ) { m_uiAnimationState = 0; }
				}
			}
		}
	}

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_NORM );
	}

	void DoEyeGlow()
	{
		if( m_iState == STATE_IDLE )
			EyeOff();
		else
			EyeOn( 200 );

		EyeUpdate();
	}

	void EyeOff()
	{
		m_iEyeBrightness = 0;
	}

	void EyeOn( int level )
	{
		m_iEyeBrightness = level;
	}

	void EyeUpdate()
	{
		if( m_pEyeGlow !is null )
		{
			m_pEyeGlow.pev.renderamt = Math.ApproachAngle( m_iEyeBrightness, m_pEyeGlow.pev.renderamt, 26 );

			if( m_pEyeGlow.pev.renderamt == 0 )
				m_pEyeGlow.pev.effects |= EF_NODRAW;
			else
				m_pEyeGlow.pev.effects &= ~EF_NODRAW;

			g_EntityFuncs.SetOrigin( m_pEyeGlow, m_pDriveEnt.pev.origin );
		}
	}

	void DoFlame()
	{
		if( m_iState != STATE_FLAME ) return;
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			StopFlame();
			DoIdleAnimation( true );
			return;
		}

		if( m_pDriveEnt.pev.sequence == ANIM_RANGE_LOOP )
		{
			Vector vecAngles = g_vecZero;

			FlameUpdate();

			Vector org = m_pDriveEnt.pev.origin;
			org.z += 48;
			Math.MakeVectors( m_pPlayer.pev.v_angle );
			Vector dir = g_Engine.v_forward;
			vecAngles = Math.VecToAngles( dir );
			vecAngles.x = -vecAngles.x;
			vecAngles.y -= m_pDriveEnt.pev.angles.y;

			FlameControls( vecAngles.x, vecAngles.y );
		}
	}

	void FlameCreate()
	{
		Vector vecGun;
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		for( int i = 0; i < 4; i++ )
		{
			if( i < 2 )
				m_hFlame[i] = EHandle( g_EntityFuncs.CreateBeam(FLAME_SPRITE, 120) );
			else
				m_hFlame[i] = EHandle( g_EntityFuncs.CreateBeam(FLAME_SPRITE, 70) );

			if( m_hFlame[i].IsValid() )
			{
				int attach = i%2;
				g_EngineFuncs.GetAttachment( m_pDriveEnt.edict(), attach+1, vecGun, void );

				Vector vecEnd = (g_Engine.v_forward * FLAME_LENGTH) + vecGun;
				g_Utility.TraceLine( vecGun, vecEnd, dont_ignore_monsters, m_pDriveEnt.edict(), tr );

				m_pFlame(i).PointEntInit( tr.vecEndPos, m_pDriveEnt.entindex() );

				//Thanks H² :ayaya:
				if( i < 2 )
					m_pFlame(i).SetColor( 220, 90, 60 );
				else
					m_pFlame(i).SetColor( 0, 100, 220 );

				m_pFlame(i).SetBrightness( 190 );
				m_pFlame(i).SetFlags( BEAM_FSHADEIN );
				m_pFlame(i).SetScrollRate( 20 );
				m_pFlame(i).SetEndAttachment( attach + 2 );

				GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, vecGun, 384, 0.3, m_pPlayer ); 
			}
		}

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_FLAME_ON], VOL_NORM, ATTN_NORM );
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_FLAME_LOOP], VOL_NORM, ATTN_NORM );
	}

	void FlameUpdate()
	{
		TraceResult tr;
		Vector vecStart;
		bool bStreaks = false;

		for( int i = 0; i < 2; i++ )
		{
			if( m_pFlame(i) !is null )
			{
				m_vecAim.x = m_pPlayer.pev.v_angle.x;
				m_vecAim.z = 0;

				if( m_pPlayer.pev.v_angle.x > 44.0 )
					m_vecAim.x = 44.0;
				else if( m_pPlayer.pev.v_angle.x < -40.0 )
					m_vecAim.x = -40.0;

				float flAngleDiff = Math.AngleDiff( m_pDriveEnt.pev.angles.y, m_pPlayer.pev.v_angle.y );
				if( flAngleDiff < 60 and flAngleDiff > -60 )
					m_vecAim.y = m_pPlayer.pev.v_angle.y;

				Math.MakeVectors( m_vecAim );

				g_EngineFuncs.GetAttachment( m_pDriveEnt.edict(), i+1, vecStart, void );
				//Vector vecEnd = vecStart + (g_Engine.v_forward * FLAME_LENGTH);
				//FIXED The flames completely miss some enemies without this FIXED
				//float flOffset = (i == 0 ? -105 : 105);
				// + g_Engine.v_right * flOffset
				Vector vecEnd = vecStart + g_Engine.v_forward * FLAME_LENGTH;

				g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr );

				m_pFlame(i).SetStartPos( tr.vecEndPos );
				m_pFlame(i+2).SetStartPos( (vecStart * 0.6) + (tr.vecEndPos * 0.4) );

				if( tr.flFraction != 1.0 and g_Engine.time > m_flStreakTime )
				{
					StreakSplash( tr.vecEndPos, tr.vecPlaneNormal, 6, 20, 50, 400 );
					bStreaks = true;
					g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 + Math.RandomLong(0, 2) );

					//g_WeaponFuncs.RadiusDamage( tr.vecEndPos, m_pPlayer.pev, m_pPlayer.pev, FLAME_DAMAGE, FLAME_DAMAGE * 2.5, CLASS_PLAYER, DMG_BURN );
					FlameDamage( vecStart, tr.vecEndPos, m_pPlayer.pev, m_pPlayer.pev, FLAME_DAMAGE, CLASS_PLAYER, DMG_BURN );

					NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
						m1.WriteByte( TE_ELIGHT );
						m1.WriteShort( m_pDriveEnt.entindex() + 0x1000 * (i + 2) ); //entity, attachment
						m1.WriteCoord( vecStart.x ); //origin
						m1.WriteCoord( vecStart.y );
						m1.WriteCoord( vecStart.z );
						m1.WriteCoord( Math.RandomFloat( 32, 48 ) ); //radius
						m1.WriteByte( 255 );	//rgb
						m1.WriteByte( 255 );
						m1.WriteByte( 255 );
						m1.WriteByte( 2 );	//life * 10
						m1.WriteCoord( 0 ); //decay
					m1.End();
				}
			}
		}

		if( bStreaks )
			m_flStreakTime = g_Engine.time + 0.1;

		if( m_flNextAmmoUse < g_Engine.time )
		{
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
			m_flNextAmmoUse = g_Engine.time + 0.1;
		}
	}

	void FlameControls( float angleX, float angleY )
	{
		if( angleY < -180 )
			angleY += 360;
		else if( angleY > 180 )
			angleY -= 360;

		if( angleY < -45 )
			angleY = -45;
		else if( angleY > 45 )
			angleY = 45;

		m_flFlameX = Math.ApproachAngle( angleX, m_flFlameX, 4 );
		m_flFlameY = Math.ApproachAngle( angleY, m_flFlameY, 8 );
		m_pDriveEnt.SetBoneController( 0, m_flFlameY );
		m_pDriveEnt.SetBoneController( 1, m_flFlameX );
	}

	void FlameDestroy()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_FLAME_OFF], VOL_NORM, ATTN_NORM );

		for( int i = 0; i < 4; i++ )
		{
			if( m_pFlame(i) !is null )
				g_EntityFuncs.Remove( m_pFlame(i) );
		}
	}

	void FlameDamage( Vector vecStart, Vector vecEnd, entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int iClassIgnore, int bitsDamageType )
	{
		CBaseEntity@ pEntity = null;
		TraceResult tr;
		float flAdjustedDamage;
		Vector vecSpot;

		Vector vecMid = (vecStart + vecEnd) * 0.5;

		float searchRadius = (vecStart - vecMid).Length();

		Vector vecAim = (vecEnd - vecStart).Normalize();

		while( (@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, vecMid, searchRadius, "*", "classname" ) ) !is null )
		{
			if( pEntity.pev.takedamage != DAMAGE_NO )
			{
				if( iClassIgnore != CLASS_NONE and pEntity.Classify() == iClassIgnore )
					continue;

				vecSpot = pEntity.BodyTarget( vecMid );

				float dist = DotProduct( vecAim, vecSpot - vecMid );
				if( dist > searchRadius )
					dist = searchRadius;
				else if( dist < -searchRadius )
					dist = searchRadius;

				Vector vecSrc = vecMid + dist * vecAim;

				g_Utility.TraceLine( vecSrc, vecSpot, dont_ignore_monsters, m_pDriveEnt.edict(), tr );

				if( tr.flFraction == 1.0 or tr.pHit is pEntity.edict() )
				{
					dist = (vecSrc - tr.vecEndPos).Length();

					if( dist > 64 )
					{
						flAdjustedDamage = flDamage - (dist - 64) * 0.4;
						if( flAdjustedDamage <= 0 )
							continue;
					}
					else
						flAdjustedDamage = flDamage;

					if( tr.flFraction != 1.0 )
					{
						g_WeaponFuncs.ClearMultiDamage();
						pEntity.TraceAttack( pevInflictor, flAdjustedDamage, (tr.vecEndPos - vecSrc).Normalize(), tr, bitsDamageType );
						g_WeaponFuncs.ApplyMultiDamage( pevInflictor, pevAttacker );
					}
					else
						pEntity.TakeDamage( pevInflictor, pevAttacker, flAdjustedDamage, bitsDamageType );
				}
			}
		}
	}

	void StopFlame()
	{
		FlameDestroy();
		FlameControls( 0, 0 );
		m_pDriveEnt.SetBoneController( 0, 0 );
		m_pDriveEnt.SetBoneController( 1, 0 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void StreakSplash( const Vector &in origin, const Vector &in direction, int color, int count, int speed, int velocityRange )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin );
			m1.WriteByte( TE_STREAK_SPLASH );
			m1.WriteCoord( origin.x );
			m1.WriteCoord( origin.y );
			m1.WriteCoord( origin.z );
			m1.WriteCoord( direction.x );
			m1.WriteCoord( direction.y );
			m1.WriteCoord( direction.z );
			m1.WriteByte( color );
			m1.WriteShort( count );
			m1.WriteShort( speed );
			m1.WriteShort( velocityRange );
		m1.End();
	}

	void DoAmmoRegen()
	{
		if( m_iState != STATE_FLAME and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < AMMO_FLAME_MAX )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + 1 );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void MeleeAE()
	{
		if( m_iState != STATE_MELEE or m_pDriveEnt.pev.sequence != ANIM_MELEE ) return;

		if( IsBetween2(GetFrame(55), 27, 29) and m_uiAnimationState == 0 ) { MeleeAttack(MELEE_RANGE, MELEE_DAMAGE, DMG_SLASH); m_uiAnimationState++; }
		else if( GetFrame(55) >= 38 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
	}

	void MeleeAttack( float flRange, int iDamage, int iDmgType, bool bKick = false )
	{
		if( m_pDriveEnt is null ) return;

		CBaseEntity@ pHurt = CheckTraceHullAttack( flRange, iDamage, iDmgType );
		if( pHurt !is null )
		{
			if( (pHurt.pev.flags & FL_MONSTER) != 0 or ((pHurt.pev.flags & FL_CLIENT) == 1 and CNPC::PVP) ) //and movetype isn't MOVETYPE_FLY ??
			{
				pHurt.pev.punchangle.x = -30; // pitch
				pHurt.pev.punchangle.y = -30;	// yaw
				pHurt.pev.punchangle.z = 30;	// roll

				if( bKick )
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 800 + g_Engine.v_up * 800;
				else
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 400 - g_Engine.v_right * 400 + g_Engine.v_up * 400;
			}

			if( bKick )
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_STEP1], VOL_NORM, 0.5, 0, 90 + Math.RandomLong(0, 15) );
			else
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MELEE_HIT1, SND_MELEE_HIT3)], VOL_NORM, ATTN_NORM, 0, 50 + Math.RandomLong(0, 15) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MELEE_MISS1, SND_MELEE_MISS2)], VOL_NORM, ATTN_NORM, 0, 50 + Math.RandomLong(0, 15) );
	}

	void CheckKickInput()
	{
		if( m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_JUMP) != 0 )
		{
			m_iState = STATE_KICK;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_KICK );
		}
	}

	void KickAE()
	{
		if( m_iState != STATE_KICK or m_pDriveEnt.pev.sequence != ANIM_KICK ) return;

		if( IsBetween2(GetFrame(23), 8, 10) and m_uiAnimationState == 0 ) { Kick(); m_uiAnimationState++; }
	}

	void Kick()
	{
		MeleeAttack( KICK_RANGE, KICK_DAMAGE, DMG_SLASH, true );
	}

	void CheckStompInput()
	{
		if( m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			m_iState = STATE_STOMP;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_STOMP );
		}
	}

	void StompAE()
	{
		if( m_iState != STATE_STOMP or m_pDriveEnt.pev.sequence != ANIM_STOMP ) return;

		if( IsBetween2(GetFrame(21), 18, 20) and m_uiAnimationState == 0 ) { StompAttack(); m_uiAnimationState++; }
	}

	void StompAttack()
	{
		TraceResult tr;

		Math.MakeVectors( m_pDriveEnt.pev.angles );
		Vector vecFootOffset = g_Engine.v_forward * 42 - g_Engine.v_right * 28;
		Vector vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + g_Engine.v_forward * 35;
		Vector vecEnd = vecStart + (g_Engine.v_forward * 1024);

		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );
		g_PlayerFuncs.ScreenShake( m_pDriveEnt.pev.origin, 12.0, 100.0, 2.0, 1000 );
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_STOMP], VOL_NORM, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-10, 10) );

		g_Utility.TraceLine( m_pDriveEnt.pev.origin + vecFootOffset, m_pDriveEnt.pev.origin - Vector(0, 0, 20), ignore_monsters, m_pDriveEnt.edict(), tr );

		if( tr.flFraction < 1.0 )
			g_Utility.DecalTrace( tr, DECAL_GARGSTOMP1 );
	}

	void StompCreate( const Vector &in origin, const Vector &in end, float speed )
	{
		CBaseEntity@ pStomp = g_EntityFuncs.Create( "garg_stomp_baby", origin, g_vecZero, true, m_pPlayer.edict() );

		Vector dir = (end - origin);
		pStomp.pev.scale = dir.Length();
		pStomp.pev.movedir = dir.Normalize();
		pStomp.pev.speed = speed;
		g_EntityFuncs.DispatchSpawn( pStomp.edict() );
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		vecOrigin.z -= CNPC_MODEL_OFFSET;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_babygarg", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );
		m_pDriveEnt.pev.set_controller( 0,  127 );
		m_pDriveEnt.pev.set_controller( 1,  127 );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;

		self.m_bExclusiveHold = true;

		if( CNPC_FIRSTPERSON )
		{
			SetRender( 1 ); //if it's 0 the flames start at the gargs feet
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
		}
		else
		{
			SetRender( 255 );
			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_BABYGARG );

		if( m_pDriveEnt !is null )
		{
			@m_pEyeGlow = g_EntityFuncs.CreateSprite( GARG_EYE_SPRITE, m_pDriveEnt.pev.origin, false );
			@m_pEyeGlow.pev.owner = m_pDriveEnt.edict();
			m_pEyeGlow.SetTransparency( kRenderGlow, 255, 255, 255, 0, kRenderFxNoDissipation );
			m_pEyeGlow.SetAttachment( m_pDriveEnt.edict(), 1 );
			m_pEyeGlow.pev.scale = 0.5;
			EyeOff();
		}
	}

	void SetRender( int iRenderAmount )
	{
		cnpc_babygarg@ pDriveEnt = cast<cnpc_babygarg@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		if( !pDriveEnt.m_hRenderEntity.IsValid() )
		{
			string szDriveEntTargetName = "cnpc_babygarg_rend_" + m_pPlayer.entindex();
			m_pDriveEnt.pev.targetname = szDriveEntTargetName;

			dictionary keys;
			keys[ "target" ] = szDriveEntTargetName;

			if( iRenderAmount < 255 )
				keys[ "rendermode" ] = "2"; //kRenderTransTexture
			else
				keys[ "rendermode" ] = "0"; //kRenderNormal

			keys[ "renderamt" ] = "" + iRenderAmount;
			keys[ "spawnflags" ] = "64"; //Affect Activator (ignore netname)

			CBaseEntity@ pRender = g_EntityFuncs.CreateEntity( "env_render_individual", keys );

			if( pRender !is null )
			{
				pRender.Use( m_pPlayer, pRender, USE_ON, 0.0 );
				pDriveEnt.m_hRenderEntity = EHandle( pRender );
			}			
		}
		else
		{
			if( iRenderAmount < 255 )
				pDriveEnt.m_hRenderEntity.GetEntity().pev.rendermode = 2;
			else
				pDriveEnt.m_hRenderEntity.GetEntity().pev.rendermode = 0;

			pDriveEnt.m_hRenderEntity.GetEntity().pev.renderamt = iRenderAmount;
		}
	}

	void ResetPlayer()
	{
		m_pPlayer.pev.iuser3 = 0; //enable ducking
		m_pPlayer.pev.fuser4 = 0; //enable jumping
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_babygarg : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

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
		//else
			//pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		RemoveEyeGlow();

		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.SUB_StartFadeOut) );
		pev.nextthink = g_Engine.time;
	}

	void RemoveEyeGlow()
	{
		CBaseEntity@ pEyeGlow = null;
		while( (@pEyeGlow = g_EntityFuncs.FindEntityByClassname(pEyeGlow, "env_sprite")) !is null )
		{
			if( pEyeGlow.pev.owner is self.edict() )
				break;
		}

		if( pEyeGlow !is null ) g_EntityFuncs.Remove( pEyeGlow );
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

	void UpdateOnRemove()
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		RemoveEyeGlow();

		BaseClass.UpdateOnRemove();
	}
}

final class info_cnpc_babygarg : CNPCSpawnEntity
{
	info_cnpc_babygarg()
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
		pev.set_controller( 1,  127 );
	}
}

//the base garg_stomp won't doesn't hit some monsters (eg: zombies and smaller)
class garg_stomp_baby : ScriptBaseEntity
{
	void Spawn()
	{
		pev.nextthink = g_Engine.time;
		pev.dmgtime = g_Engine.time;

		pev.framerate = 30;
		g_EntityFuncs.SetModel( self, GARG_EYE_SPRITE );
		pev.rendermode = kRenderTransTexture;
		pev.renderamt = 0;
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "weapons/mine_charge.wav", VOL_NORM, ATTN_NORM, 0, int(PITCH_NORM * 0.55) );
	}

	void Think()
	{
		TraceResult tr;

		pev.nextthink = g_Engine.time + 0.1;

		Vector vecStart = pev.origin;
		vecStart.z += 30;
		Vector vecEnd = vecStart + (pev.movedir * pev.speed * g_Engine.frametime);

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, human_hull, self.edict(), tr ); //head_hull is too small

		if( tr.pHit !is null and tr.pHit !is pev.owner )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			entvars_t@ pevOwner = pev;
			if( pev.owner !is null )
				@pevOwner = pev.owner.vars;

			if( pEntity !is null )
			{
				bool bDealDamage = true;
				if( pEntity.GetClassname() == "cnpc_garg" and pEntity.pev.owner !is null and pev.owner !is null )
				{
					if( pev.owner is pEntity.pev.owner ) 
						bDealDamage = false;
				}

				if( bDealDamage and (pEntity.pev.flags & FL_CLIENT) == 0 or ((pEntity.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
					pEntity.TakeDamage( pev, pevOwner, STOMP_DAMAGE, DMG_SONIC );
			}
		}

		pev.speed = pev.speed + (g_Engine.frametime) * pev.framerate;
		pev.framerate = pev.framerate + (g_Engine.frametime) * 1500;

		while( g_Engine.time - pev.dmgtime > 0.025 )
		{
			pev.origin = pev.origin + pev.movedir * pev.speed * 0.025;

			for( int i = 0; i < 2; i++ )
			{
				CSprite@ pSprite = g_EntityFuncs.CreateSprite( GARG_EYE_SPRITE, pev.origin, true );
				if( pSprite !is null )
				{
					g_Utility.TraceLine( pev.origin, pev.origin - Vector(0, 0, 500), ignore_monsters, self.edict(), tr );
					pSprite.pev.origin = tr.vecEndPos;
					pSprite.pev.velocity = Vector( Math.RandomFloat(-200, 200), Math.RandomFloat(-200, 200), 175 );
					pSprite.pev.nextthink = g_Engine.time + 0.3;
					pSprite.SetTransparency( kRenderTransAdd, 255, 255, 255, 255, kRenderFxFadeFast );
					pSprite.AnimateAndDie( Math.RandomFloat(2.0, 6.0) );
				}
			}

			pev.dmgtime += 0.025;

			pev.scale -= 0.025 * pev.speed;
			if( pev.scale <= 0 )
			{
				g_EntityFuncs.Remove(self);
				g_SoundSystem.StopSound( self.edict(), CHAN_BODY, "weapons/mine_charge.wav" ); 
			}
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_babygarg::garg_stomp_baby", "garg_stomp_baby" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_babygarg::info_cnpc_babygarg", "info_cnpc_babygarg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_babygarg::cnpc_babygarg", "cnpc_babygarg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_babygarg::weapon_babygarg", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "babygargflame" );

	g_Game.PrecacheOther( "info_cnpc_babygarg" );
	g_Game.PrecacheOther( "cnpc_babygarg" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_babygarg END

/* FIXME
*/

/* TODO
	Make a CreateEye function
*/
