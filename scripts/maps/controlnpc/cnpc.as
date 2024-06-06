#include "CBaseDriveWeapon"
#include "headcrab"
#include "agrunt"
#include "icky"
#include "pitdrone"

#include "turret"

void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @CNPC::ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @CNPC::PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::PlayerTakeDamage );

	cnpc_headcrab::Register();
	cnpc_agrunt::Register();
	cnpc_icky::Register();
	cnpc_pitdrone::Register();

	cnpc_turret::Register();
}

namespace CNPC
{

const bool PVP	= false; //TODO

//xen
const int HEADCRAB_SLOT			= 1;
const int HEADCRAB_POSITION	= 10;
const int AGRUNT_SLOT				= 1;
const int AGRUNT_POSITION		= 11;
const int ICKY_SLOT					= 1;
const int ICKY_POSITION				= 12;
const int PITDRONE_SLOT			= 1;
const int PITDRONE_POSITION	= 13;

//military
const int TURRET_SLOT				= 2;
const int TURRET_POSITION		= 10;

const string sCNPCKV = "$i_cnpc_iscontrollingnpc";
const string sCNPCKVPainTime = "$f_cnpc_nextpaintime";

const float flModelToGameSpeedModifier = 1.650124131504528; //gotten from player maxspeed (270) divided by player model speed (163.624054)

const array<string> arrsCNPCWeapons =
{
	"weapon_headcrab",
	"weapon_agrunt",
	"weapon_icky",
	"weapon_pitdrone",
	"weapon_turret"
};

enum cnpc_e
{
	CNPC_HEADCRAB = 1,
	CNPC_AGRUNT,
	CNPC_ICKY,
	CNPC_PITDRONE,
	CNPC_TURRET
};

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
			/*if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );*/

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

		/*case CNPC_TURRET:
		{
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			//if (pev->health <= 10)
			//{
				//if (m_iOn && (1 || RANDOM_LONG(0, 0x7FFF) > 800))
				//{
					//m_fBeserk = 1;
					//SetThink(&CBaseTurret::SearchThink);
				//}
			//}

			break;
		}*/

		default: break;
	}

	//This disables damaging another player, even if they're enemies
	if( pDamageInfo.pVictim.GetClassname() == "player" and pDamageInfo.pAttacker.GetClassname() == "cnpc_turret" )
	{
		CustomKeyvalues@ pAttackerCustom = pDamageInfo.pAttacker.GetCustomKeyvalues();
		pDamageInfo.flDamage = 0.0;

		//Doesn't work, but might after some tinkering
		/*int rel = pDamageInfo.pVictim.IRelationship(pDamageInfo.pAttacker);
		bool isFriendly = rel == R_AL or rel == R_NO;

		if( isFriendly )
			pDamageInfo.flDamage = 0.0;*/
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if( pPlayer.m_hActiveItem.GetEntity() !is null )
	{
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );

		if( arrsCNPCWeapons.find(pWeapon.GetClassname()) >= 0 )
			g_EntityFuncs.Remove( pWeapon );
	}

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( sCNPCKV, 0 );

	return HOOK_CONTINUE;
}

} //namespace CNPC END

/* TODO
	Disable flashlight and USE-key while controlling a monster ??
	Disable fall damage and sounds
	Disable crouching to prevent models from sinking into the ground
	Use self.m_fSequenceFinished instead ??
	Allow for pvp
*/