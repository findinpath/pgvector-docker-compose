SHOW CATALOGS;
SELECT version();

-- PostgreSQL connector
SHOW TABLES IN postgresql.tpch;

-- vector type is mapped to array(real) type
DESCRIBE postgresql.tpch.items;
SELECT * FROM postgresql.tpch.items;
SELECT * FROM postgresql.tpch.another_items;

/* Three new functions */
-- nearest neighbor (L2 distance): <->
EXPLAIN 
SELECT * FROM postgresql.tpch.items 
ORDER BY euclidean_distance(embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

-- cosine distance: <=>
EXPLAIN 
SELECT * FROM postgresql.tpch.items 
ORDER BY cosine_distance(embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

-- dot / inner product: <#>
EXPLAIN 
SELECT * FROM postgresql.tpch.items 
ORDER BY -dot_product(embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

-- Note1: pushdown doesn't happen in case of -1 * dot_product expression. It should be "-dot_product"
EXPLAIN 
SELECT * FROM postgresql.tpch.items 
ORDER BY -1 * dot_product(embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

-- Note2: predicate pushdown is unsupported. The following query causes full scan and filter in SEP engine 
EXPLAIN
SELECT * FROM postgresql.tpch.items 
WHERE euclidean_distance(embedding, ARRAY[1.1, 2.2, 3.3]) > 1;


-- Prepare a schema
CREATE SCHEMA hive.default;

-- Simple Trino view with pgvector on Hive
CREATE OR REPLACE VIEW hive.default.simple_view AS SELECT * FROM postgresql.tpch.items 
ORDER BY euclidean_distance(embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;


EXPLAIN
SELECT * FROM hive.default.simple_view;

/* 
 * 1. CTE (Common Table Expression) with ORDER BY ... LIMIT pushdown
 * Two TableScan with <-> operator happen on pgvector side
 */
EXPLAIN
WITH vector_results AS (
 SELECT id, embedding AS vector FROM postgresql.tpch.items
  UNION ALL
 SELECT id, another_embedding AS vector FROM postgresql.tpch.another_items
)
SELECT * FROM vector_results
ORDER BY euclidean_distance(vector, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

/*
 * 2. UNION Trino view with pgvector on Hive
 */  
CREATE OR REPLACE VIEW hive.default.union_view AS 
SELECT id, embedding AS vector FROM postgresql.tpch.items
UNION ALL
SELECT id, another_embedding AS vector FROM postgresql.tpch.another_items;

SELECT * FROM hive.default.union_view;

-- Two TableScan with <-> operator happen on pgvector side  
EXPLAIN
SELECT * FROM hive.default.union_view
ORDER BY euclidean_distance(vector, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

/* 
 * 3. JOIN Hive table and pgvector tables
 */  
CREATE TABLE hive.default.hive_table(id int, name varchar);
INSERT INTO hive.default.hive_table VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Carol');
SELECT * FROM hive.default.hive_table;

EXPLAIN
WITH vector_results AS (
 SELECT * FROM postgresql.tpch.items
  UNION ALL
 (SELECT * FROM postgresql.tpch.another_items ORDER BY euclidean_distance(another_embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1)
)
SELECT a.id, b.name FROM vector_results a 
INNER JOIN hive.default.hive_table b ON a.id = b.id;

/* 
 * 4. Comparison operators against non-vector columns
 */  
EXPLAIN 
SELECT * FROM postgresql.tpch.items
WHERE id BETWEEN 2 AND 3
ORDER BY euclidean_distance(embedding, ARRAY[1.1, 2.2, 3.3]) LIMIT 1;

-- Session properties
SET SESSION postgresql.dynamic_filtering_enabled = false;
SET SESSION postgresql.join_pushdown_strategy = 'EAGER';
