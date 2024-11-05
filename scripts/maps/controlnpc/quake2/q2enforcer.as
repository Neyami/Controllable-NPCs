namespace cnpc_q2enforcer
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2enforcer";
const string CNPC_MODEL				= "models/quake2/monsters/enforcer/enforcer.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/enforcer/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/enforcer/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/enforcer/gibs/foot.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/enforcer/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/enforcer/gibs/head.mdl";

const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 120.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the enforcer itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_RUN					= -1;
const float SPEED_WALK					= -1;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float GUN_FIRERATE				= 0.1;
const int GUN_AMMO						= 30;
const float GUN_DAMAGE				= 3.0;
const int AMMO_REGEN_AMOUNT	= 2;
const float AMMO_REGEN_RATE		= 0.1; //+AMMO_REGEN_AMOUNT per AMMO_REGEN_RATE seconds
const float GUN_MAXPITCH				= 30.0;

const float CD_MELEE						= 1.5;
const float MELEE_RANGE				= 80.0;
const float MELEE_KICK					= 50.0;

const array<string> pPainSounds = 
{
	"quake2/npcs/enforcer/infpain1.wav",
	"quake2/npcs/enforcer/infpain2.wav"
};

const array<string> pDieSounds = 
{
	"quake2/npcs/enforcer/infdeth1.wav",
	"quake2/npcs/enforcer/infdeth2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/enforcer/infidle1.wav",
	"quake2/npcs/enforcer/infsght1.wav",
	"quake2/npcs/enforcer/infsrch1.wav",
	"quake2/npcs/enforcer/infatck3.wav",
	"quake2/npcs/enforcer/infatck1.wav",
	"quake2/npcs/enforcer/infatck2.wav",
	"quake2/npcs/enforcer/melee2.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_COCK,
	SND_SHOOT,
	SND_MELEE,
	SND_MELEE_HIT
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_RUN_SHOOT, //8
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_DUCK,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEFEND, //5
	ANIM_GUN_NOCOCK,
	ANIM_GUN_START,
	ANIM_GUN_LOOP,
	ANIM_GUN_END,
	ANIM_MELEE
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_DUCKING,
	STATE_PAIN,
	STATE_GUN_START,
	STATE_GUN_SHOOT,
	STATE_GUN_END,
};

final class weapon_q2enforcer : CBaseDriveWeaponQ2
{
	private float m_flNextAmmoRegen;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2enforcer.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2enforcer.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2enforcer_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= GUN_AMMO;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2ENFORCER_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2ENFORCER_POSITION - 1;
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

