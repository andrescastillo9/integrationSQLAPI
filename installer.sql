--install tmeporal solution crear terceros

--------------------------------------------------------
-- DDL para la Tabla de Registro/Auditoría de Terceros
--------------------------------------------------------


-- Otorgar permisos sobre el procedimiento orquestador principal
GRANT EXECUTE ON DESARROLLO.PR_MIGRACION_MASIVA_ORQUESTADOR TO MIGRACION;

-- Otorgar permisos sobre el procedimiento de contrato único
GRANT EXECUTE ON DESARROLLO.PR_MIGRAR_CONTRATO_UNICO TO MIGRACION;
GRANT EXECUTE ON DESARROLLO.SMART_GESTION_CONTRATOS.P_PROCESO_CONTRATO TO MIGRACION,INTEGRACION;

-- Otorgar permisos sobre el paquete que contiene las funciones (f_crear_titular, f_crear_beneficiario, f_crear_infofinanciera)
GRANT EXECUTE ON DESARROLLO.SMART_GESTION_CONTRATOS TO MIGRACION;

GRANT EXECUTE ON DESARROLLO.P_MIGRAR_TERCEROS_BATCH TO MIGRACION;
GRANT EXECUTE ON DESARROLLO.P_PROCESAR_ADMISIONES_BATCH TO MIGRACION;

-- Otorgar permisos de Inserción, Borrado, Selección y Actualización sobre la tabla temporal
GRANT SELECT, INSERT, UPDATE, DELETE ON DESARROLLO.TEMP_CONTRATOS TO MIGRACION;

GRANT SELECT, INSERT, UPDATE, DELETE ON "DESARROLLO"."IZTZTER" TO MIGRACION;

GRANT SELECT, INSERT, UPDATE, DELETE ON "DESARROLLO"."IZTZADM" TO MIGRACION;


CREATE OR REPLACE TRIGGER SATURN.SZ_SARADAP_INSERT
BEFORE INSERT ON SARADAP
FOR EACH ROW
DECLARE
BEGIN
    IF :NEW.SARADAP_DATA_ORIGIN = 'IGZ_INT_CRM' AND :NEW.SARADAP_APPL_NO > 0 THEN
        :NEW.SARADAP_APPL_PREFERENCE := :NEW.SARADAP_APPL_NO + 1;
    END IF;
END SZ_SARADAP_INSERT;
/
ALTER TRIGGER SATURN.SZ_SARADAP_INSERT ENABLE;

CREATE TABLE "DESARROLLO"."IZTZTER" (
    -- Clave Primaria y Control Técnico
    "IZTZTER_ID"               NUMBER GENERATED ALWAYS AS IDENTITY 
                               MINVALUE 1 MAXVALUE 9999999999999999999999999999 
                               INCREMENT BY 1 START WITH 1 
                               CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE,
    "IZTZTER_ACTIVITY_DATE"    DATE DEFAULT SYSDATE,
    "IZTZTER_USER_ID"          VARCHAR2(50 BYTE) DEFAULT USER,

    ----------------------------------------------------------------------------
    -- DATOS DE ENTRADA (Mapeo de r_tercero_in)
    ----------------------------------------------------------------------------
    "IZTZTER_ENTITY_IND"       VARCHAR2(1 BYTE),
    "IZTZTER_TIPO_DOC"         VARCHAR2(100 BYTE),
    "IZTZTER_DOC_NUMBER"       VARCHAR2(30 BYTE),       -- spbpers.spbpers_ssn%TYPE
    "IZTZTER_FIRST_NAME"       VARCHAR2(60 BYTE),       -- spriden.spriden_first_name%TYPE
    "IZTZTER_MIDDLE_NAME"      VARCHAR2(60 BYTE),       -- spriden.spriden_mi%TYPE
    "IZTZTER_LAST_NAME"        VARCHAR2(60 BYTE),       -- spriden.spriden_last_name%TYPE
    "IZTZTER_EMAIL"            VARCHAR2(128 BYTE),      -- goremal.goremal_email_address%TYPE
    "IZTZTER_CELULAR"          VARCHAR2(30 BYTE),       -- sprtele.sprtele_phone_number%TYPE
    "IZTZTER_DIRECCION"        VARCHAR2(255 BYTE),      -- spraddr.spraddr_street_line1%TYPE
    "IZTZTER_PAIS_SF"          VARCHAR2(100 BYTE),
    "IZTZTER_DEPT_SF"          VARCHAR2(100 BYTE),
    "IZTZTER_CIUDAD_SF"        VARCHAR2(100 BYTE),
    "IZTZTER_SEX_SF"           VARCHAR2(100 BYTE),
    "IZTZTER_MRTL_CODE_SF"     VARCHAR2(100 BYTE),
    "IZTZTER_BIRTH_DATE"       DATE,
    "IZTZTER_EXPI_DATE_EXP"    DATE,
    "IZTZTER_VERF_DIGIT"       VARCHAR2(100 BYTE),
    "IZTZTER_CONFID_IND"       VARCHAR2(100 BYTE),

    ----------------------------------------------------------------------------
    -- DATOS DE SALIDA Y RESULTADO (Mapeo de r_tercero_out)
    ----------------------------------------------------------------------------
    "IZTZTER_COINCIDENCIA"     VARCHAR2(1 BYTE),
    "IZTZTER_PIDM"             NUMBER(8,0),             -- spriden.spriden_pidm%TYPE
    "IZTZTER_ID_BANNER"        VARCHAR2(9 BYTE),        -- spriden.spriden_id%TYPE
    "IZTZTER_OUT_TIPO_DOC"     VARCHAR2(100 BYTE),
    "IZTZTER_OUT_NUMERO_DOC"   VARCHAR2(30 BYTE),       -- spbpers.spbpers_ssn%TYPE
    "IZTZTER_OUT_EMAIL"        VARCHAR2(128 BYTE),      -- goremal.goremal_email_address%TYPE
    "IZTZTER_MENSAJE"          VARCHAR2(4000 BYTE),
    "IZTZTER_LINEA_ERROR"      VARCHAR2(4000 BYTE),

    CONSTRAINT "PK_IZTZTER" PRIMARY KEY ("IZTZTER_ID")
) 
GRANT EXECUTE ON INTEGRACION.IGZ_INT_CRM TO BANINST1;
GRANT EXECUTE ON INTEGRACION.IGZ_INT_CRM TO DESARROLLO;
CREATE OR REPLACE PUBLIC SYNONYM IGZ_INT_CRM FOR INTEGRACION.IGZ_INT_CRM;

