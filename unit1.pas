unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, MaskEdit, Buttons, LCLType;

const
  MaxFiles = 999; // Максимальное количество файлов для обработки
  MaxBS = 999; // Максимальное число БС
  MaxTOTypes = 9;
  MaxTOStrings = 33;
  MaxFotoTypes = 153; // 152 строки типов фотографий
  sDelim='_';
  FileSuffix='.jpg';
type

  TMyPic = record
    sName: String; // Имя файла
    sNewName: String;
    iTOType: Integer; // Тип ТО, -1 - если нет типа
    iNumType: Integer; // Тип фото, -1 если нет
  end;

  { TCollectMyPic }
{$M+}
  TCollectMyPic = object
      //published
      constructor Init;
      Function GetName:String; // полное имя фото
      Function GetAlreadyProcCount:Integer; // Количество обработанных фото
      Function GetDir:String;
      Procedure SetDir(sNameDir:String);// Смена каталога со сбросом параметров
      Procedure SetTO(iTO:Integer);
      Procedure SetNum(iNum:Integer);
      Function GetTO:Integer;
      Function GetNum:Integer;
      Function GetMaxNum:Integer; // Всего фото
      Procedure PrevFoto;
      Procedure NextFoto;
      Procedure ClearVars; // Сброс переменных

      public
      //private
        sPathDir : String; // Каталог обработки
        iCurIndex : Integer; // Текущая обр. фото
        iFilesCount : Integer; // Количество фото в каталоге
        AllPic: Array [1..MaxFiles] of TMyPic;


  end;


  { TForm1 }

  TForm1 = class(TForm)


    BitBtn1: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ListBox1: TListBox;
    MaskEdit1: TMaskEdit;
    RadioGroup1: TRadioGroup;
    SelectDirectoryDialog1: TSelectDirectoryDialog;

    procedure BitBtn1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure MaskEdit1Change(Sender: TObject);
    procedure RadioGroup1SelectionChanged(Sender: TObject);
    procedure RedrawStat;
    procedure StoreFoto;
  private
    MyAllPic:TCollectMyPic;
    AllBS: Array [1..MaxBS] of String[100];
  public

  end;


var
  Form1: TForm1;

implementation

type
  TTOTypeRec = record
    cCode: Char;
    sTONum: String[12];
  end;
  TTOTypeArray = Array [1..MaxTOTypes] of TTOTypeRec;

