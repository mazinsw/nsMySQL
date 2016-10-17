unit UnicodeUtils;

interface

uses
  SysUtils, Classes;

function IsIn(Ch: WideChar; const S: UnicodeString): Boolean;
procedure LoadFileEx(const FileName: string; Lines: TStrings;
  var WithBOM: Boolean; var Encoding: TEncoding; var LineBreak: string); overload;
procedure LoadFileEx(const FileName: string; Lines: TStrings); overload;

implementation

uses
  chsdIntf, nsCore;

function IsIn(Ch: WideChar; const S: UnicodeString): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to Length(S) do
  begin
    if Ch = S[I] then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function DetectLineBreak(const Buffer: PChar): string;
var
  Ptr: PChar;
begin
  Result := #13#10;
  Ptr := Buffer;
  while Ptr^ <> #0 do
  begin
    if Ptr^ = #13 then
		begin
			if (Ptr + 1)^ = #10 then
				Break
			else
			begin
        Result := #13;
				Break;
			end;
		end
    else if Ptr^ = #10 then
		begin
			Result := #10;
      Break;
		end;
    Inc(Ptr);
  end;
end;

procedure LoadFileEx(const FileName: string; Lines: TStrings); overload;
var
  WithBOM: Boolean;
  Encoding: TEncoding;
  LineBreak: string;
begin
  LoadFileEx(FileName, Lines, WithBOM, Encoding, LineBreak);
end;

procedure LoadFileEx(const FileName: string; Lines: TStrings;
  var WithBOM: Boolean; var Encoding: TEncoding; var LineBreak: string);
var
  ChSInfo: rCharsetInfo;
  Size: Integer;
  Buffer: TBytes;
  Stream: TStream;
  Text: string;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Size := Stream.Size - Stream.Position;
    SetLength(Buffer, Size);
    Stream.Read(Buffer[0], Size);
    Stream.Free;
    Encoding := nil;
    // detect file encoding and read it
    chsdet_Reset;
    chsdet_HandleData(PAnsiChar(Buffer), Size);
    if not chsdet_Done then
      chsdet_DataEnd;
    WithBOM := True;
    case chsdet_GetDetectedBOM of
      BOM_UCS4_BE,    // 00 00 FE FF           UCS-4,    big-endian machine    (1234 order)
      BOM_UCS4_2143,  // 00 00 FF FE           UCS-4,    unusual octet order   (2143)
      BOM_UTF16_BE:   // FE FF ## ##           UTF-16,   big-endian
        Encoding := TEncoding.BigEndianUnicode;
      BOM_UCS4_LE,    // FF FE 00 00           UCS-4,    little-endian machine (4321 order)
      BOM_UCS4_3412,  // FE FF 00 00           UCS-4,    unusual octet order   (3412)
      BOM_UTF16_LE:   // FF FE ## ##           UTF-16,   little-endian
        Encoding := TEncoding.Unicode;
      BOM_UTF8:        // EF BB BF              UTF-8
        Encoding := TEncoding.UTF8;
    else
      WithBOM := False;
      ChSInfo := chsdet_GetDetectedCharset;
      if ChSInfo.CodePage = 65001 then
        Encoding := TEncoding.UTF8
      else if ChSInfo.CodePage = -1 then
        Encoding := TEncoding.UTF8
      else
        Encoding := TEncoding.Default;
    end;
    if WithBOM then
      Size := TEncoding.GetBufferEncoding(Buffer, Encoding)
    else
      Size := 0;
    Text := Encoding.GetString(Buffer, Size, Length(Buffer) - Size);
    LineBreak := DetectLineBreak(PChar(Text));
    Lines.SetText(PChar(Text));
  finally
  end;
end;

end.
