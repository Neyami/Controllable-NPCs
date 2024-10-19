namespace cnpc_q2supertank
{

const bool CNPC_NPC_HITBOX		= true; //Use the hitbox of the monster model instead of the player. Experimental!
const string CNPC_DISPLAYNAME	= "CNPC Q2 Super Tank";
bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2supertank";
const string CNPC_MODEL				= "models/quake2/monsters/supertank/supertank.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_METAL		= "models/quake2/objects/gibs/sm_metal.mdl";
const string MODEL_GIB_CGUN		= "models/quake2/monsters/supertank/gibs/cgun.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/supertank/gibs/chest.mdl";
const string MODEL_GIB_CORE		= "models/quake2/monsters/supertank/gibs/core.mdl";
const string MODEL_GIB_LTREAD	= "models/quake2/monsters/supertank/gibs/ltread.mdl";
const string MODEL_GIB_RTREAD	= "models/quake2/monsters/supertank/gibs/rtread.mdl";
const string MODEL_GIB_RGUN		= "models/quake2/monsters/supertank/gibs/rgun.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/supertank/gibs/tube.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/supertank/gibs/head.mdl";

const Vector CNPC_SIZEMIN			= Vector( -80, -80, 0 );
const Vector CNPC_SIZEMAX			= Vector( 80, 80, 142 );

const float CNPC_HEALTH				= 1500.0;
const float CNPC_VIEWOFS_FPV		= 117.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 128.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the supertank itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_RUN					= -1;

const float CNPC_MAXPITCH			= 30.0;

const float CD_ROCKET					= 2.0;
const float ROCKET_DMG				= 50;
const float ROCKET_SPEED				= 750;

const float CD_CHAINGUN				= 0.5;
const float CHAINGUN_FIRERATE		= 0.10;
const int CHAINGUN_AMMO			= 150;
const float CHAINGUN_DAMAGE		= 6.0;
const int AMMO_REGEN_AMOUNT	= 3;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds

const float CD_GRENADE				= 2.0;
const float GRENADE_DMG				= 50;
const float GRENADE_SPEED			= 750;

const array<string> pPainSounds = 
{
	"quake2/npcs/supertank/btkpain1.wav",
	"quake2/npcs/supertank/btkpain2.wav",
	"quake2/npcs/supertank/btkpain3.wav"
};

const array<string> pDieSounds = 
{
	"quake2/npcs/supertank/btkdeth1.wav"
};

const array<string> pExplosionSprites = 
{
	"sprites/exp_a.spr",
	"sprites/bexplo.spr",
	"sprites/dexplo.spr",
	"sprites/eexplo.spr"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/supertank/btkunqv1.wav",
	"quake2/npcs/supertank/btkunqv2.wav",
	"quake2/npcs/supertank/btkengn1.wav",
	"quake2/weapons/rocket_explode.wav",
	"quake2/npcs/infantry/infatck1.wav", //machine gun
	"quake2/weapons/rocklf1a.wav", //rocket launcher
	"quake2/weapons/grenlf1a.wav" //grenade launcher
};

enum sound_e
{
	SND_GIB = 1,
	SND_SEARCH1,
	SND_SEARCH2,
	SND_TREAD,
	SND_EXPLOSION,
	SND_CHAINGUN,
	SND_ROCKET,
	SND_GRENADE
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_FORWARD,
	ANIM_BACKWARD,	//18
	ANIM_TURN_LEFT,	//18
	ANIM_TURN_RIGHT,	//18
	ANIM_ATK_CHAINGUN,
	ANIM_ATK_CHAINGUN_END,
	ANIM_ATK_ROCKET,
	ANIM_ATK_GRENADE,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_DEATH
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_PAIN,
	STATE_MOVING,
	STATE_ATK_CHAINGUN,
	STATE_ATK_CHAINGUN_END,
	STATE_ATK_ROCKET,
	STATE_ATK_GRENADE
};

enum attach_e
{
	ATTACH_CG_MUZZLE = 0,
	ATTACH_ROCKET_MIDDLE,
	ATTACH_GREN_LEFT,
	ATTACH_GREN_RIGHT
};

final class weapon_q2supertank : CBaseDriveWeaponQ2
{
	private float m_flNextAmmoRegen;
	private float m_flNextGrenade;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_CGUN );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_CORE );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_LTREAD );
		g_Game.PrecacheModel( MODEL_GIB_RTREAD );
		g_Game.PrecacheModel( MODEL_GIB_RGUN );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );
		g_Game.PrecacheModel( "sprites/steam1.spr" );		

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		for( uint i = 0; i < pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( pExplosionSprites[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2supertank.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2supertank.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2supertank_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CHAINGUN_AMMO;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2SUPERTANK_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2SUPERTANK_POSITION - 1;
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

		self.m_iDefaultAmmo = CHAINGUN_AMMO;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, CHAINGUN_AMMO );

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
			if( GetState() > STATE_MOVING ) return;

			SetState( STATE_ATK_ROCKET );
			SetSpeed( 0 );
			SetAnim( ANIM_ATK_ROCKET );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_ROCKET;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			if( m_iState < STATE_ATK_CHAINGUN )
			{
				SetState( STATE_ATK_CHAINGUN );
				SetSpeed( 0 );
				SetAnim( ANIM_ATK_CHAINGUN );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1;
				return;
			}
			else if( GetState(STATE_ATK_CHAINGUN) )
			{
				if( !GetAnim(ANIM_ATK_CHAINGUN) )
					SetAnim( ANIM_ATK_CHAINGUN );

				Shoot();

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CHAINGUN_FIRERATE;
			}
		}
		else
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
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
			cnpc_q2supertank@ pDriveEnt = cast<cnpc_q2supertank@>(CastToScriptClass(m_pDriveEnt));
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
			DoSearchSound();
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			KeepPlayerNonsolid();
			StopShooting();
			DoAmmoRegen();
			CheckGrenadeInput();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		SetSpeed( int(SPEED_RUN) );

		if( m_pDriveEnt.pev.sequence != ANIM_FORWARD )
		{
			SetState( STATE_MOVING );
			SetSpeed( int(SPEED_RUN) );
			SetAnim( ANIM_FORWARD );
		}

		m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
	}

	void DoIdleAnimation()
	{
		if( (GetState(STATE_ATK_ROCKET) or GetState(STATE_ATK_GRENADE)) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( GetState(STATE_ATK_CHAINGUN) or (GetAnim(ANIM_ATK_CHAINGUN_END) and !m_pDriveEnt.m_fSequenceFinished) ) return;
		if( (GetAnim(ANIM_PAIN1) or GetAnim(ANIM_PAIN2) or GetAnim(ANIM_PAIN3)) and !m_pDriveEnt.m_fSequenceFinished) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_TREAD] ); //CHAN_VOICE

				SetSpeed( int(SPEED_RUN) );
				SetState( STATE_IDLE );
				SetAnim( ANIM_IDLE );
			}
			else if( GetState(STATE_IDLE) and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void KeepPlayerNonsolid()
	{
		if( CNPC_NPC_HITBOX )
		{
			m_pPlayer.pev.solid = SOLID_NOT;
			m_pPlayer.pev.flags |= (FL_NOTARGET|FL_GODMODE);
		}
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SEARCH1, SND_SEARCH2)], VOL_NORM, ATTN_NORM );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_FORWARD:
			{
				if( GetFrame(18, 0) and m_uiAnimationState == 0 ) { TreadSound(); m_uiAnimationState++; }
				else if( GetFrame(18) >= 10 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATK_ROCKET:
			{
				if( GetFrame(27, 7) and m_uiAnimationState == 0 ) { FireRocket(1); m_uiAnimationState++; }
				else if( GetFrame(27, 10) and m_uiAnimationState == 1 ) { FireRocket(2); m_uiAnimationState++; }
				else if( GetFrame(27, 13) and m_uiAnimationState == 2 ) { FireRocket(3); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATK_GRENADE:
			{
				if( GetFrame(6, 0) and m_uiAnimationState == 0 ) { FireGrenade(1); m_uiAnimationState++; }
				else if( GetFrame(6, 3) and m_uiAnimationState == 1 ) { FireGrenade(2); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN1:
			case ANIM_PAIN2:
			case ANIM_PAIN3:
			{
				if( GetFrame(4, 0) ) { SetSpeed(0); SetState(STATE_PAIN); m_uiAnimationState++; }

				break;
			}
		}
	}

	void TreadSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_TREAD], VOL_NORM, ATTN_NORM ); //CHAN_VOICE
	}

	void Shoot()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_CHAINGUN], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( ATTACH_CG_MUZZLE, vecOrigin, void );

		MachineGunEffects( vecOrigin, 10 );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > CNPC_MAXPITCH )
			vecAim.x = CNPC_MAXPITCH;
		else if( vecAim.x < -CNPC_MAXPITCH )
			vecAim.x = -CNPC_MAXPITCH;

		vecAim.y += 1.0; //closer to the crosshairs
		vecAim.x -= 0.5; //closer to the crosshairs

		g_EngineFuncs.MakeVectors( vecAim );

		self.FireBullets( 1, vecOrigin, g_Engine.v_forward, VECTOR_CONE_3DEGREES, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, CHAINGUN_DAMAGE, m_pPlayer.pev );

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
	}

	void StopShooting()
	{
		if( !GetState(STATE_ATK_CHAINGUN) ) return;

		if( (GetState(STATE_ATK_CHAINGUN) and !GetButton(IN_ATTACK2)) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			SetState( STATE_ATK_CHAINGUN_END );
			SetAnim( ANIM_ATK_CHAINGUN_END );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_CHAINGUN;
		}
	}

	void DoAmmoRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( GetState() <= STATE_MOVING and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < CHAINGUN_AMMO )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + AMMO_REGEN_AMOUNT );
				if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > CHAINGUN_AMMO )
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, CHAINGUN_AMMO );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void FireRocket( int iRocketNum )
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ROCKET], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( ATTACH_ROCKET_MIDDLE, vecOrigin, void );
		Math.MakeVectors( m_pDriveEnt.pev.angles );

		if( iRocketNum == 1 )
			vecOrigin = vecOrigin + g_Engine.v_right * 8.0;
		else if( iRocketNum == 3 )
			vecOrigin = vecOrigin - g_Engine.v_right * 8.0;

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > CNPC_MAXPITCH )
			vecAim.x = CNPC_MAXPITCH;
		else if( vecAim.x < -CNPC_MAXPITCH )
			vecAim.x = -CNPC_MAXPITCH;

		g_EngineFuncs.MakeVectors( vecAim );

		monster_fire_rocket( vecOrigin, g_Engine.v_forward, ROCKET_DMG, ROCKET_SPEED, 2.0 );
	}

	void CheckGrenadeInput()
	{
		if( GetState() > STATE_MOVING or m_flNextGrenade > g_Engine.time ) return;

		if( GetPressed(IN_RELOAD) )
		{
			SetState( STATE_ATK_GRENADE );
			SetSpeed( 0 );
			SetAnim( ANIM_ATK_GRENADE );
			m_flNextGrenade = g_Engine.time + CD_GRENADE;
		}
	}

	void FireGrenade( int iGrenadeNum )
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_GRENADE], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( ATTACH_GREN_LEFT+(iGrenadeNum-1), vecOrigin, void );

		g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle );

		TraceResult tr;
		g_Utility.TraceLine( vecOrigin, g_Engine.v_forward * 8192, dont_ignore_monsters, m_pPlayer.edict(), tr );

		Vector vecVelocity = VecCheckThrow( vecOrigin, tr.vecEndPos, GRENADE_SPEED, 1.0 );
		monster_fire_grenade( vecOrigin, vecVelocity, GRENADE_DMG );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2supertank", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		if( CNPC_NPC_HITBOX )
		{
			m_pPlayer.pev.solid = SOLID_NOT;
			m_pPlayer.pev.flags |= (FL_NOTARGET|FL_GODMODE);
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_flCustomHealth", "" + m_flCustomHealth );
		}

		m_pPlayer.pev.effects |= EF_NODRAW;		
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
			m1.WriteString( "cam_idealdist 256\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2SUPERTANK );
	}

	void DoFirstPersonView()
	{
		cnpc_q2supertank@ pDriveEnt = cast<cnpc_q2supertank@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2supertank_rend_" + m_pPlayer.entindex();
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
		g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_TREAD] ); //CHAN_VOICE

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
}