const
  TOTypesNames : TTOTypeArray =
    ((cCode:'1'; sTONum:'АМС'),
     (cCode:'2'; sTONum:'КТП'),
     (cCode:'3'; sTONum:'ЛЭИ'),
     (cCode:'4'; sTONum:'КТО'),
     (cCode:'5'; sTONum:'СКВ'),
     (cCode:'6'; sTONum:'ПСКВ'),
     (cCode:'7'; sTONum:'АУГПТ'),
     (cCode:'8'; sTONum:'ДГУ'),
     (cCode:'9'; sTONum:'НРП'));

  FotoTypeStrings : Array[1..MaxFotoTypes] of String[80] =
    ('0 Выберите тип ТО',
    '1.1_Общий вид АМС', '1.2_Общий вид здания с АМС',
    '1.3_Секций АМС', '1.4_Общий вид территории', '1.5_Места прохода к АМС',
    '1.6_Трапы, страховка к АМС', '1.7_Ограждения территории', '1.8_Кабельный мост',
    '1.9_Площадка и огорождение', '1.10_Люк', '1.11_С высоты',
    '1.12_Лестницы и ограждения', '1.13_Соеденения',
    '1.14_Крепления отяжек к АМС', '1.15_Молниеприемники',
    '1.16_СОМ', '1.17_Распред.кор.СОМ', '1.18_Крепление АМС к фундаменту',
    '1.19_Фундамент', '1.20_Крепление АМС к разгруз. Раме', '1.21_Разгруз. Рама',
    '1.22_Оттяжки', '1.23_Измерение оттяжек', '1.24_Сливные отверстия',
    '1.25_Стоянки', '1.26_Протяжка', '1.27_Рейка',
    '1.28_Выполненные работы', '1.29_Дефекты', '1.30_Плакаты безоп.', '1.31_Другое',
    '1.32_MateLine', '2.1_общий вид', '2.2_фундамент', '2.3_ограждения',
    '2.4_территория 1м внеш.', '2.5_покрытие', '2.6_заземление', '2.7_состояние ТП',
    '2.8_изоляторы и конт. Зажимы', '2.9_селикагель',
    '2.10_двери и замки', '2.11_контакты на КТП', '2.12_занки без.',
    '2.13_ввода', '2.14_навесные замки', '2.15_территория зачистка', '2.16_очистка оборудования',
    '2.17_измерения', '2.18_швы и болт соед', '2.19_РЛНД изоляторы',
    '2.20_РЛНД контакты', '2.21_РЛНД управление', '2.22_РЛНД запор. Устр',
    '2.23_РЛНД зеземление', '2.24_Опоры ВЛ', '2.25_Оранная зона',
    '2.32_MateLine', '2.33_другое', '3.1_измерения',
    '3.2_серийные номера', '3.3_точки съема', '3.32_MateLine',
    '3.33_Другое', '4.1_ключи', '4.2_вид с наружи площадка',
    '4.3_вид с наружи контейнер', '4.4_вид с наружи АМС',
    '4.5_вид с наружи ДГУ', '4.6_вид с наружи выгородка',
    '4.7_вид внутри от входа', '4.8_вид внутри стойки',
    '4.9_вид внутри АКБ', '4.10_вид внутри кабельросты',
    '4.11_ОПС блок управления', '4.12_ОПС датчики', '4.13_ОПС огнетушители',
    '4.14_гермоввод', '4.15_разгрузочная рама', '4.16_фундамент контейнера',
    '4.17_гидроизоляция фундамента', '4.18_наруж. Кабельрост', '4.19_защитн. Полоса ',
    '4.20_знаки безопасности', '4.21_внешние АВР', '4.32_MateLine',
    '4.33_Другое', '5.1_ключи', '5.2_внутренний бл',
    '5.3_внешний бл', '5.4_фрикулинг', '5.5_обогреватель',
    '5.6_блок управления', '5.7_фильтры', '5.8_теплообменник нар. Бл',
    '5.9_защита', '5.10_аварийная индикация',
    '5.11_пульт', '5.12_вреонопроводы', '5.13_внешние АВР',
    '5.32_MateLine', '5.33_Другое', '6.1_дефекты', '6.2_внутр. Блок',
    '6.3_вн. Бл фильтр', '6.4_вн бл фреон', '6.5_вн бл компрессор',
    '6.6_внешний блок', '6.7_фильтры', '6.8_Т внеш. Блок', '6.9_Т внутр блок',
    '6.10_клеммы', '6.11_давление испарения', '6.12_давления конденсации',
    '6.13_АВР индикация', '6.14_дренаж', '6.15_Лог АВР', '6.32_MateLine',
    '6.33_Другое', '7.1_внешний вид тех часть', '7.2_внешний вид контр. Приборы',
    '7.3_манометр', '7.4_манометр пломба', '7.5_давление', '7.6_дата овидет.',
    '7.7_источники питания', '7.32_MateLine', '7.33_Другое', '8.1_внешний вид',
    '8.2_крепления', '8.3_трубопроводы', '8.4_уборка', '8.5_электр. Части',
    '8.6_масло', '8.7_масл. Ф', '8.8_топл. Ф', '8.9_воздуш. Ф',
    '8.10_антифриз', '8.11_АКБ', '8.12_приборы', '8.13_генератор внешн. Вид',
    '8.14_генератор крепление', '8.15_генератор чистка', '8.16_генератор контакты',
    '8.17_контейнер общий вид', '8.18_контейнер освещение', '8.19_контейнер жалюзи',
    '8.32_MateLine', '8.33_Другое', '9.1_ключи', '9.32_MateLine', '9.33_Другое');


