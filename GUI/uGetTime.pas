unit uGetTime;

interface

uses
	uTypes, uParserMsg,
	Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
	ExtCtrls, ComCtrls, uDButton, uDLabel, uDForm, uDEdit, uDMemo;

type
	TOnApplyTime = procedure(Value: S8);

	TfGetTime = class(TDForm)
		TrackBarH: TTrackBar;
		TrackBarM: TTrackBar;
		TrackBarS: TTrackBar;
		Label1: TLabel;
		Label2: TLabel;
		Label3: TLabel;
		TrackBarD: TTrackBar;
		Label4: TLabel;
		LabelH: TLabel;
		LabelM: TLabel;
		LabelS: TLabel;
		LabelD: TLabel;
		ButtonOk: TDButton;
		ButtonCancel: TDButton;
		EditInput: TDEdit;
		ButtonMin: TDButton;
		ButtonCur: TDButton;
		ButtonMax: TDButton;
		SpinButtonH: TUpDown;
		SpinButtonS: TUpDown;
		SpinButtonM: TUpDown;
		SpinButtonD: TUpDown;
		ButtonDef: TDButton;
		ButtonApply: TDButton;
		EditError: TDMemo;
		procedure EditInputChange(Sender: TObject);
		procedure TrackBarHMSDChange(Sender: TObject);
		procedure ButtonMinClick(Sender: TObject);
		procedure ButtonCurClick(Sender: TObject);
		procedure ButtonMaxClick(Sender: TObject);
		procedure ButtonDefClick(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure ButtonOkClick(Sender: TObject);
		procedure ButtonCancelClick(Sender: TObject);
		procedure SpinButtonHMSDChangingEx(Sender: TObject;
			var AllowChange: Boolean; NewValue: Smallint;
			Direction: TUpDownDirection);
	private
		{ Private declarations }
		Messages: TParserMessages;
		TMinVal, TCurVal, TDefVal, TMaxVal, NowVal: S8;
		OnApply: TOnApplyTime;
		procedure ChangeTime;
		procedure InitButtons;
		procedure InitEdit;
		procedure InitTrackBar;
	public
		{ Public declarations }
		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
	end;

function GetTime(const Prompt: string;
	var CurVal: U4; const MinVal, DefVal, MaxVal: U4; OnApplyTime: TOnApplyTime): Boolean;
function GetTimeS4(const Prompt: string;
	var CurVal: S4; const MinVal, DefVal, MaxVal: S4; OnApplyTime: TOnApplyTime): Boolean;
function GetTimeS8(const Prompt: string;
	var CurVal: S8; const MinVal, DefVal, MaxVal: S8; OnApplyTime: TOnApplyTime): Boolean;

implementation

{$R *.DFM}
uses
	Math,
	uStrings, uInputFormat, uDParser, uOutputFormat, uLayout, uDictionary;

var
	fGetTime: TfGetTime;

function GetTime(const Prompt: string;
	var CurVal: U4; const MinVal, DefVal, MaxVal: U4; OnApplyTime: TOnApplyTime): Boolean;
var C: S8;
begin
	C := CurVal;
	Result := GetTimeS8(Prompt, C, MinVal, DefVal, MaxVal, OnApplyTime);
	CurVal := C;
end;

function GetTimeS4(const Prompt: string;
	var CurVal: S4; const MinVal, DefVal, MaxVal: S4; OnApplyTime: TOnApplyTime): Boolean;
var C: S8;
begin
	C := CurVal;
	Result := GetTimeS8(Prompt, C, MinVal, DefVal, MaxVal, OnApplyTime);
	CurVal := C;
end;

function GetTimeS8(const Prompt: string;
	var CurVal: S8; const MinVal, DefVal, MaxVal: S8; OnApplyTime: TOnApplyTime): Boolean;
begin
{	Assert(not ((MinVal > MaxVal) or (DefVal < MinVal) or (DefVal > MaxVal)
		or (CurVal < MinVal) or (CurVal > MaxVal)));}

	if not Assigned(fGetTime) then
	begin
		fGetTime := TfGetTime.Create(Application.MainForm);
	end;

	with fGetTime do
	begin
		ButtonApply.Enabled := Assigned(OnApplyTime);
		OnApply := OnApplyTime;
		TMinVal := MinVal;
		TCurVal := CurVal;
		TDefVal := DefVal;
		TMaxVal := MaxVal;
		if TMaxVal < TMinVal then TMaxVal := TMinVal;
		if TCurVal < TMinVal then
			TCurVal := TMinVal
		else if TCurVal > TMaxVal then
			TCurVal := TMaxVal;
		NowVal := TCurVal;
		Caption := Translate(RemoveSingleAmp(Prompt));
	// H
		TrackBarH.OnChange := nil;
		TrackBarH.Min := TMinVal div Hour;
		TrackBarH.Max := TMaxVal div Hour;
		if TrackBarH.Max - TrackBarH.Min > 112 then
			TrackBarH.TickStyle := tsNone
		else
			TrackBarH.TickStyle := tsAuto;
		TrackBarH.OnChange := TrackBarHMSDChange;
	// M
		TrackBarM.OnChange := nil;
		if TMaxVal < Hour then
		begin
			TrackBarM.Min := TMinVal div Minute;
			TrackBarM.Max := TMaxVal div Minute;
		end
		else
		begin
			TrackBarM.Min := 0;
			TrackBarM.Max := 59;
		end;
		TrackBarM.OnChange := TrackBarHMSDChange;
	// S
		TrackBarS.OnChange := nil;
		if TMaxVal < Minute then
		begin
			TrackBarS.Min := TMinVal div Second;
			TrackBarS.Max := TMaxVal div Second;
		end
		else
		begin
			TrackBarS.Min := 0;
			TrackBarS.Max := 59;
		end;
		TrackBarS.OnChange := TrackBarHMSDChange;
	// D
		TrackBarD.OnChange := nil;
		if TMaxVal < 1000 then
		begin
			TrackBarD.Min := TMinVal;
			TrackBarD.Max := TMaxVal;
		end
		else
		begin
			TrackBarD.Min := 0;
			TrackBarD.Max := 1000;
		end;
		TrackBarD.OnChange := TrackBarHMSDChange;

		InitTrackBar;
		InitButtons;
		InitEdit;
		if ActiveControl <> EditInput then ActiveControl := EditInput;
		if Assigned(OnApply) then
		begin
			FormStyle := fsStayOnTop;
			Show;
			Result := True;
		end
		else
		begin
			FormStyle := fsNormal;
			if ShowModal = mrOK then
			begin
				CurVal := NowVal;
				Result := True;
			end
			else
			begin
				Result := False;
			end;
		end;
	end;
end;

procedure TfGetTime.InitButtons;
var
	H, M, S, D: U4;
begin
	ButtonMin.Enabled := NowVal <> TMinVal;
	ButtonCur.Enabled := NowVal <> TCurVal;
	ButtonDef.Enabled := NowVal <> TDefVal;
	ButtonMax.Enabled := NowVal <> TMaxVal;
	MsToHMSD(NowVal, H, M, S, D);
	LabelH.Caption := IntToStr(H);
	LabelM.Caption := IntToStr(M);
	LabelS.Caption := IntToStr(S);
	LabelD.Caption := IntToStr(D);
end;

procedure TfGetTime.InitEdit;
begin
	EditInput.OnChange := nil;
	if TMaxVal >= Hour then
		EditInput.Text := MsToStr(NowVal, diMSD, -3, False)
	else
		EditInput.Text := MsToStr(NowVal, diHMSD, -3, False);
	EditInput.SelectAll;
	EditInput.OnChange := EditInputChange;
end;

procedure TfGetTime.InitTrackBar;
var
	H, M, S, D: U4;
begin
	msToHMSD(NowVal, H, M, S, D);
	TrackBarH.OnChange := nil;
	TrackBarM.OnChange := nil;
	TrackBarS.OnChange := nil;
	TrackBarD.OnChange := nil;
	TrackBarH.Position := H;
	TrackBarM.Position := M;
	TrackBarS.Position := S;
	TrackBarD.Position := D;
	TrackBarH.OnChange := TrackBarHMSDChange;
	TrackBarM.OnChange := TrackBarHMSDChange;
	TrackBarS.OnChange := TrackBarHMSDChange;
	TrackBarD.OnChange := TrackBarHMSDChange;
end;

procedure TfGetTime.EditInputChange(Sender: TObject);
begin
	EditInput.OnChange := nil;
	NowVal := StrToMs(EditInput.Text, TMinVal, TDefVal, TMaxVal, True, Messages);
	Messages.ToStrings(EditError.Lines);
	Messages.Clear;

	InitButtons;
	InitTrackBar;
	ChangeTime;
	EditInput.OnChange := EditInputChange;
end;

procedure TfGetTime.TrackBarHMSDChange(Sender: TObject);
begin
	NowVal :=
		S8(TrackBarH.Position) * Hour +
		TrackBarM.Position * Minute +
		TrackBarS.Position * Second +
		TrackBarD.Position;
	if NowVal < TMinVal then
		NowVal := TMinVal
	else if NowVal > TMaxVal then
		NowVal := TMaxVal;
	InitEdit;
	InitButtons;
	ChangeTime;
end;

procedure TfGetTime.ButtonMinClick(Sender: TObject);
begin
	NowVal := TMinVal;
	InitTrackBar;
	InitEdit;
	InitButtons;
	ChangeTime;
end;

procedure TfGetTime.ButtonCurClick(Sender: TObject);
begin
	NowVal := TCurVal;
	InitTrackBar;
	InitEdit;
	InitButtons;
	ChangeTime;
end;

procedure TfGetTime.ButtonDefClick(Sender: TObject);
begin
	NowVal := TDefVal;
	InitTrackBar;
	InitEdit;
	InitButtons;
	ChangeTime;
end;

procedure TfGetTime.ButtonMaxClick(Sender: TObject);
begin
	NowVal := TMaxVal;
	InitTrackBar;
	InitEdit;
	InitButtons;
	ChangeTime;
end;

procedure TfGetTime.ChangeTime;
begin
	if Assigned(OnApply) then OnApply(NowVal);
end;

procedure TfGetTime.ButtonOkClick(Sender: TObject);
begin
	if Assigned(OnApply) then
	begin
		Close;
	end;
end;

procedure TfGetTime.ButtonCancelClick(Sender: TObject);
begin
	if Assigned(OnApply) then
	begin
		if NowVal <> TCurVal then OnApply(TCurVal);
		Close;
	end;
end;

procedure TfGetTime.FormCreate(Sender: TObject);
begin
	Background := baGradient;
	LayoutControls([ButtonOk, ButtonCancel, ButtonApply], ClientWidth, ClientHeight);
end;

procedure TfGetTime.SpinButtonHMSDChangingEx(Sender: TObject;
	var AllowChange: Boolean; NewValue: Smallint;
	Direction: TUpDownDirection);
var L: SG;
begin
	L := TUpDown(Sender).Tag;
	if Direction = updUp then
	begin
		if NowVal + L <= TMaxVal  then Inc(NowVal, L) else NowVal := TMaxVal;
	end
	else
	begin
		if NowVal >= L + TMinVal then Dec(NowVal, L) else NowVal := 0;
	end;
{	if NowVal < TMinVal then
		NowVal := TMinVal
	else if NowVal > TMaxVal then
		NowVal := TMaxVal;}
	InitTrackBar;
	InitEdit;
	InitButtons;
	ChangeTime;
end;

constructor TfGetTime.Create(AOwner: TComponent);
begin
	inherited;
	Messages := TParserMessages.Create;
end;

destructor TfGetTime.Destroy;
begin
	FreeAndNil(Messages);
	inherited;
end;

end.
