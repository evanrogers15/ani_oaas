#!/bin/bash

mkdir /data
mkdir /data/influx
cp -f /initial/bsr_script_interactive.sh /config/bsr_script_interactive.sh
chmod +x /config/bsr_script_interactive.sh
cp -f /initial/grafana.ini /config/grafana.ini
cp -f /initial/telegraf.conf /config/telegraf.conf
cp -f /initial/influxdb_ds.yml /config/influxdb_ds.yml



mkdir /data
mkdir /data/influx
cp -f /initial/grafana.ini /config/grafana.ini
cp -f /initial/telegraf.conf /config/telegraf.conf
cp -f /initial/influxdb_ds.yml /config/influxdb_ds.yml