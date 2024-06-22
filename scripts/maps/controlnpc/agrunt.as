namespace cnpc_agrunt
{

const bool CNPC_HARDLANDING		= true; //when falling from a great height the grunt will be stunned for a second or so
	
const string CNPC_WEAPONNAME	= "weapon_agrunt";
const string CNPC_MODEL				= "models/agrunt.mdl";
const Vector CNPC_SIZEMIN			= Vector( -16, -16, 0 );
const Vector CNPC_SIZEMAX			= Vector( 16, 16, 72 );

const float CNPC_HEALTH				= 150.0;
const bool DISABLE_CROUCH			= true;
const float CNPC_VIEWOFS				= 40.0; //camera height offset
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the shocktrooper itself
const float CNPC_IDLESOUND			= 10.0; //how often to check for an idlesound

const float CD_HORNET					= 2.0;
const float CD_MELEE						= 1.0;

const float MELEE_DAMAGE				= 20.0;
const float MELEE_RANGE				= 100.0;

const float HORNET_REFIRE				= 0.2;
const float CNPC_FIRE_MINRANGE	= 48.0; //decides how close you can be to a wall before shooting gets blocked

const float CD_GRENADE					= 2.0;
const float GRENADE_VELOCITY		= 750.0;
const float AMMO_REGEN_RATE		= 0.1; //+1 per AMMO_REGEN_RATE seconds
const int GRENADE_AMMO				= 100; //amount required to toss a snark nest

const array<string> pAttackHitSounds = 
{
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav"
};

const array<string> pAttackMissSounds = 
{
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav"
};

const array<string> pIdleSounds = 
{
	"agrunt/ag_idle1.wav",
	"agrunt/ag_idle2.wav",
	"agrunt/ag_idle3.wav",
	"agrunt/ag_idle4.wav"
};

const array<string> pPainSounds = 
{
	"agrunt/ag_pain1.wav",
	"agrunt/ag_pain2.wav",
	"agrunt/ag_pain3.wav",
	"agrunt/ag_pain4.wav",
	"agrunt/ag_pain5.wav"
};

const array<string> pDieSounds = 
{
	"agrunt/ag_die1.wav",
	"agrunt/ag_die4.wav",
	"agrunt/ag_die5.wav"
};

const array<string> pStepSounds = 
{
	"player/pl_ladder1.wav",
	"player/pl_ladder2.wav",
	"player/pl_ladder3.wav",
	"player/pl_ladder4.wav"
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK = 2,
	ANIM_RUN,
	ANIM_MELEE_R = 8,
	ANIM_MELEE_L,
	ANIM_SHOOT = 19,
	ANIM_QUICKSHOOT,
	ANIM_LONGSHOOT,
	ANIM_DEATH1,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_DEATH5,
	ANIM_FLOAT,
	ANIM_LAND = 31,
	ANIM_THROW
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_ATTACK_MELEE,
	STATE_ATTACK_HORNET,
	STATE_GRENADE,
	STATE_LANDHARD
};

class weapon_agrunt : CBaseDriveWeapon
{
	private int m_iLastWord;

	private int m_iAgruntMuzzleFlash;
	private float m_flStopHornetAttack;
	private bool m_bShotBlocked;

	private int m_iRandomAttack;

	private bool m_bHasThrownGrenade;
	private float m_flNextGrenade;
	private float m_flNextAmmoRegen;

	private bool m_bIsFallingHard;

	void Spawn()
	{
		Precache();

		self.m_iDefaultAmmo = GRENADE_AMMO;

		m_iState = STATE_IDLE;
		m_iRandomAttack = 0;
		m_bShotBlocked = false;
		m_iLastWord = 0;
		m_flNextIdleSound = g_Engine.time + CNPC_IDLESOUND;
		m_flNextGrenade = 0.0;
		m_bHasThrownGrenade = false;
		m_bIsFallingHard = false;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		m_iAgruntMuzzleFlash = g_Game.PrecacheModel( "sprites/muz4.spr" );

		for( uint i = 0; i < pAttackHitSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackHitSounds[i] );

		for( uint i = 0; i < pAttackMissSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackMissSounds[i] );

		for( uint i = 0; i < pIdleSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pIdleSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		for( uint i = 0; i < pStepSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pStepSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_agrunt.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_aliengrunt.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_aliengrunt_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= GRENADE_AMMO;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::AGRUNT_SLOT - 1;
		info.iPosition		= CNPC::AGRUNT_POSITION - 1;
		info.iFlags 			= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY; //to prevent monster from being despawned if out of ammo TODO
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

		m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType, GRENADE_AMMO);

		if( m_iAutoDeploy == 1 ) m_pPlayer.SwitchWeapon(self);

		return true;
	}

	bool Deploy()
	{
		if( m_iAutoDeploy == 1 )
		{
			spawn_driveent();
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
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			if( m_iState != STATE_ATTACK_MELEE and m_iState != STATE_GRENADE and m_iState != STATE_LANDHARD )
			{
				if( CheckIfShotIsBlocked(CNPC_FIRE_MINRANGE) )
				{
					m_bShotBlocked = true;
					self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
					return;
				}

				m_iState = STATE_ATTACK_HORNET;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				m_pDriveEnt.pev.sequence = ANIM_LONGSHOOT;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				SetThink( ThinkFunction(this.HornetAttackThink) );
				pev.nextthink = g_Engine.time + 0.3;
				m_flStopHornetAttack = g_Engine.time + 1.5;
			}
		}
		else
		{
			spawn_driveent();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_HORNET;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_HORNET;
	}

	void SecondaryAttack()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( m_iState != STATE_ATTACK_HORNET and m_iState != STATE_GRENADE and m_iState != STATE_LANDHARD )
		{
			m_iState = STATE_ATTACK_MELEE;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iRandomAttack = Math.RandomLong(2, 3);

			switch( m_iRandomAttack )
			{
				case 2:	m_pDriveEnt.pev.sequence = ANIM_MELEE_R; pev.nextthink = g_Engine.time + 0.5; break;
				case 3:	m_pDriveEnt.pev.sequence = ANIM_MELEE_L; pev.nextthink = g_Engine.time + 0.4; break;
			}

			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			SetThink( ThinkFunction(this.MeleeAttackThink) );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_MELEE;
		self.m_flTimeWeaponIdle = g_Engine.time + CD_MELEE;
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

			if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and m_iState < STATE_ATTACK_MELEE )
			{
				m_pPlayer.SetMaxSpeedOverride( -1 );
				DoMovementAnimation();
			}

			DoIdleAnimation();
			DoIdleSound();
			CheckGrenadeInput();
			ThrowGrenade();
			DoAmmoRegen();
			DoFalling();
			DoGunAiming();
		}
	}

	void HornetAttackThink()
	{
		if( m_pPlayer is null or m_pDriveEnt is null or m_iState != STATE_ATTACK_HORNET or m_flStopHornetAttack < g_Engine.time or m_bShotBlocked )
		{
			SetThink( null );
			return;
		}

		if( CheckIfShotIsBlocked(CNPC_FIRE_MINRANGE) )
		{
			SetThink( null );
			m_bShotBlocked = true;
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			DoIdleAnimation();
			return;
		}

		ShootHornet();
		pev.nextthink = g_Engine.time + HORNET_REFIRE;
	}

	void ShootHornet()
	{
		if( m_pDriveEnt !is null and m_pPlayer.IsAlive() )
		{
			Vector vecAngle, vecOrigin, vecMuzzle;
			vecAngle = m_pPlayer.pev.v_angle;

			if( vecAngle.x < -44.5 ) vecAngle.x = -44.5;
			if( vecAngle.x > 32.0 ) vecAngle.x = 32.0;

			Math.MakeVectors( vecAngle );
			m_pDriveEnt.GetAttachment( 0, vecOrigin, void );

			m_pDriveEnt.pev.effects = EF_MUZZLEFLASH;

			vecMuzzle = vecOrigin + g_Engine.v_forward * 32;

			NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecMuzzle );
				m1.WriteByte( TE_SPRITE );
				m1.WriteCoord( vecMuzzle.x );
				m1.WriteCoord( vecMuzzle.y );
				m1.WriteCoord( vecMuzzle.z );
				m1.WriteShort( m_iAgruntMuzzleFlash );
				m1.WriteByte( 6 ); // size * 10
				m1.WriteByte( 128 ); // brightness
			m1.End();

			CBaseEntity@ pHornet = g_EntityFuncs.Create( "hornet", vecOrigin, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
			pHornet.pev.velocity = g_Engine.v_forward * 300;

			switch( Math.RandomLong(0, 2) )
			{
				case 0: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, "agrunt/ag_fire1.wav", VOL_NORM, ATTN_NORM ); break;
				case 1: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, "agrunt/ag_fire2.wav", VOL_NORM, ATTN_NORM ); break;
				case 2: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, "agrunt/ag_fire3.wav", VOL_NORM, ATTN_NORM ); break;
			}
		}
	}

	void MeleeAttackThink()
	{
		if( m_pPlayer is null or !m_pPlayer.IsAlive() or m_pDriveEnt is null )
		{
			SetThink( null );
			return;
		}

		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, MELEE_DAMAGE, DMG_CLUB );
		
		if( pHurt !is null )
		{
			pHurt.pev.punchangle.y = (m_iRandomAttack == 3) ? -25.0 : 25.0;
			pHurt.pev.punchangle.x = 8.0;

			if( (pHurt.pev.flags & (FL_CLIENT)) == 1 )
				pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * ((m_iRandomAttack == 3) ? 250.0 : -250.0);

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackHitSounds[Math.RandomLong(0,(pAttackHitSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

			Vector vecArmPos, vecArmAng;
			m_pDriveEnt.GetAttachment( 0, vecArmPos, vecArmAng );
			g_WeaponFuncs.SpawnBlood( vecArmPos, pHurt.BloodColor(), 25 );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, pAttackMissSounds[Math.RandomLong(0,(pAttackMissSounds.length() - 1))], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

		SetThink( null );
	}

	void DoMovementAnimation()
	{
		float flMinWalkVelocity = -150.0;
		float flMaxWalkVelocity = 150.0;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				m_iState = STATE_WALK;
				m_pDriveEnt.pev.sequence = ANIM_WALK;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
			else
			{
				if( GetFrame(20) == 9 )
				{
					switch( Math.RandomLong(0, 1) )
					{
						case 0:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[1], VOL_NORM, ATTN_NORM, 0, 70 ); break;
						case 1:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[3], VOL_NORM, ATTN_NORM, 0, 70 ); break;
					}
				}
				else if( GetFrame(20) == 19 )
				{
					switch( Math.RandomLong(0, 1) )
					{
						case 0:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[0], VOL_NORM, ATTN_NORM, 0, 70 ); break;
						case 1:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[2], VOL_NORM, ATTN_NORM, 0, 70 ); break;
					}
				}
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
			else
			{
				if( GetFrame(26) == 11 )
				{
					switch( Math.RandomLong(0, 1) )
					{
						case 0:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[1], VOL_NORM, ATTN_NORM, 0, 70 ); break;
						case 1:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[3], VOL_NORM, ATTN_NORM, 0, 70 ); break;
					}
				}
				else if( GetFrame(26) == 23 )
				{
					switch( Math.RandomLong(0, 1) )
					{
						case 0:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[0], VOL_NORM, ATTN_NORM, 0, 70 ); break;
						case 1:	g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_BODY, pStepSounds[2], VOL_NORM, ATTN_NORM, 0, 70 ); break;
					}
				}

				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
			}
		}
	}

	void DoIdleAnimation()
	{
		if( m_pDriveEnt is null ) return;
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState == STATE_ATTACK_MELEE and (m_pDriveEnt.pev.sequence == ANIM_MELEE_L or m_pDriveEnt.pev.sequence == ANIM_MELEE_R) and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_ATTACK_HORNET and m_pDriveEnt.pev.sequence == ANIM_LONGSHOOT and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_GRENADE and m_pDriveEnt.pev.sequence == ANIM_THROW and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_LANDHARD and m_pDriveEnt.pev.sequence == ANIM_LAND and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( -1 );
				m_iState = STATE_IDLE;
				m_pDriveEnt.pev.sequence = ANIM_IDLE;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
				m_bShotBlocked = false;
			}
		}
	}

	void IdleSound()
	{
		if( m_pDriveEnt is null ) return;

		int num = -1;

		do
		{
			num = Math.RandomLong( 0,3 );
		} while( num == m_iLastWord );

		m_iLastWord = num;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pIdleSounds[num], VOL_NORM, ATTN_NORM );

		if( Math.RandomLong(1, 10) <= 1 )
			m_flNextIdleSound = g_Engine.time + ( 10 + Math.RandomFloat(0.0, 10.0) );
		else
			m_flNextIdleSound = g_Engine.time + Math.RandomFloat( 0.5, 1.0 );
	}

	void CheckGrenadeInput()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState == STATE_ATTACK_HORNET or m_iState == STATE_ATTACK_MELEE or m_iState == STATE_LANDHARD ) return;
		if( m_flNextGrenade > g_Engine.time ) return;
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < GRENADE_AMMO ) return;
		if( CheckIfShotIsBlocked(CNPC_FIRE_MINRANGE*1.8) ) return;

		if( (m_pPlayer.pev.button & IN_RELOAD) == 0 and (m_pPlayer.pev.oldbuttons & IN_RELOAD) != 0 )
		{
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iState = STATE_GRENADE;
			m_pDriveEnt.pev.sequence = ANIM_THROW;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			m_flNextGrenade = g_Engine.time + CD_GRENADE;
		}
	}

	void ThrowGrenade()
	{
		if( m_iState != STATE_GRENADE or m_pDriveEnt.pev.sequence != ANIM_THROW ) return;

		if( GetFrame(16) == 7 and !m_bHasThrownGrenade )
		{
			Vector vecAngle = m_pPlayer.pev.v_angle;

			//prevent nests from spawning in the floor
			if( vecAngle.x > 15.0 )
				vecAngle.x = 15.0;
			else if( vecAngle.x <= -60.0 )
				vecAngle.x = -60.0;

			Math.MakeVectors( vecAngle );
			Vector vecGrenadeOrigin = m_pDriveEnt.pev.origin + Vector(0, 0, 32);
			vecGrenadeOrigin = vecGrenadeOrigin + g_Engine.v_forward * 72.0;
			Vector vecGrenadeVelocity = m_pPlayer.pev.velocity + g_Engine.v_forward * GRENADE_VELOCITY;

			CBaseEntity@ pSnarkNest = g_EntityFuncs.Create( "monster_sqknest", vecGrenadeOrigin, g_vecZero, true );
			pSnarkNest.pev.velocity = vecGrenadeVelocity;
			g_EntityFuncs.DispatchKeyValue( pSnarkNest.edict(), "is_player_ally", "1" );
			g_EntityFuncs.DispatchSpawn( pSnarkNest.edict() );
			pSnarkNest.pev.nextthink = g_Engine.time + 4.0; //prevents DropToFloor from teleporting the nest when spawned

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - GRENADE_AMMO );
			m_bHasThrownGrenade = true;
		}
		else if( GetFrame(56) > 45 and m_bHasThrownGrenade )
			m_bHasThrownGrenade = false;
	}

	void DoAmmoRegen()
	{
		if( m_iState != STATE_GRENADE and m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < GRENADE_AMMO )
		{
			if( m_flNextAmmoRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) +1 );

				m_flNextAmmoRegen = g_Engine.time + AMMO_REGEN_RATE;
			}
		}
	}

	void DoFalling()
	{
		if( m_iState > STATE_ATTACK_MELEE ) return;

		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_pPlayer.m_flFallVelocity != 0 )
		{
			if( m_pPlayer.m_flFallVelocity >= 580.0 ) m_bIsFallingHard = true;

			if( m_pDriveEnt.pev.sequence != ANIM_FLOAT )
			{
				m_pDriveEnt.pev.sequence = ANIM_FLOAT;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}

		if( CNPC_HARDLANDING )
		{
			if( m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_bIsFallingHard )
			{
				if( m_pDriveEnt.pev.sequence != ANIM_LAND )
				{
					m_iState = STATE_LANDHARD;
					m_pDriveEnt.pev.sequence = ANIM_LAND;
					m_pDriveEnt.pev.frame = 0;
					m_pDriveEnt.ResetSequenceInfo();
					m_pPlayer.SetMaxSpeedOverride( 0 );
					m_bIsFallingHard = false;
				}
			}
		}
	}

	void DoGunAiming()
	{
		if( m_iState == STATE_ATTACK_HORNET )
		{
			Vector angDir = m_pPlayer.pev.v_angle;

			if( angDir.x > 180 )
				angDir.x = angDir.x - 360;

			m_pDriveEnt.SetBlending( 0, -angDir.x );
		}
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_agrunt", m_pPlayer.pev.origin, m_pPlayer.pev.angles, true, m_pPlayer.edict()) );

		m_pDriveEnt.pev.set_controller( 0,  127 );

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_AGRUNT );
	}

	void ResetPlayer()
	{
		m_pPlayer.pev.fuser4 = 0; //enable jump
		m_pPlayer.pev.max_health = 100;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_RED;

		m_pPlayer.SetViewMode( ViewMode_FirstPerson );
		m_pPlayer.SetMaxSpeedOverride( -1 );

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}

	bool CheckIfShotIsBlocked( float flMinRange )
	{
		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		g_Utility.TraceHull( m_pPlayer.pev.origin, m_pPlayer.pev.origin + g_Engine.v_forward * flMinRange, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

		if( tr.flFraction != 1.0 ) return true;

		return false;
	}
}

