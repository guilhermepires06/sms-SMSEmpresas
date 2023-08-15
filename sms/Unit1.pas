unit Unit1;

interface

                                    ///////////////////////////////////////////
                                    // API FEITA PELO SITE smsempresa.com.br//
                                    //////////////////////////////////////////





uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdHTTP, IdURI, System.JSON,
  IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdAuthentication, XMLDoc, XMLIntf,
  Vcl.ComCtrls, Vcl.CheckLst, Data.DB, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait,FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, System.IOUtils, FireDAC.Comp.UI,
  FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Intf, Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, StrUtils,
  System.Win.TaskbarCore, Vcl.Taskbar,Winapi.ShellAPI,Generics.Collections, Generics.Defaults,DateUtils, System.Threading, System.NetEncoding, System.RegularExpressions, Vcl.Clipbrd;

type
  TForm1 = class(TForm)
    BtnEnviar: TButton;
    IdHTTP1: TIdHTTP;
    EditNumero: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    EditMensagem: TMemo;
    EditResposta: TMemo;
    DateTimePickerFrom: TDateTimePicker;
    DateTimePickerTo: TDateTimePicker;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    BtnSaldo: TButton;
    BtnResposta: TButton;
    MemoResposta: TMemo;
    EditID: TEdit;
    BtnRespostRescebida: TButton;
    Label7: TLabel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label8: TLabel;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    ListBox1: TListBox;
    Timer1: TTimer;
    Button1: TButton;
    ImageList1: TImageList;
    Taskbar1: TTaskbar;
    Timer2: TTimer;
    procedure BtnEnviarClick(Sender: TObject);
    procedure BtnRespostaClick(Sender: TObject);
    procedure BtnSaldoClick(Sender: TObject);
    procedure BtnRespostRescebidaClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure EditRespostaChange(Sender: TObject);
    procedure atualizador(Sender: TObject);



  private
    { Private declarations }
    procedure SendSMS(const key: string; const number: Int64; const msg: string);
    procedure FillListBox1;
    function IDExistsInDatabase(const ID: string): Boolean;
    procedure PerformAPICall(const APIURL, JSONData: string;
      var APIResponse: string);



  public

  public
    { Public declarations }
    qryHistorico: TFDQuery;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses Unit2;



procedure TForm1.BtnEnviarClick(Sender: TObject);              ///////////////// BOTAO ENVIAR
var
  apiKey: string;
  numberStr: string;
  number: Int64;
  msg: string;
begin

if EditNumero.Text = '' then
  begin
    ShowMessage('Por favor, insira o Numero de Telefone antes de realizar a consulta.');
    Exit;
  end;

  apiKey := 'COLOQUE A KEY AQUI';

  numberStr := EditNumero.Text;
  msg := EditMensagem.Text;

  if TryStrToInt64(numberStr, number) then
  begin
    SendSMS(apiKey, number, msg);
  end
  else
  begin
    ShowMessage('Número inválido');
  end;
end;


///////////////////função para verificar se tem algum ID igual///////////////////
function TForm1.IDExistsInDatabase(const ID: string): Boolean;
begin
  DM.qryHistorico.SQL.Text := 'SELECT COUNT(*) FROM TAB_HISTORICO WHERE ID_SMS = :ID_SMS';
  DM.qryHistorico.ParamByName('ID_SMS').AsString := ID;
  DM.qryHistorico.Open;
  try
    Result := (not DM.qryHistorico.Fields[0].IsNull) and (DM.qryHistorico.Fields[0].AsInteger > 0);
  finally
    DM.qryHistorico.Close;
  end;
end;


procedure TForm1.SendSMS(const key: string; const number: Int64; const msg: string);
var
  httpClient: TIdHTTP;
  url: string;
  requestData: TStringStream;
  response: string;
  xmlDoc: IXMLDocument;
  node: IXMLNode;
  ID: string;
