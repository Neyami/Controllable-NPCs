namespace cnpc_q2gunner
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2gunner";
const string CNPC_MODEL				= "models/quake2/monsters/gunner/gunner.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/gunner/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/gunner/gibs/foot.mdl";
const string MODEL_GIB_GARM		= "models/quake2/monsters/gunner/gibs/garm.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/gunner/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/gunner/gibs/head.mdl";

const Vector CNPC_SIZEMIN			= Vector( -16, -16, 0 );
const Vector CNPC_SIZEMAX			= Vector( 16, 16, 88 );

const float CNPC_HEALTH				= 175.0;
const float CNPC_VIEWOFS_FPV		= 54.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 48.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the gunner itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const float CNPC_FADETIME			= 0.5;

const float SPEED_RUN					= -1;
const float SPEED_WALK					= -1;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_GRENADE				= 1.0;
const float GRENADE_DAMAGE		= 50;
const float GRENADE_SPEED			= 750;

const float CHAINGUN_FIRERATE		= 0.1;
const int CHAINGUN_AMMO			= 55;
const float CHAINGUN_DAMAGE		= 6.0;
const Vector CHAINGUN_SPREAD	= VECTOR_CONE_3DEGREES;

const int AMMO_REGEN_AMOUNT	= 2;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds
const float CNPC_MAXPITCH			= 30.0;

const float CD_KICK						= 3.0;
const float MELEE_RANGE				= 80.0;
const float MELEE_DAMAGE			= 15.0;
const float MELEE_KICK					= 270.0;

const array<string> pPainSounds = 
{
	"quake2/npcs/gunner/gunpain1.wav",
	"quake2/npcs/gunner/gunpain2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/gunner/gunidle1.wav",
	"quake2/npcs/gunner/sight1.wav",
	"quake2/npcs/gunner/gunsrch1.wav",
	"quake2/npcs/gunner/gunatck1.wav",
	"quake2/npcs/gunner/gunatck2.wav",
	"quake2/npcs/gunner/gunatck3.wav",
	"quake2/npcs/gunner/death1.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_CHAINGUN_OPEN,
	SND_CHAINGUN_FIRE,
	SND_GRENADE,
	SND_DEATH
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_GRENADE = 5,
	ANIM_CHAINGUN_START,
	ANIM_CHAINGUN_LOOP,
	ANIM_CHAINGUN_END,
	ANIM_KICK,
	ANIM_DUCK,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_DEATH
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_DUCKING,
	STATE_SPINUP,
	STATE_SHOOT,
	STATE_SPINDOWN,
	STATE_PAIN
};

