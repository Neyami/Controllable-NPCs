namespace cnpc_bullsquid
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_bullsquid";
const string CNPC_MODEL				= "models/bullsquid.mdl";
const Vector CNPC_SIZEMIN			= Vector( -32, -32, 0 );
const Vector CNPC_SIZEMAX			= Vector( 32, 32, 64 );

const float CNPC_HEALTH				= 110.0;
const float CNPC_VIEWOFS_FPV		= 0.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the bullsquid itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (80.776039 * CNPC::flModelToGameSpeedModifier); //102.776039
const float SPEED_RUN					= (149.355347 * CNPC::flModelToGameSpeedModifier); //349.355347
const float VELOCITY_WALK			= 180.0; //if the player's velocity is this or lower, use the walking animation

const float CD_SPIT						= 2.0;
const float SPIT_VELOCITY				= 1500.0;

const float CD_BITE						= 1.5;
const float MELEE_RANGE_BITE		= 70.0;
const float MELEE_DAMAGE_BITE	= 25.0;

const float MELEE_DAMAGE_TAIL	= 45.0;

//sk_bullsquid_dmg_spit               "15"

const array<string> pPainSounds = 
{
	"bullchicken/bc_pain1.wav",
	"bullchicken/bc_pain2.wav",
	"bullchicken/bc_pain3.wav",
	"bullchicken/bc_pain4.wav"
};

const array<string> pDieSounds = 
{
	"bullchicken/bc_die1.wav",
	"bullchicken/bc_die2.wav",
	"bullchicken/bc_die3.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"bullchicken/bc_idle1.wav",
	"bullchicken/bc_idle2.wav",
	"bullchicken/bc_idle3.wav",
	"bullchicken/bc_idle4.wav",
	"bullchicken/bc_idle5.wav",
	"bullchicken/bc_attackgrowl.wav",
	"bullchicken/bc_attackgrowl2.wav",
	"bullchicken/bc_attackgrowl3.wav",
	"bullchicken/bc_bite2.wav",
	"bullchicken/bc_bite3.wav",
	"bullchicken/bc_attack2.wav",
	"bullchicken/bc_attack3.wav",
	"bullchicken/bc_acid1.wav",
	"bullchicken/bc_spithit1.wav",
	"bullchicken/bc_spithit2.wav"
};

enum sound_e
{
	SND_IDLE1 = 1,
	SND_IDLE5 = 5,
	SND_BITE1,
	SND_BITE2,
	SND_BITE3,
	SND_BITE1_HIT,
	SND_BITE2_HIT,
	SND_SPIT1,
	SND_SPIT2,
};

enum anim_e
{
	ANIM_WALK = 0,
	ANIM_RUN,
	ANIM_IDLE = 7,
	ANIM_ATTACK_TAIL,
	ANIM_ATTACK_BITE,
	ANIM_ATTACK_RANGE,
	ANIM_DEATH1 = 16,
	ANIM_DEATH2
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_ATTACK
};

class weapon_bullsquid : CBaseDriveWeapon
{
	private int m_iSquidSpitSprite;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( "sprites/bigspit.spr" ); //spit projectile.
		m_iSquidSpitSprite = g_Game.PrecacheModel( "sprites/tinyspit.spr" ); //client side spittle.

