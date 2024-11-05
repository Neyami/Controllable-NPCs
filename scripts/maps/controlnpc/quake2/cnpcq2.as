#include "CBaseDriveWeaponQ2"
#include "cnpcq2entities"

#include "q2soldier" //20, 30, 40 HP
#include "q2gunner" //175 HP
#include "q2ironmaiden" //175 HP
#include "q2berserker" //240 HP
#include "q2enforcer" //240 HP
#include "q2gladiator" //400 HP
#include "q2tank" //750 HP
#include "q2supertank" //1500 HP
#include "q2makron" //3000 HP

namespace CNPC
{

namespace Q2
{

const int Q2SOLDIER_SLOT					= 5;
const int Q2SOLDIER_POSITION			= 11;
const int Q2GUNNER_SLOT					= 5;
const int Q2GUNNER_POSITION			= 12;
const int Q2IRONMAIDEN_SLOT			= 5;
const int Q2IRONMAIDEN_POSITION	= 13;
const int Q2BERSERKER_SLOT			= 5;
const int Q2BERSERKER_POSITION		= 14;
const int Q2ENFORCER_SLOT				= 5;
const int Q2ENFORCER_POSITION		= 15;
const int Q2GLADIATOR_SLOT				= 5;
const int Q2GLADIATOR_POSITION		= 16;
const int Q2TANK_SLOT						= 5;
const int Q2TANK_POSITION				= 17;
const int Q2SUPERTANK_SLOT			= 5;
const int Q2SUPERTANK_POSITION		= 18;
const int Q2MAKRON_SLOT					= 5;
const int Q2MAKRON_POSITION			= 19;

const array<string> arrsCNPCQ2Weapons =
{
	"weapon_q2soldier",
	"weapon_q2gunner",
	"weapon_q2ironmaiden",
	"weapon_q2berserker",
	"weapon_q2enforcer",
	"weapon_q2gladiator",
	"weapon_q2tank",
	"weapon_q2supertank",
	"weapon_q2makron"
};

const array<string> arrsCNPCQ2Gibbable =
{
	"cnpc_q2soldier",
	"cnpc_q2gunner",
	"cnpc_q2ironmaiden",
	"cnpc_q2berserker",
	"cnpc_q2enforcer",
	"cnpc_q2gladiator",
	"cnpc_q2tank"
};

enum cnpcq2_e
{
	CNPC_Q2SOLDIER = CNPC::CNPC_LASTVANILLA + 1,
	CNPC_Q2GUNNER,
	CNPC_Q2IRONMAIDEN,
	CNPC_Q2BERSERKER,
	CNPC_Q2ENFORCER,
	CNPC_Q2GLADIATOR,
	CNPC_Q2TANK,
	CNPC_Q2SUPERTANK,
	CNPC_Q2MAKRON
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

	cnpc_q2soldier::Register();
	cnpc_q2gunner::Register();
	cnpc_q2ironmaiden::Register();
	cnpc_q2berserker::Register();
	cnpc_q2enforcer::Register();
	cnpc_q2gladiator::Register();
	cnpc_q2tank::Register();
	cnpc_q2supertank::Register();
	cnpc_q2makron::Register();
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
		case CNPC_Q2SOLDIER:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2soldier::weapon_q2soldier@ pWeapon = cast<cnpc_q2soldier::weapon_q2soldier@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
			{
				if( pWeapon.m_iState == 3 ) //STATE_DUCKING
					pDamageInfo.flDamage *= 0.5;

				pWeapon.HandlePain( pDamageInfo.flDamage );
			}

			break;
		}

		case CNPC_Q2GUNNER:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2gunner::weapon_q2gunner@ pWeapon = cast<cnpc_q2gunner::weapon_q2gunner@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
			{
				if( pWeapon.m_iState == 3 ) //STATE_DUCKING
					pDamageInfo.flDamage *= 0.5;

				pWeapon.HandlePain( pDamageInfo.flDamage );
			}

			break;
		}

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

		case CNPC_Q2ENFORCER:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2enforcer::weapon_q2enforcer@ pWeapon = cast<cnpc_q2enforcer::weapon_q2enforcer@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

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

		case CNPC_Q2MAKRON:
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
			cnpc_q2makron::weapon_q2makron@ pWeapon = cast<cnpc_q2makron::weapon_q2makron@>( CastToScriptClass(pPlayer.m_hActiveItem.GetEntity()) );

			if( pWeapon !is null and pWeapon.m_pDriveEnt !is null )
				pWeapon.HandlePain( pDamageInfo.flDamage );

			break;
		}

		default: break;
	}

	return HOOK_CONTINUE;
}

