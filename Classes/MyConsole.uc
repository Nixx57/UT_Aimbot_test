//=====================================================================================
// BOT START.
//=====================================================================================
class MyConsole extends UTConsole Config(MyConsole);

var config bool bAutoAim;
var config int MySetSlowSpeed;
var config bool bUseSplash;
var config bool bAimPlayers;
var config bool bRotateSlow;
var config bool bUseLinearSpeed;
var config bool bDebug;
var config bool bShowOverlay;

var PlayerPawn Me;
var Pawn CurrentTarget;
var int LastFireMode;
var Vector AltOffset;

var Actor TargetToFollow;
var string Status;
var Actor NextNode;

struct PositionData
{
    var Vector Location;
    var float Time;
};

var PositionData PreviousLocations[65]; // Tableau circulaire
var int LocationIndex; // Indice pour le tableau

event PostRender (Canvas Canvas)
{
	Super.PostRender(Canvas); 

	if(bShowOverlay)
	{
		MyPostRender(Canvas);
	}	
}

event Tick( float Delta )
{
	Super.Tick( Delta );

	if ( (Root != None) && bShowMessage )
		Root.DoTick( Delta );

	Begin(Delta);

	if(Me.Destination != vect(0, 0, 0) || TargetToFollow != None)
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

function Begin(float Delta)
{
	Me = Viewport.Actor;

	if (Me == None || Me.PlayerReplicationInfo == None)
	{
		Return;
	}
		
	if(!bAutoAim || Me.IsInState('GameEnded'))
	Return;
	
	if(Me.Weapon != None && !Me.Weapon.IsA('Translocator'))
	PawnRelated(Delta);
}

function MyPostRender (Canvas Canvas)
{
	DrawMySettings(Canvas);
}


function DrawMySettings (Canvas Canvas)
{
	local string Str[11];
	local int initial, i;

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

	Canvas.SetPos(20, Canvas.ClipY / 2 + 100);
	Canvas.DrawText("Aim Players  : " $ String(bAimPlayers));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 110);
	Canvas.DrawText("----------");	

	Canvas.SetPos(20, Canvas.ClipY / 2 + 120);
	Canvas.DrawText("RotationSpeed  : " $ String(MySetSlowSpeed));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 140);
	Canvas.DrawText("FireMode  : " $ String(LastFireMode));

	Canvas.SetPos(20, Canvas.ClipY / 2 + 160);
	Canvas.DrawText("Status  : " $ Status);


	/////////////////////////////////
	// DEBUG
	/////////////////////////////////

	if(bDebug)
	{
		Canvas.SetPos(20, Canvas.ClipY / 2 + 180);
		Canvas.DrawText("---DEBUG---");
		i = 0;
		initial = 200;

		Str[0] = "Skill : "$String(Bot(CurrentTarget).Skill);
		Str[1] = "Accuracy : "$String(Bot(CurrentTarget).Accuracy);
		Str[2] = "bJumpy : "$String(Bot(CurrentTarget).bJumpy);
		Str[3] = "Alertness : "$String(Bot(CurrentTarget).Alertness);
		Str[4] = "CampingRate : "$String(Bot(CurrentTarget).CampingRate);
		Str[5] = "Aggressiveness  : "$String(Bot(CurrentTarget).Aggressiveness);
		Str[6] = "StrafingAbility : "$String(Bot(CurrentTarget).StrafingAbility);
		Str[7] = "BaseAggressiveness : "$String(Bot(CurrentTarget).BaseAggressiveness);
		Str[8] = "Acceleration : "$String(CalculateCustomAcceleration(CurrentTarget));
		Str[9] = "Velocity : "$String(CalculateCustomVelocity(CurrentTarget));

		for(i=0;i<ArrayCount(Str);i++)
		{			
			Canvas.SetPos(20, Canvas.ClipY / 2 + initial);
			Canvas.DrawText(Str[i]);
			initial += 20;
		}
	}
}

function UpdatePreviousLocations(Pawn Target, float DeltaTime)
{
	PreviousLocations[LocationIndex].Location = Target.Location;
	PreviousLocations[LocationIndex].Time = Me.Level.TimeSeconds; // Le temps de jeu actuel
	LocationIndex = (LocationIndex + 1) % ArrayCount(PreviousLocations);
}

