namespace cnpc_hwgrunt
{

bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_hwgrunt";
const string CNPC_MODEL				= "models/hwgrunt.mdl";
const string MODEL_MINIGUN			= "models/v_minigun.mdl";
const string MODEL_PISTOL			= "models/v_9mmhandgun.mdl";
const string MODEL_DEAGLE			= "models/v_desert_eagle.mdl";
const string MODEL_357					= "models/v_357.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 200.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the hwgrunt itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_RUN_MG			= (83.127602 * CNPC::flModelToGameSpeedModifier) * 0.8;
const float SPEED_RUN					= (83.127602 * CNPC::flModelToGameSpeedModifier) * 1.5;
const float SPEED_WALK_MG			= (37.280136 * CNPC::flModelToGameSpeedModifier) * 3.0;
const float SPEED_WALK					= (37.280136 * CNPC::flModelToGameSpeedModifier) * 3.8;
const float VELOCITY_WALK_MG		= 90.0; //if the player's velocity is this or lower, use the walking animation
const float VELOCITY_WALK			= 150.0;

const float CD_PRIMARY					= 0.08;
const float DAMAGE_MINIGUN			= 15;

const int AMMO_MINIGUN				= 600;
const int AMMO_PISTOL					= 17;
const int AMMO_DEAGLE				= 7;
const int AMMO_357						= 6;
const float DAMAGE_PISTOL			= 9;
const float DAMAGE_DEAGLE			= 44;
const float DAMAGE_357				= 66;
const float CD_PISTOL					= 0.4;
const float CD_DEAGLE					= 0.5;
const float CD_357							= 0.6;
const float RELOAD_TIME				= 2.0;

const int AMMO_REGEN_AMOUNT	= 3;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds

const float PICKUP_RADIUS			= 42.0;

const array<string> pPainSounds = 
{
	"hgrunt/gr_pain1.wav",
	"hgrunt/gr_pain2.wav",
	"hgrunt/gr_pain3.wav",
	"hgrunt/gr_pain4.wav",
	"hgrunt/gr_pain5.wav"
};

const array<string> pDieSounds = 
{
	"hgrunt/gr_die1.wav",
	"hgrunt/gr_die2.wav",
	"hgrunt/gr_die3.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"hassault/hw_spinup.wav",
	"hassault/hw_spin.wav",
	"hassault/hw_shoot2.wav",
	"hassault/hw_spindown.wav",
	"weapons/pl_gun3.wav",
	"otis/ot_attack.wav",
	"weapons/357_shot1.wav",
	"hgrunt/gr_reload1.wav"
};

enum sound_e
{
	SND_SPINUP = 1,
	SND_SPIN,
	SND_SHOOT_MINIGUN,
	SND_SPINDOWN,
	SND_SHOOT_PISTOL,
	SND_SHOOT_DEAGLE,
	SND_SHOOT_357,
	SND_RELOAD_DONE
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
	ANIM_DEATH3,
	ANIM_PISTOL_IDLE = 16,
	ANIM_PISTOL_WALK,
	ANIM_PISTOL_RUN,
	ANIM_PISTOL_SHOOT,
	ANIM_PISTOL_CSHOOT,
	ANIM_PISTOL_RELOAD,
	ANIM_PICKUP
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_SPINUP,
	STATE_SHOOT,
	STATE_SPINDOWN,
	STATE_PICKUP,
	STATE_RELOAD
};

enum secwep_e
{
	WPN_MINIGUN = 0,
	WPN_PISTOL,
	WPN_DEAGLE,
	WPN_357,
	WPN_NONE
};

enum animtypes_e
{
	WANIM_DRAW = 0,
	WANIM_SPINUP,
	WANIM_SHOOT,
	WANIM_SPINDOWN,
	WANIM_RELOAD
};

final class weapon_hwgrunt : CBaseDriveWeapon
{
	int m_iVoicePitch;

	protected EHandle m_hPickupTarget;
	protected CBaseEntity@ m_pPickupTarget
	{
		get const { return m_hPickupTarget.GetEntity(); }
		set { m_hPickupTarget = EHandle(@value); }
	}

	private int m_iShell;
	private float m_flNextAmmoRegen;
	private bool m_bHasMinigun;
	bool m_bShouldDropMinigun;

	private int m_iSecondaryWeapon;
	private int m_iMaxSecAmmo;
	private bool m_bCrouching;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );
		m_bHasMinigun = true;
		m_bShouldDropMinigun = false;
		m_bCrouching = false;

		if( Math.RandomLong(0, 1) == 1 )
			m_iVoicePitch = 92 + Math.RandomLong(0, 7);
		else
			m_iVoicePitch = 95;