begin
  httpClient := TIdHTTP.Create(nil);
  try
    url := 'https://api.smsempresa.com.br/v1/send';
    httpClient.IOHandler := IdSSLIOHandlerSocketOpenSSL1;

    requestData := TStringStream.Create(
      '[{"key": "' + key + '", "type": 9, "number":' + IntToStr(number) + ', "msg": "' + msg + '"}]',
      TEncoding.UTF8
    );
    try
      httpClient.Request.ContentType := 'application/json';
      httpClient.Request.CustomHeaders.Add('key: ' + key);

      response := httpClient.Post(url, requestData);
      xmlDoc := TXMLDocument.Create(nil);
      try
        xmlDoc.LoadFromXML(response);
        node := xmlDoc.DocumentElement.ChildNodes['retorno'];
        if Assigned(node) then
        begin
          //Verifique se o ID_SMS já existe no banco de dados
          ID := node.Attributes['id'];
          if not IDExistsInDatabase(ID) then
          begin
            // Se o ID não estiver presente no banco de dados, salve a resposta e o ID em TAB_HISTORICO
            EditResposta.Text := 'Situação: ' + node.Attributes['situacao'] + sLineBreak +
                                 'Código: ' + node.Attributes['codigo'] + sLineBreak +
                                 'id: '  + ID + sLineBreak +
                                 'Mensagem: ' + node.Text;

            MemoResposta.Text :=  response;

            // Salve a resposta, o número e a mensagem em TAB_HISTORICO
            DM.qryHistorico.SQL.Text :=
              'INSERT INTO TAB_HISTORICO (ID_SMS, DESTINO, MENSAGEM) VALUES (:ID_SMS, :DESTINO, :MENSAGEM)';
            DM.qryHistorico.ParamByName('ID_SMS').AsString := ID;
            DM.qryHistorico.ParamByName('DESTINO').AsLargeInt := number;
            DM.qryHistorico.ParamByName('MENSAGEM').AsString := msg;
            DM.qryHistorico.ExecSQL; //Uso o ExecSQL para executar a instrução INSERT

            ShowMessage('Registro salvo com sucesso!');
          end
          else
            ShowMessage('ID_SMS já existe no banco de dados.');
        end;
      finally
        xmlDoc := nil;
      end;
    finally
      requestData.Free;
    end;
  finally
    httpClient.Free;
  end;
end;


///////////////////  atualizar o HISTORICO   ///////////////////
procedure TForm1.FillListBox1;
var
  HistoricData: string;
begin

  if not Assigned(DM) then
    DM := TDM.Create(Application);

  try
    DM.Conn.BeforeConnect := DM.ConnBeforeConnect;
    DM.Conn.Connected := True;

    // Define a consulta SQL para buscar os dados do banco de dados
    DM.qryHistorico.SQL.Text := 'SELECT ID_SMS, DATA, OPERADORA, DESTINO, MENSAGEM, SITUACAO FROM TAB_HISTORICO';

    // Abre a consulta e recupera os dados do banco de dados
    DM.qryHistorico.Open;

    // Limpa o ListBox antes de preencher com novos dados
    ListBox1.Clear;

    // Preenche o ListBox com os dados retornados pela consulta
    while not DM.qryHistorico.Eof do
    begin
      // Cria uma string com os dados do histórico

      HistoricData :=
        DM.qryHistorico.FieldByName('ID_SMS').AsString    + '   |   ' +
        DM.qryHistorico.FieldByName('DATA').AsString      + '   |   ' +
        DM.qryHistorico.FieldByName('OPERADORA').AsString + '   |   ' +
        DM.qryHistorico.FieldByName('DESTINO').AsString   + '   |   ' +
        DM.qryHistorico.FieldByName('MENSAGEM').AsString  +'    |   ' +
        DM.qryHistorico.FieldByName('SITUACAO').AsString;


      ListBox1.Items.Add(HistoricData); // Adiciona a string como um item no ListBox
      DM.qryHistorico.Next;
    end;
  finally
    DM.qryHistorico.Close;
  end;