function PawnRelated(float Delta)
{
	local Pawn Target;

	if(CurrentTarget != None)
	{
		if(!VisibleTarget(CurrentTarget) || !ValidTarget(CurrentTarget))
		{
			CurrentTarget = None;
		}
	}

	if(CurrentTarget == None)
	{
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
	}

	if(CurrentTarget != None)
	{
    	UpdatePreviousLocations(CurrentTarget, Delta);
		SetPawnRotation(CurrentTarget, Delta);
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

function SetPawnRotation (Pawn Target, float Delta)
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

	SetMyRotation(End,Start,Delta);
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

function Vector CalculateCustomVelocity(Pawn Target)
{
    local Vector Velocity, AverageVelocity;
    local float TimeDifference;
    local int i;
    
    AverageVelocity = vect(0,0,0);
    
    for(i=0; i < ArrayCount(PreviousLocations)-1; i++)
    {
        TimeDifference = PreviousLocations[(LocationIndex+i+1)% ArrayCount(PreviousLocations)].Time - PreviousLocations[(LocationIndex+i)% ArrayCount(PreviousLocations)].Time;
    	if (TimeDifference > 0)
    	{
	    	Velocity = (PreviousLocations[(LocationIndex+i+1)% ArrayCount(PreviousLocations)].Location - PreviousLocations[(LocationIndex+i)% ArrayCount(PreviousLocations)].Location) / TimeDifference;
	    	AverageVelocity += Velocity;
        }
    }
    AverageVelocity = AverageVelocity / (ArrayCount(PreviousLocations)-1);
    
    return AverageVelocity;
}

function Vector CalculateCustomAcceleration(Pawn Target)
{
    local Vector Acceleration, AverageAcceleration, CurrentVelocity, PreviousVelocity;
    local float TimeDifferenceCurrent, TimeDifferencePrevious;
    local int i, PreviousIndex, PreviousPreviousIndex;
    
    AverageAcceleration = vect(0,0,0);

    for(i=0; i < ArrayCount(PreviousLocations)-2; i++)
    {
        PreviousIndex = (LocationIndex - 1 - i + ArrayCount(PreviousLocations)) % ArrayCount(PreviousLocations);
        PreviousPreviousIndex = (LocationIndex - 2 - i + ArrayCount(PreviousLocations)) % ArrayCount(PreviousLocations);
         if (PreviousLocations[PreviousIndex].Time != 0 && PreviousLocations[PreviousPreviousIndex].Time != 0)
        {
            TimeDifferenceCurrent = PreviousLocations[(LocationIndex - i) % ArrayCount(PreviousLocations)].Time - PreviousLocations[PreviousIndex].Time;
            TimeDifferencePrevious = PreviousLocations[PreviousIndex].Time - PreviousLocations[PreviousPreviousIndex].Time;
            
            if (TimeDifferenceCurrent > 0 && TimeDifferencePrevious > 0)
            {
                CurrentVelocity = (PreviousLocations[(LocationIndex - i) % ArrayCount(PreviousLocations)].Location - PreviousLocations[PreviousIndex].Location) / TimeDifferenceCurrent;
                PreviousVelocity = (PreviousLocations[PreviousIndex].Location - PreviousLocations[PreviousPreviousIndex].Location) / TimeDifferencePrevious;

                Acceleration = (CurrentVelocity - PreviousVelocity) / ((TimeDifferenceCurrent + TimeDifferencePrevious) / 2);
                AverageAcceleration += Acceleration;
            }
         }
    }
    
    
    AverageAcceleration = AverageAcceleration / (ArrayCount(PreviousLocations)-2);

    return AverageAcceleration;
}

function Vector BulletSpeedCorrection (Pawn Target)
{
    local float BulletSpeed, TargetDist, ToF;
    local Vector Correction, Start, AimSpot, CustomVelocity, CustomAcceleration;
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
            ToF = TargetDist / BulletSpeed; // initial time of flight calculation
			CustomVelocity = CalculateCustomVelocity(Target);
			CustomAcceleration = CalculateCustomAcceleration(Target);

            AimSpot = Target.Location + CustomVelocity*ToF + CustomAcceleration * Square(ToF) * 0.5;

			if(Me.FastTrace(AimSpot, Start))
			{
				TargetDist = VSize(AimSpot - Start);
				ToF = (ToF + (TargetDist / BulletSpeed)) / 2; // recalculate time of flight
				Correction = CustomVelocity * ToF + CustomAcceleration * Square(ToF) * 0.5;
				return Correction;
			}
        }
    }

    return vect(0,0,0);
}

