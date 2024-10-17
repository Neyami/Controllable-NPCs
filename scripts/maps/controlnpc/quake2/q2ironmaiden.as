namespace cnpc_q2ironmaiden
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2ironmaiden";
const string CNPC_MODEL				= "models/quake2/monsters/ironmaiden/ironmaiden.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/ironmaiden/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/ironmaiden/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/ironmaiden/gibs/foot.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/ironmaiden/gibs/head.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/ironmaiden/gibs/tube.mdl";

const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 175.0;
const float CNPC_VIEWOFS_FPV		= 43.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 42.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the ironmaiden itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_WALK					= 270*0.6;

const float CD_ROCKET					= 2.0;
const float ROCKET_DMG				= 50;
const float ROCKET_SPEED				= 750;
const float CNPC_MAXPITCH			= 30.0;

const float CD_MELEE						= 1.5;
const float MELEE_RANGE				= 80.0;
const int MELEE_DAMAGE				= 10; //+Math.RandomLong(0, 6)
const float MELEE_KICK					= 100.0;

const array<string> pPainSounds = 
{
	"quake2/npcs/ironmaiden/chkpain1.wav",
	"quake2/npcs/ironmaiden/chkpain2.wav",
	"quake2/npcs/ironmaiden/chkpain3.wav"
};

const array<string> pDieSounds = 
{
	"quake2/npcs/ironmaiden/chkdeth1.wav",
	"quake2/npcs/ironmaiden/chkdeth2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/ironmaiden/chkidle1.wav",
	"quake2/npcs/ironmaiden/chkidle2.wav",
	"quake2/npcs/ironmaiden/chksght1.wav",
	"quake2/npcs/ironmaiden/chksrch1.wav",
	"quake2/npcs/ironmaiden/chkatck1.wav",
	"quake2/npcs/ironmaiden/chkatck2.wav",
	"quake2/npcs/ironmaiden/chkatck3.wav",
	"quake2/npcs/ironmaiden/chkatck4.wav",
	"quake2/npcs/ironmaiden/chkatck5.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_IDLE1,
	SND_IDLE2,
	SND_SIGHT,
	SND_SEARCH,
	SND_ROCKET_PRELAUNCH,
	SND_ROCKET_LAUNCH,
	SND_MELEE_SWING,
	SND_MELEE_HIT,
	SND_ROCKET_RELOAD
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_ROCKET,
	ANIM_MELEE = 6,
	ANIM_DEATH1 = 10,
	ANIM_DEATH2,
	ANIM_DUCK,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_WALK
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_DUCKING,
	STATE_PAIN
};

