namespace cnpc_rgrunt
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_rgrunt";
const string CNPC_MODEL				= "models/rgrunt.mdl";
const string MODEL_MP5				= "models/v_9mmar.mdl";
const string MODEL_M16				= "models/v_m16a2.mdl";
const string MODEL_SHOTGUN		= "models/v_shotgun.mdl";
const string MODEL_RPG				= "models/v_rpg.mdl";
const string MODEL_SNIPER			= "models/v_m40a1.mdl";
const string MODEL_GRENADE		= "models/v_grenade.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 100.0;
const float CNPC_LOWHEALTH			= 20.0; //when to trigger low-health mode
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the rgrunt itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (55.501198 * CNPC::flModelToGameSpeedModifier); //55.501198
const float SPEED_RUN					= (140.424637 * CNPC::flModelToGameSpeedModifier); //140.424637
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

const float CD_GRENADE_TOSS		= 6.0;
const float CD_GRENADE_LAUNCH	= 6.0;
const float CD_GRENADE_DROP		= 6.0;
const float GRENADE_THROW			= 500.0;
const float GRENADE_LAUNCH		= 800.0;

const float DMG_SHOCKTOUCH		= 100.0;

const string SMOKE_SPRITE			= "sprites/steam1.spr";
const float EXPLODE_DAMAGE			= 100.0;
const string GIB_MODEL1				= "models/computergibs.mdl";
const string GIB_MODEL2				= "models/chromegibs.mdl";

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
	"zombie/claw_miss2.wav",
	"turret/tu_die.wav",
	"turret/tu_die2.wav",
	"buttons/spark5.wav",
	"buttons/spark6.wav",
	"debris/beamstart14.wav",
	"debris/metal6.wav"
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
	SND_KICKMISS,
	SND_DEATH1,
	SND_DEATH2,
	SND_SPARK1,
	SND_SPARK2,
	SND_SHOCK,
	SND_REPAIR
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
	RGRUNT_MP5 = (1 << 0), //1
	RGRUNT_HANDGRENADE = (1 << 1), //2
	RGRUNT_M16 = (1 << 2), //4
	RGRUNT_SHOTGUN = (1 << 3), //8
	RGRUNT_RPG = (1 << 6), //64
	RGRUNT_SNIPER = (1 << 7) //128
};

enum animtypes_e
{
	WANIM_DRAW = 0,
	WANIM_SHOOT,
	WANIM_LAUNCH,
	WANIM_RELOAD
};

const int GUN_GROUP = 2;

const int GUN_M16 = 0;
const int GUN_SHOTGUN = 1;
const int GUN_NONE = 2;
const int GUN_RPG = 3;
const int GUN_MP5 = 4;
const int GUN_SNIPER = 5;

