//hwrobo.mdl by Garompa

namespace cnpc_hwrgrunt
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_hwrgrunt";
const string CNPC_MODEL				= "models/hwrgrunt.mdl";
const string MODEL_VIEW				= "models/v_minigun.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 200.0;
const float CNPC_LOWHEALTH			= 40.0; //when to trigger low-health mode
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the hwrgrunt itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (37.280136 * CNPC::flModelToGameSpeedModifier) * 1.6;
const float SPEED_RUN					= (83.127602 * CNPC::flModelToGameSpeedModifier);
const float VELOCITY_WALK			= 75.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 0.08;
const float DAMAGE_MINIGUN			= 15;

const int AMMO_MINIGUN				= 600;

const int AMMO_REGEN_AMOUNT	= 3;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds

const float DMG_SHOCKTOUCH		= 125.0;

const string SMOKE_SPRITE			= "sprites/steam1.spr";
const float EXPLODE_DAMAGE			= 125.0;
const string GIB_MODEL1				= "models/computergibs.mdl";
const string GIB_MODEL2				= "models/chromegibs.mdl";

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"hassault/hw_spinup.wav",
	"hassault/hw_spin.wav",
	"hassault/hw_shoot2.wav",
	"hassault/hw_spindown.wav",
	"turret/tu_die.wav",
	"turret/tu_die2.wav",
	"buttons/spark5.wav",
	"buttons/spark6.wav",
	"debris/beamstart14.wav",
	"debris/metal6.wav"
};

enum sound_e
{
	SND_SPINUP = 1,
	SND_SPIN,
	SND_SHOOT,
	SND_SPINDOWN,
	SND_DEATH1,
	SND_DEATH2,
	SND_SPARK1,
	SND_SPARK2,
	SND_SHOCK,
	SND_REPAIR
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK = 2,
	ANIM_RUN,
	ANIM_SHOOT = 6,
	ANIM_SPINUP,
	ANIM_SPINDOWN,
	ANIM_DEATH1 = 11,
	ANIM_DEATH2,
	ANIM_DEATH3
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_SPINUP,
	STATE_SHOOT,
	STATE_SPINDOWN
};

class weapon_hwrgrunt : CBaseDriveWeapon
{
	int m_iVoicePitch;
	private int m_iShell;
	private float m_flNextAmmoRegen;

	private float m_flNextThink; //for stuff that shouldn't run every frame

	bool m_bShockTouch;
	private float m_flNextShockTouch;
	private float m_flNextSpark;
	private bool m_bDoubleSpark;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_bShockTouch = false;
		m_flNextShockTouch = g_Engine.time;
		m_flNextSpark = g_Engine.time + 1.0;
		m_bDoubleSpark = false;

		m_iVoicePitch = 115;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( SMOKE_SPRITE );
		g_Game.PrecacheModel( GIB_MODEL1 );
		g_Game.PrecacheModel( GIB_MODEL2 );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_hwrgrunt.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_hwrgrunt.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_hwrgrunt_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		if( m_iMaxAmmo == 0 ) m_iMaxAmmo = AMMO_MINIGUN;

		info.iMaxAmmo1	= m_iMaxAmmo;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::HWRGRUNT_SLOT - 1;
		info.iPosition			= CNPC::HWRGRUNT_POSITION - 1;
		info.iFlags 				= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
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

