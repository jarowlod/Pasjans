unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, BCButton, BCLabel, TplGradientUnit, LSControls,
  orca_scene3d, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, Menus,
  BGRABitmap, BGRABitmapTypes, mmsystem, BCTypes, UFireworks;

type
  TPasjansStatus = (psTalia, psRozdane, psZdjete);
  TPasjansLvl = (lvlEasy, lvlNormal, lvlHard);

  THistoriaField = record
    Numer   : integer;
    isRewers: Boolean;
    Status  : TPasjansStatus;
    Kolumna : integer;
    Pozycja : integer;
  end;

  { THistoria }

  THistoria = class
    Lista: Array of THistoriaField;
  end;

  { TKartaImage }

  TKartaImage = class(TGraphicControl)
  private
    fBitmapKarta  : TBGRABitmap;
    fBitmapRewers : Pointer;
    FisRewers     : Boolean;
    FKolor        : integer;  // 1: czerwo, 2: dzwonek, 3: wino, 4: żoledz
    FKolumna      : integer;
    FNazwa        : string;
    FNominal      : integer; // 1-As, 2,3,4,5,6,7,8,9,10, 11-J, 12-D, 13-K
    FNumer        : integer;
    FPozycja      : integer;
    FStatus       : TPasjansStatus;
    procedure SetisRewers(AValue: Boolean);
    procedure SetKolor(AValue: integer);
    procedure SetKolumna(AValue: integer);
    procedure SetNazwa(AValue: string);
    procedure SetNominal(AValue: integer);
    procedure SetNumer(AValue: integer);
    procedure SetPozycja(AValue: integer);
    procedure SetStatus(AValue: TPasjansStatus);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Status: TPasjansStatus read FStatus write SetStatus default psTalia;
    property Nazwa: string read FNazwa write SetNazwa;
    property Kolor: integer read FKolor write SetKolor;
    property Nominal: integer read FNominal write SetNominal;
    property Numer: integer read FNumer write SetNumer;
    property isRewers: Boolean read FisRewers write SetisRewers default true;
    property Kolumna: integer read FKolumna write SetKolumna;
    property Pozycja: integer read FPozycja write SetPozycja;
  end;

  { TPasjans }

  TPasjans = class
    fOwner       : TComponent;
    fBitmapRewers: TBGRABitmap;
    fKarty       : array of TKartaImage;
    fKol_Pos     : array[1..10] of integer;
    fTalia_Pos   : TPoint;
    fListaKart   : TList;   // lista kart które są przenoszone
    fListaWTalii : TList;
    lblRuchy     : TBCLabel;
    fRuchy       : integer;
    lblTaliaStan : TBCLabel;
    lblTaliaTlo  : TBCLabel;
    fLvlGame     : TPasjansLvl;
    isGameActive : Boolean;

    procedure KartaMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure KartaMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure KartaMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    Height    : integer;
    Width     : integer;
    isPressed : Boolean;
    oldPos    : TPoint;
    Historia  : TList;
    fCienImage: TKartaImage;
    fCienWSP  : Single;
    fFireworks: TFireworks;

    function isTaliaWin: Boolean;                              // sprawdza czy karty wygraly i zabiera je
    function isPasjansWin: Boolean;                            // czy gra skonczona - wygrana
    function isLegalDown(Item1, Item2: TKartaImage): Boolean;  // czy można polozyc karte
    function isLegalUp: Boolean;                               // czy mozna uniesc karte
    function isKolorTaliOK(A,B: integer): Boolean;             // test zgodnosci koloru kart wzgledem levelu gry

    function NajblizszaKolumna(x: integer): integer;
    function isPustaKolumna: Boolean;
    function OdkryjOstatniaKarteKolumny(VKolumna, VPozycja: integer): integer; // numer karty
    procedure TaliaStanUpdate;
    procedure RuchyIncUpdate(isInc: Boolean);

    procedure ZapiszRuch;
    procedure DopiszRuch(Value: TKartaImage);
    procedure HistoriaClear;

    procedure CienON;
    procedure CienOFF;
    procedure CienMove;
  public
    constructor Create(Sender: TComponent; AlvlGame: TPasjansLvl);
    destructor Destroy; override;
    procedure BeginGame;
    procedure ChangeLevel(AlvlGame: TPasjansLvl);
    procedure WczytajKarty(filename: string);
    procedure ObliczKolumny;
    procedure TasowanieTalii;
    procedure RozdajKarty;
    procedure RozdajPoczatek;
    procedure SetSize(AWidth, AHeight: integer);
    procedure Cofnij;
    procedure Fireworks;   // efekty po wygranej
  end;

  { TForm1 }

  TForm1 = class(TForm)
    BCButton2: TBCButton;
    BCButton3: TBCButton;
    BCButton4: TBCButton;
    BCLabel1: TBCLabel;
    BCLabel2: TBCLabel;
    BCLabel3: TBCLabel;
    BCLabel4: TBCLabel;
    BCLabel6: TBCLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    plGradient1: TplGradient;
    PopupMenu1: TPopupMenu;
    Timer1: TTimer;
    procedure BCButton2Click(Sender: TObject);
    procedure BCButton3Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FlvlGame: TPasjansLvl;
    procedure SetlvlGame(AValue: TPasjansLvl);
  public
    Pasjans: TPasjans;
    CzasStart: TTime;
    property lvlGame: TPasjansLvl read FlvlGame write SetlvlGame default lvlNormal;
  end;

