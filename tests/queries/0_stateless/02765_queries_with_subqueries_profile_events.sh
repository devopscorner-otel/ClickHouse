#!/usr/bin/env bash

CUR_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../shell_config.sh
. "$CUR_DIR"/../shell_config.sh

$CLICKHOUSE_CLIENT -q "
    DROP TABLE IF EXISTS mv;
    DROP TABLE IF EXISTS output;
    DROP TABLE IF EXISTS input;

    CREATE TABLE input (key Int) Engine=Null;
    CREATE TABLE output AS input Engine=Null;
    CREATE MATERIALIZED VIEW mv TO output SQL SECURITY NONE AS SELECT * FROM input;
"

for enable_analyzer in 0 1; do
    query_id="$(random_str 10)"
    query="INSERT INTO input SELECT * FROM numbers(1)"
    echo "$query"
    $CLICKHOUSE_CLIENT --parallel_distributed_insert_select=0 --enable_analyzer "$enable_analyzer" --query_id "$query_id" -q "$query"
    $CLICKHOUSE_CLIENT -m -q "
        SYSTEM FLUSH LOGS query_log;
        SELECT
            1 view,
            $enable_analyzer enable_analyzer,
            ProfileEvents['InsertQuery'] InsertQuery,
            ProfileEvents['SelectQuery'] SelectQuery,
            ProfileEvents['InsertQueriesWithSubqueries'] InsertQueriesWithSubqueries,
            ProfileEvents['SelectQueriesWithSubqueries'] SelectQueriesWithSubqueries,
            ProfileEvents['QueriesWithSubqueries'] QueriesWithSubqueries
        FROM system.query_log
        WHERE current_database = currentDatabase() AND type = 'QueryFinish' AND query_id = '$query_id'
        FORMAT TSVWithNames;
    "

    query_id="$(random_str 10)"
    query="SELECT * FROM system.one WHERE dummy IN (SELECT * FROM system.one) FORMAT Null"
    echo "$query"
    $CLICKHOUSE_CLIENT --enable_analyzer "$enable_analyzer" --query_id "$query_id" -q "$query"
    $CLICKHOUSE_CLIENT -m -q "
        SYSTEM FLUSH LOGS query_log;
        SELECT
            1 subquery,
            $enable_analyzer enable_analyzer,
            ProfileEvents['InsertQuery'] InsertQuery,
            ProfileEvents['SelectQuery'] SelectQuery,
            ProfileEvents['InsertQueriesWithSubqueries'] InsertQueriesWithSubqueries,
            ProfileEvents['SelectQueriesWithSubqueries'] SelectQueriesWithSubqueries,
            ProfileEvents['QueriesWithSubqueries'] QueriesWithSubqueries
        FROM system.query_log
        WHERE current_database = currentDatabase() AND type = 'QueryFinish' AND query_id = '$query_id'
        FORMAT TSVWithNames;
    "

    query_id="$(random_str 10)"
    query="WITH (SELECT * FROM system.one) AS x SELECT x FORMAT Null"
    echo "$query"
    $CLICKHOUSE_CLIENT --enable_analyzer "$enable_analyzer" --query_id "$query_id" -q "$query"
    $CLICKHOUSE_CLIENT -m -q "
        SYSTEM FLUSH LOGS query_log;
        SELECT
            1 CSE,
            $enable_analyzer enable_analyzer,
            ProfileEvents['InsertQuery'] InsertQuery,
            ProfileEvents['SelectQuery'] SelectQuery,
            ProfileEvents['InsertQueriesWithSubqueries'] InsertQueriesWithSubqueries,
            ProfileEvents['SelectQueriesWithSubqueries'] SelectQueriesWithSubqueries,
            ProfileEvents['QueriesWithSubqueries'] QueriesWithSubqueries
        FROM system.query_log
        WHERE current_database = currentDatabase() AND type = 'QueryFinish' AND query_id = '$query_id'
        FORMAT TSVWithNames;
    "

    query_id="$(random_str 10)"
    query="WITH (SELECT * FROM system.one) AS x SELECT x, x FORMAT Null"
    echo "$query"
    $CLICKHOUSE_CLIENT --enable_analyzer "$enable_analyzer" --query_id "$query_id" -q "$query"
    $CLICKHOUSE_CLIENT -m -q "
        SYSTEM FLUSH LOGS query_log;
        SELECT
            1 CSE_Multi,
            $enable_analyzer enable_analyzer,
            ProfileEvents['InsertQuery'] InsertQuery,
            ProfileEvents['SelectQuery'] SelectQuery,
            ProfileEvents['InsertQueriesWithSubqueries'] InsertQueriesWithSubqueries,
            ProfileEvents['SelectQueriesWithSubqueries'] SelectQueriesWithSubqueries,
            ProfileEvents['QueriesWithSubqueries'] QueriesWithSubqueries
        FROM system.query_log
        WHERE current_database = currentDatabase() AND type = 'QueryFinish' AND query_id = '$query_id'
        FORMAT TSVWithNames;
    "

    query_id="$(random_str 10)"
    query="WITH x AS (SELECT * FROM system.one) SELECT * FROM x FORMAT Null"
    echo "$query"
    $CLICKHOUSE_CLIENT --enable_analyzer "$enable_analyzer" --query_id "$query_id" -q "$query"
    $CLICKHOUSE_CLIENT -m -q "
        SYSTEM FLUSH LOGS query_log;
        SELECT
            1 CTE,
            $enable_analyzer enable_analyzer,
            ProfileEvents['InsertQuery'] InsertQuery,
            ProfileEvents['SelectQuery'] SelectQuery,
            ProfileEvents['InsertQueriesWithSubqueries'] InsertQueriesWithSubqueries,
            ProfileEvents['SelectQueriesWithSubqueries'] SelectQueriesWithSubqueries,
            ProfileEvents['QueriesWithSubqueries'] QueriesWithSubqueries
        FROM system.query_log
        WHERE current_database = currentDatabase() AND type = 'QueryFinish' AND query_id = '$query_id'
        FORMAT TSVWithNames;
    "

    query_id="$(random_str 10)"
    query="WITH x AS (SELECT * FROM system.one) SELECT * FROM x UNION ALL SELECT * FROM x FORMAT Null"
    echo "$query"
    $CLICKHOUSE_CLIENT --enable_analyzer "$enable_analyzer" --query_id "$query_id" -q "$query"
    $CLICKHOUSE_CLIENT -m -q "
        SYSTEM FLUSH LOGS query_log;
        SELECT
            1 CTE_Multi,
            $enable_analyzer enable_analyzer,
            ProfileEvents['InsertQuery'] InsertQuery,
            ProfileEvents['SelectQuery'] SelectQuery,
            ProfileEvents['InsertQueriesWithSubqueries'] InsertQueriesWithSubqueries,
            ProfileEvents['SelectQueriesWithSubqueries'] SelectQueriesWithSubqueries,
            ProfileEvents['QueriesWithSubqueries'] QueriesWithSubqueries
        FROM system.query_log
        WHERE current_database = currentDatabase() AND type = 'QueryFinish' AND query_id = '$query_id'
        FORMAT TSVWithNames;
    "
done
