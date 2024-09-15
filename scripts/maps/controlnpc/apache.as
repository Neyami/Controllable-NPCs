namespace cnpc_apache
{

const bool CNPC_ROCKETS					= true; // Set false/true to disable/enable rocket launchers
bool CNPC_FIRSTPERSON					= false;

const string CNPC_WEAPONNAME		= "weapon_apache";
const string CNPC_MODEL					= "models/apache.mdl";
const Vector CNPC_SIZEMIN				= Vector( -80, -80, -140 );
const Vector CNPC_SIZEMAX				= Vector( 80, 80, 0 );

const float CNPC_HEALTH					= 500.0;
const float CNPC_VIEWOFS_FPV			= -28.0; //camera height offset
const float CNPC_VIEWOFS_TPV			= 28.0;
const float CNPC_RESPAWNTIME			= 13.0; //from the point that the weapon is removed, not the apache itself
const float CNPC_MODEL_OFFSET		= 140.0; //sometimes the model floats above the ground

const float CD_GUN							= 0.1;
const float DAMAGE_GUN					= 12; //sk_12mm_bullet

const float CD_ROCKETS					= 1.0; //8.0
const int ROCKET_AMOUNT					= 4; //per volley
const float ROCKET_REFIRE				= 0.3; //time between each rocket getting launched in a volley
const int ROCKET_REGEN_AMOUNT		= 1;
const float ROCKET_REGEN_RATE		= 1.0; //+ROCKET_REGEN_AMOUNT per ROCKET_REGEN_RATE seconds
const float ROCKET_DAMAGE				= 150.0;
const string ROCKET_MODEL				= "models/HVR.mdl";

const float FLY_ACCEL_FORWARD		= 300.0;
const float FLY_ACCEL_BACK				= 240.0;
const float FLY_ACCEL_SIDE				= 260.0;
const float FLY_ACCEL_UP					= 150.0;
const float FLY_ACCEL_DOWN				= 200.0;
const float FLY_MAXSPEED_FORWARD	= 500.0;
const float FLY_MAXSPEED_BACK		= 320.0;
const float FLY_MAXSPEED_SIDE			= 300.0;
const float FLY_MAXSPEED_UP			= 230.0;
const float FLY_MAXSPEED_DOWN		= 250.0;
const float FLY_DECEL_FORWARD		= 240.0;
const float FLY_DECEL_UP					= 200.0;
const float FLY_DECEL_BACK				= 190.0;
const float FLY_DECEL_DOWN				= 150.0;
const float FLY_DECEL_SIDE				= 200.0;

const string SPRITE_SMOKE				= "sprites/steam1.spr";
const string SPRITE_FIREBALL			= "sprites/zerogxplode.spr";
const string SPRITE_WATEREXP			= "sprites/WXplo1.spr";
const string SPRITE_EXPLODE				= "sprites/fexplo.spr";
const string SPRITE_BEAMCYLINDER	= "sprites/white.spr";
const string MODEL_GIBS					= "models/metalplategibs_green.mdl";
const float CRASH_DAMAGE				= 300.0;
const float CRASH_RADIUS					= 750.0;

const array<string> arrsCNPCSounds = 
{
	"ambience/particle_suck1.wav", //only here for the precache
	"apache/ap_rotor2.wav",
	"apache/ap_whine1.wav",
	"weapons/mortarhit.wav",
	"turret/tu_fire1.wav"
};

enum sound_e
{
	SND_ROTOR = 1,
	SND_WHINE,
	SND_EXPLODE,
	SND_GUN
};

class weapon_apache : CBaseDriveWeapon
{
	private bool m_bMoveForward;
	private bool m_bMoveBack;
	private bool m_bMoveLeft;
	private bool m_bMoveRight;
	private bool m_bMoveUp;
	private bool m_bMoveDown;
	private float m_flForwardSpeed;
	private float m_flSideSpeed;
	private float m_flVerticalSpeed;
	private float m_flSpeedModifier;
	private float m_flAnglesPitch;
	private float m_flAnglesYaw;
	private float m_flGunX, m_flGunY;
	private int m_iFlareSprite, m_iSmokeSprite;
	private bool m_bFireRockets;
	private float m_flNextRocket;
	private float m_flNextRocketRegen;
	private float m_flSide;
	private int m_iDoSmokePuff;
	private int m_iSoundState;

	void Spawn()
	{
		Precache();

		m_flSpeedModifier = 0.1; //0.01 ??
		m_bFireRockets = false;
		m_flSide = 1.0;

		self.FallInit(); //needed??
	}

	void Precache()
	{
		g_Game.PrecacheModel( CNPC_MODEL );
		m_iFlareSprite = g_Game.PrecacheModel( "sprites/flare4.spr" );
		m_iSmokeSprite = g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_FIREBALL );
		g_Game.PrecacheModel( SPRITE_SMOKE );
		g_Game.PrecacheModel( SPRITE_EXPLODE );
		g_Game.PrecacheModel( SPRITE_BEAMCYLINDER );
		g_Game.PrecacheModel( MODEL_GIBS );

		g_Game.PrecacheOther( "cnpc_hvr_rocket" );

		for( uint i = 0; i < arrsCNPCSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( arrsCNPCSounds[i] );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/controlnpc/weapon_apache.txt" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_apache.spr" );
		g_Game.PrecacheGeneric( "sprites/controlnpc/ui_apache_sel.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= ROCKET_AMOUNT;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= CNPC::APACHE_SLOT - 1;
		info.iPosition			= CNPC::APACHE_POSITION - 1;
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

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, ROCKET_AMOUNT );

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
			FireGun();
		}
		else
		{
			spawnDriveEnt();
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5;

			return;
		}

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + CD_GUN;
	}

	void SecondaryAttack()
	{
		if( m_pDriveEnt !is null )
		{
			if( CNPC_ROCKETS )
			{
				if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) == ROCKET_AMOUNT )
				{
					m_bFireRockets = true;
					self.m_flNextSecondaryAttack = g_Engine.time + CD_ROCKETS;

					return;
				}
			}
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
			cnpc_apache@ pDriveEnt = cast<cnpc_apache@>(CastToScriptClass(m_pDriveEnt));
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
			CheckInput();
			DoRocketRegen();

			if( m_flNextThink <= g_Engine.time )
			{
				ShowDamage();
				DoControl();
				DoFlight();
				UpdateGun();
				DoRockets();

				m_flNextThink = g_Engine.time + 0.01;
			}
		}
	}

	void CheckInput()
	{
		m_flAnglesPitch = -m_pPlayer.pev.v_angle.x;
		m_flAnglesYaw = m_pPlayer.pev.v_angle.y;

		m_pPlayer.pev.effects |= EF_NODRAW;
		Math.MakeVectors( m_pPlayer.pev.v_angle );

		g_EntityFuncs.SetOrigin( m_pPlayer, m_pDriveEnt.pev.origin );
		m_pPlayer.pev.velocity = m_pDriveEnt.pev.velocity;

		if( (m_pPlayer.pev.button & IN_FORWARD) != 0 )
		{
			m_bMoveForward = true;
			m_bMoveBack = false;
		}
		else if( (m_pPlayer.pev.button & IN_BACK) != 0 )
		{
			m_bMoveForward = false;
			m_bMoveBack = true;
		}

		if( (m_pPlayer.pev.button & IN_JUMP) != 0 )
		{
			m_bMoveUp = true;
			m_bMoveDown = false;
		}
		else if( (m_pPlayer.pev.button & IN_DUCK) != 0 )
		{
			m_bMoveUp = false;
			m_bMoveDown = true;
		}

		if( (m_pPlayer.pev.button & IN_MOVELEFT) != 0 )
		{
			m_bMoveLeft = true;
			m_bMoveRight = false;
		}
		else if( (m_pPlayer.pev.button & IN_MOVERIGHT) != 0 )
		{
			m_bMoveLeft = false;
			m_bMoveRight = true;
		}

		if( (m_pPlayer.pev.button & IN_FORWARD) == 0 )
			m_bMoveForward = false;

		if( (m_pPlayer.pev.button & IN_BACK) == 0 )
			m_bMoveBack = false;

		if( (m_pPlayer.pev.button & IN_JUMP) == 0 )
			m_bMoveUp = false;

		if( (m_pPlayer.pev.button & IN_DUCK) == 0 )
			m_bMoveDown = false;

		if( (m_pPlayer.pev.button & IN_MOVELEFT) == 0 )
			m_bMoveLeft = false;

		if( (m_pPlayer.pev.button & IN_MOVERIGHT) == 0 )
			m_bMoveRight = false;
	}

	void ShowDamage()
	{
		if( m_pDriveEnt.pev.dmg > 0 )
		{
			m_iDoSmokePuff = int(m_pDriveEnt.pev.dmg);
			m_pDriveEnt.pev.dmg = 0;
		}

		if( m_iDoSmokePuff > 0 or Math.RandomLong(0, 99) > m_pPlayer.pev.health )
		{
			NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, m_pDriveEnt.pev.origin );
				m1.WriteByte( TE_SMOKE );
				m1.WriteCoord( m_pDriveEnt.pev.origin.x );
				m1.WriteCoord( m_pDriveEnt.pev.origin.y );
				m1.WriteCoord( m_pDriveEnt.pev.origin.z - 32 );
				m1.WriteShort( m_iSmokeSprite );
				m1.WriteByte( Math.RandomLong(0, 9) + 20 ); // scale * 10
				m1.WriteByte( 12 ); // framerate
			m1.End();
		}

		if( m_iDoSmokePuff > 0 )
			m_iDoSmokePuff--;
	}

	void DoControl()
	{
		if( m_bMoveForward )
		{
			if( m_flForwardSpeed < FLY_MAXSPEED_FORWARD )
				m_flForwardSpeed = m_flForwardSpeed + FLY_ACCEL_FORWARD * m_flSpeedModifier;
			else if( m_flForwardSpeed > FLY_MAXSPEED_FORWARD )
				m_flForwardSpeed = FLY_MAXSPEED_FORWARD;
		}
		else if( m_bMoveBack )
		{
			if( m_flForwardSpeed > -FLY_MAXSPEED_BACK )
				m_flForwardSpeed = m_flForwardSpeed - FLY_ACCEL_BACK * m_flSpeedModifier;
			else if( m_flForwardSpeed < -FLY_MAXSPEED_BACK )
				m_flForwardSpeed = -FLY_MAXSPEED_BACK;
		}
		else
		{
			if( m_flForwardSpeed < 0.0 )
			{
				if( m_flForwardSpeed + FLY_DECEL_BACK * m_flSpeedModifier <= 0.0 )
					m_flForwardSpeed = m_flForwardSpeed + FLY_DECEL_BACK * m_flSpeedModifier;
				else
					m_flForwardSpeed = 0.0;
			}
			else if( m_flForwardSpeed > 0.0 )
			{
				if( m_flForwardSpeed - FLY_DECEL_FORWARD * m_flSpeedModifier <= 0.0 )
					m_flForwardSpeed = m_flForwardSpeed - FLY_DECEL_FORWARD * m_flSpeedModifier;
				else
					m_flForwardSpeed = 0.0;
			}
		}

		if( m_bMoveRight )
		{
			if( m_flSideSpeed < FLY_MAXSPEED_SIDE )
				m_flSideSpeed = m_flSideSpeed + FLY_ACCEL_SIDE * m_flSpeedModifier;
			else if( m_flSideSpeed > FLY_MAXSPEED_SIDE )
				m_flSideSpeed = FLY_MAXSPEED_SIDE;
		}
		else if( m_bMoveLeft )
		{
			if( m_flSideSpeed > -FLY_MAXSPEED_SIDE )
				m_flSideSpeed = m_flSideSpeed - FLY_ACCEL_SIDE * m_flSpeedModifier;
			else if( m_flSideSpeed < -FLY_MAXSPEED_SIDE )
				m_flSideSpeed = -FLY_MAXSPEED_SIDE;
		}
		else
		{
			if( m_flSideSpeed < 0.0 )
			{
				if( m_flSideSpeed + FLY_DECEL_SIDE * m_flSpeedModifier <= 0.0 )
					m_flSideSpeed = m_flSideSpeed + FLY_DECEL_SIDE * m_flSpeedModifier;
				else
					m_flSideSpeed = 0.0;
			}
			else if( m_flSideSpeed > 0.0 )
			{
				if( m_flSideSpeed - FLY_DECEL_SIDE * m_flSpeedModifier <= 0.0 )
					m_flSideSpeed = m_flSideSpeed - FLY_DECEL_SIDE * m_flSpeedModifier;
				else
					m_flSideSpeed = 0.0;
			}
		}

		if( m_bMoveUp )
		{
			if( m_flVerticalSpeed < FLY_MAXSPEED_UP )
				m_flVerticalSpeed = m_flVerticalSpeed + FLY_ACCEL_UP * m_flSpeedModifier;
			else if( m_flVerticalSpeed > FLY_MAXSPEED_UP )
				m_flVerticalSpeed = FLY_MAXSPEED_UP;
		}
		else if( m_bMoveDown )
		{
			if( m_flVerticalSpeed > -FLY_MAXSPEED_DOWN )
				m_flVerticalSpeed = m_flVerticalSpeed - FLY_ACCEL_DOWN * m_flSpeedModifier;
			else if( m_flVerticalSpeed < -FLY_MAXSPEED_DOWN )
				m_flVerticalSpeed = -FLY_MAXSPEED_DOWN;
		}
		else
		{
			if( m_flVerticalSpeed < 0.0 )
			{
				if( m_flVerticalSpeed + FLY_DECEL_DOWN * m_flSpeedModifier <= 0.0 )
					m_flVerticalSpeed = m_flVerticalSpeed + FLY_DECEL_DOWN * m_flSpeedModifier;
				else
					m_flVerticalSpeed = 0.0;
			}
			else if( m_flVerticalSpeed > 0.0 )
			{
				if( m_flVerticalSpeed - FLY_DECEL_UP * m_flSpeedModifier <= 0.0 )
					m_flVerticalSpeed = m_flVerticalSpeed - FLY_DECEL_UP * m_flSpeedModifier;
				else
					m_flVerticalSpeed = 0.0;
			}
		}

		if( abs(m_flVerticalSpeed) <= 0.0 )
			m_pDriveEnt.pev.velocity.z = m_pDriveEnt.pev.velocity.z * 0.98;
		else
			m_pDriveEnt.pev.velocity.z = m_pDriveEnt.pev.velocity.z * 0.5 + m_flVerticalSpeed * 0.5;

		if( abs(m_flForwardSpeed) <= 0.0 and abs(m_flSideSpeed) <= 0.0 )
		{
			m_pDriveEnt.pev.velocity.x = m_pDriveEnt.pev.velocity.x * 0.98;
			m_pDriveEnt.pev.velocity.y = m_pDriveEnt.pev.velocity.y * 0.98;
		}
		else
		{
			Math.MakeVectors( m_pDriveEnt.pev.angles );

			m_pDriveEnt.pev.velocity.x = m_pDriveEnt.pev.velocity.x * 0.5 + m_flForwardSpeed * g_Engine.v_forward.x * 0.5 + m_flSideSpeed * g_Engine.v_right.x * 0.5;
			m_pDriveEnt.pev.velocity.y = m_pDriveEnt.pev.velocity.y * 0.5 + m_flForwardSpeed * g_Engine.v_forward.y * 0.5 + m_flSideSpeed * g_Engine.v_right.y * 0.5;
		}
	}

	void DoFlight()
	{
		//Yaw: will slowly turn the helicopter in the direction the player is aiming
		Math.MakeAimVectors( m_pDriveEnt.pev.angles + m_pDriveEnt.pev.avelocity * 0.5 );

		Vector vecDesiredPos;
		g_EngineFuncs.AngleVectors( m_pPlayer.pev.v_angle, vecDesiredPos, void, void );
		float flSide = DotProduct( vecDesiredPos, g_Engine.v_right );

		if( flSide < 0 )
		{
			if( m_pDriveEnt.pev.avelocity.y < 60 )
				m_pDriveEnt.pev.avelocity.y += 8;
		}
		else
		{
			if( m_pDriveEnt.pev.avelocity.y > -60 )
				m_pDriveEnt.pev.avelocity.y -= 8;
		}

		m_pDriveEnt.pev.avelocity.y *= 0.98;

		//Pitch: moving forward tilts the heli forward, moving back tilts it back
		if( m_bMoveForward and m_flForwardSpeed > 0.0 )
		{
			if( m_pDriveEnt.pev.angles.x > -40 )
				m_pDriveEnt.pev.avelocity.x -= (m_flForwardSpeed * 0.01);
			else
				m_pDriveEnt.pev.avelocity.x = 0.0;
		}
		else if( m_bMoveBack and m_flForwardSpeed < 0.0 )
		{
			if( m_pDriveEnt.pev.angles.x < 30 )
				m_pDriveEnt.pev.avelocity.x += -(m_flForwardSpeed * 0.01);
			else
				m_pDriveEnt.pev.avelocity.x = 0.0;
		}
		else
		{
			float flPitch = DotProduct( vecDesiredPos, g_Engine.v_up );

			if( flPitch > 0 )
			{
				if( m_pDriveEnt.pev.angles.x < 30 )
				{
					if( m_pDriveEnt.pev.avelocity.x < 60 )
						m_pDriveEnt.pev.avelocity.x += 8;
				}
				else
					m_pDriveEnt.pev.avelocity.x = 0.0;
			}
			else
			{
				if( m_pDriveEnt.pev.angles.x > -40 )
				{
					if( m_pDriveEnt.pev.avelocity.x > -60 )
						m_pDriveEnt.pev.avelocity.x -= 8;
				}
				else
					m_pDriveEnt.pev.avelocity.x = 0.0;
			}
		}

		m_pDriveEnt.pev.avelocity.x *= 0.98;

		//Roll: strafing left tilts the heli to the right, strafing right tilts it to the right
		/*if( m_bMoveRight ) //and m_flSideSpeed > 0.0
		{
			if( m_pDriveEnt.pev.angles.z < 30 )
				m_pDriveEnt.pev.avelocity.z += (m_flSideSpeed * 0.01);
			else
				m_pDriveEnt.pev.avelocity.z = 0.0;
		}
		else if( m_bMoveLeft ) //and m_flSideSpeed < 0.0
		{
			if( m_pDriveEnt.pev.angles.z > -30 )
				m_pDriveEnt.pev.avelocity.z += (m_flSideSpeed * 0.01);
			else
				m_pDriveEnt.pev.avelocity.z = 0.0;
		}
		else
		{
			if( m_pDriveEnt.pev.angles.z > 1.0 )
				m_pDriveEnt.pev.avelocity.z -= 1.9;
			else if( m_pDriveEnt.pev.angles.z < -1.0 )
				m_pDriveEnt.pev.avelocity.z += 1.9;
			else
			{
				m_pDriveEnt.pev.avelocity.z = 0.0;
				m_pDriveEnt.pev.angles.z = 0.0;
			}
		}

		m_pDriveEnt.pev.avelocity.z *= 0.98;*/

		// make rotor, engine sounds
		if( m_iSoundState == 0 )
		{
			g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_ROTOR], VOL_NORM, 0.3, 0, 110 );
			//g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_WHINE], 0.5, 0.2, 0, 110 );

			m_iSoundState = SND_CHANGE_PITCH;
		}
		else
		{
			CBaseEntity@ pPlayer = null;

			@pPlayer = g_EntityFuncs.FindEntityByClassname( null, "player" );
			// UNDONE: this needs to send different sounds to every player for multiplayer.	
			if( pPlayer !is null )
			{
				float pitch = DotProduct( m_pDriveEnt.pev.velocity - pPlayer.pev.velocity, (pPlayer.pev.origin - m_pDriveEnt.pev.origin).Normalize() );

				pitch = int(100 + pitch / 50.0);

				if( pitch > 250 )
					pitch = 250;
				if( pitch < 50 )
					pitch = 50;
				if( pitch == 100 )
					pitch = 101;

				float flVol = (30 / 100.0) + 0.1;
				if( flVol > 1.0 )
					flVol = 1.0;

				g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_ROTOR], VOL_NORM, 0.3, SND_CHANGE_PITCH | SND_CHANGE_VOL, int(pitch) );
			}

			//g_SoundSystem.EmitSoundDyn( m_pDriveEnt.edict(), CHAN_STATIC, arrsCNPCSounds[SND_WHINE], flVol, 0.2, SND_CHANGE_PITCH | SND_CHANGE_VOL, int(pitch) );

			//g_Game.AlertMessage( at_notice, "pitch: %1, flVol: %2\n", pitch, flVol );
		}
	}

	void UpdateGun()
	{
		m_pDriveEnt.SetBoneController( 0, m_pPlayer.pev.v_angle.y - m_pDriveEnt.pev.angles.y );
		m_pDriveEnt.SetBoneController( 1, m_pPlayer.pev.v_angle.x + m_pDriveEnt.pev.angles.x );
	}

	void FireGun()
	{
		Vector posBarrel, posGun;
		m_pDriveEnt.GetAttachment( 0, posBarrel, void );
		m_pDriveEnt.GetAttachment( 1, posGun, void );
		Vector vecGun = (posBarrel - posGun).Normalize( );

		self.FireBullets( 1, posGun, vecGun, VECTOR_CONE_4DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 1, DAMAGE_GUN, m_pPlayer.pev );
		g_SoundSystem.EmitSound( m_pDriveEnt.edict(), CHAN_WEAPON, arrsCNPCSounds[SND_GUN], VOL_NORM, 0.3 );

		//Muzzleflash
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, posBarrel );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( posBarrel.x );
			m1.WriteCoord( posBarrel.y );
			m1.WriteCoord( posBarrel.z - 10.0 );
			m1.WriteShort( m_iFlareSprite );
			m1.WriteByte( 5 ); //scale
			m1.WriteByte( 50 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES ); //te_explflags
		m1.End();
	}

	void DoRockets()
	{
		if( !m_bFireRockets ) return;

		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > 0 )
		{
			if( m_flNextRocket < g_Engine.time )
			{
				FireRocket();
				m_flNextRocket = g_Engine.time + ROCKET_REFIRE;
				m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) - 1 );
			}
		}
		else
		{
			m_bFireRockets = false;
			m_flNextRocketRegen = g_Engine.time + 1.0;
		}
	}

	void FireRocket()
	{
		int count;

		Math.MakeAimVectors( m_pDriveEnt.pev.angles );
		Vector vecSrc = m_pDriveEnt.pev.origin + 1.5 * (g_Engine.v_forward * 21 + g_Engine.v_right * 70 * m_flSide + g_Engine.v_up * -79);

		switch( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) % 5 )
		{
			case 0:	vecSrc = vecSrc + g_Engine.v_right * 10; break;
			case 1: vecSrc = vecSrc - g_Engine.v_right * 10; break;
			case 2: vecSrc = vecSrc + g_Engine.v_up * 10; break;
			case 3: vecSrc = vecSrc - g_Engine.v_up * 10; break;
			case 4: break;
		}

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
			m1.WriteByte( TE_SMOKE );
			m1.WriteCoord( vecSrc.x );
			m1.WriteCoord( vecSrc.y );
			m1.WriteCoord( vecSrc.z );
			m1.WriteShort( m_iSmokeSprite );
			m1.WriteByte( 20 ); // scale * 10
			m1.WriteByte( 12 ); // framerate
		m1.End();

		CBaseEntity@ pRocket = g_EntityFuncs.Create( "cnpc_hvr_rocket", vecSrc, m_pDriveEnt.pev.angles, false, m_pPlayer.edict() );
		if( pRocket !is null )
			pRocket.pev.velocity = g_Engine.v_forward * 100;
			//pRocket.pev.velocity = m_pDriveEnt.pev.velocity + g_Engine.v_forward * 100;

		m_flSide = -m_flSide;
	}

	void DoRocketRegen()
	{
		if( (m_iSpawnFlags & CNPC::FL_INFINITEAMMO) != 0 ) return;

		if( !m_bFireRockets and m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) < ROCKET_AMOUNT )
		{
			if( m_flNextRocketRegen < g_Engine.time )
			{
				m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) + ROCKET_REGEN_AMOUNT );
				if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) > ROCKET_AMOUNT )
					m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, ROCKET_AMOUNT );

				m_flNextRocketRegen = g_Engine.time + ROCKET_REGEN_RATE;
			}
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

		vecOrigin.z += CNPC_MODEL_OFFSET;

		@m_pDriveEnt = cast<CBaseAnimating@>( g_EntityFuncs.Create("cnpc_apache", vecOrigin, Vector(0, m_pPlayer.pev.angles.y, 0), false, m_pPlayer.edict()) );

		if( m_pDriveEnt !is null )
		{
			g_EntityFuncs.DispatchKeyValue( m_pDriveEnt.edict(), "m_iSpawnFlags", "" + m_iSpawnFlags );
			m_pDriveEnt.pev.set_controller( 0,  127 );
		}

		m_pPlayer.pev.effects |= EF_NODRAW;
		m_pPlayer.pev.solid = SOLID_NOT;
		m_pPlayer.pev.movetype = MOVETYPE_NOCLIP;
		m_pPlayer.pev.flags |= (FL_NOTARGET|FL_GODMODE);
		//m_pPlayer.pev.takedamage = DAMAGE_NO;
		m_pPlayer.pev.iuser3 = 1; //disable ducking
		m_pPlayer.pev.fuser4 = 1; //disable jumping
		m_pPlayer.pev.max_health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.pev.health = (m_flCustomHealth > 0.0) ? m_flCustomHealth : CNPC_HEALTH;
		m_pPlayer.m_bloodColor = DONT_BLEED;
		m_pPlayer.SetMaxSpeedOverride( 0 );

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
			m1.WriteString( "cam_idealdist 512\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, CNPC::CNPC_APACHE );
	}

	void DoFirstPersonView()
	{
		cnpc_apache@ pDriveEnt = cast<cnpc_apache@>(CastToScriptClass(m_pDriveEnt));
		if( pDriveEnt is null ) return;

		string szDriveEntTargetName = "cnpc_apache_rend_" + m_pPlayer.entindex();
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
		m_pPlayer.SetMaxSpeedOverride( -1 );

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, m_pPlayer.edict() );
			m1.WriteString( "cam_idealdist 64\n" );
		m1.End();

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( CNPC::sCNPCKV, 0 );
	}
}

