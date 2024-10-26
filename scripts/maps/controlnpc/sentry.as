namespace cnpc_sentry
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_sentry";
const string CNPC_MODEL				= "models/sentry.mdl";
const Vector CNPC_SIZEMIN			= Vector( -16, -16, 0 );
const Vector CNPC_SIZEMAX			= Vector( 16, 16, 64 );

const string SMOKE_SPRITE			= "sprites/steam1.spr";

const float CNPC_HEALTH				= 80.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the sentry itself
const float CNPC_RESPAWNEXIT		= 5.0; //time until it can be used again after a player exits
const float CNPC_MODEL_OFFSET	= 32.0; //the player gets teleported into the floor when using NPC hitboxes

const float CNPC_FIRERATE				= 0.1;
const float CD_DEPLOY					= 1.0;

const int AMMO_MAX						= 120;
const float AMMO_REGEN_RATE		= 0.1; //+1 per AMMO_REGEN_RATE seconds
const Vector TURRET_SPREAD			= VECTOR_CONE_2DEGREES; //the npc has g_vecZero
const float TURRET_RANGE				= 1200.0;
const float TURRET_DAMAGE			= 6.0; //sk_9mmAR_bullet
const float TURRET_MAXPITCH		= 65.0; //the turret can't be aimed lower than this

//forced to use this because of some bug with the normal usage of ammo
const int HUD_CHANNEL_AMMO		= 9; //0-15

const float HUD_CLIP_X					= 0.85;
const float HUD_CLIP_Y					= 1.0;
const float HUD_AMMO_X				= 0.9;
const float HUD_AMMO_Y				= 1.0;
const float HUD_DANGER_CUTOFF	= 0.2;

const RGBA HUD_COLOR_NORMAL	= RGBA_SVENCOOP;
const RGBA HUD_COLOR_LOW		= RGBA(255, 0, 0, 255);

const array<string> pDieSounds = 
{
	"turret/tu_die.wav",
	"turret/tu_die2.wav",
	"turret/tu_die3.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"turret/tu_deploy.wav",
	//"turret/tu_active2.wav",
	"turret/tu_spinup.wav",
	"turret/tu_spindown.wav",
	"turret/tu_ping.wav",
	"weapons/hks_hl1.wav",
	"weapons/hks_hl2.wav",
	"weapons/hks_hl3.wav"
};

enum sound_e
{
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
	ANIM_DEATH
};

enum states_e
{
	STATE_IDLE_INACTIVE = 0,
	STATE_IDLE_ACTIVE,
	STATE_DEPLOYING,
	STATE_RETIRING,
	STATE_FIRE
};

class weapon_sentry : CBaseDriveWeapon
{
	Vector m_vecExitOrigin, m_vecExitAngles; //for noplayerdeath

	private float m_flCanExit;

	private float m_flPingTime;

	private int m_iBaseTurnRate; //angles per second
	private float m_flTurnRate; //actual turn rate

	float m_flStartYaw;
	private Vector m_vecCurAngles;
	private Vector m_vecGoalAngles;

	private HUDNumDisplayParams m_hudParamsAmmo;
	private int m_iAmmoMax;
	private int m_iAmmoCurrent;
	private float m_flNextAmmoRegen;

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
		m_flTurnRate = 30.0;
		m_iAmmoMax = AMMO_MAX;
		m_iAmmoCurrent = AMMO_MAX;
		m_flCanExit = 0.0;

		m_hudParamsAmmo.color1 = HUD_COLOR_NORMAL;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( SMOKE_SPRITE );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_sentry.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_sentry.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_sentry_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::SENTRY_SLOT - 1;
		info.iPosition			= CNPC::SENTRY_POSITION - 1;
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

		ResetPlayer();

