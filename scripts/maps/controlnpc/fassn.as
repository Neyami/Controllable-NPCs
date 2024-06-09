//CAUTION: MESSY CODE AHEAD

namespace cnpc_fassn
{

const bool BLOCK_JUMP_IF_NOT_ENOUGH_ROOM	= false;

bool CNPC_FIRSTPERSON					= false;
	
const string sWeaponName				= "weapon_fassn";

const float CNPC_HEALTH					= 50.0;
const float CNPC_VIEWOFS_FPV			= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV			= 28.0;
const float CNPC_VIEWOFS_SHOOT	= 14.0;
const float CNPC_RESPAWNTIME			= 13.0; //from the point that the weapon is removed, not the fassn itself

const float SPEED_WALK						= -1;
const float SPEED_RUN						= -1;
const float VELOCITY_WALK				= 150.0; //if the player's velocity is this or lower, use the walking animation
const float JUMP_VELOCITY					= 160.0;
const float CD_PRIMARY						= 0.25; //gun
const float CD_SECONDARY					= 1.0; //kicks
const float CD_GRENADE						= 6.0; //grenade

const float MELEE_DAMAGE					= 20.0;
const float MELEE_RANGE					= 100.0;

const int STEALTH_MAX						= 100;
const float STEALTH_REGEN_RATE		= 0.1;

//HUD STUFF
const int HUD_CHANNEL_STEALTH		= 11; //0-15

const float HUD_STEALTH_X				= 0.5;
const float HUD_STEALTH_Y				= 1.0;
const float HUD_DANGER_CUTOFF		= 0.2;

const RGBA HUD_COLOR_NORMAL		= RGBA_SVENCOOP;
const RGBA HUD_COLOR_LOW			= RGBA(255, 0, 0, 255);

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav",
	"weapons/pl_gun1.wav",
	"weapons/pl_gun2.wav",
	"debris/beamstart1.wav",
	"weapons/cbar_hitbod1.wav",
	"weapons/cbar_hitbod2.wav",
	"weapons/cbar_hitbod3.wav",
	"weapons/xbow_hitbod2.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav"
};

enum sound_e
{
	SND_RESPAWN = 0,
	SND_SHOOT1,
	SND_SHOOT2,
	SND_STEALTH,
	SND_KICKHIT1,
	SND_KICKHIT2,
	SND_KICKHIT3,
	SND_KICKHITWALL,
	SND_KICKMISS1,
	SND_KICKMISS2
};

enum anim_e
{
	ANIM_IDLE = 1,
	ANIM_IDLE_COMBAT,
	ANIM_RUN,
	ANIM_WALK,
	ANIM_SHOOT,
	ANIM_GRENADETHROW,
	ANIM_KICKLONG,
	ANIM_KICK,
	ANIM_DEATH_RUN,
	ANIM_DEATH,
	ANIM_DEATH_COMBAT,
	ANIM_JUMP_START,
	ANIM_JUMP_LOOP,
	ANIM_JUMP_FALLING,
	ANIM_JUMP_SHOOT,
	ANIM_LAND
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_SHOOT,
	STATE_JUMP,
	STATE_JUMP_SHOOT,
	STATE_MELEE,
	STATE_GRENADE,
	STATE_DEATH
};

class weapon_fassn : CBaseDriveWeapon
{
	int m_iAutoDeploy;
	private int m_iShell;
	private bool m_bHasFired; //HACK
	private float m_flLastShot;
	private float m_flDiviation;

	private int m_iRandomAttack;

	private bool m_bHasThrownGrenade; //HACK
	private float m_flNextGrenade;

	private bool m_bStealthActive;
	private float m_flNextStealth; //for slowly fading in and out of stealth
	private float m_iTargetRanderamt;