class weapon_rgrunt : CBaseDriveWeapon
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

	private float m_flNextThink; //for stuff that shouldn't run every frame

	bool m_bShockTouch;
	private float m_flNextShockTouch;
	private float m_flNextSpark;
	private bool m_bDoubleSpark;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		CNPC::g_flTalkWaitTime = 0.0;
		m_iWeaponStage = 0;
		m_bGrenadeUsed = false;
		m_flNextGrenade = 0.0;
		m_bSpotActive = false;
		m_bShockTouch = false;
		m_flNextShockTouch = g_Engine.time;
		m_flNextSpark = g_Engine.time + 1.0;
		m_bDoubleSpark = false;

		m_iVoicePitch = 120;

		if( pev.weapons == 0 )
			pev.weapons = RGRUNT_MP5 | RGRUNT_HANDGRENADE;

		if( (pev.weapons & RGRUNT_SHOTGUN) != 0 )
			m_iMaxAmmo = AMMO_MAX_SHOTGUN;
		else if( (pev.weapons & RGRUNT_RPG) != 0 )
			m_iMaxAmmo = AMMO_MAX_RPG;
		else if( (pev.weapons & RGRUNT_SNIPER) != 0 )
			m_iMaxAmmo = AMMO_MAX_SNIPER;
		else
			m_iMaxAmmo = AMMO_MAX;

		self.m_iDefaultAmmo = m_iMaxAmmo;
		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( SMOKE_SPRITE );
		g_Game.PrecacheModel( GIB_MODEL1 );
		g_Game.PrecacheModel( GIB_MODEL2 );
		g_Game.PrecacheModel( MODEL_MP5 );
		g_Game.PrecacheModel( MODEL_M16 );
		g_Game.PrecacheModel( MODEL_SHOTGUN );
		g_Game.PrecacheModel( MODEL_RPG );
		g_Game.PrecacheModel( MODEL_SNIPER );
		g_Game.PrecacheModel( MODEL_GRENADE );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );
		m_iShotgunShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_rgrunt.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_rgrunt.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_rgrunt_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= m_iMaxAmmo;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::RGRUNT_SLOT - 1;
		info.iPosition			= CNPC::RGRUNT_POSITION - 1;
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

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_iMaxAmmo );

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

		return self.DefaultDeploy( self.GetV_Model(GetWeaponModel()), "", GetWeaponAnim(WANIM_DRAW), "" );
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

					if( (pev.weapons & RGRUNT_MP5) != 0 and (pev.weapons & RGRUNT_M16) == 0 )
					{
						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_MP5 );
						else
							SetAnim( ANIM_CROUCH_SHOOT_MP5 );

						Shoot( RGRUNT_MP5 );
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_SHOOT_MP5_1, SND_SHOOT_MP5_3)], VOL_NORM, ATTN_NORM );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 1024, 0.3, m_pPlayer ); 

						flTime = CD_MP5;
					}
					else if( (pev.weapons & RGRUNT_SHOTGUN) != 0 )
					{
						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_SHOTGUN );
						else
							SetAnim( ANIM_CROUCH_SHOOT_SHOTGUN );

						Shoot( RGRUNT_SHOTGUN );
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_SHOTGUN], VOL_NORM, ATTN_NORM );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 1024, 0.3, m_pPlayer ); 

						flTime = CD_SHOTGUN;
					}
					else if( (pev.weapons & RGRUNT_M16) != 0 )
					{
						m_iWeaponStage = 0;

						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_M16 );
						else
							SetAnim( ANIM_CROUCH_SHOOT_M16 );

						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 1024, 0.3, m_pPlayer ); 

						SetThink( ThinkFunction(this.M16Think) );
						pev.nextthink = g_Engine.time;

						flTime = CD_M16;
					}
					else if( (pev.weapons & RGRUNT_SNIPER) != 0 )
					{
						if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
							SetAnim( ANIM_SHOOT_SNIPER );
						else
							SetAnim( ANIM_CROUCH_SHOOT_SNIPER );

						Shoot( RGRUNT_SNIPER );
						g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_SNIPER], VOL_NORM, ATTN_NORM );
						GetSoundEntInstance().InsertSound ( bits_SOUND_COMBAT, m_pDriveEnt.pev.origin, 1024, 0.3, m_pPlayer ); 

						flTime = CD_SNIPER;
					}
					else if( (pev.weapons & RGRUNT_RPG) != 0 )
					{
						SetAnim( ANIM_SHOOT_RPG );
						Shoot( RGRUNT_RPG );
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
			case 0: { if( m_iWeaponStage == 0 ) { Shoot( RGRUNT_M16 ); g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_SHOOT_M16], VOL_NORM, ATTN_NORM ); m_iWeaponStage++; } break; }
			case 2: { if( m_iWeaponStage == 1 ) { Shoot( RGRUNT_M16 ); m_iWeaponStage++; } break; }
			case 4: { if( m_iWeaponStage == 2 ) { Shoot( RGRUNT_M16 ); m_iWeaponStage++; } break; }
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
			case RGRUNT_MP5:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24 + g_Engine.v_right * 8, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
				m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_10DEGREES, 2048.0, BULLET_MONSTER_MP5, 0, MP5_DAMAGE, m_pPlayer.pev );

				break;
			}

			case RGRUNT_SHOTGUN:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24 + g_Engine.v_right * 8, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShotgunShell, TE_BOUNCE_SHOTSHELL );
				m_pDriveEnt.FireBullets( SHOTGUN_PELLETS, vecShootOrigin, vecShootDir, VECTOR_CONE_15DEGREES, 2048.0, BULLET_PLAYER_BUCKSHOT, 0, SHOTGUN_DAMAGE, m_pPlayer.pev );

				break;
			}

			case RGRUNT_M16:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24 + g_Engine.v_right * 8, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
				m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_10DEGREES, 2048.0, BULLET_MONSTER_SAW, 0, M16_DAMAGE, m_pPlayer.pev );

				break;
			}

			case RGRUNT_SNIPER:
			{
				Vector vecShellVelocity = g_Engine.v_right * Math.RandomFloat(40, 90) + g_Engine.v_up * Math.RandomFloat(75, 200) + g_Engine.v_forward * Math.RandomFloat(-40, 40);
				g_EntityFuncs.EjectBrass( vecShootOrigin + vecShootDir * 24 + g_Engine.v_right * 8, vecShellVelocity, m_pDriveEnt.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );
				m_pDriveEnt.FireBullets( 1, vecShootOrigin, vecShootDir, VECTOR_CONE_2DEGREES, 2048.0, BULLET_MONSTER_SAW, 0, SNIPER_DAMAGE, m_pPlayer.pev );

				break;
			}

			case RGRUNT_RPG:
			{
				m_pDriveEnt.GetAttachment( 0, vecShootOrigin, void );
				CBaseEntity@ pRocket = g_EntityFuncs.CreateRPGRocket( vecShootOrigin, m_pPlayer.pev.v_angle, m_pPlayer.edict() );
				pRocket.pev.dmg = RPG_DAMAGE;
				pRocket.pev.nextthink = g_Engine.time; //forces the rocket to launch immediately

				break;
			}
		}

		if( CNPC_FIRSTPERSON )
			self.SendWeaponAnim( GetWeaponAnim(WANIM_SHOOT) );

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

				if( (pev.weapons & RGRUNT_RPG) != 0 )
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
			if( (pHurt.pev.FlagBitSet(FL_MONSTER) and pHurt.GetClassname() != "monster_alien_voltigore" and pHurt.GetClassname() != "monster_gargantua" and pHurt.GetClassname() != "monster_bigmomma") or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 45.0;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 300.0 + g_Engine.v_up * 50.0;
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
			m_pPlayer.pev.viewmodel = GetWeaponModel();
			self.SendWeaponAnim( GetWeaponAnim(WANIM_DRAW) );
		}
		else
		{
			cnpc_rgrunt@ pDriveEnt = cast<cnpc_rgrunt@>(CastToScriptClass(m_pDriveEnt));
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

			if( m_flNextThink <= g_Engine.time )
			{
				LowHealth();
				DoShockTouch();
				m_flNextThink = g_Engine.time + 0.1;
			}
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
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				SetAnim( ANIM_WALK );
			}

			m_pDriveEnt.pev.framerate = 1.7; //the walking animation is too slow
		}
		else
		{
			if( m_iState != STATE_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
		}
	}

	void DoIdleAnimation( bool bOverrideState = false )
	{
		if( m_pDriveEnt is null ) return;

		if( !bOverrideState )
		{
			if( m_iState == STATE_RANGE and (m_pPlayer.pev.button & IN_ATTACK != 0 or !m_pDriveEnt.m_fSequenceFinished) ) return;
			if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_RELOAD and InReloadAnimation() and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( m_iState == STATE_IDLE and (m_pPlayer.pev.button & IN_ATTACK2) == 0 and (m_pPlayer.pev.oldbuttons & IN_ATTACK2) != 0 ) SetAnim( ANIM_IDLE );
			if( m_iState == STATE_GRENADE and InGrenadeAnimation() and !m_pDriveEnt.m_fSequenceFinished ) return;
		}

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE or bOverrideState )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;

				if( (pev.weapons & RGRUNT_RPG) == 0 )
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

			if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS and m_pDriveEnt.pev.sequence != ANIM_IDLE_COMBAT and (pev.weapons & RGRUNT_RPG) == 0 )
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

		if( CNPC::g_iRobotGruntQuestion != 0 or Math.RandomLong(0, 1) == 1 )
		{
			if( CNPC::g_iRobotGruntQuestion == 0 )
			{
				switch( Math.RandomLong(0, 2) )
				{
					case 0: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_CHECK", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iRobotGruntQuestion = 1; break; }
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_QUEST", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); CNPC::g_iRobotGruntQuestion = 2; break; }
					case 2: {g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_IDLE", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); break; }
				}
			}
			else
			{
				switch( CNPC::g_iRobotGruntQuestion )
				{
					case 1: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_CLEAR", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); break; }
					case 2: { g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_ANSWER", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch ); break;}
				}

				CNPC::g_iRobotGruntQuestion = 0;
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

			if( (pev.weapons & (RGRUNT_MP5|RGRUNT_M16)) != 0 )
				SetAnim( ANIM_RELOAD_MP5 );
			else if( (pev.weapons & RGRUNT_SHOTGUN) != 0 )
				SetAnim( ANIM_RELOAD_SHOTGUN );
			else if( (pev.weapons & RGRUNT_RPG) != 0 )
				SetAnim( ANIM_RELOAD_RPG );
			else if( (pev.weapons & RGRUNT_SNIPER) != 0 )
				SetAnim( ANIM_RELOAD_SNIPER );

			if( CNPC_FIRSTPERSON )
				self.SendWeaponAnim( GetWeaponAnim(WANIM_RELOAD) );

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
		if( (pev.weapons & (RGRUNT_HANDGRENADE|RGRUNT_M16)) == 0 ) return;
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState > STATE_RANGE ) return;
		if( m_flNextGrenade > g_Engine.time ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 and (m_pPlayer.pev.button & IN_ATTACK2) != 0)
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iState = STATE_GRENADE;

			if( (pev.weapons & RGRUNT_HANDGRENADE) != 0 )
			{
				if( m_pPlayer.pev.v_angle.x >= 60 )
				{
					SetAnim( ANIM_GRENADE_DROP );
					m_flNextGrenade = g_Engine.time + CD_GRENADE_DROP;
				}
				else
				{
					g_SoundSystem.PlaySentenceGroup( m_pDriveEnt.edict(), "RB_THROW", VOL_NORM, ATTN_NORM, 0, m_iVoicePitch );
					SetAnim( ANIM_GRENADE_THROW );
					m_flNextGrenade = g_Engine.time + CD_GRENADE_TOSS;
				}
			}
			else if( (pev.weapons & RGRUNT_M16) != 0 )
			{
				if( CNPC_FIRSTPERSON )
					self.SendWeaponAnim( 8 );

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
				if( CNPC_FIRSTPERSON )
				{
					if( GetFrame(56) == 8 and m_uiAnimationState == 0 )
					{
						m_pPlayer.pev.viewmodel = MODEL_GRENADE;
						self.SendWeaponAnim( 2 );
						m_uiAnimationState++;
					}
					else if( GetFrame(56) == 34 and m_uiAnimationState == 1 )
					{
						self.SendWeaponAnim( 5 );
						m_uiAnimationState++;
					}
					else if( GetFrame(56) > 50 and m_uiAnimationState == 2 )
					{
						m_pPlayer.pev.viewmodel = GetWeaponModel();
						self.SendWeaponAnim( GetWeaponAnim(WANIM_DRAW) );
						m_uiAnimationState++;
					}
				}

				if( GetFrame(56) == 34 and !m_bGrenadeUsed )
				{
					Math.MakeVectors( m_pPlayer.pev.v_angle );
					Vector vecGrenadeVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * GRENADE_THROW;

					g_EntityFuncs.ShootTimed( m_pPlayer.pev, m_pDriveEnt.pev.origin + g_Engine.v_forward * 34.0 + Vector (0, 0, 32.0), vecGrenadeVelocity, 3.5 );

					m_bGrenadeUsed = true;
				}
				else if( GetFrame(56) > 50 and m_bGrenadeUsed )
					m_bGrenadeUsed = false;

				break;
			}

			case ANIM_GRENADE_DROP:
			{
				if( CNPC_FIRSTPERSON )
				{
					if( GetFrame(56) == 1 and m_uiAnimationState == 0 )
					{
						m_pPlayer.pev.viewmodel = MODEL_GRENADE;
						self.SendWeaponAnim( 2 );
						m_uiAnimationState++;
					}
					else if( GetFrame(56) == 11 and m_uiAnimationState == 1 )
					{
						self.SendWeaponAnim( 6 );
						m_uiAnimationState++;
					}
					else if( GetFrame(56) > 50 and m_uiAnimationState == 2 )
					{
						m_pPlayer.pev.viewmodel = GetWeaponModel();
						self.SendWeaponAnim( GetWeaponAnim(WANIM_DRAW) );
						m_uiAnimationState++;
					}
				}

				if( GetFrame(56) == 31 and !m_bGrenadeUsed )
				{
					Math.MakeVectors( m_pDriveEnt.pev.angles );
					g_EntityFuncs.ShootTimed( m_pPlayer.pev, m_pDriveEnt.pev.origin + g_Engine.v_forward * 17.0 - g_Engine.v_right * 27.0 + g_Engine.v_up * 6.0, g_vecZero, 3.0 );

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

					if( CNPC_FIRSTPERSON )
						self.SendWeaponAnim( GetWeaponAnim(WANIM_LAUNCH) );

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
		if( (pev.weapons & RGRUNT_RPG) == 0 ) return;

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

	void LowHealth()
	{
		if( m_pPlayer.pev.health <= CNPC_LOWHEALTH and m_pDriveEnt.pev.deadflag != DEAD_DEAD )
		{
			Vector vecSrc = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), Math.RandomFloat(pev.origin.z, pev.absmax.z) );

			if( m_flNextSpark - 0.1 <= g_Engine.time and m_bDoubleSpark )
			{
				g_Utility.Sparks( vecSrc );
				m_bDoubleSpark = false;
			}

			if( m_flNextSpark + Math.RandomFloat(0, 1) <= g_Engine.time )
			{
				g_Utility.Sparks( vecSrc );
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_SPARK1, SND_SPARK2)], 0.5, ATTN_NORM, 0, 95 + Math.RandomLong(0, 10) );

				m_flNextSpark = g_Engine.time + 0.3;
				UpdateGlow();
				m_bDoubleSpark = true;
			}
		}
	}

	void UpdateGlow()
	{
		if( m_flNextSpark > g_Engine.time and !m_bShockTouch )
		{
			if( Math.RandomLong(0, 30) > 26 )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_SHOCK], 0.8, ATTN_NORM, 0, PITCH_NORM );
				GlowEffect( true );
				m_bShockTouch = true;
				m_flNextShockTouch = g_Engine.time + 0.45;
			}
			else if( Math.RandomLong(0, 40) == 15 )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_SHOCK], 0.8, ATTN_NORM, 0, PITCH_NORM );
				GlowEffect( true );
				m_bShockTouch = true;
				m_flNextShockTouch = g_Engine.time + 0.35;
			}
		}
	}

	void DoShockTouch()
	{
		if( m_bShockTouch )
		{
			TraceResult tr;
			g_Utility.TraceHull( m_pPlayer.pev.origin, m_pPlayer.pev.origin + Vector(0, 0, 72), dont_ignore_monsters, large_hull, m_pPlayer.edict(), tr );
			
			if( tr.pHit !is null )
			{
				CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
				pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, DMG_SHOCKTOUCH, DMG_SHOCK );
			}

			/*Doesn't work properly
			cnpc_rgrunt@ pDriveEnt = cast<cnpc_rgrunt@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null )
			{
				pDriveEnt.SetTouch( TouchFunction(pDriveEnt.ShockTouch) );
				pDriveEnt.pev.solid = SOLID_TRIGGER;
				m_pPlayer.pev.solid = SOLID_NOT;
				g_EntityFuncs.SetSize( pDriveEnt.pev, CNPC_SIZEMIN*1.2, CNPC_SIZEMAX*1.2 );
			}*/

			if( g_Engine.time > m_flNextShockTouch )
			{
				GlowEffect( false );
				m_bShockTouch = false;
			}
		}
		else
		{
			cnpc_rgrunt@ pDriveEnt = cast<cnpc_rgrunt@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null )
			{
				pDriveEnt.SetTouch( null );
				//pDriveEnt.pev.solid = SOLID_NOT;
				//m_pPlayer.pev.solid = SOLID_SLIDEBOX;
				g_EntityFuncs.SetSize( pDriveEnt.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
			}
		}
	}

	void GlowEffect( bool bOn )
	{
		if( bOn )
		{
			m_pDriveEnt.pev.rendermode = kRenderNormal;
			m_pDriveEnt.pev.renderfx = kRenderFxGlowShell;
			m_pDriveEnt.pev.renderamt = 4.0;
			m_pDriveEnt.pev.rendercolor = Vector(100, 100, 220);
		}
		else
		{
			m_pDriveEnt.pev.rendermode = kRenderNormal;
			m_pDriveEnt.pev.renderfx = kRenderFxNone;
			m_pDriveEnt.pev.renderamt = 255.0;
			m_pDriveEnt.pev.rendercolor = g_vecZero;
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_rgrunt", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		m_pDriveEnt.pev.set_controller( 0,  127 );

		g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "body", "" + pev.body );
		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_RGRUNT );
	}

	void DoFirstPersonView()
	{
		cnpc_rgrunt@ pDriveEnt = cast<cnpc_rgrunt@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_rgrunt_rend_" + m_pPlayer.entindex();
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
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}

	bool InReloadAnimation()
	{
		return ( m_pDriveEnt.pev.sequence == ANIM_RELOAD_MP5 
		or m_pDriveEnt.pev.sequence == ANIM_RELOAD_RPG 
		or m_pDriveEnt.pev.sequence == ANIM_RELOAD_SHOTGUN 
		or m_pDriveEnt.pev.sequence == ANIM_RELOAD_SNIPER );
	}

	bool InGrenadeAnimation()
	{
		return ( m_pDriveEnt.pev.sequence == ANIM_GRENADE_LAUNCH 
		or m_pDriveEnt.pev.sequence == ANIM_GRENADE_THROW 
		or m_pDriveEnt.pev.sequence == ANIM_GRENADE_DROP );
	}

	string GetWeaponModel()
	{
		if( (pev.weapons & RGRUNT_MP5) != 0 ) return MODEL_MP5;
		else if( (pev.weapons & RGRUNT_M16) != 0 ) return MODEL_M16;
		else if( (pev.weapons & RGRUNT_SHOTGUN) != 0 ) return MODEL_SHOTGUN;
		else if( (pev.weapons & RGRUNT_RPG) != 0 ) return MODEL_RPG;
		else if( (pev.weapons & RGRUNT_SNIPER) != 0 ) return MODEL_SNIPER;

		return "";
	}

	int GetWeaponAnim( int iAnimType )
	{
		if( (pev.weapons & RGRUNT_MP5) != 0 )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 4;
				case WANIM_SHOOT: return Math.RandomLong( 5, 7 );
				case WANIM_RELOAD: return 3;
			}
		}
		else if( (pev.weapons & RGRUNT_M16) != 0 )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 0;
				case WANIM_SHOOT: return Math.RandomLong( 4, 5 );
				case WANIM_LAUNCH: return 7;
				case WANIM_RELOAD: return 6;
			}
		}
		else if( (pev.weapons & RGRUNT_SHOTGUN) != 0 )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 6;
				case WANIM_SHOOT: return 2;
				case WANIM_RELOAD: return 8;
			}
		}
		else if( (pev.weapons & RGRUNT_RPG) != 0 )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 5;
				case WANIM_SHOOT: return 3;
				case WANIM_RELOAD: return 2;
			}
		}
		else if( (pev.weapons & RGRUNT_SNIPER) != 0 )
		{
			switch( iAnimType )
			{
				case WANIM_DRAW: return 0;
				case WANIM_SHOOT: return 2;
				case WANIM_RELOAD: return 4;
			}
		}

		return 0;
	}
}