class cnpc_q2supertank : CBaseDriveEntityHitboxQ2
{
	private int m_iDeathExplosions;

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
			pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
			pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
			self.m_bloodColor = DONT_BLEED;
			self.m_FormattedName = CNPC_DISPLAYNAME;
			//g_EntityFuncs.DispatchKeyValue( self.edict(), "displayname", CNPC_DISPLAYNAME );
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

	int BloodColor() { return DONT_BLEED; }

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
			//Prevent player damage
			CBaseEntity@ pInflictor = g_EntityFuncs.Instance(pevInflictor);
			if( pInflictor !is null and m_pOwner !is null and m_pOwner.IRelationship(pInflictor) <= R_NO )
				return 0;

			pev.health -= flDamage;

			if( pev.health < (pev.max_health * 0.5) )
				pev.skin = 1;

			if( m_pOwner !is null and m_pOwner.IsConnected() and pev.health > 0 )
				m_pOwner.pev.health = pev.health;

			pevAttacker.frags += self.GetPointsForDamage( flDamage );
			HandlePain( flDamage );

			if( pev.health <= 0 )
			{
				if( m_pOwner !is null and m_pOwner.IsConnected() )
					m_pOwner.Killed( pevAttacker, GIB_NEVER );

				pev.health = 0;
				pev.takedamage = DAMAGE_NO;

				return 0;
			}

