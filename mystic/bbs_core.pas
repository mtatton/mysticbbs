Unit BBS_Core;

{$I M_OPS.PAS}

Interface

Uses
  m_io_Base,
  {$IFNDEF UNIX}
  m_io_Sockets,
  {$ENDIF}
  m_FileIO,
  m_Strings,
  m_DateTime,
  BBS_Common,
  BBS_IO,
  BBS_MsgBase,
  BBS_User,
  BBS_FileBase,
  BBS_Menus,
  MPL_Execute;

Const
  mysMessageThreshold = 3;

Type
  TBBSCore = Class
    {$IFNDEF UNIX}
      Client        : TIOBase;
    {$ENDIF}
    User          : TBBSUser;
    Msgs          : TMsgBase;
    FileBase      : TFileBase;
    Menu          : TMenuEngine;
    IO            : TBBSIO;
    EventFile     : File of EventRec;
    ThemeFile     : File of RecTheme;
    VoteFile      : File of VoteRec;
    Vote          : VoteRec;
    CommHandle    : LongInt;
    ShutDown      : Boolean;
    TempPath      : String;
    Event         : EventRec;
    NextEvent     : EventRec;
    Theme         : RecTheme;
    LocalMode     : Boolean;
    Baud          : LongInt;
    ExitLevel     : Byte;
    EventWarn     : Boolean;
    EventExit     : Boolean;
    EventRunAfter : Boolean;
    NodeNum       : Byte;
    TimerStart    : Integer;
    TimerEnd      : Integer;
    LastTimeLeft  : Integer;
    TimeOut       : LongInt;
    UserHostInfo  : String[50];
    UserIPInfo    : String[15];
    CheckTimeOut  : Boolean;
    TimeOffset    : Word;
    TimeSaved     : Word;
    TimerOn       : Boolean;
    TimeChecked   : Boolean;
    ConfigMode    : Boolean;
    InUserEdit    : Boolean;
    AllowMessages : Boolean;
    InMessage     : Boolean;
    MessageCheck  : Byte;
    HistoryFile   : File of RecHistory;
    HistoryEmails : Word;
    HistoryPosts  : Word;
    HistoryDLs    : Word;
    HistoryDLKB   : LongInt;
    HistoryULs    : Word;
    HistoryULKB   : LongInt;
    PromptFile    : File of RecPrompt;
    Prompt        : RecPrompt;

    Constructor Create;
    Destructor  Destroy; Override;

    Procedure   UpdateHistory;
    Procedure   FindNextEvent;
    Function    GetPrompt         (N : Word) : String;
    Procedure   SystemLog         (Str: String);
    Function    MinutesUntilEvent (ExecTime: Integer): Integer;
    Procedure   SetTimeLeft       (Mins: Integer);
    Function    ElapsedTime       : Integer;
    Function    TimeLeft          : Integer;
    Function    LoadThemeData     (Str: String) : Boolean;
  End;

Var
  Session : TBBSCore;

Implementation

Constructor TBBSCore.Create;
Begin
  Inherited Create;

  HistoryEmails := 0;
  HistoryPosts  := 0;
  HistoryDLs    := 0;
  HistoryDLKB   := 0;
  HistoryULs    := 0;
  HistoryULKB   := 0;
  ShutDown      := False;
  CommHandle    := -1;
  LocalMode     := False;
  Baud          := -1;
  ExitLevel     := 0;
  EventWarn     := False;
  EventExit     := False;
  EventRunAfter := False;
  NodeNum       := 1;
  UserHostInfo  := '';
  UserIPInfo    := '';
  CheckTimeOut  := True;
  TimeOffset    := 0;
  TimeSaved     := 0;
  TimerOn       := False;
  TimeChecked   := False;
  ConfigMode    := False;
  InUserEdit    := False;
  AllowMessages := True;
  InMessage     := False;
  MessageCheck  := mysMessageThreshold;

  {$IFNDEF UNIX}
    Client := TIOSocket.Create;
    TIOSocket(Client).FTelnetServer := True;
  {$ENDIF}

  User     := TBBSUser.Create(Pointer(Self));
  IO       := TBBSIO.Create(Pointer(Self));
  Msgs     := TMsgBase.Create(Pointer(Self));
  FileBase := TFileBase.Create(Pointer(Self));
  Menu     := TMenuEngine.Create(Pointer(Self));
