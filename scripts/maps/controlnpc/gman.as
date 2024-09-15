namespace cnpc_gman
{

bool CNPC_FIRSTPERSON				= false;

const string CNPC_WEAPONNAME	= "weapon_gman";
const string CNPC_MODEL				= "models/gman.mdl";
const Vector CNPC_SIZEMIN			= VEC_HUMAN_HULL_MIN;
const Vector CNPC_SIZEMAX			= VEC_HUMAN_HULL_MAX;

const float CNPC_HEALTH				= 100.0; //irrelevant
const float CNPC_VIEWOFS_FPV		= 28.0; //camera height offset
const float CNPC_VIEWOFS_TPV		= 28.0;
const float CNPC_RESPAWNTIME		= 13.0; //from the point that the weapon is removed, not the gman itself
const float CNPC_RESPAWNEXIT		= 5.0; //time until it can be used again after a player exits
const float CNPC_MODEL_OFFSET	= 32.0; //sometimes the model floats above the ground
const float CNPC_ORIGINUPDATE	= 0.1; //how often should the driveent's origin be updated? Lower values causes hacky looking movement when viewing other players
const bool CNPC_FIDGETANIMS		= true; //does this monster have more than 1 idle animation?

const float SPEED_WALK					= (55.71381 * CNPC::flModelToGameSpeedModifier);

const float CD_PRIMARY					= 0.5;

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"common/npc_step1.wav",
	"common/npc_step3.wav",
	"gman/gman_mumble1.wav",
	"gman/gman_mumble2.wav",
	"gman/gman_mumble3.wav",
	"gman/gman_mumble4.wav",
	"gman/gman_mumble5.wav",
	"gman/gman_mumble6.wav",
	"common/wpn_denyselect.wav"
};

enum sound_e
{
	SND_STEP1 = 1,
	SND_STEP2,
	SND_PHONE1,
	SND_PHONE6 = 8,
	SND_USE
};

enum anim_e
{
	ANIM_IDLE = 0,
	ANIM_WALK = 6,
	ANIM_PHONE_IDLE = 14,
	ANIM_PHONE_DEPLOY,
	ANIM_PUSH = 17
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_PUSH,
	STATE_PHONE_TOGGLE,
	STATE_PHONE_USE
};

class weapon_gman : CBaseDriveWeapon
{
	private float m_flCanExit;
	private bool m_bPhoneOut;

