namespace cnpc_kingpin
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_kingpin";
const string CNPC_MODEL				= "models/kingpin.mdl";
const Vector CNPC_SIZEMIN			= Vector( -24, -24, 0 );
const Vector CNPC_SIZEMAX			= Vector( 24, 24, 112 );

const float CNPC_HEALTH				= 450;
const float CNPC_VIEWOFS_FPV		= 40.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 40.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the kingpin itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (57.630451 * CNPC::flModelToGameSpeedModifier);
const float SPEED_RUN					= (77.845566 * CNPC::flModelToGameSpeedModifier);
const float VELOCITY_WALK			= 75.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY					= 1.5; //melee
const float MELEE_RANGE				= 100.0;
const float MELEE_DAMAGE			= 40.0;

const float CD_SECONDARY			= 4.0; //plasma ball - kingpin has a 10 second cooldown
const string SPRITE_CHARGE			= "sprites/nhth1.spr";

const float LIGHTNING_DAMAGE		= 25.0;
const string SPRITE_EYE					= "sprites/boss_glow.spr";
const string SPRITE_LIGHTGLOW	= "sprites/flare2.spr"; //when an eye discharges lightning

const string SPRITE_BEAM				= "sprites/kingpin_beam.spr"; //lightning attack and death animation
const string SPRITE_DEFLECT			= "sprites/laserbeam.spr";

//sk_kingpin_tele_blast               "15"
//sk_kingpin_plasma_blast             "80"
//sk_kingpin_telefrag                 "500"

const array<string> pPainSounds = 
{
	"kingpin/kingpin_pain1.wav",
	"kingpin/kingpin_pain2.wav",
	"kingpin/kingpin_pain3.wav"
};

const array<string> pDieSounds = 
{
	"kingpin/kingpin_death1.wav",
	"kingpin/kingpin_death2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"kingpin/kingpin_move.wav",
	"kingpin/kingpin_moveslow.wav",
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav",
	"kingpin/port_suckout1.wav",
	"kingpin/port_suckin1.wav",
	"kingpin/kingpin_idle1.wav",
	"kingpin/kingpin_idle2.wav",
	"kingpin/kingpin_idle3.wav",
	"debris/beamstart10.wav"
};

enum sound_e
{
	SND_RUN = 1,
	SND_WALK,
	SND_HIT1,
	SND_HIT2,
	SND_HIT3,
	SND_MISS1,
	SND_MISS2,
	SND_SUCKOUT,
	SND_SUCKIN,
	SND_IDLE1,
	SND_IDLE2,
	SND_IDLE3,
	SND_BEAM
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_MELEE,
	ANIM_RANGE,
	ANIM_DEATH
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_MELEE,
	STATE_RANGE
};

class weapon_kingpin : CBaseDriveWeapon
{
	bool m_bShieldOn;
	bool m_bSomeBool; //??
	private int m_iShieldFlags;
	float m_flTargetRenderamt; //??
	float m_flShieldTime;
	private int m_iStartingRenderMode;
	private int m_iStartingRenderFx;
	private float m_flStartingRenderamt;
	private Vector m_vecStartingColor;

	private int m_iPlasmaCharge, m_iPlasmaChargeBeam;
	private float m_flPlasmaBall;

	protected EHandle m_hPlasmaball;
	protected CBaseEntity@ m_pPlasmaball
	{
		get const { return m_hPlasmaball.GetEntity(); }
		set { m_hPlasmaball = EHandle(@value); }
	}

	private int m_iLightningGlow;

	protected array<EHandle> m_hEye(4);
	CSprite@ m_pEye( uint i )
	{
		return cast<CSprite@>( m_hEye[i].GetEntity() );
	}

	protected EHandle m_hEnemy;
	protected CBaseEntity@ m_pEnemy
	{
		get const { return m_hEnemy.GetEntity(); }
		set { m_hEnemy = EHandle(@value); }
	}

	protected EHandle m_hDeflectTarget;
	protected CBaseEntity@ m_pDeflectTarget
	{
		get const { return m_hDeflectTarget.GetEntity(); }
		set { m_hDeflectTarget = EHandle(@value); }
	}

