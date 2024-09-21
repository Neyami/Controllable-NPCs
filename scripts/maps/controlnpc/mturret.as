namespace cnpc_mturret
{

bool CNPC_FIRSTPERSON					= true;
const bool EPILEPSY_PREVENTION		= true; //there's a lot of flashing in thirdperson view if you look up far enough
const bool BLOCK_PLAYER_AIMING		= false; //when inactive

const string CNPC_WEAPONNAME		= "weapon_mturret";
const string CNPC_MODEL					= "models/miniturret.mdl";
const Vector CNPC_SIZEMIN_ON			= Vector( -16, -16, -32 );
const Vector CNPC_SIZEMAX_ON		= Vector( 16, 16, 32 );
const Vector CNPC_SIZEMIN_OFF		= Vector( -16, -16, -16 );
const Vector CNPC_SIZEMAX_OFF		= Vector( 16, 16, 16 );

const string TURRET_SMOKE_SPRITE	= "sprites/steam1.spr";

const float CNPC_HEALTH					= 80.0;
const float CNPC_VOFS_FPV_ON			= 8.0; //camera height offsets
const float CNPC_VOFS_FPV_OFF		= 0.0;
const float CNPC_VOFS_TPV				= 32.0;
const float CNPC_VOFS_FPV_ON_CL	= 24.0; //ceiling
const float CNPC_VOFS_FPV_OFF_CL	= 42.0;
const float CNPC_VOFS_TPV_CL			= -48.0;
const float CNPC_RESPAWNTIME			= 13.0; //from the point that the weapon is removed, not the turret itself
const float CNPC_RESPAWNEXIT			= 5.0; //time until it can be used again after a player exits

const float CNPC_FIRERATE					= 0.05;
const float CD_DEPLOY						= 1.0;

const int AMMO_MAX							= 140;
const float AMMO_REGEN_RATE			= 0.1; //+1 per AMMO_REGEN_RATE seconds
const Vector TURRET_SPREAD				= VECTOR_CONE_3DEGREES;//g_vecZero;
const float TURRET_RANGE					= 1200.0;
const float TURRET_DAMAGE				= 12.0;
const float TURRET_MAXPITCH			= 65.0; //the turret can't be aimed lower than this

//forced to use this because of some bug with the normal usage of ammo
const int HUD_CHANNEL_AMMO			= 9; //0-15

const float HUD_CLIP_X						= 0.85;
const float HUD_CLIP_Y						= 1.0;
const float HUD_AMMO_X					= 0.9;
const float HUD_AMMO_Y					= 1.0;
const float HUD_DANGER_CUTOFF		= 0.2;

const RGBA HUD_COLOR_NORMAL		= RGBA_SVENCOOP;
const RGBA HUD_COLOR_LOW			= RGBA(255, 0, 0, 255);

const array<string> pDieSounds = 
{
	"turret/tu_die.wav",
	"turret/tu_die2.wav",
	"turret/tu_die3.wav"
};

const array<string> arrsTurretSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"turret/tu_deploy.wav",
	//"turret/tu_active2.wav",
	"turret/tu_spinup.wav",
	"turret/tu_spindown.wav",
	"turret/tu_ping.wav",
	"weapons/hks1.wav",
	"weapons/hks2.wav",
	"weapons/hks3.wav"
};

enum sound_e
{
	SND_RESPAWN,
	SND_DEPLOY = 1,
	//SND_ACTIVE,
	SND_SPINUP,
	SND_SPINDOWN,
	SND_PING,
	SND_SHOOT1,
	SND_SHOOT2,
	SND_SHOOT3
};

enum anim_e
{
	ANIM_IDLE_OFF = 0,
	ANIM_FIRE,
	ANIM_SPIN,
	ANIM_DEPLOY,
	ANIM_RETIRE,
	ANIM_DIE
};

enum states_e
{
	STATE_IDLE_INACTIVE = 0,
	STATE_IDLE_ACTIVE,
	STATE_DEPLOYING,
	STATE_RETIRING,
	STATE_FIRE
};

class weapon_mturret : CBaseDriveWeapon
{
	private float m_flPingTime;

	private int m_iBaseTurnRate; // angles per second
	private float m_fTurnRate; // actual turn rate

	float m_flStartYaw;
	private Vector m_vecCurAngles;
	private Vector m_vecGoalAngles;

	protected EHandle m_hEpilepsyPreventer;
	protected CBaseEntity@ m_pEpilepsyPreventer
	{
		get const { return cast<CBaseEntity@>(m_hEpilepsyPreventer.GetEntity()); }
		set { m_hEpilepsyPreventer = EHandle(@value); }
	}

