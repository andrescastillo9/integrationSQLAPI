CREATE OR REPLACE PACKAGE               "ZTZ_ASYNC_PROC" as

      /************************************************************************************************************************/  
      -- FILE NAME..:   ztz_async_proc.sql
      -- RELEASE....:   Aug 2020
      -- VERSION....:   2.001
      -- OBJECT NAME:   ZTZ_ASYNC_PROC
      -- PRODUCT....:   ZTZ - API for Integration Platform
      -- DEVELOPER..:   JOSE ANTONIO POLO HERNANDEZ - NEORIS.
      /************************************************************************************************************************/


  --------------------------------------------------------------------------------------
  type iztzm00_type is record (
        recid	number,
        ifzid	varchar2(10 byte),
        activity_date	date,
        data_origin	varchar2(50 byte),
        user_id	varchar2(50 byte),
        request_data	clob,
        response_data	clob,
        request_timestamp	timestamp(6),
        response_timestamp	timestamp(6),
        response_message	clob,
        proc_ind	varchar2(2 byte),
        setdata_timestamp	timestamp(6),
        getdata_timestamp	timestamp(6),
        prcid number
  );  
  iztzm00_userId varchar2(32) := 'ZTZ PROCESS';
  iztzm00_dataOrigin varchar2(32) := 'INTEGRACION SAP';
  ztz_recPerPage number := 100;
  --------------------------------------------------------------------------------------
  beginProcessURL varchar2(256) := 'http://172.31.2.95:8081/mservice_qa/rest/execute/';
  --beginProcessURL varchar2(256) := 'http://172.31.2.95:8081/mservice_prod/rest/execute/';
  --beginProcessURL varchar2(256) := 'http://172.31.2.88:8090/mservice_prod/rest/execute/';--producción;
  --------------------------------------------------------------------------------------
  --utilities
  function ut_iztExists(iztid in varchar2)return boolean;
  --------------------------------------------------------------------------------------
  --package level procedures
  --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
  procedure ps_reviewProcess(p_procid in number default null);
  --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
  procedure ps_beginRequest(p_procid in number default null);
  function ps_startProcess(iztid in varchar2, p_clog_id varchar2 default null)return number;
  procedure ps_finishProcess(p_prcid in number);
  procedure ps_sendRequestToWS(iztid in varchar2, p_procid in number default null);
  procedure ps_setDataForPublish(iztid in varchar2, requestData in clob, responseData in clob);
  --acastillo para logifi004 logifi006
  procedure ps_setDataForPublishIfi(iztid in varchar2, requestData in clob, responseData in clob, recid in out number);

  function ps_setDataRequest(prcid in number, request_data in clob)return number;
  function ps_setDataRequestWithComponent(prcid in number, url_component varchar2, request_data in clob)return number;
  function ps_insertProcRecord(iztid in varchar2, dataOrigin in varchar2, userId in varchar2) return number;
  function ps_insertIztRecord(tableName in varchar2, prcid in number, requestData in clob, dataOrigin in varchar2, userId in varchar2)return number;
  procedure ps_setDataResponse(prcid in number, recid in number, response_data in clob);
  function ps_getDataResponse(prcid in number, recid in number)return clob;
  --------------------------------------------------------------------------------------
  --web service exclusive procedures
  procedure ws_sendRequestToWS(reqData in json, p_procid in number default null);
  --procedure ws_getRequestData(tableName in varchar2, requestData out clob, recId out number);
  procedure ws_getRequestData(tableName in varchar2, requestData out clob, recId out number, procId in number default null);
  procedure ws_setResponseData(tableName in varchar2, recId in number, responseData in clob);
  --------------------------------------------------------------------------------------
  procedure ws_updateProcess(p_prcid in number);
  --------------------------------------------------------------------------------------
  --frontend procedures
  procedure pn_getIztNameList (nameList out clob);
  procedure pn_getIztRecord (iztid in varchar, recOut out clob);
  procedure pn_getIztRequestData(inputParam in varchar2, recOut out clob);
  procedure pn_getIztResponseData(inputParam in varchar2, recOut out clob);
  procedure pn_getIztRqDataAndRspData(inputParam in varchar2, recOutRequest out clob, recOutResponse out clob, recOutDateRequest out varchar2, recOutDateResponse out varchar2, recOutId out varchar2);
  procedure pn_getIztLogList (inputParam in varchar2, logList out clob, recCount out varchar2);
  procedure pn_getIztProcessProgress(resultList out clob);
  --------------------------------------------------------------------------------------

end ztz_async_proc;









/


