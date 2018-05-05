unit CastleGIS;

{$mode objfpc}{$H+}

interface

uses
  CastleImages, CastleVectors, CastleGLImages,
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
    procedure ParseLatitude(const aData: string);
    procedure ParseLongtitude(const aData: string);
    procedure ParseDepth(const aData: string);
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
    //procedure ParseTime(const aData: string);
  public
    FTime: TDateTime;
    FEnergy: extended; {in Joules}
//    property Time: TDateTime read FTime;
    function isTime(const aTime: TDateTime): boolean;
    function isWithinTime(const aTime1, aTime2: TDateTime): boolean;
  end;

type
  TReferencePointType = (rpBottomLeft, rpTopRight);

type
  TWGS84Rectangle = class(TObject)
  public
    { Link between coordinates and WGS84 geographical coordinates
      [rpBottomLeft] should be Bottom-Left coordinate of the image and
      [rpTopRight] should be Top-Right coordinate of the image
      Otherwise the image will be drawn inversed }
    ReferencePointImage: array [TReferencePointType] of TVector2Integer;
    ReferencePointWGS84: array [TReferencePointType] of TVector2;
    function ImageWidth: integer;
    function ImageHeight: integer;
    function GeoWidth: single;
    function GeoHeight: single;

    function LongtitudeToX(const aLongtitude: single): integer;
    function LatitudeToY(const aLatitude: single): integer;
    function LngLatToXY(const aLngLat: TVector2): TVector2Integer;

    function XToLongtitude(const aX: integer): single;
    function YToLatitude(const aY: integer): single;
    function XYToLngLat(const aXY: TVector2Integer): TVector2;
  end;

type
  TBaseMap = class(TWGS84Rectangle)
  strict private
    MapImage: TGLImage;
  public
    { Draw the Base map scaled against TWGS84Rectangle
      Both BaseMap and Container must be correctly geo-aligned }
    procedure Draw(Container: TWGS84Rectangle);
  public
    constructor Create(const aURL: string);
    destructor Destroy; override;
  end;

type
  TGeoList = specialize TObjectList<TGeoObject>;
  TTimedList = specialize TObjectList<TTimedObject>;


implementation
uses
  SysUtils;

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

procedure TGeoObject.ParseLatitude(const aData: string);
begin
  FLatitude := aData.ToExtended;
end;

procedure TGeoObject.ParseLongtitude(const aData: string);
begin
  FLongtitude := aData.ToExtended;
end;

procedure TGeoObject.ParseDepth(const aData: string);
begin
  if aData <> '' then
    FDepth := aData.ToExtended
  else
    FDepth := 0;
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

{=============== TBaseMap =========================}

function TWGS84Rectangle.ImageWidth: integer;
begin
  Result := ReferencePointImage[rpTopRight][0] - ReferencePointImage[rpBottomLeft][0];
end;

function TWGS84Rectangle.ImageHeight: integer;
begin
  Result := ReferencePointImage[rpTopRight][1] - ReferencePointImage[rpBottomLeft][1];
end;

function TWGS84Rectangle.GeoWidth: single;
begin
  Result := ReferencePointWGS84[rpTopRight][0] - ReferencePointWGS84[rpBottomLeft][0];
end;

function TWGS84Rectangle.GeoHeight: single;
begin
  Result := ReferencePointWGS84[rpTopRight][1] - ReferencePointWGS84[rpBottomLeft][1];
end;

function TWGS84Rectangle.LongtitudeToX(const aLongtitude: single): integer;
begin
  Result := ReferencePointImage[rpBottomLeft][0] +
    Round((aLongtitude - ReferencePointWGS84[rpBottomLeft][0]) * ImageWidth / GeoWidth);
end;

function TWGS84Rectangle.LatitudeToY(const aLatitude: single): integer;
begin
  Result := ReferencePointImage[rpBottomLeft][1] +
    Round((aLatitude - ReferencePointWGS84[rpBottomLeft][1]) * ImageHeight / GeoHeight);
end;

function TWGS84Rectangle.LngLatToXY(const aLngLat: TVector2): TVector2Integer;
begin
  Result := Vector2Integer(LongtitudeToX(aLngLat[0]), LatitudeToY(aLngLat[1]));
end;

function TWGS84Rectangle.XToLongtitude(const aX: integer): single;
begin
  Result := ReferencePointWGS84[rpBottomLeft][0] +
    ((aX - ReferencePointImage[rpBottomLeft][0]) * GeoWidth / ImageWidth );
end;

function TWGS84Rectangle.YToLatitude(const aY: integer): single;
begin
  Result := ReferencePointWGS84[rpBottomLeft][1] +
    ((aY - ReferencePointImage[rpBottomLeft][1]) * GeoHeight / ImageHeight );
end;

function TWGS84Rectangle.XYToLngLat(const aXY: TVector2Integer): TVector2;
begin
  Result := Vector2(XToLongtitude(aXY[0]), YToLatitude(aXY[1]));
end;




constructor TBaseMap.Create(const aURL: string);
begin
  MapImage := TGLImage.Create(aURL, true);
end;

destructor TBaseMap.Destroy;
begin
  FreeAndNil(MapImage);
  inherited Destroy;
end;

procedure TBaseMap.Draw(Container: TWGS84Rectangle);
//var
begin
{  ReferencePointImage: array [TReferencePointType] of TVector2Integer;
  ReferencePointWGS84: array [TReferencePointType] of TVector2;}
  {(const X, Y, DrawWidth, DrawHeight: Single;
      const ImageX, ImageY, ImageWidth, ImageHeight: Single);}
  MapImage.Draw(Container.ReferencePointImage[rpBottomLeft][0],
    Container.ReferencePointImage[rpBottomLeft][1],
    Container.ImageWidth, Container.ImageHeight);
end;

end.