	private HUDNumDisplayParams m_hudParamsAmmo;
	private int m_iAmmoMax;
	private int m_iAmmoCurrent;
	private float m_flNextAmmoRegen;

	private int m_iOrientation;

	private float m_flCanExit;

	Vector m_vecExitOrigin, m_vecExitAngles; //for noplayerdeath

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "orientation" )
		{
			m_iOrientation = atoi( szValue );
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
		else if( szKey == "autodeploy" )
		{
			m_iAutoDeploy = atoi( szValue );
			return true;
		}
		else if( szKey == "startyaw" )
		{
			m_flStartYaw = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE_INACTIVE );
		m_iBaseTurnRate = 30;
		m_fTurnRate = 30.0;
		m_iAmmoMax = AMMO_MAX;
		m_iAmmoCurrent = AMMO_MAX;
		m_flCanExit = 0.0;

		m_hudParamsAmmo.color1 = HUD_COLOR_NORMAL;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( TURRET_SMOKE_SPRITE );

		for( uint i = 0; i < arrsTurretSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsTurretSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_mturret.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_mturret.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_mturret_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::MTURRET_SLOT - 1;
		info.iPosition		= CNPC::MTURRET_POSITION - 1;
		info.iFlags 			= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY; //to prevent monster from being despawned if out of ammo
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

		BaseClass.Holster( skipLocal );
	}

	void UpdateOnRemove()
	{
		ResetPlayer();

		BaseClass.UpdateOnRemove();
	}

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iAmmoCurrent > 0 )
				DoGun();
		}
		else
		{
			spawnDriveEnt();
			m_flStartYaw = m_pPlayer.pev.angles.y;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CNPC_FIRERATE;
		self.m_flTimeWeaponIdle = g_Engine.time + CNPC_FIRERATE;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt is null )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		if( GetState(STATE_IDLE_INACTIVE) )
		{
			SetState( STATE_DEPLOYING );
			SetAnim( ANIM_DEPLOY );
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsTurretSounds[SND_DEPLOY], 0.5, ATTN_NORM );
		}
		else if( GetState(STATE_IDLE_ACTIVE) )
		{
			m_vecCurAngles = m_pPlayer.pev.v_angle;
			m_vecGoalAngles.x = 0.0;
			m_vecGoalAngles.y = m_flStartYaw;
			SetState( STATE_RETIRING );

			SetAnim( ANIM_RETIRE, -1.0, 255 );
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsTurretSounds[SND_SPINDOWN], 0.5, ATTN_NORM );
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsTurretSounds[SND_DEPLOY], 0.5, ATTN_NORM, 0, 120 );

			SetThink( ThinkFunction(this.RetireThink) );
			pev.nextthink = g_Engine.time + 0.1;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_DEPLOY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_DEPLOY;
	}

	void TertiaryAttack()
	{
		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;

		if( m_pDriveEnt is null ) return;

		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );

			if( GetState(STATE_IDLE_INACTIVE) )
				m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_FPV_OFF : CNPC_VOFS_FPV_OFF_CL );
			else
				m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_FPV_ON : CNPC_VOFS_FPV_ON_CL );

			DoFirstPersonView();
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			cnpc_mturret@ pDriveEnt = cast<cnpc_mturret@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			if( m_hEpilepsyPreventer.IsValid() )
				g_EntityFuncs.Remove( m_hEpilepsyPreventer.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_TPV : CNPC_VOFS_TPV_CL );
			CNPC_FIRSTPERSON = false;
		}
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( m_pDriveEnt.pev.sequence == ANIM_DEPLOY and m_pDriveEnt.m_fSequenceFinished )
			{
				SetAnim( ANIM_SPIN );
				SetState( STATE_IDLE_ACTIVE );
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsTurretSounds[SND_SPINUP], 0.5, ATTN_NORM );
				g_EntityFuncs.SetSize( m_pDriveEnt.pev, CNPC_SIZEMIN_ON, CNPC_SIZEMAX_ON );

				if( CNPC_FIRSTPERSON )
					m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_FPV_ON : CNPC_VOFS_FPV_ON_CL );
				else
					m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_TPV : CNPC_VOFS_TPV_CL );
			}
			else if( m_pDriveEnt.pev.sequence == ANIM_RETIRE and m_pDriveEnt.m_fSequenceFinished )
			{
				SetAnim( ANIM_IDLE_OFF );
				SetState( STATE_IDLE_INACTIVE );
				g_EntityFuncs.SetSize( m_pDriveEnt.pev, CNPC_SIZEMIN_OFF, CNPC_SIZEMAX_OFF );

				if( CNPC_FIRSTPERSON )
					m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_FPV_OFF : CNPC_VOFS_FPV_OFF_CL );
				else
					m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_TPV : CNPC_VOFS_TPV_CL );
			}
			else if( GetState(STATE_FIRE) and ((m_pPlayer.pev.button & IN_ATTACK) == 0 or m_iAmmoCurrent <= 0) )
				DoIdleAnimation();

			DoPing();
			MoveTurret();
			DoAmmoRegen();
			BlockPlayerAiming();
			KeepPlayerInPlace();
			DoEpilepsyPrevention();
			CheckForExit();
		}
	}

	void DoGun()
	{
		if( GetState(STATE_IDLE_ACTIVE) )
		{
			SetState( STATE_FIRE );
			SetAnim( ANIM_FIRE );
		}
		else if( GetState(STATE_FIRE) )
		{
			Vector vecSrc;
			Vector vecAngle = m_pPlayer.pev.v_angle;

			if( m_iOrientation == 0 )
			{
				if( vecAngle.x > TURRET_MAXPITCH )
					vecAngle.x = TURRET_MAXPITCH;
			}
			else
			{
				if( vecAngle.x < -TURRET_MAXPITCH )
					vecAngle.x = -TURRET_MAXPITCH;
			}

			m_pDriveEnt.GetAttachment( 0, vecSrc, void );
			Math.MakeVectors( vecAngle );
			Shoot( vecSrc, g_Engine.v_forward );			
		}
	}

	void Shoot( Vector &in vecSrc, Vector &in vecDir )
	{
		self.FireBullets( 1, vecSrc, vecDir, TURRET_SPREAD, TURRET_RANGE, BULLET_PLAYER_CUSTOMDAMAGE, 1, TURRET_DAMAGE, m_pPlayer.pev ); //BULLET_MONSTER_9MM
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsTurretSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT3)], VOL_NORM, ATTN_NORM );
		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		--m_iAmmoCurrent;
		UpdateHUD( HUD_CHANNEL_AMMO, m_iAmmoCurrent, m_iAmmoMax );
	}

	void DoAmmoRegen()
	{
		if( GetState(STATE_IDLE_INACTIVE) and m_iAmmoCurrent < m_iAmmoMax )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_iAmmoCurrent++;

				UpdateHUD( HUD_CHANNEL_AMMO, m_iAmmoCurrent, m_iAmmoMax );
				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void BlockPlayerAiming()
	{
		if( !BLOCK_PLAYER_AIMING ) return;

		if( GetState(STATE_IDLE_INACTIVE) or GetState(STATE_DEPLOYING) or GetState(STATE_RETIRING) )
		{
			m_pPlayer.pev.angles = m_pDriveEnt.pev.angles;
			m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		}
	}

	void KeepPlayerInPlace()
	{
		m_pPlayer.pev.velocity = g_vecZero;
	}

	void DoEpilepsyPrevention()
	{
		if( !EPILEPSY_PREVENTION or CNPC_FIRSTPERSON ) return;

		if( m_pDriveEnt.pev.sequence == ANIM_FIRE or m_pDriveEnt.pev.sequence == ANIM_SPIN )
		{
			if( (m_iOrientation == 0 and m_pPlayer.pev.v_angle.x <= -60.0) or (m_iOrientation == 1 and m_pPlayer.pev.v_angle.x >= 60.0) )
			{
				if( !m_hEpilepsyPreventer.IsValid() )
				{
					string szDriveEntTargetName = "cnpc_mturret_rend_" + m_pPlayer.entindex();
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
						m_hEpilepsyPreventer = EHandle( pRender );
					}
				}
			}
			else
			{
				if( m_hEpilepsyPreventer.IsValid() )
					g_EntityFuncs.Remove( m_hEpilepsyPreventer.GetEntity() );
			}
		}
		else
		{
			if( m_hEpilepsyPreventer.IsValid() )
				g_EntityFuncs.Remove( m_hEpilepsyPreventer.GetEntity() );
		}
	}

	void DoPing()
	{
		if( GetState(STATE_IDLE_ACTIVE) )
		{
			if( m_flPingTime == 0 )
				m_flPingTime = g_Engine.time + 1.0;
			else if( m_flPingTime <= g_Engine.time )
			{
				m_flPingTime = g_Engine.time + 1.0;
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsTurretSounds[SND_PING], VOL_NORM, ATTN_NORM );
			}
		}
	}

	void MoveTurret()
	{
		if( GetState(STATE_IDLE_ACTIVE) or GetState(STATE_FIRE) )
		{
			float flPitch = m_pPlayer.pev.v_angle.x;

			if( m_iOrientation == 0 )
			{
				if( flPitch > TURRET_MAXPITCH )
					flPitch = TURRET_MAXPITCH;
			}
			else
			{
				if( flPitch < -TURRET_MAXPITCH )
					flPitch = -TURRET_MAXPITCH;
			}

			if( m_iOrientation == 0 )
			{
				m_pDriveEnt.SetBoneController( 0, m_pPlayer.pev.v_angle.y - m_pDriveEnt.pev.angles.y );
				m_pDriveEnt.SetBoneController( 1, flPitch );
			}
			else
			{
				m_pDriveEnt.SetBoneController( 0, -(m_pPlayer.pev.v_angle.y - 180 - m_pDriveEnt.pev.angles.y) );
				m_pDriveEnt.SetBoneController( 1, -flPitch );
			}
		}
	}

	void RetireThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( GetState(STATE_RETIRING) )
		{
			bool state = false;

			if( m_vecCurAngles.x != m_vecGoalAngles.x )
			{
				float flDir = m_vecGoalAngles.x > m_vecCurAngles.x ? 1.0 : -1.0;

				m_vecCurAngles.x += 0.1 * m_fTurnRate * flDir;

				if( flDir == 1.0 )
				{
					if( m_vecCurAngles.x > m_vecGoalAngles.x )
						m_vecCurAngles.x = m_vecGoalAngles.x;
				} 
				else
				{
					if( m_vecCurAngles.x < m_vecGoalAngles.x )
						m_vecCurAngles.x = m_vecGoalAngles.x;
				}

				if( m_iOrientation == 0 )
					m_pDriveEnt.SetBoneController( 1, -m_vecCurAngles.x );
				else
					m_pDriveEnt.SetBoneController( 1, m_vecCurAngles.x );

				//glitchy :\
				//m_pPlayer.pev.angles.x = m_vecCurAngles.x;
				//m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
			}

			if( m_vecCurAngles.y != m_vecGoalAngles.y )
			{
				float flDir = m_vecGoalAngles.y > m_vecCurAngles.y ? 1 : -1 ;
				float flDist = abs(m_vecGoalAngles.y - m_vecCurAngles.y); //fabs

				if( flDist > 180 )
				{
					flDist = 360 - flDist;
					flDir = -flDir;
				}

				if( flDist > 30 )
				{
					if( m_fTurnRate < m_iBaseTurnRate * 10 )
						m_fTurnRate += m_iBaseTurnRate;
				}
				else if( m_fTurnRate > 45 )
					m_fTurnRate -= m_iBaseTurnRate;
				else
					m_fTurnRate += m_iBaseTurnRate;

				m_vecCurAngles.y += 0.1 * m_fTurnRate * flDir;

				if( m_vecCurAngles.y < 0 )
					m_vecCurAngles.y += 360;
				else if( m_vecCurAngles.y >= 360 )
					m_vecCurAngles.y -= 360;

				if( flDist < (0.05 * m_iBaseTurnRate) )
					m_vecCurAngles.y = m_vecGoalAngles.y;

				if( m_iOrientation == 0 )
					m_pDriveEnt.SetBoneController( 0, m_vecCurAngles.y - m_pDriveEnt.pev.angles.y );
				else 
					m_pDriveEnt.SetBoneController( 0, m_pDriveEnt.pev.angles.y - 180 - m_vecCurAngles.y );

				//glitchy :\
				//m_pPlayer.pev.angles.y = m_vecCurAngles.y;
				//m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;

				state = true;
			}

			if( !state )
				m_fTurnRate = m_iBaseTurnRate;
		}
		else
			SetThink( null );
	}

	void DoIdleAnimation()
	{
		SetState( STATE_IDLE_ACTIVE );
		SetAnim( ANIM_SPIN );
	}

	void CheckForExit()
	{
		if( m_pDriveEnt is null ) return;
		if( m_flCanExit > g_Engine.time ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_USE) != 0 )
			ExitPlayer();
	}

	void ExitPlayer( bool bManual = true )
	{
		if( bManual )
		{
			cnpc_mturret@ pDriveEnt = cast<cnpc_mturret@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );
		}

		CBaseEntity@ cbeSpawnEnt = null;
		info_cnpc_mturret@ pSpawnEnt = null;
		while( (@cbeSpawnEnt = g_EntityFuncs.FindEntityByClassname(cbeSpawnEnt, "info_cnpc_mturret")) !is null )
		{
			@pSpawnEnt = cast<info_cnpc_mturret@>(CastToScriptClass(cbeSpawnEnt));
			if( pSpawnEnt.m_pCNPCWeapon is null ) continue;
			if( pSpawnEnt.m_pCNPCWeapon.edict() is self.edict() ) break;
		}

		if( pSpawnEnt !is null )
			pSpawnEnt.m_flTimeToRespawn = g_Engine.time + CNPC_RESPAWNEXIT;

		ResetPlayer();

		Vector vecOrigin = pev.origin + Vector( 0, 0, 19 );

		if( m_iOrientation == 1 )
			vecOrigin = pev.origin + Vector( 0, 0, -19 );

		if( bManual )
		{
			g_EntityFuncs.Remove( m_pDriveEnt );
			m_pPlayer.pev.health = 100;
		}
		else
		{
			vecOrigin = m_vecExitOrigin;
			m_pPlayer.pev.angles = m_vecExitAngles;
			m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
			m_pPlayer.pev.health = 100;
			m_pPlayer.pev.velocity = g_vecZero;
		}

		g_EntityFuncs.SetOrigin( m_pPlayer, vecOrigin );
		g_EntityFuncs.Remove( self );
	}

	void spawnDriveEnt()
	{
		if( m_iOrientation == 0 and !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		if( m_iOrientation == 0 )
		{
			//Trace up then down to find the ground
			TraceResult tr;
			g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, 1) * 64, ignore_monsters, m_pPlayer.edict(), tr );
			g_Utility.TraceLine( tr.vecEndPos, tr.vecEndPos + Vector(0, 0, -1) * 128, ignore_monsters, m_pPlayer.edict(), tr );
			vecOrigin = tr.vecEndPos;
		}
		else if( m_iOrientation == 1 )
		{
			//Trace down then up to find the ceiling
			TraceResult tr;
			g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -1) * 64, ignore_monsters, m_pPlayer.edict(), tr );
			g_Utility.TraceLine( tr.vecEndPos, tr.vecEndPos + Vector(0, 0, 1) * 128, ignore_monsters, m_pPlayer.edict(), tr );
			vecOrigin = tr.vecEndPos;
		}

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_mturret", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );
		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_flCustomHealth", "" + m_flCustomHealth );

		if( (m_iSpawnFlags & CNPC::FL_NOPLAYERDEATH) != 0 )
		{
			cnpc_mturret@ pDriveEnt = cast<cnpc_mturret@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null )
			{
				pDriveEnt.m_vecExitOrigin = m_vecExitOrigin;
				pDriveEnt.m_vecExitAngles = m_vecExitAngles;
			}
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.solid = SOLID_NOT;
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		//m_pPlayer.pev.flags |= FL_FLY;
		m_pPlayer.pev.flags |= (FL_NOTARGET|FL_GODMODE);
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = DONT_BLEED;

		self.m_bExclusiveHold = true;

		if( CNPC_FIRSTPERSON )
		{
			m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_FPV_OFF : CNPC_VOFS_FPV_OFF_CL );
			DoFirstPersonView();
		}
		else
		{
			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, m_iOrientation == 0 ? CNPC_VOFS_TPV : CNPC_VOFS_TPV_CL );
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_MTURRET );

		SetHudParamsAmmo();

		g_PlayerFuncs.HudNumDisplay( m_pPlayer, m_hudParamsAmmo );
		UpdateHUD( HUD_CHANNEL_AMMO, m_iAmmoCurrent, m_iAmmoMax );

		if( m_pDriveEnt !is null )
		{
			if( m_iOrientation == 1 )
			{
				//m_pDriveEnt.pev.idealpitch = 180;
				m_pDriveEnt.pev.angles.x = 180;
				//m_pDriveEnt.pev.view_ofs.z = -m_pDriveEnt.pev.view_ofs.z;
				m_pDriveEnt.pev.effects |= EF_INVLIGHT;
				m_pDriveEnt.pev.angles.y = m_pDriveEnt.pev.angles.y + 180;

				if( m_pDriveEnt.pev.angles.y > 360 )
					m_pDriveEnt.pev.angles.y = m_pDriveEnt.pev.angles.y - 360;
			}

			m_flCanExit = g_Engine.time + 1.0;
		}
	}

	void DoFirstPersonView()
	{
		cnpc_mturret@ pDriveEnt = cast<cnpc_mturret@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_mturret_rend_" + m_pPlayer.entindex();
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
		if( m_hEpilepsyPreventer.IsValid() )
			g_EntityFuncs.Remove( m_hEpilepsyPreventer.GetEntity() );

		g_PlayerFuncs.HudToggleElement( m_pPlayer, HUD_CHANNEL_AMMO, false );
		m_pPlayer.pev.iuser3 = 0; //enable ducking
		m_pPlayer.pev.fuser4 = 0; //enable jumping
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.pev.movetype = MOVETYPE_WALK;
		m_pPlayer.pev.flags &= ~(FL_NOTARGET|FL_GODMODE|FL_FLY);
		m_pPlayer.pev.effects &= ~EF_NODRAW;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		SetSpeed( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}

	void UpdateHUD( uint8 channel, float value, float maxvalue )
	{
		switch( channel )
		{
			case HUD_CHANNEL_AMMO:
			{
				if( float(value/maxvalue) <= HUD_DANGER_CUTOFF )
					m_hudParamsAmmo.color1 = HUD_COLOR_LOW;
				else
					m_hudParamsAmmo.color1 = HUD_COLOR_NORMAL;

				g_PlayerFuncs.HudNumDisplay( m_pPlayer, m_hudParamsAmmo );

				break;
			}
		}

		g_PlayerFuncs.HudUpdateNum( m_pPlayer, channel, value );
	}

	void SetHudParamsAmmo()
	{
		m_hudParamsAmmo.channel = HUD_CHANNEL_AMMO;
		m_hudParamsAmmo.flags = HUD_ELEM_DEFAULT_ALPHA;
		m_hudParamsAmmo.value = m_iAmmoMax;
		m_hudParamsAmmo.x = HUD_AMMO_X;
		m_hudParamsAmmo.y = HUD_AMMO_Y;
		m_hudParamsAmmo.maxdigits = 3;
	}
}