CREATE OR REPLACE PROCEDURE DESARROLLO.P_MIGRAR_TERCEROS_BATCH (
    p_limite_registros IN NUMBER DEFAULT NULL -- Permite procesar un número máximo opcional
) IS
    -- Cursor de procesamiento sin FOR UPDATE para permitir COMMITS
    CURSOR c_terceros IS
        SELECT IZTZTER_ID,
               IZTZTER_ENTITY_IND,
               IZTZTER_TIPO_DOC,
               IZTZTER_DOC_NUMBER,
               IZTZTER_FIRST_NAME,
               IZTZTER_MIDDLE_NAME,
               IZTZTER_LAST_NAME,
               IZTZTER_EMAIL,
               IZTZTER_CELULAR,
               IZTZTER_DIRECCION,
               IZTZTER_PAIS_SF,
               IZTZTER_DEPT_SF,
               IZTZTER_CIUDAD_SF,
               IZTZTER_SEX_SF,
               IZTZTER_MRTL_CODE_SF,
               IZTZTER_BIRTH_DATE,
               IZTZTER_EXPI_DATE_EXP,
               IZTZTER_VERF_DIGIT,
               IZTZTER_CONFID_IND
          FROM DESARROLLO.IZTZTER
         WHERE IZTZTER_COINCIDENCIA IS NULL;

    -- Variables para RECORDs del Paquete de Integración
    v_tercero_in  INTEGRACION.IGZ_INT_CRM.r_tercero_in;
    v_tercero_out INTEGRACION.IGZ_INT_CRM.r_tercero_out;

    -- Contadores de control
    v_procesados  NUMBER := 0;
    v_errores     NUMBER := 0;

    -- Variables de captura de error
    v_err_msg     VARCHAR2(4000);
    v_err_trace   VARCHAR2(4000);