End;

Destructor TBBSCore.Destroy;
Begin
  Msgs.Free;
  FileBase.Free;
  Menu.Free;
  User.Free;
  IO.Free;

  Close (PromptFile);

  {$IFDEF WINDOWS}
    Client.Free;
  {$ENDIF}

  Inherited Destroy;
End;

Procedure TBBSCore.UpdateHistory;
Var
  History : RecHistory;
Begin
  If User.ThisUser.Flags AND UserNoHistory = 0 Then Exit;

  Assign  (HistoryFile, Config.DataPath + 'history.dat');
  ioReset (HistoryFile, SizeOf(RecHistory), fmRWDN);

  If IoResult <> 0 Then ioReWrite(HistoryFile, SizeOf(RecHistory), fmRWDW);

  History.Date := CurDateDos;

  While Not Eof(HistoryFile) Do Begin
    ioRead (HistoryFile, History);

    If DateDos2Str(History.Date, 1) = DateDos2Str(CurDateDos, 1) Then Begin
      ioSeek (HistoryFile, FilePos(HistoryFile) - 1);
      Break;
    End;
  End;

  If Eof(HistoryFile) Then Begin
    FillChar(History, SizeOf(History), 0);
    History.Date := CurDateDos;
  End;

  Inc (History.Emails,     HistoryEmails);
  Inc (History.Posts,      HistoryPosts);
  Inc (History.Downloads,  HistoryDLs);
  Inc (History.Uploads,    HistoryULs);
  Inc (History.DownloadKB, HistoryDLKB);
  Inc (History.UploadKB,   HistoryULKB);

  If Not LocalMode And (User.ThisUser.Flags AND UserNoLastCall = 0) Then
    Inc (History.Calls, 1);

  If User.ThisUser.Calls = 1 Then Inc (History.NewUsers, 1);

  ioWrite (HistoryFile, History);
  Close   (HistoryFile);
End;

Procedure TBBSCore.FindNextEvent;
Var
  MinCheck : Integer;
Begin
  NextEvent.Active := False;

  MinCheck := -1;

  Assign  (EventFile, Config.DataPath + 'events.dat');
  ioReset (EventFile, SizeOf(EventRec), fmRWDN);

  If IoResult <> 0 Then ioReWrite (EventFile, SizeOf(EventRec), fmRWDN);

  While Not Eof(EventFile) Do Begin
    ioRead (EventFile, Event);

    If MinCheck = -1 Then Begin
      If Event.Active and ((Event.Node = 0) or (Event.Node = NodeNum)) Then begin
        MinCheck  := MinutesUntilEvent(Event.ExecTime);
        NextEvent := Event;
      End;
    End Else
    If (Event.Active) and ((Event.Node = 0) or (Event.Node = NodeNum)) and (MinutesUntilEvent(Event.ExecTime) < MinCheck) Then Begin
      MinCheck  := MinutesUntilEvent(Event.ExecTime);
      NextEvent := Event;
    End;
  End;

  Close (EventFile);
End;

Function TBBSCore.GetPrompt (N : Word) : String;
Begin
  {$I-}
  Seek (PromptFile, N);
  Read (PromptFile, Prompt);
  {$I+}

  If IoResult <> 0 Then Begin
    FileMode := 66;

    {$I-}
    Assign (PromptFile, Config.DataPath + Theme.FileName + '.thm');
    Reset  (PromptFile);
    Seek   (PromptFile, N);
    Read   (PromptFile, Prompt);
    {$I+}

    If IoResult <> 0 Then Begin
      io.OutFull ('|CR|12Error reading prompt ' + strI2S(N) + '|DE|DE');
      SystemLog  ('Error reading prompt ' + strI2S(N));
      Halt       (1);
    End;
  End;

  If Prompt[1] = '@' Then Begin
    io.OutFile (Copy(Prompt, 2, Length(Prompt)), True, 0);
    Prompt := '';
  End Else
  If Prompt[1] = '!' Then Begin
    ExecuteMPL (NIL, Copy(Prompt, 2, Length(Prompt)));
    Prompt := '';
  End;

  Result := Prompt;