class cnpc_mturret : ScriptBaseMonsterEntity
{
	float m_flCustomHealth;
	int m_iSpawnFlags;
	Vector m_vecExitOrigin, m_vecExitAngles; //for noplayerdeath

	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;

	int m_iOrientation; //0 = floor, 1 = celiing

	private float m_flDmgTime;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "orientation" )
		{
			m_iOrientation = atoi( szValue );
			return true;
		}
		else if( szKey == "m_iSpawnFlags" )
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
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN_OFF, CNPC_SIZEMAX_OFF );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		if( m_iOrientation == 0 )
			g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_FLY;
		pev.flags |= FL_MONSTER;
		pev.deadflag = DEAD_NO;
		pev.takedamage = DAMAGE_AIM;
		pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		self.m_bloodColor = DONT_BLEED;
		self.m_FormattedName = "CNPC Mini-Turret";

		pev.sequence = ANIM_IDLE_OFF;
		pev.frame = 0;
		self.ResetSequenceInfo();

		self.SetBoneController( 0, 0 );
		self.SetBoneController( 1, 0 );

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
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

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if( pev.takedamage <= DAMAGE_NO )
			return 0;

		if( pev.sequence == ANIM_IDLE_OFF )
			flDamage /= 10.0;

		pev.health -= flDamage;
		if( m_pOwner !is null and m_pOwner.IsConnected() and pev.health > 0 )
			m_pOwner.pev.health = pev.health;

		if( pev.health <= 0 )
		{
			if( m_pOwner !is null and m_pOwner.IsConnected() )
			{
				if( (m_iSpawnFlags & CNPC::FL_NOPLAYERDEATH) != 0 )
				{
					weapon_mturret@ pWeapon = cast<weapon_mturret@>( CastToScriptClass(m_pOwner.m_hActiveItem.GetEntity()) );
					if( pWeapon !is null )
						pWeapon.ExitPlayer( false );
				}
				else
					m_pOwner.Killed( pevAttacker, GIB_NEVER );
			}

			pev.health = 0;
			pev.takedamage = DAMAGE_NO;

			return 0;
		}

		pevAttacker.frags += self.GetPointsForDamage( flDamage );
		/*TODO Berserk
		if( pev.health <= 10 )
		{
			if( m_iOn and (1 || Math.RandomLong(0, 0x7FFF) > 800) )
			{
				m_fBeserk = 1;
				SetThink(&CBaseTurret::SearchThink);
			}
		}*/

		return 1;
	}

	void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType )
	{
		if( ptr.iHitgroup == 10 )
		{
			// hit armor
			if( m_flDmgTime != g_Engine.time or (Math.RandomLong(0, 10) < 1) )
			{
				g_Utility.Ricochet( ptr.vecEndPos, Math.RandomFloat(1.0, 2.0) ); 
				m_flDmgTime = g_Engine.time;
			}

			flDamage = 0.1;// don't hurt the monster much, but allow bits_COND_LIGHT_DAMAGE to be generated
		}

		if( pev.takedamage <= DAMAGE_NO )
			return;

		g_WeaponFuncs.AddMultiDamage( pevAttacker, self, flDamage, bitsDamageType );
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.takedamage = DAMAGE_NO;
			pev.solid = SOLID_NOT;

			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;
			pev.dmgtime = g_Engine.time;

			return;
		}

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		self.StudioFrameAdvance();
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.deadflag != DEAD_DEAD )
		{
			pev.deadflag = DEAD_DEAD;

			float flRndSound = Math.RandomFloat( 0 , 1 );

			if( flRndSound <= 0.33 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pDieSounds[0], VOL_NORM, ATTN_NORM );
			else if( flRndSound <= 0.66 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pDieSounds[1], VOL_NORM, ATTN_NORM );
			else 
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, pDieSounds[2], VOL_NORM, ATTN_NORM );

			//g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STATIC, arrsTurretSounds[SND_ACTIVE], 0, 0, SND_STOP, 100 );

			/*if( m_iOrientation == 0 )
				m_vecGoalAngles.x = -15;
			else
				m_vecGoalAngles.x = -90;*/

			pev.sequence = ANIM_DIE;
			pev.frame = 0;
			self.ResetSequenceInfo();
		}

		if( pev.dmgtime + Math.RandomFloat(0, 2) > g_Engine.time )
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_SMOKE );
				m1.WriteCoord( Math.RandomFloat(pev.absmin.x, pev.absmax.x) );
				m1.WriteCoord( Math.RandomFloat(pev.absmin.y, pev.absmax.y) );
				m1.WriteCoord( pev.origin.z - m_iOrientation * 64 );
				m1.WriteShort( g_EngineFuncs.ModelIndex(TURRET_SMOKE_SPRITE) );
				m1.WriteByte( 25 );
				m1.WriteByte( 10 - m_iOrientation * 5 );
			m1.End(); 
		}
		
		if( pev.dmgtime + Math.RandomFloat(0, 5) > g_Engine.time )
		{
			Vector vecSrc = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), 0 );

			if( m_iOrientation == 0 )
				vecSrc = vecSrc + Vector( 0, 0, Math.RandomFloat(pev.origin.z, pev.absmax.z) );
			else
				vecSrc = vecSrc + Vector( 0, 0, Math.RandomFloat(pev.absmin.z, pev.origin.z) );

			g_Utility.Sparks( vecSrc );
		}

		if( self.m_fSequenceFinished and pev.dmgtime + 5 < g_Engine.time )
		{
			pev.framerate = 0;
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time;
		}
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

