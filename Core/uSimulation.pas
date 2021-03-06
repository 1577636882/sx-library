unit uSimulation;

interface

uses uTypes;

var
	// Read Only
	GTime, // Global time
	GTimeStep: U4; // Time interval between GetGTime

function TimeDifference(const NowTime, LastTime: U4): U4; overload;
function TimeDifference(const NowTime, LastTime: U8): U8; overload;
function IntervalFrom(const StartTime: U4): U4; overload;
function IntervalFrom(const StartTime: U8): U8; overload;
// procedure InitGTime; // Reset Timer, GTime counts from 0

{
	call often
	problem is when the call between GetGTime is longer that 42 days
	then the measured interval is incorrect
}
procedure GetGTime(const MaximumTimeStep: U4 = 0); // Update GTime variable

implementation

uses
	Windows,
	uMath, uLog, uOutputFormat;

//{$define Prec} // Precision Timer, but slower (3%)

{function GetTickCount: U4;
begin
	Result := Windows.GetTickCount and $0fff;
end;}

function TimeDifference(const NowTime, LastTime: U4): U4;
asm
	mov Result, NowTime
	sub Result, LastTime
//	and Result, $0fff
end;

function TimeDifference(const NowTime, LastTime: U8): U8;
begin
	Result := NowTime - LastTime;
end;

function IntervalFrom(const StartTime: U4): U4;
begin
	GetGTime(0);
	Result := TimeDifference(GTime, StartTime);
end;

function IntervalFrom(const StartTime: U8): U8;
begin
	Result := TimeDifference(PerformanceCounter, StartTime);
end;

var
	GTime2, LastWinTime: {$ifdef Prec}U8{$else}U4{$endif};

procedure InitGTime;
begin
	LastWinTime := {$ifdef Prec}PerformanceCounter{$else}GetTickCount{$endif};
end;

procedure GetGTime(const MaximumTimeStep: U4 = 0);
var
	GTimeStep2, MaximumTimeStep2, WinTime: {$ifdef Prec}U8{$else}U4{$endif};
begin
	WinTime := {$ifdef Prec}PerformanceCounter{$else}GetTickCount{$endif};
	GTimeStep2 := TimeDifference(WinTime, LastWinTime);
	LastWinTime := WinTime;

	if (MaximumTimeStep > 0) then
	begin
		MaximumTimeStep2 := {$ifdef Prec}RoundDivU8(MaximumTimeStep * PerformanceFrequency, Second){$else}MaximumTimeStep{$endif};
		if (GTimeStep2 >= 2 * MaximumTimeStep2) then // Long lag and hibernation
		begin
			if LogWarning then LogAdd('Time Lag ' + MsToStr(GTimeStep2, diDHMSD, 3, False, ofIO));
			GTimeStep2 := MaximumTimeStep2;
		end;
	end;
	{$ifdef Prec}GTimeStep := RoundDivU8(Second * GTimeStep2, PerformanceFrequency){$else}GTimeStep := GTimeStep2{$endif}; // Convert to readable value
	Inc(GTime2, GTimeStep2);

	{$ifdef Prec}GTime := RoundDivU8(Second * GTime2, PerformanceFrequency){$else}GTime := GTime2{$endif}; // Convert to readable value
end;

initialization
{$IFNDEF NoInitialization}
	InitGTime;
{$ENDIF NoInitialization}
end.