	protected EHandle m_hDeflectBeam;
	protected CBeam@ m_pDeflectBeam
	{
		get const { return cast<CBeam@>(m_hDeflectBeam.GetEntity()); }
		set { m_hDeflectBeam = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_flPlasmaBall = 0.0;
		m_iShieldFlags = 15;
		m_iStartingRenderMode = pev.rendermode;
		m_iStartingRenderFx = pev.renderfx;
		m_flStartingRenderamt = 255; //pev.renderamt;
		m_vecStartingColor = pev.rendercolor;
		m_bShieldOn = false;
		m_flTargetRenderamt = 255;
		m_bSomeBool = true;
		m_flShieldTime = 0.0;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		m_iPlasmaCharge = g_Game.PrecacheModel( SPRITE_CHARGE );
		m_iPlasmaChargeBeam = g_Game.PrecacheModel( SPRITE_BEAM );
		m_iLightningGlow = g_Game.PrecacheModel( SPRITE_LIGHTGLOW );
		g_Game.PrecacheModel( SPRITE_EYE );
		g_Game.PrecacheModel( SPRITE_DEFLECT );

		g_Game.PrecacheOther( "kingpin_plasma_ball" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_kingpin.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_kingpin.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_kingpin_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::KINGPIN_SLOT - 1;
		info.iPosition			= CNPC::KINGPIN_POSITION - 1;
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
		{
			ShieldOff();
			@m_pDriveEnt.pev.owner = null;
		}

		if( m_pPlasmaball !is null )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlasmaball.edict(), CHAN_VOICE, "kingpin/kingpin_seeker_amb.wav", 0, 0, SND_STOP, 100 ); 
			g_EntityFuncs.Remove( m_pPlasmaball );
		}

		RemoveEffects();
		ResetPlayer();

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_iState = STATE_MELEE;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_MELEE );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_RANGE );
			SetSpeed( 0 );
			SetAnim( ANIM_RANGE );

			self.m_flNextPrimaryAttack = g_Engine.time + CD_PRIMARY;
			self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
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
			cnpc_kingpin@ pDriveEnt = cast<cnpc_kingpin@>(CastToScriptClass(m_pDriveEnt));
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

			if( m_flNextThink <= g_Engine.time )
			{
				LookForEnemies();
				ChargeEyes();
				DeflectStuff();

				if( m_bSomeBool and g_Engine.time > m_flShieldTime )
					ResolveRenderProps();

				DoShield();
				DoLightningAttack();
				DoPlasmaBall();

				m_flNextThink = g_Engine.time + 0.1;
			}
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState == STATE_RANGE ) return;

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
		if( m_iState == STATE_MELEE and m_pDriveEnt.pev.sequence == ANIM_MELEE and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_RANGE and m_pDriveEnt.pev.sequence == ANIM_RANGE and !m_pDriveEnt.m_fSequenceFinished ) return;

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

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE3)], VOL_NORM, ATTN_NORM );
	}

	void HandleAnimEvent( int iSequence )
	{
		if( !IsBetween2(iSequence, ANIM_WALK, ANIM_RANGE) ) return;

		switch( iSequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(41, 0) and m_uiAnimationState == 0 ) { MovementSound(true); m_uiAnimationState++; }
				else if( GetFrame(41) > 10 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_RUN:
			{
				if( GetFrame(20, 0) and m_uiAnimationState == 0 ) { MovementSound(false); m_uiAnimationState++; }
				else if( GetFrame(20) > 10 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE:
			{
				if( GetFrame(26, 11) and m_uiAnimationState == 0 ) { MeleeAttack(true); m_uiAnimationState++; }
				else if( GetFrame(26, 21) and m_uiAnimationState == 1 ) { MeleeAttack(false); m_uiAnimationState++; }
				else if( GetFrame(26) >= 4 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_RANGE:
			{
				if( GetFrame(40, 13) and m_uiAnimationState == 0 ) { ChargePlasmaball(); m_uiAnimationState++; }
				else if( GetFrame(40, 24) and m_uiAnimationState == 1 ) { m_pDriveEnt.pev.framerate = 0.0; m_uiAnimationState++; }
				else if( GetFrame(40) >= 29 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void MovementSound( bool bWalk )
	{
		int iSound = SND_RUN;
		if( bWalk ) iSound = SND_WALK;
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[iSound], VOL_NORM, ATTN_NORM );
	}

	void MeleeAttack( bool bRight )
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE, DMG_SLASH );
		if( pHurt !is null )
		{
			if( (pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP)) and pHurt.pev.movetype != MOVETYPE_FLY )
			{
				pHurt.pev.punchangle.z = -15.0;
				pHurt.pev.punchangle.x = 10.0;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 100 + g_Engine.v_right * (bRight ? 200 : -200) + g_Engine.v_up * 200;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT3)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MISS1, SND_MISS2)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
	}

	void ChargePlasmaball()
	{
		m_flPlasmaBall = g_Engine.time;

		Math.MakeVectors( m_pDriveEnt.pev.angles );

		Vector vecOrigin = m_pDriveEnt.pev.origin + g_Engine.v_forward * 32 + g_Engine.v_up * 64;
		//Necessary because the value is too large otherwise
		int iFlags = 33806; //2 | 4 | 8 | 1024 | 32768

		NetworkMessage m1( MSG_PVS, NetworkMessages::RampSprite, vecOrigin );
			m1.WriteShort( m_iPlasmaCharge ); //spriteindex
			m1.WriteByte( 15 ); //lifetime
			m1.WriteCoord( vecOrigin.x ); //origin
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( iFlags ); //33806, flags? changes the sprite into various sizes and colors
			//32 colors the sprite ?? hardcoded redish ??
			//512 spins the sprite CCW
			//1024 slowly grows the sprite in size
			//32768 animates the sprite ??
			m1.WriteByte( 3 );
			m1.WriteByte( 255 );
			m1.WriteByte( 160 );
			m1.WriteByte( 10 );
			m1.WriteByte( 10 ); //size ??
		m1.End();
	}

	void DoPlasmaBall()
	{
		if( m_iState != STATE_RANGE or m_pDriveEnt.pev.sequence != ANIM_RANGE ) return;

		if( (g_Engine.time - m_flPlasmaBall) < 1.3 )
		{
			TraceResult tr;
			Vector vecStart = m_pDriveEnt.pev.origin + g_Engine.v_forward * 32 + g_Engine.v_up * 64;
			Vector vecEnd = vecStart + Vector( Math.RandomFloat(-256, 256), Math.RandomFloat(-256, 256), Math.RandomFloat(-256, 256) );

			Math.MakeVectors( m_pDriveEnt.pev.angles );
			g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, m_pPlayer.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_BEAMPOINTS );
					m1.WriteCoord( vecStart.x );//start position
					m1.WriteCoord( vecStart.y );
					m1.WriteCoord( vecStart.z );
					m1.WriteCoord( tr.vecEndPos.x );//end position
					m1.WriteCoord( tr.vecEndPos.y );
					m1.WriteCoord( tr.vecEndPos.z );
					m1.WriteShort( m_iPlasmaChargeBeam );//sprite index
					m1.WriteByte( 0 );//starting frame
					m1.WriteByte( 15 );//framerate in 0.1's
					m1.WriteByte( 1 );//life in 0.1's
					m1.WriteByte( 50 );//width in 0.1's
					m1.WriteByte( 255 );//noise amplitude in 0.1's
					m1.WriteByte( 200 );//red
					m1.WriteByte( 100 );//green
					m1.WriteByte( 255 );//blue
					m1.WriteByte( 150 );//brightness
					m1.WriteByte( 0 );//scroll speed
				m1.End();
			}
		}
		else
		{
			if( m_pDriveEnt.pev.framerate <= 0.0 )
			{
				m_pDriveEnt.pev.framerate = 1.0;
				Math.MakeVectors( m_pDriveEnt.pev.angles );

				Vector vecOrigin = m_pDriveEnt.pev.origin + g_Engine.v_forward * 32 + g_Engine.v_up * 64;
				CBaseEntity@ pBall = g_EntityFuncs.Create( "kingpin_plasma_ball", vecOrigin, g_vecZero, false, m_pPlayer.edict() );
				if( pBall !is null )
				{
					CBaseMonster@ pBallMonster = pBall.MyMonsterPointer();
					pBallMonster.m_hEnemy = EHandle( BestVisibleEnemy() );

					@m_pPlasmaball = pBall;
				}
			}
		}
	}

	CBaseEntity@ BestVisibleEnemy()
	{
		CBaseEntity@ pReturn = null;
		
		while( (@pReturn = g_EntityFuncs.FindEntityInSphere(pReturn, m_pDriveEnt.pev.origin, 4096, "*", "classname")) !is null )
		{
			if( pReturn.pev.FlagBitSet(FL_MONSTER | FL_CLIENT) and pReturn.IsAlive() )
			{
				if( m_pPlayer.IRelationship(pReturn) > R_NO and pReturn.IsAlive() and pReturn.edict() !is m_pPlayer.edict() and !pReturn.pev.FlagBitSet(FL_NOTARGET) )
				{
					if( m_pPlayer.FInViewCone(pReturn) and m_pPlayer.FVisible(pReturn, true) )
						return pReturn;
				}
			}
		}

		return null;
	}

	void LookForEnemies()
	{
		if( m_pEnemy is null )
		{
			CBaseEntity@ pEnemy = BestVisibleEnemy();
			if( pEnemy !is null )
			{
				@m_pEnemy = pEnemy;

				//Randomize the eye charging a bit
				for( int i = 0; i < 4; i++ )
				{
					if( m_pEye(i) !is null )
							m_pEye(i).pev.dmgtime = g_Engine.time + Math.RandomFloat(0, 0.5);
				}
			}
		}
		else if( !m_pEnemy.IsAlive() )
			@m_pEnemy = null;
	}

	void ChargeEyes()
	{
		for( int i = 0; i < 4; i++ )
		{
			if( m_pEye(i) !is null )
			{
				if( m_pEnemy !is null )
				{
					if( m_pEye(i).pev.dmgtime < g_Engine.time )
					{
						if( m_pEye(i).pev.renderamt <= 0 )
							m_pEye(i).pev.renderamt++;
						else if( m_pEye(i).pev.renderamt < 255 )
							m_pEye(i).pev.renderamt += (m_pEye(i).pev.renderamt * 0.15);

						if( m_pEye(i).pev.renderamt > 255 )
							m_pEye(i).pev.renderamt = 255;
					}
				}
				else if( m_pEye(i).pev.renderamt > 0 )
					m_pEye(i).pev.renderamt = 0;
			}
		}
	}

	void DeflectStuff()
	{
		if( m_pDeflectTarget !is null or RecheckDeflectTarget() )
		{
			float flDist = (m_pDeflectTarget.pev.origin - m_pDriveEnt.pev.origin).Length();

			if( flDist > 256.0 )
			{
				RemoveDeflectBeam();
				@m_pDeflectTarget = null;

				return;
			}

			float flMinDist = 10.0;

			flMinDist = 10.0;

			if( flDist >= 10.0 )
				flMinDist = flDist;

			Vector vecMathgic = (m_pDeflectTarget.pev.origin - m_pDriveEnt.pev.origin) / flDist * g_Engine.frametime * 2000000.0 / flMinDist;
			if( vecMathgic.z < 50.0 )
				vecMathgic.z = 50.0;

			m_pDeflectTarget.pev.velocity = m_pDeflectTarget.pev.velocity + vecMathgic; //set it to vecMathgic directly to cause rockets to deflect back towards the launcher

			if( m_pDeflectTarget.GetClassname() == "rpg_rocket" )
			{
				Vector vecNewAngles = Math.VecToAngles( m_pDeflectTarget.pev.velocity );
				m_pDeflectTarget.pev.angles = vecNewAngles;
			}
		}
	}

	void ResolveRenderProps()
	{
		m_bSomeBool = false;

		if( m_bShieldOn and m_flShieldTime >= g_Engine.time )
		{
			m_bSomeBool = true;
			m_pDriveEnt.pev.renderfx = kRenderFxGlowShell;
			m_pDriveEnt.pev.renderamt = m_flTargetRenderamt;
			m_pDriveEnt.pev.rendercolor = Vector(100, 100, 255);
		}
		else
		{
			if( (m_iShieldFlags & 1) != 0 )
				m_pDriveEnt.pev.rendermode = m_iStartingRenderMode;

			if( (m_iShieldFlags & 2) != 0 )
				m_pDriveEnt.pev.renderfx = m_iStartingRenderFx;

			if( (m_iShieldFlags & 4) != 0 )
				m_pDriveEnt.pev.renderamt = m_flStartingRenderamt;

			if( (m_iShieldFlags & 8) != 0 )
				m_pDriveEnt.pev.rendercolor = m_vecStartingColor;
		}
	}

	void SetRenderAmount( float flAmount)
	{
		if( m_pDriveEnt !is null )
			m_pDriveEnt.pev.renderamt = flAmount;
	}

	void ShieldOn()
	{
		if( !m_bShieldOn and m_flTargetRenderamt > 0.0 )
		{
			m_bShieldOn = true;
			ResolveRenderProps();
			m_pPlayer.m_bloodColor = DONT_BLEED; //lets you get the proper values from GetGlobalTrace
		}
	}

	void ShieldOff()
	{
		if( m_bShieldOn )
		{
			m_bShieldOn = false;
			ResolveRenderProps();
			m_pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;
		}
	}

	void DoShield()
	{
		if( m_pEnemy !is null )
			ShieldOn();
		else
			ShieldOff();
	}

	void DoLightningAttack()
	{
		if( m_pEnemy !is null )
		{
			int iEye = SelectEyeToFire();

			if( iEye >= 0 )
			{
				if( LightningAttack(iEye) )
				{
					m_pEye( iEye ).pev.renderamt = 0;
					m_pEye( iEye ).pev.dmgtime = g_Engine.time + Math.RandomFloat(0, 0.5);
				}
			}
		}
	}

	int SelectEyeToFire()
	{
		for( int i = 0; i < 4; i++ )
		{
			if( m_pEye(i) !is null and m_pEye(i).pev.renderamt >= 255 )
				return i;
		}

		return -1;
	}

	bool LightningAttack( int iEye )
	{
		if( m_pEnemy !is null )
		{
			Vector vecOrigin;
			m_pDriveEnt.GetAttachment( iEye, vecOrigin, void );

			//check for line of sight
			TraceResult tr;
			g_Utility.TraceLine( vecOrigin, m_pEnemy.Center(), ignore_monsters, m_pPlayer.edict(), tr );

			if( tr.flFraction != 1.0 ) return false;

			g_WeaponFuncs.ClearMultiDamage();
			m_pEnemy.TraceAttack( m_pPlayer.pev, LIGHTNING_DAMAGE, (m_pEnemy.Center() - vecOrigin).Normalize(), tr, DMG_SHOCK );
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			CBeam@ pBeam = g_EntityFuncs.CreateBeam( SPRITE_BEAM, 50 );
			if( pBeam !is null )
			{
				pBeam.PointsInit( vecOrigin, m_pEnemy.Center() );
				pBeam.SetBrightness( 255 );
				pBeam.SetNoise( 50 );
				pBeam.SetScrollRate( 50 );
				pBeam.SetColor( 150, 100, 255 );
				pBeam.LiveForTime( 0.3 );
			}

			int iWeirdBehaviour = -75;
			NetworkMessage m1( MSG_PVS, NetworkMessages::RampSprite, vecOrigin );
				m1.WriteShort( m_iLightningGlow );
				m1.WriteByte( 10 );
				m1.WriteCoord( vecOrigin.x );
				m1.WriteCoord( vecOrigin.y );
				m1.WriteCoord( vecOrigin.z );
				m1.WriteShort( 1039 ); //1 | 2 | 4 | 8 | 1024
				m1.WriteByte( 63 );
				m1.WriteByte( 20 );
				m1.WriteByte( 255 );
				m1.WriteByte( 110 );
				m1.WriteByte( iWeirdBehaviour );
			m1.End();

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_BEAM], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(90, 100) );

			return true;
		}

		return false;
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_kingpin", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

			CreateEyes();
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_KINGPIN );
	}

	void DoFirstPersonView()
	{
		cnpc_kingpin@ pDriveEnt = cast<cnpc_kingpin@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_kingpin_rend_" + m_pPlayer.entindex();
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

	void CreateEyes()
	{
		for( int i = 0; i < 4; i++ )
		{
			m_hEye[i] = EHandle( g_EntityFuncs.CreateSprite(SPRITE_EYE, m_pDriveEnt.pev.origin, false) );

			if( m_hEye[i].IsValid() )
			{
				g_EntityFuncs.SetOrigin( m_pEye(i), m_pDriveEnt.pev.origin );
				m_pEye(i).SetAttachment( m_pDriveEnt.edict(), i+1 );
				m_pEye(i).pev.framerate = 10.0;
				m_pEye(i).TurnOn();
				m_pEye(i).SetTransparency( kRenderTransAdd, 255, 255, 255, 0, kRenderFxNone );
				m_pEye(i).SetScale( 0.3 );
			}
		}
	}

	void RemoveEffects()
	{
		for( int i = 0; i < 4; i++ )
		{
			if( m_hEye[i].IsValid() )
				m_hEye[i].GetEntity().SUB_StartFadeOut();
		}

		RemoveDeflectBeam();
	}

	void RemoveDeflectBeam()
	{
		if( m_pDeflectBeam !is null )
			g_EntityFuncs.Remove( m_pDeflectBeam );
	}

	bool RecheckDeflectTarget()
	{
		RemoveDeflectBeam();
		FindNewProjectileThreats();

		if( m_pDeflectTarget !is null ) return true;

		return false;
	}

	void FindNewProjectileThreats()
	{
		if( m_pDeflectTarget is null )
		{
			CBaseEntity@ pEntity = null;
			while( (@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, m_pDriveEnt.pev.origin, 256.0, "*", "classname")) !is null )
			{
				if( pEntity.GetClassname() != "grenade" and pEntity.GetClassname() != "rpg_rocket" and pEntity.GetClassname() != "monster_satchel" and pEntity.GetClassname() != "sporegrenade" and pEntity.GetClassname() != "monster_snark" ) continue;

				if( m_pDriveEnt.FVisible(pEntity, true) )
					break;
			}

			if( pEntity !is null )
			{
				//if( pEntity.pev.velocity.Length() <= 1000.0 ) //??
				{
					if( m_pPlayer.pev.health >= 50.0 )
						MakeDeflectTarget( pEntity );
					else
					{
						Vector vecCenter = m_pDriveEnt.Center();
						float flWhatTheFuck = CrossProduct(vecCenter, pEntity.pev.origin).Length();
						/*float flWhatTheFuck = (vecCenter.x - pEntity.pev.origin.x) * (vecCenter.x - pEntity.pev.origin.x) + 
														(vecCenter.y - pEntity.pev.origin.y) * (vecCenter.y - pEntity.pev.origin.y) + 
														(vecCenter.z - pEntity.pev.origin.z) * (vecCenter.z - pEntity.pev.origin.z);*/

						if( flWhatTheFuck <= 40000.0 )
							MakeDeflectTarget( pEntity );
						else
							TryToDetonateTarget( pEntity );
					}
				}
			}
		}
	}

	void MakeDeflectTarget( CBaseEntity@ pEntity )
	{
		if( m_pDriveEnt is null ) return;

		RemoveDeflectBeam();

		@m_pDeflectTarget = pEntity;

		CBeam@ pBeam = g_EntityFuncs.CreateBeam( SPRITE_DEFLECT, 20 );
		if( pBeam !is null )
		{
			@m_pDeflectBeam = pBeam;

			m_pDeflectBeam.EntsInit( m_pDriveEnt.entindex(), m_pDeflectTarget.entindex() );
			m_pDeflectBeam.SetColor( 150, 100, 255 );
			m_pDeflectBeam.SetBrightness( 255 );
			m_pDeflectBeam.SetFlags( 66 ); //15 | 64; // 0xF | 0x40
			m_pDeflectBeam.SetNoise( 100 );
			m_pDeflectBeam.SetScrollRate( 50.0 );
		}
	}

	void TryToDetonateTarget( CBaseEntity@ pEntity )
	{
		@pEntity.pev.owner = m_pPlayer.edict();

		if( pEntity.GetClassname() == "monster_snark" )
			pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, 100.0, DMG_GENERIC );
		else if( pEntity.pev.solid != SOLID_NOT ) //without this the explosions never stop
			pEntity.Killed( m_pPlayer.pev, GIB_NEVER );

		CreateDetBeam( pEntity );
	}

	void CreateDetBeam( CBaseEntity@ pEntity )
	{
		CBeam@ pBeam = g_EntityFuncs.CreateBeam( SPRITE_DEFLECT, 50 );
		if( pBeam !is null )
		{
			pBeam.PointsInit( m_pDriveEnt.Center(), pEntity.Center() );
			pBeam.SetColor( 255, 255, 255 );
			pBeam.SetBrightness( 255 );
			pBeam.SetFlags( 130 ); //15 | 128  //0xF | 0x80;
			pBeam.SetNoise( 50 );
			pBeam.SetScrollRate( 50.0 );
			pBeam.LiveForTime( 0.2 );
		}
	}
}