		g_SoundSystem.PrecacheSound( "zombie/claw_miss2.wav" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_bullsquid.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_bullsquid.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_bullsquid_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::BULLSQUID_SLOT - 1;
		info.iPosition			= CNPC::BULLSQUID_POSITION - 1;
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
			if( GetState() > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATTACK_RANGE );

			m_pDriveEnt.pev.angles.y = m_pPlayer.pev.v_angle.y;
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_BITE;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATTACK_BITE );

			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_BITE1, SND_BITE3)], VOL_NORM, ATTN_NORM );

			m_pDriveEnt.pev.angles.y = m_pPlayer.pev.v_angle.y;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_BITE;
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
			cnpc_bullsquid@ pDriveEnt = cast<cnpc_bullsquid@>(CastToScriptClass(m_pDriveEnt));
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

			CheckTailWhipInput();

			if( m_flNextThink <= g_Engine.time )
			{
				Blink();
				m_flNextThink = g_Engine.time + 0.1;
			}
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_RUN ) return;

		SetSpeed( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				SetState( STATE_WALK );
				SetSpeed( int(SPEED_WALK) );
				SetAnim( ANIM_WALK );
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				SetState( STATE_RUN );
				SetSpeed( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing

			if( (m_pPlayer.pev.button & IN_DUCK) != 0 )
			{
				m_pDriveEnt.pev.framerate = 1.25;
				SetSpeed( int(SPEED_RUN*1.25) );
			}
			else
				m_pDriveEnt.pev.framerate = 1.0;
		}
	}

	void DoIdleAnimation()
	{
		if( GetState() > STATE_RUN and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetSpeed( int(SPEED_RUN) );
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

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE5)], VOL_NORM, 1.5 );
	}

	void HandleAnimEvent( int iSequence )
	{
		if( !IsBetween2(iSequence, ANIM_ATTACK_TAIL, ANIM_ATTACK_RANGE) ) return;

		switch( iSequence )
		{
			case ANIM_ATTACK_BITE:
			{
				if( GetFrame(29, 7) and m_uiAnimationState == 0 ) { BiteAttack(); m_uiAnimationState++; }
				else if( GetFrame(29, 10) and m_uiAnimationState == 1 ) { BiteAttack(true); m_uiAnimationState++; }
				else if( GetFrame(29) > 20 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATTACK_TAIL:
			{
				if( GetFrame(55, 23) and m_uiAnimationState == 0 ) { TailAttack(); m_uiAnimationState++; }
				else if( GetFrame(55) > 33 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATTACK_RANGE:
			{
				if( GetFrame(42, 11) and m_uiAnimationState == 0 ) { SpitAttack(); m_uiAnimationState++; }
				else if( GetFrame(42) > 20 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void CheckTailWhipInput()
	{
		if( GetState() > STATE_RUN or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_JUMP) != 0 )
		{
			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATTACK_TAIL );

			m_pDriveEnt.pev.angles.y = m_pPlayer.pev.v_angle.y;
		}
	}

	void BiteAttack( bool bThrow = false )
	{
		if( !bThrow )
		{
			CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE_BITE, MELEE_DAMAGE_BITE, DMG_SLASH );
			
			if( pHurt !is null )
			{
				if( (pHurt.pev.flags & FL_MONSTER) != 0 or ((pHurt.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
				{
					pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_forward * 100;
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_up * 100;
				}
			}

			return;
		}

		if( CNPC::PVP )
		{
			CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE_BITE, 0, 0 );

			if( pHurt !is null )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_BITE1_HIT, SND_BITE2_HIT)], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(90, 110) );

				g_PlayerFuncs.ScreenShake( pHurt.pev.origin, 25.0, 1.5, 0.7, 2 );

				if( ((pHurt.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
				{
					Math.MakeVectors( m_pDriveEnt.pev.angles );
					pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * 300 + g_Engine.v_up * 300;
				}
			}
		}
	}

	void TailAttack()
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE_BITE, MELEE_DAMAGE_TAIL, (DMG_CLUB | DMG_ALWAYSGIB) );

		if( pHurt !is null )
		{
			if( ((pHurt.pev.flags & FL_CLIENT) != 0 and CNPC::PVP) )
			{
				pHurt.pev.punchangle.z = -20;
				pHurt.pev.punchangle.x = 20;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_right * 200;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_up * 100;
			}
		}
	}

	void SpitAttack()
	{
		Vector vecSpitOffset;
		Vector vecSpitDir;

		Math.MakeVectors( m_pDriveEnt.pev.angles );

		g_EngineFuncs.GetBonePosition( m_pDriveEnt.edict(), 19, vecSpitOffset, void );
		//vecSpitOffset = (g_Engine.v_right * 8 + g_Engine.v_forward * 37 + g_Engine.v_up * 23);
		//vecSpitOffset = (m_pDriveEnt.pev.origin + vecSpitOffset);
		Vector vecAim = m_pPlayer.pev.v_angle;
		Math.MakeVectors( vecAim );
		vecSpitDir = g_Engine.v_forward;

		/*vecSpitDir.x += Math.RandomFloat( -0.05, 0.05 );
		vecSpitDir.y += Math.RandomFloat( -0.05, 0.05 );
		vecSpitDir.z += Math.RandomFloat( -0.05, 0 );*/

		if( CNPC_FIRSTPERSON )
			vecSpitDir = vecSpitDir + g_Engine.v_right * -0.005 + g_Engine.v_up * 0.01;
		else
			vecSpitDir = vecSpitDir + g_Engine.v_right * -0.005 + g_Engine.v_up * 0.04;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_SPIT1, SND_SPIT1)], VOL_NORM, ATTN_NORM );

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpitOffset );
			m1.WriteByte( TE_SPRITE_SPRAY );
			m1.WriteCoord( vecSpitOffset.x ); //position
			m1.WriteCoord( vecSpitOffset.y );
			m1.WriteCoord( vecSpitOffset.z );
			m1.WriteCoord( vecSpitDir.x ); //direction
			m1.WriteCoord( vecSpitDir.y );
			m1.WriteCoord( vecSpitDir.z );
			m1.WriteShort( m_iSquidSpitSprite );
			m1.WriteByte( 15 ); //count
			m1.WriteByte( 210 ); //speed
			m1.WriteByte( 25 ); //noise (client will divide by 100)
		m1.End();

		ShootSpit( vecSpitOffset, vecSpitDir * SPIT_VELOCITY );
	}

	void ShootSpit( Vector vecStart, Vector vecVelocity )
	{
		CBaseEntity@ pSpit = g_EntityFuncs.Create( "squidspit", vecStart, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );

		pSpit.pev.movetype = MOVETYPE_FLY;
		pSpit.pev.velocity = vecVelocity;
		@pSpit.pev.owner = m_pPlayer.edict();

		pSpit.pev.nextthink = g_Engine.time + 0.1;
	}

	void Blink()
	{
		if( m_pDriveEnt.pev.skin != 0 )
		{
			// close eye if it was open.
			m_pDriveEnt.pev.skin = 0; 
		}

		if( Math.RandomLong(0, 39) == 0 )
			m_pDriveEnt.pev.skin = 1;
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_bullsquid", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

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
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_BULLSQUID );
	}

	void DoFirstPersonView()
	{
		cnpc_bullsquid@ pDriveEnt = cast<cnpc_bullsquid@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_bullsquid_rend_" + m_pPlayer.entindex();
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

class cnpc_bullsquid : CBaseDriveEntity
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and (pev.sequence == ANIM_RUN or pev.sequence == ANIM_WALK) )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		//else
			//pev.angles.y = m_pOwner.pev.angles.y;

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
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH2 );
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.SUB_StartFadeOut) );
		pev.nextthink = g_Engine.time;
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

final class info_cnpc_bullsquid : CNPCSpawnEntity
{
	info_cnpc_bullsquid()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_bullsquid::info_cnpc_bullsquid", "info_cnpc_bullsquid" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_bullsquid::cnpc_bullsquid", "cnpc_bullsquid" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_bullsquid::weapon_bullsquid", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_bullsquid" );
	g_Game.PrecacheOther( "cnpc_bullsquid" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_bullsquid END

/* FIXME
*/

/* TODO
	NPC Hitbox
*/