namespace cnpc_scientist
{

const bool AAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHH = false; //AAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHH
const bool USE_CUSTOM_SENTENCES = false;

bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME		= "weapon_scientist";
const string CNPC_MODEL					= "models/scientist.mdl";
const Vector CNPC_SIZEMIN				= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX				= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 50.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the scientist itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?
const float CNPC_HEADRESETTIME	= 2.0;

const float SPEED_WALK					= -1; //model * CNPC::flModelToGameSpeedModifier;
const float SPEED_RUN					= -1; //model * CNPC::flModelToGameSpeedModifier;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 1.0; //use syringe
const int AMMO_MAX						= 100;
const int AMMO_USE						= 25;
const float HEAL_RANGE					= 25.0;
const float HEAL_AMOUNT				= 25.0;
const float AMMO_REGEN_RATE		= 0.1; //+1 per AMMO_REGEN_RATE seconds

const float CD_SECONDARY				= 1.5; //AAAAAAAAAAAHHHHHHHHH

const array<string> pPainSounds = 
{
	"scientist/sci_pain1.wav",
	"scientist/sci_pain2.wav",
	"scientist/sci_pain3.wav",
	"scientist/sci_pain4.wav",
	"scientist/sci_pain5.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"scientist/scream01.wav",
	"scientist/scream02.wav",
	"scientist/scream04.wav",
	"scientist/scream05.wav",
	"scientist/scream06.wav",
	"scientist/scream08.wav",
	"scientist/scream20.wav",
	"scientist/scream22.wav",
	"scientist/scream23.wav",
	"scientist/scream24.wav",
	"scientist/scream25.wav"
};

enum sound_e
{
	SND_SCREAM1 = 1,
	SND_SCREAM10 = 10
};

enum anim_e
{
	ANIM_WALK = 0,
	ANIM_WALK_SCARED,
	ANIM_RUN,
	ANIM_RUN_SCARED,
	ANIM_IDLE = 13,
	ANIM_SYRINGE_ON = 28,
	ANIM_SYRINGE_OFF,
	ANIM_SYRINGE_USE,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_DEATH6,
	ANIM_BACKFLIP = 112
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_SYRINGE_TOGGLE,
	STATE_SYRINGE_USE
};

class weapon_scientist : CBaseDriveWeapon
{
	int m_iVoicePitch;
	EHandle m_hTalkTarget;
	bool m_bAnswerQuestion;
	private float m_flResetHead;
	private bool m_bHasGreetedPlayer;

	private bool m_bSyringeOut;
	private bool m_bHasHealed;
	private float m_flNextAmmoRegen;

	void Spawn()
	{
		Precache();

		self.m_iDefaultAmmo = AMMO_MAX;

		m_iState = STATE_IDLE;
		m_bAnswerQuestion = false;
		m_flResetHead = 0.0;
		m_bSyringeOut = false;
		m_bHasHealed = false;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_scientist.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_scientist.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_scientist_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= AMMO_MAX;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::SCIENTIST_SLOT - 1;
		info.iPosition		= CNPC::SCIENTIST_POSITION - 1;
		info.iFlags 			= 0;
		info.iWeight			= 0; //-1 ?? 100 ??

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

		m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, AMMO_MAX);

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

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_bSyringeOut and m_iState < STATE_SYRINGE_TOGGLE )
			{
				if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < AMMO_USE ) return;

