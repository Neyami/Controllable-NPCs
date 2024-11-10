namespace cnpc_q2soldier
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2soldier";
const string CNPC_MODEL				= "models/quake2/monsters/soldier/soldier.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_BONE2		= "models/quake2/objects/gibs/bone2.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/soldier/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/soldier/gibs/chest.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/soldier/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/soldier/gibs/head.mdl";

const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH_BLASTER	= 20.0;
const float CNPC_HEALTH_SGUN		= 30.0;
const float CNPC_HEALTH_MGUN		= 40.0;
const float CNPC_VIEWOFS_FPV		= 38.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 38.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the soldier itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const float CNPC_FADETIME			= 0.5;

const float SPEED_RUN					= -1;
const float SPEED_WALK					= -1;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 1.0;
const float BLASTER_DAMAGE			= 5;
const float BLASTER_SPEED			= 600;
const int BLASTER_AMMO				= 10;

const float SHOTGUN_DAMAGE		= 2.0;
const Vector SHOTGUN_SPREAD		= VECTOR_CONE_5DEGREES;
const int SHOTGUN_COUNT			= 9;
const int SHOTGUN_AMMO				= 10;

const float MGUN_FIRERATE			= 0.1;
const int MGUN_AMMO					= 35;
const float MGUN_DAMAGE				= 7.0;
const Vector MGUN_SPREAD			= VECTOR_CONE_3DEGREES;

const int AMMO_REGEN_AMOUNT	= 2;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds
const float CNPC_MAXPITCH			= 30.0;

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/soldier/solidle1.wav",
	"quake2/npcs/soldier/solsght1.wav",
	"quake2/npcs/soldier/solsrch1.wav",
	"quake2/npcs/enforcer/infatck3.wav",
	"quake2/npcs/soldier/solatck2.wav",
	"quake2/npcs/soldier/solatck1.wav",
	"quake2/npcs/soldier/solatck3.wav",
	"quake2/npcs/soldier/solpain1.wav",
	"quake2/npcs/soldier/solpain2.wav",
	"quake2/npcs/soldier/solpain3.wav",
	"quake2/npcs/soldier/soldeth1.wav",
	"quake2/npcs/soldier/soldeth2.wav",
	"quake2/npcs/soldier/soldeth3.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_COCK,
	SND_BLASTER,
	SND_SHOTGUN,
	SND_MGUN,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3,
	SND_DEATH1,
	SND_DEATH2,
	SND_DEATH3
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET1,
	ANIM_IDLE_FIDGET2,
	ANIM_WALK1 = 4,
	ANIM_WALK2,
	ANIM_RUN,
	ANIM_ATTACK1 = 9,
	ANIM_ATTACK2,
	ANIM_MGUN,
	ANIM_DUCK = 14,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_PAIN4,
	ANIM_DEATH1,
	ANIM_DEATH2, //gut shot
	ANIM_DEATH3, //head shot
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_DEATH6
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_DUCKING,
	STATE_PAIN,
	STATE_MGUN,
	STATE_MGUN_END
};

enum weapons_e
{
	WEAPON_BLASTER,
	WEAPON_SHOTGUN,
	WEAPON_MGUN,
	WEAPON_RANDOM
};

