//=====================================================================================
// BOT START.
//=====================================================================================
class MyConsole extends UTConsole Config(MyAimbot);

var config bool bAutoAim;
var config int MySetSlowSpeed;
var config bool bUseSplash;
var config bool bAimPlayers;
var config bool bRotateSlow;
var config bool bDebug;

var PlayerPawn Me;
var Pawn CurrentTarget;
var int LastFireMode;
var Vector AltOffset;

var Vector Destination;
var Actor TargetToFollow;
var string Status;
var Actor NextNode;

event PostRender (Canvas Canvas)
{
	Super.PostRender(Canvas); 

	MyPostRender(Canvas);
}

event Tick( float Delta )
{
	Super.Tick( Delta );

	if ( (Root != None) && bShowMessage )
		Root.DoTick( Delta );

	Begin();
	if(Destination != vect(0, 0, 0) || TargetToFollow != None)
	{
		MoveToDestination();
	}
	else
	{
		if(Status != "Normal")
		{
			Status = "Normal";
		}
	}
}

//================================================================================
// MAIN BOT.
//================================================================================

exec function Fire(optional float F)
{
	LastFireMode=1;
	Me.Fire();
}
exec function AltFire(optional float F)
{
	LastFireMode=2;
	Me.AltFire();
}

function Begin()
{
	Me = Viewport.Actor;

	if (Me == None || Me.PlayerReplicationInfo == None)
	{
		Return;
	}
		
	if(!bAutoAim || Me.IsInState('GameEnded'))
	Return;
	
	if(Me.Weapon != None && !Me.Weapon.IsA('Translocator'))
	PawnRelated();
}

function MyPostRender (Canvas Canvas)
{
	DrawMySettings(Canvas);
}


function DrawMySettings (Canvas Canvas)
{
	Canvas.Font = Canvas.SmallFont;
	
	Canvas.SetPos(20, Canvas.ClipY / 2);
	Canvas.DrawText("[MyAimbot]");
	
	Canvas.SetPos(20, Canvas.ClipY / 2 + 10 );
	Canvas.DrawText("----------");	
	
	Canvas.SetPos(20, Canvas.ClipY / 2 + 20);
	Canvas.DrawText("AutoAim  : " $ String(bAutoAim));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 40);
	Canvas.DrawText("Use Splash  : " $ String(bUseSplash));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 60);
	Canvas.DrawText("Rotate Slow  : " $ String(bRotateSlow));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 80);
	Canvas.DrawText("Aim Players  : " $ String(bAimPlayers));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 90);
	Canvas.DrawText("----------");	

	Canvas.SetPos(20, Canvas.ClipY / 2 + 100);
	Canvas.DrawText("RotationSpeed  : " $ String(MySetSlowSpeed));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 120);
	Canvas.DrawText("FireMode  : " $ String(LastFireMode));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 140);
	Canvas.DrawText("Status  : " $ Status);


	/////////////////////////////////
	// DEBUG
	/////////////////////////////////

	if(bDebug)
	{
		Canvas.SetPos(20, Canvas.ClipY / 2 + 160);
		Canvas.DrawText("---DEBUG---");

		Canvas.SetPos(20, Canvas.ClipY / 2 + 180);
		Canvas.DrawText("Physics  : " $  GetEnum(enum'EPhysics', CurrentTarget.PlayerReplicationInfo.Physics));

		Canvas.SetPos(20, Canvas.ClipY / 2 + 200);
		Canvas.DrawText("aForward : " $  Me.aForward);

		Canvas.SetPos(20, Canvas.ClipY / 2 + 220);
		Canvas.DrawText("aStrafe : " $  Me.aStrafe);
	}
}

function PawnRelated()
{
	local Pawn Target;

	if(CurrentTarget != None)
	{
		if(!VisibleTarget(CurrentTarget) || !ValidTarget(CurrentTarget))
		{
			CurrentTarget = None;
		}
	}

	foreach Me.Level.AllActors(Class'Pawn', Target)
	{
		if ( ValidTarget(Target) )
		{	
			if ( VisibleTarget(Target) )
			{	
				if(CurrentTarget == None)
				{
					CurrentTarget = Target;
				}
				if ( VSize(Target.Location - Me.Location) < VSize(CurrentTarget.Location - Me.Location) )
				{
					CurrentTarget = Target;
				}
			}
		}
	}
	if(CurrentTarget != None)
	{
		SetPawnRotation(CurrentTarget);
	}
}