CREATE OR REPLACE PACKAGE BODY               "ZTZ_ASYNC_PROC" as

	procedure p_ins_tzrrlog ( 
				 p_pidm  number default null,
				 p_process varchar2  default null,
				 p_reference varchar2 default null,
				 p_log varchar2 default null,
				 p_user_id varchar2 default null
				 )
				is
			begin
			insert into tzrrlog 
			(
			 tzrrlog_pidm,
			 tzrrlog_process,
			 tzrrlog_reference,
			 tzrrlog_log,
			 tzrrlog_user_id,
			 tzrrlog_activity_date
			)
			values
			(
			  p_pidm,
			 p_process,
			 SUBSTR(p_reference,1,99),
			 SUBSTR(p_log,1,3999),
			 p_user_id,
			 sysdate
			);

	end;
    --**************************************************************
    function ut_iztExists(iztid in varchar2)return boolean
    is
        cursor confExists is 
            select iztzcfg_iztid from iztzcfg where iztzcfg_iztid = iztid and iztzcfg_change_ind is null;
        idExists varchar2(15) := null;
    begin
        open confExists;
        fetch confExists into idExists;
        close confExists;

        if idExists is not null then
            return true;
        else
            return false;
        end if;
    end ut_iztExists;
    --**************************************************************
    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
    /*
   PROCEDURE ps_reviewProcess(p_procid IN NUMBER DEFAULT NULL) IS
    -- Un solo cursor con FOR UPDATE NOWAIT
    CURSOR masterCursor IS
        SELECT
            iztzprc_id,
            iztzprc_iztid,
            iztzprc_start_process
        FROM
            iztzprc
        WHERE
            (iztzprc_proc_ind = 'P' OR iztzprc_proc_ind = 'X')
            AND iztzprc_finish_data IS NOT NULL
            AND iztzprc_total_records IS NOT NULL
            AND iztzprc_start_process IS NULL
            AND (p_procid IS NULL OR iztzprc_id = p_procid);
        --FETCH FIRST 1 ROWS ONLY
        --FOR UPDATE WAIT 5; -- Se añade el bloqueo aquí

    prcid        NUMBER      := NULL;
    iztid        VARCHAR2(32) := NULL;
    startProcess TIMESTAMP   := NULL;
BEGIN
    -- Se abre el cursor, lo que intenta obtener el bloqueo
    OPEN masterCursor;
    FETCH masterCursor INTO prcid, iztid, startProcess;
    CLOSE masterCursor;

    -- Si se encontró una fila, se procede con la lógica
    IF prcid IS NOT NULL THEN
        -- Como ya se tiene el bloqueo, se puede actualizar directamente
        IF startProcess IS NULL THEN
            UPDATE iztzprc
            SET
                iztzprc_start_process = SYSDATE
            WHERE
                iztzprc_id = prcid;
        END IF;

        ps_sendRequestToWS(iztid, prcid);

        COMMIT; -- Se confirma la transacción
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Manejar el caso en que no se encuentran filas para procesar
        NULL;
    WHEN OTHERS THEN
        -- En caso de cualquier otro error (incluido el de bloqueo), se revierte y se registra
        ROLLBACK;
        p_ins_tzrrlog(0, 'INTERFACE_BANNER_SAP', 'ps_reviewProcess Error',
                      'iztid ' || iztid || ' prcid ' || prcid || ' error ' || SUBSTR(SQLERRM, 1, 3000), USER);
END ps_reviewProcess;
*/    
    PROCEDURE ps_reviewProcess(p_procid IN NUMBER DEFAULT NULL) IS
    CURSOR masterCursor IS
        SELECT
            iztzprc_id,
            iztzprc_iztid,
            iztzprc_start_process
        FROM
            iztzprc
        WHERE
                (iztzprc_proc_ind = 'P' OR iztzprc_proc_ind = 'X')
            AND iztzprc_finish_data IS NOT NULL
            AND iztzprc_total_records IS NOT NULL
            AND iztzprc_start_process IS NULL
            AND (p_procid IS NULL OR iztzprc_id = p_procid) -- This line is the key change
        ORDER BY
            iztzprc_id
        FETCH FIRST 1 ROWS ONLY;
    prcid        NUMBER         := NULL;
    iztid        VARCHAR2(32)   := NULL;
    startProcess TIMESTAMP      := NULL;
    BEGIN
        --DBMS_LOCK.SLEEP(3);
        ---------------------------------------------------------------------
        OPEN masterCursor;
        FETCH masterCursor INTO prcid, iztid, startProcess;
        CLOSE masterCursor;
        ---------------------------------------------------------------------
        IF prcid IS NOT NULL THEN
            IF startProcess IS NULL THEN
                UPDATE iztzprc
                SET
                    iztzprc_start_process = SYSDATE
                WHERE
                    iztzprc_id = prcid;
                COMMIT;
            END IF;
            -----------------------------------------------------------------
            ps_sendRequestToWS(iztid,p_procid);
            -----------------------------------------------------------------
        END IF;
        p_ins_tzrrlog(0, 'INTERFACE_BANNER_SAP', 'ps_reviewProcess OK ',
                    'si prcid is null no encontro procesos sin iniciar '
                    || iztid
                    || ' prcid '
                    || prcid, USER);

    EXCEPTION
        WHEN OTHERS THEN
            p_ins_tzrrlog(0, 'INTERFACE_BANNER_SAP', 'ps_reviewProcess Error ',
                        ' iztid '
                        || iztid
                        || ' prcid '
                        || prcid
                        || ' error '
                        || SUBSTR(SQLERRM, 1, 3000), USER);
    END ps_reviewProcess;
    --**************************************************************

    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
    procedure ps_beginRequest(p_procid in number default null)
    is
    begin
        ------------------------------------------------------------
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_beginRequest OK', 'llamado a ps_reviewProcess', user);
        --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
        ps_reviewProcess(p_procid);

		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_beginRequest Error', SUBSTR (SQLERRM, 1, 500), user);

        ------------------------------------------------------------
    end ps_beginRequest;
    --**************************************************************
    function ps_startProcess(iztid in varchar2, p_clog_id varchar2)return number
    is
        newProcId number := null;
    begin
        if ut_iztExists(iztid) then
            -------------------------------------------------------------------
            --newProcId := ps_insertProcRecord(iztid, iztzm00_dataOrigin||p_clog_id, iztzm00_userId);
            newProcId := ps_insertProcRecord(iztid, iztzm00_dataOrigin||p_clog_id, iztzm00_userId);
            dbms_output.put_line('IFI001 - ps_startProcess' || iztzm00_dataOrigin||p_clog_id);

            -------------------------------------------------------------------
        end if;
        -----------------------------------------------------------------------
        return newProcId;
        -----------------------------------------------------------------------
    end ps_startProcess;
    --**************************************************************
    /*procedure ps_finishProcess(p_prcid in number)
    is
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = p_prcid;
        iztid varchar(32);                
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        tempCursor sys_refcursor;
        totalRecords number;
        tableName varchar2(64);
        sentence varchar2(128);
    begin
        open masterCursor;
        fetch masterCursor into iztid;
        close masterCursor;
        -------------------------------------------------------------------
        open confCursor;
        fetch confCursor into tableName;
        close confCursor;
        -------------------------------------------------------------------
        sentence := 'select count(recid) from '||tableName||' where prcid = '||p_prcid;--||' for update wait 5';
        open tempCursor for sentence; 
        fetch tempCursor into totalRecords;
        close tempCursor;    
        ------------------------------------------------------------
        update iztzprc set iztzprc_finish_data = sysdate, iztzprc_missing_records = totalRecords, iztzprc_total_records = totalRecords where iztzprc_id = p_prcid;
        commit;
        -----------------------------------------------------------------------
        if totalRecords <= 0 then
            update iztzprc set iztzprc_proc_ind = 'R' where iztzprc_id = p_prcid;
            commit;
        end if;
        -----------------------------------------------------------------------
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_finishProcess OK', 'iztid '||iztid||' prcid '||p_prcid||' sentence '||sentence|| ' totalRecords: '||totalRecords, user);

		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_finishProcess Error',' iztid '||iztid||' prcid '||p_prcid||' errosql' || SUBSTR (SQLERRM, 1, 500), user);

    end ps_finishProcess;
    */

            procedure ps_finishProcess(p_prcid in number)
        is
            cursor masterCursor is
                select
                    iztzprc_iztid as iztid
                from
                    iztzprc
                where
                    iztzprc_id = p_prcid
                for update; -- Se reserva la fila para su actualización
            iztid varchar(32);
            cursor confCursor is
                select
                    iztzcfg_table_name as table_name
                from
                    iztzcfg
                where
                    iztzcfg_iztid = iztid and
                    iztzcfg_change_ind is null;
            tempCursor sys_refcursor;
            totalRecords number;
            tableName varchar2(64);
            sentence varchar2(128);
        begin
            -- Abrir el cursor y bloquear la fila de iztzprc
            open masterCursor;
            fetch masterCursor into iztid;
            -- Si no se encuentra la fila, lanzar una excepción
            if masterCursor%notfound then
                raise no_data_found;
            end if;
            close masterCursor;
            -------------------------------------------------------------------
            open confCursor;
            fetch confCursor into tableName;
            close confCursor;
            -------------------------------------------------------------------
            sentence := 'select count(recid) from '||tableName||' where prcid = '||p_prcid;
            open tempCursor for sentence;
            fetch tempCursor into totalRecords;
            close tempCursor;
            ------------------------------------------------------------
            update iztzprc set
                iztzprc_finish_data = sysdate,
                iztzprc_missing_records = totalRecords,
                iztzprc_total_records = totalRecords
            where
                iztzprc_id = p_prcid;
            -----------------------------------------------------------------------
            if totalRecords <= 0 then
                update iztzprc set
                    iztzprc_proc_ind = 'R'
                where
                    iztzprc_id = p_prcid;
            end if;
            -----------------------------------------------------------------------
            commit;
            p_ins_tzrrlog(0, 'INTERFACE_BANNER_SAP', 'ps_finishProcess OK', 'iztid '||iztid||' prcid '||p_prcid||' sentence '||sentence|| ' totalRecords: '||totalRecords, user);
        EXCEPTION
            WHEN OTHERS THEN
                p_ins_tzrrlog(0, 'INTERFACE_BANNER_SAP', 'ps_finishProcess Error', ' iztid '||iztid||' prcid '||p_prcid||' errosql' || SUBSTR(SQLERRM, 1, 500), user);
                rollback;
        end ps_finishProcess;
    --**************************************************************
    procedure ps_sendRequestToWS(iztid in varchar2, p_procid in number default null)    
  --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)

    is
        cursor confCursor is
            select
                iztzcfg_request_url as request_url,
                iztzcfg_table_name as table_name,
                iztzcfg_request_method as request_method,
                iztzcfg_authorization as request_credentials,
                iztzcfg_content_type as content_type,
                iztzcfg_header_accept as header_accept
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        recordConf confCursor%rowtype;   
        confObj json;
    begin 
        -----------------------------------------------------------------------
        if ut_iztExists(iztid) then
            -------------------------------------------------------------------
            open confCursor;
            fetch confCursor into recordConf;
            close confCursor;
            -------------------------------------------------------------------
            --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ps_sendRequestToWS 1: request_url:'||recordConf.request_url||'table_name:'||recordConf.table_name||'request_method:'||recordConf.request_method||'content_type:'||recordConf.content_type||'header_accept:'||recordConf.header_accept||'request_credentials:'||recordConf.request_credentials);--debug
            --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ps_sendRequestToWS 1');--debug
            confObj := json();
            confObj.put('request_url', recordConf.request_url);
            confObj.put('table_name', recordConf.table_name);
            --pruebas de lanzamiento por id de proceso
            -- Convierte p_procid a una cadena de texto antes de agregarlo al JSON
            if p_procid is not null then
                confObj.put('proc_id', to_char(p_procid));
            end if;
                --confObj.put('proc_id', null);
            --end if;

            confObj.put('request_method', recordConf.request_method);
            confObj.put('content_type', recordConf.content_type);
            confObj.put('header_accept', recordConf.header_accept);
            confObj.put('request_credentials', recordConf.request_credentials);
            -------------------------------------------------------------------
            --dbms_output.put_line('ps_beginRequest'||'request_url:'||recordConf.request_url||'table_name:'||recordConf.table_name||'request_method:'||recordConf.request_method||'content_type:'||recordConf.content_type||'header_accept:'||recordConf.header_accept||'request_credentials:'||recordConf.request_credentials);
            --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
            ws_sendRequestToWS(confObj, p_procid);  
            -------------------------------------------------------------------
        end if;
        -----------------------------------------------------------------------
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_sendRequestToWS OK', 'ps_beginRequest'||'request_url:'||recordConf.request_url||'table_name:'||recordConf.table_name||'request_method:'||recordConf.request_method||'content_type:'||recordConf.content_type||'header_accept:'||recordConf.header_accept||'request_credentials:'||recordConf.request_credentials||' p_procid '||p_procid, user);

		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_beginRequest Error','ps_beginRequest'||'request_url:'||recordConf.request_url||'table_name:'||recordConf.table_name||'request_method:'||recordConf.request_method||'content_type:'||recordConf.content_type||'header_accept:'||recordConf.header_accept||'request_credentials:'||recordConf.request_credentials||' errosql' || SUBSTR (SQLERRM, 1, 2500), user);

    end ps_sendRequestToWS;
    --**************************************************************
    procedure ps_setDataForPublish(iztid in varchar2, requestData in clob, responseData in clob)
    is
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        totalRecords number;
        tableName varchar2(64);
        procid number;
        recid number;
        sentence varchar2(2048);
    begin
            -------------------------------------------------------
            sentence := 'insert into iztzprc (iztzprc_iztid, iztzprc_activity_date, iztzprc_data_origin, 
                        iztzprc_user_id, iztzprc_proc_ind, iztzprc_start_data, iztzprc_finish_data, 
                        iztzprc_start_process, iztzprc_finish_process, iztzprc_total_records, iztzprc_missing_records) 
                        values (:1, sysdate, :2, :3, ''R'', sysdate, sysdate, sysdate, sysdate, 1, 0) returning iztzprc_id into :4';
            --dbms_output.put_line('ps_insertProcRecord insertar:'||sentence);                        
            execute immediate sentence
            using in iztid, in iztzm00_dataOrigin, in iztzm00_userId, out procid;
            commit;
            -------------------------------------------------------
            open confCursor;
            fetch confCursor into tableName;
            close confCursor;
            --------------------------------------------------------
            sentence := 'insert into '|| tableName ||' (prcid, request_data, response_data, 
                        setdata_timestamp, request_timestamp, response_timestamp,
                        activity_date, data_origin, user_id, proc_ind) 
                        values (:1, :2, :3, sysdate, sysdate, sysdate, sysdate, :4, :5, ''R'') returning recid into :6';
            --dbms_output.put_line('ps_insertIztRecord insertar:'||prcid||' '||dataOrigin||' '||userId||' '||requestData);                        
            execute immediate sentence
            using in procid, in requestData, in responseData, in iztzm00_dataOrigin, in iztzm00_userId, out recid;
            commit;
            --------------------------------------------------------    
    end ps_setDataForPublish;
    --**************************************************************
	----acastillo cc logifi006 y ifi004
    procedure ps_setDataForPublishIfi(iztid in varchar2, requestData in clob, responseData in clob, recid in out number)
    is
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        totalRecords number;
        tableName varchar2(64);
        procid number;
        --recid number;
        sentence varchar2(2048);
	    newRecId number := null;

    begin
            -------------------------------------------------------
            sentence := 'insert into iztzprc (iztzprc_iztid, iztzprc_activity_date, iztzprc_data_origin, 
                        iztzprc_user_id, iztzprc_proc_ind, iztzprc_start_data, iztzprc_finish_data, 
                        iztzprc_start_process, iztzprc_finish_process, iztzprc_total_records, iztzprc_missing_records) 
                        values (:1, sysdate, :2, :3, ''R'', sysdate, sysdate, sysdate, sysdate, 1, 0) returning iztzprc_id into :4';
            --dbms_output.put_line('ps_insertProcRecord insertar:'||sentence);                        
            execute immediate sentence
            using in iztid, in iztzm00_dataOrigin, in iztzm00_userId, out procid;
            commit;
            -------------------------------------------------------
            open confCursor;
            fetch confCursor into tableName;
            close confCursor;
            --------------------------------------------------------
            sentence := 'insert into '|| tableName ||' (prcid, request_data, response_data, 
                        setdata_timestamp, request_timestamp, response_timestamp,
                        activity_date, data_origin, user_id, proc_ind) 
                        values (:1, :2, :3, sysdate, sysdate, sysdate, sysdate, :4, :5, ''R'') returning recid into :6';
            --dbms_output.put_line('ps_insertIztRecord insertar:'||prcid||' '||dataOrigin||' '||userId||' '||requestData);                        
            execute immediate sentence
            using in procid, in requestData, in responseData, in iztzm00_dataOrigin, in iztzm00_userId, out recid;
            commit;
			--return recid;

            --------------------------------------------------------    
    end ps_setDataForPublishIfi;	
	-------------------------------------------
    function ps_setDataRequest(prcid in number, request_data in clob)return number
    is
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        iztid varchar(32);                
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null; 
        tableName varchar2(64);
        sentence varchar2(32767);
        newRecId number := null;
    begin
            open masterCursor;
            fetch masterCursor into iztid;
            close masterCursor;
            if ut_iztExists(iztid) then
                -------------------------------------------------------------------
                open confCursor;
                fetch confCursor into tableName;
                close confCursor;
                -------------------------------------------------------------------
                --dbms_output.put_line('ps_setDataRequest'||tableName||'prcid:'||prcid||'iztid:'||iztid||'iztzm00_dataOrigin:'||iztzm00_dataOrigin||'iztzm00_userId:'||iztzm00_userId);
                --dbms_output.put_line('');
                newRecId := ps_insertIztRecord(tableName, prcid, request_data, iztzm00_dataOrigin, iztzm00_userId);
                -------------------------------------------------------------------
            end if;
            -----------------------------------------------------------------------
            return newRecId;
            -----------------------------------------------------------------------
    end ps_setDataRequest;
    --**************************************************************
    function ps_setDataRequestWithComponent(prcid in number, url_component varchar2, request_data in clob)return number
    is
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        iztid varchar(32);                
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null; 
        tableName varchar2(64);
        sentence varchar2(32767);
        newRecId number := null;

        complete_request clob := ' ';
    begin
            open masterCursor;
            fetch masterCursor into iztid;
            close masterCursor;
            if ut_iztExists(iztid) then
                complete_request  := url_component || '#####' || request_data;
                -------------------------------------------------------------------
                open confCursor;
                fetch confCursor into tableName;
                close confCursor;
                -------------------------------------------------------------------
                newRecId := ps_insertIztRecord(tableName, iztid, complete_request, iztzm00_dataOrigin, iztzm00_userId);
                -------------------------------------------------------------------
            end if;
            -----------------------------------------------------------------------
            return newRecId;
            -----------------------------------------------------------------------
    end ps_setDataRequestWithComponent;
    --**************************************************************
    function ps_insertProcRecord(iztid in varchar2, dataOrigin in varchar2, userId in varchar2) return number
    is
        procid number;
        sentence varchar2(2048);
    begin
            sentence := 'insert into iztzprc (iztzprc_iztid, iztzprc_activity_date, iztzprc_data_origin, 
                        iztzprc_user_id, iztzprc_proc_ind, iztzprc_start_data) 
                        values (:1, sysdate, :2, :3, ''P'', sysdate) returning iztzprc_id into :4';
            dbms_output.put_line('ps_insertProcRecord insertar:'||sentence);                        
            execute immediate sentence
            using in iztid, in dataOrigin, in userId, out procid;
            commit;
            dbms_output.put_line('ps_insertProcRecord insertar:'||dataOrigin);                        

        return procid;
    end ps_insertProcRecord;
    --**************************************************************
    function ps_insertIztRecord(tableName in varchar2, prcid in number, requestData in clob, dataOrigin in varchar2, userId in varchar2)
    return number
    is
        recid number;
        sentence varchar2(2048);
    begin
            sentence := 'insert into '|| tableName ||' (prcid, request_data, setdata_timestamp, activity_date, data_origin, user_id, proc_ind) 
                        values (:1, :2, sysdate, sysdate, :3, :4, ''P'') returning recid into :5';
            --dbms_output.put_line('ps_insertIztRecord insertar:'||prcid||' '||dataOrigin||' '||userId||' '||requestData);                        
            execute immediate sentence
            using in prcid, in requestData, in dataOrigin, in userId, out recid;
            commit;
        return recid;
    end ps_insertIztRecord;
    --**************************************************************
    procedure ps_setDataResponse(prcid in number, recid in number, response_data in clob)
    is
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        iztid varchar(32);                
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null; 
        tableName varchar2(64);
        sentence varchar2(32767);
        newRecId number := null;
    begin
            open masterCursor;
            fetch masterCursor into iztid;
            close masterCursor;
            if ut_iztExists(iztid) then
                -------------------------------------------------------------------
                open confCursor;
                fetch confCursor into tableName;
                close confCursor;
                -------------------------------------------------------------------
                sentence := 'update '||tableName||' set response_data = :1, proc_ind = ''R'', request_timestamp = sysdate, response_timestamp = sysdate';
                sentence := sentence || ' where recid = ' || recid;
                --dbms_output.put_line('paso por ps_setDataResponse: sentence'||sentence);
                execute immediate sentence
                using in response_data;
                commit;
                -------------------------------------------------------------------
                ws_updateProcess(prcid);
            end if;
            -----------------------------------------------------------------------
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_setDataResponse OK', 'recid ' ||recid|| ' iztid '||iztid||' sentence '||sentence||' tableName '||tableName, user);

		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ps_setDataResponse Error ',' recid ' ||recid|| ' iztid '||iztid||' sentence '||sentence||' errorsql ' ||SUBSTR (SQLERRM, 1, 500), user);

    end ps_setDataResponse;
    --**************************************************************
    function ps_getDataResponse(prcid in number, recid in number)return clob
    is
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        iztid varchar(32);                
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null; 
        tableName varchar2(64);
        retCursor sys_refcursor;
        sentence varchar2(256);
        resp_data clob := null;
    begin
            open masterCursor;
            fetch masterCursor into iztid;
            close masterCursor;
            if ut_iztExists(iztid) then
                -------------------------------------------------------------------
                open confCursor;
                fetch confCursor into tableName;
                close confCursor;
                -------------------------------------------------------------------
                sentence := 'select response_data from ' || tableName || ' where recid = ' || recid;
                --dbms_output.put_line('paso por ps_getDataResponse sentence:'||sentence);
                open retCursor for sentence;
                fetch retCursor into resp_data;
                close retCursor;
                commit;
                -------------------------------------------------------------------
            end if;
            -----------------------------------------------------------------------
            return resp_data;
    end ps_getDataResponse;
    --**************************************************************

    --**************************************************************
    procedure ws_sendRequestToWS(reqData in json, p_procid in number default null) 
    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
    is
        -----------------------------------------------------
        req utl_http.req;
        res utl_http.resp;
        reqObj json;
        reqStr clob;
        resBuffer varchar2(4000); 
        resLine varchar2(4000);
        respObj json;
        tempObj json;
        -----------------------------------------------------
    begin
        -----------------------------------------------------
        reqStr := reqData.to_char();
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_sendRequestToWS reqStr: ',reqStr, user);

        -----------------------------------------------------
        utl_http.set_transfer_timeout(35000);
        --utl_http.set_transfer_timeout(30);
        req := utl_http.begin_request(beginProcessURL, 'POST',' HTTP/1.1');
        utl_http.set_header(req, 'user-agent', 'mozilla/4.0'); 
        utl_http.set_header(req, 'content-type', 'text/plain');
        utl_http.set_header(req, 'content-length', length(reqStr));
        -------------------------------------------------------
        utl_http.set_header(req, 'Authorization', 'Basic WlRaX1BST0NFU1M6UE9MT19NU0VSVklDRQ==');
        -------------------------------------------------------
        utl_http.set_header(req, 'cache-control', 'no-cache');
        utl_http.write_text(req, reqStr);

       -- dbms_output.put_line('ws_sendRequestToWS'||reqStr);
		--p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_sendRequestToWS req: ',req, user);

        ---------------------------------------------------------
        res := utl_http.get_response(req);

        begin
            loop
                utl_http.read_line(res, resLine);
                resBuffer := resBuffer || resLine;
            end loop;
            -----------------------------------------------------
            exception
            when utl_http.end_of_body then
                    --dbms_output.put_line('ws_sendRequestToWS error 1:'||resBuffer);
					p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_sendRequestToWS error 1:', 'resBuffer: '||SUBSTR (resBuffer, 1, 80), user);

                    utl_http.end_response(res);
                    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
                    --ps_reviewProcess(p_procid);
                    --SUCCESSFUL
            when utl_http.network_access_denied then 
                    --dbms_output.put_line('network_access_denied');
					p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_sendRequestToWS error 2:', 'network_access_denied', user);

                    utl_http.end_response(res);
                    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)                    
                    --ps_reviewProcess(p_procid);
                    --ACCESS DENIED
            when utl_http.transfer_timeout then  
                    --dbms_output.put_line('transfer_timeout');
					p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_sendRequestToWS error 3:', 'transfer_timeout', user);

                    utl_http.end_response(res);
                    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)                    
                    --ps_reviewProcess(p_procid);
                    --TIME OUT
            when others then  
                    --dbms_output.put_line('others');
					p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_sendRequestToWS error 4:', 'others errorsql '||SUBSTR (SQLERRM, 1, 3000)||' resBuffer '||SUBSTR (resBuffer, 1, 3000), user);
                    utl_http.end_response(res);
                    --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
                    ps_reviewProcess(p_procid);
                    --UNKNOWN
            --dbms_output.put_line('...finishing');
            -----------------------------------------------------
            --6306 acastillo 2025-09-07 se agrega parametro de id proceso (opcional)
            --ps_reviewProcess(p_procid);
            -----------------------------------------------------

        end;
        ----------------------------------------------------------
        --dbms_output.put_line('Fin de Resbuffer:'||resBuffer);
        ----------------------------------------------------------

    end ws_sendRequestToWS;
    --**************************************************************
    /*procedure ws_getRequestData(tableName in varchar2, requestData out clob, recId out number, procId in number default null)
    is
        tempCursor sys_refcursor;
        sentence varchar2(255);
    begin
    		--DBMS_LOCK.Sleep(1/5);

        -----------------------------------------------------------------
        --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ws_getRequestData 1:'||tableName);--debug
		--ajuste acastillo evitar duplicados en SAP        
		--sentence := 'select recid, request_data from '||tableName||' where proc_ind = ''P'' and request_timestamp is null order by recid fetch first 1 rows only';
        if procId is null then
            sentence := 'select recid, request_data from '||tableName||' where proc_ind = ''P'' and request_timestamp is null and rownum=1 for update skip locked order by recid';
        else 
            sentence := 'select recid, request_data from '||tableName||' where proc_ind = ''P'' and request_timestamp is null and rownum=1 and prcid = '||procId||' for update skip locked order by recid';
        end if;

		p_ins_tzrrlog(null,  'INTERFACE_BANNER_SAP', SYSTIMESTAMP|| ' ws_getRequestData OK0', 'recid ' ||recid|| ' sentence '||sentence||' tableName '||tableName||' procId '||procId, user);

        open tempCursor for sentence; 
        fetch tempCursor into recId, requestData;
        close tempCursor;    
        -----------------------------------------------------------------
        if recId is null then
            recId := -1;
        else
            --sentence := 'update '||tableName||' set request_timestamp = sysdate where recid = :1';
            --acastillo 07092021 Asigna inmediatamente status R para garantizar la actualizacion correcta en tabla de procesos desde ws_updateProcess
            sentence := 'update '||tableName||' set request_timestamp = sysdate, proc_ind = ''R'' where recid = :1';

            execute immediate sentence using in recId;
            commit;
        end if;
		p_ins_tzrrlog(null,  'INTERFACE_BANNER_SAP', SYSTIMESTAMP|| ' ws_getRequestData OK', 'recid ' ||recid|| ' sentence '||sentence||' tableName '||tableName, user);

		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_getRequestData Error ', 'recid ' ||recid|| ' sentence '||sentence ||' error '||SUBSTR (SQLERRM, 1, 500), user);

        -----------------------------------------------------------------
        --DBMS_OUTPUT.PUT_LINE(requestData || ' ' || recId);
    end ws_getRequestData;
    */
