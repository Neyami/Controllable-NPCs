#include "CBaseDriveWeaponQ2"
#include "cnpcq2entities"

#include "q2gladiator"
#include "q2tank"

namespace CNPC
{

namespace Q2
{

const int Q2GLADIATOR_SLOT			= 5;
const int Q2GLADIATOR_POSITION	= 10;
const int Q2TANK_SLOT					= 5;
const int Q2TANK_POSITION			= 11;

const array<string> arrsCNPCQ2Weapons =
{
	"weapon_q2gladiator",
	"weapon_q2tank"
};

const array<string> arrsCNPCQ2Gibbable =
{
	"cnpc_q2gladiator",
	"cnpc_q2tank"
};

enum cnpcq2_e
{
	CNPC_Q2GLADIATOR = CNPC::CNPC_LASTVANILLA + 1,
	CNPC_Q2TANK
};

void MapInitCNPCQ2()
{
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::Q2::PlayerTakeDamage );

    for( uint i = 0; i < arrsCNPCQ2Weapons.length(); i++ )
		arrsCNPCWeapons.insertLast( arrsCNPCQ2Weapons[i] );

    for( uint i = 0; i < arrsCNPCQ2Gibbable.length(); i++ )
      arrsCNPCGibbable.insertLast( arrsCNPCQ2Gibbable[i] );

	cnpc_q2gladiator::Register();
	cnpc_q2tank::Register();
}

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
		case CNPC_Q2GLADIATOR:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2gladiator::weapon_q2gladiator@ pWeapon = cast<cnpc_q2gladiator::weapon_q2gladiator@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
				pWeapon.m_pDriveEnt.pev.dmg = pDamageInfo.flDamage;

			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 3.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_q2gladiator::pPainSounds[Math.RandomLong(0,(cnpc_q2gladiator::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
		}

		case CNPC_Q2TANK:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2tank::weapon_q2tank@ pWeapon = cast<cnpc_q2tank::weapon_q2tank@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
				pWeapon.m_pDriveEnt.pev.dmg = pDamageInfo.flDamage;

			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + 3.0;
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_q2tank::pPainSounds[Math.RandomLong(0,(cnpc_q2tank::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

			break;
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