		self.m_iDefaultAmmo = GetMaxAmmo();
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, GetMaxAmmo() );

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);
		if( m_flFireRate <= 0.0 ) m_flFireRate = CD_PRIMARY;

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
		}

		return self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), "", 4, "" );
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
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.15;
				return;
			}

			if( m_iState < STATE_SPINUP )
			{
				m_iState = STATE_SHOOT;
				m_pPlayer.SetMaxSpeedOverride( 0 );
				SetAnim( ANIM_SPINUP );

				if( CNPC_FIRSTPERSON )
					self.SendWeaponAnim( 6 );

				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SPINUP], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
				return;
			}
			else if( m_iState == STATE_SHOOT )
			{
				if( m_pDriveEnt.pev.sequence != ANIM_SHOOT )
					SetAnim( ANIM_SHOOT );

				if( CNPC_FIRSTPERSON )
					self.SendWeaponAnim( 9 );

				Shoot();

				self.m_flNextPrimaryAttack = g_Engine.time + m_flFireRate;
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}
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
			self.SendWeaponAnim( 4 );
		}
		else
		{
			cnpc_hwrgrunt@ pDriveEnt = cast<cnpc_hwrgrunt@>(CastToScriptClass(m_pDriveEnt));
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

			DoAiming();
			StopShooting();
			DoAmmoRegen();

			if( m_flNextThink <= g_Engine.time )
			{
				LowHealth();
				DoShockTouch();
				m_flNextThink = g_Engine.time + 0.1;
			}
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState > STATE_RUN ) return;

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

			m_pDriveEnt.pev.framerate = 1.7; //the walking animation is too slow
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
		if( (m_pDriveEnt.pev.sequence >= ANIM_SPINUP or m_pDriveEnt.pev.sequence == ANIM_SPINDOWN) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_SHOOT ) return;

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
		}
	}

	void IdleSound()
	{
		if( CNPC::g_flTalkWaitTime > g_Engine.time ) return;

		if( CNPC::g_iRobotGruntQuestion != 0 or Math.RandomLong(0, 1) == 1 )
		{
			if( CNPC::g_iRobotGruntQuestion == 0 )
			{
				switch( Math.RandomLong(0, 2) )
				{
					case 0: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_CHECK", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iRobotGruntQuestion = 1; break; }
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_QUEST", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iRobotGruntQuestion = 2; break; }
					case 2: {g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_IDLE", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); break; }
				}
			}
			else
			{
				switch( CNPC::g_iRobotGruntQuestion )
				{
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_CLEAR", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); break; }
					case 2: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_ANSWER", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); break;}
				}

				CNPC::g_iRobotGruntQuestion = 0;
			}

			CNPC::g_flTalkWaitTime = g_Engine.time + Math.RandomFloat( 1.5, 2.0 );
		}
	}

	void Shoot()
	{
		Vector vecShootOrigin, vecShootDir;

		m_pDriveEnt.GetAttachment( 0, vecShootOrigin, void );

		Vector vecAngle = m_pPlayer.pev.v_angle;
		if( vecAngle.x < -40.0 )
			vecAngle.x = -40.0;

		Math.MakeVectors( vecAngle );
		vecShootDir = g_Engine.v_forward;

		self.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_4DEGREES, 4096.0, BULLET_PLAYER_CUSTOMDAMAGE, 4, DAMAGE_MINIGUN, m_pPlayer.pev );
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5) );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 1536, 0.3, m_pPlayer ); 

		Vector vecShellOrigin;
		m_pDriveEnt.GetAttachment( 1, vecShellOrigin, void );
		Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);

		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
	}

	void DoAiming()
	{
		if( !IsBetween2(m_iState, STATE_SPINUP, STATE_SPINDOWN) ) return;

		Vector angDir = Math.VecToAngles( g_Engine.v_forward );
		m_pDriveEnt.SetBlending( 0, angDir.x );
	}

	void StopShooting()
	{
		if( m_iState < STATE_SPINUP or m_iState == STATE_SPINDOWN ) return;

		if( ((m_iState == STATE_SPINUP or m_iState == STATE_SHOOT) and (m_pPlayer.pev.button & IN_ATTACK) == 0) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			m_iState = STATE_SPINDOWN;
			SetAnim( ANIM_SPINDOWN );

			if( CNPC_FIRSTPERSON )
				self.SendWeaponAnim( 7 );

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SPINDOWN], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.4;
		}
	}

	void DoAmmoRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( m_iState < STATE_SPINUP and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < m_iMaxAmmo )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + AMMO_REGEN_AMOUNT );
				if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > m_iMaxAmmo )
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_iMaxAmmo );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void LowHealth()
	{
		if( m_pPlayer.pev.health <= CNPC_LOWHEALTH and m_pDriveEnt.pev.deadflag != DEAD_DEAD )
		{
			Vector vecSrc = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), Math.RandomFloat(pev.origin.z, pev.absmax.z) );

			if( m_flNextSpark - 0.1 <= g_Engine.time and m_bDoubleSpark )
			{
				g_Utility.Sparks( vecSrc );
				m_bDoubleSpark = false;
			}

			if( m_flNextSpark + Math.RandomFloat(0, 1) <= g_Engine.time )
			{
				g_Utility.Sparks( vecSrc );
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_SPARK1, SND_SPARK2)], 0.5, ATTN_NORM, 0, 95 + Math.RandomLong(0, 10) );

				m_flNextSpark = g_Engine.time + 0.3;
				UpdateGlow();
				m_bDoubleSpark = true;
			}
		}
	}

	void UpdateGlow()
	{
		if( m_flNextSpark > g_Engine.time and !m_bShockTouch )
		{
			if( Math.RandomLong(0, 30) > 26 )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_SHOCK], 0.8, ATTN_NORM, 0, PITCH_NORM );
				GlowEffect( true );
				m_bShockTouch = true;
				m_flNextShockTouch = g_Engine.time + 0.45;
			}
			else if( Math.RandomLong(0, 40) == 15 )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_SHOCK], 0.8, ATTN_NORM, 0, PITCH_NORM );
				GlowEffect( true );
				m_bShockTouch = true;
				m_flNextShockTouch = g_Engine.time + 0.35;
			}
		}
	}

	void DoShockTouch()
	{
		if( m_bShockTouch )
		{
			TraceResult tr;
			g_Utility.TraceHull( m_pPlayer.pev.origin, m_pPlayer.pev.origin + Vector(0, 0, 72), dont_ignore_monsters, large_hull, m_pPlayer.edict(), tr );
			
			if( tr.pHit !is null )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
				pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, DMG_SHOCKTOUCH, DMG_SHOCK );
			}

			/*Doesn't work properly
			cnpc_hwrgrunt@ pDriveEnt = cast<cnpc_hwrgrunt@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null )
			{
				pDriveEnt.SetTouch( TouchFunction(pDriveEnt.ShockTouch) );
				pDriveEnt.pev.solid = SOLID_TRIGGER;
				m_pPlayer.pev.solid = SOLID_NOT;
				g_EntityFuncs.SetSize( pDriveEnt.pev, CNPC_SIZEMIN*1.2, CNPC_SIZEMAX*1.2 );
			}*/

			if( g_Engine.time > m_flNextShockTouch )
			{
				GlowEffect( false );
				m_bShockTouch = false;
			}
		}
		else
		{
			cnpc_hwrgrunt@ pDriveEnt = cast<cnpc_hwrgrunt@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null )
			{
				pDriveEnt.SetTouch( null );
				//pDriveEnt.pev.solid = SOLID_NOT;
				//m_pPlayer.pev.solid = SOLID_SLIDEBOX;
				g_EntityFuncs.SetSize( pDriveEnt.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
			}
		}
	}

	void GlowEffect( bool bOn )
	{
		if( bOn )
		{
			m_pDriveEnt.pev.rendermode = kRenderNormal;
			m_pDriveEnt.pev.renderfx = kRenderFxGlowShell;
			m_pDriveEnt.pev.renderamt = 4.0;
			m_pDriveEnt.pev.rendercolor = Vector(100, 100, 220);
		}
		else
		{
			m_pDriveEnt.pev.rendermode = kRenderNormal;
			m_pDriveEnt.pev.renderfx = kRenderFxNone;
			m_pDriveEnt.pev.renderamt = 255.0;
			m_pDriveEnt.pev.rendercolor = g_vecZero;
		}
	}

	int GetMaxAmmo()
	{
		int iRetval = AMMO_MINIGUN;

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 )
			iRetval = 9999;
		else if( (m_iSpawnFlags & CNPC::FL_CUSTOMAMMO) != 0 )
			iRetval = m_iMaxAmmo;

		return iRetval;
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_hwrgrunt", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.pev.set_controller( 0,  127 );
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = DONT_BLEED;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_HWRGRUNT );
	}

	void DoFirstPersonView()
	{
		cnpc_hwrgrunt@ pDriveEnt = cast<cnpc_hwrgrunt@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_hwrgrunt_rend_" + m_pPlayer.entindex();
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
}