var
  Form1: TForm1;

const
  plik_tekstur = 'card-1274_760.png';
  // wielkosc karty
  karta_H = 152;
  karta_W = 98;

  liczba_kart_w_talii = 104; // liczba kart w talii potrzebnych do gry w pająka

implementation

{$R *.frm}


{ TKartaImage }

procedure TKartaImage.SetNazwa(AValue: string);
begin
  if FNazwa=AValue then Exit;
  FNazwa:=AValue;
end;

procedure TKartaImage.SetNominal(AValue: integer);
begin
  if FNominal=AValue then Exit;
  FNominal:=AValue;
end;

procedure TKartaImage.SetNumer(AValue: integer);
begin
  if FNumer=AValue then Exit;
  FNumer:=AValue;
end;

procedure TKartaImage.SetPozycja(AValue: integer);
begin
  if FPozycja=AValue then Exit;
  FPozycja:=AValue;
end;

procedure TKartaImage.SetStatus(AValue: TPasjansStatus);
begin
  if FStatus=AValue then Exit;
  FStatus:=AValue;

  Visible:= not (FStatus = psZdjete);
end;

procedure TKartaImage.Paint;
var img: TBGRABitmap;
begin
  if (csCreating in FControlState) then
    Exit;
  inherited Paint;

  img:= TBGRABitmap.Create(fBitmapKarta);

  if FisRewers then
       img.PutImage(0,0, TBGRABitmap(fBitmapRewers), dmDrawWithTransparency)
    else
       img.PutImage(0,0, fBitmapKarta, dmDrawWithTransparency);

  BGRAReplace(img, img.Resample(Width, Height));

  img.Draw(Canvas,0,0, false);
  img.Free;
end;

constructor TKartaImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Parent := TWinControl(AOwner);
  Left   := 10;
  Top    := 50;
  Width  := karta_W;
  Height := karta_H;
  fBitmapKarta:= TBGRABitmap.Create(karta_W, karta_H);

  Status   := psTalia;
  Kolumna  := 1;
  Pozycja  := 0;
end;

destructor TKartaImage.Destroy;
begin
  fBitmapKarta.Free;
  inherited Destroy;
end;

procedure TKartaImage.SetKolor(AValue: integer);
begin
  if FKolor=AValue then Exit;
  FKolor:=AValue;
end;

procedure TKartaImage.SetKolumna(AValue: integer);
begin
  if FKolumna=AValue then Exit;
  FKolumna:=AValue;
end;

procedure TKartaImage.SetisRewers(AValue: Boolean);
begin
  if FisRewers=AValue then Exit;
  FisRewers:=AValue;
end;

{ TPasjans }

function ComparePos(Item1, Item2: Pointer): integer;
begin
  Result:= TKartaImage(Item1).Pozycja - TKartaImage(Item2).Pozycja;
end;

procedure TPasjans.KartaMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var i: integer;
begin
  PlaySound(PChar('klik3.wav'), 0, SND_FILENAME or SND_ASYNC);
  //PlaySound('KLIK3', HINSTANCE, SND_RESOURCE or SND_ASYNC);

  if Button = mbLeft then
    if TKartaImage(Sender).Status = psTalia then  //if TKartaImage(Sender).isTalia then
      begin
        if not isPustaKolumna then RozdajKarty;
      end
    else
      if TKartaImage(Sender).isRewers then
      begin
        // nic nie robimy
      end
    else
      begin
        isPressed:= true;
        oldPos.x:= X;
        oldPos.y:= Y;

        fListaKart.Add( TKartaImage(Sender) );
        for i:=0 to Length(fKarty)-1 do
          if (fKarty[i].Status = psRozdane) and //if (not fKarty[i].isTalia) and
             (fKarty[i].Kolumna = TKartaImage(Sender).Kolumna) and
             (fKarty[i].Pozycja > TKartaImage(Sender).Pozycja) then fListaKart.Add( fKarty[i] );

        fListaKart.Sort( @ComparePos );

        if not isLegalUp() then
        begin
          isPressed:= false;
          fListaKart.Clear;
          exit;
        end;

        CienON;

        for i:=0 to fListaKart.Count-1 do TKartaImage(fListaKart.Items[i]).BringToFront;
      end;
