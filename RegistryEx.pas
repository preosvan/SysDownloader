unit RegistryEx;

interface

uses
  System.Win.Registry, System.Classes;

type
  TRegistryEx = class(TRegistry)
  public
    procedure WriteMultiString(const AName: string; const AValue: TStringList);
  end;

implementation

uses
  Winapi.Windows, System.SysUtils;

{ TRegistriEx }

procedure TRegistryEx.WriteMultiString(const AName: string; const AValue: TStringList);
var
  Buffer: Pointer;
  BufSize: DWORD;
  I, J, K: Integer;
  S: string;
  P: PChar;
begin
  BufSize := 0;
  for I := 0 to AValue.Count - 1 do
    inc(BufSize, (Length(AValue[I]) + 1)*2);  //*2
  Inc(BufSize);
  GetMem(Buffer, BufSize);
  K := 0;
  P := Buffer;
  for I := 0 to AValue.Count - 1 do
  begin
    S := AValue[I];
    for J := 0 to Length(S) - 1 do
    begin
      P[K] := S[J + 1];
      Inc(K);
    end;
    P[K] := chr(0);
    Inc(K);
  end;
  P[K] := chr(0);

  if RegSetValueEx(CurrentKey, PChar(AName), 0, REG_MULTI_SZ, Buffer,
    BufSize) <> ERROR_SUCCESS then
    raise Exception.Create('Error RegistryExt Write Param ' + AName);
end;

end.