class cnpc_hwrgrunt : ScriptBaseAnimating
{
	int m_iSpawnFlags;

	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	private float m_flRemoveTime;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_iSpawnFlags" )
		{
			m_iSpawnFlags = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

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
		if( pev.deadflag == CNPC::DEAD_GIB )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			DoDeath( true );

			return;
		}

		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			DoDeath();

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
		else if( (m_pOwner.pev.button & IN_ATTACK) != 0 )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void ShockTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.takedamage == DAMAGE_NO or pOther.edict() is m_pOwner.edict() )
			return;

		if( m_pOwner !is null and m_pOwner.IsConnected() and m_pOwner.pev.deadflag == DEAD_NO )
		{
			if( pOther.pev.FlagBitSet(FL_MONSTER) or (pOther.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
				pOther.TakeDamage( m_pOwner.pev, m_pOwner.pev, DMG_SHOCKTOUCH, DMG_SHOCK );
		}
	}

	void DoDeath( bool bGibbed = false )
	{
		pev.velocity = g_vecZero;

		if( (m_iSpawnFlags & CNPC::FL_DISABLEDROP) == 0 )
			DropWeapon();

		if( bGibbed and (m_iSpawnFlags & CNPC::FL_NOEXPLODE) == 0 )
		{
			ExplosiveDeath();
			return;
		}

		GlowEffect( false );
		GetSoundEntInstance().InsertSound ( bits_SOUND_DANGER, pev.origin, 250, 2.5, self ); 

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_DEATH1, SND_DEATH2)], VOL_NORM, 0.5 );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, 0.0), Vector(4.0, 4.0, 1.0) );

		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH3 );
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flRemoveTime = g_Engine.time + Math.RandomFloat( 3.0, 7.0 );
		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void DropWeapon()
	{
		Vector vecDropOrigin;
		self.GetAttachment( 1, vecDropOrigin, void );

		CBaseEntity@ pDrop = g_EntityFuncs.Create( "weapon_minigun", vecDropOrigin + Vector(0, 0, 16) , pev.angles, false );
		if( pDrop !is null )
		{
			pDrop.pev.spawnflags |= 1024; //Disable Respawn
			self.SetBodygroup( 1, 4 ); 
		}
	}

	void GlowEffect( bool bOn )
	{
		if( bOn )
		{
			pev.rendermode = kRenderNormal;
			pev.renderfx = kRenderFxGlowShell;
			pev.renderamt = 4.0;
			pev.rendercolor = Vector(100, 100, 220);
		}
		else
		{
			pev.rendermode = kRenderNormal;
			pev.renderfx = kRenderFxNone;
			pev.renderamt = 255.0;
			pev.rendercolor = g_vecZero;
		}
	}

	void DieThink()
	{
		if( pev.deadflag != DEAD_DEAD )
			pev.deadflag = DEAD_DEAD;

		if( m_flRemoveTime <= g_Engine.time )
		{
			pev.solid = SOLID_NOT;

			if( (m_iSpawnFlags & CNPC::FL_NOEXPLODE) == 0 )
				ExplosiveDeath();
			else
			{
				SetThink( ThinkFunction(this.SUB_StartFadeOut) );
				pev.nextthink = g_Engine.time;
			}
		}
		else
		{
			if( (m_iSpawnFlags & CNPC::FL_NOEXPLODE) == 0 )
			{
				Vector vecOrigin = pev.origin;

				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
					m1.WriteByte( TE_SMOKE );
					m1.WriteCoord( Math.RandomFloat(pev.absmin.x, pev.absmax.x) );
					m1.WriteCoord( Math.RandomFloat(pev.absmin.y, pev.absmax.y) );
					m1.WriteCoord( vecOrigin.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(SMOKE_SPRITE) );
					m1.WriteByte( 15 ); // scale * 10
					m1.WriteByte( 10 ); // framerate
				m1.End();

				vecOrigin = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), Math.RandomFloat(pev.origin.z, pev.absmax.z) );
				g_Utility.Sparks( vecOrigin );
			}

			pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void ExplosiveDeath()
	{
			SpawnExplosion( pev.origin, 0.0, 0.0, EXPLODE_DAMAGE );

			NetworkMessage gib1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				gib1.WriteByte( TE_BREAKMODEL );
				gib1.WriteCoord( pev.origin.x ); // position
				gib1.WriteCoord( pev.origin.y );
				gib1.WriteCoord( pev.origin.z );
				gib1.WriteCoord( 200 ); // size
				gib1.WriteCoord( 200 );
				gib1.WriteCoord( 64 );
				gib1.WriteCoord( 10 ); // velocity
				gib1.WriteCoord( 20 );
				gib1.WriteCoord( 80 );
				gib1.WriteByte( 30 ); // randomization
				gib1.WriteShort( g_EngineFuncs.ModelIndex(GIB_MODEL1) ); //model id#
				gib1.WriteByte( 15 ); // # of shards
				gib1.WriteByte( 100 ); // duration (3.0 seconds)
				gib1.WriteByte( BREAK_METAL ); // flags
			gib1.End();

			NetworkMessage gib2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				gib2.WriteByte( TE_BREAKMODEL );
				gib2.WriteCoord( pev.origin.x ); // position
				gib2.WriteCoord( pev.origin.y );
				gib2.WriteCoord( pev.origin.z );
				gib2.WriteCoord( 200 ); // size
				gib2.WriteCoord( 200 );
				gib2.WriteCoord( 96 );
				gib2.WriteCoord( 0 ); // velocity
				gib2.WriteCoord( 0 );
				gib2.WriteCoord( 10 );
				gib2.WriteByte( 30 ); // randomization
				gib2.WriteShort( g_EngineFuncs.ModelIndex(GIB_MODEL2) ); //model id#
				gib2.WriteByte( 15 ); // # of shards
				gib2.WriteByte( 100 ); // duration (3.0 seconds)
				gib2.WriteByte( BREAK_METAL ); // flags
			gib2.End();

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_SHOCK], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			CBaseEntity@ pSmoker = g_EntityFuncs.Create( "env_smoker", pev.origin, g_vecZero, false );
			pSmoker.pev.health = 1; //1 smoke balls
			pSmoker.pev.scale = 10; //4.6X normal size
			pSmoker.pev.dmg = 0; //0 radial distribution
			pSmoker.pev.nextthink = g_Engine.time + 0.5; //Start in 0.5 seconds

			Vector vecOrigin = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), Math.RandomFloat(pev.origin.z, pev.absmax.z) );
			g_Utility.Sparks( vecOrigin );

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;
	}

	void SpawnExplosion( Vector center, float randomRange, float time, int magnitude )
	{
		CBaseEntity@ pExplosion = g_EntityFuncs.Create( "env_explosion", center, g_vecZero, false );
		pExplosion.KeyValue( "iMagnitude", string(magnitude) );

		g_EntityFuncs.DispatchSpawn( pExplosion.edict() );

		if( m_pOwner !is null and m_pOwner.IsConnected() and m_pOwner.pev.deadflag == DEAD_NO )
			pExplosion.Use( m_pOwner, m_pOwner, USE_ON );
		else
			pExplosion.Use( self, self, USE_ON );

		pExplosion.pev.nextthink = g_Engine.time + time;
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

final class info_cnpc_hwrgrunt : CNPCSpawnEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}
		else if( szKey == "gag" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_GAG;

			return true;
		}
		else if( szKey == "disabledrop" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_DISABLEDROP;

			return true;
		}
		else if( szKey == "noexplode" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_NOEXPLODE;

			return true;
		}
		else if( szKey == "maxammo" )
		{
			if( atoi(szValue) > 0 )
			{
				m_iMaxAmmo = atoi(szValue);
				m_iSpawnFlags |= CNPC::FL_CUSTOMAMMO;
			}
			else if( atoi(szValue) == -1 )
			{
				m_iMaxAmmo = 9999;
				m_iSpawnFlags |= CNPC::FL_INFINITEAMMO;
			}

			return true;
		}
		else if( szKey == "firerate" )
		{
			m_flFireRate = atof( szValue );

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	info_cnpc_hwrgrunt()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hwrgrunt::info_cnpc_hwrgrunt", "info_cnpc_hwrgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hwrgrunt::cnpc_hwrgrunt", "cnpc_hwrgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hwrgrunt::weapon_hwrgrunt", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "hwrgruntammo" );

	g_Game.PrecacheOther( "info_cnpc_hwrgrunt" );
	g_Game.PrecacheOther( "cnpc_hwrgrunt" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_hwrgrunt END

/* FIXME
*/

/* TODO
	Check FL_ONGROUND and a downward trace to stop firing if soaring through the air ??
	Add "disablerepair" setting
*/