function bool VisibleTarget (Pawn Target)
{
	local float VectorsX[3];
	local float VectorsY[3];
	local float VectorsZ[3];
	local Vector Start, Check;
	local int x,y,z;

	if(Me.LineOfSightTo(Target) || Me.CanSee(Target))
	{
		return true;
	}

	Start = MuzzleCorrection(Target);

	VectorsX[0] = Target.Location.X + (-1.0 * Target.CollisionRadius);
	VectorsX[1] = Target.Location.X;
	VectorsX[2] = Target.Location.X + (1.0 * Target.CollisionRadius);

	VectorsY[0] = Target.Location.Y + (-1.0 * Target.CollisionRadius);
	VectorsY[1] = Target.Location.Y;
	VectorsY[2] = Target.Location.Y + (1.0 * Target.CollisionRadius);

	VectorsZ[0] = Target.Location.Z + (-1.0 * Target.CollisionHeight);
	VectorsZ[1] = Target.Location.Z;
	VectorsZ[2] = Target.Location.Z + (1.0 * Target.CollisionHeight);

	for(x=0; x<=2; x++)
	{
		for(y=0; y<=2; y++)
		{
			for(z=0; z<=2; z++)
			{
				Check.X = VectorsX[x];
				Check.Y = VectorsY[y];
				Check.Z = VectorsZ[z];
				if(Me.FastTrace(Check, Start)) 
				{
					return true;
				}
			}
		}
	}
}