end;



procedure TForm1.FormShow(Sender: TObject);/// chama a função para listar tudo
begin
     FillListBox1;
     DateTimePickerFrom.Date := Date;
     DateTimePickerTo.Date := Date;
end;





procedure TForm1.BtnRespostaClick(Sender: TObject);
var
  IdHTTP: TIdHTTP;
  JSONRequest, JSONResponse: TStringStream;
  APIURL: string;
  JSONData: TJSONObject;
begin
  EditResposta.Clear;
  MemoResposta.Clear;

  APIURL := 'https://api.smsdev.com.br/v1/report/total';
  IdHTTP := TIdHTTP.Create(Self);
  JSONRequest := TStringStream.Create('{"key":"' + 'COLOQUE A KEY AQUI' + '","date_from":"' +
    FormatDateTime('dd/mm/yyyy', DateTimePickerFrom.Date) + '","date_to":"' +
    FormatDateTime('dd/mm/yyyy', DateTimePickerTo.Date) + '"}');
  JSONResponse := TStringStream.Create;

  try
    IdHTTP.Post(APIURL, JSONRequest, JSONResponse);
    JSONData := TJSONObject.ParseJSONValue(JSONResponse.DataString) as TJSONObject;

    if (JSONData <> nil) then
    begin
      EditResposta.Text :=
        'Situação Da Conexão: ' + JSONData.GetValue('situacao').Value + sLineBreak +
        'Data Início: ' + JSONData.GetValue('data_inicio').Value + sLineBreak +
        'Data Fim: ' + JSONData.GetValue('data_fim').Value + sLineBreak +
        'Quantidade de SMS Enviado: ' + JSONData.GetValue('qtd_credito').Value;

      MemoResposta.Text := JSONData.ToString;  // Converte o objeto JSON para string e exibe no MemoResposta
    end
    else
    begin
      EditResposta.Text := 'Resposta inválida ou campos ausentes no JSON';
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao chamar a API: ' + E.Message);
  end;

  IdHTTP.Free;
  JSONRequest.Free;
  JSONResponse.Free;
end;




function ExtractXMLTagValue(const XML, TagName: string): string;
var
  XMLDoc: IXMLDocument;
  Node: IXMLNode;
begin
  Result := '';
  XMLDoc := TXMLDocument.Create(nil);
  try
    XMLDoc.LoadFromXML(XML);
    Node := XMLDoc.DocumentElement.ChildNodes.FindNode(TagName);
    if Assigned(Node) then
      Result := Node.Text;
  except
  end;
end;





procedure TForm1.BtnSaldoClick(Sender: TObject);//////// VERIFICA O SALDO DA CONTA
var
  IdHTTP: TIdHTTP;
  JSONRequest, JSONResponse: TStringStream;
  APIURL: string;
  JSONParam: TJSONObject;
  JSONResult: TJSONObject;

begin
EditResposta.Clear;
  APIURL := 'https://api.smsdev.com.br/v1/balance';

  IdHTTP := TIdHTTP.Create(Self);
  JSONRequest := TStringStream.Create;

  try
    JSONParam := TJSONObject.Create;
    JSONParam.AddPair('key', 'COLOQUE A KEY AQUI');

    JSONRequest.WriteString(JSONParam.ToJSON);
    JSONResponse := TStringStream.Create;

    try
      IdHTTP.Post(APIURL, JSONRequest, JSONResponse);
      JSONResult := TJSONObject.ParseJSONValue(JSONResponse.DataString) as TJSONObject;
      try
        if Assigned(JSONResult) then
        begin

          EditResposta.Text :=
            'Situação: ' + JSONResult.GetValue('situacao').Value + sLineBreak +
            '' + JSONResult.GetValue('descricao').Value + #13+ ': ' + JSONResult.GetValue('saldo_sms').Value + sLineBreak;
            MemoResposta.Text :=  JSONResult.ToString;
        end
        else
        begin
          ShowMessage('Resposta inválida da API.');
        end;
      finally
        JSONResult.Free;
      end;
    except
      on E: Exception do
        ShowMessage('Erro ao chamar a API: ' + E.Message);
    end;
    JSONParam.Free;
    JSONResponse.Free;
  finally
    IdHTTP.Free;
    JSONRequest.Free;
  end;
