namespace cnpc_tentacle
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_tentacle";
const string CNPC_MODEL				= "models/tentacle2.mdl";
const Vector CNPC_SIZEMIN			= Vector( -32, -32, 0 );
const Vector CNPC_SIZEMAX			= Vector( 32, 32, 640 ); //high value needed for TraceAttack to work properly

const float CNPC_HEALTH				= 750.0;
const float CNPC_VIEWOFS_FPV		= 256.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 256.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the tentacle itself
const float CNPC_RESPAWNEXIT		= 5.0; //time until it can be used again after a player exits
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float CD_PRIMARY					= 0.8; //irrelevant, CD is based on the length of the attack animations
const float CD_SECONDARY			= 0.5; //irrelevant, CD is based on the length of the attack animations
const float DAMAGE_RADIUS			= 100.0;

const int ACT_T_IDLE						= 1010;
const int ACT_T_TAP						= 1020;
const int ACT_T_STRIKE					= 1030;

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"tentacle/te_strike1.wav",
	"tentacle/te_strike2.wav",
	"player/pl_dirt1.wav",
	"player/pl_dirt2.wav",
	"player/pl_dirt3.wav",
	"player/pl_dirt4.wav",
	"player/pl_slosh1.wav",
	"player/pl_slosh2.wav",
	"player/pl_slosh3.wav",
	"player/pl_slosh4.wav",
	"tentacle/te_roar1.wav",
	"tentacle/te_roar2.wav"
};

enum sound_e
{
	SND_STRIKE_SILO1 = 1,
	SND_STRIKE_SILO2,
	SND_STRIKE_DIRT1,
	SND_STRIKE_DIRT4 = 6,
	SND_STRIKE_WATER1,
	SND_STRIKE_WATER4 = 10,
	SND_ROAR1,
	SND_ROAR2
};

enum anim_e
{
	ANIM_PIT_IDLE = 0,
	ANIM_RISE_TO_TEMP1,
	ANIM_TEMP1_TO_FLOOR,

	ANIM_FLOOR_IDLE,
	ANIM_FLOOR_FIDGET_PISSED,
	ANIM_FLOOR_FIDGET_SMALLRISE,	//5
	ANIM_FLOOR_FIDGET_WAVE,
	ANIM_FLOOR_STRIKE,
	ANIM_FLOOR_TAP,
	ANIM_FLOOR_ROTATE,
	ANIM_FLOOR_REAR,						//10
	ANIM_FLOOR_REAR_IDLE,
	ANIM_FLOOR_TO_LEV1,

	ANIM_LEV1_IDLE,
	ANIM_LEV1_FIDGET_CLAW,
	ANIM_LEV1_FIDGET_SHAKE,			//15
	ANIM_LEV1_FIDGET_SNAP,
	ANIM_LEV1_STRIKE,
	ANIM_LEV1_TAP,
	ANIM_LEV1_ROTATE,
	ANIM_LEV1_REAR,							//20
	ANIM_LEV1_REAR_IDLE,
	ANIM_LEV1_TO_LEV2,

	ANIM_LEV2_IDLE,
	ANIM_LEV2_FIDGET_SHAKE,
	ANIM_LEV2_FIDGET_SWING,			//25
	ANIM_LEV2_FIDGET_TUT,
	ANIM_LEV2_STRIKE,
	ANIM_LEV2_TAP,
	ANIM_LEV2_ROTATE,
	ANIM_LEV2_REAR,							//30
	ANIM_LEV2_REAR_IDLE,
	ANIM_LEV2_TO_LEV3,

	ANIM_LEV3_IDLE,
	ANIM_LEV3_FIDGET_SHAKE,
	ANIM_LEV3_FIDGET_SIDE,				//35
	ANIM_LEV3_FIDGET_SWIPE,
	ANIM_LEV3_STRIKE,
	ANIM_LEV3_TAP,
	ANIM_LEV3_ROTATE,
	ANIM_LEV3_REAR,							//40
	ANIM_LEV3_REAR_IDLE,

	ANIM_LEV1_DOOR_REACH,

	ANIM_LEV3_TO_ENGINE,

