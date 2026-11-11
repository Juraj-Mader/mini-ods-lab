-- =====================================================================
-- Seed data for the source application: 20 customers, 200 orders.
-- Deterministic (no random values), so every fresh lab looks the same.
-- =====================================================================
ALTER SESSION SET CONTAINER = FREEPDB1;

INSERT INTO src_app.customers (full_name, email, country)
SELECT 'Customer ' || LEVEL,
       'customer' || LEVEL || '@example.sk',
       CASE WHEN MOD(LEVEL, 5) = 0 THEN 'CZ' ELSE 'SK' END
FROM dual
CONNECT BY LEVEL <= 20;

INSERT INTO src_app.orders (customer_id, order_date, amount, currency, status, updated_at)
SELECT MOD(LEVEL, 20) + 1,
       TRUNC(SYSDATE) - MOD(LEVEL, 30),
       ROUND(10 + MOD(LEVEL * 37, 990) + MOD(LEVEL, 100) / 100, 2),
       'EUR',
       CASE MOD(LEVEL, 4)
           WHEN 0 THEN 'NEW'
           WHEN 1 THEN 'PAID'
           WHEN 2 THEN 'SHIPPED'
           ELSE 'CANCELLED'
       END,
       SYSTIMESTAMP - NUMTODSINTERVAL(MOD(LEVEL, 30), 'DAY')
FROM dual
CONNECT BY LEVEL <= 200;

COMMIT;