class cnpc_apache : ScriptBaseMonsterEntity
{
	private float m_flNextRocket; //only used for death effects here

	int m_iSpawnFlags;

	protected CBasePlayer@ m_pOwner
	{
		get { return cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) ); }
	}

	EHandle m_hRenderEntity;
	float m_flNextOriginUpdate; //hopefully fixes hacky movement on other players

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_iSpawnFlags" )
		{
			m_iSpawnFlags = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, CNPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, CNPC_SIZEMIN, CNPC_SIZEMAX );
		g_EngineFuncs.DropToFloor( self.edict() );

		Vector vecOrigin = pev.origin;
		vecOrigin.z += CNPC_MODEL_OFFSET;
		g_EntityFuncs.SetOrigin( self, vecOrigin );

		pev.solid = SOLID_BBOX;
		pev.movetype = MOVETYPE_FLY;
		pev.flags |= FL_MONSTER;
		pev.deadflag = DEAD_NO;
		pev.takedamage = DAMAGE_AIM;
		pev.max_health = CNPC_HEALTH;
		pev.health = CNPC_HEALTH;
		self.m_bloodColor = DONT_BLEED;
		self.m_FormattedName = "CNPC Apache Helicopter";

		pev.sequence = 0;
		pev.frame = 0;
		self.ResetSequenceInfo();

		m_flNextOriginUpdate = g_Engine.time;
		//lift off!
		pev.velocity.z += 128;

		SetThink( ThinkFunction(this.DriveThink) );
		pev.nextthink = g_Engine.time;
	}

	int BloodColor() { return DONT_BLEED; }

	int Classify()
	{
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
		//Prevent getting damage by your own rockets (hacky)
		if( pevInflictor.classname == "cnpc_hvr_rocket" and pevAttacker.classname == "player" ) return 0;

		if( !CNPC::PVP and pevAttacker.classname == "player" ) return 0;

		if( (bitsDamageType & DMG_BLAST) != 0 )
			flDamage *= 2;

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
		//g_Game.AlertMessage( at_notice, "flDamage: %1\n", flDamage );

		//return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		return 0;
	}

	void TraceAttack( entvars_t@ pevAttacker, float flDamage, const Vector& in vecDir, TraceResult& in ptr, int bitsDamageType )
	{
		//g_Game.AlertMessage( at_notice, "iHitgroup: %1, flDamage: %2\n", ptr.iHitgroup, flDamage );

		// ignore blades
		if( ptr.iHitgroup == 6 and (bitsDamageType & (DMG_ENERGYBEAM|DMG_BULLET|DMG_CLUB)) != 0 )
			return;

		// hit hard, hits cockpit, hits engines
		if( flDamage > 50 or ptr.iHitgroup == 1 or ptr.iHitgroup == 2 )
		{
			//g_Game.AlertMessage( at_notice, "Hit hard, cockpit, or engines - flDamage: %1\n", flDamage );
			g_WeaponFuncs.AddMultiDamage( pevAttacker, self, flDamage, bitsDamageType );
			//m_iDoSmokePuff = 3 + (flDamage / 5.0);
			pev.dmg = 3 + (flDamage / 5.0);
		}
		else
		{
			// do half damage in the body
			//g_WeaponFuncs.AddMultiDamage( pevAttacker, self, flDamage / 2.0, bitsDamageType );
			g_Utility.Ricochet( ptr.vecEndPos, 2.0 );
		}
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		if( pev.deadflag != DEAD_DYING )
		{
			pev.deadflag = DEAD_DYING;
			DoDeath();
		}
	}

	void DriveThink()
	{
		if( m_pOwner is null or !m_pOwner.IsConnected() or m_pOwner.pev.deadflag != DEAD_NO )
		{
			if( m_hRenderEntity.IsValid() )
				g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

			Killed( null, GIB_NEVER );

			return;
		}

		self.StudioFrameAdvance();

		pev.nextthink = g_Engine.time + 0.01;
	}

	void DoDeath()
	{
		if( m_hRenderEntity.IsValid() )
			g_EntityFuncs.Remove( m_hRenderEntity.GetEntity() );

		pev.movetype = MOVETYPE_BOUNCE;
		pev.gravity = 0.3;

		g_SoundSystem.StopSound( self.edict(), CHAN_STATIC, arrsCNPCSounds[SND_ROTOR] );

		g_EntityFuncs.SetSize( pev, Vector(-32, -32, -64), Vector(32, 32, 0) );
		SetThink( ThinkFunction(this.DyingThink) );
		SetTouch( TouchFunction(this.CrashTouch) );
		pev.nextthink = g_Engine.time + 0.1;
		pev.health = 0;
		pev.takedamage = DAMAGE_NO;

		if( (pev.spawnflags & 8) != 0 ) //SF_NOWRECKAGE
			m_flNextRocket = g_Engine.time + 4.0;
		else
			m_flNextRocket = g_Engine.time + 15.0;
	}

	void DyingThink()
	{
		self.StudioFrameAdvance();
		pev.nextthink = g_Engine.time + 0.1;

		pev.avelocity = pev.avelocity * 1.02;

		//Geckon
		pev.avelocity.x += Math.RandomLong(1, -1);
		pev.avelocity.z += Math.RandomLong(1, -1);
		Math.MakeVectors( pev.angles ); // A bit of upward lift.
		pev.velocity = pev.velocity + (g_Engine.v_up * 75);

		pev.movetype = MOVETYPE_TOSS;
		pev.gravity = 0.8;
		//Geckon

		// still falling?
		if( m_flNextRocket > g_Engine.time )
		{
			// random explosions
			NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				m1.WriteByte( TE_EXPLOSION );		// This just makes a dynamic light now
				m1.WriteCoord( pev.origin.x + Math.RandomFloat(-150, 150) );
				m1.WriteCoord( pev.origin.y + Math.RandomFloat(-150, 150) );
				m1.WriteCoord( pev.origin.z + Math.RandomFloat(-150, -50) );
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_FIREBALL) );
				m1.WriteByte( Math.RandomLong(0, 29) + 30 ); // scale * 10
				m1.WriteByte( 12 ); // framerate
				m1.WriteByte( TE_EXPLFLAG_NONE );
			m1.End();

			// lots of smoke
			NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				m2.WriteByte( TE_SMOKE );
				m2.WriteCoord( pev.origin.x + Math.RandomFloat(-150, 150) );
				m2.WriteCoord( pev.origin.y + Math.RandomFloat(-150, 150) );
				m2.WriteCoord( pev.origin.z + Math.RandomFloat(-150, -50) );
				m2.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
				m2.WriteByte( 100 ); // scale * 10
				m2.WriteByte( 10 ); // framerate
			m2.End();

			Vector vecSpot = pev.origin + (pev.mins + pev.maxs) * 0.5;
			
			NetworkMessage m3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpot );
				m3.WriteByte( TE_BREAKMODEL );
				m3.WriteCoord( vecSpot.x ); // position
				m3.WriteCoord( vecSpot.y );
				m3.WriteCoord( vecSpot.z );
				m3.WriteCoord( 400 ); // size
				m3.WriteCoord( 400 );
				m3.WriteCoord( 132 );
				m3.WriteCoord( pev.velocity.x ); // velocity
				m3.WriteCoord( pev.velocity.y );
				m3.WriteCoord( pev.velocity.z );
				m3.WriteByte( 50 ); // randomization
				m3.WriteShort( g_EngineFuncs.ModelIndex(MODEL_GIBS) ); //model id#
				m3.WriteByte( 4 ); // # of shards. let client decide
				m3.WriteByte( 30 ); // duration 3.0 seconds
				m3.WriteByte( BREAK_METAL ); // flags
			m3.End();

			// don't stop it we touch a entity
			pev.flags &= ~FL_ONGROUND;
			pev.nextthink = g_Engine.time + 0.2;

			return;
		}
		else
		{
			Vector vecSpot = pev.origin + (pev.mins + pev.maxs) * 0.5;

			// fireball
			NetworkMessage m5( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpot );
				m5.WriteByte( TE_SPRITE );
				m5.WriteCoord( vecSpot.x );
				m5.WriteCoord( vecSpot.y );
				m5.WriteCoord( vecSpot.z + 256 );
				m5.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_EXPLODE) );
				m5.WriteByte( 120 ); // scale * 10
				m5.WriteByte( 255 ); // brightness
			m5.End();

			// big smoke
			NetworkMessage m6( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpot );
				m6.WriteByte( TE_SMOKE );
				m6.WriteCoord( vecSpot.x );
				m6.WriteCoord( vecSpot.y );
				m6.WriteCoord( vecSpot.z );
				m6.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
				m6.WriteByte( 250 ); // scale * 10
				m6.WriteByte( 5 ); // framerate
			m6.End();

			// blast circle
			NetworkMessage m7( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				m7.WriteByte( TE_BEAMCYLINDER );
				m7.WriteCoord( pev.origin.x );
				m7.WriteCoord( pev.origin.y );
				m7.WriteCoord( pev.origin.z );
				m7.WriteCoord( pev.origin.x );
				m7.WriteCoord( pev.origin.y );
				m7.WriteCoord( pev.origin.z + 2000 ); // reach damage radius over .2 seconds
				m7.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_BEAMCYLINDER) );
				m7.WriteByte( 0 ); // startframe
				m7.WriteByte( 0 ); // framerate
				m7.WriteByte( 4 ); // life
				m7.WriteByte( 32 );  // width
				m7.WriteByte( 0 );   // noise
				m7.WriteByte( 255 );   // r, g, b
				m7.WriteByte( 255 );   // r, g, b
				m7.WriteByte( 192 );   // r, g, b
				m7.WriteByte( 128 ); // brightness
				m7.WriteByte( 0 );		// speed
			m7.End();

			g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, arrsCNPCSounds[SND_EXPLODE], VOL_NORM, 0.3 );

			g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, self.pev, CRASH_DAMAGE, CRASH_RADIUS, CLASS_NONE, DMG_BLAST ); 

			//Geckon: No wreckage or gibs, it would be hardly noticeable anyway.
			/*//if( (pev.spawnflags & SF_NOWRECKAGE) == 0 and (pev.flags & FL_ONGROUND) != 0 )
			if( (pev.flags & FL_ONGROUND) != 0 )
			{
				CBaseEntity@ pWreckage = g_EntityFuncs.Create( "cycler_wreckage", pev.origin, pev.angles, false );
				g_EntityFuncs.SetModel( pWreckage, string(pev.model) );
				g_EntityFuncs.SetSize( pWreckage.pev, Vector(-200, -200, -128), Vector(200, 200, -32) );
				pWreckage.pev.frame = pev.frame;
				pWreckage.pev.sequence = pev.sequence;
				pWreckage.pev.framerate = 0;
				pWreckage.pev.dmgtime = g_Engine.time + 5.0;
			}

			// gibs
			vecSpot = pev.origin + (pev.mins + pev.maxs) * 0.5;

			NetworkMessage m8( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSpot );
				m8.WriteByte( TE_BREAKMODEL );
				m8.WriteCoord( vecSpot.x ); // position
				m8.WriteCoord( vecSpot.y );
				m8.WriteCoord( vecSpot.z + 64 );
				m8.WriteCoord( 400 ); // size
				m8.WriteCoord( 400 );
				m8.WriteCoord( 128 );
				m8.WriteCoord( 0 ); // velocity
				m8.WriteCoord( 0 );
				m8.WriteCoord( 200 );
				m8.WriteByte( 30 ); // randomization
				m8.WriteShort( g_EngineFuncs.ModelIndex(MODEL_GIBS) ); //model id#
				m8.WriteByte( 200 ); // # of shards
				m8.WriteByte( 200 ); // duration 10.0 seconds
				m8.WriteByte( BREAK_METAL ); // flags
			m8.End();*/

			SetThink( ThinkFunction(this.RemoveThink) );
			pev.nextthink = g_Engine.time + 0.1;
		}
	}

	void CrashTouch( CBaseEntity@ pOther )
	{
		// only crash if we hit something solid
		if( pOther.pev.solid == SOLID_BSP )
		{
			SetTouch(null);
			m_flNextRocket = g_Engine.time;
			pev.nextthink = g_Engine.time;
		}
	}

	void RemoveThink()
	{
		self.SUB_Remove();
	}
}

