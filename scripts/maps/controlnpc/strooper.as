namespace cnpc_strooper
{

bool CNPC_FIRSTPERSON					= false;
	
const string CNPC_WEAPONNAME		= "weapon_strooper";
const string CNPC_MODEL					= "models/strooper.mdl";
const Vector CNPC_SIZEMIN				= Vector( -24, -24, 0 );
const Vector CNPC_SIZEMAX				= Vector( 24, 24, 72 );

const float CNPC_HEALTH					= 200.0;
const float CNPC_VIEWOFS_FPV			= 40.0; //camera height offset
const float CNPC_VIEWOFS_TPV			= 40.0;
const float CNPC_VIEWOFS_SHOOT	= 14.0;
const float CNPC_RESPAWNTIME			= 13.0; //from the point that the weapon is removed, not the shocktrooper itself
const float CNPC_MODEL_OFFSET		= 36.0; //sometimes the model floats above the ground

const float SPEED_WALK						= -1; //461.184601 * CNPC::flModelToGameSpeedModifier; //461.184601
const float SPEED_RUN						= -1; //137.380585 * CNPC::flModelToGameSpeedModifier; //137.380585
const float VELOCITY_WALK				= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY						= 0.3; //doesn't actually affect the rate of fire, unless you change the var below
const float CNPC_FIRERATE_MUL		= 1.0; //changing this will modify the rate of fire by changing the model's framerate
const float CNPC_FIRE_MINRANGE		= 48.0; //decides how close you can be to a wall before shooting gets blocked
const int AMMO_MAX							= 10;
const float AMMO_REGEN_RATE			= 0.1; //+1 per AMMO_REGEN_RATE seconds
const float SHOCK_DAMAGE				= 15.0;

const float CD_SECONDARY					= 1.5;
const float MELEE_RANGE					= 70.0;
const float MELEE_DAMAGE					= 12.0;

const float CD_GRENADE						= 6.0;
const float GRENADE_VELOCITY			= 750.0;
const float GRENADE_DAMAGE				= 100;

const array<string> pPainSounds = 
{
	"shocktrooper/shock_trooper_pain1.wav",
	"shocktrooper/shock_trooper_pain2.wav",
	"shocktrooper/shock_trooper_pain3.wav",
	"shocktrooper/shock_trooper_pain4.wav",
	"shocktrooper/shock_trooper_pain5.wav"
};

const array<string> pDieSounds = 
{
	"shocktrooper/shock_trooper_die1.wav",
	"shocktrooper/shock_trooper_die2.wav",
	"shocktrooper/shock_trooper_die3.wav",
	"shocktrooper/shock_trooper_die4.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav",
	"weapons/shock_fire.wav",
	"zombie/claw_miss2.wav"
};

enum sound_e
{
	SND_SHOOT = 1,
	SND_MELEE_MISS
};

enum animw_e
{
	ANIM_W_SHOOT = 1
};

enum anim_e
{
	ANIM_WALK = 0,
	ANIM_RUN,
	ANIM_GRENADETHROW = 9,
	ANIM_IDLE,
	ANIM_MELEE = 13,
	ANIM_CROUCH_IDLE,
	ANIM_SHOOT_START,
	ANIM_SHOOT,
	ANIM_DEATH1 = 27,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_DEATH6
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_SHOOT,
	STATE_MELEE,
	STATE_GRENADE,
	STATE_DEATH
};

class weapon_strooper : CBaseDriveWeapon
{
	private bool m_bHasFired;
	private bool m_bShotBlocked;
	private int m_iShockTrooperMuzzleFlash;
	private float m_flNextAmmoRegen;

	private bool m_bSecondSwingDone;

	private bool m_bHasThrownGrenade;
	private float m_flNextGrenade;

	private float m_flLastBlinkInterval;
	private float m_flLastBlinkTime;

	void Spawn()
	{
		Precache();

		self.m_iDefaultAmmo = AMMO_MAX;
		m_iState = STATE_IDLE;
		m_bHasFired = false;
		m_bShotBlocked = false;
		m_bSecondSwingDone = false;
		m_flNextGrenade = 0.0;
		m_bHasThrownGrenade = false;
		m_flLastBlinkTime = m_flLastBlinkInterval = g_Engine.time;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( "models/v_shock.mdl" );
		m_iShockTrooperMuzzleFlash = g_Game.PrecacheModel( "sprites/muzzle_shock.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_strooper.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_strooper.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_strooper_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::STROOPER_SLOT - 1;
		info.iPosition		= CNPC::STROOPER_POSITION - 1;
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

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, AMMO_MAX );

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

		return self.DefaultDeploy( self.GetV_Model("models/v_shock.mdl"), "", 0, "" );
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
			if( m_iState == STATE_MELEE or m_iState == STATE_GRENADE ) return;

			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.3;
				return;
			}

			TraceResult tr;
			Math.MakeVectors( m_pPlayer.pev.angles );
			g_Utility.TraceHull( m_pPlayer.pev.origin, m_pPlayer.pev.origin + g_Engine.v_forward * CNPC_FIRE_MINRANGE, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction != 1.0 ) 
			{
				m_bShotBlocked = true;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
				return;
			}

			m_bShotBlocked = false;

			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			{
				if( m_pDriveEnt.pev.sequence != ANIM_CROUCH_IDLE )
				{
					m_pDriveEnt.pev.sequence = ANIM_CROUCH_IDLE;
					m_pDriveEnt.pev.frame = 0;
					m_pDriveEnt.ResetSequenceInfo();
				}

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.3;
				return;
			}

			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( m_iState != STATE_SHOOT )
			{
				if( CNPC_FIRSTPERSON )
					m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_SHOOT );

				m_iState = STATE_SHOOT;
				m_pDriveEnt.pev.sequence = ANIM_SHOOT;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				if( CNPC_FIRERATE_MUL != 1.0 )
					m_pDriveEnt.pev.framerate = CNPC_FIRERATE_MUL;
			}
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
		if( m_pDriveEnt !is null )
		{
			if( m_iState != STATE_SHOOT and m_iState != STATE_GRENADE )
			{
				m_iState = STATE_MELEE;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				m_pDriveEnt.pev.sequence = ANIM_MELEE;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				SetThink( ThinkFunction(this.MeleeAttackThink) );
				pev.nextthink = g_Engine.time + 0.3;
			}
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
	}

	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
		{
			SetThink( null );
			return;
		}

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MELEE_MISS], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

		CBaseEntity@ pHurt = Kick();
		if( pHurt !is null )
		{
			if( !pHurt.pev.FlagBitSet(FL_CLIENT) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				Math.MakeVectors( m_pPlayer.pev.angles );
				pHurt.pev.punchangle.x = 15;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 50;
				pHurt.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, MELEE_DAMAGE, DMG_CLUB );
			}
		}

		if( !m_bSecondSwingDone )
		{
			pev.nextthink = g_Engine.time + 0.4;
			m_bSecondSwingDone = true;
		}
		else
		{
			SetThink( null );
			m_bSecondSwingDone = false;
		}
	}

	CBaseEntity@ Kick()
	{
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.angles );
		Vector vecStart = m_pDriveEnt.pev.origin;
		vecStart.z += 72.0 * 0.5; //pev.size.z
		Vector vecEnd = vecStart + g_Engine.v_forward * MELEE_RANGE;

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			return pEntity;
		}

		return null;
	}

	void TertiaryAttack()
	{
		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			DoFirstPersonView();
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			cnpc_strooper@ pDriveEnt = cast<cnpc_strooper@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}

		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
	}

	void Reload() //necessary to prevent the reload-key from interfering?
	{
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.pev.friction = 2; //no sliding!

			if( m_pPlayer.pev.button & (IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 )
				m_pPlayer.SetMaxSpeedOverride( 0 );
			else if( m_pPlayer.pev.button & IN_FORWARD != 0 and m_iState != STATE_SHOOT and m_iState != STATE_MELEE and m_iState != STATE_GRENADE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
				DoMovementAnimation();
			}

			DoIdleAnimation();
			Blink();
			Shoot();
			DoAmmoRegen();
			CheckGrenadeInput();
			ThrowGrenade();
		}
	}

	void DoMovementAnimation()
	{
		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				m_pDriveEnt.pev.sequence = ANIM_WALK;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_pDriveEnt.pev.sequence = ANIM_RUN;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState == STATE_SHOOT and m_pPlayer.pev.button & IN_ATTACK != 0 and !m_bShotBlocked ) return;
		if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_GRENADE and m_pDriveEnt.pev.sequence == ANIM_GRENADETHROW and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
				m_bShotBlocked = false;
				m_iState = STATE_IDLE;
				m_pDriveEnt.pev.sequence = ANIM_IDLE;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
				g_EngineFuncs.CVarSetFloat( "sk_plr_shockrifle", 15 );
			}
		}
	}

	// from halflife-op4-updated
	void Blink()
	{
		float flLastBlink = g_Engine.time - m_flLastBlinkTime;

		if( flLastBlink >= 3.0 )
		{
			if( flLastBlink >= Math.RandomFloat(3.0, 7.0) )
			{
				m_pDriveEnt.pev.skin = 1;

				m_flLastBlinkInterval = g_Engine.time;
				m_flLastBlinkTime = g_Engine.time;
			}
		}

		if( m_pDriveEnt.pev.skin > 0 )
		{
			if( g_Engine.time - m_flLastBlinkInterval >= 0.1 )
			{
				if( m_pDriveEnt.pev.skin == 3 )
					m_pDriveEnt.pev.skin = 0;
				else
					++m_pDriveEnt.pev.skin;

				m_flLastBlinkInterval = g_Engine.time;
			}
		}
	}

	void Shoot()
	{
		if( m_iState == STATE_SHOOT and m_pPlayer.pev.button & IN_ATTACK == 0 ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_SHOOT ) return;
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 ) return;
		if( m_bShotBlocked ) return;

		if( GetFrame(13) == 2 and !m_bHasFired )
		{
			Vector vecShootOrigin, vecShootDir;

			m_pDriveEnt.GetAttachment( 0, vecShootOrigin, void );

			Math.MakeVectors( m_pPlayer.pev.v_angle );

			Vector vecMuzzle = vecShootOrigin + -g_Engine.v_right * 4.0;
			NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecMuzzle );
				m1.WriteByte( TE_SPRITE );
				m1.WriteCoord( vecMuzzle.x );
				m1.WriteCoord( vecMuzzle.y );
				m1.WriteCoord( vecMuzzle.z );
				m1.WriteShort( m_iShockTrooperMuzzleFlash );
				m1.WriteByte( 4 ); // scale * 10
				m1.WriteByte( 128 ); // brightness
			m1.End();

			m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

			vecShootOrigin = vecShootOrigin + g_Engine.v_forward * 32;
			vecShootDir = g_Engine.v_forward;

			vecShootDir = vecShootDir + -g_Engine.v_right * 0.03 + g_Engine.v_up * 0.01;

			if( !CNPC_FIRSTPERSON )
				vecShootDir = vecShootDir + g_Engine.v_up * 0.03;

			CBaseEntity@ pBeam = g_EntityFuncs.Create( "shock_beam", vecShootOrigin, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );

			pBeam.pev.velocity = vecShootDir * 2000;
			pBeam.pev.angles.x = -m_pPlayer.pev.v_angle.x;

			g_EngineFuncs.CVarSetFloat( "sk_plr_shockrifle", SHOCK_DAMAGE );

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

			Vector angDir = Math.VecToAngles( vecShootDir );
			m_pDriveEnt.SetBlending( 0, angDir.x );

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );
			GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, m_pPlayer ); 

			if( CNPC_FIRSTPERSON ) self.SendWeaponAnim( ANIM_W_SHOOT );

			m_bHasFired = true;
		}
		else if( GetFrame(13) > 3 and m_bHasFired )
			m_bHasFired = false;
	}

	void DoAmmoRegen()
	{
		if( IsBetween2(m_iState, STATE_IDLE, STATE_RUN) and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < AMMO_MAX )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + 1 );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void CheckGrenadeInput()
	{
		if( m_iState == STATE_SHOOT or m_iState == STATE_MELEE ) return;
		if( m_flNextGrenade > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 )
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iState = STATE_GRENADE;
			m_pDriveEnt.pev.sequence = ANIM_GRENADETHROW;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			m_flNextGrenade = g_Engine.time + CD_GRENADE;
		}
	}

	void ThrowGrenade()
	{
		if( m_iState != STATE_GRENADE or m_pDriveEnt.pev.sequence != ANIM_GRENADETHROW ) return;

		if( GetFrame(56) == 40 and !m_bHasThrownGrenade )
		{
			Math.MakeVectors( m_pPlayer.pev.v_angle );
			Vector vecGrenadeOrigin = m_pDriveEnt.pev.origin + Vector(0, 0, 98);
			Vector vecGrenadeVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * GRENADE_VELOCITY;

			CreateSpore( m_pDriveEnt.pev.origin + Vector(0, 0, 98), vecGrenadeVelocity );

			m_bHasThrownGrenade = true;
		}
		else if( GetFrame(56) > 45 and m_bHasThrownGrenade )
			m_bHasThrownGrenade = false;
	}

	void CreateSpore( const Vector &in vecOrigin, const Vector &in vecAngles )
	{
		CBaseEntity@ cbeSpore = g_EntityFuncs.Create( "sporegrenade2", vecOrigin, vecAngles, true, m_pPlayer.edict() );
		sporegrenade2@ pSpore = cast<sporegrenade2@>(CastToScriptClass(cbeSpore));

		pSpore.pev.velocity = vecAngles;
		pSpore.pev.angles = Math.VecToAngles(vecAngles);

		g_EntityFuncs.DispatchSpawn( pSpore.self.edict() );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_strooper", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_STROOPER );
	}

	void DoFirstPersonView()
	{
		cnpc_strooper@ pDriveEnt = cast<cnpc_strooper@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_strooper_pid_" + m_pPlayer.entindex();
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
		m_pPlayer.pev.fuser4 = 0; //enable jump
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

class sporegrenade2 : ScriptBaseMonsterEntity
{
	protected EHandle m_hSprite;
	protected CSprite@ m_pSprite
	{
		get const { return cast<CSprite@>(m_hSprite.GetEntity()); }
		set { m_hSprite = EHandle(@value); }
	}

	private int m_iBlow, m_iBlowSmall, m_iSpitSprite, m_iTrail;
	private float m_flIgniteTime;
	private float m_flSoundDelay;

	void Spawn()
	{
		Precache();

		pev.movetype = MOVETYPE_BOUNCE;
		pev.solid = SOLID_BBOX;
		pev.gravity = 0.5;
		pev.friction = 0.7;
		pev.dmg = GRENADE_DAMAGE;
		pev.angles.x -= ( Math.RandomLong(-5, 5) + 30 );

		g_EntityFuncs.SetModel( self, "models/spore.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		SetThink( ThinkFunction(this.FlyThink) );
		SetTouch( TouchFunction(this.SporeTouch) );

		m_flIgniteTime = g_Engine.time;

		pev.nextthink = g_Engine.time + 0.01;

		@m_pSprite = g_EntityFuncs.CreateSprite( "sprites/glow01.spr", pev.origin, false ); 
		m_pSprite.SetTransparency( kRenderTransAdd, 180, 180, 40, 100, kRenderFxDistort );
		m_pSprite.SetScale( 0.8f );
		m_pSprite.SetAttachment( self.edict(), 0 );

		m_flSoundDelay = g_Engine.time;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/spore.mdl" );
		g_Game.PrecacheModel( "sprites/glow01.spr" );

		m_iBlow = g_Game.PrecacheModel( "sprites/spore_exp_01.spr" );
		m_iBlowSmall = g_Game.PrecacheModel( "sprites/spore_exp_c_01.spr" );
		m_iSpitSprite = m_iTrail = g_Game.PrecacheModel( "sprites/tinyspit.spr" );

		g_SoundSystem.PrecacheSound( "weapons/splauncher_impact.wav" );
		g_SoundSystem.PrecacheSound( "weapons/splauncher_bounce.wav" );
	}

	void IgniteThink()
	{
		SetThink( null );
		SetTouch( null );

		if( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/splauncher_impact.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		const Vector vecDir = pev.velocity.Normalize();

		TraceResult tr;

		g_Utility.TraceLine( pev.origin, pev.origin + vecDir * 64, dont_ignore_monsters, self.edict(), tr );
		g_Utility.DecalTrace( tr, DECAL_SPORESPLAT1 + Math.RandomLong(0, 2) );

		NetworkMessage message1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			message1.WriteByte( TE_SPRITE_SPRAY );
			message1.WriteCoord( pev.origin.x );
			message1.WriteCoord( pev.origin.y );
			message1.WriteCoord( pev.origin.z );
			message1.WriteCoord( tr.vecPlaneNormal.x );
			message1.WriteCoord( tr.vecPlaneNormal.y );
			message1.WriteCoord( tr.vecPlaneNormal.z );
			message1.WriteShort( m_iSpitSprite );
			message1.WriteByte( 100 ); // count
			message1.WriteByte( 40 ); // speed
			message1.WriteByte( 180 );
		message1.End();

		NetworkMessage message2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			message2.WriteByte( TE_DLIGHT );
			message2.WriteCoord( pev.origin.x );
			message2.WriteCoord( pev.origin.y );
			message2.WriteCoord( pev.origin.z );
			message2.WriteByte( 10 );
			message2.WriteByte( 15 );
			message2.WriteByte( 220 );
			message2.WriteByte( 40 );
			message2.WriteByte( 5 );
			message2.WriteByte( 10 );
		message2.End();

		NetworkMessage message3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			message3.WriteByte( TE_SPRITE );
			message3.WriteCoord( pev.origin.x );
			message3.WriteCoord( pev.origin.y );
			message3.WriteCoord( pev.origin.z );
			message3.WriteShort( (Math.RandomLong(0, 1) == 1) ? m_iBlow : m_iBlowSmall );
			message3.WriteByte( 20 );
			message3.WriteByte( 128 );
		message3.End();

		NetworkMessage message4( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			message4.WriteByte( TE_SPRITE_SPRAY );
			message4.WriteCoord( pev.origin.x );
			message4.WriteCoord( pev.origin.y );
			message4.WriteCoord( pev.origin.z );
			message4.WriteCoord( Math.RandomFloat(-1, 1) );
			message4.WriteCoord( 1 );
			message4.WriteCoord( Math.RandomFloat(-1, 1) );
			message4.WriteShort( m_iTrail );
			message4.WriteByte( 2 ); // count
			message4.WriteByte( 20 ); // speed
			message4.WriteByte( 80 );
		message4.End();

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pev.owner.vars, pev.dmg, 200, 0, DMG_ALWAYSGIB|DMG_BLAST );

		SetThink( ThinkFunction(SUB_Remove) );

		pev.nextthink = g_Engine.time;
	}

	void FlyThink()
	{
		if( g_Engine.time <= (m_flIgniteTime + 4.0) )
		{
			Vector velocity = pev.velocity.Normalize();

			NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				message.WriteByte( TE_SPRITE_SPRAY );
				message.WriteCoord( pev.origin.x );
				message.WriteCoord( pev.origin.y );
				message.WriteCoord( pev.origin.z );
				message.WriteCoord( velocity.x );
				message.WriteCoord( velocity.y );
				message.WriteCoord( velocity.z );
				message.WriteShort( m_iTrail );
				message.WriteByte( 2 ); // count
				message.WriteByte( 20 ); // speed
				message.WriteByte( 80 );
			message.End();
		}
		else
			SetThink( ThinkFunction(this.IgniteThink) );

		pev.nextthink = g_Engine.time + 0.03;
	}

	void SporeTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.takedamage == DAMAGE_NO )
		{
			if( pOther.edict() !is pev.owner )
			{
				if( g_Engine.time > m_flSoundDelay )
				{
					GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, pev.origin, int(floor(pev.dmg / 0.4)), 0.3, self ); 

					m_flSoundDelay = g_Engine.time + 1.0;
				}

				if( (pev.flags & FL_ONGROUND) != 0 )
					pev.velocity = pev.velocity * 0.5;
				else
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/splauncher_bounce.wav", 0.25, ATTN_NORM, 0, PITCH_NORM );
			}
		}
		else
		{
			pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_GENERIC );

			IgniteThink();
		}
	}

	void SUB_Remove()
	{
		self.SUB_Remove();
	}
}