BEGIN
    DBMS_OUTPUT.ENABLE(1000000);
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO PROCEDIMIENTO BATCH: MIGRACION TERCEROS ===');

    FOR r_rec IN c_terceros LOOP
        BEGIN
            -- 1. Mapeo de la tabla al RECORD de Entrada
            v_tercero_in.entity_ind     := r_rec.IZTZTER_ENTITY_IND;
            v_tercero_in.tipo_doc       := r_rec.IZTZTER_TIPO_DOC;
            v_tercero_in.doc_number     := r_rec.IZTZTER_DOC_NUMBER;
            v_tercero_in.first_name     := r_rec.IZTZTER_FIRST_NAME;
            v_tercero_in.middle_name    := r_rec.IZTZTER_MIDDLE_NAME;
            v_tercero_in.last_name      := r_rec.IZTZTER_LAST_NAME;
            v_tercero_in.email          := r_rec.IZTZTER_EMAIL;
            v_tercero_in.celular        := r_rec.IZTZTER_CELULAR;
            v_tercero_in.direccion      := r_rec.IZTZTER_DIRECCION;
            v_tercero_in.pais_sf        := r_rec.IZTZTER_PAIS_SF;
            v_tercero_in.dept_sf        := r_rec.IZTZTER_DEPT_SF;
            v_tercero_in.ciudad_sf      := r_rec.IZTZTER_CIUDAD_SF;
            v_tercero_in.sex_sf         := r_rec.IZTZTER_SEX_SF;
            v_tercero_in.mrtl_code_sf   := r_rec.IZTZTER_MRTL_CODE_SF;
            v_tercero_in.birth_date     := r_rec.IZTZTER_BIRTH_DATE;
            v_tercero_in.expi_date_exp := r_rec.IZTZTER_EXPI_DATE_EXP;
            v_tercero_in.verf_digit     := r_rec.IZTZTER_VERF_DIGIT;
            v_tercero_in.confid_ind     := r_rec.IZTZTER_CONFID_IND;

            -- 2. Invocación del procedimiento de negocio en INTEGRACION
            INTEGRACION.IGZ_INT_CRM.p_process_third_party(
                p_tercero_in  => v_tercero_in,
                p_tercero_out => v_tercero_out
            );

            -- 3. Actualización de salida por ID
            UPDATE DESARROLLO.IZTZTER
               SET IZTZTER_COINCIDENCIA   = v_tercero_out.coincidencia,
                   IZTZTER_PIDM           = v_tercero_out.pidm,
                   IZTZTER_ID_BANNER      = v_tercero_out.id_banner,
                   IZTZTER_OUT_TIPO_DOC   = v_tercero_out.tipo_documento,
                   IZTZTER_OUT_NUMERO_DOC = v_tercero_out.numero_documento,
                   IZTZTER_OUT_EMAIL      = v_tercero_out.email,
                   IZTZTER_MENSAJE        = v_tercero_out.mensaje,
                   IZTZTER_LINEA_ERROR    = v_tercero_out.linea_error,
                   IZTZTER_ACTIVITY_DATE  = SYSDATE,
                   IZTZTER_USER_ID        = USER
             WHERE IZTZTER_ID = r_rec.IZTZTER_ID;

            v_procesados := v_procesados + 1;

        EXCEPTION
            WHEN OTHERS THEN
                v_errores   := v_errores + 1;
                v_err_msg   := SUBSTR(SQLERRM, 1, 3500);
                v_err_trace := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

                UPDATE DESARROLLO.IZTZTER
                   SET IZTZTER_COINCIDENCIA   = 'E',
                       IZTZTER_MENSAJE        = 'Error en ejecución PL/SQL: ' || v_err_msg,
                       IZTZTER_LINEA_ERROR    = v_err_trace,
                       IZTZTER_ACTIVITY_DATE  = SYSDATE,
                       IZTZTER_USER_ID        = USER
                 WHERE IZTZTER_ID = r_rec.IZTZTER_ID;
        END;

        -- Commit cada 100 registros procesados
        IF MOD(v_procesados + v_errores, 100) = 0 THEN
            COMMIT;
        END IF;

        -- Detención opcional si se alcanzó el límite especificado en parámetro
        IF p_limite_registros IS NOT NULL AND (v_procesados + v_errores) >= p_limite_registros THEN
            EXIT;
        END IF;

    END LOOP;

    -- Commit final de la transacción
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('PROCESO FINALIZADO');
    DBMS_OUTPUT.PUT_LINE('Total Registros Exitosos : ' || v_procesados);
    DBMS_OUTPUT.PUT_LINE('Total Registros Erróneos : ' || v_errores);
    DBMS_OUTPUT.PUT_LINE('==================================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error no controlado en P_MIGRAR_TERCEROS_BATCH: ' || SQLERRM);
END P_MIGRAR_TERCEROS_BATCH;
/

CREATE TABLE "DESARROLLO"."IZTZADM" (
    -- Clave Primaria y Control Técnico
    "IZTZADM_ID"               NUMBER GENERATED ALWAYS AS IDENTITY 
                               MINVALUE 1 MAXVALUE 9999999999999999999999999999 
                               INCREMENT BY 1 START WITH 1 
                               CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE,
    "IZTZADM_ACTIVITY_DATE"    DATE DEFAULT SYSDATE,
    "IZTZADM_USER_ID"          VARCHAR2(50 BYTE) DEFAULT USER,

    ----------------------------------------------------------------------------
    -- DATOS DE ENTRADA (Mapeo de Parámetros de Entrada)
    ----------------------------------------------------------------------------
    "IZTZADM_PIDM"             NUMBER(8,0),             -- spriden.spriden_pidm%TYPE
    "IZTZADM_TERM_CODE_ENTRY"  VARCHAR2(6 BYTE),        -- stvterm.stvterm_code%TYPE
    "IZTZADM_ADMT_CODE"        VARCHAR2(2 BYTE),        -- stvadmt.stvadmt_code%TYPE
    "IZTZADM_SITE_CODE"        VARCHAR2(10 BYTE),       -- stvsite.stvsite_code%TYPE
    "IZTZADM_STYP_CODE"        VARCHAR2(2 BYTE),        -- stvstyp.stvstyp_code%TYPE
    "IZTZADM_APST_CODE"        VARCHAR2(2 BYTE),        -- stvapst.stvapst_code%TYPE
    "IZTZADM_RESD_CODE"        VARCHAR2(2 BYTE),        -- stvresd.stvresd_code%TYPE
    "IZTZADM_APPL_PREFERENCE"  NUMBER(2,0),
    "IZTZADM_PROGRAM_1"        VARCHAR2(12 BYTE),       -- smrprle.smrprle_program%TYPE

    ----------------------------------------------------------------------------
    -- DATOS DE SALIDA Y RESULTADO (Mapeo de Salida p_process_admission)
    ----------------------------------------------------------------------------
    "IZTZADM_APPL_NO"          NUMBER(2,0),             -- saradap.saradap_appl_no%TYPE
    "IZTZADM_ROWID_SARADAP"    VARCHAR2(18 BYTE),       -- ROWID generado en SARADAP
    "IZTZADM_STATUS"           VARCHAR2(10 BYTE),       -- 'S' (Éxito) / 'E' (Error) / NULL (Pendiente)
    "IZTZADM_MENSAJE"          VARCHAR2(4000 BYTE),     -- Mensaje descriptivo retornado
    "IZTZADM_LINEA_ERROR"      VARCHAR2(4000 BYTE),     -- Trace del error si aplica

    CONSTRAINT "PK_IZTZADM" PRIMARY KEY ("IZTZADM_ID")
) ;
--------------------------------------------------------
-- Permisos y Privilegios
--------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON "DESARROLLO"."IZTZADM" TO "BANINST1";
GRANT SELECT, INSERT, UPDATE, DELETE ON "DESARROLLO"."IZTZADM" TO "INTEGRACION";


