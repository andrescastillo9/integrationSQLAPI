CREATE OR REPLACE PACKAGE             "IZT_INTERFACE_LEGACY_MODPUB" AS

  /**************************************************************************************************************************/
  -- FILE NAME..:   IZT_INTERFACE_LEGACY_MODPUB.sql
  -- RELEASE....:   Marzo 2024
  -- OBJECT NAME:   IZT_INTERFACE_LEGACY
  -- PRODUCT....:   IZT - Banner interfaces to Legacy systems.
  -- DEVELOPER..:   Andres Castillo
  /**************************************************************************************************************************/
procedure p_mod011_registro(json_entrada in clob, p_outputData out clob);

procedure mod_011_saveLog(v_recid in number, resultJson in clob, responseJson in clob);

END IZT_INTERFACE_LEGACY_MODPUB;





/


CREATE OR REPLACE PACKAGE BODY               "IZT_INTERFACE_LEGACY_MODPUB" AS

PROCEDURE PROCESS_IZTZM11
IS
        CURSOR cur_iztzm11 IS
            SELECT RECID, ACTIVITY_DATE, REQUEST_DATA, RESPONSE_DATA, PROC_IND
            FROM IZTZM11
            WHERE RECID NOT IN (SELECT RECID FROM SZVLGI7)
            AND JSON_EXISTS(REQUEST_DATA, '$.notasfinales')
            ORDER BY 1;


    v_id_banner        VARCHAR2(50);
    v_nrc             VARCHAR2(50);
    v_term            VARCHAR2(50);
    v_id_component    VARCHAR2(50);
    v_component_score VARCHAR2(50);
    v_tipo_mensaje    VARCHAR2(50);
    v_mensaje         VARCHAR2(255);

    v_json_request    JSON_OBJECT_T;
    v_json_response   JSON_OBJECT_T;
    v_json_notas      JSON_ARRAY_T;
    v_json_log        JSON_ARRAY_T;
    v_json_nota       JSON_OBJECT_T;
    v_json_resp       JSON_OBJECT_T;
BEGIN
    FOR rec IN cur_iztzm11 LOOP
        BEGIN
            -- Intentar parsear JSON, si falla se ignora el registro
            BEGIN
                v_json_request := JSON_OBJECT_T.parse(rec.REQUEST_DATA);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error parsing REQUEST_DATA en RECID: ' || rec.RECID || ' - ' || SQLERRM);
                    CONTINUE;
            END;

            BEGIN
                v_json_response := JSON_OBJECT_T.parse(rec.RESPONSE_DATA);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error parsing RESPONSE_DATA en RECID: ' || rec.RECID || ' - ' || SQLERRM);
                    CONTINUE;
            END;

            -- Verificar si "notasfinales" y "Log" existen en JSON
            IF v_json_request.has('notasfinales') THEN
                v_json_notas := TREAT(v_json_request.get('notasfinales') AS JSON_ARRAY_T);
            ELSE
                --DBMS_OUTPUT.PUT_LINE('No hay "notasfinales" en REQUEST_DATA para RECID: ' || rec.RECID);
                CONTINUE;
            END IF;

            IF v_json_response.has('Log') THEN
                v_json_log := TREAT(v_json_response.get('Log') AS JSON_ARRAY_T);
            ELSE
                DBMS_OUTPUT.PUT_LINE('No hay "Log" en RESPONSE_DATA para RECID: ' || rec.RECID);
                CONTINUE;
            END IF;

            -- Recorrer cada nota en request
            FOR i IN 0 .. v_json_notas.get_size - 1 LOOP
                v_json_nota := TREAT(v_json_notas.get(i) AS JSON_OBJECT_T);

                -- Validar existencia de campos antes de extraer valores
                v_id_banner := CASE WHEN v_json_nota.has('id_banner') THEN v_json_nota.get_string('id_banner') ELSE NULL END;
                v_nrc := CASE WHEN v_json_nota.has('nrc') THEN v_json_nota.get_string('nrc') ELSE NULL END;
                v_term := CASE WHEN v_json_nota.has('term') THEN v_json_nota.get_string('term') ELSE NULL END;
                v_component_score := CASE WHEN v_json_nota.has('final_grde') THEN v_json_nota.get_string('final_grde') ELSE NULL END;

                -- Buscar el mensaje correspondiente en response
                v_tipo_mensaje := NULL;
                v_mensaje := NULL;
                FOR j IN 0 .. v_json_log.get_size - 1 LOOP
                    v_json_resp := TREAT(v_json_log.get(j) AS JSON_OBJECT_T);
                    IF v_json_resp.get_string('id_banner') = v_id_banner AND v_json_resp.get_string('nrc') = v_nrc THEN
                        v_tipo_mensaje := CASE WHEN v_json_resp.has('TIPO_MENSAJE') THEN v_json_resp.get_string('TIPO_MENSAJE') ELSE NULL END;
                        v_mensaje := CASE WHEN v_json_resp.has('MENSAJE') THEN v_json_resp.get_string('MENSAJE') ELSE NULL END;
                        EXIT;
                    END IF;
                END LOOP;

                -- Intentar insertar en SZRLGI7 y capturar errores
                BEGIN
                    INSERT INTO SZVLGI7 (
                        RECID, REQUEST_DATA, RESPONSE_DATA, ACTIVITY_DATE, ID_BANNER, NRC, TERM, ID_COMPONENT, COMPONENT_SCORE, TIPO_MENSAJE, MENSAJE, PROC_IND
                    ) VALUES (
                        rec.RECID, rec.REQUEST_DATA, rec.RESPONSE_DATA, rec.ACTIVITY_DATE, v_id_banner, v_nrc, v_term, v_id_component, v_component_score, v_tipo_mensaje, v_mensaje, rec.PROC_IND
                    );
                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error insertando RECID: ' || rec.RECID || ' - ' || SQLERRM);
                        CONTINUE;
                END;
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error en RECID: ' || rec.RECID || ' - ' || SQLERRM);
                CONTINUE;
        END;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error general en procedimiento: ' || SQLERRM);
