---
description: 'Documentation for GRANT Statement'
sidebar_label: 'GRANT'
sidebar_position: 38
slug: /sql-reference/statements/grant
title: 'GRANT Statement'
---

import CloudNotSupportedBadge from '@theme/badges/CloudNotSupportedBadge';

# GRANT Statement

- Grants [privileges](#privileges) to ClickHouse user accounts or roles.
- Assigns roles to user accounts or to the other roles.

To revoke privileges, use the [REVOKE](../../sql-reference/statements/revoke.md) statement. Also you can list granted privileges with the [SHOW GRANTS](../../sql-reference/statements/show.md#show-grants) statement.

## Granting Privilege Syntax {#granting-privilege-syntax}

```sql
GRANT [ON CLUSTER cluster_name] privilege[(column_name [,...])] [,...] ON {db.table[*]|db[*].*|*.*|table[*]|*} TO {user | role | CURRENT_USER} [,...] [WITH GRANT OPTION] [WITH REPLACE OPTION]
```

- `privilege` — Type of privilege.
- `role` — ClickHouse user role.
- `user` — ClickHouse user account.

The `WITH GRANT OPTION` clause grants `user` or `role` with permission to execute the `GRANT` query. Users can grant privileges of the same scope they have and less.
The `WITH REPLACE OPTION` clause replace old privileges by new privileges for the `user` or `role`, if is not specified it appends privileges.

## Assigning Role Syntax {#assigning-role-syntax}

```sql
GRANT [ON CLUSTER cluster_name] role [,...] TO {user | another_role | CURRENT_USER} [,...] [WITH ADMIN OPTION] [WITH REPLACE OPTION]
```

- `role` — ClickHouse user role.
- `user` — ClickHouse user account.

The `WITH ADMIN OPTION` clause grants [ADMIN OPTION](#admin-option) privilege to `user` or `role`.
The `WITH REPLACE OPTION` clause replace old roles by new role for the `user` or `role`, if is not specified it appends roles.

## Grant Current Grants Syntax {#grant-current-grants-syntax}
```sql
GRANT CURRENT GRANTS{(privilege[(column_name [,...])] [,...] ON {db.table|db.*|*.*|table|*}) | ON {db.table|db.*|*.*|table|*}} TO {user | role | CURRENT_USER} [,...] [WITH GRANT OPTION] [WITH REPLACE OPTION]
```

-   `privilege` — Type of privilege.
-   `role` — ClickHouse user role.
-   `user` — ClickHouse user account.

Using the `CURRENT GRANTS` statement allows you to give all specified privileges to the given user or role.
If none of the privileges were specified, then the given user or role will receive all available privileges for `CURRENT_USER`.

## Usage {#usage}

To use `GRANT`, your account must have the `GRANT OPTION` privilege. You can grant privileges only inside the scope of your account privileges.

For example, administrator has granted privileges to the `john` account by the query:

```sql
GRANT SELECT(x,y) ON db.table TO john WITH GRANT OPTION
```

It means that `john` has the permission to execute:

- `SELECT x,y FROM db.table`.
- `SELECT x FROM db.table`.
- `SELECT y FROM db.table`.

`john` can't execute `SELECT z FROM db.table`. The `SELECT * FROM db.table` also is not available. Processing this query, ClickHouse does not return any data, even `x` and `y`. The only exception is if a table contains only `x` and `y` columns. In this case ClickHouse returns all the data.

Also `john` has the `GRANT OPTION` privilege, so it can grant other users with privileges of the same or smaller scope.

Access to the `system` database is always allowed (since this database is used for processing queries).

You can grant multiple privileges to multiple accounts in one query. The query `GRANT SELECT, INSERT ON *.* TO john, robin` allows accounts `john` and `robin` to execute the `INSERT` and `SELECT` queries over all the tables in all the databases on the server.

## Wildcard grants {#wildcard-grants}

Specifying privileges you can use asterisk (`*`) instead of a table or a database name. For example, the `GRANT SELECT ON db.* TO john` query allows `john` to execute the `SELECT` query over all the tables in `db` database.
Also, you can omit database name. In this case privileges are granted for current database.
For example, `GRANT SELECT ON * TO john` grants the privilege on all the tables in the current database, `GRANT SELECT ON mytable TO john` grants the privilege on the `mytable` table in the current database.

:::note
The feature described below is available starting with the 24.10 ClickHouse version.
:::

You can also put asterisks at the end of a table or a database name. This feature allows you to grant privileges on an abstract prefix of the table's path.
Example: `GRANT SELECT ON db.my_tables* TO john`. This query allows `john` to execute the `SELECT` query over all the `db` database tables with the prefix `my_tables*`.

More examples:

`GRANT SELECT ON db.my_tables* TO john`
```sql
SELECT * FROM db.my_tables -- granted
SELECT * FROM db.my_tables_0 -- granted
SELECT * FROM db.my_tables_1 -- granted

SELECT * FROM db.other_table -- not_granted
SELECT * FROM db2.my_tables -- not_granted
```

`GRANT SELECT ON db*.* TO john`
```sql
SELECT * FROM db.my_tables -- granted
SELECT * FROM db.my_tables_0 -- granted
SELECT * FROM db.my_tables_1 -- granted
SELECT * FROM db.other_table -- granted
SELECT * FROM db2.my_tables -- granted
```

All newly created tables within granted paths will automatically inherit all grants from their parents.
For example, if you run the `GRANT SELECT ON db.* TO john` query and then create a new table `db.new_table`, the user `john` will be able to run the `SELECT * FROM db.new_table` query.

You can specify asterisk **only** for the prefixes:
```sql
GRANT SELECT ON db.* TO john -- correct
GRANT SELECT ON db*.* TO john -- correct

GRANT SELECT ON *.my_table TO john -- wrong
GRANT SELECT ON foo*bar TO john -- wrong
GRANT SELECT ON *suffix TO john -- wrong
GRANT SELECT(foo) ON db.table* TO john -- wrong
```

## Privileges {#privileges}

A Privilege is a permission given to a user to execute specific kinds of queries.

Privileges have a hierarchical structure and a set of permitted queries depends on the privilege scope.

The hierarchy of privileges in ClickHouse is shown below:

- [`ALL`](#all)
  - [`ACCESS MANAGEMENT`](#access-management)
    - `ALLOW SQL SECURITY NONE`
    - `ALTER QUOTA`
    - `ALTER ROLE`
    - `ALTER ROW POLICY` 
    - `ALTER SETTINGS PROFILE`
    - `ALTER USER`
    - `CREATE QUOTA`
    - `CREATE ROLE`
    - `CREATE ROW POLICY`
    - `CREATE SETTINGS PROFILE`
    - `CREATE USER`
    - `DROP QUOTA`
    - `DROP ROLE`
    - `DROP ROW POLICY`
    - `DROP SETTINGS PROFILE`
    - `DROP USER`
    - `ROLE ADMIN`
    - `SHOW ACCESS`
      - `SHOW QUOTAS`
      - `SHOW ROLES`
      - `SHOW ROW POLICIES`
      - `SHOW SETTINGS PROFILES`
      - `SHOW USERS`
  - [`ALTER`](#alter)
    - `ALTER DATABASE`
      - `ALTER DATABASE SETTINGS`
    - `ALTER TABLE`
      - `ALTER COLUMN`
        - `ALTER ADD COLUMN`
        - `ALTER CLEAR COLUMN`
        - `ALTER COMMENT COLUMN`
        - `ALTER DROP COLUMN`
        - `ALTER MATERIALIZE COLUMN`
        - `ALTER MODIFY COLUMN`
        - `ALTER RENAME COLUMN` 
      - `ALTER CONSTRAINT`
        - `ALTER ADD CONSTRAINT`
        - `ALTER DROP CONSTRAINT` 
      - `ALTER DELETE`
      - `ALTER FETCH PARTITION`
      - `ALTER FREEZE PARTITION`
      - `ALTER INDEX`
        - `ALTER ADD INDEX`
        - `ALTER CLEAR INDEX`
        - `ALTER DROP INDEX`
        - `ALTER MATERIALIZE INDEX`
        - `ALTER ORDER BY`
        - `ALTER SAMPLE BY` 
      - `ALTER MATERIALIZE TTL`
      - `ALTER MODIFY COMMENT`
      - `ALTER MOVE PARTITION`
      - `ALTER PROJECTION`
      - `ALTER SETTINGS`
      - `ALTER STATISTICS`
        - `ALTER ADD STATISTICS`
        - `ALTER DROP STATISTICS`
        - `ALTER MATERIALIZE STATISTICS`
        - `ALTER MODIFY STATISTICS` 
      - `ALTER TTL`
      - `ALTER UPDATE` 
    - `ALTER VIEW`
      - `ALTER VIEW MODIFY QUERY`
      - `ALTER VIEW REFRESH`
      - `ALTER VIEW MODIFY SQL SECURITY`
  - [`BACKUP`](#backup)
  - [`CLUSTER`](#cluster)
  - [`CREATE`](#create)
    - `CREATE ARBITRARY TEMPORARY TABLE`
      - `CREATE TEMPORARY TABLE`
    - `CREATE DATABASE`
    - `CREATE DICTIONARY`
    - `CREATE FUNCTION`
    - `CREATE RESOURCE`
    - `CREATE TABLE`
    - `CREATE VIEW`
    - `CREATE WORKLOAD`
  - [`dictGet`](#dictget)
  - [`displaySecretsInShowAndSelect`](#displaysecretsinshowandselect)
  - [`DROP`](#drop)
    - `DROP DATABASE`
    - `DROP DICTIONARY`
    - `DROP FUNCTION`
    - `DROP RESOURCE`
    - `DROP TABLE`
    - `DROP VIEW` 
    - `DROP WORKLOAD`
  - [`INSERT`](#insert)
  - [`INTROSPECTION`](#introspection)
    - `addressToLine`
    - `addressToLineWithInlines`
    - `addressToSymbol`
    - `demangle`
  - `KILL QUERY`
  - `KILL TRANSACTION`
  - `MOVE PARTITION BETWEEN SHARDS`
  - [`NAMED COLLECTION ADMIN`](#named-collection-admin)
    - `ALTER NAMED COLLECTION`
    - `CREATE NAMED COLLECTION`
    - `DROP NAMED COLLECTION`
    - `NAMED COLLECTION`
    - `SHOW NAMED COLLECTIONS`
    - `SHOW NAMED COLLECTIONS SECRETS`
  - [`OPTIMIZE`](#optimize)
  - [`SELECT`](#select)
  - [`SET DEFINER`](/sql-reference/statements/create/view#sql_security)
  - [`SHOW`](#show)
    - `SHOW COLUMNS` 
    - `SHOW DATABASES`
    - `SHOW DICTIONARIES`
    - `SHOW TABLES`
  - `SHOW FILESYSTEM CACHES`
  - [`SOURCES`](#sources)
    - `AZURE`
    - `FILE`
    - `HDFS`
    - `HIVE`
    - `JDBC`
    - `KAFKA`
    - `MONGO`
    - `MYSQL`
    - `NATS`
    - `ODBC`
    - `POSTGRES`
    - `RABBITMQ`
    - `REDIS`
    - `REMOTE`
    - `S3`
    - `SQLITE`
    - `URL`
  - [`SYSTEM`](#system)
    - `SYSTEM CLEANUP`
    - `SYSTEM DROP CACHE`
      - `SYSTEM DROP COMPILED EXPRESSION CACHE`
      - `SYSTEM DROP CONNECTIONS CACHE`
      - `SYSTEM DROP DISTRIBUTED CACHE`
      - `SYSTEM DROP DNS CACHE`
      - `SYSTEM DROP FILESYSTEM CACHE`
      - `SYSTEM DROP FORMAT SCHEMA CACHE`
      - `SYSTEM DROP MARK CACHE`
      - `SYSTEM DROP MMAP CACHE`
      - `SYSTEM DROP PAGE CACHE`
      - `SYSTEM DROP PRIMARY INDEX CACHE`
      - `SYSTEM DROP QUERY CACHE`
      - `SYSTEM DROP S3 CLIENT CACHE`
      - `SYSTEM DROP SCHEMA CACHE`
      - `SYSTEM DROP UNCOMPRESSED CACHE`
    - `SYSTEM DROP PRIMARY INDEX CACHE`
    - `SYSTEM DROP REPLICA`
    - `SYSTEM FAILPOINT`
    - `SYSTEM FETCHES`
    - `SYSTEM FLUSH`
      - `SYSTEM FLUSH ASYNC INSERT QUEUE`
      - `SYSTEM FLUSH LOGS`
    - `SYSTEM JEMALLOC`
    - `SYSTEM KILL QUERY`
    - `SYSTEM KILL TRANSACTION`
    - `SYSTEM LISTEN`
    - `SYSTEM LOAD PRIMARY KEY`
    - `SYSTEM MERGES`
    - `SYSTEM MOVES`
    - `SYSTEM PULLING REPLICATION LOG`
    - `SYSTEM REDUCE BLOCKING PARTS`
    - `SYSTEM REPLICATION QUEUES`
    - `SYSTEM REPLICA READINESS`
    - `SYSTEM RESTART DISK`
    - `SYSTEM RESTART REPLICA`
    - `SYSTEM RESTORE REPLICA`
    - `SYSTEM RELOAD`
      - `SYSTEM RELOAD ASYNCHRONOUS METRICS`
      - `SYSTEM RELOAD CONFIG`
        - `SYSTEM RELOAD DICTIONARY`
        - `SYSTEM RELOAD EMBEDDED DICTIONARIES`
        - `SYSTEM RELOAD FUNCTION`
        - `SYSTEM RELOAD MODEL`
        - `SYSTEM RELOAD USERS`
    - `SYSTEM SENDS`
      - `SYSTEM DISTRIBUTED SENDS`
      - `SYSTEM REPLICATED SENDS`
    - `SYSTEM SHUTDOWN`
    - `SYSTEM SYNC DATABASE REPLICA`
    - `SYSTEM SYNC FILE CACHE`
    - `SYSTEM SYNC FILESYSTEM CACHE`
    - `SYSTEM SYNC REPLICA`
    - `SYSTEM SYNC TRANSACTION LOG`
    - `SYSTEM THREAD FUZZER`
    - `SYSTEM TTL MERGES`
    - `SYSTEM UNFREEZE`
    - `SYSTEM UNLOAD PRIMARY KEY`
    - `SYSTEM VIEWS`
    - `SYSTEM VIRTUAL PARTS UPDATE`
    - `SYSTEM WAIT LOADING PARTS`
  - [`TABLE ENGINE`](#table-engine)
  - [`TRUNCATE`](#truncate)
  - `UNDROP TABLE` 
- [`NONE`](#none)

Examples of how this hierarchy is treated:

- The `ALTER` privilege includes all other `ALTER*` privileges.
- `ALTER CONSTRAINT` includes `ALTER ADD CONSTRAINT` and `ALTER DROP CONSTRAINT` privileges.

Privileges are applied at different levels. Knowing of a level suggests syntax available for privilege.

Levels (from lower to higher):

- `COLUMN` — Privilege can be granted for column, table, database, or globally.
- `TABLE` — Privilege can be granted for table, database, or globally.
- `VIEW` — Privilege can be granted for view, database, or globally.
- `DICTIONARY` — Privilege can be granted for dictionary, database, or globally.
- `DATABASE` — Privilege can be granted for database or globally.
- `GLOBAL` — Privilege can be granted only globally.
- `GROUP` — Groups privileges of different levels. When `GROUP`-level privilege is granted, only that privileges from the group are granted which correspond to the used syntax.

Examples of allowed syntax:

- `GRANT SELECT(x) ON db.table TO user`
- `GRANT SELECT ON db.* TO user`

Examples of disallowed syntax:

- `GRANT CREATE USER(x) ON db.table TO user`
- `GRANT CREATE USER ON db.* TO user`

The special privilege [ALL](#all) grants all the privileges to a user account or a role.

By default, a user account or a role has no privileges.

If a user or a role has no privileges, it is displayed as [NONE](#none) privilege.

Some queries by their implementation require a set of privileges. For example, to execute the [RENAME](../../sql-reference/statements/optimize.md) query you need the following privileges: `SELECT`, `CREATE TABLE`, `INSERT` and `DROP TABLE`.

### SELECT {#select}

Allows executing [SELECT](../../sql-reference/statements/select/index.md) queries.

Privilege level: `COLUMN`.

**Description**

User granted with this privilege can execute `SELECT` queries over a specified list of columns in the specified table and database. If user includes other columns then specified a query returns no data.

Consider the following privilege:

```sql
GRANT SELECT(x,y) ON db.table TO john
```

This privilege allows `john` to execute any `SELECT` query that involves data from the `x` and/or `y` columns in `db.table`, for example, `SELECT x FROM db.table`. `john` can't execute `SELECT z FROM db.table`. The `SELECT * FROM db.table` also is not available. Processing this query, ClickHouse does not return any data, even `x` and `y`. The only exception is if a table contains only `x` and `y` columns, in this case ClickHouse returns all the data.

### INSERT {#insert}

Allows executing [INSERT](../../sql-reference/statements/insert-into.md) queries.

Privilege level: `COLUMN`.

**Description**

User granted with this privilege can execute `INSERT` queries over a specified list of columns in the specified table and database. If user includes other columns then specified a query does not insert any data.

**Example**

```sql
GRANT INSERT(x,y) ON db.table TO john
```

The granted privilege allows `john` to insert data to the `x` and/or `y` columns in `db.table`.

### ALTER {#alter}

Allows executing [ALTER](../../sql-reference/statements/alter/index.md) queries according to the following hierarchy of privileges:

- `ALTER`. Level: `COLUMN`.
  - `ALTER TABLE`. Level: `GROUP`
  - `ALTER UPDATE`. Level: `COLUMN`. Aliases: `UPDATE`
  - `ALTER DELETE`. Level: `COLUMN`. Aliases: `DELETE`
  - `ALTER COLUMN`. Level: `GROUP`
  - `ALTER ADD COLUMN`. Level: `COLUMN`. Aliases: `ADD COLUMN`
  - `ALTER DROP COLUMN`. Level: `COLUMN`. Aliases: `DROP COLUMN`
  - `ALTER MODIFY COLUMN`. Level: `COLUMN`. Aliases: `MODIFY COLUMN`
  - `ALTER COMMENT COLUMN`. Level: `COLUMN`. Aliases: `COMMENT COLUMN`
  - `ALTER CLEAR COLUMN`. Level: `COLUMN`. Aliases: `CLEAR COLUMN`
  - `ALTER RENAME COLUMN`. Level: `COLUMN`. Aliases: `RENAME COLUMN`
  - `ALTER INDEX`. Level: `GROUP`. Aliases: `INDEX`
  - `ALTER ORDER BY`. Level: `TABLE`. Aliases: `ALTER MODIFY ORDER BY`, `MODIFY ORDER BY`
  - `ALTER SAMPLE BY`. Level: `TABLE`. Aliases: `ALTER MODIFY SAMPLE BY`, `MODIFY SAMPLE BY`
  - `ALTER ADD INDEX`. Level: `TABLE`. Aliases: `ADD INDEX`
  - `ALTER DROP INDEX`. Level: `TABLE`. Aliases: `DROP INDEX`
  - `ALTER MATERIALIZE INDEX`. Level: `TABLE`. Aliases: `MATERIALIZE INDEX`
  - `ALTER CLEAR INDEX`. Level: `TABLE`. Aliases: `CLEAR INDEX`
  - `ALTER CONSTRAINT`. Level: `GROUP`. Aliases: `CONSTRAINT`
  - `ALTER ADD CONSTRAINT`. Level: `TABLE`. Aliases: `ADD CONSTRAINT`
  - `ALTER DROP CONSTRAINT`. Level: `TABLE`. Aliases: `DROP CONSTRAINT`
  - `ALTER TTL`. Level: `TABLE`. Aliases: `ALTER MODIFY TTL`, `MODIFY TTL`
  - `ALTER MATERIALIZE TTL`. Level: `TABLE`. Aliases: `MATERIALIZE TTL`
  - `ALTER SETTINGS`. Level: `TABLE`. Aliases: `ALTER SETTING`, `ALTER MODIFY SETTING`, `MODIFY SETTING`
  - `ALTER MOVE PARTITION`. Level: `TABLE`. Aliases: `ALTER MOVE PART`, `MOVE PARTITION`, `MOVE PART`
  - `ALTER FETCH PARTITION`. Level: `TABLE`. Aliases: `ALTER FETCH PART`, `FETCH PARTITION`, `FETCH PART`
  - `ALTER FREEZE PARTITION`. Level: `TABLE`. Aliases: `FREEZE PARTITION`
  - `ALTER VIEW`. Level: `GROUP`
  - `ALTER VIEW REFRESH`. Level: `VIEW`. Aliases: `ALTER LIVE VIEW REFRESH`, `REFRESH VIEW`
  - `ALTER VIEW MODIFY QUERY`. Level: `VIEW`. Aliases: `ALTER TABLE MODIFY QUERY`
  - `ALTER VIEW MODIFY SQL SECURITY`. Level: `VIEW`. Aliases: `ALTER TABLE MODIFY SQL SECURITY`

Examples of how this hierarchy is treated:

- The `ALTER` privilege includes all other `ALTER*` privileges.
- `ALTER CONSTRAINT` includes `ALTER ADD CONSTRAINT` and `ALTER DROP CONSTRAINT` privileges.

**Notes**

- The `MODIFY SETTING` privilege allows modifying table engine settings. It does not affect settings or server configuration parameters.
- The `ATTACH` operation needs the [CREATE](#create) privilege.
- The `DETACH` operation needs the [DROP](#drop) privilege.
- To stop mutation by the [KILL MUTATION](../../sql-reference/statements/kill.md#kill-mutation) query, you need to have a privilege to start this mutation. For example, if you want to stop the `ALTER UPDATE` query, you need the `ALTER UPDATE`, `ALTER TABLE`, or `ALTER` privilege.

### BACKUP {#backup}

Allows execution of [`BACKUP`] in queries. For more information on backups see ["Backup and Restore"](../../operations/backup.md).

### CREATE {#create}

Allows executing [CREATE](../../sql-reference/statements/create/index.md) and [ATTACH](../../sql-reference/statements/attach.md) DDL-queries according to the following hierarchy of privileges:

- `CREATE`. Level: `GROUP`
  - `CREATE DATABASE`. Level: `DATABASE`
  - `CREATE TABLE`. Level: `TABLE`
    - `CREATE ARBITRARY TEMPORARY TABLE`. Level: `GLOBAL`
      - `CREATE TEMPORARY TABLE`. Level: `GLOBAL`
  - `CREATE VIEW`. Level: `VIEW`
  - `CREATE DICTIONARY`. Level: `DICTIONARY`

**Notes**

- To delete the created table, a user needs [DROP](#drop).

### CLUSTER {#cluster}

Allows executing `ON CLUSTER` queries.

```sql title="Syntax"
GRANT CLUSTER ON *.* TO <username>
```

By default, queries with `ON CLUSTER` require the user to have the `CLUSTER` grant.
You will get the following error if you to try to use `ON CLUSTER` in a query without first granting the `CLUSTER` privilege:

```text
Not enough privileges. To execute this query, it's necessary to have the grant CLUSTER ON *.*. 
```

The default behavior can be changed by setting the `on_cluster_queries_require_cluster_grant` setting,
located in the `access_control_improvements` section of `config.xml` (see below), to `false`.

```yaml title="config.xml"
<access_control_improvements>
    <on_cluster_queries_require_cluster_grant>true</on_cluster_queries_require_cluster_grant>
</access_control_improvements>
```

### DROP {#drop}

Allows executing [DROP](../../sql-reference/statements/drop.md) and [DETACH](../../sql-reference/statements/detach.md) queries according to the following hierarchy of privileges:

- `DROP`. Level: `GROUP`
  - `DROP DATABASE`. Level: `DATABASE`
  - `DROP TABLE`. Level: `TABLE`
  - `DROP VIEW`. Level: `VIEW`
  - `DROP DICTIONARY`. Level: `DICTIONARY`

### TRUNCATE {#truncate}

Allows executing [TRUNCATE](../../sql-reference/statements/truncate.md) queries.

Privilege level: `TABLE`.

### OPTIMIZE {#optimize}

Allows executing [OPTIMIZE TABLE](../../sql-reference/statements/optimize.md) queries.

Privilege level: `TABLE`.

### SHOW {#show}

Allows executing `SHOW`, `DESCRIBE`, `USE`, and `EXISTS` queries according to the following hierarchy of privileges:

- `SHOW`. Level: `GROUP`
  - `SHOW DATABASES`. Level: `DATABASE`. Allows to execute `SHOW DATABASES`, `SHOW CREATE DATABASE`, `USE <database>` queries.
  - `SHOW TABLES`. Level: `TABLE`. Allows to execute `SHOW TABLES`, `EXISTS <table>`, `CHECK <table>` queries.
  - `SHOW COLUMNS`. Level: `COLUMN`. Allows to execute `SHOW CREATE TABLE`, `DESCRIBE` queries.
  - `SHOW DICTIONARIES`. Level: `DICTIONARY`. Allows to execute `SHOW DICTIONARIES`, `SHOW CREATE DICTIONARY`, `EXISTS <dictionary>` queries.

**Notes**

A user has the `SHOW` privilege if it has any other privilege concerning the specified table, dictionary or database.

### KILL QUERY {#kill-query}

Allows executing [KILL](../../sql-reference/statements/kill.md#kill-query) queries according to the following hierarchy of privileges:

Privilege level: `GLOBAL`.

**Notes**

`KILL QUERY` privilege allows one user to kill queries of other users.

### ACCESS MANAGEMENT {#access-management}

Allows a user to execute queries that manage users, roles and row policies.

- `ACCESS MANAGEMENT`. Level: `GROUP`
  - `CREATE USER`. Level: `GLOBAL`
  - `ALTER USER`. Level: `GLOBAL`
  - `DROP USER`. Level: `GLOBAL`
  - `CREATE ROLE`. Level: `GLOBAL`
  - `ALTER ROLE`. Level: `GLOBAL`
  - `DROP ROLE`. Level: `GLOBAL`
  - `ROLE ADMIN`. Level: `GLOBAL`
  - `CREATE ROW POLICY`. Level: `GLOBAL`. Aliases: `CREATE POLICY`
  - `ALTER ROW POLICY`. Level: `GLOBAL`. Aliases: `ALTER POLICY`
  - `DROP ROW POLICY`. Level: `GLOBAL`. Aliases: `DROP POLICY`
  - `CREATE QUOTA`. Level: `GLOBAL`
  - `ALTER QUOTA`. Level: `GLOBAL`
  - `DROP QUOTA`. Level: `GLOBAL`
  - `CREATE SETTINGS PROFILE`. Level: `GLOBAL`. Aliases: `CREATE PROFILE`
  - `ALTER SETTINGS PROFILE`. Level: `GLOBAL`. Aliases: `ALTER PROFILE`
  - `DROP SETTINGS PROFILE`. Level: `GLOBAL`. Aliases: `DROP PROFILE`
  - `SHOW ACCESS`. Level: `GROUP`
    - `SHOW_USERS`. Level: `GLOBAL`. Aliases: `SHOW CREATE USER`
    - `SHOW_ROLES`. Level: `GLOBAL`. Aliases: `SHOW CREATE ROLE`
    - `SHOW_ROW_POLICIES`. Level: `GLOBAL`. Aliases: `SHOW POLICIES`, `SHOW CREATE ROW POLICY`, `SHOW CREATE POLICY`
    - `SHOW_QUOTAS`. Level: `GLOBAL`. Aliases: `SHOW CREATE QUOTA`
    - `SHOW_SETTINGS_PROFILES`. Level: `GLOBAL`. Aliases: `SHOW PROFILES`, `SHOW CREATE SETTINGS PROFILE`, `SHOW CREATE PROFILE`
  - `ALLOW SQL SECURITY NONE`. Level: `GLOBAL`. Aliases: `CREATE SQL SECURITY NONE`, `SQL SECURITY NONE`, `SECURITY NONE`

The `ROLE ADMIN` privilege allows a user to assign and revoke any roles including those which are not assigned to the user with the admin option.

### SYSTEM {#system}

Allows a user to execute [SYSTEM](../../sql-reference/statements/system.md) queries according to the following hierarchy of privileges.

- `SYSTEM`. Level: `GROUP`
  - `SYSTEM SHUTDOWN`. Level: `GLOBAL`. Aliases: `SYSTEM KILL`, `SHUTDOWN`
  - `SYSTEM DROP CACHE`. Aliases: `DROP CACHE`
    - `SYSTEM DROP DNS CACHE`. Level: `GLOBAL`. Aliases: `SYSTEM DROP DNS`, `DROP DNS CACHE`, `DROP DNS`
    - `SYSTEM DROP MARK CACHE`. Level: `GLOBAL`. Aliases: `SYSTEM DROP MARK`, `DROP MARK CACHE`, `DROP MARKS`
    - `SYSTEM DROP UNCOMPRESSED CACHE`. Level: `GLOBAL`. Aliases: `SYSTEM DROP UNCOMPRESSED`, `DROP UNCOMPRESSED CACHE`, `DROP UNCOMPRESSED`
  - `SYSTEM RELOAD`. Level: `GROUP`
    - `SYSTEM RELOAD CONFIG`. Level: `GLOBAL`. Aliases: `RELOAD CONFIG`
    - `SYSTEM RELOAD DICTIONARY`. Level: `GLOBAL`. Aliases: `SYSTEM RELOAD DICTIONARIES`, `RELOAD DICTIONARY`, `RELOAD DICTIONARIES`
      - `SYSTEM RELOAD EMBEDDED DICTIONARIES`. Level: `GLOBAL`. Aliases: `RELOAD EMBEDDED DICTIONARIES`
  - `SYSTEM MERGES`. Level: `TABLE`. Aliases: `SYSTEM STOP MERGES`, `SYSTEM START MERGES`, `STOP MERGES`, `START MERGES`
  - `SYSTEM TTL MERGES`. Level: `TABLE`. Aliases: `SYSTEM STOP TTL MERGES`, `SYSTEM START TTL MERGES`, `STOP TTL MERGES`, `START TTL MERGES`
  - `SYSTEM FETCHES`. Level: `TABLE`. Aliases: `SYSTEM STOP FETCHES`, `SYSTEM START FETCHES`, `STOP FETCHES`, `START FETCHES`
  - `SYSTEM MOVES`. Level: `TABLE`. Aliases: `SYSTEM STOP MOVES`, `SYSTEM START MOVES`, `STOP MOVES`, `START MOVES`
  - `SYSTEM SENDS`. Level: `GROUP`. Aliases: `SYSTEM STOP SENDS`, `SYSTEM START SENDS`, `STOP SENDS`, `START SENDS`
    - `SYSTEM DISTRIBUTED SENDS`. Level: `TABLE`. Aliases: `SYSTEM STOP DISTRIBUTED SENDS`, `SYSTEM START DISTRIBUTED SENDS`, `STOP DISTRIBUTED SENDS`, `START DISTRIBUTED SENDS`
    - `SYSTEM REPLICATED SENDS`. Level: `TABLE`. Aliases: `SYSTEM STOP REPLICATED SENDS`, `SYSTEM START REPLICATED SENDS`, `STOP REPLICATED SENDS`, `START REPLICATED SENDS`
  - `SYSTEM REPLICATION QUEUES`. Level: `TABLE`. Aliases: `SYSTEM STOP REPLICATION QUEUES`, `SYSTEM START REPLICATION QUEUES`, `STOP REPLICATION QUEUES`, `START REPLICATION QUEUES`
  - `SYSTEM SYNC REPLICA`. Level: `TABLE`. Aliases: `SYNC REPLICA`
  - `SYSTEM RESTART REPLICA`. Level: `TABLE`. Aliases: `RESTART REPLICA`
  - `SYSTEM FLUSH`. Level: `GROUP`
    - `SYSTEM FLUSH DISTRIBUTED`. Level: `TABLE`. Aliases: `FLUSH DISTRIBUTED`
    - `SYSTEM FLUSH LOGS`. Level: `GLOBAL`. Aliases: `FLUSH LOGS`

The `SYSTEM RELOAD EMBEDDED DICTIONARIES` privilege implicitly granted by the `SYSTEM RELOAD DICTIONARY ON *.*` privilege.

### INTROSPECTION {#introspection}

Allows using [introspection](../../operations/optimizing-performance/sampling-query-profiler.md) functions.

- `INTROSPECTION`. Level: `GROUP`. Aliases: `INTROSPECTION FUNCTIONS`
  - `addressToLine`. Level: `GLOBAL`
  - `addressToLineWithInlines`. Level: `GLOBAL`
  - `addressToSymbol`. Level: `GLOBAL`
  - `demangle`. Level: `GLOBAL`

### SOURCES {#sources}

Allows using external data sources. Applies to [table engines](../../engines/table-engines/index.md) and [table functions](/sql-reference/table-functions).

- `SOURCES`. Level: `GROUP`  
  - `AZURE`. Level: `GLOBAL`  
  - `FILE`. Level: `GLOBAL`  
  - `HDFS`. Level: `GLOBAL`  
  - `HIVE`. Level: `GLOBAL`  
  - `JDBC`. Level: `GLOBAL`  
  - `KAFKA`. Level: `GLOBAL`  
  - `MONGO`. Level: `GLOBAL`  
  - `MYSQL`. Level: `GLOBAL`  
  - `NATS`. Level: `GLOBAL`  
  - `ODBC`. Level: `GLOBAL`  
  - `POSTGRES`. Level: `GLOBAL`  
  - `RABBITMQ`. Level: `GLOBAL`  
  - `REDIS`. Level: `GLOBAL`  
  - `REMOTE`. Level: `GLOBAL`  
  - `S3`. Level: `GLOBAL`  
  - `SQLITE`. Level: `GLOBAL`  
  - `URL`. Level: `GLOBAL`

The `SOURCES` privilege enables use of all the sources. Also you can grant a privilege for each source individually. To use sources, you need additional privileges.

Examples:

- To create a table with the [MySQL table engine](../../engines/table-engines/integrations/mysql.md), you need `CREATE TABLE (ON db.table_name)` and `MYSQL` privileges.
- To use the [mysql table function](../../sql-reference/table-functions/mysql.md), you need `CREATE TEMPORARY TABLE` and `MYSQL` privileges.

### dictGet {#dictget}

- `dictGet`. Aliases: `dictHas`, `dictGetHierarchy`, `dictIsIn`

Allows a user to execute [dictGet](/sql-reference/functions/ext-dict-functions#dictget-dictgetordefault-dictgetornull), [dictHas](../../sql-reference/functions/ext-dict-functions.md#dicthas), [dictGetHierarchy](../../sql-reference/functions/ext-dict-functions.md#dictgethierarchy), [dictIsIn](../../sql-reference/functions/ext-dict-functions.md#dictisin) functions.

Privilege level: `DICTIONARY`.

**Examples**

- `GRANT dictGet ON mydb.mydictionary TO john`
- `GRANT dictGet ON mydictionary TO john`

### displaySecretsInShowAndSelect {#displaysecretsinshowandselect}

Allows a user to view secrets in `SHOW` and `SELECT` queries if both
[`display_secrets_in_show_and_select` server setting](../../operations/server-configuration-parameters/settings#display_secrets_in_show_and_select)
and
[`format_display_secrets_in_show_and_select` format setting](../../operations/settings/formats#format_display_secrets_in_show_and_select)
are turned on.

### NAMED COLLECTION ADMIN {#named-collection-admin}

Allows a certain operation on a specified named collection. Before version 23.7 it was called NAMED COLLECTION CONTROL, and after 23.7 NAMED COLLECTION ADMIN was added and NAMED COLLECTION CONTROL is preserved as an alias.

- `NAMED COLLECTION ADMIN`. Level: `NAMED_COLLECTION`. Aliases: `NAMED COLLECTION CONTROL`
  - `CREATE NAMED COLLECTION`. Level: `NAMED_COLLECTION`
  - `DROP NAMED COLLECTION`. Level: `NAMED_COLLECTION`
  - `ALTER NAMED COLLECTION`. Level: `NAMED_COLLECTION`
  - `SHOW NAMED COLLECTIONS`. Level: `NAMED_COLLECTION`. Aliases: `SHOW NAMED COLLECTIONS`
  - `SHOW NAMED COLLECTIONS SECRETS`. Level: `NAMED_COLLECTION`. Aliases: `SHOW NAMED COLLECTIONS SECRETS`
  - `NAMED COLLECTION`. Level: `NAMED_COLLECTION`. Aliases: `NAMED COLLECTION USAGE, USE NAMED COLLECTION`

Unlike all other grants (CREATE, DROP, ALTER, SHOW) grant NAMED COLLECTION was added only in 23.7, while all others were added earlier - in 22.12.

**Examples**

Assuming a named collection is called abc, we grant privilege CREATE NAMED COLLECTION to user john.
- `GRANT CREATE NAMED COLLECTION ON abc TO john`

### TABLE ENGINE {#table-engine}

Allows using a specified table engine when creating a table. Applies to [table engines](../../engines/table-engines/index.md).

**Examples**

- `GRANT TABLE ENGINE ON * TO john`
- `GRANT TABLE ENGINE ON TinyLog TO john`

### ALL {#all}

<CloudNotSupportedBadge/>

Grants all the privileges on regulated entity to a user account or a role.

:::note
The privilege `ALL` is not supported in ClickHouse Cloud, where the `default` user has limited permissions. Users can grant the maximum permissions to a user by granting the `default_role`. See [here](/cloud/security/cloud-access-management/overview#initial-settings) for further details.
Users can also use the `GRANT CURRENT GRANTS` as the default user to achieve similar effects to `ALL`.
:::

### NONE {#none}

Doesn't grant any privileges.

### ADMIN OPTION {#admin-option}

The `ADMIN OPTION` privilege allows a user to grant their role to another user.