CREATE OR REPLACE PROCEDURE DESARROLLO.P_PROCESAR_ADMISIONES_BATCH (
    p_limite_registros IN NUMBER DEFAULT NULL -- Límite opcional de registros a procesar
) IS
    -- Cursor de lectura sobre registros no procesados o pendientes
    CURSOR c_admisiones IS
        SELECT IZTZADM_ID,
               IZTZADM_PIDM,
               IZTZADM_TERM_CODE_ENTRY,
               IZTZADM_ADMT_CODE,
               IZTZADM_SITE_CODE,
               IZTZADM_STYP_CODE,
               IZTZADM_APST_CODE,
               IZTZADM_RESD_CODE,
               IZTZADM_APPL_PREFERENCE,
               IZTZADM_PROGRAM_1
          FROM DESARROLLO.IZTZADM
         WHERE IZTZADM_STATUS IS NULL;

    -- Variables para almacenar los parámetros de salida de p_process_admission
    v_appl_no_out   NUMBER;
    v_rowid_out     ROWID;
    v_status_out    VARCHAR2(10);
    v_message_out   VARCHAR2(4000);

    -- Contadores de control
    v_procesados    NUMBER := 0;
    v_errores       NUMBER := 0;

    -- Variables para captura de excepciones locales
    v_err_msg       VARCHAR2(4000);
    v_err_trace     VARCHAR2(4000);

BEGIN
    DBMS_OUTPUT.ENABLE(1000000);
    DBMS_OUTPUT.PUT_LINE('=== INICIANDO BATCH: PROCESAMIENTO DE ADMISIONES ===');

    FOR r_rec IN c_admisiones LOOP
        BEGIN
            -- 1. Invocación del procedimiento de negocio en el esquema INTEGRACION
            INTEGRACION.IGZ_INT_CRM.p_process_admission(
                p_pidm            => r_rec.IZTZADM_PIDM,
                p_term_code_entry => r_rec.IZTZADM_TERM_CODE_ENTRY,
                p_admt_code       => r_rec.IZTZADM_ADMT_CODE,
                p_site_code       => r_rec.IZTZADM_SITE_CODE,
                p_styp_code       => r_rec.IZTZADM_STYP_CODE,
                p_apst_code       => r_rec.IZTZADM_APST_CODE,
                p_resd_code       => r_rec.IZTZADM_RESD_CODE,
                p_appl_preference => r_rec.IZTZADM_APPL_PREFERENCE,
                p_program_1       => r_rec.IZTZADM_PROGRAM_1,
                p_appl_no_out     => v_appl_no_out,
                p_rowid_out       => v_rowid_out,
                p_status_out      => v_status_out,
                p_message_out     => v_message_out
            );

            -- 2. Actualización de los resultados en la tabla IZTZADM por ID
            UPDATE DESARROLLO.IZTZADM
               SET IZTZADM_APPL_NO       = v_appl_no_out,
                   IZTZADM_ROWID_SARADAP = CAST(v_rowid_out AS VARCHAR2(18)),
                   IZTZADM_STATUS        = v_status_out,
                   IZTZADM_MENSAJE       = v_message_out,
                   IZTZADM_LINEA_ERROR   = NULL,
                   IZTZADM_ACTIVITY_DATE = SYSDATE,
                   IZTZADM_USER_ID       = USER
             WHERE IZTZADM_ID = r_rec.IZTZADM_ID;

            IF v_status_out = 'S' THEN
                v_procesados := v_procesados + 1;
            ELSE
                v_errores := v_errores + 1;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                -- Control individual de excepciones para evitar la caída del lote completo
                v_errores   := v_errores + 1;
                v_err_msg   := SUBSTR(SQLERRM, 1, 3500);
                v_err_trace := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

                UPDATE DESARROLLO.IZTZADM
                   SET IZTZADM_STATUS        = 'E',
                       IZTZADM_MENSAJE       = 'Error no controlado en PL/SQL: ' || v_err_msg,
                       IZTZADM_LINEA_ERROR   = v_err_trace,
                       IZTZADM_ACTIVITY_DATE = SYSDATE,
                       IZTZADM_USER_ID       = USER
                 WHERE IZTZADM_ID = r_rec.IZTZADM_ID;
        END;

        -- Commit incremental cada 100 registros procesados
        IF MOD(v_procesados + v_errores, 100) = 0 THEN
            COMMIT;
        END IF;

        -- Finalización opcional por límite de registros
        IF p_limite_registros IS NOT NULL AND (v_procesados + v_errores) >= p_limite_registros THEN
            EXIT;
        END IF;

    END LOOP;

    -- Commit final de la transacción
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('PROCESAMIENTO FINALIZADO');
    DBMS_OUTPUT.PUT_LINE('Solicitudes Exitosas : ' || v_procesados);
    DBMS_OUTPUT.PUT_LINE('Solicitudes con Error: ' || v_errores);
    DBMS_OUTPUT.PUT_LINE('==================================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error crítico fatal en P_PROCESAR_ADMISIONES_BATCH: ' || SQLERRM);