	private HUDNumDisplayParams m_hudParamsStealth;
	private int m_iStealthMax;
	private int m_iStealthCurrent;
	private float m_flNextStealthRegen;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "autodeploy" )
		{
			m_iAutoDeploy = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_bHasFired = false;
		m_bHasThrownGrenade = false;
		m_flNextGrenade = 0.0;
		m_iRandomAttack = 0;
		m_bStealthActive = false;
		m_flNextStealth = 0.0;
		m_iTargetRanderamt = 20.0;
		m_iStealthMax = STEALTH_MAX;
		m_iStealthCurrent = STEALTH_MAX;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/hassassin.mdl" );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_fassn.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_fassn.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_fassn_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::FASSN_SLOT - 1;
		info.iPosition		= CNPC::FASSN_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(sWeaponName) );
		m1.End();

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
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
			if( m_iState == STATE_JUMP or m_iState == STATE_MELEE or m_iState == STATE_GRENADE ) return;

			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( m_iState != STATE_SHOOT and m_iState != STATE_JUMP_SHOOT )
			{
				DisableStealth();

				m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_SHOOT );
				m_iState = STATE_SHOOT;
				m_pDriveEnt.pev.sequence = ANIM_SHOOT;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else if( m_iState == STATE_JUMP_SHOOT )
			{
				DisableStealth();
				ShootAirborne();
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CD_PRIMARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState != STATE_JUMP and m_iState != STATE_JUMP_SHOOT and m_iState != STATE_SHOOT and m_iState != STATE_GRENADE )
			{
				DisableStealth();
				m_iState = STATE_MELEE;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				m_iRandomAttack = Math.RandomLong(0, 1);

				switch( m_iRandomAttack )
				{
					case 0:	m_pDriveEnt.pev.sequence = ANIM_KICK; pev.nextthink = g_Engine.time + 0.3; break;
					case 1:	m_pDriveEnt.pev.sequence = ANIM_KICKLONG; pev.nextthink = g_Engine.time + 0.1; break;
				}

				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				SetThink( ThinkFunction(this.MeleeAttackThink) );
			}
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + CD_SECONDARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_SECONDARY;
	}


	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
		{
			SetThink( null );
			return;
		}

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE, DMG_CLUB );

		if( pHurt !is null )
		{
			if( (pHurt.pev.flags & FL_MONSTER) == 1 or ((pHurt.pev.flags & FL_CLIENT) == 1 and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -100;
			}

			if( pHurt.IsBSPModel() )
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_KICKHITWALL], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
			else
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_KICKHIT1, SND_KICKHIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

			Vector vecArmPos, vecArmAng;
			m_pDriveEnt.GetAttachment( 0, vecArmPos, vecArmAng );
			g_WeaponFuncs.SpawnBlood( vecArmPos, pHurt.BloodColor(), 25 );
		}
		else
		{
			int iSound = SND_KICKMISS1;

			if( m_iRandomAttack == 0 or m_iRandomAttack == 1 ) iSound = SND_KICKMISS1;
			else iSound = SND_KICKMISS2;

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[iSound], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}

		if( m_iRandomAttack == 0 or m_iRandomAttack == 2 ) //single kick and second hit of the double kick
			SetThink( null );
		else if( m_iRandomAttack == 1 ) //double kick, first
		{
			m_iRandomAttack = 2;
			pev.nextthink = g_Engine.time + 0.4;
		}
	}

	void TertiaryAttack()
	{
		if( m_pDriveEnt !is null )
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
				cnpc_fassn@ pDriveEnt = cast<cnpc_fassn@>(CastToScriptClass(m_pDriveEnt));
				if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

				m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
				m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
				CNPC_FIRSTPERSON = false;
			}

			self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
		}
	}

	void CheckGrenadeInput()
	{
		if( m_iState == STATE_SHOOT or m_iState == STATE_JUMP or m_iState == STATE_MELEE ) return;
		if( m_flNextGrenade > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 )
		{
			m_iTargetRanderamt = 255;
			m_bStealthActive = false;
			m_flNextStealth = g_Engine.time + 0.1;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iState = STATE_GRENADE;
			m_pDriveEnt.pev.sequence = ANIM_GRENADETHROW;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			m_flNextGrenade = g_Engine.time + CD_GRENADE;
		}
	}

	void ThrowGrenade()
	{
		if( m_iState != STATE_GRENADE or m_pDriveEnt.pev.sequence != ANIM_GRENADETHROW ) return;

		if( GetFrame(16) == 8 and !m_bHasThrownGrenade )
		{
			Math.MakeVectors( m_pPlayer.pev.v_angle );
			Vector vecGrenadeVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * 750.0;

			g_EntityFuncs.ShootTimed( m_pPlayer.pev, m_pDriveEnt.pev.origin + g_Engine.v_forward * 34 + Vector (0, 0, 32), vecGrenadeVelocity, 2.0 );

			m_bHasThrownGrenade = true;
		}
		else if( GetFrame(16) > 10 and m_bHasThrownGrenade )
			m_bHasThrownGrenade = false;
	}

	void CheckStealthInput()
	{
		if( m_iState == STATE_MELEE or m_iState == STATE_SHOOT or m_iState ==STATE_JUMP_SHOOT or m_iState == STATE_GRENADE ) return;

		if( (m_pPlayer.pev.button & IN_DUCK) == 0 and (m_pPlayer.pev.oldbuttons & IN_DUCK) != 0 )
		{
			if( m_bStealthActive )
				DisableStealth();
			else
			{
				m_iTargetRanderamt = 20;
				m_bStealthActive = true;
				m_flNextStealth = g_Engine.time + 0.1;
			}
		}

		if( (m_pPlayer.pev.button & IN_DUCK) != 0 )
		{
			NetworkMessage disableduck( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
				disableduck.WriteString( "-duck\n" );
			disableduck.End();
		}
	}

	void DisableStealth()
	{
		m_iTargetRanderamt = 255;
		m_bStealthActive = false;
		m_flNextStealth = g_Engine.time + 0.1;
	}

	void DoStealth()
	{
		if( m_bStealthActive )
		{
			if( m_pDriveEnt.pev.renderamt > m_iTargetRanderamt )
			{
				m_pDriveEnt.pev.rendermode = kRenderTransTexture;

				if( m_flNextStealth <= g_Engine.time )
				{
					if( m_pDriveEnt.pev.renderamt == 255 )
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEALTH], 0.2, ATTN_NORM );

					m_pDriveEnt.pev.renderamt = Math.max( m_pDriveEnt.pev.renderamt - 50, m_iTargetRanderamt );
					m_flNextStealth = g_Engine.time + 0.1;
				}
			}
			else if( m_flNextStealth <= g_Engine.time )
			{
				m_pPlayer.pev.flags |= FL_NOTARGET;

				//HUD STUFF
				--m_iStealthCurrent;
				UpdateHUD( HUD_CHANNEL_STEALTH, m_iStealthCurrent, m_iStealthMax );
				m_flNextStealth = g_Engine.time + 0.1;
			}

			if( m_iStealthCurrent <= 0 )
				DisableStealth();
		}
		else if( m_pDriveEnt.pev.renderamt < m_iTargetRanderamt )
		{
			if( m_flNextStealth <= g_Engine.time )
			{
				m_pDriveEnt.pev.renderamt = Math.min( m_pDriveEnt.pev.renderamt + 50, m_iTargetRanderamt );
				m_flNextStealth = g_Engine.time + 0.1;
			}

			if( m_pDriveEnt.pev.renderamt >= 255 )
			{
				m_pDriveEnt.pev.rendermode = kRenderNormal;
				m_flNextStealth = 0.0;
				m_pPlayer.pev.flags &= ~FL_NOTARGET;
			}
		}

		if( !m_bStealthActive and m_pDriveEnt.pev.renderamt >= 255 and m_iStealthCurrent < m_iStealthMax )
		{
			if( m_flNextStealthRegen < g_Engine.time )
			{
				//HUD STUFF
				m_iStealthCurrent++;

				UpdateHUD( HUD_CHANNEL_STEALTH, m_iStealthCurrent, m_iStealthMax );
				m_flNextStealthRegen = g_Engine.time + STEALTH_REGEN_RATE;
			}
		}		
	}

	void Reload() //necessary to prevent the reload-key from interfering?
	{
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		DoIdleAnimation();

		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.pev.friction = 2; //no sliding!

			if( m_pPlayer.pev.button & (IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 )
				m_pPlayer.SetMaxSpeedOverride( 0 );
			else if( m_pPlayer.pev.button & IN_FORWARD != 0 and m_iState != STATE_SHOOT and m_iState != STATE_MELEE and m_iState != STATE_GRENADE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
				DoMovementAnimation();
				self.m_flTimeWeaponIdle = g_Engine.time + 0.1;
			}

			DoIdleAnimation();
			Jump();
			Airborne();
			Shoot();
			CheckGrenadeInput();
			ThrowGrenade();
			CheckStealthInput();
			DoStealth();
		}
	}

	void DoMovementAnimation()
	{
		if( m_iState == STATE_SHOOT ) return;
		if( (m_iState == STATE_JUMP or m_iState == STATE_JUMP_SHOOT) and !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				m_pDriveEnt.pev.sequence = ANIM_WALK;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_pDriveEnt.pev.sequence = ANIM_RUN;
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
		if( m_iState == STATE_SHOOT and m_pPlayer.pev.button & IN_ATTACK != 0 ) return;
		if( m_iState == STATE_JUMP and !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState == STATE_MELEE and (m_pDriveEnt.pev.sequence == ANIM_KICK or m_pDriveEnt.pev.sequence == ANIM_KICKLONG) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_GRENADE and m_pDriveEnt.pev.sequence == ANIM_GRENADETHROW and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
				m_iState = STATE_IDLE;
				m_pDriveEnt.pev.sequence = m_bStealthActive ? ANIM_IDLE_COMBAT : ANIM_IDLE;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
	}

	void Jump()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState == STATE_SHOOT and m_pPlayer.pev.button & IN_ATTACK != 0 ) return;
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState == STATE_MELEE or m_iState == STATE_GRENADE ) return;

		if( (m_pPlayer.pev.button & IN_JUMP) == 0 and (m_pPlayer.pev.oldbuttons & IN_JUMP) != 0 )
		{
			TraceResult	tr;
			Vector vecJumpVelocity;
			Math.MakeAimVectors( m_pPlayer.pev.angles );
			Vector vecDest = m_pPlayer.pev.origin + Vector( -g_Engine.v_forward.x*64, -g_Engine.v_forward.y*64, JUMP_VELOCITY ); //backflip

			if( BLOCK_JUMP_IF_NOT_ENOUGH_ROOM )
			{
				g_Utility.TraceHull( m_pPlayer.pev.origin + Vector(0, 0, 36), vecDest + Vector(0, 0, 36), dont_ignore_monsters, human_hull, m_pPlayer.edict(), tr );

				if( tr.fStartSolid != 0 or tr.flFraction < 1.0 )
					return;
			}

			g_EntityFuncs.SetOrigin( m_pPlayer, m_pPlayer.pev.origin + Vector(0, 0, 1) ); // take her off ground so engine doesn't instantly reset onground 

			m_iState = STATE_JUMP;
			m_pDriveEnt.pev.sequence = ANIM_JUMP_START;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			float flGravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );

			float time = sqrt( 160 / (0.5 * flGravity) );
			float speed = flGravity * time / 160;
			vecJumpVelocity = (vecDest - pev.origin) * speed;

			m_pPlayer.pev.velocity = vecJumpVelocity;
		}
	}

	void Airborne()
	{
		if( m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_pDriveEnt.pev.sequence == ANIM_JUMP_START and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pDriveEnt.pev.velocity.z > 0 )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_JUMP_LOOP )
			{
				m_pDriveEnt.pev.sequence = ANIM_JUMP_LOOP;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
		else if( m_pPlayer.pev.button & IN_ATTACK != 0 )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_JUMP_SHOOT )
			{
				m_iState = STATE_JUMP_SHOOT;
				m_pDriveEnt.pev.sequence = ANIM_JUMP_SHOOT;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
		else
		{
			m_iState = STATE_JUMP;
			m_pDriveEnt.pev.sequence = ANIM_JUMP_FALLING;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();
		}		
	}

	void Shoot()
	{
		if( m_iState == STATE_SHOOT and m_pPlayer.pev.button & IN_ATTACK == 0 ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_SHOOT ) return;

		if( GetFrame(9) == 2 and !m_bHasFired )
		{
			Vector vecShootOrigin, vecShootDir;

			Math.MakeVectors( m_pPlayer.pev.v_angle );

			m_pDriveEnt.GetAttachment( 0, vecShootOrigin, void );
			vecShootDir = g_Engine.v_forward;

			if( m_flLastShot + 2 < g_Engine.time )
				m_flDiviation = 0.10;
			else
			{
				m_flDiviation -= 0.01;

				if( m_flDiviation < 0.02 )
					m_flDiviation = 0.02;
			}

			m_flLastShot = g_Engine.time;

			Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40,90) + g_Engine.v_up * Math.RandomFloat(75,200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
			g_EntityFuncs.EjectBrass( m_pDriveEnt.pev.origin + g_Engine.v_up * 32 + g_Engine.v_forward * 12, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
			m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, Vector(m_flDiviation, m_flDiviation, m_flDiviation), 2048.0, BULLET_MONSTER_9MM );

			switch( Math.RandomLong(0, 1) )
			{
				case 0:
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT1], Math.RandomFloat(0.6, 0.8), ATTN_NORM );
					break;
				case 1:
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT2], Math.RandomFloat(0.6, 0.8), ATTN_NORM );
					break;
			}

			m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

			Vector angDir = Math.VecToAngles( vecShootDir );
			m_pDriveEnt.SetBlending( 0, angDir.x );

			m_bHasFired = true;
		}
		else if( GetFrame(9) > 3 and m_bHasFired )
			m_bHasFired = false;
	}

	void ShootAirborne()
	{
		Vector vecShootOrigin, vecShootDir;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		m_pDriveEnt.GetAttachment( 0, vecShootOrigin, void );
		vecShootDir = g_Engine.v_forward;

		if( m_flLastShot + 2 < g_Engine.time )
			m_flDiviation = 0.10;
		else
		{
			m_flDiviation -= 0.01;

			if( m_flDiviation < 0.02 )
				m_flDiviation = 0.02;
		}

		m_flLastShot = g_Engine.time;

		Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40,90) + g_Engine.v_up * Math.RandomFloat(75,200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
		g_EntityFuncs.EjectBrass( m_pDriveEnt.pev.origin + g_Engine.v_up * 32 + g_Engine.v_forward * 12, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
		m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, Vector(m_flDiviation, m_flDiviation, m_flDiviation), 2048.0, BULLET_MONSTER_9MM );

		switch( Math.RandomLong(0, 1) )
		{
			case 0:
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT1], Math.RandomFloat(0.6, 0.8), ATTN_NORM );
				break;
			case 1:
				g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT2], Math.RandomFloat(0.6, 0.8), ATTN_NORM );
				break;
		}

		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		Vector angDir = Math.VecToAngles( vecShootDir );
		m_pDriveEnt.SetBlending( 0, angDir.x );
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

		if( m_iAutoDeploy == 0 )
			vecOrigin.z -= 32.0;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_fassn", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );
		m_pDriveEnt.pev.renderamt = 255;

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_FASSN );

		//HUD STUFF
		SetHudParamsStealth();

		g_PlayerFuncs.HudNumDisplay( m_pPlayer, m_hudParamsStealth );
		UpdateHUD( HUD_CHANNEL_STEALTH, m_iStealthCurrent, m_iStealthMax );
	}

	void DoFirstPersonView()
	{
		cnpc_fassn@ pDriveEnt = cast<cnpc_fassn@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_fassn_pid_" + m_pPlayer.entindex();
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
		//HUD STUFF
		g_PlayerFuncs.HudToggleElement( m_pPlayer, HUD_CHANNEL_STEALTH, false );

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

	//HUD STUFF
	void UpdateHUD( uint8 channel, float value, float maxvalue )
	{
		switch( channel )
		{
			case HUD_CHANNEL_STEALTH:
			{
				if( float(value/maxvalue) <= HUD_DANGER_CUTOFF )
					m_hudParamsStealth.color1 = HUD_COLOR_LOW;
				else
					m_hudParamsStealth.color1 = HUD_COLOR_NORMAL;

				g_PlayerFuncs.HudNumDisplay( m_pPlayer, m_hudParamsStealth );

				break;
			}
		}

		g_PlayerFuncs.HudUpdateNum( m_pPlayer, channel, value );
	}

	void SetHudParamsStealth()
	{
		m_hudParamsStealth.channel = HUD_CHANNEL_STEALTH;
		m_hudParamsStealth.flags = HUD_ELEM_DEFAULT_ALPHA;
		m_hudParamsStealth.value = m_iStealthMax;
		m_hudParamsStealth.x = HUD_STEALTH_X;
		m_hudParamsStealth.y = HUD_STEALTH_Y;
		m_hudParamsStealth.maxdigits = 3;
	}
}

