{
  Original Code from
  (C) 2001 - Peter Windridge

  Code in seperate unit and some changes
  2003 by Bernhard Mayer

  Fixed and formatted by Brett Dever
  http://editor.nfscheats.com/

  2014 Rodrigo Ruz  - theroadtodelphi.wordpress.com
  Added comptability for Delphi UNICODE Versions.

  2016 Francimar Alves  - mzsw.com.br
  Added switch for UNICODE and ANSI version.

  simply include this unit in your plugin project and export
  functions as needed
}

unit NSIS;

interface

{$INCLUDE NSIS.inc}

uses
  Windows, CommCtrl, SysUtils;

type
  VarConstants = (
    INST_0, // $0
    INST_1, // $1
    INST_2, // $2
    INST_3, // $3
    INST_4, // $4
    INST_5, // $5
    INST_6, // $6
    INST_7, // $7
    INST_8, // $8
    INST_9, // $9
    INST_R0, // $R0
    INST_R1, // $R1
    INST_R2, // $R2
    INST_R3, // $R3
    INST_R4, // $R4
    INST_R5, // $R5
    INST_R6, // $R6
    INST_R7, // $R7
    INST_R8, // $R8
    INST_R9, // $R9
    INST_CMDLINE, // $CMDLINE
    INST_INSTDIR, // $INSTDIR
    INST_OUTDIR, // $OUTDIR
    INST_EXEDIR, // $EXEDIR
    INST_LANG, // $LANGUAGE
    __INST_LAST
  );
  TVariableList = INST_0 .. __INST_LAST;

type
  PluginCallbackMessages = (NSPIM_UNLOAD,
    // This is the last message a plugin gets, do final cleanup
    NSPIM_GUIUNLOAD // Called after .onGUIEnd
    );
  TNSPIM = NSPIM_UNLOAD .. NSPIM_GUIUNLOAD;
  // TPluginCallback = function (const NSPIM: Integer): Pointer;
  TExecuteCodeSegment = function(const funct_id: Integer; const parent: HWND)
    : Integer; stdcall;
  Tvalidate_filename = procedure(const filename: Pointer); cdecl;
  TRegisterPluginCallback = function(const DllInstance: HMODULE;
    const CallbackFunction: Pointer): Integer; stdcall;

  pexec_flags_t = ^exec_flags_t;

  exec_flags_t = record
    autoclose: Integer;
    all_user_var: Integer;
    exec_error: Integer;
    abort: Integer;
    exec_reboot: Integer;
    reboot_called: Integer;
    XXX_cur_insttype: Integer;
    plugin_api_version: Integer;
    silent: Integer;
    instdir_error: Integer;
    rtl: Integer;
    errlvl: Integer;
    alter_reg_view: Integer;
    status_update: Integer;
  end;

  pextrap_t = ^extrap_t;

  extrap_t = record
    exec_flags: Pointer; // exec_flags_t;
    exec_code_segment: Pointer; // TFarProc;
    validate_filename: Pointer; // Tvalidate_filename;
    RegisterPluginCallback: Pointer; // TRegisterPluginCallback;
  end;

  pstack_t = ^stack_t;

  stack_t = record
    next: pstack_t;
    text: PAnsiChar;
  end;

{$IFDEF UNICODE}

  pstack_tW = ^stack_tW;

  stack_tW = record
    next: pstack_tW;
    text: PWideChar;
  end;
{$ENDIF}

var
  g_stringsize: Integer;
  g_stacktopA: ^pstack_t;
  g_variablesA: PAnsiChar;
{$IFDEF UNICODE}
  g_stacktopW: ^pstack_tW;
  g_variablesW: PWideChar;
{$ENDIF}
  g_hwndParent: HWND;
  g_hwndList: HWND;
  g_hwndLogList: HWND;

  g_extraparameters: pextrap_t;
  func: TExecuteCodeSegment;
  extrap: extrap_t;

procedure InitA(const hwndParent: HWND; const string_size: Integer;
  const variables: PAnsiChar; const stacktop: Pointer;
  const extraparameters: Pointer = nil);
function LogMessageA(const Msg: AnsiString): BOOL;
function CallA(const NSIS_func: AnsiString): Integer;
function PopStringA: AnsiString;
procedure PushStringA(const str: AnsiString = '');
function GetUserVariableA(const varnum: TVariableList): AnsiString;
procedure SetUserVariableA(const varnum: TVariableList;
  const value: AnsiString);
procedure NSISDialogA(const text, caption: AnsiString; const buttons: Integer);
{$IFDEF UNICODE}
procedure InitW(const hwndParent: HWND; const string_size: Integer;
  const variables: PWideChar; const stacktop: Pointer;
  const extraparameters: Pointer = nil);