//More true to the original ??
void ThrowGib( EHandle hEntity, int iCount, const string &in sGibName, float flDamage, int iBone = -1, int iType = 0, int iSkin = 0 )
{
	CBaseEntity@ pEntity = hEntity.GetEntity();
	if( pEntity is null ) return;

	for( int i = 0; i < iCount; i++ )
	{
		CGib@ pGib = g_EntityFuncs.CreateGib( pEntity.pev.origin, g_vecZero );
		pGib.Spawn( sGibName );
		pGib.pev.skin = iSkin;

		if( iBone >= 0 )
		{
			Vector vecBonePos;
			g_EngineFuncs.GetBonePosition( pEntity.edict(), iBone, vecBonePos, void );
			g_EntityFuncs.SetOrigin( pGib, vecBonePos );
		}
		else
		{
			Vector vecOrigin = pEntity.pev.origin;

			vecOrigin.x = pEntity.pev.absmin.x + pEntity.pev.size.x * (Math.RandomFloat(0 , 1));
			vecOrigin.y = pEntity.pev.absmin.y + pEntity.pev.size.y * (Math.RandomFloat(0 , 1));
			vecOrigin.z = pEntity.pev.absmin.z + pEntity.pev.size.z * (Math.RandomFloat(0 , 1)) + 1;

			g_EntityFuncs.SetOrigin( pGib, vecOrigin );
		}

		pGib.pev.velocity = VelocityForDamage( flDamage );

		pGib.pev.velocity.x += Math.RandomFloat( -0.15, 0.15 );
		pGib.pev.velocity.y += Math.RandomFloat( -0.25, 0.15 );
		pGib.pev.velocity.z += Math.RandomFloat( -0.2, 1.9 );

		pGib.pev.avelocity.x = Math.RandomFloat( 70, 200 );
		pGib.pev.avelocity.y = Math.RandomFloat( 70, 200 );

		pGib.LimitVelocity();

		if( iType == BREAK_FLESH )
		{
			pGib.m_bloodColor = BLOOD_COLOR_RED;
			pGib.m_cBloodDecals = 5;
			pGib.m_material = matFlesh;
			g_WeaponFuncs.SpawnBlood( pGib.pev.origin, BLOOD_COLOR_RED, 400 );
		}
		else
			pGib.m_bloodColor = DONT_BLEED;
	}
}

/*void ThrowGib( int iCount, const string &in sGibName, float flDamage, int iType, bool bHead = false )
{
	Vector vecOrigin = pev.origin;
	Vector vecVelocity = VelocityForDamage( flDamage );

	if( bHead)
		vecOrigin.z += pev.size.z;
	else
		vecOrigin.z += pev.size.z * 0.5;

	NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		m1.WriteByte( TE_BREAKMODEL );
		m1.WriteCoord( vecOrigin.x ); //position x y z
		m1.WriteCoord( vecOrigin.y );
		m1.WriteCoord( vecOrigin.z );
		m1.WriteCoord( 1 ); //size x y z
		m1.WriteCoord( 1 );
		m1.WriteCoord( 1 );
		m1.WriteCoord( vecVelocity.x ); //velocity x y z
		m1.WriteCoord( vecVelocity.y );
		m1.WriteCoord( vecVelocity.z );
		m1.WriteByte( 3 ); //random velocity in 10's
		m1.WriteShort( g_EngineFuncs.ModelIndex(sGibName) );
		m1.WriteByte( iCount ); //count
		m1.WriteByte( Math.RandomLong(100, 200) ); //life in 0.1 secs
		m1.WriteByte( iType ); //flags
	m1.End();

	if( iType == BREAK_FLESH )
		g_WeaponFuncs.SpawnBlood( vecOrigin, BLOOD_COLOR_RED, 400 );
}*/

Vector VelocityForDamage( float flDamage )
{
	Vector vec( Math.RandomFloat(-200, 200), Math.RandomFloat(-200, 200), Math.RandomFloat(300, 400) );

	if( flDamage > 50 )
		vec = vec * 0.7;
	else if( flDamage > 200 )
		vec = vec * 2;
	else
		vec = vec * 10;

	return vec;
}

/*Vector VelocityForDamage( float flDamage )
{
	return Vector( Math.RandomFloat(-1.0, 1.0) * flDamage, Math.RandomFloat(-1.0, 1.0) * flDamage, Math.RandomFloat(-1.0, 1.0) * flDamage + 200.0 );
}*/

} //namespace Q2 END

} //namespace CNPC END


/* FIXME
*/

/* TODO
	Flinch animations
*/