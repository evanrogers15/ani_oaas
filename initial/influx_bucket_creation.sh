#!/bin/bash

curl -s -o /data/influx/orgs.json -X GET -H "Content-type: application/json" -H "Authorization: Token $DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" 'http://influxdb:8086/api/v2/orgs'
curl -s -o /data/influx/tasks.json -X GET -H "Content-type: application/json" -H "Authorization: Token $DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" 'http://influxdb:8086/api/v2/tasks'
curl -s -o /data/influx/buckets.json -X GET -H "Content-type: application/json" -H "Authorization: Token $DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" 'http://influxdb:8086/api/v2/buckets'   

influx_org_id=($( jq -r '.orgs[].id' /data/influx/orgs.json))
influx_org_name=($( jq -r '.orgs[].name' /data/influx/orgs.json))
existing_buckets=($( jq -r '.buckets[].name' /data/influx/buckets.json))
bucket=(bsr_bucket bsr_final_1m bsr_final_5m bsr_final_60m demo_bsr_bucket demo_bsr_final)
bucket_count="${#bucket[@]}"

#bucket creation
for ((j=0; j<$bucket_count; j++))
  do
  bucket_temp=${bucket[$j]}
    if [[ ! " ${existing_buckets[@]} " =~ " ${bucket_temp} " ]]; then
      curl -s -o /dev/null -X 'POST' "http://influxdb:8086/api/v2/buckets" \
    --header "Content-type: application/json" \
    --header "Authorization: Token $DOCKER_INFLUXDB_INIT_ADMIN_TOKEN" \
    --data-raw '{
        "name": "'$bucket_temp'",
        "orgID": "'$influx_org_id'"
      }'
      echo $bucket" created."
    fi
  done