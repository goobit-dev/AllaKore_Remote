{


      This source has created by Maickonn Richard.
      Any questions, contact-me: senjaxus@gmail.com

      My Github: https://www.github.com/Senjaxus

      Are totally free!



}


unit Form_Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, AppEvnts, IdBaseComponent, IdComponent,
  IdTCPServer, IdMappedPortTCP, IdContext, IdCustomTCPServer, IdGlobal;

type
  TCustomThreadConnection = class(TThread)
  private
    FContext: TIdContext;
    FTarget: TIdContext;
  protected
    FID: string;
    function ReadString: string;
    function ReadBuffer: TIdBytes;
    procedure Execute; override;
  public
    constructor Create(AContext: TIdContext; AID: string = '');
    property Context: TIdContext read FContext;
    property ID: string read FID;
    property Target: TIdContext read FTarget write FTarget;
  end;

// Thread to Define type connection, if Main, Desktop Remote, Download or Upload Files.
type
  TThreadConnection_Define = class(TCustomThreadConnection)
  protected
    procedure Execute; override;
  end;

// Thread to Define type connection are Main.
type
  TThreadConnection_Main = class(TCustomThreadConnection)
  private
    Password, TargetID, TargetPassword: string;
    StartPing, EndPing: Cardinal;
  protected
    procedure Execute; override;
    procedure AddItems;
    procedure InsertTargetID;
    procedure InsertPing;
  end;

// Thread to Define type connection are Desktop.
type
  TThreadConnection_Desktop = class(TCustomThreadConnection)
  protected
    procedure Execute; override;
  end;

// Thread to Define type connection are Keyboard.
type
  TThreadConnection_Keyboard = class(TCustomThreadConnection)
  protected
    procedure Execute; override;
  end;

// Thread to Define type connection are Files.
type
  TThreadConnection_Files = class(TCustomThreadConnection)
  protected
    procedure Execute; override;
  end;

type
  Tfrm_Main = class(TForm)
    Splitter1: TSplitter;
    Logs_Memo: TMemo;
    Connections_ListView: TListView;
    ApplicationEvents1: TApplicationEvents;
    Main_IdTCPServer: TIdTCPServer;
    Ping_Timer: TTimer;
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure FormCreate(Sender: TObject);
    procedure Main_IdTCPServerExecute(AContext: TIdContext);
    procedure Main_IdTCPServerConnect(AContext: TIdContext);
    procedure Ping_TimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frm_Main: Tfrm_Main;

const
  Port = 3898; // Port for Indy Socket;

implementation

{$R *.dfm}

// Get current Version
function GetAppVersionStr: string;
type
  TBytes = array of Byte;
var
  Exe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  Exe := ParamStr(0);
  Size := GetFileVersionInfoSize(PChar(Exe), Handle);
  if Size = 0 then
    RaiseLastOSError;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
    RaiseLastOSError;
  if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
    RaiseLastOSError;
  Result := Format('%d.%d.%d.%d', [LongRec(FixedPtr.dwFileVersionMS).Hi,  //major
    LongRec(FixedPtr.dwFileVersionMS).Lo,  //minor
    LongRec(FixedPtr.dwFileVersionLS).Hi,  //release
    LongRec(FixedPtr.dwFileVersionLS).Lo]) //build
end;

function GenerateID(): string;
var
  i: Integer;
  ID: string;
  Exists: Boolean;
begin

  Exists := false;

  while true do
  begin
    Randomize;
    ID := IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + '-' + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + '-' + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9));

    i := 0;
    while i < frm_Main.Connections_ListView.Items.Count - 1 do
    begin

      if (frm_Main.Connections_ListView.Items.Item[i].SubItems[2] = ID) then
      begin
        Exists := True;
        break;
      end
      else
        Exists := false;

      Inc(i);
    end;
    if not (Exists) then
      Break;
  end;

  Result := ID;
end;

function GeneratePassword(): string;
begin
  Randomize;
  Result := IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9)) + IntToStr(Random(9));
end;

function FindListItemID(ID: string): TListItem;
var
  i: Integer;
begin
  i := 0;
  while i < frm_Main.Connections_ListView.Items.Count do
  begin
    if (frm_Main.Connections_ListView.Items.Item[i].SubItems[1] = ID) then
      break;

    Inc(i);
  end;
  Result := frm_Main.Connections_ListView.Items.Item[i];
end;

function CheckIDExists(ID: string): Boolean;
var
  i: Integer;
  Exists: Boolean;
begin

  Exists := false;
  i := 0;
  while i < frm_Main.Connections_ListView.Items.Count do
  begin
    if (frm_Main.Connections_ListView.Items.Item[i].SubItems[1] = ID) then
    begin
      Exists := true;
      break;
    end;

    Inc(i);
  end;
  Result := Exists;
