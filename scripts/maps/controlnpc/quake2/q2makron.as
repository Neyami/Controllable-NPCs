namespace cnpc_q2makron
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_q2makron";
const string CNPC_MODEL				= "models/quake2/monsters/makron/makron.mdl";
const Vector CNPC_SIZEMIN			= Vector( -32, -32, 0 );
const Vector CNPC_SIZEMAX			= Vector( 32, 32, 128 );

const float CNPC_HEALTH				= 3000.0;
const float CNPC_VIEWOFS_FPV		= 72.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 80.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not makron itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?
const float CNPC_FADETIME			= 1.5; //after the death animation is finished

const float SPEED_RUN					= -1;
const float SPEED_WALK					= -1;
const float VELOCITY_WALK			= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_BFG						= 2.0;
const float BFG_DAMAGE				= 50.0;
const float BFG_SPEED					= 600.0;
const float BFG_MAXPITCH				= 30.0;

const float CD_BLASTER					= 2.0;
const float BLASTER_DAMAGE			= 15.0;
const float BLASTER_SPEED			= 1000.0;

const float CD_RAILGUN					= 2.0;
const float RAILGUN_DAMAGE			= 50.0;
const float RAILGUN_MAXPITCH		= 30.0;

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"quake2/misc/udeath.wav",
	"quake2/npcs/makron/laf1.wav",
	"quake2/npcs/makron/laf2.wav",
	"quake2/npcs/makron/laf3.wav",
	"quake2/npcs/makron/bfg_fire.wav",
	"quake2/npcs/makron/blaster.wav",
	"quake2/npcs/makron/rail_up.wav",
	"quake2/weapons/rg_fire.wav",
	"quake2/npcs/makron/step1.wav",
	"quake2/npcs/makron/step2.wav",
	"quake2/npcs/makron/voice4.wav",
	"quake2/npcs/makron/voice3.wav",
	"quake2/npcs/makron/voice.wav",
	"quake2/npcs/makron/popup.wav",
	"quake2/npcs/makron/pain3.wav",
	"quake2/npcs/makron/pain2.wav",
	"quake2/npcs/makron/pain1.wav",
	"quake2/npcs/makron/death.wav",
	"quake2/npcs/makron/bhit.wav",
	"quake2/npcs/makron/brain1.wav",
	"quake2/npcs/makron/spine.wav"
};

enum sound_e
{
	SND_GIB = 1,
	SND_SIGHT1,
	SND_SIGHT2,
	SND_SIGHT3,
	SND_ATK_BFG,
	SND_ATK_BLASTER,
	SND_ATK_RAILGUN1,
	SND_ATK_RAILGUN2,
	SND_STEP_LEFT,
	SND_STEP_RIGHT,
	SND_TAUNT1,
	SND_TAUNT2,
	SND_TAUNT3,
	SND_POPUP,
	SND_PAIN4,
	SND_PAIN5,
	SND_PAIN6,
	SND_DEATH,
	SND_FALL,
	SND_BRAINSPLORCH,
	SND_SPINE
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK,
	ANIM_RUN,
	ANIM_ATK_BFG,
	ANIM_ATK_BLASTER,
	ANIM_ATK_RG,
	ANIM_PAIN4 = 7,
	ANIM_PAIN5,
	ANIM_PAIN6,
	ANIM_DEATH
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
	ATTACH_BFG = 0,
	ATTACH_BLASTER,
	ATTACH_RAILGUN
};

