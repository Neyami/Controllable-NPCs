namespace cnpc_q2berserker
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2berserker";
const string CNPC_MODEL				= "models/quake2/monsters/berserker/berserker.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_GEAR		= "models/quake2/objects/gibs/gear.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/berserker/gibs/chest.mdl";
const string MODEL_GIB_HAMMER	= "models/quake2/monsters/berserker/gibs/hammer.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/berserker/gibs/head.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/berserker/gibs/thigh.mdl";

const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 240.0;
const float CNPC_VIEWOFS_FPV		= 48.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 32.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the berserker itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_RUN					= -1;
const float SPEED_WALK					= -1;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_SPIKE						= 1.0;
const float CD_CLUB						= 1.0;
const float MELEE_RANGE				= 80.0;
const float MELEE_KICK_SPIKE		= 80.0;
const float MELEE_KICK_CLUB		= 400.0;

const float JUMP_LOWEST				= 350.0;
const float JUMP_HIGHEST				= 650.0;

const float SLAM_DAMAGE				= 18.0; //8
const float SLAM_RADIUS				= 125.0; //165
const float SLAM_MULTIPLIER_MAX	= 3.0;

const array<string> pPainSounds = 
{
	"quake2/npcs/berserker/berpain2.wav"
};

const array<string> pDieSounds = 
{
	"quake2/npcs/berserker/berdeth2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/berserker/beridle1.wav",
	"quake2/npcs/berserker/sight.wav",
	"quake2/npcs/berserker/bersrch1.wav",
	"quake2/npcs/berserker/attack.wav",
	"quake2/npcs/mutant/thud1.wav",
	"quake2/world/explod2.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_ATTACK,
	SND_THUD,
	SND_EXPLODE
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_SPIKE,
	ANIM_CLUB,
	ANIM_STRIKE,
	ANIM_DUCK = 10,
	ANIM_PAIN1 = 12,
	ANIM_PAIN2,
	ANIM_DEATH1,
	ANIM_DEATH2
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_DUCKING,
	STATE_PAIN,
	STATE_JUMP
};

