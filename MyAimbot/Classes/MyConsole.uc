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


// if a config statement is before the variable, you will be able to save the variable into "MyAimbot.ini"
var config bool bBotActive;
var config bool bAutoAim;
var config bool bAutoFire;
var config bool bDrawRadar;
var config int MySetSlowSpeed;
var config int LastFireMode;

// These vars will not be saved to the .ini file
var PlayerPawn Me;
var Pawn CurrentTarget;



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

exec function Fire(optional float F)
{
	Me.Fire();
	LastFireMode=1;
}
exec function AltFire(optional float F)
{
	Me.AltFire();
	LastFireMode=2;
}

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

	Canvas.SetPos(20, Canvas.ClipY / 2 + 40);
	Canvas.DrawText("RotationSpeed    : " $ String(MySetSlowSpeed));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 60);
	Canvas.DrawText("FireMode    : " $ String(LastFireMode));
	
}


// This function holds the code that will cycle through all Players on the Map
function PawnRelated(Canvas Canvas)
{
	local Pawn Target;

	if(!Me.LineOfSightTo(CurrentTarget) || !ValidTarget(Target))
	{
		CurrentTarget = None;
	}
	// Cycle through all players (Pawns) on the Map and store them in a temporarry variable "Target"
	foreach Me.Level.AllActors(Class'Pawn', Target)
	{
		// Check if this Target is Valid, we don't want to be Aiming at spectator or people that are allready dead :P
		if ( ValidTarget(Target) )
		{	
			// Check if the feature "AutoAim" is active
			if ( bAutoAim )
			{
				if ( GoodWeapon() && Me.LineOfSightTo(Target) )
				{	
					if(CurrentTarget == None)
					{
						CurrentTarget = Target;
					}
					if ( VSize(Target.Location - Me.Location) < VSize(CurrentTarget.Location - Me.Location) )
					{
						CurrentTarget = Target;
					}

					SetPawnRotation(CurrentTarget);
				}

			}
		}
	}
}


