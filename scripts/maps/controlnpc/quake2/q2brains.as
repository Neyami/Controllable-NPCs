namespace cnpc_q2brains
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2brains";
const string CNPC_MODEL				= "models/quake2/monsters/brains/brains.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/brains/gibs/arm.mdl";
const string MODEL_GIB_BOOT		= "models/quake2/monsters/brains/gibs/boot.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/brains/gibs/chest.mdl";
const string MODEL_GIB_DOOR		= "models/quake2/monsters/brains/gibs/door.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/brains/gibs/head.mdl";
const string MODEL_GIB_PELVIS		= "models/quake2/monsters/brains/gibs/pelvis.mdl";

const Vector CNPC_SIZEMIN			= Vector( -16, -16, 0 );
const Vector CNPC_SIZEMAX			= Vector( 16, 16, 80 );

const float CNPC_HEALTH				= 300.0;
const float CNPC_VIEWOFS_FPV		= 48.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 42.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the brains itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_WALK					= 270*0.5;

const float CD_SLASH						= 1.0; //3.0
const float MELEE_RANGE				= 80.0;
const int MELEE_DAMAGE_MIN		= 15;
const int MELEE_DAMAGE_MAX		= 20;
const float MELEE_KICK					= 80.0;

const float CD_CHEST						= 1.0; //3.0
const float MELEE_RANGE_CHEST	= 120;

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/brains/brnlens1.wav",
	"quake2/npcs/brains/brnsght1.wav",
	"quake2/npcs/brains/brnsrch1.wav",
	"quake2/npcs/brains/melee1.wav",
	"quake2/npcs/brains/melee2.wav",
	"quake2/npcs/brains/melee3.wav",
	"quake2/npcs/brains/brnatck1.wav",
	"quake2/npcs/brains/brnatck3.wav",
	"quake2/npcs/brains/brnpain1.wav",
	"quake2/npcs/brains/brnpain2.wav",
	"quake2/npcs/brains/brndeth1.wav",
	"quake2/weapons/laser_hit.wav",
	"quake2/misc/mon_power2.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_MELEE1,
	SND_MELEE2,
	SND_MELEE_HIT,
	SND_CHEST_OPEN,
	SND_TENTS_IN,
	SND_PAIN1,
	SND_PAIN2,
	SND_DEATH,
	SND_ARMORHIT,
	SND_ARMOROFF
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK,
	ANIM_SLASH,
	ANIM_CHEST,
	ANIM_DUCK,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_DEATH1,
	ANIM_DEATH2
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_DUCKING,
	STATE_PAIN
};

