namespace cnpc_garg
{
	
const bool CNPC_NPC_HITBOX		= true; //Use the hitbox of the monster model instead of the player. Experimental!
const bool CNPC_TRANSPARENT		= true; //should the garg be transparent in third person view?
const int CNPC_TRANS_AMOUNT		= 150;
const bool CNPC_DMGONDEATH		= true; //should the explosions deal damage when the garg dies?
bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_garg";
const string CNPC_MODEL				= "models/garg.mdl";
const Vector CNPC_SIZEMIN			= Vector( -32, -32, 0 );
const Vector CNPC_SIZEMAX			= Vector( 32, 32, 214 );

const float CNPC_HEALTH				= 1000.0;
const float CNPC_VIEWOFS_FPV		= 84.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 128.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the garg itself
const float CNPC_MODEL_OFFSET	= 32.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= -1;
const float SPEED_RUN					= -1;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const int GARG_DAMAGE				= (DMG_ENERGYBEAM|DMG_CRUSH|DMG_MORTAR|DMG_BLAST);
const string GARG_EYE_SPRITE		= "sprites/gargeye1.spr";
const string GARG_GIB_MODEL		= "models/metalplategibs.mdl";

const float CD_PRIMARY					= 1.0;
const float FLAME_DAMAGE			= 4.0;
const int FLAME_LENGTH				= 330;
const int AMMO_FLAME_MAX			= 100;
const string FLAME_SPRITE				= "sprites/xbeam3.spr";
const float AMMO_REGEN_RATE		= 0.1; //+1 per AMMO_REGEN_RATE seconds

const float CD_SECONDARY			= 1.5; //melee
const float MELEE_RANGE				= 90.0;
const float MELEE_DAMAGE			= 50.0;

const float CD_STOMP					= 1.0;
const float STOMP_SPEED				= 250.0;
const float STOMP_DAMAGE			= 100.0;

const float KICK_RANGE					= 90.0;
const float KICK_DAMAGE				= 50.0;

const int AMMO_BIRTH_MAX			= 100;
const int AMMO_FROM_FOOD			= 25;

const string GARG_FART_SPRITE		= "sprites/ballsmoke.spr";

const array<string> pPainSounds = 
{
	"garg/gar_pain1.wav",
	"garg/gar_pain2.wav",
	"garg/gar_pain3.wav"
};

const array<string> pDieSounds = 
{
	"garg/gar_die1.wav",
	"garg/gar_die2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"garg/gar_attack1.wav",
	"garg/gar_breathe1.wav",
	"garg/gar_breathe2.wav",
	"garg/gar_breathe3.wav",
	"garg/gar_step1.wav",
	"garg/gar_step2.wav",
	"garg/gar_flameoff1.wav",
	"garg/gar_flameon1.wav",
	"garg/gar_flamerun1.wav",
	"garg/gar_attack1.wav",
	"garg/gar_attack2.wav",
	"garg/gar_attack3.wav",
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav",
	"garg/gar_stomp1.wav",
	"garg/gar_idle3.wav",
	"bullchicken/bc_bite3.wav",
	"weapons/ric1.wav",
	"weapons/ric2.wav",
	"weapons/ric3.wav",
	"weapons/ric4.wav",
	"weapons/ric5.wav",
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
	SND_STOMP,
	SND_EAT1,
	SND_EAT2,
	SND_RIC1,
	SND_RIC5 = 25
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
	ANIM_BITE,
	ANIM_SMASH = 17,
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
	STATE_KICK,
	STATE_BITE,
	STATE_BIRTH
};

class weapon_garg : CBaseDriveWeapon
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

	private EHandle m_hBiteTarget;
	private CBaseEntity@ m_pBiteTarget
	{
		get const { return m_hBiteTarget.GetEntity(); }
		set { m_hBiteTarget = EHandle(@value); }
	}

