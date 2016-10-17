unit Log;

interface

type
  TLog = class
  private
    FFileName: string;
    FFile: TextFile;
    procedure OpenLogfile;
  public
    constructor Create(const FileName: string);
    procedure Debug(const Message: string);
    procedure Warning(const Message: string);
    procedure Error(const Message: string);
    procedure Information(const Message: string);
  end;

implementation

uses
  Forms, SysUtils;

const
  BreakingLine =
    '//----------------------------------------------------------------------------//';

  // ** This procedure just creates a new Logfile an appends when it was created **
constructor TLog.Create(const FileName: string);
begin
  FFileName := FileName;
end;

procedure TLog.OpenLogfile;
begin
  // Assigns Filename to variable F
  AssignFile(FFile, FFileName);
  // Rewrites the file F
  Rewrite(FFile);
  // Open file for appending
  Append(FFile);
  // Write text to Textfile F
  WriteLn(FFile, BreakingLine);
  WriteLn(FFile, 'This Logfile was created on ' + DateTimeToStr(Now));
  WriteLn(FFile, BreakingLine);
  WriteLn(FFile, '');
end;

procedure TLog.Debug(const Message: string);
begin
  Information('Debug: ' + Message);
end;

procedure TLog.Error(const Message: string);
begin
  Information('Error: ' + Message);
end;

procedure TLog.Information(const Message: string);
begin
  try
    // Checking for file
    if not FileExists(FFileName) then
      OpenLogfile // if file is not available then create a new file
    else
    begin// Assigns Filename to variable F
      AssignFile(FFile, FFileName);
      // start appending text
      Append(FFile);
    end;
  except
    Exit;
  end;
  // Write a new line with current date and message to the file
  WriteLn(FFile, DateTimeToStr(Now) + ': ' + Message);
  // Close file
  CloseFile(FFile)
end;

procedure TLog.Warning(const Message: string);
begin
  Information('Warning: ' + Message);
end;

end.