class info_cnpc_mturret : ScriptBaseAnimating
{
	EHandle m_hCNPCWeapon;
	CBaseEntity@ m_pCNPCWeapon
	{
		get const { return m_hCNPCWeapon.GetEntity(); }
		set { m_hCNPCWeapon = EHandle(@value); }
	}

	bool m_bActive;

	private int m_iOrientation;
	private float m_flRespawnTime; //how long until respawn
	float m_flTimeToRespawn; //used to check if ready to respawn
	int m_iSpawnFlags; //Just in case
	float m_flCustomHealth;

	int ObjectCaps()
	{
		if( (m_iSpawnFlags & CNPC::FL_TRIGGER_ONLY) != 0 )
			return BaseClass.ObjectCaps();

		return m_bActive ? (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE) : BaseClass.ObjectCaps();
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}
		else if( szKey == "customhealth" )
		{
			m_flCustomHealth = atof( szValue );
			return true;
		}
		else if( szKey == "orientation" )
		{
			m_iOrientation = atoi( szValue );
			return true;
		}
		else if( szKey == "triggeronly" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_TRIGGER_ONLY;

			return true;
		}
		else if( szKey == "noplayerdeath" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_NOPLAYERDEATH;

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN_OFF, CNPC_SIZEMAX_OFF );