		if( pev.weapons > 4 ) pev.weapons = 0; //invalid number, set to random

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_MINIGUN );
		g_Game.PrecacheModel( MODEL_PISTOL );
		g_Game.PrecacheModel( MODEL_DEAGLE );
		g_Game.PrecacheModel( MODEL_357 );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_hwgrunt.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_hwgrunt.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_hwgrunt_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		if( m_iMaxAmmo == 0 ) m_iMaxAmmo = AMMO_MINIGUN;
		if( m_iMaxSecAmmo == 0 ) m_iMaxSecAmmo = AMMO_PISTOL;

		info.iMaxAmmo1	= m_iMaxAmmo;
		info.iMaxAmmo2	= m_iMaxSecAmmo;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::HWGRUNT_SLOT - 1;
		info.iPosition			= CNPC::HWGRUNT_POSITION - 1;
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

		SetSecondaryWeapon();
		self.m_iDefaultAmmo = GetMaxAmmo();
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, GetMaxAmmo() );
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, GetMaxAmmo(true) );

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);
		if( m_flFireRate <= 0.0 ) m_flFireRate = CD_PRIMARY;

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
		}

		return self.DefaultDeploy( self.GetV_Model(MODEL_MINIGUN), "", 4, "" );
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
			if( m_bHasMinigun )
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.15;
					return;
				}

				if( m_iState < STATE_SPINUP )
				{
					SetState( STATE_SHOOT );
					SetSpeed( 0 );
					SetAnim( ANIM_SPINUP );

					if( CNPC_FIRSTPERSON )
						self.SendWeaponAnim( GetWeaponAnim(WANIM_SPINUP) );

					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SPINUP], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
					return;
				}
				else if( GetState(STATE_SHOOT) )
				{
					if( m_pDriveEnt.pev.sequence != ANIM_SHOOT )
						SetAnim( ANIM_SHOOT );

					if( CNPC_FIRSTPERSON )
						self.SendWeaponAnim( GetWeaponAnim(WANIM_SHOOT) );

					Shoot();

					self.m_flNextPrimaryAttack = g_Engine.time + m_flFireRate;
				}
			}
			else
			{
				if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
				{
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.15;
					return;
				}

				SetState( STATE_SHOOT );
				SetSpeed( 0 );

				ShootSecondary();

				if( CNPC_FIRSTPERSON )
					self.SendWeaponAnim( GetWeaponAnim(WANIM_SHOOT) );
			}
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

		if( m_pDriveEnt is null ) return;

		m_bShouldDropMinigun = true;
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
			m_pPlayer.pev.viewmodel = GetWeaponModel();
			self.SendWeaponAnim( GetWeaponAnim(WANIM_DRAW) );
		}
		else
		{
			cnpc_hwgrunt@ pDriveEnt = cast<cnpc_hwgrunt@>(CastToScriptClass(m_pDriveEnt));
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
			CheckPickupInput();
			PickupAE();
			CheckReloadInput();
			ReloadAE();

			if( m_flNextThink <= g_Engine.time )
			{
				DropMinigun();
				m_flNextThink = g_Engine.time + 0.1;
			}
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState > STATE_RUN ) return;

		SetSpeed( m_bHasMinigun ? int(SPEED_RUN_MG) : int(SPEED_RUN) );

		float flMinWalkVelocity = m_bHasMinigun ? -VELOCITY_WALK_MG : -VELOCITY_WALK;
		float flMaxWalkVelocity = m_bHasMinigun ? VELOCITY_WALK_MG : VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK and m_pDriveEnt.pev.sequence != ANIM_PISTOL_WALK )
			{
				SetState( STATE_WALK );
				SetSpeed( m_bHasMinigun ? int(SPEED_WALK_MG) : int(SPEED_WALK) );
				SetAnim( m_bHasMinigun ? ANIM_WALK : ANIM_PISTOL_WALK );
			}

			if( m_pDriveEnt.pev.sequence == ANIM_WALK )
				m_pDriveEnt.pev.framerate = 1.7; //the walking animation is too slow
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN and m_pDriveEnt.pev.sequence != ANIM_PISTOL_RUN )
			{
				SetState( STATE_RUN );
				SetSpeed( m_bHasMinigun ? int(SPEED_RUN_MG) : int(SPEED_RUN) );
				SetAnim( m_bHasMinigun ? ANIM_RUN : ANIM_PISTOL_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation( bool bOverrideState = false )
	{
		if( !bOverrideState )
		{
			if( (m_pDriveEnt.pev.sequence >= ANIM_SPINUP or m_pDriveEnt.pev.sequence == ANIM_SPINDOWN) and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( GetState(STATE_SHOOT) and m_bHasMinigun ) return;
			if( GetState(STATE_SHOOT) and (m_pDriveEnt.pev.sequence == ANIM_PISTOL_SHOOT or m_pDriveEnt.pev.sequence == ANIM_PISTOL_CSHOOT) and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( GetState(STATE_PICKUP) and m_pDriveEnt.pev.sequence == ANIM_PICKUP and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( GetState(STATE_RELOAD) and m_pDriveEnt.pev.sequence == ANIM_PISTOL_RELOAD and !m_pDriveEnt.m_fSequenceFinished ) return;
		}

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE or bOverrideState )
			{
				SetSpeed( int(SPEED_RUN) );
				SetState( STATE_IDLE );
				SetAnim( m_bHasMinigun ? ANIM_IDLE : ANIM_PISTOL_IDLE );
			}
			else if( GetState(STATE_IDLE) and CNPC_FIDGETANIMS and m_bHasMinigun )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void IdleSound()
	{
		if( CNPC::g_flTalkWaitTime > g_Engine.time ) return;

		if( CNPC::g_iGruntQuestion != 0 or Math.RandomLong(0, 1) == 1 )
		{
			if( CNPC::g_iGruntQuestion == 0 )
			{
				switch( Math.RandomLong(0, 2) )
				{
					case 0: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_CHECK", 0.35, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iGruntQuestion = 1; break; }
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_QUEST", 0.35, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iGruntQuestion = 2; break; }
					case 2: {g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_IDLE", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break; }
				}
			}
			else
			{
				switch( CNPC::g_iGruntQuestion )
				{
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_CLEAR", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break; }
					case 2: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_ANSWER", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break;}
				}

				CNPC::g_iGruntQuestion = 0;
			}

			CNPC::g_flTalkWaitTime = g_Engine.time + Math.RandomFloat( 1.5, 2.0 );
		}
	}

	void SetSecondaryWeapon()
	{
		switch( pev.weapons )
		{
			//random
			case 0:
			{
				SetArmedWeapon( WPN_MINIGUN );
				m_iSecondaryWeapon = Math.RandomLong( WPN_PISTOL, WPN_357 );

				break;
			}

			case WPN_PISTOL:
			{
				SetArmedWeapon( WPN_MINIGUN );
				m_iSecondaryWeapon = WPN_PISTOL;
				m_iMaxSecAmmo = AMMO_PISTOL;

				break;
			}

			case WPN_DEAGLE:
			{
				SetArmedWeapon( WPN_MINIGUN );
				m_iSecondaryWeapon = WPN_DEAGLE;
				m_iMaxSecAmmo = AMMO_DEAGLE;

				break;
			}

			case WPN_357:
			{
				SetArmedWeapon( WPN_MINIGUN );
				m_iSecondaryWeapon = WPN_357;
				m_iMaxSecAmmo = AMMO_357;

				break;
			}
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
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_MINIGUN], VOL_NORM, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5) );
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
		if( !m_bHasMinigun or m_iState < STATE_SPINUP or m_iState >= STATE_SPINDOWN ) return;

		if( ((GetState(STATE_SPINUP) or GetState(STATE_SHOOT)) and (m_pPlayer.pev.button & IN_ATTACK) == 0) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			SetState( STATE_SPINDOWN );
			SetAnim( ANIM_SPINDOWN );

			if( CNPC_FIRSTPERSON )
				self.SendWeaponAnim( GetWeaponAnim(WANIM_SPINDOWN) );

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

	void ShootSecondary()
	{
		int iDamage = DAMAGE_PISTOL;
		int iSound = SND_SHOOT_PISTOL;
		float flNextAttack = CD_PISTOL;

		SetAnim( ANIM_PISTOL_SHOOT );

		switch( m_iSecondaryWeapon )
		{
			case WPN_DEAGLE:
			{
				iDamage = DAMAGE_DEAGLE;
				iSound = SND_SHOOT_DEAGLE;
				flNextAttack = CD_DEAGLE;

				break;
			}

			case WPN_357:
			{
				iDamage = DAMAGE_357;
				iSound = SND_SHOOT_357;
				flNextAttack = CD_357;

				break;
			}
		}

		Vector vecShootOrigin, vecShootDir;

		Vector vecAngle = m_pPlayer.pev.v_angle;
		if( vecAngle.x < -40.0 )
			vecAngle.x = -40.0;

		Math.MakeVectors( vecAngle );

		vecShootOrigin = m_pDriveEnt.pev.origin + (g_Engine.v_forward * -0.125) * m_pPlayer.pev.scale + (g_Engine.v_right * 12.0) * m_pPlayer.pev.scale + (g_Engine.v_up * 40.0) * m_pPlayer.pev.scale;
		vecShootDir = g_Engine.v_forward;

		self.FireBullets( 1, vecShootOrigin, vecShootDir, (m_bCrouching ? VECTOR_CONE_1DEGREES : VECTOR_CONE_2DEGREES), 4096.0, BULLET_PLAYER_CUSTOMDAMAGE, 0, iDamage, m_pPlayer.pev );

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[iSound], VOL_NORM, ATTN_NORM );

		if( m_iSecondaryWeapon != WPN_357 )
		{
			Vector vecShellOrigin;
			m_pDriveEnt.GetAttachment( 1, vecShellOrigin, void );
			Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
			g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
		}

		GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 1024, 0.3, m_pPlayer ); 
		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) - 1 );

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flNextAttack;
	}

	void DropMinigun()
	{
		if( !m_bHasMinigun or !m_bShouldDropMinigun ) return;

		DropWeapon();
		m_bHasMinigun = false;
		m_bShouldDropMinigun = false;
		SetArmedWeapon( m_iSecondaryWeapon );
		m_pPlayer.pev.viewmodel = GetWeaponModel();
		self.SendWeaponAnim( GetWeaponAnim(WANIM_DRAW) );
		DoIdleAnimation( true );
	}

	void DropWeapon()
	{
		if( m_pDriveEnt is null ) return;

		Vector vecDropOrigin;
		m_pDriveEnt.GetAttachment( 1, vecDropOrigin, void );

		CBaseEntity@ pDrop = g_EntityFuncs.Create( "weapon_minigun", vecDropOrigin + Vector(0, 0, 16) , m_pDriveEnt.pev.angles, false );
		if( pDrop !is null )
		{
			pDrop.pev.spawnflags |= 1024; //Disable Respawn
			m_pDriveEnt.SetBodygroup( 1, 4 ); 
		}
	}

	void SetArmedWeapon( int iWeapon )
	{
		if( m_pDriveEnt is null ) return;

		if( !m_bHasMinigun )
		{
			switch( iWeapon )
			{
				case WPN_MINIGUN: { m_pDriveEnt.SetBodygroup( 1, WPN_MINIGUN ); break; }
				case WPN_PISTOL: { m_pDriveEnt.SetBodygroup( 1, WPN_PISTOL ); break; }
				case WPN_DEAGLE: { m_pDriveEnt.SetBodygroup( 1, WPN_DEAGLE ); break; }
				case WPN_357: { m_pDriveEnt.SetBodygroup( 1, WPN_357 ); break; }
				case WPN_NONE: { m_pDriveEnt.SetBodygroup( 1, WPN_NONE ); break; }
			}
		}
		else if( iWeapon > WPN_MINIGUN )
			m_pDriveEnt.SetBodygroup( 1, WPN_PISTOL );
		else
			m_pDriveEnt.SetBodygroup( 1, WPN_MINIGUN );
	}

	void CheckPickupInput()
	{
		if( m_bHasMinigun or m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_USE) != 0 )
		{
			CBaseEntity@ pWeapon = FindWeapon();
			if( pWeapon is null ) return;

			SetState( STATE_PICKUP );
			SetSpeed( 0 );
			SetAnim( ANIM_PICKUP );
		}
	}

	CBaseEntity@ FindWeapon()
	{
		CBaseEntity@ pEntity = null;
		while( (@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "weapon_minigun")) !is null )
		{
			if( (m_pDriveEnt.pev.origin - pEntity.pev.origin).Length() > PICKUP_RADIUS ) continue;

			@m_pPickupTarget = pEntity;
			break;
		}

		return pEntity;
	}

	void PickupAE()
	{
		if( m_iState != STATE_PICKUP or m_pDriveEnt.pev.sequence != ANIM_PICKUP or m_pPickupTarget is null ) return;

		if( IsBetween2(GetFrame(51), 26, 28) and m_uiAnimationState == 0 ) { PickupMinigun(); m_uiAnimationState++; }
		else if( GetFrame(51) >= 37 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
	}

	void PickupMinigun()
	{
		SetArmedWeapon( 0 );
		m_bHasMinigun = true;
		m_bShouldDropMinigun = false;
		g_EntityFuncs.Remove(m_pPickupTarget);

		m_pPlayer.pev.viewmodel = GetWeaponModel();
		self.SendWeaponAnim( GetWeaponAnim(WANIM_DRAW) );
	}

	void CheckReloadInput()
	{
		if( m_bHasMinigun or m_iState > STATE_RUN or m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) >= GetMaxAmmo(true) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			SetState( STATE_RELOAD );
			SetSpeed( 0 );

			SetAnim( ANIM_PISTOL_RELOAD );

			if( CNPC_FIRSTPERSON )
				self.SendWeaponAnim( GetWeaponAnim(WANIM_RELOAD) );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (RELOAD_TIME + 0.1);
		}
	}

	void ReloadAE()
	{
		if( m_iState != STATE_RELOAD ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_PISTOL_RELOAD ) return;

		if( IsBetween2(GetFrame(61), 24, 26) and m_uiAnimationState == 0 ) { ReloadGun(); m_uiAnimationState++; }
		else if( GetFrame(61) >= 25 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
	}

	void ReloadGun()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_RELOAD_DONE], VOL_NORM, ATTN_NORM );
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, GetMaxAmmo(true) );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_hwgrunt", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			m_pDriveEnt.pev.set_controller( 0,  127 );
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_HWGRUNT );
	}

	void DoFirstPersonView()
	{
		cnpc_hwgrunt@ pDriveEnt = cast<cnpc_hwgrunt@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_hwgrunt_rend_" + m_pPlayer.entindex();
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
		SetSpeed( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}

	int GetMaxAmmo( bool bSecondary = false )
	{
		int iRetval = AMMO_MINIGUN;

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 )
			iRetval = 9999;
		else if( (m_iSpawnFlags & CNPC::FL_CUSTOMAMMO) != 0 )
			iRetval = m_iMaxAmmo;

		if( bSecondary )
		{
			if( m_iSecondaryWeapon == WPN_PISTOL )
				iRetval = AMMO_PISTOL;
			else if( m_iSecondaryWeapon == WPN_DEAGLE )
				iRetval = AMMO_DEAGLE;
			else if( m_iSecondaryWeapon == WPN_357 )
				iRetval = AMMO_357;

			if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 )
				iRetval = 9999;
		}

		return iRetval;
	}

	string GetWeaponModel()
	{
		if( m_bHasMinigun ) return MODEL_MINIGUN;
		else if( m_iSecondaryWeapon == WPN_PISTOL ) return MODEL_PISTOL;
		else if( m_iSecondaryWeapon == WPN_DEAGLE ) return MODEL_DEAGLE;
		else if( m_iSecondaryWeapon == WPN_357 ) return MODEL_357;

		return "";
	}

	int GetWeaponAnim( int iAnimType )
	{
		if( m_bHasMinigun )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 4;
				case WANIM_SPINUP: return 6;
				case WANIM_SHOOT: return 9;
				case WANIM_SPINDOWN: return 7;
			}
		}
		else if( m_iSecondaryWeapon == WPN_PISTOL )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 7;
				case WANIM_SHOOT: return 3;
				case WANIM_RELOAD: return 6;
			}
		}
		else if( m_iSecondaryWeapon == WPN_DEAGLE )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 9;
				case WANIM_SHOOT: return 5;
				case WANIM_RELOAD: return 8;
			}
		}
		else if( m_iSecondaryWeapon == WPN_357 )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 5;
				case WANIM_SHOOT: return 2;
				case WANIM_RELOAD: return 3;
			}
		}

		return 0;
	}
}

