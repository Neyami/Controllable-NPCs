#include "CBaseDriveWeapon"
#include "headcrab"
#include "houndeye"
#include "islave"
#include "agrunt"
#include "icky"
#include "pitdrone"
#include "strooper"
#include "gonome"

#include "fassn"
#include "mturret"
#include "turret"

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

	cnpc_fassn::Register();
	cnpc_mturret::Register();
	cnpc_turret::Register();
}

namespace CNPC
{

int g_iShockTrooperQuestion;

const bool PVP										= false; //TODO
const float CNPC_SPEAK_DISTANCE	= 768.0;

//xen
const int HEADCRAB_SLOT			= 1;
const int HEADCRAB_POSITION	= 10;
const int HOUNDEYE_SLOT			= 1;
const int HOUNDEYE_POSITION	= 11;
const int ISLAVE_SLOT				= 1;
const int ISLAVE_POSITION			= 12;
const int AGRUNT_SLOT				= 1;
const int AGRUNT_POSITION		= 13;
const int ICKY_SLOT					= 1;
const int ICKY_POSITION				= 14;
const int PITDRONE_SLOT			= 1;
const int PITDRONE_POSITION	= 15;
const int STROOPER_SLOT			= 1;
const int STROOPER_POSITION	= 16;
const int GONOME_SLOT				= 1;
const int GONOME_POSITION		= 17;

//military
const int FASSN_SLOT					= 2;
const int FASSN_POSITION			= 10;
const int MTURRET_SLOT				= 2;
const int MTURRET_POSITION		= 11;
const int TURRET_SLOT				= 2;
const int TURRET_POSITION		= 12;

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

	"weapon_fassn",
	"weapon_mturret",
	"weapon_turret"
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

	CNPC_FASSN,
	CNPC_MTURRET,
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
	if( pDamageInfo.pVictim.GetClassname() == "player" and pDamageInfo.pAttacker.GetClassname() == "player" )
	{
		if( pDamageInfo.pVictim.Classify() == pDamageInfo.pAttacker.Classify() )
			return HOOK_CONTINUE;
	}

	if( pDamageInfo.pVictim.GetClassname() == "player" and (pDamageInfo.pAttacker.GetClassname() == "cnpc_turret" or pDamageInfo.pAttacker.GetClassname() == "cnpc_mturret") )
	{
		//hacky isFriendly check
		if( pDamageInfo.pAttacker.pev.owner !is null )
		{
			CBaseEntity@ pOwner = g_EntityFuncs.Instance(pDamageInfo.pAttacker.pev.owner);
			if( pDamageInfo.pVictim.Classify() == pOwner.Classify() )
				pDamageInfo.flDamage = 0.0;
		}
	}

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

		/*TODO, add berserk mode??
		case CNPC_TURRET:
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

	string sWeaponName;
	string sModel;
	int iStartAnim;
	Vector vecSizeMin, vecSizeMax;

	int ObjectCaps() { return m_bActive ? (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE) : BaseClass.ObjectCaps(); }

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

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, sModel );
		g_EntityFuncs.SetSize( self.pev, vecSizeMin, vecSizeMax );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		if( CNPC::arrsFlyingMobs.find(self.GetClassname()) < 0 )
			g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = iStartAnim;
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
				g_EntityFuncs.SetOrigin( pActivator, pev.origin );
				pActivator.pev.angles = pev.angles;
				pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
				@m_pCNPCWeapon = g_EntityFuncs.Create( sWeaponName, pActivator.pev.origin, g_vecZero, true );
				m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

				g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
				g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );

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