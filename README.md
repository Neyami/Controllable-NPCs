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

If you want to use custom sentences (scientist only for now), set `USE_CUSTOM_SENTENCES` to true,  
and add the contents of sound/default_sentences.txt to the bottom of either svencoop\sound\default_sentences.txt, or copy that file into svencood_addon\sound\ (preferable)

<BR>

# HEADCRAB #  
`weapon_headcrab` - Give this to the player  

Primary Attack: Leap at target, or just forward it not aiming at an enemy


<BR>

# HOUNDEYE #  
`weapon_houndeye` - Give this to the player  
`info_cnpc_houndeye` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Sonic Attack  
Tertiary Attack: Toggle between first- and third-person view  
Back Key (S): Hop backwards  


<BR>

# ALIEN SLAVE #  
`weapon_islave` - Give this to the player  
`info_cnpc_islave` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Lightning Attack  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Revive nearby dead alien slaves as allies  


<BR>

# ALIEN GRUNT #  
`weapon_agrunt` - Give this to the player  
`info_cnpc_agrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot Hornets  
Secondary Attack: Melee  
Reload: Throw a Snark Nest  
Also; try falling from different heights :ayaya:  


<BR>

# ICHTHYOSAUR #  
`weapon_icky` - Give this to the player  
`info_cnpc_icky` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Bite  
Secondary Attack: Charge and bite the first enemy hit  


<BR>


# PIT DRONE #  
`weapon_pitdrone` - Give this to the player  

Primary Attack: Shoot Spikes  
Secondary Attack: Melee  
Reload: Reload spikes  
Jump: Short hop  
Longjump (duck-key, quickly followed by jump): Leap


<BR>


# SHOCK TROOPER #  
`weapon_strooper` - Give this to the player  
`info_cnpc_strooper` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot Lightning Bolts  
Secondary Attack: Melee  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Throw Spore Grenade  
Talk in chat: Speak in the language of Shock Troopers  

Ammo replenishes when idle  



<BR>


# GONOME #  
`weapon_gonome` - Give this to the player  
`info_cnpc_gonome` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Melee, Left and Right Slash  
Secondary Attack: Melee, Bite and Thrash  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Throw Guts  
Use: Hold to feed on dead humanoids to regenerate health  


<BR>


# HUMAN ASSASSIN #  
`weapon_fassn` - Give this to the player  
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
`weapon_mturret` - Give this to the player  
`info_cnpc_mturret` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot  
Secondary Attack: Deploy and retire  
Tertiary Attack: Toggle between first- and third-person view  
Use: Exit turret  

Turret replenishes ammo when retired  


<BR>


# TURRET #  
`weapon_turret` - Give this to the player  
`info_cnpc_turret` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Shoot  
Secondary Attack: Deploy and retire  
Tertiary Attack: Toggle between first- and third-person view  
Use: Exit turret  

Turret replenishes ammo when retired  
When active and not shooting, nearby enemies will be highlighted  


<BR>



# SCIENTIST #  
`weapon_scientist` - Give this to the player  
`info_cnpc_scientist` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Heal friendlies if the syringe is out  
Secondary Attack: **AAAAAAAAAAAAAHHHHHHHHHHHHHHH**  
Tertiary Attack: Toggle between first- and third-person view  
Reload: Toggle syringe  

Healing ammo replenishes when the syringe isn't out  


<BR>



# HUMAN GRUNT #  
`weapon_hgrunt` - Give this to the player  
`info_cnpc_hgrunt` - Usable entity that turns the player into the monster upon using. Mappers can place this  

Primary Attack: Fire the weapon when aiming, or kick when not aiming  
Secondary Attack: Aim  
Tertiary Attack: Toggle between first- and third-person view  
Reload: M16 will launch a contact grenade, the other weapons will toss a grenade, look straight down~ish to place a grenade on the ground  

Refer to `controlnpc.fgd` to see the keyvalues that set the weapons  


<BR>