class cnpc_strooper : ScriptBaseAnimating
{
	EHandle m_hRenderEntity;
	private bool m_bHasDroppedRoach;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 72) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_bHasDroppedRoach = false;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	int Classify()
	{
		if( CNPC::PVP )
		{
			if( pev.owner !is null )
			{
				CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

				if( pOwner.IsConnected() )
				{
					if( pOwner.Classify() == CLASS_PLAYER )
						return CLASS_PLAYER_ALLY;
					else
						return pOwner.Classify();
				}
			}
		}

		return CLASS_PLAYER_ALLY;
	}

	void DriveThink()
	{
		if( pev.owner is null or pev.owner.vars.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		Vector vecOrigin = pOwner.pev.origin;
		vecOrigin.z -= CNPC_MODEL_OFFSET;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.velocity = pOwner.pev.velocity;

		pev.angles.x = 0;
		pev.angles.y = pOwner.pev.angles.y;
		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		self.StudioFrameAdvance();
		pev.nextthink = g_Engine.time + 0.01;

		if( pev.deadflag != DEAD_DEAD )
		{
			pev.deadflag = DEAD_DEAD;

			pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH6 );
			pev.frame = 0;
			self.ResetSequenceInfo();

			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );
		}

		CheckRoachdrop();

		if( self.m_fSequenceFinished )
		{
			pev.framerate = 0;
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time;
		}
	}

	void CheckRoachdrop()
	{
		if( m_bHasDroppedRoach ) return;

		switch( pev.sequence )
		{
			case ANIM_DEATH1: { if( GetFrame(52) == 5 ) DropShockroach(); break; }
			case ANIM_DEATH2: { if( GetFrame(31) == 13 ) DropShockroach(); break; }
			case ANIM_DEATH3: { if( GetFrame(52) == 3 ) DropShockroach(); break; }
			case ANIM_DEATH4: { if( GetFrame(23) == 6 ) DropShockroach(); break; }
			case ANIM_DEATH5: { if( GetFrame(52) == 1 ) DropShockroach(); break; }
			case ANIM_DEATH6: { if( GetFrame(52) == 10 ) DropShockroach(); break; }
		}
	}

	// from halflife-op4-updated
	void DropShockroach()
	{
		Vector vecAngles = pev.angles;
		vecAngles.x = vecAngles.z = 0;

		self.SetBodygroup( 1, 1 );

		CBaseEntity@ pRoach = g_EntityFuncs.Create( "monster_shockroach", pev.origin + Vector(0, 0, 48) , vecAngles, false, self.edict() );

		if( pRoach !is null )
		{
			pRoach.pev.velocity = Vector( Math.RandomFloat(-20, 20), Math.RandomFloat(-20, 20), Math.RandomFloat(20, 30) );
			pRoach.pev.avelocity = Vector( 0, Math.RandomFloat(20, 40), 0 );

			if( CNPC::PVP )
			{
				if( Classify() == CLASS_PLAYER_ALLY )
					g_EntityFuncs.DispatchKeyValue( pRoach.edict(), "classify", string(CLASS_PLAYER_ALLY) );
				else
					g_EntityFuncs.DispatchKeyValue( pRoach.edict(), "classify", string(Classify()) );
			}
			else
				g_EntityFuncs.DispatchKeyValue( pRoach.edict(), "classify", string(CLASS_PLAYER_ALLY) );
		}

		m_bHasDroppedRoach = true;
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

	int GetFrame( int iMaxFrames )
	{
		return int( (pev.frame/255) * iMaxFrames );
	}
}

final class info_cnpc_strooper : CNPCSpawnEntity
{
	info_cnpc_strooper()
	{
		sWeaponName = CNPC_WEAPONNAME;
		sModel = CNPC_MODEL;
		iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		vecSizeMin = CNPC_SIZEMIN;
		vecSizeMax = CNPC_SIZEMAX;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_strooper::sporegrenade2", "sporegrenade2" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_strooper::info_cnpc_strooper", "info_cnpc_strooper" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_strooper::cnpc_strooper", "cnpc_strooper" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_strooper::weapon_strooper", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "shockbeams" );

	g_Game.PrecacheOther( "cnpc_strooper" );
	g_Game.PrecacheOther( "info_cnpc_strooper" );
	g_Game.PrecacheOther( "sporegrenade2" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_strooper END

/* FIXME
*/

/* TODO
*/