class cnpc_agrunt : ScriptBaseAnimating
{
	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

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

		Vector vecOrigin = m_pOwner.pev.origin;
		vecOrigin.z -= 32.0;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.velocity = m_pOwner.pev.velocity;

		pev.angles.x = 0;

		if( pev.velocity.Length2D() > 0.0 )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else
			pev.angles.y = m_pOwner.pev.angles.y;

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH5 );
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

final class info_cnpc_agrunt : CNPCSpawnEntity
{
	info_cnpc_agrunt()
	{
		sWeaponName = CNPC_WEAPONNAME;
		sModel = CNPC_MODEL;
		iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		vecSizeMin = CNPC_SIZEMIN;
		vecSizeMax = CNPC_SIZEMAX;
	}

	void DoSpecificStuff()
	{
		pev.set_controller( 0,  127 );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_agrunt::info_cnpc_agrunt", "info_cnpc_agrunt" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_agrunt::cnpc_agrunt", "cnpc_agrunt" );
	g_Game.PrecacheOther( "cnpc_agrunt" );

	g_Game.PrecacheMonster( "monster_sqknest", true );
	g_Game.PrecacheMonster( "monster_sqknest", false );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_agrunt::weapon_agrunt", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "hornets" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_agrunt END

/* FIXME
*/

/* TODO
Use turning animations 
*/
