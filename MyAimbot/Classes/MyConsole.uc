//=====================================================================================
// BOT START.
//=====================================================================================

class MyConsole extends UTConsole Config(MyAimbot);
// MyConsole : This must match the filename you are programming in
// UTConsole : This is the Class your script extends
// Config(MyAimbot) : Your bot settings will be saved in the "MyAimbot.ini" file


#exec Texture Import File=Textures\MyCross.bmp Name=MyCross 
#exec Texture Import File=Textures\MyLogo.bmp  Name=MyLogo 
// #exec lines are used to tell the compiler it should Import a texture or sound
// In this case you will Import the file "MyCross.bmp" and give it the variable name "MyCross"
// The same goes for MyLogo.bmp

///////////////////////////////////////////////////////////////
// TEST
///////////////////////////////////////////////////////////////
struct TargetStruct
{
	var Pawn 	Target;
	var Vector 	TOffset;
	var bool 	TVisible;
	var bool 	TEnemy;
	var byte 	TFireMode;
	var int 	TWarning;
};
///////////////////////////////////////////////////////////////
// ENDTEST
///////////////////////////////////////////////////////////////





// if a config statement is before the variable, you will be able to save the variable into "MyAimbot.ini"
var config bool bBotActive;
var config bool bAutoAim;
var config bool bAutoFire;
var config bool bDrawRadar;


// These vars will not be saved to the .ini file
var PlayerPawn Me;
var bool bBotIsShooting;


// Hook into the PostRender event to get Canvas acces
// If you have Canvas acces you are able to write and show stuff onto your Screen
event PostRender (Canvas Canvas)
{
	Super.PostRender(Canvas); 
	// This will execute all the code that is located into the "PostRender" event we have just overwritten
	// Don't forget this

	MyPostRender(Canvas);
	// Ok now execute our own code located into the "MyPostRender" function
	// We pass on Canvas acces to our function too so we can Draw stuff on Screen
}


//================================================================================
// MAIN BOT.
//================================================================================


// This is where the magic happens :P
// It is the start of our own Aimbot code
function MyPostRender (Canvas Canvas)
{

	Me = Viewport.Actor;
	// We give the Variable "Me" the value "Viewport.Actor"
	// "Me" now hold our own Player (PlayerPawn)
	

	// This is a check if we activated our Aimbot
	// And we check if the variable Me is NOT None
	// You must be carefull that a variable you use is not None because
	// it can lead to enormous errors and even a crash of UT
	if (!bBotActive || Me == None || Me.PlayerReplicationInfo == None)
	{
		Return;
		// If we didn't activate our aimbot or the Me variable is None
		// we stop this function with the "Return" statement
	}
	
	// Now execute our Code that is located in the Function below and give them all Canvas acces
	DrawMyLogo(Canvas);
	DrawMySettings(Canvas);
	PawnRelated(Canvas);
}


// Let us draw a nice bot logo on screen so you can show off your newly created aimbot to your friends :P
function DrawMyLogo (Canvas Canvas)
{
	Canvas.Style = 3;
	// set the Canvas Style to transparant

	Canvas.bCenter = False;
	// we don't want it in the center of the screen

	Canvas.bNoSmooth = True;

	// Divide the screen height by 3
	Canvas.SetPos(20, Canvas.ClipY / 3);
	
	// set the DrawColor to White
	Canvas.DrawColor.R = 229;
	Canvas.DrawColor.G = 229;
	Canvas.DrawColor.B = 229;
	Canvas.DrawColor.A = 0;	
	
	// Draw our 1337 Logo :P
	Canvas.DrawIcon(Texture'MyLogo', 0.7);
}


// It is allways usefull to show on screen what features of the Aimbot are On/Off
function DrawMySettings (Canvas Canvas)
{
	// set the Font to small so we don't fill up an entire screen by just writing some settings
	Canvas.Font = Canvas.SmallFont;
	
	Canvas.SetPos(20, Canvas.ClipY / 2);
	Canvas.DrawText("[MyAimbot]");
	
	Canvas.SetPos(20, Canvas.ClipY / 2 + 10 );
	Canvas.DrawText("----------");	
	
	Canvas.SetPos(20, Canvas.ClipY / 2 + 20);
	Canvas.DrawText("AutoAim  : " $ String(bAutoAim));
	
	Canvas.SetPos(20, Canvas.ClipY / 2 + 30);
	Canvas.DrawText("AutoFire : " $ String(bAutoFire));
	
	Canvas.SetPos(20, Canvas.ClipY / 2 + 40);
	Canvas.DrawText("Radar    : " $ String(bDrawRadar));	
	
}