END P_PROCESAR_ADMISIONES_BATCH;
/













----------INSTALL

CREATE OR REPLACE EDITIONABLE TRIGGER "BANINST1"."TRG_SORTEST_INTERFAZ_SALESFORCE"
AFTER INSERT OR UPDATE ON "SATURN"."SORTEST"
FOR EACH ROW
DECLARE
v_job_name   VARCHAR2(100);
v_job_action CLOB;
v_start_date TIMESTAMP WITH TIME ZONE;
-- Variables para detalle extendido de error
v_error_msg  VARCHAR2(4000);
v_backtrace  VARCHAR2(4000);

BEGIN
-- 1. Crear un nombre de JOB único combinando la llave de la tabla y un timestamp
v_job_name := 'JOB_SORTEST_' || :NEW.sortest_pidm || '' || :NEW.sortest_tesc_code || '' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF');
-- 2. Configurar el retardo de 5 segundos requerido
v_start_date := SYSTIMESTAMP + INTERVAL '5' SECOND;

-- 3. Construir el bloque PL/SQL dinámico que llamará al procedimiento
v_job_action := 'BEGIN 
                    IGZ_INT_CRM.p_point003_banner_to_salesforce(
                        p_pidm       => ' || :NEW.sortest_pidm || ',
                        p_test_code  => ''' || :NEW.sortest_tesc_code || ''',
                        p_test_score => ''' || :NEW.sortest_test_score || '''
                    );
                 END;';

-- Log informativo de los datos enviados a la cola del Scheduler
log4plsq.plog.info(
    'TRG_SORTEST_INTERFAZ_SALESFORCE: Programando Job [' || v_job_name || '] ' ||
    'para PIDM=' || :NEW.sortest_pidm || 
    ', TestCode=' || :NEW.sortest_tesc_code || 
    ', TestScore=' || :NEW.sortest_test_score || 
    ' | Action: ' || v_job_action
);

-- 4. Invocar el procedimiento para registrar el Scheduler Job temporal
INTEGRACION.ZTZ_ASYNC_PROC.P_CREATE_SCHEDULER_JOB (
    p_job_name   => v_job_name,
    p_job_action => v_job_action,
    p_start_date => v_start_date
);

EXCEPTION
WHEN OTHERS THEN
-- Captura del mensaje de error y la línea exacta del Backtrace
v_error_msg := SQLERRM;
v_backtrace := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

-- Registrar el detalle extendido en la tabla de logs de log4plsq
    log4plsq.plog.error(
        'TRG_SORTEST_INTERFAZ_SALESFORCE Error (PIDM: ' || NVL(TO_CHAR(:NEW.sortest_pidm), 'N/A') || 
        ', Test: ' || NVL(:NEW.sortest_tesc_code, 'N/A') || ') | Error: ' || v_error_msg || 
        ' | Linea/Backtrace: ' || REPLACE(v_backtrace, CHR(10), ' ')
    );

    -- Salida en consola con detalle de línea para depuración inmediata en SQL Developer / PL/SQL Developer
    DBMS_OUTPUT.PUT_LINE('Error en TRG_SORTEST_INTERFAZ_SALESFORCE: ' || v_error_msg);
    DBMS_OUTPUT.PUT_LINE('Detalle Linea (Backtrace): ' || v_backtrace);
    
END;
/
ALTER TRIGGER "BANINST1"."TRG_SORTEST_INTERFAZ_SALESFORCE" ENABLE;    
-- 1. Asignar privilegios directos sobre la tabla SARADAP al usuario INTEGRACION
GRANT SELECT, INSERT, UPDATE, DELETE ON SATURN.SARADAP TO INTEGRACION;
-- 1. Asignar privilegio de ejecución sobre el paquete SAKDCSN al usuario INTEGRACION
GRANT EXECUTE ON SAKDCSN TO INTEGRACION;
GRANT EXECUTE ON SAKDCSN TO INTEGRACION;
GRANT EXECUTE ON SB_FIELDOFSTUDY TO INTEGRACION;
GRANT EXECUTE ON BANINST1.SB_STUDYPATH TO INTEGRACION;
-- Permiso para el paquete del Scheduler/Cola Asíncrona
GRANT EXECUTE ON INTEGRACION.ZTZ_ASYNC_PROC TO BANINST1;
GRANT EXECUTE ON INTEGRACION.ZTZ_ASYNC_PROC TO SATURN;
GRANT SELECT, INSERT, UPDATE, DELETE ON SATURN.sarchkl TO INTEGRACION;
GRANT SELECT, INSERT, UPDATE, DELETE ON SATURN.sgbstdn TO INTEGRACION;