		self.m_iDefaultAmmo = GUN_AMMO;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, GUN_AMMO );

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
			if( m_iState < STATE_GUN_START )
			{
				if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

				SetState( STATE_GUN_SHOOT );
				SetSpeed( 0 );
				SetAnim( ANIM_GUN_START );

				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0;

				return;
			}
			else if( m_iState == STATE_GUN_SHOOT )
			{
				if( !GetAnim(ANIM_GUN_LOOP) )
					SetAnim( ANIM_GUN_LOOP );

				Shoot();

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
			SetAnim( ANIM_MELEE );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
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
			cnpc_q2enforcer@ pDriveEnt = cast<cnpc_q2enforcer@>(CastToScriptClass(m_pDriveEnt));
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

			StopShooting();
			DoAmmoRegen();
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
		if( (GetAnim() >= ANIM_GUN_START or GetAnim(ANIM_GUN_END)) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( GetState(STATE_GUN_SHOOT) ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
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

		if( GetState(STATE_DUCKING) )
			return;

		int brandom = Math.RandomLong( 0, 1 );
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[0+brandom], VOL_NORM, ATTN_NORM );

		SetAnim( ANIM_PAIN1 + brandom );
		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_IDLE_FIDGET:
			{
				if( GetFrame(49, 0) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
				else if( GetFrame(49, 5) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(49, 47) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_WALK:
			{
				if( GetFrame(13, 0) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(13, 6) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
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

			case ANIM_PAIN1:
			{
				if( GetFrame(10, 4) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(10, 9) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN2:
			{
				if( GetFrame(10, 4) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(10, 9) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DUCK:
			{
				if( GetFrame(5, 3) ) { DoDucking(); }

				break;
			}
			/*//Footstep on 1 and 6
			//Fire on 2
			//Skip to frame 14 on 6
			case ANIM_GUN_NOCOCK: //15
			{
				break;
			}*/

			case ANIM_GUN_START:
			{
				if( GetFrame(11, 3) and m_uiAnimationState == 0 ) { CockSound(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE:
			{
				if( GetFrame(8, 2) and m_uiAnimationState == 0 ) { AttackSound(); m_uiAnimationState++; }
				else if( GetFrame(8, 3) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(8, 5) and m_uiAnimationState == 2 ) { MeleeAttack(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void CheckDuckInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( GetButton(IN_DUCK) )
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

	void Footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		CNPC::monster_footstep( EHandle(m_pDriveEnt), EHandle(m_pPlayer), m_iStepLeft, iPitch, bSetOrigin, vecSetOrigin );
	}

	void AttackSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MELEE], VOL_NORM, ATTN_NORM );
	}

	void MeleeAttack()
	{
		int iDamage = Math.RandomLong(5, 10);

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, iDamage, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				Math.MakeVectors( m_pDriveEnt.pev.angles );

				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK;
			}

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
		}
		else
			self.m_flNextSecondaryAttack = g_Engine.time + CD_MELEE;
	}

	void CockSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_COCK], VOL_NORM, ATTN_NORM );
	}

	void Shoot()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( 0, vecOrigin, void );

		MachineGunEffects( vecOrigin, 3 );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > GUN_MAXPITCH )
			vecAim.x = GUN_MAXPITCH;
		else if( vecAim.x < -GUN_MAXPITCH )
			vecAim.x = -GUN_MAXPITCH;

		vecAim.y += 1.0; //closer to the crosshairs
		vecAim.x -= 0.5; //closer to the crosshairs

		g_EngineFuncs.MakeVectors( vecAim );

		monster_fire_bullet( vecOrigin, g_Engine.v_forward, GUN_DAMAGE, VECTOR_CONE_3DEGREES );

		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) == 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
	}

	void StopShooting()
	{
		if( GetState() < STATE_GUN_START or GetState() >= STATE_GUN_END ) return;

		if( ((GetState(STATE_GUN_START) or GetState(STATE_GUN_SHOOT)) and (m_pPlayer.pev.button & IN_ATTACK) == 0) or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			SetState( STATE_GUN_END );
			SetAnim( ANIM_GUN_END );
		}
	}

	void DoAmmoRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( GetState() <= STATE_MOVING and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < GUN_AMMO )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + AMMO_REGEN_AMOUNT );
				if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > GUN_AMMO )
					m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, GUN_AMMO );

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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2enforcer", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = DONT_BLEED; //BLOOD_COLOR_RED;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2ENFORCER );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2enforcer@ pDriveEnt = cast<cnpc_q2enforcer@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2enforcer_rend_" + m_pPlayer.entindex();
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

class cnpc_q2enforcer : CBaseDriveEntityQ2
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
		else if( GetAnim() >= ANIM_GUN_START )
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

		int iRand = Math.RandomLong( 0, 2 );
		if( iRand == 0 )
		{
			pev.body = 1;
			pev.sequence = ANIM_DEATH1;
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[1], VOL_NORM, ATTN_NORM );
		}
		else if( iRand == 1 )
		{
			pev.body = 1;
			pev.sequence = ANIM_DEATH2;
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[0], VOL_NORM, ATTN_NORM );
		}
		else
		{
			pev.sequence = ANIM_DEATH3;
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[1], VOL_NORM, ATTN_NORM );
		}

		// don't always pop a head gib, it gets old
		if( iRand != 2 and Math.RandomFloat(0.0, 1.0) <= 0.45 ) //0.25
			CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, pev.dmg, -1, BREAK_FLESH );

		pev.frame = 0;
		self.ResetSequenceInfo();
		m_uiAnimationState = 0;

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_CHEST, pev.dmg, 5, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GUN, pev.dmg, 9 );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_FOOT, pev.dmg, 4, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_FOOT, pev.dmg, 17, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_ARM, pev.dmg, 8, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_ARM, pev.dmg, 12, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, pev.dmg, 6, BREAK_FLESH );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( pev.sequence )
		{
			case ANIM_DEATH1:
			{
				if( GetFrame(20, 2) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(20, 8) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(20, 15) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(20, 17) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DEATH2:
			{
				if( GetFrame(25, 5) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(25, 6) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( m_uiAnimationState >= 2 and m_uiAnimationState <= 13 )
				{
					if( GetFrame(25, 8 + m_uiAnimationState) )
					{
						DeathShot();
						m_uiAnimationState++;
					}
				}
				else if( GetFrame(25, 22) and m_uiAnimationState == 14 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 15 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DEATH3:
			{
				if( GetFrame(9, 2) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(9, 7) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
		}
	}

	void Footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		CNPC::monster_footstep( EHandle(self), EHandle(self), m_iStepLeft, iPitch, bSetOrigin, vecSetOrigin );
	}

	void DeathShot()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		Vector vecBonePos, vecMuzzle2;
		g_EngineFuncs.GetBonePosition( self.edict(), 9, vecBonePos, void );
		self.GetAttachment( 1, vecMuzzle2, void );

		Vector vecAim = (vecMuzzle2 - vecBonePos).Normalize();

		MachineGunEffects( vecMuzzle2 );
		monster_fire_bullet( vecMuzzle2, vecAim, GUN_DAMAGE, VECTOR_CONE_3DEGREES );
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

final class info_cnpc_q2enforcer : CNPCSpawnEntity
{
	info_cnpc_q2enforcer()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2enforcer::info_cnpc_q2enforcer", "info_cnpc_q2enforcer" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2enforcer::cnpc_q2enforcer", "cnpc_q2enforcer" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2enforcer::weapon_q2enforcer", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "q2enfammo" );

	g_Game.PrecacheOther( "info_cnpc_q2enforcer" );
	g_Game.PrecacheOther( "cnpc_q2enforcer" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2enforcer END

/* FIXME
*/

/* TODO
	Running attack ??
*/