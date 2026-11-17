-- EXTRACT_ORDERS - manual version
-- Copies new/changed orders from SRC_APP into staging as text.

-- 1. Get a batch number
SELECT batch_seq.NEXTVAL FROM dual;

-- 2. Copy new data as text (only rows changed since the watermark)
INSERT INTO stg_orders
       (batch_id, order_id, customer_id, order_date, amount,
        currency, status, source_updated_at)
SELECT 1,
       TO_CHAR(o.order_id),
       TO_CHAR(o.customer_id),
       TO_CHAR(o.order_date, 'YYYY-MM-DD'),
       TO_CHAR(o.amount),
       o.currency,
       o.status,
       TO_CHAR(o.updated_at, 'YYYY-MM-DD HH24:MI:SS')
FROM src_app.orders o
WHERE o.updated_at > (SELECT last_success_at
                      FROM load_control
                      WHERE job_name = 'EXTRACT_ORDERS');

-- 3. Verify the row count
SELECT COUNT(*) FROM stg_orders WHERE batch_id = 1;

-- 4. Move the watermark to the newest change we copied
UPDATE load_control
SET last_success_at = (SELECT MAX(updated_at) FROM src_app.orders)
WHERE job_name = 'EXTRACT_ORDERS';

-- 5. Save
COMMIT;