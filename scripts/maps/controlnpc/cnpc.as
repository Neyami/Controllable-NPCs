#include "quake2/cnpcq2"

#include "CBaseDriveWeapon"
#include "headcrab"
#include "houndeye"
#include "pitdrone"
#include "islave"
#include "zombie"
#include "bullsquid"
#include "agrunt"
#include "gonome"
#include "strooper"
#include "icky"
#include "kingpin"
#include "babygarg"
#include "tentacle"
#include "garg"
#include "bigmomma"

#include "gman"
#include "fassn"
#include "sentry"
#include "mturret"
#include "hgrunt"
#include "rgrunt"
#include "turret"
#include "hwgrunt"
#include "hwrgrunt"
#include "apache"

#include "scientist"
#include "barney"
#include "otis"
#include "engineer"

void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @CNPC::ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @CNPC::PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::PlayerTakeDamage );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @CNPC::ClientSay );

	cnpc_headcrab::Register();
	cnpc_houndeye::Register();
	cnpc_pitdrone::Register();
	cnpc_islave::Register();
	cnpc_zombie::Register();
	cnpc_bullsquid::Register();
	cnpc_agrunt::Register();
	cnpc_gonome::Register();
	cnpc_strooper::Register();
	cnpc_icky::Register();
	cnpc_kingpin::Register();
	cnpc_babygarg::Register();
	cnpc_tentacle::Register();
	cnpc_garg::Register();
	cnpc_bigmomma::Register();

	cnpc_gman::Register();
	cnpc_fassn::Register();
	cnpc_sentry::Register();
	cnpc_mturret::Register();
	cnpc_hgrunt::Register();
	cnpc_rgrunt::Register();
	cnpc_turret::Register();
	cnpc_hwgrunt::Register();
	cnpc_hwrgrunt::Register();
	cnpc_apache::Register();
	
	cnpc_scientist::Register();
	cnpc_barney::Register();
	cnpc_otis::Register();
	cnpc_engineer::Register();

	CNPC::Q2::MapInitCNPCQ2();
}

namespace CNPC
{

int g_iShockTrooperQuestion;
int g_iGruntQuestion;
int g_iRobotGruntQuestion;
int g_iTorchAllyQuestion;
float g_flTalkWaitTime;

const bool PVP								= false;
const float CNPC_SPEAK_DISTANCE	= 768.0;
const int DEAD_GIB						= 42;

enum flags_e
{
	FL_TRIGGER_ONLY = 1,
	FL_GAG = 2,
	FL_DISABLEDROP = 4,
	FL_NOEXPLODE = 8,
	FL_CUSTOMAMMO = 16,
	FL_INFINITEAMMO = 32,
	FL_NOPLAYERDEATH = 64
};

//xen
const int HEADCRAB_SLOT			= 1;
const int HEADCRAB_POSITION	= 10;
const int HOUNDEYE_SLOT			= 1;
const int HOUNDEYE_POSITION	= 11;
const int PITDRONE_SLOT			= 1;
const int PITDRONE_POSITION	= 12;
const int ISLAVE_SLOT				= 1;
const int ISLAVE_POSITION		= 13;
const int ZOMBIE_SLOT				= 1;
const int ZOMBIE_POSITION		= 14;
const int BULLSQUID_SLOT			= 1;
const int BULLSQUID_POSITION	= 15;
const int AGRUNT_SLOT				= 1;
const int AGRUNT_POSITION		= 16;
const int GONOME_SLOT				= 1;
const int GONOME_POSITION		= 17;
const int STROOPER_SLOT			= 1;
const int STROOPER_POSITION	= 18;
const int ICKY_SLOT					= 1;
const int ICKY_POSITION			= 19;
const int KINGPIN_SLOT				= 2;
const int KINGPIN_POSITION		= 20;

const int BABYGARG_SLOT			= 2;
const int BABYGARG_POSITION	= 10;
const int TENTACLE_SLOT			= 2;
const int TENTACLE_POSITION	= 11;
const int GARG_SLOT					= 2;
const int GARG_POSITION			= 12;
const int BIGMOMMA_SLOT			= 2;
const int BIGMOMMA_POSITION	= 13;

//black mesa etc
const int GMAN_SLOT					= 3;
const int GMAN_POSITION			= 10;
const int FASSN_SLOT				= 3;
const int FASSN_POSITION			= 11;
const int SENTRY_SLOT				= 3;
const int SENTRY_POSITION		= 12;
const int MTURRET_SLOT			= 3;
const int MTURRET_POSITION		= 13;
const int HGRUNT_SLOT				= 3;
const int HGRUNT_POSITION		= 14;
const int RGRUNT_SLOT				= 3;
const int RGRUNT_POSITION		= 15;
const int TURRET_SLOT				= 3;
const int TURRET_POSITION		= 16;
const int HWGRUNT_SLOT			= 3;
const int HWGRUNT_POSITION	= 17;
const int HWRGRUNT_SLOT		= 3;
const int HWRGRUNT_POSITION	= 18;
const int APACHE_SLOT				= 3;
const int APACHE_POSITION		= 19;

//friendles
const int SCIENTIST_SLOT			= 4;
const int SCIENTIST_POSITION	= 10;
const int BARNEY_SLOT				= 4;
const int BARNEY_POSITION		= 11;
const int OTIS_SLOT					= 4;
const int OTIS_POSITION			= 12;
const int ENGINEER_SLOT			= 4;
const int ENGINEER_POSITION	= 13;

const string sCNPCKV = "$i_cnpc_iscontrollingnpc";
const string sCNPCKVPainTime = "$f_cnpc_nextpaintime";

const float flModelToGameSpeedModifier = 1.650124131504528; //gotten from player maxspeed (270) divided by player model speed (163.624054)

const array<string>arrsEdibles =
{
	"monster_barney",
	"monster_hgrunt",
	"monster_human_grunt",
	"monster_otis",
	"monster_scientist",

	"monster_barney_dead",
	"monster_hevsuit_dead",
	"monster_hgrunt_dead",
	"monster_otis_dead",
	"monster_scientist_dead"
};

const array<string>arrsFlyingMobs =
{
	"info_cnpc_icky"
};

array<string> arrsCNPCWeapons =
{
	"weapon_headcrab",
	"weapon_houndeye",
	"weapon_pitdrone",
	"weapon_islave",
	"weapon_zombie",
	"weapon_bullsquid",
	"weapon_agrunt",
	"weapon_gonome",
	"weapon_strooper",
	"weapon_icky",
	"weapon_kingpin",
	"weapon_babygarg",
	"weapon_tentacle",
	"weapon_garg",
	"weapon_bigmomma",

	"weapon_gman",
	"weapon_fassn",
	"weapon_sentry",
	"weapon_mturret",
	"weapon_hgrunt",
	"weapon_rgrunt",
	"weapon_turret",
	"weapon_hwgrunt",
	"weapon_hwrgrunt",
	"weapon_apache",

	"weapon_scientist",
	"weapon_barney",
	"weapon_otis",
	"weapon_engineer"
};

array<string> arrsCNPCGibbable =
{
	"cnpc_zombie",
	"cnpc_bullsquid",
	"cnpc_kingpin",
	"cnpc_bigmomma",

	"cnpc_hgrunt",
	"cnpc_fassn",
	"cnpc_hwrgrunt",
	"cnpc_hwgrunt",
	"cnpc_apache",

	"cnpc_scientist",
	"cnpc_barney",
	"cnpc_otis",
	"cnpc_engineer"
};

enum cnpc_e
{
	CNPC_HEADCRAB = 1,
	CNPC_HOUNDEYE,
	CNPC_PITDRONE,
	CNPC_ISLAVE,
	CNPC_ZOMBIE,
	CNPC_BULLSQUID,
	CNPC_AGRUNT,
	CNPC_GONOME,
	CNPC_STROOPER,
	CNPC_ICKY,
	CNPC_KINGPIN,
	CNPC_BABYGARG,
	CNPC_TENTACLE,
	CNPC_GARG,
	CNPC_BIGMOMMA,

