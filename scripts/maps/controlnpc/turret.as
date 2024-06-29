namespace cnpc_turret
{

bool CNPC_FIRSTPERSON					= true;
const bool EPILEPSY_PREVENTION		= true; //there's a lot of flashing in thirdperson view if you look up far enough

const bool ENEMY_DETECTION			= true; //Enemies within range get glowshelled in red every turret ping
const Vector ED_COLOR						=Vector( 255, 0, 0 );

const string sWeaponName				= "weapon_turret";
const string TURRET_GLOW_SPRITE	= "sprites/flare3.spr";
const string TURRET_SMOKE_SPRITE	= "sprites/steam1.spr";

const float CNPC_HEALTH					= 200.0;
const float CNPC_VIEWOFS_FPV_ON	= 0.0; //camera height offset
const float CNPC_VIEWOFS_FPV_OFF	= -16.0;
const float CNPC_VIEWOFS_TPV			= -28.0;
const float CNPC_RESPAWNTIME			= 13.0; //from the point that the weapon is removed, not the turret itself

const float CNPC_FIRERATE					= 0.05;
const float CD_DEPLOY						= 1.0;

const int AMMO_MAX							= 240;
const float AMMO_REGEN_RATE			= 0.1; //+1 per AMMO_REGEN_RATE seconds
const Vector TURRET_SPREAD				= g_vecZero;
const float TURRET_RANGE					= 1200.0;

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
	"ambience/particle_suck1.wav",
	"turret/tu_deploy.wav",
	"turret/tu_active2.wav",
	"turret/tu_spinup.wav",
	"turret/tu_spindown.wav",
	"turret/tu_ping.wav",
	"turret/tu_fire1.wav"
};

enum sound_e
{
	SND_RESPAWN,
	SND_DEPLOY = 0,
	SND_ACTIVE2,
	SND_SPINUP,
	SND_SPINDOWN,
	SND_PING,
	SND_SHOOT
};

enum anim_e
{
	ANIM_IDLE = 0,
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
	STATE_FIRE,
	STATE_DEATH
};

class weapon_turret : CBaseDriveWeapon
{
	private float m_flPingTime;
	private float m_flDetectOffTime;

	private int m_iBaseTurnRate; // angles per second
	private float m_fTurnRate; // actual turn rate

	float m_flStartYaw;
	private Vector m_vecCurAngles;
	private Vector m_vecGoalAngles;

	protected EHandle m_hEyeGlow;
	protected CSprite@ m_pEyeGlow
	{
		get const { return cast<CSprite@>(m_hEyeGlow.GetEntity()); }
		set { m_hEyeGlow = EHandle(@value); }
	}

	protected EHandle m_hEpilepsyPreventer;
	protected CBaseEntity@ m_pEpilepsyPreventer
	{
		get const { return cast<CBaseEntity@>(m_hEpilepsyPreventer.GetEntity()); }
		set { m_hEpilepsyPreventer = EHandle(@value); }
	}

	private int m_eyeBrightness;

	private HUDNumDisplayParams m_hudParamsAmmo;
	private int m_iAmmoMax;
	private int m_iAmmoCurrent;
	private float m_flNextAmmoRegen;