			return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		}

		return 0;
	}

	void HandlePain( float flDamage )
	{
		if( pev.pain_finished > g_Engine.time )
			return;

		// Lessen the chance of him going into his pain frames
		//if( mod.id != MOD_CHAINFIST )
		{
			if( flDamage <= 25 )
			{
				if( Math.RandomFloat(0.0, 1.0) < 0.2 )
					return;
			}

			// Don't go into pain if he's firing his rockets
			if( GetAnim(ANIM_ATK_ROCKET) )
				return;
		}

		if( flDamage <= 10 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pPainSounds[0], VOL_NORM, ATTN_NORM );
		else if( flDamage <= 25 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pPainSounds[2], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pPainSounds[1], VOL_NORM, ATTN_NORM );

		pev.pain_finished = g_Engine.time + 3.0;

		//if (!M_ShouldReactToPain(self, mod))
			//return; // no pain anims in nightmare

		if( flDamage <= 10 )
			pev.sequence = ANIM_PAIN1;
		else if( flDamage <= 25 )
			pev.sequence = ANIM_PAIN2;
		else
			pev.sequence = ANIM_PAIN3;

		pev.frame = 0;
		self.ResetSequenceInfo();
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

		if( pev.health > 0 )
			pev.deadflag = DEAD_NO;

		if( m_flNextOriginUpdate < g_Engine.time )
		{
			Vector vecOrigin = m_pOwner.pev.origin;
			vecOrigin.z -= CNPC_MODEL_OFFSET;
			g_EntityFuncs.SetOrigin( self, vecOrigin );
			m_flNextOriginUpdate = g_Engine.time + CNPC_ORIGINUPDATE;
		}

		pev.velocity = m_pOwner.pev.velocity;

		pev.angles.x = 0;

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and pev.sequence == ANIM_FORWARD )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( GetAnim(ANIM_ATK_CHAINGUN) or GetAnim(ANIM_ATK_ROCKET) or GetAnim(ANIM_ATK_GRENADE) )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath( bool bGibbed = false )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_TREAD] ); //CHAN_VOICE

		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		pev.velocity = g_vecZero;

		if( bGibbed )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_GIB], VOL_NORM, ATTN_NORM );
			SpawnGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		ThrowGib( 2, MODEL_GIB_MEAT, 500, BREAK_FLESH );
		ThrowGib( 2, MODEL_GIB_METAL, 500, BREAK_METAL );
		ThrowGib( 1, MODEL_GIB_CHEST, 500 );
		ThrowGib( 1, MODEL_GIB_CORE, 500 );
		ThrowGib( 1, MODEL_GIB_LTREAD, 500 );
		ThrowGib( 1, MODEL_GIB_RTREAD, 500 );
		ThrowGib( 1, MODEL_GIB_RGUN, 500 );
		ThrowGib( 1, MODEL_GIB_TUBE, 500 );
		ThrowGib( 1, MODEL_GIB_HEAD, 500, BREAK_METAL, true );

		Explosion( pev.origin, 90 );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.BossExplode) );
			pev.nextthink = g_Engine.time;
			m_iDeathExplosions = 0;
		}
	}

	void BossExplode()
	{
		Vector vecOrigin = pev.origin;
		vecOrigin.z += 24 + Math.RandomFloat(0, 14); //(rand()&15)

		switch( m_iDeathExplosions++ )
		{
			case 0:
			{
				vecOrigin.x -= 24;
				vecOrigin.y -= 24;
				break;
			}

			case 1:
			{
				vecOrigin.x += 24;
				vecOrigin.y += 24;
				break;
			}

			case 2:
			{
				vecOrigin.x += 24;
				vecOrigin.y -= 24;
				break;
			}

			case 3:
			{
				vecOrigin.x -= 24;
				vecOrigin.y += 24;
				break;
			}

			case 4:
			{
				vecOrigin.x -= 48;
				vecOrigin.y -= 48;
				break;
			}

			case 5:
			{
				vecOrigin.x += 48;
				vecOrigin.y += 48;
				break;
			}

			case 6:
			{
				vecOrigin.x -= 48;
				vecOrigin.y += 48;
				break;
			}

			case 7:
			{
				vecOrigin.x += 48;
				vecOrigin.y -= 48;
				break;
			}

			case 8:
			{
				SpawnGibs();
				SUB_Remove();
				return;
			}
		}

		Explosion( vecOrigin, 30 );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void Explosion( Vector vecOrigin, int iScale )
	{
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_Game.PrecacheModel(pExplosionSprites[Math.RandomLong(0, pExplosionSprites.length() - 1)]) );
			m1.WriteByte( iScale );//scale
			m1.WriteByte( 30 );//framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_EXPLOSION], VOL_NORM, ATTN_NORM );
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_q2supertank : CNPCSpawnEntity
{
	info_cnpc_q2supertank()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;

		if( CNPC_NPC_HITBOX )
			m_flSpawnOffset = CNPC_MODEL_OFFSET;
	}
}

void Register()
{
	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2grenade" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2grenade", "cnpcq2grenade" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2rocket" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2rocket", "cnpcq2rocket" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2supertank::info_cnpc_q2supertank", "info_cnpc_q2supertank" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2supertank::cnpc_q2supertank", "cnpc_q2supertank" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2supertank::weapon_q2supertank", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "stankammo" );

	g_Game.PrecacheOther( "cnpcq2grenade" );
	g_Game.PrecacheOther( "cnpcq2rocket" );
	g_Game.PrecacheOther( "info_cnpc_q2supertank" );
	g_Game.PrecacheOther( "cnpc_q2supertank" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2supertank END

/* FIXME
*/

/* TODO
	More tank-like movement ??
*/