final class info_cnpc_apache : CNPCSpawnEntity
{
	info_cnpc_apache()
	{
		m_sWeaponName = CNPC_WEAPONNAME;
		m_sModel = CNPC_MODEL;
		m_iStartAnim = 0;
		m_flDefaultRespawnTime = CNPC_RESPAWNTIME;
		m_vecSizeMin = CNPC_SIZEMIN;
		m_vecSizeMax = CNPC_SIZEMAX;
	}

	void DoSpecificStuff()
	{
		g_EntityFuncs.SetOrigin( self, pev.origin + Vector(0, 0, CNPC_MODEL_OFFSET) );
		pev.set_controller( 0,  127 );
	}
}

final class cnpc_hvr_rocket : ScriptBaseEntity
{
	private int m_iTrail;
	private Vector m_vecForward;
	private float m_flBecomeSolid;

	void Spawn()
	{
		Precache();

		pev.movetype = MOVETYPE_FLY;
		pev.solid = SOLID_NOT;

		g_EntityFuncs.SetModel( self, ROCKET_MODEL );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		SetThink( ThinkFunction(this.IgniteThink) );
		SetTouch( TouchFunction(this.ExplodeTouch) );

		Math.MakeAimVectors( pev.angles );
		m_vecForward = g_Engine.v_forward;
		m_flBecomeSolid = g_Engine.time + 0.5;

		pev.gravity = 0.5;
		pev.dmg = ROCKET_DAMAGE;
		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( ROCKET_MODEL );
		g_Game.PrecacheModel( SPRITE_WATEREXP );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		g_SoundSystem.PrecacheSound( "weapons/rocket1.wav" );
	}

