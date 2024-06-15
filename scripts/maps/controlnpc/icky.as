//CAUTION: MESSY CODE AHEAD

namespace cnpc_icky
{

bool CNPC_FIRSTPERSON				= false;
	
const string sWeaponName			= "weapon_icky";

const float CNPC_HEALTH				= 350.0;
const float CNPC_CAMDIST				= 256.0;
const float CNPC_VIEWOFS_FPV		= 0.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 40.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the icky itself
const float CNPC_FLOATTIME			= 20.0; //the body will stick around for this long

const float SPEED_RUN_MAX			= 300.0;
const float SPEED_WALK_MAX			= 150.0;
const float VELOCITY_WALK			= 180.0; //if the velocity is this or lower, use the walking animation
const float CD_PRIMARY					= 1.5;
const float CD_SECONDARY				= 0.1;
const float CD_SECONDARY_HIT		= 2.0; //after biting an enemy

const int BITE_DAMAGE1					= 15; //primary quick bites
const int BITE_DAMAGE2					= 30; //charge
const float BITE_RANGE					= 192.0;

const array<string> pPainSounds = 
{
	"ichy/ichy_pain2.wav",
	"ichy/ichy_pain3.wav",
	"ichy/ichy_pain5.wav"
};

const array<string> pDieSounds = 
{
	"ichy/ichy_die2.wav",
	"ichy/ichy_die4.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav",
	"ichy/ichy_attack1.wav",
	"ichy/ichy_attack2.wav",
	"ichy/ichy_bite1.wav",
	"ichy/ichy_bite2.wav"
};

enum sound_e
{
	SND_RESPAWN = 0,
	SND_ATTACK1,
	SND_ATTACK2,
	SND_BITE1,
	SND_BITE2
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_BELLYUP = 7,
	ANIM_BITE_RIGHT,
	ANIM_BITE_LEFT,
	ANIM_BITE_BIG
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_BITE,
	STATE_CHARGE,
	STATE_CHARGE_HIT
};

class weapon_icky : CBaseDriveWeapon
{
	private float m_flNextSpeedChange;
	private float m_flSwimSpeed;
	private float m_flMaxSpeed;
	private int m_iRandomAttack;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_flNextSpeedChange = 0.0;
		m_flSwimSpeed = 0.0;
		m_flMaxSpeed = SPEED_RUN_MAX;
		m_iRandomAttack = 0;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/icky.mdl" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_icky.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_icky.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_icky_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::ICKY_SLOT - 1;
		info.iPosition		= CNPC::ICKY_POSITION - 1;
		info.iFlags 			= 0;
		info.iWeight			= 0; //-1 ??

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m1.WriteLong( g_ItemRegistry.GetIdForName(sWeaponName) );
		m1.End();

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;
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
			if( m_iState != STATE_CHARGE and m_iState != STATE_CHARGE_HIT )
			{
				m_iState = STATE_BITE;
				m_iRandomAttack = Math.RandomLong(0, 1);

				switch( m_iRandomAttack )
				{
					case 0:	m_pDriveEnt.pev.sequence = ANIM_BITE_LEFT; pev.nextthink = g_Engine.time + 0.5; break;
					case 1:	m_pDriveEnt.pev.sequence = ANIM_BITE_RIGHT; pev.nextthink = g_Engine.time + 0.4; break;
				}

				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				SetThink( ThinkFunction(this.MeleeAttackThink) );
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null and m_iState != STATE_BITE )
		{
			if( m_iState != STATE_CHARGE )
			{
				cnpc_icky@ pDriveEnt = cast<cnpc_icky@>(CastToScriptClass(m_pDriveEnt));
				if( pDriveEnt !is null )
				{
					m_pDriveEnt.pev.sequence = ANIM_RUN;
					m_pDriveEnt.pev.frame = 0;
					m_pDriveEnt.ResetSequenceInfo();

					m_iState = STATE_CHARGE;
					pDriveEnt.m_iState = STATE_CHARGE;
					pDriveEnt.SetTouch( TouchFunction(pDriveEnt.BiteTouch) );
				}
			}
			else if( m_iState == STATE_CHARGE )
			{
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_ATTACK1, SND_ATTACK2)], VOL_NORM, 0.6, 0, Math.RandomLong(95, 105) );

