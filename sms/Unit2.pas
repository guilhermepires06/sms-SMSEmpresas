unit Unit2;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, System.IOUtils, FireDAC.Comp.UI,
  FireDAC.Phys.FB, FireDAC.Phys.FBDef;

type

  TDm = class(TDataModule)
    Conn: TFDConnection;
    qryHistorico: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure ConnBeforeConnect(Sender: TObject);
  private
    { Private declarations }
  public

  end;

var
  Dm: TDm;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TDm.ConnBeforeConnect(Sender: TObject);
begin

    with conn do
    begin
       Params.Values ['Database'] := 'SQLite';
       Params.Values['Database'] := System.SysUtils.GetCurrentDir + '/banco.db';
       end;


    end;



procedure TDm.DataModuleCreate(Sender: TObject);
begin
    Conn.Connected := True;
    try

         except on e:exception do
         raise Exception.Create('Error Message'+ e.Message);

    end;

end;

end.
