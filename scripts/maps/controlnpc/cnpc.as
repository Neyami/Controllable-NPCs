#include "CBaseDriveWeapon"
#include "headcrab"
#include "houndeye"
#include "islave"
#include "agrunt"
#include "icky"
#include "pitdrone"
#include "strooper"
#include "gonome"
#include "garg"
#include "babygarg"

#include "hgrunt"
#include "fassn"
#include "mturret"
#include "turret"
#include "rgrunt"
#include "hwrgrunt"
#include "hwgrunt"

#include "scientist"
#include "engineer"

void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @CNPC::ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @CNPC::PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::PlayerTakeDamage );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @CNPC::ClientSay );

	cnpc_headcrab::Register();
	cnpc_houndeye::Register();
	cnpc_islave::Register();
	cnpc_agrunt::Register();
	cnpc_icky::Register();
	cnpc_pitdrone::Register();
	cnpc_strooper::Register();
	cnpc_gonome::Register();
	cnpc_garg::Register();
	cnpc_babygarg::Register();

	cnpc_hgrunt::Register();
	cnpc_fassn::Register();
	cnpc_mturret::Register();
	cnpc_turret::Register();
	cnpc_rgrunt::Register();
	cnpc_hwrgrunt::Register();
	cnpc_hwgrunt::Register();

	cnpc_scientist::Register();
	cnpc_engineer::Register();
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
	FL_GAG = 1,
	FL_DISABLEDROP = 2,
	FL_NOEXPLODE = 4,
	FL_CUSTOMAMMO = 8,
	FL_INFINITEAMMO = 16
};

//xen
const int HEADCRAB_SLOT			= 1;
const int HEADCRAB_POSITION	= 10;
const int HOUNDEYE_SLOT			= 1;
const int HOUNDEYE_POSITION	= 11;
const int ISLAVE_SLOT				= 1;
const int ISLAVE_POSITION		= 12;
const int AGRUNT_SLOT				= 1;
const int AGRUNT_POSITION		= 13;
const int ICKY_SLOT					= 1;
const int ICKY_POSITION			= 14;
const int PITDRONE_SLOT			= 1;
const int PITDRONE_POSITION	= 15;
const int STROOPER_SLOT			= 1;
const int STROOPER_POSITION	= 16;
const int GONOME_SLOT				= 1;
const int GONOME_POSITION		= 17;
const int GARG_SLOT					= 1;
const int GARG_POSITION			= 18;
const int BABYGARG_SLOT			= 1;
const int BABYGARG_POSITION	= 19;

//black mesa etc
const int HGRUNT_SLOT				= 2;
const int HGRUNT_POSITION		= 10;
const int FASSN_SLOT				= 2;
const int FASSN_POSITION			= 11;
const int MTURRET_SLOT			= 2;
const int MTURRET_POSITION		= 12;
const int TURRET_SLOT				= 2;
const int TURRET_POSITION		= 13;
const int RGRUNT_SLOT				= 2;
const int RGRUNT_POSITION		= 14;
const int HWRGRUNT_SLOT		= 2;
const int HWRGRUNT_POSITION	= 15;
const int HWGRUNT_SLOT			= 2;
const int HWGRUNT_POSITION	= 16;

//friendles
const int SCIENTIST_SLOT			= 3;
const int SCIENTIST_POSITION	= 10;
const int ENGINEER_SLOT			= 3;
const int ENGINEER_POSITION	= 11;

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

const array<string> arrsCNPCWeapons =
{
	"weapon_headcrab",
	"weapon_houndeye",
	"weapon_islave",
	"weapon_agrunt",
	"weapon_icky",
	"weapon_pitdrone",
	"weapon_strooper",
	"weapon_gonome",
	"weapon_garg",
	"weapon_babygarg",

	"weapon_hgrunt",
	"weapon_fassn",
	"weapon_mturret",
	"weapon_turret",
	"weapon_rgrunt",
	"weapon_hwrgrunt",
	"weapon_hwgrunt",

	"weapon_scientist",
	"weapon_engineer"
};