				m_iState = STATE_SYRINGE_USE;
				m_pPlayer.SetMaxSpeedOverride( 0 );
				SetAnim( ANIM_SYRINGE_USE );
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			//g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "CNPC_SC_SCREAM", VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SCREAM1, SND_SCREAM10)], VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
		}

		self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
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
			cnpc_scientist@ pDriveEnt = cast<cnpc_scientist@>(CastToScriptClass(m_pDriveEnt));
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

			ResetHead();
			CheckSyringeInput();
			ToggleSyringe();
			DoHealing();
			DoAmmoRegen();
			//TurnHead();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState >= STATE_SYRINGE_TOGGLE ) return;

		m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			int iAnim = ANIM_WALK;
			if( m_pPlayer.pev.button & IN_ATTACK2 != 0 ) iAnim = ANIM_WALK_SCARED;

			if( m_pDriveEnt.pev.sequence != iAnim )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				SetAnim( iAnim );
			}
		}
		else
		{
			int iAnim = ANIM_RUN;
			if( m_pPlayer.pev.button & IN_ATTACK2 != 0 ) iAnim = ANIM_RUN_SCARED;

			if( m_pDriveEnt.pev.sequence != iAnim )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				SetAnim( iAnim );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState == STATE_SYRINGE_TOGGLE and (m_pDriveEnt.pev.sequence == ANIM_SYRINGE_ON or m_pDriveEnt.pev.sequence == ANIM_SYRINGE_OFF) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_SYRINGE_USE and m_pDriveEnt.pev.sequence == ANIM_SYRINGE_USE and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;
				SetAnim( ANIM_IDLE );
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void IdleSound()
	{
		// if someone else is talking, don't speak
		if( CNPC::g_flTalkWaitTime > g_Engine.time ) return;

		string sSentence;

		// set global min delay for next conversation
		if( !AAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHH )
			CNPC::g_flTalkWaitTime = g_Engine.time + Math.RandomFloat(4.8, 5.2);
		else
			CNPC::g_flTalkWaitTime = g_Engine.time + Math.RandomFloat(0.8, 1.2);

		if( m_bAnswerQuestion )
		{
			if( m_hTalkTarget.IsValid() )
			{
				IdleHeadTurn( m_hTalkTarget.GetEntity().pev.origin );
				m_hTalkTarget = null;
			}

			if( AAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHH )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SCREAM1, SND_SCREAM10)], VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
				CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat(0.8, 1.2);
			}
			else
			{
				if( USE_CUSTOM_SENTENCES and Math.RandomLong(1, 10) > 8 )
					sSentence = "CNPC_SC_ANSWER";
				else
					sSentence = "SC_ANSWER";

				g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), sSentence, VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );

				CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat(4.8, 5.2);
			}

			m_bAnswerQuestion = false;

			return;
		}

		// try to talk to any standing or sitting scientists nearby
		CBaseEntity@ pentFriend = FindNearestFriend();

		if( pentFriend !is null and Math.RandomLong(0, 1) == 1 )
		{
			if( !pentFriend.pev.FlagBitSet(FL_CLIENT) )
			{
				CBaseEntity@ cbeFriendController = GetFriendController(pentFriend);
				if( cbeFriendController !is null )
				{
					weapon_scientist@ pFriendController = cast<weapon_scientist@>(CastToScriptClass(cbeFriendController));

					if( pFriendController !is null )
					{
						pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
						pFriendController.m_bAnswerQuestion = true;
					}
				}
			}

			if( AAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHH )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SCREAM1, SND_SCREAM10)], VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
				CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat(0.8, 1.2);
			}
			else
			{
				if( pentFriend.pev.FlagBitSet(FL_CLIENT) and !m_bHasGreetedPlayer )
				{
					if( USE_CUSTOM_SENTENCES and Math.RandomLong(1, 10) > 8 )
						sSentence = "CNPC_SC_HELLO";
					else
						sSentence = "SC_HELLO";

					m_bHasGreetedPlayer = true;
				}
				else				
				{
					if( USE_CUSTOM_SENTENCES and Math.RandomLong(1, 10) > 8 )
						sSentence = "CNPC_SC_QUESTION";
					else
						sSentence = "SC_QUESTION"; //SC_PQUEST
				}

				g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), sSentence, VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
				CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat(4.8, 5.2);
			}

			IdleHeadTurn( pentFriend.pev.origin );

			return;
		}

		// otherwise, play an idle statement
		if( Math.RandomLong(0, 1) == 1 )
		{
			if( AAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHH )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SCREAM1, SND_SCREAM10)], VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
				CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat(0.8, 1.2);
			}
			else
			{
				if( USE_CUSTOM_SENTENCES and Math.RandomLong(1, 10) > 8 )
					sSentence = "CNPC_SC_IDLE";
				else
					sSentence = "SC_IDLE"; //SC_PIDLE

				g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), sSentence, VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
				CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat(4.8, 5.2);
			}

			return;
		}

		// never spoke
		CNPC::g_flTalkWaitTime = 0.0;

		/*OLD IdleSound
		if( Math.RandomLong(0, 1) == 1 )
			g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "SC_IDLE", VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) ); //SC_PIDLE

		m_flNextIdleSound = g_Engine.time + CNPC_IDLESOUND;*/
	}
