namespace cnpc_engineer
{

bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_engineer";
const string CNPC_MODEL				= "models/sandstone/engineer.mdl";
const string CNPC_MODEL_VIEW		= "models/v_desert_eagle.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 100.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 40.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the engineer itself
const float CNPC_MODEL_OFFSET	= 32.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (55.501198 * CNPC::flModelToGameSpeedModifier); //55.501198
const float SPEED_WALK_LIMP		= (47.042507 * CNPC::flModelToGameSpeedModifier); //47.042507
const float SPEED_RUN					= (140.424637 * CNPC::flModelToGameSpeedModifier); //140.424637
const float SPEED_RUN_LIMP			= (85.191559 * CNPC::flModelToGameSpeedModifier); //85.191559
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_RANGE					= 0.3; //0.11 ??
const float RANGE_DAMAGE			= 44;
const int AMMO_MAX						= 7;
const float RELOAD_TIME				= 1.0;

const float CD_MELEE						= 1.0;
const float MELEE_RANGE				= 50.0;
const float MELEE_DAMAGE			= 12.0;

const array<string> pPainSounds = 
{
	"fgrunt/pain1.wav",
	"fgrunt/pain2.wav",
	"fgrunt/pain3.wav",
	"fgrunt/pain4.wav",
	"fgrunt/pain5.wav",
	"fgrunt/pain6.wav"
};

const array<string> pDieSounds = 
{
	"fgrunt/death1.wav",
	"fgrunt/death2.wav",
	"fgrunt/death3.wav",
	"fgrunt/death4.wav",
	"fgrunt/death5.wav",
	"fgrunt/death6.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"weapons/desert_eagle_fire.wav",
	"hgrunt/gr_reload1.wav",
	"weapons/cbar_hitbod1.wav",
	"weapons/cbar_hitbod2.wav",
	"weapons/cbar_hitbod3.wav",
	"weapons/xbow_hitbod2.wav",
	"zombie/claw_miss2.wav"
};

enum sound_e
{
	SND_SHOOT = 1,
	SND_RELOAD_DONE,
	SND_KICKHIT1,
	SND_KICKHIT2,
	SND_KICKHIT3,
	SND_KICKHITWALL,
	SND_KICKMISS
};

enum anim_e
{
	ANIM_WALK = 0,
	ANIM_RUN,
	ANIM_IDLE1 = 6,
	ANIM_IDLE_FIDGET,
	ANIM_IDLE2,
	ANIM_IDLE_COMBAT,
	ANIM_MELEE,
	ANIM_CROUCH_IDLE,
	ANIM_CROUCH_SHOOT = 13,
	ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_WALK_LIMP = 20,
	ANIM_RUN_LIMP,
	ANIM_DEATH1 = 24,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_DEATH6,
	ANIM_CHARGE_SET = 48
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_RANGE,
	STATE_MELEE,
	STATE_RELOAD,
	STATE_CHARGE_SET
};

class weapon_engineer : CBaseDriveWeapon
{
	private int m_iShell;
	private int m_iWeaponStage;
	private bool m_bCrouching;
	int m_iVoicePitch;

	array<string> arrsBombTargetNames = { "asbomb1", "asbomb2", "asbomb3", "asbomb4", "asbomb5", "asbomb6", "asbomb7", "asbomb8", "asbomb9" };
	private EHandle m_hBombTarget;
	private CBaseEntity@ m_pBombTarget
	{
		get const { return m_hBombTarget.GetEntity(); }
		set { m_hBombTarget = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_iWeaponStage = 0;
		m_bCrouching = false;
		m_iVoicePitch = Math.RandomLong(95, 100);

		self.m_iDefaultAmmo = AMMO_MAX;
		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( CNPC_MODEL_VIEW );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_engineer.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_engineer.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_engineer_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= AMMO_MAX;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::ENGINEER_SLOT - 1;
		info.iPosition			= CNPC::ENGINEER_POSITION - 1;
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
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
		}

		return self.DefaultDeploy( self.GetV_Model(CNPC_MODEL_VIEW), "", 9, "" );
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
		float flTime = 1.0;

		if( m_pDriveEnt !is null )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.3;
				return;
			}