function LogMessageW(const Msg: string): BOOL;
function CallW(const NSIS_func: string): Integer;
function PopStringW: string;
procedure PushStringW(const str: string = '');
function GetUserVariableW(const varnum: TVariableList): string;
procedure SetUserVariableW(const varnum: TVariableList; const value: string);
procedure NSISDialogW(const text, caption: string; const buttons: Integer);
{$ENDIF}

procedure Init(const hwndParent: HWND; const string_size: Integer;
  const variables: Pointer; const stacktop: Pointer;
  const extraparameters: Pointer = nil);
function LogMessage(const Msg: string): BOOL;
function Call(const NSIS_func: string): Integer;
function PopString: string;
procedure PushString(const str: string = '');
function GetUserVariable(const varnum: TVariableList): string;
procedure SetUserVariable(const varnum: TVariableList; const value: string);
procedure NSISDialog(const text, caption: string; const buttons: Integer);

implementation

procedure InitA(const hwndParent: HWND; const string_size: Integer;
  const variables: PAnsiChar; const stacktop: Pointer;
  const extraparameters: Pointer);
begin
  g_stringsize := string_size;
  g_hwndParent := hwndParent;
  g_stacktopA := stacktop;
  g_variablesA := variables;
  g_hwndList := 0;
  g_hwndList := FindWindowEx(FindWindowEx(g_hwndParent, 0, '#32770', nil), 0,
    'SysListView32', nil);
  g_extraparameters := extraparameters;
  if g_extraparameters <> nil then
    extrap := g_extraparameters^;
end;

{$IFDEF UNICODE}

procedure InitW(const hwndParent: HWND; const string_size: Integer;
  const variables: PWideChar; const stacktop: Pointer;
  const extraparameters: Pointer);
begin
  g_stringsize := string_size;
  g_hwndParent := hwndParent;
  g_stacktopW := stacktop;
  g_variablesW := variables;
  g_hwndList := 0;
  g_hwndList := FindWindowEx(FindWindowEx(g_hwndParent, 0, '#32770', nil), 0,
    'SysListView32', nil);
  g_extraparameters := extraparameters;
  if g_extraparameters <> nil then
    extrap := g_extraparameters^;
end;
{$ENDIF}

procedure Init(const hwndParent: HWND; const string_size: Integer;
  const variables: Pointer; const stacktop: Pointer;
  const extraparameters: Pointer);
begin
{$IFDEF NSIS_UNICODE}
  InitW(hwndParent, string_size, variables, stacktop, extraparameters);
{$ELSE}
  InitA(hwndParent, string_size, variables, stacktop, extraparameters);
{$ENDIF}
end;

function CallA(const NSIS_func: AnsiString): Integer;
var
  NSISFun: Integer; // The ID of nsis function
begin
  Result := 0;
  NSISFun := StrToIntDef(string(NSIS_func), 0);
  if (NSISFun <> 0) and (g_extraparameters <> nil) then
  begin
    @func := extrap.exec_code_segment;
    NSISFun := NSISFun - 1;
    Result := func(NSISFun, g_hwndParent);
  end;
end;

{$IFDEF UNICODE}

function CallW(const NSIS_func: string): Integer;
var
  NSISFun: Integer; // The ID of nsis function
begin
  Result := 0;
  NSISFun := StrToIntDef(NSIS_func, 0);
  if (NSISFun <> 0) and (g_extraparameters <> nil) then
  begin
    @func := extrap.exec_code_segment;
    NSISFun := NSISFun - 1;
    Result := func(NSISFun, g_hwndParent);
  end;
end;
{$ENDIF}

function Call(const NSIS_func: string): Integer;
begin
{$IFDEF NSIS_UNICODE}
  Result := CallW(NSIS_func);
{$ELSE}
  Result := CallA(AnsiString(NSIS_func));
{$ENDIF}
end;

function LogMessageA(const Msg: AnsiString): BOOL;
var
  ItemCount: Integer;
  item: TLVItemA;
begin
  Result := FAlse;
  if g_hwndList = 0 then
    exit;
  FillChar(item, sizeof(item), 0);
  ItemCount := SendMessage(g_hwndList, LVM_GETITEMCOUNT, 0, 0);
  item.iItem := ItemCount;
  item.mask := LVIF_TEXT;
  item.pszText := PAnsiChar(Msg);
  ListView_InsertItemA(g_hwndList, item);
  ListView_EnsureVisible(g_hwndList, ItemCount, TRUE);
end;

{$IFDEF UNICODE}

function LogMessageW(const Msg: string): BOOL;
var
  ItemCount: Integer;
  item: TLVItem;
begin
  Result := FAlse;
  if g_hwndList = 0 then
    exit;
  FillChar(item, sizeof(item), 0);
  ItemCount := SendMessage(g_hwndList, LVM_GETITEMCOUNT, 0, 0);
  item.iItem := ItemCount;
  item.mask := LVIF_TEXT;
  item.pszText := PWideChar(Msg);
  ListView_InsertItem(g_hwndList, item);
  ListView_EnsureVisible(g_hwndList, ItemCount, TRUE);
