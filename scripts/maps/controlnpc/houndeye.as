namespace cnpc_houndeye
{

bool CNPC_FIRSTPERSON					= false;
const bool USE_SPECIAL_EFFECT		= false;
	
const string sWeaponName				= "weapon_houndeye";

const float CNPC_HEALTH					= 60.0;
const float CNPC_VIEWOFS_FPV			= 0.0; //camera height offset
const float CNPC_VIEWOFS_TPV			= 0.0;
const float CNPC_RESPAWNTIME			= 13.0; //from the point that the weapon is removed, not the houndeye itself
const float CNPC_MODEL_OFFSET		= 36.0; //sometimes the model floats above the ground

const float SPEED_WALK						= 40; //35.94265 * CNPC::flModelToGameSpeedModifier; //35.94265 from model, player = 71.196838
const float SPEED_RUN						= -1; //220.556808 * CNPC::flModelToGameSpeedModifier; //220.556808 from model, player = 163.624054
const float VELOCITY_WALK				= 150.0; //if the player's velocity is this or lower, use the walking animation

const float CD_PRIMARY						= 2.0;
const float SONIC_CHARGETIME			= 1.60; //1.23
const float SONIC_DAMAGE					= 15;
const int SONIC_RADIUS						= 384;
const RGBA SONIC_BEAM_COLOR_1	= RGBA(188, 220, 255, 255); //based on number of nearby friendly player houndeyes
const RGBA SONIC_BEAM_COLOR_2	= RGBA(101, 133, 221, 255);
const RGBA SONIC_BEAM_COLOR_3	= RGBA(67, 85, 255, 255);
const RGBA SONIC_BEAM_COLOR_4	= RGBA(62, 33, 211, 255);

const float SQUAD_RADIUS					= 420.0; //friendly player-controlled houndeyes within this range will count as squadmembers (changes color of the sonic beams and increases damage)
const float SQUAD_BONUS					= 1.1;

const float CNPC_JUMPVELOCITY	= 200.0;

const array<string> pPainSounds = 
{
	"houndeye/he_pain3.wav",
	"houndeye/he_pain4.wav",
	"houndeye/he_pain5.wav"
};

const array<string> pDieSounds = 
{
	"houndeye/he_die1.wav",
	"houndeye/he_die2.wav",
	"houndeye/he_die3.wav"
};

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav",
	"houndeye/he_attack1.wav",
	"houndeye/he_attack3.wav",
	"houndeye/he_blast1.wav",
	"houndeye/he_blast2.wav",
	"houndeye/he_blast3.wav"
};

enum sound_e
{
	SND_RESPAWN = 0,
	SND_ATTACK1,
	SND_ATTACK2,
	SND_BLAST1,
	SND_BLAST2,
	SND_BLAST3
};

enum anim_e
{
	ANIM_IDLE = 1,
	ANIM_RUN = 3,
	ANIM_DEATH1 = 6,
	ANIM_DEATH2,
	ANIM_DEATH3,
	ANIM_DEATH4,
	ANIM_ATTACK_SONIC, //10
	ANIM_DEATH5 = 13, //from fall damage??
	ANIM_WALK = 15,
	ANIM_JUMPBACK = 27
};

enum states_e
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_ATTACK_SONIC,
	STATE_JUMPBACK,
	STATE_DEATH
};

class weapon_houndeye : CBaseDriveWeapon
{
	private int m_iSpriteTexture;
	private float m_flSonicAttack;
	private float m_flSpecialEffect;

	void Spawn()
	{
		Precache();

		m_iState = STATE_IDLE;
		m_flSonicAttack = 0.0;
		m_flSpecialEffect = 0.0;

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/houndeye.mdl" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/shockwave.spr" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		for( uint i = 0; i < pPainSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pPainSounds[i] );

		for( uint i = 0; i < pDieSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pDieSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_houndeye.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_houndeye.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_houndeye_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot				= CNPC::HOUNDEYE_SLOT - 1;
		info.iPosition		= CNPC::HOUNDEYE_POSITION - 1;
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
			if( m_iState == STATE_JUMPBACK or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

			m_pPlayer.SetMaxSpeedOverride( 0 );
			m_iState = STATE_ATTACK_SONIC;
			m_pDriveEnt.pev.sequence = ANIM_ATTACK_SONIC;
			m_pDriveEnt.pev.frame = 0;
			m_pDriveEnt.ResetSequenceInfo();

			m_flSonicAttack = g_Engine.time + SONIC_CHARGETIME;
			m_flSpecialEffect = g_Engine.time;

			switch( Math.RandomLong(0, 1) )
			{
				case 0: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATTACK1], 0.7, ATTN_NORM ); break;
				case 1: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATTACK2], 0.7, ATTN_NORM ); break;
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
			cnpc_houndeye@ pDriveEnt = cast<cnpc_houndeye@>(CastToScriptClass(m_pDriveEnt));
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