class cnpc_kingpin : CBaseDriveEntity
{
	private float m_flSomeFloat; //??
	private bool m_bSomeOtherBool; //??

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
		m_flSomeFloat = 0.0;
		m_bSomeOtherBool = false;

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
		else if( pev.sequence != ANIM_RANGE and (m_pOwner.pev.button & IN_ATTACK) != 0 )
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath( bool bGibbed = false )
	{
		pev.velocity = g_vecZero;

		SetupDeath();

		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		if( bGibbed )
		{
			DoGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, 0.5 );

		SetThink( ThinkFunction(this.DeathEffectThink) );
		pev.nextthink = g_Engine.time;
	}

	void DoGibs()
	{
		NetworkMessage m1( MSG_ALL, NetworkMessages::Gib );
			m1.WriteByte( 4 ); //gib type ?? 0: human,  1: human, 2: alien, 4: tiny alien
			m1.WriteCoord( self.Center().x ); //origin
			m1.WriteCoord( self.Center().y );
			m1.WriteCoord( self.Center().z );
			m1.WriteCoord( 600 ); //velocity ??
			m1.WriteCoord( 600 );
			m1.WriteCoord( 600 );
		m1.End();

		g_EntityFuncs.SpawnRandomGibs( self.pev, 6, 0 );
	}