	void Spawn()
	{
		Precache();

		SetState( STATE_IDLE );
		m_flCanExit = 0.0;
		m_bPhoneOut = false;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_gman.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_gman.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_gman_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::GMAN_SLOT - 1;
		info.iPosition			= CNPC::GMAN_POSITION - 1;
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
			if( m_pDriveEnt.pev.sequence <= ANIM_WALK )
			{
				SetSpeed( 0 );
				SetState( STATE_PUSH );
				SetAnim( ANIM_PUSH );
			}
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_PRIMARY;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null and m_bPhoneOut and GetState() <= STATE_WALK )
		{
			SetSpeed( 0 );
			SetState( STATE_PHONE_USE );
			SetAnim( ANIM_PHONE_IDLE );
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
			cnpc_gman@ pDriveEnt = cast<cnpc_gman@>(CastToScriptClass(m_pDriveEnt));
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

			CheckForExit();
			MoveHead();
			CheckForPhone();
		}
	}

	void DoMovementAnimation()
	{
		m_pPlayer.pev.friction = 2; //no sliding!

		if( m_pPlayer.pev.button & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) == 0 or GetState() == STATE_PHONE_USE ) return;

		SetSpeed( int(SPEED_WALK) );

		if( m_pDriveEnt.pev.sequence != ANIM_WALK )
		{
			SetState( STATE_WALK );
			SetSpeed( int(SPEED_WALK) );
			SetAnim( ANIM_WALK );
		}
		else
			m_pPlayer.pev.flTimeStepSound = 9999; //prevents normal footsteps from playing
	}

	void DoIdleAnimation()
	{
		if( m_iState == STATE_PUSH and m_pDriveEnt.pev.sequence == ANIM_PUSH and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_PHONE_TOGGLE and m_pDriveEnt.pev.sequence == ANIM_PHONE_DEPLOY and !m_pDriveEnt.m_fSequenceFinished ) return;
		if( m_iState == STATE_PHONE_USE and m_pPlayer.pev.button & IN_ATTACK2 != 0 ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				SetSpeed( int(SPEED_WALK) );
				SetState( STATE_IDLE );
				SetAnim( ANIM_IDLE );
			}
			else if( m_iState == STATE_IDLE and CNPC_FIDGETANIMS )
			{
				if( m_pDriveEnt.m_fSequenceFinished )
					SetAnim( m_pDriveEnt.LookupActivity(ACT_IDLE) );
			}
		}
	}

	void HandleAnimEvent( int iSequence )
	{
		if( iSequence < ANIM_IDLE ) return;

		switch( iSequence )
		{
			case ANIM_WALK:
			{
				if( GetFrame(20, 0) and m_uiAnimationState == 0 ) { FootStep(1); m_uiAnimationState++; }
				else if( GetFrame(20, 10) and m_uiAnimationState == 1 ) { FootStep(2); m_uiAnimationState++; }
				else if( GetFrame(20) >= 15 and m_uiAnimationState == 2 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PHONE_DEPLOY:
			{
				if( GetFrame(58, 38) and m_uiAnimationState == 0 ) { TogglePhone(); m_uiAnimationState++; }

				break;
			}

			case ANIM_PHONE_IDLE:
			{
				if( GetFrame(194, 38) and m_uiAnimationState == 0 ) { TalkOnPhone(); m_uiAnimationState++; }
				else if( GetFrame(194) >= 100 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}

			case ANIM_PUSH:
			{
				if( GetFrame(27, 14) and m_uiAnimationState == 0 ) { PushButton(); m_uiAnimationState++; }
				else if( GetFrame(27) >= 20 and m_uiAnimationState == 1 ) { m_uiAnimationState = 0; }

				break;
			}
		}
	}

	void FootStep( int iStepNum )
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_STEP1 + (iStepNum-1)], VOL_NORM, ATTN_NORM );
	}

	void TogglePhone()
	{
		if( !m_bPhoneOut )
			m_pDriveEnt.SetBodygroup( 1, 1 );
		else
			m_pDriveEnt.SetBodygroup( 1, 0 );

		m_bPhoneOut = !m_bPhoneOut;
	}

	void TalkOnPhone()
	{
		//if( Math.RandomLong(0, 1) == 1 )
			g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_VOICE, arrsCNPCSounds[Math.RandomLong(SND_PHONE1, SND_PHONE6)], VOL_NORM, ATTN_NORM );
	}

	void PushButton()
	{
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_BODY, arrsCNPCSounds[SND_USE], VOL_NORM, ATTN_NORM );
	}

	void CheckForExit()
	{
		if( m_flCanExit > g_Engine.time ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_USE) != 0 )
			ExitPlayer();
	}

	void ExitPlayer()
	{
		cnpc_gman@ pDriveEnt = cast<cnpc_gman@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt !is null and pDriveEnt.m_hRenderEntity.IsValid() ) g_EntityFuncs.Remove( pDriveEnt.m_hRenderEntity.GetEntity() );

		CBaseEntity@ cbeSpawnEnt = null;
		info_cnpc_gman@ pSpawnEnt = null;
		while( (@cbeSpawnEnt = g_EntityFuncs.FindEntityByClassname(cbeSpawnEnt, "info_cnpc_gman")) !is null )
		{
			@pSpawnEnt = cast<info_cnpc_gman@>(CastToScriptClass(cbeSpawnEnt));
			if( pSpawnEnt.m_pCNPCWeapon is null ) continue;
			if( pSpawnEnt.m_pCNPCWeapon.edict() is self.edict() ) break;
		}

		if( pSpawnEnt !is null )
			pSpawnEnt.m_flTimeToRespawn = g_Engine.time + CNPC_RESPAWNEXIT;

		ResetPlayer();

		Vector vecOrigin = pev.origin + Vector( 0, 0, 19 );

		g_EntityFuncs.Remove( m_pDriveEnt );
		g_EntityFuncs.SetOrigin( m_pPlayer, vecOrigin );
		g_EntityFuncs.Remove( self );
	}

	void MoveHead()
	{
		if( GetState() == STATE_PHONE_USE )
		{
			m_pDriveEnt.pev.set_controller( 0,  127 ); //look straight ahead
			return;
		}

		Vector vecAngles;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		vecAngles = Math.VecToAngles( g_Engine.v_forward );
		vecAngles.y -= m_pDriveEnt.pev.angles.y;
		if( vecAngles.y < -180 )
			vecAngles.y += 360;
		else if( vecAngles.y > 180 )
			vecAngles.y -= 360;

		if( fabs(vecAngles.y) > 110 )
			m_pDriveEnt.pev.set_controller( 0,  127 ); //look straight ahead
		else
			m_pDriveEnt.SetBoneController( 0, vecAngles.y );
	}

	float fabs( float x )
	{
		return ( (x) > 0 ? (x) : 0 - (x) );
	}

	void CheckForPhone()
	{
		if( m_pDriveEnt is null or m_iState > STATE_WALK or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.m_afButtonPressed & IN_RELOAD) != 0 )
		{
			m_iState = STATE_PHONE_TOGGLE;

			m_pPlayer.SetMaxSpeedOverride( 0 );

			if( m_bPhoneOut )
				SetAnim( ANIM_PHONE_DEPLOY, 1.0, 30 );
			else
				SetAnim( ANIM_PHONE_DEPLOY, -1.0, 255 );
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

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_gman", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			m_pDriveEnt.pev.set_controller( 0,  127 );
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			m_flCanExit = g_Engine.time + 1.0;
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.flags |= (FL_NOTARGET|FL_GODMODE);
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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_GMAN );
	}

	void DoFirstPersonView()
	{
		cnpc_gman@ pDriveEnt = cast<cnpc_gman@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_gman_rend_" + m_pPlayer.entindex();
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
		m_pPlayer.pev.flags &= ~(FL_NOTARGET|FL_GODMODE);
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

class cnpc_gman : CBaseDriveEntity
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

		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath()
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		pev.velocity = g_vecZero;

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

final class info_cnpc_gman : CNPCSpawnEntity
{
	info_cnpc_gman()
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
		pev.set_controller( 0,  127 );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_gman::info_cnpc_gman", "info_cnpc_gman" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_gman::cnpc_gman", "cnpc_gman" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_gman::weapon_gman", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc" );

	g_Game.PrecacheOther( "info_cnpc_gman" );
	g_Game.PrecacheOther( "cnpc_gman" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_gman END

/* FIXME
*/

/* TODO
*/