SELECT argument_name, data_type, in_out
FROM all_arguments
WHERE object_name = 'P_CREATE'
  AND package_name = 'SB_STUDYPATH'
ORDER BY sequence;
-- Permiso para el procedimiento de integración
GRANT EXECUTE ON IGZ_INT_CRM.p_point003_banner_to_salesforce TO BANINST1;

GRANT EXECUTE ON IGZ_INT_CRM.P_POINT003_BANNER_TO_SALESFORCE TO BANINST1;
-- Permiso para el paquete de trazabilidad (si aplica)
GRANT EXECUTE ON log4plsq.plog TO BANINST1;

ALTER TRIGGER "BANINST1"."TRG_SORTEST_INTERFAZ_SALESFORCE" ENABLE;

GRANT EXECUTE ON INTEGRACION.ZTZ_ASYNC_PROC TO BANINST1; 

Insert into IZTZCFG (IZTZCFG_IZTID,IZTZCFG_ACTIVITY_DATE,IZTZCFG_DATA_ORIGIN,IZTZCFG_USER_ID,IZTZCFG_NAME,IZTZCFG_DESCRIPTION,IZTZCFG_REQUEST_URL,IZTZCFG_REQUEST_METHOD,IZTZCFG_REQUEST_MODE,IZTZCFG_TABLE_NAME,IZTZCFG_SOURCE_SYSTEM,IZTZCFG_CHANGE_IND,IZTZCFG_AUTHORIZATION,IZTZCFG_WS_TYPE,IZTZCFG_CONTENT_TYPE,IZTZCFG_RESPONSE_HANDLE,IZTZCFG_HEADER_ACCEPT,IZTZCFG_WALLET_PATH,IZTZCFG_WALLET_PASSWORD) 
values ('SAL003',to_date('15-APR-24','DD-MON-RR'),'INTERFAZ','INTEGRACION','SAL003','Envió test clasificación',null,'POST','BATCH','IZTZM03','SALESFORCE',null,'Basic SVpUX1NBUDpORU9SSVNfTU9EMDEx','CON','text/plain',null,'text/plain',null,null);

-- Insert para la prueba de clasificación de Inglés
INSERT INTO gtvsdax (
    gtvsdax_external_code,
    gtvsdax_internal_code,
    gtvsdax_reporting_date,
    gtvsdax_translation_code,
    gtvsdax_internal_code_seqno,
    gtvsdax_internal_code_group,
    gtvsdax_desc,
    gtvsdax_sysreq_ind,
    gtvsdax_activity_date,
    gtvsdax_user_id,
    gtvsdax_sysi_code,
    gtvsdax_concept,
    gtvsdax_comments,
    gtvsdax_surrogate_id,
    gtvsdax_version,
    gtvsdax_data_origin,
    gtvsdax_vpdi_code
) VALUES (
    'Inglés',
    'INT_SALFOR',
    NULL,
    NULL,
    1,
    'INTERFACE_SALESFORCE',
    'Common Matching Salesforce CRM',
    'N',
    SYSDATE,
    'BANINST1',
    'G',
    'COMMON MATCHING',
    'DESEA_PRESENTAR_TEST',
    NULL,
    0,
    'INTEGRACION',
    NULL
);

-- Insert para la prueba de clasificación de Francés
INSERT INTO gtvsdax (
    gtvsdax_external_code,
    gtvsdax_internal_code,
    gtvsdax_reporting_date,
    gtvsdax_translation_code,
    gtvsdax_internal_code_seqno,
    gtvsdax_internal_code_group,
    gtvsdax_desc,
    gtvsdax_sysreq_ind,
    gtvsdax_activity_date,
    gtvsdax_user_id,
    gtvsdax_sysi_code,
    gtvsdax_concept,
    gtvsdax_comments,
    gtvsdax_surrogate_id,
    gtvsdax_version,
    gtvsdax_data_origin,
    gtvsdax_vpdi_code
) VALUES (
    'Frances',
    'INT_SALFOR',
    NULL,
    NULL,
    2,
    'INTERFACE_SALESFORCE',
    'Common Matching Salesforce CRM',
    'N',
    SYSDATE,
    'BANINST1',
    'G',
    'COMMON MATCHING',
    'TEST_CLAS_FRANC',
    NULL,
    0,
    'INTEGRACION',
    NULL
);

COMMIT;


  SELECT
                *
            FROM
                gorcmsr
            WHERE
                gorcmsr_cmsc_code = 'PERSON'
--installer