end;

procedure TPasjans.KartaMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var i: integer;
    h: integer;
begin
  if isPressed then
  begin
    TKartaImage(Sender).Left := TKartaImage(Sender).Left + X - oldPos.x;
    TKartaImage(Sender).Top  := TKartaImage(Sender).Top + Y - oldPos.y;

    CienMove;

    h:= Round(TKartaImage(Sender).Height * 0.30);
    for i:=1 to fListaKart.Count-1 do
    begin
      TKartaImage(fListaKart.Items[i]).Left:= TKartaImage(Sender).Left;
      TKartaImage(fListaKart.Items[i]).Top:= TKartaImage(fListaKart.Items[i-1]).Top + h;
    end;
  end;
end;

procedure TPasjans.KartaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var kol, i, poz, iNr : integer;
    Legal: Boolean;
    old_kol, old_poz: integer;
    nr: integer;
begin
  if isPressed then
  begin
    CienOFF;

    Legal:= false;
    old_poz:= TKartaImage(Sender).Pozycja;
    old_kol:= TKartaImage(Sender).Kolumna;

    kol:= NajblizszaKolumna( TKartaImage(Sender).Left );
    if kol > 0 then
    begin
      // sprawdzamy jaki wiersz
      if kol <> TKartaImage(Sender).Kolumna then
      begin
        poz:=-1;
        iNr:=-1;
        for i:=0 to Length(fKarty)-1 do
          if (fKarty[i].Status =  psRozdane) and//if (not fKarty[i].isTalia) and
             (fKarty[i].Kolumna = kol) and
             (fKarty[i].Pozycja > poz) then
              begin
                poz:= fKarty[i].Pozycja;
                iNr:= i;
              end;

        Legal:= (iNr<0) or isLegalDown(TKartaImage(Sender), fKarty[iNr]);
        if Legal then
          begin
            ZapiszRuch;

            TKartaImage(Sender).Pozycja:= poz + 1;
            TKartaImage(Sender).Kolumna:= kol;
            TKartaImage(Sender).Left:= fKol_Pos[kol];
            TKartaImage(Sender).Top:= 50 + round(TKartaImage(Sender).Pozycja * TKartaImage(Sender).Height * 0.20);
          end;
      end;
    end;

    if not Legal then // jesli jest poza kolumna to wracamy do poczatku
    begin
      TKartaImage(Sender).Left:= fKol_Pos[ TKartaImage(Sender).Kolumna ];
      TKartaImage(Sender).Top:= 50 + TKartaImage(Sender).Pozycja * round( TKartaImage(Sender).Height * 0.20);
    end;

    for i:=1 to fListaKart.Count-1 do   // pozostale przenoszone karty ladoja w slad za kartą
    begin
      TKartaImage(fListaKart.Items[i]).Left:= TKartaImage(Sender).Left;
      TKartaImage(fListaKart.Items[i]).Top := TKartaImage(fListaKart.Items[i-1]).Top + round(TKartaImage(Sender).Height * 0.20);
      TKartaImage(fListaKart.Items[i]).Pozycja:= TKartaImage(fListaKart.Items[i-1]).Pozycja + 1;
      TKartaImage(fListaKart.Items[i]).Kolumna:= TKartaImage(fListaKart.Items[i-1]).Kolumna;
    end;

    if Legal then
      begin
        nr:= OdkryjOstatniaKarteKolumny(old_kol, old_poz);
        if nr>=0 then DopiszRuch(fKarty[nr]); // jesli odkryta to zapisz ta zamiane

        if isTaliaWin then HistoriaClear;  // sprawdza czy karty zostaly ulozone w kolejnosci i zdjete, jesli tak to czysci historie
        RuchyIncUpdate(True);
      end;

    fListaKart.Clear;
  end;
  isPressed:= false;
end;

function TPasjans.NajblizszaKolumna(x: integer): integer;
var i: integer;
    w: integer;
begin
  w:= fKarty[0].Width div 2;
  Result:=0;

  for i:=1 to Length(fKol_Pos) do
    if abs(x - fKol_Pos[i]) <= w then
    begin
      Result:= i;
      Exit;
    end;
end;

function TPasjans.isPustaKolumna: Boolean;
var i: integer;
    countPozZero: integer;