				cnpc_icky@ pDriveEnt = cast<cnpc_icky@>(CastToScriptClass(m_pDriveEnt));
				if( pDriveEnt !is null )
				{
					if( pDriveEnt.m_iState == STATE_CHARGE_HIT )
					{
						m_iState = STATE_CHARGE_HIT;
						m_pDriveEnt.pev.velocity = g_vecZero;
						self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY_HIT;
						self.m_flTimeWeaponIdle = g_Engine.time + CD_SECONDARY_HIT;

						return;
					}
				}
			}
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_SECONDARY;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_SECONDARY;
	}

	void TertiaryAttack()
	{
		if( !CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			DoFirstPersonView();
			CNPC_FIRSTPERSON = true;
		}
		else
		{
			cnpc_icky@ pDriveEnt = cast<cnpc_icky@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}

		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
	}

	void Reload() //necessary to prevent the reload-key from interfering?
	{
	}

	//doesn't actually do anything??
	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		DoIdleAnimation();

		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.pev.friction = 2; //no sliding!

			/*NetworkMessage disableduck( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
				disableduck.WriteString( "-duck\n" );
			disableduck.End();*/

			KeepInWater();
			DoMovement();

			if( m_iState == STATE_CHARGE and m_pPlayer.pev.button & IN_ATTACK2 == 0 )
			{
				cnpc_icky@ pDriveEnt = cast<cnpc_icky@>(CastToScriptClass(m_pDriveEnt));
				if( pDriveEnt !is null )
				{
					pDriveEnt.SetTouch( null );
					pDriveEnt.m_iState = STATE_RUN;
				}

				m_iState = STATE_RUN;
			}

			if( m_pPlayer.pev.velocity.Length2D() <= 10.0 )
				DoIdleAnimation();
		}
	}

	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
		{
			SetThink( null );
			return;
		}

		CBaseEntity@ pHurt = CheckTraceHullAttack( BITE_RANGE, BITE_DAMAGE1, (DMG_SLASH|DMG_ALWAYSGIB) );

		if( pHurt !is null )
		{
			if( (pHurt.pev.flags & FL_MONSTER) == 1 and (pHurt.pev.flags & FL_CLIENT) == 0 )
			{
				pHurt.pev.punchangle.y = (m_iRandomAttack == 1) ? -25.0 : 25.0;
				pHurt.pev.punchangle.x = 8.0;
			}
			else if( (pHurt.pev.flags & FL_CLIENT) == 1 and CNPC::PVP )
			{
				pHurt.pev.punchangle.y = (m_iRandomAttack == 1) ? -25.0 : 25.0;
				pHurt.pev.punchangle.x = 8.0;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_right * ((m_iRandomAttack == 1) ? -250.0 : 250.0);
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_BITE1, SND_BITE2)], VOL_NORM, 0.6, 0, Math.RandomLong(95, 105) );

			g_WeaponFuncs.SpawnBlood( pHurt.Center(), pHurt.BloodColor(), 125 );
		}

		SetThink( null );
	}

	void KeepInWater()
	{
		if( m_pDriveEnt.pev.waterlevel < WATERLEVEL_WAIST )
			m_pDriveEnt.pev.movetype = MOVETYPE_STEP;
		else
			m_pDriveEnt.pev.movetype = MOVETYPE_FLY;
	}

	void DoMovement()
	{
		g_EntityFuncs.SetOrigin( m_pPlayer, m_pDriveEnt.pev.origin );

		m_pPlayer.pev.velocity = m_pDriveEnt.pev.velocity;

		Vector vecAngles = m_pPlayer.pev.v_angle;
		vecAngles.x = -vecAngles.x;
		m_pDriveEnt.pev.angles = vecAngles;

		if( m_iState == STATE_CHARGE )
			m_flMaxSpeed = SPEED_RUN_MAX * 1.5;
		else if( m_pPlayer.pev.button & IN_DUCK != 0 )
			m_flMaxSpeed = SPEED_WALK_MAX;
		else
			m_flMaxSpeed = SPEED_RUN_MAX;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		if( m_pPlayer.pev.button & IN_FORWARD != 0 or m_iState == STATE_CHARGE )
		{
			DoMovementAnimation();

			if( m_flSwimSpeed < m_flMaxSpeed )
			{
				if( m_flNextSpeedChange < g_Engine.time )
				{
					m_flSwimSpeed += 40.0;
					m_flNextSpeedChange = g_Engine.time + 0.1;
				}
			}
		}
		else
		{
			if( m_flSwimSpeed > 0 )
			{
				DoMovementAnimation();

				if( m_flNextSpeedChange < g_Engine.time )
				{
					m_flSwimSpeed -= 40.0;
					m_flNextSpeedChange = g_Engine.time + 0.1;
				}
			}
		}

		Vector vecVelocity = g_Engine.v_forward * Math.clamp( 0, m_flMaxSpeed, m_flSwimSpeed );

		if( m_pDriveEnt.pev.waterlevel < WATERLEVEL_WAIST and vecVelocity.z > 0.0 )
			vecVelocity.z = 0.0;

		m_pDriveEnt.pev.velocity = vecVelocity;
	}

	void DoMovementAnimation()
	{
		if( m_iState == STATE_CHARGE or (m_pDriveEnt.pev.sequence == ANIM_BITE_BIG and !m_pDriveEnt.m_fSequenceFinished) ) return;
		if( (m_pDriveEnt.pev.sequence == ANIM_BITE_LEFT or m_pDriveEnt.pev.sequence == ANIM_BITE_RIGHT) and !m_pDriveEnt.m_fSequenceFinished ) return;

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( IsBetween(m_pDriveEnt.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pDriveEnt.pev.sequence = ANIM_WALK;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				m_iState = STATE_RUN;
				m_pDriveEnt.pev.sequence = ANIM_RUN;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;
		if( m_pDriveEnt.pev.sequence == ANIM_BITE_BIG and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( (m_pDriveEnt.pev.sequence == ANIM_BITE_LEFT or m_pDriveEnt.pev.sequence == ANIM_BITE_RIGHT) and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_iState != STATE_IDLE )
		{
			m_iState = STATE_IDLE;
			m_pDriveEnt.pev.sequence = ANIM_IDLE;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();
		}
	}

	void spawn_driveent()
	{
		if( m_pPlayer.pev.waterlevel < WATERLEVEL_HEAD )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nout of water" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		if( m_iAutoDeploy == 0 )
			vecOrigin.z -= 32.0;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_icky", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;
		m_pPlayer.SetMaxSpeedOverride( 0 );
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		m_pPlayer.pev.solid = SOLID_NOT;

		self.m_bExclusiveHold = true;

		if( CNPC_FIRSTPERSON )
		{
			m_pPlayer.SetViewMode( ViewMode_FirstPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_FPV );
			DoFirstPersonView();
		}
		else
		{
			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist " + CNPC_CAMDIST + "\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_ICKY );
	}

	void DoFirstPersonView()
	{
		cnpc_icky@ pDriveEnt = cast<cnpc_icky@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_icky_pid_" + m_pPlayer.entindex();
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
		m_pPlayer.pev.fuser4 = 0; //enable jump
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 28 );
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_icky : ScriptBaseAnimating
{
	int m_iState;
	EHandle m_hRenderEntity;
	private float m_flRemoveCorpse;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/icky.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-32, -32, 0), Vector(32, 32, 64) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid = SOLID_BBOX;
		pev.movetype = MOVETYPE_FLY;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		self.SetBoneController( 0, 0 );

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void BiteTouch( CBaseEntity@ pOther )
	{
		if( !pOther.pev.FlagBitSet((FL_MONSTER|FL_CLIENT)) or !pOther.IsAlive() ) return;

		Vector2D vec2LOS;

		Math.MakeVectors( pev.angles );

		vec2LOS = (pOther.pev.origin - pev.origin).Make2D();
		vec2LOS = vec2LOS.Normalize();

		if( DotProduct(vec2LOS , g_Engine.v_forward.Make2D()) >= 0.7 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_BITE1, SND_BITE2)], VOL_NORM, 0.6, 0, Math.RandomLong(95, 105) );

			pev.sequence = ANIM_BITE_BIG;
			pev.frame = 0;
			self.ResetSequenceInfo();

			if( (pOther.pev.flags & FL_CLIENT) == 0 )
			{
				pOther.TakeDamage( pev.owner.vars, pev.owner.vars, BITE_DAMAGE2, (DMG_SLASH|DMG_ALWAYSGIB) );
				pOther.pev.punchangle.z = -18;
				pOther.pev.punchangle.x = 5;
				pOther.pev.velocity = pOther.pev.velocity - g_Engine.v_right * 300;
			}
			else if( (pOther.pev.flags & FL_CLIENT) == 1 and CNPC::PVP )
			{
				pOther.TakeDamage( pev.owner.vars, pev.owner.vars, BITE_DAMAGE2, (DMG_SLASH|DMG_ALWAYSGIB) );
				pOther.pev.punchangle.z = -18;
				pOther.pev.punchangle.x = 5;
				pOther.pev.velocity = pOther.pev.velocity - g_Engine.v_right * 300;
				pOther.pev.angles.x += Math.RandomFloat( -35, 35 );
				pOther.pev.angles.y += Math.RandomFloat( -90, 90 );
				pOther.pev.angles.z = 0;
				pOther.pev.fixangle = FAM_FORCEVIEWANGLES;
			}

			g_WeaponFuncs.SpawnBlood( pOther.Center(), pOther.BloodColor(), 250 );

			m_iState = STATE_CHARGE_HIT;
			SetTouch( null );
		}
	}

	void DriveThink()
	{
		if( pev.owner is null or pev.owner.vars.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

			return;
		}

		self.StudioFrameAdvance();

		if( m_iState == STATE_CHARGE )
			pev.framerate = 2.0;
		else
			pev.framerate = 1.0;

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH2 );
		pev.frame = 0;
		self.ResetSequenceInfo();
		self.StudioFrameAdvance();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, 0.6, 0, Math.RandomLong(95, 105) );

		SetThink( ThinkFunction(this.FloatThink) );
		pev.nextthink = g_Engine.time;
	}

	void FloatThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		self.StudioFrameAdvance();

		if( (pev.sequence == ANIM_DEATH1 or pev.sequence == ANIM_DEATH2) and self.m_fSequenceFinished )
		{
			pev.deadflag = DEAD_DEAD;
			pev.skin = 1; //EYE_BASE

			pev.sequence = ANIM_BELLYUP;
			pev.frame = 0;
			self.ResetSequenceInfo();

			m_flRemoveCorpse = g_Engine.time + CNPC_FLOATTIME;
		}
		else if( pev.sequence == ANIM_BELLYUP )
		{
			pev.angles.x = Math.ApproachAngle( 0, pev.angles.x, 20 );
			pev.velocity = pev.velocity * 0.8;

			if( pev.waterlevel > WATERLEVEL_FEET and pev.velocity.z < 64 )
				pev.velocity.z += 8;
			else 
				pev.velocity.z -= 8;
		}

		if( m_flRemoveCorpse > 0.0 and m_flRemoveCorpse < g_Engine.time )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time;
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