final class weapon_q2brains : CBaseDriveWeaponQ2
{
	private bool m_bChestAttack;
	private float m_flCurrentArmor;
	private float m_flArmorEffectTime;
	private float m_flArmorEffectOff;
	private bool m_bHasArmor;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_BOOT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_DOOR );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_PELVIS );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2brains.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2brains.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2brains_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2BRAINS_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2BRAINS_POSITION - 1;
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
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_SLASH );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SLASH;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetYaw( m_pPlayer.pev.v_angle.y );
			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_CHEST );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_CHEST;
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
			cnpc_q2brains@ pDriveEnt = cast<cnpc_q2brains@>(CastToScriptClass(m_pDriveEnt));
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
			HandleAnimEvent();

			CheckDuckInput();
			PowerArmorOff();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		if( m_pDriveEnt.pev.sequence != ANIM_WALK )
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

	void AlertSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandlePain( float flDamage, float flYaw, float flDot )
	{
		if( flDot > 0.3 )
			CheckPowerArmor( flYaw );

		m_pDriveEnt.pev.dmg = flDamage;
		m_flCurrentArmor = m_pPlayer.pev.armorvalue;

		if( m_pPlayer.pev.health < (CNPC_HEALTH * 0.5) )
			m_pDriveEnt.pev.skin = 1;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		float flRand = Math.RandomFloat( 0.0, 1.0 );

		if( flRand < 0.33 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
		else if( flRand < 0.66 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );

		if( /*GetState(STATE_DUCKING) or */GetAnim(ANIM_CHEST) )
			return;

		if( flRand < 0.33 )
			SetAnim( ANIM_PAIN1 );
		else if( flRand < 0.66 )
			SetAnim( ANIM_PAIN2 );
		else
			SetAnim( ANIM_PAIN3 );

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void CheckPowerArmor( float flYaw )
	{
		if( m_flArmorEffectTime > g_Engine.time ) return;

		if( m_pPlayer.pev.armorvalue > 0 and m_flCurrentArmor > 0 )
		{
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_ARMORHIT], VOL_NORM, ATTN_NORM );
			PowerArmorEffect( flYaw );
			m_flArmorEffectTime = g_Engine.time + 0.2;
		}
	}

	void HandleAnimEvent()
	{
		switch( m_pDriveEnt.pev.sequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(12, 3) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(12, 4) and m_uiAnimationState == 1 ) { SetSpeed(int(SPEED_WALK*0.3)); m_uiAnimationState++; } //limp a bit
				else if( GetFrame(12, 8) and m_uiAnimationState == 2 ) { SetSpeed(SPEED_WALK); m_uiAnimationState++; }
				else if( GetFrame(12, 9) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_SLASH:
			{
				if( GetFrame(18, 3) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 4) and m_uiAnimationState == 1 ) { WalkMove(-3); brain_swing_right(); m_uiAnimationState++; }
				else if( GetFrame(18, 7) and m_uiAnimationState == 2 ) { WalkMove(-7); MeleeAttack(true); m_uiAnimationState++; }
				else if( GetFrame(18, 9) and m_uiAnimationState == 3 ) { WalkMove(6); brain_swing_left(); m_uiAnimationState++; }
				else if( GetFrame(18, 11) and m_uiAnimationState == 4 ) { WalkMove(2); MeleeAttack(false); m_uiAnimationState++; }
				else if( GetFrame(18, 17) and m_uiAnimationState == 5 ) { WalkMove(-12); Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 6 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_CHEST:
			{
				if( GetFrame(17, 0) and m_uiAnimationState == 0 ) { ChestSound(true); m_uiAnimationState++; }
				else if( GetFrame(17, 6) and m_uiAnimationState == 1 ) { brain_tentacle_attack(); m_uiAnimationState++; }
				else if( GetFrame(17, 7) and m_uiAnimationState == 2 ) { ChestSound(false); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DUCK:
			{
				if( GetFrame(8, 4) ) { DoDucking(); }

				break;
			}

			case ANIM_PAIN1:
			{
				if( GetFrame(21, 0) and m_uiAnimationState == 0 ) { WalkMove(-6); m_uiAnimationState++; }
				else if( GetFrame(21, 1) and m_uiAnimationState == 1 ) { WalkMove(-2); m_uiAnimationState++; }
				else if( GetFrame(21, 2) and m_uiAnimationState == 2 ) { WalkMove(-6); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(21, 13) and m_uiAnimationState == 3 ) { WalkMove(2); m_uiAnimationState++; }
				else if( GetFrame(21, 15) and m_uiAnimationState == 4 ) { WalkMove(2); m_uiAnimationState++; }
				else if( GetFrame(21, 16) and m_uiAnimationState == 5 ) { WalkMove(1); m_uiAnimationState++; }
				else if( GetFrame(21, 17) and m_uiAnimationState == 6 ) { WalkMove(7); m_uiAnimationState++; }
				else if( GetFrame(21, 19) and m_uiAnimationState == 7 ) { WalkMove(3); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(21, 20) and m_uiAnimationState == 8 ) { WalkMove(-1); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 9 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN2:
			{
				if( GetFrame(8, 0) and m_uiAnimationState == 0 ) { WalkMove(-2); m_uiAnimationState++; }
				else if( GetFrame(8, 5) and m_uiAnimationState == 1 ) { WalkMove(3); m_uiAnimationState++; }
				else if( GetFrame(8, 6) and m_uiAnimationState == 2 ) { WalkMove(1); m_uiAnimationState++; }
				else if( GetFrame(8, 7) and m_uiAnimationState == 3 ) { WalkMove(-2); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN3:
			{
				if( GetFrame(6, 0) and m_uiAnimationState == 0 ) { WalkMove(-2); m_uiAnimationState++; }
				else if( GetFrame(6, 1) and m_uiAnimationState == 1 ) { WalkMove(2); m_uiAnimationState++; }
				else if( GetFrame(6, 2) and m_uiAnimationState == 2 ) { WalkMove(1); m_uiAnimationState++; }
				else if( GetFrame(6, 3) and m_uiAnimationState == 3 ) { WalkMove(3); m_uiAnimationState++; }
				else if( GetFrame(6, 5) and m_uiAnimationState == 4 ) { WalkMove(-4); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 5 ) { m_uiAnimationState = 0; }

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

	void PowerArmorEffect( float flYaw = 0.0 )
	{
		CBaseEntity@ pScreenEffect = g_EntityFuncs.Create( "cnpcq2pscreen", m_pPlayer.pev.origin + Vector(0, 0, 12), Vector(0, flYaw, 0), false ); //22
		if( pScreenEffect !is null )
		{
			pScreenEffect.pev.scale = 24; //32.0;
			pScreenEffect.pev.rendermode = kRenderTransColor;
			pScreenEffect.pev.renderamt = 76.5; //30.0

			//Push it out a bit
			Math.MakeVectors( pScreenEffect.pev.angles );
			g_EntityFuncs.SetOrigin( pScreenEffect, pScreenEffect.pev.origin + g_Engine.v_forward * m_pDriveEnt.pev.size.x );
		}
	}

	void PowerArmorOff()
	{
		if( m_bHasArmor and m_flArmorEffectOff < g_Engine.time )
		{
			if( m_pPlayer.pev.armorvalue <= 0 and m_flCurrentArmor <= 0 )
			{
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_ARMOROFF], VOL_NORM, ATTN_NORM );
				m_bHasArmor = false;
			}

			m_flArmorEffectOff = g_Engine.time + 0.1;
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

	void brain_swing_right()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_MELEE1], VOL_NORM, ATTN_NORM );
	}

	void brain_swing_left()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_MELEE2], VOL_NORM, ATTN_NORM );
	}

	void MeleeAttack( bool bRight )
	{
		int iDamage = Math.RandomLong(MELEE_DAMAGE_MIN, MELEE_DAMAGE_MAX);

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, iDamage, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				Math.MakeVectors( m_pDriveEnt.pev.angles );

				if( bRight )
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK + g_Engine.v_right * -MELEE_KICK;
				else
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK + g_Engine.v_right * MELEE_KICK;
			}

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
		}
	}

	void ChestSound( bool bOpen )
	{
		if( bOpen )
		{
			m_bChestAttack = false;
			m_flCurrentArmor = m_pPlayer.pev.armorvalue;
			m_pPlayer.pev.armorvalue = 0;

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_CHEST_OPEN], VOL_NORM, ATTN_NORM );
		}
		else
		{
			if( m_flCurrentArmor > 0 )
				m_pPlayer.pev.armorvalue = m_flCurrentArmor;

			if( m_bChestAttack )
			{
				m_bChestAttack = false;

				SetState( STATE_ATTACK );
				SetSpeed( 0 );
				SetAnim( ANIM_SLASH );
			}
		}
	}

	void brain_tentacle_attack()
	{
		int iDamage = Math.RandomLong(10, 15);

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE_CHEST, iDamage, DMG_SLASH, false );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				Math.MakeVectors( m_pDriveEnt.pev.angles );

				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -600;

				m_bChestAttack = true;
			}
		}
		//else
			//self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_TENTS_IN], VOL_NORM, ATTN_NORM );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2brains", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.armortype = m_pPlayer.pev.armorvalue = m_flCurrentArmor = 100;
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2BRAINS );

		AlertSound();
		m_bHasArmor = true;
	}

	void DoFirstPersonView()
	{
		cnpc_q2brains@ pDriveEnt = cast<cnpc_q2brains@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2brains_rend_" + m_pPlayer.entindex();
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

class cnpc_q2brains : CBaseDriveEntityQ2
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
		else if( GetAnim(ANIM_SLASH) )
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

		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH2 );
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 2, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_ARM, pev.dmg, 28, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_ARM, pev.dmg, 35, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_BOOT, pev.dmg, 45 );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_DOOR, pev.dmg, 25, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_DOOR, pev.dmg, 26, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, pev.dmg, 4, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_PELVIS, pev.dmg, 1, BREAK_FLESH );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( pev.sequence )
		{
			case ANIM_DEATH1:
			{
				if( GetFrame(18, 1) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 2) and m_uiAnimationState == 1 ) { WalkMove(-2); m_uiAnimationState++; }
				else if( GetFrame(18, 3) and m_uiAnimationState == 2 ) { WalkMove(9); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 7) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(18, 15) and m_uiAnimationState == 4 ) { Footstep(); m_uiAnimationState++; }

				break;
			}

			case ANIM_DEATH2:
			{
				if( GetFrame(5, 1) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(5, 3) and m_uiAnimationState == 1 ) { WalkMove(9); m_uiAnimationState++; }


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

final class info_cnpc_q2brains : CNPCSpawnEntity
{
	info_cnpc_q2brains()
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
	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2pscreen" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2pscreen", "cnpcq2pscreen" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2brains::info_cnpc_q2brains", "info_cnpc_q2brains" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2brains::cnpc_q2brains", "cnpc_q2brains" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2brains::weapon_q2brains", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "cnpcq2pscreen" );
	g_Game.PrecacheOther( "info_cnpc_q2brains" );
	g_Game.PrecacheOther( "cnpc_q2brains" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2brains END

/* FIXME
*/

/* TODO
	Add laser attack
	Use a custom variable and hud instead of pev.armorvalue for the power screen
*/