function bool TargetFall(Pawn Target)
{
	if((Target.Physics == PHYS_Falling || (!Target.bCanFly && !Target.Region.Zone.bWaterZone)) && Target.Velocity.Z != 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

function SetMyRotation (Vector End, Vector Start, float Delta)
{
    local Rotator Rot;
    local Rotator SmoothedRot;
    local float Alpha;
    local int PitchDiff, YawDiff, RollDiff;
    local float AngularSpeed;

    Rot = Normalize(rotator(End - Start));

    if (bRotateSlow)
    {
        if (bUseLinearSpeed)
        {
            // Calcul de la diffÃ©rence de rotation
            PitchDiff = Rot.Pitch - Me.ViewRotation.Pitch;
            YawDiff = Rot.Yaw - Me.ViewRotation.Yaw;
            RollDiff = Rot.Roll - Me.ViewRotation.Roll;

            // Normalisation des diffÃ©rences
            if (Abs(PitchDiff) > 32768) PitchDiff = -Sign(PitchDiff) * (65536 - Abs(PitchDiff));
            if (Abs(YawDiff) > 32768) YawDiff = -Sign(YawDiff) * (65536 - Abs(YawDiff));
            if (Abs(RollDiff) > 32768) RollDiff = -Sign(RollDiff) * (65536 - Abs(RollDiff));

            // Calcul de l'alpha
            Alpha = FMin(1.0, (MySetSlowSpeed / 100) * Delta);

            // Interpolation linÃ©aire manuelle
            SmoothedRot.Pitch = Me.ViewRotation.Pitch + int(PitchDiff * Alpha);
            SmoothedRot.Yaw = Me.ViewRotation.Yaw + int(YawDiff * Alpha);
            SmoothedRot.Roll = Me.ViewRotation.Roll + int(RollDiff * Alpha);
        }
        else
        {
            // Calcul de la diffÃ©rence de rotation
            PitchDiff = Rot.Pitch - Me.ViewRotation.Pitch;
            YawDiff = Rot.Yaw - Me.ViewRotation.Yaw;
            RollDiff = Rot.Roll - Me.ViewRotation.Roll;

            // Normalisation des diffÃ©rences
            if (Abs(PitchDiff) > 32768) PitchDiff = -Sign(PitchDiff) * (65536 - Abs(PitchDiff));
            if (Abs(YawDiff) > 32768) YawDiff = -Sign(YawDiff) * (65536 - Abs(YawDiff));
            if (Abs(RollDiff) > 32768) RollDiff = -Sign(RollDiff) * (65536 - Abs(RollDiff));

            // Calcul de la vitesse angulaire
            AngularSpeed = (MySetSlowSpeed / 100) * Delta;

            // Calcul de l'alpha
            Alpha = FMin(1.0, AngularSpeed);

            // Interpolation linÃ©aire manuelle avec vitesse angulaire
            SmoothedRot.Pitch = Me.ViewRotation.Pitch + int(PitchDiff * Alpha);
            SmoothedRot.Yaw = Me.ViewRotation.Yaw + int(YawDiff * Alpha);
            SmoothedRot.Roll = Me.ViewRotation.Roll + int(RollDiff * Alpha);
        }

        Me.ViewRotation = Normalize(SmoothedRot);
    }
    else
    {
        Me.ViewRotation = Rot;
    }
}

function int Sign(float Value)
{
    if (Value > 0)
    {
        return 1;
    }
    else if (Value < 0)
    {
        return -1;
    }
    else
    {
        return 0;
    }
}

function MoveToDestination()
{
    local float Distance, MyRot, DistToNode;
    local Vector Dir, StrafeDir;
    local Vector NextLocation;
    local bool bCanReach;
    local rotator ViewRot;

    if (NextNode != None)
    {
        DistToNode = VSize(NextNode.Location - Me.Location);
        if (DistToNode < 64.0f || !Me.FastTrace(NextNode.Location, Me.Location))
		{
			if(Me.FastTrace(Me.Destination, Me.Location))
			{
				NextNode.SetLocation(Me.Destination);
			}
			Msg("Node reached");
			NextNode = None;
		}
        else
        {
            NextLocation = NextNode.Location;
        }
	}

    if(Me.Destination != vect(0, 0, 0) && NextNode == None)
	{
		TargetToFollow = None;
    	Distance = Me.VSize(Me.Destination - Me.Location);
		if (Distance > 64.0f)
    	{	
			NextNode = Me.FindPathTo(Me.Destination);
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
		Me.Destination = vect(0, 0, 0);
		NextNode = Me.FindPathToward(TargetToFollow); 
		Status = "Following...";
	}

    if(NextNode == None)
    {
        Me.aForward = 0;
		Me.aStrafe = 0;
        return;
    }
	
	ViewRot = Me.ViewRotation;
    MyRot = ViewRot.Yaw * 360 / 65536;

    if(MyRot < 0)
    {
        MyRot += 360;
    }

    MyRot = MyRot * Pi / 180;

    Dir = Normal(NextNode.Location - Me.Location);

    if(VSize(NextNode.Location - Me.Location) > 200)
    {
        Me.aForward = Cos(MyRot) * Dir.X + Sin(MyRot) * Dir.Y;
        Me.aStrafe = -Sin(MyRot) * Dir.X + Cos(MyRot) * Dir.Y;
    }
    else
    {
        StrafeDir = Normal(NextNode.Location - Me.Location);
        if(!Me.FastTrace(Me.Destination, Me.Location) ||
          (StrafeDir Dot vector(Me.ViewRotation) < 0.7))
          {
            Me.aForward = Cos(MyRot) * Dir.X + Sin(MyRot) * Dir.Y;
			Me.aStrafe = -Sin(MyRot) * Dir.X + Cos(MyRot) * Dir.Y;
          }
        else
        {
            Me.aForward = Cos(MyRot) * Dir.X + Sin(MyRot) * Dir.Y;
            Me.aStrafe = (-Sin(MyRot) * Dir.X + Cos(MyRot) * Dir.Y) * 0.4;
        }

        if(VSize(NextNode.Location - Me.Location) < 32)
        {
            if(Me.FastTrace(Me.Destination, Me.Location) )
            {
				NextNode.SetLocation(Me.Destination);
            }
        }
	}

	Msg("Node dist : "$ VSize(Me.Location - NextNode.Location));
}

function Rotator RotateSlow (Rotator RotA, Rotator RotB, float Delta)
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
		RotC.Pitch=RotA.Pitch + Pitch * (MySetSlowSpeed * Delta);
	} 
	else 
	{
		RotC.Pitch=RotB.Pitch;
	}
	
	if ( !Bool2 )
	{
		RotC.Yaw=RotA.Yaw + Yaw * (MySetSlowSpeed * Delta);
	} 
	else 
	{
		RotC.Yaw=RotB.Yaw;
	}
	
	if ( !Bool3 )
	{
		RotC.Roll=RotA.Roll + Roll * (MySetSlowSpeed * Delta);
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
	Msg("doAutoAim");
	Msg("SetRotationSpeed X");
	Msg("IncreaseSpeed");
	Msg("ReduceSpeed");
	Msg("UseSplash");
	Msg("UseRotateSlow");
	Msg("UseDebug");
	Msg("----------");
	Msg("SuperBotTeam");
	Msg("GetSkills");
	Msg("GodModeTeam X");
	Msg("----------");
	Msg("MoveTo NAME");
	Msg("MoveFollow NAME");
	Msg("MoveToRandom");
	Msg("MoveToBest");
	Msg("MoveToBase");
	Msg("MoveToEnemyFlag");
	Msg("MoveStop");
}

//================================================================================
// (Useless) Functions.
//================================================================================

exec function SuperBotTeam()
{
	local Pawn Target;
	
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
			Bot(Target).CombatStyle = RandRange(-1,1); //Xan Style
			Bot(Target).BaseAggressiveness =FRand();
			Bot(Target).Aggressiveness = FRand();
			Bot(Target).Skill = 3;
			Bot(Target).Accuracy = 1;
			Bot(Target).bJumpy = true;
			Bot(Target).Alertness = 1;
			Bot(Target).CampingRate = FRand();
			Bot(Target).StrafingAbility = 1;
		}
	}
	Msg("SuperBot Team on");
	
}