		Vector vecOrigin = pev.origin;
		if( m_iOrientation == 0 )
		{
			//Trace up then down to find the ground
			TraceResult tr;
			g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, 1) * 64, ignore_monsters, self.edict(), tr );
			g_Utility.TraceLine( tr.vecEndPos, tr.vecEndPos + Vector(0, 0, -1) * 128, ignore_monsters, self.edict(), tr );
			vecOrigin = tr.vecEndPos;
		}
		else if( m_iOrientation == 1 )
		{
			//Trace down then up to find the ceiling
			TraceResult tr;
			g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -1) * 64, ignore_monsters, self.edict(), tr );
			g_Utility.TraceLine( tr.vecEndPos, tr.vecEndPos + Vector(0, 0, 1) * 128, ignore_monsters, self.edict(), tr );
			vecOrigin = tr.vecEndPos;
		}

		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = ANIM_IDLE_OFF;
		pev.rendermode = kRenderTransTexture;
		pev.renderfx = kRenderFxDistort;
		pev.renderamt = 128;

		if( m_flRespawnTime <= 0 ) m_flRespawnTime = CNPC_RESPAWNTIME;
		m_bActive = true;

		self.SetBoneController( 0, 0 );
		self.SetBoneController( 1, 0 );

		SetUse( UseFunction(this.UseCNPC) );
		SetThink( ThinkFunction(this.InitializeThink) );
		pev.nextthink = g_Engine.time + 0.3;
	}

	void InitializeThink()
	{
		if( m_iOrientation == 1 )
		{
			//pev.idealpitch = 180;
			pev.angles.x = 180;
			pev.view_ofs.z = -pev.view_ofs.z;
			pev.effects |= EF_INVLIGHT;
			pev.angles.y = pev.angles.y + 180;

			if( pev.angles.y > 360 )
				pev.angles.y = pev.angles.y - 360;
		}
	}

	void UseCNPC( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( !m_bActive or !pActivator.pev.FlagBitSet(FL_CLIENT) ) return;
		if( m_iOrientation == 0 and !pActivator.pev.FlagBitSet(FL_ONGROUND) ) return;

		CustomKeyvalues@ pCustom = pActivator.GetCustomKeyvalues();
		if( pCustom.GetKeyvalue(CNPC::sCNPCKV).GetInteger() > 0 ) return;

		Vector vecNewOrigin;
		Vector vecExitOrigin = pActivator.pev.origin;
		Vector vecExitAngles = pActivator.pev.angles;

		if( m_iOrientation == 0 )
			vecNewOrigin = pev.origin + Vector(0, 0, 20);
		else if( m_iOrientation == 1 )
			vecNewOrigin = pev.origin + Vector(0, 0, -52);

		g_EntityFuncs.SetOrigin( pActivator, vecNewOrigin );
		pActivator.pev.angles = pev.angles;
		pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
		@m_pCNPCWeapon = g_EntityFuncs.Create( CNPC_WEAPONNAME, pActivator.pev.origin, g_vecZero, true );
		m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "orientation", "" + m_iOrientation );
		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "startyaw", "" + pev.angles.y );
		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_flCustomHealth", "" + m_flCustomHealth );
		g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );

		if( (m_iSpawnFlags & CNPC::FL_NOPLAYERDEATH) != 0 )
		{
			weapon_mturret@ pWeapon = cast<weapon_mturret@>( CastToScriptClass(m_pCNPCWeapon) );
			if( pWeapon !is null )
			{
				pWeapon.m_vecExitOrigin = vecExitOrigin;
				pWeapon.m_vecExitAngles = vecExitAngles;
			}
		}

		m_pCNPCWeapon.Touch( pActivator ); //make sure they pick it up

		SetUse( null );
		pev.effects |= EF_NODRAW;
		m_bActive = false;

		if( m_flRespawnTime == -1 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		SetThink( ThinkFunction(this.RespawnThink) );
		pev.nextthink = g_Engine.time;
	}

	void RespawnThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( m_pCNPCWeapon is null and m_flTimeToRespawn <= 0.0 )
			m_flTimeToRespawn = g_Engine.time +m_flRespawnTime;

		if( m_flTimeToRespawn > 0.0 and m_flTimeToRespawn <= g_Engine.time )
		{
			SetThink( null );
			SetUse( UseFunction(this.UseCNPC) );
			pev.effects &= ~EF_NODRAW;
			m_flTimeToRespawn = 0.0;
			m_bActive = true;

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsTurretSounds[SND_RESPAWN], VOL_NORM, 0.3, 0, 90 );
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_mturret::info_cnpc_mturret", "info_cnpc_mturret" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_mturret::cnpc_mturret", "cnpc_mturret" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_mturret::weapon_mturret", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_mturret" );
	g_Game.PrecacheOther( "cnpc_mturret" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_mturret END

/* FIXME
	Find out why using the normal ammo causes the turret to auto-retire
*/

/* TODO
	Use tu_active2.wav ??
*/