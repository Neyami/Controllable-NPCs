namespace cnpc_hgrunt
{

bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_hgrunt";
const string CNPC_MODEL				= "models/hgrunt.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 100.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the hgrunt itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (55.501198 * CNPC::flModelToGameSpeedModifier); //55.501198
const float SPEED_WALK_LIMP		= (47.042507 * CNPC::flModelToGameSpeedModifier); //47.042507
const float SPEED_RUN					= (140.424637 * CNPC::flModelToGameSpeedModifier); //140.424637
const float SPEED_RUN_LIMP			= (85.191559 * CNPC::flModelToGameSpeedModifier); //85.191559
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_MP5						= 0.1;
const float CD_SHOTGUN				= 0.3;
const float CD_M16						= 0.6;
const float CD_SNIPER					= 1.0;
const int AMMO_MAX						= 36; //MP5 & M16
const int AMMO_MAX_SHOTGUN		= 8;
const int AMMO_MAX_RPG				= 1;
const int AMMO_MAX_SNIPER			= 5;

const int SHOTGUN_PELLETS			= 7; //sk_hgrunt_pellets
const int SHOTGUN_DAMAGE			= 6; //sk_grunt_buckshot
const int MP5_DAMAGE					= 6; //sk_9mmAR_bullet
const int M16_DAMAGE					= 15; //sk_556_bullet
const int SNIPER_DAMAGE				= 40; //sk_massassin_sniper
const int RPG_DAMAGE					= 150; //sk_plr_rpg
const float RELOAD_TIME				= 1.0;

const float CD_MELEE						= 1.0;
const float MELEE_RANGE				= 70.0;
const float MELEE_DAMAGE			= 12.0;

const float CD_GRENADE_TOSS		= 1.0; //6.0
const float CD_GRENADE_LAUNCH	= 1.0; //6.0
const float CD_GRENADE_DROP		= 1.0; //6.0
const float GRENADE_THROW			= 500.0;
const float GRENADE_LAUNCH		= 800.0;

const array<string> pPainSounds = 
{
	"hgrunt/gr_pain1.wav",
	"hgrunt/gr_pain2.wav",
	"hgrunt/gr_pain3.wav",
	"hgrunt/gr_pain4.wav",
	"hgrunt/gr_pain5.wav"
};

const array<string> pDieSounds = 
{
	"hgrunt/gr_die1.wav",
	"hgrunt/gr_die2.wav",
	"hgrunt/gr_die3.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"weapons/hks1.wav",
	"weapons/hks2.wav",
	"weapons/hks3.wav",
	"weapons/sbarrel1.wav",
	"hgrunt/gr_mgun1.wav",
	"weapons/sniper_fire.wav",
	"weapons/glauncher.wav",
	"items/cliprelease1.wav",
	"items/clipinsert1.wav",
	"hgrunt/gr_reload1.wav",
	"weapons/reload1.wav",
	"weapons/reload3.wav",
	"weapons/sniper_reload_first_seq.wav",
	"weapons/sniper_bolt1.wav",
	"weapons/cbar_hitbod1.wav",
	"weapons/cbar_hitbod2.wav",
	"weapons/cbar_hitbod3.wav",
	"weapons/xbow_hitbod2.wav",
	"zombie/claw_miss2.wav"
};

enum sound_e
{
	SND_SHOOT_MP5_1 = 1,
	SND_SHOOT_MP5_2,
	SND_SHOOT_MP5_3,
	SND_SHOOT_SHOTGUN,
	SND_SHOOT_M16,
	SND_SHOOT_SNIPER,
	SND_SHOOT_GRENADE,
	SND_RELOAD1,
	SND_RELOAD2,
	SND_RELOAD_DONE,
	SND_RELOAD_SG1,
	SND_RELOAD_SG2,
	SND_RELOAD_SNIPER1,
	SND_RELOAD_SNIPER2,
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
	ANIM_GRENADE_LAUNCH = 9,
	ANIM_GRENADE_THROW,
	ANIM_IDLE_FIDGET,
	ANIM_IDLE,
	ANIM_IDLE_COMBAT,
	ANIM_MELEE,
	ANIM_CROUCH_IDLE,
	ANIM_CROUCH_SHOOT_M16 = 17,
	ANIM_SHOOT_M16,
	ANIM_CROUCH_SHOOT_MP5,
	ANIM_SHOOT_MP5,
	ANIM_RELOAD_MP5,
	ANIM_CROUCH_SHOOT_SHOTGUN,
	ANIM_SHOOT_SHOTGUN,
	ANIM_RELOAD_SHOTGUN,
	ANIM_GRENADE_DROP = 28,
	ANIM_WALK_LIMP,
	ANIM_RUN_LIMP,
	ANIM_STRAFE_LEFT = 33,
	ANIM_STRAFE_RIGHT,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_DEATH6,
	ANIM_IDLE_RPG = 88,
	ANIM_AIM_RPG,
	ANIM_SHOOT_RPG,
	ANIM_RELOAD_RPG,
	ANIM_CROUCH_SHOOT_SNIPER,
	ANIM_SHOOT_SNIPER,
	ANIM_RELOAD_SNIPER
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_RANGE,
	STATE_MELEE,
	STATE_GRENADE,
	STATE_RELOAD
};

/*
1  : "MP5"
3  : "MP5 + HG"
5  : "M16 + GL"
8  : "Shotgun"
10 : "Shotgun + HG"
64 : "Rocket Launcher"
66 : "Rocket Launcher + HG"
128 : "Sniper Rifle"
130 : "Sniper Rifle + HG"
*/
enum weapons_e
{
	HGRUNT_MP5 = (1 << 0), //1
	HGRUNT_HANDGRENADE = (1 << 1), //2
	HGRUNT_M16 = (1 << 2), //4
	HGRUNT_SHOTGUN = (1 << 3), //8
	HGRUNT_RPG = (1 << 6), //64
	HGRUNT_SNIPER = (1 << 7) //128
};

const int HEAD_GROUP = 1;

const int HEAD_GASMASK = 0;
const int HEAD_BERET = 1;
const int HEAD_OPSMASK = 2;
const int HEAD_M203 = 3;
const int HEAD_HELMET = 4;

const int GUN_GROUP = 2;

const int GUN_M16 = 0;
const int GUN_SHOTGUN = 1;
const int GUN_NONE = 2;
const int GUN_RPG = 3;
const int GUN_MP5 = 4;
const int GUN_SNIPER = 5;

class weapon_hgrunt : CBaseDriveWeapon
{
	int m_iVoicePitch;

	private int m_iShell, m_iShotgunShell;
	private int m_iWeaponStage;

	private bool m_bGrenadeUsed;
	private float m_flNextGrenade;

	private bool m_bSpotActive;
	protected EHandle m_hSpot;
	protected CBaseEntity@ m_pSpot
	{
		get const { return cast<CBaseEntity@>(m_hSpot.GetEntity()); }
		set { m_hSpot = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		CNPC::g_flTalkWaitTime = 0.0;
		m_iWeaponStage = 0;
		m_bGrenadeUsed = false;
		m_flNextGrenade = 0.0;
		m_bSpotActive = false;

		if( Math.RandomLong(0, 1) == 1 )
			m_iVoicePitch = 109 + Math.RandomLong(0, 7);
		else
			m_iVoicePitch = 100;

		if( pev.weapons == 0 )
		{
			// initialize to original values
			pev.weapons = HGRUNT_MP5 | HGRUNT_HANDGRENADE;
		}

		if( (pev.weapons & HGRUNT_SHOTGUN) != 0 )
			m_iMaxAmmo = AMMO_MAX_SHOTGUN;
		else if( (pev.weapons & HGRUNT_RPG) != 0 )
			m_iMaxAmmo = AMMO_MAX_RPG;
		else if( (pev.weapons & HGRUNT_SNIPER) != 0 )
			m_iMaxAmmo = AMMO_MAX_SNIPER;
		else
			m_iMaxAmmo = AMMO_MAX;

		self.m_iDefaultAmmo = m_iMaxAmmo;
		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );
		m_iShotgunShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_hgrunt.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_hgrunt.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_hgrunt_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= m_iMaxAmmo;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::HGRUNT_SLOT - 1;
		info.iPosition			= CNPC::HGRUNT_POSITION - 1;
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

		m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_iMaxAmmo);

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

		if( m_pSpot !is null )
			g_EntityFuncs.Remove( m_pSpot );

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
				if( m_iState != STATE_MELEE and m_iState != STATE_GRENADE and m_iState != STATE_RELOAD )
				{
					if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
					{
						DoIdleAnimation( true );
						self.m_flNextPrimaryAttack = g_Engine.time + 0.3;
						return;
					}

					m_iState = STATE_RANGE;
					m_pPlayer.SetMaxSpeedOverride( 0 );

					if( (pev.weapons & HGRUNT_MP5) != 0 and (pev.weapons & HGRUNT_M16) == 0 )
					{
						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_MP5 );
						else
							SetAnim( ANIM_CROUCH_SHOOT_MP5 );

						Shoot( HGRUNT_MP5 );
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_SHOOT_MP5_1, SND_SHOOT_MP5_3)], VOL_NORM, ATTN_NORM );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 384, 0.3, m_pPlayer ); 

						flTime = CD_MP5;
					}
					else if( (pev.weapons & HGRUNT_SHOTGUN) != 0 )
					{
						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_SHOTGUN );
						else
							SetAnim( ANIM_CROUCH_SHOOT_SHOTGUN );

						Shoot( HGRUNT_SHOTGUN );
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_SHOTGUN], VOL_NORM, ATTN_NORM );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 384, 0.3, m_pPlayer ); 

						flTime = CD_SHOTGUN;
					}
					else if( (pev.weapons & HGRUNT_M16) != 0 )
					{
						m_iWeaponStage = 0;

						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_M16 );
						else
							SetAnim( ANIM_CROUCH_SHOOT_M16 );

						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 384, 0.3, m_pPlayer ); 

						SetThink( ThinkFunction(this.M16Think) );
						pev.nextthink = g_Engine.time;

						flTime = CD_M16;
					}
					else if( (pev.weapons & HGRUNT_SNIPER) != 0 )
					{
						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_SNIPER );
						else
							SetAnim( ANIM_CROUCH_SHOOT_SNIPER );

						Shoot( HGRUNT_SNIPER );
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_SNIPER], VOL_NORM, ATTN_NORM );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 384, 0.3, m_pPlayer ); 

						flTime = CD_SNIPER;
					}
					else if( (pev.weapons & HGRUNT_RPG) != 0 )
					{
						SetAnim( ANIM_SHOOT_RPG );
						Shoot( HGRUNT_RPG );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0, m_pPlayer ); 

						flTime = 1.0; //irrelevant due to the clipsize of 1
					}
				}
			}
			else
			{
				if( m_iState != STATE_RANGE and m_iState != STATE_GRENADE and m_iState != STATE_RELOAD )
				{
					m_iState = STATE_MELEE;
					m_pPlayer.SetMaxSpeedOverride( 0 );

					SetAnim( ANIM_MELEE );

					SetThink( ThinkFunction(this.MeleeAttackThink) );
					pev.nextthink = g_Engine.time + 0.3;

					flTime = CD_MELEE;
				}
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + flTime;
	}

	void M16Think()
	{
		if( m_pDriveEnt is null or m_iState != STATE_RANGE )
		{
			SetThink( null );
			return;
		}

		switch( GetFrame(13) )
		{
			case 0: { if( m_iWeaponStage == 0 ) { Shoot( HGRUNT_M16 ); g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_M16], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
			case 2: { if( m_iWeaponStage == 1 ) { Shoot( HGRUNT_M16 ); m_iWeaponStage++; } break; }
			case 4: { if( m_iWeaponStage == 2 ) { Shoot( HGRUNT_M16 ); m_iWeaponStage++; } break; }
			case 12: { if( m_iWeaponStage == 3 ) { DoIdleAnimation(); SetThink( null ); } break; }
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Shoot( int iWeapon )
	{
		Vector vecShootOrigin, vecShootDir;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		vecShootOrigin = m_pDriveEnt.pev.origin + Vector(0, 0, 60);
		vecShootDir = g_Engine.v_forward;

		switch( iWeapon )
		{
			case HGRUNT_MP5:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
				m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_10DEGREES, 2048.0, BULLET_MONSTER_MP5, 0, MP5_DAMAGE, m_pPlayer.pev );

				break;
			}

			case HGRUNT_SHOTGUN:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShotgunShell, TE_BOUNCE_SHOTSHELL );
				m_pDriveEnt.FireBullets( SHOTGUN_PELLETS, vecShootOrigin, vecShootDir, VECTOR_CONE_15DEGREES, 2048.0, BULLET_PLAYER_BUCKSHOT, 0, SHOTGUN_DAMAGE, m_pPlayer.pev );

				break;
			}

			case HGRUNT_M16:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
				m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_10DEGREES, 2048.0, BULLET_MONSTER_SAW, 0, M16_DAMAGE, m_pPlayer.pev );

				break;
			}

			case HGRUNT_SNIPER:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
				m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_2DEGREES, 2048.0, BULLET_MONSTER_SAW, 0, SNIPER_DAMAGE, m_pPlayer.pev );

				break;
			}

			case HGRUNT_RPG:
			{
				m_pDriveEnt.GetAttachment( 0, vecShootOrigin, void );
				CBaseEntity@ pRocket = g_EntityFuncs.CreateRPGRocket( vecShootOrigin, m_pPlayer.pev.v_angle, m_pPlayer.edict() );
				pRocket.pev.dmg = RPG_DAMAGE;
				pRocket.pev.nextthink = g_Engine.time; //forces the rocket to launch immediately

				break;
			}
		}

		m_pDriveEnt.pev.effects |= EF_MUZZLEFLASH;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

		Vector angDir = Math.VecToAngles( vecShootDir );
		m_pDriveEnt.SetBlending( 0, angDir.x );
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState == STATE_RELOAD or m_iState == STATE_GRENADE ) return;

			if( m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT and m_pDriveEnt.pev.sequence != ANIM_CROUCH_IDLE and (m_pPlayer.pev.button & IN_ATTACK) == 0 )
			{
				m_iState = STATE_RANGE;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				if( (pev.weapons & HGRUNT_RPG) != 0 )
				{
					SetAnim( ANIM_AIM_RPG );
					self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
				}
				else
				{
					if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
						SetAnim( ANIM_IDLE_COMBAT );
				}
			}
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
	}

	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
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

		SetThink( null );
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
			cnpc_hgrunt@ pDriveEnt = cast<cnpc_hgrunt@>(CastToScriptClass(m_pDriveEnt));
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
			DoRPGAiming();
			CheckGrenadeInput();
			DoGrenade();
			UpdateSpot();
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

				m_pDriveEnt.pev.framerate = 1.7; //the walking animation is too slow
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
		if( !bOverrideState )
		{
			if( m_iState == STATE_RANGE and (m_pPlayer.pev.button & IN_ATTACK != 0 or !m_pDriveEnt.m_fSequenceFinished) ) return;
			if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_RELOAD and (m_pDriveEnt.pev.sequence == ANIM_RELOAD_MP5 or m_pDriveEnt.pev.sequence == ANIM_RELOAD_RPG or m_pDriveEnt.pev.sequence == ANIM_RELOAD_SHOTGUN or m_pDriveEnt.pev.sequence == ANIM_RELOAD_SNIPER) and !m_pDriveEnt.m_fSequenceFinished ) return; //reduce this line somehow??
			if( m_iState == STATE_IDLE and (m_pPlayer.pev.button & IN_ATTACK2) == 0 and (m_pPlayer.pev.oldbuttons & IN_ATTACK2) != 0 ) SetAnim( ANIM_IDLE );
			if( m_iState == STATE_GRENADE and (m_pDriveEnt.pev.sequence == ANIM_GRENADE_LAUNCH or m_pDriveEnt.pev.sequence == ANIM_GRENADE_THROW or m_pDriveEnt.pev.sequence == ANIM_GRENADE_DROP) and !m_pDriveEnt.m_fSequenceFinished ) return;
		}

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE or bOverrideState )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;

				if( (pev.weapons & HGRUNT_RPG) == 0 )
				{
					if( (m_pPlayer.pev.button & IN_ATTACK2) != 0 and (m_pPlayer.pev.button & IN_DUCK) == 0 )
						SetAnim( ANIM_IDLE_COMBAT );
					else
					{
						if( (m_pPlayer.pev.button & IN_DUCK) != 0 )
							SetAnim( ANIM_CROUCH_IDLE );
						else
							SetAnim( ANIM_IDLE );
					}
				}
				else
					SetAnim( ANIM_IDLE_RPG );
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS and m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT and (pev.weapons & HGRUNT_RPG) == 0 )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	// from hgrunt.cpp
	void IdleSound()
	{
		if( CNPC::g_flTalkWaitTime > g_Engine.time ) return;

		if( CNPC::g_iGruntQuestion != 0 or Math.RandomLong(0, 1) == 1 )
		{
			if( CNPC::g_iGruntQuestion == 0 )
			{
				// ask question or make statement
				switch( Math.RandomLong(0, 2) )
				{
					 // check in
					case 0: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_CHECK", 0.35, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iGruntQuestion = 1; break; }

					// question
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_QUEST", 0.35, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iGruntQuestion = 2; break; }

					// statement
					case 2: {g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_IDLE", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break; }
				}
			}
			else
			{
				switch( CNPC::g_iGruntQuestion )
				{
					// check in
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_CLEAR", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break; }

					// question
					case 2: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "HG_ANSWER", 0.35, ATTN_NORM, 0, m_iVoicePitch ); break;}
				}

				CNPC::g_iGruntQuestion = 0;
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
		else if( (m_pPlayer.pev.oldbuttons & IN_DUCK) != 0 )
		{
			if( m_iState == STATE_IDLE and m_pDriveEnt.pev.sequence != ANIM_IDLE and m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT )
				DoIdleAnimation( true );
		}
	}

	void DoReload()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState >= STATE_GRENADE or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) >= m_iMaxAmmo or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 and (m_pPlayer.pev.button & IN_ATTACK2) == 0 )
		{
			m_iState = STATE_RELOAD;
			m_iWeaponStage = 0;

			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( (pev.weapons & (HGRUNT_MP5|HGRUNT_M16)) != 0 )
				SetAnim( ANIM_RELOAD_MP5 );
			else if( (pev.weapons & HGRUNT_SHOTGUN) != 0 )
				SetAnim( ANIM_RELOAD_SHOTGUN );
			else if( (pev.weapons & HGRUNT_RPG) != 0 )
				SetAnim( ANIM_RELOAD_RPG );
			else if( (pev.weapons & HGRUNT_SNIPER) != 0 )
				SetAnim( ANIM_RELOAD_SNIPER );

			SetThink( ThinkFunction(this.ReloadThink) );
			pev.nextthink = g_Engine.time;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (RELOAD_TIME + 0.1);
		}
	}

	void ReloadThink()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState != STATE_RELOAD ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_RELOAD_MP5 and m_pDriveEnt.pev.sequence != ANIM_RELOAD_RPG and m_pDriveEnt.pev.sequence != ANIM_RELOAD_SHOTGUN and m_pDriveEnt.pev.sequence != ANIM_RELOAD_SNIPER ) return;

		if( m_pDriveEnt.pev.sequence == ANIM_RELOAD_MP5 )
		{
			switch( GetFrame(61) )
			{
				case 11: { if( m_iWeaponStage == 0 ) { g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD1], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
				case 39: { if( m_iWeaponStage == 1 ) { g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD2], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
				case 41:
				{
					if( m_iWeaponStage == 2 )
					{
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_RELOAD_DONE], VOL_NORM, ATTN_NORM );
						m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_iMaxAmmo);
						DoIdleAnimation();
						SetThink( null );
					}

					break;
				}
			}
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_RELOAD_SHOTGUN )
		{
			switch( GetFrame(61) )
			{
				case 11: { if( m_iWeaponStage == 0 ) { g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD_SG1], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
				case 29: { if( m_iWeaponStage == 1 ) { g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD_SG2], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
				case 39: { if( m_iWeaponStage == 2 ) { g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD_SG1], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
				case 41:
				{
					if( m_iWeaponStage == 3 )
					{
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_RELOAD_DONE], VOL_NORM, ATTN_NORM );
						m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_iMaxAmmo);
						DoIdleAnimation();
						SetThink( null );
					}

					break;
				}
			}
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_RELOAD_RPG )
		{
			switch( GetFrame(61) )
			{
				case 60:
				{
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_RELOAD_DONE], VOL_NORM, ATTN_NORM );
					m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_iMaxAmmo);
					DoIdleAnimation();
					SetThink( null );

					break;
				}
			}
		}
		else if( m_pDriveEnt.pev.sequence == ANIM_RELOAD_SNIPER )
		{
			switch( GetFrame(61) )
			{
				case 0: { if( m_iWeaponStage == 0 ) { g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD_SNIPER1], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
				case 55:
				{
					if( m_iWeaponStage == 1 )
					{
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_ITEM, arrsCNPCSounds[SND_RELOAD_SNIPER2], VOL_NORM, ATTN_NORM );
						m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, m_iMaxAmmo);
						DoIdleAnimation();
						SetThink( null );
					}

					break;
				}
			}
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoRPGAiming()
	{
		if( m_pDriveEnt is null ) return;
		if( m_pDriveEnt.pev.sequence != ANIM_AIM_RPG ) return;

		Vector angDir = Math.VecToAngles( m_pPlayer.pev.v_angle );
		m_pDriveEnt.SetBlending( 0, angDir.x );
	}

	void CheckGrenadeInput()
	{
		if( m_pDriveEnt is null ) return;
		if( (pev.weapons & (HGRUNT_HANDGRENADE|HGRUNT_M16)) == 0 ) return;
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState > STATE_RANGE ) return;
		if( m_flNextGrenade > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 and (m_pPlayer.pev.button & IN_ATTACK2) != 0)
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iState = STATE_GRENADE;

			if( (pev.weapons & HGRUNT_HANDGRENADE) != 0 )
			{
				if( m_pPlayer.pev.v_angle.x >= 60 )
				{
					SetAnim( ANIM_GRENADE_DROP );
					m_flNextGrenade = g_Engine.time + CD_GRENADE_DROP;
				}
				else
				{
					SetAnim( ANIM_GRENADE_THROW );
					m_flNextGrenade = g_Engine.time + CD_GRENADE_TOSS;
				}
			}
			else if( (pev.weapons & HGRUNT_M16) != 0 )
			{
				SetAnim( ANIM_GRENADE_LAUNCH );
				m_flNextGrenade = g_Engine.time + CD_GRENADE_LAUNCH;
			}
		}
	}

	void DoGrenade()
	{
		if( m_pDriveEnt is null ) return;
		if( m_iState != STATE_GRENADE or (m_pDriveEnt.pev.sequence != ANIM_GRENADE_LAUNCH and m_pDriveEnt.pev.sequence != ANIM_GRENADE_THROW and m_pDriveEnt.pev.sequence != ANIM_GRENADE_DROP) ) return;

		switch( m_pDriveEnt.pev.sequence )
		{
			case ANIM_GRENADE_THROW:
			{
				if( GetFrame(56) == 34 and !m_bGrenadeUsed )
				{
					Math.MakeVectors( m_pPlayer.pev.v_angle );
					Vector vecGrenadeVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * GRENADE_THROW;

					g_EntityFuncs.ShootTimed( m_pPlayer.pev, m_pDriveEnt.pev.origin + g_Engine.v_forward * 34 + Vector (0, 0, 32), vecGrenadeVelocity, 3.5 );

					m_bGrenadeUsed = true;
				}
				else if( GetFrame(56) > 50 and m_bGrenadeUsed )
					m_bGrenadeUsed = false;

				break;
			}

			case ANIM_GRENADE_DROP:
			{
				if( GetFrame(56) == 31 and !m_bGrenadeUsed )
				{
					Math.MakeVectors( m_pDriveEnt.pev.angles );
					g_EntityFuncs.ShootTimed( m_pPlayer.pev, m_pDriveEnt.pev.origin + g_Engine.v_forward * 17 - g_Engine.v_right * 27 + g_Engine.v_up * 6, g_vecZero, 3 );

					m_bGrenadeUsed = true;
				}
				else if( GetFrame(56) > 50 and m_bGrenadeUsed )
					m_bGrenadeUsed = false;

				break;
			}

			case ANIM_GRENADE_LAUNCH:
			{
				if( GetFrame(46) == 24 and !m_bGrenadeUsed )
				{
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_GRENADE], 0.8, ATTN_NORM );

					Math.MakeVectors( m_pPlayer.pev.v_angle );

					Vector vecGrenadeOrigin;
					Vector vecGrenadeVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * GRENADE_LAUNCH;
					m_pDriveEnt.GetAttachment( 0, vecGrenadeOrigin, void );
					g_EntityFuncs.ShootContact( m_pPlayer.pev, vecGrenadeOrigin, vecGrenadeVelocity ); 

					m_bGrenadeUsed = true;
				}
				else if( GetFrame(46) > 40 and m_bGrenadeUsed )
					m_bGrenadeUsed = false;

				break;
			}
		}
	}

	void UpdateSpot()
	{
		if( m_pDriveEnt is null ) return;
		if( (pev.weapons & HGRUNT_RPG) == 0 ) return;

		if( (m_pPlayer.pev.button & IN_ATTACK2) != 0 )
		{
			if( m_pSpot is null )
				@m_pSpot = g_EntityFuncs.Create( "rpg_laser_spot", m_pPlayer.pev.origin, g_vecZero, false, m_pPlayer.edict() );

			Math.MakeVectors( m_pPlayer.pev.v_angle );
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecAiming = g_Engine.v_forward;

			TraceResult tr;
			g_Utility.TraceLine( vecSrc, vecSrc + vecAiming * 8192, dont_ignore_monsters, m_pPlayer.edict(), tr );

			g_EntityFuncs.SetOrigin( m_pSpot, tr.vecEndPos );
		}
		else
		{
			if( m_pSpot !is null )
				g_EntityFuncs.Remove( m_pSpot );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_hgrunt", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		m_pDriveEnt.pev.set_controller( 0,  127 );

		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "body", "" + pev.body );
		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "skin", "" + pev.skin );
		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_HGRUNT );
	}

	void DoFirstPersonView()
	{
		cnpc_hgrunt@ pDriveEnt = cast<cnpc_hgrunt@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_hgrunt_rend_" + m_pPlayer.entindex();
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

class cnpc_hgrunt : ScriptBaseAnimating
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

		if( (pev.weapons & HGRUNT_RPG) == 0 )
			pev.sequence = ANIM_IDLE;
		else
			pev.sequence = ANIM_IDLE_RPG;

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
		else if( (m_pOwner.pev.button & IN_ATTACK2) != 0 )
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

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_IDLE );

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