class cnpc_rgrunt : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	private float m_flRemoveTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		if( (pev.weapons & RGRUNT_RPG) == 0 )
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
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
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
		else if( (m_pOwner.pev.button & IN_ATTACK2) != 0 )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void ShockTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.takedamage == DAMAGE_NO or pOther.edict() is m_pOwner.edict() )
			return;

		if( m_pOwner !is null and m_pOwner.IsConnected() and m_pOwner.pev.deadflag == DEAD_NO )
		{
			if( pOther.pev.FlagBitSet(FL_MONSTER) or (pOther.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
				pOther.TakeDamage( m_pOwner.pev, m_pOwner.pev, DMG_SHOCKTOUCH, DMG_SHOCK );
		}
	}

	void DoDeath()
	{
		GlowEffect( false );
		GetSoundEntInstance().InsertSound ( bits_SOUND_DANGER, pev.origin, 250, 2.5, self ); 

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_DEATH1, SND_DEATH2)], VOL_NORM, 0.5 );
		g_EntityFuncs.SetSize( self.pev, Vector(-1.0, -1.0, 0.0), Vector(4.0, 4.0, 1.0) );

		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH6 );
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flRemoveTime = g_Engine.time + Math.RandomFloat( 3.0, 7.0 );
		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void GlowEffect( bool bOn )
	{
		if( bOn )
		{
			pev.rendermode = kRenderNormal;
			pev.renderfx = kRenderFxGlowShell;
			pev.renderamt = 4.0;
			pev.rendercolor = Vector(100, 100, 220);
		}
		else
		{
			pev.rendermode = kRenderNormal;
			pev.renderfx = kRenderFxNone;
			pev.renderamt = 255.0;
			pev.rendercolor = g_vecZero;
		}
	}

	void DieThink()
	{
		if( pev.deadflag != DEAD_DEAD )
			pev.deadflag = DEAD_DEAD;

		if( m_flRemoveTime <= g_Engine.time )
		{
			pev.solid = SOLID_NOT;

			SpawnExplosion( pev.origin, 0.0, 0.0, EXPLODE_DAMAGE );

			NetworkMessage gib1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				gib1.WriteByte( TE_BREAKMODEL );
				gib1.WriteCoord( pev.origin.x ); // position
				gib1.WriteCoord( pev.origin.y );
				gib1.WriteCoord( pev.origin.z );
				gib1.WriteCoord( 200 ); // size
				gib1.WriteCoord( 200 );
				gib1.WriteCoord( 64 );
				gib1.WriteCoord( 10 ); // velocity
				gib1.WriteCoord( 20 );
				gib1.WriteCoord( 80 );
				gib1.WriteByte( 30 ); // randomization
				gib1.WriteShort( g_EngineFuncs.ModelIndex(GIB_MODEL1) ); //model id#
				gib1.WriteByte( 15 ); // # of shards
				gib1.WriteByte( 100 ); // duration (3.0 seconds)
				gib1.WriteByte( BREAK_METAL ); // flags
			gib1.End();

			NetworkMessage gib2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				gib2.WriteByte( TE_BREAKMODEL );
				gib2.WriteCoord( pev.origin.x ); // position
				gib2.WriteCoord( pev.origin.y );
				gib2.WriteCoord( pev.origin.z );
				gib2.WriteCoord( 200 ); // size
				gib2.WriteCoord( 200 );
				gib2.WriteCoord( 96 );
				gib2.WriteCoord( 0 ); // velocity
				gib2.WriteCoord( 0 );
				gib2.WriteCoord( 10 );
				gib2.WriteByte( 30 ); // randomization
				gib2.WriteShort( g_EngineFuncs.ModelIndex(GIB_MODEL2) ); //model id#
				gib2.WriteByte( 15 ); // # of shards
				gib2.WriteByte( 100 ); // duration (3.0 seconds)
				gib2.WriteByte( BREAK_METAL ); // flags
			gib2.End();

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_SHOCK], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			CBaseEntity@ pSmoker = g_EntityFuncs.Create( "env_smoker", pev.origin, g_vecZero, false );
			pSmoker.pev.health = 1; //1 smoke balls
			pSmoker.pev.scale = 10; //4.6X normal size
			pSmoker.pev.dmg = 0; //0 radial distribution
			pSmoker.pev.nextthink = g_Engine.time + 0.5; //Start in 0.5 seconds

			Vector vecOrigin = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), Math.RandomFloat(pev.origin.z, pev.absmax.z) );
			g_Utility.Sparks( vecOrigin );

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;
		}
		else
		{
			Vector vecOrigin = pev.origin;

			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
				m1.WriteByte( TE_SMOKE );
				m1.WriteCoord( Math.RandomFloat(pev.absmin.x, pev.absmax.x) );
				m1.WriteCoord( Math.RandomFloat(pev.absmin.y, pev.absmax.y) );
				m1.WriteCoord( vecOrigin.z );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SMOKE_SPRITE) );
				m1.WriteByte( 15 ); // scale * 10
				m1.WriteByte( 10 ); // framerate
			m1.End();

			vecOrigin = Vector( Math.RandomFloat(pev.absmin.x, pev.absmax.x), Math.RandomFloat(pev.absmin.y, pev.absmax.y), Math.RandomFloat(pev.origin.z, pev.absmax.z) );
			g_Utility.Sparks( vecOrigin );

			pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void SpawnExplosion( Vector center, float randomRange, float time, int magnitude )
	{
		CBaseEntity@ pExplosion = g_EntityFuncs.Create( "env_explosion", center, g_vecZero, false );
		pExplosion.KeyValue( "iMagnitude", string(magnitude) );

		g_EntityFuncs.DispatchSpawn( pExplosion.edict() );

		if( m_pOwner !is null and m_pOwner.IsConnected() and m_pOwner.pev.deadflag == DEAD_NO )
			pExplosion.Use( m_pOwner, m_pOwner, USE_ON );
		else
			pExplosion.Use( self, self, USE_ON );

		pExplosion.pev.nextthink = g_Engine.time + time;
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_rgrunt : CNPCSpawnEntity
{
	info_cnpc_rgrunt()
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
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void DoSpecificStuff()
	{
		if( (pev.weapons & RGRUNT_RPG) == 0 )
			pev.sequence = ANIM_IDLE;
		else
			pev.sequence = ANIM_IDLE_RPG;

		pev.set_controller( 0,  127 );

		if( (pev.weapons & RGRUNT_MP5) != 0 and (pev.weapons & RGRUNT_M16) == 0 )
			self.SetBodygroup( GUN_GROUP, GUN_MP5 );
		else if( (pev.weapons & RGRUNT_SHOTGUN) != 0 )
			self.SetBodygroup( GUN_GROUP, GUN_SHOTGUN );
		else if( (pev.weapons & RGRUNT_M16) != 0 )
			self.SetBodygroup( GUN_GROUP, GUN_M16 );
		else if( (pev.weapons & RGRUNT_RPG) != 0 )
			self.SetBodygroup( GUN_GROUP, GUN_RPG );
		else if( (pev.weapons & RGRUNT_SNIPER) != 0 )
			self.SetBodygroup( GUN_GROUP, GUN_SNIPER );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_rgrunt::info_cnpc_rgrunt", "info_cnpc_rgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_rgrunt::cnpc_rgrunt", "cnpc_rgrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_rgrunt::weapon_rgrunt", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "rgruntammo" );

	g_Game.PrecacheOther( "info_cnpc_rgrunt" );
	g_Game.PrecacheOther( "cnpc_rgrunt" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_rgrunt END

/* FIXME
*/

/* TODO
	Use IsBetween2 instead of switch-case for fake anim events ??
*/