END PROCESS_IZTZM11;


PROCEDURE PROCESS_IZTZM11_NF
IS
    CURSOR cur_iztzm11 IS
        SELECT RECID, ACTIVITY_DATE, REQUEST_DATA, RESPONSE_DATA, PROC_IND
        FROM IZTZM11
        WHERE RECID NOT IN (SELECT RECID FROM SZVLGI7)
        AND JSON_EXISTS(REQUEST_DATA, '$.notas')
        ORDER BY 1;

    v_id_banner        VARCHAR2(50);
    v_nrc             VARCHAR2(50);
    v_term            VARCHAR2(50);
    v_id_component    VARCHAR2(50);
    v_component_score VARCHAR2(50);
    v_tipo_mensaje    VARCHAR2(50);
    v_mensaje         VARCHAR2(255);

    v_json_request    JSON_OBJECT_T;
    v_json_response   JSON_OBJECT_T;
    v_json_notas      JSON_ARRAY_T;
    v_json_log        JSON_ARRAY_T;
    v_json_nota       JSON_OBJECT_T;
    v_json_resp       JSON_OBJECT_T;
BEGIN
    FOR rec IN cur_iztzm11 LOOP
        BEGIN
            -- Intentar parsear JSON, si falla se ignora el registro
            BEGIN
                v_json_request := JSON_OBJECT_T.parse(rec.REQUEST_DATA);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error parsing REQUEST_DATA en RECID: ' || rec.RECID || ' - ' || SQLERRM);
                    CONTINUE;
            END;

            BEGIN
                v_json_response := JSON_OBJECT_T.parse(rec.RESPONSE_DATA);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error parsing RESPONSE_DATA en RECID: ' || rec.RECID || ' - ' || SQLERRM);
                    CONTINUE;
            END;

            -- Verificar si "notas" y "Log" existen en JSON
            IF v_json_request.has('notas') THEN
                v_json_notas := TREAT(v_json_request.get('notas') AS JSON_ARRAY_T);
            ELSE
                --DBMS_OUTPUT.PUT_LINE('No hay "notas" en REQUEST_DATA para RECID: ' || rec.RECID);
                CONTINUE;
            END IF;

            IF v_json_response.has('Log') THEN
                v_json_log := TREAT(v_json_response.get('Log') AS JSON_ARRAY_T);
            ELSE
                DBMS_OUTPUT.PUT_LINE('No hay "Log" en RESPONSE_DATA para RECID: ' || rec.RECID);
                CONTINUE;
            END IF;

            -- Recorrer cada nota en request
            FOR i IN 0 .. v_json_notas.get_size - 1 LOOP
                v_json_nota := TREAT(v_json_notas.get(i) AS JSON_OBJECT_T);

                -- Validar existencia de campos antes de extraer valores
                v_id_banner := CASE WHEN v_json_nota.has('id_banner') THEN v_json_nota.get_string('id_banner') ELSE NULL END;
                v_nrc := CASE WHEN v_json_nota.has('nrc') THEN v_json_nota.get_string('nrc') ELSE NULL END;
                v_term := CASE WHEN v_json_nota.has('term') THEN v_json_nota.get_string('term') ELSE NULL END;
                v_id_component := CASE WHEN v_json_nota.has('id_component') THEN v_json_nota.get_string('id_component') ELSE NULL END;
                v_component_score := CASE WHEN v_json_nota.has('component_grde') THEN v_json_nota.get_string('component_grde') ELSE NULL END;

                -- Buscar el mensaje correspondiente en response
                v_tipo_mensaje := NULL;
                v_mensaje := NULL;
                FOR j IN 0 .. v_json_log.get_size - 1 LOOP
                    v_json_resp := TREAT(v_json_log.get(j) AS JSON_OBJECT_T);
                    IF v_json_resp.get_string('id_banner') = v_id_banner 
                        AND v_json_resp.get_string('nrc') = v_nrc 
                        AND v_json_resp.get_string('id_component') = v_id_component THEN

                        v_tipo_mensaje := CASE WHEN v_json_resp.has('TIPO_MENSAJE') THEN v_json_resp.get_string('TIPO_MENSAJE') ELSE NULL END;
                        v_mensaje := CASE WHEN v_json_resp.has('MENSAJE') THEN v_json_resp.get_string('MENSAJE') ELSE NULL END;
                        EXIT;
                    END IF;
                END LOOP;

                -- Intentar insertar en SZRLGI7 y capturar errores
                BEGIN
                    INSERT INTO SZVLGI7 (
                        RECID, REQUEST_DATA, RESPONSE_DATA, ACTIVITY_DATE, ID_BANNER, NRC, TERM, ID_COMPONENT, COMPONENT_SCORE, TIPO_MENSAJE, MENSAJE, PROC_IND
                    ) VALUES (
                        rec.RECID, rec.REQUEST_DATA, rec.RESPONSE_DATA, rec.ACTIVITY_DATE, v_id_banner, v_nrc, v_term, v_id_component, v_component_score, v_tipo_mensaje, v_mensaje, rec.PROC_IND
                    );
                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error insertando RECID: ' || rec.RECID || ' - ' || SQLERRM);
                        CONTINUE;
                END;
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error en RECID: ' || rec.RECID || ' - ' || SQLERRM);
                CONTINUE;
        END;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error general en procedimiento: ' || SQLERRM);