final class weapon_q2soldier : CBaseDriveWeaponQ2
{
	private float m_flMaxHealth;
	private float m_flNextAmmoRegen;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );
		m_flMaxHealth = CNPC_HEALTH_BLASTER;

		if( pev.weapons == WEAPON_BLASTER )
			m_iMaxAmmo = BLASTER_AMMO;
		else if( pev.weapons == WEAPON_SHOTGUN )
			m_iMaxAmmo = SHOTGUN_AMMO;
		else
			m_iMaxAmmo = MGUN_AMMO;

		self.m_iDefaultAmmo = m_iMaxAmmo;
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_BONE2 );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2soldier.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2soldier.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2soldier_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= m_iMaxAmmo;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2SOLDIER_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2SOLDIER_POSITION - 1;
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

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_iMaxAmmo );

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
			if( pev.weapons == WEAPON_BLASTER or pev.weapons == WEAPON_SHOTGUN )
			{
				if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 ) return;

				SetState( STATE_ATTACK );
				SetSpeed( 0 );

				if( Math.RandomFloat(0.0, 1.0) < 0.5 )
					SetAnim( ANIM_ATTACK1 );
				else
					SetAnim( ANIM_ATTACK2 );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
			}
			else
			{
				if( GetState() < STATE_MGUN )
				{
					if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < m_iMaxAmmo ) return;

					SetState( STATE_MGUN );
					SetSpeed( 0 );
					SetAnim( ANIM_MGUN );

					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.4;
				}
				else if( GetState(STATE_MGUN) )
				{
					SetFramerate( 0 );

					soldier_fire();

					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + MGUN_FIRERATE;
				}
			}
		}
		else
		{
			spawnDriveEnt();
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
		}
		else
		{
			cnpc_q2soldier@ pDriveEnt = cast<cnpc_q2soldier@>(CastToScriptClass(m_pDriveEnt));
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
			DoSearchSound();
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			CheckDuckInput();
			StopShooting();
			DoAmmoRegen();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		SetSpeed( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK1 )
			{
				SetState( STATE_MOVING );
				SetSpeed( int(SPEED_WALK) );
				SetAnim( ANIM_WALK1 );
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				SetState( STATE_MOVING );
				SetSpeed( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( GetState() >= STATE_ATTACK and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( GetState(STATE_MGUN) or (GetAnim(ANIM_MGUN) and !m_pDriveEnt.m_fSequenceFinished) ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetSpeed( int(SPEED_RUN) );
				SetState( STATE_IDLE );
				SetAnim( ANIM_IDLE );
			}
			else if( GetState(STATE_IDLE) and m_pDriveEnt.m_fSequenceFinished )
			{
				float flRand = Math.RandomFloat( 0.0, 1.0 );
				
				if( !GetAnim(ANIM_IDLE) or flRand < 0.6  )
					SetAnim( ANIM_IDLE );
				else if( flRand < 0.8 )
					SetAnim( ANIM_IDLE_FIDGET2 );
				else
					SetAnim( ANIM_IDLE_FIDGET1 );
			}
		}
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void IdleSound()
	{
		if( Math.RandomFloat(0.0, 1.0) > 0.8 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandlePain( float flDamage )
	{
		m_pDriveEnt.pev.dmg = flDamage;

		if( m_pPlayer.pev.health < (m_flMaxHealth * 0.5) )
			m_pDriveEnt.pev.skin = 1;

		if( g_Engine.time < m_pDriveEnt.pev.pain_finished )
		{
			if( m_pPlayer.pev.velocity.z > 100 and (GetAnim(ANIM_PAIN1) or GetAnim(ANIM_PAIN2) or GetAnim(ANIM_PAIN3)) )
			{
				SetAnim( ANIM_PAIN4 );
				SetSpeed( 0 );
				SetState( STATE_PAIN );
			}

			return;
		}

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		if( pev.weapons == WEAPON_BLASTER )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
		else if( pev.weapons == WEAPON_SHOTGUN )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN3], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );

		if( m_pPlayer.pev.velocity.z > 100 )
		{
			SetAnim( ANIM_PAIN4 );
			SetSpeed( 0 );
			SetState( STATE_PAIN );

			return;
		}

		if( GetState(STATE_DUCKING) )
			return;

		SetAnim( ANIM_PAIN1 + Math.RandomLong(0, 2) );
		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_IDLE: //stand1
			{
				if( GetFrame(30, 2) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_IDLE_FIDGET1: //stand3
			{
				if( GetFrame(39, 21) and m_uiAnimationState == 0 ) { CockSound(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_IDLE_FIDGET2: //stand2
			{
				if( GetFrame(40, 22) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(40, 40) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_WALK1:
			{
				if( GetFrame(11, 3) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(11, 8) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_WALK2:
			{
				if( GetFrame(11, 0) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(11, 5) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_RUN:
			{
				if( GetFrame(7, 1) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(7, 4) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN1:
			{
				if( GetFrame(5, 0) and m_uiAnimationState == 0 ) { WalkMove(-3.0); m_uiAnimationState++; }
				else if( GetFrame(5, 1) and m_uiAnimationState == 1 ) { WalkMove(4.0); m_uiAnimationState++; }
				else if( GetFrame(5, 2) and m_uiAnimationState == 2 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(5, 3) and m_uiAnimationState == 3 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN2:
			{
				if( GetFrame(7, 0) and m_uiAnimationState == 0 ) { WalkMove(-13.0); m_uiAnimationState++; }
				else if( GetFrame(7, 1) and m_uiAnimationState == 1 ) { WalkMove(-1.0); m_uiAnimationState++; }
				else if( GetFrame(7, 2) and m_uiAnimationState == 2 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(7, 3) and m_uiAnimationState == 3 ) { WalkMove(4.0); m_uiAnimationState++; }
				else if( GetFrame(7, 4) and m_uiAnimationState == 4 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(7, 5) and m_uiAnimationState == 5 ) { WalkMove(3.0); m_uiAnimationState++; }
				else if( GetFrame(7, 6) and m_uiAnimationState == 6 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 7 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN3:
			{
				if( GetFrame(18, 0) and m_uiAnimationState == 0 ) { WalkMove(-8.0); m_uiAnimationState++; }
				else if( GetFrame(18, 1) and m_uiAnimationState == 1 ) { WalkMove(10.0); m_uiAnimationState++; }
				else if( GetFrame(18, 2) and m_uiAnimationState == 2 ) { WalkMove(-4.0); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 3) and m_uiAnimationState == 3 ) { WalkMove(-1.0); m_uiAnimationState++; }
				else if( GetFrame(18, 4) and m_uiAnimationState == 4 ) { WalkMove(-3.0); m_uiAnimationState++; }
				else if( GetFrame(18, 6) and m_uiAnimationState == 5 ) { WalkMove(3.0); m_uiAnimationState++; }
				else if( GetFrame(18, 11) and m_uiAnimationState == 6 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(18, 13) and m_uiAnimationState == 7 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(18, 14) and m_uiAnimationState == 8 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(18, 15) and m_uiAnimationState == 9 ) { WalkMove(4.0); m_uiAnimationState++; }
				else if( GetFrame(18, 16) and m_uiAnimationState == 10 ) { WalkMove(3.0); m_uiAnimationState++; }
				else if( GetFrame(18, 17) and m_uiAnimationState == 11 ) { WalkMove(2.0); Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 12 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN4:
			{
				if( GetFrame(17, 3) and m_uiAnimationState == 0 ) { WalkMove(-10.0); m_uiAnimationState++; }
				else if( GetFrame(17, 4) and m_uiAnimationState == 1 ) { WalkMove(-6.0); m_uiAnimationState++; }
				else if( GetFrame(17, 5) and m_uiAnimationState == 2 ) { WalkMove(8.0); m_uiAnimationState++; }
				else if( GetFrame(17, 6) and m_uiAnimationState == 3 ) { WalkMove(4.0); m_uiAnimationState++; }
				else if( GetFrame(17, 7) and m_uiAnimationState == 4 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(17, 9) and m_uiAnimationState == 5 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(17, 10) and m_uiAnimationState == 6 ) { WalkMove(5.0); m_uiAnimationState++; }
				else if( GetFrame(17, 11) and m_uiAnimationState == 7 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(17, 12) and m_uiAnimationState == 8 ) { WalkMove(-1.0); m_uiAnimationState++; }
				else if( GetFrame(17, 13) and m_uiAnimationState == 9 ) { WalkMove(-1.0); m_uiAnimationState++; }
				else if( GetFrame(17, 14) and m_uiAnimationState == 10 ) { WalkMove(3.0); m_uiAnimationState++; }
				else if( GetFrame(17, 15) and m_uiAnimationState == 11 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 12 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATTACK1:
			{
				if( GetFrame(12, 2) and m_uiAnimationState == 0 ) { soldier_fire(); m_uiAnimationState++; }
				else if( GetFrame(12, 6) and m_uiAnimationState == 1 ) { soldier_attack1_refire1(); m_uiAnimationState++; }
				else if( GetFrame(12, 7) and m_uiAnimationState == 2 ) { CockSound(); m_uiAnimationState++; }
				else if( GetFrame(12, 8) and m_uiAnimationState == 3 ) { soldier_attack1_refire2(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATTACK2:
			{
				if( GetFrame(18, 4) and m_uiAnimationState == 0 ) { soldier_fire(); m_uiAnimationState++; }
				else if( GetFrame(18, 8) and m_uiAnimationState == 1 ) { soldier_attack2_refire1(); m_uiAnimationState++; }
				else if( GetFrame(18, 12) and m_uiAnimationState == 2 ) { CockSound(); m_uiAnimationState++; }
				else if( GetFrame(18, 14) and m_uiAnimationState == 3 ) { soldier_attack2_refire2(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DUCK:
			{
				if( GetFrame(5, 2) ) { DoDucking(); }

				break;
			}
		}
	}

	void Footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		CNPC::monster_footstep( EHandle(m_pDriveEnt), EHandle(m_pPlayer), m_iStepLeft, iPitch, bSetOrigin, vecSetOrigin );
	}

	void CheckDuckInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( GetPressed(IN_DUCK) )
		{
			SetState( STATE_DUCKING );
			SetSpeed( 0 );
			SetAnim( ANIM_DUCK );
		}
	}

	void DoDucking()
	{
		if( GetButton(IN_DUCK) )
			SetFramerate( 0 );
		else
			SetFramerate( 1.0 );
	}

	void CockSound()
	{
		if( GetAnim(ANIM_IDLE_FIDGET1) )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_COCK], VOL_NORM, ATTN_IDLE );
		else
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_COCK], VOL_NORM, ATTN_NORM );
	}

	void soldier_fire()
	{
		Vector vecMuzzle;
		m_pDriveEnt.GetAttachment( 0, vecMuzzle, void );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > CNPC_MAXPITCH )
			vecAim.x = CNPC_MAXPITCH;
		else if( vecAim.x < -CNPC_MAXPITCH )
			vecAim.x = -CNPC_MAXPITCH;

		g_EngineFuncs.MakeVectors( vecAim );

		if( pev.weapons == WEAPON_BLASTER )
		{
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_BLASTER], VOL_NORM, ATTN_NORM );

			if( GetAnim(ANIM_ATTACK1) )
			{
				vecAim.y += 0.5; //closer to the crosshairs
				vecAim.x += -1.0; //closer to the crosshairs
				g_EngineFuncs.MakeVectors( vecAim );
			}

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			monster_fire_blaster( vecMuzzle, g_Engine.v_forward, BLASTER_DAMAGE, BLASTER_SPEED );
		}
		else if( pev.weapons == WEAPON_SHOTGUN )
		{
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOTGUN], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			MachineGunEffects( vecMuzzle );
			monster_fire_shotgun( vecMuzzle, g_Engine.v_forward, SHOTGUN_DAMAGE, SHOTGUN_SPREAD, SHOTGUN_COUNT );
		}
		else
		{
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MGUN], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			MachineGunEffects( vecMuzzle );
			monster_fire_bullet( vecMuzzle, g_Engine.v_forward, MGUN_DAMAGE, MGUN_SPREAD );
		}

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
	}

	void soldier_attack1_refire1()
	{
		if( pev.weapons != WEAPON_BLASTER )
			return;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;

		if( GetButton(IN_ATTACK) )
		{
			m_uiAnimationState = 0;
			m_pDriveEnt.pev.frame = SetFrame( 12, 2 );
			soldier_fire();
		}
		else
		{
			m_uiAnimationState = 4;
			m_pDriveEnt.pev.frame = SetFrame( 12, 10 );
		}
	}

	void soldier_attack1_refire2()
	{
		if( pev.weapons == WEAPON_BLASTER )
			return;

		if( !GetButton(IN_ATTACK) )
			return;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			m_uiAnimationState = 0;
			m_pDriveEnt.pev.frame = SetFrame( 12, 2 );
			soldier_fire();
		}
	}

	void soldier_attack2_refire1()
	{
		if( pev.weapons != WEAPON_BLASTER )
			return;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			return;

		if( GetButton(IN_ATTACK) )
		{
			m_uiAnimationState = 0;
			m_pDriveEnt.pev.frame = SetFrame( 18, 4 );
			soldier_fire();
		}
		else
		{
			m_uiAnimationState = 4;
			m_pDriveEnt.pev.frame = SetFrame( 18, 16 );
		}
	}

	void soldier_attack2_refire2()
	{
		if( pev.weapons == WEAPON_BLASTER )
			return;

		if( !GetButton(IN_ATTACK) )
			return;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			m_uiAnimationState = 0;
			m_pDriveEnt.pev.frame = SetFrame( 18, 4 );
			soldier_fire();
		}
	}

	void StopShooting()
	{
		if( !GetState(STATE_MGUN) ) return;

		if( (GetState(STATE_MGUN) and !GetButton(IN_ATTACK)) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			SetState( STATE_MGUN_END );
			SetFramerate( 1.0 );
		}
	}

	void DoAmmoRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( GetState() <= STATE_MOVING and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < m_iMaxAmmo )
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2soldier", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "weapons", "" + pev.weapons );

			if( pev.weapons == WEAPON_BLASTER )
				g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "skin", "0" );
			else if( pev.weapons == WEAPON_SHOTGUN )
			{
				g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "skin", "2" );
				m_flMaxHealth = CNPC_HEALTH_SGUN;
			}
			else
			{
				g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "skin", "4" );
				m_flMaxHealth = CNPC_HEALTH_MGUN;
			}
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : m_flMaxHealth;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : m_flMaxHealth;
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2SOLDIER );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2soldier@ pDriveEnt = cast<cnpc_q2soldier@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2soldier_rend_" + m_pPlayer.entindex();
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
}

class cnpc_q2soldier : CBaseDriveEntityQ2
{
	private Vector m_vecMuzzle, m_vecBonePos;

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
			DoDeath( true );

			return;
		}

		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (GetAnim(ANIM_RUN) or GetAnim(ANIM_WALK1) or GetAnim(ANIM_WALK2)) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( GetAnim(ANIM_ATTACK1) or GetAnim(ANIM_ATTACK2) or GetAnim(ANIM_MGUN) )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath( bool bGibbed = false )
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		if( bGibbed )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_GIB], VOL_NORM, ATTN_NORM );
			SpawnGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		if( pev.weapons == WEAPON_BLASTER )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DEATH2], VOL_NORM, ATTN_NORM );
		else if( pev.weapons == WEAPON_SHOTGUN )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DEATH1], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DEATH3], VOL_NORM, ATTN_NORM );

		int iRand;
		// only do the spin-death if we have enough velocity to justify it
		if( pev.velocity.z > 65.0 or pev.velocity.Length() > 150.0 )
			iRand = Math.RandomLong(0, 4);
		else
			iRand = Math.RandomLong(0, 3);

		if( iRand == 0 )
			SetAnim( ANIM_DEATH1 );
		else if( iRand == 1 )
			SetAnim( ANIM_DEATH2 + Math.RandomLong(0, 1) ); //no way to check for headshots atm.
		else if( iRand == 2 )
			SetAnim( ANIM_DEATH4 );
		else if( iRand == 3 )
			SetAnim( ANIM_DEATH5 );
		else
			SetAnim( ANIM_DEATH6 );

		pev.frame = 0;
		self.ResetSequenceInfo();

		pev.velocity = g_vecZero;

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
		pev.movetype = MOVETYPE_STEP;
	}

	void SpawnGibs()
	{
		CNPC::Q2::ThrowGib( EHandle(self), 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_BONE2, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_ARM, pev.dmg, 7, BREAK_FLESH, pev.skin / 2 ); //divide by 2 to get the proper gibskin, since the monster model has 6 skins but the gibs only have 3
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GUN, pev.dmg, 5, 0, pev.skin / 2 );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH, pev.skin / 2 );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH, pev.skin / 2 );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( pev.sequence )
		{
			case ANIM_DEATH1:
			{
				if( pev.weapons == WEAPON_MGUN )
				{
					if( g_Engine.time >= pev.dmgtime )
						pev.framerate = 1.0;
					else
					{
						if( m_uiAnimationState == 5) m_uiAnimationState = 4;
						else if( m_uiAnimationState == 6)
						{
							pev.frame = SetFrame( 36, 25 );
							m_uiAnimationState = 5;
						}

						pev.framerate = 0.0;
					}					
				}

				if( GetFrame(36, 1) and m_uiAnimationState == 0 ) { WalkMove(-10.0); m_uiAnimationState++; }
				else if( GetFrame(36, 2) and m_uiAnimationState == 1 ) { WalkMove(-10.0); m_uiAnimationState++; }
				else if( GetFrame(36, 3) and m_uiAnimationState == 2 ) { WalkMove(-10.0); m_uiAnimationState++; }
				else if( GetFrame(36, 4) and m_uiAnimationState == 3 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(36, 21) and m_uiAnimationState == 4 ) { DeathShot(true); m_uiAnimationState++; }
				else if( GetFrame(36, 24) and m_uiAnimationState == 5 ) { DeathShot(); m_uiAnimationState++; }

				break;
			}

			case ANIM_DEATH2:
			{
				if( GetFrame(35, 0) and m_uiAnimationState == 0 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(35, 1) and m_uiAnimationState == 1 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(35, 2) and m_uiAnimationState == 2 ) { WalkMove(-5.0); m_uiAnimationState++; }

				break;
			}

			case ANIM_DEATH3:
			{
				if( GetFrame(45, 0) and m_uiAnimationState == 0 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(45, 1) and m_uiAnimationState == 1 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(45, 2) and m_uiAnimationState == 2 ) { WalkMove(-5.0); m_uiAnimationState++; }

				break;
			}

			case ANIM_DEATH4:
			{
				if( GetFrame(53, 2) and m_uiAnimationState == 0 ) { WalkMove(1.5); m_uiAnimationState++; }
				else if( GetFrame(53, 3) and m_uiAnimationState == 1 ) { WalkMove(2.5); m_uiAnimationState++; }
				else if( GetFrame(53, 4) and m_uiAnimationState == 2 ) { WalkMove(-1.5); m_uiAnimationState++; }
				else if( GetFrame(53, 8) and m_uiAnimationState == 3 ) { WalkMove(-0.5); m_uiAnimationState++; }
				else if( GetFrame(53, 11) and m_uiAnimationState == 4 ) { WalkMove(4.0); m_uiAnimationState++; }
				else if( GetFrame(53, 12) and m_uiAnimationState == 5 ) { WalkMove(4.0); m_uiAnimationState++; }
				else if( GetFrame(53, 13) and m_uiAnimationState == 6 ) { WalkMove(8.0); m_uiAnimationState++; }
				else if( GetFrame(53, 14) and m_uiAnimationState == 7 ) { WalkMove(8.0); m_uiAnimationState++; }
				else if( GetFrame(53, 49) and m_uiAnimationState == 8 ) { WalkMove(5.5); m_uiAnimationState++; }
				else if( GetFrame(53, 50) and m_uiAnimationState == 9 ) { WalkMove(2.5); m_uiAnimationState++; }
				else if( GetFrame(53, 51) and m_uiAnimationState == 10 ) { WalkMove(-2.0); m_uiAnimationState++; }
				else if( GetFrame(53, 52) and m_uiAnimationState == 11 ) { WalkMove(-2.0); m_uiAnimationState++; }

				break;
			}

			case ANIM_DEATH5:
			{
				if( GetFrame(24, 0) and m_uiAnimationState == 0 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(24, 1) and m_uiAnimationState == 1 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(24, 2) and m_uiAnimationState == 2 ) { WalkMove(-5.0); m_uiAnimationState++; }

				break;
			}
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
		}
	}

	void DeathShot( bool bFirstShot = false )
	{
		if( bFirstShot )
		{
			g_EngineFuncs.GetBonePosition( self.edict(), 5, m_vecBonePos, void );
			self.GetAttachment( 0, m_vecMuzzle, void );
		}

		Vector vecAim = (m_vecMuzzle - m_vecBonePos).Normalize();

		if( pev.weapons == WEAPON_BLASTER )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_BLASTER], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( m_vecMuzzle, 20, 255, 255, 0 );
			monster_fire_blaster( m_vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
		}
		else if( pev.weapons == WEAPON_SHOTGUN )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOTGUN], VOL_NORM, ATTN_NORM );

			monster_muzzleflash( m_vecMuzzle, 20, 255, 255, 0 );
			MachineGunEffects( m_vecMuzzle );
			monster_fire_shotgun( m_vecMuzzle, vecAim, SHOTGUN_DAMAGE, SHOTGUN_SPREAD, SHOTGUN_COUNT );
		}
		else
		{
			if( pev.framerate > 0.0 )
				pev.dmgtime = g_Engine.time + Math.RandomFloat( 0.3, 1.1 );

			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MGUN], VOL_NORM, ATTN_NORM );

			MachineGunEffects( m_vecMuzzle );
			monster_fire_bullet( m_vecMuzzle, vecAim, MGUN_DAMAGE, MGUN_SPREAD );

			pev.nextthink = g_Engine.time + 0.1;
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

final class info_cnpc_q2soldier : CNPCSpawnEntity
{
	info_cnpc_q2soldier()
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
		if( pev.weapons == WEAPON_RANDOM )
			pev.weapons = Math.RandomLong(0, 2);

		if( pev.weapons == WEAPON_BLASTER )
			pev.skin = 0;
		else if( pev.weapons == WEAPON_SHOTGUN )
			pev.skin = 2;
		else
			pev.skin = 4;
	}
}

void Register()
{
	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2laser" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2laser", "cnpcq2laser" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2soldier::info_cnpc_q2soldier", "info_cnpc_q2soldier" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2soldier::cnpc_q2soldier", "cnpc_q2soldier" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2soldier::weapon_q2soldier", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "q2soldammo" );

	g_Game.PrecacheOther( "info_cnpc_q2soldier" );
	g_Game.PrecacheOther( "cnpc_q2soldier" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2soldier END

/* FIXME
*/

/* TODO
*/