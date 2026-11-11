-- =====================================================================
-- ODS_APP: operational data store.
-- Flow:  SRC_APP.ORDERS --(EXTRACT_ORDERS)--> STG_ORDERS --(LOAD_ORDERS)--> ORDERS
-- Every job run writes one row to JOB_LOG. LOAD_CONTROL keeps watermarks.
-- =====================================================================
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Staging: everything is text, exactly like a CSV file from a source system.
-- This is where bad data enters (letters in amount, missing values, duplicates).
CREATE TABLE ods_app.stg_orders (
    batch_id           NUMBER        NOT NULL,
    order_id           VARCHAR2(50),
    customer_id        VARCHAR2(50),
    order_date         VARCHAR2(50),
    amount             VARCHAR2(50),
    currency           VARCHAR2(50),
    status             VARCHAR2(50),
    source_updated_at  VARCHAR2(50),
    staged_at          TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

-- Target: typed and constrained. Reports and other applications read from here.
CREATE TABLE ods_app.orders (
    order_id           NUMBER        PRIMARY KEY,
    customer_id        NUMBER        NOT NULL,
    order_date         DATE          NOT NULL,
    amount             NUMBER(12,2)  NOT NULL,
    currency           VARCHAR2(3)   NOT NULL,
    status             VARCHAR2(20)  NOT NULL,
    source_updated_at  TIMESTAMP     NOT NULL,
    batch_id           NUMBER        NOT NULL,
    ods_loaded_at      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);

-- One row per job run. This is the first place support looks.
CREATE TABLE ods_app.job_log (
    log_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_name       VARCHAR2(50)   NOT NULL,
    batch_id       NUMBER,
    started_at     TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    finished_at    TIMESTAMP,
    status         VARCHAR2(10)   DEFAULT 'RUNNING' NOT NULL,
    rows_read      NUMBER,
    rows_loaded    NUMBER,
    error_code     NUMBER,
    error_message  VARCHAR2(4000),
    CONSTRAINT job_log_status_chk
        CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED'))
);

-- Watermark per job: "data changed after this time has not been processed yet".
CREATE TABLE ods_app.load_control (
    job_name         VARCHAR2(50)  PRIMARY KEY,
    last_success_at  TIMESTAMP     NOT NULL,
    enabled          VARCHAR2(1)   DEFAULT 'Y' NOT NULL,
    CONSTRAINT load_control_enabled_chk CHECK (enabled IN ('Y', 'N'))
);

CREATE SEQUENCE ods_app.batch_seq;

COMMENT ON TABLE ods_app.stg_orders   IS 'Raw text copy of source orders, one batch per extract run';
COMMENT ON TABLE ods_app.orders       IS 'Validated, typed orders - the data consumers read';
COMMENT ON TABLE ods_app.job_log      IS 'Audit trail of every job run: status, row counts, errors';
COMMENT ON TABLE ods_app.load_control IS 'Watermarks and on/off switch per job';

INSERT INTO ods_app.load_control (job_name, last_success_at)
VALUES ('EXTRACT_ORDERS', TIMESTAMP '2000-01-01 00:00:00');

INSERT INTO ods_app.load_control (job_name, last_success_at)
VALUES ('LOAD_ORDERS', TIMESTAMP '2000-01-01 00:00:00');

COMMIT;
