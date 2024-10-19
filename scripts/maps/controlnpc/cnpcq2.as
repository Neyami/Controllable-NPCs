#include "CBaseDriveWeaponQ2"
#include "cnpcq2entities"

#include "q2ironmaiden"
#include "q2berserker"
#include "q2gladiator"
#include "q2tank"
#include "q2supertank"

namespace CNPC
{

namespace Q2
{

const int Q2IRONMAIDEN_SLOT			= 5;
const int Q2IRONMAIDEN_POSITION	= 10;
const int Q2BERSERKER_SLOT			= 5;
const int Q2BERSERKER_POSITION		= 11;
const int Q2GLADIATOR_SLOT				= 5;
const int Q2GLADIATOR_POSITION		= 12;
const int Q2TANK_SLOT						= 5;
const int Q2TANK_POSITION				= 13;
const int Q2SUPERTANK_SLOT			= 5;
const int Q2SUPERTANK_POSITION		= 14;

const array<string> arrsCNPCQ2Weapons =
{
	"weapon_q2ironmaiden",
	"weapon_q2berserker",
	"weapon_q2gladiator",
	"weapon_q2tank",
	"weapon_q2supertank"
};

const array<string> arrsCNPCQ2Gibbable =
{
	"cnpc_q2ironmaiden",
	"cnpc_q2berserker",
	"cnpc_q2gladiator",
	"cnpc_q2tank"
};

enum cnpcq2_e
{
	CNPC_Q2IRONMAIDEN = CNPC::CNPC_LASTVANILLA + 1,
	CNPC_Q2BERSERKER,
	CNPC_Q2GLADIATOR,
	CNPC_Q2TANK,
	CNPC_Q2SUPERTANK
};

enum steptype_e
{
	STEP_CONCRETE = 0, // default step sound
	STEP_METAL, // metal floor
	STEP_DIRT, // dirt, sand, rock
	STEP_VENT, // ventilation duct
	STEP_GRATE, // metal grating
	STEP_TILE, // floor tiles
	STEP_SLOSH, // shallow liquid puddle
	STEP_WADE, // wading in liquid
	STEP_LADDER, // climbing ladder
	STEP_WOOD,
	STEP_FLESH,
	STEP_SNOW
};

void MapInitCNPCQ2()
{
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::Q2::PlayerTakeDamage );

    for( uint i = 0; i < arrsCNPCQ2Weapons.length(); i++ )
		arrsCNPCWeapons.insertLast( arrsCNPCQ2Weapons[i] );

    for( uint i = 0; i < arrsCNPCQ2Gibbable.length(); i++ )
      arrsCNPCGibbable.insertLast( arrsCNPCQ2Gibbable[i] );

	cnpc_q2ironmaiden::Register();
	cnpc_q2berserker::Register();
	cnpc_q2gladiator::Register();
	cnpc_q2tank::Register();
	cnpc_q2supertank::Register();
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	CustomKeyvalues@ pCustom = pDamageInfo.pVictim.GetCustomKeyvalues();

	//pAttacker is sometimes null
	if( pCustom.GetKeyvalue(sCNPCKV).GetInteger() <= 0 or pDamageInfo.pAttacker is null ) return HOOK_CONTINUE;

	//prevent other players from triggering painsounds
	if( pDamageInfo.pVictim !is pDamageInfo.pAttacker )
	{
		if( pDamageInfo.pVictim.GetClassname() == "player" and pDamageInfo.pAttacker.GetClassname() == "player" )
		{
			if( pDamageInfo.pVictim.Classify() == pDamageInfo.pAttacker.Classify() )
				return HOOK_CONTINUE;
		}
	}

	switch( pCustom.GetKeyvalue(sCNPCKV).GetInteger() )
	{
		case CNPC_Q2IRONMAIDEN:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2ironmaiden::weapon_q2ironmaiden@ pWeapon = cast<cnpc_q2ironmaiden::weapon_q2ironmaiden@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
			{
				if( pWeapon.m_iState == 3 ) //STATE_DUCKING
					pDamageInfo.flDamage *= 0.5;

				pWeapon.HandlePain( pDamageInfo.flDamage );
			}

			break;
		}

		case CNPC_Q2BERSERKER:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2berserker::weapon_q2berserker@ pWeapon = cast<cnpc_q2berserker::weapon_q2berserker@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
			{
				if( pWeapon.m_iState == 3 ) //STATE_DUCKING
					pDamageInfo.flDamage *= 0.5;

				pWeapon.HandlePain( pDamageInfo.flDamage );
			}

			break;
		}

		case CNPC_Q2GLADIATOR:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2gladiator::weapon_q2gladiator@ pWeapon = cast<cnpc_q2gladiator::weapon_q2gladiator@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
				pWeapon.HandlePain( pDamageInfo.flDamage );

			break;
		}

		case CNPC_Q2TANK:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2tank::weapon_q2tank@ pWeapon = cast<cnpc_q2tank::weapon_q2tank@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
				pWeapon.HandlePain( pDamageInfo.flDamage );

			break;
		}

		case CNPC_Q2SUPERTANK:
		{
			if( cnpc_q2supertank::CNPC_NPC_HITBOX )
				return HOOK_CONTINUE;
			else
			{
				if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
					return HOOK_CONTINUE;

				float flNextPainTime = g_Engine.time + 3.0;
				pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			if( pDamageInfo.flDamage <= 10 )
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_q2supertank::pPainSounds[0], VOL_NORM, ATTN_NORM );
			else if( pDamageInfo.flDamage <= 25 )
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_q2supertank::pPainSounds[2], VOL_NORM, ATTN_NORM );
			else
				g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_q2supertank::pPainSounds[1], VOL_NORM, ATTN_NORM );

				break;
			}
		}

		default: break;
	}

	return HOOK_CONTINUE;
}

} //namespace Q2 END

} //namespace CNPC END


/* FIXME
	Pain sounds get played at origin 0 0 0 for some reason
*/

/* TODO
	Flinch animations
*/