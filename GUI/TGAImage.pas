unit TGAImage;

interface

uses SysUtils, Classes, Graphics;

type
	TTGAImage = class(TBitmap)
	public
		procedure LoadFromStream(s: TStream); override;
		procedure SaveToStream(s: TStream); override;
	end;

implementation

uses uTypes, uMath, uDBitmap, uColor;

type
// Header type for TGA images
	TTgaHeader = packed record // 18
		IDLength     : U1;
		ColorMapType : U1;
		ImageType    : U1;
		ColorMapSpec : array[0..4] of U1; // 5
		OrigX  : U2;
		OrigY  : U2;
		Width  : U2;
		Height : U2;
		BPP    : U1;
		ImageInfo : U1;
	end;

procedure TTgaImage.LoadFromStream(s: TStream);
label LNextLine;
var
	Header: TTgaHeader;

	ImageSizeS, ImageSizeD: SG;
	CompImage: Pointer; // S
	ColorDepth: SG; // S
	PS, PD: PRGB;
	MaxPS, MaxPD: SG;

	C: SG;
	y: SG;
begin
	s.ReadBuffer(Header, sizeof(Header));
	if ((Header.ImageType = 2) or { TGA_RGB }
		(Header.ImageType = 10))
		and (Header.ColorMapType = 0) // Don't support colormapped files
		and (Header.BPP >= 24) // 24bit or 32bit image
	then
	begin
		s.Seek(header.IDLength, soFromCurrent);

		if BPP = 3 then
			PixelFormat := pf24bit
		else
			PixelFormat := pf32bit;
		Width := Header.Width;
		Height := Header.Height;
		ColorDepth := MaxDiv(Header.BPP, 8);
		ImageSizeD := Header.Width * Header.Height * BPP;
		ImageSizeS := s.Size - SizeOf(Header) - Header.IDLength;

		if (ImageSizeS = ImageSizeD) and (Header.ImageInfo = 0) and (Header.ImageType = 2) then
			s.ReadBuffer(PU1(Scanline[Header.Height - 1])^, ImageSizeD)
		else
		begin
			GetMem(CompImage, ImageSizeS);
			try
				s.ReadBuffer(CompImage^, ImageSizeS);

				PS := CompImage;
				if Header.ImageInfo = $20 then
					y := Header.Height
				else
					y := -1;
				while True do
				begin
					LNextLine:
					if Header.ImageInfo = $20 then
					begin
						Dec(y); if (y < 0) then Break;
					end
					else
					begin
						Inc(y); if (y >= Header.Height) then Break;
					end;

					PD := ScanLine[Header.Height - 1 - y]; // Align for 24bit
					MaxPS := SG(PS) + Header.Width * ColorDepth;
					MaxPD := SG(PD) + Header.Width * BPP;
					while True do
					begin
						if Header.ImageType = 10 then
						begin // Compressed
							C := PU1(PS)^;
							Inc(PByte(PS), 1);
							if SG(PS) >= MaxPS then Break;
							if C and $80 = 0 then
							begin
								while C >= 0 do
								begin
									PD^ := PS^;
									Inc(PByte(PS), ColorDepth);
									Inc(PByte(PD), BPP);
									if SG(PS) >= MaxPS then goto LNextLine;
									if SG(PD) >= MaxPD then goto LNextLine;
									Dec(C);
								end;
							end
							else
							begin
								C := C and $7F;
								while C >= 0 do
								begin
									PD^ := PS^;
									Inc(PByte(PD), BPP);
									if SG(PD) >= MaxPD then
									begin
										Inc(PByte(PS), ColorDepth);
										goto LNextLine;
									end;
									Dec(C);
								end;
								Inc(PByte(PS), ColorDepth);
							end;
						end
						else
						begin // Uncompressed
							while True do
							begin
								PD^ := PS^;
								Inc(PByte(PS), ColorDepth);
								Inc(PByte(PD), BPP);
								if SG(PS) >= MaxPS then goto LNextLine;
								if SG(PD) >= MaxPD then goto LNextLine;
							end;
							Break;
						end;
					end;
				end;
			finally
				FreeMem(CompImage);
			end;
		end;
	end
	else if IsRelease then
		raise EInvalidGraphic.Create('Only 24/32 bit color uncompressed tga image is supported.');
end;

procedure TTgaImage.SaveToStream(s: TStream);
var
	header: TTgaHeader;
	ImageSize: integer;
begin
	FillChar(header, sizeof(header), 0);
	header.ImageType := 2;
	header.ImageInfo := 0; // $20; // bottom-up
	if PixelFormat = pf32bit then
		header.BPP := 32
	else if PixelFormat = pf24bit then
		header.BPP := 24
	else
	begin
		// Convert
		PixelFormat := pf24bit;
		header.BPP := 24;
	end;
	header.Width := Width;
	header.Height := Height;
	ImageSize := Width * Height * (header.BPP div 8);
	s.WriteBuffer(header, sizeof(header));
	s.WriteBuffer(PU1(Scanline[height-1])^, ImageSize);
end;

initialization
{$IFNDEF NoInitialization}
	TPicture.RegisterFileFormat('tga', 'Targa Graphics', TTGAImage);
{$ENDIF NoInitialization}
finalization
{$IFNDEF NoFinalization}
	TPicture.UnregisterGraphicClass(TTGAImage);
{$ENDIF NoFinalization}
end.