begin
  countPozZero:= 0;
  for i:=0 to Length(fKarty)-1 do
  begin
    if (fKarty[i].Status = psRozdane)and//if (not fKarty[i].isTalia)and
       (fKarty[i].Pozycja = 0) then inc(countPozZero);
  end;
  Result:= not (countPozZero = Length(fKol_Pos));
  if Result then MessageDlg('Karty można rozdać tylko na inne karty w kolumnie.', mtWarning, [mbOK],0);
end;

function TPasjans.OdkryjOstatniaKarteKolumny(VKolumna, VPozycja: integer): integer;
var i: integer;
begin
  Result:= -1;
  if VPozycja<=0 then exit;
  for i:=0 to Length(fKarty)-1 do
    if (fKarty[i].Status = psRozdane) and //if (not fKarty[i].isTalia) and
       (fKarty[i].isRewers) and
       (fKarty[i].Kolumna = VKolumna) and
       (fKarty[i].Pozycja = VPozycja-1) then
       begin
         fKarty[i].isRewers:= false;
         fKarty[i].Refresh;
         Result:= i;
         Break;
       end;
end;

procedure TPasjans.TaliaStanUpdate;
var stan: integer;
begin
  stan:= fListaWTalii.Count div 10;
  if stan > 0 then
      lblTaliaStan.Caption:= IntToStr(stan)
    else
      lblTaliaStan.Caption:='';
end;

procedure TPasjans.RuchyIncUpdate(isInc: Boolean);
begin
  if isInc then inc(fRuchy) else fRuchy:= 0;
  if lblRuchy<>nil then lblRuchy.Caption:= IntToStr(fRuchy);
end;

procedure TPasjans.CienON;
begin
  fCienImage.BringToFront;
  CienMove;
  fCienImage.Visible:= true;
end;

procedure TPasjans.CienOFF;
begin
  fCienImage.Visible:= false;
end;

procedure TPasjans.CienMove;
begin
  fCienImage.Canvas.Lock;
  fCienImage.Top:=    TKartaImage(fListaKart.Items[0]).Top -   round(37 * fCienWSP);
  fCienImage.Left:=   TKartaImage(fListaKart.Items[0]).Left -  round(36 * fCienWSP);
  fCienImage.Width:=  TKartaImage(fListaKart.Items[0]).Width + round(79 * fCienWSP);
  fCienImage.Height:= (TKartaImage(fListaKart.Items[fListaKart.Count-1]).Top - TKartaImage(fListaKart.Items[0]).Top) + TKartaImage(fListaKart.Items[0]).Height + round(82 * fCienWSP);
  fCienImage.Canvas.Unlock;
end;

constructor TPasjans.Create(Sender: TComponent; AlvlGame: TPasjansLvl);
var i: integer;
begin
  fOwner       := Sender;
  fLvlGame     := AlvlGame;
  fBitmapRewers:= TBGRABitmap.Create(karta_W, karta_H);
  fListaKart   := TList.Create;
  fListaWTalii := TList.Create;
  lblRuchy     := nil;
  lblTaliaTlo  := nil;
  isGameActive := true;

  fCienImage:= TKartaImage.Create(Sender);
  fCienImage.fBitmapKarta.LoadFromFile('cien.png');
  fCienImage.FisRewers:= false;
  fCienImage.Visible:= false;

  Historia:= TList.Create;

  lblTaliaStan:= TBCLabel.Create(Sender);
  lblTaliaStan.Parent:= TWinControl(Sender);
  lblTaliaStan.FontEx.FontQuality:= fqSystem;
  lblTaliaStan.FontEx.Shadow:= true;
  lblTaliaStan.FontEx.Color:= $00FFE6E6;
  lblTaliaStan.Caption:='1';

  SetLength( fKarty, liczba_kart_w_talii);
  for i:=0 to Length(fKarty)-1 do
  begin
    fKarty[i]:= TKartaImage.Create( Sender );
    fKarty[i].fBitmapRewers:= fBitmapRewers;

    fKarty[i].OnMouseDown:= @KartaMouseDown;
    fKarty[i].OnMouseMove:= @KartaMouseMove;
    fKarty[i].OnMouseUp  := @KartaMouseUp;
  end;

  WczytajKarty(plik_tekstur);

  SetSize(TWinControl( Sender ).Width, TWinControl( Sender ).Height);

  fTalia_Pos.x:= Width - fKarty[0].Width - 20;
  fTalia_Pos.y:= Height - fKarty[0].Height - 20;
end;

destructor TPasjans.Destroy;
var i: integer;
begin
  for i:=0 to Length(fKarty)-1 do fKarty[i].Free;
  fListaWTalii.Free;
  fListaKart.Free;
  fBitmapRewers.Free;
  lblTaliaStan.Free;
  fCienImage.Free;

  inherited Destroy;