	private int m_iOrientation;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "orientation" )
		{
			m_iOrientation = atoi( szValue );
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

		m_iState = STATE_IDLE_INACTIVE;
		m_iBaseTurnRate = 30.0;
		m_fTurnRate = 30.0;
		m_iAmmoMax = AMMO_MAX;
		m_iAmmoCurrent = AMMO_MAX;

		m_hudParamsAmmo.color1 = HUD_COLOR_NORMAL;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/turret.mdl" );
		g_Game.PrecacheModel( TURRET_GLOW_SPRITE );
		g_Game.PrecacheModel( TURRET_SMOKE_SPRITE );

		for( uint i = 0; i < arrsTurretSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsTurretSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_turret.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_turret.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_turret_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::TURRET_SLOT - 1;
		info.iPosition		= CNPC::TURRET_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(sWeaponName) );
		m1.End();

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
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
			spawn_driveent();
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

		if( m_iState == STATE_IDLE_INACTIVE )
		{
			m_iState = STATE_DEPLOYING;
			SetAnim( ANIM_DEPLOY );
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsTurretSounds[SND_DEPLOY], 0.5, ATTN_NORM );
		}
		else if( m_iState == STATE_IDLE_ACTIVE )
		{
			m_vecCurAngles = m_pPlayer.pev.v_angle;
			m_vecGoalAngles.x = 0.0;
			m_vecGoalAngles.y = m_flStartYaw;
			m_iState = STATE_RETIRING;

			EyeOff();
			SetTurretAnim( ANIM_RETIRE );
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
		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV_OFF );
			DoFirstPersonView();
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			cnpc_turret@ pDriveEnt = cast<cnpc_turret@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			if( m_hEpilepsyPreventer.IsValid() )
				g_EntityFuncs.Remove( m_hEpilepsyPreventer.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}

		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
	}

	void Reload() //necessary to prevent the reload-key from interfering?
	{
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		DoIdleAnimation();

		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( m_pDriveEnt.pev.sequence == ANIM_DEPLOY and m_pDriveEnt.m_fSequenceFinished )
			{
				SetAnim( ANIM_SPIN );
				m_iState = STATE_IDLE_ACTIVE;
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsTurretSounds[SND_SPINUP], 0.5, ATTN_NORM );
				g_EntityFuncs.SetSize( m_pDriveEnt.pev, Vector(-32, -32, -32), Vector(32, 32, 32) );
				m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV_ON );
			}
			else if( m_pDriveEnt.pev.sequence == ANIM_RETIRE and m_pDriveEnt.m_fSequenceFinished )
			{
				SetAnim( ANIM_IDLE );
				m_iState = STATE_IDLE_INACTIVE;
				g_EntityFuncs.SetSize( m_pDriveEnt.pev, Vector(-32, -32, -16), Vector(32, 32, 16) );
				m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV_OFF );
			}
			else if( m_iState == STATE_FIRE and ((m_pPlayer.pev.button & IN_ATTACK) == 0 or m_iAmmoCurrent <= 0) )
				DoIdleAnimation();

			DoPing();
			//DoEnemyDetectionOff( m_pDriveEnt.pev.origin ); //not needed when using networkmessage
			MoveTurret();
			DoAmmoRegen();
			BlockPlayerAiming();
			KeepPlayerInPlace();
			DoEpilepsyPrevention();
		}
	}

	void DoGun()
	{
		if( m_iState == STATE_IDLE_ACTIVE )
		{
			m_iState = STATE_FIRE;
			SetAnim( ANIM_FIRE );
		}
		else if( m_iState == STATE_FIRE )
		{
			Vector vecSrc;
			Vector vecAngle = m_pPlayer.pev.v_angle;
			m_pDriveEnt.GetAttachment( 0, vecSrc, void );
			Math.MakeVectors( vecAngle );
			Shoot( vecSrc, g_Engine.v_forward );			
		}
	}

	void Shoot( Vector &in vecSrc, Vector &in vecDir )
	{
		m_pDriveEnt.FireBullets( 1, vecSrc, vecDir, TURRET_SPREAD, TURRET_RANGE, BULLET_MONSTER_12MM, 1 );
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsTurretSounds[SND_SHOOT], VOL_NORM, 0.6 );
		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		--m_iAmmoCurrent;
		UpdateHUD( HUD_CHANNEL_AMMO, m_iAmmoCurrent, m_iAmmoMax );
	}

	void DoAmmoRegen()
	{
		if( m_iState == STATE_IDLE_INACTIVE and m_iAmmoCurrent < m_iAmmoMax )
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
		if( m_iState == STATE_IDLE_INACTIVE or m_iState == STATE_DEPLOYING or m_iState == STATE_RETIRING )
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
			if( m_pPlayer.pev.v_angle.x <= -60.0 )
			{
				if( !m_hEpilepsyPreventer.IsValid() )
				{
					string szDriveEntTargetName = "cnpc_turret_pid_" + m_pPlayer.entindex();
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
		if( m_iState == STATE_IDLE_ACTIVE )
		{
			if( m_flPingTime == 0 )
				m_flPingTime = g_Engine.time + 1.0;
			else if( m_flPingTime <= g_Engine.time )
			{
				m_flPingTime = g_Engine.time + 1.0;
				m_flDetectOffTime = g_Engine.time + 0.8;
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsTurretSounds[SND_PING], VOL_NORM, ATTN_NORM );

				EyeOn();
				DoEnemyDetectionOn();
			}
			else if (m_eyeBrightness > 0)
				EyeOff();
		}
	}

	void EyeOn()
	{
		if( m_pEyeGlow !is null )
		{
			if (m_eyeBrightness != 255)
				m_eyeBrightness = 255;

			m_pEyeGlow.SetBrightness( m_eyeBrightness );
		}
	}

	void EyeOff()
	{
		if( m_pEyeGlow !is null )
		{
			if( m_eyeBrightness > 0 )
			{
				m_eyeBrightness = Math.max( 0, m_eyeBrightness - 30 );
				m_pEyeGlow.SetBrightness( m_eyeBrightness );
			}
		}
	}

	void DoEnemyDetectionOn()
	{
		if( !ENEMY_DETECTION ) return;

		CBaseEntity@ pTarget = null;
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, m_pDriveEnt.pev.origin, TURRET_RANGE/2, "*", "classname")) !is null )
		{
			int rel = m_pPlayer.IRelationship(pTarget);
			bool isFriendly = rel == R_AL or rel == R_NO;

			if( !pTarget.pev.FlagBitSet(FL_MONSTER) or !pTarget.IsAlive() or isFriendly )
				continue;

			/*NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
				m1.WriteByte( TE_DLIGHT );
				m1.WriteCoord( pTarget.Center().x );
				m1.WriteCoord( pTarget.Center().y );
				m1.WriteCoord( pTarget.Center().z );
				m1.WriteByte( 32 ); //radius in 10's
				m1.WriteByte( int(ED_COLOR.x) ); //r g b
				m1.WriteByte( int(ED_COLOR.y) );
				m1.WriteByte( int(ED_COLOR.z) );
				m1.WriteByte( 255 ); //life in 10's
				m1.WriteByte( 50 ); //decay rate in 10's
			m1.End();*/

			NetworkMessage m2( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
				m2.WriteByte( TE_ELIGHT );
				//m2.WriteShort( pTarget.entindex() + 0x1000 * (i + 2) );		// entity, attachment
				m2.WriteShort( pTarget.entindex() );
				m2.WriteCoord( pTarget.Center().x );		// origin
				m2.WriteCoord( pTarget.Center().y );
				m2.WriteCoord( pTarget.Center().z );
				m2.WriteCoord( 1024 );	// radius
				m2.WriteByte( int(ED_COLOR.x) );	// R
				m2.WriteByte( int(ED_COLOR.y) );	// G
				m2.WriteByte( int(ED_COLOR.z) );	// B
				m2.WriteByte( 16 );	// life * 10
				m2.WriteCoord( 2000 ); // decay
			m2.End(); 

			/*if( pTarget.pev.renderfx == kRenderFxNone )
			{
				pTarget.pev.renderfx = kRenderFxGlowShell;
				pTarget.pev.rendercolor = Vector(255, 0, 0);
				pTarget.pev.renderamt = 64;
				CustomKeyvalues@ pCustom = pTarget.GetCustomKeyvalues();
				pCustom.InitializeKeyvalueWithDefault( "$i_cnpc_isturrettarget" );
				pCustom.SetKeyvalue( "$i_cnpc_isturrettarget", 1 );
			}*/
		}
	}

	//not needed when using networkmessage
	/*void DoEnemyDetectionOff( Vector vecOrigin, bool bTurretDead = false )
	{
		if( !ENEMY_DETECTION ) return;

		if( m_flDetectOffTime <= g_Engine.time or bTurretDead )
		{
			CBaseEntity@ pTarget = null;
			while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, vecOrigin, 8192.0, "*", "classname")) !is null )
			{
				int rel = m_pPlayer.IRelationship(pTarget);
				bool isFriendly = rel == R_AL or rel == R_NO;

				if( !pTarget.pev.FlagBitSet(FL_MONSTER) or isFriendly )
					continue;

				CustomKeyvalues@ pCustom = pTarget.GetCustomKeyvalues();
				if( pCustom.GetKeyvalue("$i_cnpc_isturrettarget").GetInteger() == 1 )
				{
					pTarget.pev.renderfx = kRenderFxNone;
					pCustom.SetKeyvalue( "$i_cnpc_isturrettarget", 0 );
				}
			}
		}
	}*/

	void MoveTurret()
	{
		if( m_iState == STATE_IDLE_ACTIVE or m_iState == STATE_FIRE )
		{
			if( m_pPlayer.pev.v_angle.x > 40.0 )
			{
				m_pPlayer.pev.angles.x = 40.0;
				m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
			}

			m_pDriveEnt.SetBoneController( 0, m_pPlayer.pev.v_angle.y - m_pDriveEnt.pev.angles.y );
			m_pDriveEnt.SetBoneController( 1, m_pPlayer.pev.v_angle.x );
		}
	}

	void RetireThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( m_iState == STATE_RETIRING )
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

				//if( m_iOrientation == 0 )
					//m_pDriveEnt.SetBoneController( 1, -m_vecCurAngles.x );
				//else
					m_pDriveEnt.SetBoneController(1, m_vecCurAngles.x);

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

				//if (m_iOrientation == 0)
					m_pDriveEnt.SetBoneController(0, m_vecCurAngles.y - m_pDriveEnt.pev.angles.y );
				//else 
					//m_pDriveEnt.SetBoneController( 0, m_pDriveEnt.pev.angles.y - 180 - m_vecCurAngles.y );

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

	void SetTurretAnim( int anim )
	{
		if( m_pDriveEnt.pev.sequence != anim )
		{
			switch( anim )
			{
				case ANIM_FIRE:
				case ANIM_SPIN:
				{
					if( m_pDriveEnt.pev.sequence != ANIM_FIRE and m_pDriveEnt.pev.sequence != ANIM_SPIN )
						pev.frame = 0;

					break;
				}

				default:
				{
					pev.frame = 0;
					break;
				}
			}

			m_pDriveEnt.pev.sequence = anim;
			m_pDriveEnt.ResetSequenceInfo();

			switch( anim )
			{
				case ANIM_RETIRE:
				{
					m_pDriveEnt.pev.frame			= 255;
					m_pDriveEnt.pev.framerate		= -1.0;
					break;
				}

				case ANIM_DIE:
				{
					m_pDriveEnt.pev.framerate		= 1.0;
					break;
				}
			}
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;

		m_iState = STATE_IDLE_ACTIVE;
		SetAnim( ANIM_SPIN );
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		if( m_iAutoDeploy == 0 )
			vecOrigin.z -= 32.0;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_turret", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.movetype = MOVETYPE_NONE;
		m_pPlayer.pev.flags |= FL_FLY;
		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = DONT_BLEED;

		self.m_bExclusiveHold = true;

		if( CNPC_FIRSTPERSON )
		{
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV_OFF );
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_TURRET );

		if( m_pDriveEnt !is null )
		{
			@m_pEyeGlow = g_EntityFuncs.CreateSprite( TURRET_GLOW_SPRITE, m_pDriveEnt.pev.origin, false );
			@m_pEyeGlow.pev.owner = m_pDriveEnt.edict();
			m_pEyeGlow.SetTransparency( kRenderGlow, 255, 0, 0, 0, kRenderFxNoDissipation );
			m_pEyeGlow.SetAttachment( m_pDriveEnt.edict(), 2 );
			m_eyeBrightness = 0;
		}

		SetHudParamsAmmo();

		g_PlayerFuncs.HudNumDisplay( m_pPlayer, m_hudParamsAmmo );
		UpdateHUD( HUD_CHANNEL_AMMO, m_iAmmoCurrent, m_iAmmoMax );
	}

	void DoFirstPersonView()
	{
		cnpc_turret@ pDriveEnt = cast<cnpc_turret@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_turret_pid_" + m_pPlayer.entindex();
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
		//DoEnemyDetectionOff( m_pPlayer.pev.origin, true ); //not needed when using networkmessage

		if( m_hEpilepsyPreventer.IsValid() )
			g_EntityFuncs.Remove( m_hEpilepsyPreventer.GetEntity() );

		g_PlayerFuncs.HudToggleElement( m_pPlayer, HUD_CHANNEL_AMMO, false );
		m_pPlayer.pev.fuser4 = 0; //enable jump
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.pev.movetype = MOVETYPE_WALK;
		m_pPlayer.pev.flags &= ~FL_FLY;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

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

class cnpc_turret : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;

	int m_iOrientation;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/turret.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-32, -32, -16), Vector(32, 32, 16) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		self.SetBoneController( 0, 0 );
		self.SetBoneController( 1, 0 );

		m_iOrientation = 0; //0 = floor, 1 = celiing

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

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

			//g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STATIC, "turret/tu_active2.wav", 0, 0, SND_STOP,100 );

			/*if( m_iOrientation == 0 )
				m_vecGoalAngles.x = -15;
			else
				m_vecGoalAngles.x = -90;*/

			pev.sequence = ANIM_DIE;
			pev.frame = 0;
			self.ResetSequenceInfo();

			CBaseEntity@ pEyeSprite = null;
			do( @pEyeSprite = g_EntityFuncs.FindEntityByClassname( pEyeSprite, "env_sprite" ) );
			while( pEyeSprite.pev.owner !is self.edict() );

			if( pEyeSprite !is null ) g_EntityFuncs.Remove(pEyeSprite );
		}

		if( pev.dmgtime + Math.RandomFloat(0, 2) > g_Engine.time )
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_SMOKE );
				m1.WriteCoord( Math.RandomFloat(pev.absmin.x, pev.absmax.x) );
				m1.WriteCoord( Math.RandomFloat(pev.absmin.y, pev.absmax.y) );
				m1.WriteCoord( pev.origin.z - m_iOrientation * 64 );
				m1.WriteShort( g_EngineFuncs.ModelIndex(TURRET_SMOKE_SPRITE) );
				m1.WriteByte( 25 ); // scale * 10
				m1.WriteByte( 10 - m_iOrientation * 5 ); // framerate
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