	void ItemPreFrame()
	{
		if( m_pDriveEnt !is null )
		{
			m_pPlayer.pev.friction = 2; //no sliding!

			if( m_pPlayer.pev.button & (IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) != 0 )
				m_pPlayer.SetMaxSpeedOverride( 0 );
			else if( m_pPlayer.pev.button & IN_FORWARD != 0 and m_iState != STATE_JUMPBACK and m_iState != STATE_ATTACK_SONIC )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
				DoMovementAnimation();
				self.m_flTimeWeaponIdle = g_Engine.time + 0.1;
			}

			DoIdleAnimation();
			JumpBack();
			CheckSonicAttack();
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
		if( m_iState == STATE_JUMPBACK and !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;
		if( m_iState == STATE_ATTACK_SONIC and m_flSonicAttack > 0.0 ) return;

		if( m_pPlayer.pev.velocity.Length() <= 10.0 )
		{
			if( m_iState != STATE_IDLE )
			{
				m_pPlayer.SetMaxSpeedOverride( int(SPEED_RUN) ); //-1
				m_iState = STATE_IDLE;
				m_pDriveEnt.pev.sequence = ANIM_IDLE;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();
			}
		}
	}

	void JumpBack()
	{
		if( m_iState == STATE_JUMPBACK or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( (m_pPlayer.pev.button & IN_BACK) == 0 and (m_pPlayer.pev.oldbuttons & IN_BACK) != 0 )
		{
			if( m_iState == STATE_ATTACK_SONIC )
			{
				g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATTACK1] );
				g_SoundSystem.StopSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_ATTACK2] );
				m_flSonicAttack = 0.0;
			}

			/*will block the jump if there is no space behind, from houndeye.cpp
			TraceResult tr;
			Math.MakeVectors( m_pPlayer.pev.angles );
			g_Utility.TraceHull( m_pPlayer.pev.origin, m_pPlayer.pev.origin + g_Engine.v_forward * -128, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );

			if( tr.flFraction == 1.0 )*/
			{
				m_pPlayer.SetMaxSpeedOverride( 0 );
				m_iState = STATE_JUMPBACK;
				m_pDriveEnt.pev.sequence = ANIM_JUMPBACK;
				m_pDriveEnt.pev.frame = 0;
				m_pDriveEnt.ResetSequenceInfo();

				Math.MakeAimVectors( m_pPlayer.pev.angles );
				g_EntityFuncs.SetOrigin( m_pPlayer, m_pPlayer.pev.origin + Vector(0, 0, 1) );

				float flGravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );

				m_pPlayer.pev.velocity = g_Engine.v_forward * -CNPC_JUMPVELOCITY;
				m_pPlayer.pev.velocity.z += (0.6 * flGravity) * 0.5;
			}
		}
	}

	void CheckSonicAttack()
	{
		if( m_iState != STATE_ATTACK_SONIC or !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) ) return;

		if( m_flSonicAttack > 0.0 and m_flSonicAttack <= g_Engine.time )
		{
			DoSonicAttack();
			DoIdleAnimation();
			m_flSonicAttack = 0.0;
			m_flSpecialEffect = 0.0;
			m_pDriveEnt.pev.skin = 0; //back to eye fully open
		}

		if( USE_SPECIAL_EFFECT )
		{
			if( m_pDriveEnt.pev.sequence == ANIM_ATTACK_SONIC )
			{
				if( m_flSpecialEffect > 0.0 and m_flSpecialEffect <= g_Engine.time )
				{
					DoSpecialEffect();
					m_flSpecialEffect = g_Engine.time + 0.1;
				}
			}
		}
	}

	//from houndeye.cpp
	RGBA GetBeamColor()
	{
		uint8 bRed, bGreen, bBlue;

		if( InSquad() )
		{
			switch( SquadCount() )
			{
			case 2:
				// no case for 0 or 1, cause those are impossible for monsters in Squads.
				bRed		= SONIC_BEAM_COLOR_2.r;
				bGreen	= SONIC_BEAM_COLOR_2.g;
				bBlue		= SONIC_BEAM_COLOR_2.b;
				break;
			case 3:
				bRed		= SONIC_BEAM_COLOR_3.r;
				bGreen	= SONIC_BEAM_COLOR_3.g;
				bBlue		= SONIC_BEAM_COLOR_3.b;
				break;
			case 4:
				bRed		= SONIC_BEAM_COLOR_4.r;
				bGreen	= SONIC_BEAM_COLOR_4.g;
				bBlue		= SONIC_BEAM_COLOR_4.b;
				break;
			default:
				//g_Game.AlertMessage( at_aiconsole, "Unsupported Houndeye SquadSize!\n" );
				bRed		= SONIC_BEAM_COLOR_1.r;
				bGreen	= SONIC_BEAM_COLOR_1.g;
				bBlue		= SONIC_BEAM_COLOR_1.b;
				break;
			}
		}
		else
		{
			// solo houndeye - weakest beam
			bRed	= SONIC_BEAM_COLOR_1.r;
			bGreen	= SONIC_BEAM_COLOR_1.g;
			bBlue	= SONIC_BEAM_COLOR_1.b;
		}

		return RGBA( bRed, bGreen, bBlue, 255 );
	}

	void DoSonicAttack()
	{
		float flAdjustedDamage;
		float flDist;

		switch( Math.RandomLong(0, 2) )
		{
			case 0: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, "houndeye/he_blast1.wav", VOL_NORM, ATTN_NORM ); break;
			case 1: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, "houndeye/he_blast2.wav", VOL_NORM, ATTN_NORM ); break;
			case 2: g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, "houndeye/he_blast3.wav", VOL_NORM, ATTN_NORM ); break;
		}

		// blast circles
		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, m_pDriveEnt.pev.origin );
			m1.WriteByte( TE_BEAMCYLINDER );
			m1.WriteCoord( m_pDriveEnt.pev.origin.x );
			m1.WriteCoord( m_pDriveEnt.pev.origin.y );
			m1.WriteCoord( m_pDriveEnt.pev.origin.z + 16 );
			m1.WriteCoord( m_pDriveEnt.pev.origin.x );
			m1.WriteCoord( m_pDriveEnt.pev.origin.y );
			m1.WriteCoord( m_pDriveEnt.pev.origin.z + 16 + SONIC_RADIUS / .2); // reach damage radius over .3 seconds
			m1.WriteShort( m_iSpriteTexture );
			m1.WriteByte( 0 ); // startframe
			m1.WriteByte( 0 ); // framerate
			m1.WriteByte( 2 ); // life
			m1.WriteByte( 16 );  // width
			m1.WriteByte( 0 );   // noise
			m1.WriteByte( GetBeamColor().r );   // r, g, b
			m1.WriteByte( GetBeamColor().g );   // r, g, b
			m1.WriteByte( GetBeamColor().b );   // r, g, b
			m1.WriteByte( GetBeamColor().a ); // brightness
			m1.WriteByte( 0 );		// speed
		m1.End();

		NetworkMessage m2( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, m_pDriveEnt.pev.origin );
			m2.WriteByte( TE_BEAMCYLINDER );
			m2.WriteCoord( m_pDriveEnt.pev.origin.x );
			m2.WriteCoord( m_pDriveEnt.pev.origin.y );
			m2.WriteCoord( m_pDriveEnt.pev.origin.z + 16 );
			m2.WriteCoord( m_pDriveEnt.pev.origin.x );
			m2.WriteCoord( m_pDriveEnt.pev.origin.y );
			m2.WriteCoord( m_pDriveEnt.pev.origin.z + 16 + ( SONIC_RADIUS / 2 ) / .2); // reach damage radius over .3 seconds
			m2.WriteShort( m_iSpriteTexture );
			m2.WriteByte( 0 ); // startframe
			m2.WriteByte( 0 ); // framerate
			m2.WriteByte( 2 ); // life
			m2.WriteByte( 16 );  // width
			m2.WriteByte( 0 );   // noise
			m2.WriteByte( GetBeamColor().r );   // r, g, b
			m2.WriteByte( GetBeamColor().g );   // r, g, b
			m2.WriteByte( GetBeamColor().b );   // r, g, b
			m2.WriteByte( GetBeamColor().a ); // brightness
			m2.WriteByte( 0 );		// speed
		m2.End();

		CBaseEntity@ pEntity = null;
		while( (@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, m_pPlayer.pev.origin, SONIC_RADIUS, "*", "classname")) !is null )
		{
			if( pEntity.pev.takedamage != DAMAGE_NO and pEntity.edict() !is m_pPlayer.edict() )
			{
				if( !pEntity.pev.ClassNameIs("monster_houndeye") )
				{// houndeyes don't hurt other houndeyes with their attack

					// houndeyes do FULL damage if the ent in question is visible. Half damage otherwise.
					// This means that you must get out of the houndeye's attack range entirely to avoid damage.
					// Calculate full damage first

					if( SquadCount() > 1 )
						flAdjustedDamage = SONIC_DAMAGE + SONIC_DAMAGE * ( SQUAD_BONUS * (SquadCount() - 1) );
					else
						flAdjustedDamage = SONIC_DAMAGE;

					flDist = (pEntity.Center() - m_pPlayer.pev.origin).Length();

					flAdjustedDamage -= ( flDist / SONIC_RADIUS ) * flAdjustedDamage;

					if( !m_pPlayer.FVisible(pEntity, true) )
					{
						if( pEntity.IsPlayer() )
						{
							// if this entity is a client, and is not in full view, inflict half damage. We do this so that players still 
							// take the residual damage if they don't totally leave the houndeye's effective radius. We restrict it to clients
							// so that monsters in other parts of the level don't take the damage and get pissed.
							flAdjustedDamage *= 0.5;
						}
						else if( !pEntity.pev.ClassNameIs("func_breakable") and !pEntity.pev.ClassNameIs("func_pushable") ) 
						{
							// do not hurt nonclients through walls, but allow damage to be done to breakables
							flAdjustedDamage = 0;
						}
					}

					if( flAdjustedDamage > 0 )
						pEntity.TakeDamage( m_pPlayer.pev, m_pPlayer.pev, flAdjustedDamage, DMG_SONIC | DMG_ALWAYSGIB );
				}
			}
		}
	}

	void DoSpecialEffect()
	{
		m_pDriveEnt.pev.skin = Math.RandomLong( 0, 2 );

		//MakeIdealYaw( m_vecEnemyLKP );
		//ChangeYaw( pev.yaw_speed );
		
		float life;
		life = ((255 - m_pDriveEnt.pev.frame) / (m_pDriveEnt.pev.framerate * m_pDriveEnt.m_flFrameRate));
		if( life < 0.1 ) life = 0.1;

		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, m_pDriveEnt.pev.origin );
			m1.WriteByte( TE_IMPLOSION );
			m1.WriteCoord( m_pDriveEnt.pev.origin.x );
			m1.WriteCoord( m_pDriveEnt.pev.origin.y );
			m1.WriteCoord( m_pDriveEnt.pev.origin.z + 16 );
			m1.WriteByte( int(50 * life + 100) ); // radius
			m1.WriteByte( int(m_pDriveEnt.pev.frame / 25.0) ); // count
			m1.WriteByte( int(life * 10) ); // life
		m1.End();
	}

	bool InSquad()
	{
		return SquadCount() > 1;
		//return m_hSquadLeader !is null;
	}

	/*bool IsLeader()
	{
		return m_hSquadLeader == this;
	}*/

	int SquadCount()
	{
		int iSquadCount = 1;

		CBasePlayer@ pPlayer = null;
		for( int i = 1; i <= g_Engine.maxClients; ++i )
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );

			if( pPlayer is null ) continue;
			if( pPlayer is m_pPlayer ) continue;
			if( !pPlayer.IsAlive() ) continue;
			if( (m_pPlayer.pev.origin - pPlayer.pev.origin).Length() > SQUAD_RADIUS ) continue;
			if( pPlayer.Classify() != m_pPlayer.Classify() ) continue; //hacky isFriendly check

			CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
			if( pCustom.GetKeyvalue(CNPC::sCNPCKV).GetInteger() == CNPC::CNPC_HOUNDEYE )
				iSquadCount++;
		}

		return iSquadCount;
	}

	void spawn_driveent()
	{
		if( !m_pPlayer.pev.FlagBitSet(FL_ONGROUND) and m_iAutoDeploy == 0 )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Unable to deploy\nwhile in the air" );
			return;
		}

		m_pPlayer.pev.velocity = g_vecZero;
		Vector vecOrigin = m_pPlayer.pev.origin;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_houndeye", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), true, m_pPlayer.edict()) );

		g_EntityFuncs.DispatchSpawn( m_pDriveEnt.edict() );

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.fuser4 = 1; //disable jump
		m_pPlayer.pev.max_health = CNPC_HEALTH;
		m_pPlayer.pev.health = CNPC_HEALTH;
		m_pPlayer.m_bloodColor = BLOOD_COLOR_YELLOW;

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
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_HOUNDEYE );
	}

	void DoFirstPersonView()
	{
		cnpc_houndeye@ pDriveEnt = cast<cnpc_houndeye@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_houndeye_pid_" + m_pPlayer.entindex();
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

class cnpc_houndeye : ScriptBaseAnimating
{
	EHandle m_hRenderEntity;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/houndeye.mdl" );
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
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			pev.velocity = g_vecZero;
			SetThink( ThinkFunction(this.DieThink) );
			pev.nextthink = g_Engine.time;

			return;
		}

		CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		Vector vecOrigin = pOwner.pev.origin;
		vecOrigin.z -= CNPC_MODEL_OFFSET;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.velocity = pOwner.pev.velocity;

		pev.angles.x = 0;
		pev.angles.y = pOwner.pev.angles.y;
		pev.angles.z = 0;

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DieThink()
	{
		pev.sequence = Math.RandomLong( ANIM_DEATH1, ANIM_DEATH4 );
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

class info_cnpc_houndeye : ScriptBaseAnimating
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
		g_EntityFuncs.SetModel( self, "models/houndeye.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 36) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_EngineFuncs.DropToFloor( self.edict() );

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;
		pev.sequence = ANIM_IDLE;
		pev.rendermode = kRenderTransTexture;
		pev.renderfx = kRenderFxDistort;
		pev.renderamt = 128;

		if( m_flRespawnTime <= 0 ) m_flRespawnTime = CNPC_RESPAWNTIME;

		SetUse( UseFunction(this.UseCNPC) );
	}

	int ObjectCaps() { return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE); }

	void UseCNPC( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue  ) 
	{
		if( pActivator.pev.FlagBitSet(FL_CLIENT) and pActivator.pev.FlagBitSet(FL_ONGROUND) )
		{
			g_EntityFuncs.SetOrigin( pActivator, pev.origin );
			pActivator.pev.angles = pev.angles;
			pActivator.pev.fixangle = FAM_FORCEVIEWANGLES;
			@m_pCNPCWeapon = g_EntityFuncs.Create( sWeaponName, pActivator.pev.origin, g_vecZero, true );
			m_pCNPCWeapon.pev.spawnflags = SF_NORESPAWN | SF_CREATEDWEAPON;

			g_EntityFuncs.DispatchKeyValue( m_pCNPCWeapon.edict(), "autodeploy", "1" );
			g_EntityFuncs.DispatchSpawn( m_pCNPCWeapon.edict() );

			SetUse( null );
			pev.effects |= EF_NODRAW;

			SetThink( ThinkFunction(this.RespawnThink) );
			pev.nextthink = g_Engine.time;
		}
	}

	void RespawnThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( m_pCNPCWeapon is null and m_flTimeToRespawn <= 0.0 )
			m_flTimeToRespawn = g_Engine.time +m_flRespawnTime;

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
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_houndeye::info_cnpc_houndeye", "info_cnpc_houndeye" );
	g_Game.PrecacheOther( "info_cnpc_houndeye" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_houndeye::cnpc_houndeye", "cnpc_houndeye" );
	g_Game.PrecacheOther( "cnpc_houndeye" );

	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_houndeye::weapon_houndeye", sWeaponName );
	g_ItemRegistry.RegisterWeapon( sWeaponName, "controlnpc" );
	g_Game.PrecacheOther( sWeaponName );
}

} //namespace cnpc_houndeye END

/* FIXME
*/

/* TODO
	Make friendly NPC houndeyes a part of the squad??
*/