End;

Procedure TBBSCore.SystemLog (Str: String);
Var
  tLOG : Text;
Begin
  Assign (tLOG, Config.LogsPath + 'sysop.' + strI2S(NodeNum));
  {$I-} Append(tLOG); {$I+}
  If IoResult <> 0 Then ReWrite (tLOG);

  If Str = '-' Then
    WriteLn (tLOG, strRep('-', 40))
  Else
    WriteLn (tLOG, DateDos2Str(CurDateDos, 1) + ' ' + TimeDos2Str(CurDateDos, False) + ' ' + Str);

  Close (tLOG);
End;

Function TBBSCore.MinutesUntilEvent (ExecTime: Integer): Integer;
Begin {exits if 0 mins}
  If ExecTime > TimerMinutes Then Result := ExecTime - TimerMinutes Else
  If TimerMinutes > ExecTime Then Result := 1440 - TimerMinutes + ExecTime Else
  If NextEvent.Active Then Begin
    If DateDos2Str(NextEvent.LastRan, 1) = DateDos2Str(CurDateDos, 1) Then Begin
      Result := 1440; {if it was already ran...}
      Exit;
    End;
    If NextEvent.Forced Then Begin
      EventExit := True;
      {$IFDEF UNIX}
        io.OutFullLn (GetPrompt(137));
        SystemLog ('User disconnected for system event');
      {$ELSE}
        If Not LocalMode Then begin
          io.OutFullLn    (GetPrompt(137));
          SystemLog('User disconnected for system event');
        End;
      {$ENDIF}

      SystemLog('Event: ' + NextEvent.Name);

      Halt (NextEvent.ErrLevel);
    End Else
      EventRunAfter := True;
  End;
End;

Procedure TBBSCore.SetTimeLeft (Mins: Integer);
Begin
  TimerStart := TimerMinutes;
  TimerEnd   := TimerStart + Mins;
  TimerOn    := True;
End;

Function TBBSCore.ElapsedTime : Integer;
Begin
  If TimerStart > TimerMinutes Then Begin
    Dec (TimerStart, 1440);
    Dec (TimerEnd,   1440);
  End;

  ElapsedTime := TimerMinutes - TimerStart;
End;

Function TBBSCore.TimeLeft : Integer;
Begin
  If Not TimerOn Then Begin
    TimeLeft := 0;
    Exit;
  End;

  If TimerStart > TimerMinutes Then Begin
    Dec (TimerStart, 1440);
    Dec (TimerEnd,   1440);

    SetTimeLeft (User.Security.Time);
  End;

  TimeLeft := TimerEnd - TimerMinutes;
End;

Function TBBSCore.LoadThemeData (Str: String) : Boolean;
Begin
  Result := False;

  Reset (ThemeFile);

  While Not Eof(ThemeFile) Do Begin
    Read (ThemeFile, Theme);

    {$IFDEF FS_SENSITIVE}
    If Theme.FileName = Str Then Begin
    {$ELSE}
    If strUpper(Theme.FileName) = strUpper(Str) Then Begin
    {$ENDIF}
      If Not FileExist(Config.DataPath + Theme.FileName + '.thm') Then Break;

      {$I-} Close (PromptFile); {$I+}

      If IoResult <> 0 Then;

      Assign (PromptFile, Config.DataPath + Theme.FileName + '.thm');

      Result := ioReset(PromptFile, SizeOf(RecPrompt), fmRWDN);

      Break;
    End;
  End;

  Close (ThemeFile);
End;

End.