end;

procedure TPasjans.BeginGame;
var i: integer;
begin
  for i:=0 to Length(fKarty)-1 do
    fKarty[i].Status:= psTalia;

  ObliczKolumny;
  TasowanieTalii;
  RozdajPoczatek;

  isGameActive:= true;
end;

procedure TPasjans.ChangeLevel(AlvlGame: TPasjansLvl);
begin
  if AlvlGame = fLvlGame then exit;
  fLvlGame:= AlvlGame;

  WczytajKarty(plik_tekstur); // w zaleznosci od poziomu gry wczytujemy talie kart jedno lub dwu kolorowe

  BeginGame;
end;

procedure TPasjans.WczytajKarty(filename: string);
var i,w,j,t: integer;
    srcRec: TRect;
    nr: integer;
    fBitmapKarty: TBGRABitmap;
begin
  fBitmapKarty := TBGRABitmap.Create;
  fBitmapKarty.LoadFromFile(filename);

  for t:=0 to 1 do  // dwie talie kart
  for j:=0 to 3 do // wiersze
    for i:=0 to 12 do // kolumny
      begin
        w:= j;
        if fLvlGame = lvlEasy then
              begin
                if j=1 then w:=0;
                if j=2 then w:=3;
              end;

        nr:= (t*52) + (j*13)+i;

        srcRec.Left:= i * karta_W;
        srcRec.Top := w * karta_H;
        srcRec.Right := srcRec.Left + karta_W;
        srcRec.Bottom:= srcRec.Top  + karta_H;

        fKarty[nr].Nazwa:= IntToStr(i+1);
        fKarty[nr].Nominal:= i+1;
        if i=0 then fKarty[nr].Nazwa:= 'As' else
        if i=10 then fKarty[nr].Nazwa:= 'J' else
        if i=11 then fKarty[nr].Nazwa:= 'D' else
        if i=12 then fKarty[nr].Nazwa:= 'K';

        fKarty[nr].Numer:= nr;
        fKarty[nr].Kolor:= w+1;

        //fKarty[nr].fBitmapKarta:= TBGRABitmap.Create(karta_W, karta_H);
        fBitmapKarty.DrawPart(srcRec, fKarty[nr].fBitmapKarta.Canvas, 0,0, true);
      end;

  //wczytaj rewers karty
  srcRec.Left:= 2 * karta_W;
  srcRec.Top := 4 * karta_H;
  srcRec.Right := srcRec.Left + karta_W;
  srcRec.Bottom:= srcRec.Top  + karta_H;
  fBitmapKarty.DrawPart(srcRec, fBitmapRewers.Canvas, 0,0, false);

  fBitmapKarty.Free;
end;

procedure TPasjans.ObliczKolumny;
var i: integer;
    w: integer;
    h, h_space: integer;
begin
  w:= (Width div 10) - 10;
  h:= Round(w * 1.54);
  h_space := Round(h * 0.20);
  fCienWSP:= w/ karta_W;

  fKol_Pos[1]:= 5;
  for i:=2 to Length(fKol_Pos) do
    fKol_Pos[i]:= fKol_Pos[i-1] + w + 10;

  fTalia_Pos.x:= Width - w - 20;
  fTalia_Pos.y:= Height - h - 20;

  for i:=0 to Length(fKarty)-1 do
  begin
    fKarty[i].Canvas.Lock;

    fKarty[i].Width := w;
    fKarty[i].Height:= h;

    if fKarty[i].Status = psTalia then  //if fKarty[i].isTalia then
      begin
        fKarty[i].Left:= fTalia_Pos.x;
        fKarty[i].Top := fTalia_Pos.y;
      end
    else
      begin   // pozycja kart rozdanych
        fKarty[i].Left:= fKol_Pos[ fKarty[i].Kolumna ];
        fKarty[i].Top := 50 + (fKarty[i].Pozycja * h_space);
      end;
    fKarty[i].Canvas.Unlock;
  end;

  // obliczam pozycje stanu talii
  lblTaliaStan.FontEx.Height:= h div 2;
  lblTaliaStan.Left:= fTalia_Pos.x - lblTaliaStan.Width;
  lblTaliaStan.Top := fTalia_Pos.y;

  if Assigned(lblTaliaTlo) then
    begin
      lblTaliaTlo.Left:= lblTaliaStan.Left - 10;
      lblTaliaTlo.Top := lblTaliaStan.Top  - 20;
      lblTaliaTlo.Width := (fTalia_Pos.x - lblTaliaTlo.Left) + w + 10;
      lblTaliaTlo.Height:= h + 30;
    end;
