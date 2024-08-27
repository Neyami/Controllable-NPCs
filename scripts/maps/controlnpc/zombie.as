namespace cnpc_zombie
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_zombie";
const string CNPC_MODEL				= "models/zombie.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 100.0;
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the zombie itself
const float CNPC_MODEL_OFFSET	= 36.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= false; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (181.171677 * CNPC::flModelToGameSpeedModifier) * 0.25;

const float CD_MELEE1					= 2.2; //right, left slash
const float CD_MELEE2					= 1.4; //both arms
const float MELEE_RANGE				= 70.0;
const float DMG_ONE						= 25;
const float DMG_BOTH					= 40;

const array<string> pPainSounds = 
{
	"zombie/zo_pain1.wav",
	"zombie/zo_pain2.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"common/npc_step1.wav",
	"common/npc_step2.wav",
	"common/npc_step3.wav",
	"common/npc_step4.wav",
	"zombie/zo_attack1.wav",
	"zombie/zo_attack2.wav",
	"zombie/claw_strike1.wav",
	"zombie/claw_strike2.wav",
	"zombie/claw_strike3.wav",
	"zombie/claw_miss1.wav",
	"zombie/claw_miss2.wav",
	"zombie/zo_idle1.wav",
	"zombie/zo_idle2.wav",
	"zombie/zo_idle3.wav",
	"zombie/zo_idle4.wav"
};

enum sound_e
{
	SND_STEP1 = 1,
	SND_STEP2,
	SND_STEP3,
	SND_STEP4,
	SND_ATTACK1,
	SND_ATTACK2,
	SND_HIT1,
	SND_HIT2,
	SND_HIT3,
	SND_MISS1,
	SND_MISS2,
	SND_IDLE1,
	SND_IDLE2,
	SND_IDLE3,
	SND_IDLE4
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_MELEE1 = 8, //right, left slash
	ANIM_MELEE2, //both arms
	ANIM_WALK,
	ANIM_DEATH1 = 15,
	ANIM_DEATH5 = 19,
	ANIM_DEATH_SLIDE = 26
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_ATTACK
};

class weapon_zombie : CBaseDriveWeapon
{
	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_zombie.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_zombie.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_zombie_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::ZOMBIE_SLOT - 1;
		info.iPosition			= CNPC::ZOMBIE_POSITION - 1;
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
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_iState = STATE_ATTACK;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_MELEE1 );
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_MELEE1;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_iState = STATE_ATTACK;
			m_pPlayer.SetMaxSpeedOverride( 0 );
			SetAnim( ANIM_MELEE2 );
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_MELEE2;
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
			cnpc_zombie@ pDriveEnt = cast<cnpc_zombie@>(CastToScriptClass(m_pDriveEnt));
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
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 ) return;

		m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );

		if( m_pDriveEnt.pev.sequence != ANIM_WALK )
		{
			m_iState = STATE_WALK;
			m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
			SetAnim( ANIM_WALK );
		}
		else
			m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
	}

	void DoIdleAnimation()
	{
		if( m_iState == STATE_ATTACK and (m_pDriveEnt.pev.sequence == ANIM_MELEE1 or m_pDriveEnt.pev.sequence == ANIM_MELEE2) and !m_pDriveEnt.m_fSequenceFinished ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_WALK) );
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
		g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE4)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5,5) );
	}

	void HandleAnimEvent( int iSequence )
	{
		if( iSequence != ANIM_WALK and iSequence != ANIM_MELEE1 and iSequence != ANIM_MELEE2 ) return;

		switch( iSequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(60, 2) and m_uiAnimationState == 0 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(60, 12) and m_uiAnimationState == 1 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(60, 22) and m_uiAnimationState == 2 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(60, 31) and m_uiAnimationState == 3 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(60, 41) and m_uiAnimationState == 4 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(60, 51) and m_uiAnimationState == 5 ) { FootStep(); m_uiAnimationState++; }
				else if( GetFrame(60) >= 58 and m_uiAnimationState == 6 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE1:
			{
				if( GetFrame(36, 10) and m_uiAnimationState == 0 ) { MeleeAttack1(true); m_uiAnimationState++; }
				else if( GetFrame(36, 19) and m_uiAnimationState == 1 ) { MeleeAttack1(false); m_uiAnimationState++; }
				else if( GetFrame(36) >= 30 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_MELEE2:
			{
				if( GetFrame(21, 6) and m_uiAnimationState == 0 ) { MeleeAttack2(); m_uiAnimationState++; }
				else if( GetFrame(21) >= 10 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void FootStep()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[Math.RandomLong(SND_STEP1, SND_STEP4)], VOL_NORM, ATTN_NORM );
	}

	void MeleeAttack1( bool bRight )
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, DMG_ONE, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.z = bRight ? -18 : 18;
				pHurt.pev.punchangle.x = 5;
				pHurt.pev.velocity = pHurt.pev.velocity - g_Engine.v_right * 100;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MISS1, SND_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

		if( Math.RandomLong(0, 1) == 1 )
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_ATTACK1, SND_ATTACK2)], 1.0, ATTN_NORM, 0, 100 + Math.RandomLong(-5,5) );
	}

	void MeleeAttack2()
	{
		CBaseEntity@ pHurt = CheckTraceHullAttack( MELEE_RANGE, DMG_BOTH, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or (pHurt.pev.FlagBitSet(FL_CLIENT) and CNPC::PVP) )
			{
				pHurt.pev.punchangle.x = 5;
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * -100;
			}

			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_HIT1, SND_HIT3)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );
		}
		else
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[Math.RandomLong(SND_MISS1, SND_MISS2)], VOL_NORM, ATTN_NORM, 0, 100 + Math.RandomLong(-5, 5) );

		if( Math.RandomLong(0, 1) == 1 )
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_ATTACK1, SND_ATTACK2)], 1.0, ATTN_NORM, 0, 100 + Math.RandomLong(-5,5) );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_zombie", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_ZOMBIE );
	}

	void DoFirstPersonView()
	{
		cnpc_zombie@ pDriveEnt = cast<cnpc_zombie@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_zombie_rend_" + m_pPlayer.entindex();
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
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_zombie : CBaseDriveEntity
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
		else if( (m_pOwner.pev.button & (IN_ATTACK|IN_ATTACK2)) != 0 )
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
			//Spawn gibs
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;

			return;
		}

		SetThink( ThinkFunction(this.DieThink) );
		pev.nextthink = g_Engine.time;
	}

	void DieThink()
	{
		//Is there a wall behind?
		TraceResult tr;
		Math.MakeVectors( pev.angles );
		g_Utility.TraceLine( pev.origin, pev.origin + Vector(0, 0, 36) + g_Engine.v_forward * -24, ignore_monsters, self.edict(), tr );

		if( tr.vecPlaneNormal != g_vecZero )
			pev.sequence = ANIM_DEATH_SLIDE;
		else
			pev.sequence = Math.RandomLong(ANIM_DEATH1, ANIM_DEATH5);

		pev.frame = 0;
		self.ResetSequenceInfo();

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

final class info_cnpc_zombie : CNPCSpawnEntity
{
	info_cnpc_zombie()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_zombie::info_cnpc_zombie", "info_cnpc_zombie" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_zombie::cnpc_zombie", "cnpc_zombie" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_zombie::weapon_zombie", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_zombie" );
	g_Game.PrecacheOther( "cnpc_zombie" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_zombie END

/* FIXME
*/

/* TODO
	Spawn zombie gibs when gibbed
*/