exec function GetSkills()
{
	local Pawn Target;

	foreach Me.Level.AllActors(Class'Pawn', Target)
	{
		
		if 
		( 
			(Target != None) && // Target variable is Not Empty
			(Target != Me) && //Target is Not ower own Player
			(Target.PlayerReplicationInfo != None) && // Target has Replication info
			(!Target.PlayerReplicationInfo.bIsSpectator) && // Target is Not a spectator
			(!Target.PlayerReplicationInfo.bWaitingPlayer) // Target is Not somebody that is pending to get into the game
		)
		{
			//Bot(Target).CombatStyle = 0.5; //Xan Style
			//Bot(Target).BaseAggressiveness = 5;
			Msg("NAME = "$Target.PlayerReplicationInfo.PlayerName);
			Msg("Skill : "$Bot(Target).Skill);
			Msg("Accuracy : "$Bot(Target).Accuracy);
			Msg("bJumpy : "$Bot(Target).bJumpy);
			Msg("Alertness : "$Bot(Target).Alertness);
			Msg("CampingRate : "$Bot(Target).CampingRate);
			Msg("StrafingAbility : "$Bot(Target).StrafingAbility);
			Msg("BaseAggressiveness : "$Bot(Target).BaseAggressiveness);
			Msg("Aggressiveness : "$Bot(Target).Aggressiveness);
		}
	}
}


