namespace cnpc_pitdrone
{

const string CNPC_WEAPONNAME	= "weapon_pitdrone";
const string CNPC_MODEL				= "models/pit_drone.mdl";
const Vector CNPC_SIZEMIN			= Vector(-16, -16, 0);
const Vector CNPC_SIZEMAX			= Vector(16, 16, 72);

const float CNPC_HEALTH				= 60.0;
const float CNPC_MODEL_OFFSET	= 32.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky movement on other players
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the template itself

const bool DISABLE_CROUCH			= false;
const float CNPC_VIEWOFS				= 0.0; //camera height offset

//The numbers are from the model, but are too slow :FeelsBadMan:
const float SPEED_WALK					= -1; //66.860611 * CNPC::flModelToGameSpeedModifier;
const float SPEED_RUN					= -1; //126.246635 * CNPC::flModelToGameSpeedModifier;

const float RANGE_CD						= 0.8;
const float RANGE_DAMAGE				= 15.0;
const float RANGE_SPEED				= 900.0;
const float RANGE_PITCH_MIN		= -44.5;
const float RANGE_PITCH_MAX		= 32.0;

const float MELEE_CD						= 1.5;
const float MELEE_RANGE				= 70.0;
const float MELEE_DAMAGE1			= 25.0;
const float MELEE_DAMAGE2			= 25.0;

const float RELOAD_TIME				= 1.0;
const float JUMP_VELOCITY				= 350.0;


const array<string> pAttackSounds = 
{
	"pitdrone/pit_drone_melee_attack1.wav",
	"pitdrone/pit_drone_melee_attack2.wav"
};

const array<string> pAttackHitStrikeSounds = 
{
	"bullchicken/bc_bite2.wav"
};

const array<string> pAttackMissSounds = 
{
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav"
};

const array<string> pAttackSoundsSpike = 
{
	"pitdrone/pit_drone_attack_spike1.wav",
	"pitdrone/pit_drone_attack_spike2.wav"
};

const array<string> pPainSounds = 
{
	"pitdrone/pit_drone_pain1.wav",
	"pitdrone/pit_drone_pain2.wav",
	"pitdrone/pit_drone_pain3.wav",
	"pitdrone/pit_drone_pain4.wav"
};

const array<string> pDieSounds = 
{
	"pitdrone/pit_drone_die1.wav",
	"pitdrone/pit_drone_die2.wav",
	"pitdrone/pit_drone_die3.wav"
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_MELEE1,
	ANIM_MELEE2,
	ANIM_RANGE,
	ANIM_RELOAD,
	ANIM_JUMP,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_DEATH3
};

const array<string> arrsAnims = 
{
	"idle_1",
	"walk",
	"run",
	"bite",
	"whip",
	"range",
	"reload",
	"jump",
	"die",
	"die1",
	"die2"
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_ATTACK_RANGE,
	STATE_ATTACK_MELEE,
	STATE_RELOAD,
	STATE_JUMP
};

class weapon_pitdrone : CBaseDriveWeapon
{
	private int m_iRandomAttack;
	private int m_iSpikeSpray;
	private float m_flDuckPressed;

	void Spawn()
	{
		Precache();

		self.m_iDefaultAmmo = 6;

		m_iState = STATE_IDLE;
		m_iRandomAttack = 0;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( "models/pit_drone_spike.mdl" );
		m_iSpikeSpray = g_Game.PrecacheModel( "sprites/tinyspit.spr" );

		uint i;

		for( i = 0; i < pAttackSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackSounds[i] );

		for( i = 0; i < pAttackHitStrikeSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackHitStrikeSounds[i] );

		for( i = 0; i < pAttackMissSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackMissSounds[i] );

		for( i = 0; i < pAttackSoundsSpike.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackSoundsSpike[i] );

		for( i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_pitdrone.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_pitdrone.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_pitdrone_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::PITDRONE_SLOT - 1;
		info.iPosition		= CNPC::PITDRONE_POSITION - 1;
		info.iFlags 			= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY;
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

		m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, 6);

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
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.3;
			return;
		}

