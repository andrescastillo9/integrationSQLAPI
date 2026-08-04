--example how to sing up a new interface
SET DEFINE OFF;
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('MOD011',to_date('15-APR-24','DD-MON-RR'),'INTERFAZ','INTEGRACION','MOD011','Recepción notas por componente','http://172.31.2.95:8081/mod011_qa/rest/execute/','POST','BATCH','IZTZM11','MOODLE',null,'Basic SVpUX1NBUDpORU9SSVNfTU9EMDEx','PUB','text/plain',null,'text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IHR007',to_date('28-JUL-22','DD-MON-RR'),'INTERFAZ','INTEGRACION','IHR007','Pagos a docentes','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/pagoprogramacion','POST','BATCH','IZTZM10','BANNER',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','text/plain','IZT_INTERFACE_SAP_IHR_DOC.ihr007_process_response','text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('PLACETOPAY',to_date('05-NOV-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','PLACE TO PAY','proceso de SONDA','https://secure.placetopay.ec/redirection/api/session/','POST','BATCH','IZTZM07','SONDA',null,null,'CON','application/json',null,'application/json');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('ILG001',to_date('02-JUL-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','ILG001','consulta directorio activo','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/ConsultaUserName','GET','BATCH','IZTZM01','LEGADO_PUCE',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','text/plain','IZT_INTERFACE_LEGACY_ILG.ilg001_registro','text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('MOD003',to_date('27-AUG-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','MOD003','Moodle 3: Recepción de notas de exámenes de admisión','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/Cargue','POST','BATCH','IZTZM03','LEGADO PUCE',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','application/json','IZT_INTERFACE_LEGACY_MOD.mod003_registro','application/json');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IHR001',to_date('29-AUG-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','IHR001','Creación y modificación de docentes y administrativos','http://172.31.2.95:8081/ihr001_qa/rest/execute/','POST','BATCH','IZTZM05','SAP',null,'Basic SVRaX1NBUDpQT0xPX0lIUjAwMQ==','PUB','text/plain',null,'text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IFI005_A',to_date('28-AUG-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','IFI005 CREACION','Creación Bussiness Partner','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/deudor','POST','BATCH','IZTZM04','BANNER',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','text/plain','IZT_INTERFACE_SAP_IFI.ifi005_process_response','text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IFI001',to_date('04-JUL-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','IFI001','Envío documento financiero','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/docfinanciero/','POST','BATCH','IZTZM02','BANNER',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','text/plain','IZT_INTERFACE_SAP_IFI.ifi001_process_response','text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IFI004',to_date('10-OCT-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','IFI004','Registro estado documento electrónico','http://172.31.2.95:8081/ifi004_qa_df/rest/execute/','POST','BATCH','IZTZM06','SAP',null,'Basic SVpUX1NBUDpESUVHT0ZPTlNFQ0FfSUZJMDA0','PUB','text/plain',null,'text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IFI006',to_date('17-DEC-19','DD-MON-RR'),'INTERFAZ','INTEGRACION','IFI006','Envío devoluciones a Banner','http://172.31.2.95:8081/ifi006_qa/rest/execute/','POST','BATCH','IZTZM08','SAP',null,'Basic SVpUX1NBUDpORU9SSVNfSUZJMDA2','PUB','text/plain',null,'text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IFI005_B',to_date('09-NOV-21','DD-MON-RR'),'INTERFAZ','INTEGRACION','IFI005 ACTUALIZACION','Actualización Bussiness Partner','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/deudor/','PUT','BATCH','IZTZM09','BANNER',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','text/plain','IZT_INTERFACE_SAP_IFI.ifi005_update_response','text/plain');
Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT) values ('IFI011',to_date('06-JUL-26','DD-MON-RR'),'INTERFAZ','INTEGRACION','IFI011 VAUCHER','Actualiación Vaucher','http://pucesappoq1.puce.edu.ec:50000/RESTAdapter/ifi011/actualizavoucher','POST','BATCH','IZTZM12','BANNER',null,'Basic UE9RX1dTOkluaWNpbzAx','CON','text/plain','IZT_INTERFACE_SAP_IFI.ifi005_process_response','text/plain');

--example how to implement a new message interface
PROCEDURE pr_envia_interfaz_sap (
        p_pidm        IN NUMBER,
        p_tran_number IN NUMBER,
        p_zuonr       IN VARCHAR2
    ) AS
        -- Variables para almacenar los resultados de las consultas
        v_detail_code      tbraccd.tbraccd_detail_code%TYPE;
        v_sap_docnum       varchar2(30);
        v_receipt_num      tzrfact.tzrfact_receipt_num%TYPE; 
        v_sri_docnum       tzrfact.tzrfact_sri_docnum%TYPE;
        v_buzei            izlg01p.izlg01p_buzei%TYPE;
        v_numproc          izlg01p.izlg01p_numproc%TYPE;
        v_bukrs            izlg01h.izlg01h_bukrs%TYPE;
        v_gjahr            izlg01h.izlg01h_gjahr%TYPE;

        -- Variables para el control de la interfaz
        v_procid           VARCHAR2(100); 
        v_recid            VARCHAR2(100); 
        v_json             CLOB;

        -- Nuevas variables para el cálculo de SDE Data
        v_rowid            ROWID;
        v_sde_return       VARCHAR2(4000);
    BEGIN

        -- =====================================================================
        -- PASO 1: Obtener el código de detalle correspondiente
        -- =====================================================================
        BEGIN
            SELECT UNIQUE tbraccd_detail_code
              INTO v_detail_code
              FROM tbraccd
             WHERE tbraccd_pidm = p_pidm
               AND tbraccd_tran_number = p_tran_number;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(-20001, 'No se encontró código de detalle para PIDM: ' || p_pidm || ' y Transacción: ' || p_tran_number);
        END;

        -- =====================================================================
        -- PASO 2: Obtener documentos SAP y SRI, y validar contabilización
        -- =====================================================================
        BEGIN
            SELECT tzrfact_receipt_num,tzrfact_sap_docnum, tzrfact_sri_docnum
              INTO v_receipt_num,v_sap_docnum, v_sri_docnum
              FROM tzrfact
             WHERE tzrfact_pidm = TO_CHAR(p_pidm)
               AND tzrfact_det_code_doc = v_detail_code
               AND tzrfact_tran_num = p_tran_number
               and TZRFACT_FACT_CANCEL_IND is null;

            -- Validación crítica: Si SAP_DOCNUM es NULL, se detiene el proceso
            IF v_sap_docnum IS NULL THEN
                raise_application_error(-20002, 'El documento no ha sido contabilizado en SAP. Proceso de interfaz cancelado.');
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(-20003, 'No se encontraron registros en tzrfact para los datos provistos.');
        END;

        -- =====================================================================
        -- PASO 3: Calcular Posición (BUZEI) y Número de Proceso (NUMPROC)
        -- =====================================================================
        BEGIN
            SELECT izlg01p_buzei, izlg01p_numproc
              INTO v_buzei, v_numproc
              FROM izlg01p
             WHERE izlg01p_sgtxt = v_sri_docnum
               AND izlg01p_xref1 = v_detail_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  SELECT izlg01p_buzei, izlg01p_numproc
                  INTO v_buzei, v_numproc
                  FROM izlg01p
                  WHERE izlg01p_sgtxt = v_receipt_num
                  AND izlg01p_xref1 = v_detail_code;

                  --select IZLG01R_CODSAP
                  select IZLG01R_NUM_DOCUMENTO
                  INTO v_sap_docnum
                  from IZLG01R
                  WHERE izlg01r_numproc = v_numproc
                  and ROWNUM = 1;
                --raise_application_error(-20004, 'No se encontró posición en IZLG01P usando SRI_DOCNUM: ' || v_sri_docnum);
            WHEN TOO_MANY_ROWS THEN
                SELECT izlg01p_buzei, izlg01p_numproc
                  INTO v_buzei, v_numproc
                  FROM (SELECT izlg01p_buzei, izlg01p_numproc FROM izlg01p 
                         WHERE izlg01p_sgtxt = v_sri_docnum AND izlg01p_xref1 = v_detail_code)
                 WHERE ROWNUM = 1;
        END;

        -- =====================================================================
        -- PASO 4: Calcular BUKRS y GJAHR con el número de proceso
        -- =====================================================================
        BEGIN
            SELECT izlg01h_bukrs, izlg01h_gjahr
              INTO v_bukrs, v_gjahr
              FROM izlg01h
             WHERE izlg01h_numproc = v_numproc;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(-20005, 'No se encontraron datos de cabecera en IZLG01H para NUMPROC: ' || v_numproc);
        END;

        -- =====================================================================
        -- PASO 5: Construcción de la TRAMA JSON Dinámica
        -- =====================================================================
        v_json := JSON_OBJECT(
                    'BUKRS' VALUE v_bukrs,
                    'BELNR' VALUE v_sap_docnum,
                    'GJAHR' VALUE v_gjahr,
                    'BUZEI' VALUE TO_CHAR(v_buzei),
                    'ZUONR' VALUE p_zuonr
                  );

        -- =====================================================================
        -- PASO 6: Orquestación y Envío de la Interfaz
        -- =====================================================================
        v_procid := ztz_async_proc.ps_startProcess('IFI011');
        v_recid  := ztz_async_proc.ps_setDataRequest(v_procid, v_json);
        ztz_async_proc.ps_finishProcess(v_procid);
        ztz_async_proc.ps_beginRequest(v_procid);

        BEGIN
            SELECT r_id
              INTO v_rowid
              FROM (
                  SELECT ROWID AS r_id
                    FROM tbracdt
                   WHERE tbracdt_pidm        = p_pidm
                     AND tbracdt_tran_number = p_tran_number
                     AND tbracdt_text        = p_zuonr
                   ORDER BY tbracdt_activity_date DESC -- Trae el más reciente si hubiera duplicados
              )
             WHERE ROWNUM = 1;

            p_create_sde_data (  
            p_table    => 'TBRACDT',
            p_column   => 'FECHA_ENVIO_SAP',
            p_rowid    => v_rowid,             -- El ROWID calculado en el paso 5
            p_pk       => NULL,
            p_value    => sys.anydata.convertDate(SYSDATE), -- Conversión nativa a sys.anydata
            p_datatype => 'DATE',
            p_validate => 'N',
            v_return   => v_sde_return
        );

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                raise_application_error(-20006, 'No se pudo calcular el ROWID en tbracdt para PIDM: ' || p_pidm || ', Tran: ' || p_tran_number || ' y Texto: ' || p_zuonr);
        END;


    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20999, 'Error general en IZT_INTERFACE_IFI11_VOUCHER.pr_envia_interfaz_sap: ' || SQLERRM);
    END pr_envia_interfaz_sap;
    
    --ejemplo implementación inbound mediante ps_setDataForPublishIfi
     PROCEDURE p_ifi006_registro (
        json_entrada   IN             CLOB,
        p_outputdata   OUT            CLOB
    ) AS
        id_banner           varchar2(64);
        doc_number          varchar2(64);
        ncre_sri            varchar2(64);
        valor               varchar2(64);
        fecha_transac       varchar2(64);
        v_error             varchar2(1) := 'N';
        detail_desc         varchar2(64);
        cod_detalle         varchar2(32);
        ---------------------------------------
        pidm                number;
        ---------------------------------------
        lv_out_stat            varchar2(4000);
		lv_anul_validate	   varchar2(1);
		lv_cancel_validate	   varchar2(1);
		lv_acdt_validate	   varchar2(1);
		lv_sum_tbraccd		   tbraccd.tbraccd_amount%type;
		lv_sum_value_tram	   tbraccd.tbraccd_amount%type;
		lv_sum_charge		   tbraccd.tbraccd_amount%type;
		lv_sum_pay			   tbraccd.tbraccd_amount%type;
        lv_sum_nc              tbraccd.tbraccd_amount%type;
		---------------------------------------
        cursor searchCursor is
            select i.*
            from tzrfact i
            where 1=1
                --and i.tzrfact_id = id_banner
                and i.tzrfact_sri_docnum = doc_number
                and i.tzrfact_crednt_sricode = ncre_sri
            fetch first 1 rows only;
        ---------------------------------------
        cursor tranCursor is
            select tbraccd_tran_number from tbraccd, spriden
            where 1=1
                and spriden_id = id_banner
                and spriden_pidm = tbraccd_pidm
            order by tbraccd_tran_number desc
            fetch first 1 rows only;
        ---------------------------------------
		--acastillo ajuste control devolucion
		cursor c_anul_validate is
		select unique 'Y'
		from tzrfact
		where tzrfact_crednt_sricode = ncre_sri
		and   tzrfact_sdoc_code = 'BA';
		--and   tzrfact_pidm = pidm;

		cursor c_cancel_validate is
		select unique 'Y'
		from tzrfact
		where tzrfact_crednt_sricode = ncre_sri
		--and   tzrfact_pidm = pidm
		and   tzrfact_nc_cancel_ind ='Y';

		cursor c_acdt_validate is
		select unique 'Y'
		from  tbracdt
		where tbracdt_text = ncre_sri
		and   tbracdt_pidm = pidm;

		cursor c_sum_tbraccd is
		select sum (tbraccd_amount)
		from tbraccd
		where tbraccd_tran_number in (select tbracdt_tran_number
										from tbracdt
										where tbracdt_text = ncre_sri
										and tbracdt_pidm = pidm
										)
		and tbraccd_pidm = pidm;

		cursor c_sum_charge is
		select sum(tzrfact_amnt_trans)
		from tzrfact, tbbdetc
		where tzrfact_det_code_doc = tbbdetc_detail_code
		and   tzrfact_crednt_sricode = ncre_sri--'001-125-000020031'
		and   tzrfact_sdoc_code='BN'
		and   tbbdetc_type_ind='C';

		cursor c_sum_pay is
		select sum(tzrfact_amnt_trans)
		from tzrfact, tbbdetc
		where tzrfact_det_code_doc = tbbdetc_detail_code
		and   tzrfact_crednt_sricode = ncre_sri--'001-125-000020031'
		and   tzrfact_sdoc_code='BN'
		and   tbbdetc_type_ind='P';
		---------------------------------------

        globalObj                  json;
        rootObj                    json;
        tzRecord                   tzrfact%rowtype;
        lastTranNumber             number(9);
        p_row_id                   rowid;
        --Salida
        mensaje_error              clob := ' ';
        response_obj               json;
        largeresponse              clob := ' ';
	    v_recid                     number;

    BEGIN
        -------------------------------------------------------------------
        globalObj := json(json_entrada);
        rootObj := json(globalObj.get('devolucion'));
        -------------------------------------------------------------------
        response_obj := json();
        mensaje_error := '';
		ncre_sri := null;
		lv_anul_validate := null;
		lv_cancel_validate := null;
		lv_acdt_validate := null;
		lv_sum_tbraccd   := 0;
		lv_sum_value_tram := 0;
		lv_sum_charge :=0;
		lv_sum_pay :=0;

        -------------------------------------------------------------------
        id_banner := izt_interface_util.validate_field(rootObj, 'id_banner');
        if id_banner = '' or id_banner is null then
            mensaje_error := mensaje_error || 'El campo "id_banner" es obligatorio ';
            v_error := 'Y';
        end if;

        doc_number := izt_interface_util.validate_field(rootObj, 'num_documento');
        if doc_number = '' or doc_number is null then
            mensaje_error := mensaje_error || 'El campo "num_documento" es obligatorio ';
            v_error := 'Y';
        end if;

        ncre_sri := izt_interface_util.validate_field(rootObj, 'ncred_sri');
        if ncre_sri = '' or ncre_sri is null then
            mensaje_error := mensaje_error || 'El campo "ncre_sri" es obligatorio ';
            v_error := 'Y';
			else
				open c_anul_validate;
				fetch c_anul_validate into lv_anul_validate;
				close c_anul_validate;

				open c_cancel_validate;
				fetch c_cancel_validate into lv_cancel_validate;
				close c_cancel_validate;

				if lv_anul_validate = 'Y' then
					v_error := 'Y';
					mensaje_error := mensaje_error || 'Se emitió una nota de crédito Total ';

				end if;
                if  lv_cancel_validate = 'Y' THEN
						mensaje_error := mensaje_error || 'La nota crédito fue anulada, no aplica devolución ';
						v_error := 'Y';
				end if;
        end if;

        valor := izt_interface_util.validate_field(rootObj, 'valor');
        if valor = '' or valor is null then
            mensaje_error := mensaje_error || 'El campo "valor" es obligatorio ';
            v_error := 'Y';
        elsif izt_interface_util.is_number(valor) <> 1 then
            mensaje_error := mensaje_error || 'El campo "valor" debe ser numerico ';
            v_error := 'Y';
        end if;

        fecha_transac := izt_interface_util.validate_field(rootObj, 'fecha_transac');
        if fecha_transac = '' or fecha_transac is null then
            mensaje_error := mensaje_error || 'El campo "fecha_transac" es obligatorio ';
            v_error := 'Y';
        elsif izt_interface_util.is_date(fecha_transac, 'DD/MM/YYYY') <> 1 then
            mensaje_error := mensaje_error || 'El campo "fecha_transacc" debe ser una fecha valida en formato "DD/MM/YYYY" ';
            v_error := 'Y';

        end if;
		-----------acastillo ajuste valida nota credito-----------------------
		select distinct tzrfact_pidm into pidm from tzrfact where tzrfact_sri_docnum = doc_number and tzrfact_crednt_sricode = ncre_sri;
		if sql%notfound then
			response_obj.put('TIPO_MENSAJE', 'E');
			response_obj.put('MENSAJE', 'No existe registro de persona con id "' || id_banner || '"');
			v_error := 'Y';
		end if;
	if v_error = 'N' then
		open c_acdt_validate;
		fetch c_acdt_validate into lv_acdt_validate;
		close c_acdt_validate;

        open c_sum_tbraccd;
        fetch c_sum_tbraccd into lv_sum_tbraccd;
		if lv_sum_tbraccd is null then
			lv_sum_tbraccd := 0;
		end if;
        close c_sum_tbraccd;
        dbms_output.put_line('lv_sum_tbraccd '||lv_sum_tbraccd);

        open c_sum_charge;
        fetch c_sum_charge into lv_sum_charge;
		if lv_sum_charge is null then
			lv_sum_charge := 0;
		end if;
        close c_sum_charge;
        dbms_output.put_line('lv_sum_charge '||lv_sum_charge);

        open c_sum_pay;
        fetch c_sum_pay into lv_sum_pay;
		if lv_sum_pay is null then
			lv_sum_pay := 0;
		end if;
		close c_sum_pay;

		dbms_output.put_line('lv_sum_pay '||lv_sum_pay);
        dbms_output.put_line('lv_acdt_validate '||lv_acdt_validate);

		if lv_acdt_validate = 'Y' then

			lv_sum_value_tram := lv_sum_tbraccd + valor;
            dbms_output.put_line('lv_sum_value_tram = lv_sum_tbraccd + valor '||lv_sum_value_tram);
            dbms_output.put_line('valor '||valor);

			lv_sum_nc := lv_sum_charge - lv_sum_pay;
            dbms_output.put_line('lv_sum_nc '||lv_sum_nc);
			if lv_sum_nc < 0 then
				if lv_sum_nc * -1 < lv_sum_value_tram then
					mensaje_error := mensaje_error || 'No se puede grabar, supera el valor de la nota crédito';
					v_error := 'Y';
				dbms_output.put_line('mensaje_error '||mensaje_error);

				end if;
			else
				mensaje_error := mensaje_error || 'El estudiante no tiene saldo a favor a devolver';
				v_error := 'Y';
				dbms_output.put_line('mensaje_error '||mensaje_error);

			end if;

		else
            dbms_output.put_line('Registro no encontrado en tbracdt '||lv_acdt_validate);

			lv_sum_value_tram := valor;
            dbms_output.put_line('valor '||valor);

            dbms_output.put_line('lv_sum_value_tram '||lv_sum_value_tram);
            dbms_output.put_line('lv_sum_charge '||lv_sum_charge);
            dbms_output.put_line('lv_sum_pay '||lv_sum_pay);

			lv_sum_nc := lv_sum_charge - lv_sum_pay;
            dbms_output.put_line('lv_sum_nc '||lv_sum_nc);
			if lv_sum_nc < 0 then
				lv_sum_nc := lv_sum_nc * -1;
			end if;
			if lv_sum_value_tram > lv_sum_nc then
				mensaje_error := mensaje_error || 'El valor supera el monto de la nota crédito';
				v_error := 'Y';
				dbms_output.put_line('mensaje_error '||mensaje_error);

			end if;
		end if;
        -------------------------------------------------------------------
		tzRecord := null;
        --------------------------------------------------------------
		open searchCursor;
		fetch searchCursor into tzRecord;
		if searchCursor%notfound then
			mensaje_error := mensaje_error || 'No existe registro conicidente para num_documento '|| doc_number || ' y ncre_sri '|| ncre_sri;
			v_error := 'Y';
		end if;
		close searchCursor;
        --------------------------------------------------------------
		cod_detalle :=null;
		getCodDevolucion(cod_detalle);
		if cod_detalle = null then
			mensaje_error := mensaje_error || 'Falta parametrizacion para "codigo de detalle';
			v_error := 'Y';
		end if;
	end if;

        if v_error = 'N' then
		lastTranNumber := 1;
		----------------------------------------
		----------------------------------------
        gb_common.p_set_context ('TB_RECEIVABLE',
                                 'SYSTEM_TRAN',
                                 'TRUE',
                                 'N');
        tb_receivable.p_create(
					  pidm,
					  tzRecord.tzrfact_term_code,
					  cod_detalle,
					  'SAP_IFI006',
					  SYSDATE,
					  valor,
					  SYSDATE,--to_date(fecha_transac, 'DD/MM/YYYY'),
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  'T',
					  'Y',
					  0,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  to_date(fecha_transac, 'DD/MM/YYYY'),--ajuste ifi006 AC NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  NULL ,
					  'N',
					  NULL ,
					  NULL ,
					  NULL ,
					  lastTranNumber,
					  p_row_id,
					  NULL,
					  NULL,
					  NULL,
					  NULL);
					  commit;
					  --aplicar pagos despues de afectar cuenta de estudiante.
                      gb_common.p_set_context ('TB_RECEIVABLE',
                          'PROCESS',
                          'APPLPMNT',
                          'N');
					  begin
						P_APLICATVRAPPL_IFI006 (p_id => gb_common.f_get_id(pidm),
							 p_update_mode   => 'U',
							 output          => lv_out_stat);
					  end;
					  --insertar en TSADETL
					  begin
						  p_insert_text  (
						  p_pidm => pidm,
						  p_tran_number => lastTranNumber,
						  p_text => ncre_sri);
						  commit;
					 end;
			----------------------------------------
			response_obj.put('TIPO_MENSAJE', 'S');
			response_obj.put('MENSAJE', 'Registro exitoso');
			----------------------------------------
        else
            response_obj.put('TIPO_MENSAJE', 'E');
            response_obj.put('MENSAJE', mensaje_error);
        end if;
        -------------------------------------------------------------------------------
        response_obj.to_clob(largeresponse);
        p_outputdata := largeresponse;
        -------------------------------------------------------------------------------
        ztz_async_proc.ps_setDataForPublishIfi(ifi006_iztid, json_entrada, p_outputdata, v_recid);
        ifi_006_saveLog(v_recid, json_entrada, p_outputdata);
        -------------------------------------------------------------------------------
        EXCEPTION
        WHEN OTHERS THEN
            response_obj.put('TIPO_MENSAJE', 'E');
            response_obj.put('MENSAJE', 'Error de registro: ' || SQLERRM);
            response_obj.to_clob(largeresponse);
            p_outputdata := largeresponse;
            ---------------------------------------------------------------------------
            ztz_async_proc.ps_setDataForPublishIfi(ifi006_iztid, json_entrada, p_outputdata, v_recid);
			ifi_006_saveLog(v_recid, json_entrada, p_outputdata);

            ---------------------------------------------------------------------------
    END p_ifi006_registro;