// This function holds the code that will cycle through all Players on the Map
function TargetStruct PawnRelated(Canvas Canvas)
{
	local Pawn Target;
	local TargetStruct BestTarget;
	local TargetStruct CurrentTarget;
	
	BestTarget=ClearTargetInfo(BestTarget);

	// Cycle through all players (Pawns) on the Map and store them in a temporarry variable "Target"
	foreach Me.Level.AllActors(Class'Pawn', Target)
	{
		// Check if this Target is Valid, we don't want to be Aiming at spectator or people that are allready dead :P
		if ( ValidTarget(Target) )
		{
			// Check if the feature "DrawRadar" is active
			if ( bDrawRadar )
			{
				DrawPlayerOnRadar(Target, Canvas);
				// execute the code that will draw this Target in our 3D Radar
			}
			
			// Check if the feature "AutoAim" is active
			if ( bAutoAim )
			{
				if ( IsEnemy(Target) )
				{
					CurrentTarget.Target=Target;
					CurrentTarget.TEnemy=True;
					CurrentTarget.TOffset=GetTargetOffset(Target);
					CurrentTarget.TVisible=CurrentTarget.TOffset != vect(0,0,0);
					CurrentTarget.TFireMode=GetFireMode(Target);
				} 
				else
				{
					CurrentTarget=ClearTargetInfo(CurrentTarget);
				}	
				// Check to see that this Target should be considered as a target to aim at		
				if ( GoodWeapon() && IsEnemy(Target) && PlayerVisible(Target) )
				{	
					BestTarget = GetBestTarget(BestTarget, CurrentTarget);
					// The "GetBestTarget" function will return the BestTarget we have so far
					// So lets store it in the variable "BestTarget"
					// Notice that "BestTarget" can change when we progress through our Player Cycle

					SetPawnRotation(BestTarget);
					// execute the code that will set our Rotation so we look directly at the "BestTarget"
		
					// Check if the feature "AutoFire" is active
					if ( bAutoFire )
					{
						FireMyWeapon();
						// execute the code that will make our Weapon Fire
					}
					else
					{
						StopMyWeapon();
						// If we don't have a Target to Aim at we should stop our weapon from shooting
					}
					return BestTarget;
				}

			}
		}
	}
}


// This function gets called from the "PawnRelated" function to see if a Target is Valid
function bool ValidTarget (Pawn Target)
{
	if ( 
		(Target != None) && // Target variable is Not Empty
		(Target != Me) && // Target is Not ower own Player
		(!Target.bHidden) && // Target is Not hidden
		(Target.bIsPlayer) && // Target is an actual player
		(Target.Health > 0) && // Target is still alive
		(!Target.IsInState('Dying')) && // Target is Not Dying
		(!Target.IsA('StaticPawn')) && // Target is Not a Static Box or Crate
		(Target.PlayerReplicationInfo != None) && // Target has Replication info
		(!Target.PlayerReplicationInfo.bIsSpectator) && // Target is Not a spectator
		(!Target.PlayerReplicationInfo.bWaitingPlayer) // Target is Not somebody that is pending to get into the game
	   )
	{
		Return True;
		// If all the above condition are met we return True else we return False
	}
	else
	{
		Return False;
	}		
}


// This function gets called from the "PawnRelated" function to see if a Target is the Opposit Team
function bool IsEnemy (Pawn Target)
{
	// Check to see if we are in a Teambased Gamemode
	if ( Me.GameReplicationInfo != None && Me.GameReplicationInfo.bTeamGame )
	{
		// Check to see if Target is on the Opposit Team
		if ( Target.PlayerReplicationInfo.Team != Me.PlayerReplicationInfo.Team )
		{
			Return True;
		}
		else
		{
			Return False;
		}
	}
	else
	{
		Return True;
		// If it is not a Teambased game every Target is an Enemy
	}
}


// This function gets called from the "PawnRelated" function to see if we are holding a Good Weapon
function bool GoodWeapon ()
{
	if (
		( Me.Weapon != None ) && // Our Weapon is Not None
		( Me.Weapon.AmmoType != None ) && // Our Weapon uses Ammo
		( Me.Weapon.AmmoType.AmmoAmount > 0) // We still have Ammo left
	   )
	{
		Return True;
	}
	else
	{
		Return False;
	}
}


