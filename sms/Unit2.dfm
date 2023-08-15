object Dm: TDm
  OnCreate = DataModuleCreate
  Height = 281
  Width = 230
  object Conn: TFDConnection
    Params.Strings = (
      'Database=C:\Users\Suporte 04\Desktop\sms\Win32\Debug\banco.db'
      'DriverID=SQLite')
    LoginPrompt = False
    AfterConnect = DataModuleCreate
    BeforeConnect = ConnBeforeConnect
    Left = 16
    Top = 8
  end
  object qryHistorico: TFDQuery
    CachedUpdates = True
    Connection = Conn
    SQL.Strings = (
      'select *from TAB_HISTORICO')
    Left = 96
    Top = 8
  end
end