	void IgniteThink()
	{
		pev.effects |= EF_LIGHT;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/rocket1.wav", VOL_NORM, 0.5 );

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_BEAMFOLLOW );
			m1.WriteShort( self.entindex() );
			m1.WriteShort( m_iTrail );
			m1.WriteByte( 15 ); // life
			m1.WriteByte( 5 );  // width
			m1.WriteByte( 224 ); //r
			m1.WriteByte( 224 ); //g
			m1.WriteByte( 255 ); //b
			m1.WriteByte( 255 ); // brightness
		m1.End();

		SetThink( ThinkFunction(this.AccelerateThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void AccelerateThink()
	{
		if( m_flBecomeSolid > 0.0 and m_flBecomeSolid < g_Engine.time )
		{
			pev.solid = SOLID_BBOX;
			m_flBecomeSolid = 0.0;
		}

		float flSpeed = pev.velocity.Length();

		if( flSpeed < 1800 )
			pev.velocity = pev.velocity + m_vecForward * 200;

		pev.angles = Math.VecToAngles( pev.velocity );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void ExplodeTouch( CBaseEntity@ pOther )
	{
		TraceResult tr;
		Vector vecSpot;

		@pev.enemy = pOther.edict();

		vecSpot = pev.origin - pev.velocity.Normalize() * 32;
		g_Utility.TraceLine( vecSpot, vecSpot + pev.velocity.Normalize() * 64, ignore_monsters, self.edict(), tr );

		Explode( tr, DMG_BLAST );
	}

	void Explode( TraceResult pTrace, int bitsDamageType )
	{
		pev.model = string_t();
		pev.solid = SOLID_NOT;

		pev.takedamage = DAMAGE_NO;

		if( pTrace.flFraction != 1.0f )
			pev.origin = pTrace.vecEndPos + (pTrace.vecPlaneNormal * (pev.dmg - 24) * 0.6);

		int iContents = g_EngineFuncs.PointContents( pev.origin );

		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			if( iContents != CONTENTS_WATER )
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_FIREBALL) );
			else
				m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_WATEREXP) );
			m1.WriteByte( int((pev.dmg - 50) * 0.60)  );
			m1.WriteByte( 15 );
			m1.WriteByte( TE_EXPLFLAG_NONE );
		m1.End();

		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0, self ); 

		entvars_t@ pevOwner;
		if( pev.owner !is null )
			@pevOwner = pev.owner.vars;
		else
			@pevOwner = null;

		@pev.owner = null;

		g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pevOwner, pev.dmg, pev.dmg * 2.5, CLASS_NONE, bitsDamageType );

		if( Math.RandomFloat(0, 1) < 0.5 )
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH1 );
		else
			g_Utility.DecalTrace( pTrace, DECAL_SCORCH2 );

		switch( Math.RandomLong(0, 2) )
		{
			case 0:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/debris1.wav", 0.55, ATTN_NORM ); break;
			case 1:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/debris2.wav", 0.55, ATTN_NORM ); break;
			case 2:	g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "weapons/debris3.wav", 0.55, ATTN_NORM ); break;
		}

		pev.effects |= EF_NODRAW;
		SetThink( ThinkFunction(this.Smoke) );
		pev.velocity = g_vecZero;
		pev.nextthink = g_Engine.time + 0.3;

		if( iContents != CONTENTS_WATER )
		{
			int sparkCount = Math.RandomLong(0, 3);
			for( int i = 0; i < sparkCount; i++ )
				g_EntityFuncs.Create( "spark_shower", pev.origin, pTrace.vecPlaneNormal, false );
		}
	}

	void Smoke()
	{
		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_WATER )
			g_Utility.Bubbles( pev.origin - Vector(64, 64, 64), pev.origin + Vector(64, 64, 64), 100 );
		else
		{
			NetworkMessage smoke( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
				smoke.WriteByte( TE_SMOKE );
				smoke.WriteCoord( pev.origin.x );
				smoke.WriteCoord( pev.origin.y );
				smoke.WriteCoord( pev.origin.z );
				smoke.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
				smoke.WriteByte( int((pev.dmg - 50) * 0.80) );
				smoke.WriteByte( 12 );
			smoke.End();
		}

		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_apache::cnpc_hvr_rocket", "cnpc_hvr_rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_apache::info_cnpc_apache", "info_cnpc_apache" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_apache::cnpc_apache", "cnpc_apache" );
	g_CustomEntityFuncs.RegisterCustomEntity( "cnpc_apache::weapon_apache", CNPC_WEAPONNAME );
	g_ItemRegistry.RegisterWeapon( CNPC_WEAPONNAME, "controlnpc", "", "hvrrockets" );

	g_Game.PrecacheOther( "info_cnpc_apache" );
	g_Game.PrecacheOther( "cnpc_apache" );
	g_Game.PrecacheOther( CNPC_WEAPONNAME );
}

} //namespace cnpc_apache END

/* FIXME
*/

/* TODO
	Add gun autoaim ??
	Add settings to map entity
*/