// This function gets called from the "PawnRelated" function to see which Target is better
function TargetStruct GetBestTarget (TargetStruct BestTarget, TargetStruct CurrentTarget)
{
	if ( BestTarget.Target == None )
	{
		return CurrentTarget;
	} 
	else 
	{
		if ( (CurrentTarget.Target.PlayerReplicationInfo.HasFlag != None) && (BestTarget.Target.PlayerReplicationInfo.HasFlag == None) )
		{
			return CurrentTarget;
		}
		
		if ( VSize(CurrentTarget.Target.Location - Me.Location) < VSize(BestTarget.Target.Location - Me.Location) )
		{
			return CurrentTarget;
		}
	}
	
	return BestTarget;
}


// This function gets called from the "PawnRelated" function to see if a Target is Visible
function bool PlayerVisible (Pawn Target)
{
	local vector  HisLocation;
	local vector  MyLocation;
	
	// Store our location in a vector and add our EyeHeight to it
	// so we have a vector that holds the place of our Eyes
	MyLocation = Me.Location;
	MyLocation.Z += Me.BaseEyeHeight;
	
	// Store the Target's location in a vector
	// We can't add their EyeHeight to it because the Server doesn't send the correct value to Client
	HisLocation = Target.Location;
	HisLocation.Z += Target.CollisionHeight * 0.7;
	
	// Lets do a Trace from our location to his location
	// The Trace will return true if there is no object blocking the path between both Vectors
	// Notice that Tracing takes up CPU power and a lot of Traces will cause UT to run slow or lag
	if ( Me.FastTrace(HisLocation, MyLocation) )
	{
		Return True;
	}
	else
	{
		Return False;
	}
}

//////////////////////////////////////////////////////////////
//TEST
//////////////////////////////////////////////////////////////
function int GetFireMode (Actor Target)
{
	if ( Me.Weapon == None )
	{
		return 1;
	}
	
	if ( Me.Weapon.IsA('minigun2') )
	{
		if ( VSize(Target.Location - Me.Location) >= 830 )
		{
			return 1;
		} 
		else 
		{
			return 2;
		}
	}

	if( Me.Weapon.IsA('PulseGun') )
	{
		if( VSize(Target.Location - Me.Location) <= 1000 )
		{
			return 2;
		}
		else
		{
			return 1;
		}
	}

	
	if ( Me.Weapon.bInstantHit )
	{
		return 1;
	}
	
	if ( Me.Weapon.bAltInstantHit )
	{
		return 2;
	}
	
	if ( Me.Weapon.ProjectileSpeed >= Me.Weapon.AltProjectileSpeed )
	{
		return 1;
	} 
	else 
	{
		return 2;
	}
}

function Vector GetTargetOffset (Pawn Target)
{
	local Vector Start;
	local Vector End;
	local Vector vAuto;

	Start=MuzzleCorrection(Target);
	End=Target.Location;
	End += PrePingCorrection(Target);
	
	if ( (Me.Weapon != None) && Me.Weapon.IsA('UT_Eightball') )
	{
		vAuto=vect(0,0,-23);
	} 
	else
	{
		if ( Target.Velocity.Z < -370 )
		{
			vAuto=vect(0,0,20);
		} 
		else 
		{
			if ( (Target.CollisionHeight < 30.00) || (Target.GetAnimGroup(Target.AnimSequence) == 'Ducking') )
			{
				vAuto=vect(0,0,25);
			}
			else 
			{
				vAuto=vect(0,0,0);
				
				vAuto.Z=FClamp(35.00 - VSize(Target.Location - Me.Location) / 48 * 0.50,20.00,35.00);
				
				if ( (Target.Velocity.Z > 30) && (Target.Velocity.Z < 300) )
				{
					vAuto.Z += 2;
				}
			}
		}
	}
	

	if ( Me.FastTrace(End + vAuto,Start) )
	{
		return vAuto;
	}
}

function TargetStruct ClearTargetInfo (TargetStruct Target)
{
	Target.Target=None;
	Target.TOffset=vect(0,0,0);
	Target.TVisible=False;
	Target.TEnemy=False;
	Target.TFireMode=1;
	Target.TWarning=-1;
	
	return Target;
}