final class weapon_q2gunner : CBaseDriveWeaponQ2
{
	private float m_flNextAmmoRegen;
	private float m_flNextKick;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.m_iDefaultAmmo = CHAINGUN_AMMO;
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_GARM );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2gunner.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2gunner.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2gunner_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= CHAINGUN_AMMO;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2GUNNER_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2GUNNER_POSITION - 1;
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

		SetAmmo( 1, CHAINGUN_AMMO );

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
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_GRENADE );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_GRENADE;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or GetAmmo(1) <= 0 )
			{
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.15;

				return;
			}

			if( GetState() < STATE_ATTACK )
			{
				if( GetAmmo(1) <= int(CHAINGUN_AMMO/2) ) return;

				SetState( STATE_SHOOT );
				SetSpeed( 0 );
				SetAnim( ANIM_CHAINGUN_START );

				self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			}
			else if( GetState(STATE_SHOOT) )
			{
				if( !GetAnim(ANIM_CHAINGUN_LOOP) )
					SetAnim( ANIM_CHAINGUN_LOOP );

				GunnerFire();

				self.m_flNextSecondaryAttack = g_Engine.time + CHAINGUN_FIRERATE;
			}
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
			cnpc_q2gunner@ pDriveEnt = cast<cnpc_q2gunner@>(CastToScriptClass(m_pDriveEnt));
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
			HandleAnimEvent();

			StopShooting();
			DoAmmoRegen();
			CheckKickInput();
			CheckDuckInput();
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
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				SetState( STATE_MOVING );
				SetSpeed( int(SPEED_WALK) );
				SetAnim( ANIM_WALK );
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
		if( GetState(STATE_SHOOT) or (GetAnim(ANIM_CHAINGUN_END) and !m_pDriveEnt.m_fSequenceFinished) ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetSpeed( int(SPEED_RUN) );
				SetState( STATE_IDLE );
				SetAnim( ANIM_IDLE );
			}
			else if( GetAnim(ANIM_IDLE_FIDGET) and m_pDriveEnt.m_fSequenceFinished )
				SetAnim( ANIM_IDLE );
		}
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandlePain( float flDamage )
	{
		m_pDriveEnt.pev.dmg = flDamage;

		if( m_pPlayer.pev.health < (CNPC_HEALTH * 0.5) )
			m_pDriveEnt.pev.skin = 1;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0,(pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

		if( GetState(STATE_DUCKING) )
			return;

		if( flDamage <= 10 )
			SetAnim( ANIM_PAIN3 );
		else if( flDamage <= 25 )
			SetAnim( ANIM_PAIN2 );
		else
			SetAnim( ANIM_PAIN1 );

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent()
	{
		switch( m_pDriveEnt.pev.sequence )
		{
			case ANIM_IDLE:
			{
				if( GetFrame(30, 9) and m_uiAnimationState == 0 ) { if( !gunner_fidget() ) m_uiAnimationState++; }
				else if( GetFrame(30, 19) and m_uiAnimationState == 1 ) { if( !gunner_fidget() ) m_uiAnimationState++; }
				else if( GetFrame(30, 29) and m_uiAnimationState == 2 ) { if( !gunner_fidget() ) m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_IDLE_FIDGET:
			{
				if( GetFrame(40, 7) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_WALK:
			{
				if( GetFrame(14, 5) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(14, 12) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_RUN:
			{
				if( GetFrame(9, 1) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(9, 5) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_GRENADE:
			{
				if( GetFrame(21, 4) and m_uiAnimationState == 0 ) { GunnerGrenade(); m_uiAnimationState++; }
				else if( GetFrame(21, 7) and m_uiAnimationState == 1 ) { GunnerGrenade(); m_uiAnimationState++; }
				else if( GetFrame(21, 10) and m_uiAnimationState == 2 ) { GunnerGrenade(); m_uiAnimationState++; }
				else if( GetFrame(21, 13) and m_uiAnimationState == 3 ) { GunnerGrenade(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_CHAINGUN_START:
			{
				if( GetFrame(6, 4) and m_uiAnimationState == 0 ) { gunner_opengun(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_CHAINGUN_END:
			{
				if( GetFrame(7, 2) and m_uiAnimationState == 0 ) { gunner_opengun(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_KICK:
			{
				if( GetFrame(8, 0) and m_uiAnimationState == 0 ) { WalkMove(-7.7); m_uiAnimationState++; }
				else if( GetFrame(8, 1) and m_uiAnimationState == 1 ) { WalkMove(-4.9); m_uiAnimationState++; }
				else if( GetFrame(8, 2) and m_uiAnimationState == 2 ) { WalkMove(12.6); GunnerKick(); m_uiAnimationState++; }
				else if( GetFrame(8, 4) and m_uiAnimationState == 3 ) { WalkMove(-3.0); m_uiAnimationState++; }
				else if( GetFrame(8, 6) and m_uiAnimationState == 4 ) { WalkMove(-4.1); m_uiAnimationState++; }
				else if( GetFrame(8, 7) and m_uiAnimationState == 5 ) { WalkMove(8.6); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 6 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN1:
			{
				if( GetFrame(18, 0) and m_uiAnimationState == 0 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(18, 2) and m_uiAnimationState == 1 ) { WalkMove(-5.0); m_uiAnimationState++; }
				else if( GetFrame(18, 3) and m_uiAnimationState == 2 ) { WalkMove(3.0); m_uiAnimationState++; }
				else if( GetFrame(18, 4) and m_uiAnimationState == 3 ) { WalkMove(-1.0); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 9) and m_uiAnimationState == 4 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(18, 10) and m_uiAnimationState == 5 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(18, 11) and m_uiAnimationState == 6 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(18, 12) and m_uiAnimationState == 7 ) { WalkMove(1.0); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 14) and m_uiAnimationState == 8 ) { WalkMove(-2.0); m_uiAnimationState++; }
				else if( GetFrame(18, 15) and m_uiAnimationState == 9 ) { WalkMove(-2.0); m_uiAnimationState++; }
				else if( GetFrame(18, 17) and m_uiAnimationState == 10 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 11 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN2:
			{
				if( GetFrame(8, 0) and m_uiAnimationState == 0 ) { WalkMove(-2.0); m_uiAnimationState++; }
				else if( GetFrame(8, 1) and m_uiAnimationState == 1 ) { WalkMove(11.0); m_uiAnimationState++; }
				else if( GetFrame(8, 2) and m_uiAnimationState == 2 ) { WalkMove(6.0); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(8, 3) and m_uiAnimationState == 3 ) { WalkMove(2.0); m_uiAnimationState++; }
				else if( GetFrame(8, 4) and m_uiAnimationState == 4 ) { WalkMove(-1.0); m_uiAnimationState++; }
				else if( GetFrame(8, 5) and m_uiAnimationState == 5 ) { WalkMove(-7.0); m_uiAnimationState++; }
				else if( GetFrame(8, 6) and m_uiAnimationState == 6 ) { WalkMove(-2.0); m_uiAnimationState++; }
				else if( GetFrame(8, 7) and m_uiAnimationState == 7 ) { WalkMove(-7.0); Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 8 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN3:
			{
				if( GetFrame(9, 0) and m_uiAnimationState == 0 ) { WalkMove(-3.0); m_uiAnimationState++; }
				else if( GetFrame(9, 1) and m_uiAnimationState == 1 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(9, 2) and m_uiAnimationState == 2 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( GetFrame(9, 4) and m_uiAnimationState == 3 ) { WalkMove(1.0); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DUCK:
			{
				if( GetFrame(8, 4) ) { DoDucking(); }

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

	bool gunner_fidget()
	{
		if( Math.RandomFloat(0.0, 1.0) <= 0.05 )
		{
			SetAnim( ANIM_IDLE_FIDGET );
			return true;
		}

		return false;
	}

	void CheckKickInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_flNextKick > g_Engine.time ) return;

		if( GetPressed(IN_JUMP) )
		{
			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_KICK );

			m_flNextKick = g_Engine.time + 3.0;
		}
	}

	void GunnerKick()
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE, DMG_GENERIC, false );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK + g_Engine.v_up * MELEE_KICK;
			}
		}
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

	void GunnerGrenade()
	{
		Vector vecMuzzle;
		m_pDriveEnt.GetAttachment( 0, vecMuzzle, void );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > CNPC_MAXPITCH )
			vecAim.x = CNPC_MAXPITCH;
		else if( vecAim.x < -CNPC_MAXPITCH )
			vecAim.x = -CNPC_MAXPITCH;

		g_EngineFuncs.MakeVectors( vecAim );

		monster_muzzleflash( vecMuzzle, 20, 255, 128, 0 );
		monster_fire_grenade( vecMuzzle, g_Engine.v_forward * GRENADE_SPEED, GRENADE_DAMAGE );

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_GRENADE], VOL_NORM, ATTN_NORM );
	}

	void gunner_opengun()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_CHAINGUN_OPEN], VOL_NORM, ATTN_IDLE );
	}

	void GunnerFire()
	{
		Vector vecMuzzle;
		m_pDriveEnt.GetAttachment( 1, vecMuzzle, void );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > CNPC_MAXPITCH )
			vecAim.x = CNPC_MAXPITCH;
		else if( vecAim.x < -CNPC_MAXPITCH )
			vecAim.x = -CNPC_MAXPITCH;

		g_EngineFuncs.MakeVectors( vecAim );

		monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
		MachineGunEffects( vecMuzzle );
		monster_fire_bullet( vecMuzzle, g_Engine.v_forward, CHAINGUN_DAMAGE, CHAINGUN_SPREAD );

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
			ReduceAmmo( 1, 1 );

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_CHAINGUN_FIRE], VOL_NORM, ATTN_NORM );
	}

	void StopShooting()
	{
		if( GetState() < STATE_SPINUP or GetState() >= STATE_SPINDOWN ) return;

		if( ((GetState(STATE_SPINUP) or GetState(STATE_SHOOT)) and !GetButton(IN_ATTACK2)) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or GetAmmo(1) <= 0 )
		{
			SetState( STATE_SPINDOWN );
			SetAnim( ANIM_CHAINGUN_END );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.4;
		}
	}

	void DoAmmoRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( GetState() <= STATE_MOVING and GetAmmo(1) < CHAINGUN_AMMO )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				IncreaseAmmo( 1, AMMO_REGEN_AMOUNT );

				if( GetAmmo(1) > CHAINGUN_AMMO )
					SetAmmo( 1, CHAINGUN_AMMO );

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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2gunner", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

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
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2GUNNER );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2gunner@ pDriveEnt = cast<cnpc_q2gunner@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2gunner_rend_" + m_pPlayer.entindex();
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

class cnpc_q2gunner : CBaseDriveEntityQ2
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_WALK) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( GetAnim(ANIM_GRENADE) or IsBetween2(GetAnim(), ANIM_CHAINGUN_START, ANIM_CHAINGUN_END) )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

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
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_GIB], VOL_NORM, ATTN_NORM );
			SpawnGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		CNPC::Q2::ThrowGib( EHandle(self), 2, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 2, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_CHEST, pev.dmg, 6, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GARM, pev.dmg, 19, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GUN, pev.dmg, 9 );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_FOOT, pev.dmg, Math.RandomLong(0, 1) == 0 ? 4 : 25, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, pev.dmg, 7, BREAK_FLESH );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( pev.sequence )
		{
			case ANIM_DEATH:
			{
				if( GetFrame(11, 2) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(11, 3) and m_uiAnimationState == 1 ) { WalkMove(-7); m_uiAnimationState++; }
				else if( GetFrame(11, 4) and m_uiAnimationState == 2 ) { WalkMove(-3); m_uiAnimationState++; }
				else if( GetFrame(11, 5) and m_uiAnimationState == 3 ) { WalkMove(-5); m_uiAnimationState++; }
				else if( GetFrame(11, 6) and m_uiAnimationState == 4 ) { WalkMove(8); m_uiAnimationState++; }
				else if( GetFrame(11, 7) and m_uiAnimationState == 5 ) { WalkMove(6); m_uiAnimationState++; }
				else if( GetFrame(11, 8) and m_uiAnimationState == 6 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 7 ) { m_uiAnimationState = 0; }

				break;
			}
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
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

final class info_cnpc_q2gunner : CNPCSpawnEntity
{
	info_cnpc_q2gunner()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
	}
}

void Register()
{
	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2grenade" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2grenade", "cnpcq2grenade" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2gunner::info_cnpc_q2gunner", "info_cnpc_q2gunner" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2gunner::cnpc_q2gunner", "cnpc_q2gunner" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2gunner::weapon_q2gunner", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "q2gnrammo" );

	g_Game.PrecacheOther( "info_cnpc_q2gunner" );
	g_Game.PrecacheOther( "cnpc_q2gunner" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2gunner END

/* FIXME
*/

/* TODO
*/