function bool ValidTarget (Pawn Target)
{
	If(Target.IsA('ScriptedPawn')) //If is a monster (Monster Hunt)
	{
		if(ScriptedPawn(Target).AttitudeTo(Me) < 4 &&
		!Target.IsInState('Dying') && Target.Health > 0)
		{
			return true;
		}
	}

	If(bAimPlayers)
	{
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
			if ( Me.GameReplicationInfo.bTeamGame )
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
}

function SetPawnRotation (Pawn Target)
{
	local Vector Start;
	local Vector End;
	local Vector Predict;
	local Projectile Ball;
	local Pawn BallTarget;

	
	Start=MuzzleCorrection(Target);
	End=Target.Location;
	End += GetTargetOffset(Target);

	Predict = End + BulletSpeedCorrection(Target);

	if(Me.FastTrace(Predict, Start))
	{
		End = Predict;
	}

	if(Me.Weapon.IsA('ShockRifle') || Me.Weapon.IsA('ASMD'))
	{
		foreach Me.Level.AllActors(Class'Projectile', Ball)
		{
			if(Ball.IsA('ShockProj') || Ball.IsA('TazerProj'))
			{
				foreach Me.Level.AllActors(Class'Pawn', BallTarget)
				{	
					if (ValidTarget(BallTarget) && VSize(BallTarget.Location - Ball.Location) < (250 + BallTarget.CollisionRadius) && Me.LineOfSightTo(Ball))
					{	
						End = Ball.Location;
						break;
					}						
				}
			}
		}
	}

	SetMyRotation(End,Start);
}

function Vector MuzzleCorrection (Pawn Target)
{
	local Vector Correction,X,Y,Z;

	GetAxes(Me.ViewRotation,X,Y,Z);

	if (Me.Weapon != None)
	{
		Correction = Me.Location + Me.Weapon.CalcDrawOffset() + Me.Weapon.FireOffset.X * X + Me.Weapon.FireOffset.Y * Y + Me.Weapon.FireOffset.Z * Z;
	}
	
	return Correction;
}

function Vector GetTargetOffset (Pawn Target)
{
	local Vector Start;
	local Vector End;
	local Vector vAuto;
	local Actor HitActor;

	local Vector HitLocation, HitNormal;

	Start=MuzzleCorrection(Target);
	End=Target.Location;
	vAuto = vect(0,0,0);

	if(bUseSplash && 
	((LastFireMode == 1 && Me.Weapon.bRecommendSplashDamage) || (LastFireMode == 2 && Me.Weapon.bRecommendAltSplashDamage)) && 
	Target.Velocity != vect(0,0,0) &&
	Target.Velocity.Z == 0)
	{
		vAuto.Z = -0.9 * Target.CollisionHeight;
	}
	else
	{
		vAuto.Z = 0.5 * Target.CollisionHeight;
	}
	

	HitActor = Me.Trace(HitLocation, HitNormal, End + vAuto, Start);
	if (HitActor != None && (HitActor == Target || HitActor.IsA('Projectile')) ) //if can hit target (and ignore projectile between player and target)
	{
		return vAuto;
	}

	HitActor = Me.Trace(HitLocation, HitNormal, End + AltOffset, Start);
	if(HitActor != None && (HitActor == Target || HitActor.IsA('Projectile')))
	{
		return AltOffset;
	}

	AltOffset.X = RandRange(-1.0, 1.0) * Target.CollisionRadius;
	AltOffset.Y = RandRange(-1.0, 1.0) * Target.CollisionRadius;
	AltOffset.Z = RandRange(-1.0, 1.0) * Target.CollisionHeight;
}

function Vector BulletSpeedCorrection (Pawn Target)
{
	local float BulletSpeed, TargetDist;
	local Vector Correction, GravityCorrection, Start;

	Start = MuzzleCorrection(Target);
	
	if (Me.Weapon != None)
	{
		if ( (LastFireMode == 1) &&  !Me.Weapon.bInstantHit )
		{
			BulletSpeed = Me.Weapon.ProjectileClass.default.speed;
		}
		
		if ( (LastFireMode == 2) &&  !Me.Weapon.bAltInstantHit )
		{
			BulletSpeed = Me.Weapon.AltProjectileClass.default.speed;
		}
		
		if ( BulletSpeed > 0 )
		{
			TargetDist = VSize(Target.Location - Start);
			GravityCorrection = Target.Velocity * TargetDist / BulletSpeed + Target.Region.Zone.ZoneGravity * Square(TargetDist / BulletSpeed) * 0.5;

			if(TargetFall(Target) && Me.FastTrace(GravityCorrection, Start))
			{
				
				Correction = Target.Velocity * TargetDist / BulletSpeed + Target.Region.Zone.ZoneGravity * Square(TargetDist / BulletSpeed) * 0.5;
			}
			else
			{
				Correction = Target.Velocity * TargetDist / BulletSpeed;
			}
			return Correction;			
		}
	}
	
	return vect(0,0,0);
}

function bool TargetFall(Pawn Target)
{
	if((Target.Physics == PHYS_Falling || (!Target.bCanFly && !Target.Region.Zone.bWaterZone)))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function SetMyRotation (Vector End, Vector Start)
{
	local Rotator Rot;

	Rot=Normalize(rotator(End - Start));

	if(bRotateSlow)
	{
		Rot=RotateSlow(Normalize(Me.ViewRotation),Rot);
	}
	
	Me.ViewRotation=Rot;
	//Me.SetRotation(Rot);
	//Me.ClientSetLocation(Me.Location,Rot);
}

function MoveToDestination()
{
	local float Distance, MyRot;
	local Vector Dir;

	if(NextNode != None && (VSize(NextNode.Location - Me.Location) < 64.0f || !Me.FastTrace(NextNode.Location, Me.Location)))
	{
		Msg("Node reached");
		NextNode.Destroy();
		NextNode = None;
	}

	if(Destination != vect(0, 0, 0) && NextNode == None)
	{
    	Distance = Me.VSize(Destination - Me.Location);
		if (Distance > 200.0f)
    	{	
			NextNode = Me.FindPathTo(Destination, True, True);
			Status = "Moving...";
		}
		else
		{
			MoveStop();
			Msg("Destination reached");
		}
	}
	else if(TargetToFollow != None && NextNode == None) 
	{
		NextNode = Me.FindPathToward(TargetToFollow, True, True); 
		Status = "Following...";
	}

	if(NextNode != None)
	{
		MyRot = Normalize(Me.ViewRotation).Yaw * 360 / 65536;

		if(MyRot < 0)
		{
			MyRot += 360;
		}

		MyRot = MyRot * Pi / 180;

		Dir = Normal(NextNode.Location - Me.Location);
		Msg("Node dist : "$ VSize(Me.Location - NextNode.Location));

		Me.aForward = Cos(MyRot) * Dir.X + Sin(MyRot) * Dir.Y;
		Me.aStrafe = -Sin(MyRot) * Dir.X + Cos(MyRot) * Dir.Y;
	}
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

exec function doAutoAim ()
{
	bAutoAim = !bAutoAim;
	Msg("AutoAim = " $ string(bAutoAim));
}

exec function SetRotationSpeed(int num)
{
	MySetSlowSpeed = num;

	Msg("Rotation Speed = " $ string(MySetSlowSpeed));
}

exec function IncreaseSpeed()
{
	if(MySetSlowSpeed < 0)
	{
		MySetSlowSpeed = 0;
	}
	else
	{
		MySetSlowSpeed += 100;
	}

	Msg("Rotation Speed = " $ string(MySetSlowSpeed));
}

exec function ReduceSpeed()
{
	if(MySetSlowSpeed <= 0)
	{
		MySetSlowSpeed = 0;
	}
	else
	{
		MySetSlowSpeed -= 100;
	}

	Msg("Rotation Speed = " $ string(MySetSlowSpeed));
}

exec function UseSplash()
{
	bUseSplash = !bUseSplash;
	Msg("Use Splash = " $ string(bUseSplash));
}

exec function UseRotateSlow()
{
	bRotateSlow = !bRotateSlow;
	Msg("Rotate Slow = "$ string(bRotateSlow));
}

exec function UseDebug()
{
	bDebug = !bDebug;
	Msg("bDebug = "$ string(bDebug));
}

exec function AimPlayers()
{
	bAimPlayers = !bAimPlayers;
	Msg("bAimPlayers = "$ string(bAimPlayers));
}

exec function doSave()
{
	// We want to save some settings to the "MyAimbot.ini" file so lets call a Native function to do that
	SaveConfig();
	StaticSaveConfig();
	Msg("Settings Saved");
}

exec function help()
{
	Msg("doAutoAim = switch ON/OFF");
	Msg("SetRotationSpeed 'NUMBER' = Set rotation speed at 'NUMBER'");
	Msg("IncreaseSpeed = +100 to rotation speed");
	Msg("ReduceSpeed = -100 to rotation speed");
	Msg("UseSplash = Aim feet with rocket laucher");
	Msg("UseRotateSlow = enable/disable smooth aiming");
	Msg("UseDebug = enable/disable debug info (dev)");
	Msg("doSave = Save Settings");
}

exec function GodModeTeam(int Disable)
{
	local Pawn Target;

	if(Disable == 1)
	{
		foreach Me.Level.AllActors(Class'Pawn', Target)
		{
			
			if 
			( 
				(Target != None) && // Target variable is Not Empty
				(Target != Me) && //Target is Not ower own Player
				(Target.PlayerReplicationInfo != None) && // Target has Replication info
				(!Target.PlayerReplicationInfo.bIsSpectator) && // Target is Not a spectator
				(!Target.PlayerReplicationInfo.bWaitingPlayer) && // Target is Not somebody that is pending to get into the game
				(Me.GameReplicationInfo.bTeamGame) &&
				(Target.PlayerReplicationInfo.Team == Me.PlayerReplicationInfo.Team)
			)
			{
				Target.ReducedDamageType = 'All';
			}
		}
		Msg("God Mode Team on");
	}
	else if(Disable == 0)
	{
		foreach Me.Level.AllActors(Class'Pawn', Target)
		{
			if 
			( 
				(Target != None) && // Target variable is Not Empty
				(Target != Me) && //Target is Not ower own Player
				(Target.PlayerReplicationInfo != None) && // Target has Replication info
				(!Target.PlayerReplicationInfo.bIsSpectator) && // Target is Not a spectator
				(!Target.PlayerReplicationInfo.bWaitingPlayer) && // Target is Not somebody that is pending to get into the game
				(Me.GameReplicationInfo.bTeamGame) &&
				(Target.PlayerReplicationInfo.Team == Me.PlayerReplicationInfo.Team)
			)
			{
				Target.ReducedDamageType = '';
			}
		}
		Msg("God Mode Team off");
	}
}

exec function MoveTo(string name)
{
	local Pawn Target;

	foreach Me.Level.AllActors(Class'Pawn', Target)
	{
		if(Target.PlayerReplicationInfo.PlayerName == name)
		{
			Destination = Target.Location;
			if(TargetToFollow != None)
			{
				TargetToFollow = None;
			}

			Msg("Player found, move to "$ Target.PlayerReplicationInfo.PlayerName);
			return;
		}
	}
	Msg("Player name not found");
}

exec function MoveFollow(string name)
{
	local Pawn Target;

	foreach Me.Level.AllActors(Class'Pawn', Target)
	{
		if(Target.PlayerReplicationInfo.PlayerName == name)
		{
			TargetToFollow = Target;
			if(Destination != vect(0, 0, 0))
			{
				Destination = vect(0, 0, 0);
			}
			Msg("Player found, following "$ Target.PlayerReplicationInfo.PlayerName);
			return;
		}
	}
	Msg("Player name not found");
}

exec function MoveToRandom()
{
	Destination = Me.FindRandomDest().Location;
	Msg("Move to random dest");
}

exec function MoveToBest()
{
	local float MinWeight;

	Destination = Me.FindBestInventoryPath(MinWeight, true).Location;
	Msg("Move to inventory (??)");
}

exec function MoveToGoal()
{
	Destination = Me.specialGoal.Location;
	Msg("Move to goal");
}

exec function MoveStop()
{
	TargetToFollow = None;
	Destination = vect(0, 0, 0);
	Status = "Normal";
	Me.aForward = 0;
	Me.aStrafe = 0;
	Msg("Move stop");
}

//================================================================================
// DEFAULTS.
//================================================================================

defaultproperties
{
	bAutoAim=True;
	MySetSlowSpeed=300;
	LastFireMode=1;
	AltOffset=vect(0,0,0);
	bUseSplash=1;
	bRotateSlow=0;
	bDebug=0;
	bAimPlayers=1
}


//=====================================================================================
// BOT END.
//=====================================================================================