final class weapon_q2berserker : CBaseDriveWeaponQ2
{
	private float m_flJumpSpeed;
	private int m_iSlamShockwave;
	private float m_flAirtimeMultiplier;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		m_flJumpSpeed = JUMP_LOWEST;
		m_flAirtimeMultiplier = 1.0;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_GEAR );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_HAMMER );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );

		m_iSlamShockwave = g_Game.PrecacheModel( "sprites/shockwave.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2berserker.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2berserker.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2berserker_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= 100;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2BERSERKER_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2BERSERKER_POSITION - 1;
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
			SetAnim( ANIM_CLUB );
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 0 );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SPIKE;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_SPIKE );
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 0 );
		}

		self.m_flNextSecondaryAttack = g_Engine.time + CD_CLUB;
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
			cnpc_q2berserker@ pDriveEnt = cast<cnpc_q2berserker@>(CastToScriptClass(m_pDriveEnt));
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
			CheckJumpInput();
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
				m_pDriveEnt.pev.framerate = 0.8; //the walking animation is too fast
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

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_NORM );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
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

		if( GetState(STATE_JUMP) or GetState(STATE_ATTACK) ) return;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0,(pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

		if( GetState(STATE_DUCKING) )
			return;

		if( flDamage <= 50 or Math.RandomFloat(0.0, 1.0) < 0.5 )
			SetAnim( ANIM_PAIN1 );
		else
			SetAnim( ANIM_PAIN2 );

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(12, 3) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(12, 9) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
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

			case ANIM_IDLE_FIDGET:
			{
				if( GetFrame(20, 5) and m_uiAnimationState == 0 ) { IdleSound(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_SPIKE:
			{
				if( GetFrame(8, 3) and m_uiAnimationState == 0 ) { AttackSound(); m_uiAnimationState++; }
				else if( GetFrame(8, 4) and m_uiAnimationState == 1 ) { MeleeAttack(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_CLUB:
			{
				if( GetFrame(12, 2) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(12, 5) and m_uiAnimationState == 1 ) { AttackSound(); m_uiAnimationState++; }
				else if( GetFrame(12, 7) and m_uiAnimationState == 2 ) { MeleeAttack(true); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_STRIKE:
			{
				if( GetFrame(23, 3) and m_uiAnimationState == 0 ) { SetFramerate(0.1); m_uiAnimationState++; }
				else if( GetFrame(23, 5) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(23, 7) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(23, 22) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN2:
			{
				if( GetFrame(20, 4) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(20, 13) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(20, 19) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DUCK:
			{
				if( GetFrame(10, 5) ) { DoDucking(); }

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

	void AttackSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_ATTACK], VOL_NORM, ATTN_NORM );
	}

	void MeleeAttack( bool bClubAttack = false )
	{
		int iDamage = Math.RandomLong(5, 11);
		if( bClubAttack ) iDamage = Math.RandomLong(15, 21);

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, iDamage, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				Math.MakeVectors( m_pDriveEnt.pev.angles );

				if( bClubAttack )
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK_CLUB + g_Engine.v_right * (MELEE_KICK_CLUB * 0.5);
				else
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK_SPIKE + g_Engine.v_up * (MELEE_KICK_SPIKE * 3.0);
			}
		}
	}

	void CheckJumpInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( GetPushedDown(IN_JUMP) )
		{
			m_flJumpSpeed = JUMP_LOWEST;
			m_flAirtimeMultiplier = 1.0;
		}
		else if( GetReleased(IN_JUMP) )
		{
			SetState( STATE_JUMP );
			SetSpeed( 0 );
			SetAnim( ANIM_STRIKE );
			SetYaw( m_pPlayer.pev.v_angle.y );

			Math.MakeVectors( m_pDriveEnt.pev.angles );
			g_EntityFuncs.SetOrigin( m_pPlayer, m_pPlayer.pev.origin + Vector(0, 0, 1) );
			Vector vecJumpVelocity = Vector( g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z ) * m_flJumpSpeed;
			m_pPlayer.pev.velocity = vecJumpVelocity;

			SetThink( ThinkFunction(this.JumpThink) );
			pev.nextthink = g_Engine.time;
		}
		else if( GetButton(IN_JUMP) )
		{
			if( m_flNextThink < g_Engine.time )
			{
				m_flJumpSpeed += 10;
				if( m_flJumpSpeed > JUMP_HIGHEST )
					m_flJumpSpeed = JUMP_HIGHEST;

				float flNormalizedJumpSpeed = (m_flJumpSpeed - JUMP_LOWEST) / (JUMP_HIGHEST - JUMP_LOWEST);

				m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, int(flNormalizedJumpSpeed * 100) );
				m_flNextThink = g_Engine.time + 0.1;
			}
		}
	}

	void JumpThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			SetFramerate( 1.0 );

			if( m_flJumpSpeed < (JUMP_HIGHEST * 0.8) )
				m_pDriveEnt.pev.frame = SetFrame( 23, 18 );
			else
				m_pDriveEnt.pev.frame = SetFrame( 23, 7 );

			m_uiAnimationState = 2;

			berserk_attack_slam();

			m_flJumpSpeed = JUMP_LOWEST;
			m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, 0 );
			m_pPlayer.pev.velocity = g_vecZero;

			SetThink( null );

			return;
		}

		if( m_flAirtimeMultiplier < SLAM_MULTIPLIER_MAX )
			m_flAirtimeMultiplier += 0.1;
	}

	void berserk_attack_slam()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_THUD], VOL_NORM, ATTN_NORM );
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_EXPLODE], 0.75, ATTN_NORM );

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMCYLINDER );
			m1.WriteCoord( m_pDriveEnt.pev.origin.x ); //origin
			m1.WriteCoord( m_pDriveEnt.pev.origin.y );
			m1.WriteCoord( m_pDriveEnt.pev.origin.z + 16 );
			m1.WriteCoord( m_pDriveEnt.pev.origin.x ); //axis and radius
			m1.WriteCoord( m_pDriveEnt.pev.origin.y );
			m1.WriteCoord( m_pDriveEnt.pev.origin.z + 16 + SLAM_RADIUS / 0.2); // reach damage radius over .3 seconds
			m1.WriteShort( m_iSlamShockwave );
			m1.WriteByte( 0 ); // startframe
			m1.WriteByte( 0 ); // framerate
			m1.WriteByte( 2 ); // life
			m1.WriteByte( int(32 * m_flAirtimeMultiplier) );  // width
			m1.WriteByte( 0 );   // noise
			m1.WriteByte( 188 );   // r, g, b
			m1.WriteByte( 220 );   // r, g, b
			m1.WriteByte( 255 );   // r, g, b
			m1.WriteByte( 255 ); // brightness
			m1.WriteByte( 0 );		// speed
		m1.End();

		NetworkMessage m2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m2.WriteByte( TE_BEAMCYLINDER );
			m2.WriteCoord( m_pDriveEnt.pev.origin.x ); //origin
			m2.WriteCoord( m_pDriveEnt.pev.origin.y );
			m2.WriteCoord( m_pDriveEnt.pev.origin.z + 16 );
			m2.WriteCoord( m_pDriveEnt.pev.origin.x ); //axis and radius
			m2.WriteCoord( m_pDriveEnt.pev.origin.y );
			m2.WriteCoord( m_pDriveEnt.pev.origin.z + 16 + ( SLAM_RADIUS / 2 ) / 0.2); // reach damage radius over .3 seconds
			m2.WriteShort( m_iSlamShockwave );
			m2.WriteByte( 0 ); // startframe
			m2.WriteByte( 0 ); // framerate
			m2.WriteByte( 2 ); // life
			m2.WriteByte( int(16 * m_flAirtimeMultiplier) );  // width
			m2.WriteByte( 0 );   // noise
			m2.WriteByte( 188 );   // r, g, b
			m2.WriteByte( 220 );   // r, g, b
			m2.WriteByte( 255 );   // r, g, b
			m2.WriteByte( 255 ); // brightness
			m2.WriteByte( 0 );		// speed
		m2.End();

		//Vector vecOrigin;
		//m_pDriveEnt.GetAttachment( 0, vecOrigin, void );
		T_SlamRadiusDamage( m_pDriveEnt.pev.origin, SLAM_DAMAGE, SLAM_RADIUS );
	}

	void T_SlamRadiusDamage( Vector vecOrigin, float flDamage, float flRadius )
	{
		CBaseEntity@ pEntity = null;
		Vector vecPoint;
		Vector vecDir;

		while( (@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, m_pDriveEnt.pev.origin, flRadius, "*", "classname" ) ) !is null )
		{
			if( pEntity.edict() is m_pPlayer.edict() or pEntity.edict() is m_pDriveEnt.edict() )
				continue;

			if( pEntity.pev.takedamage == DAMAGE_NO )
				continue;

			if( m_pPlayer.IRelationship(pEntity) <= R_NO )
				continue;

			vecDir = (pEntity.pev.origin - vecOrigin).Normalize();

			g_WeaponFuncs.ClearMultiDamage();
			pEntity.TraceAttack( m_pPlayer.pev, SLAM_DAMAGE, vecDir, g_Utility.GetGlobalTrace(), (DMG_GENERIC|DMG_LAUNCH) );
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			pEntity.pev.velocity.z = Math.max( 270.0, pEntity.pev.velocity.z );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2berserker", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2BERSERKER );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2berserker@ pDriveEnt = cast<cnpc_q2berserker@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2berserker_rend_" + m_pPlayer.entindex();
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

class cnpc_q2berserker : CBaseDriveEntityQ2
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
		else if( GetAnim(ANIM_SPIKE) or GetAnim(ANIM_CLUB) )
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

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		CNPC::Q2::ThrowGib( EHandle(self), 2, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_GEAR, pev.dmg, -1, BREAK_METAL );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HAMMER, pev.dmg, 10, BREAK_CONCRETE );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_THIGH, pev.dmg, Math.RandomLong(0, 1) == 0 ? 11 : 15, BREAK_FLESH );
		CNPC::Q2::ThrowGib( EHandle(self), 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( pev.sequence )
		{
			case ANIM_DEATH1:
			{
				if( GetFrame(13, 4) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DEATH2:
			{
				if( GetFrame(8, 4) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

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

final class info_cnpc_q2berserker : CNPCSpawnEntity
{
	info_cnpc_q2berserker()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2berserker::info_cnpc_q2berserker", "info_cnpc_q2berserker" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2berserker::cnpc_q2berserker", "cnpc_q2berserker" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2berserker::weapon_q2berserker", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "", "zerkammo" );

	g_Game.PrecacheOther( "info_cnpc_q2berserker" );
	g_Game.PrecacheOther( "cnpc_q2berserker" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2berserker END

/* FIXME
*/

/* TODO
	Multiply damage and radius of the jumping attack based on distance ??
	run_attack1
*/
