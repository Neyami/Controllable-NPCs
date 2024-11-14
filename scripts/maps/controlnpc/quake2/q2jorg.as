namespace cnpc_q2jorg
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2jorg";
const string CNPC_MODEL				= "models/quake2/monsters/jorg/jorg.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_METAL		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/jorg/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/jorg/gibs/foot.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/jorg/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/jorg/gibs/head.mdl";
const string MODEL_GIB_SPIKE		= "models/quake2/monsters/jorg/gibs/spike.mdl";
const string MODEL_GIB_SPINE		= "models/quake2/monsters/jorg/gibs/spine.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/jorg/gibs/thigh.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/jorg/gibs/tube.mdl";

const Vector CNPC_SIZEMIN			= Vector( -80, -80, 0 );
const Vector CNPC_SIZEMAX			= Vector( 80, 80, 142 );

const float CNPC_HEALTH				= 3000.0;
const float CNPC_VIEWOFS_FPV		= 117.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 128.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not jorg itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_WALK					= 270.0;

const float GUN_FIRERATE				= 0.1;
const int GUN_AMMO						= 210;
const float GUN_DAMAGE				= 6.0;
const Vector GUN_SPREAD				= VECTOR_CONE_3DEGREES;

const int AMMO_REGEN_AMOUNT	= 2;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds
const float CNPC_MAXPITCH			= 30.0;

const float CD_BFG						= 2.0;
const float BFG_DAMAGE				= 50.0;
const float BFG_SPEED					= 300.0;
const float BFG_MAXPITCH				= 30.0;

const array<string> pDieSounds = 
{
	"quake2/npcs/jorg/bs3deth1.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/jorg/bs3idle1.wav",
	"quake2/npcs/jorg/bs3srch1.wav",
	"quake2/npcs/jorg/bs3srch2.wav",
	"quake2/npcs/jorg/bs3srch3.wav",
	"quake2/npcs/jorg/step1.wav",
	"quake2/npcs/jorg/step2.wav",
	"quake2/npcs/jorg/bs3atck1.wav",
	"quake2/npcs/jorg/w_loop.wav",
	"quake2/npcs/jorg/xfire.wav",
	"quake2/npcs/jorg/bs3atck1_end.wav",
	"quake2/npcs/jorg/bs3atck2.wav",
	"quake2/npcs/jorg/bs3pain1.wav",
	"quake2/npcs/jorg/bs3pain2.wav",
	"quake2/npcs/jorg/bs3pain3.wav"
	"quake2/npcs/jorg/d_hit.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE,
	SND_SEARCH1,
	SND_SEARCH2,
	SND_SEARCH3,
	SND_STEP_LEFT,
	SND_STEP_RIGHT,
	SND_ATK_GUN_START,
	SND_ATK_GUN_LOOP,
	SND_ATK_GUN_FIRE,
	SND_ATK_GUN_END,
	SND_ATK_BFG,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3,
	SND_DEATHHIT
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK,
	ANIM_ATTACK_GUNS,
	ANIM_GUNS_START,
	ANIM_GUNS_LOOP,
	ANIM_GUNS_END,
	ANIM_ATTACK_BFG,
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
	STATE_SPINUP,
	STATE_SHOOT,
	STATE_SPINDOWN,
	STATE_PAIN
};

enum attach_e
{
	ATTACH_GUN_LEFT = 0,
	ATTACH_GUN_RIGHT
};