/*
    procedure ws_getRequestData(tableName in varchar2, requestData out clob, recId out number, procId in number default null)
is
    tempCursor sys_refcursor;
    sentence varchar2(255);
begin
    -- Establecer valores por defecto en caso de que no se encuentre un registro
    recId := -1;
    requestData := null;

    if procId is null then
        sentence := 'select recid, request_data from '||tableName||' where proc_ind = ''P'' and request_timestamp is null and rownum=1 for update wait 5 order by recid';
    else  
        sentence := 'select recid, request_data from '||tableName||' where proc_ind = ''P'' and request_timestamp is null and rownum=1 and prcid = '||procId||' for update wait 5 order by recid';
    end if;

    begin -- Nuevo bloque para manejar la excepción de bloqueo
        open tempCursor for sentence;
        fetch tempCursor into recId, requestData;
        close tempCursor;

        if recId is not null then
            sentence := 'update '||tableName||' set request_timestamp = sysdate, proc_ind = ''R'' where recid = :1';
            execute immediate sentence using in recId;
            commit;
        end if;
    exception
        when others then
            p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_getRequestData Error ', 'recid ' ||recid|| ' sentence '||sentence ||' error '||SUBSTR (SQLERRM, 1, 500), user);
            -- Si ocurre un error, recId ya está en -1, lo que detendrá el bucle en Java
    end;

    p_ins_tzrrlog(null,  'INTERFACE_BANNER_SAP', SYSTIMESTAMP|| ' ws_getRequestData OK', 'recid ' ||recid|| ' sentence '||sentence||' tableName '||tableName, user);
    exception
        when others then
            p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_getRequestData Error ', 'recid ' ||recid|| ' sentence '||sentence ||' error '||SUBSTR (SQLERRM, 1, 500), user);

end ws_getRequestData;
*/
PROCEDURE ws_getRequestData(
    tableName   IN  VARCHAR2,
    requestData OUT CLOB,
    recId       OUT NUMBER,
    procId      IN  NUMBER DEFAULT NULL
)
IS
    tempCursor   SYS_REFCURSOR;
    sentence     VARCHAR2(2000);
    idDocumento  VARCHAR2(200);