END PROCESS_IZTZM11_NF;


PROCEDURE p_update_shrmrks(
    p_score         IN NUMBER,      -- nota origen
    p_pctage        IN NUMBER,      -- % origen
    p_grde_code     IN VARCHAR2,    -- grade origen
    p_gchg_code     IN VARCHAR2,    -- razón cambio origen
    p_marker        IN NUMBER,      -- pidm profe origen
    p_summary       IN VARCHAR2,    -- summary origen
    p_term_code     IN VARCHAR2,    -- periodo de procesamiento
    p_crn           IN VARCHAR2,    -- crn destino
    p_pidm          IN NUMBER,      -- pidm
    p_gcom_id_dest  IN NUMBER,      -- id componente destino
    p_error         OUT VARCHAR2    -- return error
)
IS
    v_dummy NUMBER;

BEGIN
    UPDATE SHRMRKS 
      SET SHRMRKS_SCORE         = null,
          SHRMRKS_PERCENTAGE    = null,
          SHRMRKS_GRDE_CODE     = NULL,
          SHRMRKS_GCHG_CODE     = p_gchg_code,
          SHRMRKS_SUMMARY       = p_summary,
          SHRMRKS_COMPLETED_DATE= SYSDATE,
          SHRMRKS_GCOM_DATE     = SYSDATE,
          SHRMRKS_MARK_CALC_DATE= SYSDATE,
          SHRMRKS_ACTIVITY_DATE = SYSDATE
    WHERE SHRMRKS_TERM_CODE = p_term_code
      AND SHRMRKS_CRN       = p_crn
      AND SHRMRKS_PIDM      = p_pidm
      AND SHRMRKS_GCOM_ID   = p_gcom_id_dest;

    -- Si el SELECT tuvo éxito, procedemos con el UPDATE
    UPDATE SHRMRKS 
      SET SHRMRKS_SCORE         = p_score,
          SHRMRKS_PERCENTAGE    = p_pctage,
          SHRMRKS_GRDE_CODE     = p_grde_code,
          SHRMRKS_GCHG_CODE     = p_gchg_code,
          SHRMRKS_SUMMARY       = p_summary,
          SHRMRKS_COMPLETED_DATE= SYSDATE,
          SHRMRKS_GCOM_DATE     = SYSDATE,
          SHRMRKS_MARK_CALC_DATE= SYSDATE,
          SHRMRKS_ACTIVITY_DATE = SYSDATE
    WHERE SHRMRKS_TERM_CODE = p_term_code
      AND SHRMRKS_CRN       = p_crn
      AND SHRMRKS_PIDM      = p_pidm
      AND SHRMRKS_GCOM_ID   = p_gcom_id_dest;

  p_error := 'N';
    IF SQL%ROWCOUNT = 0 THEN
         p_error := 'No se actualizó nota en SHRMRKS, revisar datos enviados';
         tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'error durante update SHRMRKS '||p_pidm||' p_grde_code'||p_grde_code, SQLERRM, USER);
    END IF;

         tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'durante update SHRMRKS '||p_pidm||' p_score'||p_score, SQLERRM, USER);

    begin     
        DELETE shrcmrk WHERE shrcmrk_pidM=p_pidm and shrcmrk_term_code=p_term_code and shrcmrk_crn=p_crn;
        shkegrb.p_shrcmrkprocess(term => p_term_code, 
                                        crn => p_crn, 
                                        pidm => p_pidm,
                                        user_id => user);                                        
        --commit;
        --response_obj.put('TIPO_MENSAJE', 'S');
        --response_obj.put('MENSAJE', 'Registro exitoso');  
        exception
        when others then
            --response_obj.put('MENSAJE', SQLERRM||v_gmod_code||v_subj_code||v_crse||v_level_code||v_score);  
                  tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'error update SHRMRKS '||p_pidm, SQLERRM, USER);

   end;        


EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_error := 'Registro bloqueado, se omite actualización';
    WHEN OTHERS THEN
        p_error := 'Error al intentar actualizar SHRMRKS: ' || SQLERRM;
        tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'error p_update_shrmrks', SQLERRM, USER);
END p_update_shrmrks;


function f_validatejasonfield(inputchar in varchar2)
    return varchar2
    is
        ret varchar(1024);
    begin
        if inputchar is null then
            ret := '';
        else            
            ret := trim(replace(inputchar, '"'));
        end if;

         ret := replace(replace(replace(
                replace(replace(replace(
                replace(replace(replace(
                replace(replace(replace(
                replace(ret,
                '\u00E1','á'),
                '\u00E9','é'),
                '\u00ED','í'),
                '\u00F3','ó'),
                '\u00FA','ú'),
                '\u00FA','u'),
                '\u00C1','A'),
                '\u00C9','E'),
                '\u00CD','I'),
                '\u00D3','O'),
                '\u00DA','U'),
                '\u00F1','?'),
                '\u00D1','?');
        return ret;
    end f_validatejasonfield;

  /**************************************************************************************************************************
   Nombre Procedure :p_mod011_registro
   Descripcion: Guardar registro desde sistema externo.
   Fecha ultima actualizacion: 2024 marzo
   Comentarios: --
   User: Andres Castillo  
  /**************************************************************************************************************************/
   PROCEDURE p_mod011_registro (
        json_entrada   IN             CLOB,
        p_outputdata   OUT            CLOB
    ) AS
     ---------------------------------------------------------------------------
        sociedad                   CHAR(4);
        tipo_documento             CHAR(1);
        num_documento              CHAR(20);
        nro_sri                    CHAR(17);
        nro_autorizacion           VARCHAR(49);
        estado                     CHAR(2);
        detalle                    CHAR(100);
        --Entrada

        obj                        json;
        obj1                       json;
        existe                     CHAR(1);
        error                      CHAR(1) := 'N';
        error_api                  varchar2(200);
        --Salida
        mensaje_error              CLOB;
        --
        valor_temporal             VARCHAR2(1024);
        nota_credito               CHAR(1) := 'N';
        factura                    CHAR(1) := 'N';
        cantidad_filas_afectadas   INT := 0;
        v_count                    INT:=0;
        v_chain                    CLOB;
        output_list                JSON_LIST;
        response_obj               json;
        input_list                 JSON_LIST;
        obj_value                  PLJSON_VALUE;
        temp_str                   VARCHAR2(4000);
        tempObj                    json;
        globalObj                  json;
        largeresponse              clob := ' ';
        largeInput                 clob := ' ';
		v_szrtdoc_code			   szrtdoc.szrtdoc_code%type;

        id_banner           varchar2(64);
        id_nrc          varchar2(64);
        id_term            varchar2(64);
        id_component               varchar2(64);
        component_grde               varchar2(64);
        component_score     varchar2(64);
        v_error             varchar2(1) := 'N';
        v_valid_gcom        varchar2(5);
        v_valid_nrc_term    varchar2(5);
        v_valid_nrc_term_act varchar2(5);
        v_valid_tckn_term varchar2(5);
        v_valid_regs_term varchar2(5);
        v_valid_estudiante varchar2(5);
        v_valid_regscomp_exist varchar2(5);

        cursor valid_gcom (p_crn varchar2, p_idcomp varchar2, p_term varchar2) is
        select 'Y'
        from shrgcom
        where SHRGCOM_CRN = p_crn
        and SHRGCOM_ID = p_idcomp
        and SHRGCOM_TERM_CODE = p_term;

        cursor valid_nrc_term (p_crn varchar2, p_term varchar2) is
        select 'Y'
        from ssbsect
        where ssbsect_crn = p_crn
        and ssbsect_term_code = p_term;

        cursor valid_nrc_term_act (p_crn varchar2, p_term varchar2) is
        select 'Y'
        from ssbsect
        where ssbsect_crn = p_crn
        and ssbsect_term_code = p_term
        and SSBSECT_SSTS_CODE = 'I';

        cursor valid_tckn_term (p_pidm varchar2, p_term varchar2) is
        select 'Y'
        from shrtckn
        where SHRTCKN_PIDM = p_pidm
        and SHRTCKN_TERM_CODE = p_term;

        cursor valid_regs_term (p_pidm varchar2, p_term varchar2, p_nrc varchar2) is
        select 'Y'
        from SFRSTCR
        where SFRSTCR_PIDM = p_pidm
        and SFRSTCR_TERM_CODE =p_term
        and SFRSTCR_CRN = p_nrc
        and SFRSTCR_RSTS_CODE IN ('RE','RW');

        cursor valid_regs_term_kn (p_pidm varchar2, p_term varchar2, p_nrc varchar2) is
        select 'Y'
        from SHRTCKN
        where SHRTCKN_PIDM = p_pidm
        and SHRTCKN_TERM_CODE =p_term
        and SHRTCKN_CRN = p_nrc;

        cursor valid_regscomp_exist (p_pidm varchar2, p_term varchar2, p_nrc varchar2, p_idcomp varchar2, component_grde varchar2) is
        select 'Y'
        from shrmrks
        where shrmrks_pidm = p_pidm
        and SHRMRKS_TERM_CODE = p_term
        and SHRMRKS_CRN = p_nrc
        and SHRMRKS_GCOM_ID = p_idcomp
        and SHRMRKS_GRDE_CODE = component_grde;


        cursor valid_estudiante (p_pidm varchar2) is
        select 'Y'
        from sovlcur
        where sovlcur_pidm = p_pidm;

        v_gmod_code varchar2(10);
        v_subj_code varchar2(10);
        v_crse varchar2(10);
        v_level_code varchar2(10);
        v_count_levl number(2);
        v_score varchar2(10);
        v_tipo_trama varchar2(10);
        i integer:= 0;
        v_counter NUMBER := 0; -- Contador de iteraciones

    BEGIN
        --DBMS_OUTPUT.disable;
        globalObj := json(json_entrada);
        begin
            globalObj.get('notasfinales').to_clob(largeInput);
            v_tipo_trama := 'notafinal';    
        exception
          when others then
            null;
        end;
        begin
            globalObj.get('notas').to_clob(largeInput);
            v_tipo_trama := 'nota';    
        exception
          when others then
            null;
        end;
        input_list := izt_interface_util.validate_jsonlist(largeInput);
        output_list := json_list();

        if v_tipo_trama = 'nota' then
            for i in 1..input_list.count
            loop
                    response_obj := json();
                    mensaje_error := '';
                    error := 'N';
                    v_valid_gcom        := null;
                    v_valid_nrc_term    := null;
                    v_valid_nrc_term_act := null;
                    v_valid_tckn_term := null;
                    v_valid_regs_term := null;
                    v_valid_estudiante := null;
                    v_valid_regscomp_exist := null;
                    -------------------------------------------------------------------
                    obj_value := input_list.get(i);
                    obj1 := json(obj_value);
                    --tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'p_mod011_registro', obj1.to_char, user);

                    --Validacion de errores
                    id_banner := izt_interface_util.validate_field(obj1, 'id_banner');
                    if id_banner = '' or id_banner is null then
                        mensaje_error := mensaje_error || 'El campo "id_banner" es obligatorio ';
                        error := 'Y';
                    end if;

                    id_nrc := izt_interface_util.validate_field(obj1, 'nrc');
                    if id_nrc = '' or id_nrc is null then
                        mensaje_error := mensaje_error || 'El campo nrc es obligatorio ';
                        error := 'Y';
                    end if;
                    id_component := izt_interface_util.validate_field(obj1, 'id_component');
                    if id_component = '' or id_component is null then
                        mensaje_error := mensaje_error || 'E003 - El campo id_component es obligatorio ';
                        error := 'Y';
                    end if;
                    component_grde := izt_interface_util.validate_field(obj1, 'component_grde');
                    if component_grde = '' or component_grde is null then
                        mensaje_error := mensaje_error || 'E002 - El campo component_grde es obligatorio ';
                        error := 'Y';
                    end if;

                    id_term := izt_interface_util.validate_field(obj1, 'term');
                    if id_term = '' or id_term is null then
                        mensaje_error := mensaje_error || 'El campo "term" es obligatorio ';
                        error := 'Y';                
                    end if;

                    tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'id_nrc', id_nrc, user);
                    tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'id_term', id_term, user);

                    tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'v_valid_nrc_term', v_valid_nrc_term, user);

                    open valid_nrc_term (id_nrc,id_term);
                    fetch valid_nrc_term into v_valid_nrc_term;
                    close valid_nrc_term;

                    tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'v_valid_nrc_term', v_valid_nrc_term, user);

                    if error = 'N' and v_valid_nrc_term is null then
                        mensaje_error := mensaje_error || 'E005 - No existe NRC en el periodo enviado ';
                        error := 'Y';                
                    end if;

                    open valid_nrc_term_act (id_nrc,id_term);
                    fetch valid_nrc_term_act into v_valid_nrc_term_act;
                    close valid_nrc_term_act;

                    if error = 'N' and v_valid_nrc_term_act is not null then
                        mensaje_error := mensaje_error || 'E006 - NRC está inactivo ';
                        error := 'Y';                
                    end if;

                    open valid_gcom (id_nrc,id_component,id_term);
                    fetch valid_gcom into v_valid_gcom;
                    close valid_gcom;

                    if error = 'N' and v_valid_gcom is null then
                        mensaje_error := mensaje_error || 'E004 - No existe parametrización del componente Calificable en SHAGCOM ';
                        error := 'Y';                
                    end if;

                    open valid_estudiante (gb_common.f_get_pidm(id_banner));
                    fetch valid_estudiante into v_valid_estudiante;
                    close valid_estudiante;

                    if error = 'N' and v_valid_estudiante is null then
                        mensaje_error := mensaje_error || 'E001 - No es estudiante matriculado ';
                        error := 'Y';                
                    end if;

                    open valid_tckn_term (gb_common.f_get_pidm(id_banner),id_term);
                    fetch valid_tckn_term into v_valid_tckn_term;
                    close valid_tckn_term;

                    --case 6321 quitar validacion req. puce
                    /*if error = 'N' and v_valid_tckn_term is not null then
                        mensaje_error := mensaje_error || 'E008 - Estudiante con notas en Historia academica ';
                        error := 'Y';                
                    end if;
                    */
                    BEGIN
                        OPEN valid_regs_term (gb_common.f_get_pidm(id_banner), id_term, id_nrc);
                        FETCH valid_regs_term INTO v_valid_regs_term;

                        IF valid_regs_term%NOTFOUND THEN
                            v_valid_regs_term := NULL; -- Asigna NULL si no hay resultados
                        END IF;

                        CLOSE valid_regs_term;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_valid_regs_term := NULL; -- Retorna NULL si no hay coincidencias
                        WHEN OTHERS THEN
                            v_valid_regs_term := NULL; -- Captura cualquier otro error
                            -- Opcional: Registrar el error en un log si es necesario
                            tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'error valid_regs_term', SQLERRM, USER);
                    END;


                    if error = 'N' and v_valid_regs_term is null then
                        mensaje_error := mensaje_error || 'E007 - Estudiante sin nrc inscrito en el periodo ';
                        error := 'Y';                
                    end if;

                    /*open valid_regscomp_exist (gb_common.f_get_pidm(id_banner),id_term,id_nrc,id_component, component_grde);
                    fetch valid_regscomp_exist into v_valid_regscomp_exist;
                    close valid_regscomp_exist;

                    if error = 'N' and v_valid_regscomp_exist is not null then
                        mensaje_error := mensaje_error || 'E010 - El componente ya esta calificado con esta misma nota '||component_grde;
                        error := 'Y';                
                    end if;*/

                    select ssbsect_gmod_code,ssbsect_subj_code,ssbsect_crse_numb
                    into v_gmod_code, v_subj_code, v_crse
                    from ssbsect
                    where ssbsect_term_code = id_term
                    and ssbsect_crn = id_nrc;

                    v_count_levl:=0;
                    select COUNT(*)
                    into v_count_levl
                    from scrlevl
                    where scrlevl_subj_code = v_subj_code
                    and   scrlevl_crse_numb = v_crse;  

                    tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'antes de update v_count_levl '||v_count_levl, SQLERRM, USER);

                    --if error = 'N' then
                        if v_count_levl = 0 then
                            mensaje_error := mensaje_error || 'E010 - Curso no tiene asociado nivel';
                            error := 'Y';
                        END IF;                        
                    --end if;

                    if error = 'N' then                  
                        --calcular score apartir de grade
                        --1. calcular gmod,subj,crse
                        select ssbsect_gmod_code,ssbsect_subj_code,ssbsect_crse_numb
                        into v_gmod_code, v_subj_code, v_crse
                        from ssbsect
                        where ssbsect_term_code = id_term
                        and ssbsect_crn = id_nrc;

                        --2- calcular level from subj and crse
                        /*
                        select scrlevl_levl_code 
                        into v_level_code
                        from scrlevl
                        where scrlevl_subj_code = v_subj_code
                        and   scrlevl_crse_numb = v_crse;                        
                        */
                        SELECT MIN(s.scrlevl_levl_code)
                        INTO   v_level_code
                        FROM   scrlevl s
                        WHERE  s.scrlevl_subj_code = v_subj_code
                        AND    s.scrlevl_crse_numb = v_crse
                        AND    EXISTS (
                                   SELECT 1 FROM shrgrde g
                                   WHERE  g.shrgrde_levl_code = s.scrlevl_levl_code
                                   AND    g.shrgrde_code      = component_grde
                               ) ;

                        --3 calcular score a partir de levl y grade
                        select shrgrde_numeric_value
                        into v_score
                        from shrgrde
                        where shrgrde_levl_code = v_level_code
                        and   shrgrde_code = component_grde;

                        tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'antes de update p_update_shrmrks '||gb_common.f_get_pidm(id_banner), SQLERRM, USER);

                        v_counter:=0;
                        --WHILE v_valid_regscomp_exist IS NULL AND v_counter < 2 LOOP
                            v_counter := v_counter + 1;

                            tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'durante update p_update_shrmrks '||gb_common.f_get_pidm(id_banner), SQLERRM, USER);

                            /*if error = 'N' and v_valid_regscomp_exist is not null then
                                mensaje_error := mensaje_error || 'E010 - El componente ya esta calificado con esta misma nota '||component_grde;
                                error := 'Y';                
                            end if;
                            */
                            begin

                            p_update_shrmrks(p_score	=> null,
                                                    p_pctage  		=> null,
                                                    p_grde_code 		=> component_grde,
                                                    p_gchg_code 		=> 'OE',
                                                    p_marker			=> null,
                                                    p_summary		=> null,
                                                    p_term_code		=> id_term,
                                                    p_crn			=> id_nrc,
                                                    p_pidm			=> gb_common.f_get_pidm(id_banner),
                                                    p_gcom_id_dest	=> id_component,
                                                    p_error         => error_api);
                            --commit;
                                                tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'error_api', error_api, user);

                                            if error_api <> 'N' then

                                                response_obj.put('TIPO_MENSAJE', 'E');
                                                mensaje_error := mensaje_error || error_api;
                                                response_obj.put('MENSAJE', mensaje_error);                
                                            else

                                                begin     
                                                /*DELETE shrcmrk WHERE shrcmrk_pidM=gb_common.f_get_pidm(id_banner) and shrcmrk_term_code=id_term and shrcmrk_crn=id_nrc;
                                                --shkegrb.p_shrcmrkprocess(term => id_term, 
                                                                                crn => id_nrc, 
                                                                                pidm => gb_common.f_get_pidm(id_banner),
                                                                                user_id => user); */                                       
                                                commit;
                                                response_obj.put('TIPO_MENSAJE', 'S');
                                                response_obj.put('MENSAJE', 'Registro exitoso');  
                                                exception
                                                when others then
                                                    response_obj.put('MENSAJE', SQLERRM||v_gmod_code||v_subj_code||v_crse||v_level_code||v_score);  
                                                    end;                                        
                                            end if;
                                open valid_regscomp_exist (gb_common.f_get_pidm(id_banner),id_term,id_nrc,id_component, component_grde);
                                fetch valid_regscomp_exist into v_valid_regscomp_exist;
                                close valid_regscomp_exist;   

                                exception when others then
                                    tzkpufc.p_ins_tzrrlog(NULL, 'INTERFACE_BANNER_MOODLE', 'error 0durante update SHRMRKS '||gb_common.f_get_pidm(id_banner), SQLERRM, USER);
                                end;
                        -- loop;
                    else

                        response_obj.put('TIPO_MENSAJE', 'E');
                        response_obj.put('MENSAJE', mensaje_error);                

                    end if;                
                    response_obj.put('id_banner', id_banner);
                    response_obj.put('nrc', id_nrc);
                    response_obj.put('id_term', id_term);                                         
                    response_obj.put('id_component', id_component);
                    output_list.append(response_obj.to_json_value);
            end loop;
            -----
            else
            globalObj.get('notasfinales').to_clob(largeInput);

            input_list := izt_interface_util.validate_jsonlist(largeInput);


            output_list := json_list();

            for i in 1..input_list.count
            loop
                    response_obj := json();
                    mensaje_error := '';
                    error := 'N';
                    v_valid_gcom        := null;
                    v_valid_nrc_term    := null;
                    v_valid_nrc_term_act := null;
                    v_valid_tckn_term := null;
                    v_valid_regs_term := null;
                    v_valid_estudiante := null;
                    v_valid_regscomp_exist := null;
                    -------------------------------------------------------------------
                    obj_value := input_list.get(i);
                    obj1 := json(obj_value);
                    --tzkpufc.p_ins_tzrrlog(null, 'INTERFACE_BANNER_MOODLE', 'p_mod011_registro', obj1.to_char, user);

                    --Validacion de errores
                    id_banner := izt_interface_util.validate_field(obj1, 'id_banner');
                    if id_banner = '' or id_banner is null then
                        mensaje_error := mensaje_error || 'El campo "id_banner" es obligatorio ';
                        error := 'Y';
                    end if;

                    id_nrc := izt_interface_util.validate_field(obj1, 'nrc');
                    if id_nrc = '' or id_nrc is null then
                        mensaje_error := mensaje_error || 'El campo nrc es obligatorio ';
                        error := 'Y';
                    end if;

                    id_term := izt_interface_util.validate_field(obj1, 'term');
                    if id_term = '' or id_term is null then
                        mensaje_error := mensaje_error || 'El campo "term" es obligatorio ';
                        error := 'Y';                
                    end if;


                    open valid_estudiante (gb_common.f_get_pidm(id_banner));
                    fetch valid_estudiante into v_valid_estudiante;
                    close valid_estudiante;

                    if error = 'N' and v_valid_estudiante is null then
                        mensaje_error := mensaje_error || 'E001 - No es estudiante matriculado ';
                        error := 'Y';                
                    end if;

                    open valid_regs_term_kn (gb_common.f_get_pidm(id_banner),id_term,id_nrc);
                    fetch valid_regs_term_kn into v_valid_regs_term;
                    close valid_regs_term_kn;

                    if error = 'N' and v_valid_regs_term is null then
                        mensaje_error := mensaje_error || 'E002 - Estudiante sin nrc en historia';
                        error := 'Y';                
                    end if;

                    component_grde := izt_interface_util.validate_field(obj1, 'final_grde');

                    -- Validar si el campo es nulo o vacío
                    if component_grde = '' or component_grde is null or component_grde = ' ' then
                        mensaje_error := mensaje_error || 'E003 - Curso llegó sin calificación final ';
                        error := 'Y';
                    -- Validar si el campo no es numérico
                    elsif not regexp_like(component_grde, '^\d+(\,\d+)?$') then
                        mensaje_error := mensaje_error || 'E004 - La calificación final no es un valor numérico válido ';
                        error := 'Y';
                    end if;


                    /*open valid_nrc_term (id_nrc,id_term);
                    fetch valid_nrc_term into v_valid_nrc_term;
                    close valid_nrc_term;

                    if error = 'N' and v_valid_nrc_term is null then
                        mensaje_error := mensaje_error || 'E005 - No existe NRC en el periodo enviado ';
                        error := 'Y';                
                    end if;*/


                    if error = 'N' then                  

                                        begin
                                        update shrtckn
                                        set shrtckn_course_comment = izt_interface_util.validate_field(obj1, 'final_grde'),
                                        shrtckn_user_id=user
                                        where shrtckn_pidm = gb_common.f_get_pidm(id_banner)
                                        and shrtckn_crn = id_nrc
                                        and shrtckn_term_code = id_term;
                                        commit;
                                            response_obj.put('TIPO_MENSAJE', 'S');
                                            response_obj.put('MENSAJE', 'E005 - OK Nota registrada exitosamente');  
                                            response_obj.put('id_banner', id_banner);
                                            response_obj.put('nrc', id_nrc);
                                            response_obj.put('id_term', id_term);                                         
                                            --response_obj.put('final_grde', final_grde);
                                            --output_list.append(response_obj.to_json_value);
                                            exception
                                            when others then
                                                response_obj.put('MENSAJE', SQLERRM);  
                                        end;                                                                                

                    else

                        response_obj.put('TIPO_MENSAJE', 'E');
                        response_obj.put('MENSAJE', mensaje_error);                
                        response_obj.put('id_banner', id_banner);
                        response_obj.put('nrc', id_nrc);
                        response_obj.put('id_term', id_term);  
                        --output_list.append(response_obj.to_json_value);
                    end if;                
                    output_list.append(response_obj.to_json_value);
            end loop;
            ---notasfinales
            end if;
        tempObj := json();
        tempObj.put('Log', output_list.to_json_value);

        tempObj.to_clob(largeresponse);

        p_outputdata := largeresponse;
        -------------------------------------------------------------------------------
        ztz_async_proc.ps_setDataForPublish('MOD011', json_entrada, p_outputdata);
        -------------------------------------------------------------------------------
    /*BEGIN
        PROCESS_IZTZM11;
        PROCESS_IZTZM11_NF;    
    END;*/
    exception
      when others then
        response_obj.put('TIPO_MENSAJE', 'E');
        response_obj.put('MENSAJE', SQLERRM);                
    END p_mod011_registro;