end;

function CheckIDPassword(ID, Password: string): Boolean;
var
  i: Integer;
  Correct: Boolean;
begin

  Correct := false;
  i := 0;
  while i < frm_Main.Connections_ListView.Items.Count do
  begin
    if (frm_Main.Connections_ListView.Items.Item[i].SubItems[1] = ID) and (frm_Main.Connections_ListView.Items.Item[i].SubItems[2] = Password) then
    begin
      Correct := true;
      break;
    end;

    Inc(i);
  end;

  Result := Correct;

end;

{ TCustomThreadConnection }

constructor TCustomThreadConnection.Create(AContext: TIdContext; AID: string = '');
begin
  inherited Create(True);
  FContext := AContext;
  FID := AID;
  FreeOnTerminate := True;
end;

procedure TCustomThreadConnection.Execute;
begin
  {$IFDEF DEBUG}
  NameThreadForDebugging(AnsiString(Format('%s:%.8x', [ClassName, Integer(Self)])));
  {$ENDIF}
end;

function TCustomThreadConnection.ReadString: string;
var
  Bytes: TIdBytes;
  i: Integer;
begin
  Bytes := ReadBuffer;
  SetLength(Result, Length(Bytes));
  for i := 1 to Length(Result) do
    Word(Result[i]) := Bytes[i - 1];
end;

function TCustomThreadConnection.ReadBuffer: TIdBytes;
begin
  Result := Nil;
  try
    with Context.Connection.IOHandler do
      //Result := ReadLn;
      while not Terminated and Connected do begin
        while not Terminated and Connected and InputBufferIsEmpty do
          CheckForDataOnSource(IdTimeoutInfinite);
        if not InputBufferIsEmpty then begin
          InputBuffer.ExtractToBytes(Result, -1, False);
          Break;
        end;
      end;
  except
  end;
end;

{ Tfrm_Main }

procedure Tfrm_Main.ApplicationEvents1Exception(Sender: TObject; E: Exception);
begin
  Logs_Memo.Lines.Add(' ');
  Logs_Memo.Lines.Add(' ');
  Logs_Memo.Lines.Add(E.Message);
end;

procedure Tfrm_Main.FormCreate(Sender: TObject);
begin
  Main_IdTCPServer.DefaultPort := Port;
  Main_IdTCPServer.Active := true;

  Caption := Caption + ' - ' + GetAppVersionStr;
end;

procedure Tfrm_Main.Main_IdTCPServerExecute(AContext: TIdContext);
begin
  Sleep(5); // Avoids using 100% CPU
end;

{ TThreadConnection_Define }
// Here it will be defined the type of connection.
procedure TThreadConnection_Define.Execute;
var
  s, s2, ID: string;
  ThreadMain: TThreadConnection_Main;
  ThreadDesktop: TThreadConnection_Desktop;
  ThreadKeyboard: TThreadConnection_Keyboard;
  ThreadFiles: TThreadConnection_Files;
begin
  inherited;

  try
    while Context.Connection.Connected do
    begin
      s := ReadString;

      if (Length(s) < 1) then
        Break; // Break the while
      if (Pos('<|MAINSOCKET|>', s) > 0) then
      begin
      // Create the Thread for Main Socket
        ThreadMain := TThreadConnection_Main.Create(Context);
        ThreadMain.Start;

        break; // Break the while
      end;

      if (Pos('<|DESKTOPSOCKET|>', s) > 0) then
      begin
        s2 := s;

        Delete(s2, 1, Pos('<|DESKTOPSOCKET|>', s) + 16);
        ID := Copy(s2, 1, Pos('<<|', s2) - 1);

      // Create the Thread for Desktop Socket
        ThreadDesktop := TThreadConnection_Desktop.Create(Context, ID);
        ThreadDesktop.Start;

        break; // Break the while
      end;

      if (Pos('<|KEYBOARDSOCKET|>', s) > 0) then
      begin
        s2 := s;

        Delete(s2, 1, Pos('<|KEYBOARDSOCKET|>', s) + 17);
        ID := Copy(s2, 1, Pos('<<|', s2) - 1);

      // Create the Thread for Keyboard Socket
        ThreadKeyboard := TThreadConnection_Keyboard.Create(Context, ID);
        ThreadKeyboard.Start;

        break; // Break the while
      end;

      if (Pos('<|FILESSOCKET|>', s) > 0) then
      begin
        s2 := s;

        Delete(s2, 1, Pos('<|FILESSOCKET|>', s) + 14);
        ID := Copy(s2, 1, Pos('<<|', s2) - 1);

      // Create the Thread for Keyboard Socket
        ThreadFiles := TThreadConnection_Files.Create(Context, ID);
        ThreadFiles.Start;

        break; // Break the while
      end;
    end;
  except
  end;