end;
{$ENDIF}

function LogMessage(const Msg: string): BOOL;
begin
{$IFDEF NSIS_UNICODE}
  Result := LogMessageW(Msg);
{$ELSE}
  Result := LogMessageA(AnsiString(Msg));
{$ENDIF}
end;

function PopStringA: AnsiString;
var
  th: pstack_t;
begin
  if Integer(g_stacktopA^) <> 0 then
  begin
    th := g_stacktopA^;
    Result := PAnsiChar(@th.text);
    g_stacktopA^ := th.next;
    GlobalFree(HGLOBAL(th));
  end;
end;

{$IFDEF UNICODE}

function PopStringW: string;
var
  th: pstack_tW;
begin
  if Integer(g_stacktopW^) <> 0 then
  begin
    th := g_stacktopW^;
    Result := PWideChar(@th.text);
    g_stacktopW^ := th.next;
    GlobalFree(HGLOBAL(th));
  end;
end;
{$ENDIF}

function PopString: string;
begin
{$IFDEF NSIS_UNICODE}
  Result := PopStringW;
{$ELSE}
  Result := string(PopStringA);
{$ENDIF}
end;

procedure PushStringA(const str: AnsiString);
var
  th: pstack_t;
begin
  if Integer(g_stacktopA) <> 0 then
  begin
    th := pstack_t(GlobalAlloc(GPTR, sizeof(stack_t) + g_stringsize));
    lstrcpynA(@th.text, PAnsiChar(str), g_stringsize);
    th.next := g_stacktopA^;
    g_stacktopA^ := th;
  end;
end;

{$IFDEF UNICODE}

procedure PushStringW(const str: string);
var
  th: pstack_tW;
begin
  if Integer(g_stacktopW) <> 0 then
  begin
    th := pstack_tW(GlobalAlloc(GPTR, sizeof(stack_t) + g_stringsize));
    lstrcpynW(@th.text, PWideChar(str), g_stringsize);
    th.next := g_stacktopW^;
    g_stacktopW^ := th;
  end;
end;
{$ENDIF}

procedure PushString(const str: string);
begin
{$IFDEF NSIS_UNICODE}
  PushStringW(str);
{$ELSE}
  PushStringA(AnsiString(str));
{$ENDIF}
end;

function GetUserVariableA(const varnum: TVariableList): AnsiString;
begin
  if (Integer(varnum) >= 0) and (Integer(varnum) < Integer(__INST_LAST)) then
    Result := g_variablesA + Integer(varnum) * g_stringsize
  else
    Result := '';
end;

{$IFDEF UNICODE}

function GetUserVariableW(const varnum: TVariableList): string;
begin
  if (Integer(varnum) >= 0) and (Integer(varnum) < Integer(__INST_LAST)) then
    Result := g_variablesW + Integer(varnum) * g_stringsize
  else
    Result := '';
end;
{$ENDIF}

function GetUserVariable(const varnum: TVariableList): string;
begin
{$IFDEF NSIS_UNICODE}
  Result := GetUserVariableW(varnum);
{$ELSE}
  Result := string(GetUserVariableA(varnum));
{$ENDIF}
end;

procedure SetUserVariableA(const varnum: TVariableList;
  const value: AnsiString);
begin
  if (value <> '') and (Integer(varnum) >= 0) and
    (Integer(varnum) < Integer(__INST_LAST)) then
    lstrcpyA(g_variablesA + Integer(varnum) * g_stringsize, PAnsiChar(value))
end;

{$IFDEF UNICODE}

procedure SetUserVariableW(const varnum: TVariableList; const value: string);
begin
  if (value <> '') and (Integer(varnum) >= 0) and
    (Integer(varnum) < Integer(__INST_LAST)) then
    lstrcpyW(g_variablesW + Integer(varnum) * g_stringsize, PWideChar(value))
end;
{$ENDIF}

procedure SetUserVariable(const varnum: TVariableList; const value: string);
begin
{$IFDEF NSIS_UNICODE}
  SetUserVariableW(varnum, value);
{$ELSE}
  SetUserVariableA(varnum, AnsiString(value));
{$ENDIF}
end;

procedure NSISDialogA(const text, caption: AnsiString; const buttons: Integer);
begin
  MessageBoxA(g_hwndParent, PAnsiChar(text), PAnsiChar(caption), buttons);
end;

{$IFDEF UNICODE}

procedure NSISDialogW(const text, caption: string; const buttons: Integer);
begin
  MessageBoxW(g_hwndParent, PWideChar(text), PWideChar(caption), buttons);
end;
{$ENDIF}

procedure NSISDialog(const text, caption: string; const buttons: Integer);
begin
{$IFDEF NSIS_UNICODE}
  NSISDialogW(text, caption, buttons);
{$ELSE}
  NSISDialogA(AnsiString(text), AnsiString(caption), buttons);
{$ENDIF}
end;

begin

end.