		if( m_pDriveEnt !is null )
		{
			m_iState = STATE_ATTACK_RANGE;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_RANGE]);
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			SetThink( ThinkFunction(this.RangeAttackThink) );
			pev.nextthink = g_Engine.time + 0.3;
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + RANGE_CD;
		self.m_flTimeWeaponIdle = g_Engine.time + RANGE_CD;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null and m_iState != STATE_ATTACK_RANGE and m_iState != STATE_RELOAD )
		{
			m_iState = STATE_ATTACK_MELEE;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iRandomAttack = Math.RandomLong(0, 1);

			switch( m_iRandomAttack )
			{
				//both arms
				case 0:
				{
					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, pAttackSounds[0], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
					m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_MELEE1]);
					pev.nextthink = g_Engine.time + 0.5;

					break;
				}

				//slashes
				case 1:
				{
					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, pAttackSounds[1], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
					m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_MELEE2]);
					pev.nextthink = g_Engine.time + 0.2;

					break;
				}
			}

			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			SetThink( ThinkFunction(this.MeleeAttackThink) );

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + MELEE_CD;
			self.m_flTimeWeaponIdle = g_Engine.time + MELEE_CD;
		}
	}

	void Reload()
	{
	}

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

			if( DISABLE_CROUCH )
			{
				NetworkMessage disableduck( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
					disableduck.WriteString( "-duck\n" );
				disableduck.End();
			}
			else
				m_pPlayer.pev.view_ofs = Vector( 0.0, 0.0, CNPC_VIEWOFS );

			if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and (m_iState < STATE_ATTACK_RANGE or (m_iState == STATE_JUMP and m_pPlayer.pev.FlagBitSet(FL_ONGROUND))) )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				DoMovementAnimation();
			}

			if( m_pPlayer.pev.velocity.Length() <= 10.0 and m_iState != STATE_ATTACK_RANGE and m_iState != STATE_ATTACK_MELEE and m_iState != STATE_RELOAD )
				DoIdleAnimation();

			if( (m_pPlayer.pev.button & IN_DUCK) != 0 and (m_pPlayer.pev.oldbuttons & IN_DUCK) == 0 and m_flDuckPressed <= 0.0 )
				m_flDuckPressed = g_Engine.time + 0.3;

			DoReload();
			DoJump();
		}
	}

	void RangeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null or m_iState != STATE_ATTACK_RANGE )
		{
			SetThink( null );
			return;
		}

		ShootSpike();
		SetThink( null );
	}

	void ShootSpike()
	{
		if( m_pDriveEnt !is null and m_pPlayer.IsAlive() )
		{
			Vector vecOrigin, vecAngle, vecDir, vecForward, vecUp;
			g_EngineFuncs.AngleVectors( m_pDriveEnt.pev.angles, vecForward, void, vecUp );

			vecAngle = m_pPlayer.pev.v_angle;
			if( vecAngle.x < RANGE_PITCH_MIN ) vecAngle.x = RANGE_PITCH_MIN;
			if( vecAngle.x > RANGE_PITCH_MAX ) vecAngle.x = RANGE_PITCH_MAX;

			Math.MakeVectors( vecAngle );

			vecOrigin = ( vecForward * 15 + vecUp * 36 );
			vecOrigin = ( m_pDriveEnt.pev.origin + vecOrigin );

			vecDir = g_Engine.v_forward;

			vecDir.x += Math.RandomFloat( -0.02, 0.02 );
			vecDir.y += Math.RandomFloat( -0.02, 0.02 );
			vecDir.z += Math.RandomFloat( -0.02, 0.0 );

			NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_SPRITE_SPRAY );
				m1.WriteCoord( vecOrigin.x );
				m1.WriteCoord( vecOrigin.y );
				m1.WriteCoord( vecOrigin.z );
				m1.WriteCoord( vecDir.x );
				m1.WriteCoord( vecDir.y );
				m1.WriteCoord( vecDir.z );
				m1.WriteShort( m_iSpikeSpray );
				m1.WriteByte( 10 );		// count
				m1.WriteByte( 150 );	// speed
				m1.WriteByte( 25 );		// noise (client will divide by 100)
			m1.End();

			CBaseEntity@ pSpike = g_EntityFuncs.Create( "pitdronespike", vecOrigin, vecAngle, false, m_pPlayer.edict() );

			pSpike.pev.velocity = vecDir * RANGE_SPEED;
			pSpike.pev.angles = Math.VecToAngles( pSpike.pev.velocity );

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );

			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) == 0 ) 
				m_pDriveEnt.SetBodygroup( 1, 0 );
			else 
				m_pDriveEnt.SetBodygroup( 1, m_pDriveEnt.GetBodygroup(1) + 1 );

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pAttackSoundsSpike[Math.RandomLong(0,(pAttackSoundsSpike.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
		}
	}

	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
		{
			SetThink( null );
			return;
		}

		if( m_iRandomAttack == 0 ) //both arms
		{
			CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE1, (DMG_CLUB|DMG_ALWAYSGIB) );

			if( pHurt !is null )
			{
				int rel = m_pPlayer.IRelationship(pHurt);
				bool isFriendly = rel == R_AL or rel == R_NO;

				if( pHurt.pev.flags & (FL_MONSTER | FL_CLIENT) != 0 and !isFriendly)
				{
					pHurt.pev.punchangle.z = Math.RandomFloat(-25.0, 25.0);
					pHurt.pev.punchangle.x = -30.0;
					g_PlayerFuncs.ScreenShake( pHurt.pev.origin, 8.0, 1.5, 0.7, 2 );

					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pAttackHitStrikeSounds[Math.RandomLong(0,(pAttackHitStrikeSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
				}
			}
			else
			{
				if( Math.RandomLong(0, 1) == 1 )
					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackSoundsSpike[Math.RandomLong(0,(pAttackSoundsSpike.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );

				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackMissSounds[Math.RandomLong(0,(pAttackMissSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
			}
		}
		else if( m_iRandomAttack == 1 ) //right slash
		{
			int iDmgFlags = DMG_SLASH;
			if( Math.RandomLong(0, 10) > 5 ) iDmgFlags |= DMG_ALWAYSGIB; //thanks H² :ayaya:

			CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE2, iDmgFlags );

			if( pHurt !is null )
			{
				int rel = m_pPlayer.IRelationship(pHurt);
				bool isFriendly = rel == R_AL or rel == R_NO;

				if( pHurt.pev.flags & (FL_MONSTER | FL_CLIENT) != 0 and !isFriendly )
				{
					pHurt.pev.punchangle.z = -20;
					pHurt.pev.punchangle.x = 20;
					pHurt.pev.velocity = pHurt.pev.velocity + ( m_pPlayer.pev.origin - pHurt.pev.origin ).Normalize() * 120; //pulls the target closer
				}
			} 
			else
				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackMissSounds[Math.RandomLong(0,(pAttackMissSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );

			m_iRandomAttack = 2;
			pev.nextthink = g_Engine.time + 0.6;
			return;
		}
		else if( m_iRandomAttack == 2 ) //left slash
		{
			int iDmgFlags = DMG_SLASH;
			if( Math.RandomLong(0, 10) > 5 ) iDmgFlags |= DMG_ALWAYSGIB; //thanks H² :ayaya:

			CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE2, iDmgFlags );

			if( pHurt !is null )
			{
				int rel = m_pPlayer.IRelationship(pHurt);
				bool isFriendly = rel == R_AL or rel == R_NO;

				if( pHurt.pev.flags & (FL_MONSTER | FL_CLIENT) != 0 and !isFriendly )
				{
					pHurt.pev.punchangle.z = 20;
					pHurt.pev.punchangle.x = -20;
					pHurt.pev.velocity = pHurt.pev.velocity + ( m_pPlayer.pev.origin - pHurt.pev.origin ).Normalize() * 120; //pulls the target closer
				}
			}
			else
			{
				if( Math.RandomLong(0, 1) == 1 )
					g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackSoundsSpike[Math.RandomLong(0,(pAttackSoundsSpike.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );

				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackMissSounds[Math.RandomLong(0,(pAttackMissSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, Math.RandomLong(95, 105) );
			}
		}

		SetThink( null );
	}

	void DoReload()
	{
		if( m_iState == STATE_IDLE and (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < 6 )
		{
			m_iState = STATE_RELOAD;

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_RELOAD]);
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			SetThink( ThinkFunction(this.ReloadThink) );
			pev.nextthink = g_Engine.time + RELOAD_TIME;

			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + (RELOAD_TIME + 0.1);
			self.m_flTimeWeaponIdle = g_Engine.time + (RELOAD_TIME + 0.1);
		}
	}

	void ReloadThink()
	{
		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.SetBodygroup( 1, 1 );
			m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, 6);
			DoIdleAnimation();
		}

		SetThink( null );
	}

	void DoJump()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( m_flDuckPressed > 0.0 and m_flDuckPressed < g_Engine.time )
			m_flDuckPressed = 0.0;

		if( !IsBetween2(m_iState, STATE_ATTACK_RANGE, STATE_RELOAD) and (m_pPlayer.pev.button & IN_JUMP) == 0 and (m_pPlayer.pev.oldbuttons & IN_JUMP) != 0 )
		{
			m_iState = STATE_JUMP;

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_JUMP]);
			m_pDriveEnt.pev.frame = SetFrame(10, 43);
			m_pDriveEnt.ResetSequenceInfo();
			Math.MakeVectors( m_pPlayer.pev.angles );

			g_EntityFuncs.SetOrigin( m_pPlayer, m_pPlayer.pev.origin + Vector(0, 0, 1) );// take him off ground so engine doesn't instantly reset onground 

			if( m_flDuckPressed > 0.0 and m_pPlayer.pev.velocity.Length() > 0.0 )
				m_pPlayer.pev.velocity = m_pPlayer.pev.velocity + Vector( g_Engine.v_forward.x, g_Engine.v_forward.y, g_Engine.v_up.z ) * JUMP_VELOCITY;
			else
			{
				float flGravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
				m_pPlayer.pev.velocity.z += (0.625 * flGravity) * 0.5;
			}
		}
	}

	void DoMovementAnimation()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		float flMinWalkVelocity = -150.0;
		float flMaxWalkVelocity = 150.0;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != m_pDriveEnt.LookupSequence(arrsAnims[ANIM_WALK]) )
			{
				m_iState = STATE_WALK;
				//m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
				m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_WALK]);
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != m_pDriveEnt.LookupSequence(arrsAnims[ANIM_RUN]) )
			{
				m_iState = STATE_RUN;
				//m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) );
				m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_RUN]);
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null or m_iState == STATE_JUMP ) return;

		if( m_iState != STATE_IDLE )
		{
			m_pPlayer.SetMaxSpeedOverride( -1 ); //int(SPEED_RUN)
			m_iState = STATE_IDLE;
			m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence(arrsAnims[ANIM_IDLE]);
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();
		}
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_pitdrone", m_pPlayer.pev.origin, m_pPlayer.pev.angles, true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.view_ofs = Vector( 0.0, 0.0, CNPC_VIEWOFS );
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;

		self.m_bExclusiveHold = true;

		m_pPlayer.SetViewMode( ViewMode_ThirdPerson );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_PITDRONE );
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

