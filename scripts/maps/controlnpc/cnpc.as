#include "CBaseDriveWeapon"
#include "agrunt"

void MapInit()
{
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @CNPC::ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @CNPC::PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @CNPC::PlayerTakeDamage );

	cnpc_agrunt::Register();
}

namespace CNPC
{

const string sCNPCKV = "$i_cnpc_iscontrollingnpc";
const string sCNPCKVPainTime = "$fl_cnpc_nextpaintime";

enum cnpc_e
{
	CNPC_AGRUNT = 1
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
		case CNPC_AGRUNT:
		{
			
			if( pCustom.GetKeyvalue(sCNPCKVPainTime).GetFloat() > g_Engine.time )
				return HOOK_CONTINUE;

			float flNextPainTime = g_Engine.time + Math.RandomFloat(3.0, 4.0);
			pCustom.SetKeyvalue( sCNPCKVPainTime, flNextPainTime );

			g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_BODY, cnpc_agrunt::pPainSounds[Math.RandomLong(0,(cnpc_agrunt::pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(85, 120) ); 

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

		if( pWeapon.GetClassname() == "weapon_agrunt" )
			g_EntityFuncs.Remove( pWeapon );
	}

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( sCNPCKV, 0 );

	return HOOK_CONTINUE;
}

} //namespace CNPC END