final class weapon_q2makron : CBaseDriveWeaponQ2
{
	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_q2makron.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2makron.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_q2makron_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::Q2::Q2MAKRON_SLOT - 1;
		info.iPosition			= CNPC::Q2::Q2MAKRON_POSITION - 1;
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
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATK_BFG );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_BFG;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATK_BLASTER );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_BLASTER;
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
			cnpc_q2makron@ pDriveEnt = cast<cnpc_q2makron@>(CastToScriptClass(m_pDriveEnt));
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
			HandleAnimEvent( m_pDriveEnt.pev.sequence );

			CheckRailgunInput();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() > STATE_MOVING ) return;

		SetSpeed( int(SPEED_RUN) );

		float flMinWalkVelocity = -VELOCITY_WALK;
		float flMaxWalkVelocity = VELOCITY_WALK;

		if( (m_pPlayer.pev.button & IN_USE) != 0 or IsBetween(m_pPlayer.pev.velocity.Length(), flMinWalkVelocity, flMaxWalkVelocity) )
		{
			if( m_pDriveEnt.pev.sequence != ANIM_WALK )
			{
				SetState( STATE_MOVING );
				SetSpeed( int(SPEED_WALK) );
				SetAnim( ANIM_WALK, 0.8 );
			}
		}
		else
		{
			if( m_pDriveEnt.pev.sequence != ANIM_RUN )
			{
				SetState( STATE_MOVING );
				SetSpeed( int(SPEED_RUN) );
				SetAnim( ANIM_RUN );
			}
			else
				m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
		}
	}

	void DoIdleAnimation()
	{
		if( GetState() >= STATE_ATTACK and !m_pDriveEnt.m_fSequenceFinished ) return;

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

	void AlertSound()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_SIGHT1, SND_SIGHT3)], VOL_NORM, ATTN_NONE );
	}

	void HandlePain( float flDamage )
	{
		m_pDriveEnt.pev.dmg = flDamage;

		if( m_pPlayer.pev.health < (CNPC_HEALTH * 0.5) )
			m_pDriveEnt.pev.skin = 1;

		if( m_pDriveEnt.pev.pain_finished > g_Engine.time )
			return;

		if( flDamage <= 25 and Math.RandomFloat(0.0, 1.0) < 0.2 )
				return;

		m_pDriveEnt.pev.pain_finished = g_Engine.time + 3.0;

		bool bDoPain6 = false;

		if( flDamage <= 40 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN4], VOL_NORM, ATTN_NONE );
		else if( flDamage <= 110 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN5], VOL_NORM, ATTN_NONE );
		else
		{
			if( flDamage <= 150 )
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.45 )
				{
					bDoPain6 = true;
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN6], VOL_NORM, ATTN_NONE );
				}
			}
			else
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.35 )
				{
					bDoPain6 = true;
					g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[SND_PAIN6], VOL_NORM, ATTN_NONE );
				}
			}
		}

		if( flDamage <= 40 )
			SetAnim( ANIM_PAIN4 );
		else if( flDamage <= 110 )
			SetAnim( ANIM_PAIN5 );
		else if( bDoPain6 )
			SetAnim( ANIM_PAIN6 );
		else
			return;

		SetSpeed( 0 );
		SetState( STATE_PAIN );
	}

	void HandleAnimEvent( int iSequence )
	{
		switch( iSequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(11, 0) and m_uiAnimationState == 0 ) { makron_step_left(); m_uiAnimationState++; }
				else if( GetFrame(11, 5) and m_uiAnimationState == 1 ) { makron_step_right(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_RUN:
			{
				if( GetFrame(11, 0) and m_uiAnimationState == 0 ) { makron_step_left(); m_uiAnimationState++; }
				else if( GetFrame(11, 5) and m_uiAnimationState == 1 ) { makron_step_right(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATK_BFG:
			{
				if( GetFrame(8, 3) and m_uiAnimationState == 0 ) { MakronBFG(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATK_BLASTER:
			{
				if( m_uiAnimationState <= 16 )
				{
					if( GetFrame(26, 4 + m_uiAnimationState) )
					{
						MakronHyperblaster();
						m_uiAnimationState++;
					}
				}
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 17 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_ATK_RG:
			{
				if( GetFrame(16, 8) and m_uiAnimationState == 0 ) { MakronRailgun(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PAIN6:
			{
				if( GetFrame(27, 18) and m_uiAnimationState == 0 ) { makron_popup(); m_uiAnimationState++; }
				else if( GetFrame(27, 26) and m_uiAnimationState == 1 ) { makron_taunt(); m_uiAnimationState++; }
				else if( m_pDriveEnt.m_fSequenceFinished and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void makron_step_left()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_LEFT], VOL_NORM, ATTN_NORM );
	}

	void makron_step_right()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_RIGHT], VOL_NORM, ATTN_NORM );
	}

	void makron_popup()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_POPUP], VOL_NORM, ATTN_NONE );
	}

	void makron_taunt()
	{
		float r;

		r = Math.RandomFloat(0.0, 1.0);
		if( r <= 0.3 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_TAUNT1], VOL_NORM, ATTN_NONE );
		else if( r <= 0.6 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_TAUNT2], VOL_NORM, ATTN_NONE );
		else
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_AUTO, arrsCNPCSounds[SND_TAUNT3], VOL_NORM, ATTN_NONE );
	}

	void CheckRailgunInput()
	{
		if( GetState() > STATE_MOVING or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( GetPressed(IN_RELOAD) )
		{
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATK_RAILGUN1], VOL_NORM, ATTN_NORM );

			SetState( STATE_ATTACK );
			SetSpeed( 0 );
			SetAnim( ANIM_ATK_RG );
		}
	}

	void MakronBFG()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATK_BFG], VOL_NORM, ATTN_NORM );

		Vector vecMuzzle;
		m_pDriveEnt.GetAttachment( ATTACH_BFG, vecMuzzle, void );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > BFG_MAXPITCH )
			vecAim.x = BFG_MAXPITCH;
		else if( vecAim.x < -BFG_MAXPITCH )
			vecAim.x = -BFG_MAXPITCH;

		vecAim.y += -1.0; //closer to the crosshairs
		vecAim.x += -0.5; //closer to the crosshairs

		monster_muzzleflash( vecMuzzle, 30, 128, 255, 128 );

		Math.MakeVectors( vecAim );
		monster_fire_bfg( vecMuzzle, g_Engine.v_forward, BFG_DAMAGE, BFG_SPEED );
	}

	void MakronHyperblaster()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATK_BLASTER], VOL_NORM, ATTN_NORM );

		Vector vecMuzzle;
		m_pDriveEnt.GetAttachment( ATTACH_BLASTER, vecMuzzle, void );

		//This will make the shots only go where the arm points throughout the animation
		//Vector vecBonePos;
		//g_EngineFuncs.GetBonePosition( m_pDriveEnt.edict(), 4, vecBonePos, void );
		//Vector vecAim = (vecMuzzle - vecBonePos).Normalize();

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecAim = g_Engine.v_forward;

		monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );

		if( !GetButton(IN_USE) )
			monster_fire_blaster( vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
		else
			monster_fire_bfg( vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
	}

	void MakronRailgun()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATK_RAILGUN2], VOL_NORM, ATTN_NORM );

		Vector vecMuzzle;
		m_pDriveEnt.GetAttachment( ATTACH_RAILGUN, vecMuzzle, void );

		Vector vecAim = m_pPlayer.pev.v_angle;
		if( vecAim.x > RAILGUN_MAXPITCH )
			vecAim.x = RAILGUN_MAXPITCH;
		else if( vecAim.x < -RAILGUN_MAXPITCH )
			vecAim.x = -RAILGUN_MAXPITCH;

		monster_muzzleflash( vecMuzzle, 20, 128, 128, 255 );

		Math.MakeVectors( vecAim );
		monster_fire_railgun( vecMuzzle, g_Engine.v_forward, RAILGUN_DAMAGE );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_q2makron", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::Q2::CNPC_Q2MAKRON );

		AlertSound();
	}

	void DoFirstPersonView()
	{
		cnpc_q2makron@ pDriveEnt = cast<cnpc_q2makron@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_q2makron_rend_" + m_pPlayer.entindex();
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

class cnpc_q2makron : CBaseDriveEntityQ2
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

	void TorsoThink()
	{
		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;

		if( pev.angles.x > 0 )
			pev.angles.x = Math.max( 0.0, pev.angles.x - 15 );
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
		else if( GetAnim(ANIM_ATK_BFG) or GetAnim(ANIM_ATK_RG) or GetAnim(ANIM_ATK_BLASTER) )
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
			//SpawnGibs();

			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		pev.sequence = ANIM_DEATH;
		pev.body = 1;
		pev.frame = 0;
		self.ResetSequenceInfo();

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );

		SpawnTorso();

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
		pev.movetype = MOVETYPE_STEP;
	}

	void SpawnTorso()
	{
		Math.MakeVectors( pev.angles );
		Vector vecOrigin = pev.origin;
		vecOrigin.z += (pev.size.z - 30);

		CBaseEntity@ pTorso = g_EntityFuncs.Create( "cnpc_q2makron_torso", vecOrigin + g_Engine.v_forward * -20, Vector(0, pev.angles.y, 0), false );
		pTorso.pev.velocity = g_Engine.v_forward * -120 + g_Engine.v_up * 120;
	}

	void DieThink()
	{
		pev.nextthink = g_Engine.time + 0.01;
		self.StudioFrameAdvance();

		switch( GetFrame(95) )
		{
			case 0: { if( m_uiAnimationState == 0 ) { WalkMove(-15); m_uiAnimationState++; } break; }
			case 1: { if( m_uiAnimationState == 1 ) { WalkMove(3); m_uiAnimationState++; } break; }
			case 2: { if( m_uiAnimationState == 2 ) { WalkMove(-12); m_uiAnimationState++; } break; }
			case 3: { if( m_uiAnimationState == 3 ) { makron_step_left(); m_uiAnimationState++; } break; }
			case 15: { if( m_uiAnimationState == 4 ) { WalkMove(11); m_uiAnimationState++; } break; }
			case 16: { if( m_uiAnimationState == 5 ) { WalkMove(12); m_uiAnimationState++; } break; }
			case 17: { if( m_uiAnimationState == 6 ) { WalkMove(11); makron_step_right(); m_uiAnimationState++; } break; }
			case 33: { if( m_uiAnimationState == 7 ) { WalkMove(5); m_uiAnimationState++; } break; }
			case 34: { if( m_uiAnimationState == 8 ) { WalkMove(7); m_uiAnimationState++; } break; }
			case 35: { if( m_uiAnimationState == 9 ) { WalkMove(6); makron_step_left(); m_uiAnimationState++; } break; }
			case 38: { if( m_uiAnimationState == 10 ) { WalkMove(-1); m_uiAnimationState++; } break; }
			case 39: { if( m_uiAnimationState == 11 ) { WalkMove(2); m_uiAnimationState++; } break; }
			case 53: { if( m_uiAnimationState == 12 ) { WalkMove(-6); m_uiAnimationState++; } break; }
			case 54: { if( m_uiAnimationState == 13 ) { WalkMove(-4); m_uiAnimationState++; } break; }
			case 55: { if( m_uiAnimationState == 14 ) { WalkMove(-6); makron_step_right(); m_uiAnimationState++; } break; }
			case 56: { if( m_uiAnimationState == 15 ) { WalkMove(-4); m_uiAnimationState++; } break; }
			case 57: { if( m_uiAnimationState == 16 ) { WalkMove(-4); makron_step_left(); m_uiAnimationState++; } break; }
			case 62: { if( m_uiAnimationState == 17 ) { WalkMove(-2); m_uiAnimationState++; } break; }
			case 63: { if( m_uiAnimationState == 18 ) { WalkMove(-5); m_uiAnimationState++; } break; }
			case 64: { if( m_uiAnimationState == 19 ) { WalkMove(-3); makron_step_right(); m_uiAnimationState++; } break; }
			case 65: { if( m_uiAnimationState == 20 ) { WalkMove(-8); m_uiAnimationState++; } break; }
			case 66: { if( m_uiAnimationState == 21 ) { WalkMove(-3); makron_step_left(); m_uiAnimationState++; } break; }
			case 67: { if( m_uiAnimationState == 22 ) { WalkMove(-7); m_uiAnimationState++; } break; }
			case 68: { if( m_uiAnimationState == 23 ) { WalkMove(-4); m_uiAnimationState++; } break; }
			case 69: { if( m_uiAnimationState == 24 ) { WalkMove(-4); makron_step_right(); m_uiAnimationState++; } break; }
			case 70: { if( m_uiAnimationState == 25 ) { WalkMove(-6); m_uiAnimationState++; } break; }
			case 71: { if( m_uiAnimationState == 26 ) { WalkMove(-7); m_uiAnimationState++; } break; }
			case 72: { if( m_uiAnimationState == 27 ) { makron_step_left(); m_uiAnimationState++; } break; }
			case 85: { if( m_uiAnimationState == 28 ) { WalkMove(-2); m_uiAnimationState++; } break; }
			case 88: { if( m_uiAnimationState == 29 ) { WalkMove(2); m_uiAnimationState++; } break; }
			case 90: { if( m_uiAnimationState == 30 ) { WalkMove(27); makron_hit(); m_uiAnimationState++; } break; }
			case 91: { if( m_uiAnimationState == 31 ) { WalkMove(26); m_uiAnimationState++; } break; }
			case 92: { if( m_uiAnimationState == 32 ) { makron_brainsplorch(); m_uiAnimationState++; } break; }
		}

		if( self.m_fSequenceFinished )
		{
			SetThink( ThinkFunction(this.SUB_StartFadeOut) );
			pev.nextthink = g_Engine.time + CNPC_FADETIME;
		}
	}

	void WalkMove( float flDist )
	{
		g_EngineFuncs.WalkMove( self.edict(), pev.angles.y, flDist, WALKMOVE_WORLDONLY );
	}

	void makron_step_left()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_LEFT], VOL_NORM, ATTN_NORM );
	}

	void makron_step_right()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP_RIGHT], VOL_NORM, ATTN_NORM );
	}

	void makron_hit()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsCNPCSounds[SND_FALL], VOL_NORM, ATTN_NONE );
	}

	void makron_brainsplorch()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_BRAINSPLORCH], VOL_NORM, ATTN_NORM );
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

