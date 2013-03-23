Unit MUTIL_Common;

{$I M_OPS.PAS}

Interface

Uses
  m_Output,
  m_IniReader,
  mutil_Status,
  bbs_Common,
  bbs_MsgBase_Abs,
  bbs_MsgBase_Squish,
  bbs_MsgBase_JAM;

Var
  Console      : TOutput;
  INI          : TINIReader;
  BarOne       : TStatusBar;
  BarAll       : TStatusBar;
  ProcessTotal : Byte = 0;
  ProcessPos   : Byte = 0;
  bbsConfig    : RecConfig;
  TempPath     : String;
  StartPath    : String;
  LogFile      : String;
  LogLevel     : Byte = 1;

Const
  Header_GENERAL    = 'General';
  Header_IMPORTNA   = 'Import_FIDONET.NA';
  Header_IMPORTMB   = 'Import_MessageBase';
  Header_ECHOEXPORT = 'ExportEchoMail';
  Header_ECHOIMPORT = 'ImportEchoMail';
  Header_FILEBONE   = 'Import_FILEBONE.NA';
  Header_FILESBBS   = 'Import_FILES.BBS';
  Header_UPLOAD     = 'MassUpload';
  Header_TOPLISTS   = 'GenerateTopLists';
  Header_ALLFILES   = 'GenerateAllFiles';
  Header_MSGPURGE   = 'PurgeMessageBases';
  Header_MSGPACK    = 'PackMessageBases';
  Header_MSGPOST    = 'PostTextFiles';

Procedure Log                (Level: Byte; Code: Char; Str: String);
Function  strAddr2Str        (Addr : RecEchoMailAddr) : String;
Function  GetUserBaseSize    : Cardinal;
Function  GenerateMBaseIndex : LongInt;
Function  GenerateFBaseIndex : LongInt;
Function  IsDupeMBase        (FN: String) : Boolean;
Function  IsDupeFBase        (FN: String) : Boolean;
Procedure AddMessageBase     (Var MBase: RecMessageBase);
Procedure AddFileBase        (Var FBase: RecFileBase);
Function  ShellDOS           (ExecPath: String; Command: String) : LongInt;
Procedure ExecuteArchive     (FName: String; Temp: String; Mask: String; Mode: Byte);
Function  GetMBaseByIndex    (Num: LongInt; Var TempBase: RecMessageBase) : Boolean;
Function  GetMBaseByTag      (Tag: String; Var TempBase: RecMessageBase) : Boolean;
Function  GetMBaseByNetZone  (Zone: Word; Var TempBase: RecMessageBase) : Boolean;
Function  MessageBaseOpen    (Var Msg: PMsgBaseABS; Var Area: RecMessageBase) : Boolean;
Function  SaveMessage        (mArea: RecMessageBase; mFrom, mTo, mSubj: String; mAddr: RecEchoMailAddr; mText: RecMessageText; mLines: Integer) : Boolean;
Function  GetFTNPKTName      : String;
Function  GetFTNArchiveName  (Orig, Dest: RecEchoMailAddr) : String;
Function  GetFTNFlowName     (Dest: RecEchoMailAddr) : String;
Function  GetNodeByIndex     (Num: LongInt; Var TempNode: RecEchoMailNode) : Boolean;

Implementation

Uses
  {$IFDEF UNIX}
    Unix,
  {$ENDIF}
  DOS,
  m_Types,
  m_Strings,
  m_DateTime,
  m_FileIO;

Procedure Log (Level: Byte; Code: Char; Str: String);
Var
  T : Text;
Begin
  If (LogLevel < Level) or (LogFile = '') Then Exit;

  Assign (T, LogFile);
  Append (T);

  If Str = '' Then
    WriteLn (T, '')
  Else
    WriteLn (T, Code + ' ' + DateDos2Str(CurDateDos, 1) + ' ' + TimeDos2Str(CurDateDos, 2) + ' ' + Str);

  Close (T);
End;

Function strAddr2Str (Addr : RecEchoMailAddr) : String;
Var
  Temp : String[20];