final class weapon_q2jorg : CBaseDriveWeaponQ2
{
	private float m_flNextAmmoRegen;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.m_iDefaultAmmo = GUN_AMMO;
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_SPIKE );
		g_Game.PrecacheModel( MODEL_GIB_SPINE );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2jorg.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2jorg.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2jorg_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= GUN_AMMO;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2JORG_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2JORG_POSITION - 1;
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

		SetAmmo( 1, GUN_AMMO );

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
		StopIdleSound();

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
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
				if( GetAmmo(1) <= int(GUN_AMMO/2) ) return;

				SetState( STATE_SHOOT );
				SetSpeed( 0 );
				SetAnim( ANIM_GUNS_START );

				m_pDriveEnt.pev.dmgtime = 69; //let jorg turn while firing

				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_ATK_GUN_START], VOL_NORM, ATTN_NORM );
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_ATK_GUN_LOOP], 0.8, ATTN_IDLE );

				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			}
			else if( GetState(STATE_SHOOT) )
			{
				if( !GetAnim(ANIM_GUNS_LOOP) )
					SetAnim( ANIM_GUNS_LOOP );

				jorg_firebullets();

				self.m_flNextPrimaryAttack = g_Engine.time + GUN_FIRERATE;
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
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATTACK_BFG );

			m_pDriveEnt.pev.dmgtime = 69; //let jorg turn while firing
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_BFG;
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
			cnpc_q2jorg@ pDriveEnt = cast<cnpc_q2jorg@>(CastToScriptClass(m_pDriveEnt));
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
		}
	}

	//overridden here because of that pesky idle sound
	void SetAnim( int iAnim, float flFramerate = 1.0, float flFrame = 0.0 )
	{
		if( m_pDriveEnt !is null )
		{
			StopIdleSound();

			m_pDriveEnt.pev.sequence = iAnim;
			m_pDriveEnt.ResetSequenceInfo();
			m_pDriveEnt.pev.frame = flFrame;
			m_pDriveEnt.pev.framerate = flFramerate;
			m_uiAnimationState = 0;
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		if( !GetAnim(ANIM_WALK) )
		{
			SetState( STATE_MOVING );
			SetSpeed( int(SPEED_WALK) );
			SetAnim( ANIM_WALK );
		}
		else
			m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
	}

	void DoIdleAnimation()
	{
		if( GetState() >= STATE_ATTACK and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( GetState(STATE_SHOOT) or (GetAnim(ANIM_GUNS_END) and !m_pDriveEnt.m_fSequenceFinished) ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetSpeed( int(SPEED_WALK) );
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

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_NORM );
	}

	void StopIdleSound()
	{
		g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE] ); 
		g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_ATK_GUN_LOOP] );
	}

	void SearchSound()
	{
		float flRand = Math.RandomFloat( 0.0, 1.0 );

		if( flRand <= 0.3 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH1], VOL_NORM, ATTN_NORM );
		else if( flRand <= 0.6 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH2], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH3], VOL_NORM, ATTN_NORM );
	}

	void HandlePain( float flDamage )
	{
		m_pDriveEnt.pev.dmg = flDamage;

		if( m_pPlayer.pev.health < (CNPC_HEALTH * 0.5) )
			m_pDriveEnt.pev.skin = 1;
		else
			m_pDriveEnt.pev.skin = 0;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		// Lessen the chance of him going into his pain frames if he takes little damage
		if( flDamage <= 40 )
		{
			if( Math.RandomFloat(0.0, 1.0) <= 0.6 )
				return;
		}

		//If he's entering his attack1 or using attack1, lessen the chance of him going into pain
		if( GetAnim(ANIM_GUNS_START) )
		{
			if( Math.RandomFloat(0.0, 1.0) <= 0.2 ) //0.005
				return;
		}

		if( GetAnim(ANIM_GUNS_LOOP) )
		{
			if( Math.RandomFloat(0.0, 1.0) <= 0.1 ) //0.00005
				return;
		}

		if( GetAnim(ANIM_ATTACK_BFG) )
		{
			if( Math.RandomFloat(0.0, 1.0) <= 0.2 ) //0.005
				return;
		}

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		bool bDoPain3 = false;

		if( flDamage > 50 )
		{
			if( flDamage <= 100 )
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
			else
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.3 )
				{
					bDoPain3 = true;
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN3], VOL_NORM, ATTN_NORM );
				}
			}
		}

		//if (!M_ShouldReactToPain(self, mod))
			//return; // no pain anims in nightmare
		
		jorg_attack1_end_sound();

		if( flDamage <= 50 )
			SetAnim( ANIM_PAIN1 );
		else if( flDamage <= 100 )
			SetAnim( ANIM_PAIN2 );
		else if (bDoPain3)
			SetAnim( ANIM_PAIN3 );

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent()
	{
		switch( GetAnim() )
		{
			case ANIM_IDLE:
			{
				if( GetFrame(51, 0) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
				else if( GetFrame(51, 33) and m_uiAnimationState == 1 ) { WalkMove(19); m_uiAnimationState++; }
				else if( GetFrame(51, 34) and m_uiAnimationState == 2 ) { WalkMove(11); jorg_step_left(); m_uiAnimationState++; }
				else if( GetFrame(51, 37) and m_uiAnimationState == 3 ) { WalkMove(6); m_uiAnimationState++; }
				else if( GetFrame(51, 38) and m_uiAnimationState == 4 ) { WalkMove(9); jorg_step_right(); m_uiAnimationState++; }
				else if( GetFrame(51, 46) and m_uiAnimationState == 5 ) { WalkMove(-2); m_uiAnimationState++; }
				else if( GetFrame(51, 47) and m_uiAnimationState == 6 ) { WalkMove(-17); jorg_step_left(); m_uiAnimationState++; }
				else if( GetFrame(51, 49) and m_uiAnimationState == 7 ) { WalkMove(-12); m_uiAnimationState++; }
				else if( GetFrame(51, 50) and m_uiAnimationState == 8 ) { WalkMove(-14); jorg_step_right(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 9 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_WALK:
			{
				if( GetFrame(15, 0) and m_uiAnimationState == 0 ) { jorg_step_left(); m_uiAnimationState++; }
				else if( GetFrame(15, 1) and m_uiAnimationState == 1 ) { SetSpeed(int(SPEED_WALK*0.3)); m_uiAnimationState++; }
				else if( GetFrame(15, 4) and m_uiAnimationState == 2 ) { SetSpeed(SPEED_WALK); m_uiAnimationState++; }
				else if( GetFrame(15, 7) and m_uiAnimationState == 3 ) { jorg_step_right(); m_uiAnimationState++; }
				else if( GetFrame(15, 8) and m_uiAnimationState == 4 ) { SetSpeed(int(SPEED_WALK*0.3)); m_uiAnimationState++; }
				else if( GetFrame(15, 11) and m_uiAnimationState == 5 ) { SetSpeed(SPEED_WALK); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 6 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN3:
			{
				if( GetFrame(25, 0) and m_uiAnimationState == 0 ) { WalkMove(-28); m_uiAnimationState++; }
				else if( GetFrame(25, 1) and m_uiAnimationState == 1 ) { WalkMove(-6); m_uiAnimationState++; }
				else if( GetFrame(25, 2) and m_uiAnimationState == 2 ) { WalkMove(-3); jorg_step_left(); m_uiAnimationState++; }
				else if( GetFrame(25, 3) and m_uiAnimationState == 3 ) { WalkMove(-9); m_uiAnimationState++; }
				else if( GetFrame(25, 4) and m_uiAnimationState == 4 ) { jorg_step_right(); m_uiAnimationState++; }
				else if( GetFrame(25, 8) and m_uiAnimationState == 5 ) { WalkMove(-7); m_uiAnimationState++; }
				else if( GetFrame(25, 9) and m_uiAnimationState == 6 ) { WalkMove(1); m_uiAnimationState++; }
				else if( GetFrame(25, 10) and m_uiAnimationState == 7 ) { WalkMove(-11); m_uiAnimationState++; }
				else if( GetFrame(25, 11) and m_uiAnimationState == 8 ) { WalkMove(-4); m_uiAnimationState++; }
				else if( GetFrame(25, 14) and m_uiAnimationState == 9 ) { WalkMove(10); m_uiAnimationState++; }
				else if( GetFrame(25, 15) and m_uiAnimationState == 10 ) { WalkMove(11); m_uiAnimationState++; }
				else if( GetFrame(25, 17) and m_uiAnimationState == 11 ) { WalkMove(10); m_uiAnimationState++; }
				else if( GetFrame(25, 18) and m_uiAnimationState == 12 ) { WalkMove(3); m_uiAnimationState++; }
				else if( GetFrame(25, 19) and m_uiAnimationState == 13 ) { WalkMove(10); m_uiAnimationState++; }
				else if( GetFrame(25, 20) and m_uiAnimationState == 14 ) { WalkMove(7); jorg_step_left(); m_uiAnimationState++; }
				else if( GetFrame(25, 21) and m_uiAnimationState == 15 ) { WalkMove(17); m_uiAnimationState++; }
				else if( GetFrame(25, 24) and m_uiAnimationState == 16 ) { jorg_step_right(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 17 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATTACK_BFG:
			{
				if( GetFrame(13, 6) and m_uiAnimationState == 0 ) { jorgBFG(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void jorg_attack1_end_sound()
	{
		if( GetAnim(ANIM_GUNS_LOOP) or GetAnim(ANIM_GUNS_END) )
		{
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATK_GUN_END], VOL_NORM, ATTN_NORM );
			g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_ATK_GUN_LOOP] );
		}
	}

	void jorg_step_left()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_LEFT], VOL_NORM, ATTN_NORM );
	}

	void jorg_step_right()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_RIGHT], VOL_NORM, ATTN_NORM );
	}

	void jorg_firebullets()
	{
		for( uint i = 0; i < 2; i++ )
		{
			Vector vecMuzzle;
			m_pDriveEnt.GetAttachment( ATTACH_GUN_LEFT+i, vecMuzzle, void );

			Vector vecAim = m_pPlayer.pev.v_angle;
			if( vecAim.x > CNPC_MAXPITCH )
				vecAim.x = CNPC_MAXPITCH;
			else if( vecAim.x < -CNPC_MAXPITCH )
				vecAim.x = -CNPC_MAXPITCH;

			if( i == 0 ) //left
			{
				vecAim.y += -6.0; //closer to the crosshairs

				if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
					ReduceAmmo( 1, 1 );

				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATK_GUN_FIRE], VOL_NORM, ATTN_NORM );
			}
			else //right
				vecAim.y += 6.0; //closer to the crosshairs

			g_EngineFuncs.MakeVectors( vecAim );

			monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
			MachineGunEffects( vecMuzzle );
			monster_fire_bullet( vecMuzzle, g_Engine.v_forward, GUN_DAMAGE, GUN_SPREAD );
		}

		//jorg_firebullet_left();
		//jorg_firebullet_right();
	}

	void StopShooting()
	{
		if( GetState() < STATE_SPINUP or GetState() >= STATE_SPINDOWN ) return;

		if( ((GetState(STATE_SPINUP) or GetState(STATE_SHOOT)) and !GetButton(IN_ATTACK)) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or GetAmmo(1) <= 0 )
		{
			SetState( STATE_SPINDOWN );
			SetAnim( ANIM_GUNS_END );

			jorg_attack1_end_sound();

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.4;
			m_pDriveEnt.pev.dmgtime = 0.0; //stop jorg from turning when firing is done
		}
	}

	void DoAmmoRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( GetState() <= STATE_MOVING and GetAmmo(1) < GUN_AMMO )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				IncreaseAmmo( 1, AMMO_REGEN_AMOUNT );

				if( GetAmmo(1) > GUN_AMMO )
					SetAmmo( 1, GUN_AMMO );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void jorgBFG()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_ATK_BFG], VOL_NORM, ATTN_NORM );

		Math.MakeVectors( m_pDriveEnt.pev.angles );
		Vector vecOrigin = m_pDriveEnt.pev.origin + g_Engine.v_forward * 6.3 + g_Engine.v_right * -9.0 + g_Engine.v_up * 111.2;

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > BFG_MAXPITCH )
			vecAim.x = BFG_MAXPITCH;
		else if( vecAim.x < -BFG_MAXPITCH )
			vecAim.x = -BFG_MAXPITCH;

		vecAim.x += -2.0; //closer to the crosshairs
		vecAim.y += -1.0; //closer to the crosshairs

		monster_muzzleflash( vecOrigin, 30, 128, 255, 128 );

		Math.MakeVectors( vecAim );
		monster_fire_bfg( vecOrigin, g_Engine.v_forward, BFG_DAMAGE, BFG_SPEED );

		m_pDriveEnt.pev.dmgtime = 0.0; //stop jorg from turning when firing is done
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2jorg", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

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
			m1.WriteString( "cam_idealdist 256\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2JORG );
	}

	void DoFirstPersonView()
	{
		cnpc_q2jorg@ pDriveEnt = cast<cnpc_q2jorg@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2jorg_rend_" + m_pPlayer.entindex();
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

class cnpc_q2jorg : CBaseDriveEntityQ2
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and pev.sequence == ANIM_WALK )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( pev.dmgtime > 0.0 )
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

		SetAnim( ANIM_DEATH );

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		CNPC::Q2::ThrowGib( EHandle(self), 2, MODEL_GIB_MEAT, 500, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 2, MODEL_GIB_METAL, 500, -1, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_CHEST, 500, 2, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_FOOT, 500, 30, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_FOOT, 500, 31, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GUN, 500, 10, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GUN, 500, 19, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, 500, 3, BREAK_FLESH );

		for( uint i = 0; i < 6; i++ )
		{
			if( i <= 2 )
				CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_SPIKE, 500, 4+i, BREAK_METAL );
			else if( i > 2 )
				CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_SPIKE, 500, 10+i, BREAK_METAL );
		}

		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_SPINE, 500, 22, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_THIGH, 500, 23, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_THIGH, 500, 27, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 4, MODEL_GIB_TUBE, 500, -1 );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		if( GetAnim(ANIM_DEATH) )
		{
			if( GetFrame(50, 5) and m_uiAnimationState == 0 ) { WalkMove(-2); m_uiAnimationState++; }
			else if( GetFrame(50, 6) and m_uiAnimationState == 1 ) { WalkMove(-5); m_uiAnimationState++; }
			else if( GetFrame(50, 7) and m_uiAnimationState == 2 ) { WalkMove(-8); m_uiAnimationState++; }
			else if( GetFrame(50, 8) and m_uiAnimationState == 3 ) { WalkMove(-15); jorg_step_left(); m_uiAnimationState++; }
			else if( GetFrame(50, 15) and m_uiAnimationState == 4 ) { WalkMove(-11); m_uiAnimationState++; }
			else if( GetFrame(50, 16) and m_uiAnimationState == 5 ) { WalkMove(-25); m_uiAnimationState++; }
			else if( GetFrame(50, 17) and m_uiAnimationState == 6 ) { WalkMove(-10); jorg_step_right(); m_uiAnimationState++; }
			else if( GetFrame(50, 24) and m_uiAnimationState == 7 ) { WalkMove(-21); m_uiAnimationState++; }
			else if( GetFrame(50, 25) and m_uiAnimationState == 8 ) { WalkMove(-10); m_uiAnimationState++; }
			else if( GetFrame(50, 26) and m_uiAnimationState == 9 ) { WalkMove(-16); jorg_step_left(); m_uiAnimationState++; }
			else if( GetFrame(50, 32) and m_uiAnimationState == 10 ) { WalkMove(22); m_uiAnimationState++; }
			else if( GetFrame(50, 33) and m_uiAnimationState == 11 ) { WalkMove(33); jorg_step_left(); m_uiAnimationState++; }
			else if( GetFrame(50, 36) and m_uiAnimationState == 12 ) { WalkMove(28); m_uiAnimationState++; }
			else if( GetFrame(50, 37) and m_uiAnimationState == 13 ) { WalkMove(28); jorg_step_right(); m_uiAnimationState++; }
			else if( GetFrame(50, 46) and m_uiAnimationState == 14 ) { WalkMove(-19); m_uiAnimationState++; }
			else if( GetFrame(50, 47) and m_uiAnimationState == 15 ) { jorg_death_hit(); m_uiAnimationState++; }
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
		}
	}

	void jorg_death_hit()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_DEATHHIT], VOL_NORM, ATTN_NORM );
	}

	void jorg_step_left()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_LEFT], VOL_NORM, ATTN_NORM );
	}

	void jorg_step_right()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_RIGHT], VOL_NORM, ATTN_NORM );
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

final class info_cnpc_q2jorg : CNPCSpawnEntity
{
	info_cnpc_q2jorg()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2jorg::info_cnpc_q2jorg", "info_cnpc_q2jorg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2jorg::cnpc_q2jorg", "cnpc_q2jorg" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2jorg::weapon_q2jorg", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "q2jorgammo" );

	g_Game.PrecacheOther( "info_cnpc_q2jorg" );
	g_Game.PrecacheOther( "cnpc_q2jorg" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2jorg END

/* FIXME
*/

/* TODO
*/