final class cnpc_hwgrunt : CBaseDriveEntity
{
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_PISTOL_RUN or pev.sequence == ANIM_WALK or pev.sequence == ANIM_PISTOL_WALK) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( (m_pOwner.pev.button & IN_ATTACK) != 0 )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath( bool bGibbed = false )
	{
		pev.velocity = g_vecZero;

		if( (m_iSpawnFlags & CNPC::FL_DISABLEDROP) == 0 )
			DropWeapon();

		if( bGibbed )
		{
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

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
			self.SetBodygroup( 1, WPN_NONE );
		}
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong(ANIM_DEATH1, ANIM_DEATH3);
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM, 0, 95 + Math.RandomLong(0, 9) );

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

final class info_cnpc_hwgrunt : CNPCSpawnEntity
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
		else if( szKey == "disable_minigun_drop" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_DISABLEDROP;

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

	info_cnpc_hwgrunt()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hwgrunt::info_cnpc_hwgrunt", "info_cnpc_hwgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hwgrunt::cnpc_hwgrunt", "cnpc_hwgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hwgrunt::weapon_hwgrunt", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "hwgpriammo", "hwgsecammo" );

	g_Game.PrecacheOther( "info_cnpc_hwgrunt" );
	g_Game.PrecacheOther( "cnpc_hwgrunt" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_hwgrunt END

/* FIXME
*/

/* TODO
	Use empty/non-empty animations for secondary weapons ??
*/