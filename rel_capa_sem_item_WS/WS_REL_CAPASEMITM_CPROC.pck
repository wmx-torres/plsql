CREATE OR REPLACE PACKAGE WS_REL_CAPASEMITM_CPROC IS

  FUNCTION Parametros RETURN VARCHAR2;
  FUNCTION Nome RETURN VARCHAR2;
  FUNCTION Tipo RETURN VARCHAR2;
  FUNCTION Versao RETURN VARCHAR2;
  FUNCTION Descricao RETURN VARCHAR2;
  FUNCTION Modulo RETURN VARCHAR2;
  FUNCTION Classificacao RETURN VARCHAR2;
  FUNCTION Orientacao RETURN VARCHAR2;
  FUNCTION Executar(pEmpresa        VARCHAR2,
                    pEstab          VARCHAR2,
                    pPeriodoInicial DATE,
                    pPeriodoFinal   DATE
                    ) RETURN INTEGER;

END WS_REL_CAPASEMITM_CPROC;
/
CREATE OR REPLACE PACKAGE BODY WS_REL_CAPASEMITM_CPROC IS

  ------| Declaracao de Variaveis Publicas para Empresa, Estabelecimento e Usuario de Login  |-------------
  --mcod_empresa empresa.cod_empresa%TYPE;
  mcod_usuario usuario_empresa.cod_usuario%TYPE;
  co_action1 CONSTANT VARCHAR2(7) := 'TODOS';
  co_action2 CONSTANT VARCHAR2(7) := 'DATE';

  ------| FIM DA DECLARAC?O DAS FUNC?ES PARA FORMATAC?O DE VALOR |-------------
  FUNCTION Parametros RETURN VARCHAR2 IS
    pstr VARCHAR2(5000);
  BEGIN

    ------| Carregando Variaveis Publicas de LOGIN  |-------------
    -- mcod_empresa := LIB_PARAMETROS.RECUPERAR('EMPRESA');
    mcod_usuario := LIB_PARAMETROS.RECUPERAR('USUARIO');

    --------------| Carrega  Paramteros |----------------------

    ----------> CODIGO DA EMPRESA --
    LIB_PROC.add_param(pstr,
                       'Empresa',
                       'Varchar2',
                       'combobox',
                       'S',
                       co_action1,
                       NULL,
                       'select ''TODOS'',''TODOS'' from dual union ' ||
                       'SELECT cod_empresa, cod_empresa ||'' - ''|| razao_social FROM empresa ORDER BY 1');

    ----------> CODIGO DO ESTABELECIMENTO --
    Lib_Proc.Add_Param(Pstr,
                       'Estabelecimento',
                       'varchar2',
                       'combobox',
                       'S',
                       co_action1,
                       Null,
                       'select ''TODOS'',''TODOS'' from dual union ' ||
                       'select cod_empresa||''-''||cod_estab, cod_estab||'' - ''||razao_social||'' - ''||nome_fantasia from estabelecimento ORDER BY 1');

    ----------> DATA INICIAL --
    LIB_PROC.add_param(pstr,
                       'Periodo Inicial',
                       'Date',
                       'Textbox',
                       'S',
                       NULL,
                       co_action2, 'S');

    -----------> DATA FINAL --
    LIB_PROC.add_param(pstr, 'Periodo Final', 'Date', 'Textbox',
                       'S',
                       NULL,
                       co_action2, 'S');

    --------------| Fim da Carga dos Parametros  |-------------
    RETURN pstr;
  END;

  ----- Nome do Processo (ao lado do box)
  FUNCTION Nome RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatorio capa sem item - SAFX07/08/09'; 
  END;

  ----- ASSUNTO
  FUNCTION Tipo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'RELATORIOS';
  END;

  ----- Versao
  FUNCTION Versao RETURN VARCHAR2 IS
  BEGIN
    RETURN '1.0';
  END;

  ----- Descricao do processo
  FUNCTION Descricao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Relatorio capa sem item - SAFX07/08/09';
  END;

  ------ Nome do Modulo
  FUNCTION Modulo RETURN VARCHAR2 IS
  BEGIN
    RETURN 'FRAMEWORK';
  END;

  --UTILIZADO PARA CLASSIFICAC?O NO MASTERSAF
  FUNCTION Classificacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Obrigacoes';
  END;

  -- Orientacao do Papel
  FUNCTION Orientacao RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PORTRAIT';
  END;

  ------| PROCESSAMENTO PRINCIPAL  |-------------
  FUNCTION Executar(pEmpresa        VARCHAR2,
                    pEstab          VARCHAR2,
                    pPeriodoInicial DATE,
                    pPeriodoFinal   DATE) RETURN INTEGER IS

    -- DECLARACAO DE VARIAVEIS
    mproc_id               INTEGER;
    mdata_ini              DATE;
    mdata_fim              DATE;
    w_linha_arquivo        varchar2(2000);

    -- INICIO DO PROCESSO DE GERACAO DOS REGISTROS */
  BEGIN

    -- Cria Processo
    mproc_id := Lib_Proc.NEW('WS_REL_CAPASEMITM_CPROC', 48, 150);

    IF pPeriodoInicial > pPeriodoFinal THEN
      Lib_Proc.Add_Log('A Data Inicial e maior que a Data Final.', 0);
      Lib_Proc.CLOSE();
      RETURN Mproc_Id;

    END IF;

    ------| CRIA AS ABAS DO RELATORIO  |-------------
    lib_proc.Add_tipo(mproc_id, 2, 'RELATORIO_CAPA_SEMITEM.CSV', 2);

    mdata_ini    := pPeriodoInicial;
    mdata_fim    := pPeriodoFinal;

    -- cabecalho do Arquivo
    w_linha_arquivo := 'COD_EMPRESA;COD_ESTAB;DATA_FISCAL;MOVTO_E_S;NORM_DEV;COD_DOCTO;COD_FIS_JUR;NUM_DOCFIS;SERIE_DOCFIS;SUB_SERIE_DOCFIS;DATA_EMISSAO;COD_CLASS_DOC_FIS';
    LIB_PROC.add(w_linha_arquivo, 2);

    for c_1 in (Select x07.cod_empresa,
                       x07.cod_estab,
                       x07.data_fiscal,
                       x07.movto_e_s,
                       x07.norm_dev,
                       x07.ident_docto,
                       x04.cod_fis_jur,
                       x07.ident_fis_jur,
                       x2005.cod_docto,
                       x07.num_docfis,
                       x07.serie_docfis,
                       x07.sub_serie_docfis,
                       x07.data_emissao,
                       x07.cod_class_doc_fis
                  From X07_Docto_Fiscal   X07,
                       x04_pessoa_fis_jur x04,
                       x2005_tipo_docto   x2005
                 Where x07.ident_fis_jur = x04.ident_fis_jur
                   and x07.ident_docto = x2005.ident_docto
                   and X07.Cod_Empresa || X07.Cod_Estab || X07.Data_Fiscal ||
                       X07.Movto_e_s || X07.Ident_Fis_Jur || X07.Num_Docfis ||
                       X07.Serie_Docfis Not In
                       (Select x08.Cod_Empresa || x08.Cod_Estab ||
                               x08.Data_Fiscal || x08.Movto_e_s ||
                               x08.Ident_Fis_Jur || x08.Num_Docfis ||
                               x08.Serie_Docfis
                          From X08_Itens_Merc x08
                         Where x08.cod_empresa = x07.cod_empresa
                           and x08.Data_Fiscal Between  mdata_ini And mdata_fim )
                   And X07.Data_Fiscal Between mdata_ini And mdata_fim
                   and ( x07.Cod_Empresa || '-' || x07.Cod_Estab =  pEstab Or pEstab  = co_action1 )
                   and ( x07.Cod_Empresa =  pEmpresa Or pEmpresa = co_action1)
                   And x07.cod_class_doc_fis = '1') loop
      begin

        -----| IMPRIME LINHA-A-LINHA no .csv  |-------------
        w_linha_arquivo := c_1.cod_empresa || ';' || c_1.cod_estab || ';' ||
                           TO_CHAR(c_1.data_fiscal, co_action2) || ';' ||
                           c_1.movto_e_s || ';' || c_1.norm_dev || ';' ||
                           c_1.cod_docto || ';' || c_1.cod_fis_jur || ';' ||
                           c_1.num_docfis || ';' || c_1.serie_docfis || ';' ||
                           c_1.sub_serie_docfis || ';' ||
                           TO_CHAR(c_1.data_emissao, co_action2) || ';' ||
                           c_1.cod_class_doc_fis;
        LIB_PROC.add(w_linha_arquivo, 2);

      exception
        when others then
          LIB_PROC.add_log('ERRO DE GERACAO DO RELATORIO. Erro: ' ||
                           sqlerrm,
                           0);
      end;
    end loop;

    for c_2 in (Select x07.cod_empresa,
                       x07.cod_estab,
                       x07.data_fiscal,
                       x07.movto_e_s,
                       x07.norm_dev,
                       x07.ident_docto,
                       x04.cod_fis_jur,
                       x07.ident_fis_jur,
                       x2005.cod_docto,
                       x07.num_docfis,
                       x07.serie_docfis,
                       x07.sub_serie_docfis,
                       x07.data_emissao,
                       x07.cod_class_doc_fis
                  From X07_Docto_Fiscal   X07,
                       x04_pessoa_fis_jur x04,
                       x2005_tipo_docto   x2005
                 Where x07.ident_fis_jur = x04.ident_fis_jur
                   and x07.ident_docto = x2005.ident_docto
                   and X07.Cod_Empresa || X07.Cod_Estab || X07.Data_Fiscal ||
                       X07.Movto_e_s || X07.Ident_Fis_Jur || X07.Num_Docfis ||
                       X07.Serie_Docfis Not In
                       (Select x09.Cod_Empresa || x09.Cod_Estab ||
                               x09.Data_Fiscal || x09.Movto_e_s ||
                               x09.Ident_Fis_Jur || x09.Num_Docfis ||
                               x09.Serie_Docfis
                          From X09_Itens_Serv x09
                         Where x09.cod_empresa = x07.cod_empresa
                           and x09.Data_Fiscal Between mdata_ini And mdata_fim )
                   And X07.Data_Fiscal Between mdata_ini And mdata_fim
                   and ( x07.Cod_Empresa || '-' || x07.Cod_Estab =  Pestab Or Pestab = co_action1 )
                   and ( x07.Cod_Empresa =  pEmpresa Or pEmpresa = co_action1 )
                   And x07.cod_class_doc_fis = '2') loop
      begin

        -----| IMPRIME LINHA-A-LINHA no .csv  |-------------
        w_linha_arquivo :=  c_2.cod_empresa || ';' || c_2.cod_estab || ';' ||
                           TO_CHAR(c_2.data_fiscal, 'DD/MM/YYYY') || ';' ||
                           c_2.movto_e_s || ';' || c_2.norm_dev || ';' ||
                           c_2.cod_docto || ';' || c_2.cod_fis_jur || ';' ||
                           c_2.num_docfis || ';' || c_2.serie_docfis || ';' ||
                           c_2.sub_serie_docfis || ';' ||
                           TO_CHAR(c_2.data_emissao, 'DD/MM/YYYY') || ';' ||
                           c_2.cod_class_doc_fis;
        LIB_PROC.add(w_linha_arquivo, 2);

      exception
        when others then
          LIB_PROC.add_log('ERRO DE GERACAO DO RELATORIO. Erro: ' ||
                           sqlerrm,
                           0);
      end;
    end loop;

    --FIM DO RELATORIO
    --fecha o processo
    lib_proc.CLOSE;
    COMMIT;
    RETURN mproc_id;

  END;
END WS_REL_CAPASEMITM_CPROC;
/