end;
                             // src   des
function TPasjans.isLegalDown(Item1, Item2: TKartaImage): Boolean;
begin
  Result:= (not Item2.isRewers) and (Item1.Nominal = Item2.Nominal-1);
end;

function TPasjans.isLegalUp: Boolean;
var i: integer;
begin
  Result:= true;
  if fListaKart.Count <= 1 then exit;

  for i:=1 to fListaKart.Count-1 do
  begin
    Result:= (isKolorTaliOK(TKartaImage(fListaKart.Items[i]).Kolor, TKartaImage(fListaKart.Items[i-1]).Kolor)) and
             (TKartaImage(fListaKart.Items[i]).Nominal = TKartaImage(fListaKart.Items[i-1]).Nominal-1);
    if not Result then exit;
  end;
end;

function TPasjans.isKolorTaliOK(A, B: integer): Boolean;
begin
  case fLvlGame of
    lvlEasy  : Result:= (A + B = 5) or (A = B);  // tylko jeden kolor kart w tali, wszystkie karty sa jednego koloru (wczytane na poczatku)
    lvlNormal: Result:= (A + B = 5) or (A = B);  // oba czerwone 1+4  lub oba czarne 2+3, or kolor zgodny
    lvlHard  : Result:= (A = B);                 // tylko kolor zgodny;
  end;
end;

procedure TPasjans.TasowanieTalii;
var i: integer;
    pomT: array of integer;
    ii: integer;
begin
  Randomize;
  fListaWTalii.Clear;
  SetLength(pomT, Length(fKarty));
  for i:=0 to Length(pomT)-1 do pomT[i]:= i;

  while Length(pomT)>0 do
  begin
    ii:= Random(Length(pomT));
    i:= pomT[ii];
    fKarty[i].Status:= psTalia;//fKarty[i].isTalia:= true;      // przy okazji ustawiamy wszystkie karty do talii
    fKarty[i].isRewers:= true;

    fListaWTalii.Add( fKarty[i]);
    pomT[ii]:= pomT[Length(pomT)-1];
    SetLength(pomT, Length(pomT)-1);
  end;
end;

procedure TPasjans.RozdajKarty;
var i,k: integer;
    poz: integer;
begin
  // rozdajemy z tali kart po jedenj na kolumnę
  if fListaWTalii.Count<=0 then exit;
  // dajemy 10 kart, po 1 na kolumnę
  for k:=1 to 10 do
  begin
    Sleep(80);
    PlaySound(PChar('klik3.wav'), 0, SND_FILENAME or SND_ASYNC);

    poz:= -1;
    for i:=0 to Length(fKarty)-1 do
          if (fKarty[i].Status = psRozdane) and//if (not fKarty[i].isTalia) and
             (fKarty[i].Kolumna = k) and
             (fKarty[i].Pozycja > poz) then
              begin
                poz:= fKarty[i].Pozycja;
              end;

    poz:= poz+1;
    i:= TKartaImage(fListaWTalii.Items[0]).Numer;
    fKarty[i].Pozycja  := poz;
    fKarty[i].Top      := 50 + round( poz * fKarty[i].Height * 0.20);
    fKarty[i].Left     := fKol_Pos[k];
    fKarty[i].isRewers := false;
    fKarty[i].Status:= psRozdane; //fKarty[i].isTalia  := false;
    fKarty[i].Kolumna  := k;
    fKarty[i].BringToFront;

    fKarty[i].Paint;

    fListaWTalii.Delete(0);
    if fListaWTalii.Count<=0 then Break;
  end;
  isTaliaWin;
  TaliaStanUpdate;
  HistoriaClear;
end;

procedure TPasjans.RozdajPoczatek;
var i,k: integer;
    poz: integer;
    licznik: integer;
begin
  // rozdajemy z tali kart rozdanie poczatkowe 54 karty
  if fListaWTalii.Count<=0 then exit;
  // dajemy 10 kart, po 1 na kolumnę
  RuchyIncUpdate(false);
  licznik:=0;
  while licznik<54 do
  begin
    for k:=1 to 10 do
    begin
      inc(licznik);

      poz:= -1;
      for i:=0 to Length(fKarty)-1 do
            if (fKarty[i].Status = psRozdane) and //if (not fKarty[i].isTalia) and
               (fKarty[i].Kolumna = k) and
               (fKarty[i].Pozycja > poz) then
                begin
                  poz:= fKarty[i].Pozycja;
                end;

      poz:= poz+1;
      i:= TKartaImage(fListaWTalii.Items[0]).Numer;
      fKarty[i].Pozycja  := poz;
      fKarty[i].Top      := 50 + round( poz * fKarty[i].Height * 0.20);
      fKarty[i].Left     := fKol_Pos[k];
      fKarty[i].isRewers := (licznik<45);
      fKarty[i].Status:= psRozdane; //fKarty[i].isTalia  := false;
      fKarty[i].Kolumna  := k;
      fKarty[i].BringToFront;

      fListaWTalii.Delete(0);
      if fListaWTalii.Count<=0 then break;
      if licznik>=54 then break;
    end;
    if fListaWTalii.Count<=0 then break;
  end;
  TaliaStanUpdate;
  HistoriaClear;