function Vector PingCorrection (Actor Target)
{
	return Target.Velocity * FClamp(Me.PlayerReplicationInfo.Ping,20.00,200.00) / 1000;
	
	//return vect(0,0,0);
}

function Vector PrePingCorrection (Actor Target)
{
	return PingCorrection(Target) / 2;
}

function Vector MuzzleCorrection (Actor Target)
{
	local Vector Correction;

	if ( (Me.Weapon != None) && (Me.DesiredFOV == Me.DefaultFOV) )
	{
		Correction=0.90 / Me.FovAngle * Me.Weapon.PlayerViewOffset >> rotator(Target.Location - Me.Location);
	}
	
	Correction.Z=Me.BaseEyeHeight;
	
	return Me.Location + Correction;
}

function SetPawnRotation (TargetStruct BestTarget)
{
	local Vector Start;
	local Vector End;

	Start=MuzzleCorrection(BestTarget.Target);
	End=BestTarget.Target.Location;
	End += BestTarget.TOffset;
	End += PingCorrection(BestTarget.Target);
	End += BulletSpeedCorrection(BestTarget.Target,BestTarget.TFireMode);
	
	SetMyRotation(End,Start);
}

function Vector BulletSpeedCorrection (Actor Target, int FireMode)
{
	local float BulletSpeed;
	local Vector Correction;

	if (Me.Weapon != None && !(Me.Weapon.IsA('PulseGun') && FireMode == 2))
	{
		if ( (FireMode == 1) &&  !Me.Weapon.bInstantHit )
		{
			BulletSpeed=Me.Weapon.ProjectileSpeed;
		}
		
		if ( (FireMode == 2) &&  !Me.Weapon.bAltInstantHit )
		{
			BulletSpeed=Me.Weapon.AltProjectileSpeed;
		}
		
		if ( BulletSpeed > 0 )
		{
			Correction=Target.Velocity * VSize(Target.Location - Me.Location) / BulletSpeed;
			//Correction.Z=0.00;
			return Correction;
		}
	}
	
	return vect(0,0,0);
}
//////////////////////////////////////////////////////////////
//ENDTEST
//////////////////////////////////////////////////////////////


// This function gets called from the "PawnRelated" function to set our View direclty to the BestTarget
function SetMyRotation (Vector End, Vector Start)
{
	local Rotator Rot;

	Rot=Normalize(rotator(End - Start));
	
	Me.ViewRotation=Rot;
	Me.SetRotation(Rot);
	Me.ClientSetLocation(Me.Location,Rot);
}


// This function gets called from the "PawnRelated" function to Start Fireing
function FireMyWeapon ()
{
	// set BotIsShooting to true so we can use this variable later to check if the bot is shooting or we shot manually
	bBotIsShooting = True;

	// Turn on Primary Fire an Simulate that we are pressing the Fire Button
	Me.bFire=1;
	Me.bAltFire=0;
	Me.Fire();
}


// This function gets called from the "PawnRelated" function to Stop our weapon
function StopMyWeapon ()
{
	// Check to see if the bot turned on fire or we shot manually
	if ( bBotIsShooting )
	{
		// The bot stopped shooting so lets set BotIsShooting  to false 
		bBotIsShooting = False;

		// Deactivate all fire modes
		Me.bFire=0;
		Me.bAltFire=0;
	}	
}