const array<string> arrsCNPCGibbable =
{
	"cnpc_hwrgrunt",
	"cnpc_hwgrunt"
};

enum cnpc_e
{
	CNPC_HEADCRAB = 1,
	CNPC_HOUNDEYE,
	CNPC_ISLAVE,
	CNPC_AGRUNT,
	CNPC_ICKY,
	CNPC_PITDRONE,
	CNPC_STROOPER,
	CNPC_GONOME,
	CNPC_GARG,
	CNPC_BABYGARG,

	CNPC_HGRUNT,
	CNPC_FASSN,
	CNPC_MTURRET,
	CNPC_TURRET,
	CNPC_RGRUNT,
	CNPC_HWRGRUNT,
	CNPC_HWGRUNT,

	CNPC_SCIENTIST,
	CNPC_ENGINEER
};

enum heads_e { HEAD_GLASSES = 0, HEAD_EINSTEIN = 1, HEAD_LUTHER = 2, HEAD_SLICK = 3 };

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer)
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.InitializeKeyvalueWithDefault( sCNPCKV );
	pCustom.InitializeKeyvalueWithDefault( sCNPCKVPainTime );

	return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	CustomKeyvalues@ pCustom = pDamageInfo.pVictim.GetCustomKeyvalues();

	//pAttacker is sometimes null
	if( pCustom.GetKeyvalue(sCNPCKV).GetInteger() <= 0 or pDamageInfo.pAttacker is null ) return HOOK_CONTINUE;

	//prevent other players from triggering painsounds
	if( pDamageInfo.pVictim.GetClassname() == "player" and pDamageInfo.pAttacker.GetClassname() == "player" and (pDamageInfo.bitsDamageType & DMG_CLUB) == 0 )
	{
		if( pDamageInfo.pVictim.Classify() == pDamageInfo.pAttacker.Classify() )
			return HOOK_CONTINUE;
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

		case CNPC_ISLAVE:
		{
			if( Math.RandomLong(0, 2) == 0 )
				g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_WEAPON, cnpc_islave::pPainSounds[Math.RandomLong(0,(cnpc_islave::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 110) ); //TODO cnpc_islave::m_iVoicePitch

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

		case CNPC_ICKY:
		{
			if( pDamageInfo.flDamage > 0 and pDamageInfo.pVictim.pev.deadflag == DEAD_NO )
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_icky::pPainSounds[Math.RandomLong(0,(cnpc_icky::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			//smflinch = 5, bgflinch = 6

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

		case CNPC_STROOPER:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 1.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_strooper::pPainSounds[Math.RandomLong(0,(cnpc_strooper::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

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

		case CNPC_GARG:
		{
			if( cnpc_garg::CNPC_NPC_HITBOX )
				pDamageInfo.flDamage = 0;
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

		case CNPC_BABYGARG:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(2.5, 4.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_babygarg::pPainSounds[Math.RandomLong(0,(cnpc_babygarg::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

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

		case CNPC_SCIENTIST:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.5, 0.75);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_scientist::pPainSounds[Math.RandomLong(0,(cnpc_scientist::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM ); //TODO GetVoicePitch()

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
					pDriveEnt.pev.deadflag = DEAD_GIB;
			}

			g_EntityFuncs.Remove( pWeapon );
		}
	}

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( sCNPCKV, 0 );

	return HOOK_CONTINUE;
}

/*const array<string> arrsSentStroop =
{
	"!ST_ALERT0", //2 words
	"!ST_TAUNT0",
	"!ST_ANSWER0",
	"!ST_CHECK0",
	"!ST_GREN0", //4 //3 words
	"!ST_ALERT1",
	"!ST_THROW0",
	"!ST_IDLE0",
	"!ST_CLEAR0",
	"!ST_ALERT2", //9 //4 words
	"!ST_QUEST0",
	"!ST_MONST0", //11 //5 words
	"!ST_COVER0",
	"!ST_CHARGE0",
	"!ST_QUEST0"
};*/

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

		/*if( iArgC == 1 or iArgC == 2 )
			pPlayer.PlaySentence( arrsSentStroop[Math.RandomLong(0, 3)], 0, VOL_NORM, ATTN_IDLE );
		else if( iArgC == 3 or iArgC == 4 )
			pPlayer.PlaySentence( arrsSentStroop[Math.RandomLong(4, 8)], 0, VOL_NORM, ATTN_IDLE );
		else if( iArgC >= 5 )
			pPlayer.PlaySentence( arrsSentStroop[Math.RandomLong(9, 14)], 0, VOL_NORM, ATTN_IDLE );*/
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

} //namespace CNPC END

//thanks Outerbeast :ayaya:
abstract class CNPCSpawnEntity : ScriptBaseAnimating
{
	CScheduledFunction@ m_RespawnThink; //because SetThink doesn't work here for some reason :aRage:

	protected EHandle m_hCNPCWeapon;
	protected CBaseEntity@ m_pCNPCWeapon
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

	string m_sWeaponName;
	string m_sModel;
	int m_iStartAnim;
	Vector m_vecSizeMin, m_vecSizeMax;

	//scientist
	int m_iBody;

	int ObjectCaps() { return m_bActive ? (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE) : BaseClass.ObjectCaps(); }

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "respawntime" )
		{
			m_flRespawnTime = atof( szValue );
			return true;
		}
		else if( szKey == "gag" )
		{
			if( atoi(szValue) > 0 )
				m_iSpawnFlags |= CNPC::FL_GAG;

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

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

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue  )
	{
		if( !m_bActive or !pActivator.pev.FlagBitSet(FL_CLIENT) ) return;

		if( pActivator.pev.FlagBitSet(FL_ONGROUND) or CNPC::arrsFlyingMobs.find(self.GetClassname()) >= 0 )
		{
			CustomKeyvalues@ pCustom = pActivator.GetCustomKeyvalues();
			if( pCustom.GetKeyvalue(CNPC::sCNPCKV).GetInteger() <= 0 )
			{
				Vector vecOrigin = pev.origin;
				vecOrigin.z += m_flSpawnOffset;
				g_EntityFuncs.SetOrigin( pActivator, vecOrigin );
				pActivator.pev.angles = pev.angles;
				pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
				@m_pCNPCWeapon = g_EntityFuncs.Create( m_sWeaponName, pActivator.pev.origin, g_vecZero, true );
				m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

				if( self.GetClassname() == "info_cnpc_scientist" )
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "body", "" + pev.body );
				else if( self.GetClassname() == "info_cnpc_hgrunt" )
				{
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "weapons", "" + pev.weapons );
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "skin", "" + pev.skin );
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "body", "" + pev.body );
				}
				else if( self.GetClassname() == "info_cnpc_rgrunt" )
				{
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "weapons", "" + pev.weapons );
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "body", "" + pev.body );
				}
				else if( self.GetClassname() == "info_cnpc_hwgrunt" )
					g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "weapons", "" + pev.weapons );

				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_iMaxAmmo", "" + m_iMaxAmmo );
				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "m_flFireRate", "" + m_flFireRate );

				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
				g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );
				m_pCNPCWeapon.Touch( pActivator ); //make sure they pick it up

				pev.effects |= EF_NODRAW;
				m_bActive = false;

				@m_RespawnThink = g_Scheduler.SetTimeout( @this, "RespawnThink", 0.0 );
			}
		}
	}

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

	Use self.m_fSequenceFinished instead ??

	Allow for pvp

	Idle sounds and fidget animations

	Berserk-mode for turret

	Use the driveent as a targetable entity with the proper hitbox
*/