BEGIN
    -- Valores por defecto
    recId := -1;
    requestData := NULL;

    -- Construcción de la sentencia SQL dinámica
    IF procId IS NULL THEN
        sentence := 'SELECT recid, request_data
                     FROM ' || tableName || '
                     WHERE ROWID = (
                         SELECT rid
                         FROM (
                             SELECT ROWID rid
                             FROM ' || tableName || '
                             WHERE proc_ind = ''P''
                               AND request_timestamp IS NULL
                             ORDER BY recid
                         )
                         WHERE ROWNUM = 1
                     )
                     FOR UPDATE WAIT 5';
    ELSE
        sentence := 'SELECT recid, request_data
                     FROM ' || tableName || '
                     WHERE ROWID = (
                         SELECT rid
                         FROM (
                             SELECT ROWID rid
                             FROM ' || tableName || '
                             WHERE proc_ind = ''P''
                               AND request_timestamp IS NULL
                               AND prcid = ' || procId || '
                             ORDER BY recid
                         )
                         WHERE ROWNUM = 1
                     )
                     FOR UPDATE WAIT 5';
    END IF;

    -- Log de inicio
    p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_SAP',
                  SYSTIMESTAMP || ' ws_getRequestData START',
                  'recid ' || recId || ' tableName ' || tableName || 
                  ' sentence: ' || sentence, USER);

    BEGIN
        -- Ejecutar la sentencia
        OPEN tempCursor FOR sentence;
        FETCH tempCursor INTO recId, requestData;
        CLOSE tempCursor;

        IF recId IS NOT NULL THEN
            -- Actualizar la fila tomada
            sentence := 'UPDATE ' || tableName ||
                        ' SET request_timestamp = SYSDATE, proc_ind = ''R'' WHERE recid = :1';
            EXECUTE IMMEDIATE sentence USING IN recId;
            COMMIT;

            -- Extraer el ID_DOCUMENTO del JSON
            idDocumento := JSON_VALUE(requestData, '$.CABECERA.ID_DOCUMENTO');

            p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_SAP',
                          SYSTIMESTAMP || ' ws_getRequestData OK',
                          'recid ' || recId || ' idDocumento ' || idDocumento, USER);

            -- Pausar si termina en "BT"
            IF idDocumento IS NOT NULL AND SUBSTR(idDocumento, -2) = 'BT' THEN
                DBMS_LOCK.SLEEP(4);
            END IF;
        ELSE
            p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_SAP',
                          SYSTIMESTAMP || ' ws_getRequestData NO_DATA',
                          'No se encontró registro para procesar en ' || tableName, USER);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_ins_tzrrlog(0, 'INTERFACE_BANNER_SAP',
                          'ws_getRequestData ERROR',
                          'recid ' || recId || ' sentence: ' || sentence ||
                          ' error: ' || SUBSTR(SQLERRM, 1, 500), USER);
            -- No relanzamos excepción: Java controlará recId = -1
    END;

    -- Log final
    p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_SAP',
                  SYSTIMESTAMP || ' ws_getRequestData END',
                  'recid ' || recId || ' tableName ' || tableName, USER);