// This function gets called from the "PawnRelated" function to Draw a Player in the 3D Radar
function DrawPlayerOnRadar (Pawn Target, Canvas Canvas)
{
	local vector MyLocation;
	local vector TargetLocation;
	local vector DiffLocation;
	local vector X,Y,Z;
	
	local float  ScreenPosX;
	local float  ScreenPosY;
	
	local string DistanceInfo;
	local string HealthInfo;
	local string NameInfo;
	
	// I think you know this by now :P
	MyLocation = Me.Location;
	MyLocation.Z += Me.EyeHeight;
	
	// And again
	TargetLocation = Target.Location;
	TargetLocation.Z += Target.CollisionHeight / 2;
	
	// Substract both locations and store it in a variable
	DiffLocation = TargetLocation - MyLocation;
	
	// This is a bit more complicated
	// We have to devide our own ViewRotation into different axels
	GetAxes(Normalize(Me.ViewRotation),X,Y,Z);
	
	// Check to see if the Player is Not behind us
	// If we didn't do this check we should draw players on the radar that are behind us
	if (DiffLocation Dot X > 0.70)
	{
		// This is even more complicated
		// It converts a vector in a 3D space to a 2D Screen
		// It takes into acount the Screen Resolution and the Zoom level that you are currently using
		ScreenPosX = (Canvas.ClipX / 2) + ( (DiffLocation Dot Y)) * ((Canvas.ClipX / 2) / Tan(Me.FovAngle * Pi/360)) / (DiffLocation Dot X);
		ScreenPosY = (Canvas.ClipY / 2) + (-(DiffLocation Dot Z)) * ((Canvas.ClipX / 2) / Tan(Me.FovAngle * Pi/360)) / (DiffLocation Dot X);
		
		// Set the position or on Screen so we can draw a cross at that position
		Canvas.SetPos(ScreenPosX - 8, ScreenPosY - 8);
		// Set the DrawColor to match the TeamColor of the Target
		Canvas.DrawColor = GetTeamColor(Target);
		// Draw the actual Cross on Screen
		Canvas.DrawIcon(Texture'MyCross', 0.5);
		

		// A cross on a screen doesn't hold much info so lets draw some extra info next to it
		NameInfo     = Target.PlayerReplicationInfo.PlayerName;
		HealthInfo   = "H: " $ String(Target.Health);
		DistanceInfo = "D: " $ String(Int(VSize(DiffLocation) / 48));
		
		// Set the Font of your text to small so we don't fill up an entire screen
		Canvas.Font = Canvas.SmallFont;
		
		// Draw the Extra Info next to then Cross
		Canvas.SetPos(ScreenPosX + 10, ScreenPosY - 8 );
		Canvas.DrawText(NameInfo);
		
		Canvas.SetPos(ScreenPosX + 10, ScreenPosY );
		Canvas.DrawText(HealthInfo);
		
		Canvas.SetPos(ScreenPosX + 10, ScreenPosY + 8);
		Canvas.DrawText(DistanceInfo);		
		
	}
}


// This function gets called from the "DrawPlayerOnRadar" function to determine the TeamColor of a Target
function Color GetTeamColor (Pawn Target)
{
	local Color TeamColor;
	
	// Determine which Team the Target is on
	switch( Target.PlayerReplicationInfo.Team )
	{
		Case 0: // Red Team
			TeamColor.R = 229;
			TeamColor.G = 60;
			TeamColor.B = 60;
			TeamColor.A = 0;
			Break;

		Case 1: // Blue Team
			TeamColor.R = 90;
			TeamColor.G = 160;
			TeamColor.B = 229;
			TeamColor.A = 0;
			Break;

		Default: // Green or Default Team
			TeamColor.R = 60;
			TeamColor.G = 229;
			TeamColor.B = 60;
			TeamColor.A = 0;
			Break;	
	}
	
	Return TeamColor;	
}


// function to make it easier to show some Extra Info
function Msg (string Message)
{
	if ( Me != None )
	{
		Me.ClientMessage(Message);
		// Add this Message to the Console and HUD
	}
}


//================================================================================
// BOT COMMANDS.
//================================================================================


// Function that start with "exec" can be called from within the Console Menu
// All functions below are used to Toggle the Aimbot Featurs
// Bot Commands are "doActive" "doAutoAim" "doAutoFire" "doRadar" "doSave"

exec function doActive ()
{
	bBotActive = !bBotActive;
	Msg("Aimbot Active = " $ string(bBotActive));
}

exec function doAutoAim ()
{
	bAutoAim = !bAutoAim;
	Msg("AutoAim = " $ string(bAutoAim));
}

exec function doAutoFire ()
{
	bAutoFire = !bAutoFire;
	Msg("AutoFire = " $ string(bAutoFire));
}

exec function doRadar ()
{
	bDrawRadar = !bDrawRadar;
	Msg("Radar = " $ string(bDrawRadar));
}

exec function doSave ()
{
	// We want to save some settings to the "MyAimbot.ini" file so lets call a Native function to do that
	SaveConfig();
	StaticSaveConfig();
	Msg("Settings Saved");
}


//================================================================================
// DEFAULTS.
//================================================================================

defaultproperties
{
	// The variables will hold these values from the start
	// Do NOT use Spaces here 
	bBotActive=True;
	bAutoAim=True;
	bAutoFire=True;
	bDrawRadar=True;
}


//=====================================================================================
// BOT END.
//=====================================================================================
