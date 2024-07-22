#!/bin/bash

gpio mode 12 out
gpio write 12 1

echo 70000 > /sys/devices/virtual/thermal/thermal_zone0/trip_point_0_temp
echo 70000 > /sys/devices/virtual/thermal/thermal_zone1/trip_point_0_temp
echo 70000 > /sys/devices/virtual/thermal/thermal_zone2/trip_point_0_temp
echo 70000 > /sys/devices/virtual/thermal/thermal_zone3/trip_point_0_temp

chmod ugo+xrw /dev/ttyACM*