end;

{ TThreadConnection_Main }

procedure TThreadConnection_Main.AddItems;
var
  L: TListItem;
begin
  FID := GenerateID;
  Password := GeneratePassword;
  L := frm_Main.Connections_ListView.Items.Add;
  L.Caption := IntToStr(Context.Binding.Handle);
  L.SubItems.Add(Context.Binding.PeerIP);
  L.SubItems.Add(ID);
  L.SubItems.Add(Password);
  L.SubItems.Add('');
  L.SubItems.Add('Calculating...');
  L.SubItems.Objects[4] := TObject(0);
end;

// The connection type is the main.
procedure TThreadConnection_Main.Execute;
var
  s, s2: string;
  L, L2: TListItem;
begin
  inherited;

  Synchronize(AddItems);

  L := frm_Main.Connections_ListView.FindCaption(0, IntToStr(Context.Binding.Handle), false, true, false);
  L.SubItems.Objects[0] := TObject(Self);

  Context.Connection.IOHandler.Write('<|ID|>' + ID + '<|>' + Password + '<<|');
  try
    while Context.Connection.Connected do
    begin

      s := ReadString;

      if (Length(s) < 1) then
      begin
        if Target <> nil then
          Target.Connection.IOHandler.Write('<|DISCONNECTED|>');
        Break;
      end;

      if (Pos('<|FINDID|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|FINDID|>', s2) + 9);

        TargetID := Copy(s2, 1, Pos('<<|', s2) - 1);

        if (CheckIDExists(TargetID)) then
          if (FindListItemID(TargetID).SubItems[3] = '') then
            Context.Connection.IOHandler.Write('<|IDEXISTS!REQUESTPASSWORD|>')
          else
            Context.Connection.IOHandler.Write('<|ACCESSBUSY|>')
        else
          Context.Connection.IOHandler.Write('<|IDNOTEXISTS|>');
      end;

      if (Pos('<|PONG|>', s) > 0) then
      begin
        EndPing := GetTickCount - StartPing;
        Synchronize(InsertPing);
      end;

      if (Pos('<|CHECKIDPASSWORD|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|CHECKIDPASSWORD|>', s2) + 18);

        TargetID := Copy(s2, 1, Pos('<|>', s2) - 1);
        Delete(s2, 1, Pos('<|>', s2) + 2);

        TargetPassword := Copy(s2, 1, Pos('<<|', s2) - 1);

        if (CheckIDPassword(TargetID, TargetPassword)) then
        begin
          Context.Connection.IOHandler.Write('<|ACCESSGRANTED|>');
        end
        else
          Context.Connection.IOHandler.Write('<|ACCESSDENIED|>');
      end;

      if (Pos('<|RELATION|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|RELATION|>', s2) + 11);

        FID := Copy(s2, 1, Pos('<|>', s2) - 1);
        Delete(s2, 1, Pos('<|>', s2) + 2);

        TargetID := Copy(s2, 1, Pos('<<|', s2) - 1);

        L := FindListItemID(ID);
        L2 := FindListItemID(TargetID);

        Synchronize(InsertTargetID);

      // Relates the main Sockets
        (L.SubItems.Objects[0] as TThreadConnection_Main).Target := (L2.SubItems.Objects[0] as TThreadConnection_Main).Context;
        (L2.SubItems.Objects[0] as TThreadConnection_Main).Target := (L.SubItems.Objects[0] as TThreadConnection_Main).Context;

      // Relates the Remote Desktop
        (L.SubItems.Objects[1] as TThreadConnection_Desktop).Target := (L2.SubItems.Objects[1] as TThreadConnection_Desktop).Context;
        (L2.SubItems.Objects[1] as TThreadConnection_Desktop).Target := (L.SubItems.Objects[1] as TThreadConnection_Desktop).Context;

      // Relates the Keyboard Socket
        (L.SubItems.Objects[2] as TThreadConnection_Keyboard).Target := (L2.SubItems.Objects[2] as TThreadConnection_Keyboard).Context;

      // Relates the Share Files
        (L.SubItems.Objects[3] as TThreadConnection_Files).Target := (L2.SubItems.Objects[3] as TThreadConnection_Files).Context;
        (L2.SubItems.Objects[3] as TThreadConnection_Files).Target := (L.SubItems.Objects[3] as TThreadConnection_Files).Context;

      // Get first screenshot
        (L.SubItems.Objects[1] as TThreadConnection_Desktop).Target.Connection.IOHandler.Write('<|GETFULLSCREENSHOT|>');         //<|NEWRESOLUTION|>996<|>528<<|

      // Warns Access
        (L.SubItems.Objects[0] as TThreadConnection_Main).Target.Connection.IOHandler.Write('<|ACCESSING|>');
      end;




    // Redirect commands
      if (Pos('<|REDIRECT|>', s) > 0) then
      begin
        s2 := s;
        Delete(s2, 1, Pos('<|REDIRECT|>', s2) + 11);

        if (Pos('<|FOLDERLIST|>', s2) > 0) then
        begin
          while Context.Connection.Connected do
          begin
            if (Pos('<<|FOLDERLIST', s2) > 0) then
              Break;
            s2 := s2 + ReadString;
            Sleep(5); // Avoids using 100% CPU
          end;
        end;

        if (Pos('<|FILESLIST|>', s2) > 0) then
        begin
          while Context.Connection.Connected do
          begin
            if (Pos('<<|FILESLIST', s2) > 0) then
              Break;
            s2 := s2 + ReadString;
            Sleep(5); // Avoids using 100% CPU
          end;
        end;

        Target.Connection.IOHandler.Write(s2);
      end;
    end;
  except
    L.Delete;
  end;
