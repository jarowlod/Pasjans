unit UFireworks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, BGRABitmap, BGRABitmapTypes, math;

type
//=============================================================

  { TParticle }

  TParticle = class
    pos        : TPointF;
    acc        : TPointF;
    vel        : TPointF;

    isFirework : Boolean;
    lifespan   : integer;
    dec_lifespan: integer;
    hu         : integer;
  public
    constructor Create(x,y: single; v_hu: integer; v_isFirework: boolean);
    procedure applyForce(force: TPointF);
    procedure update;
    function done: Boolean;
    procedure Show(canvas: TBGRABitmap);
  end;


  { TFirework }

  TFirework = class
    Owner: TObject;
    hu: integer;
    firework: TParticle;
    exploded: Boolean;
    particles: array of TParticle;
  public
    constructor Create(sender: TObject; width, height: integer);
    function done: Boolean;
    procedure Update;
    procedure Explode;
    procedure Show(canvas: TBGRABitmap);
  end;

  { TFireworks }

  TFireworks = class
    gravity   : TPointF;
    fireworks : array of TFirework;
    width     : integer;
    height    : integer;
  public
    constructor Create(v_width, v_height: integer);
    procedure Draw(canvas: TBGRABitmap);
  end;


implementation

{ TFireworks }

  constructor TFireworks.Create(v_width, v_height: integer);
  begin
    gravity.x:= 0;
    gravity.y:= 0.2;

    width:= v_width;
    height:= v_height;
  end;

  procedure TFireworks.Draw(canvas: TBGRABitmap);
  var i: integer;
  begin
    if random(100) < 3 then
    begin
      SetLength(fireworks, Length(fireworks)+1);
      fireworks[Length(fireworks)-1]:= TFirework.Create(self, width, height);
    end;

    for i:=Length(fireworks)-1 downto 0 do
      begin
        fireworks[i].Update;
        fireworks[i].Show(canvas);

        if fireworks[i].done then
          begin
            fireworks[i].Free;

            if i < Length(fireworks)-1 then
               fireworks[i]:= fireworks[Length(fireworks)-1];

            SetLength(fireworks, Length(fireworks)-1);
          end;
      end;
  end;

  { TFirework }

  constructor TFirework.Create(sender: TObject; width, height: integer);
  begin
    Owner:= sender;
    hu:= random(65535);
    firework:= TParticle.Create(random(width), height, hu, true);
    exploded:= false;
    SetLength(particles, 0);
  end;

  function TFirework.done: Boolean;
  begin
    if (exploded) and (Length(particles) = 0) then
      Result:= true
    else
      Result:= false;
  end;

  procedure TFirework.Update;
  var i: integer;
  begin
    if not exploded then
      begin
        firework.applyForce( TFireworks(Owner).gravity );
        firework.update();

        if firework.vel.y >= 0 then
          begin
            exploded:= true;
            Explode();
          end;
      end;

    for i:= Length(particles)-1 downto 0  do
      begin
        particles[i].applyForce( TFireworks(Owner).gravity );
        particles[i].update();

        if particles[i].done() then
          begin
            particles[i].Free;

            if i < Length(particles)-1 then
               particles[i]:= particles[Length(particles)-1];

            SetLength(particles, Length(particles)-1);
          end;
      end;

  end;

  procedure TFirework.Explode;
  var i: integer;
      max_p: integer;
  begin
    max_p:= RandomRange(100, 300);
    SetLength(particles, max_p);

    for i:=0  to max_p-1 do
      begin
        particles[i]:= TParticle.Create(firework.pos.x, firework.pos.y, hu, false);
      end;
  end;

  procedure TFirework.Show(canvas: TBGRABitmap);
  var i: integer;
  begin
    if not exploded then
      firework.Show(canvas);

    for i:=0 to Length(particles)-1 do
      particles[i].Show(canvas);
  end;

  { TParticle }

  constructor TParticle.Create(x, y: single; v_hu: integer; v_isFirework: boolean);
  var range: integer;
  begin
    pos.x:= x;
    pos.y:= y;
    hu:= v_hu;
    isFirework:= v_isFirework;
    lifespan:= 255;                  // Opacity - wygaszanie widoczności
    dec_lifespan:= RandomRange(2,5); // org 4   - co ile ma wygaszać
    acc.SetLocation(0,0);

    if isFirework then
      begin
        vel.x:= RandomRange(-3,3);    // kierunek wystrzałów
        vel.y:= RandomRange(-18, -8); // siła strzału
      end
    else
      begin
        range:= RandomRange(4, 20);
        vel.x:= RandomRange(-100, 100)/ 100;
        vel.y:= RandomRange(-100, 100)/ 100;
        vel:= vel.Scale(range);
      end;
  end;

  procedure TParticle.applyForce(force: TPointF);
  begin
    acc:= acc.Add(force);
  end;

  procedure TParticle.update;
  begin
    if not isFirework then
      begin
        vel:= vel.Scale(0.93);  // rozproszenie
        lifespan -= dec_lifespan;
      end;

    vel:= vel.Add(acc);
    pos:= pos.Add(vel);
    acc:= acc.Scale(0);
  end;

  function TParticle.done: Boolean;
  begin
    if lifespan < 0 then
      Result:= true
    else
      Result:= false;
  end;

  procedure TParticle.Show(canvas: TBGRABitmap);
  var posR: TPoint;
      s: integer;
  begin
    canvas.CanvasBGRA.Brush.Style:= bsSolid;
    canvas.CanvasBGRA.Pen.Style:= psClear;
    posR:= pos.Round;
    s:= RandomRange(1,4);

    if not isFirework then
      begin  // rozbłyski
        canvas.CanvasBGRA.Brush.BGRAColor.FromHSLAPixel(HSLA(hu, 65535, random(65535))); //65535, 32768));
        canvas.CanvasBGRA.Brush.Opacity:= lifespan;

        canvas.CanvasBGRA.Pen.Style:= psSolid;
        canvas.CanvasBGRA.Pen.Width:= 1;
        canvas.CanvasBGRA.Pen.BGRAColor.FromHSLAPixel(HSLA(hu, 65535, random(65535)));
        canvas.CanvasBGRA.Pen.Opacity:= lifespan;

        canvas.CanvasBGRA.MoveTo(posR.x-s-1, posR.y-s-1);
        canvas.CanvasBGRA.LineTo(posR.x+s, posR.y+s);
        canvas.CanvasBGRA.MoveTo(posR.x+s-1, posR.y-s-1);
        canvas.CanvasBGRA.LineTo(posR.x-s-2, posR.y+s);
        canvas.CanvasBGRA.Pen.Style:= psClear;


        canvas.CanvasBGRA.EllipseC(posR.x, posR.y, s, s);
      end
    else
      begin // rakieta
        canvas.CanvasBGRA.Brush.BGRAColor.FromHSLAPixel(HSLA(hu, 65535, 32768));
        canvas.CanvasBGRA.Brush.Opacity:= lifespan;

        canvas.CanvasBGRA.EllipseC(posR.x, posR.y, 3, 3);
        // dodatkowy cien po rakiecie
        for s:=1 to 5 do
          begin
            canvas.CanvasBGRA.Brush.Opacity:= 200 div s;
            posR:= posR.Subtract(vel.Round);
            canvas.CanvasBGRA.EllipseC(posR.x, posR.y, 3, 3);
          end;
      end;
  end;

end.
