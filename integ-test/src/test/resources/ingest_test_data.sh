#!/bin/bash
set -euo pipefail

OS_HOST="${OS_HOST:-http://localhost:9200}"
SQL_DIR="$HOME/sql/integ-test/src/test/resources"
SETTINGS='{"settings":{"number_of_replicas":0,"number_of_shards":1,"index.pluggable.dataformat.enabled":true,"index.pluggable.dataformat":"composite","index.composite.primary_data_format":"parquet","index.composite.secondary_data_formats":[]}}'

echo "=== Ingesting test data into $OS_HOST ==="

ingest() {
  local index="$1"
  local datafile="$2"
  local mapping="${3:-}"
  
  if curl -sf -o /dev/null "$OS_HOST/$index" 2>/dev/null; then
    echo "  SKIP $index (exists)"
    return
  fi
  
  if [ -n "$mapping" ] && [ -f "$mapping" ]; then
    # Merge settings with mapping
    local body=$(python3 -c "
import json,sys
m = json.load(open('$mapping'))
s = json.loads('$SETTINGS')
if 'settings' in m:
    m['settings'].update(s['settings'])
else:
    m['settings'] = s['settings']
print(json.dumps(m))
")
    curl -s -XPUT "$OS_HOST/$index" -H 'Content-Type: application/json' -d "$body" > /dev/null
  else
    curl -s -XPUT "$OS_HOST/$index" -H 'Content-Type: application/json' -d "$SETTINGS" > /dev/null
  fi
  
  if [ -f "$datafile" ]; then
    curl -s -XPOST "$OS_HOST/$index/_bulk?refresh=true" -H 'Content-Type: application/x-ndjson' --data-binary "@$datafile" > /dev/null
    local count=$(curl -s "$OS_HOST/$index/_count" | python3 -c "import sys,json;print(json.load(sys.stdin).get('count',0))")
    echo "  OK $index ($count docs)"
  else
    echo "  WARN $index (no data file: $datafile)"
  fi
}

# All indices from the test suite
ingest "opensearch-sql_test_index_account" "$SQL_DIR/accounts.json"
ingest "opensearch-sql_test_index_bank" "$SQL_DIR/bank.json"
ingest "opensearch-sql_test_index_bank_two" "$SQL_DIR/bank_two.json"
ingest "opensearch-sql_test_index_bank_with_null_values" "$SQL_DIR/bank_with_null_values.json"
ingest "opensearch-sql_test_index_dog" "$SQL_DIR/dogs.json"
ingest "opensearch-sql_test_index_people2" "$SQL_DIR/people2.json"
ingest "opensearch-sql_test_index_game_of_thrones" "$SQL_DIR/game_of_thrones_complex.json"
ingest "opensearch-sql_test_index_locations_type_conflict" "$SQL_DIR/locations_type_conflict.json"
ingest "opensearch-sql_test_index_nested_type_without_arrays" "$SQL_DIR/nested_objects_without_arrays.json"
ingest "opensearch-sql_test_index_geoip" "$SQL_DIR/geoip.json"
ingest "opensearch-sql_test_index_strings" "$SQL_DIR/strings.json"
ingest "opensearch-sql_test_index_time_data" "$SQL_DIR/time_test_data.json"
ingest "opensearch-sql_test_index_time_data2" "$SQL_DIR/time_test_data2.json"
ingest "opensearch-sql_test_index_weblogs" "$SQL_DIR/weblogs.json"
ingest "opensearch-sql_test_index_date" "$SQL_DIR/dates.json"
ingest "opensearch-sql_test_index_nested_simple" "$SQL_DIR/nested_simple.json"
ingest "mvexpand_edge_cases" "$SQL_DIR/mvexpand_edge_cases.json"
ingest "opensearch-sql_test_index_deep_nested" "$SQL_DIR/deep_nested_index_data.json"
ingest "opensearch-sql_test_index_cascaded_nested" "$SQL_DIR/cascaded_nested.json"
ingest "opensearch-sql_test_index_telemetry" "$SQL_DIR/telemetry_test_data.json"
ingest "opensearch-sql_test_index_datatypes_numeric" "$SQL_DIR/datatypes_numeric.json"
ingest "opensearch-sql_test_index_datatypes_nonnumeric" "$SQL_DIR/datatypes.json"
ingest "opensearch-sql_test_index_null_missing" "$SQL_DIR/null_missing.json"
ingest "opensearch-sql_test_index_calcs" "$SQL_DIR/calcs.json"
ingest "opensearch-sql_test_index_date_formats" "$SQL_DIR/date_formats.json"
ingest "opensearch-sql_test_index_date_formats_with_null" "$SQL_DIR/date_formats_with_null.json"
ingest "opensearch-sql_test_index_state_country" "$SQL_DIR/state_country.json"
ingest "opensearch-sql_test_index_state_country_with_null" "$SQL_DIR/state_country_with_null.json"
ingest "opensearch-sql_test_index_occupation" "$SQL_DIR/occupation.json"
ingest "opensearch-sql_test_index_hobbies" "$SQL_DIR/hobbies.json"
ingest "opensearch-sql_test_index_merge_test_1" "$SQL_DIR/merge_test_1.json"
ingest "opensearch-sql_test_index_merge_test_2" "$SQL_DIR/merge_test_2.json"
ingest "opensearch-sql_test_index_worker" "$SQL_DIR/worker.json"
ingest "opensearch-sql_test_index_work_information" "$SQL_DIR/work_information.json"
ingest "opensearch-sql_test_index_json_test" "$SQL_DIR/json_test.json"
ingest "opensearch-sql_test_index_alias" "$SQL_DIR/alias.json"
ingest "opensearch-sql_test_index_duplication_nullable" "$SQL_DIR/duplication_nullable.json"
ingest "opensearch-sql_test_index_graph_employees" "$SQL_DIR/graph_employees.json"
ingest "opensearch-sql_test_index_graph_travelers" "$SQL_DIR/graph_travelers.json"
ingest "opensearch-sql_test_index_graph_airports" "$SQL_DIR/graph_airports.json"
ingest "opensearch-sql_test_index_array" "$SQL_DIR/array.json"
ingest "opensearch-sql_test_index_hdfs_logs" "$SQL_DIR/hdfs_logs.json"
ingest "opensearch-sql_test_index_logs" "$SQL_DIR/logs.json"
ingest "opensearch-sql_test_index_otel_logs" "$SQL_DIR/otellogs.json"
ingest "test_index_mvcombine" "$SQL_DIR/mvcombine.json"
ingest "events" "$SQL_DIR/events_test.json"
ingest "events_null" "$SQL_DIR/events_null.json"
ingest "events_traffic" "$SQL_DIR/events_traffic.json"

# Dashboard indices
DASHBOARD_DIR="$HOME/sql/integ-test/src/test/java/org/opensearch/sql/ppl/dashboard"
ingest "cloudtrail_logs" "$DASHBOARD_DIR/testdata/cloudtrail_logs.json" "$DASHBOARD_DIR/mappings/cloudtrail_logs_index_mapping.json"
ingest "vpc_flow_logs" "$DASHBOARD_DIR/testdata/vpc_logs.json" "$DASHBOARD_DIR/mappings/vpc_logs_index_mapping.json"
ingest "nfw_logs" "$DASHBOARD_DIR/testdata/nfw_logs.json" "$DASHBOARD_DIR/mappings/nfw_logs_index_mapping.json"
ingest "waf_logs" "$DASHBOARD_DIR/testdata/waf_logs.json" "$DASHBOARD_DIR/mappings/waf_logs_index_mapping.json"

echo ""
echo "=== Done. Total indices: ==="
curl -s "$OS_HOST/_cat/indices?h=index" | grep -v "^\." | wc -l