class info_cnpc_icky : ScriptBaseAnimating
{
	protected EHandle m_hCNPCWeapon;
	protected CBaseEntity@ m_pCNPCWeapon
	{
		get const { return cast<CBaseEntity@>(m_hCNPCWeapon.GetEntity()); }
		set { m_hCNPCWeapon = EHandle(@value); }
	}

	private float m_flRespawnTime; //how long until respawn
	private float m_flTimeToRespawn; //used to check if ready to respawn

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
		g_EntityFuncs.SetModel( self, "models/icky.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-32, -32, 0), Vector(32, 32, 64) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = ANIM_IDLE;
		pev.rendermode = kRenderTransTexture;
		pev.renderfx = kRenderFxDistort;
		pev.renderamt = 128;

		self.SetBoneController( 0, 0 );

		if( m_flRespawnTime == 0 ) m_flRespawnTime = CNPC_RESPAWNTIME;

		SetUse( UseFunction(this.UseCNPC) );
	}

	int ObjectCaps() { return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE); }

	void UseCNPC( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue  ) 
	{
		if( pActivator.pev.FlagBitSet(FL_CLIENT) )
		{
			g_EntityFuncs.SetOrigin( pActivator, pev.origin );
			pActivator.pev.angles = pev.angles;
			pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
			@m_pCNPCWeapon = g_EntityFuncs.Create( sWeaponName, pActivator.pev.origin, g_vecZero, true );
			m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

			g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
			g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );
			m_pCNPCWeapon.Touch( pActivator ); //make sure they pick it up

			SetUse( null );
			pev.effects |= EF_NODRAW;

			if( m_flRespawnTime == -1 )
			{
				g_EntityFuncs.Remove( self );
				return;
			}

			SetThink( ThinkFunction(this.RespawnThink) );
			pev.nextthink = g_Engine.time;
		}
	}

	void RespawnThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( m_pCNPCWeapon is null and m_flTimeToRespawn <= 0.0 )
			m_flTimeToRespawn = g_Engine.time + m_flRespawnTime;

		if( m_flTimeToRespawn > 0.0 and m_flTimeToRespawn <= g_Engine.time )
		{
			SetThink( null );
			SetUse( UseFunction(this.UseCNPC) );
			pev.effects &= ~EF_NODRAW;
			m_flTimeToRespawn = 0.0;

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_RESPAWN], VOL_NORM, 0.3, 0, 90 );
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_icky::info_cnpc_icky", "info_cnpc_icky" );
	g_Game.PrecacheOther( "info_cnpc_icky" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_icky::cnpc_icky", "cnpc_icky" );
	g_Game.PrecacheOther( "cnpc_icky" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_icky::weapon_icky", sWeaponName );
	g_ItemRegistry.RegisterWeapon( sWeaponName, "controlnpc" );
	g_Game.PrecacheOther( sWeaponName );
}

} //namespace cnpc_icky END

/* FIXME
*/

/* TODO
	Use turning animations? rturn = 11, lturn = 12, 180turn = 13
*/