			if( (m_pPlayer.pev.button & IN_ATTACK2) != 0 )
			{
				if( m_iState != STATE_MELEE and m_iState != STATE_CHARGE_SET and m_iState != STATE_RELOAD )
				{
					if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
					{
						DoIdleAnimation( true );
						self.m_flNextPrimaryAttack = g_Engine.time + 0.3;
						return;
					}

					m_iState = STATE_RANGE;
					m_pPlayer.SetMaxSpeedOverride( 0 );

					if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
						SetAnim( ANIM_SHOOT );
					else
						SetAnim( ANIM_CROUCH_SHOOT );

					if( CNPC_FIRSTPERSON )
					{
						if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) == 1 )
							self.SendWeaponAnim( 6 );
						else
							self.SendWeaponAnim( 5 );
					}

					Shoot();

					int random = Math.RandomLong(0, 20);
					int pitch = random <= 10 ? (random + 95) : 100;

					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM, 0, pitch );
					GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 384, 0.3, m_pPlayer ); 

					flTime = CD_RANGE;
				}
			}
			else
			{
				if( m_iState != STATE_RANGE and m_iState != STATE_CHARGE_SET and m_iState != STATE_RELOAD )
				{
					m_iState = STATE_MELEE;
					m_pPlayer.SetMaxSpeedOverride( 0 );

					SetAnim( ANIM_MELEE );

					if( CNPC_FIRSTPERSON )
					{
						m_pPlayer.pev.viewmodel = "";

						cnpc_engineer@ pDriveEnt = cast<cnpc_engineer@>(CastToScriptClass(m_pDriveEnt));
						if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() )
							pDriveEnt.m_hRenderEntity.GetEntity().pev.renderamt = 255;
					}

					SetThink( ThinkFunction(this.MeleeAttackThink) );
					pev.nextthink = g_Engine.time + 0.3;

					flTime = CD_MELEE;
				}
			}
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
	}

	void Shoot()
	{
		Vector vecShootOrigin, vecShootDir;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		vecShootOrigin = m_pDriveEnt.pev.origin + Vector(0, 0, 60);
		vecShootDir = g_Engine.v_forward;

		Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
		g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
		self.FireBullets( 1, vecShootOrigin, vecShootDir, (m_bCrouching ? VECTOR_CONE_1DEGREES : VECTOR_CONE_2DEGREES), 1024.0, BULLET_PLAYER_357, 0, RANGE_DAMAGE, m_pPlayer.pev );

		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

		Vector angDir = Math.VecToAngles( vecShootDir );
		m_pDriveEnt.SetBlending( 0, angDir.x );
	}

	void MeleeAttackThink()
	{
		if( m_pDriveEnt is null or m_pPlayer is null or !m_pPlayer.IsAlive() )
		{
			SetThink( null );
			return;
		}

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE, DMG_CLUB, false );

		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 15;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_up * 50;
			}

			if( pHurt.IsBSPModel() )
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_KICKHITWALL], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
			else
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_KICKHIT1, SND_KICKHIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_KICKMISS], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

		if( CNPC_FIRSTPERSON )
		{
			SetThink( ThinkFunction(this.MeleeFinishThink) );
			pev.nextthink = g_Engine.time + 0.5;
		}
		else
			SetThink( null );
	}

	void MeleeFinishThink()
	{
		cnpc_engineer@ pDriveEnt = cast<cnpc_engineer@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() )
			pDriveEnt.m_hRenderEntity.GetEntity().pev.renderamt = 0;

		m_pPlayer.pev.viewmodel = CNPC_MODEL_VIEW;
		SetThink( null );
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState == STATE_RELOAD or m_iState == STATE_CHARGE_SET ) return;

			if( m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT and m_pDriveEnt.pev.sequence != ANIM_CROUCH_IDLE and (m_pPlayer.pev.button & IN_ATTACK) == 0 )
			{
				m_iState = STATE_RANGE;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
					SetAnim( ANIM_IDLE_COMBAT );
			}
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
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
			cnpc_engineer@ pDriveEnt = cast<cnpc_engineer@>(CastToScriptClass(m_pDriveEnt));
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
			DoCrouching();

			DoReload();
			CheckChargePlantingInput();
			DoChargePlanting();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState >= STATE_RANGE ) return;

		m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_iState != STATE_WALK )
			{
				m_iState = STATE_WALK;

				if( m_pPlayer.pev.health <= (m_pPlayer.pev.max_health * 0.3) )
				{
					m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK_LIMP) );
					SetAnim( ANIM_WALK_LIMP );
				}
				else
				{
					m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
					SetAnim( ANIM_WALK );
				}
			}
		}
		else
		{
			if( m_iState != STATE_RUN )
			{
				m_iState = STATE_RUN;

				if( m_pPlayer.pev.health <= (m_pPlayer.pev.max_health * 0.3) )
				{
					m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN_LIMP) );
					SetAnim( ANIM_RUN_LIMP );
				}
				else
				{
					m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
					SetAnim( ANIM_RUN );
				}
			}
		}
	}

	void DoIdleAnimation( bool bOverrideState = false )
	{
		if( m_pDriveEnt is null ) return;

		if( !bOverrideState )
		{
			if( m_iState == STATE_RANGE and (m_pPlayer.pev.button & IN_ATTACK != 0/* or !m_pDriveEnt.m_fSequenceFinished*/) ) return;
			if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_RELOAD and m_pDriveEnt.pev.sequence == ANIM_RELOAD and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_CHARGE_SET and m_pDriveEnt.pev.sequence == ANIM_CHARGE_SET ) return;
		}

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;

				if( (m_pPlayer.pev.button & IN_ATTACK2) != 0 and (m_pPlayer.pev.button & IN_DUCK) == 0 )
					SetAnim( ANIM_IDLE_COMBAT );
				else
				{
					if( (m_pPlayer.pev.button & IN_DUCK) != 0 )
						SetAnim( ANIM_CROUCH_IDLE );
					else
						SetAnim( ANIM_IDLE1 );
				}
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS and m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void IdleSound()
	{
		if( CNPC::g_flTalkWaitTime > g_Engine.time ) return;

		if( CNPC::g_iTorchAllyQuestion != 0 or Math.RandomLong(0, 1) == 1 )
		{
			if( CNPC::g_iTorchAllyQuestion == 0 )
			{
				// ask question or make statement
				switch( Math.RandomLong(0, 2) )
				{
					// check in
					case 0: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "FG_CHECK", 0.35, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iGruntQuestion = 1; break; }

					 // question
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "FG_QUEST", 0.35, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iGruntQuestion = 2; break; }

					 // statement
					case 2: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "FG_IDLE", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break; }
				}
			}
			else
			{
				switch( CNPC::g_iTorchAllyQuestion )
				{
					// check in
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "FG_CLEAR", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break; }

					// question
					case 2: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "FG_ANSWER", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break;}
				}

				CNPC::g_iTorchAllyQuestion = 0;
			}

			CNPC::g_flTalkWaitTime = g_Engine.time + Math.RandomFloat( 1.5, 2.0 );
		}
	}

	void DoCrouching()
	{
		if( m_pDriveEnt is null ) return;

		if( (m_pPlayer.pev.button & IN_DUCK) != 0 )
		{
			if( m_iState == STATE_IDLE and m_pDriveEnt.pev.sequence != ANIM_CROUCH_IDLE )
				SetAnim( ANIM_CROUCH_IDLE );
		}
		else
		{
			if( m_iState == STATE_IDLE and m_pDriveEnt.pev.sequence != ANIM_IDLE1 and m_pDriveEnt.pev.sequence != ANIM_IDLE_FIDGET and m_pDriveEnt.pev.sequence != ANIM_IDLE2 and m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT )
				DoIdleAnimation( true );
		}

		if( m_pDriveEnt.pev.sequence == ANIM_CROUCH_IDLE or m_pDriveEnt.pev.sequence == ANIM_CROUCH_SHOOT ) m_bCrouching = true;
		else m_bCrouching = false;
	}

	void DoReload()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState >= STATE_MELEE or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) >= AMMO_MAX or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			m_iState = STATE_RELOAD;
			m_iWeaponStage = 0;

			m_pPlayer.SetMaxSpeedOverride( 0 );

			SetAnim( ANIM_RELOAD );

			if( CNPC_FIRSTPERSON )
				self.SendWeaponAnim( 7 );

			SetThink( ThinkFunction(this.ReloadThink) );
			pev.nextthink = g_Engine.time;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (RELOAD_TIME + 0.1);
		}
	}

	void ReloadThink()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState != STATE_RELOAD ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_RELOAD ) return;

		switch( GetFrame(71) )
		{
			case 47:
			{
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_RELOAD_DONE], VOL_NORM, ATTN_NORM );
				m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, AMMO_MAX);
				DoIdleAnimation();
				SetThink( null );

				break;
			}
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void CheckChargePlantingInput()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState > STATE_RUN ) return;

		//if( (m_pPlayer.pev.button & IN_USE) == 0 and (m_pPlayer.pev.oldbuttons & IN_USE) != 0 )
		if( (m_pPlayer.m_afButtonPressed & IN_USE) != 0 )
		{
			float flDist;

			CBaseEntity@ pTarget = null;
			while( (@pTarget = g_EntityFuncs.FindEntityByClassname(pTarget, "scripted_sequence")) !is null )
			{
				if( arrsBombTargetNames.find(pTarget.pev.targetname) < 0 ) continue;
				flDist = (m_pPlayer.pev.origin - pTarget.pev.origin).Length();
				if( flDist > 50 ) continue;

				string sNewTargetName = string(pTarget.pev.targetname) + m_pPlayer.entindex();
				pTarget.pev.targetname = sNewTargetName;
				@m_pBombTarget = pTarget;

				break;
			}

			if( pTarget !is null )
			{
				m_pDriveEnt.pev.angles.y = pTarget.pev.angles.y;
				m_iState = STATE_CHARGE_SET;
				m_pPlayer.SetMaxSpeedOverride( 0 );
				SetAnim( ANIM_CHARGE_SET );
				m_iWeaponStage = 0;
			}
		}
	}

	void DoChargePlanting()
	{
		if( m_pDriveEnt is null or m_pBombTarget is null ) return;
		if( m_iState != STATE_CHARGE_SET or m_pDriveEnt.pev.sequence != ANIM_CHARGE_SET ) return;

		if( m_pDriveEnt.m_fSequenceFinished )
		{
			m_pBombTarget.SUB_UseTargets( m_pPlayer, USE_ON, 0 );

			DoIdleAnimation( true );
		}
		else
		{
			switch( GetFrame(101) )
			{
				case 1: { if( m_iWeaponStage == 0 ) { m_pDriveEnt.SetBodygroup( 2, 1 ); m_iWeaponStage++; } break; }
				case 65: { if( m_iWeaponStage == 1 ) { m_pDriveEnt.SetBodygroup( 2, 2 ); m_iWeaponStage++; } break; }
				case 78: { if( m_iWeaponStage == 2 ) { m_pDriveEnt.SetBodygroup( 2, 0 ); m_iWeaponStage++; } break; }
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_engineer", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		m_pDriveEnt.pev.set_controller( 0,  127 );
		m_pDriveEnt.pev.targetname = "engineer";

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_ENGINEER );
	}

	void DoFirstPersonView()
	{
		cnpc_engineer@ pDriveEnt = cast<cnpc_engineer@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_engineer_pid_" + m_pPlayer.entindex();
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
		if( m_pBombTarget !is null )
		{
			for( uint i = 0; i < arrsBombTargetNames.length(); i++ )
			{
				if( m_pBombTarget.pev.targetname == arrsBombTargetNames[i] + m_pPlayer.entindex() )
				{
					m_pBombTarget.pev.targetname = arrsBombTargetNames[i];

					break;
				}
			}

			@m_pBombTarget = null;
		}

		m_pPlayer.pev.iuser3 = 0; //enable ducking
		m_pPlayer.pev.fuser4 = 0; //enable jumping
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_engineer : ScriptBaseAnimating
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
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = ANIM_IDLE1;
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_RUN_LIMP or pev.sequence == ANIM_WALK or pev.sequence == ANIM_WALK_LIMP) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( (m_pOwner.pev.button & IN_ATTACK2) != 0 and pev.sequence != ANIM_CHARGE_SET )
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
		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH6 );
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

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

final class info_cnpc_engineer : CNPCSpawnEntity
{
	info_cnpc_engineer()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE1;
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_engineer::info_cnpc_engineer", "info_cnpc_engineer" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_engineer::cnpc_engineer", "cnpc_engineer" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_engineer::weapon_engineer", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "engyammo" );

	g_Game.PrecacheOther( "info_cnpc_engineer" );
	g_Game.PrecacheOther( "cnpc_engineer" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_engineer END

/* FIXME
*/

/* TODO
*/