--Crear perfil de coincidencia común
INSERT INTO gtvsdax (
    gtvsdax_external_code,
    gtvsdax_internal_code,
    gtvsdax_reporting_date,
    gtvsdax_translation_code,
    gtvsdax_internal_code_seqno,
    gtvsdax_internal_code_group,
    gtvsdax_desc,
    gtvsdax_sysreq_ind,
    gtvsdax_activity_date,
    gtvsdax_user_id,
    gtvsdax_sysi_code,
    gtvsdax_concept,
    gtvsdax_comments,
    gtvsdax_surrogate_id,
    gtvsdax_version,
    gtvsdax_data_origin,
    gtvsdax_vpdi_code
) VALUES (
    'CRM SALESFORCE',                       -- GTVSDAX_EXTERNAL_CODE
    'MATCH',                                -- GTVSDAX_INTERNAL_CODE
    NULL,                                   -- GTVSDAX_REPORTING_DATE
    NULL,                                   -- GTVSDAX_TRANSLATION_CODE
    1,                                      -- GTVSDAX_INTERNAL_CODE_SEQNO
    'INTERFACE_SALESFORCE',                 -- GTVSDAX_INTERNAL_CODE_GROUP
    'Common Matching Salesforce CRM',       -- GTVSDAX_DESC
    'N',                                    -- GTVSDAX_SYSREQ_IND
    SYSDATE,                                -- GTVSDAX_ACTIVITY_DATE
    USER,                                   -- GTVSDAX_USER_ID
    'G',                                    -- GTVSDAX_SYSI_CODE (General Banner)
    'COMMON MATCHING',                      -- GTVSDAX_CONCEPT
    'Perfil de coincidencia común para la integración con Salesforce CRM', -- GTVSDAX_COMMENTS
    null,                                      -- GTVSDAX_SURROGATE_ID (Usar secuencia si existe en tu ambiente)
    0,                                      -- GTVSDAX_VERSION
    'INTEGRACION',                          -- GTVSDAX_DATA_ORIGIN
    NULL                                    -- GTVSDAX_VPDI_CODE
);

COMMIT;

--------------------------------------------------------
--  DDL for Table IZTZPRC (Esquema PRGNREP)
--------------------------------------------------------

CREATE TABLE "PRGNREP"."IZTZPRC" 
(	
	"IZTZPRC_ID" NUMBER GENERATED ALWAYS AS IDENTITY 
		MINVALUE 1 MAXVALUE 9999999999999999999999999999 
		INCREMENT BY 1 START WITH 32493 
		CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE, 
	"IZTZPRC_IZTID" VARCHAR2(20 BYTE), 
	"IZTZPRC_ACTIVITY_DATE" DATE, 
	"IZTZPRC_DATA_ORIGIN" VARCHAR2(50 BYTE), 
	"IZTZPRC_USER_ID" VARCHAR2(50 BYTE), 
	"IZTZPRC_START_DATA" TIMESTAMP (6), 
	"IZTZPRC_FINISH_DATA" TIMESTAMP (6), 
	"IZTZPRC_START_PROCESS" TIMESTAMP (6), 
	"IZTZPRC_FINISH_PROCESS" TIMESTAMP (6), 
	"IZTZPRC_PROC_IND" VARCHAR2(2 BYTE), 
	"IZTZPRC_TOTAL_RECORDS" NUMBER, 
	"IZTZPRC_MISSING_RECORDS" NUMBER
) 
SEGMENT CREATION IMMEDIATE 
PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
NOCOMPRESS NOLOGGING
STORAGE(
	INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
	PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
	BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT
)
TABLESPACE "DEVELOPMENT" ;

--------------------------------------------------------
--  Public Synonym for Table IZTZPRC
--------------------------------------------------------

CREATE OR REPLACE PUBLIC SYNONYM "IZTZPRC" FOR "PRGNREP"."IZTZPRC";

GRANT SELECT, INSERT ON PRGNREP.IZTZPRC TO INTEGRACION;

DROP TABLE "PRGNREP"."IZTZM01" 
CREATE TABLE "PRGNREP"."IZTZM01" 
(	
    "RECID" NUMBER GENERATED ALWAYS AS IDENTITY 
        MINVALUE 1 MAXVALUE 9999999999999999999999999999 
        INCREMENT BY 1 START WITH 127931 
        CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE, 
    "IFZID" VARCHAR2(10 BYTE), 
    "ACTIVITY_DATE" DATE, 
    "DATA_ORIGIN" VARCHAR2(50 BYTE), 
    "USER_ID" VARCHAR2(50 BYTE), 
    "REQUEST_DATA" VARCHAR2(4000 BYTE), 
    "RESPONSE_DATA" CLOB, 
    "REQUEST_TIMESTAMP" TIMESTAMP (6), 
    "RESPONSE_TIMESTAMP" TIMESTAMP (6), 
    "RESPONSE_MESSAGE" VARCHAR2(4000 BYTE), 
    "PROC_IND" VARCHAR2(2 BYTE), 
    "SETDATA_TIMESTAMP" TIMESTAMP (6), 
    "GETDATA_TIMESTAMP" TIMESTAMP (6), 
    "PRCID" NUMBER
);


CREATE OR REPLACE PUBLIC SYNONYM "IZTZM01" FOR "PRGNREP"."IZTZM01";
GRANT SELECT, INSERT ON PRGNREP.IZTZM01 TO INTEGRACION;

