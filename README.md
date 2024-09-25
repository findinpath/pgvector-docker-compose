Trino pgvector similarity search demo
=====================================

## Setup

Setup Postgres

```
psql -h localhost -p 5432 -U test -d tpch -a -f pgvector.sql
```

Connect to Postgres

```
psql -h localhost -p 5432 -U test -d tpch
```



## Relevant Trino developments in this area

https://github.com/trinodb/trino/pull/22618

https://github.com/trinodb/trino/pull/23015