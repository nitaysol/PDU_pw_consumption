 #!/bin/bash

#run every 10 minutes
DELAY=600
######function that checks power consumption for each pdu######
function get_machine_pdu_consum
{
for i in 1 2 3 4; do
	sleep 1
	#send snmp message to get consum info
	declare "PDU$i"=$(snmpget -v 1 -c private $1-pdu$i .1.3.6.1.4.1.318.1.1.12.1.16.0 2>/dev/null | awk '{print $4}')
	PDU_NOW_CHECKING="PDU"$i
	#if its not number make it 0(null cases)
	if ! [ "${!PDU_NOW_CHECKING}" -eq "${!PDU_NOW_CHECKING}" ] 2>/dev/null; then
		declare "PDU$i"=0
	else
		echo "PDU$i=${!PDU_NOW_CHECKING}" >>$log
	fi
done
SUM_OF_POWER_CONSUM=$(expr $PDU1 + $PDU2 + $PDU3 + $PDU4)
echo "SUM of POWER CONSUMPTION=$SUM_OF_POWER_CONSUM" >>$log
echo "###########################################" >>$log
}

######MAIN######
function main
{
#For each line(each machine):
while read f;
	do
	#check machine isnt build from 3 digits and isnt starting with ignore
	if [ ! ${#f} = 9 ] && [[ $f != "ignore"* ]]; then
		ping -c 1 $f &>/dev/null
		#if machine is on check pdu consum
		if [ $? = 0 ]; then
			echo "$f-ON" >>$log
			#send to function that check consum
			get_machine_pdu_consum $f
		else
			#if ping failed, try one more try again with sleep of 1 secs
			sleep 1
			ping -c 1 $f &>/dev/null
			if [ $? = 0 ]; then
				echo "$f-ON" >>$log
				get_machine_pdu_consum $f
			else
				echo "$f-OFF" >>$log
				echo "###########################################" >>$log
			fi
		fi
	fi

done <$MACHINES
}

###########################
while true; do
	#log file output
	log="log"
	echo "				     DATE:  $(date +"%d-%m-%y") - $(date +"%T")" >>$log
	echo "                           -------------------------------------------------" >>$log
	echo "                          | STARTING POWER_CONSUMPTION CHECK FOR ALL MACHINES |" >>$log
	echo "                           -------------------------------------------------" >>$log
	echo "###########################################" >>$log
	#list of machines
	MACHINES="machines"
	main
	sleep $DELAY
done
