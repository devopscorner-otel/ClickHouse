SELECT DISTINCT result FROM (SELECT toStartOfFifteenMinutes(toDateTime(toStartOfFifteenMinutes(toDateTime(1000.0001220703125) + (number * 65536))) + (number * 9223372036854775807)) AS result FROM system.numbers LIMIT 1048576) ORDER BY result DESC NULLS FIRST FORMAT Null;
