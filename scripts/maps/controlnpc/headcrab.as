namespace cnpc_headcrab
{

const bool CNPC_NPC_HITBOX		= true; //Use the hitbox of the monster model instead of the player. Experimental!
bool CNPC_FIRSTPERSON				= false;
	
const string CNPC_WEAPONNAME	= "weapon_headcrab";
const string CNPC_MODEL				= "models/headcrab.mdl";
const Vector CNPC_SIZEMIN1			= Vector( -16, -16, 0 ); //bigger hitbox required because the player is solid
const Vector CNPC_SIZEMAX1			= Vector( 16, 16, 64 );
const Vector CNPC_SIZEMIN2			= Vector( -16, -16, 0 );
const Vector CNPC_SIZEMAX2			= Vector( 16, 16, 24 );

const float CNPC_HEALTH				= 20.0;
const float CNPC_VIEWOFS_FPV		= -28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 0.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the template itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky movement on other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (40.729595 * CNPC::flModelToGameSpeedModifier); //9.623847
const float SPEED_RUN					= (81.45919 * CNPC::flModelToGameSpeedModifier); //40.729595
const float VELOCITY_WALK			= 50.0; //if the player's velocity is this or lower, use the walking animation
const float CD_LEAP						= 2.0;
const float DMG_LEAP					= 10.0;
const float LEAP_VELOCITY				= 350.0; //velocity to use when the player has no target
const float LEAP_DISTANCE_MAX	= 650.0;
const float LEAP_MAX_RANGE			= 1024.0;

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

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"headcrab/hc_attack1.wav",
	"headcrab/hc_attack2.wav",
	"headcrab/hc_attack3.wav",
	"headcrab/hc_headbite.wav",
	"headcrab/hc_idle1.wav",
	"headcrab/hc_idle2.wav",
	"headcrab/hc_idle3.wav"
};