final class weapon_q2ironmaiden : CBaseDriveWeaponQ2
{
	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2ironmaiden.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2ironmaiden.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2ironmaiden_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2IRONMAIDEN_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2IRONMAIDEN_POSITION - 1;
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

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
		}

		return self.DefaultDeploy( "", "", 0, "" );
	}

	bool CanHolster()
	{
		return false;
	}

	void Holster( int skipLocal = 0 )
	{
		if( m_pDriveEnt !is null )
			@m_pDriveEnt.pev.owner = null;

		ResetPlayer();

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ROCKET );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_ROCKET;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_MELEE );
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
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
		}
		else
		{
			cnpc_q2ironmaiden@ pDriveEnt = cast<cnpc_q2ironmaiden@>(CastToScriptClass(m_pDriveEnt));
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
			DoSearchSound();
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			CheckDuckInput();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		SetSpeed( int(SPEED_WALK) );

		if( m_pDriveEnt.pev.sequence != ANIM_WALK )
		{
			SetState( STATE_MOVING );
			SetSpeed( int(SPEED_WALK) );
			SetAnim( ANIM_WALK );
		}
		else
			m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
	}

	void DoIdleAnimation()
	{
		if( GetState() >= STATE_ATTACK and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetSpeed( int(SPEED_WALK) );
				SetState( STATE_IDLE );
				SetAnim( ANIM_IDLE );
			}
			else if( GetState(STATE_IDLE) and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandlePain( float flDamage )
	{
		m_pDriveEnt.pev.dmg = flDamage;

		if( m_pPlayer.pev.health < (CNPC_HEALTH * 0.5) )
			m_pDriveEnt.pev.skin = 1;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0,(pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

		if( GetState(STATE_DUCKING) )
			return;

		if( flDamage <= 10 )
			SetAnim( ANIM_PAIN1 );
		else if( flDamage <= 25 )
			SetAnim( ANIM_PAIN2 );
		else
			SetAnim( ANIM_PAIN3 );

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_IDLE_FIDGET:
			{
				if( GetFrame(30, 8) and m_uiAnimationState == 0 ) { ChickMoan(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE:
			{
				if( GetFrame(16, 4) and m_uiAnimationState <= 1 ) { ChickSlash(); m_uiAnimationState++; }
				else if( GetFrame(16, 5) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(16, 11) and m_uiAnimationState == 2 ) { ChickReslash(); m_uiAnimationState++; }
				else if( GetFrame(16, 15) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ROCKET:
			{
				if( GetFrame(32, 0) and m_uiAnimationState == 0 ) { ChickPreLaunch(); m_uiAnimationState++; }
				else if( GetFrame(32, 8) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(32, 13) and m_uiAnimationState == 2 ) { FireRocket(); SetSpeed(0); m_uiAnimationState++; } //refire at 12
				else if( GetFrame(32, 14) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(32, 17) and m_uiAnimationState == 4 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(32, 20) and m_uiAnimationState == 5 ) { ChickReload(); SetSpeed(int(SPEED_WALK));m_uiAnimationState++; }
				else if( GetFrame(32, 22) and m_uiAnimationState == 6 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(32, 26) and m_uiAnimationState == 7 ) { ChickRefire(); Footstep(); m_uiAnimationState++; }
				else if( GetFrame(32, 31) and m_uiAnimationState == 8 ) { Footstep(); SetSpeed(0); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 9 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DUCK:
			{
				if( GetFrame(7, 3) ) { DoDucking(); }

				break;
			}

			case ANIM_WALK:
			{
				if( GetFrame(11, 1) and m_uiAnimationState == 0 )
				{
					Vector vecLeftFoot;
					m_pDriveEnt.GetAttachment( 1, vecLeftFoot, void ); //for more precision lmao www
					Footstep( PITCH_NORM, true, vecLeftFoot );
					m_uiAnimationState++;
				}
				else if( GetFrame(11, 6) and m_uiAnimationState == 1 )
				{
					Vector vecRightFoot;
					m_pDriveEnt.GetAttachment( 2, vecRightFoot, void );
					Footstep( PITCH_NORM, true, vecRightFoot );
					m_uiAnimationState++;
				}
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 )
					m_uiAnimationState = 0;

				break;
			}

			case ANIM_PAIN3:
			{
				if( GetFrame(21, 1) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(21, 3) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(21, 5) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(21, 20) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void Footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		CNPC::monster_footstep( EHandle(m_pDriveEnt), EHandle(m_pPlayer), m_iStepLeft, iPitch, bSetOrigin, vecSetOrigin );
	}

	void ChickMoan()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE2)], VOL_NORM, ATTN_IDLE );
	}

	void ChickSlash()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_IDLE );

		int iDamage = MELEE_DAMAGE + Math.RandomLong(0, 6);
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, iDamage, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				Math.MakeVectors( m_pDriveEnt.pev.angles );
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK;
			}

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
		}
	}

	void ChickReslash()
	{
		if( GetButton(IN_ATTACK2) and Math.RandomFloat(0.0, 1.0) <= 0.9 )
		{
			m_uiAnimationState = 0;
			m_pDriveEnt.pev.frame = SetFrame( 16, 3 );
		}
	}

	void ChickPreLaunch()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_ROCKET_PRELAUNCH], VOL_NORM, ATTN_NORM );
	}

	void FireRocket()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ROCKET_LAUNCH], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( 0, vecOrigin, void );
		Math.MakeVectors( m_pDriveEnt.pev.angles );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > CNPC_MAXPITCH )
			vecAim.x = CNPC_MAXPITCH;
		else if( vecAim.x < -CNPC_MAXPITCH )
			vecAim.x = -CNPC_MAXPITCH;

		g_EngineFuncs.MakeVectors( vecAim );

		monster_fire_rocket( vecOrigin, g_Engine.v_forward, ROCKET_DMG, ROCKET_SPEED, 2.0 );
	}

	void ChickReload()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_ROCKET_RELOAD], VOL_NORM, ATTN_NORM );
	}

	void ChickRefire()
	{
		if( GetButton(IN_ATTACK) and Math.RandomFloat(0.0, 1.0) <= 0.7 )
		{
			m_uiAnimationState = 1;
			m_pDriveEnt.pev.frame = SetFrame( 32, 12 );
			SetSpeed( int(SPEED_WALK) ); //allow for moving while firing
		}
	}

	void CheckDuckInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( GetButton(IN_DUCK) )
		{
			SetState( STATE_DUCKING );
			SetSpeed( 0 );
			SetAnim( ANIM_DUCK );
		}
	}

	void DoDucking()
	{
		if( GetButton(IN_DUCK) )
			SetFramerate( 0 );
		else
			SetFramerate( 1.0 );
	}

	void spawnDriveEnt()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		vecOrigin.z -= CNPC_MODEL_OFFSET;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2ironmaiden", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2IRONMAIDEN );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2ironmaiden@ pDriveEnt = cast<cnpc_q2ironmaiden@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2ironmaiden_rend_" + m_pPlayer.entindex();
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
		SetSpeed( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_q2ironmaiden : CBaseDriveEntityQ2
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flNextOriginUpdate = g_Engine.time;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void DriveThink()
	{
		if( pev.deadflag == CNPC::DEAD_GIB )
		{
			DoDeath( true );

			return;
		}

		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and pev.sequence == ANIM_WALK )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( GetAnim(ANIM_ROCKET) or GetAnim(ANIM_MELEE) )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath( bool bGibbed = false )
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		pev.velocity = g_vecZero;

		if( bGibbed )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_GIB], VOL_NORM, ATTN_NORM );
			SpawnGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		pev.sequence = Math.RandomLong(ANIM_DEATH1, ANIM_DEATH2);
		pev.frame = 0;
		self.ResetSequenceInfo();

		int iSound = GetAnim(ANIM_DEATH1) ? 0 : 1;
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[iSound], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		ThrowGib( 2, MODEL_GIB_BONE, pev.dmg );
		ThrowGib( 3, MODEL_GIB_MEAT, pev.dmg, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_ARM, pev.dmg );
		ThrowGib( 1, MODEL_GIB_FOOT, pev.dmg );
		ThrowGib( 1, MODEL_GIB_TUBE, pev.dmg );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, BREAK_FLESH, true );
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( pev.sequence )
		{
			case ANIM_DEATH1:
			{
				if( GetFrame(12, 1) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(12, 3) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(12, 6) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(12, 10) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_DEATH2:
			{
				if( GetFrame(23, 3) and m_uiAnimationState == 0 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(23, 10) and m_uiAnimationState == 1 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(23, 16) and m_uiAnimationState == 2 ) { Footstep(); m_uiAnimationState++; }
				else if( GetFrame(23, 21) and m_uiAnimationState == 3 ) { Footstep(); m_uiAnimationState++; }
				else if( self.m_fSequenceFinished and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
		}
	}

	void Footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		CNPC::monster_footstep( EHandle(self), EHandle(self), m_iStepLeft, iPitch, bSetOrigin, vecSetOrigin );
	}

	void SUB_StartFadeOut()
	{
		if( pev.rendermode == kRenderNormal )
		{
			pev.renderamt = 255;
			pev.rendermode = kRenderTransTexture;
		}

		pev.solid = SOLID_NOT;
		pev.avelocity = g_vecZero;

		pev.nextthink = g_Engine.time + 0.1;
		SetThink( ThinkFunction(this.SUB_FadeOut) );
	}

	void SUB_FadeOut()
	{
		if( pev.renderamt > 7 )
		{
			pev.renderamt -= 7;
			pev.nextthink = g_Engine.time + 0.1;
		}
		else 
		{
			pev.renderamt = 0;
			pev.nextthink = g_Engine.time + 0.2;
			SetThink( ThinkFunction(this.SUB_Remove) );
		}
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_q2ironmaiden : CNPCSpawnEntity
{
	info_cnpc_q2ironmaiden()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2ironmaiden::info_cnpc_q2ironmaiden", "info_cnpc_q2ironmaiden" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2ironmaiden::cnpc_q2ironmaiden", "cnpc_q2ironmaiden" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2ironmaiden::weapon_q2ironmaiden", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_q2ironmaiden" );
	g_Game.PrecacheOther( "cnpc_q2ironmaiden" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2ironmaiden END

/* FIXME
*/

/* TODO
*/