	void SetupDeath()
	{
		pev.movetype = MOVETYPE_FLY;
		pev.velocity = Vector( 0, 0, 16 );
		pev.solid = SOLID_NOT;
		pev.renderamt = 255;
		pev.renderfx = kRenderFxNone;
		pev.rendercolor = g_vecZero;

		m_flSomeFloat = g_Engine.time;
		m_bSomeOtherBool = false;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_AUTO, arrsCNPCSounds[SND_SUCKOUT], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(90, 100) ); 
	}

	void DeathEffectThink()
	{
		pev.nextthink = g_Engine.time + 0.1;
		float flTimeToDie = (g_Engine.time - m_flSomeFloat) * 0.5;
		float flEffectModifier = flTimeToDie;

		if( flTimeToDie >= 1.0 )
		{
			Vector vecOrigin = self.Center();
			NetworkMessage m1( MSG_PVS, NetworkMessages::SRDetonate, vecOrigin );
				m1.WriteCoord( vecOrigin.x ); //origin
				m1.WriteCoord( vecOrigin.y );
				m1.WriteCoord( vecOrigin.z );
				m1.WriteByte( 96 );
			m1.End();

			SetThink( null );
			DoGibs();
			g_EntityFuncs.Remove(self);

			return;
		}

		int iStopEffects = int( flTimeToDie * 4.0 );
		if( iStopEffects < 0 )
			return;

		int iCount = 0;

		do
		{
			TraceResult tr;
			Vector vecStart = self.Center();
			Vector vecEnd = vecStart + Vector( Math.RandomFloat(-256, 256), Math.RandomFloat(-256, 256), Math.RandomFloat(-256, 256) );
			int iSillyThing = int(50 + flEffectModifier * 205);

			Math.MakeVectors( pev.angles );
			g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, self.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m1.WriteByte( TE_BEAMPOINTS );
					m1.WriteCoord( vecStart.x );
					m1.WriteCoord( vecStart.y );
					m1.WriteCoord( vecStart.z );
					m1.WriteCoord( tr.vecEndPos.x );
					m1.WriteCoord( tr.vecEndPos.y );
					m1.WriteCoord( tr.vecEndPos.z );
					m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAM) );
					m1.WriteByte( 0 );
					m1.WriteByte( 15 );
					m1.WriteByte( 3 );
					m1.WriteByte( Math.RandomLong(30, iSillyThing) );//width in 0.1's
					m1.WriteByte( 255 );
					m1.WriteByte( iSillyThing );//red
					m1.WriteByte( 100 );
					m1.WriteByte( int((1 - flEffectModifier) * 205 + 50) );//blue
					m1.WriteByte( 255 );
					m1.WriteByte( 0 );
				m1.End();
			}

			++iCount;

		} while( iCount < iStopEffects );
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_kingpin : CNPCSpawnEntity
{
	info_cnpc_kingpin()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_kingpin::info_cnpc_kingpin", "info_cnpc_kingpin" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_kingpin::cnpc_kingpin", "cnpc_kingpin" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_kingpin::weapon_kingpin", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_kingpin" );
	g_Game.PrecacheOther( "cnpc_kingpin" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_kingpin END

/* FIXME
	TryToDetonateTarget
		Never detonate projectiles when above 50 health, except for 
																								rockets that are coming head on.
																								sporegrenades that are launched with SecondaryAttack (they travel faster) when coming head on.
																								sometimes snarks??
*/

/* TODO
	Add teleport?
	Add cooldown timer for plasmaball attack?
*/