end;




procedure TForm1.EditRespostaChange(Sender: TObject);
var
  xmlResponse: string;
begin
  xmlResponse := EditResposta.Text;
  //SalvarIDAutomaticamente(xmlResponse);
end;

procedure TForm1.BtnRespostRescebidaClick(Sender: TObject);
var
  IdHTTP: TIdHTTP;
  APIURL: string;
  JSONRequest: TStringStream;
  JSONResponse: string;
  IDList: TStringList;
  i: Integer;
  XMLDocument: TXMLDocument;
  Node: IXMLNode;
begin
  EditResposta.Clear;

  // Construa a URL da API
  APIURL := 'https://api.smsempresa.com.br/v1/inbox';

  // Crie os objetos necessários
  IdHTTP := TIdHTTP.Create(Self);
  JSONRequest := TStringStream.Create;

  try
    // Defina o cabeçalho para aceitar a resposta no formato JSON
    IdHTTP.Request.ContentType := 'application/json';

    // Obtenha a lista de IDs do EditID e crie um array JSON para o campo "id"
    IDList := TStringList.Create;
    IDList.Text := EditID.Text;
    JSONRequest.WriteString('{"key":"COLOQUE A KEY AQUI", "status":0, "date_from":"' +
      FormatDateTime('dd/mm/yyyy', DateTimePickerFrom.Date) + '", "date_to":"' +
      FormatDateTime('dd/mm/yyyy', DateTimePickerTo.Date) + '", "id":[');

    for i := 0 to IDList.Count - 1 do
    begin
      if i > 0 then
        JSONRequest.WriteString(',');

      JSONRequest.WriteString(IDList[i]);
    end;

    JSONRequest.WriteString(']}');

    try
      // Realize a chamada POST à API
      JSONResponse := IdHTTP.Post(APIURL, JSONRequest);

      // Exibe a resposta recebida no MemoResposta
      MemoResposta.Text := JSONResponse;

      // Criar o objeto TXMLDocument e carregar o XML retornado pela API
      XMLDocument := TXMLDocument.Create(Self);
      try
        XMLDocument.LoadFromXML(JSONResponse);

        // Encontrar o nó "retorno"
        Node := XMLDocument.DocumentElement.ChildNodes.FindNode('retorno');

        // Verificar se o nó "retorno" foi encontrado
        if Assigned(Node) then
        begin
          // Extrair o valor do nó "retorno"
          EditResposta.Text := 'RETORNO: '+ Node.Text;
        end
        else
          EditResposta.Text := 'Tag <retorno> não encontrada no XML.';

      finally
        XMLDocument.Free;
      end;

    finally
      JSONRequest.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao chamar a API: ' + E.Message);
  end;

  // Libere os objetos criados
  IdHTTP.Free;
  IDList.Free;
end;





 ///////////////////////////////////////////////////////////////////////////////
 ///////////////PARA ATUALIZAR EM SEGUNDO PLANO/////////////////////////////////
procedure TForm1.PerformAPICall(const APIURL: string; const JSONData: string; var APIResponse: string);
var
  IdHTTP: TIdHTTP;
  XMLDocument: IXMLDocument;
  NodeList: IXMLNodeList;
  I: Integer;
  ID, DataEnvio, Operadora, Situacao: string;
  RecordExists: Boolean;