procedure mod_011_saveLog(v_recid in number, resultJson in clob, responseJson in clob)
        is
            msgList json_list;
            itemObj json;
            idx number;
            record_timestamp timestamp;
            numRecs number;
            detailProc varchar2(4000) := '';
            tempObj json;
            respObj json;
            respobjTemp json;
            tempObjRolCli json;
            respobjRolCli json;
            respobjRolPro json;
            respObjPos json;
            ret varchar2(1024) := '';
            mssgObjList json_list;
            errorCount number := 0;

        begin
            ---------------------------------------------------------------------------------------------

           --if substr(trim(DBMS_LOB.SUBSTR(resultJson)), 1, 1) <> '{' then
           if resultJson is null then
                    null;--detailproc := resultJson;
                else
                    --begin
                        /*tempobj := json(resultJson);
                        respobj := json(tempobj.get('devolucion'));

                        insert into IZLG06H (
                                    IZLG06H_IDPROC,
                                    IZLG06H_ID_BANNER,
                                    IZLG06H_NUM_DOCUMENTO,
                                    IZLG06H_NCRED_SRI,
                                    IZLG06H_VALOR,
                                    IZLG06H_FECHA_TRANSAC,
                                    IZLG06H_ACTIVITY_DATE,
									IZLG06H_MESSAGE_TYPE,
									IZLG06H_MESSAGE,
									IZLG06H_MESSAGE_DATE
                                    )
                        values
                        (
                        v_recid,
                        ifi_validatejasonfield(respobj, 'id_banner'),
                        ifi_validatejasonfield(respobj, 'num_documento'),
                        ifi_validatejasonfield(respobj, 'ncred_sri'),
                        ifi_validatejasonfield(respobj, 'valor'),
                        ifi_validatejasonfield(respobj, 'fecha_transac'),
                        sysdate,
						ifi005_validatejasonfield(json(responseJson), 'TIPO_MENSAJE'),
						ifi005_validatejasonfield(json(responseJson), 'MENSAJE'),
						sysdate
                        );


                    exception
                        when others then
                         return;
                    end;

                    commit;
                */
                null;
           end if;
           ---------------------------------------------------------------------------------------------
    end mod_011_saveLog;

END IZT_INTERFACE_LEGACY_MODPUB;




/