enum sound_e
{
	SND_ATTACK1 = 1,
	SND_ATTACK2,
	SND_ATTACK3,
	SND_BITE,
	SND_IDLE1,
	SND_IDLE2,
	SND_IDLE3
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
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

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
			m1.WriteLong( g_ItemRegistry.GetIdForName(CNPC_WEAPONNAME) );
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
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.3;
			return;
		}

		if( m_pDriveEnt !is null )
		{
			m_iState = STATE_ATTACK_LEAP;
			m_flLeapResetCheck = g_Engine.time + 0.3;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			int iAnim = Math.RandomLong(ANIM_LEAP1, ANIM_LEAP3);
			SetAnim( iAnim );

			DoLeapAttack();
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

		int iSound = Math.RandomLong(0, SND_ATTACK3);
		if( iSound != 0 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[iSound], VOL_NORM, ATTN_IDLE );

		m_pPlayer.pev.velocity = vecJumpVelocity;

		m_pDriveEnt.pev.solid = SOLID_SLIDEBOX;
		m_pDriveEnt.pev.movetype = MOVETYPE_TOSS;

		cnpc_headcrab@ pDriveEnt = cast<cnpc_headcrab@>(CastToScriptClass(m_pDriveEnt));
		pDriveEnt.SetTouch( TouchFunction(pDriveEnt.LeapTouch) );
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
			cnpc_headcrab@ pDriveEnt = cast<cnpc_headcrab@>(CastToScriptClass(m_pDriveEnt));
			if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

			m_pPlayer.SetViewMode( ViewMode_ThirdPerson );
			m_pPlayer.pev.view_ofs = Vector( 0, 0, CNPC_VIEWOFS_TPV );
			CNPC_FIRSTPERSON = false;
		}

		self.m_flNextTertiaryAttack = g_Engine.time + 0.5;
	}

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			DoMovementAnimation();
			DoIdleAnimation();
			DoIdleSound();

			if( m_flLeapResetCheck > 0.0 and m_flLeapResetCheck < g_Engine.time and m_iState == STATE_ATTACK_LEAP and m_pDriveEnt.m_fSequenceFinished and m_pPlayer.pev.FlagBitSet(FL_ONGROUND) )
			{
				m_flLeapResetCheck = 0.0;
				DoIdleAnimation();
			}
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( CNPC_NPC_HITBOX )
			m_pPlayer.pev.solid = SOLID_NOT;

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or m_iState >= STATE_ATTACK_LEAP ) return;

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
		if( m_pDriveEnt is null ) return;
		if( m_iState == STATE_ATTACK_LEAP and !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

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
		if( m_pDriveEnt is null ) return;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE3)], VOL_NORM, ATTN_IDLE );
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_headcrab", m_pPlayer.pev.origin, m_pPlayer.pev.angles, false, m_pPlayer.edict()) );

		if( CNPC_NPC_HITBOX )
		{
			m_pPlayer.pev.solid = SOLID_NOT;
			m_pPlayer.pev.flags |= FL_NOTARGET;
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.view_ofs = Vector( 0, 0, 0 );
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
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_HEADCRAB );
	}

	void DoFirstPersonView()
	{
		cnpc_headcrab@ pDriveEnt = cast<cnpc_headcrab@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_headcrab_pid_" + m_pPlayer.entindex();
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

class cnpc_headcrab : ScriptBaseMonsterEntity//ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, (CNPC_NPC_HITBOX ? CNPC_SIZEMIN2 : CNPC_SIZEMIN1), (CNPC_NPC_HITBOX ? CNPC_SIZEMAX2 : CNPC_SIZEMAX1) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		if( CNPC_NPC_HITBOX )
		{
			pev.solid = SOLID_SLIDEBOX;
			pev.movetype = MOVETYPE_STEP;
			pev.flags |= FL_MONSTER;
			pev.deadflag = DEAD_NO;
			pev.takedamage = DAMAGE_AIM;
			pev.max_health = CNPC_HEALTH;
			pev.health = CNPC_HEALTH;
			self.m_bloodColor = BLOOD_COLOR_GREEN;
			self.m_FormattedName = "CNPC Headcrab";
			//g_EntityFuncs.DispatchKeyValue( self.edict(), "displayname", "CNPC Headcrab" );
		}
		else
		{
			pev.solid = SOLID_NOT;
			pev.movetype = MOVETYPE_NOCLIP;
		}

		pev.sequence = ANIM_IDLE;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flNextOriginUpdate = g_Engine.time;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	int Classify()
	{
		if( !CNPC_NPC_HITBOX ) return CLASS_NONE;

		if( CNPC::PVP )
		{
			if( m_pOwner !is null and m_pOwner.IsConnected() )
			{
				if( m_pOwner.Classify() == CLASS_PLAYER )
					return CLASS_PLAYER_ALLY;
				else
					return m_pOwner.Classify();
			}
		}

		return CLASS_PLAYER_ALLY;
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if( CNPC_NPC_HITBOX )
		{
			if( (bitsDamageType & DMG_ACID) != 0 )
				flDamage = 0;

			pev.health -= flDamage;

			if( m_pOwner !is null and m_pOwner.IsConnected() )
				m_pOwner.pev.health = pev.health;

			if( pev.health <= 0 )
			{
				if( m_pOwner !is null and m_pOwner.IsConnected() )
					m_pOwner.Killed( pevAttacker, GIB_NEVER );

				pev.health = 0;
				pev.takedamage = DAMAGE_NO;

				return 0;
			}

			pevAttacker.frags += self.GetPointsForDamage( flDamage );

			return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		}

		return 0;
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

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
		else
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		if( m_pOwner.pev.FlagBitSet(FL_ONGROUND) )
		{
			if( CNPC_NPC_HITBOX )
			{
				pev.movetype = MOVETYPE_STEP;
				pev.solid = SOLID_SLIDEBOX;
			}
			else
			{
				pev.movetype = MOVETYPE_NOCLIP;
				pev.solid = SOLID_NOT;
			}
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void LeapTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.takedamage == DAMAGE_NO )
			return;

		if( m_pOwner !is null and m_pOwner.IsConnected() and m_pOwner.pev.deadflag == DEAD_NO )
		{
			if( !m_pOwner.pev.FlagBitSet(FL_ONGROUND) )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_BITE], 1.0, ATTN_IDLE );

				pOther.TakeDamage( m_pOwner.pev, m_pOwner.pev, DMG_LEAP, DMG_SLASH );
			}
		}

		if( !CNPC_NPC_HITBOX )
			pev.solid = SOLID_NOT;

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

final class info_cnpc_headcrab : CNPCSpawnEntity
{
	info_cnpc_headcrab()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = (CNPC_NPC_HITBOX ? CNPC_SIZEMIN2 : CNPC_SIZEMIN1);
		m_vecSizeMax = (CNPC_NPC_HITBOX ? CNPC_SIZEMAX2 : CNPC_SIZEMAX1);
		m_flSpawnOffset = CNPC_MODEL_OFFSET;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_headcrab::info_cnpc_headcrab", "info_cnpc_headcrab" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_headcrab::cnpc_headcrab", "cnpc_headcrab" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_headcrab::weapon_headcrab", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_headcrab" );
	g_Game.PrecacheOther( "cnpc_headcrab" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_headcrab END

/* FIXME
*/

/* TODO
*/