exec function GodModeTeam(int Apply)
{
	local Pawn Target;

	if(Apply == 1)
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
	else if(Apply == 0)
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
			Me.Destination = Target.Location;
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
			if(Me.Destination != vect(0, 0, 0))
			{
				Me.Destination = vect(0, 0, 0);
			}
			Msg("Player found, following "$ Target.PlayerReplicationInfo.PlayerName);
			return;
		}
	}
	Msg("Player name not found");
}

exec function MoveToRandom()
{
	Me.Destination = Me.FindRandomDest().Location;
	Msg("Move to random dest");
}

exec function MoveToBest()
{
	local float MinWeight;

	Me.Destination = Me.FindBestInventoryPath(MinWeight, true).Location;
	Msg("Move to inventory (??)");
}

exec function MoveToBase()
{
	if(Me.Level.Game.IsA('CTFGame') )
	{
		Me.Destination = CTFReplicationInfo(Me.GameReplicationInfo).FlagList[Me.PlayerReplicationInfo.Team].HomeBase.Location;
		Msg("Move to base");
	}
}

exec function MoveToEnemyFlag()
{
	local CTFFlag Flag;
	local CTFFlag FlagArray[4];
	local CTFFlag Target;

	Target = None;

	if(Me.Level.Game.IsA('CTFGame') )
	{
		foreach Me.Level.AllActors(Class'CTFFlag', Flag)
		{	
			if(Flag.Team != Me.PlayerReplicationInfo.Team)
			{
				FlagArray[Flag.Team] = Flag;
			}
		}

		While(Target == None)
		{
			Target = FlagArray[Rand(4)];
		}

		Me.Destination = Target.Location;
		Msg("Move to enemy flag");
	}
}

exec function MoveStop()
{
	TargetToFollow = None;
	Me.Destination = vect(0, 0, 0);
	Status = "Normal";
	Me.aForward = 0;
	Me.aStrafe = 0;
	Msg("Move stop");
}

exec function ShowOverlay()
{
	bShowOverlay = !bShowOverlay;
	Msg("bShowOverlay = "$ string(bShowOverlay));
}

//================================================================================
// DEFAULTS.
//================================================================================



//=====================================================================================
// BOT END.
//=====================================================================================

defaultproperties
{
	bAutoAim=True
	MySetSlowSpeed=2000
	bUseSplash=True
	bAimPlayers=True
	bShowOverlay=True
	LastFireMode=1
	ConsoleKey=222
	HistoryTop=23
	HistoryBot=38
	HistoryCur=38
	History(0)="toggleautojump"
	History(1)="toggleautomove"
	History(2)="movetorandom"
	History(3)="usedebug"
	History(4)="superbotteam"
	History(5)="behindview 0"
	History(7)="setrotationspeed 1000"
	History(8)="playersonly"
	History(9)="god"
	History(10)="playersonly"
	History(11)="userotateslow"
	History(12)="god"
	History(13)="userotateslow"
	History(14)="toggleautomove"
	History(15)="behindview 1"
}
