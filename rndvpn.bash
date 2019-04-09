#!/usr/bin/env bash

set -ux

function startvpn(){

AIR_SERVERS=$(./air_servers.py | cut -d' ' -f1)
RANDOM_SERVER=$(echo ${AIR_SERVERS} | sed -e s/\ /\\n/g | shuf -n 1)
sudo gnome-terminal --geometry 80x24 --hide-menubar --zoom=0.8 --command "airvpn -cli -login='userpanzer' -password='YYdfh3&3b4*23&9' -connect -server=${RANDOM_SERVER}"

}

function stopvpn(){

PID=$(ps aux | grep "AirVPN.exe" | head -n1 | awk '{print $2}')
sudo kill -SIGTERM $PID

}

count=${1}
round=0

while  [ ${count} -ne ${round} ];

do 

startvpn

sleep 60

stopvpn

sleep 15

round=$[round+1]

done