class cnpc_pitdrone : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	private float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/pit_drone.mdl" );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = self.LookupSequence(arrsAnims[ANIM_IDLE]);
		pev.frame = 0;
		self.ResetSequenceInfo();
		self.SetBodygroup( 1, 1 );

		m_flNextOriginUpdate = g_Engine.time;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
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

		if( pev.velocity.Length2D() > 0.0 )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		pev.scale = m_pOwner.pev.scale;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		pev.sequence = self.LookupSequence( arrsAnims[Math.RandomLong(ANIM_DEATH1, ANIM_DEATH3)] );
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

final class info_cnpc_pitdrone : CNPCSpawnEntity
{
	info_cnpc_pitdrone()
	{
		sWeaponName = CNPC_WEAPONNAME;
		sModel = CNPC_MODEL;
		iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		vecSizeMin = CNPC_SIZEMIN;
		vecSizeMax = CNPC_SIZEMAX;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_pitdrone::info_cnpc_pitdrone", "info_cnpc_pitdrone" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_pitdrone::cnpc_pitdrone", "cnpc_pitdrone" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_pitdrone::weapon_pitdrone", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "spikes" );

	g_Game.PrecacheOther( "cnpc_pitdrone" );
	g_Game.PrecacheOther( "info_cnpc_pitdrone" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_pitdrone END

/* FIXME
*/

/* TODO
	Change player's maxspeed ??
	Limit the range at which targets will get pulled closer with the slash attack ??
*/