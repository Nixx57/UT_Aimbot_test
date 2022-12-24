Simple aimbot for Unreal Tournament (1999) made in UnrealScript <br />
/!\ Ineffective against anti-cheat /!\


<h3>Features : </h3>
- Slow rotation<br />
- Combo shock (if enemy is close of shock ball)<br />
- Trajectory calculation, according to the velocity of the projectiles and the gravity (if the enemy fall)<br />
- Work on NPC (coop gamemode)<br />
<br />
<h3>How to use :</h3>
1) Copy the "MyAimbot" folder in UT99 root directory <br />
2) In System/UnrealTournament.ini :<br />
a) Add (or replace) : Console=MyAimbot.MyConsole in [Engine.Engine] <br />
b) Add : EditPackages=MyAimbot in [Editor.EditorEngine] <br />
3) Exec "CompileMyAimbot.bat" <br />
4) Ingame, type "help" in console for see commands list <br /> <br />

<h4>Tips :</h4> <br />
Bind your keys to commands in User.ini <br />
Example : <br />
MouseButton4=doAutoaim <br />
PageUp=IncreaseSpeed <br />
PageDown=ReduceSpeed