Begin
  Temp := strI2S(Addr.Zone) + ':' + strI2S(Addr.Net) + '/' +
          strI2S(Addr.Node);

  If Addr.Point <> 0 Then Temp := Temp + '.' + strI2S(Addr.Point);

  Result := Temp;
End;

Function GetUserBaseSize : Cardinal;
Begin
  Result := FileByteSize(bbsConfig.DataPath + 'users.dat');

  If Result > 0 Then Result := Result DIV SizeOf(RecUser);
End;

Function IsDupeMBase (FN: String) : Boolean;
Var
  MBaseFile : File of RecMessageBase;
  MBase     : RecMessageBase;
Begin
  Result := False;

  Assign (MBaseFile, bbsConfig.DataPath + 'mbases.dat');
  {$I-} Reset (MBaseFile); {$I+}

  If IoResult <> 0 Then Exit;

  While Not Eof(MBaseFile) Do Begin
    Read (MBaseFile, MBase);

    If strUpper(MBase.FileName) = strUpper(FN) Then Begin
      Result := True;
      Break;
    End;
  End;

  Close (MBaseFile);
End;

Function IsDupeFBase (FN: String) : Boolean;
Var
  FBaseFile : File of RecFileBase;
  FBase     : RecFileBase;
Begin
  Result := False;

  Assign (FBaseFile, bbsConfig.DataPath + 'fbases.dat');
  {$I-} Reset (FBaseFile); {$I+}

  If IoResult <> 0 Then Exit;

  While Not Eof(FBaseFile) Do Begin
    Read (FBaseFile, FBase);

    If strUpper(FBase.FileName) = strUpper(FN) Then Begin
      Result := True;
      Break;
    End;
  End;

  Close (FBaseFile);
End;

Function GenerateMBaseIndex : LongInt;
Var
  MBaseFile : File of RecMessageBase;
  MBase     : RecMessageBase;
Begin
  Assign (MBaseFile, bbsConfig.DataPath + 'mbases.dat');
  Reset  (MBaseFile);

  Result := FileSize(MBaseFile);

  While Not Eof(MBaseFile) Do Begin
    Read (MBaseFile, MBase);

    If MBase.Index = Result Then Begin
      Inc   (Result);
      Reset (MBaseFile);
    End;
  End;

  Close (MBaseFile);
End;

Function GenerateFBaseIndex : LongInt;
Var
  FBaseFile : File of RecFileBase;
  FBase     : RecFileBase;
Begin
  Assign (FBaseFile, bbsConfig.DataPath + 'fbases.dat');
  Reset  (FBaseFile);

  Result := FileSize(FBaseFile);

  While Not Eof(FBaseFile) Do Begin
    Read (FBaseFile, FBase);

    If FBase.Index = Result Then Begin
      Inc   (Result);
      Reset (FBaseFile);
    End;
  End;

  Close (FBaseFile);
End;

Procedure AddMessageBase (Var MBase: RecMessageBase);
Var
  MBaseFile : File of RecMessageBase;
Begin
  Assign (MBaseFile, bbsConfig.DataPath + 'mbases.dat');
  Reset  (MBaseFile);
  Seek   (MBaseFile, FileSize(MBaseFile));
  Write  (MBaseFile, MBase);
  Close  (MBaseFile);
End;

Procedure AddFileBase (Var FBase: RecFileBase);
Var
  FBaseFile : File of RecFileBase;
Begin
  Assign (FBaseFile, bbsConfig.DataPath + 'fbases.dat');
  Reset  (FBaseFile);
  Seek   (FBaseFile, FileSize(FBaseFile));
  Write  (FBaseFile, FBase);
  Close  (FBaseFile);
End;

Function ShellDOS (ExecPath: String; Command: String) : LongInt;
Var
  Image : TConsoleImageRec;
Begin
  Console.GetScreenImage(1, 1, 80, 25, Image);

  If ExecPath <> '' Then DirChange(ExecPath);

  {$IFDEF UNIX}
    Result := Shell(Command);
  {$ENDIF}

  {$IFDEF WINDOWS}
    If Command <> '' Then Command := '/C' + Command;

    Exec (GetEnv('COMSPEC'), Command);

    Result := DosExitCode;
  {$ENDIF}

  DirChange(StartPath);

  Console.PutScreenImage(Image);
End;