class info_cnpc_turret : ScriptBaseAnimating
{
	protected EHandle m_hCNPCWeapon;
	protected CBaseEntity@ m_pCNPCWeapon
	{
		get const { return cast<CBaseEntity@>(m_hCNPCWeapon.GetEntity()); }
		set { m_hCNPCWeapon = EHandle(@value); }
	}

	//private int m_iOrientation; //TODO
	private float m_flRespawnTime; //how long until respawn
	private float m_flTimeToRespawn; //used to check if ready to respawn

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}//TODO
		/*else if( szKey == "orientation" )
		{
			m_iOrientation = atoi( szValue );
			return true;
		}*/
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/turret.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-32, -32, -16), Vector(32, 32, 16) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = ANIM_IDLE;
		pev.rendermode = kRenderTransTexture;
		pev.renderfx = kRenderFxDistort;
		pev.renderamt = 128;

		if( m_flRespawnTime <= 0 ) m_flRespawnTime = CNPC_RESPAWNTIME;

		self.SetBoneController( 0, 0 );
		self.SetBoneController( 1, 0 );

		SetUse( UseFunction(this.UseCNPC) );
	}

	int ObjectCaps() { return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE); }

	void UseCNPC( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue  ) 
	{
		if( pActivator.pev.FlagBitSet(FL_CLIENT) and pActivator.pev.FlagBitSet(FL_ONGROUND) )
		{
			g_EntityFuncs.SetOrigin( pActivator, pev.origin );
			pActivator.pev.angles = pev.angles;
			pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
			@m_pCNPCWeapon = g_EntityFuncs.Create( sWeaponName, pActivator.pev.origin, g_vecZero, true );
			m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

			g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
			g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "startyaw", "" + pev.angles.y );
			g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );
			m_pCNPCWeapon.Touch( pActivator ); //make sure they pick it up

			SetUse( null );
			pev.effects |= EF_NODRAW;

			if( m_flRespawnTime == -1 )
			{
				g_EntityFuncs.Remove( self );
				return;
			}

			SetThink( ThinkFunction(this.RespawnThink) );
			pev.nextthink = g_Engine.time;
		}
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

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsTurretSounds[SND_RESPAWN], VOL_NORM, 0.3, 0, 90 );
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_turret::info_cnpc_turret", "info_cnpc_turret" );
	g_Game.PrecacheOther( "info_cnpc_turret" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_turret::cnpc_turret", "cnpc_turret" );
	g_Game.PrecacheOther( "cnpc_turret" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_turret::weapon_turret", sWeaponName );
	g_ItemRegistry.RegisterWeapon( sWeaponName, "controlnpc" );
	g_Game.PrecacheOther( sWeaponName );
}

} //namespace cnpc_turret END

/* FIXME
	Find out why using the normal ammo causes the turret to auto-retire
	Bullets fired from the turret hurt other players, but when fired from the player they're invisible
*/

/* TODO
	Add ceiling mount, m_iOrientation
	Add tu_active2.wav ??
*/