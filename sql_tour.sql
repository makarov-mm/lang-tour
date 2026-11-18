-- =================================================================================================
--  SQL FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
--
--  Dialect: PostgreSQL. Run it with psql against any database you may create a schema in:
--
--      psql -X -d postgres -f sql_tour.sql
--
--  Verified with PostgreSQL 16.15. The script works in a schema of its own, sql_tour, which
--  it creates at the start and drops at the end (an existing schema of that name is replaced);
--  nothing else is touched. Newer servers were not available where this file was checked, so
--  the additions of PostgreSQL 17, 18 and 19 are listed in section 13 as comments that were
--  NOT run.
--
--  The lines that start with a backslash are psql commands (\echo prints a section title);
--  everything else is SQL. Most of it is standard SQL that also runs on SQL Server, MySQL
--  or SQLite with small changes; PostgreSQL-only features are marked as such.
--
--  How to read. The sections follow each other from simple to advanced, and each statement
--  prints its result. A "C#:" note shows the closest counterpart in C#, LINQ or EF Core.
--
--  The main differences from C# to keep in mind from the first line:
--
--   1. SQL is declarative. A query describes WHAT rows are wanted; the database's planner
--      decides HOW to get them (which index, which join algorithm, in which order).
--   2. The unit of thought is the set of rows, not the single object. Good SQL has no
--      loops: one statement transforms whole tables.
--   3. NULL is "unknown", and logic is three-valued: a comparison with NULL is neither true
--      nor false.
--   4. Types, constraints and transactions live in the database and hold for every client,
--      so the data stays valid no matter which program writes it.
--   5. A table has no order. Rows come back in a defined order only with ORDER BY.
--   6. Keywords are case-insensitive, strings use 'single quotes', and "double quotes" are
--      for identifiers.
--
--  Contents:
--    1. Expressions, types, NULL                 8. Changing data: upsert, UPDATE FROM, MERGE
--    2. Tables, constraints, basic DML           9. Transactions
--    3. Querying one table                      10. Arrays, JSON, ranges, dates, text search
--    4. Joins                                   11. Views, indexes, query plans
--    5. Aggregation and grouping                12. Functions, procedures, triggers
--    6. Subqueries, CTEs, set operations        13. The newest, and what was left out
--    7. Window functions
-- =================================================================================================

\set ON_ERROR_STOP on
\set QUIET on
\pset null '(null)'
\pset footer off
SET client_min_messages = warning;
SET client_encoding = 'UTF8';
SET timezone = 'UTC';
SET datestyle = 'ISO, YMD';
SET intervalstyle = 'postgres';

-- A schema is a namespace inside a database. C#: namespace.
DROP SCHEMA IF EXISTS sql_tour CASCADE;
CREATE SCHEMA sql_tour;
SET search_path = sql_tour, public;

-- =================================================================================================
\echo
\echo === 1. Expressions, types, NULL ===
-- =================================================================================================

-- SELECT evaluates expressions; it does not even need a table.
SELECT 42 AS answer, 7 / 2 AS int_division, 7 / 2.0 AS division, 7 % 3 AS remainder,
       2 ^ 10 AS power, round(2.567, 1) AS rounded, 'Hello' || ', ' || 'World' AS greeting;