/*
int CTalkMonster :: FIdleSpeak ( void )
{ 
	// try to start a conversation, or make statement
	int pitch;
	const char *szIdleGroup;
	const char *szQuestionGroup;
	float duration;

	if (!FOkToSpeak())
		return FALSE;

	// set idle groups based on pre/post disaster
	if (FBitSet(pev->spawnflags, SF_MONSTER_PREDISASTER))
	{
		szIdleGroup = m_szGrp[TLK_PIDLE];
		szQuestionGroup = m_szGrp[TLK_PQUESTION];
		// set global min delay for next conversation
		duration = RANDOM_FLOAT(4.8, 5.2);
	}
	else
	{
		szIdleGroup = m_szGrp[TLK_IDLE];
		szQuestionGroup = m_szGrp[TLK_QUESTION];
		// set global min delay for next conversation
		duration = RANDOM_FLOAT(2.8, 3.2);

	}

	pitch = GetVoicePitch();
		
	// player using this entity is alive and wounded?
	CBaseEntity *pTarget = m_hTargetEnt;

	if ( pTarget != NULL )
	{
		if ( pTarget->IsPlayer() )
		{
			if ( pTarget->IsAlive() )
			{
				m_hTalkTarget = m_hTargetEnt;
				if (!FBitSet(m_bitsSaid, bit_saidDamageHeavy) && 
					(m_hTargetEnt->pev->health <= m_hTargetEnt->pev->max_health / 8))
				{
					//EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, m_szGrp[TLK_PLHURT3], 1.0, ATTN_IDLE, 0, pitch);
					PlaySentence( m_szGrp[TLK_PLHURT3], duration, VOL_NORM, ATTN_IDLE );
					SetBits(m_bitsSaid, bit_saidDamageHeavy);
					return TRUE;
				}
				else if (!FBitSet(m_bitsSaid, bit_saidDamageMedium) && 
					(m_hTargetEnt->pev->health <= m_hTargetEnt->pev->max_health / 4))
				{
					//EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, m_szGrp[TLK_PLHURT2], 1.0, ATTN_IDLE, 0, pitch);
					PlaySentence( m_szGrp[TLK_PLHURT2], duration, VOL_NORM, ATTN_IDLE );
					SetBits(m_bitsSaid, bit_saidDamageMedium);
					return TRUE;
				}
				else if (!FBitSet(m_bitsSaid, bit_saidDamageLight) &&
					(m_hTargetEnt->pev->health <= m_hTargetEnt->pev->max_health / 2))
				{
					//EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, m_szGrp[TLK_PLHURT1], 1.0, ATTN_IDLE, 0, pitch);
					PlaySentence( m_szGrp[TLK_PLHURT1], duration, VOL_NORM, ATTN_IDLE );
					SetBits(m_bitsSaid, bit_saidDamageLight);
					return TRUE;
				}
			}
			else
			{
				//!!!KELLY - here's a cool spot to have the talkmonster talk about the dead player if we want.
				// "Oh dear, Gordon Freeman is dead!" -Scientist
				// "Damn, I can't do this without you." -Barney
			}
		}
	}

	// if there is a friend nearby to speak to, play sentence, set friend's response time, return
	CBaseEntity *pFriend = FindNearestFriend(FALSE);

	if (pFriend && !(pFriend->IsMoving()) && (RANDOM_LONG(0,99) < 75))
	{
		PlaySentence( szQuestionGroup, duration, VOL_NORM, ATTN_IDLE );
		//SENTENCEG_PlayRndSz( ENT(pev), szQuestionGroup, 1.0, ATTN_IDLE, 0, pitch );

		// force friend to answer
		CTalkMonster *pTalkMonster = (CTalkMonster *)pFriend;
		m_hTalkTarget = pFriend;
		pTalkMonster->SetAnswerQuestion( this ); // UNDONE: This is EVIL!!!
		pTalkMonster->m_flStopTalkTime = m_flStopTalkTime;

		m_nSpeak++;
		return TRUE;
	}

	// otherwise, play an idle statement, try to face client when making a statement.
	if ( RANDOM_LONG(0,1) )
	{
		//SENTENCEG_PlayRndSz( ENT(pev), szIdleGroup, 1.0, ATTN_IDLE, 0, pitch );
		CBaseEntity *pFriend = FindNearestFriend(TRUE);

		if ( pFriend )
		{
			m_hTalkTarget = pFriend;
			PlaySentence( szIdleGroup, duration, VOL_NORM, ATTN_IDLE );
			m_nSpeak++;
			return TRUE;
		}
	}

	// didn't speak
	Talk( 0 );
	CTalkMonster::g_talkWaitTime = 0;
	return FALSE;
}
*/

	void ResetHead()
	{
		if( m_flResetHead <= 0.0 or m_flResetHead > g_Engine.time ) return;

		m_pDriveEnt.pev.set_controller( 0,  127 );
		m_flResetHead = 0.0;
	}

	/*void TurnHead()
	{
		if( m_iState > STATE_IDLE )
		{
			m_pDriveEnt.pev.set_controller( 0,  127 ); //look straight ahead
			return;
		}

		m_pDriveEnt.SetBoneController( 0, m_pPlayer.pev.angles.y - m_pDriveEnt.pev.angles.y );
	}*/

	void IdleHeadTurn( Vector vecFriend )
	{
		float yaw = Math.VecToYaw( vecFriend - m_pDriveEnt.pev.origin ) - m_pDriveEnt.pev.angles.y;

		if( yaw > 180 ) yaw -= 360;
		if( yaw < -180 ) yaw += 360;

		m_pDriveEnt.SetBoneController( 0, yaw );
	}

	void CheckSyringeInput()
	{
		if( m_iState > STATE_RUN ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 )
		{
			m_iState = STATE_SYRINGE_TOGGLE;

			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( m_bSyringeOut )
				SetAnim( ANIM_SYRINGE_OFF );
			else
				SetAnim( ANIM_SYRINGE_ON );
		}
	}

	void ToggleSyringe()
	{
		if( m_iState != STATE_SYRINGE_TOGGLE ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_SYRINGE_ON and m_pDriveEnt.pev.sequence != ANIM_SYRINGE_OFF ) return;

		if( m_pDriveEnt.pev.sequence == ANIM_SYRINGE_ON )
		{
			if( GetFrame(31) == 15 and !m_bSyringeOut )
			{
				int oldBody = m_pDriveEnt.pev.body;
				m_pDriveEnt.pev.body = (oldBody % 4) + 4 * 1; //NUM_SCIENTIST_HEADS

				m_bSyringeOut = true;
			}
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_SYRINGE_OFF )
		{
			if( GetFrame(31) == 15 and m_bSyringeOut )
			{
				int oldBody = m_pDriveEnt.pev.body;
				m_pDriveEnt.pev.body = (oldBody % 4) + 4 * 0; //NUM_SCIENTIST_HEADS

				m_bSyringeOut = false;
			}
		}
	}

	void DoHealing()
	{
		if( !m_bSyringeOut or m_iState != STATE_SYRINGE_USE or m_pDriveEnt.pev.sequence != ANIM_SYRINGE_USE ) return;

		if( GetFrame(31) == 22 and !m_bHasHealed )
		{
			if( CheckTraceHullHeal(HEAL_RANGE, HEAL_AMOUNT, DMG_MEDKITHEAL) !is null )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - AMMO_USE );
				m_bHasHealed = true;
			}
		}
		else if( GetFrame(31) > 27 and m_bHasHealed )
			m_bHasHealed = false;
	}

	void DoAmmoRegen()
	{
		if( !m_bSyringeOut and m_iState < STATE_SYRINGE_TOGGLE and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < AMMO_MAX )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) +1 );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_scientist", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		m_pDriveEnt.pev.set_controller( 0,  127 );

		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "body", "" + pev.body );
		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		cnpc_scientist@ pDriveEnt = cast<cnpc_scientist@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt !is null )
			m_iVoicePitch = pDriveEnt.m_iVoicePitch;

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_SCIENTIST );
	}

	void DoFirstPersonView()
	{
		cnpc_scientist@ pDriveEnt = cast<cnpc_scientist@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_scientist_rend_" + m_pPlayer.entindex();
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

class cnpc_scientist : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	int m_iVoicePitch;

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

		pev.skin = 0;

		// -1 chooses a random head
		if( pev.body == -1 )
			pev.body = Math.RandomLong(0, 3);

		// Luther is black, make his hands black
		if( pev.body == CNPC::HEAD_LUTHER )
			pev.skin = 1;

		switch( pev.body % 3 )
		{
			case CNPC::HEAD_EINSTEIN: m_iVoicePitch = 100; break;
			case CNPC::HEAD_LUTHER:	m_iVoicePitch = 95;  break;
			case CNPC::HEAD_SLICK:	m_iVoicePitch = 100;  break;
			case CNPC::HEAD_GLASSES:
			default:	m_iVoicePitch = 105; break;
		}

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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_RUN_SCARED or pev.sequence == ANIM_WALK or pev.sequence == ANIM_WALK_SCARED) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		//else
			//pev.angles.y = m_pOwner.pev.angles.y;

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
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong(ANIM_DEATH1, ANIM_DEATH6);
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0, pPainSounds.length()-1)], VOL_NORM, ATTN_NORM, 0, m_iVoicePitch + Math.RandomLong(0, 3) );

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

final class info_cnpc_scientist : CNPCSpawnEntity
{
	info_cnpc_scientist()
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
		pev.set_controller( 0,  127 );
		pev.skin = 0;

		m_iBody = pev.body;

		// -1 chooses a random head
		if( m_iBody == -1 )
			pev.body = Math.RandomLong(0, 3);

		// Luther is black, make his hands black
		if( pev.body == CNPC::HEAD_LUTHER )
			pev.skin = 1;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_scientist::info_cnpc_scientist", "info_cnpc_scientist" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_scientist::cnpc_scientist", "cnpc_scientist" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_scientist::weapon_scientist", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "sciheal" );

	g_Game.PrecacheOther( "info_cnpc_scientist" );
	g_Game.PrecacheOther( "cnpc_scientist" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_scientist END

/* FIXME
*/

/* TODO
	Proper Idle talking
*/