end;

function TPasjans.isTaliaWin: Boolean;
var i,t,j: integer;
    nr: integer;
    poz, kol: integer;
    win: Boolean;
    ListaWin, ListaPom: TList;
begin
  ListaWin:= TList.Create;
  ListaPom:= TList.Create;

  for t:=0 to 7 do // 8 - posortowanych kolorów kart
  begin
    nr:= t*13; // 13 kart w kolorze, wyliczmy index kolejnych Asów
    poz:= fKarty[nr].Pozycja;
    kol:= fKarty[nr].Kolumna;

    if (fKarty[nr].Status = psRozdane) and
       (not fKarty[nr].isRewers) and
       (poz >= 12)  // większa szansa na pozytywny test gdy pozycja wskazuje na co najmniej 12 kart na stosie
       then
          begin
            ListaPom.Add(fKarty[nr]);
            for j:=0 to 11 do
            begin
              win:= false;
              for i:=0 to Length(fKarty)-1 do
                if (fKarty[i].Status = psRozdane) and
                   (not fKarty[i].isRewers) and
                   (fKarty[i].Kolumna = kol) and
                   (fKarty[i].Pozycja = fKarty[nr].Pozycja-1) and
                   (fKarty[i].Nominal = fKarty[nr].Nominal+1) and
                   (isKolorTaliOK(fKarty[i].Kolor, fKarty[nr].Kolor))
                   then
                     begin
                       nr:=i;
                       ListaPom.Add(fKarty[nr]);
                       win:= true;
                       break;
                     end;

              if not win then
                begin
                  ListaPom.Clear;
                  break;
                end;
          end;

        if ListaPom.Count>0 then ListaWin.AddList(ListaPom);
      end;
  end;

  // wygrane karty zabieramy z widoku
  for i:=0 to ListaWin.Count-1 do
  begin
    TKartaImage(ListaWin.Items[i]).Status  := psZdjete; //TKartaImage(ListaWin.Items[i]).isTalia:= true;
    TKartaImage(ListaWin.Items[i]).Visible := false;
    TKartaImage(ListaWin.Items[i]).isRewers:= true;
  end;

  Result:= (ListaWin.Count>0);
  // jesli bylo wiecej stosow kart do zdjecia to sprawdzamy pozostale karty na widoku po zdjetych stosach
  i:= 12;
  while ListaWin.Count>= i do
  begin
    OdkryjOstatniaKarteKolumny( TKartaImage(ListaWin.Items[i]).Kolumna, TKartaImage(ListaWin.Items[i]).Pozycja );
    i+= 12;
  end;

  if Result then isPasjansWin();

  ListaWin.Free;
  ListaPom.Free;
end;

function TPasjans.isPasjansWin: Boolean;
var i: integer;
begin
  Result:= true;
  for i:=0 to Length(fKarty)-1 do
  begin
    if fKarty[i].Status <> psZdjete then
      begin
        Result:= False;
        Break;
      end;
  end;
  isGameActive:= not Result;

  if isGameActive then exit;
  // ========= EFEKTY WYGRANA
  Fireworks;
end;

procedure TPasjans.SetSize(AWidth, AHeight: integer);
begin
  Width:=  AWidth;
  Height:= AHeight;

  ObliczKolumny;
end;

procedure TPasjans.ZapiszRuch;
var hst: THistoria;
    i: integer;
begin
  if fListaKart.Count=0 then exit;
  hst:= THistoria.Create;
  SetLength(hst.Lista, fListaKart.Count);

  for i:=0 to Length(hst.Lista)-1 do
  begin
    hst.Lista[i].Numer   := TKartaImage( fListaKart.Items[i]).Numer;
    hst.Lista[i].Kolumna := TKartaImage( fListaKart.Items[i]).Kolumna;
    hst.Lista[i].Pozycja := TKartaImage( fListaKart.Items[i]).Pozycja;
    hst.Lista[i].isRewers:= TKartaImage( fListaKart.Items[i]).isRewers;
    hst.Lista[i].Status  := TKartaImage( fListaKart.Items[i]).Status;
  end;

  Historia.Add(hst);