-- Every value has a type. A cast is CAST(x AS type) or, in PostgreSQL, x::type.
-- `numeric` is an exact decimal (C#: decimal); float8 is a binary double.
SELECT pg_typeof(42) AS int_literal, pg_typeof(42.5) AS decimal_literal, '42'::int + 1 AS cast_text,
       CAST('2026-11-17' AS date) + 45 AS date_plus_days, 0.1 + 0.2 = 0.3 AS exact_numeric,
       0.1::float8 + 0.2::float8 = 0.3::float8 AS binary_float;

-- Strings. Positions start at 1.
SELECT upper('tour') AS upper, length(U&'Gr\00FC\00DFe') AS chars,
       octet_length(U&'Gr\00FC\00DFe') AS bytes, substring('Hello, World' FROM 8 FOR 5) AS sub,
       position('World' IN 'Hello, World') AS pos, replace('a-b-c', '-', '+') AS replaced,
       lpad('5', 3, '0') AS padded, format('%s has %s items', 'cart', 3) AS formatted,
       'tour' LIKE 't%' AS like_match, split_part('a,b,c', ',', 2) AS part;

-- NULL means "unknown". Comparing with it gives NULL, so `= NULL` never matches: the test
-- is IS NULL. C#: think of a Nullable<T> whose every operator propagates null.
SELECT NULL = NULL AS null_equals_null, NULL IS NULL AS is_null, 1 + NULL AS arithmetic,
       NULL AND false AS and_false, NULL OR true AS or_true,
       coalesce(NULL, 'fallback') AS coalesced, nullif(5, 5) AS nullif_equal,
       1 IS DISTINCT FROM NULL AS null_safe_comparison;

-- CASE is the conditional expression (C#: a switch expression); generate_series produces
-- rows (C#: Enumerable.Range).
SELECT n,
       CASE WHEN n % 15 = 0 THEN 'fizzbuzz'
            WHEN n % 3 = 0 THEN 'fizz'
            WHEN n % 5 = 0 THEN 'buzz'
            ELSE n::text
       END AS fizzbuzz
FROM generate_series(9, 15) AS n;

-- =================================================================================================
\echo
\echo === 2. Tables, constraints, basic DML ===
-- =================================================================================================

-- A table is a set of rows with typed columns. Constraints are rules the database checks on
-- every write, whoever writes. C#: validation that no caller can bypass.
CREATE TYPE job_level AS ENUM ('junior', 'middle', 'senior');

CREATE TABLE departments (
    id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,   -- an auto-numbered key
    name text NOT NULL UNIQUE,
    city text NOT NULL DEFAULT 'Munich'
);

CREATE TABLE employees (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          text NOT NULL,
    email         text UNIQUE,
    department_id integer REFERENCES departments (id) ON DELETE SET NULL,   -- a foreign key
    manager_id    integer REFERENCES employees (id),          -- a self-reference: the org chart
    level         job_level NOT NULL DEFAULT 'junior',
    salary        numeric(10, 2) NOT NULL CHECK (salary > 0),
    hired         date NOT NULL,
    skills        text[] NOT NULL DEFAULT '{}',               -- an array column
    profile       jsonb NOT NULL DEFAULT '{}',                -- a JSON document
    yearly        numeric(12, 2) GENERATED ALWAYS AS (salary * 12) STORED   -- a computed column
);

CREATE TABLE projects (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name   text NOT NULL UNIQUE,
    budget numeric(12, 2),
    period daterange NOT NULL                                 -- a range of dates: [start, end)
);

CREATE TABLE assignments (                                    -- a many-to-many link table
    employee_id integer NOT NULL REFERENCES employees (id) ON DELETE CASCADE,
    project_id  integer NOT NULL REFERENCES projects (id) ON DELETE CASCADE,
    hours       integer NOT NULL CHECK (hours BETWEEN 1 AND 2000),
    PRIMARY KEY (employee_id, project_id)                     -- a composite key
);

-- INSERT adds rows; RETURNING hands back what was stored, generated values included.
-- C#/EF: the entity after SaveChanges().
INSERT INTO departments (name, city)
VALUES ('R&D', 'Munich'), ('Sales', 'Berlin'), ('Ops', DEFAULT), ('Legal', 'Vienna'),
       ('Temp', 'Rome')
RETURNING id, name, city;

INSERT INTO employees
    (name, email, department_id, manager_id, level, salary, hired, skills, profile)
VALUES
    ('Ann', 'ann@example.com', 1, NULL, 'senior', 6100, '2019-03-01', '{sql,csharp,go}',
     '{"remote": true, "languages": ["en", "de"], "address": {"city": "Munich"}}'),
    ('Bob', 'bob@example.com', 2, 1, 'middle', 4100, '2021-06-15', '{sales}',
     '{"remote": false, "languages": ["en"]}'),
    ('Cid', 'cid@example.com', 1, 1, 'middle', 5200, '2020-09-01', '{sql,python}',
     '{"remote": true, "languages": ["en", "fr"]}'),
    ('Dee', 'dee@example.com', 2, 2, 'junior', 3900, '2023-01-10', '{sales,excel}',
     '{"remote": false}'),
    ('Eve', 'eve@example.com', 3, 1, 'senior', 4700, '2018-11-20', '{linux,sql}',
     '{"remote": true, "languages": ["en", "es", "de"]}'),
    ('Fay', NULL, NULL, 3, 'junior', 3500, '2024-05-05', '{}', '{}');

INSERT INTO projects (name, budget, period)
VALUES ('Apollo', 120000, '[2026-01-01,2026-07-01)'),
       ('Borealis', 80000, '[2026-05-01,2026-12-01)'),
       ('Comet', NULL, '[2027-01-01,2027-04-01)');

INSERT INTO assignments (employee_id, project_id, hours)
VALUES (1, 1, 300), (1, 2, 120), (3, 1, 450), (3, 2, 200), (5, 2, 380), (2, 2, 60);

-- UPDATE and DELETE change the rows that a WHERE clause selects — all rows if there is none.
UPDATE employees SET salary = salary * 1.05 WHERE level = 'junior'
RETURNING name, salary, yearly;
DELETE FROM departments WHERE name = 'Temp';

-- Constraints reject bad data whatever the client is. Each of these statements fails:
--   INSERT INTO employees (name, salary, hired) VALUES ('Zed', -1, '2026-01-01');
--       ERROR: new row for relation "employees" violates check constraint "employees_salary_check"
--   INSERT INTO employees (name, email, salary, hired)
--   VALUES ('Al', 'ann@example.com', 1, '2026-01-01');
--       ERROR: duplicate key value violates unique constraint "employees_email_key"
--   INSERT INTO assignments VALUES (99, 1, 10);
--       ERROR: insert or update on table "assignments" violates foreign key constraint

-- =================================================================================================
\echo
\echo === 3. Querying one table ===
-- =================================================================================================

-- The clauses are WRITTEN in the order SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT
-- but EVALUATED as FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY, LIMIT. (LINQ writes them
-- in evaluation order: from ... where ... select.)
SELECT name, level, salary, hired
FROM employees
WHERE salary >= 4000 AND hired < DATE '2022-01-01'   -- C#: .Where(e => ...)
ORDER BY salary DESC, name                           -- C#: .OrderByDescending(...).ThenBy(...)
LIMIT 3;                                             -- C#: .Take(3); OFFSET n is .Skip(n)

SELECT name,
       email IS NULL                    AS no_email,
       name LIKE '_e%'                  AS second_letter_e,   -- _ is one character, % any run
       level IN ('middle', 'senior')    AS experienced,
       salary BETWEEN 4000 AND 5500     AS mid_salary,
       extract(year FROM hired)::int    AS hired_year,
       age(DATE '2026-11-17', hired)    AS tenure
FROM employees
ORDER BY id;

-- DISTINCT removes duplicate rows; enum values sort in the order of their declaration.
SELECT DISTINCT level FROM employees ORDER BY level DESC;

-- From C#, values are passed as parameters, never glued into the SQL text (SQL injection).
-- PREPARE shows the same idea inside SQL.
PREPARE by_level (job_level) AS SELECT name FROM employees WHERE level = $1 ORDER BY name;
EXECUTE by_level ('senior');
DEALLOCATE by_level;

-- =================================================================================================
\echo
\echo === 4. Joins ===
-- =================================================================================================

-- INNER JOIN: the matching pairs only. C#: Join, or a navigation property in EF.
SELECT e.name, d.name AS department, d.city
FROM employees AS e
JOIN departments AS d ON d.id = e.department_id
ORDER BY e.name;

-- LEFT JOIN keeps every row of the left table; the missing side is NULL.
-- C#: GroupJoin + DefaultIfEmpty. Joining a table to itself needs two aliases.
SELECT e.name, coalesce(d.name, '(none)') AS department, m.name AS manager
FROM employees AS e
LEFT JOIN departments AS d ON d.id = e.department_id
LEFT JOIN employees AS m ON m.id = e.manager_id
ORDER BY e.id;

-- FULL JOIN keeps the unmatched rows of both sides: here, people without a project and
-- projects without people (plus the big assignments).
SELECT e.name AS employee, p.name AS project, a.hours
FROM employees AS e
FULL JOIN assignments AS a ON a.employee_id = e.id
FULL JOIN projects AS p ON p.id = a.project_id
WHERE a.hours IS NULL OR a.hours > 300
ORDER BY e.name NULLS LAST, p.name;

-- An anti-join: the rows WITHOUT a match. C#: .Where(d => !employees.Any(...)).
SELECT d.name AS department_without_people
FROM departments AS d
WHERE NOT EXISTS (SELECT 1 FROM employees AS e WHERE e.department_id = d.id);

-- LATERAL lets a subquery in FROM refer to the rows before it: "for each department, its
-- best-paid employee". C#: SelectMany with an inner query.
SELECT d.name AS department, top.name, top.salary
FROM departments AS d
CROSS JOIN LATERAL (
    SELECT e.name, e.salary
    FROM employees AS e
    WHERE e.department_id = d.id
    ORDER BY e.salary DESC
    LIMIT 1
) AS top
ORDER BY d.name;

-- =================================================================================================
\echo
\echo === 5. Aggregation and grouping ===
-- =================================================================================================

-- Aggregates fold many rows into one value. count(column), sum, avg, min, max skip NULLs.
SELECT count(*) AS employees, count(email) AS with_email,
       count(DISTINCT department_id) AS departments, sum(salary) AS payroll,
       round(avg(salary), 2) AS average, min(hired) AS first_hire
FROM employees;

-- GROUP BY makes one row per group; HAVING filters groups, WHERE filters rows before
-- grouping. C#: GroupBy + Select.
SELECT d.name AS department,
       count(*) AS people,
       round(avg(e.salary), 2) AS average,
       count(*) FILTER (WHERE e.level = 'senior') AS seniors,   -- a conditional aggregate
       string_agg(e.name, ', ' ORDER BY e.name) AS names
FROM employees AS e
JOIN departments AS d ON d.id = e.department_id
GROUP BY d.name
HAVING count(*) >= 1
ORDER BY average DESC;

-- ROLLUP adds subtotals and a grand total to the same result.
SELECT coalesce(d.city, '(all cities)') AS city, coalesce(e.level::text, '(all levels)') AS level,
       count(*) AS people, sum(e.salary) AS payroll
FROM employees AS e
JOIN departments AS d ON d.id = e.department_id
GROUP BY ROLLUP (d.city, e.level)
ORDER BY d.city NULLS LAST, e.level NULLS LAST;

-- DISTINCT ON (PostgreSQL only): the first row of each group — the latest hire per department.
SELECT DISTINCT ON (department_id) department_id, name, hired
FROM employees
WHERE department_id IS NOT NULL
ORDER BY department_id, hired DESC;

-- =================================================================================================
\echo
\echo === 6. Subqueries, CTEs, set operations ===
-- =================================================================================================

-- A subquery can stand wherever a value, a list or a table is expected. The last one is
-- "correlated": it is evaluated for each row of the outer query.
SELECT name, salary,
       salary - (SELECT round(avg(salary), 2) FROM employees) AS versus_average
FROM employees
WHERE department_id IN (SELECT id FROM departments WHERE city = 'Munich')
  AND salary > (SELECT avg(peer.salary) FROM employees AS peer WHERE peer.level = employees.level)
ORDER BY name;

-- WITH names a subquery (a "common table expression"), and later ones may build on earlier
-- ones. C#: `let`, or the intermediate variables of a LINQ query.
WITH hours_per_employee AS (
    SELECT employee_id, sum(hours) AS hours
    FROM assignments
    GROUP BY employee_id
),
workload AS (
    SELECT e.name, e.salary, coalesce(h.hours, 0) AS hours
    FROM employees AS e
    LEFT JOIN hours_per_employee AS h ON h.employee_id = e.id
)
SELECT name, hours, round(salary / nullif(hours, 0), 2) AS salary_per_hour   -- nullif: no x / 0
FROM workload
ORDER BY hours DESC, name;

-- A recursive CTE walks hierarchies and graphs: the org chart from the top down.
WITH RECURSIVE chain AS (
    SELECT id, name, 0 AS depth, name AS path
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.name, c.depth + 1, c.path || ' > ' || e.name
    FROM employees AS e
    JOIN chain AS c ON e.manager_id = c.id
)
SELECT repeat('  ', depth) || name AS org_chart, depth, path
FROM chain
ORDER BY path;

-- Set operations combine whole results: UNION [ALL], INTERSECT, EXCEPT.
-- C#: Union / Concat / Intersect / Except.
SELECT unnest(skills) AS shared_skill FROM employees WHERE department_id = 1
INTERSECT
SELECT unnest(skills) FROM employees WHERE department_id = 3
ORDER BY shared_skill;

-- VALUES is a table literal.
SELECT * FROM (VALUES (1, 'one'), (2, 'two')) AS t (n, word) ORDER BY n;

-- =================================================================================================
\echo
\echo === 7. Window functions ===
-- =================================================================================================

-- A window function computes over rows related to the current one WITHOUT collapsing them
-- (unlike GROUP BY). C#: LINQ has no counterpart; there one writes loops.
SELECT name, department_id AS dept, salary,
       rank() OVER (ORDER BY salary DESC) AS overall_rank,
       row_number() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rank_in_dept,
       round(salary / sum(salary) OVER (PARTITION BY department_id) * 100, 1) AS pct_of_dept,
       salary - lag(salary) OVER (ORDER BY salary) AS gap_to_previous,
       sum(salary) OVER (ORDER BY hired) AS running_payroll
FROM employees
ORDER BY salary DESC;

-- The best-paid person of each department: number the rows in a CTE, then filter.
WITH numbered AS (
    SELECT d.name AS department, e.name, e.salary,
           dense_rank() OVER (PARTITION BY d.id ORDER BY e.salary DESC) AS position
    FROM employees AS e
    JOIN departments AS d ON d.id = e.department_id
)
SELECT * FROM numbered WHERE position = 1 ORDER BY department;

-- A named window with a moving frame: the average of each row and its two neighbours.
SELECT hired, name, salary,
       round(avg(salary) OVER w, 2) AS moving_average,
       first_value(name) OVER w AS frame_starts_at,
       ntile(3) OVER (ORDER BY hired) AS tercile
FROM employees
WINDOW w AS (ORDER BY hired ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
ORDER BY hired;

-- =================================================================================================
\echo
\echo === 8. Changing data: upsert, UPDATE FROM, MERGE ===
-- =================================================================================================

-- "Insert, or update if it is already there", atomically. EXCLUDED is the row that could
-- not be inserted. (PostgreSQL and SQLite syntax; the standard spelling is MERGE.)
INSERT INTO departments (name, city)
VALUES ('Ops', 'Hamburg'), ('Support', 'Prague')
ON CONFLICT (name) DO UPDATE SET city = EXCLUDED.city
RETURNING name, city;

-- UPDATE with a join: everyone who works on Borealis gets 100 more.
UPDATE employees AS e
SET salary = e.salary + 100
FROM assignments AS a
JOIN projects AS p ON p.id = a.project_id
WHERE a.employee_id = e.id AND p.name = 'Borealis';
SELECT name, salary FROM employees ORDER BY salary DESC;

-- MERGE synchronizes a table with a source in one pass.
MERGE INTO projects AS p
USING (VALUES ('Apollo', 150000), ('Comet', 30000), ('Draco', 50000)) AS feed (name, budget)
ON p.name = feed.name
WHEN MATCHED AND p.budget IS DISTINCT FROM feed.budget THEN
    UPDATE SET budget = feed.budget
WHEN NOT MATCHED THEN
    INSERT (name, budget, period) VALUES (feed.name, feed.budget, '[2027-06-01,2027-09-01)');
SELECT name, budget, period FROM projects ORDER BY name;

-- A data-modifying CTE: move rows from one table to another in ONE statement.
CREATE TABLE former_employees (LIKE employees);
WITH gone AS (
    DELETE FROM employees WHERE name = 'Fay' RETURNING *
)
INSERT INTO former_employees SELECT * FROM gone;
SELECT (SELECT count(*) FROM employees) AS employees,
       (SELECT string_agg(name, ', ') FROM former_employees) AS former_employees;

-- =================================================================================================
\echo
\echo === 9. Transactions ===
-- =================================================================================================

-- A transaction makes several statements atomic: all of them happen, or none.
-- C#: DbTransaction / TransactionScope. Readers never block writers (MVCC): every statement
-- sees a consistent snapshot of the data.
CREATE TABLE accounts (
    owner   text PRIMARY KEY,
    balance numeric(12, 2) NOT NULL CHECK (balance >= 0)
);
INSERT INTO accounts VALUES ('ann', 100), ('bob', 50);

BEGIN;
UPDATE accounts SET balance = balance - 30 WHERE owner = 'ann';
UPDATE accounts SET balance = balance + 30 WHERE owner = 'bob';
COMMIT;

BEGIN;
DELETE FROM accounts;                             -- a mistake ...
SELECT count(*) AS rows_inside_the_transaction FROM accounts;
ROLLBACK;                                         -- ... undone completely

-- SAVEPOINT: a partial rollback inside a transaction.
BEGIN;
UPDATE accounts SET balance = balance + 1000 WHERE owner = 'ann';
SAVEPOINT before_risky_step;
UPDATE accounts SET balance = 0;
ROLLBACK TO SAVEPOINT before_risky_step;
COMMIT;
SELECT owner, balance FROM accounts ORDER BY owner;

-- In PostgreSQL even DDL is transactional: a table created and rolled back never existed.
BEGIN;
CREATE TABLE scratch (id integer);
ROLLBACK;
SELECT to_regclass('sql_tour.scratch') IS NULL AS scratch_is_gone;

-- Isolation levels: READ COMMITTED (the default; each statement sees the latest committed
-- data), REPEATABLE READ (one snapshot for the whole transaction), SERIALIZABLE (as if the
-- transactions ran one after another; one of them may fail and must be retried).
-- SELECT ... FOR UPDATE locks the selected rows until the transaction ends.
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT owner, balance, current_setting('transaction_isolation') AS isolation
FROM accounts
WHERE owner = 'ann'
FOR UPDATE;
COMMIT;

-- =================================================================================================
\echo
\echo === 10. Arrays, JSON, ranges, dates, text search ===
-- =================================================================================================

-- Arrays (PostgreSQL). Handy for tags; a child table is the classic alternative.
SELECT name, skills, cardinality(skills) AS n, skills[1] AS first,
       'sql' = ANY (skills) AS knows_sql, skills && ARRAY['go', 'python'] AS go_or_python
FROM employees
ORDER BY id;

SELECT skill, count(*) AS people, string_agg(name, ', ' ORDER BY name) AS who
FROM employees
CROSS JOIN LATERAL unnest(skills) AS skill        -- one row per element. C#: SelectMany
GROUP BY skill
HAVING count(*) > 1
ORDER BY people DESC, skill;

-- JSONB: schemaless documents with operators and indexes.
SELECT name,
       profile -> 'languages' AS languages,                     -- -> gives JSON
       profile ->> 'remote' AS remote_text,                     -- ->> gives text
       profile #>> '{address,city}' AS city,                    -- a path
       profile @> '{"remote": true}' AS is_remote,              -- containment
       profile ? 'address' AS has_address,                      -- key exists
       jsonb_array_length(coalesce(profile -> 'languages', '[]')) AS n_languages
FROM employees
ORDER BY id;

SELECT jsonb_build_object('name', name, 'salary', salary, 'skills', to_jsonb(skills)) AS as_json
FROM employees
WHERE name = 'Ann';

UPDATE employees SET profile = jsonb_set(profile, '{address}', '{"city": "Berlin"}')
WHERE name = 'Bob'
RETURNING name, profile;

SELECT e.name, language
FROM employees AS e
CROSS JOIN LATERAL jsonb_array_elements_text(e.profile -> 'languages') AS language
WHERE language <> 'en'
ORDER BY e.name, language;

-- Ranges: @> contains, && overlaps, * intersection.
SELECT name, period, upper(period) - lower(period) AS days,
       period @> DATE '2026-06-01' AS runs_in_june
FROM projects
ORDER BY name;

SELECT a.name AS project_a, b.name AS project_b, a.period * b.period AS overlap
FROM projects AS a
JOIN projects AS b ON a.id < b.id AND a.period && b.period;

-- Dates, timestamps, intervals. C#: DateOnly, DateTimeOffset, TimeSpan.
SELECT d::date AS month_start, to_char(d, 'Mon YYYY') AS label,
       (d + INTERVAL '1 month - 1 day')::date AS month_end
FROM generate_series(DATE '2026-11-01', DATE '2027-01-01', INTERVAL '1 month') AS d;

SELECT date_trunc('month', TIMESTAMP '2026-11-17 09:30') AS truncated,
       TIMESTAMPTZ '2026-11-17 09:30+00' AT TIME ZONE 'Europe/Berlin' AS berlin_time,
       DATE '2026-12-24' - DATE '2026-11-17' AS days_until, INTERVAL '90 minutes' * 2 AS doubled;

-- Regular expressions and full-text search.
SELECT 'ann@example.com' ~ '^[\w.]+@\w+\.\w+$' AS is_email,
       regexp_replace('2026-11-17', '(\d+)-(\d+)-(\d+)', '\3.\2.\1') AS european,
       (regexp_match('port=8080;', 'port=(\d+)'))[1]::int AS port,
       regexp_split_to_array('a, b;c', '[,;]\s*') AS parts,
       to_tsvector('english', 'The quick brown foxes jumped') @@ to_tsquery('english', 'fox & jump')
           AS text_search;

-- =================================================================================================
\echo
\echo === 11. Views, indexes, query plans ===
-- =================================================================================================

-- A view is a stored query. C#: a method that returns IQueryable<T>.
CREATE VIEW staff_directory AS
SELECT e.id, e.name, d.name AS department, e.level, e.salary
FROM employees AS e
LEFT JOIN departments AS d ON d.id = e.department_id;

SELECT department, count(*) AS people FROM staff_directory GROUP BY department ORDER BY department;

-- A materialized view stores its result and is refreshed on demand.
CREATE MATERIALIZED VIEW payroll_by_department AS
SELECT department, sum(salary) AS payroll FROM staff_directory GROUP BY department;
REFRESH MATERIALIZED VIEW payroll_by_department;
SELECT * FROM payroll_by_department ORDER BY payroll DESC;

-- Indexes make lookups fast and writes slower; the planner decides whether to use one.
-- (PRIMARY KEY and UNIQUE create their indexes automatically.)
CREATE INDEX employees_department_idx ON employees (department_id);               -- a B-tree
CREATE INDEX employees_lower_name_idx ON employees (lower(name));                 -- an expression
CREATE INDEX employees_senior_idx ON employees (salary) WHERE level = 'senior';   -- partial
CREATE INDEX employees_profile_idx ON employees USING gin (profile);              -- for jsonb
ANALYZE employees;

-- EXPLAIN shows the plan. For a table this small a sequential scan is the cheapest plan,
-- so the second and third queries forbid it to show what an index scan looks like.
EXPLAIN (COSTS OFF) SELECT * FROM employees WHERE lower(name) = 'ann';
SET enable_seqscan = off;
EXPLAIN (COSTS OFF) SELECT * FROM employees WHERE lower(name) = 'ann';
EXPLAIN (COSTS OFF) SELECT name FROM employees WHERE profile @> '{"remote": true}';
RESET enable_seqscan;

-- =================================================================================================
\echo
\echo === 12. Functions, procedures, triggers ===
-- =================================================================================================

-- A SQL function is a parameterized query that runs inside the database.
CREATE FUNCTION department_payroll(dept text) RETURNS numeric
LANGUAGE sql STABLE
RETURN (SELECT coalesce(sum(e.salary), 0)
        FROM employees AS e
        JOIN departments AS d ON d.id = e.department_id
        WHERE d.name = dept);

SELECT department_payroll('R&D') AS rd, department_payroll('Nowhere') AS nowhere;

-- A function that returns a table is used like a table.
CREATE FUNCTION earning_at_least(minimum numeric) RETURNS TABLE (name text, salary numeric)
LANGUAGE sql STABLE
BEGIN ATOMIC
    SELECT e.name, e.salary FROM employees AS e WHERE e.salary >= minimum ORDER BY e.salary DESC;
END;

SELECT * FROM earning_at_least(5000);

-- PL/pgSQL adds variables, branches, loops and exception handling. An EXCEPTION clause
-- undoes everything its block did, like a savepoint. C#: try / catch around a transaction.
CREATE FUNCTION transfer(sender text, receiver text, amount numeric) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
    sender_balance numeric;
BEGIN
    IF amount <= 0 THEN
        RAISE EXCEPTION 'the amount must be positive, got %', amount
            USING ERRCODE = 'invalid_parameter_value';
    END IF;
    UPDATE accounts SET balance = balance - amount WHERE owner = sender
    RETURNING balance INTO sender_balance;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'unknown account %', sender;
    END IF;
    UPDATE accounts SET balance = balance + amount WHERE owner = receiver;
    RETURN format('ok, %s now has %s', sender, sender_balance);
EXCEPTION
    WHEN check_violation THEN                -- CHECK (balance >= 0) fired
        RETURN 'refused: insufficient funds';
    WHEN invalid_parameter_value THEN
        RETURN 'refused: ' || SQLERRM;
END;
$$;

SELECT transfer('ann', 'bob', 100) AS first, transfer('bob', 'ann', 100000) AS second,
       transfer('ann', 'bob', -5) AS third;
SELECT owner, balance FROM accounts ORDER BY owner;

-- A set-returning function with a loop. RETURN NEXT is C#'s yield return.
CREATE FUNCTION fibonacci(n integer) RETURNS SETOF bigint
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    a bigint := 0;
    b bigint := 1;
BEGIN
    FOR i IN 1..n LOOP
        RETURN NEXT a;
        SELECT b, a + b INTO a, b;
    END LOOP;
END;
$$;

SELECT array_agg(value ORDER BY position) AS fibonacci
FROM fibonacci(10) WITH ORDINALITY AS f (value, position);

-- A trigger calls a function whenever rows change. C#: an event handler that no caller can
-- forget to raise.
CREATE TABLE audit_log (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action     text NOT NULL,
    row_name   text NOT NULL,
    old_salary numeric,
    new_salary numeric
);

CREATE FUNCTION log_salary_change() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.salary IS DISTINCT FROM OLD.salary THEN
        INSERT INTO audit_log (action, row_name, old_salary, new_salary)
        VALUES (TG_OP, NEW.name, OLD.salary, NEW.salary);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (action, row_name, old_salary) VALUES (TG_OP, OLD.name, OLD.salary);
    END IF;
    RETURN coalesce(NEW, OLD);
END;
$$;

CREATE TRIGGER employees_audit
AFTER UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE FUNCTION log_salary_change();

UPDATE employees SET salary = salary + 250 WHERE name IN ('Bob', 'Dee');
DELETE FROM employees WHERE name = 'Dee';
SELECT action, row_name, old_salary, new_salary FROM audit_log ORDER BY row_name, action DESC;

-- A procedure is invoked with CALL and, unlike a function, may commit or roll back itself.
CREATE PROCEDURE give_raise(percent numeric, target job_level)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE employees SET salary = round(salary * (1 + percent / 100), 2) WHERE level = target;
END;
$$;

CALL give_raise(10, 'senior');
SELECT name, level, salary FROM employees WHERE level = 'senior' ORDER BY name;

-- DO runs an anonymous block once; ASSERT checks an invariant.
DO $$
DECLARE
    entries integer;
BEGIN
    SELECT count(*) INTO entries FROM audit_log;
    ASSERT entries = 5, format('expected 5 audit entries, found %s', entries);
END;
$$;

-- =================================================================================================
\echo
\echo === 13. The newest, and what was left out ===
-- =================================================================================================

-- Used above: identity columns (10), generated columns (12), SQL-standard function bodies
-- (14), MERGE (15). New in 16: IS JSON, any_value(), and integer literals in other bases or
-- with underscores.
SELECT '{"a": 1}' IS JSON OBJECT AS is_json_object, 'oops' IS JSON AS is_json,
       any_value(level) IS NOT NULL AS any_value_works, 1_000_000 AS underscores,
       0x1F AS hexadecimal, current_setting('server_version_num')::int >= 160000 AS at_least_16
FROM employees;

-- Newer than the server this file was verified with — NOT run here:
--   17   MERGE ... RETURNING;  JSON_TABLE(...), which turns a JSON document into rows
--   18   uuidv7() for time-ordered keys;  virtual generated columns;
--        RETURNING old.salary, new.salary;  PRIMARY KEY (id, period WITHOUT OVERLAPS)
--   19   (a release candidate when this was written; the release is due on 2026-11-19)
--        INSERT ... ON CONFLICT DO SELECT ... RETURNING, which returns the rows in conflict
--
-- Left out of this tour: roles and privileges (GRANT, row-level security), partitioning,
-- replication, COPY for bulk loading, LISTEN / NOTIFY, and extensions such as PostGIS.

DROP SCHEMA sql_tour CASCADE;
