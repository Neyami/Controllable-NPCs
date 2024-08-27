namespace cnpc_bigmomma
{

const bool CNPC_SETMAXSPEED		= true; //set the sv_maxspeed server variable to allow for the faster movement that a bigmomma has?
bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_bigmomma";
const string CNPC_MODEL				= "models/big_mom.mdl";
const string GIB_MODEL					= "models/big_momgibs.mdl";
const Vector CNPC_SIZEMIN			= Vector( -32, -32, 0 );
const Vector CNPC_SIZEMAX			= Vector( 32, 32, 64 );

const float CNPC_HEALTH				= 1500.0;
const float CNPC_VIEWOFS_FPV		= 128.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 128.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the bigmomma itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (178.396515 * CNPC::flModelToGameSpeedModifier);
const float SPEED_RUN					= 380; //(314.04599 * CNPC::flModelToGameSpeedModifier);
const float VELOCITY_WALK			= 160.0; //if the player's velocity is this or lower, use the walking animation

const float CD_MELEE1					= 1.2; //left or right slash
const float CD_MELEE2					= 1.4; //both legs
const float MELEE_DAMAGE			= 60.0;

const float CD_BIRTH						= 1.4;
const int MAXCHILDREN					= 20;

const float CD_MORTAR					= 2.0;

const array<string> pPainSounds = 
{
	"gonarch/gon_pain2.wav",
	"gonarch/gon_pain4.wav",
	"gonarch/gon_pain5.wav"
};

const array<string> pDieSounds = 
{
	"gonarch/gon_die1.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"gonarch/gon_step1.wav",
	"gonarch/gon_step2.wav",
	"gonarch/gon_step3.wav",
	"gonarch/gon_sack1.wav",
	"gonarch/gon_sack2.wav",
	"gonarch/gon_sack3.wav",
	"gonarch/gon_attack1.wav",
	"gonarch/gon_attack2.wav",
	"gonarch/gon_attack3.wav",
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"gonarch/gon_alert1.wav",
	"gonarch/gon_alert2.wav",
	"gonarch/gon_alert3.wav",
	"gonarch/gon_birth1.wav",
	"gonarch/gon_birth2.wav",
	"gonarch/gon_birth3.wav"
};

enum sound_e
{
	SND_STEP1 = 1,
	SND_STEP2,
	SND_STEP3,
	SND_SACK1,
	SND_SACK2,
	SND_SACK3,
	SND_ATTACK1,
	SND_ATTACK2,
	SND_ATTACK3,
	SND_HIT1,
	SND_HIT2,
	SND_HIT3,
	SND_SCREAM1,
	SND_SCREAM2,
	SND_SCREAM3,
	SND_BIRTH1,
	SND_BIRTH2,
	SND_BIRTH3
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_IDLE_FIDGET,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_DEATH,
	ANIM_MELEE1,
	ANIM_MELEE2_L,
	ANIM_MELEE2_R,
	ANIM_SPAWN_BABYCRAB,
	ANIM_MORTAR,
	ANIM_DEFEND = 11
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_MELEE,
	STATE_RANGE,
	STATE_BIRTH,
	STATE_DEFEND
};

class weapon_bigmomma : CBaseDriveWeapon
{
	private float m_flCrabTime; //cooldown
	private bool m_bChildPair;
	private int m_iSpitSprite;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( GIB_MODEL );
		g_Game.PrecacheOther( "bmortar" );
		m_iSpitSprite = g_Game.PrecacheModel( "sprites/mommaspout.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_bigmomma.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_bigmomma.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_bigmomma_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::BIGMOMMA_SLOT - 1;
		info.iPosition			= CNPC::BIGMOMMA_POSITION - 1;
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
			if( m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_iState = STATE_MELEE;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( Math.RandomLong(ANIM_MELEE1, ANIM_MELEE2_R) );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_MELEE1;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			{
				self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
				return;
			}

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_iState = STATE_RANGE;
			SetAnim( ANIM_MORTAR );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_MORTAR; //Math.RandomFloat( 2, 15 );
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
			cnpc_bigmomma@ pDriveEnt = cast<cnpc_bigmomma@>(CastToScriptClass(m_pDriveEnt));
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
			DoIdleSound();
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			CheckBirthInput();
			CheckDefendInput();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState > STATE_RUN ) return;

		m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				SetAnim( ANIM_WALK );
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_iState == STATE_MELEE and IsBetween2(m_pDriveEnt.pev.sequence, ANIM_MELEE1, ANIM_MELEE2_R) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_RANGE and m_pDriveEnt.pev.sequence == ANIM_MORTAR and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_BIRTH and m_pDriveEnt.pev.sequence == ANIM_SPAWN_BABYCRAB and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_DEFEND and m_pDriveEnt.pev.sequence == ANIM_DEFEND and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_iState = STATE_IDLE;
				SetAnim( ANIM_IDLE );
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void HandleAnimEvent( int iSequence )
	{
		if( iSequence > ANIM_MORTAR or iSequence == ANIM_DEATH ) return;

		switch( iSequence )
		{
			case ANIM_IDLE:
			{
				if( GetFrame(31, 1) and m_uiAnimationState == 0 ) { SackSound(); m_uiAnimationState++; }
				else if( GetFrame(31, 10) and m_uiAnimationState == 1 ) { SackSound(); m_uiAnimationState++; }
				else if( GetFrame(31, 20) and m_uiAnimationState == 2 ) { SackSound(); m_uiAnimationState = 0; }

				break;
			}

			case ANIM_IDLE_FIDGET:
			{
				if( GetFrame(31, 8) and m_uiAnimationState == 0 ) { SackSound(); m_uiAnimationState++; }
				else if( GetFrame(31, 15) and m_uiAnimationState == 1 ) { SackSound(); m_uiAnimationState = 0; }

				break;
			}

			case ANIM_WALK:
			{
				if( GetFrame(49, 20) and m_uiAnimationState == 0 ) { FootStep(false); m_uiAnimationState++; }
				else if( GetFrame(49, 24) and m_uiAnimationState == 1 ) { FootStep(true); m_uiAnimationState++; }
				else if( GetFrame(49, 47) and m_uiAnimationState == 2 ) { FootStep(false); m_uiAnimationState++; }
				else if( GetFrame(49, 48) and m_uiAnimationState == 3 ) { FootStep(true); m_uiAnimationState = 0; }

				break;
			}

			case ANIM_RUN:
			{
				if( GetFrame(23, 4) and m_uiAnimationState == 0 ) { FootStep(false); m_uiAnimationState++; }
				else if( GetFrame(23, 7) and m_uiAnimationState == 1 ) { SackSound(); m_uiAnimationState++; }
				else if( GetFrame(23, 8) and m_uiAnimationState == 2 ) { FootStep(true); m_uiAnimationState++; }
				else if( GetFrame(23, 21) and m_uiAnimationState == 3 ) { FootStep(false); m_uiAnimationState++; }
				else if( GetFrame(23, 22) and m_uiAnimationState == 4 ) { FootStep(true); m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE1:
			{
				if( GetFrame(41, 15) and m_uiAnimationState == 0 ) { AttackSound(); m_uiAnimationState++; }
				else if( GetFrame(41, 20) and m_uiAnimationState == 1 ) { MeleeAttack(); m_uiAnimationState++; }
				else if( GetFrame(41, 30) and m_uiAnimationState == 2 ) { SackSound(); m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE2_L:
			{
				if( GetFrame(20, 8) and m_uiAnimationState == 0 ) { AttackSound(); ScreamSound(); MeleeAttack(); m_uiAnimationState++; }

				break;
			}

			case ANIM_MELEE2_R:
			{
				if( GetFrame(23, 8) and m_uiAnimationState == 0 ) { MeleeAttack(); ScreamSound(); m_uiAnimationState++; }

				break;
			}

			case ANIM_SPAWN_BABYCRAB:
			{
				if( GetFrame(31, 8) and m_uiAnimationState == 0 ) { LayHeadcrab(); BirthSound(); AttackSound(); m_uiAnimationState++; }

				break;
			}

			case ANIM_MORTAR:
			{
				if( GetFrame(17, 10) and m_uiAnimationState == 0 ) { LaunchMortar(); AttackSound(); m_uiAnimationState++; }

				break;
			}
		}
	}

	void FootStep( bool bRight )
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), bRight ? CHAN_BODY : CHAN_ITEM, arrsCNPCSounds[Math.RandomLong(SND_STEP1, SND_STEP3)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
	}

	void SackSound()
	{
		if( Math.RandomLong(0, 100) < 30 )
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_SACK1, SND_SACK3)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
	}

	void AttackSound()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_ATTACK1, SND_ATTACK3)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
	}

	void ScreamSound()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SCREAM1, SND_SCREAM3)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
	}

	void BirthSound()
	{
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_BIRTH1, SND_BIRTH3)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
	}

	void MeleeAttack()
	{
		Vector vecForward, vecRight;

		g_EngineFuncs.AngleVectors( m_pDriveEnt.pev.angles, vecForward, vecRight, void );

		Vector vecCenter = m_pDriveEnt.pev.origin + vecForward * 128;
		Vector mins = vecCenter - Vector( 64, 64, 0 );
		Vector maxs = vecCenter + Vector( 64, 64, 64 );

		array<CBaseEntity@> pList(8);
		int count = g_EntityFuncs.EntitiesInBox( pList, mins, maxs, (FL_MONSTER | FL_CLIENT) ); 
		CBaseEntity@ pHurt = null;

		for( int i = 0; i < count and pHurt is null; i++ )
		{
			if( pList[i] !is m_pPlayer )
			{
				if( pList[i].pev.owner !is m_pPlayer.edict() )
					@pHurt = pList[i];
			}
		}

		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, MELEE_DAMAGE, (DMG_CRUSH | DMG_SLASH) );
				pHurt.pev.punchangle.x = 15;

				switch( m_pDriveEnt.pev.sequence )
				{
					case ANIM_MELEE2_L:
					{
						pHurt.pev.velocity = pHurt.pev.velocity + (vecForward * 150) + Vector(0, 0, 250) - (vecRight * 200);

						break;
					}

					case ANIM_MELEE2_R:
					{
						pHurt.pev.velocity = pHurt.pev.velocity + (vecForward * 150) + Vector(0, 0, 250) + (vecRight * 200);

						break;
					}

					case ANIM_MELEE1:
					{
						pHurt.pev.velocity = pHurt.pev.velocity + (vecForward * 220) + Vector(0, 0, 200);

						break;
					}
				}
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT1)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
	}

	bool CanLayCrab()
	{ 
		if( m_flCrabTime < g_Engine.time and CheckForBabies() < MAXCHILDREN )
		{
			// Don't spawn crabs inside each other
			Vector mins = m_pDriveEnt.pev.origin - Vector( 32, 32, 0 );
			Vector maxs = m_pDriveEnt.pev.origin + Vector( 32, 32, 0 );

			array<CBaseEntity@> pList(2);
			int count = g_EntityFuncs.EntitiesInBox( pList, mins, maxs, FL_MONSTER );
			for( int i = 0; i < count; i++ )
			{
				if( pList[i] != m_pDriveEnt )	// Don't hurt yourself!
					return false;
			}

			return true;
		}

		return false;
	}

	void LayHeadcrab()
	{
		CBaseEntity@ pChild = g_EntityFuncs.Create( "monster_babycrab", m_pDriveEnt.pev.origin, m_pDriveEnt.pev.angles, false, m_pPlayer.edict() );
		g_EntityFuncs.DispatchKeyValue( pChild.edict(), "is_player_ally", "1" );
		pChild.pev.spawnflags |= 0x80000000; //SF_MONSTER_FALL_TO_GROUND

		// Is this the second crab in a pair?
		if( m_bChildPair )
		{
			m_flCrabTime = g_Engine.time + Math.RandomFloat( 5, 10 );
			m_bChildPair = false;
		}
		else
		{
			m_flCrabTime = g_Engine.time + Math.RandomFloat( 0.5, 2.5 );
			m_bChildPair= true;
		}

		TraceResult tr;
		g_Utility.TraceLine( m_pDriveEnt.pev.origin, m_pDriveEnt.pev.origin - Vector(0, 0, 100), ignore_monsters, m_pDriveEnt.edict(), tr );
		g_Utility.DecalTrace( tr, DECAL_MOMMABIRTH );

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_BIRTH1, SND_BIRTH3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
	}

	int CheckForBabies()
	{
		int iCrabCount = 0;

		CBaseEntity@ pChild = null;
		while( (@pChild = g_EntityFuncs.FindEntityByClassname(pChild, "monster_babycrab")) !is null )
		{
			if( pChild.pev.deadflag == DEAD_NO and pChild.pev.owner is m_pPlayer.edict() )
				iCrabCount++;
		}

		return iCrabCount;
	}

	void CheckBirthInput()
	{
		if( m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or !CanLayCrab() ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			m_iState = STATE_BIRTH;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_SPAWN_BABYCRAB );
		}
	}

	void LaunchMortar()
	{
		Vector vecStartPos = m_pDriveEnt.pev.origin;
		vecStartPos.z += 180;

		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_SACK1, SND_SACK3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		CBaseEntity@ pBomb = g_EntityFuncs.Create( "bmortar", vecStartPos, g_vecZero, false, m_pPlayer.edict() );
		pBomb.pev.gravity = 1.0;
		pBomb.pev.scale = 2.5;

		TraceResult tr;
		g_Utility.TraceLine( m_pPlayer.GetGunPosition(), m_pPlayer.GetGunPosition() + g_Engine.v_forward * 4096, ignore_monsters, m_pDriveEnt.edict(), tr );
		Vector vecVelocity = VecCheckSplatToss( vecStartPos, tr.vecEndPos, Math.RandomFloat(150, 500) );
		if( vecVelocity == g_vecZero ) vecVelocity = g_Engine.v_forward * 750;
		pBomb.pev.velocity = vecVelocity;

		MortarSpray( vecStartPos, Vector(0, 0, 1), m_iSpitSprite, 24 );
	}

	void MortarSpray( Vector vecOrigin, Vector vecDirection, int iSpriteModel, int iCount )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_SPRITE_SPRAY );
			m1.WriteCoord( vecOrigin.x );	// pos
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteCoord( vecDirection.x );	// dir
			m1.WriteCoord( vecDirection.y );
			m1.WriteCoord( vecDirection.z );
			m1.WriteShort( iSpriteModel );	// model
			m1.WriteByte( iCount );			// count
			m1.WriteByte( 130 );			// speed
			m1.WriteByte( 80 );			// noise (client will divide by 100)
		m1.End();
	}

	Vector VecCheckSplatToss( Vector vecSpot1, Vector vecSpot2, float maxHeight )
	{
		TraceResult		tr;
		Vector			vecMidPoint;// halfway point between Spot1 and Spot2
		Vector			vecApex;// highest point 
		Vector			vecScale;
		Vector			vecGrenadeVel;
		Vector			vecTemp;
		float				flGravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );

		// calculate the midpoint and apex of the 'triangle'
		vecMidPoint = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
		g_Utility.TraceLine( vecMidPoint, vecMidPoint + Vector(0, 0, maxHeight), ignore_monsters, m_pDriveEnt.edict(), tr );
		vecApex = tr.vecEndPos;

		g_Utility.TraceLine( vecSpot1, vecApex, dont_ignore_monsters, m_pDriveEnt.edict(), tr );
		if( tr.flFraction != 1.0 )
		{
			// fail!
			return g_vecZero;
		}

		// Don't worry about actually hitting the target, this won't hurt us!

		// How high should the grenade travel (subtract 15 so the grenade doesn't hit the ceiling)?
		float height = (vecApex.z - vecSpot1.z) - 15;
		// How fast does the grenade need to travel to reach that height given gravity?
		float speed = sqrt( 2 * flGravity * height );

		// How much time does it take to get there?
		float time = speed / flGravity;
		vecGrenadeVel = (vecSpot2 - vecSpot1);
		vecGrenadeVel.z = 0;
		float distance = vecGrenadeVel.Length();

		// Travel half the distance to the target in that time (apex is at the midpoint)
		vecGrenadeVel = vecGrenadeVel * ( 0.5 / time );
		// Speed to offset gravity at the desired height
		vecGrenadeVel.z = speed;

		return vecGrenadeVel;
	}

	void CheckDefendInput()
	{
		 if( m_iState > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_DUCK) != 0 )
		{
			m_iState = STATE_DEFEND;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_DEFEND );
		}
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_bigmomma", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;

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
			m1.WriteString( "cam_idealdist 256\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_BIGMOMMA );

		if( CNPC_SETMAXSPEED )
			g_EngineFuncs.CVarSetFloat( "sv_maxspeed", int(SPEED_RUN) );
	}

	void DoFirstPersonView()
	{
		cnpc_bigmomma@ pDriveEnt = cast<cnpc_bigmomma@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_bigmomma_rend_" + m_pPlayer.entindex();
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
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_bigmomma : CBaseDriveEntity
{
	Vector m_vecAttackDir; //for spawning gibs

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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_WALK) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( (m_pOwner.pev.button & (IN_ATTACK|IN_ATTACK2|IN_RELOAD)) != 0 )
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
			SpawnRandomGibs( 5 );
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void DieThink()
	{
		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );

		SetThink( ThinkFunction(this.SUB_StartFadeOut) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnRandomGibs( int iAmount )
	{
		for( int i = 0 ; i < iAmount ; i++ )
		{
			CGib@ pGib = g_EntityFuncs.CreateGib( pev.origin, g_vecZero );

			pGib.Spawn( GIB_MODEL );

			if( i <= 1 )
				pGib.pev.body = i;
			else
				pGib.pev.body = 2;

			// spawn the gib somewhere in the monster's bounding volume
			if( pGib.pev.body == 0 ) //drop the shell from a greater height
			{
				pGib.pev.origin.x = pev.absmin.x;
				pGib.pev.origin.y = pev.absmin.y;
				pGib.pev.origin.z = pev.absmin.z + 150.0;
			}
			else
			{
				pGib.pev.origin.x = pev.absmin.x + pev.size.x * (Math.RandomFloat(0 , 1));
				pGib.pev.origin.y = pev.absmin.y + pev.size.y * (Math.RandomFloat(0 , 1));
				pGib.pev.origin.z = pev.absmin.z + pev.size.z * (Math.RandomFloat(0 , 1)) + 1;	// absmin.z is in the floor because the engine subtracts 1 to enlarge the box
			}

			// make the gib fly away from the attack vector
			pGib.pev.velocity = m_vecAttackDir * -1;

			// mix in some noise
			pGib.pev.velocity.x += Math.RandomFloat( -0.15, 0.15 );
			pGib.pev.velocity.y += Math.RandomFloat( -0.25, 0.15 );
			pGib.pev.velocity.z += Math.RandomFloat( -0.2, 1.9 );

			float flRand = 150.0;
			if( pGib.pev.body == 2 ) flRand = 100.0;
			pGib.pev.velocity = pGib.pev.velocity * Math.RandomFloat( flRand, 200 );

			pGib.pev.avelocity.x = Math.RandomFloat( 70, 200 );
			pGib.pev.avelocity.y = Math.RandomFloat( 70, 200 );

			pGib.m_bloodColor = BLOOD_COLOR_GREEN;

			if( pev.health <= -50 )
			{
				if( pev.health <= -200.0 )
					pGib.pev.velocity = pGib.pev.velocity * 3.0;
				else
					pGib.pev.velocity = pGib.pev.velocity * 2.0;
			}

			pGib.pev.solid = SOLID_BBOX;
			g_EntityFuncs.SetSize( pGib.pev, g_vecZero, g_vecZero );

			pGib.LimitVelocity();

			g_WeaponFuncs.SpawnBlood( Vector(pev.absmin.x, pev.absmin.y, pev.absmin.z + 200.0), BLOOD_COLOR_GREEN, 400 );
		}
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

final class info_cnpc_bigmomma : CNPCSpawnEntity
{
	info_cnpc_bigmomma()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_bigmomma::info_cnpc_bigmomma", "info_cnpc_bigmomma" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_bigmomma::cnpc_bigmomma", "cnpc_bigmomma" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_bigmomma::weapon_bigmomma", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_bigmomma" );
	g_Game.PrecacheOther( "cnpc_bigmomma" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_bigmomma END

/* FIXME
*/

/* TODO
	CNPC_NPC_HITBOX
*/