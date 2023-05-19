unit DTComparer;

interface

uses
FireDAC.Stan.Intf,
FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, FireDAC.Phys.IBBase,
FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Param,System.SysUtils,
FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.UI,
System.Classes,FireDAC.DBX.Migrate,Data.DB,Datasnap.DBClient,Datasnap.Provider;

type
  TStatus = procedure(Msg:string;TotalRegistros:Integer;PosicaoAtual:integer) of object;

type
  TDTComparer = class(TComponent)
  private
    fOnStatus: TStatus;
    FBancoMaster:string;
    FBancoCliente:string;
    FValoresDefault:Boolean;
    FComparaTriggers:Boolean;
    FCaminhoVendorLib:string;
    FUserNameBanco:string;
    FSenhaBanco:string;
    FPorta:string;
    FServer:string;
    FTotTabelas:integer;
    FPosicao:integer;
    ConexaoExt,Conexao:TFDConnection;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    cds_aux1,cds_aux2:Tclientdataset;
    sql_aux1,sql_aux2:TFDQuery;
    dsp_aux1,dsp_aux2:TDataSetProvider;
    ds_aux1,ds_aux2: TDataSource;
    FComparaIndice: Boolean;
    FScript: string;
    FScriptsExecutados: Integer;
    procedure SetBancoMaster(const Value: string);
    procedure SetBancoCliente(const Value: string);
    procedure SetValoresDefault(const Value: boolean);
    procedure SetCaminhoVendorLib(const Value: string);
    procedure SetUserNameBanco(const Value: string);
    procedure SetSenhaBanco(const Value: string);
    procedure SetPorta(const Value: string);
    procedure SetServer(const Value: string);
    Procedure ComparaEstruturas(vOrigem, vDestino: string);
    procedure SetComparaTriggers(const Value: Boolean);
    function verPrimaryKey(Tabela, Campo: string;Conexao:TFDConnection): Boolean;
    procedure SetComparaIndices(const Value: Boolean);
    procedure SetScript(const Value: string);
    procedure SetScriptsExecutados(const Value: Integer);
  protected
    { Protected declarations }
  public
    function ComparaBancos:Boolean;
    procedure ComparaTriggers(vOrigem, vDestino: string);
    procedure ComparaIndices(vOrigem, vDestino: string);
    procedure ExecutaScript;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published declarations }
    Property BancoMaster:String read FBancoMaster write SetBancoMaster;
    Property BancoCliente:String read FBancoCliente write SetBancoCliente;
    Property CaminhoVendorLib:String read FCaminhoVendorLib write SetCaminhoVendorLib;
    Property UserName:String read FUserNameBanco write SetUserNameBanco;
    Property SenhaBanco:String read FSenhaBanco write SetSenhaBanco;
    Property Porta:String read FPorta write SetPorta;
    Property Server:String read FServer write SetServer;
    Property ComparaValoresDefault: Boolean read FValoresDefault write SetValoresDefault Default False;
    property OnStatus: TStatus read fOnStatus write fOnStatus;
    Property VerificaTriggers: Boolean read FComparaTriggers write SetComparaTriggers Default False;
    Property VerificaIndices : Boolean read FComparaIndice   write SetComparaIndices Default False;
    property Script:string read FScript write SetScript;
    property ScriptsExecutados:Integer read FScriptsExecutados write SetScriptsExecutados;
  end;

procedure Register;

implementation

uses
  Vcl.Forms;

procedure Register;
begin
  RegisterComponents('DT Inovacao', [TDTComparer]);
end;

{ TDTComparer }

function TDTComparer.ComparaBancos: Boolean;
var
Qry,Qry1,Qry2: TFDQuery;
Qr,Vl : integer;
corte:integer;
Verifica:string;
begin
   try
      with ConexaoExt.Params do
      begin
        Clear;
        Add('DriverID=FB');
        Add('Server='    + FServer);
        Add('Database='  + FBancoMaster);
        Add('User_Name=' + FUserNameBanco);
        Add('Password='  + FSenhaBanco);
        Add('Port='      + FPorta);
      end;
      ConexaoExt.Open;

      with Conexao.Params do
      begin
        Clear;
        Add('DriverID=FB');
        Add('Server='    + FServer);
        Add('Database='  + FBancoCliente);
        Add('User_Name=' + FUserNameBanco);
        Add('Password='  + FSenhaBanco);
        Add('Port='      + FPorta);
      end;
      Conexao.Open;
      qry := TFDQuery.Create(nil);
      qry.Connection := ConexaoExt;

      qry1 := TFDQuery.Create(nil);
      qry1.Connection := Conexao;

      qry2 := TFDQuery.Create(nil);
      qry2.Connection := Conexao;

      if Assigned(fOnStatus) then
      fOnStatus('Iniciando Comparação da base de dados',0,0);
      application.ProcessMessages;

      qr := 0;
      vl := 0;
      qry.SQL.Text := 'SELECT count(RDB$RELATION_NAME) AS TOTAL FROM RDB$RELATIONS WHERE RDB$VIEW_BLR IS NULL and rdb$system_flag = 0';
      QRY.Open;
      if NOT QRY.IsEmpty then
      BEGIN
         qr := qry.FieldByName('TOTAL').AsInteger;
      END;
      QRY.SQL.Clear;

      FTotTabelas  := Qr;

      qry.SQL.Text := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS WHERE RDB$VIEW_BLR IS NULL and rdb$system_flag = 0  order by rdb$relation_name';
      qry.Open;
      while not qry.Eof  do
      begin
          VL := VL + 1;

          FPosicao := Vl;

          Sleep(45);

          ComparaEstruturas(qry.FieldByName('rdb$relation_name').AsString,qry.FieldByName('rdb$relation_name').AsString);

          if FComparaIndice then
             ComparaIndices(qry.FieldByName('rdb$relation_name').AsString,qry.FieldByName('rdb$relation_name').AsString) ;

          qry.Next ;
      end;
      qry.Close;
      QRY.Free;
      QRY1.Close;
      QRY1.Free;
      QRY2.Close;
      QRY2.Free;

      if FComparaTriggers then
      ComparaTriggers('','');

      if not FScript.IsEmpty then
         ExecutaScript;

      Conexao.Connected    := false;
      ConexaoExt.Connected := false;

      if Assigned(fOnStatus) then
      fOnStatus('Comparação da base de dados Finalizada',FTotTabelas,FPosicao);
      application.ProcessMessages;
   except on e:Exception do
   begin
         raise Exception.Create(e.Message);
   end;

   end;
