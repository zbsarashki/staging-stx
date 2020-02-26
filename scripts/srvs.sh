#!/bin/bash

# USAGE:
# Scp stx3-centos.service and this script to the target and:
# ./srvs.sh 
# This will produce two files:
#	- systemd-unitfiles: listing of unitfiles between cetnos and warrior
#	- systemd-services: listing of services' status
# Relative to the spread sheet:
# systemd-unitfiles goes to services tab
# systemd-services goes to systemd-unitfiles tab


for f in $(cat stx3-centos.services); do 
	echo -n $f:
	systemctl list-unit-files $f | grep -q $f
	if [ $? -eq 0 ]; then 
		systemctl status -n 0 $f | grep Active: | sed -e 's/^.*: \(active\|inactive\|failed\) \((.*)\).*/\1 \2/g'; 
	else
		echo ""
	fi
		
done | tee systemd-unitfiles

for f in $(cat stx3-centos.services); do 
	systemctl list-unit-files $f | grep -q $f
	if [ $? -eq 0 ]; then 
		systemctl list-unit-files $f | grep $f | sed -e 's/ /:/g'
	else
		echo $f:
	fi
done | tee systemd-services
