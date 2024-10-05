namespace CNPC
{

namespace Q2
{

const array<string> pExplosionSprites = 
{
	"sprites/exp_a.spr",
	"sprites/bexplo.spr",
	"sprites/dexplo.spr",
	"sprites/eexplo.spr"
};

class cnpcq2laser : ScriptBaseEntity
{
	protected EHandle m_hGlow;
	protected CSprite@ m_pGlow
	{
		get const { return cast<CSprite@>(m_hGlow.GetEntity()); }
		set { m_hGlow = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/laser.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_FLYMISSILE;
		pev.solid = SOLID_BBOX;
		pev.effects |= EF_DIMLIGHT;
		pev.scale = 0.9;

		Glow();

		SetThink( ThinkFunction(this.FlyThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/laser.mdl" );
		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapons/laser_fly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/laser_hit.wav" );
	}

	void Ignite()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser_fly.wav", 0.05, ATTN_NORM );
		SetThink( ThinkFunction(this.FlyThink) );
		pev.nextthink = g_Engine.time;
	}

	void Glow()
	{
		@m_pGlow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", pev.origin, false ); 
		m_pGlow.SetTransparency( 3, 50, 20, 0, 255, 14 );
		m_pGlow.SetScale( 0.5 );
		m_pGlow.SetAttachment( self.edict(), 0 );
	}

	void FlyThink()
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteByte( 16 );//radius
			m1.WriteByte( 255 );
			m1.WriteByte( 200 );
			m1.WriteByte( 100 );
			m1.WriteByte( 4 );//life
			m1.WriteByte( 128 );//decay
		m1.End();

		NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			m2.WriteByte( TE_IMPLOSION );
			m2.WriteCoord( pev.origin.x );
			m2.WriteCoord( pev.origin.y );
			m2.WriteCoord( pev.origin.z );
			m2.WriteByte( 1 );//radius
			m2.WriteByte( 4 );//count
			m2.WriteByte( 2 );//life
		m2.End();

		pev.nextthink = g_Engine.time;
	}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser_fly.wav" );

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(this.RemoveThink) );
			pev.nextthink = g_Engine.time + 0.1;
			return;
		}

		if( pOther is g_EntityFuncs.Instance(pev.owner) )
			return;

		if( pOther !is null )
		{
			if( !pOther.IsBSPModel() )
			{
				if( pOther.pev.takedamage != 0 )
				{
					g_WeaponFuncs.SpawnBlood( pev.origin, pOther.BloodColor(), pev.dmg );
					pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_ENERGYBEAM );
				}
			}
			else
			{
				Explode();
				TraceResult tr;
				tr = g_Utility.GetGlobalTrace();
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/laser_hit.wav", 0.8, ATTN_NORM );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0, 1) );

				if( pOther.pev.takedamage != 0 )
					pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_ENERGYBEAM );
			}
		}

		RemoveThink();
	}

	void Explode()
	{
		g_Utility.Sparks( pev.origin );

		NetworkMessage dl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			dl.WriteByte( TE_DLIGHT );
			dl.WriteCoord( pev.origin.x );
			dl.WriteCoord( pev.origin.y );
			dl.WriteCoord( pev.origin.z );
			dl.WriteByte( 16 );//radius
			dl.WriteByte( 255 );
			dl.WriteByte( 200 );
			dl.WriteByte( 50 );
			dl.WriteByte( 4 );//life
			dl.WriteByte( 128 );//decay
		dl.End();
	}
	// The only way to ensure that the sound stops playing...
	void RemoveThink()
	{
		SetThink( null );
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser_fly.wav" );
		g_EntityFuncs.Remove( self );
		g_EntityFuncs.Remove( m_pGlow );
	}
}

class cnpcq2rocket : ScriptBaseEntity
{
	protected EHandle m_hGlow;
	protected CSprite@ m_pGlow
	{
		get const { return cast<CSprite@>(m_hGlow.GetEntity()); }
		set { m_hGlow = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/rocket.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-1, -1, -1), Vector(1, 1, 1) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav", 1, ATTN_NORM );
		//pev.nextthink = g_Engine.time + 0.05;
		pev.movetype = MOVETYPE_FLYMISSILE;
		pev.solid = SOLID_BBOX;
		pev.effects |= EF_DIMLIGHT;
		//SetThink( ThinkFunction(Ignite) );
		Glow();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/rocket.mdl" );
		g_Game.PrecacheModel( "sprites/WXplo1.spr" );
		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		for( uint i = 0; i < pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( pExplosionSprites[i] );

		g_SoundSystem.PrecacheSound( "quake2/weapons/rocket_fly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rocket_explode.wav" );
	}

	void Glow()
	{
		@m_pGlow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", pev.origin, false ); 
		m_pGlow.SetTransparency( 3, 100, 50, 0, 255, 14 );
		m_pGlow.SetScale( 0.3 );
		m_pGlow.SetAttachment( self.edict(), 1 );
	}
	
	void Ignite()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav", 1, ATTN_NORM );
		SetThink( ThinkFunction(this.FlyThink) );
		self.pev.nextthink = g_Engine.time;
	}

	void FlyThink()
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteByte( 16 );//radius
			m1.WriteByte( 100 );
			m1.WriteByte( 50 );
			m1.WriteByte( 0 );
			m1.WriteByte( 4 );//life
			m1.WriteByte( 128 );//decay
		m1.End();
		
		pev.nextthink = g_Engine.time;
	}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav" );

		if( g_EngineFuncs.PointContents( pev.origin ) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(this.RemoveThink) );
			pev.nextthink = g_Engine.time + 0.1;
			return;
		}

		if( pOther.edict() is pev.owner )
			return;

		if( pOther !is null )
		{
			NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				m1.WriteByte( TE_EXPLOSION );
				m1.WriteCoord( pev.origin.x );
				m1.WriteCoord( pev.origin.y );
				m1.WriteCoord( pev.origin.z );

				if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_WATER )
					m1.WriteShort( g_Game.PrecacheModel("sprites/WXplo1.spr") );
				else
					m1.WriteShort( g_Game.PrecacheModel(pExplosionSprites[Math.RandomLong(0, pExplosionSprites.length() - 1)]) );

				m1.WriteByte( 30 );//scale
				m1.WriteByte( 30 );//framerate
				m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
			m1.End();

			TraceResult tr;
			Vector vecSpot, vecEnd;

			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/rocket_explode.wav", VOL_NORM, ATTN_NORM );
			vecSpot = pev.origin - pev.velocity.Normalize() * 32;
			vecEnd = pev.origin + pev.velocity.Normalize() * 64;
			g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );
			g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
			GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0, self ); 

			entvars_t@ pevOwner;
			if( pev.owner !is null )
				@pevOwner = pev.owner.vars;
			else
				@pevOwner = null;

			@pev.owner = null;

			g_WeaponFuncs.RadiusDamage( pev.origin, pevOwner, pevOwner, pev.dmg, pev.dmg * 2.5, CLASS_NONE, DMG_BLAST );
		}

		SetThink( ThinkFunction(this.RemoveThink) );
		pev.nextthink = g_Engine.time + 0.01;
	}

	// The only way to ensure that the sound stops playing...
	void RemoveThink()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav" );
		g_EntityFuncs.Remove( self );
		g_EntityFuncs.Remove( m_pGlow );
	}
}

} //namespace Q2 END

} //namespace CNPC END