		BaseClass.Holster( skipLocal );
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
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CNPC_FIRERATE;
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
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_DEPLOY], 0.5, ATTN_NORM );
		}
		else if( GetState(STATE_IDLE_ACTIVE) )
		{
			m_vecCurAngles = m_pPlayer.pev.v_angle;
			m_vecGoalAngles.x = 0.0;
			m_vecGoalAngles.y = m_flStartYaw;
			SetState( STATE_RETIRING );

			SetAnim( ANIM_RETIRE, -1.0, 255 );
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_SPINDOWN], 0.5, ATTN_NORM );
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_DEPLOY], 0.5, ATTN_NORM, 0, 120 );

			SetThink( ThinkFunction(this.RetireThink) );
			pev.nextthink = g_Engine.time + 0.1;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_DEPLOY;
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
			cnpc_sentry@ pDriveEnt = cast<cnpc_sentry@>(CastToScriptClass(m_pDriveEnt));
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
			SetSpeed( 0 );

			if( m_pDriveEnt.pev.sequence == ANIM_DEPLOY and m_pDriveEnt.m_fSequenceFinished )
			{
				SetAnim( ANIM_SPIN );
				SetState( STATE_IDLE_ACTIVE );
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_SPINUP], 0.5, ATTN_NORM );
			}
			else if( m_pDriveEnt.pev.sequence == ANIM_RETIRE and m_pDriveEnt.m_fSequenceFinished )
			{
				SetAnim( ANIM_IDLE_OFF );
				SetState( STATE_IDLE_INACTIVE );
			}
			else if( GetState(STATE_FIRE) and ((m_pPlayer.pev.button & IN_ATTACK) == 0 or m_iAmmoCurrent <= 0) )
				DoIdleAnimation();

			DoPing();
			MoveTurret();
			DoAmmoRegen();
			KeepPlayerInPlace();
			CheckForExit();

			if( m_flNextThink <= g_Engine.time )
			{
				IdleSpin();
				m_flNextThink = g_Engine.time + 0.05;
			}
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
			if( vecAngle.x > TURRET_MAXPITCH )
				vecAngle.x = TURRET_MAXPITCH;

			m_pDriveEnt.GetAttachment( 0, vecSrc, void );
			Math.MakeVectors( vecAngle );
			Shoot( vecSrc, g_Engine.v_forward );			
		}
	}

	void Shoot( Vector &in vecSrc, Vector &in vecDir )
	{
		self.FireBullets( 1, vecSrc, vecDir, TURRET_SPREAD, TURRET_RANGE, BULLET_PLAYER_CUSTOMDAMAGE, 1, TURRET_DAMAGE, m_pPlayer.pev ); //BULLET_MONSTER_MP5
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT3)], VOL_NORM, ATTN_NORM );
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

	void KeepPlayerInPlace()
	{
		m_pPlayer.pev.velocity = g_vecZero;
		m_pPlayer.pev.solid = SOLID_NOT;
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		m_pPlayer.pev.flags |= (FL_FLY|FL_NOTARGET|FL_GODMODE);
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
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_PING], VOL_NORM, ATTN_NORM );
			}
		}
	}

	void MoveTurret()
	{
		if( (GetState(STATE_IDLE_ACTIVE) and (m_pPlayer.pev.button & IN_DUCK) == 0) or GetState(STATE_FIRE) )
		{
			float flPitch = m_pPlayer.pev.v_angle.x;
			if( flPitch > TURRET_MAXPITCH )
				flPitch = TURRET_MAXPITCH;

			m_pDriveEnt.SetBoneController( 0, m_pPlayer.pev.v_angle.y - m_pDriveEnt.pev.angles.y );
			m_pDriveEnt.SetBoneController( 1, flPitch );
		}
	}

	void IdleSpin()
	{
		if( !GetState(STATE_IDLE_ACTIVE) or (m_pPlayer.pev.button & IN_DUCK) == 0 ) return;

		m_vecCurAngles.y += 0.1 * m_iBaseTurnRate;

		if( m_vecCurAngles.y < 0 )
			m_vecCurAngles.y += 360;
		else if( m_vecCurAngles.y >= 360 )
			m_vecCurAngles.y -= 360;

		m_pDriveEnt.SetBoneController( 0, m_vecCurAngles.y - m_pDriveEnt.pev.angles.y );
		m_pDriveEnt.SetBoneController( 1, 0 );
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

				m_vecCurAngles.x += 0.1 * m_flTurnRate * flDir;

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

				m_pDriveEnt.SetBoneController( 1, -m_vecCurAngles.x );
			}

			if( m_vecCurAngles.y != m_vecGoalAngles.y )
			{
				float flDir = m_vecGoalAngles.y > m_vecCurAngles.y ? 1 : -1 ;
				float flDist = abs(m_vecGoalAngles.y - m_vecCurAngles.y);

				if( flDist > 180 )
				{
					flDist = 360 - flDist;
					flDir = -flDir;
				}

				if( flDist > 30 )
				{
					if( m_flTurnRate < m_iBaseTurnRate * 10 )
						m_flTurnRate += m_iBaseTurnRate;
				}
				else if( m_flTurnRate > 45 )
					m_flTurnRate -= m_iBaseTurnRate;
				else
					m_flTurnRate += m_iBaseTurnRate;

				m_vecCurAngles.y += 0.1 * m_flTurnRate * flDir;

				if( m_vecCurAngles.y < 0 )
					m_vecCurAngles.y += 360;
				else if( m_vecCurAngles.y >= 360 )
					m_vecCurAngles.y -= 360;

				if( flDist < (0.05 * m_iBaseTurnRate) )
					m_vecCurAngles.y = m_vecGoalAngles.y;

				m_pDriveEnt.SetBoneController( 0, m_vecCurAngles.y - m_pDriveEnt.pev.angles.y );

				state = true;
			}

			if( !state )
				m_flTurnRate = m_iBaseTurnRate;
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
			cnpc_sentry@ pDriveEnt = cast<cnpc_sentry@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );
		}

		CBaseEntity@ cbeSpawnEnt = null;
		info_cnpc_sentry@ pSpawnEnt = null;
		while( (@cbeSpawnEnt = g_EntityFuncs.FindEntityByClassname(cbeSpawnEnt, "info_cnpc_sentry")) !is null )
		{
			@pSpawnEnt = cast<info_cnpc_sentry@>(CastToScriptClass(cbeSpawnEnt));
			if( pSpawnEnt.m_pCNPCWeapon is null ) continue;
			if( pSpawnEnt.m_pCNPCWeapon.edict() is self.edict() ) break;
		}

		if( pSpawnEnt !is null )
			pSpawnEnt.m_flTimeToRespawn = g_Engine.time + CNPC_RESPAWNEXIT;

		ResetPlayer();

		//Vector vecOrigin = pev.origin + Vector( 0, 0, 19 );
		Vector vecOrigin = m_vecExitOrigin + Vector( 0, 0, 8 );

		if( bManual )
		{
			g_EntityFuncs.Remove( m_pDriveEnt );
			m_pPlayer.pev.health = 100;
		}
		else
		{
			//vecOrigin = m_vecExitOrigin + Vector( 0, 0, 19 );
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
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_sentry", vecOrigin, Vector(0, m_flStartYaw, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			m_pDriveEnt.SetBoneController( 0, 0 );
			m_pDriveEnt.SetBoneController( 1, 0 );

			m_flCanExit = g_Engine.time + 1.0;
		}

		cnpc_sentry@ pDriveEnt = cast<cnpc_sentry@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt !is null )
		{
			pDriveEnt.m_vecExitOrigin = m_vecExitOrigin;
			pDriveEnt.m_vecExitAngles = m_vecExitAngles;
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.solid = SOLID_NOT;
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		m_pPlayer.pev.flags |= (FL_FLY|FL_NOTARGET|FL_GODMODE);
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_SENTRY );

		SetHudParamsAmmo();

		g_PlayerFuncs.HudNumDisplay( m_pPlayer, m_hudParamsAmmo );
		UpdateHUD( HUD_CHANNEL_AMMO, m_iAmmoCurrent, m_iAmmoMax );
	}

	void DoFirstPersonView()
	{
		cnpc_sentry@ pDriveEnt = cast<cnpc_sentry@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_sentry_rend_" + m_pPlayer.entindex();
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

class cnpc_sentry : ScriptBaseMonsterEntity
{
	int m_iSpawnFlags;
	float m_flCustomHealth;

	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;

	Vector m_vecExitOrigin, m_vecExitAngles; //for noplayerdeath

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

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		TraceResult tr;
		g_Utility.TraceLine( pev.origin, pev.origin + Vector(0, 0, 1) * 64, ignore_monsters, self.edict(), tr );
		g_Utility.TraceLine( tr.vecEndPos, tr.vecEndPos + Vector(0, 0, -1) * 128, ignore_monsters, self.edict(), tr );
		g_EntityFuncs.SetOrigin( self, tr.vecEndPos );
		//g_EngineFuncs.DropToFloor( self.edict() ); //causes the hitbox to get messed up

		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_FLY;
		pev.flags |= FL_MONSTER;
		pev.deadflag = DEAD_NO;
		pev.takedamage = DAMAGE_AIM;
		pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		self.m_bloodColor = DONT_BLEED;
		self.m_FormattedName = "CNPC Sentry";

		pev.sequence = ANIM_IDLE_OFF;
		pev.frame = 0;
		self.ResetSequenceInfo();

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

		//Prevent player damage
		CBaseEntity@ pInflictor = g_EntityFuncs.Instance(pevInflictor);
		if( pInflictor !is null and m_pOwner.IRelationship(pInflictor) <= R_NO )
			return 0;

		pev.health -= flDamage;
		if( m_pOwner !is null and m_pOwner.IsConnected() and pev.health > 0 )
			m_pOwner.pev.health = pev.health;

		if (pev.health <= 0)
		{
			if( m_pOwner !is null and m_pOwner.IsConnected() )
			{
				if( (m_iSpawnFlags & CNPC::FL_NOPLAYERDEATH) != 0 )
				{
					weapon_sentry@ pWeapon = cast<weapon_sentry@>( CastToScriptClass(m_pOwner.m_hActiveItem.GetEntity()) );
					if( pWeapon !is null )
						pWeapon.ExitPlayer( false );
				}
				else
					m_pOwner.Killed( pevAttacker, GIB_NEVER );
			}

			pev.health = 0;
			pev.takedamage = DAMAGE_NO;
			pev.dmgtime = g_Engine.time;

			pev.flags &= ~FL_MONSTER;

			//Death is handled by killing the player
			//SetThink( ThinkFunction(this.SentryDeath) );
			//pev.nextthink = g_Engine.time + 0.1;

			return 0;
		}

		pevAttacker.frags += self.GetPointsForDamage( flDamage );

		return 1;
	}

	void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType )
	{
		if( pev.takedamage <= DAMAGE_NO )
			return;

		g_WeaponFuncs.AddMultiDamage( pevAttacker, self, flDamage, bitsDamageType );
	}

	void DriveThink()
	{
		if( pev.deadflag == CNPC::DEAD_GIB )
		{
			DoDeath( true );

			return;
		}

		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			DoDeath();

			return;
		}

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath( bool bGibbed = false )
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		pev.velocity = g_vecZero;

		if( bGibbed )
		{
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		SetThink( ThinkFunction(this.SentryDeath) );
		pev.nextthink = g_Engine.time + 0.1;
		pev.dmgtime = g_Engine.time;
	}

	void SentryDeath()
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

			//g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_STATIC, arrsCNPCSounds[SND_ACTIVE], 0, 0, SND_STOP, 100 );

			self.SetBoneController( 0, 0 );
			self.SetBoneController( 1, 0 );

			pev.sequence = ANIM_DEATH;
			pev.frame = 0;
			self.ResetSequenceInfo();

			pev.solid = SOLID_NOT;
			pev.angles.y = Math.AngleMod( pev.angles.y + Math.RandomLong(0, 2) * 120 );
		}

		Vector vecSrc;
		self.GetAttachment( 1, vecSrc, void );

		if( pev.dmgtime + Math.RandomFloat(0, 2) > g_Engine.time )
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_SMOKE );
				m1.WriteCoord( vecSrc.x + Math.RandomFloat(-16, 16) );
				m1.WriteCoord( vecSrc.y + Math.RandomFloat(-16, 16) );
				m1.WriteCoord( vecSrc.z - 32 );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SMOKE_SPRITE) );
				m1.WriteByte( 15 );
				m1.WriteByte( 8 );
			m1.End(); 
		}

		if( pev.dmgtime + Math.RandomFloat(0, 8) > g_Engine.time )
			g_Utility.Sparks( vecSrc );

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

final class info_cnpc_sentry : CNPCSpawnEntity
{
	info_cnpc_sentry()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE_OFF;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
		m_flSpawnOffset = CNPC_MODEL_OFFSET;
	}

	void DoSpecificStuff()
	{
		self.SetBoneController( 0, 0 );
		self.SetBoneController( 1, 0 );
	}

	void SpecialUse( Vector vecOrigin, Vector vecAngles )
	{
		weapon_sentry@ pWeapon = cast<weapon_sentry@>( CastToScriptClass(m_pCNPCWeapon) );
		if( pWeapon !is null )
		{
			pWeapon.m_vecExitOrigin = vecOrigin;
			pWeapon.m_vecExitAngles = vecAngles;
		}

		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "startyaw", "" + pev.angles.y );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_sentry::info_cnpc_sentry", "info_cnpc_sentry" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_sentry::cnpc_sentry", "cnpc_sentry" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_sentry::weapon_sentry", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_sentry" );
	g_Game.PrecacheOther( "cnpc_sentry" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_sentry END

/* FIXME
	Find out why using the normal ammo causes the turret to auto-retire
*/

/* TODO
	Use tu_active2.wav ??
*/