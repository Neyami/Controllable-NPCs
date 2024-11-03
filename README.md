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
info_cnpc entities can also be set to trigger only  

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


# HOUNDEYE #  
`weapon_houndeye` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_houndeye` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Sonic Attack  
Tertiary Attack: Toggle between first- and third-person view  
Back Key (S): Hop backwards  


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


# ALIEN SLAVE #  
`weapon_islave` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_islave` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Lightning Attack  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Revive nearby dead alien slaves as allies  

Beamcolors are based on topcolor and bottomcolor.  


<BR>


# ZOMBIE #  
`weapon_zombie` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_zombie` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Slash right then left  
Secondary Attack: Overhead strike  
Tertiary Attack: Toggle between first- and third-person view  

Takes 30% less damage from bullets  


<BR>


# BULLSQUID #  
`weapon_bullsquid` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_bullsquid` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Spit  
Secondary Attack: Bite  
Tertiary Attack: Toggle between first- and third-person view  
Jump: Tail-whip  
Duck: Sprint  


<BR>


# ALIEN GRUNT #  
`weapon_agrunt` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_agrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot Hornets  
Secondary Attack: Melee  
Reload: Throw a Snark Nest  
Also; try falling from different heights :ayaya:  


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


# ICHTHYOSAUR #  
`weapon_icky` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_icky` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Bite  
Secondary Attack: Charge and bite the first enemy hit  


<BR>


# KINGPIN #  
`weapon_kingpin` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_kingpin` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Melee  
Secondary Attack: Homing Plasma Ball  
Tertiary Attack: Toggle between first- and third-person view  

Eyes automatically charge and fire at nearby enemies  
Projectiles fired/thrown at may be deflected or blown up  


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


# TENTACLE #  
`weapon_tentacle` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_tentacle` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Long range strike 
Secondary Attack: Close range tap  
Tertiary Attack: Toggle between first- and third-person view  
Jump: Move up  
Duck: Move down  


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


# BIG MOMMA #  
`weapon_bigmomma` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_bigmomma` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Melee attacks  
Secondary Attack: Launch mortar  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Drop baby crabs, two may be dropped before a longer cooldown is set  
Duck: Defend (no use yet)  


<BR>


# Government Man #  
`weapon_gman` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_gman` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Button push animation (does nothing)  
Secondary Attack: Talk on the phone  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Toggle the phone  

Is immune to all damage, and can't be seen by enemies.  


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


# SENTRY #  
`weapon_sentry` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_sentry` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot  
Secondary Attack: Deploy and retire  
Tertiary Attack: Toggle between first- and third-person view  
Duck: Rotates the turret when idle  
Use: Exit turret  

Turret replenishes ammo when retired  


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


# HEAVY WEAPONS GRUNT #  
`weapon_hwgrunt` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_hwgrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the minigun  
Tertiary Attack: Toggle between first- and third-person view  

May drop the minigun if hit by explosives, use any dropped minigun to pick it up  
Refer to `controlnpc.fgd` to see the keyvalues that can be set  


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


# APACHE HELICOPTER #  
`weapon_apache` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_apache` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the auto cannon 
Secondary Attack: Launch rockets  
Tertiary Attack: Toggle between first- and third-person view  
Jump: Go up  
Duck: Go down  

Rockets replenish automatically  


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


# BARNEY #  
`weapon_barney` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_barney` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot if gun is drawn  
Secondary Attack: Draw/Holster gun  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Reload gun  


<BR>


# OTIS #  
`weapon_otis` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_otis` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot if gun is drawn, eat if you have a doughnut  
Secondary Attack: Draw/Holster gun  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Reload gun  
Use: When low on health you can get doughnuts from Snack Machines (unless they're brush entities?? 😦)  


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


<BR>


# QUAKE 2 SOLDIER #  
`weapon_q2soldier` - Can be given to players, Primary Attack spawns the controllable monster. (not recommended, spawn the entity below instead)  
`info_cnpc_q2soldier` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Blaster/Shotgun/Machinegun  
Tertiary Attack: Toggle between first- and third-person view  
Duck: Duck to reduce incoming damage by 50% while holding  

Refer to `controlnpc.fgd` to see the keyvalues that set the weapons  


<BR>


# QUAKE 2 IRON MAIDEN #  
`weapon_q2ironmaiden` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2ironmaiden` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Rocket launcher  
Secondary Attack: Melee attack  
Tertiary Attack: Toggle between first- and third-person view  
Duck: Duck to reduce incoming damage by 50% while holding  


<BR>


# QUAKE 2 BERSERKER #  
`weapon_q2berserker` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2berserker` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Club  
Secondary Attack: Spike  
Tertiary Attack: Toggle between first- and third-person view  
Duck: Duck to reduce incoming damage by 50% while holding  
Jump: Jumping attack, hold to charge for a longer leap  


<BR>


# QUAKE 2 GLADIATOR #  
`weapon_q2gladiator` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2gladiator` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Melee attack  
Secondary Attack: Railgun  
Tertiary Attack: Toggle between first- and third-person view  
Jump: Dance or something idk  


<BR>


# QUAKE 2 ENFORCER #  
`weapon_q2enforcer` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2enforcer` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Machine gun  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Duck: Duck to reduce incoming damage by 50% while holding  


<BR>


# QUAKE 2 TANK #  
`weapon_q2tank` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2tank` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the blaster, hold to sometimes fire more shots  
Secondary Attack: Chaingun for close range  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Rocket launcher, hold to sometimes fire more rockets  
Jump: Victory pose that gibs corpses  


<BR>


# QUAKE 2 SUPER TANK #  
`weapon_q2supertank` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2supertank` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Rocket launcher  
Secondary Attack: Chaingun  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Fire grenades  


<BR>


# QUAKE 2 MAKRON #  
`weapon_q2makron` - Can be given to players, Primary Attack spawns the controllable monster.  
`info_cnpc_q2makron` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: BFG  
Secondary Attack: Hyper Blaster  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Railgun  