final class info_cnpc_hgrunt : CNPCSpawnEntity
{
	private int m_iHead;

	info_cnpc_hgrunt()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}
		else if( szKey == "head" )
		{
			m_iHead = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void DoSpecificStuff()
	{
		if( (pev.weapons & HGRUNT_RPG) == 0 )
			pev.sequence = ANIM_IDLE;
		else
			pev.sequence = ANIM_IDLE_RPG;

		pev.set_controller( 0,  127 );

		if( Math.RandomLong(0, 99) < 80 )
			pev.skin = 0; //light skin
		else
			pev.skin = 1; //dark skin

		if( (pev.weapons & HGRUNT_MP5) != 0 and (pev.weapons & HGRUNT_M16) == 0 )
		{
			if( Math.RandomLong(0, 1) == 1 )
				self.SetBodygroup( HEAD_GROUP, HEAD_GASMASK );
			else
				self.SetBodygroup( HEAD_GROUP, HEAD_BERET );

			self.SetBodygroup( GUN_GROUP, GUN_MP5 );
		}
		else if( (pev.weapons & HGRUNT_SHOTGUN) != 0 )
		{
			if( Math.RandomLong(0, 1) == 1 )
				self.SetBodygroup( HEAD_GROUP, HEAD_OPSMASK );
			else
				self.SetBodygroup( HEAD_GROUP, HEAD_BERET );

			self.SetBodygroup( GUN_GROUP, GUN_SHOTGUN );
		}
		else if( (pev.weapons & HGRUNT_M16) != 0 )
		{
			if( Math.RandomLong(0, 1) == 1 )
			{
				self.SetBodygroup( HEAD_GROUP, HEAD_M203 );
				self.pev.skin = 1; // alway dark skin
			}
			else
				self.SetBodygroup( HEAD_GROUP, HEAD_BERET );

			self.SetBodygroup( GUN_GROUP, GUN_M16 );
		}
		else if( (pev.weapons & HGRUNT_RPG) != 0 )
		{
			if( Math.RandomLong(0, 1) == 1 )
				self.SetBodygroup( HEAD_GROUP, HEAD_HELMET );
			else
				self.SetBodygroup( HEAD_GROUP, HEAD_BERET );

			self.SetBodygroup( GUN_GROUP, GUN_RPG );
		}
		else if( (pev.weapons & HGRUNT_SNIPER) != 0 )
		{
			if( Math.RandomLong(0, 1) == 1 )
				self.SetBodygroup( HEAD_GROUP, HEAD_HELMET );
			else
				self.SetBodygroup( HEAD_GROUP, HEAD_BERET );

			self.SetBodygroup( GUN_GROUP, GUN_SNIPER );
		}

		switch( m_iHead )
		{
			case 0: self.SetBodygroup( HEAD_GROUP, HEAD_GASMASK ); break;
			case 1: self.SetBodygroup( HEAD_GROUP, HEAD_BERET ); break;
			case 2: self.SetBodygroup( HEAD_GROUP, HEAD_OPSMASK ); break;
			case 3: self.SetBodygroup( HEAD_GROUP, HEAD_M203 ); break;
			case 4: self.SetBodygroup( HEAD_GROUP, HEAD_HELMET ); break;
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hgrunt::info_cnpc_hgrunt", "info_cnpc_hgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hgrunt::cnpc_hgrunt", "cnpc_hgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_hgrunt::weapon_hgrunt", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "hgruntammo" );

	g_Game.PrecacheOther( "info_cnpc_hgrunt" );
	g_Game.PrecacheOther( "cnpc_hgrunt" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_hgrunt END

/* FIXME
*/

/* TODO
*/