library nsMySQL;

uses
  Windows,
  SysUtils,
  ZConnection,
  ZSqlProcessor,
  ZScriptParser,
  UFrmConn in 'UFrmConn.pas' {FrmConn},
  Log in 'Log.pas',
  NSIS in 'NSIS.pas',
  UnicodeUtils in 'UnicodeUtils.pas';

procedure Connect(Conn: TZConnection; User, Passwd, HostName: string;
  Port: Integer; SkipConfig: Boolean = False);
var
  ConnOk: Boolean;
begin
  Conn.Disconnect;
  Conn.User := User;
  Conn.Password := Passwd;
  Conn.Protocol := 'mysql-5';
  if (Length(HostName) = 0) then
    Conn.HostName := 'localhost'
  else
    Conn.HostName := HostName;
  Conn.Port := Port;
  ConnOk := False;
  repeat
    try
      Conn.Connect;
      ConnOk := True;
    except
      on E: Exception do
      begin
        Passwd := '';
        if SkipConfig or not AjustarConexao(HostName, User, Passwd, Port,
          g_hwndParent) then
          raise ;
        Conn.User := User;
        Conn.Password := Passwd;
        if (Length(HostName) = 0) then
          Conn.HostName := 'localhost'
        else
          Conn.HostName := HostName;
        Conn.Port := Port;
      end;
    end;
  until ConnOk;
end;

procedure InternalExecSQL(const User, Passwd, HostName: string; Port: Integer;
  const SQL, LogFileName, Encoding: string);
var
  SqlProcessor: TZSqlProcessor;
  Conn: TZConnection;
  Log: TLog;
begin
  Conn := TZConnection.Create(nil);
  Conn.ClientCodepage := Encoding;
  Log := TLog.Create(LogFileName);
  try
    Connect(Conn, User, Passwd, HostName, Port);
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível conectar ao servidor ''%s''.'#13#13 +
          'Verifique se o computador do servidor está ligado e conectado à rede '
          + 'ou verfique a conexão de rede deste computador e tente executar novamente.', [HostName], 1);
    end;
  end;
  SqlProcessor := TZSqlProcessor.Create(nil);
  SqlProcessor.Connection := Conn;
  SqlProcessor.DelimiterType := dtDelimiter;
  try
    SqlProcessor.Script.Text := SQL;
    SqlProcessor.Execute;
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      SqlProcessor.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível executar o script de configuração.', [HostName], 2);
    end;
  end;
  SqlProcessor.Free;
  Conn.Free;
  if LogFileName <> '' then
    Log.Information('Script executado com sucesso!');
  Log.Free;
end;

procedure InternalExecSQLFromFile(const User, Passwd, HostName: string;
  Port: Integer; const FileName, LogFileName, Encoding: string);
var
  SqlProcessor: TZSqlProcessor;
  Conn: TZConnection;
  Log: TLog;
begin
  Conn := TZConnection.Create(nil);
  Conn.ClientCodepage := Encoding;
  Log := TLog.Create(LogFileName);
  try
    Connect(Conn, User, Passwd, HostName, Port);
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível conectar ao servidor ''%s''.'#13#13 +
          'Verifique se o computador do servidor está ligado e conectado à rede '
          + 'ou verfique a conexão de rede deste computador e tente executar novamente.', [HostName], 1);
    end;
  end;
  SqlProcessor := TZSqlProcessor.Create(nil);
  SqlProcessor.Connection := Conn;
  SqlProcessor.DelimiterType := dtDelimiter;
  try
    LoadFileEx(FileName, SqlProcessor.Script);
    SqlProcessor.Execute;
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      SqlProcessor.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível executar o arquivo script de configuração.',
        [HostName], 2);
    end;
  end;
  SqlProcessor.Free;
  Conn.Free;
  if LogFileName <> '' then
    Log.Information('Arquivo de script executado com sucesso!');
  Log.Free;
end;

procedure InternalExecSQLCreateUser(const User, Passwd, HostName: string;
  Port: Integer; const UserAccess, UserName, UserHost, UserPasswd, SQL,
  LogFileName, Encoding: string);
