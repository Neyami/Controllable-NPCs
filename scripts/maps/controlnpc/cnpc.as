#include "CBaseDriveWeapon"
//#include "headcrab"
#include "agrunt"
#include "pitdrone"

void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @CNPC::ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @CNPC::PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::PlayerTakeDamage );

	//cnpc_headcrab::Register();
	cnpc_agrunt::Register();
	cnpc_pitdrone::Register();
}

namespace CNPC
{

const string sCNPCKV = "$i_cnpc_iscontrollingnpc";
const string sCNPCKVPainTime = "$fl_cnpc_nextpaintime";

const float flModelToGameSpeedModifier = 1.650124131504528; //gotten from player maxspeed (270) divided by player model speed (163.624054)

enum cnpc_e
{
	CNPC_HEADCRAB = 1,
	CNPC_AGRUNT,
	CNPC_PITDRONE
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
		/*case CNPC_HEADCRAB:
		{
			
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(0.6, 1.2);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_headcrab::pPainSounds[Math.RandomLong(0,(cnpc_headcrab::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM ); 

			break;
		}*/

		case CNPC_AGRUNT:
		{
			
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(3.0, 4.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, cnpc_agrunt::pPainSounds[Math.RandomLong(0,(cnpc_agrunt::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 120) ); 

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

		default: break;
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if( pPlayer.m_hActiveItem.GetEntity() !is null )
	{
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );

		if( pWeapon.GetClassname() == "weapon_agrunt" or pWeapon.GetClassname() == "weapon_headcrab" or pWeapon.GetClassname() == "weapon_pitdrone" )
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
	Use self.m_fSequenceFinished instead ??
	Use different max_health for each monster ??
*/