{$R *.lfm}

{ TForm1 }

procedure TForm1.FormActivate(Sender: TObject);
begin
   //Label3.Caption:='init';
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  If SelectDirectoryDialog1.Execute then begin
    MyAllPic.Init;
    MyAllPic.SetDir(IncludeTrailingPathDelimiter( SelectDirectoryDialog1.FileName));
  end;
  Label2.Caption:=MyAllPic.GetDir;
  RedrawStat;
  If MyAllPic.GetMaxNum>0 then Image1.Picture.LoadFromFile(MyAllPic.GetName);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  MyAllPic.SetNum(-1);
  MyAllPic.SetTO(-1);
  RedrawStat;
  ListBox1.Items.Clear;
  ListBox1.Items.AddStrings(String(FotoTypeStrings[1]));
  RadioGroup1.ItemIndex:=MyAllPic.GetTO;
  ListBox1.ItemIndex:=MyAllPic.GetNum;
end;

procedure TForm1.Button2Click(Sender: TObject);
var iTempTO:Integer;
begin
  StoreFoto;
  iTempTO:=MyAllPic.GetTO;
  MyAllPic.PrevFoto;
  RedrawStat;
  If MyAllPic.GetTO=-1
    then RadioGroup1.ItemIndex:=iTempTO
    else   RadioGroup1.ItemIndex:=MyAllPic.GetTO;
  ListBox1.ItemIndex:=MyAllPic.GetNum;
  If MyAllPic.GetMaxNum>0 then Image1.Picture.LoadFromFile(MyAllPic.GetName);
end;

procedure TForm1.Button3Click(Sender: TObject);
var iTempTO:Integer;
begin
  StoreFoto;
  iTempTO:=MyAllPic.GetTO;
  MyAllPic.NextFoto;
  RedrawStat;
  If MyAllPic.GetTO=-1
    then RadioGroup1.ItemIndex:=iTempTO
    else   RadioGroup1.ItemIndex:=MyAllPic.GetTO;
  ListBox1.ItemIndex:=MyAllPic.GetNum;
  If MyAllPic.GetMaxNum>0 then Image1.Picture.LoadFromFile(MyAllPic.GetName);
end;


// Выдать ТО соответствующее номеру
Function GetTOString(iTOTyp, iNumTyp: Integer):String;
var
   i,i1: Integer;
   s, s1:String;
begin
  s1:='';
  Str(iTOTyp, S);
  i1:=-1;
  For i:=1 To MaxFotoTypes do begin
    If Copy(FotoTypeStrings[i],1,Length(S))=S then begin
      Inc(i1);
    end;
    If i1=iNumTyp then begin
      s1:=FotoTypeStrings[i];
    end;
  end;//for
  GetTOString:=s1;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  ArrTemp : Array[0..MaxTOTypes,0..MaxTOStrings] of integer;
  i1,i2:Integer;
  s1,s2:String;
  f:Text;
  f1: Text;
begin
  try
  system.Assign(f,'temp.txt');
  Rewrite(f);
  // Обнуление массива
  for i1:=0 to MaxTOTypes do begin
    for i2:=0 to MaxTOStrings do begin
      ArrTemp[i1,i2]:=0;
    end;// for i2
  end;//for i1
  for i1:=1 to MyAllPic.GetMaxNum do begin
    If (MyAllPic.AllPic[i1].iNumType>-1) and (MyAllPic.AllPic[i1].iTOType>-1) then begin
      Inc(ArrTemp[MyAllPic.AllPic[i1].iTOType,MyAllPic.AllPic[i1].iNumType]);
      Str(ArrTemp[MyAllPic.AllPic[i1].iTOType,MyAllPic.AllPic[i1].iNumType],s2);
      s1:=MaskEdit1.EditText+sDelim+RadioGroup1.Items.ValueFromIndex[MyAllPic.AllPic[i1].iTOType]