CREATE TABLE "PRGNREP"."IZTZM03" 
(	
    "RECID" NUMBER GENERATED ALWAYS AS IDENTITY 
        MINVALUE 1 MAXVALUE 9999999999999999999999999999 
        INCREMENT BY 1 START WITH 127931 
        CACHE 20 NOORDER NOCYCLE NOKEEP NOSCALE, 
    "IFZID" VARCHAR2(10 BYTE), 
    "ACTIVITY_DATE" DATE, 
    "DATA_ORIGIN" VARCHAR2(50 BYTE), 
    "USER_ID" VARCHAR2(50 BYTE), 
    "REQUEST_DATA" VARCHAR2(4000 BYTE), 
    "RESPONSE_DATA" VARCHAR2(4000 BYTE), 
    "REQUEST_TIMESTAMP" TIMESTAMP (6), 
    "RESPONSE_TIMESTAMP" TIMESTAMP (6), 
    "RESPONSE_MESSAGE" VARCHAR2(4000 BYTE), 
    "PROC_IND" VARCHAR2(2 BYTE), 
    "SETDATA_TIMESTAMP" TIMESTAMP (6), 
    "GETDATA_TIMESTAMP" TIMESTAMP (6), 
    "PRCID" NUMBER
);


CREATE OR REPLACE PUBLIC SYNONYM "IZTZM03" FOR "PRGNREP"."IZTZM03";
GRANT SELECT, UPDATE, INSERT ON PRGNREP.IZTZM03 TO INTEGRACION;

--------------------------------------------------------
--  DDL for Table TZRRLOG TEMPORAL TABLE 
--------------------------------------------------------

  CREATE TABLE "TAISMGR"."TZRRLOG" 
   (	"TZRRLOG_SEQUENCE" NUMBER, 
	"TZRRLOG_PIDM" NUMBER(8,0), 
	"TZRRLOG_PROCESS" VARCHAR2(30 BYTE), 
	"TZRRLOG_REFERENCE" VARCHAR2(100 BYTE), 
	"TZRRLOG_LOG" VARCHAR2(4000 BYTE), 
	"TZRRLOG_USER_ID" VARCHAR2(30 BYTE), 
	"TZRRLOG_ACTIVITY_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS NOLOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "DEVELOPMENT"  ENABLE ROW MOVEMENT ;
  
  
CREATE SEQUENCE "TAISMGR"."TZRRLOG_SEQUENCE" 
    MINVALUE 1 
    MAXVALUE 9999999999999999999999999999 
    INCREMENT BY 1 
    START WITH 1 
    CACHE 20 
    NOORDER NOCYCLE;  
--------------------------------------------------------
--  DDL for Trigger TT_TZRRLOG_SEQUENCE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "TAISMGR"."TT_TZRRLOG_SEQUENCE" 
   BEFORE INSERT OR UPDATE
   ON TAISMGR.tzrrlog    FOR EACH ROW
BEGIN
   IF INSERTING   THEN
      IF :new.tzrrlog_sequence IS NULL      THEN
         :new.tzrrlog_sequence := tzrrlog_SEQUENCE.NEXTVAL;
      END IF;
   END IF;
END;



/
ALTER TRIGGER "TAISMGR"."TT_TZRRLOG_SEQUENCE" ENABLE;

CREATE OR REPLACE PUBLIC SYNONYM "TZRRLOG" FOR "TAISMGR"."TZRRLOG";

--------------------------------------------------------
-- Permisos sobre la tabla TAISMGR.TZRRLOG para INTEGRACION
--------------------------------------------------------
GRANT SELECT, INSERT ON TAISMGR.TZRRLOG TO INTEGRACION;

--------------------------------------------------------
--  DDL for Table IZTZM04
--------------------------------------------------------

  CREATE TABLE "PRGNREP"."IZTZM04" 
   (	"RECID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 896215 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE , 
	"IFZID" VARCHAR2(10 BYTE), 
	"ACTIVITY_DATE" DATE, 
	"DATA_ORIGIN" VARCHAR2(50 BYTE), 
	"USER_ID" VARCHAR2(50 BYTE), 
	"REQUEST_DATA" CLOB, 
	"RESPONSE_DATA" CLOB, 
	"REQUEST_TIMESTAMP" TIMESTAMP (6), 
	"RESPONSE_TIMESTAMP" TIMESTAMP (6), 
	"RESPONSE_MESSAGE" CLOB, 
	"PROC_IND" VARCHAR2(2 BYTE), 
	"SETDATA_TIMESTAMP" TIMESTAMP (6), 
	"GETDATA_TIMESTAMP" TIMESTAMP (6), 
	"PRCID" NUMBER
   );

CREATE OR REPLACE public synonym IZTZM04 FOR PRGNREP.IZTZM04;   
GRANT SELECT, UPDATE,insert ON IZTZM04 TO INTEGRACION;


CREATE OR REPLACE public SYNONYM IZTZCFG FOR DESARROLLO.IZTZCFG;
GRANT SELECT, UPDATE,insert ON DESARROLLO.IZTZCFG TO INTEGRACION;
GRANT SELECT, UPDATE,insert ON iztzprc TO INTEGRACION;
GRANT EXECUTE ON BANINST1.GB_ADDITIONAL_IDENT TO INTEGRACION;

--------------------------------------------------------
--  DDL for Package ZTZ_ASYNC_PROC
--------------------------------------------------------

--install @ZTZ_ASYNC_PROC