// This function gets called from the "PawnRelated" function to see if a Target is Valid
function bool ValidTarget (Pawn Target)
{
	if(Target.IsA('FortStandard') && Me.PlayerReplicationInfo.Team != Assault(Target.Level.Game).Defender.TeamIndex)
	{
		return true;
	}

	if(Target.IsA('TeamCannon') && !TeamCannon(Target).SameTeamAs(Me.PlayerReplicationInfo.Team))
	{
		return true;
	}

	if ( 
		(Target != None) && // Target variable is Not Empty
		(Target != Me) && //Target is Not ower own Player
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
	else
	{
		Return False;
	}		
}

// This function gets called from the "PawnRelated" function to see if we are holding a Good Weapon
function bool GoodWeapon ()
{
	if (Me.Weapon != None)
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

function Vector GetTargetOffset (Pawn Target)
{
	local Vector Start;
	local Vector End;
	local Vector vAuto;

	Start=MuzzleCorrection(Target);
	End=Target.Location;
	End += PrePingCorrection(Target); 
	vAuto = vect(0,0,0);

	vAuto.Z = Me.BaseEyeHeight;
	
	//Try high
	if ( Me.FastTrace(End + vAuto,Start) )
	{
		return vAuto;
	}

	vAuto.Z = 0.90 * Target.CollisionHeight;

	//Try head
	if( Me.FastTrace(End + vAuto,Start) )
	{
		return vAuto;
	}

	vAuto.Z = -0.5 * Target.CollisionHeight;;
	//Try low
	if ( Me.FastTrace(End + vAuto,Start) )
	{
		return vAuto;
	}

	
}

function Vector PingCorrection (Pawn Target)
{
	return Target.Velocity * FClamp(Me.PlayerReplicationInfo.Ping,20.00,200.00) / 1000;
	
	//return vect(0,0,0);
}

function Vector PrePingCorrection (Pawn Target)
{
	return PingCorrection(Target) / 2;
}

function Vector MuzzleCorrection (Pawn Target)
{
	local Vector Correction;
	local Vector MyLocation;

	MyLocation = Me.Location;
	MyLocation.Z += Me.BaseEyeHeight;

	if (Me.Weapon != None)
	{
		Correction = Me.Weapon.FireOffset;
	}
	
	return MyLocation + Correction;
}

function SetPawnRotation (Pawn Target)
{
	local Vector Start;
	local Vector End;
	local Vector Predict;

	Start=MuzzleCorrection(Target);
	End=Target.Location;
	End += GetTargetOffset(Target);
	End += PingCorrection(Target);

	Predict = End + BulletSpeedCorrection(Target);

	if(Me.FastTrace(Predict, Start))
	{
		End = Predict;
	}
	
	SetMyRotation(End,Start);
}

function Vector BulletSpeedCorrection (Pawn Target)
{
	local float BulletSpeed;
	local Vector Correction;
	
	if (Me.Weapon != None)
	{
		if ( (LastFireMode == 1) &&  !Me.Weapon.bInstantHit )
		{
			BulletSpeed=Me.Weapon.ProjectileSpeed;
		}
		
		if ( (LastFireMode == 2) &&  !Me.Weapon.bAltInstantHit )
		{
			BulletSpeed=Me.Weapon.AltProjectileSpeed;
		}
		
		if ( BulletSpeed > 0 )
		{
			Correction=Target.Velocity * VSize(Target.Location - Me.Location) / BulletSpeed;

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

	Rot=RotateSlow(Normalize(Me.ViewRotation),Rot);
	
	Me.ViewRotation=Rot;
	Me.SetRotation(Rot);
	Me.ClientSetLocation(Me.Location,Rot);
}

function Rotator RotateSlow (Rotator RotA, Rotator RotB)
{
	local Rotator RotC;
	local int Pitch;
	local int Yaw;
	local int Roll;
	local bool Bool1;
	local bool Bool2;
	local bool Bool3;

	Bool1=Abs(RotA.Pitch - RotB.Pitch) <= MySetSlowSpeed;
	Bool2=Abs(RotA.Yaw - RotB.Yaw) <= MySetSlowSpeed;
	Bool3=Abs(RotA.Roll - RotB.Roll) <= MySetSlowSpeed;
	
	if ( RotA.Pitch < RotB.Pitch )
	{
		Pitch=1;
	} 
	else 
	{
		Pitch=-1;
	}
	
	if ( (RotA.Yaw > 0) && (RotB.Yaw > 0) )
	{
		if ( RotA.Yaw < RotB.Yaw )
		{
			Yaw=1;
		} 
		else 
		{
			Yaw=-1;
		}
	} 
	else 
	{
		if ( (RotA.Yaw < 0) && (RotB.Yaw < 0) )
		{
			if ( RotA.Yaw < RotB.Yaw )
			{
				Yaw=1;
			} 
			else 
			{
				Yaw=-1;
			}
		} 
		else 
		{
			if ( (RotA.Yaw < 0) && (RotB.Yaw > 0) )
			{
				if ( Abs(RotA.Yaw) + RotB.Yaw < 32768 )
				{
					Yaw=1;
				} 
				else 
				{
					Yaw=-1;
				}
			} 
			else 
			{
				if ( (RotA.Yaw > 0) && (RotB.Yaw < 0) )
				{
					if ( RotA.Yaw + Abs(RotB.Yaw) < 32768 )
					{
						Yaw=-1;
					} 
					else 
					{
						Yaw=1;
					}
				}
			}
		}
	}
	
	if ( RotA.Roll < RotB.Roll )
	{
		Roll=1;
	} 
	else 
	{
		Roll=-1;
	}
	
	if ( !Bool1 )
	{
		RotC.Pitch=RotA.Pitch + Pitch * MySetSlowSpeed;
	} 
	else 
	{
		RotC.Pitch=RotB.Pitch;
	}
	
	if ( !Bool2 )
	{
		RotC.Yaw=RotA.Yaw + Yaw * MySetSlowSpeed;
	} 
	else 
	{
		RotC.Yaw=RotB.Yaw;
	}
	
	if ( !Bool3 )
	{
		RotC.Roll=RotA.Roll + Roll * MySetSlowSpeed;
	}
	else 
	{
		RotC.Roll=RotB.Roll;
	}
	
	return Normalize(RotC);
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

exec function AddSpeed()
{
	MySetSlowSpeed += 100;
	Msg("Speed = " $ string(MySetSlowSpeed));
}

exec function ReduceSpeed()
{
	MySetSlowSpeed -= 100;
	Msg("Speed = " $ string(MySetSlowSpeed));
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
	MySetSlowSpeed=600;
	LastFireMode=1;
}


//=====================================================================================
// BOT END.
//=====================================================================================