	private float m_flBiteTargetBleed;
	private int m_iTargetBloodColor;

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
		g_Game.PrecacheModel( GARG_GIB_MODEL );
		g_Game.PrecacheModel( GARG_FART_SPRITE );
		g_Game.PrecacheModel( "sprites/zerogxplode.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_garg.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_garg.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_garg_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= AMMO_FLAME_MAX;
		info.iMaxAmmo2	= AMMO_BIRTH_MAX;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::GARG_SLOT - 1;
		info.iPosition			= CNPC::GARG_POSITION - 1;
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
			spawnDriveEnt();
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

		FlameDestroy();

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
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt is null or m_iState >= STATE_FLAME or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
		{
			m_iState = STATE_MELEE;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_MELEE );
		}
		else
		{
			if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) < AMMO_BIRTH_MAX )
			{
				m_iState = STATE_BITE;
				m_pPlayer.SetMaxSpeedOverride( 0 );
				SetAnim( ANIM_BITE );

				if( m_pBiteTarget !is null )
					@m_pBiteTarget = null;
			}
			else
			{
				TraceResult tr;
				Vector vecOrigin;
				g_EngineFuncs.GetBonePosition( m_pDriveEnt.edict(), 1, vecOrigin, void );

				Math.MakeVectors( m_pDriveEnt.pev.angles );
				g_Utility.TraceHull( vecOrigin, vecOrigin + g_Engine.v_forward * -128, dont_ignore_monsters, head_hull, m_pDriveEnt.edict(), tr );

				if( tr.flFraction == 1.0 )
				{
					m_iState = STATE_BIRTH;
					m_pPlayer.SetMaxSpeedOverride( 0 );
					SetAnim( ANIM_BITE );
				}
			}
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
	}

	void TertiaryAttack()
	{
		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;

		if( m_pDriveEnt is null ) return;

		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			SetRender( 1 ); //if it's 0 the flames start at the gargs feet
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			if( CNPC_TRANSPARENT )
				SetRender( CNPC_TRANS_AMOUNT );
			else
				SetRender( 255 );

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

			DoEyeGlow();
			DoFlame();
			DoAmmoRegen();
			MeleeAE();
			CheckStompInput();
			StompAE();
			CheckKickInput();
			KickAE();
			BiteAE();
			MoveBiteTarget();
			
			BirthAE();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( CNPC_NPC_HITBOX )
		{
			m_pPlayer.pev.solid = SOLID_NOT;
			m_pPlayer.pev.flags |= FL_NOTARGET;
		}

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
		g_PlayerFuncs.ScreenShake( m_pDriveEnt.pev.origin, 4.0, 3.0, 1.0, 750 );
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
			if( m_iState == STATE_BITE and m_pDriveEnt.pev.sequence == ANIM_BITE and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_BIRTH and m_pDriveEnt.pev.sequence == ANIM_BITE and !m_pDriveEnt.m_fSequenceFinished ) return;
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
					else if( IsBetween2(GetFrame(31), 17, 19) and m_uiAnimationState >= 1 ) { m_uiAnimationState = 0; }
				}
				else if( m_pDriveEnt.pev.sequence == ANIM_IDLE_FIDGET )
				{
					if( IsBetween2(GetFrame(66), 6, 8) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
					else if( IsBetween2(GetFrame(66), 16, 18) and m_uiAnimationState >= 1 ) { m_uiAnimationState = 0; }
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
				m_hFlame[i] = EHandle( g_EntityFuncs.CreateBeam(FLAME_SPRITE, 240) );
			else
				m_hFlame[i] = EHandle( g_EntityFuncs.CreateBeam(FLAME_SPRITE, 140) );

			if( m_hFlame[i].IsValid() )
			{
				int attach = i%2;
				g_EngineFuncs.GetAttachment( m_pDriveEnt.edict(), attach+1, vecGun, void );

				Vector vecEnd = (g_Engine.v_forward * FLAME_LENGTH) + vecGun;
				g_Utility.TraceLine( vecGun, vecEnd, dont_ignore_monsters, m_pDriveEnt.edict(), tr );

				m_pFlame(i).PointEntInit( tr.vecEndPos, m_pDriveEnt.entindex() );

				if( i < 2 )
					m_pFlame(i).SetColor( 255, 130, 90 );
				else
					m_pFlame(i).SetColor( 0, 120, 255 );

				m_pFlame(i).SetBrightness( 190 );
				m_pFlame(i).SetFlags( BEAM_FSHADEIN );
				m_pFlame(i).SetScrollRate( 20 );
				// attachment is 1 based in SetEndAttachment
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
				// UNDONE: this should check a damage mask, not an ignore
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
				{// the explosion can 'see' this entity, so hurt them!
					// decrease damage for an ent that's farther from the flame.
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

	CBaseEntity@ GargantuaCheckTraceHullAttack( float flDist, int iDamage, int iDmgType )
	{
		TraceResult tr;

		Math.MakeVectors( m_pDriveEnt.pev.angles );
		Vector vecStart = m_pDriveEnt.pev.origin;
		vecStart.z += 64;
		Vector vecEnd = vecStart + (g_Engine.v_forward * flDist) - (g_Engine.v_up * flDist * 0.3);

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

		if( tr.pHit !is null and tr.pHit !is m_pDriveEnt.edict() )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( iDamage > 0 )
				pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, iDamage, iDmgType );

			return pEntity;
		}

		return null;
	}

	void MeleeAE()
	{
		if( m_iState != STATE_MELEE or m_pDriveEnt.pev.sequence != ANIM_MELEE ) return;

		if( IsBetween2(GetFrame(55), 27, 29) and m_uiAnimationState == 0 ) { MeleeAttack(MELEE_RANGE, MELEE_DAMAGE, DMG_SLASH); m_uiAnimationState++; }
		else if( IsBetween2(GetFrame(55), 37, 39) and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
	}

	void MeleeAttack( float flRange, int iDamage, int iDmgType )
	{
		if( m_pDriveEnt is null ) return;

		CBaseEntity@ pHurt = GargantuaCheckTraceHullAttack( flRange, iDamage, iDmgType );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = -30; // pitch
				pHurt.pev.punchangle.y = -30;	// yaw
				pHurt.pev.punchangle.z = 30;	// roll

				if( iDmgType == DMG_SLASH )
					pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * 100;
				else
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 500;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MELEE_HIT1, SND_MELEE_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MELEE_MISS1, SND_MELEE_MISS2)], VOL_NORM, ATTN_NORM, 0, 50 + Math.RandomLong(0, 15) );
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
		Vector vecFootOffset = g_Engine.v_forward * 80 - g_Engine.v_right * 30;
		Vector vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + g_Engine.v_forward * 35;
		Vector vecEnd = vecStart + (g_Engine.v_forward * 1024);

		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );
		//SuperStompCreate(); //hurrdurr
		g_PlayerFuncs.ScreenShake( m_pDriveEnt.pev.origin, 12.0, 100.0, 2.0, 1000 );
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_STOMP], VOL_NORM, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-10, 10) );

		g_Utility.TraceLine( m_pDriveEnt.pev.origin + vecFootOffset, m_pDriveEnt.pev.origin - Vector(0, 0, 20), ignore_monsters, m_pDriveEnt.edict(), tr );

		if( tr.flFraction < 1.0 )
			g_Utility.DecalTrace( tr, DECAL_GARGSTOMP1 );
	}

	/*void SuperStompCreate()
	{
		TraceResult tr;
		Vector vecFootOffset = g_Engine.v_forward * 80 - g_Engine.v_right * 30;

		Math.MakeVectors( m_pDriveEnt.pev.angles );
		Vector vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		Vector vecEnd = vecStart + (g_Engine.v_forward * 1024);
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );

		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart - (g_Engine.v_forward * 1024);
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );

		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart + (g_Engine.v_right * 1024);
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );

		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart - (g_Engine.v_right * 1024);
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );


		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart + g_Engine.v_forward * 1024 + g_Engine.v_right * 1024;
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );

		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart - g_Engine.v_forward * 1024 + g_Engine.v_right * 1024;
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );

		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart - g_Engine.v_forward * 1024 - g_Engine.v_right * 1024;
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );

		vecStart = m_pDriveEnt.pev.origin + Vector(0, 0, 60) + vecFootOffset;
		vecEnd = vecStart + g_Engine.v_forward * 1024 - g_Engine.v_right * 1024;
		g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pDriveEnt.edict(), tr );
		StompCreate( vecStart, tr.vecEndPos, STOMP_SPEED );
	}*/

	void StompCreate( const Vector &in origin, const Vector &in end, float speed )
	{
		CBaseEntity@ pStomp = g_EntityFuncs.Create( "garg_stomp_custom", origin, g_vecZero, true, m_pPlayer.edict() );

		Vector dir = (end - origin);
		pStomp.pev.scale = dir.Length();
		pStomp.pev.movedir = dir.Normalize();
		pStomp.pev.speed = speed;
		g_EntityFuncs.DispatchSpawn( pStomp.edict() );
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
		MeleeAttack( KICK_RANGE, KICK_DAMAGE, DMG_CRUSH );
	}

	void BiteAE()
	{
		if( m_iState != STATE_BITE or m_pDriveEnt.pev.sequence != ANIM_BITE ) return;

		if( IsBetween2(GetFrame(67), 10, 12) and m_uiAnimationState == 0 ) { BiteFirst(); m_uiAnimationState++; }
		else if( IsBetween2(GetFrame(67), 30, 32) and m_uiAnimationState == 1 ) { g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[0], VOL_NORM, ATTN_NORM ); m_uiAnimationState++; }
		else if( IsBetween2(GetFrame(67), 36, 38) and m_uiAnimationState == 2 ) { BiteSecond(); m_uiAnimationState++; }
		else if( IsBetween2(GetFrame(67), 56, 58) and m_uiAnimationState == 3 ) { BiteThird(); m_uiAnimationState++; }
	}

	void BiteFirst()
	{
		FootStep();

		CBaseEntity@ pHurt = GargantuaCheckTraceHullAttack( 144.0 * m_pDriveEnt.pev.scale, 1, DMG_SLASH );

		if( pHurt !is null and (pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP)) and pHurt.IsAlive() and pHurt.pev.health <= (pHurt.pev.max_health * 0.5) )
		{
			@m_pBiteTarget = pHurt;
			m_pBiteTarget.pev.movetype = MOVETYPE_NOCLIP;
			m_pBiteTarget.pev.gravity = 0.0;
			m_pBiteTarget.pev.solid = SOLID_NOT;
			m_pBiteTarget.pev.flags |= FL_FLY;

			if( pHurt.pev.FlagBitSet(FL_CLIENT) )
			{
				CBasePlayer@ pTarget = cast<CBasePlayer@>( pHurt );
				pTarget.m_afPhysicsFlags |= PFLAG_ONBARNACLE; 
			}
			else
			{
				CBaseMonster@ pMonster = pHurt.MyMonsterPointer();
				pMonster.SetState( MONSTERSTATE_PLAYDEAD );
				pMonster.Stop();
			}

			m_iTargetBloodColor = pHurt.BloodColor();
		}
		else
			DoIdleAnimation( true );
	}

	void BiteSecond()
	{
		if( m_pBiteTarget is null or m_pBiteTarget.pev.deadflag != DEAD_NO )
		{
			DoIdleAnimation( true );
			return;
		}

		if( m_pBiteTarget.pev.FlagBitSet(FL_CLIENT) )
		{
			CBasePlayer@ pTarget = cast<CBasePlayer@>( m_pBiteTarget );
			if( pTarget is null or !pTarget.IsConnected() )
			{
				DoIdleAnimation( true );
				return;
			}
		}

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_EAT1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-10, 10) );

		Vector vecOrigin;
		g_EngineFuncs.GetBonePosition( m_pDriveEnt.edict(), 22, vecOrigin, void );
		g_Utility.BloodDrips( vecOrigin, g_vecZero, m_iTargetBloodColor, 600 );
		g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), vecOrigin, arrsCNPCSounds[SND_EAT2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); 

		m_pBiteTarget.Killed( m_pPlayer.pev, GIB_ALWAYS );
		@m_pBiteTarget = null;

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) + AMMO_FROM_FOOD );
	}

	void BiteThird()
	{
		Vector vecOrigin;
		g_EngineFuncs.GetBonePosition( m_pDriveEnt.edict(), 22, vecOrigin, void );
		g_Utility.BloodDrips( vecOrigin, g_vecZero, m_iTargetBloodColor, 600 );
	}

	void MoveBiteTarget()
	{
		if( m_iState != STATE_BITE or m_pDriveEnt.pev.sequence != ANIM_BITE ) return;
		if( m_pBiteTarget is null or m_pBiteTarget.pev.deadflag != DEAD_NO ) return;

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( 0, vecOrigin, void );
		vecOrigin.z -= 16.0;

		if( m_flBiteTargetBleed <= g_Engine.time )
		{
			m_flBiteTargetBleed = g_Engine.time + 0.5;
			g_Utility.BloodDrips( vecOrigin, g_vecZero, m_pBiteTarget.BloodColor(), 100 );
		}

		if( m_pBiteTarget.pev.FlagBitSet(FL_CLIENT) )
		{
			CBasePlayer@ pTarget = cast<CBasePlayer@>( m_pBiteTarget );
			if( pTarget is null or !pTarget.IsConnected() or pTarget.pev.deadflag != DEAD_NO )
			{
				DoIdleAnimation( true );
				return;
			}

			pTarget.m_afPhysicsFlags |= PFLAG_ONBARNACLE; 
		}
		else
		{
			CBaseMonster@ pMonster = m_pBiteTarget.MyMonsterPointer();
			pMonster.SetState( MONSTERSTATE_PLAYDEAD );
			pMonster.Stop();
			vecOrigin.z -= m_pBiteTarget.pev.size.z;
		}

		g_EntityFuncs.SetOrigin( m_pBiteTarget, vecOrigin );
	}

	void BirthAE()
	{
		if( m_iState != STATE_BIRTH or m_pDriveEnt.pev.sequence != ANIM_BITE ) return;

		if( IsBetween2(GetFrame(67), 10, 12) and m_uiAnimationState == 0 ) { GiveBirth(); m_uiAnimationState++; }
		else if( IsBetween2(GetFrame(67), 13, 15) and m_uiAnimationState == 1 ) { DoIdleAnimation(true); m_uiAnimationState++; }
	}

	void GiveBirth()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[2], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		g_EngineFuncs.GetBonePosition( m_pDriveEnt.edict(), 1, vecOrigin, void );

		Math.MakeVectors( m_pDriveEnt.pev.angles );
		vecOrigin = vecOrigin - g_Engine.v_forward * 92;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(GARG_FART_SPRITE) );
			m1.WriteByte( 20 ); //scale
			m1.WriteByte( 20 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		vecOrigin.z -= 48;
		CBaseEntity@ pBabygarg = g_EntityFuncs.Create( "monster_babygarg", vecOrigin, m_pDriveEnt.pev.angles, true );
		pBabygarg.pev.angles.y -= 180;
		g_EntityFuncs.DispatchKeyValue( pBabygarg.edict(), "is_player_ally", "1" );
		g_EntityFuncs.DispatchSpawn( pBabygarg.edict() );

		float flGravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
		pBabygarg.pev.velocity = g_Engine.v_forward * -200;
		pBabygarg.pev.velocity.z += (0.6 * flGravity) * 0.5;
		pBabygarg.pev.targetname = "tempgarg";
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 0 );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_garg", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );
		m_pDriveEnt.pev.set_controller( 0,  127 );
		m_pDriveEnt.pev.set_controller( 1,  127 );

		if( CNPC_NPC_HITBOX )
		{
			m_pPlayer.pev.solid = SOLID_NOT;
			m_pPlayer.pev.flags |= FL_NOTARGET;
		}

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
			if( CNPC_TRANSPARENT )
				SetRender( CNPC_TRANS_AMOUNT );
			else
				SetRender( 255 );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 256\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_GARG );

		if( m_pDriveEnt !is null )
		{
			@m_pEyeGlow = g_EntityFuncs.CreateSprite( GARG_EYE_SPRITE, m_pDriveEnt.pev.origin, false );
			@m_pEyeGlow.pev.owner = m_pDriveEnt.edict();
			m_pEyeGlow.SetTransparency( kRenderGlow, 255, 255, 255, 255, kRenderFxNoDissipation );
			m_pEyeGlow.SetAttachment( m_pDriveEnt.edict(), 1 );
			EyeOff();
		}
	}

	void SetRender( int iRenderAmount )
	{
		cnpc_garg@ pDriveEnt = cast<cnpc_garg@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		if( !pDriveEnt.m_hRenderEntity.IsValid() )
		{
			string szDriveEntTargetName = "cnpc_garg_rend_" + m_pPlayer.entindex();
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

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_garg : ScriptBaseMonsterEntity//ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players
	private float m_flPainSoundTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		if( CNPC_NPC_HITBOX )
		{
			pev.solid = SOLID_SLIDEBOX;
			pev.movetype = MOVETYPE_STEP;
			pev.flags |= FL_MONSTER;
			pev.deadflag = DEAD_NO;
			pev.takedamage = DAMAGE_AIM;
			pev.max_health = CNPC_HEALTH;
			pev.health = CNPC_HEALTH;
			self.m_bloodColor = BLOOD_COLOR_GREEN;
			self.m_FormattedName = "CNPC Gargantua";
			//g_EntityFuncs.DispatchKeyValue( self.edict(), "displayname", "CNPC Gargantua" );
		}
		else
		{
			pev.solid = SOLID_NOT;
			pev.movetype = MOVETYPE_NOCLIP;
		}

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flNextOriginUpdate = g_Engine.time;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	int BloodColor() { return BLOOD_COLOR_YELLOW; }

	int Classify()
	{
		if( !CNPC_NPC_HITBOX ) return CLASS_NONE;

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

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if( CNPC_NPC_HITBOX )
		{
			if( (bitsDamageType & GARG_DAMAGE) == 0 )
				flDamage *= 0.01;

			if( (bitsDamageType & DMG_BLAST) != 0 )
				self.SetConditions( bits_COND_LIGHT_DAMAGE );

			pev.health -= flDamage;

			if( m_pOwner !is null and m_pOwner.IsConnected() )
				m_pOwner.pev.health = pev.health;

			if( pev.health <= 0 )
			{
				if( m_pOwner !is null and m_pOwner.IsConnected() )
					m_pOwner.Killed( pevAttacker, GIB_NEVER );

				pev.health = 0;
				pev.takedamage = DAMAGE_NO;
				//DoDeath();

				return 0;
			}

			pevAttacker.frags += self.GetPointsForDamage( flDamage );

			return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		}

		return 0;
	}

	void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType )
	{
		if( CNPC_NPC_HITBOX )
		{
			if( !self.IsAlive() )
			{
				BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
				return;
			}

			if( bitsDamageType & (GARG_DAMAGE|DMG_BLAST) != 0 )
			{
				if( m_flPainSoundTime < g_Engine.time )
				{
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0, pPainSounds.length() - 1)], VOL_NORM, ATTN_NORM );
					m_flPainSoundTime = g_Engine.time + Math.RandomFloat( 2.5, 4.0 );
				}
			}

			bitsDamageType &= GARG_DAMAGE;

			if( bitsDamageType == 0 )
			{
				if( pev.dmgtime != g_Engine.time or (Math.RandomLong(0, 100) < 20) )
				{
					g_Utility.Ricochet( ptr.vecEndPos, Math.RandomFloat(0.5, 1.5) );
					pev.dmgtime = g_Engine.time;

					if( Math.RandomLong(0, 100) < 25 )
						g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_RIC1, SND_RIC5)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				}

				flDamage = 0;
			}

			BaseClass.TraceAttack( pevAttacker, flDamage, vecDir, ptr, bitsDamageType );
		}
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		if( pev.deadflag != DEAD_DEAD )
		{
			pev.deadflag = DEAD_DEAD;
			DoDeath();
		}
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			Killed( null, GIB_NEVER );

			return;
		}

		if( m_flNextOriginUpdate < g_Engine.time )
		{
			Vector vecOrigin = m_pOwner.pev.origin;
			vecOrigin.z -= CNPC_MODEL_OFFSET;
			g_EntityFuncs.SetOrigin( self, vecOrigin );
			m_flNextOriginUpdate = g_Engine.time + CNPC_ORIGINUPDATE;
		}

		pev.scale = m_pOwner.pev.scale;
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

	void DoDeath()
	{
		pev.velocity = g_vecZero;
		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time + 1.6;

		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();
		DeathEffect();
	}

	void DieThink()
	{
		RemoveEyeGlow();

		pev.renderfx = kRenderFxExplode;
		pev.rendercolor.x = 255;
		pev.rendercolor.y = 0;
		pev.rendercolor.z = 0;
		pev.framerate = 0;
		pev.nextthink = g_Engine.time + 0.15;
		SetThink( ThinkFunction(this.SUB_Remove) );

		int parts = g_EngineFuncs.ModelFrames( g_EngineFuncs.ModelIndex(GARG_GIB_MODEL) );

		for( int i = 0; i < 10; i++ )
		{
			CGib@ pGib = g_EntityFuncs.CreateGib( pev.origin, g_vecZero );

			pGib.Spawn( GARG_GIB_MODEL );

			int bodyPart = 0;
			if( parts > 1 )
				bodyPart = Math.RandomLong( 0, pev.body-1 );

			pGib.pev.body = bodyPart;
			pGib.m_bloodColor = BLOOD_COLOR_YELLOW;
			pGib.m_material = matNone;
			pGib.pev.origin = pev.origin;
			pGib.pev.velocity = g_Utility.RandomBloodVector() * Math.RandomFloat( 300, 500 );
			pGib.pev.nextthink = g_Engine.time + 1.25;
			pGib.m_lifeTime = 1.25;
			//pGib.SetThink( ThinkFunction(pGib.SUB_FadeOut) );
		}

		NetworkMessage gib( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			gib.WriteByte( TE_BREAKMODEL );
			gib.WriteCoord( pev.origin.x ); // position
			gib.WriteCoord( pev.origin.y );
			gib.WriteCoord( pev.origin.z );
			gib.WriteCoord( 200 ); // size
			gib.WriteCoord( 200 );
			gib.WriteCoord( 128 );
			gib.WriteCoord( 0 ); // velocity
			gib.WriteCoord( 0 );
			gib.WriteCoord( 0 );
			gib.WriteByte( 200 ); // randomization
			gib.WriteShort( g_EngineFuncs.ModelIndex(GARG_GIB_MODEL) ); //model id#
			gib.WriteByte( 50 ); // # of shards
			gib.WriteByte( 20 ); // duration (3.0 seconds)
			gib.WriteByte( BREAK_FLESH ); // flags
		gib.End();
	}

	void DeathEffect()
	{
		Math.MakeVectors( pev.angles );
		Vector deathPos = pev.origin + g_Engine.v_forward * 100;

		CreateSpiral( deathPos, (pev.absmax.z - pev.absmin.z) * 0.6, 125, 1.5 );

		Vector position = pev.origin;
		position.z += 32;

		for( int i = 0; i < 7; i += 2 )
		{
			SpawnExplosion( position, 70, (i * 0.3), 60 + (i*20) );
			position.z += 15;
		}

		CBaseEntity@ pSmoker = g_EntityFuncs.Create( "env_smoker", pev.origin, g_vecZero, false );
		pSmoker.pev.health = 1; //1 smoke balls
		pSmoker.pev.scale = 46; //4.6X normal size
		pSmoker.pev.dmg = 0; //0 radial distribution
		pSmoker.pev.nextthink = g_Engine.time + 2.5; //Start in 2.5 seconds
	}

	void SpawnExplosion( Vector center, float randomRange, float time, int magnitude )
	{
		center.x += Math.RandomFloat( -randomRange, randomRange );
		center.y += Math.RandomFloat( -randomRange, randomRange );

		CBaseEntity@ cbeExplosion = g_EntityFuncs.Create( "cnpc_garg_explosion", center, g_vecZero, true );
		cnpc_garg_explosion@ pExplosion = cast<cnpc_garg_explosion@>(CastToScriptClass(cbeExplosion));
		pExplosion.m_iMagnitude = magnitude;
		pExplosion.pev.nextthink = g_Engine.time + time;
		g_EntityFuncs.DispatchSpawn( pExplosion.self.edict() );
	}

	void CreateSpiral( const Vector &in origin, float height, float radius, float duration )
	{
		if( duration <= 0 )
			return;

		CBaseEntity@ pSpiral = g_EntityFuncs.Create( "streak_spiral", origin, g_vecZero, false );
		pSpiral.pev.dmgtime = pSpiral.pev.nextthink;
		pSpiral.pev.scale = radius;
		pSpiral.pev.dmg = height;
		pSpiral.pev.speed = duration;
		pSpiral.pev.health = 0;
		//g_EntityFuncs.DispatchSpawn( pSpiral.edict() );
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

final class info_cnpc_garg : CNPCSpawnEntity
{
	info_cnpc_garg()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
		m_flSpawnOffset = CNPC_MODEL_OFFSET + 4.0;
	}

	void DoSpecificStuff()
	{
		pev.set_controller( 0,  127 );
		pev.set_controller( 1,  127 );
	}
}

final class cnpc_garg_explosion : ScriptBaseEntity
{
	int m_iMagnitude;

	void Spawn()
	{
		SetThink( ThinkFunction(this.ExplodeThink) );
	}

	void ExplodeThink()
	{
		float flSpriteScale = (m_iMagnitude - 50) * 0.6;
		if( flSpriteScale < 10 )
			flSpriteScale = 10;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/zerogxplode.spr") );
			m1.WriteByte( int(flSpriteScale) ); //scale
			m1.WriteByte( 15 ); //framerate
			m1.WriteByte( 0 );
		m1.End();

		if( CNPC_DMGONDEATH )
			g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, self.pev, m_iMagnitude, m_iMagnitude * 2.5, CLASS_NONE, DMG_BLAST );

		g_EntityFuncs.Remove( self );
	}
}

//the base garg_stomp won't doesn't hit some monsters (eg: zombies and smaller)
class garg_stomp_custom : ScriptBaseEntity
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
					//pSprite.SetThink( ThinkFunction(self.SUB_Remove) );
					pSprite.SetTransparency( kRenderTransAdd, 255, 255, 255, 255, kRenderFxFadeFast );
					pSprite.AnimateAndDie( Math.RandomFloat(2.0, 6.0) );
				}
			}

			pev.dmgtime += 0.025;
			// Scale has the "life" of this effect
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_garg::garg_stomp_custom", "garg_stomp_custom" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_garg::cnpc_garg_explosion", "cnpc_garg_explosion" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_garg::info_cnpc_garg", "info_cnpc_garg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_garg::cnpc_garg", "cnpc_garg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_garg::weapon_garg", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "gargflame", "babygargs" );

	g_Game.PrecacheOther( "info_cnpc_garg" );
	g_Game.PrecacheOther( "cnpc_garg" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
	g_Game.PrecacheMonster( "monster_babygarg", true );
	g_Game.PrecacheMonster( "monster_babygarg", false );
}

} //namespace cnpc_garg END

/* FIXME
	The flame beams will point in the wrong direction if the player spins the camera around 
*/

/* TODO
*/