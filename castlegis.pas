(* geo-located objects *)
unit CastleGIS;

{$INCLUDE compilerconfig.inc}

interface

uses
  Generics.Collections;

type
  TGeoObject = class(TObject)
  strict protected
    Latitude_to_km_ratio, Longtitude_to_km_ratio: extended;

    { returns distance in km to lng,lat point }
    function AccurateDistance(aLongtitude, aLatitude: extended): extended;
  public
    FDepth, FLatitude, FLongtitude: extended;
    FHorizontalError, FDepthError: extended;
    procedure CacheLongtitudeLatitude;
  public
    function isWithinLatitude(const aValue1, aValue2: extended): boolean;
    function isWithinLongtitude(const aValue1, aValue2: extended): boolean;
    function isWithinDepth(const aValue1, aValue2: extended): boolean;
    function Distance(aLongtitude, aLatitude: extended): extended;
    function Distance(const aObj: TGeoObject): extended;
  end;

type
  TTimedObject = class(TGeoObject)
  strict protected
    const FTimeError = 30/60/60/24; {30 seconds}
  public
    FTime: TDateTime;
    FEnergy: extended; {in Joules}
//    property Time: TDateTime read FTime;
    function isTime(const aTime: TDateTime): boolean;
    function isWithinTime(const aTime1, aTime2: TDateTime): boolean;
  end;

type
  TGeoList = specialize TObjectList<TGeoObject>;
  TTimedList = specialize TObjectList<TTimedObject>;


implementation

{------------------- Time ------------------------------------}

function TTimedObject.isTime(const aTime: TDateTime): boolean;
begin
  if (FTime + FTimeError >= aTime) and (FTime - FTimeError <= aTime) then
    Result := True
  else
    Result := False;
end;

function TTimedObject.isWithinTime(const aTime1, aTime2: TDateTime): boolean;
begin
  if aTime2 > aTime1 then
  begin
    if (FTime + FTimeError >= aTime1) and (FTime - FTimeError <= aTime2) then
      Result := True
    else
      Result := False;
  end
  else
  begin
    if (FTime + FTimeError >= aTime2) and (FTime - FTimeError <= aTime1) then
      Result := False
    else
      Result := True;
  end;
end;

function TGeoObject.isWithinDepth(const aValue1, aValue2: extended): boolean;
begin
  if aValue2 > aValue1 then
  begin
    if (FDepth + FDepthError >= aValue1) and (FDepth - FDepthError <= aValue2) then
      Result := True
    else
      Result := False;
  end
  else
  begin
    if (FDepth + FDepthError >= aValue2) and (FDepth - FDepthError <= aValue1) then
      Result := True
    else
      Result := False;
  end;
end;

function TGeoObject.isWithinLatitude(const aValue1, aValue2: extended): boolean;
begin
  if aValue2 > aValue1 then
  begin
    if (FLatitude + FHorizontalError/Latitude_to_km_ratio >= aValue1) and (FLatitude - FHorizontalError/Latitude_to_km_ratio <= aValue2) then
      Result := True
    else
      Result := False;
  end
  else
  begin
    if (FLatitude + FHorizontalError/Latitude_to_km_ratio >= aValue2) and (FLatitude - FHorizontalError/Latitude_to_km_ratio <= aValue1) then
      Result := True
    else
      Result := False;
  end;
end;

function TGeoObject.isWithinLongtitude(const aValue1, aValue2: extended): boolean;
begin
  if aValue2 > aValue1 then
  begin
    if (FLongtitude + FHorizontalError/Latitude_to_km_ratio >= aValue1) and (FLongtitude - FHorizontalError/Latitude_to_km_ratio <= aValue2) then
      Result := True
    else
      Result := False;
  end
  else
  begin
    if (FLongtitude + FHorizontalError/Latitude_to_km_ratio >= aValue2) and (FLongtitude - FHorizontalError/Latitude_to_km_ratio <= aValue1) then
      Result := True
    else
      Result := False;
  end;
end;

{------------------- Geo ------------------------------------}

function TGeoObject.Distance(aLongtitude, aLatitude: extended): extended;
var
  LngDiff: extended;
begin
  LngDiff := aLongtitude - Self.FLongtitude;
  if LngDiff > 180 then
    LngDiff -= 360
  else
    if LngDiff < -180 then
      LngDiff += 360;
  Result := sqr((aLatitude - Self.FLatitude) * Latitude_to_km_ratio)  +
    sqr((LngDiff) * Longtitude_to_km_ratio);
  if True {Result < %n^2} then
    Result := sqrt(Result)
  else
    Result := AccurateDistance(aLongtitude, aLatitude);
end;

function TGeoObject.Distance(const aObj: TGeoObject): extended;
begin
  Result := Self.Distance(aObj.FLongtitude, aObj.FLatitude);
end;

function TGeoObject.AccurateDistance(aLongtitude, aLatitude: extended): extended;
begin
  {$WARNING todo}
  Result := 0;
end;

{--------------------- CACHING ------------------------------------}

procedure TGeoObject.CacheLongtitudeLatitude;
{formulae from Wikipedia}
const
  LatCoef0 = 111132.92;
  LatCoef2 = -559.82;
  LatCoef4 = 1.175;
  LatCoef6 = -0.0023;

  LngCoef1 = 111412.84;
  LngCoef3 = 93.5;
  LngCoef5 = 0.118;
begin
  Latitude_to_km_ratio := ((LatCoef0 + LatCoef2 * cos(2 * FLatitude/180) +
    LatCoef4 * cos(4 * FLatitude/180) + LatCoef6 * cos(6 * FLatitude/180)))/1000;
  Longtitude_to_km_ratio := ((LngCoef1 * cos(1 * FLatitude/180) +
    LngCoef3 * cos(3 * FLatitude/180) + LngCoef5 * cos(5 * FLatitude/180)))/1000;
end;





end.