begin
  IdHTTP := TIdHTTP.Create(nil);
  try
    IdHTTP.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

    // Realize a chamada POST à API with JSONData
    APIResponse := IdHTTP.Post(APIURL, TStringStream.Create(JSONData, TEncoding.UTF8));

    // Check if the API response is not empty or invalid
    if APIResponse <> '' then
    begin
      // Parse the response as XML
      XMLDocument := TXMLDocument.Create(nil);
      try
        XMLDocument.LoadFromXML(APIResponse);
        NodeList := XMLDocument.DocumentElement.ChildNodes; // Get the <retorno> nodes
        for I := 0 to NodeList.Count - 1 do
        begin
          ID := NodeList[I].Attributes['id'];
          DataEnvio := NodeList[I].Attributes['data_envio'];
          Operadora := NodeList[I].Attributes['operadora'];
          Situacao := NodeList[I].Text;

          // Check if the record with the same ID_SMS already exists in the database
          DM.qryHistorico.SQL.Text := 'SELECT COUNT(*) FROM TAB_HISTORICO WHERE ID_SMS = :ID_SMS';
          DM.qryHistorico.ParamByName('ID_SMS').AsString := ID;
          DM.qryHistorico.Open;
          try
            RecordExists := not DM.qryHistorico.Fields[0].IsNull and (DM.qryHistorico.Fields[0].AsInteger > 0);
          finally
            DM.qryHistorico.Close;
          end;

          // Perform update or insert based on the record existence
          if RecordExists then
          begin
            DM.qryHistorico.SQL.Text :=
              'UPDATE TAB_HISTORICO SET Data = :DataEnvio, Operadora = :Operadora, Situacao = :Situacao WHERE ID_SMS = :ID_SMS';
            DM.qryHistorico.ParamByName('ID_SMS').AsString := ID;
          end
          else
          begin
            DM.qryHistorico.SQL.Text :=
              'INSERT INTO TAB_HISTORICO (ID_SMS, Data, Operadora, Situacao) VALUES (:ID_SMS, :DataEnvio, :Operadora, :Situacao)';
            DM.qryHistorico.ParamByName('ID_SMS').AsString := ID;
          end;

          DM.qryHistorico.ParamByName('DataEnvio').AsString := DataEnvio;
          DM.qryHistorico.ParamByName('Operadora').AsString := Operadora;
          DM.qryHistorico.ParamByName('Situacao').AsString := Situacao;
          DM.qryHistorico.ExecSQL; // Use ExecSQL to execute the SQL statement
        end;
      finally
        XMLDocument := nil; // Release the XML document
      end;
    end
    else
      ShowMessage('API response is empty or invalid.');
  finally
    IdHTTP.Free;
  end;
end;

procedure TForm1.atualizador(Sender: TObject);
var
  IDs: TStringList;
  APIURL: string;
  JSONData: string;
  APIResponse: string;
begin
  IDs := TStringList.Create;
  try
    // Selecionar todos os registros da tabela TAB_HISTORICO
    DM.qryHistorico.SQL.Text := 'SELECT ID_SMS FROM TAB_HISTORICO';
    DM.qryHistorico.Open;
    try
      while not DM.qryHistorico.Eof do
      begin
        IDs.Add(DM.qryHistorico.FieldByName('ID_SMS').AsString);
        DM.qryHistorico.Next;
      end;
    finally
      DM.qryHistorico.Close;
    end;

    if IDs.Count > 0 then
    begin
      // Construir o JSON com os IDs_SMS
      JSONData := Format('{"key":"COLOQUE A KEY AQUI","id":[%s]}', [IDs.CommaText]);

      // Construir a URL da API
      APIURL := 'https://api.smsempresa.com.br/v1/dlr';

      // Realizar a chamada à API com o JSONData
      PerformAPICall(APIURL, JSONData, APIResponse);
    end;
  finally
    IDs.Free;
  end;
end;


end.

