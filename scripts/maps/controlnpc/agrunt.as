namespace cnpc_agrunt
{
	
const string sWeaponName	= "weapon_agrunt";
const float CNPC_HEALTH		= 150.0;

const bool DISABLE_CROUCH	= true;
const float CNPC_VIEWOFS		= 40.0; //camera height offset

const float CD_HORNET			= 2.0;
const float CD_MELEE				= 1.0;

const float MELEE_DAMAGE		= 20.0;
const float MELEE_RANGE		= 100.0;

const float HORNET_REFIRE		= 0.2;

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

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_DEATH,
	STATE_ATTACK_MELEE,
	STATE_ATTACK_HORNET
};

class weapon_agrunt : CBaseDriveWeapon
{
	private int m_iAgruntMuzzleFlash;
	private int m_iRandomAttack;
	private float m_flStopHornetAttack;

	void Spawn()
	{
		Precache();

		self.m_iDefaultAmmo = 100;

		m_iState = STATE_IDLE;
		m_iRandomAttack = 0;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/agrunt.mdl" );
		m_iAgruntMuzzleFlash = g_Game.PrecacheModel( "sprites/muz4.spr" );

		for( uint i = 0; i < pAttackHitSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackHitSounds[i] );

		for( uint i = 0; i < pAttackMissSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pAttackMissSounds[i] );

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
		info.iMaxAmmo1	= 100;
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
		if( m_pPlayer.pev.velocity.Length() > 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.3;
			return;
		}

		if( m_pDriveEnt !is null )
		{
			if( m_iState != STATE_WALK and m_iState != STATE_RUN and m_iState != STATE_ATTACK_MELEE and m_iState != STATE_DEATH )
			{
				m_iState = STATE_ATTACK_HORNET;
				m_pPlayer.SetMaxSpeedOverride( 0 );

				m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence("longshoot");
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
		if( m_pPlayer.pev.velocity.Length() > 10.0 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.3;
			return;
		}

		if( m_pDriveEnt !is null and m_iState != STATE_WALK and m_iState != STATE_RUN and m_iState != STATE_ATTACK_HORNET and m_iState != STATE_DEATH )
		{
			m_iState = STATE_ATTACK_MELEE;
			m_pPlayer.SetMaxSpeedOverride( 0 );

			m_iRandomAttack = Math.RandomLong(2, 3);

			switch( m_iRandomAttack )
			{
				case 2:	m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence("mattack2"); pev.nextthink = g_Engine.time + 0.5; break;
				case 3:	m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence("mattack3"); pev.nextthink = g_Engine.time + 0.4; break;
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

			if( m_pPlayer.pev.button & (IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 )
				m_pPlayer.SetMaxSpeedOverride( 0 );
			else if( m_pPlayer.pev.button & IN_FORWARD != 0 )
			{
				if( m_iState != STATE_ATTACK_MELEE and m_iState != STATE_ATTACK_HORNET )
				{
					m_pPlayer.SetMaxSpeedOverride( -1 );
					DoMovementAnimation();
					self.m_flTimeWeaponIdle = g_Engine.time + 0.1;
				}
			}

			if( m_pPlayer.pev.velocity.Length() <= 10.0 and m_iState != STATE_ATTACK_MELEE and m_iState != STATE_ATTACK_HORNET )
				DoIdleAnimation();

			if( m_iState == STATE_ATTACK_HORNET )
			{
				Vector angDir = m_pPlayer.pev.v_angle;

				if( angDir.x > 180 )
					angDir.x = angDir.x - 360;

				m_pDriveEnt.SetBlending( 0, -angDir.x );
			}
		}
	}

	void HornetAttackThink()
	{
		if( m_pPlayer is null or m_pDriveEnt is null or m_iState != STATE_ATTACK_HORNET or m_flStopHornetAttack < g_Engine.time )
		{
			SetThink( null );
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
			if( m_pDriveEnt.pev.sequence != m_pDriveEnt.LookupSequence("walk") )
			{
				m_iState = STATE_WALK;
				m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence("walk");
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
			if( m_pDriveEnt.pev.sequence != m_pDriveEnt.LookupSequence("run") )
			{
				m_iState = STATE_RUN;
				m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence("run");
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

		if( m_iState != STATE_IDLE )
		{
			m_pPlayer.SetMaxSpeedOverride( -1 );
			m_iState = STATE_IDLE;
			m_pDriveEnt.pev.sequence = m_pDriveEnt.LookupSequence("idle1");
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
}

class cnpc_agrunt : ScriptBaseAnimating//ScriptBaseMonsterEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/agrunt.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 72) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NOCLIP;

		pev.sequence = self.LookupSequence("idle1");
		pev.frame = 0;
		self.ResetSequenceInfo();

		//pev.takedamage = DAMAGE_AIM;
		//self.m_bloodColor = BLOOD_COLOR_YELLOW;
		//self.m_MonsterState		= MONSTERSTATE_NONE;
		//self.m_afCapability			= 0;
		//self.MonsterInit();

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
			//m_iState = STATE_DEATH;

			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		//if( pOwner.IsOnLadder() or  pOwner.pev.waterlevel > WATERLEVEL_FEET )
		{
			Vector vecOrigin = pOwner.pev.origin;
			vecOrigin.z -= 32.0;
			g_EntityFuncs.SetOrigin( self, vecOrigin );
		}

		pev.velocity = pOwner.pev.velocity;

		pev.angles.x = 0;
		pev.angles.y = pOwner.pev.angles.y;
		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		array<string> arrsDeathAnims = 
		{
			"dieforward",
			"diebackward",
			"diegut",
			"diesimple",
			"diehead"
		};

		pev.sequence = self.LookupSequence( arrsDeathAnims[Math.RandomLong(0, arrsDeathAnims.length()-1)] );
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_agrunt::cnpc_agrunt", "cnpc_agrunt" );
	g_Game.PrecacheOther( "cnpc_agrunt" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_agrunt::weapon_agrunt", sWeaponName );
	g_ItemRegistry.RegisterWeapon( sWeaponName, "controlnpc", "hornets" );
	g_Game.PrecacheOther( sWeaponName );
}

} //namespace cnpc_agrunt END

/* FIXME
Holding any button after attacking will cause the animation to freeze at the last frame until released
*/

/* TODO
Use turning animations 
*/