end;

procedure TThreadConnection_Main.InsertPing;
var
  L: TListItem;
begin

  L := frm_Main.Connections_ListView.FindCaption(0, IntToStr(Context.Binding.Handle), false, true, false);
  if (L <> nil) then
    L.SubItems[4] := intToStr(EndPing) + ' ms';

end;

procedure TThreadConnection_Main.InsertTargetID;
var
  L, L2: TListItem;
begin
  L := frm_Main.Connections_ListView.FindCaption(0, IntToStr(Context.Binding.Handle), false, true, false);
  if (L <> nil) then
  begin
    L2 := FindListItemID(TargetID);

    L.SubItems[3] := TargetID;
    L2.SubItems[3] := ID;
  end;
end;

{ TThreadConnection_Desktop }
// The connection type is the Desktop Screens
procedure TThreadConnection_Desktop.Execute;
var
  Bytes: TIdBytes;
  L: TListItem;
begin
  inherited;

  L := FindListItemID(ID);
  L.SubItems.Objects[1] := TObject(Self);

  try
    while Context.Connection.Connected do
    begin
      Bytes := ReadBuffer;

      if (Length(Bytes) = 0) then
        break;

      Target.Connection.IOHandler.Write(Bytes);
    end;
  except
  end;
end;

// The connection type is the Keyboard Remote
procedure TThreadConnection_Keyboard.Execute;
var
  Bytes: TIdBytes;
  L: TListItem;
begin
  inherited;

  L := FindListItemID(ID);
  L.SubItems.Objects[2] := TObject(Self);

  try
    while Context.Connection.Connected do
    begin
      Bytes := ReadBuffer;

      if (Length(Bytes) = 0) then
        break;

      Target.Connection.IOHandler.Write(Bytes);
    end;
  except
  end;
end;

{ TThreadConnection_Files }
// The connection type is to Share Files
procedure TThreadConnection_Files.Execute;
var
  Bytes: TIdBytes;
  L: TListItem;
begin
  inherited;

  L := FindListItemID(ID);
  L.SubItems.Objects[3] := TObject(Self);

  try
    while Context.Connection.Connected do
    begin
      Bytes := ReadBuffer;

      if (Length(Bytes) = 0) then
        break;

      Target.Connection.IOHandler.Write(Bytes);
    end;
  except
  end;
end;

procedure Tfrm_Main.Main_IdTCPServerConnect(AContext: TIdContext);
var
  Connection: TThreadConnection_Define;
begin
  // Create Defines Thread of Connections
  Connection := TThreadConnection_Define.Create(AContext);
  Connection.Start;
end;

procedure Tfrm_Main.Ping_TimerTimer(Sender: TObject);
var
  i: Integer;
begin
  for i := Connections_ListView.Items.Count - 1 downto 0 do
  begin
    try

      // Request Ping
      (Connections_ListView.Items.Item[i].SubItems.Objects[0] as TThreadConnection_Main).Context.Connection.IOHandler.Write('<|PING|>');
      (Connections_ListView.Items.Item[i].SubItems.Objects[0] as TThreadConnection_Main).StartPing := GetTickCount;


      // Check if Target ID exists, if not, delete it
      if not (Connections_ListView.Items.Item[i].SubItems[3] = '') then
      begin
        if not (CheckIDExists(Connections_ListView.Items.Item[i].SubItems[3])) then
        begin
          Connections_ListView.Items.Item[i].Delete;
        end;
      end;

    except
      // Any error, delete
      try
        Connections_ListView.Items.Item[i].Delete;
      except
      end;
    end;
  end;
end;

end.

