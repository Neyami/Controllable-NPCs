namespace cnpc_otis
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_otis";
const string CNPC_MODEL				= "models/otis.mdl";
const string MODEL_VIEW				= "models/v_desert_eagle.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 65.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the otis itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (54.303158 * CNPC::flModelToGameSpeedModifier) * 0.8;
const float SPEED_RUN					= (155.426682 * CNPC::flModelToGameSpeedModifier) * 0.8;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 0.5;
const float RANGE_DAMAGE			= 34; //sk_otis_bullet
const int AMMO_MAX						= 7;
const float RELOAD_TIME				= 1.0;

const float HEAL_AMOUNT				= 25;

const array<string> pPainSounds = 
{
	"barney/ba_pain1.wav",
	"barney/ba_pain2.wav",
	"barney/ba_pain3.wav"
};

const array<string> pDieSounds = 
{
	"barney/ba_die1.wav",
	"barney/ba_die2.wav",
	"barney/ba_die3.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"otis/ot_attack.wav",
	"hgrunt/gr_reload1.wav",
	"otis/candy.wav",
	"buttons/blip1.wav",
	"common/npc_step1.wav",
	"common/npc_step2.wav",
	"common/npc_step3.wav",
	"common/npc_step4.wav"
};

enum sound_e
{
	SND_SHOOT = 1,
	SND_RELOAD_DONE,
	SND_CANDY,
	SND_BUTTON,
	SND_STEP1,
	SND_STEP2,
	SND_STEP3,
	SND_STEP4
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK = 4,
	ANIM_RUN,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_DRAW,
	ANIM_HOLSTER,
	ANIM_RELOAD,
	ANIM_DEATH1 = 25,
	ANIM_DEATH6 = 30,
	ANIM_EAT = 52,
	ANIM_VENDING,
	ANIM_BUTTON = 58
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_GUN_TOGGLE,
	STATE_SHOOT,
	STATE_RELOAD,
	STATE_VENDING,
	STATE_EAT
};

class weapon_otis : CBaseDriveWeapon
{
	int m_iVoicePitch;
	EHandle m_hTalkTarget;
	bool m_bAnswerQuestion;
	private float m_flResetHead;

	private int m_iShell;
	private bool m_bGunDrawn;
	private bool m_bHasDonut;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_bAnswerQuestion = false;
		m_flResetHead = 0.0;

