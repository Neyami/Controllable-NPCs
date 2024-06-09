namespace cnpc_headcrab
{
	
const string sWeaponName			= "weapon_headcrab";

const float CNPC_HEALTH				= 20.0;

const float SPEED_WALK					= 40.729595 * CNPC::flModelToGameSpeedModifier; //9.623847
const float SPEED_RUN					= 81.45919 * CNPC::flModelToGameSpeedModifier; //40.729595
const float VELOCITY_WALK			= 50.0; //if the player's velocity is this or lower, use the walking animation
const float CD_LEAP						= 2.0;
const float DMG_LEAP						= 10.0;
const float LEAP_VELOCITY				= 350.0; //velocity to use when the player has no target
const float LEAP_DISTANCE_MAX	= 650.0;
const float LEAP_MAX_RANGE			= 1024.0;

const array<string> pAttackSounds = 
{
	"headcrab/hc_attack1.wav",
	"headcrab/hc_attack2.wav",
	"headcrab/hc_attack3.wav"
};

const array<string> pPainSounds = 
{
	"headcrab/hc_pain1.wav",
	"headcrab/hc_pain2.wav",
	"headcrab/hc_pain3.wav"
};

const array<string> pDieSounds = 
{
	"headcrab/hc_die1.wav",
	"headcrab/hc_die2.wav"
};

const array<string> pBiteSounds = 
{
	"headcrab/hc_headbite.wav"
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK = 3,
	ANIM_RUN,
	ANIM_DEATH = 7,
	ANIM_LEAP1 = 10,
	ANIM_LEAP2,
	ANIM_LEAP3
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_DEATH,
	STATE_ATTACK_LEAP
};

class weapon_headcrab : CBaseDriveWeapon
{
	private float m_flLeapResetCheck;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_flLeapResetCheck = 0.0;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/headcrab.mdl" );

		for( uint i = 0; i < pAttackSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		for( uint i = 0; i < pBiteSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pBiteSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_headcrab.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_headcrab.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_headcrab_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::HEADCRAB_SLOT - 1;
		info.iPosition		= CNPC::HEADCRAB_POSITION - 1;
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

		return true;
	}

	bool Deploy()
	{
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
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.3;
			return;
		}

		if( m_pDriveEnt !is null )
		{
			if( m_iState != STATE_DEATH )
			{
				m_iState = STATE_ATTACK_LEAP;
				m_flLeapResetCheck = g_Engine.time + 0.3;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				int iAnim = Math.RandomLong(ANIM_LEAP1, ANIM_LEAP3);
				m_pDriveEnt.pev.sequence = iAnim;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				DoLeapAttack();
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_LEAP;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_LEAP;
	}

	void DoLeapAttack()
	{
		m_pPlayer.pev.flags &= ~FL_ONGROUND;
		Math.MakeVectors( m_pPlayer.pev.angles );
		
		Vector vecJumpVelocity;
		CBaseEntity@ pTarget = g_Utility.FindEntityForward( m_pPlayer, LEAP_MAX_RANGE );

		if( pTarget !is null and pTarget.pev.FlagBitSet(FL_MONSTER) and pTarget.IsAlive() and pTarget.pev.takedamage != DAMAGE_NO )
		{
			g_EntityFuncs.SetOrigin( m_pPlayer, m_pPlayer.pev.origin + Vector(0, 0, 10) );// take him off ground so engine doesn't instantly reset onground 

			float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
			if( gravity <= 1 )
				gravity = 1;

			float height = ( pTarget.pev.origin.z + pTarget.pev.view_ofs.z - m_pPlayer.pev.origin.z );
			if( height < 32 )
				height = 32;

			float speed = sqrt( 2 * gravity * height );
			float time = speed / gravity;

			vecJumpVelocity = ( pTarget.pev.origin + pTarget.pev.view_ofs - m_pPlayer.pev.origin );
			vecJumpVelocity = vecJumpVelocity * ( 1.0 / time );

			vecJumpVelocity.z = speed;

			float distance = vecJumpVelocity.Length();
			
			if( distance > LEAP_DISTANCE_MAX )
				vecJumpVelocity = vecJumpVelocity * ( LEAP_DISTANCE_MAX / distance );
		}
		else
		{
			g_EntityFuncs.SetOrigin( m_pPlayer, m_pPlayer.pev.origin + Vector(0, 0, 1) );
			vecJumpVelocity = Vector( g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z ) * LEAP_VELOCITY;
			//Math.MakeVectors( m_pPlayer.pev.v_angle );
			//vecJumpVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * 400 + g_Engine.v_up * 200;
		}

		int iSound = Math.RandomLong(0, 2);
		if( iSound != 0 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pAttackSounds[iSound], VOL_NORM, ATTN_IDLE );

		m_pPlayer.pev.velocity = vecJumpVelocity;

		m_pDriveEnt.pev.solid = SOLID_SLIDEBOX;
		m_pDriveEnt.pev.movetype = MOVETYPE_TOSS;

		cnpc_headcrab@ pDriveEnt = cast<cnpc_headcrab@>(CastToScriptClass(m_pDriveEnt));
		pDriveEnt.SetTouch( TouchFunction(pDriveEnt.LeapTouch) );
	}

	void Reload()
	{
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iState == STATE_ATTACK_LEAP and !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			return;

		DoIdleAnimation();

		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.pev.friction = 2; //no sliding!

			if( m_pPlayer.pev.button & (IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 )
				m_pPlayer.SetMaxSpeedOverride( 0 );
			else if( m_pPlayer.pev.button & IN_FORWARD != 0 )
			{
				if( m_iState != STATE_ATTACK_LEAP )
				{
					m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
					DoMovementAnimation();
					self.m_flTimeWeaponIdle = g_Engine.time + 0.1;
				}
			}

			if( m_pPlayer.pev.velocity.Length() <= 10.0 and m_iState != STATE_ATTACK_LEAP )
				DoIdleAnimation();

			if( m_flLeapResetCheck > 0.0 and m_flLeapResetCheck < g_Engine.time and m_iState == STATE_ATTACK_LEAP and m_pDriveEnt.m_fSequenceFinished and m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			{
				m_flLeapResetCheck = 0.0;
				DoIdleAnimation();
			}
		}
	}

	void DoMovementAnimation()
	{
		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
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
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_pDriveEnt.pev.sequence = ANIM_RUN;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;

		if( m_iState != STATE_IDLE )
		{
			m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
			m_iState = STATE_IDLE;
			m_pDriveEnt.pev.sequence = ANIM_IDLE;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();
		}
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_headcrab", m_pPlayer.pev.origin, m_pPlayer.pev.angles, true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 0 );
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;

		self.m_bExclusiveHold = true;

		m_pPlayer.SetViewMode( ViewMode_ThirdPerson );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_HEADCRAB );
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

class cnpc_headcrab : ScriptBaseAnimating
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/headcrab.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 72) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void DriveThink()
	{
		if( pev.owner is null or pev.owner.vars.deadflag != DEAD_NO )
		{
			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		Vector vecOrigin = pOwner.pev.origin;
		vecOrigin.z -= 32.0;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.velocity = pOwner.pev.velocity;

		pev.angles.x = 0;
		pev.angles.y = pOwner.pev.angles.y;
		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void LeapTouch( CBaseEntity@ pOther )
	{
		if( pev.owner is null or pOther.pev.takedamage == DAMAGE_NO )
			return;

		if( !pev.FlagBitSet(FL_ONGROUND) )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, pBiteSounds[Math.RandomLong(0,(pBiteSounds.length() - 1))], 1.0, ATTN_IDLE );

			pOther.TakeDamage( pev.owner.vars, pev.owner.vars, DMG_LEAP, DMG_SLASH );
		}

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		SetTouch( null );
	}

	void DieThink()
	{
		pev.sequence = ANIM_DEATH;
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

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_headcrab::cnpc_headcrab", "cnpc_headcrab" );
	g_Game.PrecacheOther( "cnpc_headcrab" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_headcrab::weapon_headcrab", sWeaponName );
	g_ItemRegistry.RegisterWeapon( sWeaponName, "controlnpc" );
	g_Game.PrecacheOther( sWeaponName );
}

} //namespace cnpc_headcrab END

/* FIXME
*/

/* TODO
*/