Procedure ExecuteArchive (FName: String; Temp: String; Mask: String; Mode: Byte);
Var
  ArcFile : File of RecArchive;
  Arc     : RecArchive;
  Count   : LongInt;
  Str     : String;
Begin
  If Temp <> '' Then
    Temp := strUpper(Temp)
  Else
    Temp := strUpper(JustFileExt(FName));

  Assign (ArcFile, bbsConfig.DataPath + 'archive.dat');
  {$I-} Reset (ArcFile); {$I+}

  If IoResult <> 0 Then Exit;

  Repeat
    If Eof(ArcFile) Then Begin
      Close (ArcFile);

      Exit;
    End;

    Read (ArcFile, Arc);

    If (Not Arc.Active) or ((Arc.OSType <> OSType) and (Arc.OSType <> 3)) Then Continue;

    If strUpper(Arc.Ext) = Temp Then Break;
  Until False;

  Close (ArcFile);

  Case Mode of
    1 : Str := Arc.Pack;
    2 : Str := Arc.Unpack;
  End;

  If Str = '' Then Exit;

  Temp  := '';
  Count := 1;

  While Count <= Length(Str) Do Begin
    If Str[Count] = '%' Then Begin
      Inc (Count);

      If Str[Count] = '1' Then Temp := Temp + FName Else
      If Str[Count] = '2' Then Temp := Temp + Mask Else
      If Str[Count] = '3' Then Temp := Temp + TempPath;
    End Else
      Temp := Temp + Str[Count];

    Inc (Count);
  End;

  ShellDOS ('', Temp);
End;

Function GetMBaseByIndex (Num: LongInt; Var TempBase: RecMessageBase) : Boolean;
Var
  F : File;
Begin
  Result := False;

  Assign (F, bbsConfig.DataPath + 'mbases.dat');

  If Not ioReset(F, SizeOf(RecMessageBase), fmRWDN) Then Exit;

  While Not Eof(F) Do Begin
    ioRead(F, TempBase);

    If TempBase.Index = Num Then Begin
      Result := True;
      Break;
    End;
  End;

  Close (F);
End;

Function GetMBaseByTag (Tag: String; Var TempBase: RecMessageBase) : Boolean;
Var
  F : File;
Begin
  Result := False;

  Assign (F, bbsConfig.DataPath + 'mbases.dat');

  If Not ioReset(F, SizeOf(RecMessageBase), fmRWDN) Then Exit;

  While Not Eof(F) Do Begin
    ioRead(F, TempBase);

    If Tag = strUpper(TempBase.EchoTag) Then Begin
      Result := True;
      Break;
    End;
  End;

  Close (F);
End;

Function GetMBaseByNetZone (Zone: Word; Var TempBase: RecMessageBase) : Boolean;
// get netmail base with matching zone, or at least A netmail base if no match
Var
  F      : File;
  One    : RecMessageBase;
  GotOne : Boolean;
Begin
  Result := False;

  Assign (F, bbsConfig.DataPath + 'mbases.dat');

  If Not ioReset(F, SizeOf(RecMessageBase), fmRWDN) Then Exit;

  While Not Eof(F) Do Begin
    ioRead(F, TempBase);

    If (TempBase.NetType = 3) Then Begin
      One    := TempBase;
      GotOne := True;

      If Zone = bbsConfig.NetAddress[TempBase.NetAddr].Zone Then Begin
        Result := True;

        Break;
      End;
    End;
  End;

  Close (F);

  If Not Result And GotOne Then Begin
    Result   := True;
    TempBase := One;
  End;
End;

Function MessageBaseOpen (Var Msg: PMsgBaseABS; Var Area: RecMessageBase) : Boolean;
Begin
  Result := False;

  Case Area.BaseType of
    0 : Msg := New(PMsgBaseJAM, Init);
    1 : Msg := New(PMsgBaseSquish, Init);
  End;

  Msg^.SetMsgPath  (Area.Path + Area.FileName);
  Msg^.SetTempFile (TempPath + 'msgbuf.tmp');

  If Not Msg^.OpenMsgBase Then
    If Not Msg^.CreateMsgBase (Area.MaxMsgs, Area.MaxAge) Then Begin
      Dispose (Msg, Done);
      Exit;
    End Else
    If Not Msg^.OpenMsgBase Then Begin
      Dispose (Msg, Done);
      Exit;
    End;

  Result := True;