class cnpc_q2makron_torso : ScriptBaseAnimating
{
	private float m_flRemoveTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.sequence = ANIM_DEATH+1;
		pev.frame = 0;
		self.ResetSequenceInfo();

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_TOSS;
		pev.body = 2;
		pev.skin = 1;
		pev.angles.x = 90;
		pev.avelocity = g_vecZero;

		m_flRemoveTime = g_Engine.time + CNPC_FADETIME * 7; //synch with the legs

		SetThink( ThinkFunction(this.TorsoThink) );
		pev.nextthink = g_Engine.time;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SPINE], VOL_NORM, ATTN_NORM, SND_FORCE_LOOP );
	}

	void TorsoThink()
	{
		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;

		if( pev.angles.x > 0 )
			pev.angles.x = Math.max( 0.0, pev.angles.x - 15 );

		if( m_flRemoveTime < g_Engine.time )
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
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, arrsCNPCSounds[SND_SPINE] );

		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_q2makron : CNPCSpawnEntity
{
	info_cnpc_q2makron()
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
	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2bfg" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2bfg", "cnpcq2bfg" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2laser" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2laser", "cnpcq2laser" );

	if( !g_CustomEntityFuncs.IsCustomEntity( "cnpcq2railbeam" ) )  
		g_CustomEntityFuncs.RegisterCustomEntity( "CNPC::Q2::cnpcq2railbeam", "cnpcq2railbeam" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2makron::cnpc_q2makron_torso", "cnpc_q2makron_torso" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2makron::info_cnpc_q2makron", "info_cnpc_q2makron" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2makron::cnpc_q2makron", "cnpc_q2makron" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_q2makron::weapon_q2makron", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "cnpcq2bfg" );
	g_Game.PrecacheOther( "cnpcq2laser" );
	g_Game.PrecacheOther( "cnpcq2railbeam" );
	g_Game.PrecacheOther( "info_cnpc_q2makron" );
	g_Game.PrecacheOther( "cnpc_q2makron" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_q2makron END

/* FIXME
*/

/* TODO
*/