	ANIM_ENGINE_IDLE,
	ANIM_ENGINE_SWAY,					//45
	ANIM_ENGINE_SWAT,
	ANIM_ENGINE_BOB,
	ANIM_ENGINE_DEATH1,
	ANIM_ENGINE_DEATH2,
	ANIM_ENGINE_DEATH3					//50
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_ATTACK,
	STATE_LEVEL_CHANGE
};

enum strikes_e
{
	TE_NONE = -1,
	TE_SILO,
	TE_DIRT,
	TE_WATER
};

class weapon_tentacle : CBaseDriveWeapon
{
	Vector m_vecExitOrigin, m_vecExitAngles; //for noplayerdeath

	private int m_iTapSound;
	private float m_flTapRadius;
	private int m_iMyLevel;
	private float m_flStartHeight;
	private float m_flTargetHeight;
	private float m_flNextPlayerMove;

	bool CustomKeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "tapsound" )
		{
			m_iTapSound = atoi( szValue );
			return true;
		}

		return false;
	}

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		m_flTapRadius = 336;
		m_iMyLevel = 0;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_tentacle.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_tentacle.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_tentacle_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::TENTACLE_SLOT - 1;
		info.iPosition			= CNPC::TENTACLE_POSITION - 1;
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
			if( (GetState(STATE_ATTACK) and !m_pDriveEnt.m_fSequenceFinished) or GetState() > STATE_ATTACK ) return;

			SetState( STATE_ATTACK );
			SetAnim( m_pDriveEnt.LookupActivity(ACT_T_STRIKE + m_iMyLevel) );
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
			if( (GetState(STATE_ATTACK) and !m_pDriveEnt.m_fSequenceFinished) or GetState() > STATE_ATTACK ) return;

			SetState( STATE_ATTACK );
			SetAnim( m_pDriveEnt.LookupActivity(ACT_T_TAP + m_iMyLevel) );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
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
			cnpc_tentacle@ pDriveEnt = cast<cnpc_tentacle@>(CastToScriptClass(m_pDriveEnt));
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
			DoIdleAnimation();
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			KeepPlayerInPlace();
			CheckUpInput();
			CheckDownInput();

			if( m_flNextThink <= g_Engine.time )
			{
				DoHeightChange();
				DoBlending();

				m_flNextThink = g_Engine.time + 0.1;
			}

			if( m_flNextPlayerMove <= g_Engine.time )
			{
				MovePlayer();

				m_flNextPlayerMove = g_Engine.time + 0.01;
			}
		}
	}

	void DoIdleAnimation( bool bOverrideState = false )
	{
		if( !bOverrideState )
		{
			if( GetState() >= STATE_ATTACK and !m_pDriveEnt.m_fSequenceFinished ) return;
			if( GetState(STATE_LEVEL_CHANGE) ) return;
		}

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetState( STATE_IDLE );
				SetAnim( m_pDriveEnt.LookupActivity(ACT_T_IDLE + m_iMyLevel) );
				m_flTapRadius = 336;
			}
			else if( GetState(STATE_IDLE) and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_T_IDLE + m_iMyLevel) );
			}
		}
	}

	void HandleAnimEvent( int iSequence )
	{
		if( iSequence >= ANIM_ENGINE_DEATH1 ) return;

		switch( iSequence )
		{
			case ANIM_FLOOR_IDLE:
			{
				if( GetFrame(41, 0) and m_uiAnimationState == 0 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(41) >= 20 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_FLOOR_FIDGET_PISSED:
			{
				if( GetFrame(46, 0) and m_uiAnimationState == 0 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(46, 5) and m_uiAnimationState == 1 ) { Roar(); m_uiAnimationState++; }
				else if( GetFrame(46) >= 15 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV1_FIDGET_CLAW:
			{
				if( GetFrame(51, 11) and m_uiAnimationState == 0 ) { Roar(); m_uiAnimationState++; }
				else if( GetFrame(51, 16) and m_uiAnimationState == 2 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(51, 29) and m_uiAnimationState == 3 ) { Roar(); m_uiAnimationState++; }
				else if( GetFrame(51, 35) and m_uiAnimationState == 4 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(51) >= 40 and m_uiAnimationState == 5 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV2_FIDGET_SHAKE:
			{
				if( GetFrame(41, 10) and m_uiAnimationState == 0 ) { Roar(); m_uiAnimationState++; }
				else if( GetFrame(41) >= 15 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_FLOOR_FIDGET_SMALLRISE:
			{
				if( GetFrame(31, 0) and m_uiAnimationState == 0 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(31) >= 10 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV1_FIDGET_SHAKE:
			{
				if( GetFrame(51, 16) and m_uiAnimationState == 0 ) { SwingSound(); m_uiAnimationState++; }
				else if( GetFrame(51, 38) and m_uiAnimationState == 1 ) { SwingSound(); m_uiAnimationState++; }
				else if( GetFrame(51) >= 45 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_FLOOR_FIDGET_WAVE:
			{
				if( GetFrame(41, 0) and m_uiAnimationState == 0 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(41) >= 10 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV1_FIDGET_SNAP:
			{
				if( GetFrame(51, 5) and m_uiAnimationState == 0 ) { SwingSound(); m_uiAnimationState++; }
				else if( GetFrame(51, 16) and m_uiAnimationState == 1 ) { SwingSound(); m_uiAnimationState++; }
				else if( GetFrame(51, 23) and m_uiAnimationState == 2 ) { SwingSound(); m_uiAnimationState++; }
				else if( GetFrame(51, 33) and m_uiAnimationState == 3 ) { SwingSound(); m_uiAnimationState++; }
				else if( GetFrame(51) >= 40 and m_uiAnimationState == 4 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV3_FIDGET_SWIPE:
			{
				if( GetFrame(31, 16) and m_uiAnimationState == 0 ) { Roar(); m_uiAnimationState++; }
				else if( GetFrame(31) >= 20 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

 			case ANIM_FLOOR_STRIKE:
			{
				if( GetFrame(16, 6) and m_uiAnimationState == 0 ) { SetDamage(200); m_uiAnimationState++; }
				else if( GetFrame(16, 8) and m_uiAnimationState == 1 ) { Bang(); m_uiAnimationState++; }
				else if( GetFrame(16, 12) and m_uiAnimationState == 2 ) { SetDamage(25); m_uiAnimationState++; }
				else if( GetFrame(16) >= 15 and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV1_STRIKE:
			{
				if( GetFrame(31, 9) and m_uiAnimationState == 0 ) { SetDamage(200); m_uiAnimationState++; }
				else if( GetFrame(31, 11) and m_uiAnimationState == 1 ) { Bang(); m_uiAnimationState++; }
				else if( GetFrame(31, 20) and m_uiAnimationState == 2 ) { SetDamage(25); m_uiAnimationState++; }
				else if( GetFrame(31) >= 25 and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV2_STRIKE:
			{
				if( GetFrame(26, 13) and m_uiAnimationState == 0 ) { SetDamage(200); m_uiAnimationState++; }
				else if( GetFrame(26, 16) and m_uiAnimationState == 1 ) { Bang(); m_uiAnimationState++; }
				else if( GetFrame(26, 20) and m_uiAnimationState == 2 ) { SetDamage(25); m_uiAnimationState++; }
				else if( GetFrame(26) >= 25 and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_LEV3_STRIKE:
			{
				if( GetFrame(21, 6) and m_uiAnimationState == 0 ) { SetDamage(200); m_uiAnimationState++; }
				else if( GetFrame(21, 10) and m_uiAnimationState == 1 ) { Bang(); m_uiAnimationState++; }
				else if( GetFrame(21, 12) and m_uiAnimationState == 2 ) { SetDamage(25); m_uiAnimationState++; }
				else if( GetFrame(21) >= 15 and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

 			case ANIM_FLOOR_TAP:
			{
				if( GetFrame(21, 7) and m_uiAnimationState == 0 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(21, 13) and m_uiAnimationState == 1 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(21, 20) and m_uiAnimationState == 2 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(21) >= 21 and m_uiAnimationState == 3 ) { m_uiAnimationState = 0; }

				break;
			}

 			case ANIM_LEV1_TAP:
 			case ANIM_LEV2_TAP:
 			case ANIM_LEV3_TAP:
			{
				if( GetFrame(21, 7) and m_uiAnimationState == 0 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(21, 13) and m_uiAnimationState == 1 ) { Tap(); m_uiAnimationState++; }
				else if( GetFrame(21) >= 21 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void SetDamage( int iDamage )
	{
		m_pDriveEnt.pev.dmg = iDamage;
	}

	void Tap()
	{
		Vector vecSrc = m_pDriveEnt.pev.origin + m_flTapRadius * Vector( cos(m_pDriveEnt.pev.angles.y * (Math.PI / 180.0)), sin(m_pDriveEnt.pev.angles.y * (Math.PI / 180.0)), 0.0 );
		vecSrc.z += MyHeight();
		float flVol = Math.RandomFloat( 0.3, 0.5 );
		TapOrBangSound( vecSrc, flVol );

		if( !CNPC::PVP )
		{
			m_pDriveEnt.GetAttachment( 0, vecSrc, void );
			g_WeaponFuncs.RadiusDamage( vecSrc, m_pDriveEnt.pev, m_pDriveEnt.pev, 20, DAMAGE_RADIUS, CLASS_PLAYER, DMG_CRUSH );
		}
	}

	void Bang()
	{
		Vector vecSrc;
		m_pDriveEnt.GetAttachment( 0, vecSrc, void );
		float flVol = VOL_NORM;
		TapOrBangSound( vecSrc, flVol );

		if( !CNPC::PVP )
			g_WeaponFuncs.RadiusDamage( vecSrc, m_pDriveEnt.pev, m_pDriveEnt.pev, m_pDriveEnt.pev.dmg, DAMAGE_RADIUS, CLASS_PLAYER, DMG_CRUSH );
		else
			g_Engine.force_retouch++;
	}

	void TapOrBangSound( Vector vecSrc, float flVol )
	{
		switch( m_iTapSound )
		{
			case TE_NONE:
			{
				break;
			}

			case TE_SILO:
			{
				g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), vecSrc, arrsCNPCSounds[Math.RandomLong(SND_STRIKE_SILO1, SND_STRIKE_SILO2)], flVol, ATTN_NORM, 0, 100 );
				break;
			}

			case TE_DIRT:
			{
				g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), vecSrc, arrsCNPCSounds[Math.RandomLong(SND_STRIKE_DIRT1, SND_STRIKE_DIRT4)], flVol, ATTN_NORM, 0, 100 );
				break;
			}

			case TE_WATER:
			{
				g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), vecSrc, arrsCNPCSounds[Math.RandomLong(SND_STRIKE_WATER1, SND_STRIKE_WATER4)], flVol, ATTN_NORM, 0, 100 );
				break;
			}
		}
	}

	void Roar()
	{
		g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), m_pDriveEnt.pev.origin + Vector(0, 0, MyHeight()), arrsCNPCSounds[Math.RandomLong(SND_ROAR1, SND_ROAR2)], VOL_NORM, ATTN_NORM, 0, 100 );
	}

	void SwingSound()
	{
		g_SoundSystem.EmitAmbientSound( m_pDriveEnt.edict(), m_pDriveEnt.pev.origin + Vector(0, 0, MyHeight()), arrsCNPCSounds[Math.RandomLong(SND_ROAR1, SND_ROAR2)], VOL_NORM, ATTN_NORM, 0, 100 );
	}

	void KeepPlayerInPlace()
	{
		SetSpeed( 0 );
		m_pPlayer.pev.velocity = g_vecZero;
		m_pPlayer.pev.solid = SOLID_NOT;
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		m_pPlayer.pev.flags |= (FL_FLY|FL_NOTARGET|FL_GODMODE);
	}

	void CheckUpInput()
	{
		if( GetState() > STATE_IDLE or m_iMyLevel >= 3 ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_JUMP) != 0 )
		{
			SetState( STATE_LEVEL_CHANGE );
			SetAnim( ANIM_FLOOR_TO_LEV1 + (m_iMyLevel * 10) );
			m_flTargetHeight += 192;

			//int FindTransition(int iEndingSequence, int iGoalSequence, int& out iDir)   Find the transition between 2 sequences.  
		}
	}

	void CheckDownInput()
	{
		if( GetState() > STATE_IDLE or m_iMyLevel <= 0 ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_DUCK) != 0 )
		{
			SetState( STATE_LEVEL_CHANGE );
			SetAnim( ANIM_FLOOR_TO_LEV1 + ((m_iMyLevel-1) * 10), -1.0, 255 );
			m_flTargetHeight -= 192;

			//Delay the movement a bit to match the animation
			if( GetAnim(ANIM_LEV1_TO_LEV2) )
				m_flNextPlayerMove = g_Engine.time + 0.5;
		}
	}

	void DoHeightChange()
	{
		if( !GetState(STATE_LEVEL_CHANGE) ) return;

		if( m_pDriveEnt.m_fSequenceFinished )
		{
			switch( GetAnim() )
			{
				case ANIM_FLOOR_TO_LEV1:
				{
					if( m_iMyLevel == 0 )
						m_iMyLevel = 1;
					else if( m_iMyLevel == 1 )
						m_iMyLevel = 0;

					break;
				}

				case ANIM_LEV1_TO_LEV2:
				{
					if( m_iMyLevel == 1 )
						m_iMyLevel = 2;
					else if( m_iMyLevel == 2 )
						m_iMyLevel = 1;

					break;
				}

				case ANIM_LEV2_TO_LEV3:
				{
					if( m_iMyLevel == 2 )
						m_iMyLevel = 3;
					else if( m_iMyLevel == 3 )
						m_iMyLevel = 2;

					break;
				}
			}

			DoIdleAnimation( true );
		}
	}

	void MovePlayer()
	{
		if( !GetState(STATE_LEVEL_CHANGE) or m_pPlayer.pev.origin.z == m_flTargetHeight ) return;

		float flAmount = 8.0;

		switch( GetAnim() )
		{
			case ANIM_FLOOR_TO_LEV1: { flAmount = 6.0; break; }
			case ANIM_LEV1_TO_LEV2: { flAmount = 4.0; break; }
			case ANIM_LEV2_TO_LEV3: { flAmount = 2.0; break; }
		}

		Vector vecOrigin = m_pPlayer.pev.origin;
		if( vecOrigin.z < m_flTargetHeight )
			vecOrigin.z += flAmount;
		else if( vecOrigin.z > m_flTargetHeight )
			vecOrigin.z -= flAmount;

		g_EntityFuncs.SetOrigin( m_pPlayer, vecOrigin );
	}

	void DoBlending()
	{
		//this will lean the tentacle forward or back when tapping, to make sure the taps happen at the correct positions
		if( (m_pPlayer.pev.button & IN_ATTACK2) == 0 ) return;

		Vector vecSrc;
		Math.MakeVectors( m_pDriveEnt.pev.angles );

		TraceResult tr1, tr2;

		vecSrc = m_pDriveEnt.pev.origin + Vector( 0, 0, MyHeight() - 4);
		g_Utility.TraceLine( vecSrc, vecSrc + g_Engine.v_forward * 512, ignore_monsters, m_pPlayer.edict(), tr1 );

		vecSrc = m_pDriveEnt.pev.origin + Vector( 0, 0, MyHeight() + 8);
		g_Utility.TraceLine( vecSrc, vecSrc + g_Engine.v_forward * 512, ignore_monsters, m_pPlayer.edict(), tr2 );

		m_flTapRadius = m_pDriveEnt.SetBlending( 0, Math.RandomFloat(tr1.flFraction * 512, tr2.flFraction * 512) );
		//g_Game.AlertMessage( at_notice, "m_flTapRadius: %1, tr1: %2, tr2: %3\n", m_flTapRadius, tr1.flFraction * 512, tr2.flFraction * 512 );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_tentacle", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		SetSpeed( 0 );

		cnpc_tentacle@ pDriveEnt = cast<cnpc_tentacle@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt !is null )
		{
			pDriveEnt.m_vecExitOrigin = m_vecExitOrigin;
			pDriveEnt.m_vecExitAngles = m_vecExitAngles;
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.solid = SOLID_NOT;
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		m_pPlayer.pev.flags |= (FL_FLY|FL_NOTARGET|FL_GODMODE);
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = DONT_BLEED;

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
			m1.WriteString( "cam_idealdist 256\ncam_idealyaw -8\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_TENTACLE );

		m_flStartHeight = m_flTargetHeight = m_pPlayer.pev.origin.z;
	}

	void DoFirstPersonView()
	{
		cnpc_tentacle@ pDriveEnt = cast<cnpc_tentacle@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_tentacle_rend_" + m_pPlayer.entindex();
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

	void ExitPlayer( bool bManual = true )
	{
		if( bManual )
		{
			cnpc_tentacle@ pDriveEnt = cast<cnpc_tentacle@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );
		}

		CBaseEntity@ cbeSpawnEnt = null;
		info_cnpc_tentacle@ pSpawnEnt = null;
		while( (@cbeSpawnEnt = g_EntityFuncs.FindEntityByClassname(cbeSpawnEnt, "info_cnpc_tentacle")) !is null )
		{
			@pSpawnEnt = cast<info_cnpc_tentacle@>(CastToScriptClass(cbeSpawnEnt));
			if( pSpawnEnt.m_pCNPCWeapon is null ) continue;
			if( pSpawnEnt.m_pCNPCWeapon.edict() is self.edict() ) break;
		}

		if( pSpawnEnt !is null )
			pSpawnEnt.m_flTimeToRespawn = g_Engine.time + CNPC_RESPAWNEXIT;

		ResetPlayer();

		Vector vecOrigin = m_vecExitOrigin + Vector( 0, 0, 8 );

		if( bManual )
		{
			g_EntityFuncs.Remove( m_pDriveEnt );
			m_pPlayer.pev.health = 100;
		}
		else
		{
			m_pPlayer.pev.angles = m_vecExitAngles;
			m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
			m_pPlayer.pev.health = 100;
			m_pPlayer.pev.velocity = g_vecZero;
		}

		g_EntityFuncs.SetOrigin( m_pPlayer, vecOrigin );
		g_EntityFuncs.Remove( self );
	}

	void ResetPlayer()
	{
		m_pPlayer.pev.iuser3 = 0; //enable ducking
		m_pPlayer.pev.fuser4 = 0; //enable jumping
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.pev.movetype = MOVETYPE_WALK;
		m_pPlayer.pev.flags &= ~(FL_NOTARGET|FL_GODMODE|FL_FLY);
		m_pPlayer.pev.effects &= ~EF_NODRAW;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		SetSpeed( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\ncam_idealyaw -8\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}

	float MyHeight()
	{
		switch( m_iMyLevel )
		{
			case 1:
				return 256;

			case 2:
				return 448;

			case 3:
				return 640;
		}

		return 0;
	}
}

class cnpc_tentacle : CBaseDriveEntityHitbox
{
	private float m_flHitTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_FLY;
		pev.flags |= FL_MONSTER;
		pev.deadflag = DEAD_NO;
		pev.takedamage = DAMAGE_AIM;
		pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		self.m_bloodColor = BLOOD_COLOR_GREEN;
		self.m_FormattedName = "CNPC Tentacle";

		pev.sequence = ANIM_FLOOR_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flNextOriginUpdate = g_Engine.time;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;

		pev.dmg = 20;

		if( CNPC::PVP )
			SetTouch( TouchFunction(this.HitTouch) );
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if( pev.takedamage <= DAMAGE_NO )
			return 0;

		//Prevent player damage
		CBaseEntity@ pInflictor = g_EntityFuncs.Instance(pevInflictor);
		if( pInflictor !is null and m_pOwner.IRelationship(pInflictor) <= R_NO )
			return 0;

		pev.health -= flDamage;
		if( m_pOwner !is null and m_pOwner.IsConnected() and pev.health > 0 )
			m_pOwner.pev.health = pev.health;

		if (pev.health <= 0)
		{
			if( m_pOwner !is null and m_pOwner.IsConnected() )
			{
				if( (m_iSpawnFlags & CNPC::FL_NOPLAYERDEATH) != 0 )
				{
					weapon_tentacle@ pWeapon = cast<weapon_tentacle@>( CastToScriptClass(m_pOwner.m_hActiveItem.GetEntity()) );
					if( pWeapon !is null )
						pWeapon.ExitPlayer( false );
				}
				else
					m_pOwner.Killed( pevAttacker, GIB_NEVER );
			}

			pev.health = 0;
			pev.takedamage = DAMAGE_NO;
			pev.dmgtime = g_Engine.time;

			pev.flags &= ~FL_MONSTER;

			return 0;
		}

		pevAttacker.frags += self.GetPointsForDamage( flDamage );

		return 1;
	}

	//Doesn't seem to work with monsters :[
	void HitTouch( CBaseEntity@ pOther )
	{
		TraceResult tr = g_Utility.GetGlobalTrace();
		//g_Game.AlertMessage( at_notice, "pOther: %1, tr.pHit: %2\n", string(pOther.pev.classname), string(tr.pHit.vars.classname) );

		if( pOther.pev.modelindex == pev.modelindex )
			return;

		if( m_flHitTime > g_Engine.time )
			return;

		// only look at the ones where the player hit me
		if( tr.pHit is null or tr.pHit.vars.modelindex != pev.modelindex )
			return;

		//done with radiusdamage instead, because touch won't hit monsters for some reason
		if( tr.iHitgroup >= 3 and CNPC::PVP )
		{
			pOther.TakeDamage( m_pOwner.pev, m_pOwner.pev, pev.dmg, DMG_CRUSH );
			//g_Game.AlertMessage( at_notice, "wack    %1 : ", pev.dmg );
		}
		else if( tr.iHitgroup != 0 )
		{
			pOther.TakeDamage( m_pOwner.pev, m_pOwner.pev, 20, DMG_CRUSH );
			//g_Game.AlertMessage( at_notice, "tap    %1 : ", 20 );
		}
		else
			return;

		m_flHitTime = g_Engine.time + 0.5;

		//g_Game.AlertMessage( at_notice, "%1 : ", string(tr.pHit.vars.classname) );
		//g_Game.AlertMessage( at_notice, "%1 : %2 : %3\n", pev.angles.y, string(pOther.pev.classname), tr.iHitgroup );
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

		pev.velocity = g_vecZero;

		pev.angles.x = 0;
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
		pev.takedamage = DAMAGE_NO;

		if( bGibbed )
		{
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		pev.sequence = Math.RandomLong( ANIM_ENGINE_DEATH1, ANIM_ENGINE_DEATH3 );
		pev.frame = 0;
		self.ResetSequenceInfo();
		pev.framerate = Math.RandomFloat( 0.8, 1.2 );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		self.StudioFrameAdvance();

		if( self.m_fSequenceFinished )
		{
			SUB_Remove();
			return;
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

final class info_cnpc_tentacle : CNPCSpawnEntity
{
	private int m_iTapSound;

	info_cnpc_tentacle()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_FLOOR_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
		m_flSpawnOffset = CNPC_MODEL_OFFSET;
	}

	bool CustomKeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "tapsound" )
		{
			m_iTapSound = atoi( szValue );
			return true;
		}

		return false;
	}

	void SpecialUse( Vector vecOrigin, Vector vecAngles )
	{
		weapon_tentacle@ pWeapon = cast<weapon_tentacle@>( CastToScriptClass(m_pCNPCWeapon) );
		if( pWeapon !is null )
		{
			pWeapon.m_vecExitOrigin = vecOrigin;
			pWeapon.m_vecExitAngles = vecAngles;
		}

		g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "tapsound", "" + m_iTapSound );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_tentacle::info_cnpc_tentacle", "info_cnpc_tentacle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_tentacle::cnpc_tentacle", "cnpc_tentacle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_tentacle::weapon_tentacle", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_tentacle" );
	g_Game.PrecacheOther( "cnpc_tentacle" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_tentacle END

/* FIXME
*/

/* TODO
	Limit the player with sweeparc ??
*/