END ws_getRequestData;

    --**************************************************************
    procedure ws_setResponseData(tableName in varchar2, recId in number, responseData in clob)
    is
        tempCursor sys_refcursor;
        sentence clob := ' ';
        sentence_2 varchar2(256);
        sentence_3 varchar2(256);
        sentence_4 varchar2(256);
        handleName varchar2(100) := null;
        ifzid varchar2(32);
        prcid number;
        totalRecords number;
        missingRecords number;
    begin
        sentence := 'update '||tableName||' set response_timestamp = sysdate, proc_ind = ''R'', response_data = :1 where recid = :2';
        --dbms_output.put_line('ws_setResponseData 1:'||sentence);
        execute immediate sentence using in responseData, in recId;
        commit;
        --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ws_setResponseData 1:'||sentence);--debug
        ------------------------------------------------------------
        sentence_2 := 'select iztzprc.iztzprc_iztid, iztzprc.iztzprc_id from '||tableName||', iztzprc where ' || tableName || '.prcid = iztzprc.iztzprc_id and ' || tableName || '.recid = '||recId;
        --dbms_output.put_line('ws_setResponseData 2:'||sentence_2);
        execute immediate sentence_2 into ifzid, prcid;
        --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ws_setResponseData 2:'||sentence_2);--debug
        ------------------------------------------------------------
        sentence_3 := 'select iztzcfg_response_handle from iztzcfg where iztzcfg_iztid = :1';
        --dbms_output.put_line('ws_setResponseData 3:'||sentence_3);
        execute immediate sentence_3 into handleName using in ifzid;
        --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ws_setResponseData 3:'||sentence_3);--debug
        ------------------------------------------------------------
        ws_updateProcess(prcid);
        ------------------------------------------------------------
        if handleName is not null then
            sentence_4 := 'begin '||handleName||'(:1,:2); end;';
            --dbms_output.put_line('ws_setResponseData 4:'||sentence_4);
            execute immediate (sentence_4) using in responseData, recId;
            --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'ws_setResponseData 4:'||sentence_4);--debug
        end if;
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_setResponseData OK', 'recid ' ||recid|| ' sentence '||sentence||' tableName '||tableName, user);
        commit;
		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_setResponseData Error ', 'recid ' ||recid|| ' sentence '||sentence ||' errorsql '|| SUBSTR (SQLERRM, 1, 3000), user);

    end ws_setResponseData;
    --**************************************************************
    procedure ws_updateProcess(p_prcid in number)
    is
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = p_prcid;
        iztid varchar(32);                
        cursor confCursor is
            select
                iztzcfg_table_name as table_name
            from 
                iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        tempCursor sys_refcursor;
        missingRecords number;
        tableName varchar2(32);
        sentence varchar2(128);
    begin
        ------------------------------------------------------------
        open masterCursor;
        fetch masterCursor into iztid;
        close masterCursor;
        -------------------------------------------------------------------
        open confCursor;
        fetch confCursor into tableName;
        close confCursor;
        -------------------------------------------------------------------
        sentence := 'select count(recid) from '||tableName||' where prcid = '||p_prcid||' and proc_ind = ''P''';
        --dbms_output.put_line('ws_setResponseData 1:'||sentence);
        open tempCursor for sentence; 
        fetch tempCursor into missingRecords;
        close tempCursor;    
        ------------------------------------------------------------
        if missingRecords = 0 then
            update iztzprc set iztzprc_proc_ind = 'R', iztzprc_missing_records = missingRecords, iztzprc_finish_process = sysdate where iztzprc_id = p_prcid;
            commit;
        else
            update iztzprc set iztzprc_proc_ind = 'X', iztzprc_missing_records = missingRecords where iztzprc_id = p_prcid;
            commit;
        end if;
        ------------------------------------------------------------
		p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_updateProcess OK', 'llamado a ws_updateProcess iztid '||iztid||' p_prcid '||p_prcid, user);

		EXCEPTION
			WHEN OTHERS
			THEN
			 p_ins_tzrrlog(0,  'INTERFACE_BANNER_SAP', 'ws_updateProcess Error ',' iztid '||iztid||' p_prcid '||p_prcid ||' errorsql'|| SUBSTR (SQLERRM, 1, 3000), user);
			null;
    end ws_updateProcess;
    --**************************************************************


    --**************************************************************
    procedure pn_getIztNameList (nameList out clob)
    is
        tempCursor sys_refcursor;
        ifzId varchar2(16);
        ifzName varchar2(64);
        ifzType varchar2(32);
        resultArray json_list := json_list();
        resultObj json;
        retObj clob := ' ';
    begin
        open tempCursor for 
            select iztzcfg_iztid, iztzcfg_name, iztzcfg_ws_type
            from iztzcfg
            where
                iztzcfg_change_ind is null;
        loop
            fetch tempCursor into ifzId, ifzName, ifzType;
            exit when tempCursor%notfound;
            resultObj := json();
            resultObj.put('ifzId', ifzId);
            resultObj.put('ifzName', ifzName);
            resultObj.put('ifzType', ifzType);
            resultArray.append(resultObj.to_json_value);
        end loop;
        resultArray.to_clob(retObj);
        nameList := retObj;
    end pn_getIztNameList;
    --**************************************************************
    procedure pn_getIztProcessProgress(resultList out clob)
    is
        iztzprc_id number; 
        iztzcfg_name varchar(256);
        iztzprc_proc_ind varchar(5);
        iztzprc_total_records number;
        iztzprc_missing_records number;
        iztzprc_start_data varchar(64);
        iztzprc_finish_data varchar(64);
        iztzprc_start_process varchar(64);
        iztzprc_finish_process varchar(64);
        progress number;    
        cursor masterCursor is
            select p.iztzprc_id, c.iztzcfg_name, p.iztzprc_proc_ind, p.iztzprc_total_records, p.iztzprc_missing_records,
                    to_char((((p.iztzprc_total_records - p.iztzprc_missing_records) / p.iztzprc_total_records) * 100.0), '999D99' )as progress,
                    to_char(p.iztzprc_start_data, 'YYYY-MM-DD HH24:MI:SS') as iztzprc_start_data, 
                    to_char(p.iztzprc_finish_data, 'YYYY-MM-DD HH24:MI:SS') as iztzprc_finish_data,
                    to_char(p.iztzprc_start_process, 'YYYY-MM-DD HH24:MI:SS') as iztzprc_start_process, 
                    to_char(p.iztzprc_finish_process, 'YYYY-MM-DD HH24:MI:SS') as iztzprc_finish_process
            from iztzprc p, iztzcfg c 
            where   1 = 1
                    and p.iztzprc_iztid = c.iztzcfg_iztid
                    and p.iztzprc_start_data is not null 
                    and p.iztzprc_finish_data is not null
                    and iztzprc_total_records > 0
            order by iztzprc_id desc
            fetch first 100 rows only;
        resultObj json;
        resultArray json_list := json_list();
        retList clob := ' ';
    begin
        open masterCursor;
            loop
                fetch masterCursor into iztzprc_id, iztzcfg_name, iztzprc_proc_ind, 
                                        iztzprc_total_records, iztzprc_missing_records, 
                                        progress, iztzprc_start_data, iztzprc_finish_data, 
                                        iztzprc_start_process, iztzprc_finish_process;
                exit when masterCursor%notfound;
                resultObj := json();
                --
                resultObj.put('iztzprc_id', iztzprc_id);
                resultObj.put('iztzcfg_name', iztzcfg_name);
                resultObj.put('iztzprc_proc_ind', iztzprc_proc_ind);
                resultObj.put('iztzprc_total_records', iztzprc_total_records);
                resultObj.put('iztzprc_missing_records', iztzprc_missing_records);
                resultObj.put('progress', progress);
                resultObj.put('iztzprc_start_data', iztzprc_start_data);
                resultObj.put('iztzprc_finish_data', iztzprc_finish_data);
                resultObj.put('iztzprc_start_process', iztzprc_start_process);
                resultObj.put('iztzprc_finish_process', iztzprc_finish_process);
                resultArray.append(resultObj.to_json_value);
            end loop;        
        close masterCursor;
        ------------------------------------------------------------
        resultArray.to_clob(retList);
        resultList := retList;
        ------------------------------------------------------------
    end pn_getIztProcessProgress;
    --**************************************************************
    procedure pn_getIztLogList (inputParam in varchar2, logList out clob, recCount out varchar2)
    is
        tempCursor sys_refcursor;
        ifzTableName varchar2(64) := null;
        sentence varchar2(4000);
        resultRecord iztzm00_type;
        resultArray json_list := json_list();
        resultObj json;
        retObj clob := ' ';
        pPage number;
        vCnt number := 0;
        fechaDesde varchar2(32);
        fechaHasta varchar2(32);
        cntPayload varchar2(128);
        cntInRequest varchar2(2);
        cntInResponse varchar2(2);
        tmpFilter varchar2(1024);
        iztid varchar(32);                
    begin
        ------------------------------------------------------
        iztid := substr(inputParam, 1, instr(inputParam, '0;') - 1);
        --dbms_output.put_line(prcid);
        pPage := substr(inputParam, instr(inputParam, '0;') + 2, (instr(inputParam, '1;') - instr(inputParam, '0;') - 2));
        --dbms_output.put_line(pPage);
        fechaDesde := substr(inputParam, instr(inputParam, '1;') + 2, (instr(inputParam, '2;') - instr(inputParam, '1;') - 2)) || ' 00:00:00';
        --dbms_output.put_line(fechaDesde);
        fechaHasta := substr(inputParam, instr(inputParam, '2;') + 2, (instr(inputParam, '3;') - instr(inputParam, '2;') - 2)) || ' 23:59:59';
        --dbms_output.put_line(fechaHasta);
        cntPayload := substr(inputParam, instr(inputParam, '3;') + 2, (instr(inputParam, '4;') - instr(inputParam, '3;') - 2));
        --dbms_output.put_line(cntPayload);
        cntInRequest := substr(inputParam, instr(inputParam, '4;') + 2, (instr(inputParam, '5;') - instr(inputParam, '4;') - 2));
        --dbms_output.put_line(cntInRequest);
        cntInResponse := substr(inputParam, instr(inputParam, '5;') + 2, (instr(inputParam, '6;') - instr(inputParam, '5;') - 2));
        --dbms_output.put_line(cntInResponse);
        ------------------------------------------------------

        ------------------------------------------------------
        open tempCursor for 
            select iztzcfg_table_name
            from iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        fetch tempCursor into ifzTableName;
        close tempcursor;
        ------------------------------------------------------------
        if ifzTableName is not null then
            --------------------------------------------------------
            cntPayload := replace(cntPayload, '%', '\%');
            cntPayload := replace(cntPayload, ' ', '%');
            tmpFilter := ' and to_char(i.request_timestamp, ''YYYY-MM-DD'') between ' || '''' || fechaDesde || '''' || ' and ' || '''' || fechaHasta || '''';
            if length(cntPayload) > 0  and cntPayLoad <> '*' and (cntInRequest = '1' or cntInResponse = '1') then
                tmpFilter := tmpFilter || ' and (';
                if cntInRequest = '1' then
                    tmpFilter := tmpFilter || 'i.request_data like ' || '''' || '%' || cntPayload || '%' || '''';
                    if cntInResponse = '1' then
                        tmpFilter := tmpFilter || ' or i.response_data like ' || '''' || '%' || cntPayload || '%' || '''';
                    end if;
                else
                    if cntInResponse = '1' then
                        tmpFilter := tmpFilter || ' i.response_data like ' || '''' || '%' || cntPayload || '%' || '''';
                    end if;
                end if;                
                tmpFilter := tmpFilter || ' )';
            end if;
            --------------------------------------------------------
            sentence :=             ' select count(i.recid)';
            sentence := sentence || ' from  ' || ifzTableName || ' i';
            sentence := sentence || '    left join iztzprc p on i.prcid = p.iztzprc_id';
            sentence := sentence || ' where 1 = 1 ' || tmpFilter;
            open tempCursor for sentence;
            fetch tempCursor into vCnt;
            close tempCursor;
            --------------------------------------------------------
            sentence :=             ' select i.*';
            sentence := sentence || ' from  ' || ifzTableName || ' i';
            sentence := sentence || '    left join iztzprc p on i.prcid = p.iztzprc_id';
            sentence := sentence || ' where 1 = 1 ' || tmpFilter;
            --acastillo 01082022 ajuste de orden para evitar que se muestren primero los no completados.
            --sentence := sentence || ' order by i.response_timestamp desc, i.request_timestamp desc, i.setdata_timestamp desc, i.getdata_timestamp desc';
            sentence := sentence || ' order by i.request_timestamp desc, i.setdata_timestamp desc, i.getdata_timestamp desc';

            sentence := sentence || ' offset '|| (pPage*ztz_recPerPage) ||' rows fetch next '|| ztz_recPerPage ||' rows only';
            --dbms_output.put_line(sentence);
            open tempCursor for sentence;
            loop
                fetch tempCursor into resultRecord;
                exit when tempCursor%notfound;
                resultObj := json();
                resultObj.put('recid', resultRecord.recid);
                --dbms_output.put_line(resultRecord.recid);
                resultObj.put('ifzid', iztid);
                if resultRecord.prcid is null then
                    resultObj.put('prcid', 'HISTORICO');
                else    
                    resultObj.put('prcid', resultRecord.prcid);
                end if;
                resultObj.put('activity_date', resultRecord.activity_date);
                resultObj.put('data_origin', resultRecord.data_origin);
                resultObj.put('user_id', resultRecord.user_id);
                resultObj.put('request_timestamp', to_char(resultRecord.request_timestamp, 'YYYY-MM-DD HH24:MI:SS'));
                --dbms_output.put_line(to_char(resultRecord.request_timestamp, 'YYYY-MM-DD HH24:MI:SS'));
                resultObj.put('response_timestamp', to_char(resultRecord.response_timestamp, 'YYYY-MM-DD HH24:MI:SS'));
                resultObj.put('response_message', resultRecord.response_message);
                resultObj.put('proc_ind', resultRecord.proc_ind);
                resultObj.put('setdata_timestamp', to_char(resultRecord.setdata_timestamp, 'YYYY-MM-DD HH24:MI:SS'));
                resultObj.put('getdata_timestamp', to_char(resultRecord.getdata_timestamp, 'YYYY-MM-DD HH24:MI:SS'));
                resultArray.append(resultObj.to_json_value);
            end loop;
            close tempCursor;
            --insert into tmp_log_ztz(log_when, log_what) values(sysdate, 'pn_getIztLogList 1:'||sentence);--debug
            commit;
        end if;
        ------------------------------------------------------------
        resultArray.to_clob(retObj);
        logList := retObj;
        recCount := vCnt;
        ------------------------------------------------------------
    end pn_getIztLogList;
    --**************************************************************
    procedure pn_getIztRecord(iztid in varchar, recOut out clob)
    is
        tempCursor sys_refcursor;
        tempRecord iztzcfg%rowtype;
        resultObj json := json();
        retObj clob := '{}';
    begin
        ------------------------------------------------------
        open tempCursor for 
            select iztzcfg.*
            from iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        fetch tempCursor into tempRecord;
        if tempRecord.iztzcfg_iztid is not null then
            resultObj.put('iztzcfg_iztid', tempRecord.iztzcfg_iztid);
            resultObj.put('iztzcfg_name', tempRecord.iztzcfg_name);
            resultObj.put('iztzcfg_description', tempRecord.iztzcfg_description);
            resultObj.put('iztzcfg_request_url', tempRecord.iztzcfg_request_url);
            resultObj.put('iztzcfg_request_method', tempRecord.iztzcfg_request_method);
            resultObj.put('iztzcfg_request_mode', tempRecord.iztzcfg_request_mode);
            resultObj.put('iztzcfg_table_name', tempRecord.iztzcfg_table_name);
            resultObj.put('iztzcfg_source_system', tempRecord.iztzcfg_source_system);
            resultObj.put('iztzcfg_authorization', tempRecord.iztzcfg_authorization);
            resultObj.put('iztzcfg_ws_type', tempRecord.iztzcfg_ws_type);
            resultObj.put('iztzcfg_content_type', tempRecord.iztzcfg_content_type);
            resultObj.put('iztzcfg_response_handle', tempRecord.iztzcfg_response_handle);
            resultObj.put('iztzcfg_header_accept', tempRecord.iztzcfg_header_accept);
        end if;            
        ------------------------------------------------------
        resultObj.to_clob(retObj);
        recOut := retObj;
        ------------------------------------------------------
    end pn_getIztRecord;
    --**************************************************************
    procedure pn_getIztRequestData(inputParam in varchar2, recOut out clob)
    is
        prcid number;
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        tempCursor sys_refcursor;
        sentence varchar2(4000);
        ifzTableName varchar2(128);
        retObj clob := ' ';
        iztid varchar2(32);
        recid varchar2(16);
    begin
        ------------------------------------------------------
        prcid := substr(inputParam, 1, instr(inputParam, ';') - 1);
        recid := substr(inputParam, instr(inputParam, ';') + 1, 25);
        ------------------------------------------------------
        open masterCursor;
        fetch masterCursor into iztid;
        close masterCursor;
        open tempCursor for 
            select iztzcfg_table_name
            from iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        fetch tempCursor into ifzTableName;
        close tempcursor;
        ------------------------------------------------------------
        if ifzTableName is not null then
            sentence := 'select request_data from ' || ifzTableName || ' where prcid = ''' || prcid || ''' and recid = ' || recid;
            open tempCursor for sentence;
            fetch tempCursor into retObj;    
            close tempCursor;
        end if;
        recOut := retObj;
        ------------------------------------------------------
    end pn_getIztRequestData;
    --**************************************************************
    procedure pn_getIztResponseData(inputParam in varchar2, recOut out clob)
    is
        prcid number;
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        tempCursor sys_refcursor;
        sentence varchar2(4000);
        ifzTableName varchar2(128);
        retObj clob := ' ';
        iztid varchar2(32);
        recid varchar2(16);
    begin
        ------------------------------------------------------
        prcid := substr(inputParam, 1, instr(inputParam, ';') - 1);
        recid := substr(inputParam, instr(inputParam, ';') + 1, 25);
        ------------------------------------------------------
        open masterCursor;
        fetch masterCursor into iztid;
        close masterCursor;
        open tempCursor for 
            select iztzcfg_table_name
            from iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        fetch tempCursor into ifzTableName;
        close tempcursor;
        ------------------------------------------------------------
        if ifzTableName is not null then
            sentence := 'select response_data from ' || ifzTableName || ' where prcid = ''' || prcid || ''' and recid = ' || recid;
            open tempCursor for sentence;
            fetch tempCursor into retObj;    
            close tempCursor;
        end if;
        recOut := retObj;
        ------------------------------------------------------
    end pn_getIztResponseData;
    --**************************************************************
    procedure pn_getIztRqDataAndRspData(inputParam in varchar2, recOutRequest out clob, recOutResponse out clob, recOutDateRequest out varchar2, recOutDateResponse out varchar2, recOutId out varchar2)
    is
        prcid number;
        cursor masterCursor is
            select
                iztzprc_iztid as iztid
            from 
                iztzprc
            where
                iztzprc_id = prcid;
        tempCursor sys_refcursor;
        sentence varchar2(4000);
        ifzTableName varchar2(128);
        retObjRequest clob := ' ';
        retObjResponse clob := ' ';
        retDateRequest varchar2(64);
        retDateResponse varchar2(64);
        iztid varchar2(32);
        recid varchar2(16);
    begin
        ------------------------------------------------------
        recid := substr(inputParam, instr(inputParam, ';') + 1, 25);
        --dbms_output.put_line(recid);
        if substr(inputParam, 1, 1) = 'H' then
            iztid := substr(inputParam, 2, instr(inputParam, ';') - 2);
        else    
            prcid := substr(inputParam, 1, instr(inputParam, ';') - 1);
            open masterCursor;
            fetch masterCursor into iztid;
            close masterCursor;
        end if;
        ------------------------------------------------------
        --dbms_output.put_line(iztid);
        open tempCursor for 
            select iztzcfg_table_name
            from iztzcfg
            where
                iztzcfg_iztid = iztid and
                iztzcfg_change_ind is null;
        fetch tempCursor into ifzTableName;
        close tempcursor;
        ------------------------------------------------------------
        --dbms_output.put_line(ifzTableName);
        if ifzTableName is not null then
            sentence := 'select request_data, response_data, to_char(request_timestamp, ''YYYY-MM-DD HH24:MI:SS''), to_char(response_timestamp, ''YYYY-MM-DD HH24:MI:SS'') from ' || ifzTableName || ' where recid = ' || recid;
            --dbms_output.put_line(sentence);
            open tempCursor for sentence;
            fetch tempCursor into retObjRequest, retObjResponse, retDateRequest, retDateResponse;    
            close tempCursor;
        end if;
        recOutRequest := retObjRequest;
        recOutResponse := retObjResponse;
        recOutDateRequest := retDateRequest;
        recOutDateResponse := retDateResponse;
        recOutId := recid;
        ------------------------------------------------------
    end pn_getIztRqDataAndRspData;
    --**************************************************************
    /*
    procedure pn_saveIztRecord(iztid in varchar2, logList out clob)
    is
        tempCursor sys_refcursor;
        existe varchar2 := null;
        sentence varchar2(1024);
        resultRecord iztzm00_type;
        resultArray json_list := json_list();
        resultObj json;
        retObj clob := ' ';
    begin
        ------------------------------------------------------------
        if ut_iztExists(iztid) is not null then

            sentence := 'select * from ' || ifzTableName || ' where ifzid = ''' || iztid || ''' order by response_timestamp desc, request_timestamp desc, setdata_timestamp desc, getdata_timestamp desc';
            open tempCursor for sentence;
            loop
                fetch tempCursor into resultRecord;
                exit when tempCursor%notfound;
                resultObj := json();
                resultObj.put('recid', resultRecord.recid);
                resultObj.put('ifzid', resultRecord.ifzid);
                resultObj.put('pidm', resultRecord.pidm);
                resultObj.put('activity_date', resultRecord.activity_date);
                resultObj.put('data_origin', resultRecord.data_origin);
                resultObj.put('user_id', resultRecord.user_id);
                --resultObj.put('request_data', resultRecord.request_data);
                --resultObj.put('response_data', resultRecord.response_data);
                resultObj.put('request_timestamp', resultRecord.request_timestamp);
                resultObj.put('response_timestamp', resultRecord.response_timestamp);
                resultObj.put('response_message', resultRecord.response_message);
                resultObj.put('proc_ind', resultRecord.proc_ind);
                resultObj.put('setdata_timestamp', resultRecord.setdata_timestamp);
                resultObj.put('getdata_timestamp', resultRecord.getdata_timestamp);
                resultArray.append(resultObj.to_json_value);
            end loop;
        end if;
        ------------------------------------------------------------
        resultArray.to_clob(retObj);
        dbms_output.put_line(retObj);
        logList := retObj;
        ------------------------------------------------------------
    end pn_getIztLogList;
    */
    --**************************************************************









  --**************************************************************
  /*
  procedure asyncproc_next_iteration
  is
   cursor mainCursor is
        select recid, request_data
        from iztzm02
        where proc_ind = 'P'
        order by request_timestamp
        fetch first 1 rows only;

    --composedUrl varchar2(128) := 'https://pucewsd.puce.edu.ec/usuario/datosEmpleado/';
    --composedUrl varchar2(128) := 'http://172.31.2.95:8081/fake_test/rest/execute/';
    --composedUrl varchar2(128) := 'http://pucesappod1.puce.edu.ec:50000/RESTAdapter/deudor/';
    composedUrl varchar2(128) := 'http://pucesappod1.puce.edu.ec:50000/RESTAdapter/docfinanciero/';

    reqUrl varchar2(256);
    tmpId number;
    reqData clob;
    --A43dHxy?codsap=17000998
  begin
    --------------------------------------------------------------
    open mainCursor;
    fetch mainCursor into  tmpId, reqData;
    close mainCursor;
    --------------------------------------------------------------
    if tmpId is not null then
        update iztzm02
        set 
            request_timestamp = sysdate,
            proc_ind = 'C'
        where 
            recid = tmpId;
        commit;    
        ------------------------------------------------------
        --PARA GET
        --composedUrl := composedUrl||'A43dHxy?codsap='||reqData;
        --dbms_output.put_line(composedUrl);
        --asyncproc_request(composedUrl, null, tmpId);
        ------------------------------------------------------
        --PARA POST
        --dbms_output.put_line(composedUrl);
        --dbms_output.put_line(reqData);
        dbms_output.put_line(tmpId);
        asyncproc_request(composedUrl, reqData, tmpId);
    end if;
    --------------------------------------------------------------
  end asyncproc_next_iteration;
  procedure asyncproc_request(reqUrl in varchar2, reqData in clob, recId in number)
  is
        -----------------------------------------------------
        req utl_http.req;
        res utl_http.resp;
        reqObj json;
        reqStr clob;
        resBuffer varchar2(4000); 
        resLine varchar2(4000);
        respObj json;
        tempObj json;
        mssgObj json_list;
        -----------------------------------------------------
    begin
        --dbms_output.put_line(reqData);
        -----------------------------------------------------
        req := utl_http.begin_request(reqUrl, 'POST',' HTTP/1.1');
        utl_http.set_header(req, 'user-agent', 'mozilla/4.0'); 
        utl_http.set_header(req, 'content-type', 'plain/text');
        utl_http.set_header(req, 'content-length', length(reqData));
        -------------------------------------------------------
        --consulta directorio activo
        --utl_http.set_header(req, 'Authorization', 'Basic bmVvcmlzX2Jhbm5lcjpQcnVlYkBCQU5OM1I=');
        -------------------------------------------------------
        --fake service
        --utl_http.set_header(req, 'Authorization', 'Basic SVpUX0FTWU5DX1BST0M6UE9MT19GQUtF');
        -------------------------------------------------------
        --documento financiero
        utl_http.set_header(req, 'Authorization', 'Basic UE9EX1dTOlBVQ0VzYXBuZW8xOA==');
        -------------------------------------------------------
        utl_http.set_header(req, 'cache-control', 'no-cache');
        utl_http.write_text(req, reqData);
        ---------------------------------------------------------
        res := utl_http.get_response(req);
        begin
            loop
                utl_http.read_line(res, resLine);
                resBuffer := resBuffer || resLine;
            end loop;
            exception
            when utl_http.end_of_body then
                    dbms_output.put_line('end_of_body '||recId);
                    utl_http.end_response(res);
                    update iztzm02
                    set 
                        response_data = resBuffer,
                        response_timestamp = sysdate,
                        proc_ind = 'R'
                    where 
                        recid = recId;
                    commit;
            when utl_http.network_access_denied then 
                    dbms_output.put_line('network_access_denied '||recId);
                    utl_http.end_response(res);
                    update iztzm02
                    set 
                        response_message = 'Error: Network Access Denied',
                        response_timestamp = sysdate,
                        proc_ind = 'R'
                    where 
                        recid = recId;
                    commit;
            when utl_http.transfer_timeout then  
                    dbms_output.put_line('transfer_timeout '||recId);
                    utl_http.end_response(res);
                    update iztzm02
                    set 
                        response_message = 'Error: Transfer TimeOut',
                        response_timestamp = sysdate,
                        proc_ind = 'R'
                    where 
                        recid = recId;
                    commit;
            when others then  
                    dbms_output.put_line('others '||recId);
                    utl_http.end_response(res);
                    update iztzm02
                    set 
                        response_message = 'Error: Unknown',
                        response_timestamp = sysdate,
                        proc_ind = 'R'
                    where 
                        recid = recId;
                    commit;
        end;
        ----------------------------------------------------------
        asyncproc_next_iteration;
        ----------------------------------------------------------
  end asyncproc_request;
  procedure testFeed
  is
    --currentParam number := 17000900; 
    currentDoc number := 10000; 
    currentIdx number := 1;
    currentFrame varchar2(4000);
  begin
    loop
       currentFrame := '
        {
          "ID_DOCUMENTO" : "'||currentDoc||'",
          "BUKRS" : "SAP1",
          "BKTXT" : "P00046997",
          "BLDAT" : "20190626",
          "BUDAT" : "20190626",
          "GJAHR" : 2019,
          "MONAT" : 6,
          "BLART" : "BF",
          "XBLNR" : "1101000000125",
          "XREF1_HD" : "10031",
          "XREF2_HD" : "PROJAS",
          "WAERS" : "USD",
          "AWKEY" : "",
          "ORIGEN" : "BANNER",

          "DATA" : [{
            "ID_DOCUMENTO" : "'||currentDoc||'",
            "BUZEI" : 1,
            "BSCHL" : "01",
            "SHKZG" : "S",
            "KOART" : "D",
            "HKONT" : "",
            "KUNNR" : "12334",
            "LIFNR" : "",
            "STCDT" : "V",
            "STCD1" : "",
            "SGTXT" : "1101000000125",
            "XREF1" : "",
            "XREF2" : "P00046997",
            "XREF3" : "",
            "WRBTR" : 395,
            "WERKS" : "",
            "ZUONR" : "'||currentDoc||'",
            "KOSTL" : "",
            "PRCTR" : "",
            "AUFNR" : "",
            "FIPOS" : "",
            "FISTL" : "",
            "FKBER" : "",
            "ANLN1" : "",
            "ANLN2" : "",
            "MENGE" : null,
            "MEINS" : null,
            "MATNR" : "",
            "EBELN" : "",
            "POSNR" : null,
            "GSBER" : "",
            "ZFBDT" : "20190626",
            "ZLSPR" : "",
            "ZTERM" : "0000",
            "KSCHL" : "",
            "REBZG" : "",
            "REBZJ" : null,
            "KIDNO" : "1101000000125",
            "ZLSCH" : "",
            "HBKID" : "",
            "HKTID" : "",
            "MWSKZ" : "",
            "WMWST" : null,
            "FWBAS" : null,
            "WITHT_1" : "",
            "WT_WITHCD_1" : "",
            "WT_QSSHB_1" : null,
            "WT_QBSHB_1" : null,
            "WITHT_2" : "",
            "WT_WITHCD_2" : "",
            "WT_QSSHB_2" : null,
            "WT_QBSHB_2" : null,
            "PSPNR" : "",
            "NPLNR" : "",
            "VORNR" : "",
            "BSEG_GSBER" : "",
            "BSEG_PAYS_TRAN" : "",
            "BSEG_ESRRE" : "",
            "BSAK_ZOLLD" : "",
            "BSEG_BUSTW" : ""
          }]
        }       
       ';

       insert into iztzm02(ifzid, request_data, request_timestamp, proc_ind)
       values ('IFI001', currentFrame, sysdate, 'P');
       ------------------------------------- 
       currentDoc := currentDoc + 1;
       -------------------------------------
       currentIdx := currentIdx + 1;
       if currentIdx >= 501 then
            return;
       end if;
    end loop;  

  end testFeed;
  */
  --**************************************************************

/*  
procedure asyncproc_iteration
  is
   cursor mainCursor is
        select recid, request_data
        from iztzm02
        where proc_ind = 'P'
        order by request_timestamp
        fetch first 1 rows only;

    --composedUrl varchar2(128) := 'https://pucewsd.puce.edu.ec/usuario/datosEmpleado/';
    --composedUrl varchar2(128) := 'http://172.31.2.95:8081/fake_test/rest/execute/';
    --composedUrl varchar2(128) := 'http://pucesappod1.puce.edu.ec:50000/RESTAdapter/deudor/';
    composedUrl varchar2(128) := 'http://pucesappod1.puce.edu.ec:50000/RESTAdapter/docfinanciero/';

    reqUrl varchar2(256);
    tmpId number;
    reqData clob;
    --A43dHxy?codsap=17000998
  begin
    --------------------------------------------------------------
    open mainCursor;
    fetch mainCursor into  tmpId, reqData;
    close mainCursor;
    --------------------------------------------------------------
    if tmpId is not null then
        update iztzm02
        set 
            request_timestamp = sysdate,
            proc_ind = 'C'
        where 
            recid = tmpId;
        commit;    
        ------------------------------------------------------
        --PARA GET
        --composedUrl := composedUrl||'A43dHxy?codsap='||reqData;
        --dbms_output.put_line(composedUrl);
        --asyncproc_request(composedUrl, null, tmpId);
        ------------------------------------------------------
        --PARA POST
        --dbms_output.put_line(composedUrl);
        --dbms_output.put_line(reqData);
        dbms_output.put_line(tmpId);
        asyncproc_request(composedUrl, reqData, tmpId);
    end if;
    --------------------------------------------------------------
  end asyncproc_iteration;
*/  

  --**************************************************************


end ztz_async_proc;









/