//      +sDelim+ListBox1.Items.ValueFromIndex[MyAllPic.AllPic[i1].iNumType]+sDelim+s2+FileSuffix;
      +sDelim+GetTOString(MyAllPic.AllPic[i1].iTOType+1,MyAllPic.AllPic[i1].iNumType)+sDelim+s2+FileSuffix;
      MyAllPic.AllPic[i1].sNewName:=s1;
      writeln(f,'ren "',MyAllPic.AllPic[i1].sName,'" "',MyAllPic.AllPic[i1].sNewName,'"');
      system.Assign(f1,MyAllPic.AllPic[i1].sName);
      Rename(f1,MyAllPic.AllPic[i1].sNewName);
    end;//if
  end;//for
  finally
  system.Close(f);
  end;
  ShowMessage('Сделано, закройте программу');
end;

procedure TForm1.FormCreate(Sender: TObject);
var s:String;
  f:Text;
  i:Integer;
begin
  KeyPreview:=True;
  MyAllPic.Init;
  s:=MyAllPic.GetDir;
  Label2.Caption:=S;
  MyAllPic.SetDir(S);
  RedrawStat;
  If MyAllPic.GetMaxNum>0 then Image1.Picture.LoadFromFile(MyAllPic.GetName);
  for i:=1 to MaxBS do begin
    AllBS[i]:='';
  end;
  i:=1;
  AssignFile(f,'picrenamer.txt');
  try
  {$I-}
    Reset(f);
  {$I+}
    If IOResult<>0 then begin
      Rewrite(f);
      WriteLn(f,'25028012345,00005 Нет БС5');
      WriteLn(f,'25028012346,00006 Нет БС6');
      WriteLn(f,'25028012347,00007 Нет БС7');
      WriteLn(f,'25028012348,00008 Нет БС8');
      WriteLn(f,'25028012349,00009 Нет БС9');
      CloseFile(f);
      Reset(f);
    end;
    repeat
      ReadLn(f,s);
      If Length(s)>22 then begin
        AllBS[i]:=s;
        Inc(i);
      end;
    until (eof(f)) or (i>MaxBS);
    CloseFile(f);
  finally
  end;
  Label4.Caption:='Empty ERP';
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  If Key = VK_F6 then begin
    Button2Click(Sender);
    //Key:=0;
  end;
  If Key = VK_F7 then begin
    Button3Click(Sender);
    //Key:=0;
  end;
  If (Key =VK_F5) then begin
    ShowMessage('F5 pressed');
  end;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Image1.Width:=Width-224;
  Image1.Height:=Height-128;
  ListBox1.Height:=Image1.Height;
end;

procedure TForm1.Label4Click(Sender: TObject);
begin
  ListBox1.ItemIndex:=-1;
  RadioGroup1.ItemIndex:=-1;
  StoreFoto;
end;

procedure TForm1.MaskEdit1Change(Sender: TObject);
var s1:String;
  i:Integer;
begin
  s1:='Wrong ERP?';
  Label4.Font.Color:=clRed;
  For i:=1 to MaxBS do begin
    If Copy(AllBS[i],1,Length('25028012345'))=MaskEdit1.Text then begin
      s1:=AllBS[i];
      Delete(s1,1,Length('25028012345,'));
      //s1:=Copy(AllBS[i],Length('25028012345')+2,Length(AllBS[i])-Length('25028012345')-2);
      Label4.Font.Color:=clDefault;
    end;
  end;
  Label4.Caption:=s1;
end;

procedure TForm1.RadioGroup1SelectionChanged(Sender: TObject);
var
   i:Integer;
   c1:Char;
   s1:String;
