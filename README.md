## (WIP) BMod - JMod, but implemented in StarfallEX
**What is BMod?** This is a analog of Garry's Mod addon with name JMod. JMod is addon with resources, mining, armor and other solutions for roleplay, as example
**Why it needed?** It needed, because not all servers have the JMod, but it addictive to a roleplay or an event. Or just to have a fun with your friends :)

## TODO:
- [x] BGUI Library
    - [x] Fix bugs with focus
    - [x] BGUI redesign
    - [ ] Make skins system like Derma
    - [ ] Tooltips
- [ ] Config
    - [ ] Split config between client and server
    - [ ] Client config commands
- [ ] Machines
    - [x] Crafting table
        - [x] Function to melt ore
        - [ ] Add more crafts
    - [x] Solid fuel generator
    - [ ] Make GUI for machines
    - [ ] Make interfaces to connect machines
    - [ ] Try to make Wire outputs (maybe transfer some entities to StarfallEX chip? Or make chip with Wire spawning on button?)
    - [ ] Workbench
    - [ ] Fabricator
    - [ ] Solar panel
    - [x] Auger drill
    - [x] Ground scanner
    - [x] Liquid fuel generator
    - [ ] Oil rig
    - [ ] Oil refinery
    - [ ] Pumpjack
    - [ ] Turret
    - [ ] Sprinkler
    - [ ] Powerbank
    - [ ] Upgradeables
- [ ] Deposits
    - [ ] Deposits without navmesh
    - [ ] Master-chip for deposits
    - [x] Debug with icons for deposits
- [ ] Tools
    - [ ] Toolbox
        - [x] Base craft system
        - [x] Salvaging
        - [ ] Upgrade machines
    - [x] Bucket
    - [ ] More pretty system for SWEPs, not crowbar
    - [ ] Pickaxe
    - [ ] Axe
    - [ ] Shovel
- [ ] Multiplayer
    - [ ] Make shared HUD
    - [ ] Make chip ID and remoting
    - [ ] Make headphones for local chatting (can't make voice, so I should make PR to Starfall with PlayerCanHearVoice hook)
- [ ] Holomodels library
    - [x] Base modeling system
    - [x] Client and server support
    - [ ] Tweens for animations (not related to BMod)
    - [x] Both sides mesh and custom materials support
- [ ] Armor system
    - [ ] Armor creating
    - [x] Visual armor system 
    - [ ] Armor inventory managing
- [ ] Plants
- [ ] Bombs
- [ ] Misc
    - [ ] Road flare
    - [ ] Food
    - [ ] Resource and item crates
    - [ ] Medkit
- [ ] Make wiki about libraries
- [ ] Build system (make your BMod build with modules in one file)
    - [ ] GitHub releases
    - [ ] GitHub CI for BMod (maybe for other chips)

## Recommended options
`sf_props_burstmax 10`
`sf_props_burstrate 4`
