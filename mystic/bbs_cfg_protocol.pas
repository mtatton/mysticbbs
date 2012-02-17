Unit bbs_cfg_Protocol;

{$I M_OPS.PAS}

Interface

Procedure Configuration_ProtocolEditor;

Implementation

Uses
  m_FileIO,
  m_Strings,
  bbs_Common,
  bbs_ansi_MenuBox,
  bbs_ansi_MenuForm;

Procedure EditProtocol (Var Prot: RecProtocol);
Var
  Box  : TAnsiMenuBox;
  Form : TAnsiMenuForm;
Begin
  Box  := TAnsiMenuBox.Create;
  Form := TAnsiMenuForm.Create;

  Form.HelpSize := 0;

  Box.Header := ' Protocol Editor: ' + Prot.Desc + ' ';

  Box.Open (6, 5, 75, 15);

  VerticalLine (22, 7, 13);

  Form.AddBol  ('A', ' Active '      , 14,  7, 24,  7,  8, 3, @Prot.Active, '');
  Form.AddTog  ('O', ' OS '          , 18,  8, 24,  8,  4, 7, 0, 2, 'Windows Linux OSX', @Prot.OSType, '');
  Form.AddBol  ('B', ' Batch '       , 15,  9, 24,  9,  7, 3, @Prot.Batch, '');
  Form.AddChar ('K', ' Hot Key '     , 13, 10, 24, 10,  9, 1, 254, @Prot.Key, '');
  Form.AddStr  ('D', ' Description ' ,  9, 11, 24, 11, 13, 40, 40, @Prot.Desc, '');
  Form.AddStr  ('S', ' Send Command ',  8, 12, 24, 12, 14, 50, 100, @Prot.SendCmd, '');
  Form.AddStr  ('R', ' Recv Command ',  8, 13, 24, 13, 14, 50, 100, @Prot.RecvCmd, '');

  Form.Execute;
  Box.Close;

  Form.Free;
  Box.Free;
End;

Procedure Configuration_ProtocolEditor;
Var
  Box  : TAnsiMenuBox;
  List : TAnsiMenuList;
  F    : TBufFile;
  Prot : RecProtocol;

  Procedure MakeList;
  Var
    OS : String;
  Begin
    List.Clear;

    F.Reset;

    While Not F.Eof Do Begin
      F.Read (Prot);

      Case Prot.OSType of
        0 : OS := 'Windows';
        1 : OS := 'Linux  ';
        2 : OS := 'OSX';
      End;

      //'Active   OSID   Batch   Key   Description');

      List.Add (strPadR(strYN(Prot.Active), 6, ' ') + '   ' + strPadR(OS, 7, ' ') + '   ' + strPadR(strYN(Prot.Batch), 5, ' ') + '   ' + strPadR(Prot.Key, 4, ' ') + Prot.Desc, 0);
    End;

    List.Add ('', 2);
  End;

Begin
  F := TBufFile.Create(SizeOf(RecProtocol));

  F.Open (Config.DataPath + 'protocol.dat', fmOpenCreate, fmReadWrite + fmDenyNone, SizeOf(RecProtocol));

  Box  := TAnsiMenuBox.Create;
  List := TAnsiMenuList.Create;

  Box.Header    := ' Protocol Editor ';
  List.NoWindow := True;
  List.LoChars  := #01#04#13#27;

  Box.Open (13, 5, 67, 20);

  WriteXY (15,  6, 112, 'Active   OSID     Batch   Key  Description');
  WriteXY (15,  7, 112, strRep('�', 51));
  WriteXY (15, 18, 112, strRep('�', 51));
  WriteXY (18, 19, 112, '(CTRL/A) Add   (CTRL/D) Delete   (ENTER) Edit');

  Repeat
    MakeList;

    List.Open (13, 7, 67, 18);
    List.Close;

    Case List.ExitCode of
      #04 : If List.Picked < List.ListMax Then
              If ShowMsgBox(1, 'Delete this entry?') Then Begin
                F.RecordDelete (List.Picked);
                MakeList;
              End;
      #01 : Begin
              F.RecordInsert (List.Picked);

              Prot.OSType    := OSType;
              Prot.Desc    := 'New protocol';
              Prot.Key     := '!';
              Prot.Active  := False;
              Prot.Batch   := False;
              Prot.SendCmd := '';
              Prot.RecvCmd := '';

              F.Write (Prot);

              MakeList;
            End;
      #13 : If List.Picked <> List.ListMax Then Begin
              F.Seek (List.Picked - 1);
              F.Read (Prot);

              EditProtocol(Prot);

              F.Seek  (List.Picked - 1);
              F.Write (Prot);
            End;
      #27 : Break;
    End;
  Until False;

  F.Close;
  F.Free;

  Box.Close;
  List.Free;
  Box.Free;
End;

End.