var
  SqlProcessor: TZSqlProcessor;
  Conn: TZConnection;
  Log: TLog;
begin
  Conn := TZConnection.Create(nil);
  Log := TLog.Create(LogFileName);
  try
    Connect(Conn, User, Passwd, HostName, Port);
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível conectar ao servidor ''%s''.'#13#13 +
          'Verifique se o computador do servidor está ligado e conectado à rede '
          + 'ou verfique a conexão de rede deste computador e tente executar novamente.', [HostName], 1);
    end;
  end;
  SqlProcessor := TZSqlProcessor.Create(nil);
  SqlProcessor.Connection := Conn;
  SqlProcessor.DelimiterType := dtDelimiter;
  try
    SqlProcessor.Script.Add(
      'GRANT ALL PRIVILEGES ON ' + UserAccess + ' TO ''' + UserName +
        '''@''' + UserHost + ''' IDENTIFIED BY ''' + UserPasswd + ''';');
    SqlProcessor.Script.Add('FLUSH PRIVILEGES;');
    SqlProcessor.Execute;
    Conn.ClientCodepage := Encoding;
    SqlProcessor.Script.Text := SQL;
    SqlProcessor.Execute;
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      SqlProcessor.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível criar o usuário e executar o script de configuração.'
          , [HostName], 2);
    end;
  end;
  SqlProcessor.Free;
  Conn.Free;
  if LogFileName <> '' then
    Log.Information('Script executado e usuário criado com sucesso!');
  Log.Free;
end;

procedure InternalExecSQLFromFileCreateUser(const User, Passwd,
  HostName: string; Port: Integer; const UserAccess, UserName, UserHost,
  UserPasswd, FileName, LogFileName, Encoding: string);
var
  SqlProcessor: TZSqlProcessor;
  Conn: TZConnection;
  Log: TLog;
begin
  Conn := TZConnection.Create(nil);
  Log := TLog.Create(LogFileName);
  try
    Connect(Conn, User, Passwd, HostName, Port);
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível conectar ao servidor ''%s''.'#13#13 +
          'Verifique se o computador do servidor está ligado e conectado à rede '
          + 'ou verfique a conexão de rede deste computador e tente executar novamente.', [HostName], 1);
    end;
  end;
  SqlProcessor := TZSqlProcessor.Create(nil);
  SqlProcessor.Connection := Conn;
  SqlProcessor.DelimiterType := dtDelimiter;
  try
    SqlProcessor.Script.Add(
      'GRANT ALL PRIVILEGES ON ' + UserAccess + ' TO ''' + UserName +
        '''@''' + UserHost + ''' IDENTIFIED BY ''' + UserPasswd + ''';');
    SqlProcessor.Script.Add('FLUSH PRIVILEGES;');
    SqlProcessor.Execute;
    Conn.ClientCodepage := Encoding;
    LoadFileEx(FileName, SqlProcessor.Script);
    SqlProcessor.Execute;
  except
    on E: Exception do
    begin
      if LogFileName <> '' then
        Log.Error(E.message);
      Log.Free;
      SqlProcessor.Free;
      Conn.Free;
      raise Exception.CreateFmtHelp(
        'Não foi possível criar o usuário e executar o arquivo script de configuração.'
          , [HostName], 2);
    end;
  end;
  SqlProcessor.Free;
  Conn.Free;
  if LogFileName <> '' then
    Log.Information
      ('Arquivo de script executado e usuário criado com sucesso!');
  Log.Free;
end;

procedure ExecSQL(const hwndParent: HWND; const string_size: Integer;
  const variables: Pointer; const stacktop: pointer); cdecl;
var
  User, Passwd, HostName, SQL, LogFileName, Encoding: string;
  Port: Integer;
  SResult: string;
  HelpContext: Integer;
begin
  Init(hwndParent, string_size, variables, stacktop);
  User := PopString;
  Passwd := PopString;
  HostName := PopString;
  Port := StrToIntDef(PopString, 3306);
  SQL := PopString;
  LogFileName := PopString;
  Encoding := PopString;
  SResult := '0';
  HelpContext := 0;
  try
    InternalExecSQL(User, Passwd, HostName, Port, SQL, LogFileName, Encoding);
  except
    on E: Exception do
    begin
      SResult := E.Message;
      HelpContext := E.HelpContext;
    end;
  end;
  PushString(IntToStr(HelpContext));
  PushString(SResult);
end;

procedure ExecSQLFromFile(const hwndParent: HWND; const string_size: Integer;
  const variables: Pointer; const stacktop: pointer); cdecl;
var
  User, Passwd, HostName, FileName, LogFileName, Encoding: string;
  Port: Integer;
  SResult: string;
  HelpContext: Integer;
begin
  Init(hwndParent, string_size, variables, stacktop);
  User := PopString;
  Passwd := PopString;
  HostName := PopString;
  Port := StrToIntDef(PopString, 3306);
  FileName := PopString;
  LogFileName := PopString;
  Encoding := PopString;
  SResult := '0';
  HelpContext := 0;
  try
    InternalExecSQLFromFile(User, Passwd, HostName, Port, FileName,
      LogFileName, Encoding);
  except
    on E: Exception do
    begin
      SResult := E.Message;
      HelpContext := E.HelpContext;
    end;
  end;
  PushString(IntToStr(HelpContext));
  PushString(SResult);
end;

procedure ExecSQLCreateUser(const hwndParent: HWND; const string_size: Integer;
  const variables: Pointer; const stacktop: pointer); cdecl;
var
  User, Passwd, HostName, UserAccess, UserName, UserHost, UserPasswd,
    SQL, LogFileName, Encoding: string;
  Port: Integer;
  SResult: string;
  HelpContext: Integer;
begin
  Init(hwndParent, string_size, variables, stacktop);
  User := PopString;
  Passwd := PopString;
  HostName := PopString;
  Port := StrToIntDef(PopString, 3306);
  UserAccess := PopString;
  UserName := PopString;
  UserHost := PopString;
  UserPasswd := PopString;
  SQL := PopString;
  LogFileName := PopString;
  Encoding := PopString;
  SResult := '0';
  HelpContext := 0;
  try
    InternalExecSQLCreateUser(User, Passwd, HostName, Port, UserAccess,
      UserName, UserHost, UserPasswd, SQL, LogFileName, Encoding);
  except
    on E: Exception do
    begin
      SResult := E.Message;
      HelpContext := E.HelpContext;
    end;
  end;
  PushString(IntToStr(HelpContext));
  PushString(SResult);
end;

procedure ExecSQLFromFileCreateUser(const hwndParent: HWND;
  const string_size: Integer; const variables: Pointer;
  const stacktop: pointer); cdecl;
var
  User, Passwd, HostName, UserAccess, UserName, UserHost, UserPasswd,
    FileName, LogFileName, Encoding: string;
  Port: Integer;
  SResult: string;
  HelpContext: Integer;
begin
  Init(hwndParent, string_size, variables, stacktop);
  User := PopString;
  Passwd := PopString;
  HostName := PopString;
  Port := StrToIntDef(PopString, 3306);
  UserAccess := PopString;
  UserName := PopString;
  UserHost := PopString;
  UserPasswd := PopString;
  FileName := PopString;
  LogFileName := PopString;
  Encoding := PopString;
  SResult := '0';
  HelpContext := 0;
  try
    InternalExecSQLFromFileCreateUser(User, Passwd, HostName, Port,
      UserAccess, UserName, UserHost, UserPasswd, FileName, LogFileName, Encoding);
  except
    on E: Exception do
    begin
      SResult := E.Message;
      HelpContext := E.HelpContext;
    end;
  end;
  PushString(IntToStr(HelpContext));
  PushString(SResult);
end;

exports ExecSQL, ExecSQLFromFile, ExecSQLCreateUser, ExecSQLFromFileCreateUser;

end.