	CNPC_GMAN,
	CNPC_FASSN,
	CNPC_SENTRY,
	CNPC_MTURRET,
	CNPC_HGRUNT,
	CNPC_RGRUNT,
	CNPC_TURRET,
	CNPC_HWGRUNT,
	CNPC_HWRGRUNT,
	CNPC_APACHE,

	CNPC_SCIENTIST,
	CNPC_BARNEY,
	CNPC_OTIS,
	CNPC_ENGINEER,
	CNPC_LASTVANILLA
};

enum heads_e { HEAD_GLASSES = 0, HEAD_EINSTEIN = 1, HEAD_LUTHER = 2, HEAD_SLICK = 3 };

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer)
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.InitializeKeyvalueWithDefault( sCNPCKV );
	pCustom.InitializeKeyvalueWithDefault( sCNPCKVPainTime );

	return HOOK_CONTINUE;
}
//int TakeDamage(entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	CustomKeyvalues@ pCustom = pDamageInfo.pVictim.GetCustomKeyvalues();

	//pAttacker is sometimes null
	if( pCustom.GetKeyvalue(sCNPCKV).GetInteger() <= 0 or pDamageInfo.pAttacker is null ) return HOOK_CONTINUE;

	//prevent other players from triggering painsounds
	if( pDamageInfo.pVictim !is pDamageInfo.pAttacker )
	{
		if( pDamageInfo.pVictim.GetClassname() == "player" and pDamageInfo.pAttacker.GetClassname() == "player" and (pDamageInfo.bitsDamageType & DMG_CLUB) == 0 )
		{
			if( pDamageInfo.pVictim.Classify() == pDamageInfo.pAttacker.Classify() )
				return HOOK_CONTINUE;
		}
	}

	switch( pCustom.GetKeyvalue(sCNPCKV).GetInteger() )
	{
		case CNPC_HEADCRAB:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_headcrab::pPainSounds[Math.RandomLong(0,(cnpc_headcrab::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_HOUNDEYE:
		{
			if( pDamageInfo.flDamage > 0 and pDamageInfo.pVictim.pev.deadflag == DEAD_NO )
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_houndeye::pPainSounds[Math.RandomLong(0,(cnpc_houndeye::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );
			
			//flinch_small = 11, flinch_small2 = 12
			break;
		}

		case CNPC_PITDRONE:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_pitdrone::pPainSounds[Math.RandomLong(0,(cnpc_pitdrone::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 120) );

			break;
		}

		case CNPC_ISLAVE:
		{
			if( Math.RandomLong(0, 2) == 0 )
				g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_WEAPON, cnpc_islave::pPainSounds[Math.RandomLong(0,(cnpc_islave::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 110) ); //TODO cnpc_islave::m_iVoicePitch

			break;
		}

		case CNPC_ZOMBIE:
		{
			// Take 30% damage from bullets
			if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
			{
				Vector vecDir = pDamageInfo.pVictim.pev.origin - (pDamageInfo.pInflictor.pev.absmin + pDamageInfo.pInflictor.pev.absmax) * 0.5;
				vecDir = vecDir.Normalize();
				float flForce = pDamageInfo.flDamage * ((32 * 32 * 72.0) / (pDamageInfo.pVictim.pev.size.x * pDamageInfo.pVictim.pev.size.y * pDamageInfo.pVictim.pev.size.z)) * 5;
				if( flForce > 1000.0) 
					flForce = 1000.0;

				pDamageInfo.pVictim.pev.velocity = pDamageInfo.pVictim.pev.velocity + vecDir * flForce;
				pDamageInfo.flDamage *= 0.3;
			}

			if( Math.RandomLong(0, 5) < 2 )
				g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_zombie::pPainSounds[Math.RandomLong(0,(cnpc_zombie::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, 95 + Math.RandomLong(0, 9) );

			//flinchsmall = 2, flinch = 3, bigflinch = 4
			break;
		}

		case CNPC_BULLSQUID:
		{
			g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_bullsquid::pPainSounds[Math.RandomLong(0,(cnpc_bullsquid::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 120) );

			break;
		}

		case CNPC_AGRUNT:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(3.0, 4.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_agrunt::pPainSounds[Math.RandomLong(0,(cnpc_agrunt::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 120) );

			break;
		}

		case CNPC_GONOME:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_gonome::pPainSounds[Math.RandomLong(0,(cnpc_gonome::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_STROOPER:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 1.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_strooper::pPainSounds[Math.RandomLong(0,(cnpc_strooper::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_ICKY:
		{
			if( pDamageInfo.flDamage > 0 and pDamageInfo.pVictim.pev.deadflag == DEAD_NO )
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_icky::pPainSounds[Math.RandomLong(0,(cnpc_icky::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			//smflinch = 5, bgflinch = 6

			break;
		}

		case CNPC_KINGPIN:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_kingpin::weapon_kingpin@ pWeapon = cast<cnpc_kingpin::weapon_kingpin@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null )
			{
				if( pWeapon.m_bShieldOn )
				{
					TraceResult tr = g_Utility.GetGlobalTrace();
					Vector vecDir = ( pDamageInfo.pAttacker.Center() - Vector(0, 0, 10) - pDamageInfo.pVictim.Center() ).Normalize();
					Vector vecOrigin = tr.vecEndPos - (vecDir * pDamageInfo.pVictim.pev.scale) * 0.0625;

					NetworkMessage m1( MSG_PVS, NetworkMessages::ShieldRic, vecOrigin );
						m1.WriteCoord( vecOrigin.x );
						m1.WriteCoord( vecOrigin.y );
						m1.WriteCoord( vecOrigin.z );
					m1.End();
				}

				float flDamage = pDamageInfo.flDamage;
				float flDamageMultiplier = 1.0; //??

				if( pWeapon.m_bShieldOn )
				{
					pWeapon.m_flShieldTime = g_Engine.time + 0.5;

					if( !pWeapon.m_bSomeBool )
					{
						pWeapon.ResolveRenderProps();
						flDamage = pDamageInfo.flDamage;
					}

					if( flDamage > 0.0 and pDamageInfo.bitsDamageType & (DMG_FREEZE | DMG_DROWN) == 0 ) //0x4020
					{
						if( (pDamageInfo.bitsDamageType & DMG_BLAST) != 0 ) //0x40
							flDamageMultiplier = 0.4;
						else
							flDamageMultiplier = 0.2;

						float flTemp = (flDamage - flDamage * 0.01) * flDamageMultiplier;
						float flRenderamt = pWeapon.m_flTargetRenderamt;

						if( flTemp > flRenderamt )
						{
							pWeapon.m_flTargetRenderamt = 0;
							pWeapon.ShieldOff();
							flDamage = flDamage - flRenderamt * (1.0 / flDamageMultiplier);;
						}
						else
						{
							flDamage = flDamage * 0.01;
							pWeapon.m_flTargetRenderamt = flRenderamt - flTemp;
						}

						if( pWeapon.m_bSomeBool )
							pWeapon.SetRenderAmount( pWeapon.m_flTargetRenderamt );
					}
				}

				pDamageInfo.flDamage = flDamage * 0.75;
			}

			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(2.5, 4.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_kingpin::pPainSounds[Math.RandomLong(0,(cnpc_kingpin::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_BABYGARG:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(2.5, 4.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_babygarg::pPainSounds[Math.RandomLong(0,(cnpc_babygarg::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_GARG:
		{
			if( cnpc_garg::CNPC_NPC_HITBOX )
				return HOOK_CONTINUE;
			else
			{
				if( (pDamageInfo.bitsDamageType & cnpc_garg::GARG_DAMAGE) == 0 )
					pDamageInfo.flDamage *= 0.01;

				if( pDamageInfo.bitsDamageType & (cnpc_garg::GARG_DAMAGE|DMG_BLAST) != 0 )
				{
					if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
						return HOOK_CONTINUE;

					float flNextPainTime = g_Engine.time + Math.RandomFloat(2.5, 4.0);
					pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

					g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_garg::pPainSounds[Math.RandomLong(0,(cnpc_garg::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );
				}
			}

			break;
		}

		case CNPC_BIGMOMMA:
		{
			// Don't take any acid damage -- BigMomma's mortar is acid
			if( (pDamageInfo.bitsDamageType & DMG_ACID) != 0 )
				pDamageInfo.flDamage = 0.0;

			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(1.0, 3.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_bigmomma::pPainSounds[Math.RandomLong(0,(cnpc_bigmomma::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			//flinch = 10

			break;
		}


		case CNPC_GMAN:
		{
			pDamageInfo.flDamage = 0.0;
			pDamageInfo.pVictim.pev.health = pDamageInfo.pVictim.pev.max_health / 2;

			TraceResult tr = g_Utility.GetGlobalTrace();
			g_Utility.Ricochet( tr.vecEndPos, 1.0 );

			break;
		}

		case CNPC_HGRUNT:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 1.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			if( Math.RandomLong(0, 6) <= 4 )
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_hgrunt::pPainSounds[Math.RandomLong(0,(cnpc_hgrunt::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_RGRUNT:
		{
			if( pDamageInfo.flDamage < 0 or pDamageInfo.pVictim.pev.takedamage == DAMAGE_NO )
				return HOOK_CONTINUE;

			if( (pDamageInfo.bitsDamageType & DMG_CLUB) == 0 or !CanRepairRobot(pDamageInfo.pAttacker) or !pDamageInfo.pAttacker.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
				cnpc_rgrunt::weapon_rgrunt@ pWeapon = cast<cnpc_rgrunt::weapon_rgrunt@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

				if( pWeapon !is null )
				{
					if( pWeapon.m_bShockTouch )
					{
						if( pDamageInfo.bitsDamageType & (DMG_SLASH|DMG_CLUB) != 0 )
						{
							pDamageInfo.pAttacker.TakeDamage( pDamageInfo.pVictim.pev, pDamageInfo.pVictim.pev, cnpc_rgrunt::DMG_SHOCKTOUCH/4, DMG_SHOCK );
							pDamageInfo.flDamage = 0.01;
						}
					}
					else if( pDamageInfo.bitsDamageType & (DMG_SLASH|DMG_CLUB) != 0 and pDamageInfo.pVictim.pev.health <= 20.0 and Math.RandomLong(0, 2) > 1 )
					{
						pWeapon.GlowEffect( true );
						pWeapon.m_bShockTouch = true;
					}
				}

				if( pDamageInfo.bitsDamageType & (DMG_BULLET|DMG_CLUB|DMG_SNIPER) != 0 )
				{
					TraceResult tr = g_Utility.GetGlobalTrace();
					g_Utility.Ricochet( tr.vecEndPos, 1.0 );
					pDamageInfo.flDamage *= 0.15;
				}

				if( (pDamageInfo.bitsDamageType & DMG_SLASH) != 0 )
				{
					if( pDamageInfo.flDamage >= 5.0 )
						pDamageInfo.flDamage -= 5.0;

					pDamageInfo.flDamage *= 0.08;
				}

				if( (pDamageInfo.bitsDamageType & DMG_BLAST) != 0 and pDamageInfo.pVictim.pev.health > 10.0 )
				{
					if( pDamageInfo.flDamage > 15.0 )
						pDamageInfo.flDamage -= 15.0;

					pDamageInfo.flDamage *= 0.2;

					if( (pDamageInfo.bitsDamageType & DMG_BURN) == 0 )
						return HOOK_CONTINUE;
				}
				else if( (pDamageInfo.bitsDamageType & DMG_BURN) == 0 or pDamageInfo.pVictim.pev.health <= 10.0 )
					return HOOK_CONTINUE;

				pDamageInfo.flDamage *= 0.5;

				return HOOK_CONTINUE;
			}

			if( pDamageInfo.pVictim.pev.health < pDamageInfo.pVictim.pev.max_health )
			{
				g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_BODY, cnpc_rgrunt::arrsCNPCSounds[cnpc_rgrunt::SND_REPAIR], VOL_NORM, 0.6, 0, PITCH_NORM );
				
				float flDamage = g_EngineFuncs.CVarGetFloat( "sk_plr_wrench" );
				pDamageInfo.pAttacker.pev.frags += Math.min( 4, (flDamage / pDamageInfo.pVictim.pev.max_health) * (4 * (pDamageInfo.pVictim.pev.max_health / cnpc_rgrunt::CNPC_HEALTH)) );

				pDamageInfo.pVictim.pev.health += flDamage;
				if( pDamageInfo.pVictim.pev.health > pDamageInfo.pVictim.pev.max_health )
					pDamageInfo.pVictim.pev.health = pDamageInfo.pVictim.pev.max_health;

				//To prevent accidental death? :ayaya:
				if( pDamageInfo.pVictim.pev.health < 1 )
					pDamageInfo.pVictim.pev.health = 1.0;
			}

			break;
		}

		/*TODO, add berserk mode??
		case CNPC_TURRET:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			//if (pev.health <= 10)
			//{
				//if (m_iOn && (1 || RANDOM_LONG(0, 0x7FFF) > 800))
				//{
					//m_fBeserk = 1;
					//SetThink(&CBaseTurret::SearchThink);
				//}
			//}

			break;
		}*/

		case CNPC_HWGRUNT:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 1.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			if( Math.RandomLong(0, 6) <= 4 )
				g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_hwgrunt::pPainSounds[Math.RandomLong(0,(cnpc_hwgrunt::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, 95 + Math.RandomLong(0, 9) );

			if( (pDamageInfo.bitsDamageType & DMG_BLAST) != 0 and pDamageInfo.flDamage > 50.0 and Math.RandomLong(0, 10) > 9 )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
				cnpc_hwgrunt::weapon_hwgrunt@ pWeapon = cast<cnpc_hwgrunt::weapon_hwgrunt@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

				if( pWeapon !is null and (pWeapon.m_iSpawnFlags & FL_DISABLEDROP) == 0 )
					pWeapon.m_bShouldDropMinigun = true;
			}

			break;
		}

		case CNPC_HWRGRUNT:
		{
			if( pDamageInfo.flDamage < 0 or pDamageInfo.pVictim.pev.takedamage == DAMAGE_NO )
				return HOOK_CONTINUE;

			if( (pDamageInfo.bitsDamageType & DMG_CLUB) == 0 or !CanRepairRobot(pDamageInfo.pAttacker) or !pDamageInfo.pAttacker.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
				cnpc_hwrgrunt::weapon_hwrgrunt@ pWeapon = cast<cnpc_hwrgrunt::weapon_hwrgrunt@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

				if( pWeapon !is null )
				{
					if( pWeapon.m_bShockTouch )
					{
						if( pDamageInfo.bitsDamageType & (DMG_SLASH|DMG_CLUB) != 0 )
						{
							pDamageInfo.pAttacker.TakeDamage( pDamageInfo.pVictim.pev, pDamageInfo.pVictim.pev, cnpc_hwrgrunt::DMG_SHOCKTOUCH/4, DMG_SHOCK );
							pDamageInfo.flDamage = 0.01;
						}
					}
					else if( pDamageInfo.bitsDamageType & (DMG_SLASH|DMG_CLUB) != 0 and pDamageInfo.pVictim.pev.health <= 20.0 and Math.RandomLong(0, 2) > 1 )
					{
						pWeapon.GlowEffect( true );
						pWeapon.m_bShockTouch = true;
					}
				}

				if( pDamageInfo.bitsDamageType & (DMG_BULLET|DMG_CLUB|DMG_SNIPER) != 0 )
				{
					TraceResult tr = g_Utility.GetGlobalTrace();
					g_Utility.Ricochet( tr.vecEndPos, 1.0 );
					pDamageInfo.flDamage *= 0.15;
				}

				if( (pDamageInfo.bitsDamageType & DMG_SLASH) != 0 )
				{
					if( pDamageInfo.flDamage >= 5.0 )
						pDamageInfo.flDamage -= 5.0;

					pDamageInfo.flDamage *= 0.08;
				}

				if( (pDamageInfo.bitsDamageType & DMG_BLAST) != 0 and pDamageInfo.pVictim.pev.health > 10.0 )
				{
					if( pDamageInfo.flDamage > 15.0 )
						pDamageInfo.flDamage -= 15.0;

					pDamageInfo.flDamage *= 0.2;

					if( (pDamageInfo.bitsDamageType & DMG_BURN) == 0 )
						return HOOK_CONTINUE;
				}
				else if( (pDamageInfo.bitsDamageType & DMG_BURN) == 0 or pDamageInfo.pVictim.pev.health <= 10.0 )
					return HOOK_CONTINUE;

				pDamageInfo.flDamage *= 0.5;

				return HOOK_CONTINUE;
			}

			if( pDamageInfo.pVictim.pev.health < pDamageInfo.pVictim.pev.max_health )
			{
				g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_BODY, cnpc_hwrgrunt::arrsCNPCSounds[cnpc_hwrgrunt::SND_REPAIR], VOL_NORM, 0.6, 0, PITCH_NORM );
				
				float flDamage = g_EngineFuncs.CVarGetFloat( "sk_plr_wrench" );
				pDamageInfo.pAttacker.pev.frags += Math.min( 4, (flDamage / pDamageInfo.pVictim.pev.max_health) * (4 * (pDamageInfo.pVictim.pev.max_health / cnpc_hwrgrunt::CNPC_HEALTH)) );

				pDamageInfo.pVictim.pev.health += flDamage;
				if( pDamageInfo.pVictim.pev.health > pDamageInfo.pVictim.pev.max_health )
					pDamageInfo.pVictim.pev.health = pDamageInfo.pVictim.pev.max_health;

				//To prevent accidental death? :ayaya:
				if( pDamageInfo.pVictim.pev.health < 1 )
					pDamageInfo.pVictim.pev.health = 1.0;
			}

			break;
		}




		case CNPC_SCIENTIST:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_scientist::pPainSounds[Math.RandomLong(0,(cnpc_scientist::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM ); //TODO GetVoicePitch()

			break;
		}

		case CNPC_BARNEY:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_barney::pPainSounds[Math.RandomLong(0,(cnpc_barney::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM ); //TODO GetVoicePitch()

			break;
		}

		case CNPC_OTIS:
		{
			if( (pDamageInfo.bitsDamageType & (DMG_BULLET | DMG_SLASH | DMG_BLAST)) != 0 )
				pDamageInfo.flDamage = pDamageInfo.flDamage / 2;

			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			int iPitch = 100;
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_otis::weapon_otis@ pWeapon = cast<cnpc_otis::weapon_otis@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null ) iPitch = pWeapon.m_iVoicePitch;
			g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_otis::pPainSounds[Math.RandomLong(0,(cnpc_otis::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, iPitch );

			break;
		}

		case CNPC_ENGINEER:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 1.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_engineer::pPainSounds[Math.RandomLong(0,(cnpc_engineer::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		default: break;
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if( pPlayer.m_hActiveItem.GetEntity() !is null )
	{
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );

		if( arrsCNPCWeapons.find(pWeapon.GetClassname()) >= 0 )
		{
			if( (pPlayer.pev.health < -40 and iGib != GIB_NEVER) or iGib == GIB_ALWAYS )
			{
				CBaseEntity@ pDriveEnt = null;
				while( (@pDriveEnt = g_EntityFuncs.FindEntityInSphere( pDriveEnt, pPlayer.pev.origin, 42, "*", "classname" ) ) !is null )
				{
					if( arrsCNPCGibbable.find(pDriveEnt.GetClassname()) < 0 ) continue;

					if( pDriveEnt.pev.owner is pPlayer.edict() )
						break;
				}

				if( pDriveEnt !is null )
				{
					pDriveEnt.pev.deadflag = DEAD_GIB;
					if( pDriveEnt.GetClassname() == "cnpc_bigmomma" )
					{
						cnpc_bigmomma::cnpc_bigmomma@ pBigMomma = cast<cnpc_bigmomma::cnpc_bigmomma@>( CastToScriptClass(pDriveEnt) );
						if( pBigMomma !is null and pAttacker !is null )
						{
							Vector vecDir = ( pAttacker.Center() - Vector(0, 0, 10) - pDriveEnt.Center() ).Normalize();
							pBigMomma.m_vecAttackDir = vecDir.Normalize();
							pDriveEnt.pev.health = pPlayer.pev.health;
						}
					}
				}
			}

			g_EntityFuncs.Remove( pWeapon );
		}
	}

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( sCNPCKV, 0 );

	return HOOK_CONTINUE;
}

const array<string> arrsStroopWords =
{
	"blis",
	"dit",
	"dup",
	"ga",
	"hyu",
	"ka",
	"kiml",
	"kss",
	"ku",
	"kur",
	"kyur",
	"mub",
	"puh",
	"pur",
	"ras",
	"thirv",
	"wirt"
};

HookReturnCode ClientSay( SayParameters@ pParams )
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	if( pCustom.GetKeyvalue(sCNPCKV).GetInteger() != CNPC_STROOPER ) return HOOK_CONTINUE;

	const CCommand@ args = pParams.GetArguments();
	int iArgC = args.ArgC();
	string sCustomSentence = "\"shocktrooper/";

	if( iArgC > 0 )
	{
		if( iArgC > 9 ) iArgC = 9;

		for( int i = 0; i < iArgC; ++i )
		{
			if( i == (iArgC -1) )
				sCustomSentence += arrsStroopWords[Math.RandomLong(0, arrsStroopWords.length()-1)] + "\"";
			else
				sCustomSentence += arrsStroopWords[Math.RandomLong(0, arrsStroopWords.length()-1)] + " ";
		}

		CBasePlayer@ pTarget = null;
		for( int i = 1; i <= g_Engine.maxClients; ++i )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( i );

			if( pTarget !is null and (pPlayer.pev.origin - pTarget.pev.origin).Length() < CNPC_SPEAK_DISTANCE )
			{
				NetworkMessage spk( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pTarget.edict() );
					spk.WriteString( "spk "+ sCustomSentence + "\n" );
				spk.End();
			}
		}
	}

	return HOOK_CONTINUE;
}

bool CanRepairRobot( CBaseEntity@ pEntity )
{
	if( pEntity is null )
		return false;

	if( !pEntity.pev.FlagBitSet(FL_CLIENT) or (pEntity.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
		return false;

	return true;
}

//from pm_shared.c
void monster_footstep( EHandle eDriveEnt, EHandle ePlayer, int iStepLeft, int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
{
	int iRand;
	float flVol = 1.0;

	iRand = Math.RandomLong(0, 1) + (iStepLeft * 2);

	CBaseEntity@ pDriveEnt = eDriveEnt.GetEntity();
	Vector vecOrigin = pDriveEnt.pev.origin;

	if( bSetOrigin )
		vecOrigin = vecSetOrigin;

	TraceResult tr;
	g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -64),  ignore_monsters, pDriveEnt.edict(), tr );

	edict_t@ pWorld = g_EntityFuncs.Instance(0).edict();
	if( tr.pHit !is null ) @pWorld = tr.pHit;

	string sTexture = g_Utility.TraceTexture( pWorld, vecOrigin, vecOrigin + Vector(0, 0, -64) );
	char chTextureType = g_SoundSystem.FindMaterialType( sTexture );
	int iStep = MapTextureTypeStepType( chTextureType );

	if( ePlayer.GetEntity().pev.waterlevel == WATERLEVEL_FEET ) iStep = CNPC::Q2::STEP_SLOSH;
	else if( ePlayer.GetEntity().pev.waterlevel >= WATERLEVEL_WAIST ) iStep = CNPC::Q2::STEP_WADE;

	switch( iStep )
	{
		case CNPC::Q2::STEP_VENT:
		{
			flVol = 0.7; //fWalking ? 0.4 : 0.7;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_duct1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_duct3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_duct2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_duct4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_DIRT:
		{
			flVol = 0.55; //fWalking ? 0.25 : 0.55;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_dirt1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_dirt3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_dirt2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_dirt4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_GRATE:
		{
			flVol = 0.5; //fWalking ? 0.2 : 0.5;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_grate1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_grate3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_grate2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_grate4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_METAL:
		{
			flVol = 0.5; //fWalking ? 0.2 : 0.5;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_metal1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_metal3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_metal2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_metal4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_SLOSH:
		{
			flVol = 0.5; //fWalking ? 0.2 : 0.5;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_slosh1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_slosh3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_slosh2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_slosh4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_WADE: { break; }

		case CNPC::Q2::STEP_TILE:
		{
			flVol = 0.5; //fWalking ? 0.2 : 0.5;

			if( Math.RandomLong(0, 4) == 0 )
				iRand = 4;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_tile1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_tile3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_tile2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_tile4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 4: g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_tile5.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_WOOD:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_wood1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_wood3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_wood2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_wood4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_FLESH:
		{
			flVol = 0.55; //fWalking ? 0.25 : 0.55;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_organic1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_organic3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_organic2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_organic4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_SNOW:
		{
			flVol = 0.55; //fWalking ? 0.25 : 0.55;

			if( Math.RandomLong(0, 1) == 1 )
				iRand += 4;

			switch( iRand )
			{
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 4:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow5.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 5:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow6.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 6:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow7.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 7:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_snow8.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}

		case CNPC::Q2::STEP_CONCRETE:
		default:
		{
			flVol = 0.5; //fWalking ? 0.2 : 0.5;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_step1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_step3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_step2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pDriveEnt.edict(), CHAN_BODY, "player/pl_step4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
			}

			break;
		}
	}

	//g_Game.AlertMessage( at_notice, "sTexture: %1\n", sTexture );
	//g_Game.AlertMessage( at_notice, "chTextureType: %1\n", string(chTextureType) );
	//g_Game.AlertMessage( at_notice, "iStep: %1\n", iStep );
}

int MapTextureTypeStepType( char chTextureType )
{
	if( chTextureType == 'C' ) return CNPC::Q2::STEP_CONCRETE;
	else if( chTextureType == 'M' ) return CNPC::Q2::STEP_METAL;
	else if( chTextureType == 'D' ) return CNPC::Q2::STEP_DIRT;
	else if( chTextureType == 'V' ) return CNPC::Q2::STEP_VENT;
	else if( chTextureType == 'G' ) return CNPC::Q2::STEP_GRATE;
	else if( chTextureType == 'T' ) return CNPC::Q2::STEP_TILE;
	else if( chTextureType == 'S' ) return CNPC::Q2::STEP_SLOSH;
	else if( chTextureType == 'W' ) return CNPC::Q2::STEP_WOOD; //TODO
	else if( chTextureType == 'F' ) return CNPC::Q2::STEP_FLESH;
	else if( chTextureType == 'O' ) return CNPC::Q2::STEP_SNOW;

	return CNPC::Q2::STEP_CONCRETE;
}
} //namespace CNPC END

//thanks Outerbeast :ayaya:
abstract class CNPCSpawnEntity : ScriptBaseAnimating
{
	CScheduledFunction@ m_RespawnThink; //because SetThink doesn't work here for some reason :aRage:

	protected EHandle m_hCNPCWeapon;
	CBaseEntity@ m_pCNPCWeapon
	{
		get const { return m_hCNPCWeapon.GetEntity(); }
		set { m_hCNPCWeapon = EHandle(@value); }
	}

	bool m_bActive;
	float m_flDefaultRespawnTime;
	float m_flRespawnTime; //how long until respawn
	float m_flTimeToRespawn; //used to check if ready to respawn
	float m_flSpawnOffset; //when using CNPC_NPC_HITBOX the player spawns in the floor
	int m_iSpawnFlags; //Just in case
	int m_iMaxAmmo;
	float m_flFireRate;
	float m_flCustomHealth;

	string m_sWeaponName;
	string m_sModel;
	int m_iStartAnim;
	Vector m_vecSizeMin, m_vecSizeMax;

	//scientist
	int m_iBody;

	int ObjectCaps()
	{
		if( (m_iSpawnFlags & CNPC::FL_TRIGGER_ONLY) != 0 )
			return BaseClass.ObjectCaps();

		return m_bActive ? (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE) : BaseClass.ObjectCaps();
	}

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}
		else if( szKey == "customhealth" )
		{
			m_flCustomHealth = atof( szValue );
			return true;
		}
		else if( szKey == "gag" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_GAG;

			return true;
		}
		else if( szKey == "triggeronly" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_TRIGGER_ONLY;

			return true;
		}
		else if( szKey == "noplayerdeath" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_NOPLAYERDEATH;

			return true;
		}
		else if( CustomKeyValue(szKey, szValue) )
			return true;
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	bool CustomKeyValue( const string& in szKey, const string& in szValue ) { return false; }

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, m_sModel );
		g_EntityFuncs.SetSize( self.pev, m_vecSizeMin, m_vecSizeMax );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		if( CNPC::arrsFlyingMobs.find(self.GetClassname()) < 0 )
			g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = m_iStartAnim;
		pev.rendermode = kRenderTransTexture;
		pev.renderfx = kRenderFxDistort;
		pev.renderamt = 128;

		if( m_flRespawnTime <= 0 ) m_flRespawnTime = m_flDefaultRespawnTime;

		m_bActive = true;

		DoSpecificStuff();
	}

	void DoSpecificStuff() {}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( !m_bActive or !pActivator.pev.FlagBitSet(FL_CLIENT) ) return;

		if( pActivator.pev.FlagBitSet(FL_ONGROUND) or CNPC::arrsFlyingMobs.find(self.GetClassname()) >= 0 )
		{
			CustomKeyvalues@ pCustom = pActivator.GetCustomKeyvalues();
			if( pCustom.GetKeyvalue(CNPC::sCNPCKV).GetInteger() <= 0 )
			{
				Vector vecExitOrigin = pActivator.pev.origin;
				Vector vecExitAngles = pActivator.pev.angles;
				Vector vecOrigin = pev.origin;
				vecOrigin.z += m_flSpawnOffset;
				g_EntityFuncs.SetOrigin( pActivator, vecOrigin );

				@m_pCNPCWeapon = g_EntityFuncs.Create( m_sWeaponName, pActivator.pev.origin, g_vecZero, true );
				m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

				if( self.GetClassname() == "info_cnpc_scientist" )
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "body", "" + pev.body );
				else if( self.GetClassname() == "info_cnpc_hgrunt" )
				{
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "skin", "" + pev.skin );
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "body", "" + pev.body );
				}
				else if( self.GetClassname() == "info_cnpc_rgrunt" )
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "body", "" + pev.body );

				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "weapons", "" + pev.weapons );
				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_iMaxAmmo", "" + m_iMaxAmmo );
				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_flFireRate", "" + m_flFireRate );
				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_flCustomHealth", "" + m_flCustomHealth );

				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
				g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );
				m_pCNPCWeapon.Touch( pActivator ); //make sure they pick it up

				pev.effects |= EF_NODRAW;
				m_bActive = false;

				@m_RespawnThink = g_Scheduler.SetTimeout( @this, "RespawnThink", 0.0 );

				SpecialUse( vecExitOrigin, vecExitAngles );
				pActivator.pev.angles = pev.angles;
				pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
			}
		}
	}

	void SpecialUse( Vector vecOrigin, Vector vecAngles ) {}

	void RespawnThink()
	{
		if( m_pCNPCWeapon is null and m_flTimeToRespawn <= 0.0 )
			m_flTimeToRespawn = g_Engine.time + m_flRespawnTime;

		if( m_flTimeToRespawn > 0.0 and m_flTimeToRespawn <= g_Engine.time )
		{
			if( self.GetClassname() == "info_cnpc_scientist" )
			{
				// -1 chooses a random head
				if( m_iBody == -1 )
					pev.body = Math.RandomLong(0, 3);

				// Luther is black, make his hands black
				if( pev.body == CNPC::HEAD_LUTHER )
					pev.skin = 1;
			}

			pev.effects &= ~EF_NODRAW;
			m_flTimeToRespawn = 0.0;
			m_bActive = true;

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "ambience/particle_suck1.wav", VOL_NORM, 0.3, 0, 90 );
			g_Scheduler.RemoveTimer( m_RespawnThink );
			return;
		}

		@m_RespawnThink = g_Scheduler.SetTimeout( @this, "RespawnThink", 0.1 );
	}
}

/* TODO
	Disable flashlight and USE-key while controlling a monster ??

	Disable fall damage and sounds

	Allow for pvp

	Berserk-mode for turret

	Flinch animations ??

	Use the driveent as a targetable entity with the proper hitbox

	use g_EngineFuncs.ChangeYaw(edict_t@ pEntity) for head-turners. This updates entvars_t::angles[ 1 ] to approach entvars_t::ideal_yaw, at entvars_t::yaw_speed degrees speed.
*/