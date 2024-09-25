-- Prepartion
CREATE EXTENSION vector SCHEMA public;
CREATE SCHEMA tpch;

DROP TABLE IF EXISTS tpch.items;
CREATE TABLE tpch.items (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO tpch.items (embedding) VALUES ('[1.1, 2.2, 3.3]'), ('[4.4, 5.5, 6.6]'), ('[7.7, 8.8, 9.9]');
SELECT * FROM tpch.items;

DROP TABLE IF EXISTS tpch.another_items;
CREATE TABLE tpch.another_items (id bigserial PRIMARY KEY, another_embedding vector(3));
INSERT INTO tpch.another_items VALUES (4, '[0.1, 0.2, 0.3]'), (5, '[0.4, 0.5, 0.6]'), (6, '[0.7, 0.8, 0.9]');
SELECT * FROM tpch.another_items;

-- pgvector operators
-- nearest neighbor (L2 distance): <->
SELECT * FROM tpch.items 
ORDER BY embedding <-> '[1.1, 2.2, 3.3]' LIMIT 1;

-- cosine distance: <=>
SELECT * FROM tpch.items 
ORDER BY embedding <=> '[1.1, 2.2, 3.3]' LIMIT 1;

-- dot / inner product: <#>
SELECT * FROM tpch.items 
ORDER BY embedding <#> '[1.1, 2.2, 3.3]' LIMIT 1;