end;

procedure TDTComparer.ComparaEstruturas(vOrigem, vDestino: string);
var
   TrsAB: TFDDBXTransactionDesc;
   vCampoTipo,vCampoTipoD,vOrigemCampo,vOrigemTipo: string;
   vCampoDec,vCampoTam,vOrigemTamanho: integer;
   vCampoExiste,vTabelaExiste,vPrimeiraExecucao,xPrimaryKey: boolean;
   idtrans:integer;
   sql:STRING;
   D_Campo,DDefault,VCampoDefault:string;
begin
   if Assigned(fOnStatus) then
      fOnStatus('Atualizando Banco de Dados: ' + vOrigem , FTotTabelas, FPosicao);

   application.ProcessMessages;

   sql_aux1                      := TFDQuery.Create(nil);
   sql_aux2                      := TFDQuery.Create(nil);

   cds_aux1                      := TClientDataSet.Create(nil);
   cds_aux2                      := TClientDataSet.Create(nil);

   dsp_aux1                      := TProvider.Create(nil);
   dsp_aux2                      := TProvider.Create(nil);

   ds_aux1                       := TDataSource.Create(nil);
   ds_aux2                       := TDataSource.Create(nil);

   sql_aux1.Connection           := ConexaoExt;
   dsp_aux1.DataSet              := sql_aux1;
   cds_aux1.SetProvider(dsp_aux1);
   ds_aux1.DataSet               := cds_aux1;
   dsp_aux1.Options              := [poAllowCommandText];

   sql_aux2.Connection           := Conexao;
   dsp_aux2.DataSet              := sql_aux2;
   cds_aux2.SetProvider(dsp_aux2);
   ds_aux2.DataSet               := cds_aux2;
   dsp_aux2.Options              := [poAllowCommandText];

   cds_aux1.close;
   sql_aux1.commandText := 'SELECT A.RDB$FIELD_NAME CAMPO,'+
                              '       C.RDB$TYPE_NAME TIPO,'+
                              '       B.RDB$FIELD_LENGTH TAMANHO,'+
                              '       B.RDB$FIELD_SCALE DECIMAIS,'+
                              '       B.RDB$FIELD_PRECISION AS TAMDEC '+
                              'FROM   RDB$RELATION_FIELDS A,'+
                              '       RDB$FIELDS B,'+
                              '       RDB$TYPES C '+
                              'WHERE  (A.RDB$RELATION_NAME = '''+vOrigem+''') AND '+
                              '       (B.RDB$FIELD_NAME = A.RDB$FIELD_SOURCE) AND '+
                              '       (C.RDB$TYPE = B.RDB$FIELD_TYPE) AND '+
                              '       (C.RDB$FIELD_NAME = ''RDB$FIELD_TYPE'') '+
                              'ORDER BY RDB$FIELD_POSITION';
   cds_aux1.Open;

   // Select Campos de Destino
   cds_aux2.close;
   sql_aux2.commandText := 'SELECT A.RDB$FIELD_NAME CAMPO,'+
                              '       C.RDB$TYPE_NAME TIPO,'+
                              '       B.RDB$FIELD_LENGTH TAMANHO,'+
                              '       B.RDB$FIELD_SUB_TYPE DECIMAIS '+
                              'FROM   RDB$RELATION_FIELDS A,'+
                              '       RDB$FIELDS B,'+
                              '       RDB$TYPES C '+
                              'WHERE  (A.RDB$RELATION_NAME = '''+vDestino+''') AND '+
                              '       (B.RDB$FIELD_NAME = A.RDB$FIELD_SOURCE) AND '+
                              '       (C.RDB$TYPE = B.RDB$FIELD_TYPE) AND '+
                              '       (C.RDB$FIELD_NAME = ''RDB$FIELD_TYPE'') '+
                              'ORDER BY RDB$FIELD_POSITION';
   cds_aux2.open;
   vTabelaExiste     := (not cds_aux2.Eof);
   vPrimeiraExecucao := True;
   idtrans           :=0;
   if vOrigem = 'TBCONCILIACAO' then
    vOrigem := vOrigem;

   with cds_aux1 do
   begin
      while not eof do
      begin
         vOrigemCampo  := Trim(fieldbyname('campo').asstring);
         vCampoTam     := fieldbyname('TAMANHO').asinteger;
         vCampoTipo    := fieldbyname('TIPO').AsString;
         vCampoExiste  := False;
         cds_aux2.first;

         while not cds_aux2.eof do
         begin
            if Trim(cds_aux2.fieldbyname('CAMPO').asstring) = vOrigemCampo then
            begin
               vOrigemTamanho  := cds_aux2.fieldbyname('TAMANHO').asinteger;
               vOrigemTipo     := cds_aux2.fieldbyname('TIPO').AsString;
               vCampoExiste    := True;
               Break;
            end;
            cds_aux2.next;
         end;
         if not vCampoExiste then
         begin
            idtrans        := idtrans + 1;
            vCampoTipo     := Trim(fieldbyname('TIPO').asstring);
            if fieldbyname('DECIMAIS').asinteger = 0 then
               vCampoDec   := 0
            else
            vCampoDec      := (fieldbyname('DECIMAIS').asinteger*-1);
            vCampoTam      := fieldbyname('TAMANHO').asinteger;
            if (vCampoTipo = 'LONG') AND (vCampoDec = 0) then
               vCampoTipoD := 'INTEGER'
            else if vCampoTipo = 'BLOB' then
               vCampoTipoD := 'BLOB SUB_TYPE 1'
            else if vCampoTipo = 'VARYING' then
               vCampoTipoD := 'VARCHAR('+IntToStr(vCampoTam)+')  character set WIN1252 collate WIN_PTBR'
            ELSE if vCampoTipo = 'TIMESTAMP' then
               vCampoTipoD := 'TIMESTAMP'
            else if vCampoTipo = 'DATE' then
               vCampoTipoD := 'DATE'
            else if vCampoTipo = 'DOUBLE' then
               vCampoTipoD := 'DOUBLE PRECISION DEFAULT 0.0'
            else if ((vCampoTipo = 'LONG') OR (vCampoTipo = 'INT64')) AND (vCampoDec > 0) then
               vCampoTipoD := 'DECIMAL('+IntToStr(fieldbyname('TAMDEC').asinteger)+','+IntToStr(vCampoDec)+')';
            try
               TrsAB.TransactionID  := idtrans;
               TrsAB.IsolationLevel := xiReadCommitted;
               Conexao.StartTransaction(TrsAB);
               if not vTabelaExiste and vPrimeiraExecucao then
               begin
                 if verPrimaryKey( vOrigem, vOrigemCampo, ConexaoExt) then
                 BEGIN
                         TRY
                           TRY
                               conexao.execsql('DROP GENERATOR '+vDestino+'_ID_GEN7');
                           EXCEPT
                           END;
                         FINALLY
                         END;
                         TRY
                           TRY
                               conexao.execsql('CREATE TABLE '+vDestino+' ('+vOrigemCampo+' '+vCampoTipoD+' NOT NULL)');
                           EXCEPT
                           END;
                         FINALLY
                         END;
                         TRY
                           TRY
                               conexao.execsql('ALTER TABLE '+vDestino+' ADD '+vOrigemCampo+' '+vCampoTipoD + ' NOT NULL');
                           EXCEPT
                           END;
                         FINALLY
                         END;
                         TRY
                           TRY
                               SQL :=
                               ' update rdb$relation_fields set ' +
                               ' rdb$null_flag = 1 ' +
                               ' where (rdb$field_name = '+ vOrigemCampo +') ' +
                               ' and (rdb$relation_name = '+vDestino+'); ';
                               conexao.execsql(sql);
                           EXCEPT
                           END;
                         FINALLY
                         END;
                         TRY
                           TRY
                               conexao.execsql('ALTER TABLE '+vDestino+' ADD PRIMARY KEY ('+vOrigemCampo+')');
                           EXCEPT
                           END;
                         FINALLY
                         END;
                         TRY
                           TRY
                               conexao.execsql('CREATE GENERATOR '+vDestino+'_ID_GEN7');
                           EXCEPT
                           END;
                         FINALLY
                         END;
                         TRY
                           TRY
                               SQL := ' CREATE TRIGGER BI_'+vDestino+'_ID FOR '+vDestino+'' +
                               ' ACTIVE BEFORE INSERT POSITION 0' +
                               ' AS' +
                               ' BEGIN' +
                               '   IF (NEW.ID IS NULL) THEN' +
                               '       NEW.ID = GEN_ID('+vDestino+'_ID_GEN7, 1);' +
                               ' END';
                               conexao.execsql(SQL)
                           EXCEPT
                           END;
                         FINALLY
                         END;
                 END ELSE begin
                         conexao.execsql('CREATE TABLE '+vDestino+' ('+vOrigemCampo+' '+vCampoTipoD+')');
                 end;
                 Conexao.Commit(TrsAB);
               end ELSE begin
                       if verPrimaryKey( vOrigem, vOrigemCampo, ConexaoExt) then
                       BEGIN
                               TRY
                                 TRY
                                     conexao.execsql('DROP GENERATOR '+vDestino+'_ID_GEN7');
                                 EXCEPT
                                 END;
                               FINALLY
                               END;
                               TRY
                                 TRY
                                     conexao.execsql('CREATE TABLE '+vDestino+' ('+vOrigemCampo+' '+vCampoTipoD+' NOT NULL)');
                                 EXCEPT
                                 END;
                               FINALLY
                               END;
                               TRY
                                 TRY
                                     conexao.execsql('ALTER TABLE '+vDestino+' ADD '+vOrigemCampo+' '+vCampoTipoD + ' NOT NULL');
                                 EXCEPT
                                 END;
                               FINALLY
                               END;

                               TRY
                                 TRY
                                     SQL :=
                                     ' update rdb$relation_fields set ' +
                                     ' rdb$null_flag = 1 ' +
                                     ' where (rdb$field_name = '+ vOrigemCampo +') ' +
                                     ' and (rdb$relation_name = '+vDestino+'); ';
                                     conexao.execsql(sql);
                                 EXCEPT
                                 END;
                               FINALLY
                               END;
                               TRY
                                 TRY
                                     conexao.execsql('ALTER TABLE '+vDestino+' ADD PRIMARY KEY ('+vOrigemCampo+')');
                                 EXCEPT
                                 END;
                               FINALLY
                               END;
                               TRY
                                 TRY
                                     conexao.execsql('CREATE GENERATOR '+vDestino+'_ID_GEN7');
                                 EXCEPT
                                 END;
                               FINALLY
                               END;
                               TRY
                                 TRY
                                     SQL := ' CREATE TRIGGER BI_'+vDestino+'_ID FOR '+vDestino+'' +
                                     ' ACTIVE BEFORE INSERT POSITION 0' +
                                     ' AS' +
                                     ' BEGIN' +
                                     '   IF (NEW.ID IS NULL) THEN' +
                                     '       NEW.ID = GEN_ID('+vDestino+'_ID_GEN7, 1);' +
                                     ' END';
                                     conexao.execsql(SQL)
                                 EXCEPT
                                 END;
                               FINALLY
                               END;
                       END ELSE begin
                           conexao.execsql('ALTER TABLE '+vDestino+' ADD '+vOrigemCampo+' '+vCampoTipoD);
                       end;
                       Conexao.Commit(TrsAB);
               end;
            except
               Conexao.RollBack(TrsAB);
            end;
               vPrimeiraExecucao := False;
         END ELSE BEGIN
            vCampoTipo    := Trim(fieldbyname('TIPO').asstring);
            if fieldbyname('DECIMAIS').asinteger = 0 then
               vCampoDec  := 0
            else
            vCampoDec  := (fieldbyname('DECIMAIS').asinteger*-1);
            // ALTERA TAMANHO
            if vOrigemTamanho<>vCampoTam then
            begin
                if (vCampoTipo = 'LONG') AND (vCampoDec = 0) then
                   vCampoTipoD := 'INTEGER'
                else if vCampoTipo = 'BLOB' then
                   vCampoTipoD := 'BLOB SUB_TYPE 1'
                else if vCampoTipo = 'VARYING' then
                   vCampoTipoD := 'VARCHAR('+IntToStr(vCampoTam)+')  character set WIN1252'
                else if vCampoTipo = 'DATE' then
                   vCampoTipoD := 'DATE'
                ELSE if vCampoTipo = 'TIMESTAMP' then
                   vCampoTipoD := 'TIMESTAMP'
                else if vCampoTipo = 'DOUBLE' then
                   vCampoTipoD := 'DOUBLE PRECISION'
                else if ((vCampoTipo = 'LONG') OR (vCampoTipo = 'INT64')) AND (vCampoDec > 0) then
                   vCampoTipoD := 'DECIMAL('+IntToStr(fieldbyname('TAMDEC').asinteger)+','+IntToStr(vCampoDec)+')';
                try
                   TrsAB.TransactionID  := idtrans;
                   TrsAB.IsolationLevel := xiReadCommitted;
                   Conexao.StartTransaction(TrsAB);
                   conexao.execsql('ALTER TABLE '+vDestino+' ALTER COLUMN '+vOrigemCampo+' TYPE '+vCampoTipoD);

                   Conexao.Commit(TrsAB);
                except
                   Conexao.RollBack(TrsAB);
                end;
            end;
            // ALTERA TIPO DE CAMPO
            if vOrigemTipo<>vCampoTipo then
            begin
                if (vCampoTipo = 'LONG') AND (vCampoDec = 0) then
                   vCampoTipoD := 'INTEGER'
                else if vCampoTipo = 'BLOB' then
                   vCampoTipoD := 'BLOB SUB_TYPE 1'
                else if vCampoTipo = 'VARYING' then
                   vCampoTipoD := 'VARCHAR('+IntToStr(vCampoTam)+')  character set WIN1252'
                else if vCampoTipo = 'DATE' then
                   vCampoTipoD := 'DATE'
                ELSE if vCampoTipo = 'TIMESTAMP' then
                   vCampoTipoD := 'TIMESTAMP'
                else if vCampoTipo = 'DOUBLE' then
                   vCampoTipoD := 'DOUBLE PRECISION'
                else if ((vCampoTipo = 'LONG') OR (vCampoTipo = 'INT64')) AND (vCampoDec > 0) then
                   vCampoTipoD := 'DECIMAL('+IntToStr(fieldbyname('TAMDEC').asinteger)+','+IntToStr(vCampoDec)+')';
                try
                   TrsAB.TransactionID  := idtrans;
                   TrsAB.IsolationLevel := xiReadCommitted;
                   Conexao.StartTransaction(TrsAB);
                   conexao.ExecSQL('ALTER TABLE '+vDestino+' ALTER COLUMN '+vOrigemCampo+' TYPE '+vCampoTipoD);

                   Conexao.Commit(TrsAB);
                except
                   Conexao.RollBack(TrsAB);
                end;
            end;
            vPrimeiraExecucao := False;
         end;
         next;
      end;
   end;
  FreeAndNil(sql_aux1);
  FreeAndNil(cds_aux1);
  FreeAndNil(dsp_aux1);
  FreeAndNil(ds_aux1);

  FreeAndNil(sql_aux2);
  FreeAndNil(cds_aux2);
  FreeAndNil(dsp_aux2);
  FreeAndNil(ds_aux2);
   // adiciona e/ou altera campo Default
  if FValoresDefault then
  begin
         sql_aux1                      := TFDQuery.Create(nil);
         sql_aux2                      := TFDQuery.Create(nil);

         cds_aux1                      := TClientDataSet.Create(nil);
         cds_aux2                      := TClientDataSet.Create(nil);

         dsp_aux1                      := TProvider.Create(nil);
         dsp_aux2                      := TProvider.Create(nil);

         ds_aux1                       := TDataSource.Create(nil);
         ds_aux2                       := TDataSource.Create(nil);

         sql_aux1.Connection           := ConexaoExt;
         dsp_aux1.DataSet              := sql_aux1;
         cds_aux1.SetProvider(dsp_aux1);
         ds_aux1.DataSet               := cds_aux1;
         dsp_aux1.Options              := [poAllowCommandText];

         sql_aux2.Connection           := Conexao;
         dsp_aux2.DataSet              := sql_aux2;
         cds_aux2.SetProvider(dsp_aux2);
         ds_aux2.DataSet               := cds_aux2;
         dsp_aux2.Options              := [poAllowCommandText];

         cds_aux1.close;
         sql_aux1.commandText := 'SELECT RDB$FIELD_NAME AS CAMPO, ' +
                                 ' CAST(RDB$RELATION_FIELDS.RDB$DEFAULT_SOURCE as varchar(32765)) AS VALOR_DEFAULT ' +
                                 ' FROM RDB$RELATION_FIELDS ' +
                                 ' WHERE RDB$RELATION_NAME ='''+vOrigem+'''' +
                                 ' AND RDB$DEFAULT_SOURCE IS NOT NULL ' +
                                 ' ORDER BY RDB$FIELD_POSITION ';
         cds_aux1.open;
         vPrimeiraExecucao := True;
         idtrans :=0;
         with cds_aux1 do
         begin
                while not eof do
                begin
                   D_Campo  := Trim(fieldbyname('CAMPO').asstring);
                   DDefault := fieldbyname('VALOR_DEFAULT').AsString;
                   idtrans  := idtrans + 1;
                   try
                     TrsAB.TransactionID  := idtrans;
                     TrsAB.IsolationLevel := xiReadCommitted;
                     Conexao.StartTransaction(TrsAB);
                     conexao.ExecSQL('ALTER TABLE ' + vDestino + ' ALTER ' + D_Campo + ' SET ' + DDefault  + '');

                     Conexao.Commit(TrsAB);
                   except
                     Conexao.RollBack(TrsAB);
                   end;
                   vPrimeiraExecucao := False;
                   next;
                end;
         end;
        FreeAndNil(sql_aux1);
        FreeAndNil(cds_aux1);
        FreeAndNil(dsp_aux1);
        FreeAndNil(ds_aux1);

        FreeAndNil(sql_aux2);
        FreeAndNil(cds_aux2);
        FreeAndNil(dsp_aux2);
        FreeAndNil(ds_aux2);
  end;
end;

procedure TDTComparer.ComparaTriggers(vOrigem, vDestino: string);
var
xTrigger,IniciaTrigger,Triggertipo,NovaTrigger,TipoTrigger:string;
TrsAB: TFDDBXTransactionDesc;
idtrans:Integer;
NomeRelacao:string;
begin
      if Assigned(fOnStatus) then
       fOnStatus('Atualizando Triggers do Banco de Dados: ' + vOrigem , FTotTabelas, FPosicao);

       with ConexaoExt.Params do
       begin
         Clear;
         Add('DriverID=FB');
         Add('Server='    + FServer);
         Add('Database='  + FBancoMaster);
         Add('User_Name=' + FUserNameBanco);
         Add('Password='  + FSenhaBanco);
         Add('Port='      + FPorta);
       end;
       ConexaoExt.Open;

       with Conexao.Params do
       begin
         Clear;
         Add('DriverID=FB');
         Add('Server='    + FServer);
         Add('Database='  + FBancoCliente);
         Add('User_Name=' + FUserNameBanco);
         Add('Password='  + FSenhaBanco);
         Add('Port='      + FPorta);
       end;
       Conexao.Open;

       application.ProcessMessages;

       sql_aux1                      := TFDQuery.Create(nil);
       sql_aux2                      := TFDQuery.Create(nil);

       cds_aux1                      := TClientDataSet.Create(nil);
       cds_aux2                      := TClientDataSet.Create(nil);

       dsp_aux1                      := TProvider.Create(nil);
       dsp_aux2                      := TProvider.Create(nil);

       ds_aux1                       := TDataSource.Create(nil);
       ds_aux2                       := TDataSource.Create(nil);

       sql_aux1.Connection           := ConexaoExt;
       dsp_aux1.DataSet              := sql_aux1;
       cds_aux1.SetProvider(dsp_aux1);
       ds_aux1.DataSet               := cds_aux1;
       dsp_aux1.Options              := [poAllowCommandText];

       sql_aux2.Connection           := Conexao;
       dsp_aux2.DataSet              := sql_aux2;
       cds_aux2.SetProvider(dsp_aux2);
       ds_aux2.DataSet               := cds_aux2;
       dsp_aux2.Options              := [poAllowCommandText];

       cds_aux1.close;
       sql_aux1.commandText := ' SELECT ' +
                               ' RDB$TRIGGER_NAME, ' +
                               ' RDB$RELATION_NAME, ' +
                               ' RDB$TRIGGER_SEQUENCE, ' +
                               ' RDB$TRIGGER_TYPE, ' +
                               ' RDB$TRIGGER_SOURCE, ' +
                               ' RDB$TRIGGER_BLR, ' +
                               ' RDB$DESCRIPTION, ' +
                               ' RDB$TRIGGER_INACTIVE, ' +
                               ' RDB$SYSTEM_FLAG, ' +
                               ' RDB$FLAGS, ' +
                               ' RDB$VALID_BLR, ' +
                               ' RDB$DEBUG_INFO ' +
                               ' FROM ' +
                               ' RDB$TRIGGERS ';
       cds_aux1.Open;

       idtrans := 0;
       while not cds_aux1.Eof do
       begin
          try
              Inc(idtrans);
              TrsAB.TransactionID  := idtrans;
              TrsAB.IsolationLevel := xiReadCommitted;
              Conexao.StartTransaction(TrsAB);
              TipoTrigger   := cds_aux1.FieldByName('RDB$TRIGGER_TYPE').AsString;
              NomeRelacao   := cds_aux1.FieldByName('RDB$RELATION_NAME').AsString;

              if Assigned(fOnStatus) then
              fOnStatus('Atualizando Triggers do Banco de Dados: ' + cds_aux1.FieldByName('RDB$TRIGGER_NAME').AsString , FTotTabelas, FPosicao);

              IniciaTrigger := ' ALTER TRIGGER ' + cds_aux1.FieldByName('RDB$TRIGGER_NAME').AsString;


              if TipoTrigger='1' then
              begin
                    Triggertipo := ' ACTIVE BEFORE INSERT ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='2' then
              begin
                    Triggertipo := ' ACTIVE AFTER INSERT ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='3' then
              begin
                    Triggertipo := ' ACTIVE BEFORE UPDATE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='4' then
              begin
                    Triggertipo := ' ACTIVE AFTER UPDATE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='5' then
              begin
                    Triggertipo := ' ACTIVE BEFORE DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='6' then
              begin
                    Triggertipo := ' ACTIVE AFTER DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='113' then
              begin
                    Triggertipo := ' ACTIVE BEFORE INSERT OR UPDATE OR DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='114' then
              begin
                    Triggertipo := ' ACTIVE AFTER INSERT OR UPDATE OR DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='17' then
              begin
                    Triggertipo := ' ACTIVE BERFORE UPDATE OR DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='18' then
              begin
                    Triggertipo := ' ACTIVE AFTER UPDATE OR DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='25' then
              begin
                    Triggertipo := ' ACTIVE BEFORE INSERT OR DELETE ' +
                                   ' POSITION 0 ';

              end else if TipoTrigger='26' then
              begin
                    Triggertipo := ' ACTIVE AFTER INSERT OR DELETE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='27' then
              begin
                    Triggertipo := ' ACTIVE BEFORE INSERT OR UPDATE ' +
                                   ' POSITION 0 ';
              end else if TipoTrigger='28' then
              begin
                    Triggertipo := ' ACTIVE AFTER INSERT OR UPDATE ' +
                                   ' POSITION 0 ';
              end;
              xTrigger      := cds_aux1.FieldByName('RDB$TRIGGER_SOURCE').AsString;

              NovaTrigger   :=  IniciaTrigger + Triggertipo + xTrigger;

              if Length(xTrigger)>0 then
              Conexao.ExecSQL(NovaTrigger);
              Conexao.Commit(TrsAB);
          except on e:Exception do
          begin

               if Pos('be changed',e.Message)<>0 then
               begin
               try
                    IniciaTrigger := ' CREATE TRIGGER ' + cds_aux1.FieldByName('RDB$TRIGGER_NAME').AsString + ' FOR ' + NomeRelacao + ' ';
                    if TipoTrigger='1' then
                    begin
                          Triggertipo := ' ACTIVE BEFORE INSERT ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='2' then
                    begin
                          Triggertipo := ' ACTIVE AFTER INSERT ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='3' then
                    begin
                          Triggertipo := ' ACTIVE BEFORE UPDATE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='4' then
                    begin
                          Triggertipo := ' ACTIVE AFTER UPDATE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='5' then
                    begin
                          Triggertipo := ' ACTIVE BEFORE DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='6' then
                    begin
                          Triggertipo := ' ACTIVE AFTER DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='113' then
                    begin
                          Triggertipo := ' ACTIVE BEFORE INSERT OR UPDATE OR DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='114' then
                    begin
                          Triggertipo := ' ACTIVE AFTER INSERT OR UPDATE OR DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='17' then
                    begin
                          Triggertipo := ' ACTIVE BERFORE UPDATE OR DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='18' then
                    begin
                          Triggertipo := ' ACTIVE AFTER UPDATE OR DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='25' then
                    begin
                          Triggertipo := ' ACTIVE BEFORE INSERT OR DELETE ' +
                                         ' POSITION 0 ';

                    end else if TipoTrigger='26' then
                    begin
                          Triggertipo := ' ACTIVE AFTER INSERT OR DELETE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='27' then
                    begin
                          Triggertipo := ' ACTIVE BEFORE INSERT OR UPDATE ' +
                                         ' POSITION 0 ';
                    end else if TipoTrigger='28' then
                    begin
                          Triggertipo := ' ACTIVE AFTER INSERT OR UPDATE ' +
                                         ' POSITION 0 ';
                    end;
                    xTrigger      := cds_aux1.FieldByName('RDB$TRIGGER_SOURCE').AsString;

                    NovaTrigger   :=  IniciaTrigger + Triggertipo + xTrigger;

                    if Length(xTrigger)>0 then
                    Conexao.ExecSQL(NovaTrigger);
                    Conexao.Commit(TrsAB);
                 except
                 end;
               end else begin
                   Conexao.RollBack(TrsAB);
               end;
          end;

          end;

          cds_aux1.Next;
       end;
       cds_aux1.Close;

       FreeAndNil(sql_aux1);
       FreeAndNil(cds_aux1);
       FreeAndNil(dsp_aux1);
       FreeAndNil(ds_aux1);

       Conexao.Connected    := false;
       ConexaoExt.Connected := false;
end;

procedure TDTComparer.ComparaIndices(vOrigem, vDestino: string);
var
  QryField,QryGrava,QryIndiceLoc : TFDQuery;
  Texto : String;
  idtrans:integer;
begin
    if Assigned(fOnStatus) then
       fOnStatus('Atualizando Índices do Banco de Dados: ' + vOrigem , FTotTabelas, FPosicao);

   application.ProcessMessages;
   idtrans := 0;
   try
         try
             QryField  := TFDQuery.Create(nil);
             QryField.Connection  := ConexaoExt;

             QryGrava := TFDQuery.Create(nil);
             QryGrava.Connection := Conexao;

             QryIndiceLoc := TFDQuery.Create(nil);
             QryIndiceLoc.Connection := Conexao;

             QryField.SQL.Text := 'SELECT RDB$INDEX_SEGMENTS.RDB$INDEX_NAME AS INDEX_NAME,RDB$INDEX_SEGMENTS.RDB$FIELD_NAME AS FIELD_NAME,RDB$INDICES.RDB$RELATION_NAME AS TABELA '+
                                  'FROM RDB$INDEX_SEGMENTS INNER JOIN RDB$INDICES ON (RDB$INDEX_SEGMENTS.RDB$INDEX_NAME = RDB$INDICES.RDB$INDEX_NAME) '+
                                  'WHERE RDB$INDICES.RDB$RELATION_NAME = :tabela ';
             QryField.ParamByName('tabela').AsString   := vOrigem;
             QryField.Open();
             while not QryField.Eof do
             begin
                 QryIndiceLoc.SQL.Text := 'SELECT count(*) AS TOTAL, RDB$INDEX_SEGMENTS.RDB$INDEX_NAME AS INDEX_NAME,RDB$INDEX_SEGMENTS.RDB$FIELD_NAME AS FIELD_NAME,RDB$INDICES.RDB$RELATION_NAME AS TABELA '+
                                          'FROM RDB$INDEX_SEGMENTS INNER JOIN RDB$INDICES ON (RDB$INDEX_SEGMENTS.RDB$INDEX_NAME = RDB$INDICES.RDB$INDEX_NAME) '+
                                          'WHERE RDB$INDICES.RDB$RELATION_NAME = :tabela AND  RDB$FIELD_NAME = :generico GROUP BY RDB$INDEX_SEGMENTS.RDB$INDEX_NAME ,RDB$INDEX_SEGMENTS.RDB$FIELD_NAME ,RDB$INDICES.RDB$RELATION_NAME';
                 QryIndiceLoc.ParamByName('tabela').AsString   := vOrigem;
                 QryIndiceLoc.ParamByName('generico').AsString := QryField.FieldByName('FIELD_NAME').AsString;
                 QryIndiceLoc.Open();

                 if  QryIndiceLoc.FieldByName('TOTAL').AsInteger=0 then
                 begin
                     idtrans  :=  1;
                     Texto    := 'CREATE INDEX ' + QryField.FieldByName('INDEX_NAME').AsString + ' ON ' + vDestino  + '(' + QryField.FieldByName('FIELD_NAME').AsString + ')';
                     QryGrava.SQL.Text := Texto;
                     QryGrava.ExecSQL;
                 end;
                 QryIndiceLoc.Close;
                 QryField.Next;
             end;
             if idtrans = 1 then
             begin
                 Conexao.Commit;
             end;
         except
             Conexao.Rollback;
         end;
   finally
       QryField.Close;
       QryField.Free;
       QryGrava.Free;
       QryIndiceLoc.Free;
   end;

end;

constructor TDTComparer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // CRIA CONEXAO COM BASE DE DADOS
  ConexaoExt                    := TFDConnection.Create(nil);
  Conexao                       := TFDConnection.Create(nil);

  FDPhysFBDriverLink1           := TFDPhysFBDriverLink.Create(nil);
  FDPhysFBDriverLink1.VendorLib := FCaminhoVendorLib;
  FDGUIxWaitCursor1             := TFDGUIxWaitCursor.Create(nil);

  FSenhaBanco                   := 'masterkey';
  FUserNameBanco                := 'SYSDBA';
  FPorta                        := '3050';
  FServer                       := 'localhost';
  FScriptsExecutados            := 0;
end;

destructor TDTComparer.Destroy;
begin
      FreeAndNil(ConexaoExt);
      FreeAndNil(Conexao);

      FreeAndNil(FDPhysFBDriverLink1);
      FreeAndNil(FDGUIxWaitCursor1);

      inherited Destroy;
end;

procedure TDTComparer.ExecutaScript;
var
i  : Integer;
Quebra : TStringList;
begin
    FScriptsExecutados := 0;
    Quebra := TStringList.Create;
    Quebra.Clear;

    ExtractStrings([';'],[ ],Pchar( FScript ),Quebra);

    if quebra.Count>1 then
    begin
          for I := 0 to Pred( Quebra.Count ) do
          begin
              Try
                  Try
                                          
                     if Assigned(fOnStatus) then
                      fOnStatus('Executando Scripts: ' + ( i + 1).ToString , Quebra.Count, i);
                      application.ProcessMessages;
      
                     Conexao.ExecSQL( Quebra[i] );
                     Inc( FScriptsExecutados );
                  Except
                  End;
              finally
              End;     
          end;
    end;
    Quebra.Free;
end;

procedure TDTComparer.SetBancoCliente(const Value: string);
begin
     FBancoCliente := Value;
end;

procedure TDTComparer.SetBancoMaster(const Value: string);
begin
     FBancoMaster := Value;
end;

procedure TDTComparer.SetCaminhoVendorLib(const Value: string);
begin
     FCaminhoVendorLib := Value;
end;

procedure TDTComparer.SetComparaIndices(const Value: Boolean);
begin
  FComparaIndice := Value;
end;

procedure TDTComparer.SetComparaTriggers(const Value: Boolean);
begin
     FComparaTriggers := Value;
end;

procedure TDTComparer.SetPorta(const Value: string);
begin
     FPorta := value;
end;

procedure TDTComparer.SetScript(const Value: string);
begin
  FScript := Value;
end;

procedure TDTComparer.SetScriptsExecutados(const Value: Integer);
begin
  FScriptsExecutados := Value;
end;

procedure TDTComparer.SetSenhaBanco(const Value: string);
begin
     FSenhaBanco := value;
end;

procedure TDTComparer.SetServer(const Value: string);
begin
     FServer := value;
end;

procedure TDTComparer.SetUserNameBanco(const Value: string);
begin
     FUserNameBanco := value;
end;

procedure TDTComparer.SetValoresDefault(const Value: boolean);
begin
     FValoresDefault := Value;
end;

function TDTComparer.verPrimaryKey(Tabela, Campo: string;Conexao:TFDConnection): Boolean;
var
Qry1:TFDQuery;
begin
       Qry1             := TFDQuery.Create(nil);
       Qry1.Connection  := Conexao;

       Qry1.SQL.Text := ' SELECT RDB$FIELD_NAME ' +
                        ' FROM ' +
                        ' RDB$RELATION_CONSTRAINTS C, ' +
                        ' RDB$INDEX_SEGMENTS S ' +
                        ' WHERE ' +
                        ' C.RDB$RELATION_NAME = ' + QuotedStr( Tabela ) +' AND ' +
                        ' C.RDB$CONSTRAINT_TYPE = ''PRIMARY KEY'' AND RDB$FIELD_NAME= ' + QuotedStr( Campo ) +'  AND ' +
                        ' S.RDB$INDEX_NAME = C.RDB$INDEX_NAME ' +
                        ' ORDER BY RDB$FIELD_POSITION ';
       Qry1.Open;
       if Qry1.FieldByName('RDB$FIELD_NAME').AsString <> '' then
       begin
            Result := True;
       END ELSE begin
            Result := False;
       end;
       Qry1.Close;
       Qry1.Free;
end;

end.