end;

procedure TPasjans.DopiszRuch(Value: TKartaImage);
var hst: THistoria;
    i: integer;
begin
  if Historia.Count=0 then exit;
  hst:= THistoria( Historia.Items[Historia.Count-1]);
  SetLength(hst.Lista, Length(hst.Lista)+1 );

  for i:=Length(hst.Lista)-1 downto 1 do
  begin
    hst.Lista[i].Numer   := hst.Lista[i-1].Numer;
    hst.Lista[i].Kolumna := hst.Lista[i-1].Kolumna;
    hst.Lista[i].Pozycja := hst.Lista[i-1].Pozycja;
    hst.Lista[i].isRewers:= hst.Lista[i-1].isRewers;
    hst.Lista[i].Status  := hst.Lista[i-1].Status;
  end;

  hst.Lista[0].Numer   := Value.Numer;
  hst.Lista[0].Kolumna := Value.Kolumna;
  hst.Lista[0].Pozycja := Value.Pozycja;
  hst.Lista[0].isRewers:= true;   // bo zostala juz zmieniona wiec powinno byc true
  hst.Lista[0].Status  := Value.Status;
end;

procedure TPasjans.HistoriaClear;
var hst: THistoria;
    i: integer;
begin
  if Historia.Count=0 then exit;
  for i:=0 to Historia.Count-1 do
  begin
    hst:= THistoria( Historia.Items[i]);
    hst.Free;
  end;
  Historia.Clear;
end;

procedure TPasjans.Cofnij;
var hst: THistoria;
    i: integer;
    nr: integer;
begin
  if Historia.Count=0 then exit;
  hst:= THistoria( Historia.Items[Historia.Count-1]);

  for i:=0 to Length(hst.Lista )-1 do
  begin
    nr:= hst.Lista[i].Numer;
    fKarty[nr].Kolumna := hst.Lista[i].Kolumna;
    fKarty[nr].Pozycja := hst.Lista[i].Pozycja;
    fKarty[nr].isRewers:= hst.Lista[i].isRewers;
    fKarty[nr].Status  := hst.Lista[i].Status;
    fKarty[nr].BringToFront;
  end;

  Historia.Delete(Historia.Count-1);
  hst.Free;
  ObliczKolumny;
  fKarty[0].Parent.Refresh;
end;

procedure TPasjans.Fireworks;
var bmp: TBGRABitmap;
    isFirework: Integer;
    canvas: TCanvas;
begin
  lblTaliaStan.Caption:= 'WYGRANA';
  lblTaliaStan.Left:= (Width - lblTaliaStan.Width) div 2;
  lblTaliaStan.Top:= (Height - lblTaliaStan.Height) div 2;

  fFireworks:= TFireworks.Create(Width, Height);
  isFirework:= 0;
  //bmp:= TBGRABitmap.Create(Width, Height);
  canvas:= TForm(fOwner).Canvas;
  while isFirework<1000 do
  begin
    bmp:= TBGRABitmap.Create(Width, Height, clBlack);
    inc(isFirework);
    fFireworks.Draw(bmp);

    bmp.Draw( canvas, 0,0, false);
    Application.ProcessMessages;
    FreeAndNil(bmp);
  end;
  TForm(fOwner).Repaint;
end;

{ TForm1 }

procedure TForm1.BCButton2Click(Sender: TObject);
begin
  if Pasjans <> nil then FreeAndNil(Pasjans);

  Pasjans:= TPasjans.Create( Self, lvlGame );
  Pasjans.lblRuchy   := BCLabel4;
  Pasjans.lblTaliaTlo:= BCLabel6;
  Pasjans.BeginGame;

  CzasStart:= Time();
  Timer1.Enabled:= true;
end;

procedure TForm1.BCButton3Click(Sender: TObject);
begin
  if Pasjans<>nil then Pasjans.Cofnij;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  if Pasjans <> nil then Pasjans.SetSize(Width, Height);
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  if Assigned(Pasjans) then
    Pasjans.ChangeLevel(lvlEasy);

  lvlGame:= lvlEasy;
end;

procedure TForm1.MenuItem2Click(Sender: TObject);
begin
  if Assigned(Pasjans) then
    Pasjans.ChangeLevel(lvlNormal);

  lvlGame:= lvlNormal;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  if Assigned(Pasjans) then
    Pasjans.ChangeLevel(lvlHard);

  lvlGame:= lvlHard;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  BCLabel2.Caption:= TimeToStr(Time - CzasStart);
end;

procedure TForm1.SetlvlGame(AValue: TPasjansLvl);
begin
  if FlvlGame=AValue then Exit;
  FlvlGame:=AValue;
end;

end.