End;

Function SaveMessage (mArea: RecMessageBase; mFrom, mTo, mSubj: String; mAddr: RecEchoMailAddr; mText: RecMessageText; mLines: Integer) : Boolean;
Var
  SemFile : File;
  Count   : SmallInt;
  Msg     : PMsgBaseABS;
Begin
  Result := False;

  If Not MessageBaseOpen(Msg, mArea) Then Exit;

  Msg^.StartNewMsg;
  Msg^.SetLocal (True);

  If mArea.NetType > 0 Then Begin
    If mArea.NetType = 2 Then Begin
      Msg^.SetMailType (mmtNetMail);
      Msg^.SetCrash    (bbsConfig.netCrash);
      Msg^.SetHold     (bbsConfig.netHold);
      Msg^.SetKillSent (bbsConfig.netKillSent);
      Msg^.SetDest     (mAddr);
    End Else
      Msg^.SetMailType (mmtEchoMail);

    Msg^.SetOrig(bbsConfig.NetAddress[mArea.NetAddr]);

    Case mArea.NetType of
      1 : Assign (SemFile, bbsConfig.SemaPath + fn_SemFileEcho);
      2 : Assign (SemFile, bbsConfig.SemaPath + fn_SemFileNews);
      3 : Assign (SemFile, bbsConfig.SemaPath + fn_SemFileNet);
    End;

    ReWrite (SemFile);
    Close   (SemFile);
  End Else
    Msg^.SetMailType (mmtNormal);

  Msg^.SetPriv (mArea.Flags And MBPrivate <> 0);
  Msg^.SetDate (DateDos2Str(CurDateDos, 1));
  Msg^.SetTime (TimeDos2Str(CurDateDos, 0));
  Msg^.SetFrom (mFrom);
  Msg^.SetTo   (mTo);
  Msg^.SetSubj (mSubj);

  For Count := 1 to mLines Do
    Msg^.DoStringLn(mText[Count]);

  If mArea.NetType > 0 Then Begin
    Msg^.DoStringLn (#13 + '--- ' + mysSoftwareID + ' BBS v' + mysVersion + ' (' + OSID + ')');
    Msg^.DoStringLn (' * Origin: ' + mArea.Origin + ' (' + strAddr2Str(bbsConfig.NetAddress[mArea.NetAddr]) + ')');
  End;

  Msg^.WriteMsg;
  Msg^.CloseMsgBase;

  Dispose (Msg, Done);

  Result := True;
End;

Function GetFTNPKTName : String;
Var
  Hour, Min, Sec, hSec  : Word;
  Year, Month, Day, DOW : Word;
Begin
  GetTime (Hour, Min, Sec, hSec);
  GetDate (Year, Month, Day, DOW);

  Result := strZero(Day) + strZero(Hour) + strZero(Min) + strZero(Sec);
End;

Function GetFTNArchiveName (Orig, Dest: RecEchoMailAddr) : String;
Var
  Net  : LongInt;
  Node : LongInt;
Begin
  Net  := Orig.Net  - Dest.Net;
  Node := Orig.Node - Dest.Node;

  If Net  < 0 Then Net  := 65536 + Net;
  If Node < 0 Then Node := 65536 + Node;

  Result := strI2H((Net SHL 16) OR Node);
End;

Function GetFTNFlowName (Dest: RecEchoMailAddr) : String;
Begin
  Result := strI2H((Dest.Net SHL 16) OR Dest.Node);
End;

Function GetNodeByIndex (Num: LongInt; Var TempNode: RecEchoMailNode) : Boolean;
Var
  F : File;
Begin
  Result := False;

  Assign (F, bbsConfig.DataPath + 'echonode.dat');

  If Not ioReset(F, SizeOf(RecEchoMailNode), fmRWDN) Then Exit;

  While Not Eof(F) Do Begin
    ioRead(F, TempNode);

    If TempNode.Index = Num Then Begin
      Result := True;

      Break;
    End;
  End;

  Close (F);
End;

End.
