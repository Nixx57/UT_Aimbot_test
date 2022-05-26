Simple aimbot for Unreal Tournament (1999) made in UnrealScript

Features : 
- Slow rotation
- Combo shock (if enemy is close of shock ball)
- Trajectory calculation, according to the velocity of the projectiles and the gravity (if the enemy fall)
- Work on NPC (coop gamemode)

How to use :
1) Copy the "MyAimbot" folder in UT99 root directory
2) In System/UnrealTournament.ini :
  a) Add (or replace) : Console=MyAimbot.MyConsole in [Engine.Engine]
  b) Add : EditPackages=MyAimbot in [Editor.EditorEngine]
3) Exec "CompileMyAimbot.bat"
4) Ingame, type "help" in console for see commands list

Tips :
Bind your keys to commands in User.ini
Example : 
MouseButton4=doAutoaim
PageUp=IncreaseSpeed
PageDown=ReduceSpeed
