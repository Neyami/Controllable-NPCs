Play as various monsters!  
A work in progress.  

1) Download and put it in svencoop_addons, keeping directories
2) Add `map_script controlnpc/cnpc` to the map.cfg
3) uuuuuuuuuuuuhhhhhhhh
4) Place or spawn `info_cnpc_monstername`, add weapon_name to the map.cfg, or `.player_give @me weapon_name`
5) Press the primary attack to turn into the monster, or use the holographic representation  
6) ????
7) PROFIT

The only way to revert to a normal player is to die :ayaya:  
Turrets can be exited with the Use-key  

Refer to `controlnpc.fgd` to see the keyvalues that can be set for the `info_cnpc_*` entities


If you want to use custom sentences (scientist only for now), set `USE_CUSTOM_SENTENCES` to true,  
and add the contents of sound/default_sentences.txt to the bottom of either svencoop\sound\default_sentences.txt, or copy that file into svencood_addon\sound\ (preferable)  

Set `CNPC_NPC_HITBOX` to `true` to use the hitbox of the monster model instead of the player (only for monsters that have special armor, or are smaller/larger than the player) EXPERIMENTAL!!  

<BR>


# HEADCRAB #  
`weapon_headcrab` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_headcrab` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Leap at target, or just forward it not aiming at an enemy  
Tertiary Attack: Toggle between first- and third-person view  


<BR>


# ZOMBIE #  
`weapon_zombie` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_zombie` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Slash right then left  
Secondary Attack: Overhead strike  
Tertiary Attack: Toggle between first- and third-person view  

Takes 30% less damage from bullets  

<BR>


# HOUNDEYE #  
`weapon_houndeye` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_houndeye` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Sonic Attack  
Tertiary Attack: Toggle between first- and third-person view  
Back Key (S): Hop backwards  


<BR>


# ALIEN SLAVE #  
`weapon_islave` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_islave` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Lightning Attack  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Revive nearby dead alien slaves as allies  

Beamcolors are based on topcolor and bottomcolor.  


<BR>

# ALIEN GRUNT #  
`weapon_agrunt` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_agrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot Hornets  
Secondary Attack: Melee  
Reload: Throw a Snark Nest  
Also; try falling from different heights :ayaya:  


<BR>


# ICHTHYOSAUR #  
`weapon_icky` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_icky` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Bite  
Secondary Attack: Charge and bite the first enemy hit  


<BR>


# PIT DRONE #  
`weapon_pitdrone` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_pitdrone` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot Spikes  
Secondary Attack: Melee  
Reload: Reload spikes  
Jump: Short hop  
Longjump (duck-key, quickly followed by jump): Leap


<BR>


# SHOCK TROOPER #  
`weapon_strooper` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_strooper` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot Lightning Bolts  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Throw Spore Grenade  
Talk in chat: Speak in the language of Shock Troopers  

Ammo replenishes when idle  


<BR>


# GONOME #  
`weapon_gonome` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_gonome` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Melee, Left and Right Slash  
Secondary Attack: Melee, Bite and Thrash  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Throw Guts  
Use: Hold to feed on dead humanoids to regenerate health  


<BR>


# GARGANTUA #  
`weapon_garg` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_garg` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Dual flamethrower  
Secondary Attack: Melee  
Secondary Attack while holding duck: Eat enemies with low health to gain secondary ammo, use again at 100 ammo to spawn a Baby Garg  
Tertiary Attack: Toggle between first- and third-person view  
Jump: Kick  
Reload: Stomp attack  

Flamethrower ammo replenishes automatically.  
Is immune to normal bullets.  


<BR>


# BABY GARGANTUA #  
`weapon_babygarg` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_babygarg` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Dual flamethrower  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Jump: Kick  
Reload: Stomp attack  

Flamethrower ammo replenishes automatically.  


<BR>


# HUMAN GRUNT #  
`weapon_hgrunt` - Can be given to players, Primary Attack spawns the controllable monster. (not recommended, spawn the entity below instead)  
`info_cnpc_hgrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the weapon when aiming, or kick when not aiming  
Secondary Attack: Aim  
Tertiary Attack: Toggle between first- and third-person view  
Reload: M16 will launch a contact grenade, the other weapons will toss a grenade, look straight down~ish to place a grenade on the ground  
Duck: Crouch, most weapons can be fired while crouching  

Refer to `controlnpc.fgd` to see the keyvalues that set the weapons  


<BR>


# HUMAN ASSASSIN #  
`weapon_fassn` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_fassn` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot  
Secondary Attack: Melee attack  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Throw a grenade  
Duck: Toggle stealth  
Jump: Do a backflip, shooting while falling is possible  

Stealth power replenishes when not in stealth  


<BR>


# MINI TURRET #  
`weapon_mturret` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_mturret` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot  
Secondary Attack: Deploy and retire  
Tertiary Attack: Toggle between first- and third-person view  
Use: Exit turret  

Turret replenishes ammo when retired  


<BR>


# TURRET #  
`weapon_turret` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_turret` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot  
Secondary Attack: Deploy and retire  
Tertiary Attack: Toggle between first- and third-person view  
Use: Exit turret  

Turret replenishes ammo when retired  
When active and not shooting, nearby enemies will be highlighted  


<BR>


# ROBOT GRUNT #  
`weapon_rgrunt` - Can be given to players, Primary Attack spawns the controllable monster.  (not recommended, spawn the entity below instead)  
`info_cnpc_rgrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the weapon when aiming, or kick when not aiming  
Secondary Attack: Aim  
Tertiary Attack: Toggle between first- and third-person view  
Reload: M16 will launch a contact grenade, the other weapons will toss a grenade, look straight down~ish to place a grenade on the ground  
Duck: Crouch, most weapons can be fired while crouching  

Is immune to normal bullets  
At low health it will start giving off sparks and sometimes shock enemies when touched  
Can be repaired by other players with the pipe wrench  
Explodes shortly after death  
Refer to `controlnpc.fgd` to see the keyvalues that set the weapons  


<BR>


# HEAVY WEAPONS ROBOT GRUNT #  
`weapon_hwrgrunt` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_hwrgrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the minigun  
Tertiary Attack: Toggle between first- and third-person view  

Is immune to normal bullets  
At low health it will start giving off sparks and sometimes shock enemies when touched  
Can be repaired by other players with the pipe wrench  
Explodes shortly after death, instantly explodes when gibbed (can be turned off)  
Refer to `controlnpc.fgd` to see the keyvalues that can be set  


<BR>


# SCIENTIST #  
`weapon_scientist` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_scientist` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Heal friendlies if the syringe is out  
Secondary Attack: **AAAAAAAAAAAAAHHHHHHHHHHHHHHH**  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Toggle syringe  

Healing ammo replenishes when the syringe isn't out  


<BR>


# OTIS #  
`weapon_otis` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_otis` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot if gun is drawn, eat if you have a doughnut  
Secondary Attack: Draw/Holster gun  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Reload gun  
Use: When low on health you can get doughnuts from Snack Machines (unless they're brush entities 😦)  


<BR>


# ENGINEER #  
Primarily meant to be used in the sandstone map to replace/complement the Engineer NPC  

`weapon_engineer` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_engineer` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the weapon when aiming, or kick when not aiming  
Secondary Attack: Aim  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Reload the weapon  
Use: Plant the explosives in the sandstone map