		self.m_iDefaultAmmo = AMMO_MAX;
		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_VIEW );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_otis.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_otis.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_otis_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::OTIS_SLOT - 1;
		info.iPosition			= CNPC::OTIS_POSITION - 1;
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

		m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, AMMO_MAX);

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
		}

		return self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), "", 9, "" );
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
			if( m_bGunDrawn and m_iState != STATE_GUN_TOGGLE and m_iState != STATE_RELOAD )
			{
				if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 ) return;

				m_iState = STATE_SHOOT;
				m_pPlayer.SetMaxSpeedOverride( 0 );
				SetAnim( ANIM_SHOOT2 );

				if( CNPC_FIRSTPERSON )
					self.SendWeaponAnim( 5 );

				Shoot();
			}
			else if( m_bHasDonut and m_iState <= STATE_RUN )
			{
				m_iState = STATE_EAT;
				m_pPlayer.SetMaxSpeedOverride( 0 );
				SetAnim( ANIM_EAT );
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt is null or m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		m_iState = STATE_GUN_TOGGLE;

		m_pPlayer.SetMaxSpeedOverride( 0 );

		if( m_bGunDrawn )
			SetAnim( ANIM_HOLSTER );
		else
		{
			m_bHasDonut = false;
			SetAnim( ANIM_DRAW );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
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
			self.SendWeaponAnim( 9 );
		}
		else
		{
			cnpc_otis@ pDriveEnt = cast<cnpc_otis@>(CastToScriptClass(m_pDriveEnt));
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
			ToggleGunAE();
			CheckReloadInput();
			ReloadAE();
			FootstepAE();
			CheckForVendingMachine();
			VendingMachineAE();
			EatingAE();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or (m_iState > STATE_RUN and m_iState != STATE_VENDING) ) return;

		m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				SetAnim( ANIM_WALK );
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_iState == STATE_GUN_TOGGLE and (m_pDriveEnt.pev.sequence == ANIM_DRAW or m_pDriveEnt.pev.sequence == ANIM_HOLSTER) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_SHOOT and (m_pPlayer.pev.button & IN_ATTACK) != 0 ) return;
		if( m_iState == STATE_RELOAD and m_pDriveEnt.pev.sequence == ANIM_RELOAD and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_VENDING and (m_pDriveEnt.pev.sequence == ANIM_HOLSTER or m_pDriveEnt.pev.sequence >= ANIM_EAT) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_EAT and m_pDriveEnt.pev.sequence == ANIM_EAT and !m_pDriveEnt.m_fSequenceFinished ) return;

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
		if( CNPC::g_flTalkWaitTime > g_Engine.time ) return;

		CNPC::g_flTalkWaitTime = m_flResetHead = g_Engine.time + Math.RandomFloat( 2.8, 3.2 );

		if( m_bAnswerQuestion )
		{
			if( m_hTalkTarget.IsValid() )
			{
				IdleHeadTurn( m_hTalkTarget.GetEntity().pev.origin );
				m_hTalkTarget = null;
			}

			g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "OT_ANSWER", VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );

			m_bAnswerQuestion = false;

			return;
		}

		// if there is a friend nearby to speak to, play sentence, set friend's response time, return
		CBaseEntity@ pFriend = FindNearestFriend(false);

		if( pFriend !is null and !pFriend.IsMoving() and Math.RandomLong(0, 99) < 75 )
		{
			g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "OT_QUESTION", VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );

			// force friend to answer
			CBaseEntity@ cbeFriendController = GetFriendController(pFriend);
			if( cbeFriendController !is null )
			{
				if( cbeFriendController.GetClassname() == "weapon_scientist" )
				{
					cnpc_scientist::weapon_scientist@ pFriendController = cast<cnpc_scientist::weapon_scientist@>(CastToScriptClass(cbeFriendController));
					pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
					pFriendController.m_bAnswerQuestion = true;
				}
				/*else if( cbeFriendController.GetClassname() == "weapon_barney" )
				{
					cnpc_barney::weapon_barney@ pFriendController = cast<cnpc_barney::weapon_barney@>(CastToScriptClass(cbeFriendController));
					pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
					pFriendController.m_bAnswerQuestion = true;
				}*/
				else if( cbeFriendController.GetClassname() == "weapon_otis" )
				{
					cnpc_otis::weapon_otis@ pFriendController = cast<cnpc_otis::weapon_otis@>(CastToScriptClass(cbeFriendController));
					pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
					pFriendController.m_bAnswerQuestion = true;
				}

				IdleHeadTurn( pFriend.pev.origin );
			}

			return;
		}

		// otherwise, play an idle statement, try to face client when making a statement.
		if( Math.RandomLong(0, 1) == 1 )
		{
			CBaseEntity@ pFriend2 = FindNearestFriend();

			if( pFriend2 !is null )
			{
				CBaseEntity@ cbeFriendController = GetFriendController(pFriend2);
				if( cbeFriendController !is null )
				{
					if( cbeFriendController.GetClassname() == "weapon_scientist" )
					{
						cnpc_scientist::weapon_scientist@ pFriendController = cast<cnpc_scientist::weapon_scientist@>(CastToScriptClass(cbeFriendController));
						pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
					}
					/*else if( cbeFriendController.GetClassname() == "weapon_barney" )
					{
						cnpc_barney::weapon_barney@ pFriendController = cast<cnpc_barney::weapon_barney@>(CastToScriptClass(cbeFriendController));
						pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
					}*/
					else if( cbeFriendController.GetClassname() == "weapon_otis" )
					{
						cnpc_otis::weapon_otis@ pFriendController = cast<cnpc_otis::weapon_otis@>(CastToScriptClass(cbeFriendController));
						pFriendController.m_hTalkTarget = EHandle(m_pDriveEnt);
					}
				}

				g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "OT_IDLE", VOL_NORM, ATTN_IDLE, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
				IdleHeadTurn( pFriend2.pev.origin );

				return;
			}
		}

		CNPC::g_flTalkWaitTime = 0.0;
	}

	void ResetHead()
	{
		if( m_pDriveEnt is null ) return;
		if( m_flResetHead <= 0.0 or m_flResetHead > g_Engine.time ) return;

		m_pDriveEnt.pev.set_controller( 0,  127 );
		m_flResetHead = 0.0;
	}

	void IdleHeadTurn( Vector vecFriend )
	{
		if( m_pDriveEnt is null ) return;
		float yaw = Math.VecToYaw( vecFriend - m_pDriveEnt.pev.origin ) - m_pDriveEnt.pev.angles.y;

		if( yaw > 180 ) yaw -= 360;
		if( yaw < -180 ) yaw += 360;

		m_pDriveEnt.SetBoneController( 0, yaw );
	}

	void ToggleGunAE()
	{
		if( m_iState != STATE_GUN_TOGGLE ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_DRAW and m_pDriveEnt.pev.sequence != ANIM_HOLSTER ) return;

		if( m_pDriveEnt.pev.sequence == ANIM_DRAW )
		{
			if( IsBetween2(GetFrame(16), 6, 8) and !m_bGunDrawn )
			{
				m_pDriveEnt.SetBodygroup( 1, 1 );
				m_bGunDrawn = true;
			}
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_HOLSTER )
		{
			if( IsBetween2(GetFrame(21), 14, 16) and m_bGunDrawn )
			{
				m_pDriveEnt.SetBodygroup( 1, 0 );
				m_bGunDrawn = false;
			}
		}
	}

	void Shoot()
	{
		Vector vecShootOrigin, vecShootDir;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		vecShootOrigin = m_pDriveEnt.pev.origin + Vector(0, 0, 60);
		vecShootDir = g_Engine.v_forward;

		Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
		g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24 + g_Engine.v_right * 8, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
		self.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_2DEGREES, 1024.0, BULLET_PLAYER_CUSTOMDAMAGE, 0, RANGE_DAMAGE, m_pPlayer.pev );

		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

		Vector angDir = Math.VecToAngles( vecShootDir );
		m_pDriveEnt.SetBlending( 0, angDir.x );

		int iPitchShift = Math.RandomLong( 0, 20 );

		// Only shift about half the time
		if( iPitchShift > 10 )
			iPitchShift = 0;
		else
			iPitchShift -= 5;

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 100 + iPitchShift );
		GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 384, 0.3, m_pPlayer ); 
	}

	void CheckReloadInput()
	{
		if( m_iState > STATE_RUN or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) >= AMMO_MAX or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			m_iState = STATE_RELOAD;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_RELOAD );

			if( CNPC_FIRSTPERSON )
				self.SendWeaponAnim( 8 );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (RELOAD_TIME + 0.1);
		}
	}

	void ReloadAE()
	{
		if( m_iState != STATE_RELOAD ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_RELOAD ) return;

		if( IsBetween2(GetFrame(26), 18, 20) and m_uiAnimationState == 0 ) { m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, AMMO_MAX); m_uiAnimationState++; }
		else if( GetFrame(26) >= 25 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
	}

	void FootstepAE()
	{
		if( m_iState != STATE_WALK and m_iState != STATE_RUN and m_pDriveEnt.pev.sequence != ANIM_WALK and m_pDriveEnt.pev.sequence != ANIM_RUN ) return;

		if( m_pDriveEnt.pev.sequence == ANIM_WALK )
		{
			if( IsBetween2(GetFrame(32), 2, 4) and m_uiAnimationState == 0 ) { FootStep(1); m_uiAnimationState++; }
			else if( IsBetween2(GetFrame(32), 17, 19) and m_uiAnimationState == 1 ) { FootStep(3); m_uiAnimationState++; }
			else if( GetFrame(32) >= 25 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_RUN )
		{
			if( IsBetween2(GetFrame(23), 4, 6) and m_uiAnimationState == 0 ) { FootStep(2); m_uiAnimationState++; }
			else if( IsBetween2(GetFrame(23), 15, 17) and m_uiAnimationState == 1 ) { FootStep(4); m_uiAnimationState++; }
			else if( GetFrame(23) >= 20 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }
		}
	}

	void FootStep( int iStepNum )
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP1 + (iStepNum-1)], VOL_NORM, ATTN_NORM );
	}

	void CheckForVendingMachine()
	{
		if( m_pPlayer.pev.health >= CNPC_HEALTH or m_iState > STATE_RUN or m_bHasDonut ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_USE) != 0 )
		{
			Math.MakeVectors( m_pPlayer.pev.v_angle );
			TraceResult tr;
			g_Utility.TraceLine( m_pPlayer.GetGunPosition(), m_pPlayer.GetGunPosition() + g_Engine.v_forward * 36,  ignore_monsters, m_pDriveEnt.edict(), tr );
			edict_t@ pWorld = g_EntityFuncs.Instance(0).edict();
			if( tr.pHit !is null ) @pWorld = tr.pHit;
			string sTexture = g_Utility.TraceTexture( pWorld, m_pPlayer.GetGunPosition(), m_pPlayer.GetGunPosition() + g_Engine.v_forward * 36 );

			if( sTexture == "snack_mach_01" or sTexture == "snack_mach_03" )
			{
				tr = g_Utility.GetGlobalTrace();
				Vector vecAngles = Math.VecToAngles( -tr.vecPlaneNormal );
				m_pDriveEnt.pev.angles.y = vecAngles.y;
				m_iState = STATE_VENDING;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				if( m_bGunDrawn )
					SetAnim( ANIM_HOLSTER, 4.0 );
				else
					SetAnim( ANIM_VENDING );
			}
		}
	}

	void VendingMachineAE()
	{
		if( m_iState != STATE_VENDING or (m_pDriveEnt.pev.sequence < ANIM_EAT and m_pDriveEnt.pev.sequence != ANIM_HOLSTER) ) return;

		if( m_pDriveEnt.pev.sequence == ANIM_HOLSTER )
		{
			if( IsBetween2(GetFrame(21), 14, 16) and m_uiAnimationState == 0 ) { m_pDriveEnt.SetBodygroup( 1, 0 ); m_bGunDrawn = false; m_uiAnimationState++; }
			if( IsBetween2(GetFrame(21), 18, 20) and m_uiAnimationState == 1 ) { SetAnim(ANIM_VENDING); }
		}
		if( m_pDriveEnt.pev.sequence == ANIM_VENDING )
		{
			if( IsBetween2(GetFrame(101), 17, 19) and m_uiAnimationState == 0 ) { VendingActivity(1); m_uiAnimationState++; }
			else if( GetFrame(101) >= 70 and m_uiAnimationState == 1 ) { SetAnim(ANIM_BUTTON, 2.0); }
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_BUTTON )
		{
			if( IsBetween2(GetFrame(23), 6, 8) and m_uiAnimationState == 0 ) { VendingActivity(2); m_uiAnimationState++; }
			else if( GetFrame(23) >= 17 and m_uiAnimationState == 1 ) { SetAnim(ANIM_EAT); }
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_EAT )
		{
			if( IsBetween2(GetFrame(26), 6, 8) and m_uiAnimationState == 0 ) { VendingActivity(3); m_uiAnimationState++; }
			else if( GetFrame(26) >= 17 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
		}
	}

	void EatingAE()
	{
		if( m_iState != STATE_EAT or m_pDriveEnt.pev.sequence != ANIM_EAT ) return;

		if( IsBetween2(GetFrame(26), 10, 12) and m_uiAnimationState == 0 ) { VendingActivity(4); m_uiAnimationState++; }
		else if( GetFrame(26) >= 22 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }
	}

	void VendingActivity( int iActivity )
	{
		if( iActivity == 1 )
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_CANDY], VOL_NORM, ATTN_NORM, 0, m_iVoicePitch + Math.RandomLong(0, 3) );
		else if( iActivity == 2 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_BUTTON], VOL_NORM, ATTN_NORM );
		else if( iActivity == 3 )
		{
			m_pDriveEnt.SetBodygroup( 1, 2 );
			m_bHasDonut = true;
		}
		else if( iActivity == 4 )
		{
			m_pPlayer.pev.health += HEAL_AMOUNT;
			if( m_pPlayer.pev.health > CNPC_HEALTH )
				m_pPlayer.pev.health = CNPC_HEALTH;

			m_pDriveEnt.SetBodygroup( 1, 0 );
			m_bHasDonut = false;
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_otis", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			m_pDriveEnt.pev.set_controller( 0,  127 );

			cnpc_otis@ pDriveEnt = cast<cnpc_otis@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null )
				m_iVoicePitch = pDriveEnt.m_iVoicePitch;
		}

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_OTIS );
	}

	void DoFirstPersonView()
	{
		cnpc_otis@ pDriveEnt = cast<cnpc_otis@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_otis_rend_" + m_pPlayer.entindex();
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

class cnpc_otis : CBaseDriveEntity
{
	int m_iVoicePitch;

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
		m_iVoicePitch = 100 + Math.RandomLong(0, 3);

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
		else if( (m_pOwner.pev.button & IN_ATTACK) != 0 )
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

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM, 0, m_iVoicePitch + Math.RandomLong(0, 3) );

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

final class info_cnpc_otis : CNPCSpawnEntity
{
	info_cnpc_otis()
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
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_otis::info_cnpc_otis", "info_cnpc_otis" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_otis::cnpc_otis", "cnpc_otis" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_otis::weapon_otis", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "otisammo" );

	g_Game.PrecacheOther( "info_cnpc_otis" );
	g_Game.PrecacheOther( "cnpc_otis" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_otis END

/* FIXME
*/

/* TODO
	Drop donut when drawing weapon ??
*/