begin
  If MyAllPic.GetTO<>RadioGroup1.ItemIndex then begin
    MyAllPic.SetTO(RadioGroup1.ItemIndex);
    MyAllPic.SetNum(-1);
  end;

  //MyAllPic.SetNum(ListBox1.ItemIndex);

  ListBox1.Items.Clear;
  i:=RadioGroup1.ItemIndex+1;
  Str(i,s1);
  c1:=s1[1];
  For i:=1 to MaxFotoTypes //FotoTypeStrings
    do begin
      s1:=FotoTypeStrings[i];
      If s1[1]=c1 then ListBox1.Items.AddStrings(s1);
    end;
  ListBox1.ItemIndex:=MyAllPic.GetNum;
end;

procedure TForm1.RedrawStat;
var s1, s2:String;
begin
  Str(MyAllPic.GetMaxNum,S1);
  Str(MyAllPic.GetAlreadyProcCount,s2);
  Label3.Caption:='фото '+s1+' обработано '+s2;
end;

procedure TForm1.StoreFoto;
begin
  MyAllPic.SetTO(RadioGroup1.ItemIndex);
  MyAllPic.SetNum(ListBox1.ItemIndex);
end;

{ TForm1 }


{ TCollectMyPic }

constructor TCollectMyPic.Init;

begin
  ClearVars;
  sPathDir:=ExtractFilePath(ExtractFilePath(Paramstr(0)));
end;

procedure TCollectMyPic.ClearVars;
var i:Integer;
begin
  iCurIndex:=0;
  iFilesCount:=0;
  For i:=1 to MaxFiles do begin
    with AllPic[i] do begin
      sName:='';
      iTOType := -1;
      iNumType := -1;
    end;
  end;
end;

function TCollectMyPic.GetName: String;
begin
  If (iCurIndex<1) or (iCurIndex>MaxFiles) then GetName:=''
  else begin
    with AllPic[iCurIndex] do begin
      GetName:=sPathDir+sName;
    end;
  end;
end;



function TCollectMyPic.GetAlreadyProcCount: Integer;
var i,j:Integer;
begin
  j:=0;
  for i:=1 to MaxFiles do begin
    If (AllPic[i].iNumType>-1) and (AllPic[i].iTOType>-1) then j+=1;
  end;
  GetAlreadyProcCount:=j;
end;

function TCollectMyPic.GetDir: String;
begin
  GetDir:=sPathDir;
 end;

procedure TCollectMyPic.SetDir(sNameDir: String);
var
   Info:TSearchRec;
begin
  ClearVars;
  sPathDir:=sNameDir;
  iFilesCount:=0;
  if FindFirst(sPathDir+'*.jpg',faAnyFile,Info)=0
    then begin
      repeat
        iFilesCount+=1;
        If iFilesCount<=MaxFiles then begin
            AllPic[iFilesCount].sName:=Info.Name;
            AllPic[iFilesCount].iTOType:=-1;
            AllPic[iFilesCount].iNumType:=-1;
          end;
      until FindNext(Info)<>0;
    end;
  if iFilesCount>0 then iCurIndex:=1;
  FindClose(Info);
end;

procedure TCollectMyPic.SetTO(iTO: Integer);
begin
  AllPic[iCurIndex].iTOType:=iTO;
end;

procedure TCollectMyPic.SetNum(iNum: Integer);
begin
  AllPic[iCurIndex].iNumType:=iNum;
end;

function TCollectMyPic.GetTO: Integer;
begin
  GetTO:=AllPic[iCurIndex].iTOType;
end;

function TCollectMyPic.GetNum: Integer;
begin
  GetNum:=AllPic[iCurIndex].iNumType;
end;

function TCollectMyPic.GetMaxNum: Integer;
begin
  GetMaxNum:=iFilesCount;
end;

procedure TCollectMyPic.PrevFoto;
begin
  If iCurIndex>1 then Dec(iCurIndex);
end;

procedure TCollectMyPic.NextFoto;
begin
  If iCurIndex<iFilesCount then Inc(iCurIndex);
end;



end.

