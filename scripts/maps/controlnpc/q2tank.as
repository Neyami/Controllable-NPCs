namespace cnpc_q2tank
{

bool CNPC_FIRSTPERSON				= false;
const bool CNPC_REFIRE				= true; //Gives some attacks a chance to fire more projectiles if you keep holding the button

const string CNPC_WEAPONNAME	= "weapon_q2tank";
const string CNPC_MODEL				= "models/quake2/monsters/tank/tank.mdl";
const string MODEL_GIB_GEAR		= "models/quake2/objects/gibs/gear.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_METAL		= "models/quake2/objects/gibs/sm_metal.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/tank/gibs/barm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/tank/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/tank/gibs/foot.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/tank/gibs/head.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/tank/gibs/thigh.mdl";

const Vector CNPC_SIZEMIN			= Vector( -32, -32, 0 );
const Vector CNPC_SIZEMAX			= Vector( 32, 32, 128 );

const float CNPC_HEALTH				= 750.0;
const float CNPC_VIEWOFS_FPV		= 72.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 64.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the tank itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 0.5;

const float SPEED_WALK					= (55.71381 * CNPC::flModelToGameSpeedModifier);

const float CD_BLASTER					= 2.0;
const float CD_MACHINEGUN			= 2.0;
const float CD_ROCKET					= 2.0;

const float MGUN_DMG					= 20;
const float BLASTER_DMG				= 30;
const float BLASTER_SPEED			= 800;
const float ROCKET_DMG				= 50;
const float ROCKET_SPEED				= 550;

const array<string> pPainSounds = 
{
	"quake2/npcs/tank/tnkpain2.wav"
};

const array<string> pDieSounds = 
{
	"quake2/npcs/tank/death.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/tank/sight1.wav",
	"quake2/npcs/tank/tnkidle1.wav",
	"quake2/npcs/tank/step.wav",
	"quake2/npcs/tank/tnkdeth2.wav",
	"quake2/npcs/tank/tnkatck4.wav", //strike windup
	"quake2/npcs/tank/tnkatck5.wav", //strike hit
	"quake2/npcs/tank/tnkatck3.wav", //blaster
	"quake2/npcs/tank/tnkatck1.wav", //rocket launcher
	"quake2/npcs/tank/tnkatk2a.wav", //machine gun
	"quake2/npcs/tank/tnkatk2b.wav",
	"quake2/npcs/tank/tnkatk2c.wav",
	"quake2/npcs/tank/tnkatk2d.wav",
	"quake2/npcs/tank/tnkatk2e.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_SIGHT,
	SND_IDLE,
	SND_STEP,
	SND_THUD,
	SND_STRIKE1,
	SND_STRIKE2,
	SND_BLASTER,
	SND_ROCKET,
	SND_MACHINEGUN
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK,
	ANIM_BLASTER = 3,
	ANIM_STRIKE = 7,
	ANIM_ROCKET,
	ANIM_MACHINEGUN = 12,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3,
	ANIM_DEATH,
	ANIM_RECLINE
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_MOVING,
	STATE_ATTACK,
	STATE_PAIN
};

enum attach_e
{
	ATTACH_MG_MUZZLE = 0,
	ATTACH_MG_BASE,
	ATTACH_BLASTER,
	ATTACH_ROCKET_MIDDLE
};

final class weapon_q2tank : CBaseDriveWeaponQ2
{
	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_GEAR );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );

		//machine gun
		g_Game.PrecacheModel( "sprites/steam1.spr" );

		//blaster
		g_Game.PrecacheModel( "models/quake2/laser.mdl" );
		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		//rocket launcher
		g_Game.PrecacheModel( "models/quake2/rocket.mdl" );
		g_Game.PrecacheModel( "sprites/WXplo1.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		g_SoundSystem.PrecacheSound( "debris/metal1.wav" ); //gibs
		g_SoundSystem.PrecacheSound( "debris/metal3.wav" ); //gibs

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2tank.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2tank.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2tank_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2TANK_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2TANK_POSITION - 1;
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
			if( GetState() > STATE_MOVING ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_BLASTER );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_BLASTER;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING ) return;			

			SetYaw( m_pPlayer.pev.v_angle.y );
			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_MACHINEGUN );
		}

		self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
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
			cnpc_q2tank@ pDriveEnt = cast<cnpc_q2tank@>(CastToScriptClass(m_pDriveEnt));
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
			DoSearchSound();
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			CheckRocketInput();
			CheckStrikeInput();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		SetSpeed( int(SPEED_WALK) );

		if( m_pDriveEnt.pev.sequence != ANIM_WALK )
		{
			SetState( STATE_MOVING );
			SetSpeed( int(SPEED_WALK) );
			SetAnim( ANIM_WALK );
		}
		else
			m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
	}

	void DoIdleAnimation()
	{
		if( GetState() >= STATE_ATTACK and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( !GetState(STATE_IDLE) )
			{
				SetSpeed( int(SPEED_WALK) );
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

	void AlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void IdleSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void SearchSound()
	{
	}

	void HandlePain( float flDamage )
	{
		m_pDriveEnt.pev.dmg = flDamage;

		if( m_pPlayer.pev.health < (CNPC_HEALTH * 0.5) )
			m_pDriveEnt.pev.skin = 1;

		if( flDamage <= 10 )
			return;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		if( flDamage <= 30 and Math.RandomFloat(0.0, 1.0) > 0.2 )
				return;

		if( GetAnim(ANIM_ROCKET) or GetAnim(ANIM_BLASTER) )
			return;

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, pPainSounds[Math.RandomLong(0,(pPainSounds.length() - 1))], VOL_NORM, ATTN_NORM );

		if( flDamage <= 30 )
			SetAnim( ANIM_PAIN1 );
		else if( flDamage <= 60 )
			SetAnim( ANIM_PAIN2 );
		else
			SetAnim( ANIM_PAIN3 );

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(16, 7) and m_uiAnimationState == 0 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(16, 15) and m_uiAnimationState == 1 ) { FootStep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MACHINEGUN:
			{
				if( m_uiAnimationState <= 18 )
				{
					if( GetFrame(29, 5 + m_uiAnimationState) )
					{
						MachineGun();
						m_uiAnimationState++;
					}
				}
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 19 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_BLASTER:
			{
				if( GetFrame(22, 9) and m_uiAnimationState == 0 ) { FireBlaster(); m_uiAnimationState++; }
				else if( GetFrame(22, 12) and m_uiAnimationState == 1 ) { FireBlaster(); m_uiAnimationState++; }
				else if( GetFrame(22, 15) and m_uiAnimationState == 2 ) { FireBlaster(); m_uiAnimationState++; }
				else if( GetFrame(22, 18) and m_uiAnimationState == 3 ) { BlasterRefire(); m_uiAnimationState++; }
				else if( GetFrame(22, 21) and m_uiAnimationState == 4 ) { FootStep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 5 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ROCKET:
			{
				if( GetFrame(53, 15) and m_uiAnimationState == 0 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(53, 23) and m_uiAnimationState == 1 ) { FireRocket(1); m_uiAnimationState++; }
				else if( GetFrame(53, 25) and m_uiAnimationState == 2 ) { FireRocket(2); m_uiAnimationState++; }
				else if( GetFrame(53, 29) and m_uiAnimationState == 3 ) { FireRocket(3); m_uiAnimationState++; }
				else if( GetFrame(53, 32) and m_uiAnimationState == 4 ) { RocketRefire(); m_uiAnimationState++; }
				else if( GetFrame(53, 45) and m_uiAnimationState == 5 ) { FootStep(); m_pDriveEnt.pev.framerate = 2.0; m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 6 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_STRIKE:
			{
				if( GetFrame(38, 0) and m_uiAnimationState == 0 ) { Strike(1); m_uiAnimationState++; }
				else if( GetFrame(38, 6) and m_uiAnimationState == 1 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(38, 10) and m_uiAnimationState == 2 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(38, 25) and m_uiAnimationState == 3 ) { Strike(2); m_uiAnimationState++; }
				else if( GetFrame(38, 37) and m_uiAnimationState == 4 ) { FootStep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 5 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN3:
			{
				if( GetFrame(16, 15) and m_uiAnimationState == 0 ) { FootStep(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void FootStep()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP], VOL_NORM, ATTN_NORM );
	}

	void MachineGun()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_MACHINEGUN + Math.RandomLong(0, 4)], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( ATTACH_MG_MUZZLE, vecOrigin, void );

		MachineGunEffects( vecOrigin );

		Vector vecGunBase, vecGunMuzzle;
		m_pDriveEnt.GetAttachment( ATTACH_MG_BASE, vecGunBase, void );
		m_pDriveEnt.GetAttachment( ATTACH_MG_MUZZLE, vecGunMuzzle, void );
		Vector vecAim = (vecGunMuzzle - vecGunBase).Normalize();

		self.FireBullets( 1, vecOrigin, vecAim, VECTOR_CONE_3DEGREES, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, MGUN_DMG, m_pPlayer.pev );
	}

	void FireBlaster()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_BLASTER], VOL_NORM, ATTN_NORM );

		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( ATTACH_BLASTER, vecOrigin, void );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > 50 )
			vecAim.x = 50;
		else if( vecAim.x < -50 )
			vecAim.x = -50;

		g_EngineFuncs.MakeVectors( vecAim );

		vecAim = g_Engine.v_forward;

		monster_fire_blaster( vecOrigin, vecAim, BLASTER_DMG, BLASTER_SPEED ); //EF_BLASTER
	}

	void BlasterRefire()
	{
		if( CNPC_REFIRE )
		{
			if( GetButton(IN_ATTACK) and Math.RandomFloat(0, 1) <= 0.6 )
			{
				m_uiAnimationState = 0; //shouldn't this be 1 ??
				m_pDriveEnt.pev.frame = SetFrame( 22, 10 );
			}
		}
	}

	void FireRocket( int iRocketNum )
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ROCKET], VOL_NORM, ATTN_NORM );
		Vector vecOrigin;
		m_pDriveEnt.GetAttachment( ATTACH_ROCKET_MIDDLE, vecOrigin, void );
		Math.MakeVectors( m_pDriveEnt.pev.angles );

		if( iRocketNum == 1 )
			vecOrigin = vecOrigin + g_Engine.v_right * 8.0;
		else if( iRocketNum == 3 )
			vecOrigin = vecOrigin - g_Engine.v_right * 8.0;

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > 50 )
			vecAim.x = 50;
		else if( vecAim.x < -50 )
			vecAim.x = -50;

		g_EngineFuncs.MakeVectors( vecAim );

		vecAim = g_Engine.v_forward;

		monster_fire_rocket( vecOrigin, vecAim, ROCKET_DMG, ROCKET_SPEED );
	}

	void RocketRefire()
	{
		if( CNPC_REFIRE )
		{
			if( GetButton(IN_RELOAD) and Math.RandomFloat(0, 1) <= 0.4 )
			{
				m_uiAnimationState = 0; //shouldn't this be 1 ??
				m_pDriveEnt.pev.frame = SetFrame( 53, 21 );
				return;
			}
		}

		m_pDriveEnt.pev.dmgtime = 0.0; //stop the tank from turning when firing is done
	}

	void CheckRocketInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ROCKET );
			m_pDriveEnt.pev.dmgtime = 69; //let the tank turn while firing
		}
	}

	void CheckStrikeInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_JUMP) != 0 )
		{
			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_STRIKE );
		}
	}

	void Strike( int iStage )
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_STRIKE1 + (iStage-1)], VOL_NORM, ATTN_NORM );

		if( iStage == 2 )
		{
			Math.MakeVectors( m_pDriveEnt.pev.angles );
			Vector vecOrigin = m_pDriveEnt.pev.origin + g_Engine.v_forward * 35 + g_Engine.v_right * -30;
			GibCorpse( vecOrigin );
		}
	}

	void GibCorpse( Vector vecOrigin )
	{
		CBaseEntity@ pEntity = null;
		while( (@pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, vecOrigin, 21, "*", "classname" ) ) !is null )
		{
			if( !pEntity.GetClassname().StartsWith("monster_") ) continue;
			if( pEntity.IsAlive() ) continue;

			CBaseMonster@ pMonster = pEntity.MyMonsterPointer();
			if( pMonster !is null )
				pMonster.GibMonster();
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2tank", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			int iYaw = 150;
			m_pDriveEnt.pev.set_controller( 0,  iYaw );
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
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
			m1.WriteString( "cam_idealdist 128\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2TANK );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2tank@ pDriveEnt = cast<cnpc_q2tank@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2tank_rend_" + m_pPlayer.entindex();
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

class cnpc_q2tank : CBaseDriveEntityQ2
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

		if( m_pOwner.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 and pev.velocity.Length2D() > 0.0 and pev.sequence == ANIM_WALK )
			pev.angles.y = Math.VecToAngles( pev.velocity ).y;
		else if( pev.sequence == ANIM_BLASTER or (pev.sequence == ANIM_ROCKET and pev.dmgtime > 0.0) )
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
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_GIB], VOL_NORM, ATTN_NORM );
			SpawnGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		DropArm();

		pev.body = 1; //no left arm
		pev.sequence = ANIM_DEATH;
		pev.frame = 0;
		self.ResetSequenceInfo();
		m_uiAnimationState = 0;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, pDieSounds[Math.RandomLong(0, pDieSounds.length()-1)], VOL_NORM, ATTN_NORM );

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void SpawnGibs()
	{
		ThrowGib( 1, MODEL_GIB_MEAT, pev.dmg, BREAK_FLESH );
		ThrowGib( 3, MODEL_GIB_METAL, pev.dmg, BREAK_METAL );
		ThrowGib( 1, MODEL_GIB_GEAR, pev.dmg, BREAK_METAL );
		ThrowGib( 2, MODEL_GIB_FOOT, pev.dmg, BREAK_CONCRETE );
		ThrowGib( 2, MODEL_GIB_THIGH, pev.dmg, BREAK_CONCRETE );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, BREAK_CONCRETE );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, BREAK_CONCRETE, true );
		DropArm();
	}

	void DropArm()
	{
		Vector vecForward, vecRight, vecUp;
		g_EngineFuncs.AngleVectors( pev.angles, vecForward, vecRight, vecUp );

		Vector vecOrigin = pev.origin + vecRight * -16.0 + vecUp * 23.0;
		Vector vecVelocity = vecUp * 100.0 + vecRight * -120.0;

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BREAKMODEL );
			m1.WriteCoord( vecOrigin.x ); //position x y z
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteCoord( 1 ); //size x y z
			m1.WriteCoord( 1 );
			m1.WriteCoord( 1 );
			m1.WriteCoord( vecVelocity.x ); //velocity x y z
			m1.WriteCoord( vecVelocity.y );
			m1.WriteCoord( vecVelocity.z );
			m1.WriteByte( 1 ); //random velocity in 10's
			m1.WriteShort( g_EngineFuncs.ModelIndex(MODEL_GIB_ARM) );
			m1.WriteByte( 1 ); //count
			m1.WriteByte( 45 ); //life in 0.1 secs
			m1.WriteByte( BREAK_CONCRETE|BREAK_SMOKE ); //flags
		m1.End();
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		if( GetFrame(32, 27) and m_uiAnimationState == 0 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_THUD], VOL_NORM, ATTN_NORM );
			m_uiAnimationState++;
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
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

final class info_cnpc_q2tank : CNPCSpawnEntity
{
	info_cnpc_q2tank()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = ANIM_IDLE;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
	}

	void DoSpecificStuff()
	{
		int iYaw = 150;
		pev.set_controller( 0,  iYaw );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2laser", "cnpcq2laser" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2rocket", "cnpcq2rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2tank::info_cnpc_q2tank", "info_cnpc_q2tank" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2tank::cnpc_q2tank", "cnpc_q2tank" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2tank::weapon_q2tank", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "cnpcq2laser" );
	g_Game.PrecacheOther( "cnpcq2rocket" );
	g_Game.PrecacheOther( "info_cnpc_q2tank" );
	g_Game.PrecacheOther( "cnpc_q2tank" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2tank END

/* FIXME
	The idle animation, and possibly others, turns the head slightly to the left
*/

/* TODO
	Use a think for the machinegun instead of HandleAnimEvent ??
	NPC Hitbox ??
*/