class cnpc_fassn : ScriptBaseAnimating
{
	EHandle m_hRenderEntity;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/hassassin.mdl" );
		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void DriveThink()
	{
		if( pev.owner is null or pev.owner.vars.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		Vector vecOrigin = pOwner.pev.origin;
		vecOrigin.z -= 32.0;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.velocity = pOwner.pev.velocity;

		pev.angles.x = 0;
		pev.angles.y = pOwner.pev.angles.y;
		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		if( pev.sequence == ANIM_RUN )
			pev.sequence = ANIM_DEATH_RUN;
		else if( pev.sequence == ANIM_SHOOT )
			pev.sequence = ANIM_DEATH_COMBAT;
		else
			pev.sequence = ANIM_DEATH;

		pev.frame = 0;
		self.ResetSequenceInfo();

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

class info_cnpc_fassn : ScriptBaseAnimating
{
	protected EHandle m_hCNPCWeapon;
	protected CBaseEntity@ m_pCNPCWeapon
	{
		get const { return cast<CBaseEntity@>(m_hCNPCWeapon.GetEntity()); }
		set { m_hCNPCWeapon = EHandle(@value); }
	}

	private float m_flRespawnTime; //how long until respawn
	private float m_flTimeToRespawn; //used to check if ready to respawn

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/hassassin.mdl" );
		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

		Vector vecOrigin = pev.origin;
		vecOrigin.z -= 36.0;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = ANIM_IDLE;
		pev.rendermode = kRenderTransTexture;
		pev.renderfx = kRenderFxDistort;
		pev.renderamt = 128;

		if( m_flRespawnTime <= 0 ) m_flRespawnTime = CNPC_RESPAWNTIME;

		SetUse( UseFunction(this.UseCNPC) );
	}

	int ObjectCaps() { return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE); }

	void UseCNPC( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue  ) 
	{
		CustomKeyvalues@ pCustom = pActivator.GetCustomKeyvalues();
		if( pCustom.GetKeyvalue(CNPC::sCNPCKV).GetInteger() != 0 ) return;

		if( pActivator.pev.FlagBitSet(FL_CLIENT) and pActivator.pev.FlagBitSet(FL_ONGROUND) )
		{
			g_EntityFuncs.SetOrigin( pActivator, pev.origin );
			pActivator.pev.angles = pev.angles;
			pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
			@m_pCNPCWeapon = g_EntityFuncs.Create( sWeaponName, pActivator.pev.origin, g_vecZero, true );
			m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

			g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
			g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );

			SetUse( null );
			pev.effects |= EF_NODRAW;

			SetThink( ThinkFunction(this.RespawnThink) );
			pev.nextthink = g_Engine.time;
		}
	}

	void RespawnThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( m_pCNPCWeapon is null and m_flTimeToRespawn <= 0.0 )
			m_flTimeToRespawn = g_Engine.time +m_flRespawnTime;

		if( m_flTimeToRespawn > 0.0 and m_flTimeToRespawn <= g_Engine.time )
		{
			SetThink( null );
			SetUse( UseFunction(this.UseCNPC) );
			pev.effects &= ~EF_NODRAW;
			m_flTimeToRespawn = 0.0;

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_RESPAWN], VOL_NORM, 0.3, 0, 90 );
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_fassn::info_cnpc_fassn", "info_cnpc_fassn" );
	g_Game.PrecacheOther( "info_cnpc_fassn" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_fassn::cnpc_fassn", "cnpc_fassn" );
	g_Game.PrecacheOther( "cnpc_fassn" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_fassn::weapon_fassn", sWeaponName );
	g_ItemRegistry.RegisterWeapon( sWeaponName, "controlnpc" );
	g_Game.PrecacheOther( sWeaponName );
}

} //namespace cnpc_fassn END

/* FIXME
*/

/* TODO
*/