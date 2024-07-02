namespace cnpc_gonome
{

bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_gonome";
const string CNPC_MODEL				= "models/gonome.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 200.0;
const float CNPC_VIEWOFS_FPV		= 48.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 48.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the gonome itself
const float CNPC_MODEL_OFFSET	= 32.0; //sometimes the model floats above the ground
const float CNPC_IDLESOUND			= 10.0; //how often to check for an idlesound
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players

const float SPEED_WALK					= (76.553696 * CNPC::flModelToGameSpeedModifier) * 0.3; //
const float SPEED_RUN					= (184.080353 * CNPC::flModelToGameSpeedModifier); //0.8
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 2.0;
const float CD_SECONDARY				= 1.8;
const float MELEE_RANGE_SLASH	= 70.0;
const float MELEE_RANGE_BITE		= 48.0;
const float MELEE_DAMAGE_SLASH	= 30.0;
const float MELEE_DAMAGE_BITE	= 15.0;

const float CD_RANGE						= 2.0;
const float RANGE_DAMAGE				= 15.0;
const float RANGE_VELOCITY			= 900.0;

const float FEED_RANGE					= 80.0; //between the player's view and forward
const float FEED_RADIUS					= 40.0; //from the point the player is looking at
const float FEED_RATE						= 0.9; //how often health is added while feeding
const float FEED_AMOUNT				= 5.0;

const array<string> pIdleSounds = 
{
	"gonome/gonome_idle1.wav",
	"gonome/gonome_idle2.wav",
	"gonome/gonome_idle3.wav"
};

const array<string> pPainSounds = 
{
	"gonome/gonome_pain1.wav",
	"gonome/gonome_pain2.wav",
	"gonome/gonome_pain3.wav",
	"gonome/gonome_pain4.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav",
	"bullchicken/bc_acid1.wav",
	"bullchicken/bc_spithit1.wav",
	"bullchicken/bc_spithit2.wav",
	"gonome/gonome_jumpattack.wav",
	"gonome/gonome_melee1.wav",
	"gonome/gonome_melee2.wav",
	"gonome/gonome_run.wav",
	"gonome/gonome_eat.wav",
	"bullchicken/bc_bite1.wav",
	"bullchicken/bc_bite2.wav",
	"bullchicken/bc_bite3.wav",
	"gonome/gonome_death2.wav",
	"gonome/gonome_death3.wav",
	"gonome/gonome_death4.wav"
};

enum sound_e
{
	SND_HIT1 = 1,
	SND_HIT2,
	SND_HIT3,
	SND_MISS1,
	SND_MISS2,
	SND_ACID,
	SND_ACID_HIT1,
	SND_ACID_HIT2,
	SND_JUMP,
	SND_MELEE1,
	SND_MELEE2,
	SND_RUN,
	SND_EAT,
	SND_FEED1,
	SND_FEED2,
	SND_FEED3,
	SND_DIE2,
	SND_DIE3,
	SND_DIE4
};

enum anim_e
{
	ANIM_WALK = 0,
	ANIM_RUN1,
	ANIM_RUN2,
	ANIM_IDLE = 4,
	ANIM_FEED_START,
	ANIM_FEED_LOOP,
	ANIM_MELEE1,
	ANIM_MELEE2,
	ANIM_RANGE,
	ANIM_DEATH1 = 11,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_DEATH5
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_RANGE,
	STATE_MELEE,
	STATE_FEED,
	STATE_FEED_END
};

class weapon_gonome : CBaseDriveWeapon
{
	private float m_flNextFeed;

	private uint m_uiSwing;

	private float m_flNextThrow;
	private uint m_uiThrowStage;

	protected EHandle m_hGonomeGuts;
	protected CBaseEntity@ m_pGonomeGuts
	{
		get const { return m_hGonomeGuts.GetEntity(); }
		set { m_hGonomeGuts = EHandle(@value); }
	}

	protected EHandle m_hFeedTarget;
	protected CBaseEntity@ m_pFeedTarget
	{
		get const { return m_hFeedTarget.GetEntity(); }
		set { m_hFeedTarget = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_flNextIdleSound = g_Engine.time + CNPC_IDLESOUND;
		m_flNextFeed = 0.0;
		m_uiSwing = 0;
		m_flNextThrow = 0.0;
		m_uiThrowStage = 0;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pIdleSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pIdleSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_gonome.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_gonome.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_gonome_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::GONOME_SLOT - 1;
		info.iPosition		= CNPC::GONOME_POSITION - 1;
		info.iFlags 			= 0;
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

		if( m_pGonomeGuts !is null ) g_EntityFuncs.Remove( m_pGonomeGuts );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState == STATE_RANGE or m_iState == STATE_FEED or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_flNextIdleSound = g_Engine.time + CNPC_IDLESOUND;
			m_uiSwing = 0;

			//m_pPlayer.SetMaxSpeedOverride( 0 );
			m_pDriveEnt.pev.sequence = ANIM_MELEE1;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			//Doesn't work :[
			if( m_iState == STATE_RUN or m_iState == STATE_WALK )
			{
				m_pDriveEnt.pev.gaitsequence = ANIM_RUN2;
				m_pDriveEnt.ResetGaitSequenceInfo();
			}

			m_iState = STATE_MELEE;

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_MELEE1], VOL_NORM, ATTN_NORM );

			SetThink( ThinkFunction(this.MeleeAttackThink1) );
			pev.nextthink = g_Engine.time;
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState == STATE_RANGE or m_iState == STATE_FEED or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_flNextIdleSound = g_Engine.time + CNPC_IDLESOUND;
			m_iState = STATE_MELEE;
			m_uiSwing = 0;

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_pDriveEnt.pev.sequence = ANIM_MELEE2;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_MELEE2], VOL_NORM, ATTN_NORM );

			SetThink( ThinkFunction(this.MeleeAttackThink2) );
			pev.nextthink = g_Engine.time;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_SECONDARY;
	}

	//Right and left slash
	void MeleeAttackThink1()
	{
		if( m_pDriveEnt is null or m_pPlayer is null or !m_pPlayer.IsConnected() or !m_pPlayer.IsAlive() ) { SetThink(null); return; }
		if( m_iState != STATE_MELEE or m_pDriveEnt.pev.sequence != ANIM_MELEE1 or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) { SetThink(null); return; }

		switch( GetFrame(61) )
		{
			case 19: { if( m_uiSwing == 0 ) { Slash(); m_uiSwing++; } break; }
			case 35: { if( m_uiSwing == 1 ) { Slash(); m_uiSwing++; } break; }
		}

		if( m_uiSwing >= 2 ) { SetThink(null); return; }

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Slash()
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE_SLASH, MELEE_DAMAGE_SLASH, DMG_SLASH );
		if( pHurt !is null )
		{
			if( (pHurt.pev.flags & FL_MONSTER) != 0 or ((pHurt.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
			{
				pHurt.pev.punchangle.z = (m_uiSwing == 0) ? -9 : 9;
				pHurt.pev.punchangle.x = 5;
				pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * 25;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MISS1, SND_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
	}

	//Bite and thrash
	void MeleeAttackThink2()
	{
		if( m_pDriveEnt is null or m_pPlayer is null or !m_pPlayer.IsConnected() or !m_pPlayer.IsAlive() ) { SetThink(null); return; }
		if( m_iState != STATE_MELEE or m_pDriveEnt.pev.sequence != ANIM_MELEE2 or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) { SetThink(null); return; }

		switch( GetFrame(82) )
		{
			case 31: { if( m_uiSwing == 0 ) { Bite(); m_uiSwing++; } break; }
			case 41: { if( m_uiSwing == 1 ) { Bite(); m_uiSwing++; } break; }
			case 51: { if( m_uiSwing == 2 ) { Bite(); m_uiSwing++; } break; }
			case 59: { if( m_uiSwing == 3 ) { Bite(); m_uiSwing++; } break; }
		}

		if( m_uiSwing >= 4 ) { SetThink(null); return; }

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Bite()
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE_BITE, MELEE_DAMAGE_SLASH, DMG_SLASH, false );
		if( pHurt !is null )
		{
			if( (pHurt.pev.flags & FL_MONSTER) != 0 or ((pHurt.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 9;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 25;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MISS1, SND_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
	}

	void TertiaryAttack()
	{
		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			DoFirstPersonView();
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			cnpc_gonome@ pDriveEnt = cast<cnpc_gonome@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}

		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
	}

	void Reload() //necessary to prevent the reload-key from interfering?
	{
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.pev.friction = 2; //no sliding!

			if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and (m_iState < STATE_RANGE or (m_iState == STATE_MELEE and m_pDriveEnt.m_fSequenceFinished)) )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				DoMovementAnimation();
			}

			DoIdleAnimation();
			DoIdleSound();
			CheckThrowInput();
			CheckThrowGuts();
			CheckForFeeding();
		}
	}

	void DoMovementAnimation()
	{
		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				m_pDriveEnt.pev.sequence = ANIM_WALK;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
				m_pDriveEnt.pev.framerate = 1.7; //the walking animation is too slow
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN1 )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_pDriveEnt.pev.sequence = ANIM_RUN1;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState == STATE_MELEE and (m_pDriveEnt.pev.sequence == ANIM_MELEE1 or m_pDriveEnt.pev.sequence == ANIM_MELEE2) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_RANGE and m_pDriveEnt.pev.sequence == ANIM_RANGE and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_FEED ) return;
		if( m_iState == STATE_FEED_END and m_pDriveEnt.pev.sequence == ANIM_FEED_START and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;
				m_pDriveEnt.pev.sequence = ANIM_IDLE;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
	}

	void IdleSound()
	{
		if( m_pDriveEnt is null ) return;

		int pitch = 100 + Math.RandomLong( -5, 5 );
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, pIdleSounds[Math.RandomLong(0,(pIdleSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, pitch );

		m_flNextIdleSound = g_Engine.time + CNPC_IDLESOUND;
	}

	void CheckThrowInput()
	{
		if( m_iState == STATE_MELEE or m_iState == STATE_FEED or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_flNextThrow > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 )
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iState = STATE_RANGE;
			m_uiThrowStage = 0;

			m_pDriveEnt.pev.sequence = ANIM_RANGE;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			m_flNextThrow = g_Engine.time + CD_RANGE;
		}
	}

	void CheckThrowGuts()
	{
		if( m_iState != STATE_RANGE or m_pDriveEnt.pev.sequence != ANIM_RANGE or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		switch( GetFrame(85) )
		{
			case 40: { if( m_uiThrowStage == 0 ) { PullGuts(); m_uiThrowStage++; } break; }
			case 62: { if( m_uiThrowStage == 1 ) { ThrowGuts(); m_uiThrowStage++; } break; }
		}
	}

	void PullGuts()
	{
		Vector vecGutsPos;
		m_pDriveEnt.GetAttachment( 0, vecGutsPos, void );

		if( m_pGonomeGuts is null )
			@m_pGonomeGuts = g_EntityFuncs.Create( "gonomespit", vecGutsPos, g_vecZero, false, m_pPlayer.edict() );

		//Attach to hand for throwing
		m_pGonomeGuts.pev.skin = m_pDriveEnt.entindex(); //which entity's attachments to look for
		m_pGonomeGuts.pev.body = 1; //attachment number, starting at 1
		@m_pGonomeGuts.pev.aiment = m_pDriveEnt.edict();
		m_pGonomeGuts.pev.movetype = MOVETYPE_FOLLOW;

		Math.MakeVectors( m_pPlayer.pev.angles );
		Vector direction = g_Engine.v_forward;

		direction = direction + Vector( Math.RandomFloat(-0.05, 0.05), Math.RandomFloat(-0.05, 0.05), Math.RandomFloat(-0.05, 0) );

		g_Utility.BloodDrips( vecGutsPos, direction, BLOOD_COLOR_RED, 35 );
	}

	void ThrowGuts()
	{
		Vector vecGutsPos;
		m_pDriveEnt.GetAttachment( 0, vecGutsPos, void );

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		if( m_pGonomeGuts is null )
			@m_pGonomeGuts = g_EntityFuncs.Create( "gonomespit", vecGutsPos, g_vecZero, false, m_pPlayer.edict() );

		Vector direction = g_Engine.v_forward + Vector( Math.RandomFloat(-0.05, 0.05), Math.RandomFloat(-0.05, 0.05), Math.RandomFloat(-0.05, 0) );
		g_Utility.BloodDrips( vecGutsPos, direction, BLOOD_COLOR_RED, 35 );

		//Detach from owner
		m_pGonomeGuts.pev.skin = 0;
		m_pGonomeGuts.pev.body = 0;
		@m_pGonomeGuts.pev.aiment = null;
		m_pGonomeGuts.pev.movetype = MOVETYPE_FLY;

		g_EntityFuncs.SetOrigin( m_pGonomeGuts, vecGutsPos );
		m_pGonomeGuts.pev.velocity = g_Engine.v_forward * RANGE_VELOCITY;
	}

	void CheckForFeeding()
	{
		float flFeedTime;

		if( m_iState == STATE_RANGE or m_iState == STATE_MELEE or m_iState == STATE_FEED_END or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_flNextFeed > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_USE) != 0 )
		{
			if( m_iState != STATE_FEED )
			{
				if( !CanFeed() ) return;

				//g_Game.AlertMessage( at_notice, "Start feeding!\n" );
				m_iState = STATE_FEED;

				m_pPlayer.SetMaxSpeedOverride( 0 );
				m_pDriveEnt.pev.sequence = ANIM_FEED_START;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else if( m_iState == STATE_FEED and GetFrame(121) > 20/*m_pDriveEnt.m_fSequenceFinished*/ )
			{
				//g_Game.AlertMessage( at_notice, "Feeding!\n" );

				if( m_pDriveEnt.pev.sequence != ANIM_FEED_LOOP )
				{
					m_pDriveEnt.pev.sequence = ANIM_FEED_LOOP;
					m_pDriveEnt.pev.frame = 0;
					m_pDriveEnt.ResetSequenceInfo();
				}

				if( m_pFeedTarget !is null and !m_pFeedTarget.IsAlive() )
				{
					int iRandomSound = Math.RandomLong(0, 2);

					switch( iRandomSound )
					{
						case 0: { g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_FEED1], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) ); break; }

						case 1: { g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_FEED2], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) ); break; }

						case 2: { g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_FEED3], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) ); break; }
					}

					if( m_pPlayer.pev.health < m_pPlayer.pev.max_health )
						m_pPlayer.pev.health += FEED_AMOUNT;

					TraceResult tr;
					g_Utility.TraceLine( m_pFeedTarget.pev.origin, m_pFeedTarget.pev.origin, ignore_monsters, m_pPlayer.edict(), tr );

					m_pFeedTarget.TraceBleed( 0.1, m_pFeedTarget.pev.origin + Vector(0, 0, 2), tr, DMG_CLUB );
					m_pFeedTarget.TakeHealth( 0.1, DMG_CLUB );
					m_pFeedTarget.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, 0.5, DMG_CLUB );
				}
				else
					StopFeeding();

				flFeedTime = FEED_RATE;
			}
		}
		else if( (m_pPlayer.pev.button & IN_USE) == 0 and m_iState == STATE_FEED )
		{
			StopFeeding();

			flFeedTime = 0.1;
		}

		m_flNextFeed = g_Engine.time + flFeedTime;
	}

	bool CanFeed()
	{
		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecEnd = vecSrc + g_Engine.v_forward * FEED_RANGE;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		CBaseEntity@ pEntity = null;
		array <CBaseEntity@> arrTargets(69);
		int iNum = g_EntityFuncs.MonstersInSphere( arrTargets, tr.vecEndPos, FEED_RADIUS ); 

		if( iNum == 0 ) return false;

		for( uint i = 0; i < arrTargets.length(); i++ )
		{
			@pEntity = arrTargets[i];

			if( pEntity !is null and pEntity.Classify() != CLASS_NONE and pEntity.Classify() != CLASS_MACHINE and pEntity.BloodColor() != DONT_BLEED and !pEntity.IsAlive() )
			{
				bool bBreak = false;

				for( uint j = 0; j < CNPC::arrsEdibles.length(); j++ )
				{
					if( pEntity.pev.classname == CNPC::arrsEdibles[j] )
					{
						@m_pFeedTarget = arrTargets[i];
						bBreak = true;
						break;
					}
				}

				if( bBreak ) break;
			}
		}

		return (m_pFeedTarget !is null);
	}

	void StopFeeding()
	{
		//g_Game.AlertMessage( at_notice, "Stop feeding!\n" );

		@m_pFeedTarget = null;
		m_iState = STATE_FEED_END;

		if( m_pDriveEnt.pev.sequence != ANIM_FEED_START )
		{
			m_pDriveEnt.pev.sequence = ANIM_FEED_START;
			m_pDriveEnt.ResetSequenceInfo();
			m_pDriveEnt.pev.frame = 100;
			m_pDriveEnt.pev.framerate = -2.0;
		}
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		vecOrigin.z -= CNPC_MODEL_OFFSET;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_gonome", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_GONOME );

		m_flNextFeed = g_Engine.time + 1.0;
	}

	void DoFirstPersonView()
	{
		cnpc_gonome@ pDriveEnt = cast<cnpc_gonome@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_gonome_pid_" + m_pPlayer.entindex();
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
		m_pPlayer.pev.fuser4 = 0; //enable jump
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_gonome : ScriptBaseAnimating//ScriptBaseMonsterEntity
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 72) );
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
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN1 or pev.sequence == ANIM_WALK) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		int iAnim = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH5 );
		pev.sequence = iAnim;
		pev.frame = 0;
		self.ResetSequenceInfo();

		//TODO setup some more sounds
		switch( iAnim )
		{
			case ANIM_DEATH1: { g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DIE2], VOL_NORM, ATTN_NORM ); break; }
			case ANIM_DEATH2: { g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DIE3], VOL_NORM, ATTN_NORM ); break; }
			case ANIM_DEATH3: { g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DIE4], VOL_NORM, ATTN_NORM ); break; }
			case ANIM_DEATH4: { g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DIE2], VOL_NORM, ATTN_NORM ); break; }
			case ANIM_DEATH5: { g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DIE3], VOL_NORM, ATTN_NORM ); break; }
		}

		SetThink( ThinkFunction(this.SUB_StartFadeOut) );
		pev.nextthink = g_Engine.time;
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

final class info_cnpc_gonome : CNPCSpawnEntity
{
	info_cnpc_gonome()
	{
		sWeaponName = CNPC_WEAPONNAME;
		sModel = CNPC_MODEL;
		iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		vecSizeMin = CNPC_SIZEMIN;
		vecSizeMax = CNPC_SIZEMAX;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_gonome::info_cnpc_gonome", "info_cnpc_gonome" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_gonome::cnpc_gonome", "cnpc_gonome" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_gonome::weapon_gonome", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "cnpc_gonome" );
	g_Game.PrecacheOther( "info_cnpc_gonome" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_gonome END

/* FIXME
*/

/* TODO
*/